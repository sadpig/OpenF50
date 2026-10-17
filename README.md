# OpenF50 — 在 ZTE F50 / MU300 与 U30 Air 上运行 Linux

> OpenF50 是 [mu300-linux](https://github.com/dikeckaan/mu300-linux) 的社区分支（sadpig 维护）：同样的硬件（ZTE F50 / MU300、U30 Air、V50），
> 系统品牌、命令与构建均改为 OpenF50，并默认集成 iStore 应用商店。硬件适配与底层实现归上游所有。

[![Latest Release](https://img.shields.io/github/v/release/dikeckaan/openf50-linux?logo=github)](https://github.com/dikeckaan/openf50-linux/releases/latest)
[![Total Downloads](https://img.shields.io/github/downloads/dikeckaan/openf50-linux/total?color=blue&logo=github)](https://github.com/dikeckaan/openf50-linux/releases)
[![Stars](https://img.shields.io/github/stars/dikeckaan/openf50-linux?logo=github)](https://github.com/dikeckaan/openf50-linux/stargazers)
[![Forks](https://img.shields.io/github/forks/dikeckaan/openf50-linux?logo=github)](https://github.com/dikeckaan/openf50-linux/network/members)
[![Issues](https://img.shields.io/github/issues/dikeckaan/openf50-linux?logo=github)](https://github.com/dikeckaan/openf50-linux/issues)
[![License](https://img.shields.io/badge/license-MIT%20%2F%20GPL--2.0-blue)](LICENSE)

新来的？[网站](https://github.com/sadpig/OpenF50) 配有图片逐步讲解（English、Türkçe、中文），[wiki](https://github.com/sadpig/OpenF50/wiki) 里有术语表和更深入的页面。

消息与新版本：关注本仓库的 GitHub releases，
第一时间了解更新。

ZTE F50 是一台口袋 5G 路由器。本项目把它变成一台小型 Linux 电脑：**Ubuntu**（24.04 或
26.04 LTS）或 **OpenWrt**（原版，或带调制解调器控制面板），SSH、Wi-Fi、蓝牙和它的 5G
调制解调器都能工作。Android 仍留在设备上，你随时可以切回去。

可以把它想象成一台内置了 5G 调制解调器、Wi-Fi 接入点和 32 GB 存储的树莓派。

**ZTE U30 Air** 同样受支持：相同的主板和芯片，但带电池。安装程序会自动识别它在和哪台
设备通信；见[支持的设备](#supported-devices)。

> **中文：** 把 ZTE F50 / MU300 变成一台小型 Linux 电脑：Ubuntu（24.04 或 26.04）或 OpenWrt
> （原版，或带调制解调器控制面板）；SSH、Wi-Fi、蓝牙和 5G 调制解调器均可工作。Android 保留在设备上，
> 随时可以切回。安装：先用 `./install.sh --check` 查看你的设备，再用 `./install.sh`
> 安装；用 `./uninstall.sh` 卸载。Linux 可以装到内部存储或 SD 卡上；也有无需电脑、通过
> Magisk zip 安装的方式。ZTE U30 Air 同样受支持（同一主板，带电池）；安装程序会自行识别设备。

---

## 业余爱好项目，风险自负

这是一个实验性的业余项目，由喜欢这些设备的人在业余时间制作。它不是产品，
没有支持渠道，也**不提供任何形式的担保**。这里的一切都按原样提供；在我们的板子上能运行的
版本，在你的板子上未必能运行。

你对自己的设备做什么，由你自己决定并负责。特别是：

* **获取 root、解锁和救砖不属于本项目的范围。** 给设备 root、用 Magisk、
  SPD/BROM 或任何其他第三方工具刷机，以及为此从其他任何来源下载的东西，都由你自行
  承担风险，并遵循那些工具自己的说明。它们不是我们写的，我们不做检查，也无法说明
  它们会对你的设备、数据或保修造成什么影响。
* **向手机级设备写入数据可能使其无法使用。** 安装程序尽量少动设备
  （见[开始之前](#before-you-start)），且 Linux 启动失败时设备会回退到 Android，
  但写错分区、在不巧的时刻断电、数据线故障或我们这边的失误，仍可能让设备变砖或清空
  数据。请做好备份；不要在你承担不起损失的设备上安装。
* **调制解调器、射频和网络由你依法使用。** 改变设备发出的内容（TTL、与 IMEI 相关的
  设置、频段锁、VPN）可能违反运营商条款或当地法律。开启某项功能前请先确认。
* **这里的一切均未获得 ZTE、Unisoc 或任何运营商的认可**，也不主张任何商标权利。

在法律允许的最大范围内，作者和贡献者不对因使用本软件、本文档或其中链接的任何内容而
产生的任何损害、数据丢失、服务中断、费用或伤害承担责任。如果你不能接受，
请不要安装。

> **中文：** 这是一个实验性的业余项目；不是产品，没有支持，也没有任何担保。设备的 root、
> 解锁以及使用 Magisk、SPD/BROM 等第三方工具进行的一切操作都不在本项目范围内，
> 完全由你自己负责。安装可能使设备无法使用或清空你的数据；请做好
> 备份，不要在你承担不起损失的设备上安装。作者和贡献者不对因使用本软件
> 可能产生的任何损害、数据或服务丢失负责。

---

## 支持的设备

| | ZTE F50 / MU300 | ZTE U30 Air |
|---|---|---|
| 主板、芯片 | `ums9620_2h10_feimao`，Unisoc T760 (UMS9620) | 相同 |
| 供电 | 仅 USB | 电池（4050 mAh）、充电器和电量计 |
| Linux 使用的 LED | 与 ZTE 固件一致：网络灯（蓝：4G，白：5G，红：无服务）、Wi-Fi 灯（热点开启时亮） | 与 ZTE 固件一致：电池灯（白：Linux 已启动）、网络灯（蓝：4G，白：5G，红：无服务）、Wi-Fi 灯（白：2.4 GHz，蓝：5 GHz） |
| 过热告警 | 网络灯依次闪红、白、蓝：SoC 达到 85 °C，直到冷却（`thermal-guard`） | 电池灯依次闪红、白、蓝：SoC 达到 85 °C 或电池达到 50 °C，直到冷却（`thermal-guard`） |
| USB 网络 | `192.168.77.1` | `192.168.78.1`（这样两台设备可以同时插在一台电脑上） |
| 已测试 | 以下全部 | 5.4、6.18 和 7.2：USB、Wi-Fi 热点、蓝牙、移动数据、VPN、LED |
| 电池 | - | 电量、电压、电流、温度和充电状态，可在 `openf50-toolkit`、`openwrt-luci` 面板和每个内核的 `/sys/class/power_supply` 中查看（主线内核：`sc27xx-fgu`）。充电：5.4 上由厂商充电栈负责；6.18 和 7.2 上由 `bq256xx` 驱动负责（自 v2026.10.12 起；v2026.10.11 及更早的主线内核不开启充电）。自 v2026.10.20 起：支持 0-100 % 的**充电上限**（`sudo openf50-power charge-limit 80`、电源设置中的 `CHARGE_TO`、面板上的 System > Power；充到上限即停，低于上限 5 个百分点时恢复，且电池永远不会被维持在 5 % 以下）；在主线内核上还会读取端口宣告的 **Type-C 电流**，因此 1.5 A 或 3 A 的端口最高可以 2 A 充电，而不是 500 mA |
| USB host (OTG) | -（其 USB 口即供电口） | 配合 OTG 转接头使用 `sudo openf50-usb host`：U 盘（FAT、exFAT）、键盘鼠标、USB 调制解调器和网卡，由电池提供 5 V；`sudo openf50-usb device` 切回电脑模式（每次开机的默认）。仅主线内核；经 USB-C 转接器的 HDMI 不可用 |
| SD 卡 | Linux 文件系统可以放在卡上而非内部存储（见[安装](#install)） | 无卡槽 |
| 按键 | 电源键：按住 3 秒关机 | 电源键：短按点亮 LED（60 秒后熄灭），按住 3 秒关机；Wi-Fi 键切换热点 2.4 / 5 GHz，按住 3 秒关闭或开启热点 |
| NFC | - | 手机贴近设备即可加入热点，与 ZTE 固件一致：`sudo openf50-nfc` 显示标签内容，`wifi` 写入热点的名称和密码（每次热点启动时都会重写），`url https://...` 或 `text ...` 写入任意其他内容，`clear` 清空，`on`/`off` 是 ZTE 网页界面的 NFC 开关（保存在标签中） |

两者运行相同的内核、相同的系统和相同的发布版本；差别仅在于 U30 Air
充电器和 LED 的少数几个驱动，其启动镜像会加载它们来替代 F50 的（[`kernel/u30air.fragment`](kernel/u30air.fragment)）。
设备相关的任何内容都无需手动选择：安装程序从 Android 读取设备信息，启动镜像、
LED 和默认地址随之确定。U30 **Pro** 是不同的芯片（UMS9632），不受支持。

### ZTE V50 (MU3351)：实验性支持

ZTE **V50**（`ro.product.model` V50，`ro.product.device` MU3351，平台 `ums9620`；不是 Blade V50 手机）
采用与 F50 相同的平台，但有两个 SIM 卡槽、NFC，以及由 AW9523B LED 控制器驱动的三颗前灯。kano（kanoqwq）
在他自己的分支中把本项目移植到了它上面；他的发现和测量结果见 [FINDINGS 95](docs/FINDINGS.md)。**本项目
没有人拥有 V50，也没有人测试过它**：只有在你能自行切回 Android 的前提下才安装。

| | ZTE V50 / MU3351 |
|---|---|
| 内核 | 仅主线：某个标明支持 V50 的发布版本的 6.18 或 7.2（其内核包在 `devices` 中列出 `v50`）；拒绝 5.4 |
| 能运行的 | F50 上能运行的都行：相同的系统、模块和设置，USB 供电（无电池） |
| LED | NET1 灯：蓝 4G、白 5G、红无服务；Wi-Fi 灯：白 5 GHz、蓝 2.4 GHz；NET2 不亮（`leds-aw9523b`，主线） |
| USB 网络 | `192.168.79.1`（既不是 F50 的也不是 U30 Air 的网段） |
| 尚未支持 | 第二张 SIM（仅 SIM 1）、NFC、SIM 选择；eMMC host 保持唤醒（kano 修复文件丢失问题的 patch 0017） |

安装程序会用一行话说明这一点，并拦下不完全符合的 V50（型号为 V50 但 device 或
平台不同的设备）。Linux 通过设备树识别主板，与之前另外两台设备一样：V50 的设备树中有
AW9523B，而任何 F50 或 U30 Air 都没有，因此即使旧版安装程序曾把它标为 `f50`，
`openf50-device` 也会报 `v50`（这样的安装在更新后会从 `192.168.77.1` 变为 `192.168.79.1`，
除非 `/etc/openf50/lan.conf` 或 OpenWrt 的 LAN 设置固定了地址）。

## 你将得到什么

* **一个真正的 Linux 系统**，不是 App 也不是容器：带 systemd 和 `apt` 的 Ubuntu 24.04 或 26.04 LTS、
  带 LuCI 网页界面的 OpenWrt，或带 OPENF50 控制面板的 OpenWrt（见下文）。
* **三个内核可选：** Unisoc 厂商内核 5.4、主线 6.18 LTS 和主线 7.2（v2026.10.20 中为
  6.18.56 和 7.2.10，带 BTF 和 [dae](https://github.com/daeuniverse/dae) 所需的 eBPF 钩子），
  三个内核都有 KVM（`/dev/kvm`）。
* **5G/LTE 上网**，与连接到设备的一切共享。
* **Wi-Fi 热点**（5 GHz 或 2.4 GHz）和 **USB 网络**：插到电脑上就会显示为一个网卡。
* **SSH 访问**：`192.168.77.1`（U30 Air：`192.168.78.1`），另有 USB 串口控制台。
* **蓝牙** 和 **Mali GPU**（OpenCL；无屏幕输出）。
* **`openf50-toolkit`**：类似 `raspi-config` 的菜单：温度、CPU 和内存占用、网速、性能
  模式、压力测试、VPN 和服务。
* **Android 保留。** 一条命令即可切回。

## 你会失去什么（剧透：什么都不失去）

这些设备上的 Android 本来就没有屏幕、没有扬声器，也没有 HDMI，所以 Linux 不会带走任何原本
拥有的东西。它带走的只是你"口袋里还没有一台 5G Linux 服务器"的最后借口。安装它不花你
一分钱；不试试，你才会失去这台服务器。

* **Android 保留。** 两者同一时间只运行一个，重启即可切换（`openf50-next-boot
  android`，或在 Android 中执行 `su -c openf50-linux`）。
* **硬件保持原样**，无论运行哪个系统：
  * 无屏幕输出：USB-C 的 HDMI 不可用（供电芯片从不应答），所以这是一台无头（headless）
    机器，通过 SSH 或网页界面使用；
  * 无扬声器和麦克风：经调制解调器音频 DSP 的语音通话仍在开发中，
    还没有声音（见[可用与不可用](#what-works-and-what-does-not)）；
  * 可用内存约 1.4 GB，因为其余大部分被调制解调器固件保留。

## 开始之前

你的设备必须已经 **root 并解锁**（必须已经能启动修改过的 Android boot 镜像），电脑上
需要有 `adb`。如何做到这一步不属于本项目的范围。

> **B16 用户：** `FLYMODEM_ZYV1.0.0B16` 可以不降级直接 root 并安装——见
> [docs/B16-ROOT.zh-CN.md](docs/B16-ROOT.zh-CN.md)（免降级补丁镜像 + 一键脚本；
> 更早的固件仍走已验证的 B09 路线）。

> **警告。** 安装会写入 `boot_b` 和 `misc` 分区（当 Android 运行在 slot b 时——OTA
> 更新后常如此——则写 `boot_a` 而非 `boot_b`）。如果出现严重问题，你可能需要
> 救砖工具（SPD/BROM）来恢复设备。在常见的 64 GB 设备上，Android、其数据和分区表
> 绝不会被修改。**32 GB 版本**是例外：它完全没有空闲空间，安装程序会提议通过
> 缩小 `userdata` 来腾出空间——那会重写分区表并清空 Android 中的一切，属于
> 实验性功能，且会先征求同意。走这条路之前请用 `tools/backup-device.sh` 做完整备份。
> 风险始终存在。这里的一切均未获得 ZTE 或 Unisoc 的认可。

**保护你的机制：**
* Linux 安装到内部存储中空闲未用的区域，或 SD 卡上；不触碰 Android 的分区（32 GB 版本除外，你可以选择缩小 `userdata` 来创造空间）。
* Linux 以"试启动（trial boot）"方式启动。如果连续 5 次启动失败（可选 1-6），
  设备会自行回到 Android。

* `./uninstall.sh` 会把一切恢复原样。

**你需要：**
* 一台 ZTE F50 / OPENF50 或 U30 Air，已 root，通过 USB 连接，并开启了 USB 调试。
* 一台装有 `adb` 的电脑：
  * **macOS 或 Linux：** 另需 Python 3、`lz4` 和 `curl`（通常已安装）。
  * **Windows 10/11：** PowerShell。缺少时，安装程序会自行安装 Python 3（为你的用户，用 winget 或从
    python.org）及其 `lz4` 模块。使用下面的 `install.ps1` / `uninstall.ps1`，
    或在 cmd.exe 中用 `install.cmd` / `uninstall.cmd`（无需更改执行策略）。
* 大约 15 分钟。

## 安装

**第 0 步——备份无法替代的东西（推荐）。**

```sh
tools/backup-device.sh          # macOS / Linux, device in rooted Android
```

它会把你这台设备独有的数据——`prodnv`、调制解调器校准和 IMEI 分区、bootloader 链——复制到
你的电脑上，并逐项与设备校验。安装过程绝不触碰这些数据，但一旦丢失，
任何固件下载都无法找回，调制解调器将永久损坏。请把备份文件夹放在安全的地方，
且不要放进任何代码仓库：里面有你的 IMEI。

**第 1 步——检查设备。** 这一步只读取，不写入任何内容。

```sh
./install.sh --check          # macOS / Linux
.\install.ps1 -Check          # Windows (PowerShell)
install.cmd -Check            # Windows (cmd)
```

它会报告存储容量、Android 分区的结束位置以及其后有多少空闲空间。64 GB
设备上约为 32 GiB。

如果它报告完全没有空闲空间，说明你的设备是 **32 GB 版本**，`userdata`
占满了整盘（64 GB 设备在刷入替换过分区表的厂商固件后也会呈现同样状况，issue #32）。
安装程序可以通过缩小 `userdata` 腾出空间——那会清空 Android 中的一切并重写
分区表，因此属于实验性功能，会先征求同意。同意之前请先用 `tools/backup-device.sh`
备份设备。如果数字看起来两种都不是，请停下，把 `--check` 的输出贴到 issue
中；这些数字能识别版本。如果卡槽里有 SD 卡，还有一种不清除任何数据的办法：
`--check` 会说明，安装程序也会提议改用 SD 卡。

**关于 SD 卡。** 卡槽中有一张至少 700 MiB 的卡时，安装程序会询问是否把 Linux 文件系统
装到卡上而不是 eMMC 的空闲区域（`OPENF50_STORAGE=sd` 可免提问直接回答）。卡会被格式化
（ext4，卷标 `openf50sd`）；eMMC 上只写 `boot_b`（或 `boot_a`）和 `misc` 的 32 字节，
所以 eMMC 较小的设备无需重新分区。存有其他 Linux（ext4）文件系统的卡绝不会被格式化。
`openf50sd` 卡总是优先。没有卡时，设备会启动内部安装（如果有）；两者都没有时，
它会等卡 8 秒（仍在检测中的话 30 秒），约五分钟后回到 Android。
三个内核都能读卡。U30 Air 没有卡槽，因此不会询问。


* 请在设备关机状态下插卡。Linux 运行中插入的卡能被识别，但要到
  下次重启才能读取。
* 启动镜像会启动任何文件系统卷标为 `openf50sd` 的卡。这保证了换卡后
  设备仍可启动，同时也意味着任何拿到设备的人都能从卡上启动自己的系统。

**第 2 步——安装。**

```sh
./install.sh                  # macOS / Linux
.\install.ps1                 # Windows (PowerShell)
install.cmd                   # Windows (cmd)
```

![安装程序：语言、检查、系统与 Ubuntu 版本](docs/images/installer/installer-1-start.png)

它会问几个问题（内部存储还是 SD 卡；装 Ubuntu、OpenWrt 还是两者都装，以及哪个 Ubuntu、哪个 OpenWrt 和
哪个内核；哪个系统启动；是否默认启动 Linux；密码；VPN 模块），下载预构建镜像，
从你设备里复制 Wi-Fi 和调制解调器文件，然后精确展示即将写入的内容，
并等待你输入 `INSTALL`。随后它会重启进入 Linux。

安装程序会说 **English、Türkçe 和 中文**：开始时询问（默认为 English；`OPENF50_LANG=tr`
或 `.\install.ps1 -Lang zh` 可跳过询问）。增加一种语言只需一个文件：见 `i18n/README.md`。在做任何其他事之前，它会先把你的项目副本
与 GitHub 同步——`git clone` 的仓库会被快进（fast-forward），下载的 zip 会获得有变化的文件——如有更新就重启自身；
无法访问 GitHub 时则直接继续（`OPENF50_NO_SELF_UPDATE=1` / `-NoSelfUpdate` 跳过）。

选 Ubuntu 时会询问版本：**24.04 LTS**（默认，测试时间最长）或 **26.04 LTS**——最新，
带 systemd 259，需内核 6.18 或 7.2。已安装的 Ubuntu 可以
用 `sudo OPENF50_UBUNTU=26.04 openf50-update apply`（或 `24.04`）切换到另一个版本，设置和数据保留。

它还会询问**内核**：

| 选项 | 内核 | |
|---|---|---|
| 1 | 5.4 | Unisoc 厂商内核（Android 12 底座）：测试时间最长，支持本项目的一切功能 |
| 2 | 6.18 | 主线 Linux，当前的长期支持（LTS）版本：更新的驱动和安全修复，功能相同（热点、移动数据、短信、蓝牙、VPN、GPU）；暂不支持 USB-C 视频输出 |
| 3 | 最新稳定版（目前是 7.2） | 最新的主线版本：最新的驱动，功能与 6.18 相同；测试不如 6.18 充分 |

之后可在设备上用 `sudo openf50-update kernel 5.4`、`... kernel 6.18` 或 `... kernel 7.2` 更换。
Ubuntu 26.04 需要 6.18 或 7.2（它的程序使用 5.4 没有的系统调用），U30 Air 的 USB host
模式也是。

![内核选择问题（土耳其语界面）](docs/images/installer/installer-2-kernel-tr.png)

写入任何内容之前，它会展示将要做什么并等待输入 `INSTALL`：

![安装前的摘要，以及安装结束](docs/images/installer/installer-3-summary.png)

**Linux 槽位的启动链（boot chain）。** Linux 用自己槽位的 bootloader 链启动，但运行的是 Android 的调制解调器。
Android 更新（OTA）之后，两个槽位的固件版本不同，而 Linux 槽位的链还是
出厂那套（issue #86）。因此安装程序会在两者不一致时把 Android 槽位的 `uboot`、`sml`、`teecfg`、`trustos`
和 `vbmeta` 复制到 Linux 槽位——且只复制这五个，绝不碰 NV、校准分区或
Android 槽位的任何其他东西。Linux 槽位原有的镜像会先备份到 Linux 文件系统（`.openf50/bootchain/`）和
电脑上的 `work/bootchain/`；每写入一个镜像都会回读校验，不一致就把旧镜像写回
并在 Linux 武装完成前停止。摘要会说明它将做什么（从未更新过的设备上显示
"boot chain: identical on both slots"）。专家可跳过：`OPENF50_SYNC_BOOTCHAIN=0 ./install.sh`、`.\install.ps1 -NoBootchainSync`。
详情：[FINDINGS 40](docs/FINDINGS.md)。感谢 kano 的建议。

如果已装有 Linux，它会询问是 **update（更新）** 还是 **wipe（清空重装）**：

* **update**——重装系统但保留你的设置和数据：`/etc/openf50`（热点、VPN、工具箱）、
  用户账号和家目录、`/usr/local`、SSH host keys、OpenWrt 的 UCI 配置，以及你自己启用
  的服务。你自己安装的软件包会在首次开机时重新安装（见[更新](#updating)）。
* **wipe**——清空 Linux 文件系统，从头安装。

如果开始时设备运行的是 Linux 而不是 Android，安装程序会察觉，并提议
通过 SSH 帮你把它重启进 Android。

**第 3 步——登录。** 等约一分钟，然后在它所插的电脑上：

```sh
ssh ubuntu@192.168.77.1        # the password you chose during the install
```

OpenWrt 用 `ssh root@192.168.77.1`，或在浏览器打开 `http://192.168.77.1` 进入 LuCI。
U30 Air 的地址是 `192.168.78.1`。

设备广播的 Wi-Fi 网络就是它的热点；除非你另做选择，
否则使用从 Android 复制的名称和密码。

### 带 OPENF50 控制面板的 OpenWrt

第三个系统 `openwrt-luci` 是 OpenWrt 25.12 加上为这类设备编写的 LuCI 应用，
界面有英文、土耳其语和中文（安装语言扩展另有 29 种，见[语言](#languages)）。它是与原版 OpenWrt 并列的选项，不是替代品：每当选择 OpenWrt 时
安装程序都会问"Which OpenWrt?"（`OPENF50_OPENWRT=plain|luci` 可免提问），系统存放在
Linux 磁盘的 `/openwrt-luci`。其发布文件是 `openf50-openwrt-luci-rootfs.tar.gz`；
用 `sudo openf50-os openwrt-luci` 切换过去。面板的页面：

* **状态仪表盘：** 实时射频读数（信号、频段、小区、温度）、移动数据状态、Wi-Fi 客户端
  及其速率、连接时长、名称和地址、运营商 DNS 服务器和连接数；U30 Air 上
  还有电池：电量、是否在充电、功率（瓦）。调制解调器忙时页面保留
  上次读数并显示其距今时间，而不是一片空白。
* **Cellular > Network locks（网络锁）：** 网络模式、频段、小区和 EN-DC 锁定，重启后保持，
  并在开机时、射频启动前（调制解调器允许的情况下）重放。
* **Cellular > SMS（短信）：** 读取、发送和删除短信。一个轮询守护进程每 30 秒用 `AT+CMGL`
  同步一次 SIM 卡，这会把 SIM 卡上的未读短信标记为已读（实测，FINDINGS 35；面板自己维护
  未读状态）。不要在这个系统上运行 `sms delete read`。一条短信只有在轮询副本
  落盘后才从 SIM 卡删除（对那个文件及其目录做 fsync，绝不做全局 sync）。
  其余部分一直未到齐的长短信，会在一小时后按已收到的部分显示，并标记为不完整。
* **Cellular > SMS forwarding（短信转发）：** 默认关闭，手动开启。收到的短信可继续发往
  webhook（JSON、表单或纯文本，可加额外请求头；标准字段或自定义正文，可用 `{sender}`、`{time}`、
  `{text}`、`{device}`、`{message}`，每个值按类型转义）、Telegram 聊天、电子邮箱
  （仅当镜像带 `msmtp` 时）和/或通过短信转发到另一部手机（模板：`{sender}`、`{time}`、
  `{text}`、`{device}`），支持发件人允许/拒绝名单和关键词。发送失败
  会重试（30 秒起，倍增，最长一小时，共十次）；有发送日志（带"Clear"按钮）和"Send test"
  按钮。对那些以 HTTP 200 包装自身错误的服务，webhook 可以校验应答
  （`errcode=0`、`code=0`、`ok=true`）：设备只保留结果，绝不保留应答内容。令牌、密码
  以及 webhook 地址和请求头保存在 `/etc/openf50/sms-forward.conf`（仅 root 可读），且不再显示。
* **Cellular > AT terminal（AT 终端）：** 经系统守护进程使用的同一通道发送受防护的 AT 命令。
  扫描类、会改变射频、APN、SIM 或会带入 Android 的持久设置的命令，会先解释再经点击确认后
  发送；网络扫描在后台运行，页面实时跟随。Device 页面保存面板近期
  调制解调器操作的日志（只有名称和耗时，绝不含数值或短信内容）。
* **VPN**（独立的顶级菜单，基于 [VPN 模块](#vpn) v2）：**Overview**（状态、活动配置、引擎、隧道
  地址、运行时长、实时速率、按钮查看出口 IP、Start/Stop/Restart、kill switch（防泄漏开关）和需确认的 IPv6
  设置）、**Profiles**（从分享链接、粘贴文本、文件或 URL 添加；测延迟；重命名、
  查看和编辑配置、删除）、**Subscriptions**（产出配置的 URL，可手动或定时刷新）、
  **Engines**（Xray、sing-box、mihomo、dae：安装、更新或移除，在线或从上传的 tar 包安装并与
  模块发布校验）、**Settings**（kill switch、IPv6、绕过隧道的 LAN 网段、Tailscale、DNS）
  和 **Logs**。未装模块时每个页面都会提供安装入口。
* **Cellular > Device management（设备管理）：** USB 角色（device 或 host）、USB 网络模式（NCM、ECM 或 RNDIS，
  下次开机生效），以及 host 模式下可加入 LAN 网桥的适配器。
* **Cellular > Adapter settings（适配器设置）：** 面板如何连接调制解调器（AT 后端、串口、自定义 AT 适配器）。
* **System > Languages（语言）：** 界面语言，以及语言扩展：下载它，或上传文件。
* **System > Power（电源）：** 当前电源模式及原因（以页面语言显示）、电池、电源来源和充电器输入电流、三种模式的空闲参数（Wi-Fi 空闲分钟数、射频空闲 keep/lte/off、LED、CPU）、节电阈值和充电上限（0-100 %，U30 Air；也可用 `openf50-power charge-limit N`）。
* **System > Packages after an update（更新后的软件包）：** 你自己安装过的软件包以及更新对它们的处理
  （见[更新](#updating)）：哪些已装回、哪些待处理或失败及原因、被搁置的设置，以及
  Try again、Repair DNS（需确认）和 Dismiss 按钮。
* **System > Terminal（终端）：** 浏览器中的 root shell（[ttyd](https://github.com/tsl0922/ttyd)）。
  它只监听 LAN 地址（端口 7681；蜂窝侧永远到不了），且只为页面为已登录面板会话获取的
  一次性令牌打开 shell：没有第二个可猜的密码。15 分钟无活动即关闭
  （`uci set ttyd.openf50.idle=<秒数>`，0 为永不）。经 https 打开的面板会在独立标签页中打开它
  （ttyd 提供的是 HTTP：其 TLS 上的 websocket 在 Chrome 中会失败）。**Terminal settings**
  是 ttyd 自己的页面；关闭该实例（`enable`）即移除终端。

这个系统上的 IPv6 是从运营商中继的（路由器通告和 NAT66），而不是原版
OpenWrt 使用的前缀扩展。Aurora 是默认主题，Bootstrap 仍然保留。在一台 F50
和一台 U30 Air 上实测的启动耗时见 [FINDINGS 35](docs/FINDINGS.md)。

自 v2026.10.20 起，一条卡住的 AT 命令不再拖垮整个面板：每次调制解调器读取都有超时 deadline，
各页面逐条发送请求、失败后退避，调制解调器忙时锁定状态读数由缓存提供。
在 OpenWrt 上，一条 AT 命令现在约需 0.13 秒而不是整整一秒（shell 的 `read` 无法
等待不足一秒的时间），因此仪表盘的读数快了 7 倍（[FINDINGS 40](docs/FINDINGS.md)）。


该面板是 kanoqwq 的作品（[`kanoqwq/openf50-linux`](https://github.com/kanoqwq/openf50-linux)，分支
`clean-tf-7.2`）；本仓库将其移植过来，翻译改写为标准 LuCI 目录，共享
修复应用到全部三个系统。主题是 eamonxg 的
[Aurora](https://github.com/eamonxg/luci-theme-aurora)。应用自己的说明见 [`openwrt/luci-app-openf50/README.md`](openwrt/luci-app-openf50/README.md)。

### Ubuntu 上的网页面板（可选）

Ubuntu 也可以有网页面板：[Cockpit](https://cockpit-project.org/)——Ubuntu 自己的网页控制台（终端、
日志、服务、网络、存储、账户），其中带一个 **MU300** 页面：移动网络（运营商、
制式、注册状态、RSRP/RSRQ）、移动数据开关、流量用量和实时速率、电池和温度、
短信（读、发、删）、VPN（开关、配置；需 VPN 模块）、CPU 模式和电源状态、
热点名称和密码、加入 Wi-Fi 网络，以及更新（`openf50-update check` / `apply`）。网络锁
仍是 OpenWrt 面板独有的功能。它是面板扩展（panel extra），不在镜像中：

```sh
sudo openf50-extra install panel                      # Cockpit from Ubuntu's archive (about 12 MB, online)
sudo openf50-extra install panel --from openf50-extra-panel-offline.tar.gz   # offline: the release's file, Cockpit inside
sudo openf50-extra remove panel
```

或者在安装程序的提问中回答 yes（它使用离线文件，因此首次开机无需联网）。然后打开
`https://192.168.77.1:9090`（U30 Air：`.78.1`；如果你改过则用你的 LAN 地址），接受 Cockpit
的自签证书，以 `ubuntu` 用户和你的密码登录；需要 root 的页面要点
"Turn on administrative access"（再次输入你的密码）。Cockpit 只监听 LAN 网桥（USB 和热点：
`BindToDevice=br-lan`），而且防火墙本来就丢弃来自蜂窝上行（以及 Wi-Fi 上行）的所有新连接；
root 无法登录，登录页不提供其他主机，会话空闲 15 分钟后结束。更新会换掉 Ubuntu 而没有
Cockpit 的软件包：首次开机会在后台把它们装回（扩展里带着就从扩展装，否则联网后
从软件仓库装）。`openf50-panel status` 可查看其状态。

## 日常使用

`sudo openf50-toolkit` 打开的菜单涵盖下面所有功能。直接命令：

| 我想…… | 命令 |
|---|---|
| 查看温度、CPU、内存、网速 | `openf50-toolkit top` |
| 让它更快，或更凉更安静 | `sudo openf50-toolkit profile performance`（还有 `eco`、`balanced`） |
| 负载下测试稳定性 | `sudo openf50-toolkit stress all 10` |
| 检查移动连接 | `sudo mobile-data status` |
| 设置 APN | Ubuntu：`/etc/openf50/mobile-data.conf`（`OPENF50_APN`、`OPENF50_PDP_TYPE`）。OpenWrt：LuCI → Network → Interfaces → wan，或 `uci set network.wan.apn='…'; uci commit network; ifup wan`。留空则使用 SIM 卡定义的上下文，这是大多数运营商所期望的 |
| 使用 F50 的内置 SIM 而非卡槽中的卡 | `sudo openf50-sim select internal`（`external` 切回；下次开机生效，默认是外置卡，不会向调制解调器或 SIM 写入任何内容）。OpenWrt：LuCI → Network → Interfaces → wan → SIM source，用该卡自己的 APN；Ubuntu：APN 在 `/etc/openf50/mobile-data.conf` 中。仅 F50，且设备必须装有内置 SIM（docs/SIM-SELECTION.md） |
| 修改 Wi-Fi 名称或密码 | Ubuntu：编辑 `/etc/openf50/hotspot.conf`，然后 `sudo systemctl restart openf50-hotspot`。OpenWrt：LuCI → Network → Wireless（那个文件只在首次开机时读取一次） |
| 修改热点信道 | Ubuntu：`/etc/openf50/hotspot.conf` 中的 `CHANNEL=`（`auto`，或 5 GHz 的 36-48 / 149-165）。OpenWrt：LuCI → Network → Wireless。绝不要用 DFS 信道（52-144）：Wi-Fi 驱动无法检测雷达，hostapd 无法在那里启动；DFS 信道会被替换为 36（36-48 不可用时用 149），日志会说明原因（FINDINGS 42） |
| 收发短信 | `sudo sms list`、`sudo sms send NUMBER TEXT...`、`sudo sms delete INDEX`（序号、`read` 或 `all`；其他值在到达调制解调器前就会被拒绝）（带面板的 OpenWrt：Cellular → SMS；带面板扩展的 Ubuntu：OPENF50 页面） |
| 发送 USSD 代码（查余额、本机号码） | `sudo openf50-ussd '*101#'` |
| 更换内核 | `sudo openf50-update kernel 6.18`（或 `5.4`、`7.2`），然后重启 |
| 让设备加入别人的 Wi-Fi | `sudo openf50-toolkit` → Network → Wi-Fi → "Join a network"，或先 `sudo wifi-client scan` 再 `sudo wifi-client connect "名称"`（会询问密码）；见 [Wi-Fi 客户端](#wi-fi-client) |
| 更新到最新版本 | `sudo openf50-update check` 然后 `sudo openf50-update apply`。设备会在开机时和每 6 小时检查新版本，并在登录时和 `openf50-toolkit` 中提示；它绝不自行安装 |
| 移动数据固定 TTL（让运营商无法区分热点流量和设备自身流量） | `sudo openf50-ttl set 64`（`sudo openf50-ttl off` 恢复默认），`openf50-toolkit` -> Network -> TTL，或 LuCI Cellular -> TTL。主线内核上规则在 tc 中，flow offloading 保持开启；5.4 上在 nftables 中，设置 TTL 期间 offloading 关闭 |
| 在 OpenWrt 和 Ubuntu 之间切换 | `sudo openf50-os openwrt` / `sudo openf50-os ubuntu`（带控制面板的是 `openwrt-luci`） |
| 连续失败多少次启动后回退 Android（1-6，默认 5） | `sudo openf50-next-boot attempts N` |
| 永久保留 Linux：绝不自行回到 Android，只能手动 | `sudo openf50-next-boot lock`（或面板首页的"Lock Linux"）；`unlock` 恢复按次数回退。见[锁定 Linux](#locked-linux) |
| 回到 Android | `sudo openf50-next-boot android`，然后 `sudo reboot` |
| 从 Android 回到 Linux | 在设备上 `su -c openf50-linux`（见下文），或从电脑执行 `boot/android-boot-linux.sh work/boot-linux-slotb.img` |
| 让所有流量走 VPN | 见下文（先 `sudo openf50-extra install vpn`） |
| 增删可选部件（VPN 模块、更多网页界面语言） | `openf50-extra list`、`sudo openf50-extra install vpn`、`sudo openf50-extra remove vpn`（语言用 `lang`） |
| 省电：电源模式、无人连接时射频休眠、充电上限 | `openf50-power status`、`sudo openf50-power profile battery`（`plugged`、`saver`、`auto`）、`sudo openf50-power set battery.WIFI_IDLE 10`、`openf50-power log 5 /tmp/power.csv`；在 `openwrt-luci` 上是 System -> Power 页面。由充电器触发开机的设备会保持充电启动状态（LED 闪烁，热点和调制解调器关闭），直到按下 Wi-Fi 键；见 FINDINGS 36 |
| 网页界面语言（OpenWrt） | System -> System -> Language and Style；更多语言：见下文"语言"一节 |
| 弄清每颗 LED 的用途 | `sudo openf50-led test` |
| 像 Android 一样从电脑 `adb shell`、`adb push`/`pull`、`adb forward` 到 Linux | 默认开启，对所有电脑开放（任何有数据线的人都能获得无密码 root shell）；只允许自己的电脑：`sudo openf50-usb adb key adbkey.pub`，然后 `sudo openf50-usb adb auth keys`；完全关闭：`sudo openf50-usb adb off`；见 [adb 连接 Linux](#adb-to-linux) |

### adb 连接 Linux

和 Android 一样，Linux 在 USB 线上提供 adb，与 USB 网络和串口控制台并列：
`adb shell`（root 登录 shell）、`adb push`/`pull`、`adb forward`/`reverse`。从 v2026.10.23
之后的版本起，它**默认开启且允许所有电脑接入**，这样浏览器（网页安装器，
经 WebUSB）或图形工具无需先放置密钥即可与设备通信。

> **这意味着什么。** adb 没有密码。默认状态下，**任何能把 USB 线插到设备上的人
> 都能得到 root shell**——即使你已为 `ubuntu` 或 `root` 设了密码——并能读写设备上
> 的一切。Wi-Fi、LAN 或移动数据网络都到不了它：adb 只在线上。如果设备可能离开
> 你的掌控，用以下方式之一关掉它：

```sh
sudo openf50-usb adb auth keys           # only computers whose key you authorised get in (others: "unauthorized")
sudo openf50-usb adb off                 # no adb at all
```

两者在重启和更新后都保持。其余命令：

```sh
openf50-usb adb status                   # on or off, whom it lets in, the number of authorised keys
# a computer's key, for "auth keys": the one adb made for itself (adb keygen makes one where there is none)
scp ~/.android/adbkey.pub ubuntu@192.168.77.1:      # root@ on OpenWrt; 192.168.78.1 on a U30 Air
sudo openf50-usb adb key ~/adbkey.pub    # authorise it (/etc/openf50/adb_keys)
sudo openf50-usb adb keys                # the authorised keys; delete a line of /etc/openf50/adb_keys to take one back
sudo openf50-usb adb auth open           # every computer again
sudo openf50-usb adb on                  # after "off"; the USB connection drops for a moment and comes back with adb
```

* **之前配置好的设备**保持原状：`adb off` 保持关闭；在 v2026.10.20-23 期间
  （那时 adb 只收密钥）开启过 adb 或授权过密钥的设备保持仅密钥模式，直到
  `sudo openf50-usb adb auth open`。其他设备在 `openf50-update apply` 之后 adb 开启且开放。
* 安装程序（`install.sh`、`install.ps1`）会询问是否从首次开机起
  只允许安装程序所在的电脑接入；Magisk zip 没有这个问题，其系统默认开放。
* 设备在 `adb devices` 中显示为 `OPENF50LINUX-...`；Android 中的设备是另一个序列号，
  安装程序能区分两者（处于 Linux 的设备会先被送回 Android，adb 允许的话经 adb 操作）。
  密钥模式下，密钥未授权的电脑会看到 `unauthorized`，什么也得不到：设备上不会弹出
  接受密钥的提示。
* 两种模式都没有 TCP 端口（adb over Wi-Fi 和 `adb tcpip` 都未编进守护进程）。
* 没有 adb 的情况：v2026.10.20 之前的主线内核（无 FunctionFS；`openf50-update kernel` 可换一个）、
  不含 adbd 的镜像，以及 U30 Air 的端口处于 USB host 模式时（`openf50-usb host`）。`openf50-usb adb status`
  会说明是哪种。
* 与 Android 一样，adb 接口会向 Windows 请求 WinUSB 驱动（MS OS descriptors；尚未在 Windows 上
  试过——没有它时可用 Google 的 USB 驱动）。

需要通过 adb 与设备通信的程序：[docs/ADB-INTERFACE.md](docs/ADB-INTERFACE.md)。守护进程是 AOSP 的
adbd（platform-tools 34.0.5），由 `tools/adbd/build.sh` 为两个系统静态构建；见 FINDINGS 43 和 70。


### 用 Magisk zip 从 Android 安装

如果设备已经在运行带 Magisk 26 或更新版本的已 root Android，可以不用电脑、
直接从设备本身安装 Linux：从 Magisk app（通过 scrcpy、网页面板或一部运行 adb 的手机访问）
或从 `adb shell`。这些 zip 由 "Magisk installers" 工作流
（`.github/workflows/magisk.yml`）从发布版本的文件构建，并与 `SHA256SUMS-magisk` 一起附加到该
发布。发布时它自动运行，所以 zip 会在几分钟后跟上其他资产。自行构建：
`tools/make-magisk-zips.sh RELEASE_DIR OUT_DIR`。

**1. 取一个 zip。** 每个系统与内核组合一个，共 11 个。同一个 zip 在 F50 和 U30 Air 上都可用，
可装到内部存储或 SD 卡：安装程序会识别设备并找到位置。

| zip | 系统 | 内核 | 大小 |
|---|---|---|---|
| `openf50-magisk-<tag>-openwrt-k5.4.zip` | OpenWrt | 5.4 (vendor) | 48.5 MB |
| `openf50-magisk-<tag>-openwrt-k6.18.zip` | OpenWrt | 6.18 LTS | 37.2 MB |
| `openf50-magisk-<tag>-openwrt-k7.2.zip` | OpenWrt | 7.2 | 37.9 MB |
| `openf50-magisk-<tag>-openwrt-luci-k5.4.zip` | 带控制面板的 OpenWrt | 5.4 (vendor) | 48.8 MB |
| `openf50-magisk-<tag>-openwrt-luci-k6.18.zip` | 带控制面板的 OpenWrt | 6.18 LTS | 37.6 MB |
| `openf50-magisk-<tag>-openwrt-luci-k7.2.zip` | 带控制面板的 OpenWrt | 7.2 | 38.3 MB |
| `openf50-magisk-<tag>-ubuntu-24.04-k5.4.zip` | Ubuntu 24.04 | 5.4 | 124.1 MB |
| `openf50-magisk-<tag>-ubuntu-24.04-k6.18.zip` | Ubuntu 24.04 | 6.18 LTS | 112.9 MB |
| `openf50-magisk-<tag>-ubuntu-24.04-k7.2.zip` | Ubuntu 24.04 | 7.2 | 113.6 MB |
| `openf50-magisk-<tag>-ubuntu-26.04-k6.18.zip` | Ubuntu 26.04 | 6.18 LTS | 125.2 MB |
| `openf50-magisk-<tag>-ubuntu-26.04-k7.2.zip` | Ubuntu 26.04 | 7.2 | 125.9 MB |

大小为 v2026.10.18 构建的数值。zip 中不含 VPN：在设备上用
`sudo openf50-extra install vpn` 添加其模块（见 [VPN](#vpn)）。没有内核 5.4 的 Ubuntu 26.04 zip：
它的程序需要该内核没有的系统调用，与 `install.sh` 的规则相同。用 `SHA256SUMS-magisk` 校验下载。

**2. 安装它。** 把 zip 放到设备上，在 Magisk app 中打开（Modules，Install from storage），或运行
`su -c 'magisk --install-module /sdcard/Download/<zip>'`。不要从 recovery 安装。

**3. 阅读输出。** 它会显示识别到的设备、Linux 的去向、将要写入的内容，以及哪个密码可用：
镜像自带的密码——如同电脑安装时不自设密码——Ubuntu 的用户 `ubuntu` 密码是
`ubuntu`，OpenWrt 的 `root` 在你设置之前没有密码（`passwd`，或 LuCI 的 System > Administration）。
同样的说明在 `/data/adb/openf50-linux-password.txt`（`su -c cat /data/adb/openf50-linux-password.txt`）。
覆盖已有系统安装 zip（即更新）会保留其账号和密码，并显示"unchanged"。

**4. 重启。** Linux 启动。如果没有，设备会自行回到 Android。

**两个系统：两个 zip。** 先后安装 OpenWrt zip 和 Ubuntu zip，顺序不限。
第二个把自己的系统加到第一个旁边，并成为启动的那个；`openf50-os openwrt` 和
`openf50-os ubuntu` 可切换。Ubuntu 26.04 需要内核 6.18 或 7.2，所以装了它之后，
内核 5.4 的 zip 会拒绝安装。

安装成功后，zip 会保留为 Magisk 模块 "OPENF50 Linux"（即
[android/magisk/README.md](android/magisk/README.md) 中的切换模块，id 相同）：以后可用它的 Action
按钮和 `su -c openf50-linux` 从 Android 启动 Linux。

**写入了什么。** Linux 去到自己的位置：内部分区之后的空闲区域，或一张
SD 卡（已存有本项目 Linux 安装的卡优先使用，与设备开机时的行为一致）。除此之外：

* Android **不在**的那个槽位的 boot 分区（Android 在 slot a 时是 `boot_b`，
  在 slot b 时是 `boot_a`），写入后校验；
* Linux 槽位的 bootloader 链（`uboot`、`sml`、`teecfg`、`trustos`、`vbmeta`），
  仅在与 Android 槽位不一致时写入，先备份到 Linux 文件系统的 `.openf50/bootchain/`，
  写入后校验（`OPENF50_SYNC_BOOTCHAIN=0` 保持原样；见[安装](#install)）；
* `misc` 的 32 字节，最后写入，且仅在之前全部成功时。

Android 自己的 boot 分区、每个分区的 Android 槽位、分区表和 `userdata` 绝不写入。
如果安装在最后一步之前停止，`misc` 保持原样，Android 正常启动。如果最后一步之后 `misc`
本身回读不正确，安装程序会写回它之前保存的块，并告知是否成功。

**回到 Android。** 在 Linux 中：`sudo openf50-next-boot android`，然后 `sudo reboot`。
什么都不做的话，设备在连续 5 次启动失败后（1-6 可选，见下文 `OPENF50_BOOT_ATTEMPTS`，
之后可用 `openf50-next-boot attempts N` 修改）以及 Linux 完全起不来时会回退到 Android——
除非 Linux 被锁定（见下文）。

<a id="locked-linux"></a>**锁定 Linux。** `sudo openf50-next-boot lock`（或面板首页的"Lock Linux"）让
Linux 无论如何都保留：设备绝不自行回到 Android，启动失败后不会，系统
完全起不来时也不会（此时它在 USB 上等待，在设备地址提供 telnet shell，
执行 `sh /run/to-android` 可去 Android）。此后只能手动回 Android：
`openf50-next-boot android`，或面板上的"Switch to Android"。唯一例外是新内核：
`openf50-update` 会让新启动镜像先按常规次数试启动，所以起不来的内核仍会回退，
第一次成功启动后再次锁定。`sudo openf50-next-boot unlock` 恢复。下面忘记密码的出路
（启动中途拔线）在 Linux 锁定时无效。

**这里不提供。** 缩小 `userdata` 腾空间（32 GB 版本）会重写分区表并清空
Android 的数据。该功能只保留在电脑安装程序（`./install.sh`、`.\install.ps1`）中，
那里有备份步骤和手动输入 `ERASE` 在前。内部空间不足时，安装程序会说明，
并列出这台设备的选项：SD 卡、更大的卡，或电脑安装程序。

#### 自定义选择：`openf50-install.conf`

Magisk 的安装界面无法提问，所以安装程序根据设备上的情况自行决定，只有
设置文件能改变这一点。文件由 `KEY=VALUE` 行组成（`#` 为注释，引号可选）。它只被读取，
绝不执行；不在表中的键会被报告并忽略，值不在列出范围会在写入任何内容前停止
安装。每次运行都会写出 `/sdcard/openf50-install.conf.example`，包含每个键、其含义
（在它上方的注释行）和本次运行所用的值；把它复制为 `openf50-install.conf`，删掉
你想要的键前面的 `#`，再装一次 zip。`OPENF50_DRY_RUN=1` 只打印计划、不写入任何内容；
此时 zip 也不会作为模块安装。

这个文件有两个位置，因为任何有存储权限的 app 都能写 `/sdcard`：

* `/sdcard/openf50-install.conf`（或 `/sdcard/Download/openf50-install.conf`）只能选择不破坏任何东西、
  不泄露任何东西的项。
* `/data/adb/openf50-install.conf` 对所有项生效。那里只有 root 能创建文件，且安装程序
  只在它属 root 所有、组和其他人都不可写时才使用它。zip 的 `openf50/` 文件夹里的
  `openf50-install.conf` 同等有效（它与旁边的脚本同等可信）。

在 `/sdcard` 文件中发现第二类键时会被报告并忽略，安装程序会打印
把该文件变成仅 root 可改的命令：

```sh
su -c 'cp /sdcard/openf50-install.conf /data/adb/openf50-install.conf && chmod 600 /data/adb/openf50-install.conf'
```

两个文件都给出同一个键时，以 `/data/adb` 的为准，安装程序打印的计划会注明每个值
来自哪个文件。擦除许可仅在其对应的存储选择也来自 `/data/adb` 时生效：
擦除 SD 卡需要那里同时有 `OPENF50_STORAGE=sd` 和 `OPENF50_SD_ERASE=yes`（或者卡上已有
`openf50sd` 且未设置 `OPENF50_STORAGE`）；覆盖内部空间需要那里有
`OPENF50_REGION_OVERWRITE=yes` 且 `OPENF50_STORAGE=internal`，或未设置 `OPENF50_STORAGE`。

擦除类设置只对一次安装生效：一旦一次成功的安装使用了 `/data/adb/openf50-install.conf`
中的 `OPENF50_MODE=wipe`、`OPENF50_SD_ERASE=yes` 或 `OPENF50_REGION_OVERWRITE=yes`，安装程序会把那一行
变成注释（对 `OPENF50_PASSWORD` 和 `OPENF50_PASSWORD_RESET` 也一样）并说明。否则下一个 zip——
两个中的第二个，或一次更新——会再次清空或擦除。如需再次擦除，把那一行放回去。

| 键 | 值 | 来源 | 默认值 |
|---|---|---|---|
| `OPENF50_STORAGE` | `internal`、`sd` | 两者皆可 | 已有安装所在的位置（卡优先）；否则空闲区域够大时为内部存储；否则拒绝安装并说明原因 |
| `OPENF50_SD_ERASE` | `yes` | 仅 `/data/adb` | 未设置：SD 卡绝不会被格式化，新卡不会，存有安装且带 `OPENF50_MODE=wipe` 的卡也不会 |
| `OPENF50_REGION_OVERWRITE` | `yes` | 仅 `/data/adb` | 未设置：空闲区域中存有数据的内部区域不会被使用 |
| `OPENF50_MODE` | `update`、`wipe` | `update` 两者皆可，`wipe` 仅 `/data/adb` | 已有文件系统时为 `update`（保留设置和数据） |
| `OPENF50_BOOT_OS` | `ubuntu`、`openwrt`、`openwrt-luci` | 两者皆可 | 本 zip 的系统 |

| `OPENF50_BOOT` | `linux`、`android` | 两者皆可 | `linux`：默认启动 Linux，启动失败后回 Android。`android`：Android 保持默认，Linux 按需启动 |
| `OPENF50_BOOT_ATTEMPTS` | `1` 到 `6` | 两者皆可 | `5` |
| `OPENF50_HOTSPOT` | `yes`、`no` | 两者皆可 | `yes`：复制 Android 的热点名称和密码 |
| `OPENF50_GPU` | `yes`、`no` | 两者皆可 | `yes`（本设备缺少 GPU 文件组中的某个文件时跳过并提示） |
| `OPENF50_PASSWORD` | 6 个或更多字符 | 仅 `/data/adb` | 新系统用镜像自带密码：Ubuntu 的 `ubuntu`/`ubuntu`，OpenWrt 的 `root` 无密码。更新保留现有密码 |
| `OPENF50_PASSWORD_RESET` | `yes` | 仅 `/data/adb` | 未设置：更新保留现有密码。`yes`：恢复镜像自带密码 |
| `OPENF50_PASSWORD_FILE` | `sdcard` | 仅 `/data/adb` | 未设置：密码说明为 `/data/adb/openf50-linux-password.txt` |
| `OPENF50_DEVICE` | `f50`、`u30air` | 仅 `/data/adb` | 自动检测；仅当安装程序不认识型号名时才需要 |
| `OPENF50_LANG` | `en`、`tr`、`zh` | 两者皆可 | Android 区域设置的语言 |
| `OPENF50_DRY_RUN` | `1` | 两者皆可 | 未设置 |
| `OPENF50_SYNC_BOOTCHAIN` | `0`、`1` | 两者皆可 | `1`：Linux 槽位在与 Android 槽位不同时获得其启动链（先备份）。`0`：保持原样，供专家使用 |
| `OPENF50_ADB_KEY` | 电脑 `~/.android/adbkey.pub` 的一行 | 仅 `/data/adb` | 对安装的 Linux 开启 USB adb，仅授权这一个密钥（持有者可获得 root shell）。没有它，adb 状态不变 |

示例。装到卡上并格式化（卡上一切都被清空），使用自设密码，
以 root 在 `adb shell` 中执行：

```sh
su -c 'printf "OPENF50_STORAGE=sd\nOPENF50_SD_ERASE=yes\nOPENF50_PASSWORD=choose-one-here\n" > /data/adb/openf50-install.conf'
su -c 'chmod 600 /data/adb/openf50-install.conf'
```

只想看看安装会做什么、文件放在 `/sdcard`：单独一行 `OPENF50_DRY_RUN=1`。

**密码。** zip 安装的系统使用镜像自带的公开密码：Ubuntu 的用户 `ubuntu` 密码为
`ubuntu`，OpenWrt 的 `root` 无密码（与官方 OpenWrt 一致：在你用 `passwd` 或 LuCI
的 System > Administration 设置之前，dropbear 和 LuCI 允许 root 无密码登录）。不用随机密码：
随机密码只显示在一个 root 可读的文件中，而下一个 zip 会覆盖它，导致后来加在第一个
系统旁边的系统密码无人知晓（FINDINGS 47）。更新保留系统现有的账号和密码，
与 `openf50-update` 一致：镜像自带密码只用于还没有自己密码的系统（首次安装、
wipe、加在第一个旁边的第二个系统），或 `/data/adb/openf50-install.conf` 用
`OPENF50_PASSWORD_RESET=yes` 要求时。`OPENF50_PASSWORD` 则为其安装的每个系统设置你自己的
密码（这些要放在那里，不要放进 zip 自带的 `openf50/openf50-install.conf`——它从不被编辑，
且会在每次更新时重置密码）；它会做哈希，绝不显示或记录。哪个密码可用会在
安装任何东西之前显示在 Magisk 输出中，并记录在 `/data/adb/openf50-linux-password.txt`
（可信的 `OPENF50_PASSWORD_FILE=sdcard` 会把说明放到 `/sdcard/openf50-linux-password.txt`）。
安装成功后，`/data/adb/openf50-install.conf` 中的 `OPENF50_PASSWORD` 或 `OPENF50_PASSWORD_RESET`
会被替换为注释。

### 无需电脑从 Android 启动 Linux

`android/magisk/build.sh` 为已装有 Linux 的设备构建一个小型 Magisk 模块
（从电脑安装；上面的 zip 就是这个模块加安装器）。装好后，Magisk app 会出现一个
**Action** 按钮，可把设备重启进 Linux，终端中 `su -c openf50-linux` 效果相同
（`su -c 'openf50-linux status'` 只是显示哪个系统在哪个槽位）。它只写与安装程序相同的
`misc` 那 32 字节。`su -c 'openf50-linux bootchain'` 显示两个槽位的启动链是否不同，
`su -c 'openf50-linux bootchain sync'` 则像安装程序一样把 Android 槽位的复制到 Linux 槽位
（比如 Android 更新之后），备份在 `/data/adb/openf50-bootchain/`。见 [android/magisk/README.md](android/magisk/README.md)。

### VPN

设备可以让自身流量**以及**所有已连接客户端的流量都经过 VPN 服务器：`openf50-vpn`
保存配置——WireGuard `.conf`、OpenVPN `.ovpn`、Clash/mihomo YAML、VLESS、VMess、Trojan 或 Shadowsocks
分享链接、dae 用的 hysteria2 或 TUIC 链接，或原始 Xray、sing-box JSON——并运行激活的那个，
带 kill switch（防泄漏开关）、Tailscale 走隧道，Ubuntu 和 OpenWrt 上都一样。它是独立模块，
在 **[dikeckaan/mu300-linux-vpn](https://github.com/dikeckaan/mu300-linux-vpn)** 开发和发布
（命令、配置、设置、安全模型）：镜像不含它的任何部分，openf50-linux 只保留内核支持
（TUN、WireGuard、nftables）和与它配合的部分（移动数据、Wi-Fi 客户端、省电、工具箱、面板）。

模块 **v2.0.0**（随 openf50-linux v2026.10.20）把它拆成核心和引擎扩展，新增订阅（产出配置
的 URL，定时刷新）、供控制面板 VPN 部分使用的 `--json` 接口，以及 **IPv6
防护**：`IPV6` 为 `auto`、`1` 或 `0`；当隧道不带 IPv6 时，IPv6 在隧道旁被阻断，
而不是绕过 kill switch 泄漏。eBPF 引擎 [dae](https://github.com/daeuniverse/dae) 需要
v2026.10.20 或更新的内核 6.18、7.2（它们带 BTF）；5.4 无法运行。

```sh
sudo openf50-extra install vpn                                # online: the core and the engines its profiles need (first time: xray)
sudo openf50-vpn engine install sing-box                      # each engine is an extra: xray, sing-box, mihomo, dae (= openf50-extra install vpn-singbox ...)
sudo openf50-extra install vpn --from /mnt/usb/               # offline, verified: a directory with the tarballs and their SHA256SUMS
sudo openf50-extra remove vpn-mihomo                          # an engine; refused while the VPN runs on it
sudo openf50-extra remove vpn                                 # turn the VPN off first
```

安装程序也会询问它。模块存放在 Linux 分区（`/mnt/openf50-disk/extra/vpn`，引擎在
`extra/vpn-xray`、`vpn-singbox`、`vpn-mihomo`、`vpn-dae`），所以 Ubuntu 和 OpenWrt 共享一份；
安装时链接进每个已装系统，每个系统开机时再链接一次。`openf50-update apply` 把核心和
设备上有的或配置需要的每个引擎作为一组更新到最新版本（引擎在前，核心最后），
使用 VPN 的设备绝不会在没有它们的情况下被更新：离线时，更新会在改动任何东西之前停下，
并说明如何准备好模块（`openf50-linux-vpn-core.tar.gz` 加各引擎 tar 包，或
`openf50-linux-vpn.tar.gz`——核心加 xray 和 sing-box——以及 `SHA256SUMS`，放到
`/mnt/openf50-disk/.openf50-update/vpn/`，或 `OPENF50_VPN_MODULE=DIR
openf50-update apply`）。v1 模块（引擎在 vpn 扩展内部）升级时保留其两个引擎。
VPN 开启且带 kill switch 的系统丢了模块会关闭式失败（fail closed）：移动数据和 Wi-Fi 客户端
保持关闭，直到重新安装（`openf50-extra install vpn`）或关闭 VPN。缺少引擎也会关闭式
失败，在 kill switch 保护下，服务会重新拉取它；openf50-toolkit 会说明是哪一个。

### 语言

两个 OpenWrt 系统开箱即说**英语、土耳其语和简体中文**：LuCI 自己的页面（来自
OpenWrt 对 LuCI、防火墙和软件包管理器的翻译），以及 `openwrt-luci` 上的 OPENF50 控制
面板。网页界面默认是**英语**；在 System -> System -> Language and Style 切换，
`openwrt-luci` 上在 System -> Languages。更新会保留你选的语言。

其他语言是 **lang 扩展**（约 2 MB，仅 OpenWrt——Ubuntu 没有网页界面）：LuCI 有 OpenWrt
25.12.5 翻译的另外 40 种语言，控制面板有其中 29 种（ar、az、bg、cs、da、de、el、
es、fa、fi、fr、he、hi、hu、id、it、ja、kk、ko、nl、pl、pt-BR、ro、ru、sk、sv、uk、
vi、zh-TW；az、kk 和 id 没有 LuCI 翻译，只有面板的）。可从面板安装（System -> Languages：
下载它，或在设备无网络时从发布页上传 `openf50-extra-lang.tar.gz`），也可在设备上安装：

```sh
openf50-extra install lang                                 # from the release of this system
OPENF50_EXTRA_FILE=/tmp/openf50-extra-lang.tar.gz openf50-extra install lang   # from a file, offline
openf50-extra lang                                         # the languages, and which are offered
openf50-extra lang disable all; openf50-extra lang enable de ja   # offer only some of them
openf50-extra remove lang
```

语言立刻出现在语言列表中（无需重启）；扩展在更新后保留并随之一同更新。
某个系统提供其中哪些语言是该系统自己的设置（`/etc/openf50/languages`）。

控制面板除土耳其语和中文外的翻译都是英文原文的**机器（AI）翻译**。非常欢迎修正：
编辑 `openwrt/luci-app-openf50/po/<language>/openf50.po` 并提交 pull request
（`python3 tools/luci-i18n.py check` 必须保持无错；新语言还需要在
`openwrt/luci-languages.tsv` 中加一行）。

### Wi-Fi 客户端

射频可以加入另一个 Wi-Fi 网络而不是做热点（二选一：SC2355 同一时间只做一种）。
此时设备自己使用该网络，并像共享移动数据一样把它共享给 USB 客户端。

```sh
sudo wifi-client scan                    # the networks in range: signal, security, name
sudo wifi-client connect "NAME"          # asks for the password; nothing is shown as you type
sudo wifi-client connect "NAME" --open   # an open network
sudo wifi-client status
sudo wifi-client disconnect              # the hotspot comes back, and stays after a reboot
sudo wifi-client reconnect               # join the saved network again
sudo wifi-client forget                  # delete the saved network
```

* **在被询问时输入密码，不要写在命令行上。** `sudo` 会把整条命令行写进系统
  日志，所以 `sudo wifi-client connect "NAME" "PASSWORD"` 会把密码留在那里（仍可用，但会
  警告）。脚本中可用 `-` 从管道读入：`printf '%s\n' "$PW" | sudo wifi-client connect "NAME" -`，
  或把它放在仅 root 可读的文件中并用 `--password-file FILE`。已加入的网络及其密码保存在
  `/etc/openf50/wifi-client.conf`（仅 root），每次开机都会重新加入。
* **`disconnect` 是持久的**：下次开机也保持热点。`sudo wifi-client disconnect --keep`
  让下次开机仍加入该网络；`reconnect` 重新开启。
* **加入网络需要射频处于客户端模式**，这在开机时决定：当它是热点时，`connect` 会保存
  网络并请求重启（或用 `openf50-toolkit`，它提供关闭热点重启以便扫描的选项）。
* **WPA2 和 WPA2/WPA3 混合网络可用；纯 WPA3 不行。** 扫描把它们标为 `WPA3`
  （`WPA2/3` 是混合模式，按 WPA2 加入），`connect` 一发现就拒绝：这个 Wi-Fi 驱动
  没有 SAE。把路由器设为 WPA2/WPA3 混合模式即可加入。（系统随附了一个带 SAE 的驱动。）
* **共享，以及它不共享的东西**：USB 客户端经该网络访问互联网，且只能是
  互联网：它自己的设备和路由器（私有、链路本地、CGNAT、组播和其他特殊用途地址，
  以及它的子网）从 LAN 不可达，IPv6 也一概不通，所以设备 USB 上的访客不会
  进入你的家庭或酒店网络（不过该路由器的公网地址属于互联网，有些路由器
  会在其上应答）。从那个网络只有 ping、DHCP、IPv6 邻居发现和应答能进来：
  SSH 和设备的其他服务对它关闭，就像对调制解调器一样（用 USB 访问设备）。
  防火墙在射频加入之前就已就位且关闭；只有 DHCP 应答且地址通过检查后
  共享才开始（与 LAN 同子网的网络会被拒绝）。链路丢失会立刻关闭共享并丢弃
  地址（移动数据接管）；链路恢复时重新请求 DHCP，新地址经检查后
  才开始共享。连接期间会续租，带来新地址的续租同样要过检查。离开
  （`disconnect`、`forget`、失败或中断的加入）会一步清除一切，
  且只在射频离开该网络之后：不肯停下的 supplicant 会让防火墙保持关闭。
  此后除非移动数据在共享，转发也会关闭。以 nft 列出的表为准，绝不看文件：
  每次改动后都把规则逐条与请求比对，不一致（或 nft 无法作答）就关闭，
  或丢弃地址和路由；`wifi-client status` 显示 nft 报告的状态。停止
  `openf50-wifi-client.service` 以同样方式关闭客户端，不动保存的设置。
  nftables 表为 `ip openf50_wifi_nat`（Ubuntu）和 `inet openf50_wifi_filter`；
  OpenWrt 上 `wlan0` 还加入 `wan` 防火墙区域（由 fw4 做 NAT），并有一条针对私有地址的
  规则（`openf50-wifi-client-private`）。（vpn.conf 中的 `LAN_CIDRS` 条目也不会把另一个
  网络开放给 LAN 客户端。）[VPN](#vpn) 开启时，客户端仍走隧道，其 kill
  switch 像覆盖调制解调器一样覆盖 `wlan0`；这些表绝不会放任何东西绕过它。
* 网络名称按网络发送的内容显示，只要它们是可打印 UTF-8；控制字符、终端转义
  序列、不可见和双向字符、非 UTF-8 字节以及反斜杠本身都显示为 `\xNN`，
  名称首尾的空格也一样。这种网络无法从 `openf50-toolkit` 列表中选择；
  用 `sudo wifi-client connect` 和它的真实名称加入（带控制字符的名称无法加入）。
* Wi-Fi 路由的 metric 是 50，移动数据是 100，所以两者都有时用 Wi-Fi，SIM 保持空闲。

### 更新

设备可以无需电脑、从已发布的版本自行更新：

```sh
sudo openf50-update check           # installed version vs newest release
sudo openf50-update apply           # system, kernel and boot image: download, unpack, switch; then reboot
sudo openf50-update rollback        # back to the previous system
sudo openf50-update rollback-boot   # back to the previous kernel and boot image
sudo openf50-update kernel 7.2      # another kernel: 5.4 (vendor), 6.18 (LTS) or 7.2; no argument shows the current one
```

`openf50-toolkit` 在 System -> Software update 下提供同样的功能。你的设置、用户、`/usr/local`、
厂商文件（Wi-Fi 固件、Android 调制解调器用户态）和已装的扩展都会带过来（lang 扩展升到
新版本，[VPN](#vpn) 模块升到其最新版本），旧版本保留为 `<os>.old` 供回退（rollback），
直到你运行 `openf50-update clean`。新文件系统解包在旧系统旁边，最后才换入，
所以下载中断不会留下更新一半的系统。

**你自己安装的软件包**（OpenWrt 上 `apk add`，Ubuntu 上 `apt install`）不在发布镜像中。
`apply` 会在切换前列出它们，把它们的 OpenWrt 设置（`/etc/config/<name>`）暂存到
`/etc/openf50/orphaned-config/`，新系统首次开机联网后把它们装回，
并恢复其设置和服务的启用/禁用状态。Ubuntu 保留你添加的 apt 源
（PPA 及其密钥）；在新版本上导致 `apt-get update` 失败的源会被关闭并说明。
面板在 System -> Packages after an update 下展示这一切。软件源里没有的包
（从文件安装的）不会被装回，其设置暂存：`openf50-user-packages status` 说明
哪些回来了、如何恢复其余。如果这类代理（OpenClash）曾把 dnsmasq 指向自己，
设备会报告，且绝不自行回退到连接的解析器：`openf50-user-packages repair-dns`
按需执行。`openf50-update apply --no-reinstall`（或 `OPENF50_KEEP_PACKAGES=0`）跳过重装。
安装程序的 **update** 做同样的事。

内核和启动镜像也会更新。启动镜像保留你设备自己的部分（其 Android 文件和
原厂头），换上发布版的内核和 ramdisk 的通用部分，所以不需要电脑，
也不需要 Android 的任何东西。旧镜像保留给 `rollback-boot`，起不来的内核
会在常规次数的启动失败后让设备自行回到 Android。

`openf50-update apply` 先下载并校验每个文件，全部就绪前不改动任何内容；
从 v2026.09.28 起，它还会在开始之前先切换到所装版本的更新器。

**从 v2026.09.27 或更旧版本更新？** 先获取新更新器再更新；两步都在刚重启后执行
（旧启动镜像可能在安静几分钟后丢移动数据，见 docs/FINDINGS.md 32）：

```sh
sudo curl -fL https://github.com/dikeckaan/openf50-linux/releases/latest/download/openf50-update -o /opt/openf50/bin/openf50-update
sudo openf50-update apply
```

在 OpenWrt 上，以 root 执行：`wget -O /opt/openf50/bin/openf50-update https://github.com/dikeckaan/openf50-linux/releases/latest/download/openf50-update`
然后 `openf50-update apply`。之后重启以启动新系统和内核。

**更新后回到了 Android？** 用旧启动镜像时，Linux 的一次崩溃或复位（更新可能
引发，见上文）就会让设备回退到 Android 并停在那里。用 Magisk 模块的 Linux
按钮或 `su -c openf50-linux` 再次启动 Linux，然后按上文更新。如果 Linux 再也
起不来，说明启动镜像没保住：从电脑再跑一遍安装程序并选 `update`——它会写入
新的启动镜像并保留你的设置和数据。

## 卸载

设备回到 Android 后：

```sh
./uninstall.sh                # macOS / Linux
.\uninstall.ps1               # Windows (PowerShell)
uninstall.cmd                 # Windows (cmd)
```

它让 Android 重新成为启动系统，恢复第二个 boot 分区，并擦除 Linux 文件系统。你的
Android 数据不受影响，除非你要求归还空间（见下文）。擦除的彻底程度由你选：

* **secure**（默认）——覆写整个 Linux 区域并校验为空，文件真正消失。
  需要几分钟。
* **quick**——只擦除文件系统头；文件在闪存上仍可读，直到空间被重用。
* **keep**——不动 Linux 文件系统；只是它再也不会启动。

SD 卡上的 Linux 文件系统有单独的问题：**erase**（默认）覆写其前 64 MiB，
很快，文件在卡上仍可读直到空间被重用；**keep** 保持卡原样。装有任何其他
文件系统的卡绝不动。

如果你在 32 GB 版本上缩小过 `userdata` 来腾空间，它会接着提议把它扩展回
释放出的空间。这默认关闭且询问两次，因为在 64 GB 设备上同样的回答会把一直
空闲的区域交给 Android——而且和缩小一样，它会再次清空 Android 的数据。

和安装程序一样，它会先提议把设备从 Linux 重启进 Android。

## 可用与不可用

| | |
|---|---|
| Ubuntu 24.04 LTS、OpenWrt 25.12、带控制面板的 OpenWrt | ✅ |
| Ubuntu 26.04 LTS | ✅ 内核 6.18 或 7.2（其程序需要 5.4 没有的系统调用） |
| 内核 | ✅ 厂商 5.4、主线 6.18 LTS 和 7.2（v2026.10.20 中为 6.18.56 和 7.2.10，带 BTF 和 BPF JIT，可运行 dae），功能相同（U30 Air 的 USB host：仅主线）；主线包带约 360 个模块（WireGuard、SQM、隧道、USB 网卡和调制解调器、NTFS/exFAT/btrfs/NFS/CIFS、dm-crypt、容器）。6.18 大约每 20 次开机有一次卡在启动，设备回到 Android（[FINDINGS 31m](docs/FINDINGS.md)） |
| KVM | ✅ 三个内核都有 `/dev/kvm` |
| 移动数据（5G NSA / LTE） | ✅ 与 Wi-Fi 和 USB 客户端共享；调制解调器复位后自行重连 |
| 短信、USSD | ✅ `sms`、`openf50-ussd`；`openwrt-luci` 上面板中也有 |
| Wi-Fi 接入点 | ✅ 5 GHz（802.11ac）或 2.4 GHz，同一时间一种 |
| Wi-Fi 客户端 | ✅ WPA2 和 WPA2/WPA3 混合，共享给 USB 客户端；✗ 纯 WPA3 网络（驱动无 SAE） |
| USB 网络 + 串口控制台 | ✅ `192.168.77.1`（U30 Air `192.168.78.1`），`screen /dev/cu.usbmodem* 115200` |
| SSH、telnet | ✅ |
| VPN | ✅ 配置：WireGuard、OpenVPN、VLESS/VMess/Trojan/Shadowsocks 链接、Clash/mihomo、原始 Xray 或 sing-box JSON；kill switch、Tailscale 走隧道；[openf50-linux-vpn](https://github.com/dikeckaan/mu300-linux-vpn) 的模块 |
| 蓝牙 | ✅ BlueZ，可扫描 |
| GPU（Mali-G57） | ✅ OpenCL 3.0，无头 |
| 存储 | ✅ 64 GB 设备内部 eMMC 未用区域约 32 GB；32 GB 设备由你选择与 Android 的分割比例，或用 SD 卡（F50） |
| 内存 | ✅ 可用约 1.4 GB（MemTotal 1473 MiB；其余大部分被调制解调器固件保留） |
| 温控、状态 LED、SIM 卡托 | ✅ |
| U30 Air：电池、按键、NFC、USB host | ✅ 每个内核都有电池读数；每个内核都可充电（主线自 v2026.10.12 起），充电上限和 Type-C 充电电流自 v2026.10.20 起（见[支持的设备](#supported-devices)）；USB host 仅主线，外部供电时也可用 |
| 网页面板 | ✅ OpenWrt：LuCI，以及 `openwrt-luci` 上的 OPENF50 控制面板（浏览器内带终端）；Ubuntu：Cockpit 带 OPENF50 页面，作为面板扩展；两者都支持经 USB adb 到 Linux（默认关闭） |
| 回到 Android、自动回退 | ✅ |
| 屏幕输出（USB-C HDMI） | ✗ USB-C 供电芯片从不应答，所以无显示 |
| 声音 | ✗ 主板无扬声器无麦克风。经调制解调器音频 DSP 的通话音频仍在开发中，未进发布（`kernel/build-audio.sh`、`openf50-audio-dsp`、`openf50-voice`）：有了它们声卡能起来（`sprdphone-sc2730`，19 个 PCM 设备），DSP 有应答，但任何场景都没有声音流动，无音频的通话约 20 秒后结束，与该板在 Android 下一致（[FINDINGS 24, 24b](docs/FINDINGS.md)）。kano 的 [e5-linux](https://github.com/kanoqwq/e5-linux) 的通话序列和内核修复已移植，以蓝牙耳机为输出（`openf50-voice audio start bt`、`tools/hfp`）；DSP 镜像由你自己提供（`openf50-audio-dsp install`），有了它之后尚未实测（[FINDINGS 24c](docs/FINDINGS.md)）。内核有 USB 音频驱动，此处未试 |

## 原理简述

设备有两个 Android 启动槽位：A 和 B。Android 住在其中一个里（用电脑安装程序时
是 A），不被触碰。安装程序把 Linux 内核放进另一个槽位并标记为试启动。开机时，
一个小启动程序加载设备驱动，在 SD 卡或内部存储的未用区域找到 Linux 文件系统，
并从中启动 Ubuntu 或 OpenWrt。如果 Linux 连续几次启动失败（除非你另选，默认 5 次），
设备自行回退到 Android。三个 Android 小程序（`modem_control`、
`refnotify`、`cp_diskserver`）在 Linux 内的沙箱中持续运行，因为调制解调器需要它们。
从 v2026.10.20 起，前两个运行在自己的系统账号 `openf50vnd` 下，只带它们在 Android 上
保留的权能（capabilities），调制解调器的设备节点（包括其校准分区）属于该账号
而非登录用户，`/dev` 中没有任何全局可写文件（[FINDINGS 41](docs/FINDINGS.md)）。

5.4 内核由 ZTE 发布的（GPL）源码构建；6.18 和 7.2 是主线 Linux 加上本项目的
补丁和移植过去的厂商驱动（[`upstream/`](upstream/)）。每一步背后的推理在
[`docs/FINDINGS.md`](docs/FINDINGS.md)，完整构建流程在 [`docs/BUILD.md`](docs/BUILD.md)。

## 常见问题

**安装后设备没回来。** 等两分钟。如果还是没有，拔掉重插。每次没完成的启动都计数，
连续 5 次（或你选的次数）后设备启动 Android。用 `tools/collect-logs.sh` 收集日志。

**内核 6.18 上，没要求却回到了 Android。** 大约每 20 次开机有一次在最初几秒卡死
（[FINDINGS 31m](docs/FINDINGS.md)），随后设备回退到 Android。用 Magisk 模块的 Linux
按钮或 `su -c openf50-linux` 再次启动 Linux。

**电脑看得到设备但拿不到地址（macOS）。** macOS 在锁屏时不会配置它从未见过的
网络接口。每台设备有自己的 USB MAC 地址，所以第一次插入某台设备时（或在
带来这些地址的更新之后）解锁 Mac，接口就会出现。F50 和 U30 Air 同时插入时，
分别是 `192.168.77.1` 和 `192.168.78.1`；两台同型号设备需要 `/etc/openf50/lan.conf`
来区分。

**没有网络。** 先确认 SIM 卡有流量套餐，再运行 `sudo mobile-data status`。没套餐
看起来就像连接不停掉线。

**内核 5.4 上的 OpenWrt：没有地址、没有网页界面、热点无人连得上**（v2026.10.11
及之前的版本）。防火墙的开机规则集没有 LAN 的规则，5.4 上本该补上它们的
reload 总是失败（[FINDINGS 38c](docs/FINDINGS.md)）。从下一版本起修复；在那之前，
USB 串口控制台（`ttyGS0`，root shell）是入口，`nft delete flowtable inet fw4 ft; fw4 reload`
可拉起 LAN。5.4 上在 LuCI 保存的防火墙改动仍需那两条命令（或重启）才能生效。

**热点无法在 52 到 144 之间的 5 GHz 信道启动**（hostapd：`start_dfs_cac() failed`、
`AP-DISABLED`；v2026.10.18 及之前的版本）。那些是 DFS 信道，而 Wi-Fi 驱动无法检测雷达
（[FINDINGS 42](docs/FINDINGS.md)）。从 v2026.10.20 起修复：这种信道会被替换为 36
（或 149）。在那之前请选 36-48 或 149-165（165 用 20 MHz），Ubuntu 上可用 `auto`。

**一条 AT 命令卡住后控制面板不再响应**（`openwrt-luci`，v2026.10.18 及之前的版本）：
每个页面都空白，连电池卡片也是，几分钟后自行恢复。面板的锁等待按整秒计
而非十分之一秒，且有些页面在请求内读调制解调器（[FINDINGS 40](docs/FINDINGS.md)）。
从 v2026.10.20 起修复；在那之前请等待，或重启 `rpcd` 和 `openf50-atd`。

**安装程序几分钟没有输出且设备发热。** 分区表结束位置恰好是磁盘结尾的设备
（32 GB 版本和 `userdata` 后面没有空隙的 F50），读 eMMC 末尾之后的位置永不返回
（[FINDINGS 38a](docs/FINDINGS.md)）。从下一版本起修复；重启设备结束卡住的读取，
然后用新安装程序安装。

**内核警告不在 `journalctl -k` 里。** Ubuntu 上它们在 `journalctl -t kernel`
（仅警告和错误，从每次开机起点开始，带内核自己的时间戳；重复的厂商噪音被过滤，见
`/etc/openf50/kmsg-ignore`）。其余在 `dmesg`。

**网站以为你在另一个国家。** 设备没有 GPS，网站按 IP 地址猜测；移动运营商和
VPN 服务器常常看起来像另一个城市。

**我忘了密码，而 Linux 默认启动。** 要脱身不需要登录（除非 Linux 被
[锁定](#locked-linux)：那就走下面电脑路线的第 2 步）：

1. **回到 Android：** 设备通电约十秒后拔掉，再插上，连续重复你选择的
   失败启动次数（默认 5；`openf50-next-boot attempts`）。设备会看到未完成的启动
   并自行回退到 Android（`openf50-boot-ok` 只在系统起来约 30 秒后才确认启动，
   所以中断的启动绝不算成功）。
2. **设新密码**：从电脑上，不启动 Linux：
   ```sh
   tools/reset-password.sh            # ubuntu, openwrt or both
   ```
   它从 Android 挂载 Linux 文件系统并重写密码哈希，保留你的所有数据。
3. 用 `boot/android-boot-linux.sh work/boot-linux-slotb.img` 再次启动 Linux，
   或者如果 Linux 是默认系统就直接重启。

重新运行 `./install.sh` 并选择 **update** 会保留你的数据并设置你输入的密码
（Magisk zip 的更新保留旧密码，除非 `/data/adb/openf50-install.conf` 中有
`OPENF50_PASSWORD_RESET=yes`）。

**下载慢。** GitHub 的发布 CDN 在某些地区限制单连接速度（这里 180 Mbit/s 的线路
只有 0.2 MB/s）。安装程序已用 8 个并行分块下载，实测快 8 倍；
用 `OPENF50_FETCH_JOBS` 调整，或把 `OPENF50_RELEASE_URL` 指向你自己的镜像。

**绝不要在这里用 OpenWrt 的 `sysupgrade` 或刷 OpenWrt 固件镜像。** 它们是为普通电脑
写的，会覆盖设备的存储。正常的 `apk upgrade` 没问题，除了 `kernel` 和 `kmod-*` 软件包。

## 开发者

* [`docs/BUILD.md`](docs/BUILD.md)——自行构建内核和镜像（`kernel/build-all.sh` 一步完成）。
* [`docs/FINDINGS.md`](docs/FINDINGS.md)——关于这套硬件的所有发现，以及每个变通方案存在的原因。
* [`docs/DISTROS.md`](docs/DISTROS.md)——运行其他发行版（ImmortalWrt、Arch Linux ARM、Debian、Kali；
  Ubuntu 镜像的 `Dockerfile` 可用 `--build-arg BASE=...` 换底座），以及 5.4 内核排除掉的东西。
* [`upstream/`](upstream/)——主线内核移植，6.18 LTS 和 7.2。
* [`tests/`](tests/README.md)——`cd tests && python3 -m unittest` 运行全部（仅用标准库；
  boot 镜像测试需要 `lz4`），`python3 tools/check-i18n.py` 检查安装程序的翻译。CI
  （`.github/workflows/`）：`tests.yml` 在 Ubuntu、macOS 和 Windows 上跑，`installer.yml`
  （翻译、脚本语法）、`mainline.yml`（每周对最新 longterm 和 stable 内核构建移植）和
  `magisk.yml`（每个发布的 Magisk zip）。
* [Releases](https://github.com/dikeckaan/openf50-linux/releases)——预构建镜像。它们
  **不含任何专有文件**；安装程序从你自己的设备提取那些文件。

| 路径 | 内容 |
|---|---|
| `install.sh`、`uninstall.sh` | macOS/Linux 的安装程序和卸载程序 |
| `install.ps1`、`uninstall.ps1` | Windows（PowerShell）的对应脚本；`install.cmd`、`uninstall.cmd` 从 cmd.exe 启动它们 |
| `kernel/` | 内核构建环境、配置、补丁 |
| `boot/` | initramfs `init`、启动镜像构建器、槽位处理 |
| `rootfs/` | Ubuntu 镜像：`Dockerfile`、`assemble.sh`，服务和脚本在 `overlay/` |
| `openwrt/` | OpenWrt 和 ImmortalWrt 镜像构建；`luci-overlay/` 和 `luci-app-openf50/` 组成 `openwrt-luci` 系统 |
| `arch/` | Arch Linux ARM 镜像构建 |
| `upstream/` | 主线内核移植（6.18、7.2） |
| `android/magisk/` | Magisk 模块和 zip 安装器 |
| `android-vendor/` | 从*你的*设备复制所需 Android 文件的脚本 |
| `tests/` | 安装程序、启动镜像、`boot/init` 和设备脚本的单元测试 |
| `tools/` | 辅助程序、发布工具、备份、SSH/串口/日志助手 |

这里使用的内核源码镜像在
[`dikeckaan/zte-ums9620-kernel-5.4.254`](https://github.com/dikeckaan/zte-ums9620-kernel-5.4.254)。

## 致谢与许可证

* 内核源码：ZTE 为 U30 Air 发布的 GPL 版本（由 Enceka 镜像）及其中 Unisoc 驱动——GPL-2.0。
  主线内核是 kernel.org 的 Linux——GPL-2.0。
* Wi-Fi、蓝牙和 GPU 驱动：realme C51/C53 AndroidT 内核发布——GPL-2.0；
  `kernel/patches` 中的补丁为 GPL-2.0。
* 本仓库中的脚本、工具和文档：MIT（见 `LICENSE`）。
* kanoqwq（`kanoqwq/openf50-linux`，`clean-tf-7.2`）：`openwrt/luci-app-openf50`（控制面板，
  此处有修改）；SD 卡安装的构想及其启动侧改动的核心；以及从该分支移植的修复
  （更快的 USB 重绑定、提前的 DHCP 租约、RNDIS、射频开启序列；`openwrt-luci` 上的短信池和
  IPv6 中继模式），实测见 [FINDINGS 35](docs/FINDINGS.md)。
* eamonxg 的 Aurora 主题（`luci-theme-aurora`）在构建时下载，版本固定并按哈希校验。
* VPN 模块（[openf50-linux-vpn](https://github.com/dikeckaan/mu300-linux-vpn)）包含
  [Xray-core](https://github.com/XTLS/Xray-core)（MPL-2.0）、[sing-box](https://github.com/SagerNet/sing-box)
  （GPL-3.0-or-later）、[hev-socks5-tunnel](https://github.com/heiher/hev-socks5-tunnel)（MIT），
  以及作为 vpn-mihomo 的 [mihomo](https://github.com/MetaCubeX/mihomo)（MIT）；其发布会列出它们。

* 原厂固件、Android 厂商组件和 bootloader 归各自所有者，不在此分发。
  项目保留的唯一原厂镜像——固件 `ZYV1.0.0B09` 的 `trustos`（TEE）镜像，
  用作自身 TEE 损坏设备的最后修复手段——托管在 Internet Archive
  （https://archive.org/details/zte-f50-openf50-trustos-ZYV1.0.0B09；其一切权利归 ZTE/Unisoc 所有）。
  使用前请先读 [`stock/README.md`](stock/README.md)——它可能让
  本就启动不了的设备更糟。
