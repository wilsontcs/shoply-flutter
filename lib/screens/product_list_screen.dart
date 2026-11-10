import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shoply_flutter/app_router.dart';
import 'package:shoply_flutter/constants/dimensions.dart';
import 'package:shoply_flutter/controllers/catalogue_controller.dart';
import 'package:shoply_flutter/controllers/favourites_controller.dart';
import 'package:shoply_flutter/controllers/recent_searches_controller.dart';
import 'package:shoply_flutter/core/models/product_model.dart';
import 'package:shoply_flutter/screens/product_detail_screen.dart';
import 'package:shoply_flutter/widgets/catalogue_notice.dart';
import 'package:shoply_flutter/widgets/empty_state_view.dart';
import 'package:shoply_flutter/widgets/error_retry_view.dart';
import 'package:shoply_flutter/widgets/loading_view.dart';
import 'package:shoply_flutter/widgets/pagination_footer.dart';
import 'package:shoply_flutter/widgets/product_grid.dart';
import 'package:shoply_flutter/widgets/product_search_bar.dart';
import 'package:shoply_flutter/widgets/recent_searches_panel.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final RecentSearchesController _recentSearches = RecentSearchesController();
  late final CatalogueController _catalogue = CatalogueController(
    recentSearches: _recentSearches,
  );
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchText = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ValueNotifier<bool> _searchExpanded = ValueNotifier<bool>(false);
  late final Listenable _changes = Listenable.merge(<Listenable>[
    _catalogue,
    _recentSearches,
    _searchText,
    _searchFocus,
    _searchExpanded,
  ]);
  bool _queryWasEdited = false;
  int _lastSearchRevision = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _catalogue.addListener(_syncRestoredQuery);
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        unawaited(_fetchApiAsync());
        unawaited(_recentSearches.initializeAsync());
      }
    });
  }

  Future<void> _fetchApiAsync() => _catalogue.initializeAsync();

  void _syncRestoredQuery() {
    if (_lastSearchRevision != _catalogue.searchRevision) {
      _lastSearchRevision = _catalogue.searchRevision;
      if (_scroll.hasClients) {
        _scroll.jumpTo(0);
      }
    }
    if (!_queryWasEdited && _searchText.text != _catalogue.query) {
      _searchText.value = TextEditingValue(
        text: _catalogue.query,
        selection: TextSelection.collapsed(offset: _catalogue.query.length),
      );
      _searchExpanded.value = _catalogue.query.isNotEmpty;
    }
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 320) {
      unawaited(_catalogue.loadMoreAsync());
    }
  }

  void _loadMoreIfNeeded() {
    if (_catalogue.canLoadMore && _catalogue.products.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) {
          _onScroll();
        }
      });
    }
  }

  void _showSearch() {
    _searchExpanded.value = true;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        _searchFocus.requestFocus();
      }
    });
  }

  void _changeQuery(String value, {bool immediately = false}) {
    _queryWasEdited = true;
    _catalogue.changeQuery(value, immediately: immediately);
  }

  void _selectRecent(String query) {
    _searchText.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _changeQuery(query, immediately: true);
    _searchFocus.unfocus();
  }

  void _clearSearch() {
    _queryWasEdited = true;
    _searchText.clear();
    _catalogue.clearSearch();
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    _searchExpanded.value = false;
    _clearSearch();
  }

  Future<void> _refreshAsync() async {
    await _catalogue.refreshAsync();
    if (mounted &&
        _scroll.hasClients &&
        _catalogue.refreshError == null &&
        _catalogue.initialError == null) {
      _scroll.jumpTo(0);
    }
  }

  void _openProduct(ProductModel product) {
    _searchFocus.unfocus();
    GoRouter.of(context).push<void>(
      AppRouter.productDetail.replaceFirst(':id', product.id.toString()),
      extra: ProductDetailScreenArguments(
        productId: product.id,
        product: product,
      ),
    );
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _catalogue.removeListener(_syncRestoredQuery);
    _scroll.dispose();
    _catalogue.dispose();
    _recentSearches.dispose();
    _searchText.dispose();
    _searchFocus.dispose();
    _searchExpanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FavouritesController favourites = context
        .watch<FavouritesController>();
    return ListenableBuilder(
      listenable: _changes,
      builder: (BuildContext context, Widget? child) {
        _loadMoreIfNeeded();
        return PopScope<void>(
          canPop: !widget.isActive || !_searchExpanded.value,
          onPopInvokedWithResult: (bool didPop, void result) {
            if (!didPop && widget.isActive && _searchExpanded.value) {
              _closeSearch();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              leading: _searchExpanded.value
                  ? IconButton(
                      tooltip: 'Close search',
                      onPressed: _closeSearch,
                      icon: const Icon(Icons.arrow_back),
                    )
                  : null,
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _searchExpanded.value
                    ? ProductSearchBar(
                        key: const ValueKey<String>('expanded-search'),
                        controller: _searchText,
                        focusNode: _searchFocus,
                        onChanged: (String value) => _changeQuery(value),
                        onSubmitted: (String value) {
                          _changeQuery(value, immediately: true);
                          _searchFocus.unfocus();
                        },
                        onClear: _clearSearch,
                      )
                    : const Align(
                        key: ValueKey<String>('catalogue-title'),
                        alignment: Alignment.centerLeft,
                        child: Text('Shoply'),
                      ),
              ),
              actions: <Widget>[
                if (!_searchExpanded.value)
                  IconButton(
                    tooltip: 'Search products',
                    onPressed: _showSearch,
                    icon: const Icon(Icons.search),
                  ),
              ],
            ),
            body: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Dimensions.catalogueWidth,
                ),
                child: RefreshIndicator(
                  onRefresh: _refreshAsync,
                  child: CustomScrollView(
                    key: const PageStorageKey<String>('catalogue-scroll'),
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    slivers: <Widget>[
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.padding,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (_searchExpanded.value &&
                                  _searchFocus.hasFocus)
                                TextFieldTapRegion(
                                  child: RecentSearchesPanel(
                                    controller: _recentSearches,
                                    onSelect: _selectRecent,
                                  ),
                                ),
                              const SizedBox(height: Dimensions.spacing),
                              if (_catalogue.query.isNotEmpty) ...<Widget>[
                                Text(
                                  'Results for "${_catalogue.query}"',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: Dimensions.spacing),
                              ],
                              if (_catalogue.hasSnapshot)
                                Text(_catalogue.countLabel),
                              ..._notices(favourites),
                              if (_catalogue.isRefreshing &&
                                  _catalogue.hasSnapshot)
                                const LinearProgressIndicator(
                                  semanticsLabel: 'Refreshing products',
                                ),
                              const SizedBox(height: Dimensions.spacing * 2),
                            ],
                          ),
                        ),
                      ),
                      if (_catalogue.isInitialLoading)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: LoadingView(),
                        )
                      else if (!_catalogue.hasSnapshot &&
                          _catalogue.initialError != null)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: ErrorRetryView(
                            message: _catalogue.initialError!,
                            onRetry: _refreshAsync,
                          ),
                        )
                      else if (_catalogue.products.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyStateView(
                            icon: _catalogue.query.isEmpty
                                ? Icons.inventory_2_outlined
                                : Icons.search_off,
                            title: _catalogue.query.isEmpty
                                ? 'No products yet'
                                : 'No matches found',
                            message: _catalogue.query.isEmpty
                                ? 'Pull down to check for products again.'
                                : 'Try another product name.',
                          ),
                        )
                      else ...<Widget>[
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.padding,
                          ),
                          sliver: ProductGrid(
                            products: _catalogue.products,
                            onOpen: _openProduct,
                          ),
                        ),
                        if (!_catalogue.requiresRefresh)
                          SliverToBoxAdapter(
                            child: PaginationFooter(
                              isLoading: _catalogue.isLoadingMore,
                              hasMore: _catalogue.hasMore,
                              error: _catalogue.pageError,
                              onRetry: _catalogue.retryPageAsync,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _notices(FavouritesController favourites) => <Widget>[
    if (_catalogue.isShowingSavedList || _catalogue.refreshError != null)
      CatalogueNotice(
        icon: _catalogue.refreshError != null
            ? Icons.cloud_off_outlined
            : Icons.history,
        message: _catalogue.refreshError != null
            ? 'Showing saved products. ${_catalogue.refreshError}'
            : _catalogue.isRefreshing
            ? 'Showing saved products while checking for updates.'
            : 'Showing saved products. Pull down to check for updates.',
        onRetry: _catalogue.isRefreshing ? null : _refreshAsync,
      ),
    if (_catalogue.storageError != null)
      CatalogueNotice(
        icon: Icons.save_outlined,
        message: _catalogue.storageError!,
        onRetry: _catalogue.isRetryingStorage
            ? null
            : _catalogue.retryStorageAsync,
      ),
    if (favourites.error != null)
      CatalogueNotice(
        icon: Icons.favorite_border,
        message: favourites.error!,
        onRetry: favourites.retryAsync,
      ),
  ];
}
