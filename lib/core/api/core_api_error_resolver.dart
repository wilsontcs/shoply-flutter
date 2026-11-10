import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../constants/enums.dart';
import 'exceptions/exception.dart';

abstract final class CoreApiErrorResolver {
  static Exception resolveDioException(DioException exception) {
    if (CancelToken.isCancel(exception)) {
      return const ApiRequestCancelled();
    }
    final int? statusCode = exception.response?.statusCode;
    if (exception.error is FormatException) {
      return const ApiRequestException(ApiFailure.invalidData);
    }
    final ApiFailure failure = switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => ApiFailure.timeout,
      DioExceptionType.connectionError => ApiFailure.offline,
      DioExceptionType.badResponse =>
        statusCode == 404 ? ApiFailure.notFound : ApiFailure.server,
      _ => ApiFailure.unknown,
    };
    return ApiRequestException(failure, statusCode: statusCode);
  }

  static Exception resolveUnexpectedException(Object exception) {
    if (exception is ApiRequestCancelled || exception is BaseApiException) {
      return exception as Exception;
    }
    if (exception is FormatException ||
        exception is CheckedFromJsonException ||
        exception is TypeError) {
      return const ApiRequestException(ApiFailure.invalidData);
    }
    return const ApiRequestException(ApiFailure.unknown);
  }
}
