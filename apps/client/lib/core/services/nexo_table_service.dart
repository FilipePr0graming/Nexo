import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../storage/local_json_store.dart';

typedef NexoFromJson<T> = T Function(Map<String, dynamic> json);
typedef NexoToJson<T> = Map<String, dynamic> Function(T item);
typedef NexoIdOf<T> = String Function(T item);
typedef NexoSort<T> = int Function(T left, T right);

class NexoTableService<T> extends ChangeNotifier {
  NexoTableService({
    required SupabaseClient? client,
    required LocalJsonStore localStore,
    required this.table,
    required this.storageKey,
    required this.fromJson,
    required this.toJson,
    required this.idOf,
    this.orderBy = 'updated_at',
    this.ascending = false,
    this.sort,
    this.syncErrorMessage = 'Nao foi possivel sincronizar agora.',
  })  : _client = client,
        _localStore = localStore;

  final SupabaseClient? _client;
  final LocalJsonStore _localStore;
  final String table;
  final String storageKey;
  final NexoFromJson<T> fromJson;
  final NexoToJson<T> toJson;
  final NexoIdOf<T> idOf;
  final String orderBy;
  final bool ascending;
  final NexoSort<T>? sort;
  final String syncErrorMessage;

  List<T> _items = const [];
  bool _initialized = false;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;

  List<T> get items => _items;
  bool get isRemoteEnabled => _client != null;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _isLoading = true;
    notifyListeners();

    _items = await _loadLocal();
    _sortItems();
    _isLoading = false;
    notifyListeners();

    await refresh();
  }

  Future<void> refresh() async {
    if (_isSyncing || _client == null) {
      return;
    }

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _client
          .from(table)
          .select()
          .order(orderBy, ascending: ascending);
      _items = response
          .cast<Map<String, dynamic>>()
          .map(fromJson)
          .toList(growable: false);
      _sortItems();
      await _cacheAll();
    } catch (_) {
      _errorMessage = syncErrorMessage;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<T> upsertItem(T item) async {
    _replace(item);
    await _cacheAll();
    notifyListeners();

    if (_client == null) {
      return item;
    }

    try {
      final response = await _client
          .from(table)
          .upsert(toJson(item), onConflict: 'id')
          .select()
          .single();
      final saved = fromJson(response);
      _replace(saved);
      await _cacheAll();
      _errorMessage = null;
      return saved;
    } catch (_) {
      _errorMessage = syncErrorMessage;
      return item;
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteById(String id) async {
    _items = _items.where((item) => idOf(item) != id).toList(growable: false);
    await _cacheAll();
    notifyListeners();

    if (_client == null) {
      return;
    }

    try {
      await _client.from(table).delete().eq('id', id);
      _errorMessage = null;
    } catch (_) {
      _errorMessage = syncErrorMessage;
    } finally {
      notifyListeners();
    }
  }

  Future<List<T>> _loadLocal() async {
    final rawItems = await _localStore.readList(storageKey);
    return rawItems.map(fromJson).toList(growable: false);
  }

  Future<void> _cacheAll() {
    return _localStore.writeList(
      storageKey,
      _items.map(toJson).toList(growable: false),
    );
  }

  void _replace(T updated) {
    final id = idOf(updated);
    final next = <T>[];
    var found = false;
    for (final item in _items) {
      if (idOf(item) == id) {
        next.add(updated);
        found = true;
      } else {
        next.add(item);
      }
    }

    if (!found) {
      next.insert(0, updated);
    }

    _items = next;
    _sortItems();
  }

  void _sortItems() {
    final sorter = sort;
    if (sorter == null) {
      return;
    }
    _items = [..._items]..sort(sorter);
  }
}
