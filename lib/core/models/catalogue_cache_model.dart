import 'package:json_annotation/json_annotation.dart';

import 'package:shoply_flutter/core/models/product_model.dart';

part 'catalogue_cache_model.g.dart';

@JsonSerializable(
  fieldRename: FieldRename.snake,
  explicitToJson: true,
  dateTimeUtc: true,
)
class CatalogueCacheModel {
  CatalogueCacheModel({
    required this.query,
    required List<ProductModel> products,
    required this.offset,
    required this.total,
    required this.savedAt,
    this.version = CatalogueCacheModel.schemaVersion,
  }) : products = List.unmodifiable(
         <int, ProductModel>{
           for (final ProductModel product in products) product.id: product,
         }.values,
       );

  factory CatalogueCacheModel.fromJson(Map<String, dynamic> parsedJson) =>
      _$CatalogueCacheModelFromJson(parsedJson);

  static const int schemaVersion = 1;
  final int version;
  final String query;
  final List<ProductModel> products;
  final int offset;
  final int total;
  @JsonKey(name: 'savedAt')
  final DateTime savedAt;

  Map<String, dynamic> toJson() => _$CatalogueCacheModelToJson(this);
}
