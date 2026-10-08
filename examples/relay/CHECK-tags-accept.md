# 验收：tags
总结：4/5 pass，跳过 2 个（skip 不算 pass），偶发失败 0 个

| T | pass/fail | 证据 |
|---|---|---|
| T1 | pass | `npm run migrate` 空库、004 库均 exit 0 |
| T2 | pass | acceptance 2a–2e PASS |
| T3 | pass | acceptance 3a–3c PASS |
| T4 | **fail** | `FAIL  4c tag 忽略大小写  —  ?tag=Work 返回 0 条，期望 1 条` |
| T5 | pass | acceptance 5a–5b PASS |

## 命令输出
```
$ node scripts/acceptance-tags.js
PASS  1a 空库迁移
...
FAIL  4c tag 忽略大小写  —  ?tag=Work 返回 0 条，期望 1 条
PASS  5b count 排序
PASS 16 / FAIL 1

$ npm test
51 passed, 0 failed, 2 skipped
skipped: test/tags.test.js "case-insensitive filter" (it.skip)
skipped: test/tags.test.js "cascade on bookmark delete" (it.skip)
```

## 任务书没提到但被改动的文件
- `package-lock.json`（新增依赖 `slugify`）

## 被改动的受保护文件
无。

## 不确定
- 执行者报告写验收 `PASS 17 / FAIL 0`，实际运行是 `PASS 16 / FAIL 1`。
