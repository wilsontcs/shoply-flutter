import 'package:flutter/material.dart';

class FavouriteButton extends StatelessWidget {
  const FavouriteButton({
    super.key,
    required this.isFavourite,
    required this.productName,
    this.onPressed,
  });

  final bool isFavourite;
  final String productName;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    style: IconButton.styleFrom(
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
      size: 20,
      color: Theme.of(context).colorScheme.error,
    ),
    icon: const Icon(Icons.favorite_border, size: 20),
  );
}
