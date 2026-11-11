# RepoLens

App móvil en **Flutter (Dart)** que genera un informe con la información esencial de cualquier repositorio público de GitHub. El usuario pega la URL del repositorio y RepoLens muestra sus datos generales, lenguajes, commits, archivos, README, una puntuación de salud y alertas de seguridad.

No depende de ningún servidor propio: solo consume la API REST pública de GitHub (`https://api.github.com`) y guarda todo localmente en SQLite.

- **Equipo:** [NOMBRE_EQUIPO]
- **Integrantes:** Saúl Luna Hernández, grupo 5 B · [INTEGRANTES]
- **Asignatura:** [ASIGNATURA]
- **Fecha:** [FECHA]

## Capturas

| Inicio | Analizar | Resultado | Salud |
|---|---|---|---|
| ![Inicio](Entrega/Evidencias/Capturas/02_inicio.png) | ![Analizar](Entrega/Evidencias/Capturas/05_analizar.png) | ![Resumen](Entrega/Evidencias/Capturas/06_resultado_resumen.png) | ![Salud](Entrega/Evidencias/Capturas/11_resultado_salud.png) |

La lista completa de capturas está en `Entrega/Evidencias/Capturas/README.md`.

## Funcionalidades

- Splash e Inicio con acceso a las funciones principales.
- Registro e inicio de sesión locales (SQLite, contraseña con SHA-256 + salt), sesión persistente y cierre de sesión.
- Navegación con `NavigationBar` (teléfono) o `NavigationRail` (tableta): Inicio, Analizar, Historial, Favoritos y Perfil.
- Análisis de un repositorio en seis pestañas: Resumen, Lenguajes (gráfica de pastel), Commits, Archivos, README (Markdown) y Salud.
- Análisis propio: detección de stack, puntuación de salud de 0 a 100 con desglose y alertas de archivos sensibles.
- Comparación de dos repositorios lado a lado.
- Historial de análisis (consultar, reabrir sin red, eliminar uno, vaciar).
- Favoritos con nota editable (agregar, consultar, editar, eliminar).
- Caché de 30 minutos para no rebasar el límite de la API.
- Token personal de GitHub opcional, guardado en almacenamiento seguro.
- Tema claro, oscuro o del sistema.
- Errores con mensaje amable y botón Reintentar: sin conexión, timeout, 404, límite de peticiones, repo vacío, JSON inesperado y base de datos.

## Tecnologías

| Tecnología | Uso |
|---|---|
| Flutter 3.47.6 / Dart 3.13.5 | Framework y lenguaje |
| `provider` | Gestión de estado (ChangeNotifier) |
| `http` | Peticiones a la API de GitHub |
| `sqflite` + `path` | Base de datos SQLite local |
| `shared_preferences` | Sesión y tema |
| `flutter_secure_storage` | Token de GitHub |
| `crypto` | Hash SHA-256 de contraseñas |
| `fl_chart` | Gráfica de pastel de lenguajes |
| `flutter_markdown` | Render del README |
| `connectivity_plus` | Verificación de red |
| `flutter_launcher_icons` | Icono de la app |
| `flutter_test`, `http/testing`, `sqflite_common_ffi` | Pruebas |

## Requisitos

- Flutter 3.47.6 o superior (canal estable), Dart 3.13.5.
- Android SDK 36 (`compileSdk`), con build-tools 36.0.0. `minSdk` y `targetSdk` son los predeterminados de Flutter.
- JDK 17 o superior (sirve el que incluye Android Studio).
- Un dispositivo o emulador Android con internet.

## Instalación

```bash
git clone <URL_DEL_REPOSITORIO>
cd RepoLens
flutter pub get
```

## Ejecución

```bash
flutter run
```

Pruebas y análisis estático:

```bash
flutter analyze
flutter test
```

## Cómo generar la APK

```bash
flutter build apk --release
```

La APK queda en `build/app/outputs/flutter-apk/app-release.apk`. La copia de entrega está en `Entrega/Aplicacion/RepoLens.apk`.

Si Gradle falla con `Unable to establish loopback connection`, define antes esta variable (ver `DECISIONES.md`):

```bash
set JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:\ruta\corta\temporal
```

Para regenerar el icono: `dart run flutter_launcher_icons`.

## Usuario de prueba

Se crea solo en la primera ejecución:

- **Email:** `demo@repolens.app`
- **Contraseña:** `Demo1234`

## Token opcional de GitHub

Sin token, la API permite 60 peticiones por hora; con token, 5000.

1. En GitHub: *Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token*. No hace falta ningún permiso extra (solo lectura de repositorios públicos).
2. En la app: **Perfil → Token de GitHub → Pegar token personal → Guardar token**.

El token se guarda cifrado solo en el dispositivo con `flutter_secure_storage`. Nunca se escribe en el código ni en el repositorio.

## Estructura de carpetas

```
lib/
  main.dart                # punto de entrada
  app.dart                 # MaterialApp, providers, temas y rutas
  core/                    # constants, theme, utils, validators, exceptions
  models/                  # repo_info, language_stat, commit_info, contributor,
                           # repo_file, analysis_result, user, favorite, history_entry
  services/                # github_service, analyzer, auth_service,
                           # connectivity_service, token_service
  data/                    # database_helper y un repositorio por tabla
  providers/               # auth, analysis, history, favorites, theme
  screens/                 # splash, login, register, main_shell, home, analyze,
                           # result, compare, history, favorites, profile
  widgets/                 # state_views, url_form, common
test/
  unit/                    # validators, models, analyzer, github_service, auth, database
  widget/                  # auth_screens, url_form, navigation
  mocks/                   # respuestas JSON de ejemplo, MockClient y repositorio falso
Entrega/                   # APK, documentación, evidencias y bitácora
```

## Endpoints usados

Todos son `GET` sobre `https://api.github.com`:

| Endpoint | Datos |
|---|---|
| `/repos/{owner}/{repo}` | Descripción, estrellas, forks, watchers, issues, licencia, tamaño, rama, fechas, temas, avatar |
| `/repos/{owner}/{repo}/languages` | Bytes por lenguaje (se convierten a porcentajes) |
| `/repos/{owner}/{repo}/commits?per_page=10` | Commits recientes |
| `/repos/{owner}/{repo}/contributors?per_page=10` | Contribuidores |
| `/repos/{owner}/{repo}/contents` | Archivos de la raíz |
| `/repos/{owner}/{repo}/readme` | README en base64 |

## Documentación

- `Entrega/Documentacion/DocumentoTecnico.md`: documento técnico completo.
- `Entrega/Evidencias/Pruebas/MatrizPruebas.md`: matriz de pruebas.
- `Entrega/Bitacora/BitacoraDesarrollo.md`: bitácora de desarrollo.
- `GUIA_DEFENSA.md`: guía de estudio para la exposición.
- `GUION_VIDEO.md`: guion del video de demostración.
- `DECISIONES.md`: decisiones tomadas y problemas de entorno.
