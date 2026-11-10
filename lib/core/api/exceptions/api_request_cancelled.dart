/// Cancellation is control flow and must not be displayed as a failed request.
class ApiRequestCancelled implements Exception {
  const ApiRequestCancelled();
}
