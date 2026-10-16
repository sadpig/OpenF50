# 运行其他发行版

启动路径并不关心它启动的是哪个发行版。initramfs 挂载 Linux 文件系统（SD 卡上标签为 `openf50sd` 的 ext4，否则是 eMMC 空闲区域中的那个），读取 `/.openf50/boot-os`，然后 `switch_root` 进入其中指定的目录。所以一个系统就是一个装有根文件系统的目录，`openf50-os <名称>` 选择下次启动哪一个。

发行版必须自带的东西：

* **arm64（aarch64）用户空间。**
* **它必须能在你运行的内核上工作。** 对 ZTE 原厂 5.4 内核来说，这是实际中的限制：最新的用户空间已经开始依赖更新的内核。Ubuntu 26.04 的 `tar` 用 `openat2`（Linux 5.6）解析每个路径，在 5.4 上会失败，这就是 Ubuntu 26.04 只随主线内核（6.18、7.2）提供的原因。
* **其他都不需要。** 驱动、固件和 Android vendor chroot 都来自本仓库的 overlay，会被复制进每个镜像。

## 此处可直接构建

| 发行版 | 构建 | 备注 |
|---|---|---|
| Ubuntu 24.04 LTS | `rootfs/`（默认） | 经过测试的默认系统，systemd 255 |
| Ubuntu 26.04 LTS | `docker build --build-arg BASE=ubuntu:26.04 -t openf50-ubuntu:26.04 rootfs/`，然后 `rootfs/assemble.sh` | 已发布；需要内核 6.18 或 7.2 |
| OpenWrt 25.12 | `openwrt/build-rootfs.sh` | 路由器用途，LuCI，约 140 MiB 内存 |
| 带 OPENF50 面板的 OpenWrt 25.12 | `OPENF50_SYSTEM=openwrt-luci openwrt/build-rootfs.sh` | 以 `openwrt-luci` 发布，见 [BUILD.md](BUILD.md) |
| ImmortalWrt 25.12 | `OPENF50_FLAVOUR=immortalwrt openwrt/build-rootfs.sh` | 带更多驱动和 LuCI 应用的 OpenWrt 分支 |
| Arch Linux ARM | `arch/build-rootfs.sh` | 滚动更新，258 MiB 镜像 / 安装后 922 MiB；已构建，尚未在硬件上启动 |
| Debian 13 | `docker build --build-arg BASE=debian:13 -t openf50-debian:13 rootfs/`，然后 `rootfs/assemble.sh` | 包名与 Ubuntu 相同 |
| Kali Linux | `docker build --build-arg BASE=kalilinux/kali-rolling -t openf50-kali rootfs/`，然后 `rootfs/assemble.sh` | 见下文 |

Arch 构建会移除通用 Arch ARM 镜像自带的 `linux-aarch64` 内核和 `linux-firmware` 软件包（约 1.5 GB）：本设备从启动镜像引导原厂内核，并从 Android 获取固件。`pacman` 的 Landlock 沙箱仅在构建期间禁用，因为它无法在构建容器内工作。

## 如实介绍 Kali Linux

Kali 就是 Debian，所以它的安装和运行与 Debian 镜像完全一样，其工具通过 `apt` 提供。它在这台设备上做不到的：

* **没有监听模式和报文注入。** Wi-Fi 芯片是 Unisoc SC2355，其 vendor 驱动只提供 station 和接入点模式。`airmon-ng` 没有可切换的对象，所以经典的 Wi-Fi 攻击无从谈起。
* **F50 上不能接外置 Wi-Fi 网卡**：它的 USB-C 口以 *gadget* 模式运行（设备伪装成你电脑的网卡），而且还是它的供电口。U30 Air 在主线内核上有 host 模式（`openf50-usb host`），且这些内核带有 MediaTek、Ralink 和 Realtek USB Wi-Fi 驱动；但此处尚未试过外接网卡。
* **没有屏幕。** 一切都通过 SSH 进行；Kali 的桌面工具在这台硬件上毫无意义。

剩下的仍然有用：一个口袋大小、自带 5G 调制解调器的盒子，可以通过移动连接或它接入的 Wi-Fi 运行 `nmap`、`sqlmap`、`metasploit`、代理和扫描器。

## 热门发行版调查（2026-09-18 实测）

两件事决定一个发行版能否在本设备的 5.4 内核上运行，且两者都能从它自己的二进制文件中读出：其 glibc 编译时要求的最低内核版本（ELF ABI note），以及它的用户空间是否已经在使用 5.4 没有的系统调用——`tar` 里的 `openat2`（5.6）就是 Ubuntu 26.04 上坑到我们的那个。

| 发行版（arm64） | glibc 要求 | `tar` 使用 `openat2` | 结论 |
|---|---|---|---|
| Ubuntu 22.04 / 24.04 LTS | 3.7 | 否 | ✅ 可用（24.04 是经过测试的默认系统） |
| Debian 12 / 13 / sid | 3.7 | 否 | ✅ 可用，已在此构建 |
| Kali rolling | 3.7 | 否 | ✅ 可用，已在此构建（见 Kali 一节） |
| Arch Linux ARM | — | 否 | ✅ 可用，已在此构建 |
| OpenWrt / ImmortalWrt 25.12 | musl | 否 | ✅ 可用，已在此构建 |
| Alpine 3.22 | musl | 否 | ✅ 用户空间没问题——但它是 OpenRC，服务需要移植 |
| Fedora 42 / 43 | 3.7 | 否 | ✅ 用户空间没问题，尚未构建 |
| Rocky 9、AlmaLinux 10、Oracle Linux 9 | 3.7 | 否 | ✅ 用户空间没问题，尚未构建 |
| Amazon Linux 2023 | 3.7 | n/a | ✅ 用户空间没问题，尚未构建 |
| Gentoo stage3 arm64 | 3.7 | 否 | ✅ 用户空间没问题；除非使用 systemd stage3，否则是 OpenRC |
| Void Linux | — | — | ✅ 有 rootfs tar 包；runit，所以服务需要移植 |
| Raspberry Pi OS arm64 | Debian | 否 | ✅ 底层是 Debian；从其镜像中取出 rootfs 即可 |
| openSUSE Tumbleweed | 4.3 | **是** | ⚠️ 只有替换 `tar` 后才能用（与 Ubuntu 26.04 相同的坑） |
| Ubuntu 26.04+ | 3.7 | **是** | ⚠️ 在 5.4 上同样如此；在 6.18 和 7.2 上正常，并已发布 |
| Arch（官方镜像）、Void（官方镜像）、Clear Linux | — | — | ❌ 没有 arm64 容器镜像（Arch：请用 Arch Linux ARM） |

此列表中没有 glibc 要求比 5.4 更新的内核，所以内核很少是阻碍；出问题的是个别程序调用了新系统调用，而这些程序可以逐个替换掉。

### 真正需要动手做的部分

OPENF50 服务——调制解调器启动、Android vendor chroot、Wi-Fi、LAN 网桥、热点、工具箱——以 **systemd 单元**（Ubuntu、Debian、Kali、Arch、Fedora 等使用）和面向 OpenWrt/ImmortalWrt 的 **procd init 脚本**两种形式存在。使用其他 init 的发行版（Alpine 的 OpenRC、Void 的 runit）能正常启动，但必须有人重新编写那约 15 个服务定义，调制解调器和 Wi-Fi 才能自动起来。

## 放不进来的

* **任何需要自带内核的东西**（Fedora IoT、postmarketOS 镜像、Home Assistant OS）：它们附带的是为其他设备构建的内核，而本设备只能从启动镜像引导本项目的内核（原厂 5.4、主线 6.18 和 7.2）。
* **在 5.4 上，用户空间要求更新内核的发行版**：Ubuntu 26.04 及以后，以及迟早所有的滚动发行版；这些请用 6.18 或 7.2。Arch 今天还能用；未来的某个 `glibc` 或 `systemd` 可能会终结它，这就是它是"玩票"选项而非默认的原因。
* **任何 x86 的东西。**

## 安装你自己构建的发行版

安装器认得 `ubuntu`、`openwrt` 和 `openwrt-luci` 这几个名字。除此之外的，把 tar 包解到它们旁边并选中它（在 Android 上操作，Linux 文件系统按 `tools/android-mount-openf50root.sh` 中的方式挂载）：

```sh
mkdir -p /data/local/tmp/openf50root/arch
tar -xzpf openf50-arch-rootfs.tar.gz -C /data/local/tmp/openf50root/arch
echo arch > /data/local/tmp/openf50root/.openf50/boot-os
```

在设备上已运行的 Linux 中，在 `/mnt/openf50-disk/` 下做同样的事，然后 `openf50-os arch` 并重启。如果它起不来，bootloader 会自己回退到 Android，`openf50-os ubuntu` 可以把旧系统带回来。
