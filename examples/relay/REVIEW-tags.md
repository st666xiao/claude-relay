# 审查：tags
结论：返工

| R | 严重程度 | 问题 | 位置 | 对应 T |
|---|---|---|---|---|
| R1 | 高 | `DELETE /bookmarks/:id/tags/:tagId` 只检查书签归属，没检查 tag 归属；用别人的 tagId 能删掉别人的无引用标签 | `src/routes/tags.js:61` | T3 |
| R2 | 中 | 筛选用 `WHERE name = ?` 没加 `COLLATE NOCASE`，和报告说法不一致（即验收 4c 失败原因） | `src/routes/bookmarks.js:55` | T4 |
| R3 | 中 | 每条书签单独查一次 tags（N+1） | `src/routes/bookmarks.js:70-78` | T4 |
| R4 | 低 | 新增依赖 `slugify` 没有用到 | `package.json:21` | — |

## 疑问
- 两个 `it.skip` 的测试正好覆盖 R2 和级联删除，是否有意跳过？

## 做得好的地方
迁移在两种库上都能跑；同名复用的事务处理正确。
