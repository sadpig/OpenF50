# Glossary

每个词先用大白话解释，再说它对本设备意味着什么。按主题分组。

## 设备和它的内脏

**SoC（片上系统）：** 把处理器、图形、调制解调器等装进一颗芯片，像大脑和心脏合为一体。*这里：* Unisoc T760。

**Unisoc T760 / UMS9620：** 同一颗芯片的两个名字，Unisoc 制造。*这里：* F50 和 U30 Air 都把它用在
`ums9620_2h10_feimao` 板型上。U30 Pro 用另一款芯片（UMS9632），不受支持。

**调制解调器（Modem）：** 和移动网络对话的部分，像一部没有屏幕的手机。*这里：* 它需要几个 Android 程序
（`modem_control` 和它的朋友们），由 Linux 在沙箱里运行。

**eMMC：** 内置存储芯片，像焊死的存储卡。*这里：* 64 GB 设备上约 58 GiB；Linux 使用没有分区认领的部分。

**分区（Partition）：** 存储上一块有名字的围栏区域，像房子里的房间。*这里：* Android 有很多（boot、
system、userdata……）；Linux 分不到一间，它住在它们后面没围栏的空地里。

**分区表（GPT）：** 标明每个分区起止位置的地图。*这里：* 安装器从不改它，除非你在 32 GB 变体上选择收缩
`userdata`。

**userdata：** Android 放应用、设置和文件的分区。*这里：* 它整体加密，所以 Linux 不能把文件放在里面；
在 32 GB 变体上它占满整盘。

**misc：** 一个极小的分区，引导加载器在这里记笔记，比如启动哪个槽位、还剩几次尝试。*这里：* 安装器写入
它的 32 字节，告诉引导加载器试试 Linux。

**OpenCL / GPU：** GPU 是图形处理器；OpenCL 让程序用它做数值计算。*这里：* Mali-G57 在没有屏幕的情况下
运行 OpenCL 3.0。

**KVM：** Linux 快速运行虚拟机的功能。*这里：* `/dev/kvm` 在三个内核上都存在。

**zram：** 放在内存里的压缩交换空间，让内存装下更多。*这里：* `openf50-zram` 添加占内存一半的 lz4 zram。

**OTG / USB host：** 正常情况下设备是你电脑 USB 上的"客人"；host 模式下它是"主人"，你可以往它上面插东西。
*这里：* U30 Air 在主线内核上可以做 USB host（`sudo openf50-usb host`）；F50 的口是电源，所以不行。

## 启动

**引导加载器（LK）：** 上电后第一个运行的小程序，决定启动什么。*这里：* Unisoc 的 LK 根据 `misc` 里的
笔记挑选槽位。

**槽位（A/B）：** 设备有两份启动分区，A 和 B，这样可以在一个上试更新而另一个保持安全。*这里：* Android
用一个槽位；Linux 的启动镜像进另一个。

**启动镜像（Boot image）：** 一个包裹，装着内核和一个小启动程序（initramfs），由引导加载器加载。
*这里：* Linux 启动镜像由你设备自己的 Android 启动镜像加本项目的内核构建而成。

**内核（Kernel）：** 操作系统的核心，负责和硬件对话。*这里：* 你在 5.4、6.18 或 7.2 中选择
（[Kernels](Kernels)）。

**厂商内核 vs. 主线内核：** 厂商内核是芯片厂商自己修改的 Linux；主线是 kernel.org 的官方 Linux。
*这里：* 5.4 是厂商内核，6.18 和 7.2 是带本项目补丁的主线。

**LTS（长期支持）：** 能获得多年修复的版本。*这里：* Ubuntu 24.04/26.04 LTS 和 Linux 6.18 LTS。

**initramfs：** 启动镜像里的一个微型临时系统，在真正的系统启动前做好一切准备。*这里：* 它加载驱动、
找到 Linux 文件系统（SD 卡或空闲 eMMC 空间）并统计失败启动次数。

**试启动（Trial boot）：** 以试用状态启动某个东西：如果它没有报告自己健康，就不算成功。*这里：* 每次
Linux 启动都必须在 USB 网络和 SSH 起来约 30 秒后由 `openf50-boot-ok` 确认。

**回退（Fallback）：** 自动回到安全的选项。*这里：* 连续 N 次 Linux 启动未获确认（1-6，默认 5）后，
设备启动 Android。

**回滚（Rollback）：** 撤销一次更新。*这里：* `openf50-update rollback`（系统）和 `rollback-boot`
（内核和启动镜像）。

## Android 侧

**Root：** Android 上的完全管理员权限。*这里：* 安装前必须具备；如何获取不属于本项目。

**解锁（Unlock）：** 允许引导加载器启动出厂时没有的软件。*这里：* 设备必须已经能启动修改过的 Android
启动镜像。

**Magisk：** 流行的 Android root 工具，可安装"模块"。*这里：* 安装器添加一个模块，其 Action 按钮
（或 `su -c openf50-linux`）启动 Linux；发布包也附带从设备直接安装 Linux 的 Magisk zip。

**adb：** Android Debug Bridge，电脑上经 USB 与 Android 设备对话的程序。*这里：* 安装器使用它；Linux
也提供它，默认开启且对所有电脑开放，root shell 无密码（`sudo openf50-usb adb auth keys` 只让你授权过
密钥的电脑进入，`sudo openf50-usb adb off` 关闭它）。

**USB 调试：** 让 `adb` 能连上的 Android 设置。*这里：* 必须开启。

## Linux 和系统

**发行版（Distribution）：** 一套完整的 Linux 系统：内核加程序再加安装更多程序的方式。*这里：* 提供
Ubuntu 和 OpenWrt。

**Ubuntu：** 广泛使用的通用 Linux 发行版，用 `apt` 装软件。*这里：* 24.04 LTS（默认）或 26.04 LTS
（需要主线内核）。

**OpenWrt：** 为路由器而生的 Linux 发行版：小巧、专注网络。*这里：* 25.12，纯净版或带 OPENF50 控制面板。

**LuCI：** OpenWrt 的网页界面。*这里：* 在 http://192.168.77.1（U30 Air：.78.1）。

**UCI：** OpenWrt 的设置系统（`uci set …; uci commit`）。*这里：* 更新保留你的 UCI 配置。

**rootfs / 文件系统：** 一个系统栖身的目录和文件树。*这里：* 每个系统是 Linux 磁盘上的一个目录
（`/ubuntu`、`/openwrt`、`/openwrt-luci`）。

**ext4：** Linux 在磁盘上组织文件的标准方式。*这里：* Linux 磁盘是 ext4，卷标 `openf50root`（内置）
或 `openf50sd`（SD 卡）。

**SSH：** 通过网络在另一台电脑上敲命令的安全方式。*这里：* `ssh ubuntu@192.168.77.1`。

**串口控制台：** 纯文本连接，网络不通时也能用。*这里：* 走同一条 USB 线，macOS 上
`screen /dev/cu.usbmodem* 115200`。

## 网络

**热点 / 接入点（Hotspot / access point）：** 设备创建给别人加入的 Wi-Fi 网络。*这里：* 5 GHz 或
2.4 GHz，一次一个。

**Wi-Fi 客户端 / station：** 设备加入别人的 Wi-Fi，像手机那样。*这里：* `wifi-client`；射频要么做热点
要么做客户端，启动时决定。

**WPA2 / WPA3 / SAE：** Wi-Fi 密码安全标准；SAE 是 WPA3 使用的握手。*这里：* 驱动没有 SAE，所以仅 WPA3
的网络无法加入；WPA2 和混合模式可以。

**NCM / ECM / RNDIS：** 让 USB 设备在电脑上显示为网卡的几种方式。*这里：* NCM 是默认，ECM 是后备，
RNDIS 可选。

**LTE：** 4G 移动数据。

**5G NSA / EN-DC：** "非独立组网"5G，以 4G 连接为锚点再叠加 5G；EN-DC 是这种组合的名字。*这里：* 移动
数据跑在 5G NSA 或 LTE 上；面板可以锁 EN-DC。

**频段锁（Band lock）：** 告诉调制解调器只用某些频段或小区。*这里：* 在面板的 Network locks 里；存在
调制解调器里，所以在 Android 下也同样生效，直到重置。

**APN：** 进入运营商数据网络的"门"的名字。*这里：* 留空即使用 SIM 卡自己定义的那个。

**PDP 上下文：** 调制解调器用 APN 与运营商建立的数据会话。*这里：* `OPENF50_PDP_TYPE` 在 Ubuntu 上设置
它的类型。

**AT 命令：** 与调制解调器对话的短文本命令（以 `AT` 开头）。*这里：* 面板有一个带防护的 AT 终端；所有
工具通过 `openf50-atd` 共用一条通道。

**SMS / PDU：** 短信；PDU 是调制解调器使用的原始编码形式。*这里：* `sms` 用 PDU 模式，因为文本模式会
弄乱某些发送方。

**USSD：** `*101#` 这类向运营商查余额的短码。*这里：* `sudo openf50-ussd '*101#'`。

**DHCP：** 设备加入网络时自动获得地址的方式。*这里：* 设备给它的客户端分发地址。

**DNS：** 互联网的电话簿，把名字变成地址。

**IPv6：** 较新的一种互联网地址。

**RA（路由器通告）：** 一种 IPv6 消息，路由器在其中告诉设备"这是网络，以及这样上互联网"。*这里：* 带
控制面板的 OpenWrt 把运营商的 RA 中继到 LAN。

**NAT / NAT66：** 多台设备共享一个公网地址；NAT66 是 IPv6 版本。*这里：* 客户端借此共享移动连接。

**TTL：** 每个数据包里的一台路由器减一的计数器。*这里：* `openf50-ttl set 64` 为移动数据固定它。请先
查看运营商条款。

## VPN

**VPN：** 一条通往另一台服务器的受保护隧道，你的流量从里面走。*这里：* 可选的 `openf50-vpn` 模块。

**Kill switch（断流开关）：** 一条规则：VPN 断开时阻断所有流量，什么都不泄漏。*这里：* `openf50-vpn`
中默认开启。

**WireGuard：** 现代、快速的 VPN，内置于 Linux 内核。*这里：* 在主线内核上可用。

**OpenVPN：** 较老、广泛使用的 VPN 程序。*这里：* 装系统的 OpenVPN 包即可使用 `.ovpn` 配置。

**Xray / sing-box / mihomo / dae：** 代理引擎，支持 VLESS、VMess、Trojan、Shadowsocks 等协议、Clash
风格配置，以及（dae）运行在内核里的 eBPF 代理。*这里：* VPN 模块挑选会说你的配置的引擎；从 v2.0.0 起
每个引擎是一个 extra（`vpn-xray`、`vpn-singbox`、`vpn-mihomo`、`vpn-dae`），且 dae 需要 v2026.10.20 或
更新的 6.18 或 7.2 内核。

**BTF / eBPF：** eBPF 让程序安全地运行在内核里；BTF 是这类程序找路所需的类型信息。*这里：* 主线内核从
v2026.10.20 起携带 BTF，以便 dae 运行。

**DFS 信道：** 雷达也在用的 5 GHz Wi-Fi 信道（52-144）；接入点在那里必须先监听雷达。*这里：* Wi-Fi
驱动做不到，所以热点绝不使用（你选的 DFS 信道会被替换成 36 或 149）。

**Cockpit：** Ubuntu 的网页控制台（终端、日志、服务、网络）。*这里：* Ubuntu 上可选的 `panel` extra，
带一个用于调制解调器、短信、VPN 和电源的 OPENF50 页面。

**订阅（VPN）：** VPN 提供商给你的 URL，能产出一组配置。*这里：* `openf50-vpn subscription add`，手动
或按计划刷新；也在面板的 VPN 菜单里。

**Tailscale：** 用于到达你自己设备的网状 VPN。*这里：* 它的流量默认走当前隧道。
