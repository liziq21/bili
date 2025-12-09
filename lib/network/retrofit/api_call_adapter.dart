import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../utils/result.dart';
import 'api_result.dart';

class ApiCallAdapter<T>
  extends CallAdapter<Future<HttpResponse<ApiResult<T>>>, Future<Result<T>>>
{
  @override
  Future<Result<T>> adapt(Future<HttpResponse<ApiResult<T>>> Function() call) async {
    try {
      final HttpResponse(:response, data :apiResult) = await call();
      return switch (apiResult) {
        ApiResultOk() => .ok(apiResult.data),
        ApiResultError() => .error(Exception('ApiResultError: ${apiResult.error}')),
      };
    } on DioException catch (e) {
      String? data;
      if (e.response?.statusCode != 404) {
        data = e.response?.data?.toString();
      }
      return .error(Exception('${data ?? e.message}'));
    } on Exception catch (e) {
      return .error(e);
    }
  }
}