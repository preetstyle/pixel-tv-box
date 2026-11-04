#!/usr/bin/env bash
# ==============================================================================
# Pixel to TV Box 1-Click ADB Installer
# Author: preetstyle
# Description: Automatically installs TV Box configuration onto a rooted Pixel
# ==============================================================================

set -e

echo "=== Pixel to TV Box 1-Click Installer ==="

# Check ADB connection
if ! command -v adb >/dev/null 2>&1; then
    echo "[-] Error: 'adb' command not found in PATH."
    exit 1
fi

DEVICE=$(adb devices | grep -v "List" | grep "device$" | head -n 1 | awk '{print $1}')
if [ -z "$DEVICE" ]; then
    echo "[-] Error: No active ADB device found. Connect via USB or Wi-Fi."
    exit 1
fi

echo "[+] Connected to device: $DEVICE"

# Verify root access
if ! adb -s "$DEVICE" shell "su -c 'id'" | grep -q "uid=0"; then
    echo "[-] Error: Device is not rooted or su access was denied."
    exit 1
fi

echo "[+] Root access verified."

# 1. Push Touchscreen Kill script
echo "[*] Installing Touchscreen Driver Kill..."
adb -s "$DEVICE" push scripts/01_disable_touch.sh /data/local/tmp/01_disable_touch.sh
adb -s "$DEVICE" shell "su -c 'mkdir -p /data/adb/post-fs-data.d && cp /data/local/tmp/01_disable_touch.sh /data/adb/post-fs-data.d/ && chmod 755 /data/adb/post-fs-data.d/01_disable_touch.sh'"

# 2. Push Wireless ADB script
echo "[*] Installing Always-On Wireless ADB (port 5555)..."
adb -s "$DEVICE" push scripts/02_enable_tcpip.sh /data/local/tmp/02_enable_tcpip.sh
adb -s "$DEVICE" shell "su -c 'mkdir -p /data/adb/service.d && cp /data/local/tmp/02_enable_tcpip.sh /data/adb/service.d/ && chmod 755 /data/adb/service.d/02_enable_tcpip.sh'"

# 3. Push HideStatusBar dex
echo "[*] Installing Status Bar Kiosk suppressor..."
adb -s "$DEVICE" push magisk-module/kiosk/hide_statusbar.dex /data/local/tmp/hide_statusbar.dex
adb -s "$DEVICE" shell "su -c 'mkdir -p /data/adb/kiosk && cp /data/local/tmp/hide_statusbar.dex /data/adb/kiosk/hide_statusbar.dex && chmod 644 /data/adb/kiosk/hide_statusbar.dex'"

# 4. Push Master TV Box script
echo "[*] Installing Master Android TV Orchestrator..."
adb -s "$DEVICE" push scripts/03_android_tv.sh /data/local/tmp/03_android_tv.sh
adb -s "$DEVICE" shell "su -c 'cp /data/local/tmp/03_android_tv.sh /data/adb/service.d/ && chmod 755 /data/adb/service.d/03_android_tv.sh'"

# 5. Clean up temporary files
adb -s "$DEVICE" shell "rm -f /data/local/tmp/01_disable_touch.sh /data/local/tmp/02_enable_tcpip.sh /data/local/tmp/03_android_tv.sh /data/local/tmp/hide_statusbar.dex"

# 6. Execute immediately without waiting for reboot
echo "[*] Starting TV Box daemon..."
adb -s "$DEVICE" shell "su -c 'nohup /data/adb/service.d/03_android_tv.sh >/dev/null 2>&1 &'"

echo "================================================="
echo "[✓] Setup complete! Your Pixel is now a TV Box."
echo "[✓] Plug in your USB-C HDMI hub to any TV & enjoy!"
echo "================================================="
