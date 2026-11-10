import 'package:dio/dio.dart';

import '../core/api/core_api_const.dart';
import '../core/api/core_api_error_resolver.dart';
import '../core/api/core_api_response.dart';
import '../core/models/product_model.dart';
import '../core/models/product_page_model.dart';
import 'base_repo.dart';

class ProductRepo extends BaseRepo {
  ProductRepo({super.api});

  Future<CoreApiResponse<ProductPageModel>> getProductsAsync({
    String query = '',
    int offset = 0,
    CancelToken? cancelToken,
  }) async {
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Must be non-negative.');
    }
    final String normalizedQuery = query.trim();
    try {
      final CoreApiResponse<Map<String, Object?>> response = await api
          .requestAsync(
            url: normalizedQuery.isEmpty
                ? CoreApiConst.products
                : CoreApiConst.search,
            queryParameters: <String, Object?>{
              'limit': CoreApiConst.pageSize,
              'skip': offset,
              if (normalizedQuery.isNotEmpty) 'q': normalizedQuery,
            },
            cancelToken: cancelToken,
          );
      return CoreApiResponse<ProductPageModel>(
        data: ProductPageModel.fromJson(response.data),
        status: response.status,
        message: response.message,
      );
    } catch (error) {
      throw CoreApiErrorResolver.resolveUnexpectedException(error);
    }
  }

  Future<CoreApiResponse<ProductModel>> getProductAsync(
    int id, {
    CancelToken? cancelToken,
  }) async {
    if (id <= 0) {
      throw ArgumentError.value(id, 'id', 'Must be positive.');
    }
    try {
      final CoreApiResponse<Map<String, Object?>> response = await api
          .requestAsync(
            url: CoreApiConst.product(id),
            cancelToken: cancelToken,
          );
      final ProductModel product = ProductModel.fromJson(response.data);
      if (product.id != id) {
        throw const FormatException('Mismatched product ID.');
      }
      return CoreApiResponse<ProductModel>(
        data: product,
        status: response.status,
        message: response.message,
      );
    } catch (error) {
      throw CoreApiErrorResolver.resolveUnexpectedException(error);
    }
  }
}
