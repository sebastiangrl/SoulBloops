#!/usr/bin/env bash
# Empaqueta lo necesario para un WebView Android en build/android-www/
# Uso: ./scripts/sync-www-for-android.sh
# Luego copia build/android-www/* a app/src/main/assets/www/ de tu proyecto Android.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/build/android-www"

mkdir -p "${OUT}/bin"
cp "${ROOT}/index.html" "${OUT}/"
cp "${ROOT}/bin/game.js" "${OUT}/bin/"
rm -rf "${OUT}/res"
cp -R "${ROOT}/res" "${OUT}/res"

echo "OK → ${OUT}"
echo "Capacitor: npm run android:sync (copia a android/app/src/main/assets/public/)"
