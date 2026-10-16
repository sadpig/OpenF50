# Contributing

**一句话概括：** 报告、翻译、测试和修复都欢迎；在
[GitHub](https://github.com/dikeckaan/openf50-linux) 上开 issue 或 pull request。

这是个用业余时间维护的爱好项目。清晰的报告和小而聚焦的 pull request 帮助最大。

## 报告问题

1. 先读 [Troubleshooting](Troubleshooting)。
2. 说明设备（F50 / OPENF50 或 U30 Air）、发布包、系统（Ubuntu 24.04/26.04、OpenWrt、带面板的 OpenWrt）
   和内核（5.4、6.18、7.2）。
3. 附上有用的东西：
   * 安装器问题：`./install.sh --check` 的输出（它能识别存储变体）；
   * 回退到 Android 的设备：`tools/collect-logs.sh` 产出的文件夹（引导加载器日志、pstore 和留在
     Linux boot 分区里的 init 日志）；
   * 运行中的系统：`sudo mobile-data status`、`sudo wifi-client status`、`journalctl -t kernel`
     （Ubuntu）。
4. **发布前删去个人数据：** IMEI、手机号、Wi-Fi 名称和密码、VPN 链接。永远不要发布
   `tools/backup-device.sh` 的文件夹。

在 https://github.com/dikeckaan/openf50-linux/issues 开 issue。关于 VPN 模块的报告请去
https://github.com/dikeckaan/mu300-linux-vpn/issues。

## 运行测试

```sh
cd tests && python3 -m unittest        # all unit tests; standard library only (lz4 for the boot image tests)
python3 tools/check-i18n.py            # the installers' translations
python3 tools/luci-i18n.py check       # the control panel's translations
```

CI 在 Ubuntu、macOS 和 Windows 上跑 `tests.yml`，另有 `installer.yml`（翻译、脚本语法）、`mainline.yml`
（每周对最新 longterm 和 stable 内核构建内核移植）和 `magisk.yml`（每个发布包的 Magisk zip）。

## 翻译安装器

安装器（`install.sh`、`install.ps1`）说英语、土耳其语和中文。消息在 `i18n/<lang>.tsv` 里，一行一条：
英文原文、一个制表符、译文。缺行就保持英文。

添加语言（完整步骤在 [i18n/README.md](https://github.com/dikeckaan/openf50-linux/blob/main/i18n/README.md)）：

1. `python3 tools/check-i18n.py --keys` 打印所有消息；把它们译进 `i18n/<lang>.tsv`。命令、路径和需要
   输入的词（`INSTALL`、`ERASE`、`overwrite`、`update`/`wipe`）保持原样。
2. 把语言加进 `tools/i18n.sh` 的 `choose_language` 和 `install.ps1` 的菜单（那个脚本必须保持
   ASCII），并把它的"是/否"说法加进 `normalize_answer` / `NormalizeAnswer`。
3. `python3 tools/check-i18n.py` 必须报告没有缺失、没有占位符不匹配。

## 翻译控制面板

面板除土耳其语和中文外的翻译是机器（AI）翻译。在
`openwrt/luci-app-openf50/po/<language>/openf50.po` 里修正并开 pull request。
`python3 tools/luci-i18n.py check` 必须保持干净，新语言还需要在 `openwrt/luci-languages.tsv` 里加一行。

## 代码

* 改东西之前先读 [docs/FINDINGS.md](https://github.com/dikeckaan/openf50-linux/blob/main/docs/FINDINGS.md)
  了解为什么是现在这样；许多看着奇怪的步骤是因为没有它们时东西坏过。
* 构建说明：[Building from Source](Building-from-Source) 和
  [docs/BUILD.md](https://github.com/dikeckaan/openf50-linux/blob/main/docs/BUILD.md)。
* 保持镜像不含专有文件：固件和 Android 文件在安装时来自用户自己的设备。
* 在 pull request 里说明你测了什么、在哪台设备和哪个内核上测的。

## 本 wiki 和网站

* wiki 以 Markdown 保存在主仓库的 [`wiki/` 文件夹](https://github.com/dikeckaan/openf50-linux/tree/main/wiki)。
  在那里用 pull request 修改；维护者会把它复制到 GitHub wiki。
* 网站（https://kaandikec.com/openf50-linux/）是 `site/` 文件夹，纯 HTML 和 CSS，由 GitHub Actions
  部署。
* 事实变化时（命令、版本、限制），README、wiki 和网站一起更新。

## 许可证

对脚本、工具和文档的贡献以 MIT 授权；内核补丁以 GPL-2.0 授权。见
[LICENSE](https://github.com/dikeckaan/openf50-linux/blob/main/LICENSE)。
