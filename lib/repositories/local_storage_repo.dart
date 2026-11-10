import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:shoply_flutter/core/models/catalogue_cache_model.dart';
import 'package:shoply_flutter/core/models/json_parsing.dart';
import 'package:shoply_flutter/core/models/product_model.dart';

class LocalStorageException implements Exception {
  const LocalStorageException();

  String get message =>
      'Your changes could not be saved on this device. Please try again.';
}

class LocalStorageRepo {
  LocalStorageRepo({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _catalogueKey = 'shoply.catalogue.v1';
  static const String _favouritesKey = 'shoply.favourites.v1';
  static const String _historyKey = 'shoply.recent_searches.v1';
  final SharedPreferencesAsync _preferences;
  Future<void> _writeTail = Future<void>.value();

  Future<T?> _readAsync<T>(
    String key,
    T Function(Map<String, Object?>) decode,
  ) async {
    final String? raw;
    try {
      raw = await _preferences.getString(key);
    } on TypeError {
      return null;
    } catch (_) {
      throw const LocalStorageException();
    }
    if (raw == null) {
      return null;
    }
    try {
      return decode(jsonObject(jsonDecode(raw)));
    } on FormatException {
      return null;
    } on CheckedFromJsonException {
      return null;
    } on TypeError {
      return null;
    }
  }

  // Capture JSON before queueing so a later mutation cannot change an older write.
  Future<void> _writeAsync(String key, Map<String, Object?> data) {
    final String encoded = jsonEncode(data);
    final Future<void> operation = _persistAfterAsync(_writeTail, key, encoded);
    _writeTail = _settleWriteAsync(operation);
    return operation;
  }

  Future<void> _persistAfterAsync(
    Future<void> previous,
    String key,
    String encoded,
  ) async {
    await previous;
    try {
      await _preferences.setString(key, encoded);
    } catch (_) {
      throw const LocalStorageException();
    }
  }

  Future<void> _settleWriteAsync(Future<void> operation) async {
    try {
      await operation;
    } catch (_) {
      // The caller still receives the error; later writes can continue.
    }
  }

  Future<CatalogueCacheModel?> readCatalogueAsync() =>
      _readAsync(_catalogueKey, (Map<String, Object?> json) {
        if (json['version'] != CatalogueCacheModel.schemaVersion) {
          throw const FormatException('Unsupported catalogue cache version.');
        }
        final int offset = nonNegativeInt(json['offset'], 'offset');
        final int total = nonNegativeInt(json['total'], 'total');
        if (offset > total ||
            jsonList(json['products'], 'products').length > offset) {
          throw const FormatException('Invalid cached pagination.');
        }
        return CatalogueCacheModel.fromJson(json);
      });

  Future<void> saveCatalogueAsync(CatalogueCacheModel cache) =>
      _writeAsync(_catalogueKey, cache.toJson());

  Future<List<ProductModel>> readFavouritesAsync() async =>
      await _readAsync(_favouritesKey, (Map<String, Object?> json) {
        _checkVersion(json);
        final Iterable<ProductModel> products = jsonList(
          json['products'],
          'products',
        ).map((Object? item) => ProductModel.fromJson(jsonObject(item)));
        return <int, ProductModel>{
          for (final ProductModel product in products) product.id: product,
        }.values.toList(growable: false);
      }) ??
      <ProductModel>[];

  Future<void> saveFavouritesAsync(Iterable<ProductModel> products) =>
      _writeAsync(_favouritesKey, <String, Object?>{
        'version': 1,
        'products': products
            .map((ProductModel product) => product.toJson())
            .toList(),
      });

  Future<List<String>> readRecentSearchesAsync() async =>
      await _readAsync(_historyKey, (Map<String, Object?> json) {
        _checkVersion(json);
        return _normalizeHistory(
          jsonList(
            json['queries'],
            'queries',
          ).map((Object? item) => jsonString(item, 'query')),
        );
      }) ??
      <String>[];

  Future<void> saveRecentSearchesAsync(Iterable<String> queries) => _writeAsync(
    _historyKey,
    <String, Object?>{'version': 1, 'queries': _normalizeHistory(queries)},
  );

  Future<void> clearRecentSearchesAsync() =>
      saveRecentSearchesAsync(<String>[]);

  static void _checkVersion(Map<String, Object?> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported local data version.');
    }
  }

  static List<String> _normalizeHistory(Iterable<String> queries) {
    final Set<String> seen = <String>{};
    return queries
        .map((String query) => query.trim())
        .where(
          (String query) => query.isNotEmpty && seen.add(query.toLowerCase()),
        )
        .take(5)
        .toList(growable: false);
  }
}
