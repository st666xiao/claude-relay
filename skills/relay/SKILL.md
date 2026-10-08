---
name: relay
description: 多模型接力开发流程：Opus 定计划写任务书 → Haiku 收集现状 → 外部执行模型（Codex、DeepSeek、GLM 等"干活模型"）写代码 → Haiku 机械验收 → Sonnet 审查 → Opus 汇报，可选给执行者打分。用户说"走流程""按老规矩""写任务书""交给 Codex / DeepSeek / GLM 做""让 Sonnet 审查""验收一下""打分"，或要做一个需要别的模型实现的功能/修复时，都用这个 skill，即使没说"relay"。
---

# Relay：多模型接力流程

**第一步：读 `references/fit-check.md`，判断任务适不适合走流程，给用户反馈，等回复再开始 S0。**

规则文件 `references/lessons.md`：到 S2、S4、S5、S7 时读对应的节（每节几行）。

## 变体

| 命令 | 谁写代码 | 谁审查 | 适合 |
|---|---|---|---|
| `/relay`（本文件） | 外部执行模型 | Sonnet | 大功能，用用户在别处的额度 |
| `/relay-os` | Sonnet 子代理 | Opus | 不想切工具、要多轮修改 |
| `/relay-oh` | 多个 Haiku 并行 | Opus 抽查 | 量大、每份一样、不太需要审查 |

任务明显更适合另一个变体时，在 S1 提一句让用户选。

## 角色

| 角色 | 做什么 | 不做什么 |
|---|---|---|
| **Opus（你）** | 计划、任务书、验收脚本、读审查结论、汇报、部署、打分 | 不替执行者写功能代码（用户明说"这次你来做"除外） |
| **haiku-checker** | 只读收集现状；跑测试和验收脚本；原样贴输出 | 不改文件、不下结论 |
| **外部执行模型** | 按任务书写代码、提交、写报告 | 不部署、不改任务书和验收脚本 |
| **sonnet-reviewer** | 判断性审查 | 不重跑 Haiku 跑过的检查 |
| **用户** | 批准计划；把任务交给执行模型；确认部署 | — |

项目 memory / CLAUDE.md 里的分工规则优先于本 skill。

## 流程

每步一个文件，放在任务书旁边。下一步只读上一步的文件，所以每个文件要能独立看懂。`<name>` = 任务短名（如 `v9`、`idle-match`）。样例见仓库 `examples/`。

| 步骤 | 谁 | 产出 | 下一步条件 |
|---|---|---|---|
| S0 收集现状 | haiku-checker（survey） | `CHECK-<name>-survey.md` | 你核实它标"不确定"的项 |
| S1 计划 | 你 | 给用户的简短计划 | **用户确认** |
| S2 任务书 + 验收脚本 | 你 | `TASK-<name>.md`、验收脚本 | 用 `references/task-template.md` 清单过一遍 |
| S3 实现 | 外部执行模型 | 代码、提交、`REPORT-<name>.md` | 用户说"做完了" |
| S4 机械验收 | haiku-checker（accept） | `CHECK-<name>-accept.md` | 有 fail → S6 |
| S5 审查 | sonnet-reviewer | `REVIEW-<name>.md` | 结论"返工" → S6 |
| S6 返工 | 你写单，执行模型改 | `TASK-<name>-fix.md` | 回到 S3；超过 2 轮停下和用户讨论 |
| S7 汇报 + 部署 | 你 | 给用户的汇报 | 上生产前**用户确认** |
| S8 打分（可选） | 你 | `relay-scores.jsonl` 一行 | — |

### S2 要点
- 任务编号 `T1`、`T2`…，每条写**怎样算做完**（脚本或命令能检查）。
- 验收脚本你写；任务书声明执行者不许改。
- 设计点写死，不留给执行者猜。执行者读不到对话和 memory。

### S3 交给外部执行模型
写一段**可以直接粘贴**的交接提示词给用户，用户贴到自己的执行工具里（Codex desktop、DeepSeek、GLM、Cursor 等都可以）：

```
项目目录：<绝对路径>
读 <绝对路径>/TASK-<name>.md，按它完成全部 T。
做完写 <绝对路径>/REPORT-<name>.md。
不要修改任务书和验收脚本，不要部署。拿不准的写进报告，不要猜。
```

- 执行模型选约束力强、按要求干活的（"干活模型"）。任务书越具体，对执行模型能力的依赖越小。
- 只有用户明说"你来跑"，并且执行工具有命令行入口时，你才自己调用。
- 用户说"做完了"之后再继续。

### S4 / S5
```
Agent(subagent_type="haiku-checker", prompt="模式: accept\n任务书: <路径>\n要跑: <测试命令>; <验收脚本>\n报告写到: CHECK-<name>-accept.md")
Agent(subagent_type="sonnet-reviewer", prompt="任务书: <路径>\n执行者报告: REPORT-<name>.md\n验收报告: CHECK-<name>-accept.md\n审查写到: REVIEW-<name>.md")
```
agent 不存在时：`general-purpose` + `model: "haiku"` / `"sonnet"`，把 `~/.claude/agents/` 里对应文件的规则贴进 prompt。
你抽查审查里 1～2 条严重问题是不是真的。

### S6 返工
执行者原始提交和返工修复分开提交。`TASK-<name>-fix.md` 只写要改的 fail 和 `R`，引用原编号。

### S7 汇报 + 部署
用用户的语言，短：做了哪些 T、验收几条 pass、审查修了哪些 R、未解决的问题、需要用户决定的事。
部署：先上预览环境实测（测试全过 ≠ 真实环境能用）；上生产前问用户；保留上一版本用于回滚。
关键状态（任务名、提交号、未决事项）写进项目 memory。

### S8 打分（可选）
用户说"打分"，或 `~/.claude/relay-scores.jsonl` 已经存在时做。按 `references/scoring.md` 数出各项，用 `scripts/score.py add` 记录（不要手算）。汇报里附一句分数和该执行模型的历史平均。

## 为什么这样分工
- Haiku 额度消耗少：读文件、跑测试交给它，判断留给 Sonnet 和你。
- 机械检查先跑：测试没过就不花审查额度。
- Haiku 只报事实不下结论：它可能把"看起来没问题"当成"没问题"。
- 执行模型的质量会波动；流程靠验收脚本和审查兜底，打分记录波动有多大、兜底有没有起作用。
