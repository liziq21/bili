# 事故处置 runbook

恢复流程的记录。规范类规则在 `AGENTS.md`，本页只写「出事了怎么恢复」。

## 回滚已合并的 PR

1. 定位引入问题的 commit：

   ```bash
   git log --oneline -20 main
   ```

   ruleset 允许 merge / squash / rebase 三种方式，三者的回滚方式不同：

   - **squash** — PR 压成单条 commit。`git revert <sha>` 即可。
   - **rebase** — PR 里的 commit 逐条进入 main。**必须逐条 revert**，只回滚其中一条会留下其余改动。定位方法：`git log --oneline` 找到该 PR 的首个 commit 到末个 commit 的连续区间。
   - **merge** — 留下双 parent 的 merge commit。`git revert -m 1 <sha>`，缺 `-m 1` 会被 git 拒绝。

2. 在 `main` 上 revert：

   ```bash
   git checkout main && git pull

   # squash 合并的 PR
   git revert <sha>

   # rebase 合并的 PR —— 区间内每条都要 revert
   # 会为区间内每条 commit 各生成一个 revert commit
   git revert --no-edit <first-sha>^..<last-sha>

   # merge 合并的 PR
   git revert -m 1 <sha>

   git push origin main
   ```

   revert 是异常路径，不受 ruleset 的 required status checks 约束，`main` 上也不禁直推——liziq21 是仓库 admin。走直推是为了在事故中省掉一轮 PR 与 CI 等待。

   如果 revert 的 revert 又出问题，重复这个循环。

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

   基线 PNG **只能由 `rerecord-goldens.yml` 产出**，该工作流用 uhibot App token 开 PR。判定违规需要追溯引入 PNG 的 commit 到它的来源，而**不能只看分支名或 commit 作者**：

1. 列出触碰基线的 commit：

   ```bash
   git log --oneline --name-only origin/main..<pr-head> -- app/test/golden/goldens/ci/
   ```

2. 对每个 sha 到 GitHub 上确认来源。PR 分支删除或 squash 合并后，本地 git 历史不再保留 PR 分支名，`git log --decorate` 也只显示仍指向该 commit 的 ref，因此这一步必须在 GitHub 上做：

   - 该 sha 对应 `Re-record screenshot baselines` 工作流的某次 run（Actions 页面查 run 记录，生成的 PR 分支名形如 `ci/rerecord-goldens-*`）——合规。
   - 该 sha 无对应 workflow run，是 agent 直接推的——违规。

3. **无法确认来源时不要判定违规**，也不要执行 revert。

**不要只看「功能分支上有没有 PNG」**：重录工作流允许以功能分支为 `target_ref`，生成的基线 PR 也以该分支为目标，合规 PNG 合并后同样出现在功能分支上。按此判断并 revert 会撤掉合法基线，让 golden 测试再次失败。squash 合并还会重写作者署名，作者字段同样不可用作依据。

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