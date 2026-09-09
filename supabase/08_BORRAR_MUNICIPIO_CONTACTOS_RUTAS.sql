-- ============================================================
-- 08. BORRAR: municipio, contactos_emergencia y rutas
-- Elimina de forma permanente las tablas 'municipio',
-- 'contactos_emergencia' y el módulo de rutas ('rutas',
-- 'rutas_lugares', 'rutas_actividades'), que no llegaron a usarse
-- (rutas) o ya no se quieren mantener (municipio, contactos).
-- Se borra primero 'rutas_lugares'/'rutas_actividades' porque tienen
-- una llave foránea hacia 'rutas'.
-- Ejecutar una sola vez en el SQL Editor de Supabase. Esta acción
-- es irreversible: se pierden los datos que hubiera en esas tablas.
-- ============================================================

drop table if exists public.rutas_lugares;
drop table if exists public.rutas_actividades;
drop table if exists public.rutas;

drop table if exists public.municipio;

drop table if exists public.contactos_emergencia;
drop type if exists public.tipo_contacto_emergencia;
