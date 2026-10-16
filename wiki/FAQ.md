# FAQ

### 用大白话说，这是什么？
它在 ZTE F50 / OPENF50 或 ZTE U30 Air 5G 热点上、在 Android 之外装一套真正的 Linux 系统（Ubuntu 或
OpenWrt）。热点变成一台自带 5G 调制解调器的小型 Linux 电脑和路由器。见 [Home](Home)。

### 我会失去 Android 吗？
不会。Android 留在设备上。在常见的 64 GB 设备上，Android、其数据和分区表从不被修改。只有在 32 GB 变体
上你可以*选择*收缩 Android 的数据分区，那会清空 Android 的数据。见
[Going Back to Android](Going-Back-to-Android)。

### 支持哪些设备？
ZTE F50 / OPENF50 和 ZTE U30 Air（同一块板子，带电池）。U30 **Pro** 用另一款芯片（UMS9632），不受支持。

### 我需要 root 设备吗？
需要。设备在你开始前必须已经 root 并解锁（能启动修改过的 Android 启动镜像）。如何做到不属于本项目，
且风险自负。

### Windows 上能用吗？
能：Windows 10/11 上用 `install.ps1`（PowerShell）或 `install.cmd`（cmd.exe）。macOS 和 Linux 用
`install.sh`。每个系统都需要 `adb`。

### 不用电脑能安装吗？
能，只要设备上有 Magisk 26 或更新：从 Magisk 应用安装发布包里的 Magisk zip。见
[Installation](Installation#installing-from-android-with-a-magisk-zip-no-computer)。

### Ubuntu 还是 OpenWrt？
要通用 Linux 电脑选 Ubuntu，要精简路由器选 OpenWrt，要带调制解调器网页仪表盘的路由器选带控制面板的
OpenWrt。也可以两个都装。见 [Choosing a System](Choosing-a-System)。

### 哪个内核？
拿不准选 5.4（测试时间最长）；Ubuntu 26.04、U30 Air USB host 模式或 WireGuard 选 6.18 或 7.2。以后可以
换。见 [Kernels](Kernels)。

### 怎么连上它？
用 USB 插到电脑上，运行 `ssh ubuntu@192.168.77.1`（Ubuntu）或 `ssh root@192.168.77.1`（OpenWrt）。
U30 Air 上地址是 `192.168.78.1`。OpenWrt 在同一地址还有网页。或者加入它的 Wi-Fi 热点。

### 默认密码是什么？
没有默认密码：安装时你自己选（至少 6 个字符）。Magisk zip 会生成一个并显示出来。

### 5G 能用吗？
能：5G NSA 和 LTE，分享给 Wi-Fi 和 USB 客户端，调制解调器复位后自己重连。见
[Mobile Data and APN](Mobile-Data-and-APN)。

### 它能加入我家的 Wi-Fi 而不是用 SIM 卡吗？
能，用 `wifi-client`，只要网络是 WPA2 或 WPA2/WPA3 混合（不能是仅 WPA3）。期间热点关闭。见
[Wi-Fi Hotspot and Client](Wi-Fi-Hotspot-and-Client)。

### 它能为所有连上来的设备跑 VPN 吗？
能，用可选模块（WireGuard、OpenVPN、VLESS/VMess/Trojan/Shadowsocks、Clash/mihomo、Xray/sing-box
JSON），带断流开关。见 [VPN](VPN)。

### Ubuntu 上也有网页吗？
可选，v2026.10.20 起：`sudo openf50-extra install panel` 添加 Cockpit（Ubuntu 的网页控制台）加一个
OPENF50 页面，用于调制解调器、短信、VPN、电源、Wi-Fi 和更新，地址 `https://192.168.77.1:9090`，仅限
LAN。见 [Control Panel (LuCI)](Control-Panel-(LuCI)#a-web-panel-on-ubuntu-cockpit)。

### Linux 也能像 Android 一样用 `adb shell` 吗？
能。从 v2026.10.23 之后的发布包起，它默认开启且让所有电脑进入，带 root shell，这样网页安装器和其他
工具无需任何设置就能用。见 [Installation](Installation#adb-to-linux)。

### 那岂不是任何有 USB 线的人都能进我的设备？
默认情况下是的：adb 没有密码，所以谁把数据线插上设备谁就能得到 root shell，在你设置密码之后也一样。
仅限数据线：Wi-Fi 或移动网络都够不到任何东西。要关闭它，在设备上运行下面之一；两者在重启和更新后都
保持：

```sh
sudo openf50-usb adb auth keys    # only computers whose key you authorised (sudo openf50-usb adb key adbkey.pub)
sudo openf50-usb adb off          # no adb at all
```

在这个发布包之前你把 adb 关掉过、或配成密钥模式的设备，保持原样。

### 能打电话或放声音吗？
不能。板子没有扬声器和麦克风；通话音频仍在开发中，还传不出声音。

### 能接屏幕吗？
不能。USB-C 的 HDMI 不工作（USB-C 供电协商芯片从不应答）。这是一台无头机器。

### 有多少内存和存储？
约 1.4 GB 内存（2 GB 里其余大部分被调制解调器固件保留），64 GB 设备上约 32 GB 存储。F50 上 Linux 也
可以装在 SD 卡上。

### 能跑 Docker、虚拟机、其他发行版吗？
内核包含 KVM（`/dev/kvm`）和容器支持。Debian、Kali、Arch Linux ARM 和 ImmortalWrt 可以从本仓库构建；
见 [docs/DISTROS.md](https://github.com/dikeckaan/openf50-linux/blob/main/docs/DISTROS.md)。

### Linux 坏了会怎样？
连续若干次启动失败（默认 5 次，可在 1-6 之间选择）后，设备自己回到 Android。在 Android 里用
`su -c openf50-linux` 再次启动 Linux。

### 怎么更新？
`sudo openf50-update check`，然后 `sudo openf50-update apply`，然后重启。它绝不自行更新。从
v2026.10.20 起，你自己安装的软件包会在更新后回来。见 [Updating](Updating)。

### 怎么卸载？
回到 Android，运行 `./uninstall.sh`（或 `uninstall.ps1` / `uninstall.cmd`）。见
[Going Back to Android](Going-Back-to-Android#uninstalling)。

### 发布包里含 Android 或 ZTE 的文件吗？
不含。镜像不含任何专有文件；安装器从你自己的设备复制 Wi-Fi 固件和 Android 调制解调器及 GPU 用户态。

### 能用 OpenWrt 的 sysupgrade 吗？
**永远不要。** 它会覆盖设备的存储。用 `openf50-update`。

### 这安全吗？
它的设计是尽量少碰、并能回退到 Android，但它是无担保的实验性业余项目。断电或误操作仍可能让设备变砖。
先用 `tools/backup-device.sh` 备份。

### 去哪里求助？
先读 [Troubleshooting](Troubleshooting)，然后到 https://github.com/dikeckaan/openf50-linux/issues 开
issue，附上 `--check` 的输出或 `tools/collect-logs.sh` 的日志。永远不要发布你的 IMEI。
