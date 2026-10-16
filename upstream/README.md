# OPENF50 上的主线（LTS）内核

主线 **Linux 6.18.56**（当前的 longterm 系列）可在 ZTE F50 / OPENF50（Unisoc UMS9620）上运行 Ubuntu 24.04 和 OpenWrt 25.12：全部 8 个 CPU（4×A55、4×A76）、eMMC、USB NCM + ACM、5 GHz 热点、蓝牙、调制解调器与移动数据（下行和上行）、短信、VPN、Mali GPU、温控/cpufreq、PMIC 看门狗和重启均可用。`docs/FINDINGS.md` 31-31f 记录了移植所做的工作以及尚未完成的部分。

在设备上：`sudo openf50-update kernel 6.18`（或 `7.2`，最新的 stable 版本），以及用 `sudo openf50-update kernel 5.4` 切回；安装器提供全部三个选项。每个内核的模块都会保持安装状态。

参考：Unisoc 的 UMS9620 DT 系列补丁（LKML，2023-12-15，"arm64: dts: sprd: Add support for Unisoc's UMS9620"，未合入）描述了相同的 GIC/UART/定时器布局；本设备衍生自他们的 ums9620-2h10 参考板。

## 启动方式
* **设备树：** 原样使用 `vendor_boot` 中的原厂 vendor DTB。主线忽略 vendor 专用节点，使用标准节点（cpus、psci、GIC、timer、memory、reserved-memory、ramoops、ADI）。一个最小化的自定义 DTB（`dts/ums9620-mu300.dts`，用 `mkvendorboot.py` 安装）被*否决*：经过 LK 的 dtbo 合并和 fixup 之后，内核在 `setup_machine_fdt` 中挂死。
* **加载地址：** LK 总是把内核复制到 0x80080000（旧的 text_offset）；`wrap-image.py` 在前面加一个跳转桩，使 Image 从 0x80200000（2 MiB 对齐）运行。
* **复位：** PSCI SYSTEM_RESET 在这份固件上从不返回。`patches/0001-spi-sprd-adi-add-UMS9620-restart.patch` 为 `spi-sprd-adi` 添加了 UMS9620/UMP9620 变体（同时匹配 vendor 的 compatible `sprd,qogirn6pro-adi`），并通过 PMIC 软件复位完成重启，注册优先级高于 PSCI 处理函数。
* **日志：** 有了可用的复位，控制台日志会留在 ramoops 中，Android 将其显示为 `/sys/fs/pstore/console-ramoops-0`（`tools/collect-logs.sh`）。

## 构建与测试
```sh
docker build -t openf50-mainline-build upstream/
docker volume create openf50-mainline   # build.sh fetches linux-$KV (default 6.18.56) into it, checked against kernel.org
docker run --rm -v openf50-mainline:/src -v "$PWD/upstream":/work openf50-mainline-build bash /work/build.sh
docker run --rm -v openf50-mainline:/src -v "$PWD/upstream":/work openf50-mainline-build bash /work/build-modules.sh
upstream/make-bundle.sh openf50-kernel-6.18.tar.gz        # Image for LK, generic ramdisk segment, modules
# on the device: OPENF50_KERNEL_BUNDLE=/path/openf50-kernel-6.18.tar.gz openf50-update boot
```
构建会在任何悄悄偏离预期的地方停下：既不能应用也未被应用过的补丁、Kconfig 不接受的配置项（除非列在 `config-ignored.txt` 中）、锚点已移动的移植修改，或 vermagic 与内核不匹配的模块。`tools/make-release.sh` 将同一个 bundle 打包为 `openf50-kernel-6.18.tar.gz`。

配置是 allnoconfig 加上 `openf50-mainline.config`：板和启动所需的东西全部内建，同时还有 KVM（`/dev/kvm`；CPU 从 EL2 启动）；只有用到时才重要的东西——netfilter 扩展、隧道、IPsec、tc、文件系统、USB 调制解调器/网卡/Wi-Fi 网卡、device mapper——做成模块。`build-modules.sh` 把内核自带的模块（已 strip）扁平安装到 `out/modules`，与 vendor 模块放在一起，bundle 将它们全部打包；`openf50-update` 在 Ubuntu 上为它们建立索引（depmod），OpenWrt 按名字加载它们（FINDINGS 31o）。两个内核都带有 BTF（`/sys/kernel/btf/vmlinux`，由构建镜像中的 `pahole` 生成）以及 BPF JIT、tcx/clsact、cgroup 和 kprobe 钩子——dae 透明代理等 eBPF 程序需要这些（FINDINGS 31p）；生成 BTF 所用的 DWARF 保留在 `vmlinux` 中，`build-modules.sh` 会把它从 vendor 模块中剥掉。

旧的启动调试路径（手工构建的镜像、`init-bringup`、`boot/flash-trial.sh`）仍可用于实验：
```sh
python3 upstream/wrap-image.py upstream/out/Image upstream/out/Image.lk
boot/flash-trial.sh boot-mainline.img      # slot b only, falls back to Android
```

## 没有控制台时的调试
* `stub/pmic-reset.c`：用作内核入口的裸机 PMIC 复位——证明了 LK 能到达我们的代码，且 PMIC 复位可用（30 秒循环，而不是约 320 秒的 PM 断电）。
* `debug/install-probe.py`（`build.sh` 用 `OPENF50_PROBE_STAGE=N`）：在选定的启动阶段复位；循环时间可以说明该阶段是否被到达。自定义 DTB 在 `setup_machine_fdt` 的挂死就是这样定位的。

## 更新的内核（7.x）

整个移植——内核和全部 31 个树外模块——也针对 **7.2.10**（2026-10-11 的最新 stable 版本）构建，源码与 6.18 相同，并已在设备上运行：四次启动全部成功（2026-09-27），Wi-Fi 接入点、移动数据（18.7 MB/s）、蓝牙、Mali GPU、cpufreq 和调制解调器的 AT 通道均工作，日志中没有任何 warning 或 oops。（7.2 是 stable 而非 longterm 版本：6.18 仍是基础，7.x 是为了让下一次跨越保持小步。）一份源码同时服务两者：

* `port/install.py` 能识别它所编辑文件的布局（`sprd-sc27xx-spi.c` 在 7.x 中被重构），且每处修改事后都会被校验，所以漂移的锚点会让构建停止，而不是被跳过。
* 模块从 `modules/wcn_bsp/kinclude` 获得缺失的部分：`openf50_compat.h`（仅 7.x 需要的 shim：`strncpy`、alarmtimer、`linux/hex.h`）和 `linux/of_gpio.h`——一个只有内核没有对应头文件时 kbuild 才会找到的 shim 头文件。超出 shim 能力范围的 API 变更放在 `LINUX_VERSION_CODE` 条件编译下（cfg80211 ops 接受 `wireless_dev` 参数、`dma_fence_signal()` 不再返回值）。
* `.github/workflows/mainline.yml` 每周针对当前 longterm 和最新 stable 版本构建这个移植，所以下一次破坏会以一次红色运行的形式出现，而不是等到下一次跨越时才发现。

release 中以 `openf50-kernel-7.2.tar.gz` 携带它：设备上 `sudo openf50-update kernel 7.2`，或安装器中的选项 3。它与 6.18 一起构建：`build.sh` 和 `build-modules.sh` 用 `OUTDIR=out-7.2 KV=7.2.10`，`make-bundle.sh` 用 `OPENF50_UPSTREAM_OUT=upstream/out-7.2`；`tools/make-release.sh` 两者都打包。

## 主线剩余工作（截至 2026-09-26）

- 强制命令行仍带有 `clk_ignore_unused pd_ignore_unused regulator_ignore_unused fw_devlink=permissive`。`regulator_ignore_unused` 保持 SIM 的供电，`fw_devlink=permissive` 保持 USB gadget 存活，所以这两个保留；`pd_ignore_unused` 没有改变任何东西；`clk_ignore_unused` 让 315 个未使用的时钟保持开启，是值得测量的那个（FINDINGS 31h）。
- 早期的崩溃和 OpenWrt 缺失的下行是同一个 bug——delegate 模块的（FINDINGS 31f）——已修复；有一次 Ubuntu 启动在崩溃捕获机制存在之前就早期死亡（31d），原因不明，之后的重启循环中未再复现（Ubuntu 6/6，OpenWrt 4/4）。
- 关机通过 PMIC 工作（FINDINGS 31h）；在带电的 USB 口上，无电池的 F50 会再次启动。
- 音频：未移植（在 5.4 上也不工作）。

## 更早的状态记录
时钟、pinctrl、电源域、USB 3.1 gadget、eMMC、PCIe、温控、cpufreq、看门狗、LED 和 Wi-Fi/BT 已工作（见下方状态）。仍缺少的：

- ~~**调制解调器**~~：自 2026-09-19 起工作——"Modem Alive"、AT、SIM、5G NSA 注册和 `sipa_eth0` 上的数据上下文。出了什么问题见下文"6.18 上的调制解调器"（共享内存被映射为 write-back）。
- **PM 协处理器**：没有 Android 的 `modem_control`，板子会在约 290 秒后断电，所以 vendor chroot 仍然是必需的。
- ~~**GPU**~~：自 2026-09-19 起工作（DDK r40p0 移植到 6.18，OpenCL 已在设备上验证）。
- **音频**：未开始。
- **蓝牙**：已作为树外模块构建，在 6.18 上未测试。

## 6.18 上的调制解调器：已工作（2026-09-19）

调制解调器在主线内核上起来了："Modem Alive"、AT、SIM、射频、**5G NSA 注册**，以及 `sipa_eth0` 上带地址的数据上下文。设备上实测：

```
AT         -> OK                                   AT+CFUN?  -> +CFUN: 1
AT+CPIN?   -> +CPIN: READY                         AT+CSQ    -> +CSQ: 37,20
AT+CEREG?  -> +CEREG: 2,1,"C300","00E07F53",13     AT+COPS?  -> +COPS: 0,2,"28602",13
mobile data up on sipa_eth0                        sipa_eth0  UP  10.x.x.x/8
```

### 问题所在：共享内存被映射为 write-back

调制解调器与 AP 共享的区域被保留在 System RAM **内部**（没有 `no-map`），vendor 5.4 驱动用 `vm_map_ram(pages, count, -1, pgprot_noncached(PAGE_KERNEL))` 映射它们。更新的内核从 `vm_map_ram()` 中删掉了 `prot` 参数，所以移植改用了 `memremap(..., MEMREMAP_WC | MEMREMAP_WB)`，而它在 write-combine 不可用时回退到 **write-back**——对线性映射的区域来说 write-combine 永远不可用。

调制解调器不会监听 AP 的缓存，所以 AP 写入的一切对它都不可见。症状很微妙而非致命：CP 启动了，请求它的 NV 数据，NV 服务器在第二个包上记录 `fail SIZE`，写了三个块就停滞了；`modem_control` 随后以 `wait modem alive timeout` 和 `g_modem_state = 8` 放弃。`ioremap_wc()` 也不是答案——内核拒绝对 System RAM 内的地址使用它（`WARNING at arch/arm64/mm/ioremap.c:27`），实际尝试时正是如此。

`vmap(pages, count, VM_MAP, prot)` 仍然接受 pgprot，所以 `smem.c` 现在像 vendor 驱动一样构建页数组，重新把这些区域映射为 non-cached，只在区域没有 `struct page`（真正的 `no-map`）或 vendor 代码要求缓存时才用 `memremap()`。

前后对比，来自同一份日志：

| | write-back（修复前） | non-cached（修复后） |
|---|---|---|
| `fail SIZE` | 1 | 0 |
| 已服务的 NV 包（`writeData`） | 3 | 运行到完成 |
| "Modem Alive" | 从未 | 是 |

### 启动过程

`tools/openf50-modem-ml-load` 加载 25 个模块（不含 `sipa-dele`，见其注释）。`cp_diskserver` 先启动，`modem_control` 约 8 秒后启动。"Modem Alive" 在一分钟内到达，之后 `openf50-atd` 正常提供 AT 服务——连续 15 条命令无需重开。

### GPU

`mali_kbase`（Arm DDK r40p0，与 5.4 镜像使用相同的源码）在移植其内核接口后可以针对 6.18 构建：`time_t`、`hrtimer_init()` -> `hrtimer_setup()`、`del_timer*()` -> `timer_delete*()`、shrinker 分配 API、`vma->vm_flags` 访问器、`get_user_pages()`/`pin_user_pages()` 失去 `vmas` 参数、`dev_pm_opp_set_regulators()` 返回令牌、`ioremap_nocache()`、`DEFINE_SEMAPHORE()` 接受计数、`no_llseek`、`FMODE_UNSIGNED_OFFSET`、`get_file_rcu()`、devfreq 的 `scaling_min_freq`/`scaling_max_freq`，以及页迁移钩子——folio 转换将其取代，已被编译去掉（迁移只是驱动可以不用的一种优化）。

其中两处不只是改名：

* DDK 自带一份内核自上而下地址搜索的副本，它遍历 VMA **rbtree**——该结构自 6.1 起已移除。`vm_unmapped_area()` 不导出给模块，所以搜索现在用 `find_vma()` 向下遍历，并保留 DDK 额外的对齐规则（着色器代码不能触碰 4 GB 边界）。
* 它的 `Kbuild` 把电源模型（`ipa/`）加入 `mali_kbase-y`，而后面的某行用 `:=` **重新赋值**了该变量，又把这些目标文件丢掉了。没人注意到，因为 vendor 内核设置了 `CONFIG_SPRD_GPU_COOLING_DEVICE`，从不使用 `ipa/`；主线使用它，于是模块链接失败。该 include 被移到了文件末尾。

内核配置新增了 `CONFIG_SYNC_FILE`（DDK 的 fence 辅助函数）和驱动期望的 devfreq 选项。

设备上实测：驱动完成探测，`/dev/mali0` 出现，Android OpenCL 用户空间通过 vendor chroot 运行——`Mali-G57 r0p1, OpenCL 3.0 v1.r40p0`，1464 MiB，`cltest` 在 GPU 上对 4 194 304 个浮点数求和，**0 错误**。

地址搜索还值得再来一轮：第一个版本返回 `gap_end - length`，但 `align_and_check()` 已经减去了长度，所以每次分配都落在低了一个缓冲区的位置。驱动加载了，OpenCL 运行了，而每一个结果都是错的——这提醒我们"能跑"不等于"能用"。

仍未完成：音频未动。

## 状态（2026-09-17）：OpenWrt 在 6.18.52 上运行

已安装的 OpenWrt 25.12.5 通过正常的 `boot/init`（多系统 switch_root）在主线内核上启动：SSH、LuCI、USB 3.1 gadget 上的 `br-lan`、fw4/nftables、zram。

在移植之上需要的修复：

- `sdhci-sprd`：UMS9620 使用 r11p3 控制器；vendor 驱动编程 DLL 相位为 `0x2`（主线为 `0x3`）。用 `0x3` 时 HS400ES 下读取正常，但每次写入都因数据 CRC 错误失败。
- `sdhci-sprd`：eMMC 和 SD 卡槽（`sprd,name` `sdio_sd`）被探测，`sdio_wifi` 没有（Wi-Fi 在 PCIe 上）。卡槽的 card detect 是 EIC 同步控制器的第 35 线，主线的 `gpio-eic-sprd` 将其映射为 24 线（六个 bank 中的三个）：`patches/0014` 把它们全部映射，因此卡槽通过中断检测，空卡槽被忽略（issue #181：轮询时它每秒初始化一次，日志被 "Got command interrupt ... even though no command operation was in progress" 寄存器转储填满）。
- UMP9620 PMIC 看门狗由 LK 以 300 秒武装，由 `ump9620-pmic-wdt-off` 禁用。
- 用户空间配置：cgroups/namespaces/seccomp、网桥、nftables、IPv6、zram。
- 温控：vendor `sprd_thermal_r5p0`（19 个片上区域），校准数据来自 UMS9620 eFuse；eFuse provider 以只读方式构建。
- cpufreq：vendor `sprd_sip_svc` + `sprd-cpufreq-v2`；ATF 执行 DVFS，内核通过 SIP SMC 调用请求（3 个策略：4 小核 / 3 中核 / 1 大核，schedutil）。PSCI cpuidle（WFI、核休眠、cluster 断电）。空闲温度从约 54 C 降到约 48 C。
- 原厂 DT 只在 vendor 虚拟区域（`soc-thmzone`：被动 70/85 C，临界 110 C，散热映射到三个 cluster）上有触发点，而其传感器驱动主线没有：`modules/openf50_thermal` 把它带回来（取 DT 命名的十一个区域中最热的那个），于是内核的 `step_wise` 在 85 C 开始限频。`extra-modules` 加载它；`/opt/openf50/bin/thermal-guard` 之后只做监视（并保留其 105 C 关机），只在该区域缺失时自己限制 cpufreq（FINDINGS 48）。

- 看门狗：LK 武装的 UMP9620 PMIC 看门狗被接管（`ump9620-pmic-wdt`），60 秒，由内核核心组件 ping，直到 procd/systemd 打开它；硬挂死会把板子复位回 Android。
- LED：UMP9620 RGB 状态 LED（vendor `sc27xx-bltc`）。
- PCIe：vendor `pcie-sprd` 移植到 6.18 DWC host API。DT 中的 `num-vectors` 被遵守，Marlin3 驱动需要 32 个连续 MSI。
- Wi-Fi/BT（SC2355 Marlin3）：`modules/` 中有 vendor `wcn_bsp`、`sprd_wlan_combo`（仅 SC2355 PCIe）和 `sprdbt_tty`，均移植为 6.18 的树外模块（`build-modules.sh`；`tools/port54.py` 处理机械的 5.4 API 变更，其余的由 `wcn_bsp/kinclude/openf50_compat.h` 处理）。在 OpenWrt 上芯片启动其固件，5 GHz VHT80 AP 开始广播。出厂 Wi-Fi MAC 从 `/chosen/bootargs` 中的 `androidboot.wifimac` 读取。WCN 模块不能卸载再加载（与 5.4 相同）。

尚未上主线：调制解调器（sipc/sipa/modem loader）、GPU、音频；蓝牙已构建但未测试。

### 内核配置与模块审计

两个主线 bundle 都使用 `openf50-mainline.config`，包括内建的 KVM、容器支持、virtio/9p、组播/MPLS/MPTCP、流量控制、NFS/SMB、加密文件系统、LVM/RAID、USB/IP 和 UVC 摄像头。可选驱动尽可能做成模块。CBC 和 XTS 内建，因为文件系统加密需要它们。与 FINDINGS 31p 中启动失败相关的内核跟踪选项保持禁用。

`make-bundle.sh` 将实际 Image 中嵌入的配置与请求的 fragment 核对，并要求 `build-modules.sh` 记录的每个模块都存在。每个 bundle 都包含 `kernel.config`、`modules.in-tree` 和 `modules.list` 供检查。在 arm64 上 KVM 是内建的（`CONFIG_KVM=y`），所以没有 `kvm.ko`；请在设备上检查 `/dev/kvm` 和启动日志。

对已发布的 v2026.10.18（7.2.9）和 v2026.10.25（7.2.10）bundle 的审计发现两者均内建 KVM，后者包含全部 376 个旧模块，外加 `openf50_thermal.ko`。扩充后的集合是在该基线之上增加能力；它不能修复缺失的 KVM 模块。
