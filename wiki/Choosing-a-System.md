# Choosing a System

**一句话概括：** 想要通用 Linux 电脑选 **Ubuntu**，想要路由器选 **OpenWrt**，想要带 5G 调制解调器友好
网页的路由器选**带控制面板的 OpenWrt**。可以装两个再切换。

**通俗版说明：** Ubuntu 是工具齐全的大工坊；OpenWrt 是小巧整洁、带网页的路由器；带控制面板的 OpenWrt
是同一个路由器，外加一块面向 SIM 卡和射频的仪表盘。

## 并排对比

| | Ubuntu | OpenWrt | 带 OPENF50 控制面板的 OpenWrt |
|---|---|---|---|
| 安装器里的名字 | `ubuntu` | `openwrt` | `openwrt-luci` |
| 版本 | 24.04 LTS（默认）或 26.04 LTS | 25.12 | 25.12 |
| 内存占用（安装器数字） | ~500 MiB | ~140 MiB | 安装器未给出 |
| 安装体积（实测） | ~580 MiB | ~320 MiB | - |
| 装软件用 | `apt` | `apk` | `apk` |
| 网页界面 | 可选：Cockpit 加 OPENF50 页面（`openf50-extra install panel`，v2026.10.20 起）；否则 SSH 和 `openf50-toolkit` | LuCI | LuCI + OPENF50 面板（带 VPN 区块和浏览器终端） |
| 登录身份 | `ubuntu`（用 `sudo`） | `root` | `root` |
| 适合 | 服务器、容器、脚本、开发、学 Linux | 精简路由器 | 从浏览器管理的路由器：信号、频段锁、短信、AT 终端、电源 |
| Magisk zip | 有 | 有 | 有（v2026.10.18 起） |

三者都有移动数据、Wi-Fi 热点和客户端、USB 网络、SSH、短信（`sms`）、工具包和可选的 [VPN](VPN) 模块。

## 安装器的原话

```
==> What should be installed?
  1) Ubuntu LTS: 24.04 or 26.04, asked next (full distribution, apt, ~500 MiB RAM in use)
  2) OpenWrt 25.12.5 (router, LuCI web UI, ~140 MiB RAM in use)
  3) both (switch later with: openf50-os ubuntu|openwrt)

==> Which OpenWrt?
  1) OpenWrt 25.12.5: the standard LuCI web interface
  2) OpenWrt 25.12.5 with the OPENF50 control panel: dashboard, cellular locks, SMS, AT terminal, USB modes (by kanoqwq)

==> Which Ubuntu?
  1) 24.04 LTS  the longest tested, supported until 2029
  2) 26.04 LTS  the newest (systemd 259, newer packages), supported until 2031; kernel 6.18 or 7.2
```

`OPENF50_OPENWRT=plain|luci` 可以跳过 OpenWrt 问题直接回答。

## 需要的空间

安装器要求系统本身加更新保留的一份副本的空间：仅 OpenWrt 约 **800 MiB**，仅 Ubuntu 约 **1.6 GiB**，两者
约 **2.4 GiB**。在常见的 64 GB 设备（约 32 GiB 空闲）上随便选都装得下。

## Ubuntu 24.04 还是 26.04？

* **24.04 LTS** 是默认，测试最久。每个内核都能用。
* **26.04 LTS** 最新，支持到 2031 年。它的程序用到 5.4 内核没有的系统调用（比如 `tar` 在那里无法解
  包目录），所以它**需要内核 6.18 或 7.2**。安装器不会让你把它和 5.4 组合。

已装的 Ubuntu 可以用 `sudo OPENF50_UBUNTU=26.04 openf50-update apply`（或 `24.04`）切到另一个版本，
设置和数据保留。

## 两个系统，一台设备

两个系统并排住在 Linux 磁盘上，各是一个目录；`/.openf50/boot-os` 里点名的那个启动。切换：

```sh
sudo openf50-os ubuntu
sudo openf50-os openwrt
sudo openf50-os openwrt-luci   # the one with the control panel
```

然后重启。同一时刻只运行一个。

## 其他发行版

Debian、Kali、Arch Linux ARM 和 ImmortalWrt 可以从本仓库构建，但不发布、安装器也不提供。什么能用、什么
不能（比如 Kali 没有监听模式）以及如何安装你自己构建的系统：
[docs/DISTROS.md](https://github.com/dikeckaan/openf50-linux/blob/main/docs/DISTROS.md)。

## 这台设备上永远不要

**永远不要使用 OpenWrt 的 `sysupgrade`，也不要刷 OpenWrt 固件镜像。** 它们是为普通路由器写的，会覆盖
设备的存储。普通的 `apk upgrade` 没问题，除了 `kernel` 和 `kmod-*` 软件包。更新走
[`openf50-update`](Updating)。

下一步：[Kernels](Kernels)。
