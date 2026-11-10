import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shoply_flutter/app_router.dart';
import 'package:shoply_flutter/constants/dimensions.dart';
import 'package:shoply_flutter/controllers/favourites_controller.dart';
import 'package:shoply_flutter/controllers/product_detail_controller.dart';
import 'package:shoply_flutter/core/models/product_model.dart';
import 'package:shoply_flutter/utils/price_formatter.dart';
import 'package:shoply_flutter/widgets/catalogue_notice.dart';
import 'package:shoply_flutter/widgets/error_retry_view.dart';
import 'package:shoply_flutter/widgets/favourite_button.dart';
import 'package:shoply_flutter/widgets/loading_view.dart';
import 'package:shoply_flutter/widgets/product_image.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.arguments});

  final ProductDetailScreenArguments arguments;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductDetailController _controller = ProductDetailController(
    productId: widget.arguments.productId,
    product: widget.arguments.product,
  );
  final ValueNotifier<int> _imageIndex = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        unawaited(_fetchApiAsync());
      }
    });
  }

  Future<void> _fetchApiAsync() => _controller.loadAsync();

  void _back() {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRouter.home);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _imageIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FavouritesController favourites = context
        .watch<FavouritesController>();
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        final ProductModel? product = _controller.product;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Product details'),
            leading: BackButton(onPressed: _back),
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Dimensions.catalogueWidth,
              ),
              child: RefreshIndicator(
                onRefresh: _fetchApiAsync,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  slivers: <Widget>[
                    if (product == null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _controller.isLoading
                            ? const LoadingView(
                                label: 'Loading product details',
                              )
                            : ErrorRetryView(
                                message:
                                    _controller.error ??
                                    'This product is unavailable.',
                                onRetry: _fetchApiAsync,
                              ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(Dimensions.padding),
                        sliver: SliverToBoxAdapter(
                          child: _buildProduct(context, product, favourites),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProduct(
    BuildContext context,
    ProductModel product,
    FavouritesController favourites,
  ) {
    final ThemeData theme = Theme.of(context);
    final List<String> images = <String>{
      ...product.images.where((String image) => image.isNotEmpty),
      if (product.images.isEmpty) product.coverImage,
    }.toList();
    if (images.isEmpty) {
      images.add('');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_controller.isLoading)
          const LinearProgressIndicator(
            semanticsLabel: 'Updating product details',
          ),
        if (_controller.error != null)
          CatalogueNotice(
            icon: Icons.cloud_off_outlined,
            message: 'Showing saved product information. ${_controller.error}',
            onRetry: _fetchApiAsync,
          ),
        if (favourites.error != null)
          CatalogueNotice(
            icon: Icons.favorite_border,
            message: favourites.error!,
            onRetry: favourites.retryAsync,
          ),
        Stack(
          children: <Widget>[
            Hero(
              tag: ProductImage.heroTag(product.id),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radius),
                child: ColoredBox(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.25,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: PageView.builder(
                      key: ValueKey<String>('${product.id}-${images.length}'),
                      physics: const BouncingScrollPhysics(),
                      itemCount: images.length,
                      onPageChanged: (int index) => _imageIndex.value = index,
                      itemBuilder: (BuildContext context, int index) => Padding(
                        padding: const EdgeInsets.all(Dimensions.padding),
                        child: ProductImage(
                          url: images[index],
                          label:
                              '${product.title}, image ${index + 1} of ${images.length}',
                        ),
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
                isFavourite: favourites.contains(product.id),
                productName: product.title,
                onPressed: favourites.isReady
                    ? () => unawaited(favourites.toggleAsync(product))
                    : null,
              ),
            ),
          ],
        ),
        if (images.length > 1)
          ValueListenableBuilder<int>(
            valueListenable: _imageIndex,
            builder: (BuildContext context, int index, Widget? child) => Padding(
              padding: const EdgeInsets.all(Dimensions.spacing),
              child: Center(
                child: Text(
                  '${index.clamp(0, images.length - 1) + 1} / ${images.length} · Swipe for more images',
                ),
              ),
            ),
          ),
        const SizedBox(height: Dimensions.spacing * 3),
        Text(
          product.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: Dimensions.spacing),
        Text(
          formatPrice(product.price),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: Dimensions.spacing),
        Wrap(
          spacing: Dimensions.spacing * 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              '★ ${product.rating.toStringAsFixed(1)} / 5',
              style: theme.textTheme.titleMedium,
            ),
            Chip(
              avatar: const Icon(Icons.inventory_2_outlined, size: 18),
              label: Text(
                product.stock > 0
                    ? '${product.stock} in stock'
                    : 'Out of stock',
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.spacing * 3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Dimensions.padding),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(Dimensions.radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('About this product', style: theme.textTheme.titleLarge),
              const SizedBox(height: Dimensions.spacing),
              Text(
                product.description.isEmpty
                    ? 'No description is available.'
                    : product.description,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.spacing * 3),
      ],
    );
  }
}

class ProductDetailScreenArguments {
  const ProductDetailScreenArguments({required this.productId, this.product});

  final int productId;
  final ProductModel? product;
}
