# Troubleshooting

**通俗版说明：** 大多数问题都以同样安全的方式收场：设备回退到 Android，你再试一次。下面是已知问题、
成因和解决办法。如果你的问题不在这里，收集日志并[开一个 issue](https://github.com/dikeckaan/openf50-linux/issues)。

## 先做这些

* 上电后等**两分钟**；首次启动很慢。
* 用一根**好的 USB 数据线**，直接插到电脑上。
* 确认用的是**正确的地址**：`192.168.77.1`（F50）或 `192.168.78.1`（U30 Air）。
* 网络不通时 USB 串口控制台依然可用：macOS 上 `screen /dev/cu.usbmodem* 115200`。
* 回退到 Android 之后，用电脑上的 `tools/collect-logs.sh` 收集日志。

## 安装后设备没回来

等两分钟。如果还是没反应，拔了重插。每一次没完成的启动都会计数，连续 5 次（或你选择的次数）之后设备
会启动 Android。然后运行 `tools/collect-logs.sh`，带着结果开 issue。

## 在 6.18 内核上无缘无故回到 Android

一块板子上大约每 20 次启动有 1 次会在最初几秒卡死，然后设备回退到 Android（这可能需要约 20 分钟）。
用 `su -c openf50-linux` 或 Magisk 模块的 Action 按钮再次启动 Linux。如果反复发生，试试 7.2 或 5.4：
`sudo openf50-update kernel 7.2`。
[FINDINGS 31m](https://github.com/dikeckaan/openf50-linux/blob/main/docs/FINDINGS.md#31m-hard-hangs-in-the-first-seconds-under-618-open)

## 更新后回到 Android

用旧启动镜像时，Linux 的一次崩溃或重启就会让设备回到 Android。用 `su -c openf50-linux` 再次启动
Linux，然后更新（见 [Updating](Updating#coming-from-a-very-old-release)）。如果 Linux 再也起不来，
从电脑运行 `./install.sh` 并选择 **update**：它会写入新的启动镜像并保留你的数据。

## 电脑看得到设备但拿不到地址（macOS）

macOS 在锁屏时不会配置它从未见过的网络接口。每台设备有自己的 USB MAC 地址，所以第一次插入某台设备时
（或一次带来新地址的更新之后），**解锁 Mac**，接口就会出现。F50 和 U30 Air 同时插着时，它们分别是
`192.168.77.1` 和 `192.168.78.1`；两台同型号的设备需要 `/etc/openf50/lan.conf` 来区分。

## 没有网络

先确认 SIM 卡有**流量套餐**，然后运行 `sudo mobile-data status`。没有套餐的表现就是连接不停地掉。
除非运营商要求，否则 APN 留空（[Mobile Data and APN](Mobile-Data-and-APN)）。

## 5.4 内核上的 OpenWrt：没地址、没网页、谁也连不上热点

v2026.10.13 之前的发布包：防火墙的启动规则集没有 LAN 的规则，而在 5.4 上本该补上它们的重载总是失败。
**从 v2026.10.13 起已修复**；请更新。在受影响的发布包上，通过 USB 串口控制台（`ttyGS0`，root shell）
登录并运行：

```sh
nft delete flowtable inet fw4 ft; fw4 reload
```

[FINDINGS 38c](https://github.com/dikeckaan/openf50-linux/blob/main/docs/FINDINGS.md)

## 安装器几分钟不打印任何东西且设备发烫

在分区表结束于磁盘末尾的设备上（32 GB 变体，以及 `userdata` 后面没有空隙的 F50），读过内置存储末尾的
读取永远不会返回。**从 v2026.10.13 起已修复。**重启设备以结束卡住的读取，然后用当前的安装器安装
（它启动时会从 GitHub 自我更新）。
[FINDINGS 38a](https://github.com/dikeckaan/openf50-linux/blob/main/docs/FINDINGS.md)

## `--check` 报告没有空闲空间

你很可能拿到的是 **32 GB 变体**。用 SD 卡（F50），或让安装器收缩 `userdata`（实验性，会清空 Android
的数据）。见 [Installation](Installation#the-32-gb-variant)。如果数字既不像 64 GB 也不像 32 GB 设备，
带着 `--check` 的输出开 issue。

## `--check` 说空闲空间"不是空的"

有东西写进了未分区的区域。安装会覆盖它，安装器会让你输入 `overwrite`。如果你不确定那里是什么，停下来
在 issue 里问。

## 我忘了密码

想退出并不需要登录（除非 Linux 被[锁定](Going-Back-to-Android#locked-linux)）：

1. **回到 Android：** 设备上电约十秒后拔掉，再插上，连续重复你的失败启动计数次（默认 5 次）。设备
   随后会回退到 Android。
2. **从电脑设置新密码**，无需启动 Linux：
   ```sh
   tools/reset-password.sh            # ubuntu, openwrt or both
   ```
   它从 Android 挂载 Linux 文件系统并重写密码，保留你的所有数据。
3. 用 `su -c openf50-linux`（或 `boot/android-boot-linux.sh work/boot-linux-slotb.img`）再次启动
   Linux；如果 Linux 是默认系统，直接重启即可。

重新运行 `./install.sh` 并选择 **update** 也会保留你的数据并设置你输入的密码。

## 加入 Wi-Fi 网络失败

* 仅 WPA3 的网络无法加入（驱动没有 SAE）。把路由器切到 WPA2/WPA3 混合模式。
* 热点开着时，`wifi-client connect` 会保存网络并要求重启。
见 [Wi-Fi Hotspot and Client](Wi-Fi-Hotspot-and-Client)。

## 内核警告不在 `journalctl -k` 里

在 Ubuntu 上它们在 `journalctl -t kernel` 里（只有警告和错误，从每次启动的开头开始）。其余都在
`dmesg` 里。重复出现的厂商消息会被 `/etc/openf50/kmsg-ignore` 过滤掉。

## 网站以为我在另一个国家

设备没有 GPS；网站根据 IP 地址猜位置，而移动运营商和 VPN 服务器常常看起来像另一个城市。

## 下载慢

GitHub 的 CDN 在某些地区对单连接限速。安装器已经用 8 个并行分块下载；设置 `OPENF50_FETCH_JOBS` 可以改
这个数，或用 `OPENF50_RELEASE_URL` 指向你自己的镜像。

## 更新时出现 "could not arm the Linux slot for a trial"

从 v2026.10.14 或更旧版本更新时无害：旧的 `openf50-next-boot` 不认识 `--trial`。回退到 Android 仍然
有效。

## U30 Air 插着电还掉电

v2026.10.11 及更早的主线内核（6.18、7.2）不开启充电。请更新（主线上的充电从 v2026.10.12 起可用），或
使用 5.4 内核。

## 热点在 52 到 144 之间的 5 GHz 信道上起不来

hostapd 以 `start_dfs_cac() failed` / `AP-DISABLED` 停止（v2026.10.18 及之前的发布包）。那些是 DFS
信道，而 Wi-Fi 驱动无法检测雷达。**从 v2026.10.20 起已修复：** 这样的信道会被替换成 36（或 149），
日志里有一行说明。在旧发布包上请选择 36-48 或 149-165，Ubuntu 上也可选 `auto`。
[FINDINGS 42](https://github.com/dikeckaan/openf50-linux/blob/main/docs/FINDINGS.md)

## 一条 AT 命令卡住后控制面板变空白

在 v2026.10.18 及之前的 `openwrt-luci` 上，一条卡住的 AT 命令能让每个页面空白几分钟，连电池卡片也不
例外，重启后也一样。面板的锁等待按整秒而不是十分之一秒计数（OpenWrt 的 `sleep` 不接受小数），且一些
页面在请求里直接读调制解调器。**从 v2026.10.20 起已修复**；那里页面会保留上一次读数并显示其年龄。
在旧发布包上只能等它过去，或重启 `rpcd` 和 `openf50-atd`。
[FINDINGS 40](https://github.com/dikeckaan/openf50-linux/blob/main/docs/FINDINGS.md)

## 发送短信失败：`SMS FAILED: CODE:600`，或面板操作日志出现 `sms_send - killed`

v2026.10.21 及之前，在一些网络上（中国广电，issue #176）调制解调器的 IMS 栈拒绝每次提交（URC 日志中
出现 `+SPIMSREASON: 1,512,"SMS FAILED: CODE:600 REASON:Busy Everywhere"`），而接收正常；且在
`openwrt-luci` 上，超过 30 秒的发送会随面板请求一起被杀，操作日志留下 `sms_send - killed`，消息是否
发出无从得知。**从 v2026.10.22 起已修复：** 发送是一次 AT 事务（从建立到提交通道一直被占用，没有其他
客户端能插进来），且每次发送前把调制解调器报告的 SMSC 原样写回，OpenWrt 的 `openf50-sms` 和面板以及
Ubuntu 的 `sms` 都如此；面板把发送放到后台并跟踪它，刷新后也如此。在旧发布包上可以自己写回 SMSC
（`openf50-at 'AT+CSCA?'`，然后 `openf50-at 'AT+CSCA="<它显示的值>",<类型>'`，Ubuntu 上加 `sudo`），
并在面板空闲时从 shell 发送（OpenWrt 上 `openf50-sms send NUMBER TEXT`，Ubuntu 上
`sudo sms send NUMBER TEXT`）。
[FINDINGS 46](https://github.com/dikeckaan/openf50-linux/blob/main/docs/FINDINGS.md)

## 5.4 内核上容器停止时设备重启

v2026.10.20 及之前，在 5.4 上，当两个网络命名空间同时存活、其中一个消失时（Docker 容器、沙箱、
`unshare -n`），内核可能在清理时 panic（调用栈里是 `xfrm_sysctl_fini`；issue #103）；设备重启，这样
几次之后就回退到 Android。**从 v2026.10.21 起已修复**；请更新。在旧发布包上一次只跑一个容器，或使用
从未有此 bug 的 6.18 或 7.2。
[FINDINGS 44](https://github.com/dikeckaan/openf50-linux/blob/main/docs/FINDINGS.md)

## 卸载 Wi-Fi 驱动时设备崩溃（6.18、7.2）

v2026.10.20 及之前，在 6.18 或 7.2 上 `rmmod sprd_wlan_combo` 会在一秒内 panic（`__run_timers`：驱动在
已释放的内存里留了一个运行中的定时器；issue #146）。**从 v2026.10.21 起已修复。**在旧发布包上不要卸载
该模块；改为重启设备。
[FINDINGS 45](https://github.com/dikeckaan/openf50-linux/blob/main/docs/FINDINGS.md)

## 日志每隔几秒就充满 `sprd-wlan` 错误

诸如 `sc2355_dump_survey, idx 0`、`bssid not found, multicast?` 或 `data len is 251, skb need 576`
这样的行，以错误级别每隔六秒左右出现在 `dmesg` 和 `logread` 中（v2026.10.20 及之前的发布包）。它们
描述的是驱动的例行工作，不是故障（issue #140）。**从 v2026.10.21 起**它们是调试行，只有你要求时才
显示：`echo 'module sprd_wlan_combo +p' > /sys/kernel/debug/dynamic_debug/control`。旁边真正的错误
仍会记录。

## F50 上日志充满 `mmc1` 寄存器转储（6.18、7.2）

`mmc1: Got command interrupt 0x00000001 even though no command operation was in progress`，接着一段
16 行的 `SDHCI REGISTER DUMP`，在 SD 卡槽空着的 F50 上每隔几秒到几分钟出现在 `dmesg -l err` 中，见于
v2026.10.21 及之前的 6.18 和 7.2（issue #181）。主线的 EIC 驱动只映射了控制器六个 bank 中的三个，
卡槽的卡检测线找不到，于是卡槽被轮询代替：每一秒都在初始化一张不存在的卡，主机对一条无人应答的命令的
迟到回答连同转储一起被记录。**从 v2026.10.22 起已修复**：六个 bank 全部映射，卡槽有了真正的卡检测
（中断），空卡槽在插卡之前不再被打扰。这些转储是噪音，不是故障；在旧发布包上往卡槽里插张卡（有卡就
没有转储）或用 5.4——它从来没有过。U30 Air 没有卡槽。
[FINDINGS 31j](https://github.com/dikeckaan/openf50-linux/blob/main/docs/FINDINGS.md)

## U30 Air 在大功率 USB-C 端口上充电慢

v2026.10.19 及更早的主线内核从每个端口只取 500 mA。从 v2026.10.20 起它们读取端口提供的电流（1.5 或
3 A），最高以 2 A 充电。在 5.4 上由厂商栈决定。

## U30 Air 从充电器启动后一直黑屏

因插入充电器而开始的启动会一直保持**充电启动**状态（LED 闪烁，热点和调制解调器不工作），直到你按下
**Wi-Fi 键**。

## 不是 bug 的现象

* **USB-C 无屏幕输出**且**无声音**：硬件通路不存在（[Hardware Notes](Hardware-Notes)）。
* **5.4 上负载均值约 12：** 处于 D 状态等待的厂商内核线程被计入；CPU 大部分时间是空闲的。
* **约 1.4 GB 内存：** 其余部分被调制解调器固件保留。

## 永远不要

* 永远不要使用 OpenWrt 的 `sysupgrade`，也不要刷 OpenWrt 固件镜像。
* 永远不要公开发布你的备份文件夹或包含 IMEI 的日志。
