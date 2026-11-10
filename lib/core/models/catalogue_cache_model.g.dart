// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalogue_cache_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogueCacheModel _$CatalogueCacheModelFromJson(Map<String, dynamic> json) =>
    CatalogueCacheModel(
      query: json['query'] as String,
      products: (json['products'] as List<dynamic>)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      offset: (json['offset'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      savedAt: DateTime.parse(json['savedAt'] as String),
      version:
          (json['version'] as num?)?.toInt() ??
          CatalogueCacheModel.schemaVersion,
    );

Map<String, dynamic> _$CatalogueCacheModelToJson(
  CatalogueCacheModel instance,
) => <String, dynamic>{
  'version': instance.version,
  'query': instance.query,
  'products': instance.products.map((e) => e.toJson()).toList(),
  'offset': instance.offset,
  'total': instance.total,
  'savedAt': instance.savedAt.toUtc().toIso8601String(),
};
