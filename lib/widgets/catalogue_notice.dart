import 'package:flutter/material.dart';

import 'package:shoply_flutter/constants/dimensions.dart';

class CatalogueNotice extends StatelessWidget {
  const CatalogueNotice({
    super.key,
    required this.message,
    required this.icon,
    this.onRetry,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Dimensions.spacing),
        padding: const EdgeInsets.all(Dimensions.spacing * 1.5),
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          borderRadius: BorderRadius.circular(Dimensions.radius),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: colors.onSecondaryContainer),
            const SizedBox(width: Dimensions.spacing),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onSecondaryContainer),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
