-- ============================================================
-- DIAGNÓSTICO: "new row violates row-level security policy for
-- table 'lugares'" al guardar desde el panel de administración.
--
-- Causa habitual: tu cuenta de auth.users no tiene fila en
-- public.usuarios (o quedó con activo=false), así que
-- es_admin_o_editor() devuelve false y el INSERT/UPDATE se
-- rechaza. Corre estas consultas en orden.
-- ============================================================

-- 1) ¿Qué usuarios de Auth existen y cuáles tienen perfil en usuarios?
select
  au.id,
  au.email,
  u.correo,
  u.rol,
  u.activo,
  (u.id is null) as le_falta_perfil
from auth.users au
left join public.usuarios u on u.id = au.id
order by au.created_at desc;

-- Si tu correo aparece con le_falta_perfil = true, o con
-- activo = false, sigue con el paso 2.


-- 2) Backfill: crea el perfil que falte para cualquier usuario
-- de Auth existente (rol por defecto 'editor').
insert into public.usuarios (id, nombre, correo, rol)
select
  au.id,
  coalesce(au.raw_user_meta_data->>'nombre', split_part(au.email, '@', 1)),
  au.email,
  'editor'
from auth.users au
left join public.usuarios u on u.id = au.id
where u.id is null;

-- Si el perfil ya existía pero estaba inactivo, reactívalo:
update public.usuarios set activo = true where correo = 'TU_CORREO_AQUI';


-- 3) Súbete a administrador (opcional, pero recomendado para el
-- primer usuario, porque un 'editor' también puede crear/editar
-- contenido, solo que no gestiona roles de otros usuarios):
update public.usuarios set rol = 'administrador'
where correo = 'TU_CORREO_AQUI';


-- 4) Verifica que quedó bien:
select id, correo, rol, activo from public.usuarios;
