import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:shoply_flutter/constants/enums.dart';
import 'package:shoply_flutter/core/api/exceptions/exception.dart';
import 'package:shoply_flutter/core/models/catalogue_cache_model.dart';
import 'package:shoply_flutter/core/models/product_model.dart';
import 'package:shoply_flutter/core/models/product_page_model.dart';
import 'package:shoply_flutter/repositories/local_storage_repo.dart';
import 'package:shoply_flutter/repositories/product_repo.dart';
import 'package:shoply_flutter/controllers/recent_searches_controller.dart';

class CatalogueController extends ChangeNotifier {
  CatalogueController({
    required this.recentSearches,
    ProductRepo? productRepo,
    LocalStorageRepo? storageRepo,
  }) : _productRepo = productRepo ?? ProductRepo(),
       _storageRepo = storageRepo ?? LocalStorageRepo(),
       _ownsProductRepo = productRepo == null;

  final ProductRepo _productRepo;
  final LocalStorageRepo _storageRepo;
  final bool _ownsProductRepo;
  final RecentSearchesController recentSearches;
  Timer? _debounce;
  String _query = '';
  String _pendingQuery = '';
  int _searchRevision = 0;
  int _pendingClearRevision = 0;
  bool _isDebouncing = false;
  bool _serverHasMore = false;
  List<ProductModel> _searchBuffer = const <ProductModel>[];
  List<ProductModel> _products = const <ProductModel>[];
  Future<void>? _initialization;
  CancelToken? _requestToken;
  CatalogueCacheModel? _pendingCache;
  int _generation = 0;
  int _cacheWriteRevision = 0;
  int _offset = 0;
  int _total = 0;
  bool _isDisposed = false;
  bool _isRestoring = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _isRetryingStorage = false;
  bool _hasSnapshot = false;
  bool _hasMore = false;
  bool _requiresRefresh = true;
  bool _isShowingSavedList = false;
  String? _initialError;
  String? _refreshError;
  String? _pageError;
  String? _storageError;

  List<ProductModel> get products => _products;
  int get total => _total;
  String get query => _query;
  int get searchRevision => _searchRevision;
  bool get isDebouncing => _isDebouncing;
  String get countLabel => _query.isEmpty
      ? '${_products.length} of $_total products'
      : '${_products.length} matching products${_hasMore ? ' loaded' : ''}';
  bool get isRestoring => _isRestoring;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRetryingStorage => _isRetryingStorage;
  bool get hasSnapshot => _hasSnapshot;
  bool get hasMore => _hasMore;
  bool get requiresRefresh => _requiresRefresh;
  bool get isShowingSavedList => _isShowingSavedList;
  bool get isInitialLoading => _isRestoring || (!_hasSnapshot && _isRefreshing);
  String? get initialError => _initialError;
  String? get refreshError => _refreshError;
  String? get pageError => _pageError;
  String? get storageError => _storageError;

  bool get canLoadMore =>
      !_isDisposed &&
      !_isDebouncing &&
      _hasSnapshot &&
      _hasMore &&
      !_requiresRefresh &&
      !_isRestoring &&
      !_isRefreshing &&
      !_isLoadingMore &&
      _pageError == null;

  Future<void> initializeAsync() {
    if (_isDisposed) {
      return Future<void>.value();
    }
    return _initialization ??= _restoreAndRefreshAsync();
  }

  Future<void> _restoreAndRefreshAsync() async {
    final int generation = _startGeneration();
    _isRestoring = true;
    _notify();
    try {
      final CatalogueCacheModel? cache = await _storageRepo
          .readCatalogueAsync();
      if (!_isCurrent(generation)) {
        return;
      }
      _storageError = null;
      if (cache != null) {
        _query = cache.query;
        _pendingQuery = cache.query;
        _products = cache.products;
        _offset = cache.offset;
        _total = cache.total;
        _hasSnapshot = true;
        _hasMore = _offset < _total;
        _serverHasMore = _hasMore;
        _requiresRefresh = true;
        _isShowingSavedList = true;
      }
    } catch (_) {
      if (_isCurrent(generation)) {
        _storageError = 'Saved products could not be read from this device.';
      }
    }
    if (!_isCurrent(generation)) {
      return;
    }
    _isRestoring = false;
    _notify();
    await refreshAsync();
  }

  void changeQuery(String input, {bool immediately = false}) {
    if (_isDisposed) {
      return;
    }
    final String query = input.trim();
    if (!immediately && query == (_isDebouncing ? _pendingQuery : _query)) {
      return;
    }
    if (!immediately && query == _query && _hasSnapshot) {
      _debounce?.cancel();
      _startGeneration();
      _pendingQuery = query;
      _isDebouncing = false;
      _isRefreshing = false;
      _isLoadingMore = false;
      _notify();
      return;
    }
    _debounce?.cancel();
    final int generation = _startGeneration();
    final int clearRevision = recentSearches.clearRevision;
    _pendingClearRevision = clearRevision;
    _pendingQuery = query;
    _isRestoring = false;
    if (_hasSnapshot) {
      _isRefreshing = false;
    }
    _isLoadingMore = false;
    _isDebouncing = true;
    _notify();
    if (immediately) {
      unawaited(_dispatchSearchAsync(generation, clearRevision));
    } else {
      _debounce = Timer(const Duration(milliseconds: 350), () {
        unawaited(_dispatchSearchAsync(generation, clearRevision));
      });
    }
  }

  Future<void> _dispatchSearchAsync(int generation, int clearRevision) async {
    if (!_isCurrent(generation)) {
      return;
    }
    _commitPendingQuery();
    if (_query.isNotEmpty) {
      unawaited(
        recentSearches.recordAsync(_query, clearRevision: clearRevision),
      );
    }
    await refreshAsync();
  }

  void _commitPendingQuery() {
    _query = _pendingQuery;
    _isDebouncing = false;
    _searchRevision++;
    _products = const <ProductModel>[];
    _searchBuffer = const <ProductModel>[];
    _offset = 0;
    _total = 0;
    _hasSnapshot = false;
    _hasMore = false;
    _initialError = null;
    _refreshError = null;
    _pageError = null;
    _isShowingSavedList = false;
    _requiresRefresh = true;
  }

  void clearSearch() {
    if (_isDisposed) {
      return;
    }
    if (_query.isEmpty) {
      if (_isDebouncing) {
        _debounce?.cancel();
        _startGeneration();
        _pendingQuery = '';
        _isDebouncing = false;
        _isRefreshing = false;
        _isLoadingMore = false;
        _notify();
        if (!_hasSnapshot) {
          unawaited(refreshAsync());
        }
      }
      return;
    }
    changeQuery('', immediately: true);
  }

  Future<void> refreshAsync() async {
    if (_isDisposed) {
      return;
    }
    if (_isDebouncing) {
      _commitPendingQuery();
      if (_query.isNotEmpty) {
        unawaited(
          recentSearches.recordAsync(
            _query,
            clearRevision: _pendingClearRevision,
          ),
        );
      }
    }
    final int generation = _startGeneration();
    _debounce?.cancel();
    _isDebouncing = false;
    final CancelToken token = CancelToken();
    _requestToken = token;
    _isRestoring = false;
    _isRefreshing = true;
    _isLoadingMore = false;
    _requiresRefresh = true;
    _initialError = null;
    _refreshError = null;
    _pageError = null;
    _notify();
    try {
      final _LoadedCataloguePage page = await _fetchPageAsync(
        offset: 0,
        query: _query,
        token: token,
        replace: true,
      );
      if (!_isCurrent(generation)) {
        return;
      }
      _applyPage(page, replace: true);
      _requiresRefresh = false;
      _isShowingSavedList = false;
      _notify();
      await _saveSnapshotAsync(generation);
    } on ApiRequestCancelled {
      // A newer generation owns the screen; cancellation is not an error.
    } catch (error) {
      if (_isCurrent(generation)) {
        if (_hasSnapshot) {
          _refreshError = _errorMessage(error);
        } else {
          _initialError = _errorMessage(error);
        }
      }
    } finally {
      if (_isCurrent(generation)) {
        _isRefreshing = false;
        _requestToken = null;
        _notify();
      }
    }
  }

  Future<void> loadMoreAsync() async {
    if (!canLoadMore) {
      return;
    }
    final int generation = _generation;
    final int offset = _offset;
    final CancelToken token = CancelToken();
    _requestToken = token;
    _isLoadingMore = true;
    _notify();
    try {
      final _LoadedCataloguePage page = await _fetchPageAsync(
        offset: offset,
        query: _query,
        token: token,
        replace: false,
      );
      if (!_isCurrent(generation)) {
        return;
      }
      _applyPage(page, replace: false);
      _notify();
      await _saveSnapshotAsync(generation);
    } on ApiRequestCancelled {
      // Refresh cancels the old page request before replacing its data.
    } catch (error) {
      if (_isCurrent(generation)) {
        _pageError = _errorMessage(error);
      }
    } finally {
      if (_isCurrent(generation)) {
        _isLoadingMore = false;
        _requestToken = null;
        _notify();
      }
    }
  }

  Future<void> retryPageAsync() async {
    if (_isDisposed || _isLoadingMore || _isRefreshing || _requiresRefresh) {
      return;
    }
    _pageError = null;
    await loadMoreAsync();
  }

  Future<_LoadedCataloguePage> _fetchPageAsync({
    required int offset,
    required String query,
    required CancelToken token,
    required bool replace,
  }) async {
    int nextOffset = offset;
    int total = replace ? 0 : _total;
    bool more = replace || _serverHasMore;
    final List<ProductModel> matches = <ProductModel>[];
    final Set<int> seen = <int>{
      if (!replace) ..._products.map((ProductModel product) => product.id),
    };
    if (!replace) {
      for (final ProductModel product in _searchBuffer) {
        if (seen.add(product.id)) {
          matches.add(product);
        }
      }
    }
    while (matches.length < 20 && more) {
      final ProductPageModel page = (await _productRepo.getProductsAsync(
        query: query,
        offset: nextOffset,
        cancelToken: token,
      )).data;
      if (token.isCancelled) {
        throw const ApiRequestCancelled();
      }
      if (page.skip != nextOffset || page.total < 0 || page.limit < 0) {
        throw const ApiRequestException(ApiFailure.invalidData);
      }
      nextOffset += page.products.length;
      total = page.total;
      more = page.products.isNotEmpty && nextOffset < total;
      for (final ProductModel product in page.products) {
        if ((query.isEmpty ||
                product.title.toLowerCase().contains(query.toLowerCase())) &&
            seen.add(product.id)) {
          matches.add(product);
        }
      }
      if (query.isEmpty) {
        break;
      }
    }
    return _LoadedCataloguePage(
      products: matches.take(20).toList(),
      buffer: matches.skip(20).toList(),
      offset: nextOffset,
      total: total,
      serverHasMore: more,
    );
  }

  void _applyPage(_LoadedCataloguePage page, {required bool replace}) {
    _products = List<ProductModel>.unmodifiable(
      <int, ProductModel>{
        if (!replace)
          for (final ProductModel product in _products) product.id: product,
        for (final ProductModel product in page.products) product.id: product,
      }.values,
    );
    // Consume server records, including duplicates, rather than displayed IDs.
    _offset = page.offset;
    _total = page.total;
    _searchBuffer = List.unmodifiable(page.buffer);
    _serverHasMore = page.serverHasMore;
    _hasMore = _searchBuffer.isNotEmpty || _serverHasMore;
    _hasSnapshot = true;
  }

  Future<void> _saveSnapshotAsync(int generation) async {
    final CatalogueCacheModel snapshot = CatalogueCacheModel(
      query: _query,
      products: _products,
      offset: _offset,
      total: _total,
      savedAt: DateTime.now().toUtc(),
    );
    _pendingCache = snapshot;
    await _persistCacheAsync(snapshot, generation);
  }

  Future<void> _persistCacheAsync(
    CatalogueCacheModel snapshot,
    int generation,
  ) async {
    final int revision = ++_cacheWriteRevision;
    try {
      await _storageRepo.saveCatalogueAsync(snapshot);
      if (_isCurrent(generation) && revision == _cacheWriteRevision) {
        _storageError = null;
      }
    } catch (_) {
      if (_isCurrent(generation) && revision == _cacheWriteRevision) {
        _storageError =
            'Products are available, but the offline copy could not be saved.';
      }
    }
    if (_isCurrent(generation)) {
      _notify();
    }
  }

  Future<void> retryStorageAsync() async {
    if (_isDisposed || _isRetryingStorage) {
      return;
    }
    _isRetryingStorage = true;
    _notify();
    try {
      final CatalogueCacheModel? snapshot = _pendingCache;
      if (snapshot == null) {
        _initialization = null;
        await initializeAsync();
      } else {
        await _persistCacheAsync(snapshot, _generation);
      }
    } finally {
      _isRetryingStorage = false;
      _notify();
    }
  }

  int _startGeneration() {
    _requestToken?.cancel('Catalogue request replaced');
    return ++_generation;
  }

  bool _isCurrent(int generation) => !_isDisposed && generation == _generation;

  String _errorMessage(Object error) => error is BaseApiException
      ? error.message
      : 'Products could not be loaded. Please try again.';

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounce?.cancel();
    _generation++;
    _requestToken?.cancel('Catalogue closed');
    if (_ownsProductRepo) {
      _productRepo.dispose();
    }
    super.dispose();
  }
}

class _LoadedCataloguePage {
  const _LoadedCataloguePage({
    required this.products,
    required this.buffer,
    required this.offset,
    required this.total,
    required this.serverHasMore,
  });

  final List<ProductModel> products;
  final List<ProductModel> buffer;
  final int offset;
  final int total;
  final bool serverHasMore;
}
