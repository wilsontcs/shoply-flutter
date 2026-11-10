import 'package:flutter/foundation.dart';

import '../core/models/product_model.dart';
import '../repositories/local_storage_repo.dart';

/// App-scoped saved snapshots. Interactive favourite actions are added in Part 4.
class FavouritesController extends ChangeNotifier {
  FavouritesController({LocalStorageRepo? storage})
    : _storage = storage ?? LocalStorageRepo();

  final LocalStorageRepo _storage;
  List<ProductModel> _products = <ProductModel>[];
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _error;

  List<ProductModel> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool contains(int id) =>
      _products.any((ProductModel product) => product.id == id);

  Future<void> loadAsync() async {
    if (_isLoading || _isDisposed) {
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _products = await _storage.readFavouritesAsync();
    } on LocalStorageException catch (error) {
      _error = error.message;
    } finally {
      _isLoading = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
