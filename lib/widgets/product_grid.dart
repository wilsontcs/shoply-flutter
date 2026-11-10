import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoply_flutter/constants/dimensions.dart';
import 'package:shoply_flutter/controllers/favourites_controller.dart';
import 'package:shoply_flutter/core/models/product_model.dart';
import 'package:shoply_flutter/widgets/product_card.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products, required this.onOpen});

  final List<ProductModel> products;
  final ValueChanged<ProductModel> onOpen;

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: Dimensions.spacing * 1.5,
        crossAxisSpacing: Dimensions.spacing * 1.5,
        mainAxisExtent: ProductCard.extentFor(context),
      ),
      itemBuilder: (BuildContext context, int index) {
        final ProductModel product = products[index];
        return Selector<FavouritesController, ({bool selected, bool ready})>(
          key: ValueKey<int>(product.id),
          selector: (BuildContext context, FavouritesController favourites) => (
            selected: favourites.contains(product.id),
            ready: favourites.isReady,
          ),
          builder:
              (
                BuildContext context,
                ({bool selected, bool ready}) state,
                Widget? child,
              ) => ProductCard(
                product: product,
                isFavourite: state.selected,
                onOpen: () => onOpen(product),
                onFavourite: state.ready
                    ? () => unawaited(
                        context.read<FavouritesController>().toggleAsync(
                          product,
                        ),
                      )
                    : null,
              ),
        );
      },
    );
  }
}
