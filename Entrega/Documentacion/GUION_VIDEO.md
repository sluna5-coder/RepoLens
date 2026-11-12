# Guion del video de demostración — RepoLens

**Duración objetivo:** 4 minutos (entre 3 y 5).
**Formato:** grabación de la pantalla del teléfono con voz. Ten internet y la app recién instalada.

| Tiempo | En pantalla | Qué decir |
|---|---|---|
| 0:00 – 0:20 | Splash y pantalla de login | "Hola, soy Saúl Luna Hernández, del grupo 5 B. Les presento RepoLens, una app hecha en Flutter que analiza cualquier repositorio público de GitHub y entrega un informe con lo esencial. No usa ningún servidor propio: consume la API de GitHub y guarda los datos en el teléfono." |
| 0:20 – 0:45 | Tocar Entrar con los campos vacíos; luego una contraseña incorrecta; luego "Usar" del usuario de prueba y Entrar | "El inicio de sesión es local. Si dejo los campos vacíos, los marca como obligatorios. Con una contraseña incorrecta avisa con un mensaje claro. Las contraseñas se guardan con hash SHA-256 y salt. Entro con el usuario de prueba." |
| 0:45 – 1:00 | Pantalla de Inicio; señalar las cuatro tarjetas y la barra inferior | "En Inicio están las funciones principales. La barra inferior lleva a Inicio, Analizar, Historial, Favoritos y Perfil." |
| 1:00 – 1:20 | Ir a Analizar; escribir `hola` y tocar Analizar; luego pegar `https://github.com/flutter/flutter` | "En Analizar pego la URL. Si no es de GitHub, la rechaza. Acepta la URL con o sin `https`, con `.git` o con `/tree`. Analizo el repositorio de Flutter." |
| 1:20 – 2:10 | Recorrer las pestañas: Resumen, Lenguajes, Commits, Archivos, README | "El Resumen muestra estrellas, forks, watchers, issues, licencia, fechas y el stack detectado por los archivos de la raíz. En Lenguajes hay una gráfica de pastel con los porcentajes. Aquí están los diez commits más recientes, los archivos de la raíz y el README renderizado." |
| 2:10 – 2:35 | Pestaña Salud | "Esta es la parte propia de la app: una puntuación de salud de 0 a 100. Se ve el desglose: si tiene README, licencia, `.gitignore`, descripción, commits recientes, más de un contribuidor y temas. También revisa si hay archivos sensibles, como un `.env`, y lanza una alerta de seguridad." |
| 2:35 – 3:00 | Tocar la estrella, escribir una nota y Guardar; ir a Favoritos; editar la nota; eliminar | "Lo guardo en favoritos con una nota. En Favoritos puedo editar la nota y eliminar, con confirmación. Es el CRUD completo sobre SQLite." |
| 3:00 – 3:20 | Historial: abrir una entrada; eliminar una | "Cada análisis queda en el Historial. Puedo reabrirlo, incluso sin internet, eliminarlo o vaciar todo." |
| 3:20 – 3:40 | Inicio → Comparar; escribir dos repos y Comparar | "También puedo comparar dos repositorios lado a lado. La tabla resalta el mejor valor de cada fila." |
| 3:40 – 4:00 | Activar el modo avión; analizar un repo nuevo; mostrar el error; quitar el modo avión y tocar Reintentar | "Si no hay conexión, la app lo dice y ofrece reintentar. Lo mismo pasa con un repositorio que no existe o cuando se alcanza el límite de peticiones." |
| 4:00 – 4:15 | Perfil: cambiar a tema oscuro; mostrar el campo del token | "En Perfil se cambia el tema y se puede guardar un token personal de GitHub, que queda cifrado solo en el dispositivo." |
| 4:15 – 4:30 | Terminal con `flutter test` terminando en "All tests passed!" | "El proyecto tiene 70 pruebas automatizadas que pasan, y `flutter analyze` no reporta problemas. Gracias." |

## Consejos de grabación

- Antes de grabar, analiza una vez `flutter/flutter` para confirmar que hay internet.
- Para la alerta de seguridad, busca con anticipación un repositorio público que tenga un archivo `.env` o `key.properties` en la raíz y analízalo en la toma de Salud.
- Si se alcanza el límite de 60 peticiones por hora, agrega un token en Perfil o espera a la hora que indica el mensaje.
- Graba en vertical, con el brillo alto y las notificaciones en silencio.
- Si pasas de 5 minutos, recorta la comparación o el tema oscuro.
