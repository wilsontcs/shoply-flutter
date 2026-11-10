import 'package:flutter/material.dart';

import '../constants/dimensions.dart';
import '../core/models/product_model.dart';
import '../utils/price_formatter.dart';
import 'favourite_button.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.isFavourite,
    required this.onOpen,
    this.onFavourite,
  });

  final ProductModel product;
  final bool isFavourite;
  final VoidCallback onOpen;
  final VoidCallback? onFavourite;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ProductImage(url: product.coverImage, label: product.title),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 4,
              bottom: Dimensions.spacing,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        formatPrice(product.price),
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Semantics(
                        label:
                            'Rated ${product.rating.toStringAsFixed(1)} out of 5',
                        child: ExcludeSemantics(
                          child: Text(
                            '★ ${product.rating.toStringAsFixed(1)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                FavouriteButton(
                  isFavourite: isFavourite,
                  productName: product.title,
                  onPressed: onFavourite,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
