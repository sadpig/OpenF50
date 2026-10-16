# 自己动手构建全部组件

`./install.sh`（预构建）不需要这里的任何内容。仅当你想自己编译内核和根文件系统（而不是下载它们），或者你在维护本项目时，才按本页操作。请先阅读 [`../README.md`](../README.md)。

## 启动流程概览

```
LK (slot b, tries=2) ─► custom 5.4 kernel + vendor_boot DTB
   └─► initramfs /init (boot/init)
         ├─ load 85 modules in a fixed order (boot/module-order.txt)
         ├─ misc: restore slot a, unless the rootfs says default-boot=linux
         ├─ bind USB gadget: NCM, else ECM (usb0 up immediately) + ACM console; OPENF50_USBNET="rndis" binds RNDIS as the one configuration with the console, and replaces the other network function (rndis wins in either order of "rndis ncm"; a panel choice of RNDIS asks for "rndis ncm ecm", so a kernel without f_rndis still gets NCM)
         ├─ an SD card with ext4 "openf50sd", else losetup at the first 2 MiB boundary after the last partition
         │  (27762098176 on the tested device) → ext4 "openf50root" (free space after userdata)
         └─ switch_root → systemd
               ├─ openf50-vendor   : Android modem_control in a chroot (disarms PM watchdog, boots modem)
               ├─ openf50-lan      : br-lan (usb0 + wlan0) 192.168.77.1 + dnsmasq DHCP/DNS
               ├─ openf50-wifi     : pcie-sprd, wcn_bsp, sprd_wlan_combo
               ├─ openf50-mobile-data : AT on /dev/stty_nr1, sipa_eth0, nftables NAT
               ├─ openf50-bluetooth : sprdbt_tty, openf50-bt-init (PSKey/RF), btattach → bluetoothd
               └─ ssh.socket, telnetd, serial-getty@ttyGS0
```

各步骤背后的原因（LK 槽位规则、LZ4 ramdisk、USB 依赖链、PM 看门狗、`modem_control` 进程名检查、macOS ECM 链路状态……）请阅读 [`FINDINGS.md`](FINDINGS.md)。

## 构建步骤

### 1. 内核
只需一步，从固定的公开源码（内核源码树、realme Wi-Fi/蓝牙/Mali 模块）构建，所有补丁均已应用：
```sh
kernel/build-all.sh    # -> out/Image, out/modules/*.ko, out/modules.builtin*  (about 10 minutes on Apple silicon)
```
维护者用 `tools/make-release.sh TAG --publish` 发布预构建镜像（如果镜像中包含固件、Android 文件、主机密钥或本地设置，它会拒绝发布）。

**从 GitHub Actions 发布。** 同一个 release 也可以在 GitHub arm64 runner 上构建：Actions > Release > Run workflow，ref 填 `main`（该任务拒绝任何其他 ref，以及已存在的 tag 或 release），填写 tag，并保持 prerelease 开启。它会构建 5.4 内核、主线 6.18 与 7.2 内核及其模块（首次约一小时；当内核产物仍在 Actions 缓存中时约五分钟——在 `kernel/`、`upstream/` 或 kernel.org 上的最新版本变化之前它们一直在缓存里），然后运行 `tools/make-release.sh --publish --prerelease` 并分发 Magisk zip。之后在设备上试用该 prerelease，编辑其说明，再用 `gh release edit TAG --prerelease=false --latest` 将其转正：只有这时安装器和 `openf50-update` 才会向用户提供它。由 workflow 生成的 release 没有 `tools/gpu/cltest`（它需要在本地针对 Android 的库构建，不在仓库中；`make-release.sh` 只有在它存在时才会包含它），因此这类 release 中 `openf50-toolkit` 没有 GPU 压力测试项；而在带有该二进制的机器上手工制作的 release 则有。手工运行 `tools/make-release.sh TAG --publish` 仍像以前一样可用，且不会触发 workflow——workflow 只在被请求时运行。

`build-all.sh` 背后的手工步骤：
```sh
git clone https://github.com/dikeckaan/zte-ums9620-kernel-5.4.254   # or the Enceka U30 Air repo
docker build -t openf50-kbuild kernel/
docker volume create openf50-kernel
docker run --rm -v openf50-kernel:/src -v "$PWD/../zte-ums9620-kernel-5.4.254":/tree openf50-kbuild cp -a /tree /src/zte-u30air
cp kernel/f50-stock-B09.config kernel/device.config
docker run --rm -v openf50-kernel:/src -v "$PWD/kernel":/work openf50-kbuild bash /work/build-linux.sh
```
`build-linux.sh` 将 `openf50-linux.fragment` 合并进原厂配置，切换到 ThinLTO，并把 `Image` 和模块构建到 `/src/out-linux`。把 `Image`、`modules.builtin*` 和所有 `*.ko`（扁平化，`llvm-strip --strip-debug`）复制到 `out/`。

Wi-Fi 驱动：从 realme C51/C53 AndroidT 内核源码中提取 `kernel_modules/kernel5.4/wcn/wlan/wlan_combo`，放到卷中的 `/src/ext-wlan_combo`，然后运行 `kernel/build-wlan.sh`（会应用 `patches/wlan_combo-*.patch` 文件）。

内核补丁：按 `kernel/build-all.sh` 中 `KPATCHES` 列出的顺序，把 `kernel/patches/*.patch` 文件（`patch -p1`）应用到内核源码树，再执行 `echo -gb50db5b6224c > .scmversion`，使版本字符串不会带上 `-dirty` 后缀。`xfrm-sysctl-fragment-per-netns.patch` 在会创建网络命名空间（Docker、沙箱、`unshare -n`）的系统上是唯一不可省略的：没有它，原厂内核会在命名空间销毁时 panic（FINDINGS §44）。

GPU：从 realme 源码树（master 分支）把 `kernel_modules/kernel5.4/gpu/natt/mali` 复制到 `/src/ext-mali`，运行 `kernel/build-mali.sh`；用 `android-vendor/extract-gpu-subset.sh` 提取用户空间部分，并用 `tools/gpu/build.sh <包含 libc.so libdl.so libOpenCL.so 的目录>` 构建 `tools/gpu/cltest`。

蓝牙：从同一个 realme 源码树构建 `sprdbt_tty.ko`（`wcn/bluetooth/driver/tty-pcie`，`BSP_BOARD_UNISOC_WCN_SOCKET=pcie`），以及 vendor-init 工具：`docker run --rm -v "$PWD/tools/bt-init":/w openf50-kbuild gcc -O2 -static -o /w/openf50-bt-init /w/openf50-bt-init.c`。

### 2. Android vendor 子集（来自你的设备）
```sh
android-vendor/extract-subset.sh android-subset
python3 android-vendor/gen-ueventd-perms.py android-subset/vendor/etc/ueventd.rc <vendor init *.rc> > android-vendor/ueventd-perms.sh
# the F50's inputs are kept in android-vendor/ueventd/: regenerate after changing the generator with
# python3 android-vendor/gen-ueventd-perms.py android-vendor/ueventd/ueventd.rc android-vendor/ueventd/init-perms.rc > android-vendor/ueventd-perms.sh
# (and copy it to rootfs/overlay/opt/openf50/bin/ueventd-perms.sh; tests/test_vendor_ids.py checks both)
```

### 3. 启动镜像
```sh
docker build -t openf50-ubuntu:24.04 rootfs/
docker run --rm openf50-ubuntu:24.04 cat /bin/busybox > busybox && chmod +x busybox   # static, has mdev/losetup/switch_root/telnetd
docker run --rm -v "$PWD/tools/logdw":/w openf50-kbuild gcc -O2 -static -o /w/logdw /w/logdw.c
python3 boot/build-boot-image.py --stock-boot dumps/boot_a.img --misc-head dumps/misc-head.bin \
  --kernel out/Image --modules out/modules --busybox busybox --logdw tools/logdw/logdw \
  --ueventd-perms android-vendor/ueventd-perms.sh --android-subset android-subset --out boot-linux-slotb.img
```

### 4. eMMC 空闲区域上的根文件系统
1. 在*你的*设备上确认 `userdata` 之后的空间确实未分配（将最后一个分区的结束位置与 GPT 的最后一个可用 LBA 对比），并调整 `boot/init` 和 `tools/android-mount-openf50root.sh` 中的 `ROOT_OFFSET`。
2. 在 Android（root）上，通过有边界的 loop 设备创建文件系统，并先验证偏移量/大小。
3. 组装并部署：
```sh
cid=$(docker create openf50-ubuntu:24.04); docker export $cid > rootfs/base.tar; docker rm $cid
# the VPN is not part of the image: it is the module of github.com/dikeckaan/mu300-linux-vpn (built there with
# tools/make-module.sh); on the device: sudo openf50-extra install vpn [--from openf50-linux-vpn.tar.gz]
# adbd (adb over USB to Linux, on by default: openf50-usb adb): static aarch64, a couple of minutes; without it the
# image has no adb
sh tools/adbd/build.sh tools/adbd/adbd
docker run --rm -v "$PWD/rootfs":/w -v "$PWD/out/modules":/kmods:ro -v "$PWD/out":/kout:ro \
  -v "$PWD/firmware":/firmware:ro -v "$PWD/android-subset":/android-subset:ro -v "$PWD/tools/logdw/logdw":/logdw:ro \
  -v "$PWD/tools/bt-init/openf50-bt-init":/bt-init:ro -v "$PWD/tools/adbd/adbd":/adbd:ro \
  openf50-ubuntu:24.04 bash /w/assemble.sh
```
将 `openf50-ubuntu-24.04-rootfs.tar.gz` 推送到设备，并用 `tools/android-mount-openf50root.sh` 解包。`firmware/` 存放来自设备 `/odm/firmware` 的 `wcnmodem.bin`、`gnssmodem.bin` 和 `wifi_board_config*.ini`，以及来自 `/vendor/etc` 的 `bt_configure_pskey.ini` 和 `bt_configure_rf.ini`。

### 5. 启动 Linux
```sh
boot/flash-trial.sh boot-linux-slotb.img
```
约 50 秒后：`ssh ubuntu@192.168.77.1`（密码 `ubuntu`，**请修改它**）、`telnet 192.168.77.1`，或 `screen /dev/cu.usbmodem* 115200`。`sudo /opt/openf50/bin/mobile-data status|up [APN]|down|sim-reset` 控制调制解调器（除非你运行过 `down`，否则 `openf50-mobile-data-watch` 会自动重连）。`sudo reboot` 返回 Android。如果试用失败，在 Android 上用 `tools/collect-logs.sh` 收集日志。

将 Linux 设为默认系统（在 Linux 内执行）：
```sh
sudo openf50-next-boot linux     # every successful boot re-arms slot b (openf50-boot-ok.service)
sudo openf50-next-boot android   # next reboot goes to Android and stays there
sudo openf50-next-boot status
```
热点设置位于 `/etc/openf50/hotspot.conf`（`SSID=`、`PSK=`、`BAND=5|2.4`、`CHANNEL=auto|n`、`COUNTRY=`）；`tools/android-import-hotspot.sh` 会在首次启动前把当前 Android 热点配置复制进去，否则会生成随机密码并在登录时显示。

在 Android 上，`boot/android-boot-linux.sh boot-linux-slotb.img` 无需重刷即可再次启动已在 `boot_b` 上的镜像。如果 Linux 在 `openf50-boot-ok` 运行之前启动失败，LK 会在下次启动时看到 `tries_remaining=1` 并回退到 Android。

## 带 OPENF50 控制面板的 OpenWrt（`openwrt-luci`）

`openwrt/build-rootfs.sh` 构建所有类 OpenWrt 系统；`OPENF50_SYSTEM` 选择其中一个（默认 `openwrt`）：
```sh
OPENF50_SYSTEM=openwrt-luci openwrt/build-rootfs.sh openf50-openwrt-luci-rootfs.tar.gz
```
它是原版 OpenWrt 构建加上 `openwrt/luci-overlay/`（短信池、面板的 AT 通道、IPv6 中继模式、首次启动默认值）、`openwrt/luci-app-openf50/` 中的应用以及 Aurora 主题。它只基于 OpenWrt 构建：`OPENF50_SYSTEM=openwrt-luci` 与 `OPENF50_FLAVOUR=immortalwrt` 的组合会被拒绝。

* `OPENF50_LUCI_THEME_APK` —— 固定版本的 Aurora `.apk`（`luci-theme-aurora-1.4.0-r20260920.apk`）的本地副本，用于离线构建；没有它，构建会联网下载该文件。校验所用的 SHA256 固定在脚本中，无法覆盖。
* `tools/po2lmo.py IN.po OUT.lmo` 把应用的 `po/*/openf50.po` 编译为 LuCI 加载的 `.lmo` 目录文件（仅用标准库 Python，输出与 LuCI 自带的 `po2lmo` 逐字节一致；参考文件在 `tests/fixtures/po2lmo`）。该应用没有复数消息，也没有 `msgctxt`；工具对两者都会拒绝。
* `tools/luci-i18n.py check|extract|update` 让 `po/tr` 与 `po/zh_Hans` 和应用的 JavaScript、菜单、ACL 及后端中的消息保持同步（缺失、过期、占位符和游离 CJK 问题）。`python3 tools/check-i18n.py` 对安装器的 `i18n/*.tsv` 做同样的检查。

`tools/make-release.sh` 在其他镜像旁边构建 `openf50-openwrt-luci-rootfs.tar.gz` 资产，并以同样方式审计它。该资产从 Linux 磁盘上的 `/openwrt-luci` 启动。
