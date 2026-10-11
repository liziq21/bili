# bili 架构学习旅程

面向第一次读这个仓库的贡献者。按一次真实的请求路径走一遍，每层说清三件事：**这一层负责什么、代码在哪、为什么这样切分**。

文中每条原则都标了出处。标「官方」的可以顺着 URL 查到原文；标「项目约定」的是本仓库自己的选择，没有外部背书。两者混在一起读会出错，所以分开标。

## 1. 目标与约束

在讲结构之前，先说清这个应用要满足什么——结构上的每个决定都是这些约束推出来的。

- **跨平台**。同一份代码要跑在 Android、iOS、Linux、macOS、Windows 和 Web 上，不能有单平台假设。
- **不实现登录**。所有端点都是匿名可访问的。任何需要凭据的设计在这个项目里不成立。
- **测试与 CI 不联网**。所有测试用 fixture 或假客户端，CI 也不访问真实服务。
- **应用层不按服务源分支**。UI 和设计系统不认识 Bilibili 或 YouTube，只认识角色（surface、onSurface、accent）。服务身份是数据，由数据层带进渲染层。

## 2. 架构总览

Flutter 官方的架构文档把应用切成 UI 层与数据层，复杂应用可以在中间加一层领域层；官方用词是 **UI layer / logic layer / data layer**（[Guide to app architecture](https://docs.flutter.dev/app-architecture/guide)）。bili 用的就是这个划分，只是把 logic layer 叫作 `domain/`。

| 层 | 职责 | 代码位置 | 本项目用什么实现 |
|---|---|---|---|
| UI 层 | 把状态渲染成界面，接收用户交互并转成事件。不含业务逻辑 | `app/lib/feature/`、`app/lib/ui/` | flutter_bloc |
| 领域层 | 跨功能的业务规则，不依赖 Flutter | `app/lib/domain/` | 纯 Dart 用例 |
| 数据层 | 应用数据的唯一真相来源（SSOT），负责缓存、重试、离线 | `app/lib/data/`、`app/lib/database/`、`app/lib/datastore/` | Drift + Retrofit/Chopper |
| 路由 | 声明式路由表 | `app/lib/routing/` | go_router |
| 依赖注入 | 构造对象树 | `app/lib/providers/` | provider + flutter_bloc |

官方的原文是：视图「不应该包含任何业务逻辑，应该由 view model 提供渲染所需的全部数据」（[Guide](https://docs.flutter.dev/app-architecture/guide)）；数据层「是所有应用数据的真相来源，作为 SSOT，它是唯一应该更新应用数据的地方」（[Data layer case study](https://docs.flutter.dev/app-architecture/case-study/data-layer)）。

> 官方的推荐实现是 ChangeNotifier + MVVM，并在同一篇里说明「也可以用流，或者 riverpod、flutter_bloc、signals 等其他库」。bili 选 flutter_bloc，**BLoC 承担的是官方 view model 的角色**——对外表现一致，内部实现换成事件驱动。

## 3. 贯穿场景：首页信息流的一次读取

后面每一节都展开这个场景。想理解整体形状，先把这条路径走一遍。

| 步骤 | 做什么 | 去哪找 |
|---|---|---|
| 1 | 用户进入首页，界面订阅状态 | `HomeScreen` 里的 `BlocBuilder<HomeBloc, HomeState>` |
| 2 | 路由根据目录解析当前源，并在源作用域内创建 Bloc | `router.dart` 的 `_buildHome` 与 `ServiceSourceProviders` |
| 3 | Bloc 构造完成后主动请求一次数据 | `HomeBloc` 构造函数末尾的 `add(FeedsRequested())` |
| 4 | 从服务源问出它支持哪些 feed | `source.videoFeedDataSources`、`source.liveRoomFeedDataSources` |
| 5 | 先为每个 feed 发一次状态，section 置为 loading，让界面先出骨架 | `emit(state.copyWith(videoSections: [...FeedSectionState(status: FeedStatus.loading)]))` |
| 6 | 并发拉取所有 section 的第一页 | `Future.wait([...])`，逐个调 `_fetchVideoPage` / `_fetchLivePage` |
| 7 | 每个 feed 自己发请求，返回 `Result` | `_fetchVideoPage` 里的 `feed.fetchFeed(pageKey: ...)` |
| 8 | **丢弃过期响应**：请求发起时记一个递增版本号，回来时版本对不上、服务源中途换过、或 Bloc 已关闭，就直接返回不 emit | `_fetchVideoPage` 里的 `_nextRequestVersion` 与三个 `if` 条件 |
| 9 | 合并进 section 并发新状态 | `emit(_replaceVideoSection(_merge(current, result, pageKey: pageKey)))` |
| 10 | 请求全部返回后收起刷新态 | `if (state.isRefreshing) emit(state.copyWith(isRefreshing: false))` |

第 8 步值得单独看一眼。这里的两个检查解决的是两件事：`_source.id != sourceId` 丢弃不属于当前源作用域的响应；请求版本检查丢弃同一类 feed、同一 `feed.id` 上被更新请求取代的旧响应。缺少后者时，旧响应可能覆盖较新的请求结果。

## 4. 数据层

### 4.1 Repository 是唯一真相来源

**官方**：Repository「是应用数据的真相来源……负责在支持离线时同步数据、管理重试逻辑与缓存」（[Data layer case study](https://docs.flutter.dev/app-architecture/case-study/data-layer)）。

代码在 `app/lib/data/repository/`。每个仓库是一个 `abstract interface class` 加一个默认实现：

```dart
abstract interface class VideoDetailRepository() {
  Future<Result<VideoDetail>> getVideoDetail(String id);
  Future<Result<bool>> toggleLike(String id, bool isLiked);
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited);
  Future<Result<bool>> toggleSubscribe(String creatorId, bool isSubscribed);
}

class AppVideoDetailRepository([...]) implements VideoDetailRepository { ... }
```

**项目约定**：接口和实现放在同一个文件里，不拆。理由是这个仓库里仓库数量不多，拆开会让「有哪些能力」变得需要跳转才知道。

### 4.2 能力接口与可空依赖

`AppVideoDetailRepository` 的构造函数接受一个**可选**的 `VideoDetailRemoteDataSource?`。当前服务源没实现视频详情能力时，它安全地返回错误，而不是崩溃。

抽象基类在 `packages/data/lib/src/remote_data_source.dart`，按能力拆成 `SearchRemoteDataSource`、`VideoDetailRemoteDataSource`、`LiveRoomSearchRemoteDataSource` 等多个接口，每个实现类只实现自己支持的那几个。

**为什么重要**：app 层因此不需要知道「当前服务支不支持这个能力」，支持与否是数据层的判断。这是第 1 节「应用层不按服务源分支」在数据侧的落地。

### 4.3 `Result<T>` 取代异常

`packages/model/lib/src/utils/result.dart` 定义了一个 sealed class：

```dart
sealed class const Result<T>() { }
final class const Ok<T>._(final T value) extends Result<T> { }
final class const Error<T>._(final Exception error) extends Result<T> { }
```

面向远端数据的仓库方法返回 `Future<Result<T>>` 而不是抛异常。这不是全仓库无例外的规则——`RecentSearchQueryRepository.getRecentSearchQueries` 返回的是 `Stream<List<RecentSearchQuery>>`，因为搜索历史需要随数据变化持续推送，不是一次取值。

**官方**：Flutter 架构文档提到「Result 是一个包装异步调用的工具类，让处理错误和管理依赖异步调用的 UI 状态变得容易。**这个模式是推荐，不是要求**」（[Data layer case study](https://docs.flutter.dev/app-architecture/case-study/data-layer)）。

**项目约定**：本仓库把它定成必须，且在模型包里定义，让数据层与领域层都能用，不产生包依赖倒置。

### 4.4 远程数据源：接口手写，实现生成

`packages/bilibili/bpi` 与 `packages/youtube/ypi` 是服务专属的 API 客户端。

**官方**：Chopper「不使用反射，而是用 Dart 团队的 build 与 source_gen 做代码生成」（[getting-started](https://github.com/lejard-h/chopper/blob/master/getting-started.md)）。用法是在一个 `extends ChopperService` 的抽象类上标注 `@ChopperApi`，用 `@GET` / `@POST` 标注方法，生成实现类。`ChopperClient` 负责 base URL、拦截器和转换器。

所以职责划分是：**你手写抽象接口和注解，工具只负责从这个声明生成可调用的实现**。生成代码与手写声明一一对应（`_$TodosService(client)` 之于 `TodosService`）。

bpi 还额外处理了业务信封（Bilibili 返回 `{code, message, data}`，`code != 0` 算失败），这一层是项目约定，两家库都没提。

### 4.5 本地数据库

`app/lib/database/` 下分 `table/`（表声明）和 `dao/`（数据访问对象），都由 build_runner 生成 `.g.dart`。

**官方**：Drift「把表声明成 Dart 类，然后用 build_runner 在编译期生成类型安全的查询代码」；官方建议数据库用**单例**并通过依赖注入提供（[Setup](https://drift.simonbinder.eu/setup/)、[FAQ](https://drift.simonbinder.eu/faq/)）。

bili 的 `AppDatabase` 由 `RepositoryProvider<AppDatabase>` 提供（见 `app/lib/providers/repo_providers.dart`）。DAO 是数据库自己的访问对象，**不是** Repository——Repository 面向业务语义，DAO 面向表。

> 注意：Drift 官方文档里没有「何时该把数据库访问放进 repository」这类表述，DAO 页面也没有明确写这个边界。这里的划分是项目约定，理由见 4.1 的 SSOT 定义。

### 4.6 本地状态与写入

用户偏好（主题、当前服务源）走 `app/lib/datastore/`，基于 `SharedPreferences`，通过 `PreferencesDataSource` 暴露，读出来是一条流。

仓库对这条流的订阅模式见 6.2。

## 5. 领域层

`app/lib/domain/` 放跨功能的业务规则，目前是两个用例：`get_recent_search_queries_use_case.dart`、`get_search_contents_use_case.dart`。

**官方**：领域层「夹在 UI 层与数据层之间」（[Guide](https://docs.flutter.dev/app-architecture/guide)）。

**项目约定**：单一功能用到的规则直接放在对应 `feature/*/bloc/` 里，不上提到 `domain/`。`domain/` 只放确实跨功能的。所以这个目录很小是刻意的，不是没写完。

## 6. UI 层

### 6.1 状态建模

状态是 `@immutable` 的类，用 `EquatableMixin` 做结构相等，`props` 列全所有参与相等判断的字段（根 `AGENTS.md` 有硬性规定）。

事件是 `part` 文件，与 Bloc 同目录：

```
feature/home/bloc/
  home_bloc.dart
  home_event.dart      part of home_bloc.dart
  home_state.dart      part of home_bloc.dart
  feed_section_state.dart
```

**官方**：flutter_bloc 的单向流原则是「Bloc 永远不应该直接发出新状态，每一次状态变化都必须是响应一个输入事件、在某个 EventHandler 里产出的」（[Bloc Concepts](https://bloclibrary.dev/bloc-concepts/)）。

**项目约定**：全仓库用 Bloc，不用 Cubit。官方的建议是「状态简单且局部化时用 Cubit」（[Firebase Login 教程](https://bloclibrary.dev/tutorials/flutter-firebase-login/)），需要流转换器时才上 Bloc（「GitHub Search 教程」就是为了用 debounce 才选 Bloc）。bili 的搜索防抖确实需要转换器，为了一致性全仓库统一用 Bloc。

### 6.2 处理用户交互

Bloc 只通过构造函数注入依赖：

```dart
class HomeBloc({
  required final UserDataRepository userDataRepository,
  required final MediaSource source,
}) extends Bloc<HomeEvent, HomeState> {
```

**官方**：Bloc 的依赖「必须是可注入的、平台无关的，不允许平台分支」（[FAQs](https://bloclibrary.dev/faqs/)）。

Bloc 只处理当前路由作用域内的源，不订阅全局源清单。源切换由路由重新解析目录并
重建作用域，旧源和旧 Bloc 随作用域一起释放。

HomeBloc 的输入仍然只通过构造函数和事件进入，不直接导入具体服务包。源目录由组合
根注入，源实例由路由作用域按需创建；空目录由路由显示无可用源状态，不创建
HomeBloc。

### 6.3 依赖注入

`app/lib/providers/` 分为全局本地依赖、Bloc 以及源作用域：`bloc_providers.dart` 放全局 Bloc，`repo_providers.dart` 放本地仓库与数据层对象，`media_sources_provider.dart` 登记源工厂，`service_source_providers.dart` 为路由作用域按能力注入源 Repository。

```dart
RepositoryProvider<AppDatabase>(...);
RepositoryProvider<GetRecentSearchQueriesUseCase>(...);
```

**官方**：`RepositoryProvider` 定义在 **flutter_bloc**（[API 文档](https://pub.dev/documentation/flutter_bloc/latest/flutter_bloc/RepositoryProvider-class.html)），不在 provider 包里。它的语义是「DI 部件，让单个仓库实例提供给子树内多个组件」，并且「不要用 `RepositoryProvider.value` 创建新仓库，应该在 create 函数里用默认构造函数创建」。

读的时候用 `context.read<T>()`（读一次不监听）、`context.watch`（监听整体）、`context.select`（只监听一部分）。**官方**：「如果你的组件重建得太频繁，可以用 `context.select` 只监听特定的属性」（[provider 包页](https://pub.dev/packages/provider)）。

> 踩过的坑：import `package:provider` 解析不到 `RepositoryProvider`，它不在那个包里。

### 6.4 路由

`app/lib/routing/` 下 `routes.dart` 是路径常量，`router.dart` 组装路由表，`route_data/` 每屏一个 RouteData 类，`.g.dart` 由 `go_router_builder` 生成。

用了 `ShellRoute` 包住底部导航与子路由。

**官方**：`ShellRoute` 是「在匹配的子路由外面显示一个 UI 外壳」的路由，会**新建一个 Navigator** 来显示子路由（[API 文档](https://pub.dev/documentation/go_router/latest/go_router/ShellRoute-class.html)）。需要「每个标签页各自保活、切换不丢状态」时官方指向 `StatefulShellRoute`（[Configuration](https://pub.dev/documentation/go_router/latest/topics/Configuration-topic.html)）。

**官方关于代码生成**：`go_router_builder` 的定位是「消除手写一堆 go、push、location 样板代码」，并且「两条路由解析到同一个 URL 时，go_router 匹配第一条、第二条不可达——builder 会在构建期警告」，以及「错误在编译期被发现，这正是类型化路由的意义」（[包页](https://pub.dev/packages/go_router_builder)）。

> go_router 本身不内置代码生成，生成器是独立的 `go_router_builder` 包。

## 7. 延伸阅读

- [Guide to app architecture](https://docs.flutter.dev/app-architecture/guide) —— 分层的总纲，本文第 2 节的出处
- [Data layer case study](https://docs.flutter.dev/app-architecture/case-study/data-layer) —— SSOT、Repository、Service、Result 的定义
- [UI layer case study](https://docs.flutter.dev/app-architecture/case-study/ui-layer) —— View 与 ViewModel 的一对一关系
- [Bloc Concepts](https://bloclibrary.dev/bloc-concepts/) —— 事件驱动与单向流
- [bloc architecture](https://bloclibrary.dev/architecture/) —— 三层划分与 Repository 层的定位
- [Chopper getting-started](https://github.com/lejard-h/chopper/blob/master/getting-started.md) —— 注解式接口与代码生成
- [Drift setup](https://drift.simonbinder.eu/setup/) —— 表声明与编译期生成
- [go_router 配置](https://pub.dev/documentation/go_router/latest/topics/Configuration-topic.html) —— 嵌套路由与 ShellRoute

## 8. 未能核实的说法

写这份文档时核对过但**官方文档里查不到**的说法，列在这里以免后来者误引：

- 「接口定义即契约」——Retrofit 与 Chopper 的官方文档都没有这个措辞，实际是「手写抽象接口 + 注解，工具生成实现类」。
- 「Drift 建议何时把数据库访问放进 repository」——没有这条表述。Drift 讲的是 DAO 与依赖注入。
- Chopper 与 Protobuf 组合的官方示例未找到，只有 Converters 机制本身有文档。
