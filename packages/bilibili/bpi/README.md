# bpi

`bpi` 是 Bilibili Web API 的 Dart 网络层，当前提供搜索、搜索建议和视频
详情请求。需要注意：它不是 Bilibili 官方 SDK，接口行为可能随 Bilibili
服务端变化。

## 功能

- 全站搜索和按类型搜索
- 搜索建议
- 视频详情查询
- WBI 签名和 WBI key 缓存
- 可注入 `http.Client` 和 `TokenStorage`
- 类型化的 HTTP、Bilibili API、WBI 和 JSON 解析错误

## 使用

```dart
import 'package:bpi/bpi.dart';

final search = BiliNetworkSearch();
try {
  final result = await search.searchVideo('Flutter');
  print(result.result.video);
} on BpiException catch (error) {
  print(error);
} finally {
  await search.close();
}
```

如果应用需要持久化 WBI key，可以实现 `TokenStorage` 并传入
`BiliNetworkSearch(storage: storage)`。`BiliNetworkSearch` 会在同一实例中复用
HTTP client，并在不再使用时通过 `close()` 释放它。

## WBI 行为

WBI key 会从 Bilibili 导航接口获取，并在内存中缓存。WBI 请求遇到一次 401
时会清除缓存、获取新 key 并重试一次；连续失败不会无限重试。

不要在日志中打印 Cookie、登录 Token、img key、sub key 或 mixin key。

## 开发

该包要求 Dart `^3.13.0`。测试不应依赖真实 Bilibili 网络服务，应使用固定
JSON fixtures 和 mock HTTP client。

```bash
dart test
```

## 限制

- Bilibili Web API 可能随时增加字段、修改字段类型或调整鉴权策略。
- 请遵守 Bilibili 的服务条款、访问频率限制和适用法律。
- 本包不负责登录凭证的具体获取和安全存储。