#!/usr/bin/env bash
# Gerçek uygulama ekranlarını iOS simülatöründe çeker.
#
#   marketing/screenshots/scripts/capture.sh <simulator-udid> [ek flutter drive argümanları]
#
# - Simülatörü boot eder, durum çubuğunu 9:41 / dolu pil / tam sinyal yapar.
# - mobile/ klasörünü geçici bir kopyaya eşitleyip orada `flutter drive` çalıştırır
#   (repo'daki build/ klasörüne ve açık `flutter run` oturumlarına dokunmaz).
# - Test her karede `SOMINE_SHOT::<id>` yazar; betik `xcrun simctl io screenshot`
#   ile çeker ve onay dosyasını uygulamanın Documents klasörüne koyar.
# Çıktı: marketing/screenshots/public/raw/<id>.png
set -euo pipefail
UDID="${1:?simulator udid}"; shift || true
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
OUT="$ROOT/marketing/screenshots/public/raw"
WORK="${SOMINE_SHOT_WORKDIR:-${TMPDIR:-/tmp}/somine-shot-mobile}"
BUNDLE=com.somine.app
mkdir -p "$OUT" "$WORK"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState discharging \
  --batteryLevel 100 --cellularMode active --cellularBars 4 --wifiBars 3 \
  --dataNetwork wifi --operatorName ""

rsync -a --delete --exclude build --exclude .dart_tool \
  --exclude 'ios/.symlinks' "$ROOT/mobile/" "$WORK/"
cd "$WORK"
# Düzenek paketleri yalnız bu geçici kopyaya eklenir; repodaki pubspec'te yoklar,
# böylece integration_test eklentisi mağaza build'ine girmez.
dart pub add --dev 'integration_test:{"sdk":"flutter"}' 'flutter_driver:{"sdk":"flutter"}' \
  firebase_core_platform_interface:6.0.2 firebase_auth_platform_interface:7.7.3 >/dev/null
flutter pub get >/dev/null
LOG="$WORK/drive.log"; : > "$LOG"
flutter drive -d "$UDID" \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_store_screenshots_test.dart \
  --dart-define=SOMINE_API_BASE_URL=https://api.somine.test "$@" >"$LOG" 2>&1 &
DRIVE=$!

ack() {
  local data; data="$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)"
  mkdir -p "$data/Documents" && touch "$data/Documents/shot_ack_$1"
}
tail -n +1 -f "$LOG" | while IFS= read -r line; do
  echo "$line"
  if [[ "$line" == *"SOMINE_SHOT::"* ]]; then
    id="${line##*SOMINE_SHOT::}"; id="${id//[$'\r\n ']/}"
    xcrun simctl io "$UDID" screenshot --type=png "$OUT/$id.png" >/dev/null 2>&1
    ack "$id"
    echo ">>> captured $id"
  fi
  if [[ "$line" == *"All tests passed"* || "$line" == *"Some tests failed"* || "$line" == *"SOMINE_SHOTS_DONE"* ]]; then
    break
  fi
done || true
wait $DRIVE || true
echo "done -> $OUT"
