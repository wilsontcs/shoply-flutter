import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_router.dart';
import '../constants/dimensions.dart';
import '../controllers/favourites_controller.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_retry_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key, this.onBrowseProducts});

  final VoidCallback? onBrowseProducts;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Wishlist')),
    body: Consumer<FavouritesController>(
      builder:
          (
            BuildContext context,
            FavouritesController favourites,
            Widget? child,
          ) {
            if (favourites.isLoading) {
              return const LoadingView(label: 'Loading your wishlist');
            }
            if (favourites.error != null) {
              return ErrorRetryView(
                message: favourites.error!,
                onRetry: favourites.loadAsync,
              );
            }
            if (favourites.products.isEmpty) {
              return EmptyStateView(
                icon: Icons.favorite_border,
                title: 'Keep your favourites close',
                message: 'Products you save will be waiting here.',
                actionLabel: 'Browse products',
                onAction:
                    onBrowseProducts ??
                    () => GoRouter.of(context).go(AppRouter.home),
              );
            }
            return ListView.builder(
              key: const PageStorageKey<String>('wishlist-scroll'),
              padding: const EdgeInsets.all(Dimensions.padding),
              itemCount: favourites.products.length,
              itemBuilder: (BuildContext context, int index) => Align(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: ProductCard(
                    product: favourites.products[index],
                    isFavourite: true,
                    onOpen: () => GoRouter.of(context).push<void>(
                      AppRouter.productDetail.replaceFirst(
                        ':id',
                        favourites.products[index].id.toString(),
                      ),
                      extra: ProductDetailScreenArguments(
                        productId: favourites.products[index].id,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
    ),
  );
}
