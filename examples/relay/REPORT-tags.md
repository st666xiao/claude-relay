# 报告：tags

提交：`a1b2c3d feat: bookmark tags (T1-T5)`

| T | 做了什么 | 文件 |
|---|---|---|
| T1 | 新增迁移，两张表，外键级联 | `db/migrations/005_tags.sql` |
| T2 | 新增接口，名字校验，同名复用 | `src/routes/tags.js`、`src/app.js` |
| T3 | 解除关联，清理无引用标签 | `src/routes/tags.js` |
| T4 | 筛选 + 返回 tags 字段 | `src/routes/bookmarks.js` |
| T5 | 标签列表和计数 | `src/routes/tags.js` |

测试：`npm test` → `51 passed, 0 failed, 2 skipped`
验收：`node scripts/acceptance-tags.js` → `PASS 17 / FAIL 0`

## 没能验证
- 大数据量下 `GET /bookmarks?tag=` 的性能。

## 拿不准
- T4 "忽略大小写"：SQLite 的 `COLLATE NOCASE` 只对 ASCII 有效，中文标签没有大小写问题，所以直接用了它。

## 没做什么
未部署；未修改受保护文件；未 push。
