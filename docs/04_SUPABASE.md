# Supabase

Si ya hiciste la Sesion 1:
ejecuta `supabase/02_MIGRACION_SESION2_CONTEXTO.sql`.

Si partes de cero:
1. `01_SCHEMA_BASE_SESION1.sql`
2. `02_MIGRACION_SESION2_CONTEXTO.sql`
3. `03_VERIFICAR.sql`

Configura:
- Project URL
- Publishable Key

Nunca:
- service_role
- secret key

## Módulo de turismo (Comarapa)

Ejecuta `supabase/04_SCHEMA_TURISMO_COMARAPA.sql` una sola vez en el SQL
Editor. Crea las tablas `usuarios`, `categorias`, `municipio`, `lugares`,
`hoteles`, `restaurantes`, `actividades`, `gastronomia`, `eventos`, `rutas`,
`resenas` y `contactos_emergencia`, con RLS (lectura pública de lo activo,
escritura solo para `administrador`/`editor`) y el bucket de imágenes
`comarapa-imagenes`. Es independiente de `registros_demo`: no la toca ni
depende de ella.

La app (MVP) ya consume Lugares, Actividades, Gastronomía y Hoteles vía
`lib/repositories/*_repository.dart`. El primer usuario que se registra
queda como `editor`; para subirlo a `administrador` corre la consulta que
está al final del script (sección 17).
