# Greptile 标签门控验证（一次性）

本文件仅用于验证 `.greptile/config.json` 的 `labels` 过滤是否生效，随测试 PR 关闭，不会合入 main。

验证步骤：

1. 不打标签时，Greptile 不应评审本 PR
2. 打上 `deep-review` 标签后，Greptile 应起审
