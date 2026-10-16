# Control Panel (LuCI)

**一句话概括：** 在 OpenWrt 上你通过网页管理设备；`openwrt-luci` 系统额外提供 **OPENF50 控制面板**——
一个面向 5G 调制解调器、SIM、短信和电池的仪表盘。

**通俗版说明：** LuCI 就是你可能在家用路由器上见过的路由器设置页面。OPENF50 面板是为这台设备定制的一
组额外页面：信号多强、用哪些频段、你的短信、电池。

## 打开它

在连接到设备（USB 或它的 Wi-Fi）的电脑或手机的浏览器里：

* F50 / OPENF50：**http://192.168.77.1**
* U30 Air：**http://192.168.78.1**

以 `root` 登录，密码是安装时你选的那个。

## 纯净 OpenWrt vs. 控制面板

| | OpenWrt（`openwrt`） | 带面板的 OpenWrt（`openwrt-luci`） |
|---|---|---|
| LuCI（网络、无线、防火墙、软件包） | 有 | 有 |
| OPENF50 页面（仪表盘、Cellular、VPN、Power、CPU、Languages、Packages、Terminal） | - | 有 |
| 主题 | LuCI 默认 | Aurora（Bootstrap 保持安装） |
| 来自运营商的 IPv6 | 前缀扩展 | 中继（路由器通告和 NAT66） |
| Magisk zip | 有 | 有（v2026.10.18 起） |

安装时选择（"Which OpenWrt?" -> 2，或 `OPENF50_OPENWRT=luci`），或在已安装的设备上用
`sudo openf50-os openwrt-luci` 切换并重启（该系统必须已安装）。

## 面板的页面

* **状态仪表盘：** 实时射频读数（信号、频段、小区、温度）、运营商名称、移动数据状态和当前上下行速率，
  每秒刷新；Wi-Fi 客户端及其速率、连接时长、名称和地址；运营商的 DNS 服务器和连接数；U30 Air 上还有
  电池：电量、是否在充电、功率瓦数。调制解调器忙时页面保留上一次读数并显示其年龄。首页还有
  **Switch to Android** 和 **Lock Linux**（见 [Going Back to Android](Going-Back-to-Android)）。
* **Cellular > Network locks：** 网络模式、频段、小区和 EN-DC 锁，跨重启保持并在启动时重放。
  **Reset all to automatic** 清除它们。锁存在调制解调器里，所以在 Android 下也同样生效。
* **Cellular > SMS：** 读取、发送和删除消息（要记住的一条规则见 [SMS](SMS)）。
* **Cellular > SMS forwarding：** 把收到的消息转发到 webhook、Telegram 聊天或另一部手机（见
  [SMS](SMS#sms-forwarding)）。
* **Cellular > Data usage：** 按天和按账期统计的移动数据，带重置日和月度上限（`openf50-traffic`，见
  [Mobile Data and APN](Mobile-Data-and-APN#data-usage)）。
* **Cellular > AT terminal：** 走系统所用同一通道的带防护 AT 命令。扫描、改动射频、APN 或 SIM、或写入
  会延续到 Android 的设置的命令，会先解释清楚，点击后才发送；网络扫描在后台运行，页面会跟踪它。
* **VPN**（独立菜单，配合 [VPN](VPN) 模块 v2）：**Overview**（状态、活动配置、引擎、隧道、运行时长、
  实时速率、按钮背后的出口 IP、Start/Stop/Restart、断流开关和需确认的 IPv6）、**Profiles**（从分享
  链接、粘贴文本、文件或 URL 添加；测试延迟；重命名、查看和编辑配置、删除）、**Subscriptions**（产出
  配置的 URL，手动或每 6 到 168 小时刷新）、**Engines**（Xray、sing-box、mihomo、dae：安装、更新、
  移除；在线或从上传的 tarball 安装，按模块发布包校验）、**Settings**（断流开关、IPv6、绕过隧道的
  LAN 网段、Tailscale、DNS、每配置选项）和 **Logs**。没有模块时每个页面都会提议安装它。
* **Cellular > TTL：** 移动数据的固定 TTL（`openf50-ttl`）。
* **Cellular > Device management：** USB 角色（device 或 host）、USB 网络模式（NCM、ECM 或 RNDIS，下次
  启动生效），以及可加入 LAN 网桥的 host 模式网卡。
* **Cellular > Adapter settings：** 面板如何到达调制解调器（AT 后端、串口、自定义适配器）。
* **System > Languages：** 界面语言，以及 lang extra。
* **System > Power：** 当前电源配置文件及原因（以你的语言显示）、电池、电源和充电器输入电流、三个配置
  文件的空闲设置、省电阈值和充电上限（0-100 %，U30 Air）。
* **System > CPU：** CPU 配置文件：省电、均衡（默认）或性能（`openf50-cpu`）。它从不碰电压，且热保护
  在每个配置文件下都照常掌管。下方为只读的内核热区：温度、触发点和绑定到它们的冷却设备及其当前状态
  （主线内核上原生的 `soc-thmzone`，70/85 °C 被动、110 °C 临界，在 85 °C 对三个簇降频）。
* **System > Packages after an update：** 你自己安装过的软件包以及更新对它们做了什么（见
  [Updating](Updating#packages-you-installed-yourself)）。
* **System > Terminal：** 浏览器里的 root shell（[ttyd](https://github.com/tsl0922/ttyd)）。它只监听
  LAN 地址（端口 7681；蜂窝侧永远够不到），且只为页面为你已登录的面板会话取得的一次性令牌打开 shell，
  所以没有第二个密码可猜。15 分钟无活动后关闭（`uci set ttyd.openf50.idle=<秒数>`；0 表示永不）。
  通过 https 打开的面板会在单独标签页里打开它。**Terminal settings** 是 ttyd 自己的页面；那里的
  `enable 0` 会移除终端。

从 v2026.10.20 起，一条卡住的 AT 命令不再拖垮面板：每次调制解调器读取都有期限，页面逐个发送调用并在
失败后退避，且 Device 页面保留面板近期调制解调器操作的日志（只有名称和耗时）。在 OpenWrt 上一条 AT
命令约需 0.13 秒，而不是整整一秒。

## Ubuntu 上的网页面板（Cockpit）

Ubuntu 没有 LuCI，但可以有 [Cockpit](https://cockpit-project.org/)——Ubuntu 自己的网页控制台（终端、
日志、服务、网络、存储、账户）——加一个 **MU300** 页面：移动网络（运营商、技术制式、注册状态、信号）、
移动数据开关、流量统计和实时速率、电池和温度、短信、VPN（开关、配置）、CPU 配置文件和电源状态、热点
名称和密码、加入 Wi-Fi 网络，以及更新。网络锁仍是 OpenWrt 面板独有的功能。

```sh
sudo openf50-extra install panel                                           # Cockpit from Ubuntu's archive (about 12 MB)
sudo openf50-extra install panel --from openf50-extra-panel-offline.tar.gz   # offline: the release's file, Cockpit inside
sudo openf50-extra remove panel
```

安装器也会问它（默认否）。然后打开 `https://192.168.77.1:9090`（U30 Air：`.78.1`），接受 Cockpit 自己的
证书并以 `ubuntu` 登录；需要 root 的页面点 "Turn on administrative access"。Cockpit 只监听 LAN（USB 和
热点），防火墙反正也对蜂窝侧关闭它，root 不能登录，会话闲置 15 分钟后结束。界面有英语、土耳其语和
中文。

## 语言

两个 OpenWrt 系统开箱即说**英语、土耳其语和简体中文**。界面以英语启动：在 System -> System ->
Language and Style 下切换，`openwrt-luci` 上在 System -> Languages 下。更新保留你的选择。

**lang extra**（约 2 MB）为 LuCI 增加 40 种语言、为面板增加其中 29 种：

```sh
openf50-extra install lang                                               # from the release of this system
OPENF50_EXTRA_FILE=/tmp/openf50-extra-lang.tar.gz openf50-extra install lang  # from a file, offline
openf50-extra lang                                                       # which languages are offered
openf50-extra remove lang
```

面板除土耳其语和中文外的翻译是机器（AI）翻译；欢迎指正（见 [Contributing](Contributing)）。

## 致谢

面板是 kanoqwq 的作品（[kanoqwq/openf50-linux](https://github.com/kanoqwq/openf50-linux)，分支
`clean-tf-7.2`），移植到这里时翻译重写为标准 LuCI 目录。主题是 eamonxg 的
[Aurora](https://github.com/eamonxg/luci-theme-aurora)。应用自己的说明：
[openwrt/luci-app-openf50/README.md](https://github.com/dikeckaan/openf50-linux/blob/main/openwrt/luci-app-openf50/README.md)。

## OpenWrt 提醒

* 永远不要 `sysupgrade`，也不要刷 OpenWrt 固件镜像。
* `apk upgrade` 没问题，除了 `kernel` 和 `kmod-*` 软件包。
* 在 5.4 内核上，LuCI 里保存的防火墙改动手在旧发布包上可能需要
  `nft delete flowtable inet fw4 ft; fw4 reload`（或重启）；v2026.10.17 修复了 5.4 上开启流量卸载时
  的 `fw4 reload`/`restart`。
