#!/bin/sh
# Build the OPENF50 OpenWrt (or ImmortalWrt) rootfs tarball (runs on the host; needs Docker with arm64 support).
#   openwrt/build-rootfs.sh OUT.tar.gz
#   OPENF50_FLAVOUR=immortalwrt openwrt/build-rootfs.sh OUT.tar.gz
#   OPENF50_SYSTEM=openwrt-luci openwrt/build-rootfs.sh OUT.tar.gz   (OpenWrt with the OPENF50 control panel and Aurora)
# OUT is written into openwrt/ under its base name.
# Inputs (same as rootfs/assemble.sh, all optional except modules):
#   out/modules/*.ko  out/modules.builtin*  firmware/  android-subset/  android-gpu-subset/
#   tools/logdw/logdw  tools/bt-init/openf50-bt-init  tools/keys/openf50-keys  tools/gpu/cltest  busybox (static, full)
#   upstream/out/modules/*.ko (optional: out-of-tree WCN modules for the mainline 6.18 kernel)
# openwrt-luci only: OPENF50_LUCI_THEME_APK, a local copy of the pinned Aurora .apk (offline builds; else downloaded)
# Optional OPENF50_SAE_APK_DIR: local hostapd-common + wpad-basic-openssl APKs from build-u30-sae.sh.
set -eu
FLAVOUR=${OPENF50_FLAVOUR:-openwrt}
case $FLAVOUR in
    openwrt)     VER=${OPENF50_WRT_VER:-25.12.5}; BASEURL=https://downloads.openwrt.org/releases ;;
    # ImmortalWrt is an OpenWrt fork: same package manager, same layout, more drivers and LuCI apps
    immortalwrt) VER=${OPENF50_WRT_VER:-25.12.2}; BASEURL=https://downloads.immortalwrt.org/releases ;;
    *) echo "unknown flavour '$FLAVOUR' (openwrt or immortalwrt)" >&2; exit 1 ;;
esac
SYSTEM=${OPENF50_SYSTEM:-openwrt}
case $SYSTEM in
    openwrt) ;;
    # the panel on ImmortalWrt was never tested by anyone
    openwrt-luci)
        [ "$FLAVOUR" = openwrt ] || { echo "OPENF50_SYSTEM=openwrt-luci is built on OpenWrt only, not $FLAVOUR" >&2; exit 1; } ;;
    *) echo "unknown system '$SYSTEM' (openwrt or openwrt-luci)" >&2; exit 1 ;;
esac
KREL=5.4.254-gb50db5b6224c
# the default name: openf50-<system>-<version>-rootfs.tar.gz; ImmortalWrt keeps its own (it has only the plain system)
if [ "$FLAVOUR" = immortalwrt ]; then OUT=${1:-openf50-immortalwrt-$VER-rootfs.tar.gz}; else OUT=${1:-openf50-$SYSTEM-$VER-rootfs.tar.gz}; fi
TOP=$(cd "$(dirname "$0")/.." && pwd)
# build inputs (out/, firmware/, android-subset/, tools binaries, busybox) may live outside the checkout
IN=${OPENF50_INPUTS:-$TOP}
# Without its cellular protocol netifd has no wan and the image boots without mobile data. openwrt-luci also needs
# the IPv6 relay monitor: its first boot selects relay mode (91-openf50-luci), and openf50cell.sh then runs it. Plain
# OpenWrt never selects relay, and builds without it.
CELL=$TOP/openwrt/overlay/lib/netifd/proto/openf50cell.sh
[ -s "$CELL" ] || { echo "required cellular protocol helper missing: $CELL" >&2; exit 1; }
if [ "$SYSTEM" = openwrt-luci ]; then
    [ -s "$TOP/openwrt/luci-overlay/lib/netifd/proto/openf50cell-v6.sh" ] || {
        echo "required cellular protocol helper missing: openwrt/luci-overlay/lib/netifd/proto/openf50cell-v6.sh" >&2; exit 1;
    }
fi
# sipa_eth0 into fw4's software flowtable (applied below, the build fails when it no longer applies)
FW4PATCH=$TOP/openwrt/patches/fw4-sipa-offload.patch
[ -s "$FW4PATCH" ] || { echo "missing $FW4PATCH" >&2; exit 1; }
# fw4 reload/restart on the 5.4 kernel: its old flowtable goes first, in a transaction of its own (#95, FINDINGS 38)
FW4FTPATCH=$TOP/openwrt/patches/fw4-old-kernel-flowtable.patch
[ -s "$FW4FTPATCH" ] || { echo "missing $FW4FTPATCH" >&2; exit 1; }
# never an access point on a DFS channel: the SC2355 driver has no radar detection (FINDINGS 42)
NODFSPATCH=$TOP/openwrt/patches/wifi-scripts-no-dfs.patch
[ -s "$NODFSPATCH" ] || { echo "missing $NODFSPATCH" >&2; exit 1; }
# the docker mounts of the panel system, as the positional parameters (OUT is read above): each path stays one
# argument, spaces and all
set --
if [ "$SYSTEM" = openwrt-luci ]; then
    # Keep the upstream Aurora theme reproducible. Its APK is installed while
    # assembling the rootfs, so the theme is present on first boot without a
    # network-dependent uci-defaults install step. Bootstrap remains available.
    THEME_APK=${OPENF50_LUCI_THEME_APK:-$TOP/work/luci-theme-aurora-1.4.0-r20260920.apk}
    # pinned here, not overridable: OPENF50_LUCI_THEME_APK may swap the file, never the hash it is checked against
    THEME_SHA=05f9015e0a4e2859f6a153f69e472f2984481490d4ce6db19b8a41bba7264f1e
    if [ ! -s "$THEME_APK" ]; then
        [ -z "${OPENF50_LUCI_THEME_APK:-}" ] || {
            echo "theme package missing: $THEME_APK" >&2; exit 1;
        }
        mkdir -p "$TOP/work"
        curl -fL -o "$THEME_APK.part" \
          https://github.com/eamonxg/luci-theme-aurora/releases/download/v1.4.0/luci-theme-aurora-1.4.0-r20260920.apk
        mv "$THEME_APK.part" "$THEME_APK"
    fi
    theme_hash=$(shasum -a 256 "$THEME_APK" 2>/dev/null || sha256sum "$THEME_APK")
    [ "${theme_hash%% *}" = "$THEME_SHA" ] || {
        echo "Aurora APK checksum mismatch: $THEME_APK" >&2; exit 1;
    }
    # iStore app store (bundled by default on OpenF50; OPENF50_ISTORE=0 skips it): the upstream apk
    # signing key, hash-pinned like the Aurora theme. Store packages come from its feed, not pinned
    # one by one - the same policy as the OpenWrt feeds (packages.txt records the build).
    ISTORE=${OPENF50_ISTORE:-1}
    if [ "$ISTORE" != 0 ]; then
        ISTORE_PEM=${OPENF50_ISTORE_PEM:-$TOP/work/istore-apk.pem}
        ISTORE_PEM_SHA=17d39c124a39a0f0bf54601073ddb3d42bad45b40be9ad28c17e805bee04db08
        if [ ! -s "$ISTORE_PEM" ]; then
            [ -z "${OPENF50_ISTORE_PEM:-}" ] || { echo "iStore key missing: $ISTORE_PEM" >&2; exit 1; }
            curl -fL -o "$ISTORE_PEM.part" https://istore.istoreos.com/repo-apk/istore-apk.pem
            mv "$ISTORE_PEM.part" "$ISTORE_PEM"
        fi
        pem_hash=$(shasum -a 256 "$ISTORE_PEM" 2>/dev/null || sha256sum "$ISTORE_PEM")
        [ "${pem_hash%% *}" = "$ISTORE_PEM_SHA" ] || { echo "iStore key checksum mismatch: $ISTORE_PEM" >&2; exit 1; }
    fi
    # PassWall (bundled by default on OpenF50; OPENF50_PASSWALL=0 skips it): the passwall-build
    # repo signing key, hash-pinned like the iStore key. Packages come from its feed at build time,
    # so every release carries the then-latest PassWall and engines (not pinned one by one).
    PASSWALL=${OPENF50_PASSWALL:-1}
    if [ "$PASSWALL" != 0 ]; then
        PW_PEM=${OPENF50_PASSWALL_PEM:-$TOP/work/openwrt-passwall-build.pem}
        PW_PEM_SHA=52802b143489214e13b78f96599a147a638205cc22d9dd6d71229504e38ddc00
        if [ ! -s "$PW_PEM" ]; then
            [ -z "${OPENF50_PASSWALL_PEM:-}" ] || { echo "passwall-build key missing: $PW_PEM" >&2; exit 1; }
            curl -fL -o "$PW_PEM.part" https://master.dl.sourceforge.net/project/openwrt-passwall-build/apk.pub
            mv "$PW_PEM.part" "$PW_PEM"
        fi
        pw_hash=$(shasum -a 256 "$PW_PEM" 2>/dev/null || sha256sum "$PW_PEM")
        [ "${pw_hash%% *}" = "$PW_PEM_SHA" ] || { echo "passwall-build key checksum mismatch: $PW_PEM" >&2; exit 1; }
    fi
    # Vantage theme, bundled by default (OPENF50_VANTAGE=0 keeps Aurora alone): the newest GitHub
    # release unless OPENF50_VANTAGE_TAG pins one; files checked against that release's SHA256SUMS.
    VANTAGE=${OPENF50_VANTAGE:-1}
    VTAG=${OPENF50_VANTAGE_TAG:-}
    if [ "$VANTAGE" != 0 ]; then
        [ -n "$VTAG" ] || VTAG=$(curl -fsSL "https://api.github.com/repos/anothaDev/luci-theme-vantage/releases/latest" \
            | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
        [ -n "$VTAG" ] || { echo "cannot find the newest luci-theme-vantage release" >&2; exit 1; }
        VDIR=$TOP/work/vantage-$VTAG; mkdir -p "$VDIR"
        vbase=https://github.com/anothaDev/luci-theme-vantage/releases/download/$VTAG
        curl -fsSL -o "$VDIR/SHA256SUMS" "$vbase/SHA256SUMS" || { echo "vantage SHA256SUMS download failed" >&2; exit 1; }
        for vf in "luci-theme-vantage-${VTAG#v}-r1.apk" "luci-app-vantage-${VTAG#v}-r1.apk" "luci-i18n-vantage-zh-cn-${VTAG#v}-r1.apk"; do
            [ -s "$VDIR/$vf" ] || curl -fsSL -o "$VDIR/$vf" "$vbase/$vf" || { echo "vantage download failed: $vf" >&2; exit 1; }
            want=$(awk -v f="$vf" '{print $1}' "$VDIR/SHA256SUMS" | head -1)
            have=$( (shasum -a 256 "$VDIR/$vf" 2>/dev/null || sha256sum "$VDIR/$vf") | cut -d' ' -f1)
            [ "$have" = "$want" ] || { echo "vantage checksum mismatch: $vf" >&2; exit 1; }
        done
    fi
    # The panel's catalogs in the image: Turkish and Simplified Chinese (the others are the lang extra,
    # tools/make-extra.sh). A catalog without translations (English: the msgids are the English text) is no file at
    # all. Named by LuCI's code for the language (openwrt/luci-languages.tsv: zh_Hans is zh-cn), or LuCI does not
    # load them.
    CAT=$(mktemp -d)
    for l in tr zh_Hans; do
        code=$(awk -F '\t' -v d="$l" '$1 == d {print $2}' "$TOP/openwrt/luci-languages.tsv")
        [ -n "$code" ] || { echo "no row for $l in openwrt/luci-languages.tsv" >&2; exit 1; }
        python3 "$TOP/tools/po2lmo.py" "$TOP/openwrt/luci-app-openf50/po/$l/openf50.po" "$CAT/openf50.$code.lmo"
    done
    [ -s "$CAT/openf50.tr.lmo" ] || { echo "no Turkish catalog built from openwrt/luci-app-openf50/po/tr" >&2; exit 1; }
    [ -s "$CAT/openf50.zh-cn.lmo" ] || { echo "no Chinese catalog built from openwrt/luci-app-openf50/po/zh_Hans" >&2; exit 1; }
    set -- -v "$THEME_APK:/in/luci-theme-aurora.apk:ro" -v "$TOP/openwrt/luci-app-openf50:/in/luci-plugin:ro" \
        -v "$TOP/openwrt/luci-overlay:/in/luci-overlay:ro" -v "$CAT:/in/catalogs:ro"
    [ "$ISTORE" = 0 ] || set -- "$@" -v "$ISTORE_PEM:/in/istore-apk.pem:ro"
    [ "$PASSWALL" = 0 ] || set -- "$@" -v "$PW_PEM:/in/openwrt-passwall-build.pem:ro"
    [ "$VANTAGE" = 0 ] || set -- "$@" -v "$VDIR:/in/vantage:ro"
fi
TARBALL=$FLAVOUR-$VER-armsr-armv8-rootfs.tar.gz
if [ -n "${OPENF50_SAE_APK_DIR:-}" ]; then
    [ "$FLAVOUR:$VER" = openwrt:25.12.5 ] || {
        echo "U30 SAE packages require OpenWrt 25.12.5" >&2; exit 1;
    }
    SAE_APKS=$(cd "$OPENF50_SAE_APK_DIR" && pwd)
    for name in hostapd-common wpad-basic-openssl; do
        count=0
        for package in "$SAE_APKS"/"$name"-*.apk; do [ ! -s "$package" ] || count=$((count + 1)); done
        [ "$count" = 1 ] || { echo "expected exactly one $name APK in $SAE_APKS" >&2; exit 1; }
    done
    set -- "$@" -v "$SAE_APKS:/in/u30-sae:ro"
fi
URL=$BASEURL/$VER/targets/armsr/armv8

cd "$TOP"
if [ ! -f "openwrt/$TARBALL" ]; then
    curl -fL -o "openwrt/$TARBALL" "$URL/$TARBALL"
fi
want=$(curl -fsL "$URL/sha256sums" | sed -n "s/^\([0-9a-f]*\) \*$TARBALL$/\1/p")
have=$(shasum -a 256 "openwrt/$TARBALL" 2>/dev/null || sha256sum "openwrt/$TARBALL")
[ "${have%% *}" = "$want" ] || { echo "checksum mismatch for $TARBALL" >&2; exit 1; }
docker import --platform linux/arm64 "openwrt/$TARBALL" openf50-$FLAVOUR-base:$VER >/dev/null
# OpenWrt ships an unsigned regulatory.db; this kernel requires the signed database (wens key), so take Debian/Ubuntu's
REGDB=$(mktemp -d)
docker run --rm --platform linux/arm64 -v "$REGDB":/o ubuntu:26.04 sh -c \
  "apt-get update -qq >/dev/null && apt-get install -y -qq wireless-regdb >/dev/null && cp /usr/lib/firmware/regulatory.db /usr/lib/firmware/regulatory.db.p7s /o/"

opt() { [ -e "$IN/$1" ] && echo "-v $IN/$1:/in/$2:ro" || true; }

# The required input first, with a readable message: without it docker fails somewhere inside the build.
ls "$IN/out/modules"/*.ko >/dev/null 2>&1 || {
    echo "no kernel modules in $IN/out/modules - build them first (kernel/build-linux.sh), or point" >&2
    echo "OPENF50_INPUTS at the directory that has out/modules, firmware/ and android-subset/." >&2
    exit 1
}
# The optional ones decide whether the image can use the modem, Wi-Fi or the GPU at all. Missing ones
# used to be skipped silently, which produces an image that boots and then does nothing useful.
for o in firmware android-subset android-gpu-subset tools/logdw/logdw tools/bt-init/openf50-bt-init tools/keys/openf50-keys tools/adbd/adbd tools/gpu/cltest busybox upstream/out/modules; do
    [ -e "$IN/$o" ] && echo "  + $o" || echo "  - $o   (missing: the image is built without it)"
done
# shellcheck disable=SC2046
docker run --rm --platform linux/arm64 \
  -v "$TOP/rootfs/overlay/opt/openf50":/in/opt-openf50:ro -v "$TOP/openwrt/overlay":/in/overlay:ro \
  -v "$FW4PATCH":/in/fw4-sipa-offload.patch:ro \
  -v "$FW4FTPATCH":/in/fw4-old-kernel-flowtable.patch:ro \
  -v "$NODFSPATCH":/in/wifi-scripts-no-dfs.patch:ro \
  -v "$TOP/boot/module-order.txt":/in/module-order.txt:ro -v "$IN/out/modules":/in/modules:ro \
  $(opt out/modules.builtin modules.builtin) $(opt out/modules.builtin.modinfo modules.builtin.modinfo) \
  $(opt firmware firmware) $(opt android-subset android-subset) $(opt android-gpu-subset android-gpu-subset) \
  $(opt tools/logdw/logdw logdw) $(opt tools/bt-init/openf50-bt-init bt-init) $(opt tools/keys/openf50-keys keys) $(opt tools/adbd/adbd adbd) $(opt tools/gpu/cltest cltest) \
  $(opt busybox busybox) $(opt upstream/out/modules mainline-modules) -v "$TOP/openwrt":/out -v "$REGDB":/in/regdb:ro "$@" \
  -e KREL=$KREL -e OUT="$(basename "$OUT")" -e OPENF50_VERSION="${OPENF50_VERSION:-dev}" openf50-$FLAVOUR-base:$VER /bin/sh -eu -c '
mkdir -p /var/lock /var/run /tmp
# The packages come from the feed over the network while the image is built, and one connection cut in the middle of
# one package failed the whole image, and a release with it. update, upgrade and add are tried three times, ten
# seconds apart; what fails three times (a package the feed does not have) fails the build as before. Everything
# else (del) runs once. The idea is from kanoqwq/clean-tf-7.2 33640d01 (FINDINGS 66).
# --- apk-retry begin
apk() {
    case ${1:-} in
        update|upgrade|add) ;;
        *) command apk "$@"; return ;;
    esac
    _try=1
    until command apk "$@"; do
        [ "$_try" -lt 3 ] || return 1
        _try=$((_try + 1))
        echo "apk $1 failed; trying again ($_try of 3)" >&2
        sleep "${OPENF50_APK_RETRY_WAIT:-10}"
    done
}
# --- apk-retry end
apk update >/dev/null
# the release tarball carries the packages of the day the release was cut; the feed of the release branch moves on
# (LuCI, mbedtls, the CA bundle, iwinfo ...), and "apk add" below installs only what is missing, so without this
# an image shipped months later still has the old LuCI and the package manager shows every update on the first look
apk upgrade >/dev/null
# openssl-util: the VPN module (openf50-vpn, github.com/dikeckaan/mu300-linux-vpn) fetches the VPN server certificate
# with it to pin, for links that ask for allowInsecure;
# i2c-tools, gpiod-tools: openf50-usb (the charger of the U30 Air) and openf50-nfc (its NFC tag);
# jq: the VPN module reads vmess links and raw Xray/sing-box configs with it, and rewrites those configs at every start
if [ -d /in/u30-sae ]; then
    apk add --allow-untrusted /in/u30-sae/hostapd-common-*.apk /in/u30-sae/wpad-basic-openssl-*.apk >/dev/null
else
    apk add wpad-basic-mbedtls >/dev/null
fi
apk add wifi-scripts iwinfo wireless-regdb iw bash flock ip-full coreutils-stty openssl-util \
    i2c-tools gpiod-tools jq >/dev/null
# the router protocols LuCI offers, with their tools: WireGuard, PPTP/L2TP (PPPoE is in the base), 6in4/6rd/DS-Lite,
# GRE and VXLAN, ipset, and SQM (cake). Their kmod-* dependencies install the 6.12 modules of the feed, removed below like
# every other kmod: the mainline kernels have them built in or as modules of their own (openf50-mainline.config), 5.4
# has some of them only
apk add wireguard-tools luci-proto-wireguard ppp-mod-pptp xl2tpd 6in4 6rd ds-lite gre luci-proto-gre vxlan \
    luci-proto-vxlan ipset sqm-scripts luci-app-sqm >/dev/null
# the pinned Aurora theme
[ -d /in/luci-plugin ] && apk add --allow-untrusted /in/luci-theme-aurora.apk >/dev/null
# iStore app store: its official apk feed (the key is hash-pinned on the host side). The feed stays
# in the image customfeeds.list, so packages from the store can be added later with apk add.
if [ -e /in/istore-apk.pem ]; then
    cp /in/istore-apk.pem /etc/apk/keys/istore.pem
    printf "%s\n" "https://istore.istoreos.com/repo-apk/all/store/packages.adb" \
        "https://istore.istoreos.com/repo-apk/all/nas_luci/packages.adb" \
        "https://istore.istoreos.com/repo-apk/all/meta/packages.adb" \
        "https://istore.istoreos.com/repo-apk/aarch64_generic/nas/packages.adb" \
        >> /etc/apk/repositories.d/customfeeds.list
    apk update >/dev/null
    apk add luci-app-store luci-lib-taskd luci-lib-xterm taskd >/dev/null
    [ -s /usr/lib/lua/luci/controller/store.lua ] || { echo "iStore install failed" >&2; exit 1; }
fi
# PassWall: the passwall-build apk feed (key hash-pinned on the host side). Resolved at build time,
# so the image carries the latest PassWall and engines of the moment. The feeds stay in the image
# customfeeds.list for later apk-side updates (they sit behind SourceForge).
if [ -e /in/openwrt-passwall-build.pem ]; then
    cp /in/openwrt-passwall-build.pem /etc/apk/keys/openwrt-passwall-build.pem
    printf "%s\n" "https://master.dl.sourceforge.net/project/openwrt-passwall-build/snapshots/packages/aarch64_generic/passwall_luci/packages.adb" \
        "https://master.dl.sourceforge.net/project/openwrt-passwall-build/snapshots/packages/aarch64_generic/passwall_packages/packages.adb" \
        "https://master.dl.sourceforge.net/project/openwrt-passwall-build/snapshots/packages/aarch64_generic/passwall2/packages.adb" \
        >> /etc/apk/repositories.d/customfeeds.list
    retry() { i=1; while true; do "$@" && return 0; i=$((i+1)); [ $i -gt 6 ] && return 1; sleep 10; done; }
    retry apk update >/dev/null
    retry apk add luci-app-passwall luci-i18n-passwall-zh-cn xray-core sing-box geoview hysteria \
        ipt2socks naiveproxy v2ray-plugin xray-plugin simple-obfs-client >/dev/null
    [ -s /usr/lib/lua/luci/controller/passwall.lua ] && [ -s /usr/share/passwall/app.sh ] || { echo "PassWall install failed" >&2; exit 1; }
fi
# Vantage: install and make it the default theme (Aurora stays as an option)
if [ -d /in/vantage ]; then
    apk add --allow-untrusted /in/vantage/*.apk >/dev/null
    [ -d /www/luci-static/vantage ] || { echo "Vantage theme assets missing" >&2; exit 1; }
fi
# relay mode (panel system only): ra-deprecate sends its router advertisement through a raw ICMPv6 socket (#87)
[ -d /in/luci-plugin ] && apk add ucode-mod-socket >/dev/null
# System > Terminal (panel system only): ttyd, and luci-app-ttyd for its settings page and translations; the image
# configures it (luci-overlay/etc/config/ttyd: LAN address only, a root shell only for a token of a LuCI session)
[ -d /in/luci-plugin ] && apk add ttyd luci-app-ttyd >/dev/null
# ujail drops CAP_PERFMON (38), which this 5.4 kernel does not know: jailed services (dnsmasq, ntpd) crash-loop
apk del procd-ujail procd-seccomp >/dev/null 2>&1 || true
# online firmware upgrades flash whole-disk armsr images: that would overwrite the eMMC, so remove them
apk del luci-app-attendedsysupgrade attendedsysupgrade-common owut >/dev/null 2>&1 || true
# what those leave in /etc/config, and the .apk-new copies the upgrade above writes beside a changed config: an update
# adds every config file of the image the device does not have yet (openf50-update), and these belong to no package
rm -f /etc/config/attendedsysupgrade /etc/config/*.apk-new
# LuCI in Turkish and Simplified Chinese besides English, in both systems: the translation of luci-base and of
# every LuCI app the image has that the feed translates (apk checks each package against the signed index). Their
# own uci-defaults, run by apk here, register the languages in luci.languages; the other languages are the lang
# extra (openf50-extra install lang).
i18n=
for c in base $(apk list --installed "luci-app-*" | sed -n "s/^luci-app-\([^ ]*\)-[0-9][^ -]* .*/\1/p"); do
    for l in tr zh-cn; do
        apk search "luci-i18n-$c-$l" | grep -q "^luci-i18n-$c-$l-[0-9]" && i18n="$i18n luci-i18n-$c-$l"
    done
done
echo "LuCI translations:$i18n"
for l in tr zh-cn; do
    case " $i18n " in *" luci-i18n-base-$l "*) ;; *) echo "no LuCI base translation $l in the feed" >&2; exit 1 ;; esac
done
apk add $i18n >/dev/null
R=/build/root; mkdir -p $R
# copy the live filesystem of this container (the OpenWrt rootfs plus packages), without runtime mounts
for e in /*; do
    case "$e" in /proc|/sys|/dev|/build|/in|/out|/tmp) continue ;; esac
    cp -a "$e" $R/
done
mkdir -p $R/proc $R/sys $R/dev $R/tmp $R/run $R/opt
# Docker bind-mounts these three into the container, so the copy above picks up the build host versions:
# a resolv.conf pointing at the internal Docker DNS (which broke every lookup the device itself made), a hosts
# file with the container id, and a hostname that was the container id. Put the OpenWrt ones back.
# (no apostrophes in here: this whole block is one single-quoted argument to sh -c)
ln -sf /tmp/resolv.conf $R/etc/resolv.conf
printf "127.0.0.1\tlocalhost\n\n::1\tlocalhost ip6-localhost ip6-loopback\nff02::1\tip6-allnodes\nff02::2\tip6-allrouters\n" > $R/etc/hosts
printf "OpenF50\n" > $R/etc/hostname   # the real one comes from uci (etc/uci-defaults/90-openf50)
cp -a /in/opt-openf50 $R/opt/openf50
cp -a /in/overlay/. $R/
# openf50cell reports sipa_eth0 as l3_device only, so fw4 leaves it out of its software flowtable and the cellular
# downlink takes the slow forwarding path. --fuzz=0: a changed fw4 that no longer matches fails the build.
# (patch goes into the build container only: the image was copied above)
apk add patch >/dev/null
patch --batch --fuzz=0 -d $R -p1 -i /in/fw4-sipa-offload.patch
grep -q sipa_eth0 $R/usr/share/ucode/fw4.uc || { echo "fw4 patch not applied" >&2; exit 1; }
patch --batch --fuzz=0 -d $R -p1 -i /in/fw4-old-kernel-flowtable.patch
grep -q drop_old_flowtable $R/sbin/fw4 || { echo "fw4 flowtable patch not applied" >&2; exit 1; }
# wifi-scripts: a driver without radar detection (no radar_detect_widths, the SC2355) never gets an access point on a
# DFS channel - hostapd fails start_dfs_cac and the hotspot stays down otherwise (FINDINGS 42)
patch --batch --fuzz=0 -d $R -p1 -i /in/wifi-scripts-no-dfs.patch
grep -q "device_no_dfs(config);" $R/usr/share/ucode/wifi/hostapd.uc || { echo "wifi-scripts DFS patch not applied" >&2; exit 1; }
apk del patch >/dev/null   # out of packages.txt below, which lists what the image has
if [ -d /in/luci-plugin ]; then
    [ -d /in/luci-overlay ] && cp -a /in/luci-overlay/. $R/
    cp -a /in/luci-plugin/root/. $R/
    cp -a /in/luci-plugin/htdocs/. $R/www/
    chmod 0755 $R/etc/init.d/unisoc-modem-ui $R/etc/hotplug.d/net/90-unisoc-usb-host $R/etc/hotplug.d/iface/90-unisoc-usb-host $R/usr/libexec/rpcd/openf50dash $R/usr/libexec/rpcd/openf50vpn $R/usr/libexec/unisoc-modem/*
    chmod 0755 $R/usr/libexec/rpcd/openf50term $R/usr/libexec/openf50-terminal-login $R/etc/hotplug.d/iface/95-openf50-terminal
    # the terminal is System > Terminal (the panel menu: the page, and the settings page of luci-app-ttyd); its own Services >
    # Terminal frames ttyd without a token, which openf50-terminal-login refuses
    rm -f $R/usr/share/luci/menu.d/luci-app-ttyd.json
    # ttyd as luci-overlay configures it, never the package default (/bin/login on every LAN instance, no origin check)
    grep -q "^	option command ./usr/libexec/openf50-terminal-login.$" $R/etc/config/ttyd &&
        ! grep -v "^#" $R/etc/config/ttyd | grep -q "/bin/login" || { echo "ttyd is not configured for the panel" >&2; exit 1; }
    # the panel catalogs, named as LuCI names the language (base.zh-cn.lmo: openf50.zh-cn.lmo)
    for f in /in/catalogs/openf50.*.lmo; do cp "$f" $R/usr/lib/lua/luci/i18n/; done
    [ -s $R/www/luci-static/aurora/main.css ] || { echo "Aurora theme assets missing" >&2; exit 1; }
    # the default theme is set on first boot (etc/uci-defaults/91-openf50-luci); with Vantage bundled
    # it is the default and Aurora stays as an option
    if [ -d $R/www/luci-static/vantage ]; then
        sed -i "s|/luci-static/aurora|/luci-static/vantage|" $R/etc/uci-defaults/91-openf50-luci
    fi
    grep -qE "mediaurlbase=.*/luci-static/(aurora|vantage)" $R/etc/uci-defaults/91-openf50-luci || {
        echo "no known default theme in 91-openf50-luci" >&2; exit 1;
    }
fi
# the languages LuCI offers (System > System > Language and Style lists English and these); the base catalogs register
# their own, this covers one that did not
L=$R/usr/lib/lua/luci/i18n
for l in tr zh-cn; do
    [ -s $L/base.$l.lmo ] || { echo "LuCI catalog base.$l.lmo missing" >&2; exit 1; }
done
uci -c $R/etc/config -q get luci.languages.tr >/dev/null || uci -c $R/etc/config set luci.languages.tr="Türkçe (Turkish)"
uci -c $R/etc/config -q get luci.languages.zh_cn >/dev/null ||
    uci -c $R/etc/config set luci.languages.zh_cn="$(printf "\347\256\200\344\275\223\344\270\255\346\226\207 (Simplified Chinese)")"
uci -c $R/etc/config commit luci
uci -c $R/etc/config show luci.languages
# SQM (openwrt-luci): the default queue (disabled) shapes the generic eth1, which the OPENF50 does not have, so LuCI
# offered a device that is not there; it names the cellular uplink, sipa_eth0, instead
if [ -f $R/etc/config/sqm ]; then
    for q in $(uci -c $R/etc/config -q show sqm | sed -n "s/^sqm\.\([^.]*\)\.interface=.eth1.$/\1/p"); do
        uci -c $R/etc/config set sqm.$q.interface=sipa_eth0
    done
    uci -c $R/etc/config commit sqm
    uci -c $R/etc/config -q show sqm | grep -q "\.interface=.eth1.$" && { echo "SQM still names eth1" >&2; exit 1; }
fi
mv $R/sbin/sysupgrade $R/sbin/sysupgrade.openwrt && mv $R/usr/libexec/openf50-sysupgrade $R/sbin/sysupgrade
M=$R/lib/modules/$KREL; mkdir -p $M
cp /in/modules/*.ko $M/          # ubox kmodloader expects the modules flat in /lib/modules/<release>/
for f in modules.builtin modules.builtin.modinfo; do [ -e /in/$f ] && cp /in/$f $M/; done
[ -d /in/firmware ] && { mkdir -p $R/lib/firmware; cp -a /in/firmware/. $R/lib/firmware/; }
# tools shared with the Ubuntu image look under /usr/lib/firmware (openf50-bt-init, for one); OpenWrt keeps
# firmware in /lib/firmware
mkdir -p $R/usr/lib && ln -sfn ../../lib/firmware $R/usr/lib/firmware
cp /in/regdb/regulatory.db /in/regdb/regulatory.db.p7s $R/lib/firmware/
if [ -d /in/android-subset ]; then
    mkdir -p $R/opt/openf50/android && cp -a /in/android-subset/. $R/opt/openf50/android/
    mv $R/opt/openf50/android/dev/__properties__ $R/opt/openf50/android/dev-properties && rmdir $R/opt/openf50/android/dev
fi
[ -d /in/android-gpu-subset ] && cp -a /in/android-gpu-subset/. $R/opt/openf50/android/
[ -e /in/cltest ] && { mkdir -p $R/opt/openf50/android/system/bin; cp /in/cltest $R/opt/openf50/android/system/bin/cltest; chmod 755 $R/opt/openf50/android/system/bin/cltest; }
[ -e /in/logdw ] && { cp /in/logdw $R/opt/openf50/bin/logdw; chmod 755 $R/opt/openf50/bin/logdw; }
[ -e /in/bt-init ] && { cp /in/bt-init $R/opt/openf50/bin/openf50-bt-init; chmod 755 $R/opt/openf50/bin/openf50-bt-init; }
[ -e /in/keys ] && { cp /in/keys $R/opt/openf50/bin/openf50-keys; chmod 755 $R/opt/openf50/bin/openf50-keys; }
# adb over USB (tools/adbd, static): on unless openf50-usb adb off
[ -e /in/adbd ] && { cp /in/adbd $R/opt/openf50/bin/adbd; chmod 755 $R/opt/openf50/bin/adbd; }
# the VPN engines are not part of the image: they are the vpn extra (openf50-extra install vpn)
# full static busybox for the tools OpenWrt busybox leaves out (od, timeout, mountpoint, losetup, rfkill, telnetd)
if [ -e /in/busybox ]; then
    cp /in/busybox $R/opt/openf50/bin/busybox; chmod 755 $R/opt/openf50/bin/busybox
    mkdir -p $R/opt/openf50/busybox-bin
    for a in od timeout losetup telnetd getty; do
        chroot $R /bin/sh -c "command -v $a" >/dev/null 2>&1 && continue
        ln -sf ../bin/busybox $R/opt/openf50/busybox-bin/$a
    done
fi
mkdir -p $R/etc/openf50
printf "%s\n" "${OPENF50_VERSION:-dev}" > $R/etc/openf50/image-version
# enable the services (rc.common "enable" needs ubus, which is not running in the build container)
# accounts still those of the image until an installer or openf50-update puts the device ones in place
: > $R/etc/.openf50-accounts-from-image
for s in openf50-accounts openf50-vendor openf50-hw openf50-post openf50-toolkit openf50-cpu openf50-atd openf50-modem-log openf50-wifi-client openf50-buttons openf50-power openf50-traffic openf50-user-packages openf50-adbd; do
    n=$(sed -n "s/^START=//p" $R/etc/init.d/$s)
    ln -sf ../init.d/$s $R/etc/rc.d/S$n$s
done
if [ -d /in/luci-plugin ]; then
    n=$(sed -n "s/^START=//p" $R/etc/init.d/unisoc-modem-ui)
    ln -sf ../init.d/unisoc-modem-ui $R/etc/rc.d/S${n}unisoc-modem-ui
    # stopped at shutdown: the operations log of the panel (openf50dash flush-ops) is kept for the next boot
    n=$(sed -n "s/^STOP=//p" $R/etc/init.d/unisoc-modem-ui)
    ln -sf ../init.d/unisoc-modem-ui $R/etc/rc.d/K${n}unisoc-modem-ui
    # the SMS pool behind the panel (K69, D11): openwrt-luci only, the sms command stays the SMS tool of every system
    chmod 0755 $R/opt/openf50/bin/openf50-sms $R/opt/openf50/bin/openf50-smsd $R/opt/openf50/bin/openf50-sms-forward $R/etc/init.d/openf50-smsd
    n=$(sed -n "s/^START=//p" $R/etc/init.d/openf50-smsd)
    ln -sf ../init.d/openf50-smsd $R/etc/rc.d/S${n}openf50-smsd
    # the dashboard AT channels, nr6 and nr7 (K19): the collector of the panel prefers them over nr1
    chmod 0755 $R/etc/init.d/openf50-atd-dash
    n=$(sed -n "s/^START=//p" $R/etc/init.d/openf50-atd-dash)
    ln -sf ../init.d/openf50-atd-dash $R/etc/rc.d/S${n}openf50-atd-dash
    # the routes of relay mode to the LAN (K37): it starts ndp-learn only when wan is in relay mode
    chmod 0755 $R/opt/openf50/bin/ndp-learn $R/lib/netifd/proto/openf50cell-v6.sh $R/etc/init.d/openf50-ndp
    n=$(sed -n "s/^START=//p" $R/etc/init.d/openf50-ndp)
    ln -sf ../init.d/openf50-ndp $R/etc/rc.d/S${n}openf50-ndp
    ln -sf /opt/openf50/bin/openf50-sms $R/usr/bin/openf50-sms
    # Vantage menu icons (store/cellular) when that theme is installed: patched at every boot
    chmod 0755 $R/opt/openf50/bin/openf50-vantage-icons $R/etc/init.d/openf50-vantage-icons
    n=$(sed -n "s/^START=//p" $R/etc/init.d/openf50-vantage-icons)
    ln -sf ../init.d/openf50-vantage-icons $R/etc/rc.d/S${n}openf50-vantage-icons
    # System > Terminal: apk enabled ttyd itself
    [ -e $R/etc/rc.d/S99ttyd ] || { echo "ttyd is not enabled" >&2; exit 1; }
fi
# the OpenWrt button handlers (power: a tap is poweroff; wps, rfkill) are replaced: openf50-buttons owns the keys
mkdir -p $R/etc/rc.button
for b in power wps rfkill; do
    printf "#!/bin/sh\n# openf50-buttons owns the keys (see /opt/openf50/bin/openf50-buttons)\nexit 0\n" > "$R/etc/rc.button/$b"
    chmod 0755 "$R/etc/rc.button/$b"
done
# no config file of a removed package and no .apk-new copy in the image: an update adds every etc/config file of the
# image the device lacks (openf50-update), so these would land on every device (v2026.10.18, built before the cleanup
# above, had both). Removed again here, in the image itself, and checked.
rm -f $R/etc/config/attendedsysupgrade $R/etc/config/*.apk-new
for f in $R/etc/config/attendedsysupgrade $R/etc/config/*.apk-new; do
    [ ! -e "$f" ] || { echo "stray config file in the image: $f" >&2; exit 1; }
done
# what apk installed, for comparing two builds (packages on the release feed are not pinned)
apk list --installed | sort > $R/etc/openf50/packages.txt
# the packages the image asks for (its world file): an update installs the others again, the ones added on the
# device (openf50-update, upk_record; read with its own function)
(OPENF50_LIB=1; . /in/opt-openf50/bin/openf50-update; upk_manual $R openwrt) > $R/etc/openf50/image-packages
[ -s $R/etc/openf50/image-packages ] || { echo "no package list for etc/openf50/image-packages" >&2; exit 1; }
# busybox PATH is /usr/sbin:/usr/bin:/sbin:/bin, so the commands go into /usr/bin (the same list as Ubuntu)
for c in $(cat /in/opt-openf50/lib/path-commands); do ln -sf /opt/openf50/bin/$c $R/usr/bin/$c; done
# no kernel of its own: OpenWrt kmods (6.12) and grub are unused on this device
rm -rf $R/lib/modules/6.* $R/boot
# the modules of the mainline kernel (upstream/out: the vendor ones and those of the kernel itself, about 20 MiB), so that
# a switch to it needs nothing more; openf50-update installs those of the bundle it boots over them
if ls /in/mainline-modules/*.ko >/dev/null 2>&1; then
    # the release the modules were built for (their vermagic), not a version written down here
    krel=$(for f in /in/mainline-modules/*.ko; do tr "\0" "\n" < $f | sed -n "s/^vermagic=\([^ ]*\) .*/\1/p"; break; done)
    [ -n "$krel" ] && mkdir -p $R/lib/modules/$krel && cp /in/mainline-modules/*.ko $R/lib/modules/$krel/
fi
cd $R && tar -czf /out/$OUT .
ls -la /out/$OUT'
rm -rf "$REGDB" ${CAT:+"$CAT"}
