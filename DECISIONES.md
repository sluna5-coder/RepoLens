# DECISIONES.md — RepoLens

Registro de las decisiones tomadas sin consultar y del estado del trabajo.

## Estado final (2026-11-11)

### Terminado y verificado
- Proyecto Flutter 3.47.6 / Dart 3.13.5 (solo plataforma Android), paquete `app.repolens.repolens`.
- Código completo: `core/`, `models/`, `services/`, `data/`, `providers/`, `screens/`, `widgets/`.
- `flutter analyze`: **No issues found.**
- `flutter test`: **69 pruebas, todas aprobadas** (unitarias, de widget y de integración con SQLite real vía `sqflite_common_ffi`). Salida guardada en `Entrega/Evidencias/Pruebas/`.
- **APK release generada**: `flutter build apk --release` terminó bien (52.8 MB). Copia en `Entrega/Aplicacion/RepoLens.apk`.
- Icono propio generado con `dart run flutter_launcher_icons`, nombre "RepoLens" y permiso INTERNET.
- Documentación: `README.md`, `Entrega/Documentacion/DocumentoTecnico.md` (19 apartados), matriz de pruebas, bitácora, `GUIA_DEFENSA.md`, `GUION_VIDEO.md` y `Entrega/README.txt`.
- `.gitignore` con secretos excluidos; commits incrementales en español; sin tokens ni claves en el repositorio.

### No verificado
- **Probado en emulador, no en teléfono físico.** La APK se instaló en un emulador Android (`Medium_Phone`, API 37, x86_64) y se comprobó: pantalla de login, entrada con el usuario de prueba, pantalla de Inicio y un análisis real de `dart-lang/http` contra la API de GitHub (salud 100). El resto de pantallas (historial, favoritos, comparación, perfil, errores de red) no se recorrió en el emulador.
- Sin prueba automatizada: cambio de tema, pantalla de comparación y guardado del token en `flutter_secure_storage` (casos 22 a 24 de la matriz).
- Los diagramas Mermaid del documento técnico no se renderizaron para revisarlos.

### Pendiente para el autor
- Probar la APK en el teléfono, tomar las capturas y grabar el video.
- Llenar los marcadores `[NOMBRE_EQUIPO]`, `Saúl Luna Hernández, Emmanuel Alejandro, Gustavo Ceja Quintero, Pedro Andrés Aguilar y Jorge Luis Pizano Saucedo`, `[ASIGNATURA]` y `[FECHA]`.
- Corregir `git config user.email` (hoy es `tu-correo@ejemplo.com`) y subir a GitHub.

## Decisiones de diseño
- **Plataforma**: solo Android (`flutter create --platforms android`), porque la entrega es una APK.
- **Salud (0–100)**: README 20, licencia 15, `.gitignore` 10, descripción 15, commit en los últimos 90 días 20, más de un contribuidor 10, temas 10.
- **Watchers**: se usa `subscribers_count` (los observadores reales); `watchers_count` de la API es igual a las estrellas.
- **403**: solo se trata como límite de peticiones si `X-RateLimit-Remaining` es `0` o viene `Retry-After`. Otros 403 (por ejemplo, la lista de contribuidores de repos enormes) son `ApiException`, y en ese caso los contribuidores se muestran vacíos en vez de tumbar el informe.
- **Repo vacío**: el 409 de `/commits` detiene el análisis con `EmptyRepoException`.
- **README ausente**: el 404 de `/readme` no es error; el informe sale sin README.
- **Caché**: guarda el informe completo ya analizado (un JSON por repo), no cada respuesta por separado. La clave es `owner/repo` en minúsculas.
- **Historial**: guarda un snapshot JSON del informe, así se puede reabrir sin red. Cada análisis crea una entrada, incluso si salió de caché.
- **Favoritos**: restricción `UNIQUE(user_id, full_name)` para no duplicar.
- **Sesión**: en `shared_preferences` solo se guarda el id del usuario.
- **Token**: `flutter_secure_storage`; la pantalla de Perfil nunca muestra su valor, solo si existe.
- **Archivo extra**: `services/token_service.dart` (no estaba en la estructura pedida) para aislar el almacenamiento seguro.
- **Widgets**: `state_views.dart` (error, vacío, carga, diálogo de confirmación, SnackBar), `common.dart`, `url_form.dart`.
- **Carga**: indicadores de progreso en lugar de shimmer (el enunciado permite cualquiera).
- **Imágenes del README**: solo se cargan las `http(s)`; las que fallan (SVG, rutas relativas) se ocultan.
- **Pruebas de base de datos**: se agregó `sqflite_common_ffi` como dependencia de desarrollo para probar los repositorios contra SQLite real.
- **`Validators.required`** recibe el mensaje completo, para respetar el género ("La contraseña es obligatoria").
- **Firma de la APK**: se usa la firma de depuración que trae la plantilla de Flutter. Sirve para instalar y evaluar; para publicar en una tienda haría falta una llave propia.
- **APK fuera de Git**: `Entrega/Aplicacion/*.apk` está en `.gitignore` porque pesa unos 53 MB. Hay que adjuntarla aparte en la entrega o subirla como *Release* en GitHub.
- **Guías**: `GUIA_DEFENSA.md` y `GUION_VIDEO.md` están en la raíz y copiadas en `Entrega/Documentacion/`.
- **Bitácora**: los "prompts reales" son los cinco mensajes que el autor envió en la sesión; no se inventó ninguno.

## Mejora: análisis del árbol completo (2026-11-12)
Motivo: con repos pequeños o con el proyecto dentro de una subcarpeta, el informe casi no daba información (stack vacío, consejos genéricos).
- **Árbol completo**: una sola petición extra, `GET /git/trees/{rama}?recursive=1`. Si falla por otra causa que no sea red o límite de peticiones, el informe sale igual con la raíz.
- **Stack**: se buscan archivos de configuración en cualquier carpeta y herramientas como Vite, Next.js, Tailwind, Docker Compose o GitHub Actions. Sin archivos de configuración se usan las extensiones (HTML, CSS, JavaScript, etc.). En proyectos Flutter no se reportan Android, Kotlin ni CMake, porque son plantilla del framework.
- **Estructura**: archivos, carpetas, tamaño, profundidad, tipos de archivo, archivos más pesados y prácticas presentes (pruebas, CI, Docker, documentación, guía de contribución y registro de cambios).
- **Qué mejorar**: un consejo por cada criterio de salud no cumplido, más pruebas, CI, archivos sensibles, archivos de más de 5 MB e inactividad mayor a un año. Si el README está en una subcarpeta, se indica su ruta.
- **Salud**: los pesos no cambian. El `.gitignore` ahora cuenta en cualquier carpeta; el README sigue contando solo en la raíz, porque es el único que GitHub muestra en la portada.
- **Alertas de seguridad**: se revisan todas las carpetas y se muestra la ruta del archivo.
- **Caché**: los informes guardados por la versión anterior (sin análisis del árbol) se descartan.
- **Botón Actualizar** en el informe: vuelve a consultar la API sin usar la caché.
- Comprobado en el emulador con `sluna5-coder/rick-morty`: stack Flutter/Dart, 79 archivos en 38 carpetas, salud 30 y recomendaciones. Pruebas: 69 aprobadas.

## Mejora: versión web para Chrome (2026-11-12)
- Se agregó la plataforma web (`flutter create --platforms web .`). La entrega principal sigue siendo la APK.
- **SQLite en web**: `sqflite_common_ffi_web`. En `main.dart`, si `kIsWeb`, se usa `databaseFactoryFfiWeb`. Los archivos `web/sqlite3.wasm` y `web/sqflite_sw.js` se generaron con `dart run sqflite_common_ffi_web:setup` y se incluyen en el repositorio porque sin ellos la versión web no abre la base de datos.
- La API de GitHub permite peticiones desde el navegador (CORS), así que el servicio no cambió.
- `.vscode/launch.json` con dos configuraciones: "RepoLens (Chrome)" y "RepoLens (Android)".
- Nombre, descripción, colores e iconos de la versión web son los de RepoLens.
- Se borró `test/widget_test.dart`, la prueba de plantilla que creó `flutter create`.
- Comprobado en el navegador: login con el usuario de prueba y análisis de `sluna5-coder/rick-morty`.
- La APK pasó de 52.9 MB a 57.6 MB por la nueva dependencia. No se probó en el emulador después de este cambio porque estaba cerrado.

## Mejora: diseño limpio con tema oscuro por defecto (2026-11-12)
- **Estilo**: inspirado en las apps de iOS sin copiar fuentes ni iconos de Apple. Fondo negro (oscuro) o gris muy claro (claro), tarjetas agrupadas, un solo acento azul, verde, naranja y rojo del sistema para estados, títulos grandes y radios de 12 a 14 px. Todo está en `lib/core/theme.dart` (`AppColors` y `AppTheme`).
- **Tema oscuro por defecto**: `ThemeProvider` arranca en oscuro si no hay preferencia guardada. Botón de sol y luna en Inicio y en Login; en Perfil siguen las tres opciones (sistema, claro, oscuro).
- **Componentes nuevos**: `IconBadge` (icono en cuadro de color), `GroupedSection` (lista agrupada con título) y `ThemeToggleButton`.
- **Alertas de seguridad**: se ignoran los archivos dentro de carpetas de pruebas (`test`, `testing`, `fixtures`...), porque ahí suelen estar llaves falsas. Si hay más de tres alertas se muestran tres y "y N más".
- **README**: encabezado centrado con logo, insignias y capturas que cambian según el tema de GitHub (`<picture>`). Las capturas están en `docs/screenshots/` y se tomaron de la versión web a 390 × 844.
- Pruebas: 70 aprobadas.

## Mejora: imágenes del README (2026-11-12)
Motivo: muchos README usan HTML (`<p align>`, `<table>`, `<img>`), rutas relativas como `screenshots/x.png` y logos SVG. El visor de Markdown descartaba el HTML y la app solo cargaba URLs completas, así que esas imágenes no aparecían.
- `lib/core/readme_formatter.dart` convierte a Markdown lo más común del HTML de GitHub: imágenes (con su ancho y alto), `<picture>`, encabezados, enlaces, negritas, saltos de línea y tablas (las imágenes de una tabla salen una debajo de otra). No toca los bloques de código.
- Las rutas relativas se resuelven contra `raw.githubusercontent.com/{repo}/{rama}/` para imágenes y `github.com/{repo}/blob/{rama}/` para enlaces. Los enlaces `github.com/.../blob/...` de imágenes se cambian por el archivo crudo.
- SVG con `flutter_svg` (logos e insignias de shields.io).
- Las capturas grandes se limitan a 420 px de ancho.
- Comprobado en web con `jorgepizanosaucedo-crypto/de-peon-a-rey`: logo SVG, título, texto, enlace y capturas. 7 pruebas nuevas; total 77.

## Mejora: enlaces del README (2026-11-12)
- Los enlaces del README se abren en el navegador con `url_launcher`. Solo se aceptan `http`, `https` y `mailto`; las anclas internas (`#seccion`) se ignoran. Si no se puede abrir, aparece un aviso.
- En Android se declararon en `AndroidManifest.xml` las consultas `VIEW` para `http` y `https`, necesarias desde Android 11 para encontrar el navegador.

## Seguridad: correcciones de la auditoría (2026-11-12)
- **1. README que congela la app (ReDoS)**: el README se recorta a 200 KB (con aviso "README recortado"), se formatea una sola vez al abrir la pestaña (`_ReadmeTab` ahora tiene estado y se mantiene vivo) y en móvil corre con `compute` fuera del hilo de la interfaz. Además todas las expresiones de `readme_formatter.dart` tienen cuantificadores acotados, los comentarios HTML se quitan en tiempo lineal y si hay más de 5000 etiquetas se omite la conversión de HTML. Un README hecho a propósito que antes tardaba minutos ahora tarda menos de 1 s. En web `compute` corre en el mismo hilo, así que ese caso extremo aún puede pausar la pestaña un momento.
- **2. Token compartido entre cuentas**: el token se guarda por usuario (`github_token_<id>`). `GithubService` pide el token del usuario con sesión activa y no envía ninguno sin sesión. Perfil guarda y borra el token de la cuenta actual. El token global de la versión anterior se borra al iniciar y no se asigna a nadie.
- **3. Cuenta demo con clave pública y caché compartida**: el usuario demo se mantiene en todas las compilaciones porque el enunciado lo exige. El riesgo real era que la cuenta demo usara el token de otra persona o viera sus datos: con el token por usuario (punto 2) ya no puede. La caché es de datos públicos de GitHub; para no filtrar repos privados vistos con el token de una cuenta, los informes de repos privados (`private: true`) ya no se guardan en la caché.
- **4. Imágenes de cualquier host**: solo se cargan solas las imágenes por HTTPS de `raw.githubusercontent.com`, `*.githubusercontent.com`, `github.com`, `img.shields.io` y `badgen.net` (`lib/core/url_policy.dart`). Las demás muestran "Imagen externa · tocar para cargar" con el host. `Image.network` usa `cacheWidth` (ancho × densidad, máximo 1200 px).
- **5. Enlaces engañosos**: un enlace fuera de `github.com`, `*.github.com` o `*.github.io` pide confirmación mostrando el host real (o la dirección en `mailto`).
- **6. Hash rápido**: las contraseñas usan PBKDF2-HMAC-SHA256 con 100 000 iteraciones y formato `pbkdf2$100000$<hex>` (verificado con los vectores públicos). Las cuentas con el hash SHA-256 anterior se verifican con el método viejo y, al acertar, se re-hashean con PBKDF2. En móvil el hash corre con `compute`. Tras cada intento fallido hay que esperar 1, 2, 4... hasta 30 s; el intento se rechaza con aviso, sin bloquear la interfaz. Las pruebas usan 1000 iteraciones.
- **7. Sesión = id en shared_preferences**: ahora se guarda un token aleatorio de 32 bytes (`Random.secure`) y en SQLite solo su hash SHA-256, en la tabla nueva `sessions` (esquema v2, migración en `_onUpgrade`). Cerrar sesión borra el token del dispositivo y su fila. Las sesiones viejas (solo id) se descartan: hay que volver a iniciar sesión una vez.
- **8. Token en web**: Perfil muestra en web "En el navegador el token no queda cifrado de forma segura. Úsalo solo en un equipo propio."
- **9. Respaldo de Android**: `android:allowBackup="false"` y `android:fullBackupContent="false"`. No se agregó `dataExtractionRules` (Android 12+) para no crear un recurso nuevo.
- **10. CSP en web**: `<meta http-equiv="Content-Security-Policy">` en `web/index.html` con `'wasm-unsafe-eval'`, CanvasKit desde `www.gstatic.com`, fuentes de `fonts.gstatic.com` y `connect-src` limitado a GitHub, insignias y esos hosts. Comprobado en Chrome con `flutter build web`: login, registro, SQLite, análisis de `dart-lang/http`, README con insignias y recarga con sesión, sin violaciones de CSP. Como las imágenes en Flutter web se descargan con `fetch`, las de hosts no confiables siguen bloqueadas en web aunque se toque "cargar".
- **11. Respuestas enormes**: `GithubService` lee el cuerpo por partes y corta con `ResponseTooLargeException` si pasa de 10 MB (también si lo anuncia `Content-Length`). Los JSON de más de 512 KB se decodifican con `compute`. La rama se codifica por segmento en las URLs del README.
- **Redirecciones con token**: se revisó `package:http`. En Android `IOClient` usa `dart:io`, que no copia `Authorization` al redirigir a otro origen (`shouldCopyHeaderOnRedirect`). En web el navegador aplica la regla de Fetch. No hizo falta cambiar `followRedirects`.
- Pruebas: 97 aprobadas.

## Pruebas de integración (2026-11-17)
- `integration_test/app_test.dart` recorre el flujo completo en un emulador Android: registro con errores y válido, login fallido y correcto, análisis de `flutter/flutter` y de un repo pequeño con sus 6 pestañas y alta en favoritos, edición de la nota y eliminación, historial, URL inválida y repo inexistente (404 con Reintentar), comparación y cambio de tema con cierre de sesión.
- La base de datos, la sesión y la navegación son las reales. La API de GitHub se simula con un `MockClient` (decisión del autor): así la prueba no depende de la red ni gasta el límite de 60 peticiones por hora. Para inyectarlo, `RepoLensApp` acepta un `httpClient` opcional; la app real no lo usa.
- Resultado real: pasa en el emulador `Medium_Phone` (API 37) en 38 s. La salida de todas las pruebas está en `Entrega/Evidencias/Pruebas/resultado_tests.txt`.
- Comando: `flutter test integration_test/app_test.dart -d <dispositivo>`.

## Problemas de entorno encontrados
1. **Gradle: `java.io.IOException: Unable to establish loopback connection`** (causa: `java.net.SocketException: Invalid argument: connect`). El JDK de Android Studio (JBR 25) no pudo crear sockets de dominio Unix en la carpeta temporal por defecto.
   - Solución: definir antes de compilar `JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:\Users\Colibecas\.udtmp`. Se creó esa carpeta para esto; se puede borrar cuando ya no se compile.
2. **`dart run flutter_launcher_icons` fallaba**: `Failed to canonicalize path ... OS error (122)`. La ruta de la carpeta temporal donde empezó el proyecto era demasiado larga para Windows. En `Documentos\RepoLens` el comando funcionó.
3. **Kotlin: `Could not close incremental caches in R:\build\shared_preferences_android\...`**. Ocurrió al compilar desde una unidad virtual (`subst R:`) creada para acortar la ruta. La unidad se quitó (`subst R: /d`) y la compilación desde `Documentos\RepoLens` terminó bien, sin tocar `gradle.properties`.
4. **Desborde de 10 px** en las tarjetas de Inicio y de estadísticas en pantallas anchas: lo detectó la prueba de navegación. Se corrigió con alto fijo (`mainAxisExtent`) en las cuadrículas.
5. **Traslado del proyecto**: la copia automática a `Documentos\RepoLens` quedó incompleta; se completó copiando el historial de Git y restaurando los archivos (`git reset --hard`), con los mismos 11 commits.

## Comando de compilación
```
set JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:\Users\Colibecas\.udtmp
flutter build apk --release
```
