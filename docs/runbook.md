# 事故处置 runbook

恢复流程的记录。规范类规则在 `AGENTS.md`，本页只写「出事了怎么恢复」。

## 回滚已合并的 PR

1. 定位引入问题的 commit：

   ```bash
   git log --oneline -20 main
   ```

   ruleset 允许 merge / squash / rebase 三种方式。squash 与 rebase 合并的 PR 在历史里是单条独立 commit，回滚它不影响其他 PR；用 merge 合并的 PR 会留下双 parent 的 merge commit，回滚时要 revert 该 merge commit 并指定 `-m 1`。

2. 在 `main` 上 revert：

   ```bash
   git checkout main && git pull
   git revert <sha>
   git push origin main
   ```

   直接推 main 需要维护者权限。如果 revert 的 revert 又出问题，重复这个循环。

   提交信息里写明回滚原因与原 PR 编号，不要只留 revert 的默认信息。

3. 涉及的截图基线需要重录——基线随代码走，回滚代码不改基线会导致 golden 测试红。见下节。

## 重录截图基线

基线只由 CI 产出，本地录的不作数。触发 `rerecord-goldens.yml`（Actions 页面手动触发）：

- **`target_ref` 填 `main`** — 回滚已合并改动后重录。
- **`target_ref` 填功能分支名** — 新增 golden 测试时重录到该分支，让 PR 带上基线再合。

该工作流会开一个带基线 PNG 的 PR，走正常评审合并。

## PR 卡在 stale 的 CHANGES_REQUESTED

CodeRabbit 只在有新 commit 时出增量评审。head commit 没变时旧的 CHANGES_REQUESTED 持续生效：

1. 先把代码改到位（推新 commit 通常就解了——增量评审会重新出结果）。
2. 已改完但仍卡住时，在 PR 下发 `@coderabbitai full review` 请求重新评审。
3. 若无响应，检查是否处于暂停状态（CodeRabbit 的 `Reviews paused` 提示）。暂停时发 `@coderabbitai resume` 解锁后再重发。

不要在代码未改的情况下反复请求重审。

## 外部 agent 推了违规 commit

`google-labs-jules[bot]` 在 CI 报错时会自动推多轮 fix commit，其中可能包含违规内容（典型：本地录制的 golden 基线 PNG）。

1. 判定是否违规：

   ```bash
   git diff --stat origin/main <pr-head>
   ```

   基线 PNG **只能由 `rerecord-goldens.yml` 产出**，该工作流用 uhibot App token 开 PR。因此 PR 分支上出现 `goldens/ci/*.png` 的新增或修改即违规，无论 commit 作者署名是谁——包括 `google-labs-jules[bot]` 与 `liziq21`。squash 合并会重写作者署名，不能用作者字段判定。

   区分方法：合规基线由 PR 带入（分支名形如 `ci/rerecord-goldens-*`），违规基线直接出现在 agent 的功能分支上。

2. **用 revert commit 撤销，不要 force-push** —— bot 持有分支，任何历史改写都会被它的下一轮 push 覆盖。

   ```bash
   git checkout -B <pr-branch> origin/<pr-branch>
   git revert --no-edit <违规-commit-sha>
   git push origin <pr-branch>
   ```

3. 若 bot 又自动推了新 commit，重复第 1 步。

注意：PR 上任何人类评论都可能触发 bot 推新 commit，推送前先确认 PR head 是否已变。

## 依赖更新没合进来

Renovate 负责依赖更新，`.github/dependabot.yml` 已删除（避免双通道冲突）。

- patch / pin / digest 级别自动合入，无需干预。
- major / minor 不在自动合并范围内，会开 PR 等评审。若该 PR 卡住，按上面的 CodeRabbit 章节处理。