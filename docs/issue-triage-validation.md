# Issue Triage 提示词真实试运行记录

状态：完成一次受限试运行

日期：2026-10-12

## 试运行目标

验证“通过 Linear MCP 审查 GitHub Issue 同步入口”的实际边界，而不是只凭字段名称设计提示词。首轮只处理一条管理员创建的低风险参考事项，不创建工单、不移动状态、不分配执行者。

## 候选与来源

- Linear：[`LIZ-48`](https://linear.app/liziq/issue/LIZ-48/httpsgithubcommohanedzekryflutter-go-router-example-是否可供参考)
- GitHub：[`#295`](https://github.com/liziq21/bili/issues/295)
- 原始标题：`https://github.com/MohanedZekry/flutter-go-router-example 是否可供参考？`
- Linear `createdBy`：`zhiq liu`，用户 UUID `0f28defb-0c48-468b-aa03-c3bcd6abf12c`
- Linear 用户查询确认该用户为 workspace admin；GitHub Issue API 查询确认作者为仓库 `OWNER`。
- 该事项没有描述、标签、项目、优先级或负责人，状态为 `Backlog`。
- Linear attachment 明确指向 GitHub Issue #295。
- Linear 的系统评论明确说明：评论线程同步到对应 GitHub Issue，回复会在两边显示。

## 实际调查

外部参考仓库 `MohanedZekry/flutter-go-router-example`：

- HEAD：`8e28f6731fae4ec708660bc16d3155e021f906b3`
- 最近提交时间：2023-03-04
- README 以 go_router 6.2.0 为例
- 使用单一 `ShellRoute`，由 Cubit 保存底栏索引，并使用 `context.go` 切换页面
- 参考仓库使用 Flutter Material；它不是 bili 的现成代码补丁

bili 当前实现：

- `app/lib/routing/router.dart` 使用 `StatefulShellRoute.indexedStack`
- 当前保留三个分支导航栈
- 根级次级页面通过外层 `ShellRoute` 组织
- `app/lib/ui/common/app_navigation_shell.dart` 在窄屏使用 `NavigationBar`，宽屏使用 `NavigationRail`
- 项目规范要求 app 使用 `material_ui`，且数据源能力和路由 source scope 有既定边界

## 真实 MCP 操作观察

1. 首次错误地在 Linear 顶层评论使用了实现任务的 `[AI CLAIM]` 标记；该评论没有同步到 GitHub。
2. 通过 Linear 编辑该评论留下了试运行纠正记录；它仍然只存在于 Linear 顶层，因此不能作为 GitHub Issue 回复。
3. 找到 GitHub 集成生成的同步线程根评论后，通过 `parentId` 回复该线程。
4. 该回复在 Linear 中显示为子评论，并在 GitHub #295 中实际出现。
5. 没有修改 `Backlog` 状态、标签、优先级、项目、assignee 或 delegate；没有创建实现工单或 Draft PR。

## 提示词因此采用的约束

- 必须区分管理员项目事项、普通用户 Issue 和已有规划工单；“有 GitHub 镜像”不能单独证明它是新入口问题。
- 管理员短文本必须保留项目意图并获得实质调查，不能套用普通 bug 的“请补充复现步骤”。
- `Linear isAdmin` 与 GitHub 仓库管理员身份分开记录；管理员身份不等于自动提高优先级或自动批准方案。
- 所有同步回复必须以 `parentId` 回复 GitHub 系统线程根评论；找不到线程时不得发顶层替代评论。
- 不能复用实现任务的 `[AI CLAIM]`，不能创建 Draft PR，不能把 Backlog 自动移动到 Todo。
- 真实审核应有单条调查预算和每轮数量上限；超出预算进入 `needs-refinement` 或 `blocked-tooling`，而不是猜测或静默遗漏。
- 真实结论要区分“Linear 写入成功”“同步线程回复已提交”和“GitHub 侧已观察到结果”。

## 局限

- 试运行只处理一条管理员参考事项，未验证普通用户缺信息、重复 Issue、真实 bug 或需要 HITL 的实现决策。
- 这次通过 GitHub CLI 做了只读复核；正式 Jules 任务不应依赖 GitHub API 写权限。
- 调度器如何提供 session、并发串行化和时间预算仍需根据 Jules 的实际运行配置确认；提示词只规定行为边界，不启用调度。
