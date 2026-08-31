#!/usr/bin/env bash
# Pubblica un APK di ComUnity come release, con nome asset FISSO.
#
# Il nome fisso e' il punto: il sito punta a
#   .../releases/latest/download/comunity.apk
# che GitHub risolve sempre sull'ultima release. Cambiare il nome dell'asset
# (per esempio metterci dentro la versione) rompe il collegamento del sito, che
# resterebbe a puntare a un file inesistente senza dare errore prima del clic.
#
# Uso:
#   bash scripts/release-apk.sh <versione> [percorso-apk]
#   bash scripts/release-apk.sh 1.0.1
#
# Senza percorso prende l'APK dal repo del frontend accanto a questo
# ($SRV_ROOT non serve: si deriva dalla posizione dello script).

set -euo pipefail

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "Uso: bash scripts/release-apk.sh <versione> [percorso-apk]" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_APK="$REPO_ROOT/../comunity/frontend/build/app/outputs/flutter-apk/app-release.apk"
APK="${2:-$DEFAULT_APK}"

if [[ ! -f "$APK" ]]; then
  echo "APK non trovato: $APK" >&2
  echo "Compilalo prima:" >&2
  echo "  cd frontend && flutter build apk --release --dart-define=API_URL=https://app.comunity.solutions" >&2
  exit 1
fi

# La firma, prima di tutto. Senza android/key.properties la build NON fallisce:
# ripiega sulla chiave di debug e stampa solo un warning. Un APK firmato debug
# si installa, ma ha una firma diversa da quella delle release precedenti, e chi
# ce l'ha gia' installato non riesce ad aggiornare: deve disinstallare e
# perdere la sessione. Meglio accorgersene qui che dopo averlo distribuito.
APKSIGNER="$(ls "${ANDROID_SDK:-$HOME/AppData/Local/Android/Sdk}"/build-tools/*/apksigner 2>/dev/null | tail -1 || true)"
if [[ -n "$APKSIGNER" ]]; then
  CERT="$("$APKSIGNER" verify --print-certs "$APK" 2>/dev/null | grep -m1 'Subject' || true)"
  echo "Firma: $CERT"
  if echo "$CERT" | grep -qi 'Android Debug'; then
    echo "RIFIUTO: questo APK e' firmato con la chiave di DEBUG." >&2
    echo "Metti android/key.properties e il keystore, poi ricompila." >&2
    exit 1
  fi
else
  echo "ATTENZIONE: apksigner non trovato, firma NON verificata." >&2
fi

SIZE="$(du -h "$APK" | cut -f1)"
echo "APK: $APK ($SIZE)"

STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
cp "$APK" "$STAGING/comunity.apk"

TAG="v$VERSION"
NOTES="ComUnity $VERSION

Scarica **comunity.apk** e installalo dal telefono.
Per creare l'account serve un codice di invito: te lo da' chi ti ha invitato,
vale una volta sola.

Il collegamento del sito punta sempre all'ultima release."

if gh release view "$TAG" >/dev/null 2>&1; then
  echo "La release $TAG esiste gia': sostituisco l'asset."
  gh release upload "$TAG" "$STAGING/comunity.apk" --clobber
else
  gh release create "$TAG" "$STAGING/comunity.apk" \
    --title "ComUnity $VERSION" \
    --notes "$NOTES"
fi

echo
echo "Fatto. Il sito serve gia' questa versione:"
echo "  https://comunity.solutions"
echo "  $(gh repo view --json url --jq .url)/releases/latest/download/comunity.apk"
