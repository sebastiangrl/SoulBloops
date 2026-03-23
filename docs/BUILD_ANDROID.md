# Build Android (GitHub Actions + Capacitor)

El juego se compila a **JavaScript** (`haxe build.hxml`) y se empaqueta con **Capacitor** en la carpeta `android/`. El workflow **`.github/workflows/android.yml`** hace todo en la nube en cada push a `main` / `master` o al pulsar **Run workflow** en GitHub.

## Artefacto que descargas

| Situación | Archivo | Uso |
|-----------|---------|-----|
| Configuraste los **4 secretos** de firma | `soul-bloops-release` → `app-release.aab` | Subir a **Google Play** (pruebas o producción) |
| Sin secretos | `soul-bloops-debug` → `app-debug.aab` | Probar en dispositivo; **no** sirve como release en Play |

## Secretos en GitHub (Settings → Secrets and variables → Actions)

Crea un keystore local una vez:

```bash
keytool -genkey -v -keystore soul-bloops.jks -alias soul -keyalg RSA -keysize 2048 -validity 10000
```

Luego (macOS/Linux):

```bash
base64 -i soul-bloops.jks | pbcopy   # o: base64 -w0 soul-bloops.jks
```

En GitHub añade **Repository secrets**:

| Nombre | Valor |
|--------|--------|
| `ANDROID_KEYSTORE_BASE64` | Salida **una línea** del `base64` del `.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | Contraseña del keystore |
| `ANDROID_KEY_ALIAS` | Alias (ej. `soul`) |
| `ANDROID_KEY_PASSWORD` | Contraseña de la clave (a veces igual que la del keystore) |

Tras guardarlos, vuelve a ejecutar el workflow: el artefacto **release** estará listo para Play Console.

## Rama y disparadores

- Push a **`main`** o **`master`**.
- Manual: pestaña **Actions** → workflow **Android** → **Run workflow**.

## Build en tu máquina (opcional)

```bash
npm install
npm run android:sync    # haxe + sync-www + cap sync
cd android && ./gradlew bundleRelease   # necesitas JDK 17 + ANDROID_HOME + keystore vía env (ver abajo)
```

Variables de entorno para firmar igual que en CI:

- `ANDROID_KEYSTORE_FILE` — ruta absoluta al `.jks`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

## Google Play Console

1. Crea la app con el mismo **applicationId** que en `capacitor.config.json` / `android/app/build.gradle` (`com.studiosylf.soulbloops` por defecto; cámbialo si ya registraste otro paquete).
2. Sube el **AAB** en **Prueba interna** o **Cerrada**.
3. Rellena ficha, política de privacidad, datos y clasificación.

## Más documentación

- [`ADS_ANDROID.md`](ADS_ANDROID.md) — anuncios premiados (`window.soulBloopsRewardedAd`).
- [`FIGURAS.md`](FIGURAS.md) — piezas del tablero.
