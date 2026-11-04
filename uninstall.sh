#!/usr/bin/env bash
# ==============================================================================
# Pixel to TV Box Uninstaller
# Author: preetstyle
# Description: Restores phone back to stock resolution, touch driver, and launcher
# ==============================================================================

set -e

DEVICE=$(adb devices | grep -v "List" | grep "device$" | head -n 1 | awk '{print $1}')
if [ -z "$DEVICE" ]; then
    echo "[-] Error: No active ADB device found."
    exit 1
fi

echo "[*] Restoring Pixel back to standard phone configuration..."

adb -s "$DEVICE" shell "su -c '
    # Remove service scripts
    rm -f /data/adb/post-fs-data.d/01_disable_touch.sh
    rm -f /data/adb/service.d/01_disable_touch.sh
    rm -f /data/adb/service.d/02_enable_tcpip.sh
    rm -f /data/adb/service.d/03_android_tv.sh
    rm -rf /data/adb/kiosk

    # Kill background watchers
    pkill -f 03_android_tv.sh
    pkill -f HideStatusBar

    # Re-enable Pixel Launcher
    pm enable com.google.android.apps.nexuslauncher

    # Reset resolution & density
    wm size reset
    wm density reset

    # Reset auto-rotation
    settings put system accelerometer_rotation 1
    cmd window set-ignore-orientation-request -d 0 false
    cmd window fixed-to-user-rotation -d 0 disabled

    # Reset display brightness
    settings put system screen_brightness 128
'"

echo "[✓] Phone restored to stock! Please reboot your device."
