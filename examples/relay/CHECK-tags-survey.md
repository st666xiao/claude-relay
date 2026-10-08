# 现状：tags

| # | 问题 | 结果 | 证据 |
|---|---|---|---|
| 1 | 数据库是什么、迁移怎么跑 | SQLite，`npm run migrate`，迁移在 `db/migrations/`，最新是 `004_add_folders.sql` | `ls db/migrations` |
| 2 | 书签表结构 | `bookmarks(id, user_id, url, title, folder_id, created_at)` | `db/migrations/001_init.sql:3-10` |
| 3 | 测试怎么跑、现在过不过 | `npm test`，42 passed, 0 failed, 0 skipped | 命令输出末尾 3 行 |
| 4 | 路由在哪 | `src/routes/bookmarks.js`，用 `createApp({ db, clock })` 注入依赖 | `src/app.js:12` |
| 5 | 有没有现成的"按字段筛选" | `GET /bookmarks?folder=` 已有，实现在 `src/routes/bookmarks.js:48` | — |

## 不确定
- README 说"支持全文搜索"，代码里没找到对应实现。

## 和交接文档 / memory 不一致的地方
- `HANDOFF.md` 写测试是 38 个，实际 42 个。
