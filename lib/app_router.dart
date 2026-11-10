import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:shoply_flutter/screens/error_screen.dart';
import 'package:shoply_flutter/screens/main_screen.dart';
import 'package:shoply_flutter/screens/product_detail_screen.dart';
import 'package:shoply_flutter/screens/wishlist_screen.dart';

class AppRouter {
  static const String home = '/';
  static const String wishlist = '/wishlist';
  static const String productDetail = '/product_detail/:id';

  static GoRouter appRouter() {
    return GoRouter(
      routerNeglect: true,
      initialLocation: AppRouter.home,
      errorPageBuilder: (BuildContext context, GoRouterState state) {
        return MaterialPage<void>(
          key: state.pageKey,
          child: ErrorScreen(
            arguments: state.extra is ErrorScreenArguments
                ? state.extra as ErrorScreenArguments
                : ErrorScreenArguments(message: state.error?.message),
          ),
        );
      },
      routes: <RouteBase>[
        GoRoute(
          path: AppRouter.home,
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage<void>(key: state.pageKey, child: const MainScreen()),
        ),
        GoRoute(
          path: AppRouter.wishlist,
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage<void>(
                key: state.pageKey,
                child: const WishlistScreen(),
              ),
        ),
        GoRoute(
          path: AppRouter.productDetail,
          pageBuilder: (BuildContext context, GoRouterState state) {
            final int? id = int.tryParse(state.pathParameters['id'] ?? '');
            final ProductDetailScreenArguments? arguments =
                state.extra is ProductDetailScreenArguments
                ? state.extra as ProductDetailScreenArguments
                : id != null && id > 0
                ? ProductDetailScreenArguments(productId: id)
                : null;
            if (arguments == null || arguments.productId <= 0) {
              return MaterialPage<void>(
                key: state.pageKey,
                child: const ErrorScreen(
                  arguments: ErrorScreenArguments(
                    message: 'This product could not be found.',
                  ),
                ),
              );
            }
            return MaterialPage<void>(
              key: state.pageKey,
              child: ProductDetailScreen(arguments: arguments),
            );
          },
        ),
      ],
    );
  }
}
