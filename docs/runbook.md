# 事故处置 runbook

本页只规定事故恢复步骤；开发政策见根 [`AGENTS.md`](../AGENTS.md)。执行前确认当前仓库、分支、工作区改动及操作者权限。本文不授予推送、合并或 bypass 权限。

## 回滚已合并的 PR

1. 保留未提交工作（必要时使用独立 worktree），取得最新远端状态，定位原 PR 的合并方式和准确 commit 范围：

   ```bash
   git status --short
   git fetch origin
   git log --oneline -20 origin/main
   git switch -c revert/<pr-number> origin/main
   ```

2. **按实际历史选择一种**回滚方式，不要依次执行全部命令：

   ```bash
   # squash：回滚合入 main 的那条 commit
   git revert <squash-sha>

   # rebase：确认区间只包含该 PR 的提交，再由新到旧回滚整个区间
   git revert --no-edit <first-sha>^..<last-sha>

   # merge：先用 git show --no-patch --pretty=raw <merge-sha> 核对 parent
   # 只有第一 parent 确实是要保留的主线时，才使用 -m 1
   git revert -m 1 <merge-sha>
   ```

   冲突时检查每一处，不用强制覆盖；需要放弃时 `git revert --abort`。提交说明写明原因与原 PR 编号。

3. 审查 diff，运行受影响的检查，推送回滚分支并开 PR：

   ```bash
   git diff --check origin/main...HEAD
   git diff --stat origin/main...HEAD
   git push -u origin HEAD
   ```

   默认走 PR 与 CI。紧急直推必须由有当前 bypass 权限的维护者显式授权并记录原因；required checks 是否限制直推取决于远端规则，不能从管理员身份或过去的 bypass 名单推断。

4. 基线与代码应一起核对。完整 revert 可能已恢复匹配的旧基线，不必无条件重录；只有仍缺失或不匹配时才走下节。不要为了通过 golden 测试放宽容差。

## 重录截图基线

遵循根 [Screenshot Tests](../AGENTS.md#screenshot-tests)，在 Actions 页面手动触发 [`rerecord-goldens.yml`](../.github/workflows/rerecord-goldens.yml)：

- `reason` 写明重录原因。
- `target_ref` 必须是目标仓库内存在、可作为 PR base 的**分支名**，不是 tag 或 commit SHA。新 golden 填功能分支，已合并改动的后续修复可填 `main`。
- 若功能分支在 fork、环境权限不足或 workflow 无法运行，请维护者安排合规录制路径，不要改成本地录制。

工作流 checkout 目标分支并读取它的 `.fvmrc`，生成 PNG 后打开以该分支为 base 的基线 PR。审查图像差异、测试结果、源分支提交与 workflow run；不要把基线 PR 当成无须审查的自动修复。合入后重新检查功能 PR。

## PR 卡在 stale 的 CHANGES_REQUESTED

1. 先修复具体意见并推新 commit；正常情况下 CodeRabbit 会增量评审。
2. 已修复但状态仍旧时，在 PR 请求 `@coderabbitai full review`。
3. 有 `Reviews paused` 提示时先发 `@coderabbitai resume`。当前配置禁用了累计 commit 数引起的自动暂停，但人工暂停等状态仍可能存在。
4. 无状态上报时，核对 [CodeRabbit 配置](../.coderabbit.yaml) 的忽略作者、PR draft 状态及当前 ruleset；由维护者处理服务/权限问题。

不要在代码未改的情况下反复请求重审，也不要伪造 required 状态。

## 外部 agent 推了违规 commit

先核实事实，再撤销；不要靠分支名或作者字段判定 PNG 来源。

### 核实基线来源

```bash
# <base> 必须是 PR 的实际 base，不一定是 main
# <head> 是已获取到本地的 PR head
git diff --stat <base>...<head>
git log --oneline --name-only <base>..<head> -- app/test/golden/goldens/ci/
```

在 GitHub 上追溯引入 PNG 的 PR、原始提交及 `Re-record screenshot baselines` run，并核对该 run 上传的 `goldens-<run_id>` artifact 中对应 PNG 的内容/hash。只有相同分支前缀、作者或 run 链接不构成内容来源证据；squash 后需追溯原始 PR，而非要求合并 SHA 等于 run 的源 SHA。

- 功能分支合法合入 CI 基线后也会包含 PNG，不得因此回滚。
- artifact 已过期或来源无法确认时，记录证据缺口，交由维护者核实或重新走 CI 录制；不要直接判违规或撤销合法基线。

### 撤销已确认的违规内容

1. 先协调暂停 agent 的自动修复，重新 fetch 并确认远端 head，避免与下一轮 push 竞争。
2. 在干净工作区从最新 PR 分支创建本地恢复分支：`git switch -c repair/<pr-number> origin/<pr-branch>`。不要用 `checkout -B` 重置已有本地分支。
3. 如果违规 commit 只含违规内容，使用 `git revert <sha>`；若混合合法改动，审查并提交最小纠正 diff，不盲目整条回滚。基线仍须遵守 CI 来源规则。
4. 审查并验证后正常推送到 PR 分支。不要 force-push；非快进失败时重新 fetch、核对新提交后再处理。

PR 上的人类评论可能触发新的 bot 工作；恢复后复核最新 head、CI 与 review 状态。

## 依赖更新没合进来

依赖更新由 [`renovate.json`](../renovate.json) 配置：patch / pin / digest 允许自动合并，major / minor 通常留待评审。允许自动合并不等于保证合并，仍受 CI、review、ruleset、时间窗口及服务权限约束。

先检查 Renovate PR 状态与实际配置；review 卡住时按上面的 CodeRabbit 章节处理，不另开重复依赖更新通道。
