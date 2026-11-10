import 'package:json_annotation/json_annotation.dart';

import 'product_model.dart';

part 'product_page_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ProductPageModel {
  ProductPageModel({
    required List<ProductModel> products,
    required this.total,
    required this.skip,
    required this.limit,
  }) : products = List.unmodifiable(products);

  factory ProductPageModel.fromJson(Map<String, dynamic> parsedJson) =>
      _$ProductPageModelFromJson(parsedJson);

  final List<ProductModel> products;
  final int total;
  final int skip;
  final int limit;

  @JsonKey(includeFromJson: false, includeToJson: false)
  int get nextOffset => skip + products.length;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get hasMore => products.isNotEmpty && nextOffset < total;

  Map<String, dynamic> toJson() => _$ProductPageModelToJson(this);
}
