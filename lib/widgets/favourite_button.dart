import 'package:flutter/material.dart';

class FavouriteButton extends StatelessWidget {
  const FavouriteButton({
    super.key,
    required this.isFavourite,
    required this.productName,
    this.onPressed,
    this.compact = false,
  });

  final bool isFavourite;
  final String productName;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) => IconButton(
    style: IconButton.styleFrom(
      minimumSize: compact ? const Size.square(36) : const Size.square(48),
      fixedSize: compact ? const Size.square(36) : null,
      tapTargetSize: MaterialTapTargetSize.padded,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerLowest.withValues(alpha: 0.85),
    ),
    onPressed: onPressed,
    isSelected: isFavourite,
    tooltip: isFavourite
        ? 'Remove $productName from wishlist'
        : 'Add $productName to wishlist',
    selectedIcon: Icon(
      Icons.favorite,
      size: compact ? 18 : 20,
      color: Theme.of(context).colorScheme.error,
    ),
    icon: Icon(Icons.favorite_border, size: compact ? 18 : 20),
  );
}
