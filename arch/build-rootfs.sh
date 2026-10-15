#!/bin/sh
# Build an Arch Linux ARM root filesystem for the OPENF50 (runs on the host; needs Docker with arm64 support).
#   arch/build-rootfs.sh [OUT.tar.gz]
# Inputs are the same optional ones the other builds use (see openwrt/build-rootfs.sh):
#   out/modules/*.ko  out/modules.builtin*  firmware/  android-subset/  android-gpu-subset/
#   tools/logdw/logdw  tools/bt-init/openf50-bt-init  tools/gpu/cltest  busybox
# (the VPN is the module of github.com/dikeckaan/mu300-linux-vpn, engines included: openf50-extra install vpn)
#
# Arch Linux ARM ships a generic aarch64 root filesystem and a rolling package set, so the userspace is far newer
# than the 5.4 kernel this device runs. That works because nothing here needs new kernel features, but it also
# means an update can break things: this is the "fun" option, not the one to put in a router that must stay up.
set -eu
KREL=5.4.254-gb50db5b6224c
TOP=$(cd "$(dirname "$0")/.." && pwd)
IN=${OPENF50_INPUTS:-$TOP}
OUT=${1:-openf50-arch-rootfs.tar.gz}
BASE=ArchLinuxARM-aarch64-latest.tar.gz
# Arch Linux ARM serves over plain HTTP only; the packages themselves are signed and pacman verifies them
URL=http://os.archlinuxarm.org/os/$BASE

cd "$TOP"
mkdir -p arch
[ -f "arch/$BASE" ] || curl -fL --progress-bar -o "arch/$BASE" "$URL"
docker import --platform linux/arm64 "arch/$BASE" openf50-arch-base:latest >/dev/null

opt() { [ -e "$IN/$1" ] && echo "-v $IN/$1:/in/$2:ro" || true; }
# shellcheck disable=SC2046
docker run --rm --platform linux/arm64 \
  -v "$TOP/rootfs/overlay/opt/openf50":/in/opt-openf50:ro -v "$TOP/rootfs/overlay":/in/overlay:ro \
  $(opt out/modules modules) $(opt out/modules.builtin modules.builtin) \
  $(opt out/modules.builtin.modinfo modules.builtin.modinfo) \
  $(opt firmware firmware) $(opt android-subset android-subset) $(opt android-gpu-subset android-gpu-subset) \
  $(opt tools/logdw/logdw logdw) $(opt tools/bt-init/openf50-bt-init bt-init) $(opt tools/gpu/cltest cltest) \
  $(opt busybox busybox) -v "$TOP/arch":/out \
  -e KREL=$KREL -e OUT="$(basename "$OUT")" -e OPENF50_VERSION="${OPENF50_VERSION:-dev}" \
  openf50-arch-base:latest /bin/bash -eu -c '
export LANG=C
# pacman 7 sandboxes downloads with Landlock and drops to the "alpm" user; neither works inside this container
grep -q "^DisableSandbox" /etc/pacman.conf || sed -i "/^\[options\]/a DisableSandbox" /etc/pacman.conf
grep -q "^DownloadUser" /etc/pacman.conf && sed -i "s/^DownloadUser/#DownloadUser/" /etc/pacman.conf
# the image ships an empty keyring; without it every package install fails signature verification
pacman-key --init >/dev/null 2>&1
pacman-key --populate archlinuxarm >/dev/null 2>&1
pacman -Sy --noconfirm archlinux-keyring archlinuxarm-keyring >/dev/null 2>&1 || true
pacman -Syu --noconfirm --needed \
    systemd systemd-sysvcompat dbus kmod iproute2 iputils net-tools nftables dnsmasq ethtool \
    openssh wpa_supplicant hostapd iw wireless-regdb bluez bluez-utils rfkill \
    ca-certificates curl wget nano less htop sudo bash-completion \
    e2fsprogs dosfstools file procps-ng psmisc lsof usbutils pciutils python jq wireguard-tools >/dev/null
# the generic Arch ARM image carries its own kernel and the full linux-firmware set (about 1.5 GB); this device
# boots the vendor 5.4 kernel from the boot image and gets its firmware from the Android side
pacman -Rns --noconfirm linux-aarch64 linux-firmware linux-firmware-whence 2>/dev/null >/dev/null || true
pacman -Scc --noconfirm >/dev/null 2>&1 || true
rm -rf /var/cache/pacman/pkg/* /usr/share/doc /usr/share/man /usr/share/info /boot/* 2>/dev/null || true

R=/build/root; mkdir -p $R
for e in /*; do
    case "$e" in /proc|/sys|/dev|/build|/in|/out|/tmp) continue ;; esac
    cp -a "$e" $R/
done
mkdir -p $R/proc $R/sys $R/dev $R/tmp $R/run $R/opt

# the OPENF50 scripts, systemd units and configuration (same overlay as the Ubuntu image)
cp -a /in/opt-openf50 $R/opt/openf50
cp -a /in/overlay/etc $R/
mkdir -p $R/usr/lib/modules/$KREL/extra
[ -d /in/modules ] && cp /in/modules/*.ko $R/usr/lib/modules/$KREL/extra/
for f in modules.builtin modules.builtin.modinfo; do [ -e /in/$f ] && cp /in/$f $R/usr/lib/modules/$KREL/; done
depmod -b $R $KREL 2>/dev/null || true
[ -d /in/firmware ] && { mkdir -p $R/usr/lib/firmware; cp -a /in/firmware/. $R/usr/lib/firmware/; }
if [ -d /in/android-subset ]; then
    mkdir -p $R/opt/openf50/android && cp -a /in/android-subset/. $R/opt/openf50/android/
    mv $R/opt/openf50/android/dev/__properties__ $R/opt/openf50/android/dev-properties && rmdir $R/opt/openf50/android/dev
fi
# cp -an FROM/. TO/ needs GNU cp (busybox cp -n skips an existing directory without looking into it); this runs in the build containers only
[ -d /in/android-gpu-subset ] && cp -an /in/android-gpu-subset/. $R/opt/openf50/android/
[ -e /in/cltest ] && { mkdir -p $R/opt/openf50/android/system/bin; install -m755 /in/cltest $R/opt/openf50/android/system/bin/cltest; }
[ -e /in/logdw ] && install -m755 /in/logdw $R/opt/openf50/bin/logdw
[ -e /in/bt-init ] && install -m755 /in/bt-init $R/opt/openf50/bin/openf50-bt-init
[ -e /in/busybox ] && { install -m755 /in/busybox $R/opt/openf50/bin/busybox; mkdir -p $R/opt/openf50/busybox-bin; }
# on PATH for sudo too (secure_path has no /opt/openf50/bin)
for c in openf50-toolkit openf50-next-boot openf50-os openf50-update mobile-data openf50-at wifi-client; do ln -sfn /opt/openf50/bin/$c $R/usr/local/bin/$c; done

# identity and defaults
echo openf50 > $R/etc/hostname
mkdir -p $R/etc/openf50 && printf "%s\n" "${OPENF50_VERSION}" > $R/etc/openf50/image-version
printf "LABEL=openf50root / ext4 defaults,noatime 0 1\n" > $R/etc/fstab
ln -sfn /usr/share/zoneinfo/Europe/Istanbul $R/etc/localtime
sed -i "s/^#en_US.UTF-8/en_US.UTF-8/" $R/etc/locale.gen 2>/dev/null || true
echo "LANG=en_US.UTF-8" > $R/etc/locale.conf
rm -f $R/etc/ssh/ssh_host_*; : > $R/etc/machine-id
ln -sfn /run/systemd/resolve/stub-resolv.conf $R/etc/resolv.conf
# Arch Linux ARM ships an "alarm" user; the installer sets the password of root and of this one
id -u ubuntu >/dev/null 2>&1 || true
chroot $R /usr/bin/useradd -m -s /bin/bash -G wheel ubuntu 2>/dev/null || true
echo "%wheel ALL=(ALL:ALL) ALL" > $R/etc/sudoers.d/wheel; chmod 440 $R/etc/sudoers.d/wheel
# the Android vendor daemons own system account (android-run): uid 1000 is alarm here
chroot $R /usr/bin/useradd --system --user-group --no-create-home --home-dir /nonexistent --shell /usr/bin/nologin \
    --comment "OPENF50 Android vendor daemons" openf50vnd 2>/dev/null || true

# services: same set the Ubuntu image enables
for u in openf50-vendor.service:sysinit.target openf50-lan.service:multi-user.target openf50-ssh-hostkeys.service:sysinit.target \
         serial-getty@ttyGS0.service:getty.target sshd.service:multi-user.target openf50-wifi.service:multi-user.target openf50-wifi-client.service:multi-user.target \
         openf50-mobile-data.service:multi-user.target openf50-mobile-data-watch.service:multi-user.target \
         openf50-fixups.service:sysinit.target openf50-zram.service:swap.target openf50-boot-ok.service:multi-user.target \
         openf50-cp_diskserver.service:multi-user.target openf50-refnotify.service:multi-user.target \
         openf50-extra-modules.service:multi-user.target openf50-hotspot.service:multi-user.target \
         openf50-bluetooth.service:multi-user.target openf50-thermal-guard.service:multi-user.target \
         openf50-firewall.service:sysinit.target openf50-kmsg.service:sysinit.target openf50-toolkit.service:multi-user.target \
         openf50-atd.service:multi-user.target openf50-atd2.service:multi-user.target \
         systemd-networkd.service:multi-user.target systemd-resolved.service:multi-user.target; do
    svc=${u%%:*}; tgt=${u##*:}
    mkdir -p $R/etc/systemd/system/$tgt.wants
    src=/etc/systemd/system/$svc; [ -e $R$src ] || src=/usr/lib/systemd/system/$svc
    case $svc in serial-getty@*) src=/usr/lib/systemd/system/serial-getty@.service ;; esac
    ln -sfn $src $R/etc/systemd/system/$tgt.wants/$svc
done
ln -sfn /dev/null $R/etc/systemd/system/getty@tty1.service

cd $R && tar --numeric-owner -czf /out/$OUT .
ls -la /out/$OUT; du -sh $R
'
echo "built $TOP/arch/$(basename "$OUT")"
