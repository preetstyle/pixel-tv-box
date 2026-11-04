#!/system/bin/sh
# --------------------------------------------------------------------------
# 01_disable_touch.sh: Unload Touchscreen Kernel Driver (Goodix)
# Prevents phantom touches from broken digitizer
# --------------------------------------------------------------------------

# Force kernel module unload
rmmod goodix_brl_touch 2>/dev/null

# Unbind platform device if still bound
if [ -e /sys/bus/platform/drivers/goodix_ts/goodix_ts.0 ]; then
    echo -n goodix_ts.0 > /sys/bus/platform/drivers/goodix_ts/unbind 2>/dev/null
fi
