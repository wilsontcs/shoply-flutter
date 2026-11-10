import 'package:flutter/foundation.dart';

import 'package:shoply_flutter/core/api/core_api_request.dart';

/// Repositories own their default client, following the reference BaseRepo.
abstract class BaseRepo {
  BaseRepo({CoreApiRequest? api})
    : api = api ?? CoreApiRequest(),
      _ownsApi = api == null;

  @protected
  final CoreApiRequest api;
  final bool _ownsApi;

  /// A controller that creates a repo must dispose it with its own lifecycle.
  void dispose() {
    if (_ownsApi) {
      api.dispose();
    }
  }
}
