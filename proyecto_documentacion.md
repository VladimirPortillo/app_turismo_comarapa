# Proyecto Final: Mejorar el Acceso a la Información Turística de Comarapa

Este documento contiene la información detallada del proyecto estructurada según los campos solicitados, obtenida directamente del análisis del código fuente, configuración de base de datos y scripts de compilación del proyecto.

---

### 1. Nombre del proyecto
**Mejorar el acceso a la información turística de Comarapa - Proyecto Final 360**

### 2. Descripción
Aplicación móvil e interactiva desarrollada en **Flutter** y conectada a **Supabase**, orientada a guiar y potenciar el turismo en el municipio de **Comarapa** (Bolivia). Permite a los usuarios explorar atractivos turísticos, actividades locales, gastronomía y hoteles, integrando además servicios de ubicación GPS en tiempo real y consulta del estado del clima mediante APIs externas (Open-Meteo). Adicionalmente, cuenta con un módulo administrativo protegido por autenticación para gestionar los atractivos del municipio en tiempo real.

### 3. Problema que resuelve
* **Descentralización de información**: Centraliza la oferta de atractivos, hoteles, gastronomía y actividades de Comarapa que actualmente se encuentra dispersa o desactualizada.
* **Falta de contexto geográfico y climatológico**: Provee la ubicación en tiempo real mediante GPS y mapas interactivos, junto con el clima actual del lugar para que los turistas tomen decisiones informadas antes y durante sus visitas.
* **Inestabilidad de conexión**: Incorpora un mecanismo de contingencia offline ("Plan B Offline") que permite visualizar datos críticos previamente almacenados localmente cuando no se dispone de señal de internet.
* **Gestión de la oferta turística**: Resuelve la dificultad de actualizar la información de forma dinámica, proveyendo al personal administrativo de una interfaz gráfica (CRUD) conectada directamente a una base de datos en la nube.

### 4. Funcionalidades principales
* **Exploración de Atractivos y Servicios**: Clasificación y navegación de lugares turísticos, hoteles, gastronomía y actividades locales organizados por categorías.
* **Geolocalización y Mapas Interactivos**: Integración de mapas visuales basados en OpenStreetMap para ubicar geográficamente los atractivos y mostrar la posición actual del usuario mediante GPS nativo.
* **Clima en Tiempo Real**: Consulta dinámica de temperatura y estado del tiempo en la ubicación actual mediante el consumo de la API REST de Open-Meteo, con opciones de prueba fija (Tarija) y simulación de errores controlados.
* **Panel de Administración (CRUD)**: Módulo seguro de gestión para crear, editar, listar y desactivar lugares turísticos en tiempo real con sincronización inmediata con Supabase.
* **Autenticación de Usuarios**: Control de acceso robusto mediante Supabase Auth para diferenciar entre usuarios visitantes y administradores.
* **Persistencia y Modo Offline**: Soporte de almacenamiento de preferencias locales (modo oscuro, admin habilitado) y datos en caché para casos de desconexión mediante `shared_preferences`.

### 5. Tecnologías utilizadas
* **Flutter (SDK >= 3.35.0) / Dart (SDK >= 3.9.0 < 4.0.0)**: Framework principal para la UI y la lógica de negocio multiplataforma.
* **Supabase (BaaS)**: 
  * *Autenticación*: Control de acceso seguro y perfiles de usuario.
  * *Base de Datos (PostgreSQL)*: Persistencia de datos de lugares, categorías, perfiles y bitácoras en tiempo real.
* **Dependencias Clave (declaradas en `pubspec.yaml`)**:
  * `provider` (v6.1.5+1): Gestión del estado y de la inyección de dependencias.
  * `shared_preferences` (v2.5.5): Almacenamiento local para configuración y Plan B offline.
  * `http` (v1.6.0): Peticiones HTTP a la API REST de Open-Meteo.
  * `geolocator` (v14.0.3): Acceso a sensores nativos de geolocalización / GPS.
  * `flutter_map` (v8.3.2) & `latlong2` (v0.10.1): Renderizado de mapas interactivos.

### 6. Requisitos
* **Desarrollo**:
  * Flutter SDK instalado (versión compatible con `>= 3.35.0`).
  * Dart SDK.
  * Editor de código (VS Code, Android Studio, etc.) con plugins de Flutter.
* **Base de Datos**:
  * Proyecto activo en Supabase.
* **Ejecución**:
  * Dispositivo móvil físico o emulador Android (con Google APIs, nivel de API mínimo 21).
  * Navegador web Google Chrome (para pruebas rápidas en web).

### 7. Instalación
Sigue estos pasos para instalar y preparar el entorno de desarrollo:

#### En Windows:
1. Extrae o clona el proyecto en una ruta corta y sin espacios, por ejemplo: `C:\flutter_aula\PROYECTO_FINAL_360_SESION2_FINAL`.
2. Abre la terminal (PowerShell o CMD) en la raíz del proyecto.
3. Ejecuta el script de preparación inicial:
   ```cmd
   scripts\00_PREPARAR_WINDOWS.bat
   ```
   *(Este script descargará las dependencias con `flutter pub get`, regenerará las carpetas nativas `android` y `web` utilizando un seed y aplicará el manifiesto de Android correspondiente).*

#### En Linux (MX Linux u otros):
1. Extrae el proyecto dentro de tu directorio `HOME` (ej. `/home/usuario/proyecto_final`).
2. Concede permisos de ejecución a los scripts:
   ```bash
   chmod +x scripts/*.sh
   ```
3. Ejecuta el script de preparación:
   ```bash
   ./scripts/00_PREPARAR_LINUX.sh
   ```

### 8. Configuración
Para conectar la aplicación con tu backend en la nube, realiza las siguientes configuraciones:

#### A. Inicializar la Base de Datos (Supabase)
Ingresa al SQL Editor de tu panel de Supabase y ejecuta los archivos SQL del directorio `supabase/` en el orden indicado:
1. `01_SCHEMA_BASE_SESION1.sql`: Creación de la estructura de tablas inicial.
2. `02_MIGRACION_SESION2_CONTEXTO.sql`: Modificaciones para el registro del clima y GPS.
3. `04_SCHEMA_TURISMO_COMARAPA.sql`: Datos y registros específicos de turismo, categorías y gastronomía de Comarapa.
4. `05_DIAGNOSTICO_Y_FIX_USUARIOS.sql`: Configuración de roles, permisos RLS y usuarios.

#### B. Conectar la aplicación Flutter
1. Crea un archivo en la ruta `config/local.json` (esta ruta está declarada en los assets de `pubspec.yaml`).
2. Agrega la configuración de tu proyecto en formato JSON:
   ```json
   {
     "SUPABASE_URL": "https://tu-proyecto.supabase.co",
     "SUPABASE_PUBLISHABLE_KEY": "tu-anon-key-publica"
   }
   ```
   *Nota: Nunca utilices ni expongas la clave secreta `service_role` en la aplicación móvil de Flutter por razones de seguridad.*

### 9. Ejecución
Puedes ejecutar la aplicación directamente usando comandos de Flutter o a través de los scripts automatizados:

#### Usando Scripts de Menú:
* **En Windows**: Ejecuta `scripts\01_MENU_WINDOWS.bat`. Te mostrará un menú interactivo:
  * Opción `1`: Ejecutar en dispositivo conectado (Android / Emulador).
  * Opción `2`: Ejecutar en Google Chrome.
  * Opción `3`: Listar dispositivos disponibles.
* **En Linux**: Ejecuta `./scripts/01_MENU_LINUX.sh` desde la terminal.

#### Usando Comandos de Flutter:
```bash
# Ejecutar en el dispositivo predeterminado
flutter run

# Ejecutar específicamente en Google Chrome
flutter run -d chrome
```

### 10. Generación de APK
Para compilar la aplicación y generar el instalador para dispositivos Android, ejecuta los siguientes comandos en la terminal de la raíz del proyecto:

1. **Compilación de APK estándar (Release)**:
   ```bash
   flutter build apk --release
   ```
   *Este comando genera un único archivo APK universal.*

2. **Compilación optimizada (Split por arquitectura)**:
   ```bash
   flutter build apk --split-per-abi
   ```
   *Este comando divide la APK en múltiples archivos optimizados según el tipo de procesador del móvil (arm64, armeabi, x86_64), reduciendo significativamente el tamaño del instalador.*

3. **Ubicación del APK generado**:
   Una vez completada la compilación con éxito, encontrarás el archivo instalable en:
   `build/app/outputs/flutter-apk/app-release.apk` (o el nombre correspondiente si utilizaste `--split-per-abi`).

### 11. Estructura básica del proyecto
A continuación se detalla la organización de los directorios de código dentro del proyecto:
```
PROYECTO_FINAL_360_SESION2_FINAL/
├── config/                  # Configuración local (local.json con URLs del backend)
├── lib/                     # Directorio de código fuente principal de Flutter
│   ├── main.dart            # Inicializa la App, inyecta proveedores y controladores globales
│   ├── app.dart             # Widget base de navegación y punto de partida visual
│   ├── config/              # Gestión e inicialización de AppConfig
│   ├── controllers/         # Lógica de estados reactivos (ContextController, PreferencesController)
│   ├── models/              # Clases y modelos de mapeo de datos (Lugar, Actividad, Hotel, Clima)
│   ├── repositories/        # Gestión directa de datos locales y remotos (Supabase, CRUD)
│   ├── services/            # Servicios del sistema (Ubicación GPS, API Clima, SharedPreferences)
│   ├── screens/             # Vistas principales de la interfaz
│   │   ├── context/         # Módulo de geolocalización y clima interactivo (ContextLabScreen)
│   │   └── (otros screens)  # Pantallas de Home, Login, Listados, Edición CRUD y Ajustes
│   └── widgets/             # Tarjetas, indicadores y componentes de interfaz reutilizables
├── scripts/                 # Lote de scripts (.bat y .sh) para automatizar instalación y ejecución
├── supabase/                # Scripts SQL para despliegue de esquemas de bases de datos
└── test/                    # Pruebas automatizadas del proyecto
```

### 12. Pruebas
El proyecto incluye pruebas unitarias para validar la deserialización de datos, por ejemplo la conversión de la respuesta JSON de la API del clima (Open-Meteo) a un modelo de Dart (`test/weather_snapshot_test.dart`).

Para ejecutar el conjunto de pruebas unitarias, ejecuta:
```bash
flutter test
```

### 13. Capturas o evidencias
* [ ] **Pantalla de Inicio (Home)**: Muestra el banner principal del turismo de Comarapa y las categorías destacadas.
* [ ] **Listado de Lugares**: Catálogo interactivo de atractivos turísticos con filtros dinámicos.
* [ ] **Laboratorio de Contexto**: Visualización de la geolocalización real de Comarapa y temperatura actual mediante Open-Meteo.
* [ ] **Panel de Administración**: Formulario para la inserción, modificación y eliminación (CRUD) de destinos turísticos.

*(Nota para el estudiante: Se recomienda añadir las capturas en formato de imagen en una carpeta dentro del proyecto y enlazarlas en este apartado usando la sintaxis de Markdown: `![Descripción de la imagen](ruta/a/la/imagen.png)`).*

### 14. Limitaciones conocidas
* **Dependencia de Conectividad en CRUD**: Aunque el "Plan B Offline" permite mostrar la información del catálogo guardada previamente en preferencias, los flujos de creación, modificación y eliminación de registros (CRUD) requieren de una conexión activa a internet y acceso a los servidores de Supabase.
* **Permisos y Hardware de Ubicación**: En emuladores sin sensores de GPS configurados, el servicio de geolocalización puede experimentar retardos o requerir coordenadas ficticias inyectadas manualmente en el simulador.
* **Límite de solicitudes de la API de Clima**: El uso de la API gratuita de Open-Meteo está sujeto a límites de tasa de solicitudes por dirección IP.

### 15. Autor o equipo
* **Estudiante / Desarrollador**: [Ingresa tu Nombre y Apellido]
* **Curso/Materia**: Diplomado en Desarrollo de Aplicaciones Móviles - Módulo 3 (Proyecto Final)
* **Docente**: Vladimir Portillo
* **Institución**: Universidad Autónoma Juan Misael Saracho (UAJMS)
