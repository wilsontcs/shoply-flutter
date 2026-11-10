import 'package:shoply_flutter/constants/enums.dart';

abstract class BaseApiException implements Exception {
  const BaseApiException(this.failure, {this.statusCode});

  final ApiFailure failure;
  final int? statusCode;

  String get message => switch (failure) {
    ApiFailure.offline =>
      'Unable to connect. Check your internet connection and try again.',
    ApiFailure.timeout => 'The connection took too long. Please try again.',
    ApiFailure.server =>
      'Products are temporarily unavailable. Please try again.',
    ApiFailure.notFound => 'This product could not be found.',
    ApiFailure.invalidData =>
      'We could not read the product information. Please try again.',
    ApiFailure.unknown => 'Something went wrong. Please try again.',
  };

  @override
  String toString() => '$runtimeType(${failure.name}, status: $statusCode)';
}
