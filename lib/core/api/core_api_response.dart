import 'package:shoply_flutter/constants/enums.dart';

/// DummyJSON returns JSON directly; repositories map it to a typed success.
/// Failures and cancellation are thrown rather than returned as empty data.
class CoreApiResponse<T> {
  const CoreApiResponse({
    required this.data,
    this.status = CoreApiResponseStatus.success,
    this.message = '',
  });

  final CoreApiResponseStatus status;
  final String message;
  final T data;
}
