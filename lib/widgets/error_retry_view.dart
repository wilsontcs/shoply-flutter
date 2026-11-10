import 'package:flutter/material.dart';

import 'empty_state_view.dart';

class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyStateView(
    icon: Icons.cloud_off_outlined,
    title: 'Let\'s try that again',
    message: message,
    actionLabel: 'Retry',
    onAction: onRetry,
  );
}
