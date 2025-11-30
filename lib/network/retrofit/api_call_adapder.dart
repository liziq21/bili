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
      final HttpResponse(:response, data:apiResult) = await call();
      if (apiResult.data != null) {
        return Result.ok(apiResult.data);
      }
      
      if (apiResult.result != null) {
        return Result.ok(apiResult.result);
      }
      
      return Result.error(Exception('ERROR $response\n$apiResult'));
    } on DioException catch (e) {
      final response = e.response;
      final data = response?.data?.toString();
      return Result.error(Exception(
          'ERROR $response\n${data ?? e.message}'
      ));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}