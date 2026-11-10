import 'package:dio/dio.dart';

import '../models/json_parsing.dart';
import 'core_api_const.dart';
import 'core_api_error_resolver.dart';
import 'core_api_response.dart';

class CoreApiRequest {
  CoreApiRequest({Dio? client})
    : _client =
          client ??
          Dio(
            BaseOptions(
              baseUrl: CoreApiConst.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 15),
              responseType: ResponseType.json,
            ),
          );

  final Dio _client;

  Future<CoreApiResponse<Map<String, Object?>>> requestAsync({
    required String url,
    Map<String, Object?>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<Object?> response = await _client.get<Object?>(
        url,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return CoreApiResponse<Map<String, Object?>>(
        data: jsonObject(response.data),
      );
    } on DioException catch (error) {
      throw CoreApiErrorResolver.resolveDioException(error);
    } catch (error) {
      throw CoreApiErrorResolver.resolveUnexpectedException(error);
    }
  }

  void dispose() => _client.close(force: true);
}
