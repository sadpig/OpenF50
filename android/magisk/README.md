# Magisk 模块：从 Android 切换到 Linux

一键从 Android 启动 Linux 系统。它取代了"只为了改启动槽位就得插电脑"的做法。有两种获取方式：

* **release 的安装器 zip**（`openf50-magisk-<tag>-<system>-k<kernel>.zip`，见[主 README](../../README.md) 中的 "Installing from Android with a Magisk zip" 一节）安装 Linux，然后作为本模块留在设备上。安装完成后它显示为 "OPENF50 Linux" 而不是 "OPENF50 Linux switch"；模块 id 相同（`openf50_linux_switch`），所以两者互相替换。Action 按钮、`openf50-linux` 和下面的一切都同样工作。它们的文件来自本目录（`installer/` 是安装部分，`openf50-linux-switch/` 是本模块），由 `tools/make-magisk-zips.sh` 组装。
* **仅切换的模块**，用于从电脑（`./install.sh`）安装过 Linux 的设备。它不安装任何东西，只修改启动槽位：

```sh
android/magisk/build.sh          # builds openf50-linux-switch.zip
```

在 Magisk 应用中安装该 zip（模块 → 从存储安装），或从电脑安装：

```sh
adb push android/magisk/openf50-linux-switch.zip /data/local/tmp/
adb shell "su -c 'magisk --install-module /data/local/tmp/openf50-linux-switch.zip'"
adb reboot                      # Magisk applies a new module on the next boot
```

## 使用方法

* **Magisk 应用 → 模块 → OPENF50 Linux switch → Action。** 设备会武装 Android 当前不在的槽位并重启进入 Linux。
* **从终端或 adb：**

```sh
su -c openf50-linux               # switch to Linux now
su -c 'openf50-linux status'      # what is on each slot; changes nothing
su -c 'openf50-linux --dry-run'   # print the block it would write, write nothing
su -c 'openf50-linux bootchain'   # does the boot chain differ between the slots? changes nothing
su -c 'openf50-linux bootchain sync'   # copy Android's slot's chain to the Linux slot (backed up first)
```

`bootchain sync` 是安装器那一步的独立版本（`bootchain.sh`，`tools/android-bootchain.sh` 的副本；FINDINGS 40）：当两个槽位之间的 `uboot`、`sml`、`teecfg`、`trustos` 或 `vbmeta` 不同——比如 Android 更新之后——两个槽位的镜像会先连同 `SHA256SUMS` 一起保存到 `/data/adb/openf50-bootchain/<日期>/`，然后把 Android 槽位的写入 Linux 槽位并读回校验；不匹配会把旧的写回去。以下情况它会拒绝执行：Android 槽位未标记为启动成功；另一个槽位被设为下次启动但上面没有 Linux（一个等待重启的更新）；十个分区中任何一个缺失，或同一分区的两个槽位大小不同；以及在任何其他机型上。

回去什么都不用做：Linux 会在自己的启动过程中恢复 Android 的块，所以下次重启就回到 Android。在 Linux 内，`openf50-next-boot linux` 武装下一次 Linux 启动，`openf50-os <名称>` 选择启动哪个系统。

## 它写什么

切换只写 32 字节：`misc` 偏移 `0x800` 处的 AOSP `bootloader_control` 块，把 Android 不在的槽位置为最高优先级且 `tries_remaining = 2`（LK 把 1 视为已经失败的启动），Android 的槽位保持可启动并标记为成功。`boot_a`、`boot_b`、GPT、`userdata` 和其他所有分区都不动，所以 Linux 起不来的最坏结果也只是 LK 自己回退到 Android。

这个块不是预制好的二进制 blob：模块读取设备上实时的块，修改槽位后缀和两个元数据字节，并在 `awk` 中重新计算 CRC32（zlib，覆盖前 28 字节），所以在块内容不同的设备上也能保持正确。以下情况它会拒绝任何操作：magic 不是 `BCAB`；Android 的槽位未知；或另一个 boot 分区缺失、不是 boot 镜像、或只是 Android boot 镜像的副本（即未安装 Linux）。

## 已在硬件上验证

ZTE F50 / OPENF50，Magisk 30.7，Android 13：`status` 和 `--dry-run` 输出的试用块与电脑上 `boot/flash-trial.sh` 计算的完全一致，Action/`openf50-linux` 路径已将设备重启进入 Linux。
