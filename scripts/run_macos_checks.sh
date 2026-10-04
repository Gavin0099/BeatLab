#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test "$(uname -s)" = Darwin || { echo "This check requires macOS and Xcode." >&2; exit 1; }
BEATLAB_RESULT_DIR="TestResults/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$BEATLAB_RESULT_DIR"
xcodebuild -version | tee "$BEATLAB_RESULT_DIR/toolchain.txt"
swift --version | tee -a "$BEATLAB_RESULT_DIR/toolchain.txt"
swift test 2>&1 | tee "$BEATLAB_RESULT_DIR/core-tests.log"
xcrun clang -std=c11 -Wall -Wextra -Werror -O2 \
  -I Sources/BeatLabDSP/include Sources/BeatLabDSP/BeatLabDSP.c \
  Tests/DSPKernelTests/main.c -o "$BEATLAB_RESULT_DIR/dsp-tests"
"$BEATLAB_RESULT_DIR/dsp-tests" > "$BEATLAB_RESULT_DIR/dsp-tests.json"
python3 -m unittest discover -s Tests/TimingCaptureTests -v 2>&1 | tee "$BEATLAB_RESULT_DIR/capture-tests.log"
BEATLAB_SIMULATOR_ID="${1:-}"
if [ -z "$BEATLAB_SIMULATOR_ID" ]; then
  BEATLAB_SIMULATOR_ID=$(xcrun simctl list devices available -j | python3 -c 'import sys,json; devices=json.load(sys.stdin)["devices"]; phones=[d for runtime,items in devices.items() if "iOS" in runtime for d in items if d.get("isAvailable") and d["name"].startswith("iPhone")]; assert phones, "No available iPhone simulator"; print(phones[0]["udid"])')
fi
echo "Simulator: $BEATLAB_SIMULATOR_ID" | tee -a "$BEATLAB_RESULT_DIR/toolchain.txt"
xcodebuild build -project BeatLab.xcodeproj -scheme BeatLab \
  -destination "platform=iOS Simulator,id=$BEATLAB_SIMULATOR_ID" \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tee "$BEATLAB_RESULT_DIR/build.log"
xcodebuild test -project BeatLab.xcodeproj -scheme BeatLab \
  -destination "platform=iOS Simulator,id=$BEATLAB_SIMULATOR_ID" \
  -parallel-testing-enabled NO -resultBundlePath "$BEATLAB_RESULT_DIR/MVP.xcresult" \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tee "$BEATLAB_RESULT_DIR/app-tests.log"
echo "Automated checks passed. Device/playtest/release gates still require docs/mac-acceptance.md."
