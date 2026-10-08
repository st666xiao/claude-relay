---
name: relay-os
description: 不交给外部模型（Codex、DeepSeek、GLM 等）的内部接力流程：Opus 计划 → Haiku 收集现状 → Sonnet 子代理实现 → Haiku 机械验收 → Opus 审查 → 汇报。用户说"不用外部模型""不用 Codex""不外包""你们自己做""Opus 和 Sonnet 做"，或任务需要多轮修改、不想来回切 Codex 时用这个。
---

# Relay-os：Opus + Sonnet（+ Haiku）

**开始前先读 `~/.claude/skills/relay/references/fit-check.md`，判断这个任务适不适合走流程，给用户反馈，等用户回复再开始。**

规则文件 `~/.claude/skills/relay/references/lessons.md`：到写任务书、验收、审查、部署时读对应的节。

和 `/relay` 一样的步骤和文件，区别只有执行者和审查者。任务书模板用 `~/.claude/skills/relay/references/task-template.md`。

## 角色

| 角色 | 做什么 | 不做什么 |
|---|---|---|
| **Opus（你）** | 计划、任务书、验收脚本、**审查**、汇报、部署 | 不写功能代码（设计类例外，见下） |
| **Sonnet 子代理** | 按任务书实现、提交、写报告 | 不部署、不改任务书和验收脚本 |
| **haiku-checker** | S0 收集现状；S4 跑测试和验收脚本，原样报告 | 不改代码、不下结论 |
| **用户** | 批准计划、确认部署 | — |

**Haiku 放在哪里：** 还是 S0 和 S4，夹在"Sonnet 写完"和"Opus 审查"之间。原因：
- 写代码的人不应该自己证明自己做完了。Sonnet 报告里说"测试通过"，要有另一个角色独立再跑一遍。
- Opus 审查时只看 Haiku 的事实报告和 diff，不用自己跑测试、读 log，最贵的额度省在这里。

**设计类例外：** 视觉设计上 Opus 通常比其他模型做得更有区分度。界面/视觉/交互结构类任务，改成 Opus 实现、Sonnet 子代理（`sonnet-reviewer`）审查。开始前在 S1 里说明用哪种。

## 流程

S0 → S1 → S2 和 `/relay` 相同（Haiku 收集现状 → 计划等用户确认 → 写 `TASK-<name>.md` 和验收脚本）。

### S3 Sonnet 实现
```
Agent(model="sonnet", subagent_type="general-purpose", isolation="worktree", prompt="读 <项目>/TASK-<name>.md 并按它完成。做完写 REPORT-<name>.md，列出每个 T 改了什么、提交号、拿不准的地方。遵守任务书的规则部分。")
```
- 用 `isolation: "worktree"`，Sonnet 在独立的工作区改，出问题不影响主目录。项目不是 git 仓库就去掉这个参数，并在任务书里写清楚可改的目录。
- 任务书分段的，一段一个子代理调用，每段过了 S4 再做下一段。

### S4 Haiku 验收
和 `/relay` 相同：`haiku-checker`，模式 `accept`，在 Sonnet 的 worktree 里跑。有 fail → 直接 S6。

### S5 Opus 审查 → `REVIEW-<name>.md`
你自己读 diff、任务书、Sonnet 报告、Haiku 验收报告，按 `R1…` 编号写问题（严重程度 + `file:line`）。
重点看测试覆盖不到的：逻辑、边界、和任务书不一致、报告说做了实际没做的。

### S6 返工
把要修的 `R` 发给**同一个** Sonnet 子代理继续（用 SendMessage，它还记得上下文），不要重新开一个。回到 S4。超过 2 轮停下来和用户讨论。

### S7 汇报
和 `/relay` 相同。worktree 里的提交要合回主分支时，先告诉用户合哪些提交，再合。

### S8 打分（可选）
和 `/relay` 相同，按 `~/.claude/skills/relay/references/scoring.md`；executor 写 `claude-code`，model 写 Sonnet 的版本。
