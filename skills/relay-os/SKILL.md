---
name: relay-os
description: 不交给外部模型（Codex、DeepSeek、GLM 等）的内部接力流程：Opus 计划 → Haiku 收集现状 → Sonnet 子代理实现 → Haiku 机械验收 → Opus 审查 → 汇报。用户说"不用外部模型""不用 Codex""不外包""你们自己做""Opus 和 Sonnet 做"，或 "relay-os""Sonnet implements, Opus reviews"，或任务需要多轮修改、不想来回切工具时用这个。
---

# Relay-os：Opus + Sonnet（+ Haiku）

本 skill 依赖同级目录的 `relay` skill（三个 skill 要一起安装）。下文 `../relay/` 指与本 skill 目录同级的 `relay` 目录。

**第一步：读 `../relay/references/fit-check.md`，判断任务适不适合走流程，给用户反馈，等回复再开始。**

步骤、文件命名、S4/S5 的判断条件、S7、S8 都和 `../relay/SKILL.md` 相同，先读它。本文件只写不同的地方。
规则 `../relay/references/lessons.md`、任务书清单 `../relay/references/task-template.md`。

## 角色

| 角色 | 做什么 | 不做什么 |
|---|---|---|
| **Opus（你）** | 计划、任务书、验收脚本、**审查**、汇报；用户同意后部署 | 不写功能代码（设计类例外，见下） |
| **Sonnet 子代理** | 按任务书实现、提交、写报告 | 不部署、不改任务书和验收脚本 |
| **haiku-checker** | S0 收集现状；S4 跑测试和验收脚本，原样报告 | 不改代码、不下结论 |
| **用户** | 批准计划、确认每次部署 | — |

**Haiku 在 S0 和 S4**，夹在"Sonnet 写完"和"Opus 审查"之间：写代码的人不该自己证明自己做完了；Opus 审查时只看 Haiku 的事实报告和 diff，不用自己跑测试、读 log。

**设计类例外：** 界面 / 视觉 / 交互结构类任务，改成 Opus 实现、`sonnet-reviewer` 审查（Opus 通常做得更有区分度）。在 S1 里说明用哪种。

## 和 `/relay` 不同的步骤

### S2 之后：先提交任务书和验收脚本
S3 的 Sonnet 在独立 worktree 里工作，worktree 从**当前提交**创建，看不到没提交的文件。所以 S3 之前：
- 把 `TASK-<name>.md` 和验收脚本提交（提交前告诉用户提交哪些文件），记下这个提交作为基线。
- 项目不是 git 仓库：不用 worktree，在任务书里写清楚允许改的目录。

### S3 Sonnet 实现
```
Agent(model="sonnet", subagent_type="general-purpose", isolation="worktree", prompt="读 TASK-<name>.md 并按它完成全部 T。做完写 REPORT-<name>.md：每个 T 改了什么、提交号、证据、拿不准的地方。遵守任务书的规则部分。最后告诉我你的 worktree 路径和分支名。")
```
任务书分段的，一段一个调用，每段过了 S4 再做下一段。

### S4 Haiku 验收
同 `/relay`，但 prompt 里加 `工作目录: <Sonnet 的 worktree 路径>`，让 Haiku 在那里跑。

### S5 Opus 审查 → `REVIEW-<name>*.md`
你自己读 diff（`git diff <基线>..<Sonnet 分支>`）、任务书、Sonnet 报告、Haiku 验收报告，按 `R1…` 编号写问题（严重程度 + `file:line`）。
重点看测试覆盖不到的：逻辑、边界、和任务书不一致、报告说做了实际没做的。
判据和 `sonnet-reviewer` 一样：有高级问题才"返工"；中级问题有返工轮就一起修，没有就列给用户。

### S6 返工
优先用 SendMessage 让**同一个** Sonnet 子代理继续（它记得上下文）。如果它已经结束、无法继续：开一个新的 Sonnet 子代理，在同一个 worktree 里做，prompt 里给 `TASK-<name>.md`、`TASK-<name>-fix-<k>.md`、上一轮的 REPORT。回到 S4。超过 2 轮停下和用户讨论。

### S7 合并
worktree 里的提交要合回主分支时，先告诉用户合哪些提交，用户同意后再合。

### S8 打分
同 `/relay`。executor 写 `claude-code`；model 写实际写代码的模型（Sonnet 的版本；设计类例外时写 Opus 的版本）。
