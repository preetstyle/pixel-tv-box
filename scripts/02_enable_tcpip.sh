#!/system/bin/sh
# --------------------------------------------------------------------------
# 02_enable_tcpip.sh: Always-on Wireless ADB on port 5555
# Ensures wireless management across reboots without physical USB
# --------------------------------------------------------------------------

setprop service.adb.tcp.port 5555
stop adbd
start adbd
