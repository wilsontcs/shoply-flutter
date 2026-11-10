import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_router.dart';
import '../widgets/empty_state_view.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.arguments});

  final ErrorScreenArguments arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: EmptyStateView(
        icon: Icons.search_off,
        title: 'Nothing here',
        message: arguments.message ?? 'This page could not be found.',
        actionLabel: 'Browse products',
        onAction: () => GoRouter.of(context).go(AppRouter.home),
      ),
    );
  }
}

class ErrorScreenArguments {
  const ErrorScreenArguments({this.message});

  final String? message;
}
