# 原厂固件镜像

ZTE 原厂固件**不属于本仓库**（它不受本项目代码的 MIT 许可证覆盖；所有权利仍归 ZTE/Unisoc 所有）。项目仅保留一个镜像作为最后的修复手段，托管在 Internet Archive 上：

## trustos-F50_FLYMODEM_ZYV1.0.0B09.img

**https://archive.org/details/zte-f50-mu300-trustos-ZYV1.0.0B09**
（直接文件：https://archive.org/download/zte-f50-mu300-trustos-ZYV1.0.0B09/trustos-F50_FLYMODEM_ZYV1.0.0B09.img）

从一台运行原厂固件 `F50_FLYMODEM_ZYV1.0.0B09` 的 ZTE F50 / MU300 上读出的 Trusty TEE 镜像（`trustos`）。

| | |
|---|---|
| 固件版本 | `F50_FLYMODEM_ZYV1.0.0B09`（`ro.build.display.id`） |
| 分区 | `trustos_a` 和 `trustos_b`，在源设备上逐字节相同 |
| 大小 | 6 291 456 字节（分区为 6 MiB） |
| sha256 | `39244b89987dbfccc44fbe6aef5298c457a0ce3fe0e4cec54717d131144212a6` |

它不含任何设备特定数据：IMEI 和密钥位于 `prodnv` 和 eMMC 的 RPMB 区域，不在这个镜像里，这就是为什么两个槽位完全相同。

> **⚠️ 这可能与你的设备不匹配。** `trustos` 与 `sml`、`uboot` 和 `vbmeta` 作为一条链一起被校验，对应一个固件版本。把这个镜像写入运行不同固件构建的设备，可能让设备完全无法启动，那时就需要 BROM/SPD 恢复。它的存在是为那些自身 TEE 已经损坏的设备兜底——**不是**让你"以防万一"刷着玩的。

### 在你需要它之前

请做你自己的备份，而不是依赖这个文件：

```sh
tools/backup-device.sh
```

它会保存你这台机器自己的 `trustos`、bootloader 链和不可替代的校准分区，每一项都与设备校验过。

### 恢复

仅在设备处于已 root 的 Android（adb + su）时操作，且你必须理解上面的警告。下载文件，校验哈希，然后：

```sh
sha256sum trustos-F50_FLYMODEM_ZYV1.0.0B09.img                     # must match the hash in the table
adb push trustos-F50_FLYMODEM_ZYV1.0.0B09.img /data/local/tmp/trustos.img
adb shell "su -c 'sha256sum /data/local/tmp/trustos.img'"           # and again on the device
adb shell "su -c 'dd if=/data/local/tmp/trustos.img of=/dev/block/by-name/trustos_a bs=1M && sync'"
```

只有当 `trustos_b` 槽位也损坏时才用同样方式写它。如果设备已经无法启动到能用 adb 的程度，你需要 BROM/SPD 下载模式和完整固件包。
