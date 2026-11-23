# 映射描述符生成提示（构建期）

用途：在**构建期/运维期**用 LLM 从真实 fixture 和目标 canonical model 生成或修复 `FeedMappingDescriptor`，再用确定性测试验收。运行时不做任何模型调用。

背景与结论见 [`docs/research/2026-11-23-source-extensibility-and-ai-mapping.md`](../docs/research/2026-11-23-source-extensibility-and-ai-mapping.md)。

## 输入

- 源 fixture 路径（必须是已提交、可离线读取的 JSON）。
- 目标模型（`VideoModel`、`LiveRoomModel` 等）及其 `schemaVersion` / `requiredFields`。
- capability 与 feed id/title。
- 分页形状：`hasMorePath`，或 `totalCountPath` + `pageSize`。
- 认证/签名说明（描述符不实现签名；需要签名的源继续用 Dart adapter）。
- 已知怪癖：空列表、字段缺失、类型不一致、URL 规范化、HTML 标题等。

## 硬性规则

- 只输出描述符常量与确定性 transform；不得生成运行时网络调用或模型调用。
- 只使用已注册 transform，或在单独小节给出确定性的 Dart transform 实现。
- 不得编造字段。源里没有的字段就不映射；需要兜底时用 `fallbackPath`。
- ID、URL、时间、计数必须走确定性 transform，不得让模型在运行时推断。
- `schemaVersion` 必须等于目标模型的 `schemaVersion`。
- 目标模型的 `requiredFields` 必须全部出现。
- 分页只支持 `hasMorePath` 或 `totalCountPath` + `pageSize`；遇到 continuation token、签名分页或 WBI 时停止并升级，不要硬编码进描述符。
- 业务成功码必须显式写成 `successCodePath` + `successCode`。
- 必须同时提交：fixture 等价性测试；能由旧 adapter 生成 canonical golden 时，再加 conformance golden。
- 不得在测试中访问网络。

## 输出格式

1. `FeedMappingDescriptor` 代码片段。
2. 新增 transform（如有）及其单元测试。
3. fixture 等价性测试骨架（声明式输出 vs 旧 adapter）。
4. 验证命令与预期结果。
5. 未支持/有风险的部分（明确列出，不要静默跳过）。

## 验证命令

```bash
# 在目标包目录
dart analyze --fatal-infos --fatal-warnings   # 纯 Dart 包
flutter analyze --fatal-infos --fatal-warnings # 含 Flutter 的包
dart test                                      # 纯 Dart 包
flutter test test/                             # 含 Flutter 的包

# 有 conformance CLI 的源（当前为 Bilibili）
cd packages/bilibili
dart run tool/mapping_conformance.dart --feed <feed>
dart run tool/mapping_conformance.dart --feed <feed> --update  # 仅从旧 adapter 重录 golden

# 仓库根目录
python3 tool/test_matrix.py --check
```

## 评审清单

- [ ] 描述符通过 `validateFeedMappingDescriptor`，且 `requiredFields` 全覆盖。
- [ ] `schemaVersion` 与目标模型一致。
- [ ] 分页形状与源实际行为一致，且没有同时设置 `hasMorePath` 与 `totalCountPath`。
- [ ] 成功码/错误消息路径显式，失败时返回 `Result.error` 而不是空列表。
- [ ] ID/URL/时间/计数使用确定性 transform。
- [ ] fixture 等价性测试逐字段比较，不只比较数量。
- [ ] conformance golden 由旧 adapter 生成，不是由声明式引擎自证。
- [ ] 没有新增运行时模型调用、网络测试或手写 golden。

## 提示模板

```text
你是本仓库的构建期映射助手。请根据以下输入生成一个 FeedMappingDescriptor。

源 fixture: <path>
目标模型: <VideoModel|LiveRoomModel> (schemaVersion=<n>, requiredFields=<...>)
capability/feed: <capability> / <id> / <title>
分页: <hasMorePath=... | totalCountPath=... + pageSize=...>
认证/签名: <none | 说明>
已知怪癖: <...>

约束:
- 只输出描述符与确定性 transform，不生成运行时模型调用。
- 不得编造字段；缺失字段用 fallbackPath 或省略。
- 必须覆盖 requiredFields，schemaVersion 必须匹配。
- 分页只使用上述两种形状之一；不支持时明确说明并停止。
- 同时给出 fixture 等价性测试与验证命令。

输出:
1. 描述符代码
2. 新增 transform（如有）
3. 测试骨架
4. 验证命令与预期
5. 风险/未支持项
```
