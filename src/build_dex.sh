#!/usr/bin/env bash
set -e

# Compile HideStatusBar.java to classes.dex
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
PLATFORM_JAR="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}/platforms/android-34/android.jar"

if [ ! -f "$PLATFORM_JAR" ]; then
    PLATFORM_JAR=$(find /opt/homebrew /Users/$USER/Library/Android -name "android.jar" 2>/dev/null | head -n 1)
fi

echo "[*] Using platform jar: ${PLATFORM_JAR}"
mkdir -p "${BUILD_DIR}"

javac -cp "${PLATFORM_JAR}" --release 17 -d "${BUILD_DIR}" "${SCRIPT_DIR}/HideStatusBar.java"
d8 --output "${SCRIPT_DIR}/../magisk-module/kiosk" "${BUILD_DIR}/HideStatusBar.class"
mv "${SCRIPT_DIR}/../magisk-module/kiosk/classes.dex" "${SCRIPT_DIR}/../magisk-module/kiosk/hide_statusbar.dex"

echo "[✓] Built hide_statusbar.dex successfully!"
rm -rf "${BUILD_DIR}"
