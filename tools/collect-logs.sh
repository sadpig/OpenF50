#!/bin/sh
# After a trial falls back to Android: collect LK log, pstore and the init log persisted in the Linux boot partition.
set -eu
# su location resolution + su_do/dev_pull (Magisk 26+/patched B16 keep su in /debug_ramdisk)
. "$(cd "$(dirname "$0")" && pwd)/android-su.sh"
OUT=${1:-logs-$(date +%Y%m%d-%H%M%S)}
mkdir -p "$OUT"
su_do 'getprop ro.boot.slot_suffix; ls -la /sys/fs/pstore' | tee "$OUT/state.txt"
# the persistent log is in the slot Android is not on: boot_b, or boot_a when Android runs from b
slot=$(su_do 'getprop ro.boot.slot_suffix')
case $slot in _b) LS=a ;; *) LS=b ;; esac
for f in $(su_do 'ls /sys/fs/pstore'); do dev_pull "/sys/fs/pstore/$f" "$OUT/$f"; done
dev_pull /dev/block/by-name/uboot_log "$OUT/uboot_log.raw"
strings -n 6 "$OUT/uboot_log.raw" > "$OUT/uboot_log.txt"
# init writes stages + dmesg to boot_$LS at 48 MiB (8 MiB)
adb shell "${OPENF50_SU_BIN:-su} -c 'dd if=/dev/block/by-name/boot_'"$LS"' bs=4096 skip=12288 count=2048 2>/dev/null > /data/local/tmp/openf50-pull.bin'" </dev/null >/dev/null
adb pull /data/local/tmp/openf50-pull.bin "$OUT/linux-persist.raw" >/dev/null 2>&1
adb shell "${OPENF50_SU_BIN:-su} -c 'rm -f /data/local/tmp/openf50-pull.bin'" </dev/null >/dev/null
tr -d '\000' < "$OUT/linux-persist.raw" > "$OUT/linux-persist.txt" && rm -f "$OUT/linux-persist.raw"
sed -n '/OPENF50-PERSIST-BEGIN/,/--- lsmod/p' "$OUT/linux-persist.txt" || true
echo "saved: $OUT"
