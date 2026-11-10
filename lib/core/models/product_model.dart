import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ProductModel {
  ProductModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.price,
    this.rating = 0,
    this.stock = 0,
    this.thumbnail = '',
    List<String>? images,
  }) : images = List.unmodifiable(images ?? <String>[]);

  factory ProductModel.fromJson(Map<String, dynamic> parsedJson) =>
      _$ProductModelFromJson(parsedJson);

  final int id;
  final String title;
  final String description;
  final double price;
  final double rating;
  final int stock;
  final String thumbnail;
  final List<String> images;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get coverImage => thumbnail.isNotEmpty
      ? thumbnail
      : images.firstWhere((String image) => image.isNotEmpty, orElse: () => '');

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}
