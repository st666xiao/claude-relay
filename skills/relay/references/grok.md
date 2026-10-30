# 用 Grok（Cursor CLI）做执行者

用户装好 Cursor CLI（`cursor-agent` / `agent`，用能调 Grok 的账号登录）并**授权 Opus 自己调用**后，不用每次让用户去粘贴提示词。没授权就按 SKILL.md S3 的粘贴模式。

## 怎么调
用包装脚本 `scripts/grok.sh`（自动重试网络断连、只打最终回答）：

```bash
~/.claude/skills/relay/scripts/grok.sh -w <项目目录> "读 <绝对路径>/TASK-x.md，按它完成全部 T，做完写 REPORT-x.md。不要改任务书和验收脚本。"
~/.claude/skills/relay/scripts/grok.sh -r "只读：……"   # 问答 / 调研，不改文件
```

- 跑得久（几分钟到十几分钟）：Bash 用 `run_in_background`，等通知。不要 `nohup … &` 再 `while pgrep …; sleep` 轮询（10-20 这样做过，白耗回合）。
- 退出码 3：跑了很久才断连，脚本不重跑。先看工作目录和 REPORT，没做完再重派。
- 裸命令：`cursor-agent -p --trust --force --model <id> --workspace <dir> --output-format json "提示词"`。不加 `--force` 时 print 模式只提方案不落盘；`--mode ask` 只读。
- `cursor-agent models` 看当前可用模型（列表会变）。2026-10 有 `grok-4.7-{low,medium,high,xhigh}[-fast]`、`cursor-grok-4.6-*`、`cursor-grok-4.5-*`。
- 想续聊：`--resume <session_id>`（脚本 stderr 会打出 session_id）。

## 本地实测（2026-10-19）
| 测试 | 模型 | 结果 | 耗时 / 输出 token |
|---|---|---|---|
| SRT 工具（5 个函数 + CLI，9 条隐藏测试） | grok-4.7-medium-fast | 8/9；唯一不过的是任务书本身有歧义的边界，它在报告里主动点出了 | 2.7 分钟 / 14k |
| 同上 | grok-4.7-high | 8/9，同一处歧义也点出了；报告更细 | 13 分钟 / 53k |
| 读 models.json 统计 5 题（只读） | grok-4.7-medium-fast | 5/5，还发现了一个并列最大值 | 1.5 分钟 |

注意：这两次比的是 medium-fast 和 high，快慢主要来自档位（medium vs high），不能说明 fast 划算。

## 选模型
- **默认 `grok-4.7-high`（不带 fast）**。脚本默认就是它。
- **不用 `-fast`**：fast 版计费贵很多（类似 GPT 的快档，1.5 倍速度的消耗远超 1.5 倍）。不急就没必要；只有用户明说赶时间才考虑。
- 很简单的只读小问题可以用 `grok-4.7-medium` 或 `-low`（不带 fast）省一点；拿不准就用 high。
- 跑得慢没关系：后台跑，等通知。

守规矩方面表现好：没建禁止的目录、没改任务书、报告老实写"拿不准"。

## 网上的评测（2026-10）
- DeepSWE v1.1：71.0%（high），接近 GPT-5.6 Sol 72.7%、Fable 5.1 70.0%。
- Snorkel Senior SWE-Bench：tasteful pass@3 40.0%，第六。
- 独立 SWE-Together：64.7% pass@1，但 token 用量约是 4.6 的两倍。
- 共识：顶尖编码仍是 Fable 5.1；Grok 4.7 和 GPT-5.6 Sol 一档，价格便宜。
- **和 Sonnet 5.5 比**：Vals.ai 22 项共同评测里 Sonnet 赢 20 项；CursorBench 4.0 Sonnet 55.5% vs Grok 46.3%；终端类任务差距更大。

## 定位：不能平替 Sonnet
- 规格清楚的执行活（按任务书写代码、批量处理、统计查数）：可以替 Sonnet 干，省 Claude 额度，交出来照样验收。
- 判断类的活（开放式排查、多步终端操作、要看上下文的）：仍用 Sonnet。
- **S5 审查默认 sonnet-reviewer**。用户说"省 Claude 额度""让 Grok 审"时可以换 Grok 只读审查（`grok.sh -r`；实践中这样用过，审查结论经抽查属实）；但执行者是 Grok 时不让它审自己的代码。打分 note 写明"Review by grok"。

## 验收深度
按 SKILL.md「验收深度」分档，和其他执行者一样。返工也交回 Grok 改，不要我或 Sonnet 接手重写（Grok 连不上时按 SKILL.md「换执行者」）。

## 适合交给它的
- `/relay` 的 S3 执行者（按任务书写代码），尤其是要多跑几轮、想省 Claude 额度时。
- 批量、独立的小活（类似 relay-oh 的单份工作），可以并行开几个进程。
- 第二意见：同一问题让它独立做一遍，和 Sonnet / 自己的结论对照。

不适合：需要读对话上下文和 memory 的活（它看不到）；审美判断（用户自己做）；依赖用户本机专用 skill 或工具的远程操作。

## 坑
- 网络偶尔报 `Client network socket disconnected before secure TLS connection was established`，或 `Cannot use this model … Available models:` 后面是空的——都是断网，重试就好（脚本已处理）。
- `--force` 下它能跑任意 shell 命令：`-w` 指到项目目录，任务书里写清允许改的范围；验收照常走 S4 / S5，不要只信它的报告。
- 它的报告会说"测试都通过了"——那是它自己写的测试，以验收脚本为准。
- 2026-10-20 实测：长任务（约 50 分钟）结束时打出 `Cannot use this model … Available models:`（空），**但活其实全做完了**，报告也写好了——断的只是最后回传答案。旧版脚本会把整个写任务重跑一遍；现在跑过 60 秒再断就以退出码 3 停下，先看产物和 REPORT。
- 网络持续不通（12 个会话出现过 TLS 断连；10-19 用户查过代理仍失败）：别反复派，按 SKILL.md「换执行者」改用 Codex 或 Sonnet。
