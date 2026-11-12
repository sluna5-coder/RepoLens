# Bitácora de desarrollo — RepoLens

- **Equipo:** [NOMBRE_EQUIPO]
- **Integrantes:** Saúl Luna Hernández, grupo 5 B · [INTEGRANTES]
- **Asignatura:** [ASIGNATURA]
- **Fecha de entrega:** [FECHA]

## Registro de actividades

Basado en los commits reales del repositorio (`git log`). Todo el desarrollo se hizo el 2026-11-11.

| Fecha | Actividad | Responsable | Herramienta | Resultado |
|---|---|---|---|---|
| 2026-11-11 08:19 | Estructura inicial: proyecto Flutter, dependencias, permiso INTERNET, nombre de la app y `.gitignore` | Saúl Luna | Flutter CLI, Claude Code, Git | Commit `925719d`. Proyecto base creado |
| 2026-11-11 08:43 | Núcleo (constantes, tema, validadores, excepciones) y modelos con `fromJson`/`toJson` | Saúl Luna | Claude Code, Dart | Commit `7ba8982`. 9 modelos y 5 archivos de `core/` |
| 2026-11-11 08:43 | `GithubService` con cliente inyectable, `Analyzer` y servicios de red y token | Saúl Luna | Claude Code, paquete `http` | Commit `7dc5d35`. 6 endpoints y análisis propio |
| 2026-11-11 08:43 | `DatabaseHelper` y repositorios SQLite por tabla | Saúl Luna | Claude Code, `sqflite` | Commit `24e44eb`. 4 tablas y 4 repositorios |
| 2026-11-11 08:43 | Autenticación local con SHA-256 y providers de estado | Saúl Luna | Claude Code, `crypto`, `provider` | Commit `9ba79fe`. 5 providers |
| 2026-11-11 08:54 | App, widgets reutilizables y pantallas de splash, login y registro | Saúl Luna | Claude Code, Flutter | Commit `738878b` |
| 2026-11-11 08:54 | Navegación principal y pantallas de inicio, análisis, resultado, comparación, historial, favoritos y perfil | Saúl Luna | Claude Code, `fl_chart`, `flutter_markdown` | Commit `db03721`. `flutter analyze` sin problemas |
| 2026-11-11 08:54 | Pruebas unitarias y de widget con `MockClient` | Saúl Luna | Claude Code, `flutter_test` | Commit `248b14a`. 53 pruebas aprobadas |
| 2026-11-11 08:55 | Icono propio y configuración de `flutter_launcher_icons` | Saúl Luna | PowerShell (`System.Drawing`), Claude Code | Commit `3cae91b`. Icono en todas las densidades |
| 2026-11-11 09:00 | Pruebas de SQLite y navegación; corrección del desborde de cuadrículas; registro de decisiones | Saúl Luna | Claude Code, `sqflite_common_ffi` | Commit `2ccbc66`. 61 pruebas aprobadas |
| 2026-11-11 09:01 | Se documenta el fallo de compilación de la APK | Saúl Luna | Claude Code, Gradle | Commit `0f8d05c`. APK pendiente en ese momento |
| 2026-11-11 | Traslado del proyecto a `Documentos\RepoLens`, icono regenerado con `flutter_launcher_icons`, compilación de la APK y documentación | Saúl Luna | Claude Code, Flutter CLI | Ver los commits finales en `git log` |
| 2026-11-12 | Análisis del árbol completo: stack en subcarpetas, estructura, tipos de archivo, recomendaciones y botón Actualizar | Saúl Luna | Claude Code, API de GitHub (`git/trees`) | 69 pruebas aprobadas; comprobado en emulador |

Para ver la lista exacta:

```bash
git log --format="%h %ad %s" --date=format:"%Y-%m-%d %H:%M"
```

## Ejemplos de prompts usados con la IA

Son los mensajes reales que se enviaron a Claude Code en la sesión de desarrollo.

### Prompt 1 — Especificación completa del proyecto

> "Trabaja de forma autónoma en esta sesión. NO me hagas preguntas: si algo no está definido, toma la decisión más razonable, anótala en `DECISIONES.md` y continúa. [...] Debe ser una app en Flutter (Dart) llamada RepoLens. El usuario pega la URL de un repositorio público de GitHub y la app le muestra un informe [...]" (archivo `prompt_repolens_claude_code.md`, con los 11 requisitos, la arquitectura, las pruebas y la entrega).

- **Problema planteado:** construir la app completa a partir de una lista de requisitos verificables.
- **Qué propuso la IA:** revisar primero el entorno (Flutter 3.47.6, SDK 36), crear el proyecto solo para Android y avanzar por capas: núcleo y modelos, servicio de API, base de datos, autenticación, pantallas y pruebas, con un commit por etapa.
- **Qué se modificó:** todo `lib/` y `test/`.
- **Cómo se verificó:** `flutter analyze` (sin problemas) y `flutter test` (61 pruebas aprobadas).
- **Qué se aprendió:** un prompt con requisitos numerados y criterios verificables produce un resultado que se puede revisar punto por punto. Pedir una estructura de carpetas fija evita que la IA improvise la arquitectura.

### Prompt 2 — Autonomía y ahorro

> "crea todo sin colsultarme,toma las deciciones tu,actua como el creador abogando por los objetivos y gastar solo los tokens nesesarios"

- **Problema planteado:** avanzar sin interrupciones y sin gastar de más.
- **Qué propuso la IA:** tomar las decisiones abiertas por su cuenta y registrarlas. Por ejemplo: pesos de la puntuación de salud (README 20, licencia 15, `.gitignore` 10, descripción 15, commit reciente 20, contribuidores 10, temas 10), usar `subscribers_count` como watchers, y tratar el 403 como límite de peticiones solo cuando `X-RateLimit-Remaining` es 0.
- **Qué se modificó:** `lib/services/analyzer.dart`, `lib/services/github_service.dart` y `DECISIONES.md`.
- **Cómo se verificó:** `test/unit/analyzer_test.dart` comprueba las puntuaciones 100, 0 y 65; `github_service_test.dart` comprueba el 403 y el 429.
- **Qué se aprendió:** dar autonomía funciona si se exige dejar por escrito cada decisión. `DECISIONES.md` permite revisar después lo que la IA eligió y cambiarlo si no convence.

### Prompt 3 — Guardar el avance

> "guarda lo que llevamos para seguirle despues"

- **Problema planteado:** pausar el trabajo sin perder nada.
- **Qué propuso la IA:** hacer commit de todo, y escribir en `DECISIONES.md` una sección "Estado al pausar" con lo terminado, lo pendiente y el error exacto de la APK.
- **Qué se modificó:** `DECISIONES.md` y dos commits.
- **Cómo se verificó:** `git status` sin cambios pendientes y 11 commits en `git log`.
- **Qué se aprendió:** un archivo de estado dentro del repositorio permite retomar el trabajo en otra sesión sin depender de la memoria de la conversación. También se vio que la IA reportó con franqueza lo que **no** estaba hecho (APK y documentación).

### Prompt 4 — Mover el proyecto

> "Sí, muévelo"

- **Problema planteado:** el proyecto estaba en una carpeta temporal de la aplicación, con una ruta muy larga.
- **Qué propuso la IA:** crear `Documentos\RepoLens` y trasladar ahí el proyecto con su historial de Git.
- **Qué se modificó:** la ubicación del proyecto; el código no cambió.
- **Cómo se verificó:** `git log` muestra los mismos 11 commits y `git status` queda limpio en la carpeta nueva.
- **Qué se aprendió:** en Windows la longitud de la ruta importa. En la carpeta temporal `dart run flutter_launcher_icons` fallaba con `Failed to canonicalize path ... OS error (122)`; en la ruta corta funcionó sin cambiar nada.

### Prompt 5 — Continuar

> "sigue"

- **Problema planteado:** terminar lo pendiente: APK y documentación.
- **Qué propuso la IA:** leer la lista de pendientes de `DECISIONES.md`, lanzar la compilación en segundo plano y escribir mientras tanto el README, el documento técnico, la matriz de pruebas, la bitácora, la guía de defensa y el guion.
- **Qué se modificó:** `README.md`, la carpeta `Entrega/`, `GUIA_DEFENSA.md` y `GUION_VIDEO.md`.
- **Cómo se verificó:** revisión del checklist final del prompt 1; el resultado de la compilación está en `DECISIONES.md`.
- **Qué se aprendió:** como el estado estaba escrito, un prompt de una palabra bastó para retomar. La matriz de pruebas separa lo comprobado con pruebas automatizadas de lo que falta comprobar en el teléfono, y eso evita afirmar más de lo verificado.

## Problemas de la sesión y cómo se resolvieron

| Problema | Diagnóstico | Solución |
|---|---|---|
| Gradle: `Unable to establish loopback connection` | `--stacktrace` mostró `SocketException: Invalid argument: connect` (sockets de dominio Unix del JDK) | `JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=<carpeta corta>` |
| `flutter_launcher_icons` no corría | Ruta del proyecto demasiado larga | Mover el proyecto a una ruta corta |
| Kotlin: `Could not close incremental caches` | Compilación desde una unidad virtual distinta a la caché de paquetes | Compilar desde la ruta real |
| Desborde de 10 px en tarjetas | La prueba de navegación lo detectó en ancho de tableta | `mainAxisExtent` en las cuadrículas |
| Mensaje con género incorrecto | Plantilla "$campo es obligatorio" | El validador recibe el mensaje completo |
