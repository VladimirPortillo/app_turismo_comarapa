-- ============================================================
-- 11 · Editar y eliminar categorías desde la app
-- ------------------------------------------------------------
-- En la app, "eliminar" una categoría NO la borra: la oculta
-- (activo = false). Así los lugares/hoteles/eventos que ya la
-- usaban la conservan, y la app solo deja de ofrecerla al elegir
-- (CategoriaRepository.fetchByEntidad filtra por activo = true).
--
-- Antes la política de lectura era `using (activo)`, por lo que
-- una categoría oculta desaparecía también de los listados
-- (el join `categorias(nombre)` devolvía null) y no se podía
-- reactivar al volver a crearla con el mismo nombre.
-- Ejecutar una vez en el SQL Editor de Supabase.
-- ============================================================

drop policy if exists "categorias_select_publico" on public.categorias;
create policy "categorias_select_publico"
on public.categorias for select
to anon, authenticated
using (true);
