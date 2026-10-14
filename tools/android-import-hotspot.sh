#!/bin/sh
# From rooted Android: copy the current Android hotspot SSID/passphrase into the Linux rootfs
# (/etc/openf50/hotspot.conf, mode 0600). The passphrase never leaves the device.
# requires tools/android-mount-openf50root.sh pushed to /data/local/tmp
# The Linux filesystem is the installation that boots: the openf50sd filesystem on the SD card when the card holds one
# (boot/init looks there first), openf50root in internal storage otherwise. OPENF50_SD_DEV=<card device> names the card
# by hand (the mount helper refuses any card without that label).
set -eu
TOP=$(cd "$(dirname "$0")/.." && pwd)
SD=${OPENF50_SD_DEV:-}
case $SD in
    '') ;;
    */mmcblk0|*/mmcblk0p*) echo "OPENF50_SD_DEV=$SD is the internal eMMC, not the SD card" >&2; exit 1 ;;
    /dev/block/mmcblk[1-9]|/dev/block/mmcblk[1-9]p[0-9]|/dev/block/mmcblk[1-9]p[0-9][0-9]) ;;
    *) echo "OPENF50_SD_DEV=$SD is not an SD card device" >&2; exit 1 ;;
esac
if [ -z "$SD" ]; then
    # the same search reset-password.sh does (tools/storage.sh; this script is English only)
    su_do() { adb shell "/debug_ramdisk/su -c '$1'" </dev/null | tr -d '\r'; }
    t() { printf '%s' "$1"; }
    . "$TOP/tools/storage.sh"; sd_probe
    if [ -n "$SD_DEV" ] && [ "$(sd_existing)" = yes ]; then
        SD=$SD_DEV
        echo "SD card $SD (openf50sd): the installation that boots"
    fi
fi
adb shell "/debug_ramdisk/su -c '
set -e
X=/data/misc/apexdata/com.android.wifi/WifiConfigStoreSoftAp.xml
R=/data/local/tmp/openf50root
ssid=\$(sed -n \"s/.*<string name=\\\"WifiSsid\\\">&quot;\\(.*\\)&quot;<\\/string>.*/\\1/p; s/.*<string name=\\\"WifiSsid\\\">\\([^&<]*\\)<\\/string>.*/\\1/p\" \$X | head -1)
psk=\$(sed -n \"s/.*<string name=\\\"Passphrase\\\">\\(.*\\)<\\/string>.*/\\1/p\" \$X | head -1 | sed \"s/&amp;/\\&/g; s/&lt;/</g; s/&gt;/>/g; s/&quot;/\\\"/g; s/&apos;/'\"'\"'/g\")
[ -n \"\$ssid\" ] && [ \${#psk} -ge 8 ] || { echo \"no usable SoftAP config in \$X\"; exit 1; }
${SD:+OPENF50_SD_DEV=$SD }sh /data/local/tmp/android-mount-openf50root.sh \$R >/dev/null
# unmounted again however this ends, also when a step below fails
trap \"sh /data/local/tmp/android-mount-openf50root.sh -u \$R >/dev/null 2>&1\" EXIT
mkdir -p \$R/etc/openf50
umask 077
printf \"SSID=%s\\nPSK=%s\\nBAND=5\\nCHANNEL=auto\\nCOUNTRY=TR\\n\" \"\$ssid\" \"\$psk\" > \$R/etc/openf50/hotspot.conf
chown 0:0 \$R/etc/openf50/hotspot.conf; chmod 600 \$R/etc/openf50/hotspot.conf
sync
echo \"imported SSID \$ssid (passphrase \${#psk} chars) into \$R/etc/openf50/hotspot.conf\"
'" | tr -d '\r'
