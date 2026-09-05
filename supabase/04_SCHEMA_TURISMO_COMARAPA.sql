-- ============================================================
-- COMARAPA TURISMO · ESQUEMA DE BASE DE DATOS
-- Proyecto: App de turismo + panel de administración
-- Motor: PostgreSQL (Supabase) · Ejecutar completo en SQL Editor
--
-- Nota sobre tu script anterior ("registros_demo"): es una tabla
-- de práctica genérica, no forma parte del modelo de Comarapa.
-- Puedes conservarla sin problema (no choca con nada de aquí) o
-- borrarla descomentando la siguiente línea:
-- drop table if exists public.registros_demo cascade;
-- ============================================================


-- ============================================================
-- 0. EXTENSIONES
-- ============================================================

create extension if not exists pgcrypto;   -- gen_random_uuid()
create extension if not exists pg_trgm;    -- búsqueda de texto (ILIKE / autocompletado eficiente)


-- ============================================================
-- 1. TIPOS ENUM
-- Los valores fijos (roles, dificultad, moderación) van como enum:
-- ocupan menos espacio que texto libre y Postgres los valida solo,
-- sin necesitar un "check" en cada tabla que los usa.
-- Los "tipos" que el admin necesita poder editar (tipo de lugar,
-- de actividad, etc.) NO son enum: son la tabla `categorias` de
-- más abajo, tal como se definió en la especificación.
-- ============================================================

do $$ begin
  create type public.rol_usuario as enum ('administrador','editor');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.entidad_categoria as enum
    ('lugar','actividad','gastronomia','hotel','restaurante','evento');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.nivel_dificultad as enum ('facil','media','dificil');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.entidad_resenable as enum ('lugar','hotel','restaurante','actividad');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.estado_moderacion as enum ('pendiente','aprobada','rechazada');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.tipo_contacto_emergencia as enum
    ('salud','policia','bomberos','defensoria','otro');
exception when duplicate_object then null; end $$;


-- ============================================================
-- 2. FUNCIÓN UTILITARIA: updated_at automático
-- ============================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;


-- ============================================================
-- 3. USUARIOS (perfiles del panel de administración)
-- 1 fila por cada usuario de Supabase Auth que administra la app.
-- El turista NO necesita cuenta; esta tabla es solo para
-- administrador/editor, como se definió en la especificación.
-- ============================================================

create table if not exists public.usuarios (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre text not null check (char_length(nombre) between 2 and 80),
  correo text not null check (correo ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  rol rol_usuario not null default 'editor',
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.usuarios is 'Perfiles del panel de administración (administrador / editor).';

create or replace trigger trg_usuarios_updated_at
before update on public.usuarios
for each row execute function public.set_updated_at();

-- Crea automáticamente el perfil cuando se invita/crea un usuario en Supabase Auth.
-- El rol por defecto es 'editor'; para dar el rol 'administrador' hay que
-- actualizarlo manualmente una vez (ver ejemplo de UPDATE al final del script).
create or replace function public.fn_crear_perfil_usuario()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.usuarios (id, nombre, correo, rol)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nombre', split_part(new.email, '@', 1)),
    new.email,
    'editor'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create or replace trigger on_auth_user_created
after insert on auth.users
for each row execute function public.fn_crear_perfil_usuario();

-- Evita que un editor se autoasigne el rol de administrador DESDE LA APP.
-- auth.uid() solo existe cuando la petición viene de la app (con sesión);
-- si es null, el cambio se está haciendo directo en el SQL Editor de
-- Supabase (por ejemplo, para nombrar al primer administrador), así que
-- se permite: solo tú tienes acceso a ese SQL Editor.
create or replace function public.fn_bloquear_cambio_rol()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.rol <> old.rol and auth.uid() is not null and not public.es_administrador() then
    raise exception 'Solo un administrador puede cambiar roles de usuario.';
  end if;
  return new;
end;
$$;

-- (el trigger se crea más abajo, después de definir es_administrador())


-- ============================================================
-- 4. FUNCIONES DE ROL (para usar en las políticas RLS)
-- security definer + search_path fijo: evita el problema clásico
-- de que la política de "usuarios" se vuelva recursiva sobre sí misma.
-- ============================================================

create or replace function public.es_admin_o_editor()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.usuarios u
    where u.id = auth.uid() and u.rol in ('administrador','editor') and u.activo
  );
$$;

create or replace function public.es_administrador()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.usuarios u
    where u.id = auth.uid() and u.rol = 'administrador' and u.activo
  );
$$;

drop trigger if exists trg_usuarios_bloquear_rol on public.usuarios;
create or replace trigger trg_usuarios_bloquear_rol
before update of rol on public.usuarios
for each row execute function public.fn_bloquear_cambio_rol();

alter table public.usuarios enable row level security;

drop policy if exists "usuarios_select" on public.usuarios;
create policy "usuarios_select"
on public.usuarios for select
to authenticated
using (id = auth.uid() or public.es_administrador());

drop policy if exists "usuarios_update" on public.usuarios;
create policy "usuarios_update"
on public.usuarios for update
to authenticated
using (id = auth.uid() or public.es_administrador())
with check (id = auth.uid() or public.es_administrador());

grant select, update on table public.usuarios to authenticated;


-- ============================================================
-- 5. CATEGORÍAS (tabla maestra, editable desde el panel)
-- Reemplaza los "tipo" fijos de cada módulo: el admin agrega o
-- renombra categorías sin que un desarrollador toque código.
-- ============================================================

create table if not exists public.categorias (
  id uuid primary key default gen_random_uuid(),
  entidad entidad_categoria not null,
  nombre text not null check (char_length(nombre) between 2 and 60),
  icono text,
  orden smallint not null default 0,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  unique (entidad, nombre)
);
comment on table public.categorias is 'Tipos configurables por módulo (natural, arqueológico, hotel, hostal, etc.).';

create index if not exists idx_categorias_entidad on public.categorias (entidad) where activo;

-- Valida que el categoria_id elegido en cada módulo pertenezca a ese
-- mismo módulo (ej.: que un "lugar" no reciba una categoría de "hotel").
create or replace function public.fn_validar_categoria()
returns trigger
language plpgsql
as $$
declare
  v_entidad_esperada entidad_categoria := TG_ARGV[0]::entidad_categoria;
  v_ok boolean;
begin
  if new.categoria_id is null then
    return new;
  end if;
  select exists (
    select 1 from public.categorias c
    where c.id = new.categoria_id and c.entidad = v_entidad_esperada
  ) into v_ok;
  if not v_ok then
    raise exception 'La categoría % no corresponde al módulo "%"', new.categoria_id, v_entidad_esperada;
  end if;
  return new;
end;
$$;

alter table public.categorias enable row level security;

drop policy if exists "categorias_select_publico" on public.categorias;
create policy "categorias_select_publico"
on public.categorias for select
to anon, authenticated
using (activo);

drop policy if exists "categorias_insert_admin" on public.categorias;
create policy "categorias_insert_admin"
on public.categorias for insert
to authenticated
with check (public.es_admin_o_editor());

drop policy if exists "categorias_update_admin" on public.categorias;
create policy "categorias_update_admin"
on public.categorias for update
to authenticated
using (public.es_admin_o_editor())
with check (public.es_admin_o_editor());

grant select on table public.categorias to anon, authenticated;
grant insert, update on table public.categorias to authenticated;


-- ============================================================
-- 6. MUNICIPIO (registro único / singleton)
-- El "id smallint = 1" es el truco estándar para que la tabla
-- nunca tenga más de una fila.
-- ============================================================

create table if not exists public.municipio (
  id smallint primary key default 1 check (id = 1),
  nombre text not null default 'Comarapa',
  descripcion text not null default '',
  imagenes text[] not null default '{}',
  latitud double precision check (latitud between -90 and 90),
  longitud double precision check (longitud between -180 and 180),
  poblacion integer,
  altitud_msnm integer,
  clima text,
  telefono_contacto text,
  sitio_web text,
  redes_sociales jsonb not null default '{}',
  updated_at timestamptz not null default now()
);
comment on table public.municipio is 'Información general del municipio (una sola fila).';

create or replace trigger trg_municipio_updated_at
before update on public.municipio
for each row execute function public.set_updated_at();

alter table public.municipio enable row level security;

drop policy if exists "municipio_select_publico" on public.municipio;
create policy "municipio_select_publico"
on public.municipio for select
to anon, authenticated
using (true);

drop policy if exists "municipio_update_admin" on public.municipio;
create policy "municipio_update_admin"
on public.municipio for update
to authenticated
using (public.es_admin_o_editor())
with check (public.es_admin_o_editor());

drop policy if exists "municipio_insert_admin" on public.municipio;
create policy "municipio_insert_admin"
on public.municipio for insert
to authenticated
with check (public.es_admin_o_editor());

grant select on table public.municipio to anon, authenticated;
grant insert, update on table public.municipio to authenticated;

insert into public.municipio (id, nombre)
values (1, 'Comarapa')
on conflict (id) do nothing;


-- ============================================================
-- 7. LUGARES TURÍSTICOS
-- ============================================================

create table if not exists public.lugares (
  id uuid primary key default gen_random_uuid(),
  categoria_id uuid references public.categorias(id) on delete set null,
  nombre text not null check (char_length(nombre) between 3 and 120),
  descripcion text not null default '',
  imagenes text[] not null default '{}',
  latitud double precision check (latitud between -90 and 90),
  longitud double precision check (longitud between -180 and 180),
  direccion_referencia text,
  dificultad nivel_dificultad not null default 'facil',
  tiempo_visita_min integer check (tiempo_visita_min >= 0),
  costo_entrada numeric(8,2) not null default 0 check (costo_entrada >= 0),
  mejor_epoca text,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.lugares is 'Lugares turísticos (naturales, arqueológicos, aventura, miradores...).';

create index if not exists idx_lugares_categoria on public.lugares (categoria_id);
create index if not exists idx_lugares_activos on public.lugares (created_at desc) where activo;
create index if not exists idx_lugares_nombre_trgm on public.lugares using gin (nombre gin_trgm_ops);
create index if not exists idx_lugares_geo on public.lugares (latitud, longitud);

create or replace trigger trg_lugares_updated_at
before update on public.lugares
for each row execute function public.set_updated_at();

create or replace trigger trg_lugares_categoria
before insert or update of categoria_id on public.lugares
for each row execute function public.fn_validar_categoria('lugar');

alter table public.lugares enable row level security;

drop policy if exists "lugares_select_publico" on public.lugares;
create policy "lugares_select_publico"
on public.lugares for select
to anon, authenticated
using (activo or public.es_admin_o_editor());

drop policy if exists "lugares_insert_admin" on public.lugares;
create policy "lugares_insert_admin"
on public.lugares for insert
to authenticated
with check (public.es_admin_o_editor());

drop policy if exists "lugares_update_admin" on public.lugares;
create policy "lugares_update_admin"
on public.lugares for update
to authenticated
using (public.es_admin_o_editor())
with check (public.es_admin_o_editor());

grant select on table public.lugares to anon, authenticated;
grant insert, update on table public.lugares to authenticated;
-- (sin GRANT delete: el borrado siempre es lógico, vía columna "activo")


-- ============================================================
-- 8. HOTELES
-- ============================================================

create table if not exists public.hoteles (
  id uuid primary key default gen_random_uuid(),
  categoria_id uuid references public.categorias(id) on delete set null, -- hotel / hostal / cabaña / camping
  nombre text not null check (char_length(nombre) between 3 and 120),
  descripcion text not null default '',
  imagenes text[] not null default '{}',
  latitud double precision check (latitud between -90 and 90),
  longitud double precision check (longitud between -180 and 180),
  direccion_referencia text,
  precio_min numeric(8,2) check (precio_min >= 0),
  precio_max numeric(8,2) check (precio_max >= precio_min),
  servicios text[] not null default '{}',
  contacto_reservas text,
  calificacion_promedio numeric(2,1) not null default 0 check (calificacion_promedio between 0 and 5),
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.hoteles is 'Hospedaje: hoteles, hostales, cabañas, camping.';

create index if not exists idx_hoteles_categoria on public.hoteles (categoria_id);
create index if not exists idx_hoteles_activos on public.hoteles (created_at desc) where activo;
create index if not exists idx_hoteles_nombre_trgm on public.hoteles using gin (nombre gin_trgm_ops);

create or replace trigger trg_hoteles_updated_at
before update on public.hoteles
for each row execute function public.set_updated_at();

create or replace trigger trg_hoteles_categoria
before insert or update of categoria_id on public.hoteles
for each row execute function public.fn_validar_categoria('hotel');

alter table public.hoteles enable row level security;

drop policy if exists "hoteles_select_publico" on public.hoteles;
create policy "hoteles_select_publico"
on public.hoteles for select
to anon, authenticated
using (activo or public.es_admin_o_editor());

drop policy if exists "hoteles_insert_admin" on public.hoteles;
create policy "hoteles_insert_admin"
on public.hoteles for insert
to authenticated
with check (public.es_admin_o_editor());

drop policy if exists "hoteles_update_admin" on public.hoteles;
create policy "hoteles_update_admin"
on public.hoteles for update
to authenticated
using (public.es_admin_o_editor())
with check (public.es_admin_o_editor());

grant select on table public.hoteles to anon, authenticated;
grant insert, update on table public.hoteles to authenticated;


-- ============================================================
-- 9. RESTAURANTES
-- ============================================================

create table if not exists public.restaurantes (
  id uuid primary key default gen_random_uuid(),
  categoria_id uuid references public.categorias(id) on delete set null, -- tipo de comida
  nombre text not null check (char_length(nombre) between 3 and 120),
  descripcion text not null default '',
  imagenes text[] not null default '{}',
  latitud double precision check (latitud between -90 and 90),
  longitud double precision check (longitud between -180 and 180),
  direccion_referencia text,
  horario_atencion text,
  precio_referencial numeric(8,2) check (precio_referencial >= 0),
  contacto text,
  calificacion_promedio numeric(2,1) not null default 0 check (calificacion_promedio between 0 and 5),
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.restaurantes is 'Restaurantes del municipio.';

create index if not exists idx_restaurantes_categoria on public.restaurantes (categoria_id);
create index if not exists idx_restaurantes_activos on public.restaurantes (created_at desc) where activo;
create index if not exists idx_restaurantes_nombre_trgm on public.restaurantes using gin (nombre gin_trgm_ops);

create or replace trigger trg_restaurantes_updated_at
before update on public.restaurantes
for each row execute function public.set_updated_at();

create or replace trigger trg_restaurantes_categoria
before insert or update of categoria_id on public.restaurantes
for each row execute function public.fn_validar_categoria('restaurante');

alter table public.restaurantes enable row level security;

drop policy if exists "restaurantes_select_publico" on public.restaurantes;
create policy "restaurantes_select_publico"
on public.restaurantes for select
to anon, authenticated
using (activo or public.es_admin_o_editor());

drop policy if exists "restaurantes_insert_admin" on public.restaurantes;
create policy "restaurantes_insert_admin"
on public.restaurantes for insert
to authenticated
with check (public.es_admin_o_editor());

drop policy if exists "restaurantes_update_admin" on public.restaurantes;
create policy "restaurantes_update_admin"
on public.restaurantes for update
to authenticated
using (public.es_admin_o_editor())
with check (public.es_admin_o_editor());

grant select on table public.restaurantes to anon, authenticated;
grant insert, update on table public.restaurantes to authenticated;


-- ============================================================
-- 10. ACTIVIDADES
-- ============================================================

create table if not exists public.actividades (
  id uuid primary key default gen_random_uuid(),
  categoria_id uuid references public.categorias(id) on delete set null,
  nombre text not null check (char_length(nombre) between 3 and 120),
  descripcion text not null default '',
  imagenes text[] not null default '{}',
  latitud double precision check (latitud between -90 and 90),
  longitud double precision check (longitud between -180 and 180),
  dificultad nivel_dificultad not null default 'facil',
  duracion_min integer check (duracion_min >= 0),
  precio_referencial numeric(8,2) check (precio_referencial >= 0),
  operador_contacto text,
  capacidad_maxima smallint check (capacidad_maxima > 0),
  temporada text,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.actividades is 'Actividades turísticas: senderismo, cabalgatas, agroturismo, etc.';

create index if not exists idx_actividades_categoria on public.actividades (categoria_id);
create index if not exists idx_actividades_activas on public.actividades (created_at desc) where activo;
create index if not exists idx_actividades_nombre_trgm on public.actividades using gin (nombre gin_trgm_ops);

create or replace trigger trg_actividades_updated_at
before update on public.actividades
for each row execute function public.set_updated_at();

create or replace trigger trg_actividades_categoria
before insert or update of categoria_id on public.actividades
for each row execute function public.fn_validar_categoria('actividad');

alter table public.actividades enable row level security;

drop policy if exists "actividades_select_publico" on public.actividades;
create policy "actividades_select_publico"
on public.actividades for select
to anon, authenticated
using (activo or public.es_admin_o_editor());

drop policy if exists "actividades_insert_admin" on public.actividades;
create policy "actividades_insert_admin"
on public.actividades for insert
to authenticated
with check (public.es_admin_o_editor());

drop policy if exists "actividades_update_admin" on public.actividades;
create policy "actividades_update_admin"
on public.actividades for update
to authenticated
using (public.es_admin_o_editor())
with check (public.es_admin_o_editor());

grant select on table public.actividades to anon, authenticated;
grant insert, update on table public.actividades to authenticated;


-- ============================================================
-- 11. GASTRONOMÍA
-- ============================================================

create table if not exists public.gastronomia (
  id uuid primary key default gen_random_uuid(),
  categoria_id uuid references public.categorias(id) on delete set null, -- plato / bebida / producto
  restaurante_id uuid references public.restaurantes(id) on delete set null, -- "dónde encontrarlo" (opcional)
  nombre text not null check (char_length(nombre) between 3 and 120),
  descripcion text not null default '',
  imagenes text[] not null default '{}',
  temporada text,
  precio_referencial numeric(8,2) check (precio_referencial >= 0),
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.gastronomia is 'Platos, bebidas y productos típicos (ej. derivados del durazno).';

create index if not exists idx_gastronomia_categoria on public.gastronomia (categoria_id);
create index if not exists idx_gastronomia_restaurante on public.gastronomia (restaurante_id);
create index if not exists idx_gastronomia_activos on public.gastronomia (created_at desc) where activo;

create or replace trigger trg_gastronomia_updated_at
before update on public.gastronomia
for each row execute function public.set_updated_at();

create or replace trigger trg_gastronomia_categoria
before insert or update of categoria_id on public.gastronomia
for each row execute function public.fn_validar_categoria('gastronomia');

alter table public.gastronomia enable row level security;

drop policy if exists "gastronomia_select_publico" on public.gastronomia;
create policy "gastronomia_select_publico"
on public.gastronomia for select
to anon, authenticated
using (activo or public.es_admin_o_editor());

drop policy if exists "gastronomia_insert_admin" on public.gastronomia;
create policy "gastronomia_insert_admin"
on public.gastronomia for insert
to authenticated
with check (public.es_admin_o_editor());

drop policy if exists "gastronomia_update_admin" on public.gastronomia;
create policy "gastronomia_update_admin"
on public.gastronomia for update
to authenticated
using (public.es_admin_o_editor())
with check (public.es_admin_o_editor());

grant select on table public.gastronomia to anon, authenticated;
grant insert, update on table public.gastronomia to authenticated;


-- ============================================================
-- 12. EVENTOS Y FERIAS
-- ============================================================

create table if not exists public.eventos (
  id uuid primary key default gen_random_uuid(),
  categoria_id uuid references public.categorias(id) on delete set null, -- feria / fiesta patronal / cultural...
  nombre text not null check (char_length(nombre) between 3 and 120),
  descripcion text not null default '',
  imagenes text[] not null default '{}',
  latitud double precision check (latitud between -90 and 90),
  longitud double precision check (longitud between -180 and 180),
  fecha_inicio timestamptz not null,
  fecha_fin timestamptz check (fecha_fin >= fecha_inicio),
  periodicidad text, -- ej. 'anual', 'único'
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.eventos is 'Eventos y ferias del municipio (ej. Feria del Durazno).';

create index if not exists idx_eventos_categoria on public.eventos (categoria_id);
create index if not exists idx_eventos_fecha on public.eventos (fecha_inicio) where activo;

create or replace trigger trg_eventos_updated_at
before update on public.eventos
for each row execute function public.set_updated_at();

create or replace trigger trg_eventos_categoria
before insert or update of categoria_id on public.eventos
for each row execute function public.fn_validar_categoria('evento');

alter table public.eventos enable row level security;

drop policy if exists "eventos_select_publico" on public.eventos;
create policy "eventos_select_publico"
on public.eventos for select
to anon, authenticated
using (activo or public.es_admin_o_editor());

drop policy if exists "eventos_insert_admin" on public.eventos;
create policy "eventos_insert_admin"
on public.eventos for insert
to authenticated
with check (public.es_admin_o_editor());

drop policy if exists "eventos_update_admin" on public.eventos;
create policy "eventos_update_admin"
on public.eventos for update
to authenticated
using (public.es_admin_o_editor())
with check (public.es_admin_o_editor());

grant select on table public.eventos to anon, authenticated;
grant insert, update on table public.eventos to authenticated;


-- ============================================================
-- 13. RUTAS E ITINERARIOS (combinan lugares + actividades)
-- ============================================================

create table if not exists public.rutas (
  id uuid primary key default gen_random_uuid(),
  nombre text not null check (char_length(nombre) between 3 and 120),
  descripcion text not null default '',
  imagenes text[] not null default '{}',
  dificultad nivel_dificultad not null default 'facil',
  duracion_total_min integer check (duracion_total_min >= 0),
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.rutas is 'Itinerarios sugeridos que combinan lugares y actividades.';

create or replace trigger trg_rutas_updated_at
before update on public.rutas
for each row execute function public.set_updated_at();

create table if not exists public.rutas_lugares (
  ruta_id uuid not null references public.rutas(id) on delete cascade,
  lugar_id uuid not null references public.lugares(id) on delete cascade,
  orden smallint not null default 0,
  primary key (ruta_id, lugar_id)
);
create index if not exists idx_rutas_lugares_lugar on public.rutas_lugares (lugar_id);

create table if not exists public.rutas_actividades (
  ruta_id uuid not null references public.rutas(id) on delete cascade,
  actividad_id uuid not null references public.actividades(id) on delete cascade,
  orden smallint not null default 0,
  primary key (ruta_id, actividad_id)
);
create index if not exists idx_rutas_actividades_actividad on public.rutas_actividades (actividad_id);

alter table public.rutas enable row level security;
alter table public.rutas_lugares enable row level security;
alter table public.rutas_actividades enable row level security;

drop policy if exists "rutas_select_publico" on public.rutas;
create policy "rutas_select_publico"
on public.rutas for select
to anon, authenticated
using (activo or public.es_admin_o_editor());

drop policy if exists "rutas_insert_admin" on public.rutas;
create policy "rutas_insert_admin"
on public.rutas for insert
to authenticated
with check (public.es_admin_o_editor());

drop policy if exists "rutas_update_admin" on public.rutas;
create policy "rutas_update_admin"
on public.rutas for update
to authenticated
using (public.es_admin_o_editor())
with check (public.es_admin_o_editor());

drop policy if exists "rutas_lugares_select" on public.rutas_lugares;
create policy "rutas_lugares_select"
on public.rutas_lugares for select
to anon, authenticated
using (true);

drop policy if exists "rutas_lugares_write_admin" on public.rutas_lugares;
create policy "rutas_lugares_write_admin"
on public.rutas_lugares for all
to authenticated
using (public.es_admin_o_editor())
with check (public.es_admin_o_editor());

drop policy if exists "rutas_actividades_select" on public.rutas_actividades;
create policy "rutas_actividades_select"
on public.rutas_actividades for select
to anon, authenticated
using (true);

drop policy if exists "rutas_actividades_write_admin" on public.rutas_actividades;
create policy "rutas_actividades_write_admin"
on public.rutas_actividades for all
to authenticated
using (public.es_admin_o_editor())
with check (public.es_admin_o_editor());

grant select on table public.rutas to anon, authenticated;
grant insert, update on table public.rutas to authenticated;
grant select on table public.rutas_lugares to anon, authenticated;
grant insert, update, delete on table public.rutas_lugares to authenticated;
grant select on table public.rutas_actividades to anon, authenticated;
grant insert, update, delete on table public.rutas_actividades to authenticated;


-- ============================================================
-- 14. RESEÑAS Y CALIFICACIONES
-- No requieren cuenta de usuario (el turista no inicia sesión).
-- `entidad` + `entidad_id` es una asociación polimórfica: la
-- integridad ("ese lugar_id realmente existe") se valida en la
-- app, no con una FK de base de datos, porque una reseña puede
-- apuntar a lugares, hoteles, restaurantes o actividades.
-- ============================================================

create table if not exists public.resenas (
  id uuid primary key default gen_random_uuid(),
  entidad entidad_resenable not null,
  entidad_id uuid not null,
  autor_nombre text not null check (char_length(autor_nombre) between 2 and 80),
  calificacion smallint not null check (calificacion between 1 and 5),
  comentario text,
  estado_moderacion estado_moderacion not null default 'pendiente',
  created_at timestamptz not null default now()
);
comment on table public.resenas is 'Reseñas públicas sobre lugares, hoteles, restaurantes o actividades.';

create index if not exists idx_resenas_entidad on public.resenas (entidad, entidad_id);
create index if not exists idx_resenas_moderacion on public.resenas (estado_moderacion);

alter table public.resenas enable row level security;

drop policy if exists "resenas_select_aprobadas" on public.resenas;
create policy "resenas_select_aprobadas"
on public.resenas for select
to anon, authenticated
using (estado_moderacion = 'aprobada' or public.es_admin_o_editor());

drop policy if exists "resenas_insert_publico" on public.resenas;
create policy "resenas_insert_publico"
on public.resenas for insert
to anon, authenticated
with check (estado_moderacion = 'pendiente');

drop policy if exists "resenas_moderar_admin" on public.resenas;
create policy "resenas_moderar_admin"
on public.resenas for update
to authenticated
using (public.es_admin_o_editor())
with check (public.es_admin_o_editor());

grant select, insert on table public.resenas to anon, authenticated;
grant update on table public.resenas to authenticated;


-- ============================================================
-- 15. CONTACTOS DE EMERGENCIA
-- ============================================================

create table if not exists public.contactos_emergencia (
  id uuid primary key default gen_random_uuid(),
  nombre text not null check (char_length(nombre) between 3 and 120),
  tipo tipo_contacto_emergencia not null default 'otro',
  telefono text not null,
  latitud double precision check (latitud between -90 and 90),
  longitud double precision check (longitud between -180 and 180),
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.contactos_emergencia is 'Hospital, policía, bomberos, defensoría, etc.';

create index if not exists idx_contactos_tipo on public.contactos_emergencia (tipo) where activo;

create or replace trigger trg_contactos_updated_at
before update on public.contactos_emergencia
for each row execute function public.set_updated_at();

alter table public.contactos_emergencia enable row level security;

drop policy if exists "contactos_select_publico" on public.contactos_emergencia;
create policy "contactos_select_publico"
on public.contactos_emergencia for select
to anon, authenticated
using (activo or public.es_admin_o_editor());

drop policy if exists "contactos_insert_admin" on public.contactos_emergencia;
create policy "contactos_insert_admin"
on public.contactos_emergencia for insert
to authenticated
with check (public.es_admin_o_editor());

drop policy if exists "contactos_update_admin" on public.contactos_emergencia;
create policy "contactos_update_admin"
on public.contactos_emergencia for update
to authenticated
using (public.es_admin_o_editor())
with check (public.es_admin_o_editor());

grant select on table public.contactos_emergencia to anon, authenticated;
grant insert, update on table public.contactos_emergencia to authenticated;


-- ============================================================
-- 16. STORAGE (imágenes)
-- Un solo bucket público de lectura; solo administrador/editor
-- puede subir, reemplazar o borrar archivos. Organiza tus imágenes
-- en carpetas dentro del bucket, ej: lugares/, hoteles/, eventos/.
-- ============================================================

insert into storage.buckets (id, name, public)
values ('comarapa-imagenes', 'comarapa-imagenes', true)
on conflict (id) do nothing;

drop policy if exists "imagenes_lectura_publica" on storage.objects;
create policy "imagenes_lectura_publica"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'comarapa-imagenes');

drop policy if exists "imagenes_subir_admin" on storage.objects;
create policy "imagenes_subir_admin"
on storage.objects for insert
to authenticated
with check (bucket_id = 'comarapa-imagenes' and public.es_admin_o_editor());

drop policy if exists "imagenes_actualizar_admin" on storage.objects;
create policy "imagenes_actualizar_admin"
on storage.objects for update
to authenticated
using (bucket_id = 'comarapa-imagenes' and public.es_admin_o_editor());

drop policy if exists "imagenes_eliminar_admin" on storage.objects;
create policy "imagenes_eliminar_admin"
on storage.objects for delete
to authenticated
using (bucket_id = 'comarapa-imagenes' and public.es_admin_o_editor());


-- ============================================================
-- 17. PARA CREAR TU PRIMER ADMINISTRADOR
-- 1) Crea el usuario desde Authentication > Users en Supabase
--    (o que se registre él mismo); esto ya crea su fila en
--    public.usuarios con rol 'editor' automáticamente.
-- 2) Súbelo a administrador con esta consulta (cambia el correo):
--
-- update public.usuarios set rol = 'administrador'
-- where correo = 'admin@comarapa.gob.bo';
-- ============================================================


-- ============================================================
-- 18. VERIFICACIÓN RÁPIDA DEL ESQUEMA
-- ============================================================

select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;

select tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
order by tablename, policyname;
