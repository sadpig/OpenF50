#!/bin/sh
# Maintainer: build the generic release assets used by ./install.sh (prebuilt mode) and optionally publish them.
#   tools/make-release.sh TAG             build into release/TAG and audit the contents
#   tools/make-release.sh TAG --publish   also create/update the GitHub release (gh)
#   tools/make-release.sh TAG --publish --prerelease   create it as a prerelease: never "latest", so openf50-update and
#                                          the installers do not offer it until it is promoted on GitHub
# Needs docker and the kernel outputs in $OPENF50_KERNEL_OUT (default: out/, from kernel/build-all.sh).
# The assets must never contain proprietary files or anything from a particular device: the audit below fails the
# build if firmware, Android userspace, host keys or local settings end up in an image.
set -eu
TAG=${1:?usage: tools/make-release.sh TAG [--publish [--prerelease]]}
shift
PUBLISH="" PRERELEASE=""
for a in "$@"; do
    case $a in
        --publish) PUBLISH=--publish ;;
        --prerelease) PRERELEASE=--prerelease ;;
        *) echo "unknown option $a (usage: tools/make-release.sh TAG [--publish [--prerelease]])" >&2; exit 1 ;;
    esac
done
TOP=$(cd "$(dirname "$0")/.." && pwd)
KOUT=${OPENF50_KERNEL_OUT:-$TOP/out}
REPO=${OPENF50_REPO:-sadpig/OpenF50}
D=$TOP/release/$TAG
IN=$D/inputs
[ -f "$KOUT/Image" ] && ls "$KOUT"/modules/*.ko >/dev/null 2>&1 || { echo "kernel outputs missing in $KOUT (kernel/build-all.sh)" >&2; exit 1; }
ls "$KOUT"/modules-u30air/*.ko >/dev/null 2>&1 || { echo "U30 Air modules missing in $KOUT/modules-u30air (kernel/build-all.sh)" >&2; exit 1; }
[ -z "$(git -C "$TOP" status --porcelain)" ] || { echo "commit your changes first: the release must match a commit" >&2; exit 1; }
rm -rf "$D" && mkdir -p "$IN/out" "$IN/tools/logdw" "$IN/tools/bt-init" "$IN/tools/gpu"

echo "==> helper binaries"
cp -R "$KOUT/modules" "$IN/out/modules"
cp "$KOUT/modules.builtin" "$KOUT/modules.builtin.modinfo" "$IN/out/"
docker build -q -t openf50-kbuild "$TOP/kernel" >/dev/null
docker build -q -t openf50-ubuntu:24.04 "$TOP/rootfs" >/dev/null
docker build -q --build-arg BASE=ubuntu:26.04 -t openf50-ubuntu:26.04 "$TOP/rootfs" >/dev/null
docker run --rm openf50-ubuntu:24.04 cat /bin/busybox > "$IN/busybox"; chmod +x "$IN/busybox"
docker run --rm -v "$TOP/tools":/src:ro -v "$IN/tools":/o openf50-kbuild sh -c '
  gcc -O2 -static -o /o/logdw/logdw /src/logdw/logdw.c &&
  gcc -O2 -static -o /o/bt-init/openf50-bt-init /src/bt-init/openf50-bt-init.c &&
  mkdir -p /o/keys && gcc -O2 -static -o /o/keys/openf50-keys /src/keys/openf50-keys.c'
# adbd (adb over USB to Linux): static aarch64, from AOSP's sources (tools/adbd/build.sh)
# a finished binary survives a rebuild: docker/network flakes no longer force building it again
ADBD_CACHE=$TOP/work/adbd-cache/adbd
mkdir -p "$IN/tools/adbd" "$(dirname "$ADBD_CACHE")"
if [ -s "$IN/tools/adbd/adbd" ]; then :
elif [ -s "$ADBD_CACHE" ]; then cp "$ADBD_CACHE" "$IN/tools/adbd/adbd"
else sh "$TOP/tools/adbd/build.sh" "$IN/tools/adbd/adbd" >/dev/null && cp "$IN/tools/adbd/adbd" "$ADBD_CACHE"
fi
# cltest links against Android's libraries at build time only; use a local build when there is one
[ -f "$TOP/tools/gpu/cltest" ] && cp "$TOP/tools/gpu/cltest" "$IN/tools/gpu/cltest"

echo "==> kernel bundle"
K=$D/kernel && mkdir -p "$K"
cp -R "$IN/out/modules" "$K/modules"
cp -R "$KOUT/modules-u30air" "$K/modules-u30air"
# the devices this bundle runs on (openf50-update and the installers check it); not the V50: the only V50 known to run
# this project (kano's) ran mainline, and its LED driver is mainline only (upstream/make-bundle.sh, FINDINGS 95)
echo "f50 u30air" > "$K/devices"
# what it can do that older bundles could not: 5.4 reads the SD card (FINDINGS 31j), so a system on the card may get
# it; its init runs from either slot, so a Linux on slot a may get it (openf50-update checks both)
printf 'sdcard\nlinux-slot\n' > "$K/features"
cp "$KOUT/Image" "$KOUT/modules.builtin" "$KOUT/modules.builtin.modinfo" "$IN/busybox" "$IN/tools/logdw/logdw" "$K/"
# the device-independent part of the boot ramdisk, which openf50-update puts behind the device's own ramdisk to update
# the kernel and the boot image without a computer (same builder and file list as install.sh)
python3 "$TOP/boot/build-boot-image.py" --generic-ramdisk --modules "$IN/out/modules" --busybox "$IN/busybox" \
  --device-modules "u30air=$KOUT/modules-u30air" \
  --logdw "$IN/tools/logdw/logdw" --ueventd-perms "$TOP/android-vendor/ueventd-perms.sh" \
  --out "$K/ramdisk-generic.lz4" >/dev/null
tar -C "$K" -czf "$D/openf50-kernel.tar.gz" .
rm -rf "$K"

echo "==> mainline kernel bundles"
# "openf50-update kernel 6.18|7.2": built by upstream/build.sh + build-modules.sh at this commit - 6.18 into
# upstream/out, 7.2 into upstream/out-7.2 (OUTDIR=out-7.2 KV=7.2.x); each build must be the version its name says
for kv in 6.18:out 7.2:out-7.2; do
    v=${kv%%:*}; o=$TOP/upstream/${kv#*:}
    [ -f "$o/Image" ] || { echo "$o/Image missing (upstream/build.sh, build-modules.sh)" >&2; exit 1; }
    rel=$(strings "$o/Image" | sed -n 's/^Linux version \([^ ]*\) .*/\1/p' | head -1)
    case $rel in "$v".*) ;; *) echo "$o holds $rel, not $v" >&2; exit 1 ;; esac
    OPENF50_UPSTREAM_OUT=$o sh "$TOP/upstream/make-bundle.sh" "$D/openf50-kernel-$v.tar.gz" "$D/openf50-kernel.tar.gz"
done

# 24.04 keeps the name it always had (older installers and openf50-update ask for it); 26.04 has its own
for u in 24.04 26.04; do
    echo "==> Ubuntu $u root filesystem (generic)"
    B=$D/ubuntu-build && rm -rf "$B" && mkdir -p "$B"
    tar -C "$TOP/rootfs" --exclude ./base.tar --exclude './*.tar.gz' -cf - . | tar -xf - -C "$B"
    cid=$(docker create openf50-ubuntu:$u /bin/true); docker export "$cid" > "$B/base.tar"; docker rm "$cid" >/dev/null
    cltest=""; [ -f "$IN/tools/gpu/cltest" ] && cltest="-v $IN/tools/gpu/cltest:/cltest:ro"
    # shellcheck disable=SC2086
    docker run --rm -v "$B":/w -v "$IN/out/modules":/kmods:ro -v "$IN/out":/kout:ro -v "$IN/tools/logdw/logdw":/logdw:ro \
      -v "$IN/tools/bt-init/openf50-bt-init":/bt-init:ro -v "$IN/tools/keys/openf50-keys":/keys:ro -v "$IN/tools/adbd/adbd":/adbd:ro $cltest \
      -e OPENF50_VERSION="$TAG" openf50-ubuntu:$u bash /w/assemble.sh >/dev/null
    out=openf50-ubuntu-rootfs.tar.gz; [ $u = 24.04 ] || out=openf50-ubuntu-$u-rootfs.tar.gz
    mv "$B/openf50-ubuntu-$u-rootfs.tar.gz" "$D/$out"; rm -rf "$B"
done

echo "==> OpenWrt root filesystem (generic)"
OPENF50_INPUTS="$IN" OPENF50_VERSION="$TAG" sh "$TOP/openwrt/build-rootfs.sh" openf50-openwrt-release.tar.gz >/dev/null
mv "$TOP/openwrt/openf50-openwrt-release.tar.gz" "$D/openf50-openwrt-rootfs.tar.gz"

echo "==> OpenWrt with the OPENF50 control panel"
OPENF50_SYSTEM=openwrt-luci OPENF50_INPUTS="$IN" OPENF50_VERSION="$TAG" sh "$TOP/openwrt/build-rootfs.sh" openf50-openwrt-luci-release.tar.gz >/dev/null
mv "$TOP/openwrt/openf50-openwrt-luci-release.tar.gz" "$D/openf50-openwrt-luci-rootfs.tar.gz"

echo "==> lang extra"
# after the OpenWrt builds: it is built in the OpenWrt base image they import, from the same feed
sh "$TOP/tools/make-extra.sh" lang "$D/openf50-extra-lang.tar.gz" "$TAG"

echo "==> panel extra (Ubuntu's web panel: Cockpit and the OPENF50 page), online and offline"
# the offline one carries Cockpit's packages for both Ubuntu releases, from the openf50-ubuntu images built above
sh "$TOP/tools/make-extra.sh" panel "$D/openf50-extra-panel.tar.gz" "$TAG"
sh "$TOP/tools/make-extra.sh" panel-offline "$D/openf50-extra-panel-offline.tar.gz" "$TAG"

echo "==> audit"
fail=0
for a in openf50-kernel openf50-kernel-6.18 openf50-kernel-7.2 openf50-ubuntu-rootfs openf50-ubuntu-26.04-rootfs openf50-openwrt-rootfs \
         openf50-openwrt-luci-rootfs; do
    bad=$(tar -tzf "$D/$a.tar.gz" | sed 's|^\./||' | grep -E \
        -e '(^|/)lib/firmware/(wcnmodem|gnssmodem|wifi_board_config|bt_configure)' \
        -e '^opt/openf50/android/.+' -e '__properties__|dev-properties' \
        -e '(^|/)(libmali|libOpenCL|libGLES|libEGL|libvulkan)[^/]*\.so' \
        -e '^etc/ssh/ssh_host_' -e '^etc/openf50/(hotspot|vpn|toolkit|mobile-data)\.conf$' -e '^etc/dropbear/dropbear_.*_host_key' \
        -e '^opt/openf50/bin/(xray|sing-box|hev-socks5-tunnel|mihomo|openf50-vpn)$' -e '^opt/openf50/lib/vpn(/|$)' \
        -e '^etc/systemd/system/openf50-vpn\.service$' -e '^etc/init\.d/openf50-vpn$' -e '^etc/openf50/vpn\.conf\.example$' \
        | grep -vE '^opt/openf50/android/system/?$|^opt/openf50/android/system/bin/?$|^opt/openf50/android/system/bin/cltest$' || true)
    if [ -n "$bad" ]; then echo "$a contains files that must not be published:"; echo "$bad" | head -20; fail=1; fi
    mid=$(tar -xzOf "$D/$a.tar.gz" ./etc/machine-id 2>/dev/null || true)
    [ -z "$mid" ] || { echo "$a has a machine-id"; fail=1; }
done
# the panel: everything of it is in the luci asset, and nothing of it (nor Aurora) in the plain OpenWrt one
list_of() { tar -tzf "$D/$1.tar.gz" | sed 's|^\./||'; }
panel=$(list_of openf50-openwrt-luci-rootfs)
for f in usr/share/luci/menu.d/luci-app-openf50.json www/luci-static/resources/view/openf50/home.js \
         usr/libexec/rpcd/openf50dash usr/lib/lua/luci/i18n/openf50.tr.lmo usr/lib/lua/luci/i18n/openf50.zh-cn.lmo \
         www/luci-static/aurora/main.css etc/openf50/packages.txt usr/lib/lua/luci/i18n/base.tr.lmo \
         usr/lib/lua/luci/i18n/base.zh-cn.lmo; do
    printf '%s\n' "$panel" | grep -qx "$f" || { echo "openf50-openwrt-luci-rootfs lacks $f"; fail=1; }
done
plain=$(list_of openf50-openwrt-rootfs)
for f in usr/libexec/rpcd/openf50dash www/luci-static/aurora/main.css; do
    ! printf '%s\n' "$plain" | grep -qx "$f" || { echo "openf50-openwrt-rootfs has $f, which is only for openwrt-luci"; fail=1; }
done
for f in etc/openf50/packages.txt usr/lib/lua/luci/i18n/base.tr.lmo usr/lib/lua/luci/i18n/base.zh-cn.lmo; do
    printf '%s\n' "$plain" | grep -qx "$f" || { echo "openf50-openwrt-rootfs lacks $f"; fail=1; }
done
# the lang extra: catalogs only (and its manifest), and the panel's in the languages it was translated to
lx=$(tar -tzf "$D/openf50-extra-lang.tar.gz" | sed 's|^\./||')
! printf '%s\n' "$lx" | grep . | grep -Evx 'name|release|components|languages|manifest|i18n/?|i18n/[a-z0-9-]+\.[a-z]{2,3}(-[a-z]{2})?\.lmo' ||
    { echo "openf50-extra-lang.tar.gz has files that are not catalogs"; fail=1; }
for f in i18n/base.de.lmo i18n/openf50.de.lmo i18n/openf50.ja.lmo; do
    printf '%s\n' "$lx" | grep -qx "$f" || { echo "openf50-extra-lang.tar.gz lacks $f"; fail=1; }
done
# what the package list changed since the last release (OPENF50_PREV_RELEASE: its directory, with the assets)
if [ -n "${OPENF50_PREV_RELEASE:-}" ]; then
    for a in openf50-openwrt-rootfs openf50-openwrt-luci-rootfs; do
        [ -f "$OPENF50_PREV_RELEASE/$a.tar.gz" ] || { echo "$a: no previous asset in $OPENF50_PREV_RELEASE"; continue; }
        echo "==> $a: etc/openf50/packages.txt against the previous release"
        tar -xzOf "$OPENF50_PREV_RELEASE/$a.tar.gz" ./etc/openf50/packages.txt > "$D/packages.prev" 2>/dev/null || : > "$D/packages.prev"
        tar -xzOf "$D/$a.tar.gz" ./etc/openf50/packages.txt > "$D/packages.new" 2>/dev/null || : > "$D/packages.new"
        diff -u "$D/packages.prev" "$D/packages.new" || true
        rm -f "$D/packages.prev" "$D/packages.new"
    done
fi
# an extra holds what its name says, for the release it is published with (openf50-update compares ./release). The VPN
# (vpn, vpn-mihomo) is not one of this release's: it is the module of github.com/dikeckaan/mu300-linux-vpn
# the panel: its page and command; the offline one the same with Cockpit's packages for both Ubuntu releases
for a in openf50-extra-panel openf50-extra-panel-offline; do
    px=$(tar -tzf "$D/$a.tar.gz" | sed 's|^\./||')
    ! printf '%s\n' "$px" | grep . | grep -Evx 'name|release|components|manifest|bin/?|bin/openf50-panel|cockpit/?|cockpit/openf50/?|cockpit/openf50/[A-Za-z0-9_.-]+|debs/?|debs/[0-9.]+/?|debs/[0-9.]+/[A-Za-z0-9._+~-]+\.deb' ||
        { echo "$a.tar.gz has unexpected files"; fail=1; }
    for f in bin/openf50-panel cockpit/openf50/manifest.json cockpit/openf50/openf50.js cockpit/openf50/po.tr.js cockpit/openf50/po.zh_CN.js; do
        printf '%s\n' "$px" | grep -qx "$f" || { echo "$a.tar.gz lacks $f"; fail=1; }
    done
    [ "$(tar -xzOf "$D/$a.tar.gz" ./name)" = panel ] && [ "$(tar -xzOf "$D/$a.tar.gz" ./release)" = "$TAG" ] ||
        { echo "$a.tar.gz is not the panel extra of $TAG"; fail=1; }
done
for u in 24.04 26.04; do
    tar -tzf "$D/openf50-extra-panel-offline.tar.gz" | grep -q "^\./debs/$u/cockpit-ws_" || { echo "openf50-extra-panel-offline.tar.gz has no Cockpit for Ubuntu $u"; fail=1; }
done
for x in lang; do
    [ "$(tar -xzOf "$D/openf50-extra-$x.tar.gz" ./name)" = $x ] && [ "$(tar -xzOf "$D/openf50-extra-$x.tar.gz" ./release)" = "$TAG" ] ||
        { echo "openf50-extra-$x.tar.gz is not the $x extra of $TAG"; fail=1; }
done
# openf50-update refuses a kernel bundle without the SD host for a system on the card, and one whose init runs only from
# slot b for a Linux on slot a: every bundle must say it has both
for a in openf50-kernel openf50-kernel-6.18 openf50-kernel-7.2; do
    tar -xzOf "$D/$a.tar.gz" ./features 2>/dev/null | grep -qx sdcard || { echo "$a does not list sdcard in ./features"; fail=1; }
    tar -xzOf "$D/$a.tar.gz" ./features 2>/dev/null | grep -qx linux-slot || { echo "$a does not list linux-slot in ./features"; fail=1; }
done
# a mainline bundle carries the kernel's own modules next to the vendor ones (upstream/build-modules.sh): one of each
# kind - qdisc, filesystem, device mapper, USB modem, vhost - and the vendor Wi-Fi
for a in openf50-kernel-6.18 openf50-kernel-7.2; do
    l=$(tar -tzf "$D/$a.tar.gz")
    for m in sch_htb.ko ntfs3.ko dm-crypt.ko cdc_mbim.ko vhost_net.ko sprd_wlan_combo.ko; do
        printf '%s\n' "$l" | grep -qx "./modules/$m" || { echo "$a lacks modules/$m"; fail=1; }
    done
done
[ $fail = 0 ] || { echo "audit failed, nothing published" >&2; exit 1; }
rm -rf "$IN"
# the updater itself: an older openf50-update fetches this one and continues with it
cp "$TOP/rootfs/overlay/opt/openf50/bin/openf50-update" "$D/openf50-update"
(cd "$D" && { shasum -a 256 *.tar.gz openf50-update 2>/dev/null || sha256sum *.tar.gz openf50-update; } > SHA256SUMS)
ls -la "$D"

[ "$PUBLISH" = --publish ] || { echo "built release/$TAG (run again with --publish to upload)"; exit 0; }
commit=$(git -C "$TOP" rev-parse HEAD)
kernel_rev=$(sed -n 's/^KERNEL_REV=//p' "$TOP/kernel/build-all.sh")
modules_rev=$(sed -n 's/^MODULES_REV=//p' "$TOP/kernel/build-all.sh")
notes=$(mktemp)
cat > "$notes" <<EOF
Prebuilt images for \`./install.sh\` (ZTE F50 / OPENF50 and ZTE U30 Air; the installer recognises which). Check your device
first with \`./install.sh --check\`.

| file | contents |
|---|---|
| openf50-kernel.tar.gz | Linux 5.4.254 \`Image\` and modules (with the U30 Air's own in \`modules-u30air/\`), with the patches of \`kernel/patches\` (among them: no panic when a network namespace goes away, #103, and the Wi-Fi driver's routine lines no longer at error level, #140), static busybox and logdw for the boot image, and the generic boot ramdisk segment \`openf50-update\` uses |
| openf50-kernel-6.18.tar.gz | mainline Linux 6.18 (longterm) for \`openf50-update kernel 6.18\`: \`Image\`, modules, generic boot ramdisk segment; with BTF and the BPF JIT (so the VPN module's dae engine runs), FunctionFS (for adb) and card detect for the F50's SD slot (an empty slot is no longer polled, #181) |
| openf50-kernel-7.2.tar.gz | mainline Linux 7.2 (newest stable) for \`openf50-update kernel 7.2\`: the same parts |
| openf50-ubuntu-rootfs.tar.gz | Ubuntu 24.04 LTS root filesystem |
| openf50-ubuntu-26.04-rootfs.tar.gz | Ubuntu 26.04 LTS root filesystem |
| openf50-openwrt-rootfs.tar.gz | OpenWrt 25.12.5 root filesystem |
| openf50-openwrt-luci-rootfs.tar.gz | OpenWrt 25.12.5 with the OPENF50 control panel (luci-app-openf50 by kanoqwq, Aurora theme by eamonxg) |
| openf50-extra-lang.tar.gz | LuCI and the OPENF50 panel in more languages (OpenWrt only; English, Turkish and Chinese are in the images): \`openf50-extra install lang\` on the device, or System > Languages in the panel; LuCI's catalogs from the OpenWrt 25.12.5 feed, the panel's AI-translated |
| openf50-extra-panel.tar.gz | the web panel for Ubuntu: Cockpit (Ubuntu's web console: terminal, logs, services, networking, storage) and the OPENF50 page (signal, mobile data, data usage, SMS, VPN, power and CPU, Wi-Fi, updates), on the LAN only: \`sudo openf50-extra install panel\` on the device (Cockpit from Ubuntu's archive), or the installer's question |
| openf50-extra-panel-offline.tar.gz | the same with Cockpit's packages for Ubuntu 24.04 and 26.04, for a device that is not online: \`sudo openf50-extra install panel --from openf50-extra-panel-offline.tar.gz\` |
| openf50-update | the on-device updater of this release (\`openf50-update apply\` switches to it before it changes anything) |
| (the VPN) | not part of this release: the VPN toolkit (\`openf50-vpn\`, module v2: the core with hev-socks5-tunnel, and the engines as extras: \`vpn-xray\`, \`vpn-singbox\`, \`vpn-mihomo\`, \`vpn-dae\`) is the module of https://github.com/dikeckaan/mu300-linux-vpn - \`openf50-extra install vpn\` on the device, or the installer's question, takes its latest release with the engines its profiles need; on OpenWrt with the panel the VPN menu drives it |

The images contain **no proprietary files**: the installer pulls the Wi-Fi/Bluetooth firmware and the Android
modem/GPU userspace from your own device and adds them during installation. They carry a static adbd (AOSP
platform-tools, built by \`tools/adbd/build.sh\`) for adb to Linux over USB, which is **on by default and lets every
computer in**: whoever can plug a cable into the device gets a root shell without a password. To close it:
\`sudo openf50-usb adb auth keys\` (only the keys authorised with \`sudo openf50-usb adb key FILE\`) or
\`sudo openf50-usb adb off\`. A device where adb was turned off, or set up with a key, before this release stays as it was.

Built from $REPO@$commit with \`kernel/build-all.sh\` and \`tools/make-release.sh\`.
Corresponding source (GPL): kernel https://github.com/Enceka/android_kernel_zte_ums9620_mifi_u30air/tree/$kernel_rev ,
Wi-Fi/Bluetooth/Mali modules https://github.com/realme-kernel-opensource/realme_C51_C53_Narzo-N53-AndroidT-kernel-source/tree/$modules_rev ,
patches in \`kernel/patches\`. Ubuntu, OpenWrt and busybox packages come from their distributions' archives;
Aurora (luci-theme-aurora 1.4.0) from https://github.com/eamonxg/luci-theme-aurora/releases/tag/v1.4.0.
News and releases: the Telegram channel https://t.me/mu300project
EOF
if gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
    gh release upload "$TAG" -R "$REPO" --clobber "$D"/*.tar.gz "$D/openf50-update" "$D/SHA256SUMS"
else
    # shellcheck disable=SC2086
    gh release create "$TAG" -R "$REPO" --target "$commit" --title "OPENF50 Linux $TAG" --notes-file "$notes" $PRERELEASE \
      "$D"/*.tar.gz "$D/openf50-update" "$D/SHA256SUMS"
fi
rm -f "$notes"
