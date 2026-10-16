# SMS

**一句话概括：** `sudo sms list` 读取你 SIM 卡上的短信，`sudo sms send NUMBER TEXT` 发送短信——直接经
调制解调器，不经过 Android。

**通俗版说明：** 调制解调器在 SIM 卡上保管一个小信箱。这些命令打开信箱、读信、寄新信。

## 命令

```sh
sudo sms list                       # every message, long ones joined back together
sudo sms read INDEX                 # one message in full
sudo sms send NUMBER TEXT...        # send one (Turkish and emoji included; it picks the encoding)
sudo sms delete INDEX               # remove one from the SIM (also: read, all)
sudo sms watch [COMMAND]            # wait for new messages, run COMMAND for each
```

OpenWrt 上不需要 `sudo`。一切都经过 `openf50-atd`，所以它会排在其他正在和调制解调器对话的东西后面。
从 v2026.10.22 起，发送是一次事务：从建立到提交通道一直被占用，且调制解调器报告的 SMSC 先原样写回；
没有这些，一些网络会拒绝每次发送（issue #176，见 [Troubleshooting](Troubleshooting)）。
`sms delete` 只接受消息索引、`read` 或 `all`（v2026.10.20 起）；其他任何东西在调制解调器看到之前就被
拒绝，所以一个手滑的 `1,4` 再也不能清空信箱。

在带网页面板 extra（Cockpit）的 Ubuntu 上，OPENF50 页面也能读取、发送和删除消息。

## 在带控制面板的 OpenWrt 上

用面板的 **Cellular -> SMS**：读取、发送、删除。那里有一个池守护进程每 30 秒用 `AT+CMGL` 同步一次
SIM，它会**把 SIM 上未读的消息标记为已读**；面板自己维护未读状态。

> **不要在该系统上运行 `sms delete read`。** 因为池把它见过的一切都标记为已读，这会删掉没人看过的
> 消息。请从面板删除，或用 `openf50-sms delete`（它只在加 `--sim` 时才碰 SIM）。自动化请用面板的钩子
> `/etc/openf50/sms-hook`，而不是 `sms watch`。

## 短信转发

在带控制面板的 OpenWrt 上，**Cellular > SMS forwarding** 把收到的消息转发到 webhook（JSON 或表单）、
Telegram 聊天或经短信转发到另一部手机。它默认关闭，需要你打开。每个目标有一个模板（`{sender}`、
`{time}`、`{text}`、`{device}`），可按发送方和关键词过滤；有 "Send test" 按钮和投递日志，失败的投递
会以逐渐拉长的间隔重试。令牌、密码和 webhook 地址留在 `/etc/openf50/sms-forward.conf`（仅 root）里，
从不出现在日志中。邮件转发需要 `msmtp`，镜像未包含。

从 v2026.10.23 起 webhook 可以发送自定义正文，代替标准字段（`sender`、`time`、`text`、`device`、
`message`），以适应想要自己格式的服务（Lark/飞书、钉钉、企业微信、Slack、Discord、Bark、ntfy）。选择
类型（JSON、表单或纯文本；它会设置 `Content-Type`），在 "Custom body" 下写正文，用占位符 `{sender}`、
`{time}`、`{text}`、`{device}` 和 `{message}`（填好的消息模板）。每个值按类型转义——JSON 里作为
字符串内部内容，所以引号自己写：

```json
{"msg_type": "text", "content": {"text": "{message}"}}
```

表单正文里值会做百分号编码（`title={sender}&body={text}`）；纯文本里原样放入，空正文就是消息本身
（对 ntfy 足够）。正文最长 2000 字节。与地址和请求头不同，它会在面板里再次显示，所以密钥和令牌请放在
地址或请求头里。"Send test" 发送同样的正文。

任何 HTTP 2xx 都算投递成功。从 v2026.10.23 之后的发布包起，webhook 还可以检查应答：许多聊天服务即使
拒绝消息也回答 200，并在正文里说明；对这类服务，在 "The answer must contain" 里填入正常应答应有的键
和值：

| 服务 | 应答必须包含 |
|---|---|
| 钉钉、企业微信 | `errcode=0` |
| 飞书 / Lark | `code=0` |
| Slack Web API、Telegram Bot API | `ok=true` |
| Bark | 不需要（失败时它回答 HTTP 400/500）；`code=200` 也可用 |
| Slack incoming webhook、Discord、ntfy | 留空：它们用 HTTP 状态码应答，不用 JSON |

应答随后必须是顶层含有该键该值的 JSON 对象。如果键是另一个值，投递失败并像其他失败一样重试，日志会
显示（`HTTP 200, the service answered errcode=310000`；不是整数、`true`、`false` 或 `null` 的值不显示，
只说明是另一个值）。如果应答里没有这个值（`no errcode in the answer`），投递失败且**不再**重发，因为
消息很可能已经到达：用 "Send test" 验证规则（它也应用该规则，最多每 5 秒一次）。设备最多读取应答的
前 4096 字节，在内存中，只保留结果：应答本身从不记录或显示。键是由字母、数字和 `_` 组成的名字（最多
32 个）；值是整数或小写字母（最多 16 个）。

投递日志保存在内存里（最后 100 行，重启后丢失）；下面的 "Clear" 清空它。仍在等待投递的消息不受影响。

从 v2026.10.18 起，消息只有在副本落盘后才从 SIM 删除，所以断电也不会丢；其余部分迟迟不到的长短信会
在一小时后显示，标记为不完整。

## USSD

查余额之类的代码：

```sh
sudo openf50-ussd '*101#'
```

## 为什么用 PDU 模式

调制解调器的文本模式会弄乱名字而非号码的发送方，也无法看出几个存储部分其实是一条长短信，所以 `sms`
使用 PDU 模式并自行解码帧，包括土耳其语国家语言移位。发送时每个字符都装得下就用 GSM 7-bit，否则用
UCS-2。细节：
[FINDINGS 26c](https://github.com/dikeckaan/openf50-linux/blob/main/docs/FINDINGS.md#26c-sms-needs-pdu-mode-and-turkish-needs-more-than-that)。

## 语音通话

不可用：板子没有扬声器和麦克风，经调制解调器音频 DSP 的通话音频仍在开发中，还传不出声音。见
[Hardware Notes](Hardware-Notes#no-sound-no-screen)。
