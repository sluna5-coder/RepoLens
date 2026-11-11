# DECISIONES.md — RepoLens

Registro de las decisiones tomadas sin consultar y del estado del trabajo.

## Estado final (2026-11-11)

### Terminado y verificado
- Proyecto Flutter 3.47.6 / Dart 3.13.5 (solo plataforma Android), paquete `app.repolens.repolens`.
- Código completo: `core/`, `models/`, `services/`, `data/`, `providers/`, `screens/`, `widgets/`.
- `flutter analyze`: **No issues found.**
- `flutter test`: **61 pruebas, todas aprobadas** (unitarias, de widget y de integración con SQLite real vía `sqflite_common_ffi`). Salida guardada en `Entrega/Evidencias/Pruebas/`.
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
- Llenar los marcadores `[NOMBRE_EQUIPO]`, `[INTEGRANTES]`, `[ASIGNATURA]` y `[FECHA]`.
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
