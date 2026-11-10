import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shoply_flutter/app_router.dart';
import 'package:shoply_flutter/constants/dimensions.dart';
import 'package:shoply_flutter/controllers/favourites_controller.dart';
import 'package:shoply_flutter/core/models/product_model.dart';
import 'package:shoply_flutter/screens/product_detail_screen.dart';
import 'package:shoply_flutter/widgets/catalogue_notice.dart';
import 'package:shoply_flutter/widgets/empty_state_view.dart';
import 'package:shoply_flutter/widgets/error_retry_view.dart';
import 'package:shoply_flutter/widgets/loading_view.dart';
import 'package:shoply_flutter/widgets/product_grid.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key, this.onBrowseProducts});

  final VoidCallback? onBrowseProducts;

  void _openProduct(BuildContext context, ProductModel product) {
    GoRouter.of(context).push<void>(
      AppRouter.productDetail.replaceFirst(':id', product.id.toString()),
      extra: ProductDetailScreenArguments(
        productId: product.id,
        product: product,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FavouritesController favourites = context
        .watch<FavouritesController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: favourites.isLoading
          ? const LoadingView(label: 'Loading your wishlist')
          : !favourites.isReady
          ? ErrorRetryView(
              message: favourites.error ?? 'Your wishlist could not be loaded.',
              onRetry: favourites.retryAsync,
            )
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Dimensions.catalogueWidth,
                ),
                child: CustomScrollView(
                  key: const PageStorageKey<String>('wishlist-scroll'),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  slivers: <Widget>[
                    if (favourites.error != null)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.padding,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: CatalogueNotice(
                            icon: Icons.save_outlined,
                            message: favourites.error!,
                            onRetry: favourites.retryAsync,
                          ),
                        ),
                      ),
                    if (favourites.products.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyStateView(
                          icon: Icons.favorite_border,
                          title: 'Keep your favourites close',
                          message: 'Tap a heart on a product to save it here.',
                          actionLabel: 'Browse products',
                          onAction:
                              onBrowseProducts ??
                              () => GoRouter.of(context).go(AppRouter.home),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(Dimensions.padding),
                        sliver: ProductGrid(
                          products: favourites.products,
                          onOpen: (ProductModel product) =>
                              _openProduct(context, product),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
