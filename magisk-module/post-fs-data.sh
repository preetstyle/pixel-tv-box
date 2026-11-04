#!/system/bin/sh
MODDIR=${0%/*}

# Unload touchscreen driver early at post-fs-data to prevent phantom touches
rmmod goodix_brl_touch 2>/dev/null
if [ -e /sys/bus/platform/drivers/goodix_ts/goodix_ts.0 ]; then
    echo -n goodix_ts.0 > /sys/bus/platform/drivers/goodix_ts/unbind 2>/dev/null
fi
