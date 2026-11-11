# Evidencias de la API

Guarda aquí capturas que demuestren el consumo real de la API de GitHub. Puedes obtenerlas con el navegador, Postman o `curl`.

| Archivo | Qué debe mostrar |
|---|---|
| `01_repo.png` | Respuesta JSON de `GET https://api.github.com/repos/flutter/flutter` |
| `02_languages.png` | Respuesta de `/repos/flutter/flutter/languages` |
| `03_commits.png` | Respuesta de `/repos/flutter/flutter/commits?per_page=10` |
| `04_contributors.png` | Respuesta de `/repos/flutter/flutter/contributors?per_page=10` |
| `05_contents.png` | Respuesta de `/repos/flutter/flutter/contents` |
| `06_readme.png` | Respuesta de `/repos/flutter/flutter/readme` (campo `content` en base64) |
| `07_404.png` | Respuesta 404 de un repositorio que no existe |
| `08_rate_limit.png` | Encabezados `X-RateLimit-Limit`, `X-RateLimit-Remaining` y `X-RateLimit-Reset` |
| `09_app_vs_api.png` | La app y el JSON lado a lado con los mismos datos (estrellas, forks) |

Ejemplo para ver los encabezados del límite de peticiones:

```bash
curl -i https://api.github.com/repos/flutter/flutter
```
