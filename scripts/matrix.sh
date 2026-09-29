#!/bin/sh
# Runs each app's UI tests on every iOS simulator runtime given and prints the results.
#
#   scripts/matrix.sh [runtime ...]      runtimes default to 17-2 26-5 27-0
#
# A test passes when winit's window is on screen. Result bundles and logs go to build/matrix/.
set -eu

cd "$(dirname "$0")/.."
RUNTIMES=${*:-17-2 26-5 27-0}
SCHEMES="NoManifest SceneManifest"
TESTS="WindowIsShown FullscreenWindowIsShown"
OUT=$PWD/build/matrix
rm -rf "$OUT" && mkdir -p "$OUT"

xcodegen generate --quiet
for SCHEME in $SCHEMES; do
  xcodebuild build-for-testing -quiet -project WinitSceneIntegration.xcodeproj -scheme "$SCHEME" \
    -destination "generic/platform=iOS Simulator" -derivedDataPath build/DerivedData
done

device() {
  name=winit-scene-integration-$1
  udid=$(xcrun simctl list devices -j | python3 -c "
import json, sys
for devices in json.load(sys.stdin)['devices'].values():
    for d in devices:
        if d['name'] == '$name' and d['isAvailable']:
            print(d['udid']); break")
  if [ -z "$udid" ]; then
    udid=$(xcrun simctl create "$name" com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro \
      "com.apple.CoreSimulator.SimRuntime.iOS-$1")
  fi
  echo "$udid"
}

printf '%-38s' ""
for RUNTIME in $RUNTIMES; do printf '%-22s' "iOS $RUNTIME"; done
echo
for SCHEME in $SCHEMES; do
  for TEST in $TESTS; do
    printf '%-38s' "$SCHEME $TEST"
    for RUNTIME in $RUNTIMES; do
      RUN=$OUT/$SCHEME-$TEST-$RUNTIME
      if xcodebuild test-without-building -project WinitSceneIntegration.xcodeproj \
        -scheme "$SCHEME" -destination "id=$(device "$RUNTIME")" \
        -only-testing:"${SCHEME}UITests/WindowTests/test$TEST" \
        -derivedDataPath build/DerivedData -resultBundlePath "$RUN.xcresult" \
        -collect-test-diagnostics never >"$RUN.log" 2>&1
      then
        RESULT=PASS
      elif grep -q "window not shown" "$RUN.log"; then
        RESULT="FAIL (not shown)"
      else
        RESULT="FAIL (crashed)"
      fi
      printf '%-22s' "$RESULT"
    done
    echo
  done
done

# Linking a symbol UIKit only has from iOS 13 keeps an app from launching on earlier versions.
BINARY=build/DerivedData/Build/Products/Debug-iphonesimulator/SceneManifest.app/SceneManifest
if nm -u "$BINARY" | grep -q UIScene; then
  echo "Links UIScene symbols: yes"
else
  echo "Links UIScene symbols: no"
fi
