# 页面间导航规范调研

## 概述

将 App 页面间导航集中到 routing，页面将事件回调提升到 routing，事件回调可为 null 表示无实现。

## 现有导航结构分析

### 核心路由文件：`lib/routing/router.dart`

**路由层已集中的导航扩展方法：**

| 扩展方法 | 路由数据类 | 用途 |
|---------|-----------|------|
| `context.navigateToVideo(id, source?)` | `VideoRouteData` | 视频详情页 |
| `context.navigateToLive(roomId, source?)` | `LiveRouteData` | 直播间页 |
| `context.navigateToSpace(mid, source?)` | `SpaceRouteData` | 创作者空间页 |
| `context.navigateToSearchResult(keyword, source?)` | `SearchRouteData` | 搜索结果页 |
| `context.push(Routes.settings)` | - | 设置页 |
| `context.pop()` | - | 返回上一页 |

**页面回调现状（必填）：**

```dart
// HomeScreen
required final Function(String roomId) _onLive;
required final Function(String id) _onVideo;

// SearchScreen  
required final void Function(String query) onSearch;

// LocalLibraryScreen
required final void Function(String sourceId, String videoId) onVideoTap;
required final void Function(String sourceId, String creatorId) onCreatorTap;

// MediaLibraryScreen
required final void Function(MediaHistoryItem item) onVideoTap;
```

**路由提供回调的方式（`_buildHome` 示例）：**

```dart
HomeScreen(
  onSettings: () => context.push<void>(Routes.settings),
  onLive: (roomId) => context.navigateToLive(
    roomId,
    source: context.read<MediaSource>().id,
  ),
  onVideo: (id) => context.navigateToVideo(
    id,
    source: context.read<MediaSource>().id,
  ),
),
```

### 问题与改进点

1. **回调均为必填** —— 页面无法在无导航场景下复用（如预览、测试、嵌入式展示）
2. **回调签名分散** —— 每个页面自行定义 `Function(...)` 签名，缺乏统一类型
3. **source 解耦不足** —— 回调需显式传 `source`，调用方需知晓当前数据源
4. **无统一默认行为** —— 缺省时应如何处理？（静默忽略 / SnackBar / 抛异常）

## Routing 集中化方案设计

### 设计目标

1. **单一真相源**：所有页面间导航行为在 `router.dart` 定义
2. **可空回调**：页面回调参数改为可空，缺省为 no-op
3. **统一签名**：定义标准导航回调类型
4. **Source 隐式传递**：利用 `ServiceSourceProviders` 作用域自动解析

### 标准导航回调类型

```dart
/// 视频导航回调
typedef VideoNavCallback = void Function(String videoId);

/// 直播导航回调
typedef LiveNavCallback = void Function(String roomId);

/// 空间导航回调
typedef SpaceNavCallback = void Function(String mid);

/// 搜索导航回调
typedef SearchNavCallback = void Function(String query);

/// 创作者导航回调（媒体库专用，需 sourceId）
typedef CreatorNavCallback = void Function(String sourceId, String creatorId);
```

### 回调在路由层的默认实现

```dart
// lib/routing/navigation_callbacks.dart (新文件)

extension NavigationCallbacks on BuildContext {
  /// 默认视频导航：读取当前作用域的 MediaSource
  void defaultNavigateToVideo(String videoId) {
    final source = read<MediaSource>();
    navigateToVideo(videoId, source: source.id);
  }

  /// 默认直播导航
  void defaultNavigateToLive(String roomId) {
    final source = read<MediaSource>();
    navigateToLive(roomId, source: source.id);
  }

  /// 默认空间导航
  void defaultNavigateToSpace(String mid) {
    final source = read<MediaSource>();
    navigateToSpace(mid, source: source.id);
  }

  /// 默认搜索导航
  void defaultNavigateToSearchResult(String query) {
    final source = read<MediaSource>();
    navigateToSearchResult(query, source: source.id);
  }
}
```

### 页面签名变更

**变更前：**
```dart
class const HomeScreen({
  required final Function(String roomId) _onLive,
  required final Function(String id) _onVideo,
  required final VoidCallback onSettings,
})
```

**变更后：**
```dart
class const HomeScreen({
  final LiveNavCallback? onLive,
  final VideoNavCallback? onVideo,
  final VoidCallback? onSettings,
})
```

**内部调用：**
```dart
// 使用 ?? 空合并提供 no-op 默认值
onLiveTap: (liveRoom) => onLive?.call('${liveRoom.id}'),
onVideoTap: (video) => onVideo?.call(video.id),
```

### 路由层装配（`_buildHome` 更新）

```dart
Widget _buildHome(BuildContext context) {
  return BlocSelector<AppBloc, AppState, String?>(
    selector: (state) => switch (state) {
      LoadSuccess(:final userData) => userData.sourceId,
      _ => null,
    },
    builder: (context, persistedSourceId) {
      final definition = context.read<MediaSourceCatalog>().resolvePersisted(
        persistedSourceId,
      );
      if (definition == null) return const NoMediaSourceScreen();

      return ServiceSourceProviders(
        key: ValueKey('home:${definition.id}'),
        source: definition.id,
        child: Builder(
          builder: (context) => BlocProvider<HomeBloc>(
            create: (context) => HomeBloc(
              userDataRepository: context.read(),
              preferences: context.read<PreferencesDataSource?>(),
              source: context.read<MediaSource>(),
            ),
            child: Builder(
              builder: (context) => _withSearchBloc(
                context,
                HomeScreen(
                  onSettings: () => context.push<void>(Routes.settings),
                  // 利用扩展方法，source 隐式从 ServiceSourceProviders 读取
                  onLive: context.defaultNavigateToLive,
                  onVideo: context.defaultNavigateToVideo,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
```

## 事件回调提升模式

### 模式定义

**提升原则**：页面只声明「发生了什么」，不决定「怎么跳转」。

| 层级 | 职责 |
|------|------|
| 页面 | 定义 `onXxx` 回调参数，内部调用 `onXxx?.call(data)` |
| 路由 | 提供 `defaultNavigateToXxx` 实现，装配给页面 |
| 调用方 | 可覆盖默认行为（如测试注入 mock、预览模式禁用跳转） |

### 优势

1. **可测试性**：单元测试传 `null` 或 mock 回调，无需构建 Router
2. **复用性**：同一页面可在不同导航上下文复用（Shell / Dialog / Preview）
3. **关注点分离**：页面关注交互，路由关注导航拓扑
4. **演进性**：导航逻辑变更只改路由，不碰页面代码

## Null 回调处理策略

### 策略对比

| 策略 | 适用场景 | 实现 |
|------|---------|------|
| **No-op (推荐)** | 大多数页面回调 | `onVideo?.call(id)` —— 为 null 时静默忽略 |
| **SnackBar 提示** | 关键路径缺失需用户感知 | `onVideo ??= (id) => showSnackBar('导航不可用')` |
| **断言/抛异常** | 开发期捕获漏装配 | `assert(onVideo != null, 'onVideo 未提供')` |
| **降级行为** | 有合理替代路径 | `onVideo ??= (id) => context.push('/video-fallback/$id')` |

### 推荐默认：No-op

- 符合「可为 null 表示无实现」的语义
- 零侵入、零副作用
- 测试/预览场景自然生效

### 例外：关键导航显式标注

```dart
/// 必须有导航实现的回调标记
@mustCallSuper
final VideoNavCallback? onVideo;
```

## 迁移清单

### 1. 新增文件
- [ ] `lib/routing/navigation_callbacks.dart` — 统一类型定义 + 默认实现

### 2. 修改页面签名（回调改可空 + 类型别名）
- [ ] `lib/feature/home/home_screen.dart`
- [ ] `lib/feature/search/search_screen.dart`
- [ ] `lib/feature/search/search_result_screen.dart`
- [ ] `lib/feature/media_library/local_library_screen.dart`
- [ ] `lib/feature/media_library/media_library_screen.dart`
- [ ] `lib/feature/space/space_screen.dart`
- [ ] `lib/feature/video/video_screen.dart`
- [ ] `lib/feature/live/live_screen.dart`

### 3. 修改路由装配（使用默认实现）
- [ ] `lib/routing/router.dart` — `_buildHome`, `_buildSearchEntry`, `_buildLibrary` 等

### 4. 更新测试
- [ ] 相关 widget 测试传 `null` 或 mock 回调

### 5. 文档
- [ ] 本文档作为规范归档
- [ ] AGENTS.md 补充导航回调约定

## 相关 Issue

- Linear: LIZ-52
- GitHub: #331
