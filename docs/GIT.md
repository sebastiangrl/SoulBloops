# Git: qué sube con `git add .` y qué no

Este proyecto está pensado para que uses **`git add .`** sin subir basura ni secretos. El **workflow de Android** en GitHub solo necesita lo que hay en el repo **fuente**; en el runner vuelve a generar todo lo ignorado.

## Sí debe estar en el repositorio

| Qué | Para qué |
|-----|----------|
| `src/`, `res/`, `index.html`, `build.hxml` | Juego y assets |
| `package.json` + **`package-lock.json`** | `npm ci` en CI (versiones fijas de Capacitor) |
| `capacitor.config.json` | Id de app y `webDir` |
| `android/` (código Gradle, `gradlew`, manifests, Java, etc.) | Proyecto nativo Capacitor |
| `.github/workflows/android.yml` | Build en la nube |
| `scripts/sync-www-for-android.sh` | Mismo empaquetado que usa CI |
| `docs/`, `README.md`, `context.md` | Documentación |
| **`bin/game.js`** (opcional pero recomendado si compilas antes de commit) | Probar en web sin Haxe tras un `git clone` |

## No debe estar en el repositorio (`.gitignore`)

| Qué | Motivo |
|-----|--------|
| `node_modules/` | Se instala con `npm ci` / `npm install` |
| `build/` | Salida de `sync-www-for-android.sh`; CI la crea de nuevo |
| `android/app/src/main/assets/public/` | Copia de `game.js` + `res/` tras `cap sync`; CI la regenera |
| `android/**/build/`, `android/.gradle/` | Artefactos de Gradle en tu máquina |
| `android/local.properties` | Rutas SDK locales (distintas en cada PC) |
| `*.jks`, `*.keystore`, `keystore.properties` | Firmas: solo en GitHub **Secrets**, no en git |

## GitHub Actions

El workflow **no depende** de que subas `build/` ni `public/`. Hace:

1. `haxe build.hxml` → `bin/game.js`
2. `scripts/sync-www-for-android.sh` → `build/android-www/`
3. `npx cap sync android` → rellena `android/.../public/`
4. `./gradlew bundleRelease` o `bundleDebug`

## Si no quieres versionar `bin/game.js`

Descomenta en `.gitignore` la línea `/bin/game.js`. Entonces quien clone **debe** tener Haxe y ejecutar `haxe build.hxml` antes de probar en web o antes de `npm run android:sync` en local.
