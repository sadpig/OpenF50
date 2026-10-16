# OPENF50 Linux wiki

**一句话概括：** 本项目在 ZTE F50 / OPENF50 和 ZTE U30 Air 口袋 5G 热点上，在 Android 之外装一套真正的 Linux
系统（Ubuntu 或 OpenWrt），让这个小盒子变成一台自带 5G 调制解调器的 Linux 路由器和服务器。

![一台设备上 Android 与 Linux 并存](https://kaandikec.com/openf50-linux/assets/img/two-systems.svg)

## 通俗版说明

你的热点其实是一台微型电脑。出厂时它运行 Android，藏在一个网页后面，只干一件事：分享移动网络。本项目在
Android 不用的存储空间里加入第二个系统——Linux。设备启动时会启动 Linux。如果 Linux 连续几次启动失败，
设备会悄悄自己回退到 Android。Android 永远不会被删除，而且一条命令就能彻底回到 Android。

可以把它想象成一台树莓派，只不过内置了 5G 调制解调器、Wi-Fi 接入点和 32 GB 存储。

## 从哪里开始

| 如果你想…… | 阅读 |
|---|---|
| 了解需要什么并安装 | [Installation](Installation) |
| 在 Ubuntu、OpenWrt 和带控制面板的 OpenWrt 之间选择 | [Choosing a System](Choosing-a-System) |
| 选择内核（5.4、6.18 或 7.2） | [Kernels](Kernels) |
| 让移动数据可用、设置 APN | [Mobile Data and APN](Mobile-Data-and-APN) |
| 修改热点，或加入别的 Wi-Fi | [Wi-Fi Hotspot and Client](Wi-Fi-Hotspot-and-Client) |
| 读取和发送短信 | [SMS](SMS) |
| 让所有流量走 VPN | [VPN](VPN) |
| 使用网页控制面板 | [Control Panel (LuCI)](Control-Panel-(LuCI)) |
| 更新，或回滚更新 | [Updating](Updating) |
| 回到 Android，或移除 Linux | [Going Back to Android](Going-Back-to-Android) |
| 修东西 | [Troubleshooting](Troubleshooting) 和 [FAQ](FAQ) |
| 查名词 | [Glossary](Glossary) |
| 了解硬件的表现 | [Hardware Notes](Hardware-Notes) |
| 自己构建或帮忙 | [Building from Source](Building-from-Source)、[Contributing](Contributing) |

另有一个内容相同、带插图的入门网站，提供英语、土耳其语和中文版本：
**https://kaandikec.com/openf50-linux/**

## 支持的设备

| | ZTE F50 / OPENF50 | ZTE U30 Air |
|---|---|---|
| 芯片 | Unisoc T760 (UMS9620)，板型 `ums9620_2h10_feimao` | 相同 |
| 供电 | 仅 USB | 电池（4050 mAh） |
| USB 网络地址 | `192.168.77.1` | `192.168.78.1` |
| SD 卡 | 支持：Linux 可以装在卡上 | 无卡槽 |

安装程序能识别自己在和哪台设备对话。**U30 Pro** 用的是另一款芯片（UMS9632），**不**受支持。更多见
[Hardware Notes](Hardware-Notes)。

## 你得到什么，失去什么（剧透：什么都不失去）

**你得到：** Ubuntu 24.04 或 26.04 LTS，或 OpenWrt 25.12（纯净版，或带调制解调器控制面板）；三个内核可选；
通过 Wi-Fi 和 USB 共享 5G/LTE 网络；SSH，以及 USB 上的 `adb`；蓝牙；短信和 USSD；可选的 VPN 模块；
Ubuntu 上也有网页面板（Cockpit 加一个 OPENF50 页面，可选）；一个类似 `raspi-config` 的菜单
`openf50-toolkit`；自动回退到 Android；在设备上直接更新。

**关注本项目：** 版本发布和新闻会在 Telegram 频道 [t.me/mu300project](https://t.me/mu300project) 上公布。

## v2026.10.25 新功能

2026-10-25 发布的版本（先以预发布形式推出，有板子跑过之后转正；v2026.10.24 停留在预发布：它的更新器
可能以 "another openf50-update is running" 停止，且它的 OpenWrt 起来后没有 adb）。它带来的变化，以及
延伸阅读：

* **连到 Linux 的 adb 默认开启，对所有电脑开放。** 插上数据线，`adb shell` 就是 root shell，无需密钥；
  图形安装器和网页安装器都依赖它。**任何能把数据线插到设备上的人都能得到这个 shell**，在你设置密码
  之后也是如此。从未碰过 adb 的设备在这次更新后会变成开放状态；而你运行过 `openf50-usb adb off`、
  或带密钥开启过 adb 的设备保持原样。要关闭它：`openf50-usb adb auth keys`（仅限授权的密钥）或
  `openf50-usb adb off`。[Installation](Installation#adb-to-linux)、[FAQ](FAQ)
* **网页安装器：** [kaandikec.com/openf50-linux/web-installer](https://kaandikec.com/openf50-linux/web-installer/)
  从 Chrome 或 Edge 经 USB 安装，电脑上什么都不用装：你选择系统和内核，设备自己下载发布包。已在 macOS
  的 Chrome 上对一台 F50 完整跑通；Windows、Linux 电脑和 U30 Air 尚未测试。[Installation](Installation)
* **短信转发：服务自身的错误也计数。** "应答必须包含"（`errcode=0`、`code=0`、`ok=true`……）让
  带错误的 HTTP 200 也算投递失败，且投递日志有了清空按钮（issue #171）。[SMS](SMS)
* **长短信** 同一发送方复用参考号时不再互相混淆或留下残片。[SMS](SMS)
* **带用户名和密码的 APN**（`AT+CGPCO`），OpenWrt 上（`network.wan.username`/`password`/`auth`）和
  Ubuntu 上（`mobile-data.conf`）都支持。[Mobile Data and APN](Mobile-Data-and-APN)
* **面板保存的频段和小区锁在更新后保留**（之前会丢：调制解调器还锁着，面板却显示没有）。
* **Windows：安装器可以腾地方**——在 `userdata` 占满 eMMC 的机器上像 `install.sh` 一样操作，并在拒绝时
  说明数字（issue #32）。[Installation](Installation)
* **U30 Air，固件变体 ABSSV：** 当第一个地址无应答时，主线内核会在第二个地址寻找充电器（0x1a 处的
  SGM41513）（issue #102；尚未在这类机器上确认）。[Kernels](Kernels)
* **`openf50-update`** 在发布包带来更新的更新器时，不再以 "another openf50-update is running" 停止。
  [Updating](Updating)
* **内核：** 5.4 不变；6.18.56 和 7.2.10 带充电器改动重新构建。[Kernels](Kernels)

## v2026.10.23 新功能

2026-10-23 发布的版本（先以预发布形式推出，有板子跑过之后转正）。它带来的变化，以及延伸阅读：

* **Magisk 安装后主线内核上的调制解调器**（issue #127、#170）：安装器导入的 Android 文件可能变成只有
  root 可读，导致调制解调器的处理器从未被加载。安装器现在以正确的权限写入它们，且每次启动都会修复
  已有的导入。[Troubleshooting](Troubleshooting)
* **6.18 和 7.2 上的热区：** 板子的温度成为一个内核热区（`openf50_thermal`），`thermal-guard` 移交
  给它。[Kernels](Kernels)
* **OpenWrt 上短信即时到达：** 调制解调器收到消息时即刻上报（`+CMT`），而不是等下一次轮询；转发到
  webhook 可以使用自定义正文（issue #171）。[SMS](SMS)
* **面板** 显示 SIM 卡自己的号码，把调制解调器以十六进制发来的运营商名称按文本显示（issue #174），
  隐藏板子没有的 SIM 槽位，且频段或小区锁重置后会进行校验。
* **VPN 页面会说明配置被拒绝的原因**，而不是 "profile not added"，且其校验生效。各引擎自身的修复在
  VPN 模块 v2.0.1 中（重新运行 `openf50-extra install vpn`）：sing-box、mihomo 和 dae 在只允许 DNS 走
  自家解析器的运营商网络上能找到服务器；带 GEOSITE/GEOIP 规则的 mihomo 配置可以启动（地理数据随
  extra 附带）；dae 在 6.18 和 7.2 上保持稳定；切换到无法运行的配置时，正在工作的隧道不受影响。
  [VPN](VPN)
* **安装器：** 写入 SD 卡或内置存储时卡住会被察觉并报告，且启动镜像写入后会回读校验。
  [Installation](Installation)
* **内核：** 5.4 带 `NFT_QUEUE` 重新构建；6.18.56 和 7.2.10 带热区模块。[Kernels](Kernels)

## v2026.10.22 新功能

2026-10-22 发布的版本（先以预发布形式推出，有板子跑过之后转正）。仍以修复为主。它带来的变化，以及
延伸阅读：

* **发送短信不再以 `SMS FAILED: CODE:600` 失败**——在那些拒绝每次提交的网络（中国广电；issue #176）上：
  现在发送是一次完整的 AT 事务，从建立到提交之间没有任何其他东西能插进来使用调制解调器，且每次发送前
  SMSC 会原样写回调制解调器；OpenWrt（`openf50-sms` 和面板）和 Ubuntu（`sms`）上都如此。
  [SMS](SMS)、[Troubleshooting](Troubleshooting)
* **面板的短信页面保留发送结果：** 以前慢速发送会在 30 秒后随请求一起被杀掉（操作日志里出现
  `sms_send - killed`）。现在发送在后台运行，页面会跟踪它，刷新后也如此。[Troubleshooting](Troubleshooting)
* **F50 上不再有 `mmc1` 寄存器转储**（6.18 和 7.2 上）：空 SD 卡槽现在有了真正的卡检测（EIC 控制器的
  六个 bank 全部映射），不再有人轮询它（issue #181）。[Troubleshooting](Troubleshooting)、[Kernels](Kernels)
* **Magisk zip：已知密码。** zip 安装的系统使用镜像自带的密码：Ubuntu 的用户 `ubuntu` 密码为 `ubuntu`，
  OpenWrt 的 `root` 在你设置之前没有密码；`OPENF50_PASSWORD` 仍可设置你自己的密码。不再有随机密码，
  密码说明里也不含秘密（issue #167）。
  [Installation](Installation#installing-from-android-with-a-magisk-zip-no-computer)
* **没有 VPN 模块就没有 VPN 区块：** LuCI 的 VPN 菜单、Cockpit 页面的 VPN 标签页和工具包的 VPN 条目，
  只有在运行过 `openf50-extra install vpn` 之后才出现。[VPN](VPN)
* **内核：** 5.4 不变；6.18.56 和 7.2.10 带卡检测修复重新构建。[Kernels](Kernels)

## v2026.10.21 新功能

2026-10-21 发布的版本（先以预发布形式推出，有板子跑过之后转正）。大部分是修复。它带来的变化，以及
延伸阅读：

* **F50：可以选择内置 SIM** 代替卡槽里的卡：`openf50-sim select internal`（或 LuCI 中 wan 接口的
  **SIM source** 字段），使用该卡自己的 APN。下次启动生效，外部卡仍是默认，不会向调制解调器或 SIM
  写入任何东西。
  [docs/SIM-SELECTION.md](https://github.com/dikeckaan/openf50-linux/blob/main/docs/SIM-SELECTION.md)
* **内核 5.4 不再在网络命名空间消失时 panic**（Docker 容器、沙箱；issue #103）。[Troubleshooting](Troubleshooting)
* **Wi-Fi 驱动可以卸载了**（6.18 和 7.2 上）：以前 `rmmod sprd_wlan_combo` 会让设备崩溃
  （issue #146）。[Troubleshooting](Troubleshooting)
* **更安静的日志：** Wi-Fi 驱动的例行行（`sc2355_dump_survey`、`bssid not found`、`data len is`……）
  在所有内核上不再以错误级别出现在 `dmesg` 和 `logread` 中（issue #140）。[Troubleshooting](Troubleshooting)
* **`openf50-update` 一次只跑一个：** 期间启动的第二次运行会被拒绝，并指出第一个的 pid。[Updating](Updating)
* **内核：** 5.4 带上述两个修复重新构建；6.18.56 和 7.2.10 带重建的模块。[Kernels](Kernels)

## v2026.10.20 新功能

2026-10-20 发布的版本（先以预发布形式推出，有板子跑过之后转正）。它新增的内容，以及延伸阅读：

* **更新保留你自己安装的软件包**（`apk add`、`apt install`）：它们会在首次启动时回来，连同它们的设置
  和服务的启用状态；更新后面板会在 System > Packages 下显示结果。[Updating](Updating)
* **控制面板新增 VPN 区块**（Overview、Profiles、Subscriptions、Engines、Settings、Logs）、**System >
  Terminal**（浏览器里的 root shell，仅限 LAN）、首页上带速率的 Wi-Fi 客户端列表、电源页面的原因说明
  本地化，且 AT 命令卡住时不再冻结：在 OpenWrt 上一条 AT 命令现在只需 0.13 秒，而不是一秒。
  [Control Panel (LuCI)](Control-Panel-(LuCI))
* **Ubuntu 的网页面板：** Cockpit 加一个 OPENF50 页面，作为 `panel` extra。
  [Control Panel (LuCI)](Control-Panel-(LuCI)#a-web-panel-on-ubuntu-cockpit)
* **VPN 模块 v2.0.0：** 核心加引擎 extras（`vpn-xray`、`vpn-singbox`、`vpn-mihomo`、`vpn-dae`）、订阅，
  以及 IPv6 防护，让不承载 IPv6 的隧道旁什么都不泄漏。[VPN](VPN)
* **内核 6.18.56 和 7.2.10**，带 BTF 和 dae 需要的 eBPF 钩子。[Kernels](Kernels)
* **U30 Air：** 0-100 % 的充电上限（`openf50-power charge-limit N`），以及在提供 1.5 或 3 A 的 Type-C
  端口上更快充电（主线内核）。[Hardware Notes](Hardware-Notes)
* **热点不再落在 DFS 信道上**（以前在那里会启动失败）。[Wi-Fi Hotspot and Client](Wi-Fi-Hotspot-and-Client)
* **经 USB 连到 Linux 的 adb**，默认开启且对所有电脑开放：任何有数据线的人无需密码即可得到 root shell。
  用 `sudo openf50-usb adb auth keys`（仅限授权的密钥）或 `sudo openf50-usb adb off` 关闭。
  [Installation](Installation#adb-to-linux)
* **安装器会复制启动链**：Android 更新后，把 Android 槽位的启动链复制到 Linux 槽位（issue #86）。
  [Installation](Installation#the-boot-chain-of-the-linux-slot)
* **加固：** Android 调制解调器守护进程在自己的账户（`openf50vnd`）下运行，`/dev` 里不再有任何东西属于
  登录用户；`sms delete` 只向调制解调器发送消息索引。[Hardware Notes](Hardware-Notes)、[SMS](SMS)

**你失去：** 什么都不失去。这些盒子上的 Android 本来就没有屏幕、没有扬声器，也没有 HDMI；Linux 拿走的
只是你"不在口袋里放一台 5G Linux 服务器"的最后借口。安装它不花你任何东西；不试试才让你失去这台服务器。

* **Android 保留。** 两个系统同一时刻只运行一个，重启即可在两者之间切换。
* **硬件保持原样，** 无论哪个系统：无屏幕输出（USB-C 的 HDMI 不工作），无扬声器或麦克风（带音频的
  通话仍在开发中），2 GB 内存约 1.4 GB 可用，因为其余部分归调制解调器。

## 业余项目，风险自负

这是一个实验性的业余项目。它不是产品，没有支持热线，并且**不提供任何形式的担保**。Root 和解锁设备
**不是**本项目的一部分，由你自行承担风险。对手机级设备进行写操作可能让它无法使用；请做好备份，不要在
你承受不起损失的设备上安装。这里的一切均未得到 ZTE、Unisoc 或任何运营商的认可。请阅读
[README 中的完整声明](https://github.com/dikeckaan/openf50-linux#a-hobby-project-at-your-own-risk)。

## 链接

* 源代码和 README：https://github.com/dikeckaan/openf50-linux
* 发布包（预构建镜像）：https://github.com/dikeckaan/openf50-linux/releases
* VPN 模块：https://github.com/dikeckaan/mu300-linux-vpn
* 深度技术笔记：[docs/FINDINGS.md](https://github.com/dikeckaan/openf50-linux/blob/main/docs/FINDINGS.md)
* Issues：https://github.com/dikeckaan/openf50-linux/issues
