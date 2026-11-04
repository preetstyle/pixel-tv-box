# Technical Architecture & Implementation Details

This document explains the technical challenges and kernel/framework-level solutions implemented to transform a broken Google Pixel (Tensor G3, `shiba`) into a production-grade Android TV Box.

---

## 1. The Phantom Touch Problem (Digitizer Damage)

### The Problem
When a smartphone screen breaks physically, the capacitive digitizer often generates rapid, unpredictable phantom touch events. Even if an external display is attached, rogue touches on the phone screen will click buttons, dismiss videos, and cause erratic behavior.

### The Solution
Instead of disabling touch via software input filters (which still process interrupts and consume CPU cycles), we completely unload the hardware kernel module:
```sh
rmmod goodix_brl_touch
echo -n goodix_ts.0 > /sys/bus/platform/drivers/goodix_ts/unbind
```
- Executed during `post-fs-data` before Zygote and System Server spawn.
- A background loop continuously ensures the module is not re-probed.
- Result: **0 touch input devices** reported by `getevent -p`. Zero phantom touches.

---

## 2. 16:9 Aspect Ratio & Pixel-Perfect 1080p Scaling

### The Problem
Modern phones use tall aspect ratios (e.g. 20:9, 1080x2400). When mirrored onto a 16:9 TV (1080p/4K), standard mirroring produces thick black pillarboxes (bars on left and right) and blurry downscaled elements.

### The Solution
We force the Android Window Manager to render in a native 16:9 resolution:
```sh
wm size 1080x1920
wm density 320
```
- Orientation is permanently locked to landscape:
```sh
settings put system accelerometer_rotation 0
settings put system user_rotation 1
cmd window set-ignore-orientation-request -d 0 true
cmd window fixed-to-user-rotation -d 0 enabled
cmd window user-rotation -d 0 lock 1
```
- Result: Exact 16:9 aspect ratio filling the entire television screen edge-to-edge with crystal-clear 1080p/4K scaling.

---

## 3. Pure TV Kiosk Mode (Disabling the Status Bar Cleanly)

### The Problem
On Android phones, the top status bar (clock, battery icon, Wi-Fi icon) and bottom navigation bar remain visible on external displays, ruining the cinematic TV experience. Stock immersive mode (`immersive.status=*`) is often broken by apps requesting window insets.

### The Solution
We compiled a lightweight standalone Java daemon (`HideStatusBar.java`) that communicates directly with Android's internal `IStatusBarService` Binder interface:
```java
Class<?> sm = Class.forName("android.os.ServiceManager");
IBinder b = (IBinder) sm.getMethod("getService", String.class).invoke(null, "statusbar");
Object sb = Class.forName("com.android.internal.statusbar.IStatusBarService$Stub")
                 .getMethod("asInterface", IBinder.class).invoke(null, b);

// 0x001F0000 = DISABLE_SYSTEM_INFO (clock, icons, notification shade)
// Leaves Back/Home buttons and system input completely intact!
sb.getClass().getMethod("disableForUser", int.class, IBinder.class, String.class, int.class)
             .invoke(sb, 0x001F0000, new Binder(), "com.android.systemui", 0);
```
- Executed as a daemon via Android's native `app_process`.
- Result: The clock and battery icons are completely eliminated across all apps and launchers.

---

## 4. Multi-Display Auto-Mirror Handshake

### The Problem
Starting with Android 15/17, Google introduced `ConnectedDisplayDialog`. Whenever the phone is plugged into a **new TV or monitor** with an unknown EDID, SystemUI pauses video output and prompts:
*"Connect to external display: Mirror or Desktop"*.
Since the phone's built-in touchscreen is broken, the user cannot easily tap "Mirror", leaving the TV with a black or frozen screen.

### The Solution
Two complementary layers ensure instant auto-mirroring on ANY display:
1. **System Config Flags**:
   ```sh
   settings put secure mirror_built_in_display 1
   settings put global force_desktop_mode_on_external_displays 0
   device_config override lse_desktop_experience com.android.server.display.feature.flags.enable_display_content_mode_management false
   device_config override lse_desktop_experience com.android.window.flags.enable_projected_display_desktop_mode false
   device_config override systemui com.android.systemui.enable_compose_external_display_dialog false
   ```
2. **Real-time Auto-Confirm Watcher**:
   A lightweight watcher checks if `SystemUIDialog` for connected displays is focused. Within 1-2 seconds of plugging into any new TV, it taps "Don't ask again" and selects "Mirror display". Once saved, Android stores this preference permanently in `display-manager-state-v2.xml`.

---

## 5. 24/7 Docking, Battery & Thermal Protection

### The Problem
Phones docked to power and running as a TV box 24/7 can experience battery swelling or high internal temperatures.

### The Solution
1. **80% Battery Charge Limit**:
   ```sh
   settings put secure charge_optimization_mode 1
   ```
   Limits battery charging to 80% to preserve chemical battery longevity.
2. **Zero OLED Brightness**:
   ```sh
   settings put system screen_brightness_mode 0
   settings put system screen_brightness 0
   ```
   Turns off the phone's broken display backlighting entirely, keeping idle temperatures down to **26°C - 28°C**!
