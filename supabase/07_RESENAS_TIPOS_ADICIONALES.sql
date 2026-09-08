-- ============================================================
-- 07. RESEÑAS: HABILITAR EVENTOS Y GASTRONOMÍA
-- El enum entidad_resenable solo incluía 'lugar', 'hotel',
-- 'restaurante' y 'actividad'. Este script agrega 'evento' y
-- 'gastronomia' para poder guardar reseñas también de esos dos
-- módulos. No afecta las reseñas existentes.
-- Ejecutar una sola vez en el SQL Editor de Supabase.
-- ============================================================

alter type public.entidad_resenable add value if not exists 'evento';
alter type public.entidad_resenable add value if not exists 'gastronomia';
