import 'package:flutter/material.dart';

import 'package:shoply_flutter/constants/dimensions.dart';

class PaginationFooter extends StatelessWidget {
  const PaginationFooter({
    super.key,
    required this.isLoading,
    required this.hasMore,
    required this.onRetry,
    this.error,
  });

  final bool isLoading;
  final bool hasMore;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.padding),
      child: Center(
        child: isLoading
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  semanticsLabel: 'Loading more products',
                ),
              )
            : error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(error!, textAlign: TextAlign.center),
                  const SizedBox(height: Dimensions.spacing),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry loading more'),
                  ),
                ],
              )
            : Text(hasMore ? 'Scroll for more' : 'You\'ve reached the end.'),
      ),
    );
  }
}
