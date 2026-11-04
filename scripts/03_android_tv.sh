#!/system/bin/sh

# 1. Wait for system boot completed
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done
sleep 3

# 2. Disable lock screen & dismiss keyguard
locksettings set-disabled true
cmd window dismiss-keyguard
input keyevent 82
input keyevent 3

# 3. Disable Pixel Launcher permanently (removes Taskbar and bottom navigation bar completely)
pm disable-user --user 0 com.google.android.apps.nexuslauncher

# 4. 16:9 Aspect Ratio & Pixel-Perfect 1080p Resolution
wm size 1080x1920
wm density 320

# 5. Permanent Landscape Lock
settings put system accelerometer_rotation 0
settings put system user_rotation 1
cmd window set-ignore-orientation-request -d 0 true
cmd window fixed-to-user-rotation -d 0 enabled
cmd window user-rotation -d 0 lock 1

# 6. Disable navigation bar & gesture hints, enable cutout removal
cmd overlay disable com.android.internal.systemui.navbar.threebutton
cmd overlay enable com.android.internal.systemui.navbar.gestural
settings put secure navigation_bar_gesture_hint 0
cmd overlay enable com.android.internal.display.cutout.emulation.noCutout
settings put global policy_control immersive.status=*

# 7. Android TV Keyboard (LeanKeyboard)
ime enable org.liskovsoft.androidtv.rukeyboard/com.liskovsoft.leankeyboard.ime.LeanbackImeService
ime set org.liskovsoft.androidtv.rukeyboard/com.liskovsoft.leankeyboard.ime.LeanbackImeService

# 8. Launch HideStatusBar daemon ONLY if not already running (cleanly disables clock, status icons, notifications)
if ! ps -A | grep -v grep | grep -qi "hide_statusbar"; then
    nohup app_process -Djava.class.path=/data/adb/kiosk/hide_statusbar.dex /system/bin HideStatusBar >/data/local/tmp/hide_sb.log 2>&1 &
fi

# 9. Force Screen Mirroring globally & prevent desktop mode prompt
settings put secure mirror_built_in_display 1
settings put global force_desktop_mode_on_external_displays 0
device_config override lse_desktop_experience com.android.server.display.feature.flags.enable_display_content_mode_management false 2>/dev/null
device_config override lse_desktop_experience com.android.window.flags.enable_projected_display_desktop_mode false 2>/dev/null
device_config override systemui com.android.systemui.enable_compose_external_display_dialog false 2>/dev/null

svc power stayon true
settings put system screen_off_timeout 2147483647

# 10. TV Box Power & Battery Optimizations
# - Limit charge to 80% to protect battery 24/7
settings put secure charge_optimization_mode 1
# - Zero internal broken screen brightness to reduce heat & power draw
settings put system screen_brightness_mode 0
settings put system screen_brightness 0

# 11. Set GlassTV as home launcher
cmd package set-home-activity com.techgenius.tvoslauncher/.MainActivity

# 12. Ensure Touchscreen Kernel Module is completely unloaded
rmmod goodix_brl_touch 2>/dev/null
if [ -e /sys/bus/platform/drivers/goodix_ts/goodix_ts.0 ]; then
    echo -n goodix_ts.0 > /sys/bus/platform/drivers/goodix_ts/unbind 2>/dev/null
fi

# 13. Background watcher daemon:
# - Auto-enables connected external display
# - Auto-confirms Mirroring if External Display dialog appears on any new TV
# - Permanently ensures touchscreen remains dead and unloaded
while true; do
    # Keep touchscreen completely unloaded
    rmmod goodix_brl_touch 2>/dev/null
    if [ -e /sys/bus/platform/drivers/goodix_ts/goodix_ts.0 ]; then
        echo -n goodix_ts.0 > /sys/bus/platform/drivers/goodix_ts/unbind 2>/dev/null
    fi

    # Explicitly ensure any connected external displays are enabled
    ext_ids=$(cmd display get-displays --type external -i 2>/dev/null)
    for id in $ext_ids; do
        if [ -n "$id" ]; then
            cmd display enable-display "$id" >/dev/null 2>&1
        fi
    done

    # If External Display Connection Dialog pops up on ANY new TV:
    # Auto-check "Don't ask again" and auto-click "Mirror display"
    if dumpsys window | grep -q "mCurrentFocus=Window{.*SystemUIDialog.*}"; then
        # Tap "Remember choice" checkbox then "Mirror display" button
        input tap 500 668 2>/dev/null
        sleep 0.2
        input tap 912 884 2>/dev/null
    fi

    sleep 3
done &
