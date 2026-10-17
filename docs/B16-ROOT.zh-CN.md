# B16 固件免降级 root 与直装 OpenF50

> 适用：`F50_FLYMODEM_ZYV1.0.0B16`（Android 13，2025-10 安全补丁）。
> 结论：**B16 不再需要降级 B09**——打上两个补丁镜像后直接满足本项目的
> "已 root、能启动修改过的 boot 镜像"前置条件，`./install.sh` 照常使用。

## 为什么 B16 以前刷不了

B16 上有两个叠加的硬障碍（均由静态逆向定位，非推测）：

1. **Magisk su 弹窗死结。** F50 无屏幕，Magisk 的授权弹窗无法确认。B16 上 magiskd 的
   su 决策链（magisk 二进制 `0x41dd0` 起）：policies 表无记录 → ASK → 建 fifo
   `/data/.magisk/su_request_<pid>` 并向 `com.topjohnwu.magisk` 广播 →
   `poll(fd, 1, 70000)` 等 App 回写。本机未装 Magisk App 时广播立即失败，
   回退分支（`0x41e98` 处 `mov w8, #1`）把策略写死为 DENY → 调用方立刻收到
   "Permission denied"。

2. **ADB 不持久。** 中兴 MBB 定制：framework `UsbDeviceManager.isAdbEnabled()` 里
   `if (isMbbUsbUserConfig()) return false;`，而
   `isMbbUsbUserConfig() = ZTE_FEATURE_MBB_USB_CONFIG(vendor 属性=true)
   && ro.build.type==user && !ro.boot.qrcode_adb_allow`——三条全中，于是开机完成时
   framework 把 `adb` 从 `sys.usb.config` 剥掉，adbd 被杀，只剩开机头 ~8 秒窗口。
   （后台"USB 调试"开关顺带写 `adb_enabled=1` 会因缺 WRITE_SECURE_SETTINGS 权限静默失败，
   所以"重启即失效"。）

## 修法（两个补丁镜像 + 一次窗口写入）

| 部件 | 改动 | 效果 |
|---|---|---|
| boot（Magisk 移植） | magisk 二进制 1 条指令：弹窗失败回退 `mov w8,#1`→`mov w8,#2`（ASK 失败=放行） | su 免确认即时给 root |
| vendor_boot cmdline | 追加 `androidboot.qrcode_adb_allow=1` | `isMbbUsbUserConfig()=false`，MBB 硬禁失效 |
| 设置项 | 8 秒窗口内 `su -c 'settings put global adb_enabled 1'`（一次性，持久） | `applyAdbFunction` 永远保留 adb，ADB 常驻 |

AVB/dm-verity 由已验证的 trustos 补丁（B09 trustos 刷入 trustos_&lt;当前槽&gt;）旁路——
B16 与 B09 的 trustos 代码字节级一致，仅签名区不同。

**注意：** su 补丁的语义是"无策略记录即放行"（本机无 Magisk App 时任何 uid 可提权）。
这是无屏研究设备的取舍；装了 Magisk App 后弹窗路径不受影响，显式 DENY 策略仍有效。
OTA/全量包会覆盖补丁，升级后需重打。

## 操作步骤

补丁镜像与一键脚本在 F50 工具仓（zte-f50-toolkit / toolkit/bin）：

```
b16-flash-root.sh    # ADB 窗口自动测槽位 → reboot autodloader 进 BROM →
                     # spd_dump-poll 逐分区刷 trustos_<槽>、boot_<槽>、vendor_boot_<槽>
                     # → 重启后自动在窗口内固化 adb_enabled=1
b16-verify.sh --reboot-test   # 回归：ADB 持久性、su 免确认、5G/Wi-Fi/Web 后台，
                              # 以及 install.sh 关键通路预检（su_do、对面槽、SD 卡）
```

前置：原厂后台（192.168.0.1）开过至少一次"USB 调试"（否则没有开机 ADB 窗口）。

之后与固件版本无关：

```
./install.sh --check
./install.sh            # 32 GB 机型选 SD 卡目标
```

## 给维护者的实现备注

* 本项目所有 host 侧脚本经 `tools/android-su.sh` 统一解析 su 位置
  （`command -v su` → `/debug_ramdisk/su`，`OPENF50_SU_BIN` 可覆盖），
  B16 补丁环境（su 不在 PATH）与 B09 Magisk 环境行为一致。
* Linux 槽的 boot chain（含 trustos）由安装器从 Android 槽复制——
  打过补丁的 trustos 随之落到 Linux 槽，Linux 镜像同样不受 AVB 阻拦。
* 安装器以 Android 槽的 boot 分区为基底构建 Linux 镜像：B16 补丁 boot 的
  内核与 cmdline 均为原厂内容，ramdisk 差异不影响构建。
