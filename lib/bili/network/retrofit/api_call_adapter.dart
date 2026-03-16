import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:retrofit/retrofit.dart';

import '../../utils/result.dart';
import '../model/api_result.dart';

class ApiCallAdapter<T>
  extends CallAdapter<Future<HttpResponse<ApiResult<T>>>, Future<Result<T>>>
{
  final _log = Logger('ApiCallAdapter');
  
  @override
  Future<Result<T>> adapt(Future<HttpResponse<ApiResult<T>>> Function() call) async {
    try {
      final HttpResponse(:response, data :apiResult) = await call();
      return switch (apiResult) {
        ApiResultOk() => .ok(apiResult.data),
        ApiResultError() => .error(Exception('$apiResult')),
      };
    } on DioException catch (e, s) {
      String? data;
      if (e.response?.statusCode != 404) {
        data = e.response?.data?.toString();
      }
      _log.shout('DioException', data ?? e, s);
      return .error(Exception('${data ?? e.message}'));
    } catch (e, s) {
      _log.shout('Unexpected uncaught exception', e, s);
      return .error(Exception('$e'));
    }
  }
}