#!/bin/sh
# Read-only device probe inside the short early-boot ADB window of a stock B16 F50. Writes nothing.
OUT=${1:-probe-$(date +%H%M%S).txt}
end=$(( $(date +%s) + 150 ))
while [ $(date +%s) -lt $end ]; do
    [ "$(adb get-state 2>/dev/null)" = device ] && break
    sleep 0.3
done
[ "$(adb get-state 2>/dev/null)" = device ] || { echo "timed out: no ADB window"; exit 1; }
echo "$(date +%H:%M:%S) ADB window caught, collecting -> $OUT"
adb shell '
echo "## id"; id
echo "## su"; for p in /system/bin/su /system/xbin/su /sbin/su /debug_ramdisk/su /data/adb/magisk; do [ -e $p ] && echo "EXISTS $p"; done; which su magisk 2>&1
echo "## props"
for p in ro.product.model ro.product.device ro.product.board ro.build.display.id ro.build.version.release ro.build.version.sdk ro.build.version.security_patch ro.build.date ro.build.fingerprint ro.boot.slot_suffix ro.boot.verifiedbootstate ro.boot.flash.locked ro.boot.vbmeta.device_state ro.boot.hardware ro.secure ro.debuggable ro.adb.secure ro.boot.ddrsize sys.usb.config sys.usb.state persist.sys.usb.config persist.adb.tcp.port service.adb.tcp.port init.svc.adbd ro.boot.mode; do echo "$p=$(getprop $p)"; done
echo "## blocks"; ls /sys/block
echo "mmcblk0_size=$(cat /sys/block/mmcblk0/size 2>&1)"
for b in /sys/block/mmcblk[1-9]; do [ -e $b ] && echo "$b size=$(cat $b/size 2>&1) type=$(cat $b/device/type 2>&1) name=$(cat $b/device/name 2>&1)"; done
echo "## partitions"; cat /proc/partitions 2>&1 | tail -n +1
echo "## by-name"; ls -l /dev/block/by-name 2>&1 | head -80
echo "## df"; df 2>&1 | head -30
echo "## mounts-sd"; grep -iE "mmcblk1|vold|sdcard" /proc/mounts 2>&1 | head
echo "## end"
' > "$OUT" 2>&1
echo "$(date +%H:%M:%S) done, $(wc -l < "$OUT") lines"
