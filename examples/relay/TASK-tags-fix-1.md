# 返工单 tags-fix-1（第 1 轮）

只改下面几项，其余不动。规则、验收、报告要求同 `TASK-tags.md`。修复单独提交，不要改写原提交。

- 验收 4c 失败 / R2：`GET /bookmarks?tag=` 按名字忽略大小写匹配。
- R1：解除关联前检查 tag 属于当前用户，不是则 404。补一条测试。
- R3：tags 用一次查询批量取回。
- R4：删除未使用的依赖 `slugify`。
- 去掉 `test/tags.test.js` 里的两个 `it.skip`，让它们真正运行并通过。

报告写到 `REPORT-tags-fix-1.md`。修完后的验收写到 `CHECK-tags-accept-1.md`，不覆盖第一轮。
