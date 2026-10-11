# App 源注入规范

本文是 `app/` 数据源目录、路由作用域和源能力 Repository 注入的正式规范。
它约束 `app/lib/data/`、`app/lib/providers/` 和 `app/lib/routing/` 的边界；具体
服务包仍遵守 `packages/AGENTS.md` 及各自的包规范。

## 1. 术语

- **源目录（catalog）**：当前可用源的不可变定义列表。定义包含规范化 ID、显示名和
  `MediaSource` 工厂，不包含运行中的网络客户端。
- **源实例（source instance）**：某个路由作用域内实际创建的 `MediaSource`。它拥有
  该作用域使用的网络客户端和远程数据源对象。
- **能力（capability）**：`packages/data` 中的可选接口，例如
  `VideoSearchRemoteDataSource`、`VideoDetailRemoteDataSource` 和
  `VideoCommentRemoteDataSource`。
- **源作用域（source scope）**：由 `ServiceSourceProviders` 创建的子树。它拥有一个
  源实例，并向子树注入由该实例能力派生的 Repository。

## 2. 依赖边界

- `app/lib/data/` **只能**依赖 `packages/data` 的中立能力接口、`packages/model`
  和 app 内部的通用接口。
- `app/lib/data/` **不得**导入 `package:bilibili`、`package:youtube` 或其他具体
  服务包，也不得使用带平台名称的远程数据源类型。
- 具体服务包只允许由 app 的组合根导入。当前组合根是
  `app/lib/providers/media_sources_provider.dart`，它只负责登记源定义和工厂。
- app Repository 必须面向能力接口编程。平台差异先在
  `packages/<service>/` 适配到 `packages/data` 的中立接口，再进入 app。
- 若 app 需要的请求参数无法由中立接口表达，应先扩展 `packages/data` 的接口；不得
  在 app 中对具体平台类型做 downcast。

## 3. 源目录

- 根 Provider 注入的是 `MediaSourceCatalog`，不是活跃的 `List<MediaSource>` 实例。
- 源目录只保存工厂；创建工厂之前不得创建网络客户端。
- 源 ID 必须唯一、非空，并在边界处规范化为去空格的小写字符串。
- 源目录为空是合法状态。解析没有可用源时返回 `null`，不得用空字符串表示无源。
- 持久化 source ID 是可回退输入：无效或未设置时使用目录首项；目录为空时返回
  `null`。
- 绑定在媒体记录、历史记录或显式路由参数上的 source ID 表示媒体所属源。该值无效
  时不得静默回退到另一源，应显示“数据源不可用”状态。

## 4. 路由作用域和生命周期

- `ServiceSourceProviders` 根据规范化 source ID 从目录找到定义，并创建一个新的源实例。
- 该实例及其派生 Repository 只属于当前作用域；作用域销毁时必须调用源的 `close()`
  且只能调用一次。
- 同一作用域中的所有 Repository 必须由同一个源实例的 capability getter 创建。
- Repository 不拥有也不关闭源实例。
- 需要切换源时，作用域的 key 必须包含规范化 source ID，以便旧作用域先销毁、新
  作用域再创建。
- 未注册 source ID 必须在建树前以 `ArgumentError` 暴露；不能延迟为子树中的
  `ProviderNotFoundException`。

## 5. 能力驱动注入

`ServiceSourceProviders` 必须依据 capability 接口是否为非空来决定注入哪些 Repository，
不得通过 source ID 的 `switch` 分支决定能力。映射规则如下：

```text
VideoSearchRemoteDataSource          -> VideoSearchRepository
CreatorProfileSearchRemoteDataSource -> CreatorProfileSearchRepository
SearchSuggestRemoteDataSource        -> SearchSuggestRepository
LiveRoomSearchRemoteDataSource       -> LiveRoomSearchRepository
VideoDetailRemoteDataSource           -> VideoDetailRepository
VideoCommentRemoteDataSource          -> VideoCommentRepository
```

- 一个能力一个 Repository；不得为了复用实现而把两个不相关能力强行合并成一个平台
  命名 Repository。
- 缺少可选能力时省略对应 Provider，并由页面显示明确的不可用状态或隐藏该能力的
  UI。不得用一个隐藏“不支持”行为的通用 Repository 伪装成已注入能力。
- 页面级 Bloc 在 route data 或路由组装点创建，依赖由源作用域向下提供。Bloc 不得
  自己创建具体服务源。

## 6. 测试要求

源注入测试至少覆盖：

- 空目录解析为 `null`，且不创建源实例；
- 自定义源可以通过目录和作用域注入；
- 未注册 source 在建树前抛 `ArgumentError`；
- 同一作用域的 Repository 来自同一源实例；
- 作用域卸载时源实例被关闭一次；
- 每个源只注入它实际实现的能力；
- 显式无效 source 不回退到其他源；
- source 切换会使用包含 source ID 的 key 创建新作用域。

测试使用 fake source 和 fake capability，不访问真实网络。
