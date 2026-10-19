-- ============================================================
-- 09. RUTA DE SALUD (health check) para monitoreo con UptimeRobot
-- Motor: PostgreSQL (Supabase) · Ejecutar completo en SQL Editor
--
-- Expone la función RPC "salud" que hace un SELECT 1 contra la base
-- de datos. Si la base responde, devuelve {"estado":"ok", ...}.
--
-- URL de la ruta (GET, sin sesión):
--   https://djawghloqotlyxetxbyv.supabase.co/rest/v1/rpc/salud?apikey=<SUPABASE_PUBLISHABLE_KEY>
-- ============================================================

create or replace function public.salud()
returns json
language sql
stable
set search_path = public
as $$
  select json_build_object(
    'estado', case when (select 1) = 1 then 'ok' else 'error' end,
    'servicio', 'comarapa-turismo',
    'base_datos', 'supabase-postgres',
    'hora_servidor', now()
  );
$$;

comment on function public.salud() is 'Health check: SELECT 1 contra la base de datos. Usado por UptimeRobot.';

-- Solo lectura y sin datos sensibles: la puede llamar cualquiera.
grant execute on function public.salud() to anon, authenticated;
