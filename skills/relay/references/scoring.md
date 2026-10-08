# S8 打分

目的：给每次交付记一个可比较的分数。时间长了能看出：
- 同一个执行模型的质量有没有波动（比如被认为"降智"的时候）；
- 波动发生时，验收脚本和审查有没有把最终交付拉回合格线。

所以要记两个分：**首轮分**（执行者第一次交付的原始质量）和**最终分**（返工后的结果）。首轮分掉了但最终分稳定，说明流程兜住了。

只用文件里能数出来的数字，不凭印象打分。

## 数据来源

| 字段 | 从哪里数 |
|---|---|
| `t_total` | TASK 里的 T 数量 |
| `t_pass_first` | 第一轮 `CHECK-<name>-accept.md`（没有 `-<k>` 后缀的那个）里 pass 的 T 数 |
| `r_high` / `r_mid` / `r_low` | 第一份 `REVIEW-<name>.md` 里各级问题数（第一轮因全面失败跳过了审查时，用第一份出现的 REVIEW，并在 note 里写明） |
| `rework_rounds` | `TASK-<name>-fix-<k>.md` 的数量 |
| `violations` | 改了受保护文件 + 改了范围外文件 + 做了禁止操作（部署、push --force、碰远程机器等）的次数。范围内改动连带产生的文件（锁文件、生成文件）不算；和任务无关的改动算 |
| `false_claims` | 报告说做了但没做、报告"全部通过"但有 skip/fail、证据对不上的次数 |
| `evidence_ratio` | 任务书要求的证据（退出码、hash、截图、执行记录）交了几成，0～1 |
| `final_pass` | 最后一次验收是否全部 pass，且审查无"高" |

## 首轮分（0～100）

```
100
− 30 × (1 − t_pass_first / t_total)
− min(30, 10×r_high + 3×r_mid + 1×r_low)
− 15 × violations
− 15 × false_claims
− 10 × (1 − evidence_ratio)
最低 0
```

## 最终分（0～100）

```
final_pass 为真：100 − 10 × rework_rounds − 15 × violations − 15 × false_claims（最低 0）
final_pass 为假：0
```

## 记录

不要自己算，用脚本（`<relay skill 目录>` 是本文件上一级的上一级，默认安装在 `~/.claude/skills/relay`；会计算两个分数、追加到 `~/.claude/relay-scores.jsonl`、打印该模型的历史平均）：

```
python3 <relay skill 目录>/scripts/score.py add '<下面的 JSON，不含 first_score / final_score / size>'
python3 <relay skill 目录>/scripts/score.py summary
```

日志所有项目共用，便于跨项目比较同一个执行模型。一行的样子：

```json
{"date":"2026-10-08","project":"<项目名>","task":"<name>","workflow":"relay","executor":"<工具>","model":"<模型名>","effort":"<如果知道>","t_total":7,"t_pass_first":6,"r_high":1,"r_mid":4,"r_low":3,"rework_rounds":1,"violations":0,"false_claims":0,"evidence_ratio":1.0,"final_pass":true,"first_score":71,"final_score":90,"size":"M","note":"<一句话>"}
```

- `size`：S（≤3 个 T）/ M（4～8）/ L（>8）。分数只和同尺寸比较。
- `model` 写执行工具里实际显示的模型名；不知道就写 `unknown`，不要猜。`unknown` 的记录不参与历史平均。
- 开启方式：用户说"打分""score"；之后日志文件存在，每次自动打分；用户说"不打分"就跳过这次。
- `relay-os` 也打分（executor = `claude-code`，model = Sonnet 的版本）。`relay-oh` 不打这个分。

## 汇报和查看

- S7 汇报末尾加一句："首轮 71 / 最终 90；<模型> 在 M 尺寸任务的历史平均：首轮 66 / 最终 88（共 5 次）。"
- 首轮分比该模型同尺寸平均低 15 分以上：提醒用户，并说明主要扣在哪一项。
- 用户说"看看分数"：跑 `score.py summary`，把表格给用户，再用一两句话解读。记录少于 5 条时说明样本太少，不下结论。
