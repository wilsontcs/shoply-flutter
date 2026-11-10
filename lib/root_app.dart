import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:shoply_flutter/app_router.dart';
import 'package:shoply_flutter/controllers/favourites_controller.dart';
import 'package:shoply_flutter/utils/app_theme_config.dart';

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  final GoRouter _appRouter = AppRouter.appRouter();

  @override
  void dispose() {
    _appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<FavouritesController>(
        lazy: false,
        create: (BuildContext context) {
          final FavouritesController favourites = FavouritesController();
          unawaited(favourites.loadAsync());
          return favourites;
        },
      ),
    ],
    child: MaterialApp.router(
      title: 'Shoply',
      debugShowCheckedModeBanner: false,
      theme: AppThemeConfig.light,
      routeInformationParser: _appRouter.routeInformationParser,
      routerDelegate: _appRouter.routerDelegate,
      routeInformationProvider: _appRouter.routeInformationProvider,
    ),
  );
}
