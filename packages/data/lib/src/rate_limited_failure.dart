/// 源侧以限流或风控为由拒绝了这次请求，稍后重试可能成功。
///
/// 中立契约：具体服务包把平台异常适配成本类型，app 只识别本类型，不认识任何
/// 平台异常。
abstract interface class const RateLimitedFailure() implements Exception;
