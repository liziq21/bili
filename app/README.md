# app

主 Flutter 应用工程。

## 作用

- 应用入口和生命周期控制
- 页面级 feature 实现与组装
- 路由配置与依赖注入
- 本地数据库（Drift/SQLite）和持久化缓存协调
- 应用层数据仓库（Repository）协调与数据同步

## 目录说明

- `lib/feature/`：页面和功能模块（`home/`, `search/`, `live/`, `video/`, `space/`, `setting/`, `theme/`, `not_found/`）
- `lib/data/`：应用层 Repository 实现与数据桥接
- `lib/database/`：Drift 数据库定义、Table 与 DAO
- `lib/datastore/`：偏好设置与 Key-Value 持久化存储
- `lib/domain/`：应用层 Use Case 与业务逻辑
- `lib/routing/`：基于 `go_router` 的路由配置与 Data Class
- `test/`：单元测试和 Widget 测试

## 开发命令

在 `app/` 目录下执行以下开发命令：

### 安装依赖

```bash
flutter pub get
```

### 静态分析与测试

```bash
flutter analyze lib/
flutter test
```

### 代码生成

```bash
# 全量代码生成
dart run build_runner build --delete-conflicting-outputs

# 定向生成 Drift 数据库代码
dart pub run build_runner build --build-filter="lib/database/**"

# 定向生成 go_router 路由代码
dart pub run build_runner build --build-filter="lib/routing/**"
```

### 运行应用

```bash
flutter run
```

## 相关规范

详细架构规则、数据库规范与 UI 开发约束请参阅：
- [app/AGENTS.md](AGENTS.md)
- [根目录 AGENTS.md](../AGENTS.md)
