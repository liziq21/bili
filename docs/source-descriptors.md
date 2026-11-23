# 源描述符与声明式映射指南

本文件是 `FeedMappingDescriptor` / `SourceDescriptor` 的规范说明。它回答“什么时候用描述符、描述符里写什么、如何验证、如何防止漂移”，不替代可执行代码与测试。

## 1. 边界

| 场景 | 用什么 | 理由 |
|---|---|---|
| 简单 JSON feed：固定 envelope、固定 item 形状、无签名 | `FeedMappingDescriptor` + `DeclarativeFeedDataSource` | 新增源主要是数据，不是 Dart 代码 |
| 需要 endpoint/auth/pagination/rate limit 元数据 | `SourceDescriptor`（可嵌套 `FeedMappingDescriptor`） | 把传输契约与字段映射分开 |
| 需要 WBI/签名/Cookie/媒体流/复杂 renderer 树 | Dart adapter | 这些是代码与协议逻辑，不是字段映射 |
| 需要语义分类/标签 | 运行时窄 `SemanticClassifier` + validator + fallback | 只处理语义，不处理 ID/URL/计数 |

`FeedMappingDescriptor` 只负责 **item → canonical field**。`SourceDescriptor` 负责 **endpoint/method/auth/pagination/rate limit**。两者都不要存凭据。

## 2. FeedMappingDescriptor

```dart
const descriptor = FeedMappingDescriptor(
  itemsPath: r'$.data.list[*]',
  schemaVersion: VideoModel.schemaVersion,
  successCodePath: r'$.code',
  successCode: 0,
  messagePath: r'$.message',
  hasMorePath: r'$.data.no_more',
  hasMoreWhen: false,
  fields: {
    'id': FieldMapping(
      path: r'$.bvid',
      description: 'Stable Bilibili video id.',
      examples: ['BV1Deht6rEpZ'],
    ),
  },
  provenance: MappingProvenance(
    generatedBy: 'hand-written',
    promptVersion: 'poc-v1',
    generatedAt: '2026-11-23',
    reviewer: 'PoC',
    fixtureHash: '676f7551',
    sourceSchemaHash: '7fb4b425',
  ),
);
```

规则：

- `itemsPath` 必须选出 JSON 列表。
- `fields` 必须覆盖 canonical model 的 `requiredFields`。
- `FieldMapping` 必须且只能设置 `path` 或 `template` 之一。
- `description` / `examples` 是给构建期 LLM 与 reviewer 的语义提示；运行时忽略。
- `schemaVersion` 必须与 canonical model 的 `schemaVersion` 一致。
- 不得在描述符里写用户可见文案、凭据或 token。

## 3. 分页

支持四种形状：

| 形状 | 描述符字段 | 说明 |
|---|---|---|
| 布尔 has-more | `hasMorePath` + `hasMoreWhen` | 例如 `no_more: false` 表示还有下一页 |
| 总数 + 页大小 | `totalCountPath` + `pageSize` | `totalPages = ceil(count / pageSize)` |
| continuation cursor | `continuationTokenPath` | 读取下一页 cursor；`Page.nextCursor` 暴露给调用方 |
| 无分页 | 不设置 | `totalPages` 等于当前页 |

continuation cursor 示例：

```dart
const descriptor = FeedMappingDescriptor(
  itemsPath: r'$.data.list[*]',
  continuationTokenPath: r'$.data.next',
  fields: {'id': FieldMapping(path: r'$.id')},
);
```

```dart
final first = await source.fetchFeedPage();
final next = await source.fetchFeedPage(
  cursor: first.nextCursor,
  pageKey: 2,
);
```

`continuationTokenPath`、`hasMorePath`、`totalCountPath` 三者互斥；validator 会拒绝组合。

## 4. SourceDescriptor

`SourceDescriptor` 描述传输层：

```dart
const source = SourceDescriptor(
  id: 'example',
  displayName: 'Example feed',
  endpoint: 'https://api.example.com/feed',
  auth: SourceAuthDescriptor(
    kind: SourceAuthKind.apiKeyHeader,
    headerName: 'X-API-Key',
    tokenEnvironmentVariable: 'EXAMPLE_API_KEY',
  ),
  pagination: SourcePaginationDescriptor(
    kind: SourcePaginationKind.pageNumber,
    pageParameter: 'page',
    pageSizeParameter: 'page_size',
    defaultPageSize: 20,
  ),
  rateLimit: SourceRateLimitDescriptor(requestsPerMinute: 60, burst: 5),
  mapping: descriptor,
);
```

规则：

- `endpoint` 必须是 `https://`。
- `auth.none` 不得设置 header/query/token 字段。
- `apiKeyHeader` 需要 `headerName`；`apiKeyQuery` 需要 `queryParameter`；`bearerToken`/`oauth` 需要 `tokenEnvironmentVariable`。
- `tokenEnvironmentVariable` 只能是环境变量名（`^[A-Z][A-Z0-9_]*$`），不得是实际 token。
- `customSignature` 必须设置 `requiresDartAdapter: true`；签名逻辑留在 Dart adapter。
- `pagination.kind` 必须与嵌套 mapping 的分页字段一致。
- `rateLimit` 的值必须为正数。

## 5. Provenance 与漂移

每个生产描述符都应带 `MappingProvenance`：

- `generatedBy`：`hand-written`、模型名或工具名。
- `promptVersion`：构建期 prompt/模板版本。
- `generatedAt`：`YYYY-MM-DD`。
- `reviewer`：人工 reviewer 标识。
- `fixtureHash`：fixture 内容哈希（`fingerprintJson(fixture).fixtureHash`）。
- `sourceSchemaHash`：fixture key/type 形状哈希（`fingerprintJson(fixture).sourceSchemaHash`）。
- `notes`：可选说明。

哈希由 `packages/data/lib/src/mapping/mapping_fingerprint.dart` 计算：

```bash
cd packages/bilibili
dart run tool/mapping_fingerprint.dart bpi/testing/popular.json
```

漂移处理：

1. fixture 或源 schema 变化时，`descriptor provenance fingerprints match the fixtures` 测试先红。
2. 用旧 adapter 重新生成 canonical golden（`mapping_conformance.dart --update`）。
3. 更新描述符/哈希，跑 validator、conformance、任务级测试。
4. 构建期 agent 只能提 PR；不得自动合并。

## 6. 验证命令

```bash
# 纯 Dart 包
cd packages/data
dart analyze --fatal-infos --fatal-warnings
dart test

# Bilibili 包
cd packages/bilibili
flutter analyze --fatal-infos --fatal-warnings
flutter test test/
dart run tool/mapping_conformance.dart --feed popular
dart run tool/mapping_conformance.dart --feed ranking
dart run tool/mapping_fingerprint.dart bpi/testing/popular.json
```

必须同时覆盖：

- schema/descriptor validator
- fixture 结构 diff
- 精确 ID、URL、计数、时长、时间、分页、去重
- 失败 envelope、空页、未知 transform、cursor 结束

## 7. 构建期 LLM 工作流

1. 读取 `tool/mapping_scaffold_prompt.md`。
2. 提供源 fixture、canonical `requiredFields`、字段描述/示例。
3. LLM 产出 `FeedMappingDescriptor` 草案 + 测试骨架。
4. 人工 review 字段语义、分页、失败行为。
5. 跑 validator、conformance、任务级测试。
6. 记录 provenance；开 PR；不自动合并。

LLM 输出必须当作不可信输入：不得直接执行、不得直接合并、不得包含凭据。

## 8. 安全

- 不在描述符、prompt、日志、fixture 中放 API key/token。
- 运行时模型只处理窄语义分类；不生成 ID/URL/计数/分页。
- 模型输出必须经过 label allowlist、validator、fallback。
- 源数据是 untrusted input；构建期生成比运行时读取第三方数据更安全。

## 9. Review checklist

- [ ] `itemsPath` 正确，空列表/缺字段行为明确。
- [ ] `requiredFields` 全覆盖，`schemaVersion` 一致。
- [ ] 每个字段有 `path` 或 `template`，且只有一个。
- [ ] ID/URL/计数/时长/时间使用确定性 transform。
- [ ] 分页形状与描述符字段一致；cursor 结束行为已测。
- [ ] provenance 完整，fixture/schema 哈希匹配。
- [ ] conformance 与任务级断言通过。
- [ ] 没有凭据、用户文案或运行时模型调用。
