import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

//import 'package:f_biuli/utils/http_error.dart';
import 'package:f_biuli/utils/result.dart';
import 'api_result.dart';

class ApiCallAdapter<T>
  extends CallAdapter<Future<HttpResponse<ApiResult<T>>>, Future<Result<T>>>
{
  @override
  Future<Result<T>> adapt(Future<HttpResponse<ApiResult<T>>> Function() call) async {
    try {
      final httpResponse = await call();
      final response = httpResponse.response;
      final apiResult = httpResponse.data;
      if (apiResult.code != 0 || apiResult.data == null) {
        return Result.error(Exception('ERROR $response\n$apiResult'));
      }
      
      return Result.ok(apiResult.data);
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