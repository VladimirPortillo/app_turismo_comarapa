-- ============================================================
-- 10. PERMISOS: CAMBIO DE ROL Y BORRADO FÍSICO -> HTTP 403
-- Motor: PostgreSQL (Supabase) · Ejecutar completo en SQL Editor
--
-- Antes, cuando un editor intentaba cambiarse el rol, el trigger
-- lanzaba un error genérico y la API REST respondía 400. Con el
-- errcode 42501 (insufficient_privilege) la API responde 403
-- Forbidden, que es lo correcto para "no tienes permiso".
-- ============================================================

create or replace function public.fn_bloquear_cambio_rol()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.rol <> old.rol and auth.uid() is not null and not public.es_administrador() then
    -- errcode 42501 (insufficient_privilege): la API REST responde 403.
    raise exception 'Solo un administrador puede cambiar roles de usuario.'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

-- ============================================================
-- SIN BORRADO FÍSICO -> HTTP 401 (anónimo) / 403 (editor)
-- Supabase otorga por defecto DELETE a anon/authenticated en las
-- tablas de public; la RLS filtraba las filas pero la API respondía
-- 204 sin error. Quitando el permiso, la API responde 401 al anónimo
-- y 403 al usuario con sesión. El borrado es lógico (columna "activo").
-- ============================================================

revoke delete, truncate on table
  public.usuarios, public.categorias, public.lugares,
  public.hoteles, public.restaurantes, public.actividades,
  public.gastronomia, public.eventos, public.resenas
from anon, authenticated;
