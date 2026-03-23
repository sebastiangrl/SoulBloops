# Anuncios premiados (revivir) — integración Android / WebView

El juego llama a un objeto global **`window.soulBloopsRewardedAd`** si existe. Así la capa nativa (AdMob, Google Mobile Ads) puede mostrar un **rewarded ad** sin acoplar el código Haxe al SDK.

## Contrato JavaScript

Asignar **antes** de cargar `bin/game.js`:

```js
window.soulBloopsRewardedAd = {
  show: function (opts) {
    // opts.onRewarded  — llamar cuando el usuario gane la recompensa
    // opts.onDismissed — anuncio cerrado sin recompensa
    // opts.onFailed    — sin anuncio / error (opcional: string mensaje)

    // Ejemplo esquemático con AdMob (Kotlin/Java en tu Activity + WebView):
    // rewardedAd.show(activity, onUserEarnedReward -> { opts.onRewarded(); });
    // onAdDismissedFullScreenContent -> { opts.onDismissed(); };
  },
};
```

- Si **`soulBloopsRewardedAd` no existe**, en **localhost / 127.0.0.1 / file** el juego **simula** éxito tras ~450 ms (desarrollo).
- En **producción web** sin bridge, el botón de revivir puede mostrar que no está disponible (comportamiento definido en `Main`).

## Revivir en gameplay

- **Una vez por partida**: tras revivir, el tablero y la puntuación se mantienen; se repone un trío de piezas jugable.
- Tras usar revivir, solo queda **Jugar de nuevo** hasta la siguiente partida.

## Google Play / AdMob

1. Añadir dependencia **Google Mobile Ads** al módulo Android.
2. Crear **RewardedAd** con el id de unidad de tu consola AdMob.
3. Desde `WebView.addJavascriptInterface` o `evaluateJavascript`, exponer el objeto anterior al `window` de la página que carga `index.html`.

Detalles de políticas (edad, consentimiento GDPR/UMP, límite de frecuencia) van en la app nativa, no en este repo.

Build y AAB: [BUILD_ANDROID.md](BUILD_ANDROID.md).
