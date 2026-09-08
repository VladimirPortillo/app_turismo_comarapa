-- ============================================================
-- 06. RESEÑAS: AUTO-APROBACIÓN
-- Por defecto la tabla public.resenas exige que toda reseña nueva
-- entre como 'pendiente' (para moderarla antes de publicarla). Este
-- script cambia esa política para que las reseñas se publiquen de
-- inmediato: solo permite insertar filas que ya vengan marcadas como
-- 'aprobada' (la app siempre inserta así). No se toca la política de
-- lectura, que ya muestra únicamente las 'aprobada'.
-- Ejecutar una sola vez en el SQL Editor de Supabase.
-- ============================================================

drop policy if exists "resenas_insert_publico" on public.resenas;
create policy "resenas_insert_publico"
on public.resenas for insert
to anon, authenticated
with check (estado_moderacion = 'aprobada');
