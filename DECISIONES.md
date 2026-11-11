# DECISIONES.md — RepoLens

Registro de las decisiones tomadas sin consultar y del estado del trabajo.

## Estado al pausar (2026-11-11)

### Terminado y verificado
- Proyecto Flutter 3.47.6 / Dart 3.13.5 creado (solo plataforma Android), paquete `app.repolens.repolens`.
- Código completo: `core/`, `models/`, `services/`, `data/`, `providers/`, `screens/`, `widgets/`.
- `flutter analyze`: **sin problemas** ("No issues found").
- `flutter test`: **61 pruebas, todas pasan** (unitarias, de widget y de integración con SQLite real vía `sqflite_common_ffi`).
- Icono propio generado (`assets/icon/`) y copiado a `android/app/src/main/res/` en todas las densidades, con icono adaptativo.
- Nombre "RepoLens" y permiso INTERNET en `AndroidManifest.xml`.
- `.gitignore` con secretos excluidos. Commits incrementales en español.
- Evidencia de pruebas en `Entrega/Evidencias/Pruebas/resultado_flutter_test.txt` y `resultado_flutter_analyze.txt` (corresponden a la corrida de 53 pruebas; hay que regenerarlas con las 61).

### Pendiente (para continuar)
1. **APK release: todavía NO se genera.** El último intento (desde la unidad `R:`, 4 min) pasó el error de sockets pero falló en:
   `Execution failed for task ':shared_preferences_android:compileReleaseKotlin'` →
   `Could not close incremental caches in R:\build\shared_preferences_android\kotlin\compileReleaseKotlin\cacheable\caches-jvm\jvm\kotlin`.
   Es un fallo conocido de la compilación incremental de Kotlin cuando el proyecto y la caché de pub están en unidades distintas (`R:` y `C:`). Siguiente intento, sin probar aún: agregar `kotlin.incremental=false` a `android/gradle.properties`, o mover el proyecto a una carpeta de ruta corta en `C:` y compilar ahí sin `subst`. Al lograrlo, copiar `build/app/outputs/flutter-apk/app-release.apk` a `Entrega/Aplicacion/RepoLens.apk`.
2. **Documentación** (nada de esto está escrito todavía):
   - `README.md` del proyecto (sigue el de plantilla de Flutter).
   - `Entrega/Documentacion/DocumentoTecnico.md` (19 apartados).
   - `Entrega/Evidencias/Pruebas/MatrizPruebas.md` y los `README.md` de `Capturas/`, `Pruebas/`, `EvidenciasAPI/`.
   - `Entrega/Bitacora/BitacoraDesarrollo.md`.
   - `GUIA_DEFENSA.md`, `GUION_VIDEO.md`, `Entrega/README.txt`.
3. Regenerar la evidencia de pruebas con las 61 pruebas.
4. Verificación final del checklist y resumen.
5. La app **no se ha ejecutado en un dispositivo o emulador**: la interfaz solo está verificada por las pruebas de widget.

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

## Problemas de entorno encontrados
1. **Gradle: `java.io.IOException: Unable to establish loopback connection`** (causa: `java.net.SocketException: Invalid argument: connect`). El JDK de Android Studio (JBR 25) no pudo crear sockets de dominio Unix en la carpeta temporal por defecto.
   - Solución que funcionó con `gradlew help`: definir antes de compilar
     `JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:\Users\Colibecas\.udtmp`
     (se creó la carpeta `C:\Users\Colibecas\.udtmp` para esto; se puede borrar al terminar).
2. **`dart run flutter_launcher_icons` falla**: `Failed to canonicalize path ... OS error (122)`. La ruta del proyecto es demasiado larga para Windows. La configuración quedó en `pubspec.yaml`, pero los iconos se generaron con un script de PowerShell (`System.Drawing`) a los mismos destinos. En una carpeta de ruta corta el comando debería funcionar; no se comprobó.
3. **Unidad `R:`**: se creó con `subst R: <carpeta del proyecto>` para compilar desde una ruta corta. Es temporal; se quita con `subst R: /d`.
4. **Desborde de 10 px** en las tarjetas de Inicio y de estadísticas en pantallas anchas: lo detectó la prueba de navegación. Se corrigió usando alto fijo (`mainAxisExtent`) en las cuadrículas.
5. El `git config user.email` de esta máquina es `tu-correo@ejemplo.com` (valor de plantilla): conviene corregirlo antes de subir a GitHub.

## Comando de compilación
```
set JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:\Users\Colibecas\.udtmp
flutter build apk --release
```
