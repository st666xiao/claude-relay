# SWARM alt-text：给文档里的图片补 alt 文字

24 张图片缺 alt 文字（`grep -rn '!\[\](' docs/` 找到），分布在 12 个 Markdown 文件里。
分 4 份，每份 3 个文件，**每份只改自己的文件**。

| 份 | 文件 |
|---|---|
| 1 | `docs/install.md`、`docs/config.md`、`docs/cli.md` |
| 2 | `docs/api/auth.md`、`docs/api/bookmarks.md`、`docs/api/tags.md` |
| 3 | `docs/guide/import.md`、`docs/guide/export.md`、`docs/guide/sync.md` |
| 4 | `docs/faq.md`、`docs/changelog.md`、`docs/contributing.md` |

## 给 Haiku 的说明（W2，每份都发同一段，只换"你负责的文件"）

```
目标：给 Markdown 里 alt 为空的图片补上 alt 文字。

步骤：
1. 在你负责的文件里找所有 `![](路径)`。
2. 打开图片，看图片内容，结合图片前后两段文字。
3. 写 alt：中文，8～25 字，说明图里是什么，不写"图片""截图"开头。
4. 只替换 `![]` 里的空 alt，其余一个字都不改。

样例：
输入：
  运行导入命令后会看到进度条：
  ![](img/import-progress.png)
输出：
  运行导入命令后会看到进度条：
  ![导入书签时终端里的进度条和已导入数量](img/import-progress.png)

规则：
- 只改你负责的文件。不改图片，不改其他文字，不 git commit。
- 图片打不开或看不出内容：不改这一处，记一行 `UNSURE: <文件>:<行号> <原因>`。
- 最后一行写：`完成 X 条，UNSURE Y 条，失败 Z 条`。

你负责的文件：<第 N 份的文件>
```

## 过程记录（W3–W6）
- W3 试跑第 1、2 份：第 2 份把 alt 写成了英文 → 说明里加上"中文"，重跑第 2 份后正常。
- W4 并行跑第 3、4 份。
- W5 抽查 5 处（含 2 条 UNSURE 和最长的一条）：都对。`git diff --stat` 只有这 12 个文件变化。
- W6 汇报：24 处，完成 22，UNSURE 2（`docs/faq.md:40` 图片 404；`docs/sync.md:12` 图是纯色占位图），交给用户决定。
