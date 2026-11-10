import 'package:flutter/foundation.dart';
import 'package:shoply_flutter/repositories/local_storage_repo.dart';

class RecentSearchesController extends ChangeNotifier {
  RecentSearchesController({LocalStorageRepo? storage})
    : _storage = storage ?? LocalStorageRepo();

  final LocalStorageRepo _storage;
  List<String> _queries = const <String>[];
  Future<void>? _initialization;
  int _revision = 0;
  int _clearRevision = 0;
  bool _isDisposed = false;
  bool _isLoading = true;
  bool _hasLoaded = false;
  String? _error;

  List<String> get queries => _queries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get clearRevision => _clearRevision;

  Future<void> initializeAsync() => _initialization ??= _loadAsync();

  Future<void> _loadAsync() async {
    try {
      final List<String> queries = await _storage.readRecentSearchesAsync();
      if (!_isDisposed) {
        _queries = List.unmodifiable(queries);
        _hasLoaded = true;
        _error = null;
      }
    } catch (_) {
      _error = 'Recent searches could not be loaded.';
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> recordAsync(String query, {required int clearRevision}) async {
    await initializeAsync();
    final String trimmed = query.trim();
    if (_isDisposed ||
        !_hasLoaded ||
        trimmed.isEmpty ||
        clearRevision != _clearRevision) {
      return;
    }
    _queries = List.unmodifiable(
      <String>[
        trimmed,
        ..._queries.where(
          (String old) => old.toLowerCase() != trimmed.toLowerCase(),
        ),
      ].take(5),
    );
    final int revision = ++_revision;
    _notify();
    await _saveAsync(revision);
  }

  Future<void> clearAsync() async {
    // Invalidate a debounced search's history write before waiting for storage.
    _clearRevision++;
    await initializeAsync();
    if (_isDisposed) {
      return;
    }
    _queries = const <String>[];
    _hasLoaded = true;
    final int revision = ++_revision;
    _notify();
    await _saveAsync(revision);
  }

  Future<void> retryAsync() async {
    if (_isDisposed) {
      return;
    }
    if (!_hasLoaded) {
      _initialization = null;
      await initializeAsync();
      return;
    }
    await _saveAsync(++_revision);
  }

  Future<void> _saveAsync(int revision) async {
    final List<String> snapshot = _queries;
    try {
      await _storage.saveRecentSearchesAsync(snapshot);
      if (!_isDisposed && revision == _revision) {
        _error = null;
      }
    } catch (_) {
      if (!_isDisposed && revision == _revision) {
        _error = 'Recent searches could not be saved. Please retry.';
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
