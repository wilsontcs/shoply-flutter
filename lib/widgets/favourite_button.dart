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
    onPressed: onPressed,
    isSelected: isFavourite,
    tooltip: isFavourite
        ? 'Remove $productName from wishlist'
        : 'Add $productName to wishlist',
    selectedIcon: const Icon(Icons.favorite),
    icon: const Icon(Icons.favorite_border),
  );
}
