import 'package:shoply_flutter/core/api/exceptions/base_api_exception.dart';

class ApiRequestException extends BaseApiException {
  const ApiRequestException(super.failure, {super.statusCode});
}
