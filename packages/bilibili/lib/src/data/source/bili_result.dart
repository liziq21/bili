import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:logging/logging.dart';
import 'package:model/model.dart';

/// [Future.toResult] 的 B 站版本：把平台的风控拒绝换成 [RateLimitedFailure]。
///
/// app 只认识 `data` 的中立契约，平台异常在这一层就地适配，不下沉也不上浮。
extension BiliResultX<T> on Future<T> {
  Future<Result<T, Exception>> toBiliResult() async =>
      switch (await toResult()) {
        Success(:final success) => Result.success(success),
        Error(:final error) => Result.error(_neutralize(error)),
      };
}

final _log = Logger('BiliResult');

Exception _neutralize(Exception error) {
  if (error case BiliRiskControlException()) {
    // 中立异常只保留 message，这里把 bpi 带上的 statusCode / biliCode / uri
    // 一起打进日志，线上才分得清是风控还是普通失败。
    _log.warning('Bilibili risk-control rejection', error);
    return BiliRateLimitedException(error.message);
  }
  return error;
}

/// [BiliRiskControlException] 在 `data` 层的投影。
class const BiliRateLimitedException(final String message)
    implements RateLimitedFailure {
  @override
  String toString() => 'BiliRateLimitedException: $message';
}
