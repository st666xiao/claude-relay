# claude-relay

[English](README.en.md)

让 Claude Code 里的 **Opus 当总指挥**：它定计划、写任务书和验收脚本；写代码交给"干活模型"，验收交给 Haiku，审查交给 Sonnet。三个命令，三种分工。

## 安装（可以直接把这一节交给 AI 执行）

需要：Claude Code，能用 Opus、Sonnet、Haiku 子代理；macOS 或 Linux，有 `git` 和 `bash`。

**第一次安装：**

```bash
git clone https://github.com/st666xiao/claude-relay.git ~/claude-relay
~/claude-relay/install.sh -y
```

**升级到最新版：**

```bash
cd ~/claude-relay && git pull && ./install.sh -y
```

- `-y` 表示不逐个确认，直接覆盖。被覆盖的旧版先备份到 `~/.claude/backups/claude-relay-<时间>/`。不加 `-y` 时，每个已存在的文件都会问一次。
- 会装到这些位置：`~/.claude/skills/relay`、`~/.claude/skills/relay-os`、`~/.claude/skills/relay-oh`，以及 `~/.claude/agents/` 下的 `haiku-checker.md`、`haiku-worker.md`、`sonnet-reviewer.md`。三个 skill 互相引用，必须一起装。
- 检查是否装好：`ls ~/.claude/skills/relay/SKILL.md ~/.claude/agents/haiku-checker.md`，两个文件都在就说明装好了。
- 装完要**新开一个 Claude Code session** 才能用：输入 `/relay 任务描述`、`/relay-os 任务描述` 或 `/relay-oh 任务描述`。
- 打分记录在 `~/.claude/relay-scores.jsonl`，升级不会动它。

**可选：让 Opus 直接派活给外部模型。** 不装也能用，Opus 会给你一段提示词，你自己粘贴到干活工具里。

| 外部模型 | 先准备好 | 检查命令 |
|---|---|---|
| Grok | 装好 Cursor CLI 并登录 | `cursor-agent --list-models` 能列出 grok 模型 |
| Codex | 装好 Codex CLI，或者 ChatGPT 桌面版自带的那份，并登录 | `codex login status` |

然后在对话里告诉 Opus“可以直接调用 Grok / Codex CLI”。具体用法见 `skills/relay/references/grok.md` 和 `codex.md`。

注意：验收时 Haiku 会运行干活模型写出来的代码和测试，请只在你信任的项目目录里使用。

## 三种模式

```mermaid
flowchart LR
  subgraph R["/relay 标准版"]
    direction LR
    r1[Opus<br/>计划 + 任务书] --> r2[外部干活模型<br/>Grok / Codex / DeepSeek / GLM…] --> r3[Haiku<br/>跑验收] --> r4[Sonnet<br/>审查] --> r5[Opus<br/>汇报]
  end
  subgraph OS["/relay-os"]
    direction LR
    o1[Opus<br/>计划 + 任务书] --> o2[Sonnet<br/>写代码] --> o3[Haiku<br/>跑验收] --> o4[Opus<br/>审查 + 汇报]
  end
  subgraph OH["/relay-oh"]
    direction LR
    h1[Opus<br/>拆分 + 说明] --> h2[Haiku × N<br/>并行干活] --> h3[Opus<br/>抽查 + 汇报]
  end
```

| | `/relay` | `/relay-os` | `/relay-oh` |
|---|---|---|---|
| 写代码 | 外部干活模型 | Sonnet | 多个 Haiku 并行 |
| 验收 | Haiku | Haiku | Haiku |
| 审查 | Sonnet | Opus | Opus 抽查 |
| 适合 | 大功能 | 中等功能、多轮修改 | 量大、每份一样的小活 |
| 用谁的额度 | 主要是外部模型 | Claude | Claude（Haiku 很省） |

**外部干活模型**：要用能直接读写项目目录、运行命令的编码工具，比如 Codex desktop，或者接上 DeepSeek、GLM 的 Cursor、Cline 等。只有聊天窗口的不行。装了 Cursor CLI（Grok）或 Codex CLI 并授权后，Opus 可以用自带的 `scripts/grok.sh`、`scripts/codex.sh` 直接派活，不用你来回粘贴（说明在 `skills/relay/references/grok.md`、`codex.md`）。约束力强、按要求干活的模型最合适——任务书写得越具体，对模型本身能力的依赖越小。

## 一次 `/relay` 的过程

```mermaid
flowchart TD
  F{Opus 先判断<br/>适不适合走流程} -->|不适合| D[建议直接做 / 先讨论]
  F -->|适合| S0[S0 Haiku 查现状]
  S0 --> S1[S1 Opus 出计划]
  S1 --> U1{你确认}
  U1 --> S2[S2 任务书 + 验收脚本]
  S2 --> S3[S3 你把交接提示词<br/>贴给干活模型]
  S3 --> S4[S4 Haiku 跑测试和验收脚本]
  S4 -->|构建失败或大半 fail| S6[S6 返工单]
  S4 -->|其余| S5[S5 Sonnet 审查]
  S5 -->|有 fail 或需返工| S6
  S6 --> S3
  S5 -->|通过| S7[S7 汇报 → 预览环境实测]
  S7 --> U2{你确认每次部署}
  S7 -.可选.-> S8[S8 打分]
```

每一步产出一个文件（`TASK-` / `REPORT-` / `CHECK-` / `REVIEW-`），换 session、换模型都能接上。完整样例见 [examples/](examples/)。

## 打分：模型"降智"了怎么办

很多人觉得模型时好时坏。这套流程的思路是：**不依赖模型每次都发挥好，用验收脚本和审查把结果拉回合格线**，并且把每次的情况记下来。

每次交付记两个分：
- **首轮分**：干活模型第一次交出来的原始质量（验收通过率、审查问题数、越界、报告不实）
- **最终分**：返工之后的结果

```mermaid
xychart-beta
  title "示意图（不是实测数据）：首轮分波动，返工后仍然通过"
  x-axis ["任务1","任务2","任务3","任务4","任务5","任务6","任务7","任务8"]
  y-axis "分数" 0 --> 100
  line [78, 72, 45, 80, 52, 75, 40, 70]
  line [92, 90, 82, 95, 85, 90, 80, 88]
```

最终分只要验收和审查都过了就会偏高，所以它说明的是"交付是否合格"，不是模型多强。更值得看的是**首轮分的波动和返工轮数**：首轮分掉下去、返工多了一轮、最终仍然通过，就是流程兜住了一次。这是记录，不是证明；样本多了才有意义。

分数由脚本计算（`skills/relay/scripts/score.py`），记录在 `~/.claude/relay-scores.jsonl`，说一句"看看分数"就能按模型汇总。打分是可选的：说"打分"开启，之后每次自动打分，说"不打分"跳过。

**欢迎把你的 `score.py summary` 结果贴到 issue 里**，样本多了才能真正看出不同模型的差别。

## 仓库里有什么

```
skills/relay/            标准版 + 共用的规则、任务书清单、打分脚本
skills/relay-os/         Opus + Sonnet
skills/relay-oh/         Opus + 多个 Haiku
agents/                  haiku-checker / haiku-worker / sonnet-reviewer
examples/                一次完整流程的全部文件（虚构项目）
```

skill 文件是写给 AI 看的（中文），回复会用你说话的语言。

## 反馈

这三个 skill 就是靠使用中的反馈一点点改出来的，欢迎告诉我们哪里好用、哪里别扭。两种方式：

- **自己提**：开一个 [使用反馈 issue](../../issues/new?template=feedback.yml)，写用了哪个命令、什么任务、哪里顺、哪里别扭。有打分数据更好。
- **让 Claude 帮你提**：对 Claude 说"给 relay 提反馈"，它会起草一条反馈给你看，你同意后它才会发出去：装了并登录了 `gh` 时由它直接发，没有的话把内容给你自己贴。

另外，如果一次流程里碰到了 skill 本身的问题（说明写错、脚本报错、流程导致返工），Claude 会在汇报末尾问一句要不要反馈。规则：
- 顺利的时候不问，同一个 session 最多问一次。
- 起草时会去掉项目名、路径、代码和 log 原文，发出前一定先给你看完整内容。
- 回答"不用，别再问了"就永远不再问（会写入 `~/.claude/relay-feedback`，删掉这个文件就能恢复）。

详细规则见 [`skills/relay/references/feedback.md`](skills/relay/references/feedback.md)。

## License

[MIT](LICENSE)
