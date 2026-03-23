# Build Android (GitHub Actions + Capacitor)

El juego se compila a **JavaScript** (`haxe build.hxml`) y se empaqueta con **Capacitor** en la carpeta `android/`. El workflow **`.github/workflows/android.yml`** hace todo en la nube en cada push a `main` / `master` o al pulsar **Run workflow** en GitHub.

## Artefacto que descargas

| Situación | Archivo | Uso |
|-----------|---------|-----|
| Configuraste los **4 secretos** de firma | `soul-bloops-release` → `app-release.aab` | Subir a **Google Play** (pruebas o producción) |
| Sin secretos | `soul-bloops-debug` → `app-debug.aab` | Probar en dispositivo; **no** sirve como release en Play |

## Firma para Play: qué son las 4 cosas

GitHub Actions necesita **firmar** el AAB. Para eso usas un **archivo keystore** (`.jks`) y **tres textos** que tú inventas al crearlo:

| Secreto en GitHub | Qué es en la práctica |
|-------------------|------------------------|
| `ANDROID_KEYSTORE_BASE64` | El archivo `.jks` convertido a **texto base64** (una ristra larga). No es una contraseña. |
| `ANDROID_KEYSTORE_PASSWORD` | La **contraseña del almacén** (la primera que te pide `keytool`). |
| `ANDROID_KEY_ALIAS` | El **alias** de la clave: en el comando de abajo pusimos `soul` → el valor en GitHub es exactamente `soul`. |
| `ANDROID_KEY_PASSWORD` | La **contraseña de esa clave**. Si al crearla pulsaste Enter para que sea la misma que el almacén, aquí va **la misma** que `ANDROID_KEYSTORE_PASSWORD`. |

**Importante:** guarda el `.jks` y las contraseñas en un sitio seguro. Si los pierdes, no podrás actualizar la misma app en Play con el mismo certificado.

---

## Paso a paso (hazlo una vez en tu Mac)

### Paso 1 — Abre la Terminal y entra en una carpeta segura

Por ejemplo tu Escritorio o Documentos:

```bash
cd ~/Desktop
```

### Paso 2 — Crea el keystore con `keytool`

Copia y pega **todo** el comando (es una sola línea):

```bash
keytool -genkey -v -keystore soul-bloops.jks -alias soul -keyalg RSA -keysize 2048 -validity 10000
```
studio2299Jhon
Te irá preguntando cosas. Guía rápida:

1. **Contraseña del almacén de claves** → inventa una y **apúntala**. Esa será `ANDROID_KEYSTORE_PASSWORD` en GitHub.
2. **Volver a escribir la misma contraseña** → la repites.
3. Nombre, organización, ciudad… → puedes poner datos reales o lo mínimo; no afecta a Play como el certificado técnico.
4. **¿Correcto?** → escribe `sí` o `yes`.
5. **Contraseña para \<soul\>** → si quieres la misma que el almacén, solo pulsa **Enter**. Si inventas otra, **apúntala**: será `ANDROID_KEY_PASSWORD` en GitHub.

Al final debe existir el archivo **`soul-bloops.jks`** en esa carpeta (`~/Desktop` si usaste el `cd` de arriba).

- El **alias** que usamos en el comando es **`soul`** → en GitHub el secreto `ANDROID_KEY_ALIAS` será exactamente: `soul` (sin comillas).

### Paso 3 — Pasa el `.jks` a base64 (para el primer secreto)

Sigue en la misma carpeta donde quedó `soul-bloops.jks`.

**En Mac:**

```bash
base64 -i soul-bloops.jks | tr -d '\n' | pbcopy
```

Eso copia **una sola línea** larga al portapapeles. Eso es lo que pegarás en GitHub.

**Si quieres verlo en pantalla** (y copiarlo a mano):

```bash
base64 -i soul-bloops.jks | tr -d '\n'
```

**En Windows (PowerShell),** en la carpeta del `.jks`:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("soul-bloops.jks")) | Set-Clipboard
```

(o copia la salida del mismo comando sin `Set-Clipboard`).

### Paso 4 — Crea los 4 secretos en GitHub

1. Entra a tu repo: `https://github.com/sebastiangrl/SoulBloops`
2. **Settings** (ajustes del repo)
3. En el menú izquierdo: **Secrets and variables** → **Actions**
4. **New repository secret** cuatro veces:

| Name (nombre exacto) | Secret (valor) |
|------------------------|----------------|
| `ANDROID_KEYSTORE_BASE64` | Pega **toda** la línea base64 del Paso 3 (sin espacios ni saltos de línea al inicio/final). |
| `ANDROID_KEYSTORE_PASSWORD` | La contraseña del **almacén** que elegiste en el Paso 2. |
| `ANDROID_KEY_ALIAS` | Escribe tal cual: `soul` (si no cambiaste el `-alias` del comando). |
| `ANDROID_KEY_PASSWORD` | La contraseña de la **clave**; si en el Paso 2 pulsaste Enter, es **la misma** que `ANDROID_KEYSTORE_PASSWORD`. |

5. Guarda cada uno con **Add secret**.

### Paso 5 — Vuelve a generar el AAB en Actions

- **Actions** → workflow **Android** → **Run workflow**, o haz un push a `main`.

Cuando termine bien, descarga el artefacto **soul-bloops-release** (`app-release.aab`) y súbelo a Play Console.

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
