import 'package:flutter/foundation.dart';
import 'package:shoply_flutter/core/models/product_model.dart';
import 'package:shoply_flutter/repositories/local_storage_repo.dart';

class FavouritesController extends ChangeNotifier {
  FavouritesController({LocalStorageRepo? storage})
    : _storage = storage ?? LocalStorageRepo();

  final LocalStorageRepo _storage;
  List<ProductModel> _products = const <ProductModel>[];
  bool _isLoading = false;
  bool _isReady = false;
  bool _isDisposed = false;
  int _revision = 0;
  String? _error;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  bool get isReady => _isReady;
  String? get error => _error;
  bool contains(int id) =>
      _products.any((ProductModel product) => product.id == id);

  Future<void> loadAsync() async {
    if (_isLoading || _isDisposed || _isReady) {
      return;
    }
    _isLoading = true;
    _error = null;
    _notify();
    try {
      final List<ProductModel> products = await _storage.readFavouritesAsync();
      if (!_isDisposed) {
        _products = List.unmodifiable(products);
        _isReady = true;
      }
    } catch (_) {
      _error = 'Your wishlist could not be loaded. Please retry.';
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> toggleAsync(ProductModel product) async {
    if (!_isReady || _isDisposed) {
      return;
    }
    _products = List.unmodifiable(
      contains(product.id)
          ? _products.where((ProductModel item) => item.id != product.id)
          : <ProductModel>[product, ..._products],
    );
    final int revision = ++_revision;
    final List<ProductModel> snapshot = _products;
    _notify();
    await _saveAsync(snapshot, revision);
  }

  Future<void> retryAsync() async {
    if (_isDisposed) {
      return;
    }
    if (!_isReady) {
      await loadAsync();
    } else {
      await _saveAsync(_products, ++_revision);
    }
  }

  Future<void> _saveAsync(List<ProductModel> snapshot, int revision) async {
    try {
      await _storage.saveFavouritesAsync(snapshot);
      if (!_isDisposed && revision == _revision) {
        _error = null;
      }
    } catch (_) {
      if (!_isDisposed && revision == _revision) {
        _error =
            'Wishlist changes could not be saved. Tap Retry to save them again.';
      }
    }
    _notify();
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
