import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_router.dart';
import '../widgets/empty_state_view.dart';

/// ID-based route shell; product content and requests are implemented in Part 4.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.arguments});

  final ProductDetailScreenArguments arguments;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Product #${arguments.productId}'),
      leading: BackButton(
        onPressed: () {
          final GoRouter router = GoRouter.of(context);
          if (router.canPop()) {
            router.pop();
          } else {
            router.go(AppRouter.home);
          }
        },
      ),
    ),
    body: const SingleChildScrollView(
      child: EmptyStateView(
        icon: Icons.shopping_bag_outlined,
        title: 'Product details',
        message: 'Images and product information will appear here.',
      ),
    ),
  );
}

class ProductDetailScreenArguments {
  const ProductDetailScreenArguments({required this.productId});

  final int productId;
}
