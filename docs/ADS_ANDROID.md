# Anuncios premiados (revivir) — qué hacer en la práctica

El juego **ya está programado**: al pulsar «Revivir» llama a **`window.soulBloopsRewardedAd.show({ onRewarded, onDismissed, onFailed })`** si ese objeto existe (`src/game/RewardedAdBridge.hx`).  

Tu trabajo es **1)** crear la unidad en AdMob, **2)** inicializar el SDK en Android y **3)** definir ese objeto global **antes** de que cargue `bin/game.js`.

---

## 1. Consola de AdMob

1. Entra en [admob.google.com](https://admob.google.com) con la misma cuenta / organización que usarás en Play Console.
2. **Añadir aplicación** → Android → mismo `applicationId` que en el proyecto (`com.studiosylf.soulbloops` o el que uses).
3. Anota el **ID de la aplicación** AdMob (formato `ca-app-pub-xxxxxxxx~yyyyyyyyyy`). Lo pondrás en el `AndroidManifest`.
4. Crea una unidad **Recompensas** (Rewarded) y copia el **ID de la unidad** (`ca-app-pub-xxxxxxxx/zzzzzzzzzz`).
5. Mientras desarrollas, Google ofrece **IDs de prueba** oficiales (anuncios de demo) — úsalos hasta que la app esté estable; luego sustituye por tu ID real.

---

## 2. Android: dependencia y manifiesto

### `android/app/build.gradle` (dependencies)

Añade (revisa la [versión actual](https://developers.google.com/admob/android/quick-start) en la documentación de Google):

```gradle
implementation 'com.google.android.gms:play-services-ads:23.6.0'
```

### `android/app/src/main/AndroidManifest.xml`

Dentro de `<application …>` (hermano de `<activity>`), metadatos con **tu** App ID de AdMob:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxxxxx~yyyyyyyyyy"/>
```

Sin esto, el SDK puede cerrar la app o no mostrar anuncios.

También debe existir (ya está en el repo) el permiso **`com.google.android.gms.permission.AD_ID`**: en **Android 13+** sin él el identificador de publicidad son solo ceros y Play Console puede marcar error si en la ficha indicaste que la app usa ID de publicidad. Si **no** usas anuncios ni analíticas con AD ID, quita ese permiso y actualiza la declaración en Play Console en su lugar.

---

## 3. Dos formas de conectar el juego

### Opción A — Plugin de Capacitor (recomendada si quieres mantener todo en JS/TS)

1. En la raíz del repo (donde está `package.json`):

   ```bash
   npm install @capacitor-community/admob
   npx cap sync android
   ```

2. Sigue el README del plugin: [capacitor-community/admob](https://github.com/capacitor-community/admob) — **inicializar AdMob** al arrancar la app (`AdMob.initialize`, etc.).

3. Implementa un **puente** que asigne `window.soulBloopsRewardedAd` y por dentro use `prepareRewardVideoAd` / `showRewardVideoAd` y los eventos `RewardAdPluginEvents` (`Rewarded`, `Dismissed`, `FailedToLoad`, `FailedToShow`, …) mapeando a:
   - `onRewarded` → usuario ganó la recompensa (revivir en el juego),
   - `onDismissed` → cerró sin recompensa o flujo equivalente,
   - `onFailed` → sin inventario / error.

4. Ese código debe ejecutarse **antes** de `game.js`. Opciones habituales:
   - un pequeño bundle (p. ej. **esbuild** / **Vite**) que genere un `admob-bridge.js` y lo copies a `build/android-www/` junto al resto, o
   - cargar el módulo del plugin como indica la documentación de Capacitor para tu versión.

5. `npm run android:sync` y genera el AAB como en [BUILD_ANDROID.md](BUILD_ANDROID.md).

**Ventaja:** menos código Java. **Inconveniente:** necesitas una capa JS que importe el plugin (suele implicar bundler o el flujo que documente el plugin para Capacitor 6).

---

### Opción B — Solo Android (Java/Kotlin + WebView)

1. Inicializa Mobile Ads una vez (p. ej. en `Application.onCreate` o al inicio de `MainActivity` tras `super.onCreate()`):

   ```java
   MobileAds.initialize(this, initializationStatus -> {});
   ```

2. Carga y muestra un [`RewardedAd`](https://developers.google.com/admob/android/rewarded) con tu ID de unidad.

3. Expón el contrato al WebView de Capacitor cuando la página esté lista, por ejemplo con `WebView.evaluateJavascript` o un `@JavascriptInterface`, de modo que exista:

   ```js
   window.soulBloopsRewardedAd = {
     show: function (opts) {
       // Mostrar el RewardedAd; al completar recompensa → opts.onRewarded()
       // Al cerrar anuncio → opts.onDismissed()
       // Sin anuncio / error → opts.onFailed()
     }
   };
   ```

4. Cuidado con **hilos**: las callbacks del SDK suelen ir en hilos de fondo; las llamadas a `evaluateJavascript` y la UI deben ir en el **hilo principal**.

**Ventaja:** no dependes del bundler JS del plugin. **Inconveniente:** más código nativo y mantenimiento.

---

## 4. Consentimiento y políticas (obligatorio en muchos países)

- Si sirves anuncios personalizados en UE / UK / Suiza, necesitas **mensaje de consentimiento** (p. ej. **UMP** — User Messaging Platform de Google). Lo configuras en AdMob y lo integras en la app nativa o vía plugin que lo soporte.
- Actualiza **Seguridad de los datos** en Play Console según lo que recopile **AdMob** (identificadores, diagnóstico, etc.), no solo tu juego.
- Cumple las políticas de **contenido** y de **anuncios** de Google Play.

Detalle de cumplimiento: documentación oficial de AdMob y Play Console.

---

## 5. Comportamiento del juego (recordatorio)

| Situación | Qué pasa |
|-----------|----------|
| `soulBloopsRewardedAd` **no** existe y el host es **localhost / 127.0.0.1 / file** | Simula revivir tras ~450 ms (desarrollo). |
| `soulBloopsRewardedAd` **no** existe en **producción** (HTTPS real) | El botón revivir dispara `onFailed` → mensaje en UI. |
| Bridge bien configurado | Revivir **una vez por partida**; luego solo «Jugar de nuevo». |

---

## 6. Revivir en gameplay

- Tras un anuncio completado, el juego repone un trío jugable y mantiene puntuación y tablero.
- Tras usar revivir, el botón de anuncio se oculta hasta la siguiente partida.

---

## Referencias

- Build AAB: [BUILD_ANDROID.md](BUILD_ANDROID.md).
- Contrato Haxe: `src/game/RewardedAdBridge.hx`.
