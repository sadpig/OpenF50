# 测试

```sh
python3 -m unittest discover -s tests            # everything this machine can run
OPENF50_TEST_SHELLS="busybox sh" python3 -m unittest discover -s tests   # one shell only
python3 -m unittest $(cd tests && python3 shard.py 4 0)      # what CI shard 0 of 4 runs; PRs add OPENF50_TEST_SHELLS="busybox sh" (quick mode)
powershell -File tests\installer.Tests.ps1        # Windows: install.ps1's functions
```

仅使用标准库（`lz4`，命令行工具或 `pip install lz4`，用于启动镜像测试）。CI 在 Ubuntu、macOS 和 Windows 上运行它们（`.github/workflows/tests.yml`）。

| 文件 | 内容 |
|---|---|
| `test_static.py` | 每个脚本都能在运行它的每种 shell 下解析；设备程序具有可执行权限；来自历史 bug 的规则（`install.ps1` 的设备命令中没有双引号、PowerShell 仅 ASCII、init 在模块之后查找分区） |
| `test_i18n.py` | `tools/i18n.sh`：每条翻译都带全部占位符、参数原样透传、三种语言的回答 |
| `test_device_scripts.py` | `openf50-device`、`openf50-lan-ip`、`openf50-led`（两种设备、4G/5G、超时、警报声、5.4 的 LDO 开关）、`thermal-guard`（高温告警、与内核温控区的交接与收回；`extra-modules` 加载 `openf50_thermal`）、`openf50-nfc`（伪造 NFC 标签：ZTE 自己的 Wi-Fi 记录逐字节、URL、文本、`sync` 不动的东西）、`openf50-ttl`（桩 `nft`）、`openf50-wifi-band`、`openf50-buttons`、`openf50-usb`（假充电器：对电源绝不输出 5 V）、槽位 a 和槽位 b 上的 `openf50-next-boot` 和 `early-recorder`（`NextBoot`、`EarlyRecorder`） |
| `test_installer.py` | 安装器选择哪台 adb 设备：只要它不是唯一的一台且是 F50/U30 Air 就会询问；存储选择（`Storage`）、安装器交给设备的设置（`InstallEnv`）、存储卡上的热点导入（`ImportHotspot`）、擦除存储卡（`SdErase`）和空闲区域（`Region`） |
| `test_vpn_hooks.py` | 与 VPN 模块协作的各处，在没有模块时不做任何有害的事：`openf50-toolkit` 的 VPN 菜单（如何安装它，或菜单本身）、`mobile-data` 的守卫、LuCI 面板的 VPN 能力和动作（`test_power` 和 `test_wifi_client` 覆盖各自的部分） |
| `test_wifi_client.py` | `wifi-client`：扫描（iw 和 wpa_cli 输出：WPA2、WPA2/3、WPA3、UTF-8 名称、无邻居报告 BSSID 或隐藏网络）、密码来自 stdin 或文件而绝不出现在命令行、仅 WPA3 的网络在没有 SAE 时立即拒绝、有 SAE 时加入、上行共享（精确的 nft 规则在加入、链路丢失与恢复、加入失败或中断、supplicant 停不下来等过程中被关闭、共享和移除；不越过 VPN 的 kill switch；OpenWrt 上 fw4 的 wan 区域）、恶意名称在所有地方都按文本显示、名称或密码的每种输入途径共用一个校验器（工具箱也一样）、`disconnect` 在重启后保留热点 |
| `test_extra.py` | extras：`openf50-update` 对 extras 的安装与更新、`openf50-extra` 针对假 release 服务器的 install/remove/link；dikeckaan/mu300-linux-vpn 的 VPN 模块（假模块 tar 包：经 `OPENF50_VPN_URL` 在线并校验其 SHA256SUMS、离线 `--from FILE|DIR`、坏哈希或比系统更新的 `requires` 被拒绝、每个已安装系统的 `hooks/link` 与 `hooks/unlink`、启动时的 `link`）、VPN 使用中的 `openf50-update apply`（`UpdateWithTheVpn`：没有模块时在任何改动之前拒绝、已暂存或已下载的模块被安装并链接进新系统、较旧的仅引擎 vpn extra 被替换）；语言 extra（`LangExtra`：目录文件链接进 LuCI 并注册进 `luci.languages`、启用/禁用、Ubuntu 被拒绝、恶意压缩包被拒绝） |
| `test_update.py` | `openf50-update`：按系统和内核的 release 文件、启动镜像字节辅助函数、内核 bundle 是否可装上本设备、它操作的 Linux 槽位、从设备自己的原厂镜像构建的启动镜像（`FromStock`：被另一次运行追加过的文件会被拒绝当作这种镜像）、以及一次只允许一个运行（`Lock`：第二个运行说出持锁者的 pid 并以 1 退出，有 flock 时和没有时用 pid 目录；已消失运行的锁、不是 pid 的 pid、或已不属于 openf50-update 的活 pid，会被接管并输出一行说明；锁路径上的链接、其他类型的文件或目录、锁文件位置上的链接、或无法创建的目录，都以退出码 1 拒绝，绝不在无锁状态下运行；哪些加锁、哪些只读） |
| `test_user_packages.py` | 跨更新保留设备上安装的软件包（#116）：`upk_record`（OpenWrt 的 world 文件和软件包数据库、Ubuntu 的手动安装包，减去镜像的 `etc/openf50/image-packages`；它们的 UCI 文件单独存放，绝不动镜像自己的；Ubuntu 的 apt 源及其指名的密钥被保留，绝不覆盖镜像的，对没有东西可装的另一个 release 则关闭；其 systemd 单元的状态、别名和模板不纳入；`tools/android-install.sh` 中有相同的一段）、一个保留的源在 `apt-get update` 失败时被关闭（离线：无）、单元按原样启用/禁用/屏蔽、`apply_one`、以及带桩 `apk`/`apt-get`/`uci` 的 `openf50-user-packages`（连同其设置和服务装回、失败后逐个重试、离线五次启动后放弃、跳过、移除缺失的 LuCI 主题；DNS 检查失败时按关闭处理：只有当一个转发器属于彻底消失的软件包且还剩另一个服务器时才移除它；VPN 开启时、所有者不明时、属于项目端口时、或端口在窗口期内出现时绝不移除；唯一符合条件者由 `repair-dns` 单独报告并移除） |
| `test_boot_init.py` | `boot/init`：先在任意 `mmcblkN` 下找卡，再找内部区域；外来或空卡回退；300 秒计时器和条件等待；init 采用的槽位（`Slot`：命令行、设备树、镜像、不匹配）以及它恢复的块 |
| `test_vendor_ids.py` | vendor 守护进程的账户（FINDINGS 41）：`ueventd-perms.sh` 是生成器的输出，任何节点对登录用户或其他人的权限都不比 v2026.10.18 的脚本（`tests/fixtures/ueventd-perms-v2026.10.18.sh`）更开放、无全局可写模式、无数字 id、校准分区属 vendor 账户、GPU 为 `root:video`、id 映射、运行时的 id（Ubuntu、OpenWrt、initramfs）；`android-run` 以 `openf50vnd` 启动 `modem_control`/`refnotify` 且只带它们的能力集；账户在启动时创建（失败绝不妨碍调制解调器）、包含在镜像中、并被 `openf50-update` 的合并保留 |
| `test_emmc_lookup.py` | Linux 侧每个按分区名的查找（init、`early-recorder`、`openf50-update`、`android-vendor-start`）都取 eMMC 的分区，无论卡是 `mmcblk0`/`mmcblk1` 中的哪一个，都绝不取同名 GPT 分区的卡；`emmc_dev` 绝不回退到卡；`ueventd-perms.sh` 不按编号触碰任何块设备 |
| `test_android_mount.py` | `tools/android-mount-openf50root.sh -u`：loop 已被 Android 的 umount 释放的卸载成功、遗留挂着的 loop 被 detach、失败的 umount 或 detach 返回失败 |
| `test_android_install.py` | SD 卡上的 `tools/android-install.sh`：空白卡被格式化、外来 ext4 以及已 adopted 或占用中的卡被拒绝；内部安装的标记；推送的 extras（VPN 模块）、以及更新时使用中的 VPN 没有模块时的警告；`Stages`（FINDINGS 50）：卡阶段由其截止时间或卡的计数器 120 秒无 I/O 进展而结束，其整个进程组被停止并写入按启动 id 键控的锁；同一 Android 启动内重跑被拒绝、陈旧锁被移除、干净的运行不留锁；超时后不 `sync`、不卸载，且绝不输出 OK 行 |
| `test_boot_image.py` | `boot/build-boot-image.py`：通用 ramdisk、U30 Air 的模块及其顺序、四个 `misc` 块和 `--linux-slot`（`SlotBlocks`） |
| `test_magisk_installer.py` | 假设备（`fakedevice.py`）上的 `android/magisk/installer/openf50-install.sh`：`Conf`（设置文件：可信与不可信、校验、绝不执行）、`AndroidSide`（Android 自己的 shell，不是 Magisk 的 busybox）、`Plan`（机型、槽位、Linux 的去处、拒绝、试运行、示例文件）、`WorkDirectory`（仅 root 的目录，已挂载的东西不被删除）、`Install`（写入什么、校验、`misc` 最后武装；失败时 Android 仍能启动；启动镜像从分区读回文件并比较——有差异或读取失败绝不武装 Linux；本次启动中超时的 SD 卡阶段留下的锁在计划之前被拒绝；失败时保留设备日志）、`Bootchain`（计划行、拒绝先于一切、`OPENF50_SYNC_BOOTCHAIN`）、`Password`（每个新系统使用镜像自己的密码——ubuntu/ubuntu、OpenWrt 的 root 无密码——设置文件中的密码经哈希且绝不显示、便条文件、用过的设置被移除） |
| `test_magisk_zip.py` | 假 Magisk 环境中的 `customize.sh`（`Customize`）、`tools/make-magisk-zips.sh`（`Builder`：八个 zip、允许列表、清单），以及当 `OPENF50_MAGISK_ZIPS` 指向某 release 的真实 zip 时的 `ReleaseZips` |
| `test_bootchain.py` | 假 by-name 目录上的 `tools/android-bootchain.sh`：槽位相同则什么都不写；有差异的镜像只写入 Linux 槽位，且先以正确哈希备份；拒绝（大小、缺失、两个槽位指向同一设备、未知槽位或机型、Android 槽位未成功、有更新等待、从 Linux 运行）什么都不写；读回不匹配则恢复并失败；固定的五个列表，NV 名称绝不允许；切换模块的那份相同副本；`android-install.sh` 的块、计划行、安装器的接线 |
| `test_magisk_switch.py` | `android/magisk/openf50-linux-switch/switch.sh`：块写入 Android 不在的槽位，带 bootloader 校验的 CRC；拒绝 Android 启动镜像的副本 |
| `test_android_boot_image.py` | `tools/android-boot-image.sh`：只有设备才能做出的启动镜像部件（`misc` 块、Android 的文件、设备段），与相同输入下的 `boot/build-boot-image.py` 对比 |
| `fakedevice.py` | 不是测试：Magisk 测试运行的假 F50（块设备用文件模拟、sysfs 树、Android 工具的桩和假挂载表） |
| `test_openf50cell.py` | `openf50cell.sh`（OpenWrt netifd 协议），连同 netifd 函数一起 source，`ip`、`mobile-data` 为桩：APN 凭据只在其环境中（FINDINGS 65；`MobileDataContext`：source `mobile-data` 的 `define_context`、两种卡的命令、密码只在 `openf50-at` 的 stdin 上而不在其他任何地方）、外部更新、脚本安装的 v4 地址、v6 冲刷、拆除、attach 失败后的 `sleep 20`、extendprefix 接口；中继模式（K30、K35-K37、K64）：监视器 `openf50cell-v6.sh`、`ndp-learn`、`init.d/openf50-ndp`、`91-openf50-luci`、mobile-data 的 `v6_relay_ra` |
| `test_atd_dash.py` | `init.d/openf50-atd-dash`（K19）：nr6/nr7 上的两个 procd 实例，各有自己的 `OPENF50_AT_DIR` 且无 URC 通道，START 19，模式 100755，只在 `build-rootfs.sh` 的 luci 块中启用；面板的采集器依次尝试 `/run/openf50-at6`、`at7`，然后 nr1 |
| `test_early_dhcp.py` | USB 主机的早期 DHCP 租约从 `boot/init` 进入系统（K5、K9、K11、K13、K25-K27）：OpenWrt 的 preinit 服务器位于系统自己的 LAN 子网、结束它并重新挂上 `rndis0` 的 LAN 钩子、首次启动默认值（主机用广播租约固定，绝不当路由器；`earlyusb` 区域只建一次；`rndis0` 只在存在时桥接）、Ubuntu 的 `lan-start`；在每种 shell 下 |
| `test_ttl.py` | 带假 `uci`/`fw4`/`tc`/`modprobe` 的 `openf50-ttl`：nft 后端（无 `act_pedit`）在设置 TTL 期间关闭 OpenWrt 的流量卸载（启动时也一样），`off` 后恢复，没有 fw4 时不动（Ubuntu）；tc 后端（`TtlTc`）在每个 sipa_eth* 上幂等地放置 matchall/pedit 过滤器、不动卸载、tc 失败时回退到 nft，`off` 两者都移除 |
| `test_luci_i18n.py` | 控制面板的目录文件：每个 `po/<lang>` 完整且在语言表中、CJK 只出现在目录文件中；页面（语言页面也在内）在 Node 下运行；更新后的软件包页面（Repair DNS 只在其确认之后） |
| `test_po2lmo.py` | `tools/po2lmo.py` 对照 LuCI 自己的 po2lmo 生成的目录文件（`tests/fixtures/po2lmo`） |
| `test_terminal.py` | `openwrt-luci` 上的 系统 > 终端（ttyd）：`openf50term` 的一次性令牌（0700 目录中的 0600 文件，最多 16 个，ttyd 运行其他命令时拒绝）、`openf50-terminal-login`（令牌一次性且只在一分钟内换一个 root 登录，其他任何参数拒绝）、镜像的 ttyd 配置（LAN 地址、origin 检查、蜂窝侧不开任何端口、wan 输入绝不接受）、ACL、菜单和构建 |
| `test_panel.py` | Ubuntu 的 Web 面板（面板 extra：Cockpit 和 OPENF50 页面）：openf50-update 对其 tar 包的检查、`openf50-extra install panel` 在线（apt）与离线（`--from`，release 的软件包，对照 SHA256SUMS 校验）、remove、`link`（Cockpit 存在时启动不做任何事；更新后后台恢复）、`openf50-panel`（仅 LAN 的 socket、带恶意名称的 `info` JSON、密码走 stdin 的 `hotspot-set`）、防火墙让 9090 不暴露在上行、清单和翻译、页面的 JavaScript 在 Node 下（参数数组、秘密走 stdin、文本绝不按 HTML 处理）、`sms json` |
| `test_openf50dash_security.py` | 面板的 rpcd 后端 `openf50dash` 及其适配器（S1）：每个参数对照允许列表检查、不可信文本只作为一个精确参数或走 stdin、每个回复都是 JSON、共享的转义器、ACL；软件包适配器（`PackagesAdapter`：记录无论内容都按 JSON、retry 和 repair-dns 在后台、一次一个） |
| `test_panel_resilience.py` | 一条卡死的 AT 命令不得卡住面板（FINDINGS 40）：`openf50-at` 的锁等待按秒计时，即使配合整秒的 `sleep`，超过自己期限的持锁者被终结（`AtLock`）；采集器对无声调制解调器的期限（`CellDeadline`）；`lock_get` 绝不在请求中读调制解调器，扫描或改动调制解调器的 AT 命令需要确认，扫描作为任务运行（`Backend`）；本次启动和上一次启动的调用日志，绝不含取值（`OpsLog`）；Node 下的页面：每次调用不合并、退避、短信监视器、终端的确认、陈旧读数、信道分析和系统日志（`Pages`） |
| `test_sms_pool.py` | 短信池（K69、D11）：`openf50-sms` 和 `openf50-smsd` 通过桩 `openf50-at` 把 SIM 与面板的消息保存在 `/etc/openf50/sms-pool`；面板侧跑在真实的 `openf50-sms` 上；发送者复用参考号时哪些部分算一条长短信（`Codec`、`Listing`、FINDINGS 63） |
| `test_adb.py` | 经 USB 到 Linux 的 adb（FINDINGS 43、70）：adbd 补丁逐行（一个开关决定谁被放行，`OPENF50_ADB_AUTH=open`，别无其他；密钥只从 root 的文件取、仅 USB、无全局可写）、固定的源码、内核选项、镜像和 release；假 gadget 上的 `openf50-adbd`（以 `f3` 加入并让 gadget 保持原样、RNDIS 保留其 MS OS 描述符、FunctionFS 解绑后重新绑定、未就绪的 adbd 绝不会拖累网络、host 角色不受影响）；默认开启且开放；`/etc/openf50/adb` 与 `adb_auth` 每种状态下谁被放行（配好密钥的设备保持如此；为空、被截断、不可读、是符号链接或他人可写的状态绝不开放；无密钥的 keys 模式以 keys 启动 adbd）；`openf50-usb adb`（开/关、`auth open|keys`、状态整体写入且绝不经过符号链接、无法运行的地方拒绝、仅 root、密钥被检查和清理） |
| `test_usb_management.py` | 面板的 USB 管理（`device-usb`，K7、K8、D12）：角色切换、host 模式、网卡重新挂载、`boot/init` 在下次启动时应用的 USB 网络模式文件 |
| `test_traffic.py` | `openf50-traffic`（移动数据计数）：第一次读数是基准，重启、接口重建或计数器变小时新计数器只计一次，另一个接口只是基准；午夜按本地日的时间切分，时钟跳变不拉长区间，DST 变化不丢一字节；字节等待 NTP 并按运行时间记日期（更早启动的字节计入 NTP 到达的那天）；计费周期（重置日 31、二月、闰年）、`used` 和 `clear`；上限的警告和断网（每周期一次、重启后再来、手工覆盖被保留、下个周期或更高上限时恢复；OpenWrt 和 Ubuntu）；服务在 SIGTERM 时保存、单实例、陈旧锁 |
| `test_wifi_channels.py` | 热点绝不落在 DFS 信道（FINDINGS 42）：`lib/wifi-channels.sh`（国家表、DFS 信道被替换并附一行原因、`auto`、带宽）、`hotspot-start` 的 hostapd 配置（桩 `iw`）、OpenWrt 上的 `openwrt-wifi-config` 和 `openf50-wifi-band`（桩 `uci`）、构建如何应用 `openwrt/patches/wifi-scripts-no-dfs.patch`；带 `OPENF50_WRT_IMAGE`（OpenWrt 25.12 arm64 docker 镜像，如 `openf50-openwrt-base:25.12.5`）时 feed 中打过补丁的 wifi-scripts 及其为假 wiphy 生成的 hostapd 配置 |
| `test_u30_sae.py` | 可选开启的 U30 Air SAE 卸载（FINDINGS 80）：从 hostapd 补丁编译的尾部解析器（每种截断、重复和游离标记、随机输入、编译器支持时带 UBSan）、补丁的配置检查和固件请求对照假驱动调用、带桩 SDK 的 `openwrt/build-u30-sae.sh`、不带密钥和载荷转储的驱动源码、`openf50-wifi-sae-guard`（桩 `uci`/`ubus`：没有选项什么都不做、hostapd 缺少它或接入点未启动时回到 WPA2、故意关闭的热点不动）；带 `OPENF50_WRT_IMAGE` 时 wifi-scripts 为开启和回退分别写出的 hostapd 配置 |
| `test_wifi.py` | `wifi-start` 在没有 `modules.dep` 时加载 WCN 模块（K55）；`openf50-hw` 在国家代码生效后重启 AP（K15） |
| `test_early_replay_hook.py` | 在射频开启前重放 LuCI 插件已保存锁的早期钩子（K65）：它在 `mobile-data` 中的位置 |
| `test_unisoc_plugin.py` | 插件的可移植适配器边界（K81）：自定义 AT 后端契约、`--available` 什么都不发送、`boot-replay`（禁用时零 AT 流量、延迟重放、早期窗口）、`lock replay early` 不用 `SFUN` 恢复每个已保存的锁 |
| `installer.Tests.ps1` | `install.ps1`：覆盖每条翻译的 `T`、`NormalizeAnswer`、`Gib` |

设备脚本在 dash（Ubuntu 的 `/bin/sh`）、bash 和 busybox ash（OpenWrt）下运行；每个 shell 测试都会在已安装的每一种 shell 下运行。触碰设备的命令（`nft`、`ip`、`id`、`sing-box`）是桩，脚本通过 `OPENF50_SYSROOT`、`OPENF50_DISK` 等读取一个假的 `/`；`openf50-update` 以 `OPENF50_LIB=1` 被 source，这只定义它的函数而不运行任何内容。
