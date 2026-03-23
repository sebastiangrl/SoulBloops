# Soul Bloops

Block puzzle (Haxe + [Heaps](https://heaps.io)) — compila a **JS** para web y se empaqueta a **Android** con [Capacitor](https://capacitorjs.com/).

**Repo:** [github.com/sebastiangrl/SoulBloops](https://github.com/sebastiangrl/SoulBloops)

## Desarrollo web

```bash
haxe build.hxml
# Servir la carpeta del proyecto (no abras index.html como file://)
python3 -m http.server 8080
```

Abre `http://localhost:8080/index.html`.

## Android en la nube (recomendado)

Cada push a `main` / `master` ejecuta [`.github/workflows/android.yml`](.github/workflows/android.yml) y deja un **.aab** en **Actions → Android → Artifacts**.

Instrucciones y secretos de firma: **[docs/BUILD_ANDROID.md](docs/BUILD_ANDROID.md)**.

## Scripts npm

| Comando | Descripción |
|---------|-------------|
| `npm install` | Capacitor CLI y core |
| `npm run build:web` | `haxe build.hxml` + `build/android-www/` |
| `npm run android:sync` | Lo anterior + `npx cap sync android` (necesario antes de Gradle en local) |

## Estructura útil

- `src/` — código Haxe  
- `res/` — assets del juego  
- `android/` — proyecto Gradle (Capacitor)  
- `capacitor.config.json` — `appId`, `webDir: build/android-www`

## `git add .`

El **`.gitignore`** está armado para que no subas `node_modules/`, builds ni keystores, y **sí** el lockfile y el código. Detalle: **[docs/GIT.md](docs/GIT.md)**.
