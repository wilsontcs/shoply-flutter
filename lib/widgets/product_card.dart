import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shoply_flutter/constants/dimensions.dart';
import 'package:shoply_flutter/core/models/product_model.dart';
import 'package:shoply_flutter/utils/price_formatter.dart';
import 'package:shoply_flutter/widgets/favourite_button.dart';
import 'package:shoply_flutter/widgets/product_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.isFavourite,
    required this.onOpen,
    this.onFavourite,
  });

  static const double _imageHeight = 136;
  static const double _padding = 12;
  static const double _titleLineHeight = 1.35;
  final ProductModel product;
  final bool isFavourite;
  final VoidCallback onOpen;
  final VoidCallback? onFavourite;

  static double _titleHeight(BuildContext context) =>
      MediaQuery.textScalerOf(
        context,
      ).scale(Theme.of(context).textTheme.titleSmall!.fontSize!) *
      _titleLineHeight *
      2;

  static double extentFor(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double rowHeight = math.max(
      scaler.scale(textTheme.bodyMedium!.fontSize!) *
          (textTheme.bodyMedium!.height ?? 1.5),
      scaler.scale(textTheme.bodySmall!.fontSize!) *
          (textTheme.bodySmall!.height ?? 1.5),
    );
    return _imageHeight +
        _padding * 2 +
        _titleHeight(context) +
        Dimensions.spacing +
        rowHeight +
        4;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: _imageHeight,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Center(
                        child: SizedBox.square(
                          dimension: 108,
                          child: Hero(
                            tag: ProductImage.heroTag(product.id),
                            child: ProductImage(
                              url: product.coverImage,
                              label: product.title,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: FavouriteButton(
                      isFavourite: isFavourite,
                      productName: product.title,
                      onPressed: onFavourite,
                    ),
                  ),
                ],
              ),
            ),
            ColoredBox(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.38),
              child: Padding(
                padding: const EdgeInsets.all(_padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      height: _titleHeight(context),
                      child: Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          height: _titleLineHeight,
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.spacing),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            formatPrice(product.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Semantics(
                          label:
                              'Rated ${product.rating.toStringAsFixed(1)} out of 5',
                          child: ExcludeSemantics(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: theme.colorScheme.tertiary,
                                ),
                                Text(
                                  product.rating.toStringAsFixed(1),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
