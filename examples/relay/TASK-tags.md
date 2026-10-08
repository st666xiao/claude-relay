# 任务书 tags：书签标签和按标签筛选

## 前提
- 项目目录 `/home/dev/bookmarks-api`。`npm install && npm run migrate && npm test`。
- 依赖注入：`createApp({ db, clock })`（`src/app.js`）。不要绕开它直接用全局数据库连接。

## 范围
- 一段完成。只做后端接口和迁移，不做前端。
- 不做：标签改名、标签颜色、全文搜索。

### T1 迁移 `005_tags.sql`
- 新表 `tags(id, user_id, name, created_at)`，`(user_id, name)` 唯一。
- 新表 `bookmark_tags(bookmark_id, tag_id)`，主键是两列组合；删除书签或标签时级联删除。
- 做完的标准：`npm run migrate` 在空库和已有 004 的库上都成功。

### T2 `POST /bookmarks/:id/tags { name }`
- `name` 去掉首尾空格后 1～30 字，否则 400 `code: 'TAG_NAME_INVALID'`。
- 同一用户同名标签复用已有的；同一书签重复加同一标签不报错，返回 200 和当前标签列表。
- 书签不是当前用户的：404。

### T3 `DELETE /bookmarks/:id/tags/:tagId`
- 只解除关联。标签不再被任何书签使用时一起删除。

### T4 `GET /bookmarks?tag=<name>`
- 可以和已有的 `folder=` 一起用（取交集）。`tag` 按名字精确匹配，忽略大小写。
- 每条书签返回里增加 `tags: [{ id, name }]`，按 `name` 排序。

### T5 `GET /tags`
- 当前用户的全部标签和各自的书签数：`[{ id, name, count }]`，按 `count` 降序、`name` 升序。

## 验收
验收脚本由 Claude 维护，不允许修改：`scripts/acceptance-tags.js`、`scripts/lib/harness.js`。
`node scripts/acceptance-tags.js` 全部 PASS、`npm test` 全部通过且无 skip，才算完成。

## 审查要点（交付前自己先过一遍）
- 删书签、删标签时有没有留下孤立的 `bookmark_tags` 行。
- 别的用户能不能通过 tagId 解除我的标签。
- `GET /bookmarks?tag=` 有没有 N+1 查询。

## 规则
- 每条新规则都要有自动化测试。
- 做完用 git 提交一次；不要 reset / rebase / push --force；不要部署。
- 不要修改 `TASK-*.md`、`scripts/acceptance-*.js`、`scripts/lib/`。
- 拿不准的写进报告，不要猜。

## 报告
写到 `REPORT-tags.md`：每个 T 做了什么、改了哪些文件、提交号、`npm test` 和验收脚本的最后几行输出、没能验证的地方、拿不准的地方，并写明"没做什么"（未部署、未改受保护文件）。
