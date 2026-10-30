# 用 Codex CLI 做执行者

用户授权后，Opus 可以直接用 Codex CLI 派活，不用让用户去 Codex desktop 粘贴。没授权、或用户想自己在 Codex desktop 里跑时，照 SKILL.md S3 给交接提示词。

## 怎么调
用包装脚本 `scripts/codex.sh`（自己找可执行文件、写日志、只打最终回答）：

```bash
~/.claude/skills/relay/scripts/codex.sh -m gpt-6.1-terra -w <项目目录> "读 <绝对路径>/TASK-x.md，按它完成全部 T，做完写 REPORT-x.md。不要改任务书和验收脚本。"
~/.claude/skills/relay/scripts/codex.sh -r -w <目录> "只读：……"
```

- Bash 用 `run_in_background`，等通知，不要轮询。
- 可执行文件：Claude 的 shell 里 `codex` 通常不在 PATH，脚本会退到 `/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex`。ChatGPT 更新后路径可能变，找不到就 `mdfind -name CodexCLI.app`。
- 裸命令：`codex exec --skip-git-repo-check -s workspace-write -C <dir> -m <模型> -o <最终回答文件> - < 提示词文件`。参数以 `codex exec --help` 为准（2026-10-30 核对过 0.165）。
- 续聊返工：`codex exec resume --last` 或 `resume <id>`；一般直接开新调用、给返工单路径就够了。
- 不用 `--dangerously-bypass-approvals-and-sandbox`。

## 选模型
- 用户叫法 → `-m` 值：6.1 sol → `gpt-6.1-sol`，6.1 terra → `gpt-6.1-terra`。不传就用 `~/.codex/config.toml` 的默认值（2026-10 是 gpt-6.1-terra）。
- 用户点名哪个用哪个；没点名用默认值，在 S1 计划里写明。

## 沙箱的坑（`-s workspace-write`）
2026-10-28 实测出现过：
- **不能绑定或连接本机端口**：起本地服务、连 127.0.0.1 上的假服务的测试会失败（"12 pass, 7 fail"，全是沙箱造成的）。这类检查在任务书里写成"留给 Opus 跑"，S4 由 haiku-checker 或你在沙箱外跑，不算执行者 fail。
- **git 提交可能失败**：报告会说提交失败。由你代为提交前先看 diff，并在 S4 用 `git status --porcelain` 核对未提交的改动。
- 日志文件（`.codex-run.log`、`.codex-last.txt`）放在工作目录；项目是 git 仓库时加进 `.gitignore`，别让执行者 `git add` 它们。

## 失败时
- 额度用完（日志里有 usage limit / 429）：别重试，按 SKILL.md「换执行者」处理。
- 登录问题：`codex login status`；没登录让用户自己 `codex login`，不碰凭据文件。
- 它的报告说"测试都通过了"：那是它沙箱里能跑的部分，以验收脚本为准。
