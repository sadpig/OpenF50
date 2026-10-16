导入自 kanoqwq/openf50-linux，分支 clean-tf-7.2，commit 35a1c55（PR #22 及之后）。此后在此处的修改：见 git log。

# luci-app-openf50

一个自包含的 LuCI 应用，面向 Unisoc 蜂窝设备。它提供仪表盘、实时射频读数、持久的网络/频段/小区/EN-DC 锁、带防护的 AT 终端和短信界面。设备管理页面控制 USB 角色和 gadget 网络策略，并列出主机侧 USB 网卡，可选将其加入 LAN 网桥。TTL 页面（蜂窝）设置经由移动数据离开的所有报文的 TTL（`openf50-ttl`，通过 `unisoc-modem/ttl` 适配器）。CPU 页面（系统）选择性能配置——省电、均衡或性能——它会设置 CPU governor 和各 cluster 的频率上限（`openf50-cpu`，通过 `unisoc-modem/cpu` 适配器）。它始终保持在硬件频率表之内，从不改变电压，所以内核在每种配置下仍会在其温度限值处降频。终端页面（系统）内嵌 ttyd：`rpcd/openf50term` 向持有 `luci-app-openf50-terminal` ACL 的 LuCI 会话发放一次性令牌（一次连接，60 秒），ttyd 的命令 `/usr/libexec/openf50-terminal-login` 只为该令牌打开一个 root 登录，别无其他，并在 `ttyd.openf50.idle` 秒无活动后关闭它。镜像为它配置 ttyd（`openwrt/luci-overlay/etc/config/ttyd`：仅 LAN 地址、origin 检查、`url_arg`）；软件包本身不安装 ttyd，此时页面会如实说明。

仪表盘跟随 LuCI 选择的语言。其颜色在 Aurora 存在时跟随它已有的令牌，否则跟随官方 Bootstrap 主题的亮/暗令牌。翻译是标准 LuCI 目录：JavaScript 中用英文消息 id，`po/<语言>/openf50.po` 为可编辑源。土耳其语和简体中文在镜像中；其他语言（除这两个之外的 `po/*`：机器/AI 翻译，欢迎纠正）在语言 extra 中（`openf50-extra install lang`，或系统下的语言页面），由 `openwrt/luci-languages.tsv` 命名。`lmo/` 不保存在源码树中；镜像构建用 `tools/po2lmo.py` 编译目录文件，这样在未加载仪表盘 JavaScript 的无关 LuCI 页面上，顶级菜单和子菜单也能保持翻译。

软件包不启动也不拥有调制解调器。平台相关的访问位于小型命令适配器之后，所以换一个 Unisoc OpenWrt 固件时 LuCI 和 RPC 代码不需要改动。

## 流量统计与实时速率

蜂窝 > 流量统计按天和按计费周期（可配置的重置日）显示移动数据，并带可选的月度上限：达到设定百分比时警告，且仅在开启时，到上限后关闭移动数据直到下个周期。页面与 `unisoc-modem/traffic`（openf50dash 的 `traffic_get`/`traffic_set`）通信，它运行平台的 `openf50-traffic`（`OPENF50_TRAFFIC_CMD`）；没有它页面会显示流量统计不可用。计数来自该命令，所以面板与其 CLI 始终一致；在 OPENF50 上它每分钟把接口计数器采样到 RAM 一次，很少写盘（见 `openf50-traffic`）。

仪表盘的下行/上行速率走自己的通道：每秒一次 rpcd `file` 读取 `/proc/net/dev`（无进程、无 AT），在浏览器端计时。这是读权限唯一命名的文件，旁边还有 `/proc/[0-9]*/net/dev`，因为 rpcd 检查它解析后的路径（`/proc/net` 是 `/proc/self/net`）。状态快照命名接口（`data_device`），并携带 openf50-traffic 的摘要供仪表盘的用量磁贴使用。

## VPN

顶级 VPN 菜单有六个页面（概览、配置、订阅、引擎、设置、日志），基于 VPN 模块的机器可读 CLI `openf50-vpn ... --json`（github.com/dikeckaan/mu300-linux-vpn，规范 `2026-10-11-engine-extras`，第 4 节）。它们的后端是第二个 rpcd 对象 `openf50vpn`（`/usr/libexec/rpcd/openf50vpn`），与 openf50dash 分离，因为经过它的东西含有秘密：分享链接、配置、订阅 URL 和 OpenVPN 密码通过 stdin 传给 CLI（来自 root 专属运行时目录中的 0600 文件），绝不出现在 argv 中，回复的任何内容也不记录日志。读取（状态、列表、设置、任务）在 ACL 的读权限中；每个改动、日志和配置明文都在写权限中。下载（引擎、模块、订阅、来自 URL 的配置）和对每个配置做一轮延迟测试作为同一个后台任务运行，有时间上限，由页面轮询。上传去 `/tmp/openf50-vpn-upload`（配置）和 `/tmp/openf50-vpn-extra.tar.gz`（extra 的 tar 包），这是 ACL 允许面板写入的仅有的两个路径，并在任何东西读取之前被移出 `/tmp`。没有模块时页面显示一张安装它的卡片（`openf50-extra install vpn`）。`tests/fixtures/fake-openf50-vpn` 代替 CLI，以便在没有设备时试用页面。

## AT 适配器

配置 `/etc/config/unisoc_modem`：

- `at_backend=openf50` 使用已有的 `openf50-at` 守护进程并沿用其锁。
- `at_backend=atinout` 使用配置的 `at_port` 和包内锁。仅在没有其他进程读取该 tty 时使用。
- `at_backend=custom` 运行 `at_command` 中的可执行文件。它收到两个参数：`TIMEOUT` 和完整的 `AT COMMAND`。已有 RIL/AT 守护进程的平台应通过此适配器暴露它，使每个客户端共享该守护进程的锁。
- `at_backend=auto` 依次优先 `openf50-at`、`atinout`、自定义命令。

短信页面使用 `sms_command`，其 CLI 契约是现有的 `openf50-sms` 接口：`list`、`show`、`send`、`delete` 和 `sync`。这把 SIM 存储细节挡在 LuCI 之外，并允许每个固件提供自己的适配器。`send` 以 `send --stdin NUMBER` 调用，文本在 stdin 上，所以消息绝不会成为命令行参数；只认识 `send NUMBER TEXT` 的适配器会把 `--stdin` 当作号码拒绝，什么都不发。在 openwrt-luci 上适配器是短信池（`openf50-sms`、`openf50-smsd`）：守护进程每 30 秒把 SIM 同步到 `/etc/openf50/sms-pool`，并把它从 SIM 读到的消息标记为已读，所以 `sms delete read`（系统自己的短信工具）会删掉 CLI 用户从未见过的消息。请从面板删除，或用 `openf50-sms delete`——它只在加 `--sim` 时才触碰 SIM。

网络接口和状态路径也在同一个 UCI 节中配置；网页代码不要求宿主固件提供 `sipa_eth0`、`wan`、`br-lan` 或 `/opt/openf50`。

## 持久锁

软件包拥有 `/etc/init.d/unisoc-modem-ui`。仅当存在已保存的锁且启用了自动应用时，它才在启动时拉起一个非阻塞的 procd worker。worker 每两秒探测选定的 AT 适配器，就绪后立即重放设置。它从不拖延 OpenWrt 启动，并在 `replay_timeout` 秒后停止，而不是永远轮询。带有 pre-radio 钩子的平台可以在 AT 启动前创建 `/run/unisoc-modem-early-hook-pending`。该文件存在期间，此 worker 不发送 AT 探测，以保护平台的首命令握手。平台在其开射频尝试后删除它；如果早期重放没有创建完成标记，worker 回退到正常的延迟重放。

便携式 worker 用一次有界的 SFUN 重启激活已保存的模式/频段/小区设置，随后拉起配置的数据接口。仅 EN-DC 的重放不需要协议栈重启，立即应用。做了有意的 pre-radio 集成的平台可以在 AT 握手之后、射频关闭期间从该钩子调用 `/usr/libexec/unisoc-modem/lock replay early`。早期重放在写完成标记之前读回已保存的字段。读回失败则延迟重放仍可用；成功的标记防止重复应用。`early` 故意不作为用户可选项，因为它只在平台射频序列的那个精确时刻才安全。

在平台有 `/opt/openf50/bin/mobile-data` 的地方，面板的射频开关、调制解调器复位，以及锁应用或延迟重放的 SFUN 重启，都在其射频锁下运行（`mobile-data radio-locked`），所以它们绝不会与拨号或看门狗的射频序列并行。射频开关和调制解调器复位在另一个序列持锁时回答 "busy"；锁应用最多等它两分钟。

## USB 设备管理

USB 角色每次启动默认为 device。页面可以立即切换；勾选 host 自动应用会让软件包的启动 worker 在每次启动时重新应用 host 模式。在无电池的 F50 上，插件直接把请求的角色写入 sysfs：USB 管理消失，外接网卡可能需要外部供电的 hub。U30 Air 使用 `openf50-usb` 及其充电器升压/VBUS 检查。其他硬件可以使用 sysfs 回退，或用接受 `host` 或 `device` 的平台专用可执行文件配置 `unisoc_modem.usb.role_command`。插件不得绕过已知平台的供电安全检查。

NCM/ECM/RNDIS 选择只在勾选"启用所选协议"时存入 `/etc/openf50/usb-net`（一行：`ncm`、`ecm` 或 `rndis`）。`boot/init` 选定根之后，从它选择启动的系统读取该文件；当它要求的函数与 gadget 绑定的不同时，init 在 `switch_root` 前重新绑定一次 gadget（内核命令行上的 `OPENF50_USBNET` 仍然优先）。在无法生成 RNDIS 的内核上 RNDIS 回退到 NCM，再到 ECM，所以保存的选择绝不会让系统失去 USB 网络。其他 OpenWrt 构建可以在自己的 gadget 设置点实现同样的一行契约。插件本身拥有策略和 UI，不拥有内核或 gadget。`once` 只在成功启动后、且 init 留下了 `/run/openf50/usb-net-applied`（该选择对那次启动生效）时才被消费；后续启动使用平台默认的 NCM。选择持久 host 模式会自动禁用 USB 网络自动应用。当前角色为 host 时，网络模式控件被禁用。无论 UI 状态如何，后端校验同样的规则。在 openwrt-luci 上，`boot/init` 把 RNDIS 暴露为带 ACM 控制台的单一 USB 配置，RNDIS 替换另一个网络功能；当设备同时提供 RNDIS 和 NCM 配置时，Windows 不会绑定复合 RNDIS 适配器。LAN 交接时，initramfs 的早期 DHCP 服务器被停止，它使用的地址从网桥端口移除，于是只有 `br-lan` 拥有它。

USB 网卡发现使用每个网络设备的 USB sysfs 父级。刷新时它尝试把发现的设备拉起。"添加到 LAN" 只把已验证的 USB 网卡加入配置的 LAN 网桥设备的 UCI 端口列表，提交 `network` 并重载网络。所选端口在 USB netdev 热插拔和 LAN ifup 时重新挂上，无需轮询守护进程或再次重载网络。该动作是幂等的，且只在 host 模式下可用。

## 构建

把本目录单独复制到任何兼容 OpenWrt buildroot 中的 `package/luci-app-openf50`，选择 `LuCI -> Applications -> luci-app-openf50`，正常构建。本目录之外的任何文件都不会被复制进软件包；平台相关的 AT 和短信实现只在运行时通过文档化的适配器发现。

源码树热安装（没有 `.ipk`/`.apk`）：把 `root/` 复制到 `/`，`htdocs/` 复制到 `/www/`，`lmo/` 复制到 `/usr/lib/lua/luci/i18n/`；然后让 `/etc/init.d/unisoc-modem-ui`、`/usr/libexec/rpcd/openf50dash` 和 `/usr/libexec/unisoc-modem/*` 适配器可执行；然后 enable/start `unisoc-modem-ui` 并重启 `rpcd`。只复制 `root/` 会留下可见的 LuCI 菜单，但 `/luci-static/resources/view/openf50/*.js` 会返回 HTTP 404。正常的软件包安装通过本软件包的 `install` 配方完成两次复制。
