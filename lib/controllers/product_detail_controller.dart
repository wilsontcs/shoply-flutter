import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shoply_flutter/core/api/exceptions/exception.dart';
import 'package:shoply_flutter/core/models/product_model.dart';
import 'package:shoply_flutter/repositories/local_storage_repo.dart';
import 'package:shoply_flutter/repositories/product_repo.dart';

class ProductDetailController extends ChangeNotifier {
  ProductDetailController({required this.productId, ProductModel? product})
    : _product = product?.id == productId ? product : null;

  final int productId;
  final ProductRepo _repo = ProductRepo();
  final LocalStorageRepo _storage = LocalStorageRepo();
  ProductModel? _product;
  CancelToken? _token;
  int _generation = 0;
  bool _isDisposed = false;
  bool _isLoading = true;
  String? _error;

  ProductModel? get product => _product;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAsync() async {
    if (_isDisposed) {
      return;
    }
    final int generation = ++_generation;
    _token?.cancel('Product request replaced');
    final CancelToken token = CancelToken();
    _token = token;
    _isLoading = true;
    _error = null;
    _notify();
    if (_product == null) {
      try {
        final List<ProductModel> saved = <ProductModel>[
          ...?(await _storage.readCatalogueAsync())?.products,
          ...await _storage.readFavouritesAsync(),
        ];
        if (_isCurrent(generation)) {
          for (final ProductModel product in saved) {
            if (product.id == productId) {
              _product = product;
              break;
            }
          }
          _notify();
        }
      } catch (_) {
        // The network request can still succeed when local storage is unavailable.
      }
    }
    if (!_isCurrent(generation)) {
      return;
    }
    try {
      final ProductModel product = (await _repo.getProductAsync(
        productId,
        cancelToken: token,
      )).data;
      if (_isCurrent(generation)) {
        _product = product;
      }
    } on ApiRequestCancelled {
      // A newer request or a closed screen owns the lifecycle.
    } catch (error) {
      if (_isCurrent(generation)) {
        _error = error is BaseApiException
            ? error.message
            : 'Product details could not be loaded.';
      }
    } finally {
      if (_isCurrent(generation)) {
        _isLoading = false;
        _token = null;
        _notify();
      }
    }
  }

  bool _isCurrent(int generation) => !_isDisposed && generation == _generation;

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _generation++;
    _token?.cancel('Product screen closed');
    _repo.dispose();
    super.dispose();
  }
}
