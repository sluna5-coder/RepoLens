# Guía de defensa — RepoLens

Guía de estudio para la exposición. Explica, archivo por archivo, dónde ocurre cada cosa y cómo cambiarla.

## 1. La idea en 30 segundos

RepoLens recibe la URL de un repositorio público de GitHub, consulta seis endpoints de la API, convierte las respuestas en modelos, calcula un análisis propio (stack, salud y alertas) y lo muestra en seis pestañas. Todo lo que guarda (usuarios, historial, favoritos y caché) vive en SQLite dentro del teléfono. No hay servidor propio.

## 2. El recorrido de un análisis

Memoriza este camino; responde la mayoría de las preguntas:

1. `lib/widgets/url_form.dart` — el usuario escribe la URL. `Validators.repoUrl` la valida.
2. `lib/screens/analyze_screen.dart` — `runAnalysis()` llama a `AnalysisProvider.analyze()`.
3. `lib/providers/analysis_provider.dart` — `load()` hace cuatro pasos:
   normaliza la URL a `owner/repo` → busca en caché → verifica la red → llama a `GithubService.fetchAll()`.
4. `lib/services/github_service.dart` — `_get()` hace la petición HTTP; cada método convierte el JSON en un modelo.
5. `lib/services/analyzer.dart` — `Analyzer.build()` calcula stack, salud y alertas.
6. De vuelta en el provider: guarda en `cache` y en `history`.
7. `lib/screens/result_screen.dart` — muestra el `AnalysisResult` en seis pestañas.

## 3. Dónde se hace cada petición HTTP

Todas están en **un solo archivo**: `lib/services/github_service.dart`.

| Método | Endpoint |
|---|---|
| `getRepo` | `GET /repos/{owner}/{repo}` |
| `getLanguages` | `GET /repos/{owner}/{repo}/languages` |
| `getCommits` | `GET /repos/{owner}/{repo}/commits?per_page=10` |
| `getContributors` | `GET /repos/{owner}/{repo}/contributors?per_page=10` |
| `getContents` | `GET /repos/{owner}/{repo}/contents` |
| `getReadme` | `GET /repos/{owner}/{repo}/readme` |

- La petición real es una línea dentro de `_get()`: `_client.get(Uri.parse(...), headers: headers).timeout(timeout)`.
- `_get()` también agrega el token (`Authorization: Bearer ...`) si existe, y traduce cada código de estado a una excepción con un `switch`.
- `fetchAll()` pide primero el repo y después los otros cinco **en paralelo** con `Future.wait`.
- El `http.Client` llega por el constructor. Por eso en las pruebas se le pasa un `MockClient`.

## 4. Cómo se parsea el JSON

- `_get()` convierte el texto en mapas y listas con `jsonDecode`.
- Cada modelo de `lib/models/` tiene un constructor `fromJson` que lee los campos y un `toJson` que hace el camino inverso.
- Ejemplo, `lib/models/repo_info.dart`: `stars: (json['stargazers_count'] as int?) ?? 0`. Lee el campo, lo trata como entero y usa 0 si viene nulo.
- Objetos anidados: `owner['login']` y `license?['name']`.
- Fechas: `DateTime.tryParse(...)`.
- Lenguajes (`language_stat.dart`): la API manda `{"Dart": 7500, "Kotlin": 2000}`. `listFromApi` suma los bytes y calcula el porcentaje.
- README: llega en base64. Se quitan los saltos de línea, `base64.decode` y luego `utf8.decode`.
- Si un campo no tiene el tipo esperado, `_parse()` atrapa el error y lanza `UnexpectedJsonException`.
- La interfaz nunca usa mapas sueltos: solo recibe modelos.

## 5. Cómo se guarda y recupera en SQLite

- `lib/data/database_helper.dart` abre la base (`openDatabase`), con `version: 1`. `_onCreate` crea las cuatro tablas y `_onUpgrade` es donde irían las migraciones.
- Hay un repositorio por tabla en `lib/data/`:

| Operación | Ejemplo | Código |
|---|---|---|
| Crear | Agregar favorito | `db.insert('favorites', favorite.toJson())` |
| Consultar | Listar historial | `db.query('history', where: 'user_id = ?', whereArgs: [userId], orderBy: 'analyzed_at DESC')` |
| Actualizar | Editar nota | `db.update('favorites', {'note': ..., 'updated_at': ...}, where: 'id = ?', whereArgs: [id])` |
| Eliminar | Borrar del historial | `db.delete('history', where: 'id = ?', whereArgs: [id])` |

- Guardar: el modelo se convierte en mapa con `toJson()`. Recuperar: cada fila se convierte en modelo con `fromJson()`.
- `whereArgs` pasa los valores como parámetros. Así se evita la inyección SQL.
- El historial guarda el informe completo como texto JSON (`json_snapshot`), por eso se puede reabrir sin internet.
- `dbGuard()` envuelve cada operación y convierte las fallas en `DatabaseAppException`.

## 6. Autenticación

- `lib/services/auth_service.dart`.
- Registro: genera un **salt** aleatorio (`generateSalt`), calcula `sha256(salt + contraseña)` (`hashPassword`) y guarda el hash y el salt. La contraseña nunca se guarda.
- Login: busca al usuario por email, repite el hash con su salt y compara.
- Sesión: guarda el id del usuario en `shared_preferences`. El Splash la lee con `currentUser()`.
- Usuario demo: `ensureDemoUser()` lo crea la primera vez.
- Por qué salt: dos usuarios con la misma contraseña tienen hashes distintos, y no sirven las tablas precalculadas.

## 7. Cómo funcionan las validaciones

- Todas están en `lib/core/validators.dart`. Cada función devuelve `null` si el valor es válido o el mensaje de error.
- Se conectan con `validator:` en cada `TextFormField`. Al tocar el botón, `_formKey.currentState!.validate()` las ejecuta todas y pinta los mensajes.
- La URL se valida con una expresión regular (`_repoRegex`) que captura `owner` y `repo`, y acepta el protocolo, `www.`, `.git` y `/tree/...` como opcionales.
- El email duplicado no es validación de formato: lo revisa `AuthService.register` consultando la base.

## 8. Manejo de errores

- `lib/core/exceptions.dart`: una clase por tipo de error, todas hijas de `AppException`, cada una con su mensaje.
- `github_service.dart` las lanza; el provider las atrapa y las guarda en `error`; la pantalla muestra `ErrorView` (`lib/widgets/state_views.dart`) con el botón Reintentar.
- Límite de peticiones: `_resetAt()` lee `X-RateLimit-Reset` (segundos desde 1970) y lo convierte a hora.

## 9. Gestión de estado

- `provider` con `ChangeNotifier`. Los cinco providers están en `lib/providers/` y se registran en `lib/app.dart`.
- Patrón: el provider cambia sus datos y llama a `notifyListeners()`; las pantallas que hacen `context.watch<...>()` se redibujan.
- `context.read<...>()` se usa para ejecutar acciones sin redibujar.

## 10. Cómo modificar una validación

**Ejemplo: exigir 10 caracteres en la contraseña.**

1. Abre `lib/core/validators.dart`, método `password`.
2. Cambia `if (value.length < 8) return 'Debe tener al menos 8 caracteres';`
   por `if (value.length < 10) return 'Debe tener al menos 10 caracteres';`
3. Cambia el texto de ayuda en `lib/screens/register_screen.dart` (`helperText`).
4. Actualiza las pruebas que esperan el mensaje anterior: `test/unit/validators_test.dart` y `test/widget/auth_screens_test.dart`.
5. Corre `flutter test`.

Ojo: la contraseña del demo (`Demo1234`) tiene 8 caracteres. Sigue funcionando porque el login no aplica esta regla, solo el registro.

**Ejemplo: subir el máximo de la nota a 500.** Cambia `maxNoteLength` en `lib/core/constants.dart`. El validador y el contador del campo leen esa constante.

**Ejemplo: aceptar otra tecnología en la detección de stack.** Agrega una línea al mapa `_stackByFile` de `lib/services/analyzer.dart`, por ejemplo `'gemfile': 'Ruby',` (en minúsculas).

## 11. Cómo corregir un error sencillo

Método general:

1. Lee el mensaje: dice el archivo y la línea.
2. Corre `flutter analyze` para errores de código, o `flutter test` para errores de comportamiento.
3. Corrige y vuelve a correr.

Casos típicos:

| Síntoma | Dónde mirar | Arreglo |
|---|---|---|
| Un dato sale en 0 o vacío | `fromJson` del modelo | El nombre del campo JSON está mal escrito |
| "RenderFlex overflowed" | El `Row` o `Column` que indica el mensaje | Envolver el texto en `Expanded` o dar más alto |
| Siempre dice "Sin conexión" | `connectivity_service.dart` y el permiso INTERNET del `AndroidManifest.xml` | Revisar el permiso |
| No guarda en la base | El repositorio de esa tabla | El nombre de la columna en `toJson` no coincide con el `CREATE TABLE` |
| Cambié una tabla y falla al abrir | `database_helper.dart` | Subir `dbVersion` y escribir la migración en `_onUpgrade` (o desinstalar la app en desarrollo) |
| Un mensaje tiene una falta | Buscar el texto con el buscador del editor | Corregirlo también en la prueba que lo espera |

## 12. Quince preguntas probables

**1. ¿Dónde se hacen las peticiones a la API?**
En `lib/services/github_service.dart`. Todas pasan por el método `_get()`, que usa el paquete `http`.

**2. ¿Cómo conviertes el JSON en objetos?**
Con `jsonDecode` y luego el `fromJson` de cada modelo en `lib/models/`. La interfaz solo recibe modelos, no mapas.

**3. ¿Cómo guardas la contraseña?**
No la guardo. Guardo el hash SHA-256 de `salt + contraseña` y el salt, en la tabla `users`. Está en `auth_service.dart`, método `hashPassword`.

**4. ¿Para qué sirve el salt?**
Para que dos contraseñas iguales produzcan hashes distintos y no se puedan usar tablas de hashes ya calculados.

**5. ¿Qué pasa si no hay internet?**
`AnalysisProvider.load` revisa primero la caché; si no hay, `ConnectivityService` detecta que no hay red y se lanza `NoConnectionException`. La pantalla muestra el mensaje y el botón Reintentar. Los informes del historial sí se pueden abrir, porque están guardados.

**6. ¿Por qué hay una caché?**
Sin token, GitHub permite 60 peticiones por hora y cada análisis usa 6. La caché guarda el informe 30 minutos para no repetir peticiones.

**7. ¿Cómo se calcula la salud?**
En `Analyzer.healthChecks`: siete criterios con puntos que suman 100. README 20, licencia 15, `.gitignore` 10, descripción 15, commit en los últimos 90 días 20, más de un contribuidor 10 y temas 10.

**8. ¿Cómo detectas el stack?**
Por los nombres de los archivos de la raíz, con el mapa `_stackByFile`. Por ejemplo, `pubspec.yaml` indica Flutter/Dart.

**9. ¿Qué gestión de estado usas y por qué?**
`provider` con `ChangeNotifier`. Es la opción recomendada para empezar, separa la lógica de las pantallas y facilita las pruebas.

**10. ¿Qué es CRUD y dónde está completo?**
Crear, consultar, actualizar y eliminar. Está completo en favoritos (`favorite_repository.dart`): agregar, listar, editar la nota y eliminar.

**11. ¿Cómo probaste la app sin gastar peticiones?**
`GithubService` recibe el `http.Client` por constructor. En las pruebas le paso un `MockClient` con respuestas JSON de ejemplo (`test/mocks/mock_responses.dart`). Así simulo 404, 403, sin conexión y timeout.

**12. ¿Dónde se guarda el token de GitHub?**
En el almacenamiento seguro del dispositivo con `flutter_secure_storage` (`token_service.dart`). No está en el código ni en el repositorio, y la pantalla nunca lo muestra.

**13. ¿Qué pasa si cambias la estructura de una tabla?**
Subo `dbVersion` en `database_helper.dart` y escribo el cambio en `_onUpgrade`, que SQLite ejecuta en los teléfonos que ya tienen la versión anterior.

**14. ¿Cómo se adapta a una tableta?**
Con `LayoutBuilder` en `main_shell.dart`: si el ancho es de 720 px o más usa `NavigationRail` lateral en lugar de la barra inferior. Las cuadrículas pasan de 2 a 4 columnas.

**15. ¿Qué parte hizo la IA y qué parte hiciste tú?**
Yo definí los requisitos, la arquitectura y los criterios de aceptación. Claude Code generó el código, las pruebas y los borradores de la documentación. Yo lo revisé, lo probé en el teléfono y puedo explicar cada archivo. Está descrito en el apartado 16 del documento técnico y en la bitácora.

## 13. Antes de la defensa

- Abre la app y haz un análisis completo con internet.
- Ten a la mano `github_service.dart`, `analyzer.dart`, `validators.dart` y `database_helper.dart`.
- Practica el cambio del punto 10 en vivo.
- Corre `flutter test` una vez para mostrar que pasa.
