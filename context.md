# Project Context: Soul Bloops

## 1. Vision General
- **Nombre:** Soul Bloops
- **Estudio:** Studio Sylf
- **Género:** Block Puzzle (Casual/Hiper-casual)
- **Plataforma:** Mobile (Android - Play Store)
- **Target:** Mercado masivo (Equilibrio entre estética "Cute" y "Cool/Premium").

## 2. Stack Tecnológico
- **Lenguaje:** Haxe
- **Engine:** Heaps.io
- **Target principal:** JavaScript (`-js bin/game.js`) + **Capacitor** para Android (AAB vía GitHub Actions).
- **Tienda:** Google Play (empaquetado WebView / Capacitor).
- **Publicidad (revivir):** puente JS `window.soulBloopsRewardedAd` + AdMob nativo (ver `docs/ADS_ANDROID.md`).

## 3. Mecánicas Core (MVP)
- **Grid:** Tablero de 8x8.
- **Piezas:** Generación de 3 piezas por turno siempre **colocables** en algún orden (con clears entre medias), sin exigir tablero vacío al final del trío.
- **Racha:** Multiplicador de puntos por líneas borradas en colocaciones consecutivas (se corta si colocas sin borrar línea).
- **Tablero limpio:** Bonus grande + celebración si tras un clear no queda ningún bloque.
- **Semilla inicial:** Tablero más vacío que el Block Blast denso.
- **Input:** Drag & Drop con `h2d.Interactive`. El área de touch debe ser mayor al sprite para evitar que el dedo tape la pieza.
- **Lógica de Limpieza:** Eliminar filas o columnas completas.
- **Satisfacción (Juiciness):** Efectos de partículas al limpiar líneas, animaciones de "rebote" (squash & stretch) en los Bloops.

## 4. Estética y Diseño
- **Personajes:** "Bloops" (Espíritus gelatinosos con ojos y expresiones).
- **Paleta:** Colores vibrantes (Neón-Pastel) sobre fondos oscuros para resaltar en pantallas móviles.
- **Skins:** Sistema de cambio de sprites para los bloques (ej: Skin de Cristal, Skin de Fuego, Skin de Caballero).

## 5. Economía y Monetización
- **Moneda Virtual:** "Bloop Coins" obtenidas al jugar.
- **Publicidad (AdMob):** - **Rewarded Ads:** "Last Chance" (Revivir limpiando parte del grid).
    - **Banner:** No intrusivo en la parte inferior.
- **In-App Purchases (IAP):** - "No Ads" (Elimina banners).
    - Compra de "Bloop Coins".
- **Power-ups:** Martillo (elimina un bloque) y Refresh (cambia piezas actuales).

## 6. Estructura de Archivos Deseada
- `src/Main.hx`: Punto de entrada (hxd.App).
- `src/game/Grid.hx`: Lógica del tablero y validaciones.
- `src/game/Bloop.hx`: Clase para los bloques individuales y sus estados.
- `src/game/Piece.hx`: Definición de formas y lógica de arrastre.
- `src/ui/HUD.hx`: Puntaje, monedas y botones.
- `src/utils/SaveManager.hx`: Persistencia de High Score y monedas.