import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'asset_loader.dart';

/// Clean, robust dynamic data layer client for the School Management System.
///
/// Implements the agreed **Hybrid Data Persistence Architecture**:
/// 1. Tries to sync mutations directly to physical `.json` files on disk via
///    the lightweight local sync server (`http://127.0.0.1:8080/api/data`).
/// 2. Seamlessly falls back to browser `SharedPreferences` whenever the local server
///    is not running, guaranteeing zero runtime crashes and persistence across reloads.
/// 3. In-memory caching ensures instantaneous, flicker-free UI rendering.
class DynamicDataClient {
  static const String serverBaseUrl = 'http://127.0.0.1:8080';
  static const Duration serverTimeout = Duration(milliseconds: 350);

  final AssetLoader _assetLoader;
  final Map<String, dynamic> _memoryCache = {};
  bool? _isServerAvailable;

  DynamicDataClient({AssetLoader? assetLoader})
      : _assetLoader = assetLoader ?? const AssetLoader();

  /// Singleton instance for shared state across repositories
  static final DynamicDataClient instance = DynamicDataClient();

  Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 400),
      );
    } catch (_) {
      return null;
    }
  }

  /// Probes whether the local JSON disk sync server is alive.
  Future<bool> checkServerHealth() async {
    if (_isServerAvailable != null) return _isServerAvailable!;
    try {
      final response = await http
          .get(Uri.parse('$serverBaseUrl/api/health'))
          .timeout(serverTimeout);
      _isServerAvailable = response.statusCode == 200;
    } catch (_) {
      _isServerAvailable = false;
    }
    return _isServerAvailable!;
  }

  /// Loads full list collection from either:
  /// - In-memory cache
  /// - Local sync server (if running)
  /// - Asset bundle + SharedPreferences overlay (if standalone)
  Future<List<Map<String, dynamic>>> getAll({
    required String assetPath,
    required String storageKey,
    String? collectionKey,
  }) async {
    final cacheKey = '$assetPath:$collectionKey';
    if (_memoryCache.containsKey(cacheKey)) {
      final cached = _memoryCache[cacheKey];
      if (cached is List<Map<String, dynamic>>) {
        return List<Map<String, dynamic>>.from(cached);
      }
    }

    dynamic rawData;

    // 1. Try local server first (real disk data)
    final isServerUp = await checkServerHealth();
    if (isServerUp) {
      try {
        final res = await http
            .get(Uri.parse('$serverBaseUrl/api/data?file=$assetPath'))
            .timeout(serverTimeout);
        if (res.statusCode == 200) {
          rawData = jsonDecode(res.body);
        }
      } catch (_) {
        // Fall back to asset loader below
      }
    }

    // 2. If server was not reachable or failed, load from Flutter asset bundle
    if (rawData == null) {
      try {
        rawData = await _assetLoader.loadJson(assetPath, delayMs: 0);
      } catch (_) {
        rawData = null;
      }
    }

    // 3. Extract target collection if nested under a key
    List<Map<String, dynamic>> list = [];
    if (rawData is List) {
      list = rawData.whereType<Map<String, dynamic>>().map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (rawData is Map<String, dynamic>) {
      if (collectionKey != null && rawData[collectionKey] is List) {
        list = (rawData[collectionKey] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        // Find first list in the object if not specified
        for (final val in rawData.values) {
          if (val is List) {
            list = val
                .whereType<Map<String, dynamic>>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            break;
          }
        }
      }
    }

    // 4. Overlay browser SharedPreferences (ensures offline persistence)
    try {
      final prefs = await _getPrefs();
      final savedStr = prefs?.getString(storageKey);
      if (savedStr != null && savedStr.isNotEmpty) {
        final dynamic decoded = jsonDecode(savedStr);
        if (decoded is List) {
          final savedList = decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (savedList.isNotEmpty) {
            // Merge or replace with savedList
            list = savedList;
          }
        }
      }
    } catch (e) {
      debugPrint('[DynamicDataClient] SharedPreferences read fallback note: $e');
    }

    _memoryCache[cacheKey] = list;
    return List<Map<String, dynamic>>.from(list);
  }

  /// Finds single item by its ID.
  Future<Map<String, dynamic>?> getById({
    required String assetPath,
    required String storageKey,
    required String id,
    String? collectionKey,
    String idKey = 'id',
  }) async {
    final list = await getAll(
      assetPath: assetPath,
      storageKey: storageKey,
      collectionKey: collectionKey,
    );
    return list.where((item) => item[idKey]?.toString() == id).firstOrNull;
  }

  /// Creates a new record, adds it to the collection, and syncs via hybrid persistence.
  Future<Map<String, dynamic>> create({
    required String assetPath,
    required String storageKey,
    required Map<String, dynamic> item,
    String? collectionKey,
    String idKey = 'id',
  }) async {
    final list = await getAll(
      assetPath: assetPath,
      storageKey: storageKey,
      collectionKey: collectionKey,
    );

    // Prevent duplicates
    final existingIndex = list.indexWhere((e) => e[idKey]?.toString() == item[idKey]?.toString());
    if (existingIndex >= 0) {
      list[existingIndex] = Map<String, dynamic>.from(item);
    } else {
      list.insert(0, Map<String, dynamic>.from(item));
    }

    await _syncBack(
      assetPath: assetPath,
      storageKey: storageKey,
      collectionKey: collectionKey,
      updatedList: list,
    );

    return item;
  }

  /// Updates an existing record by its ID.
  Future<Map<String, dynamic>> update({
    required String assetPath,
    required String storageKey,
    required String id,
    required Map<String, dynamic> item,
    String? collectionKey,
    String idKey = 'id',
  }) async {
    final list = await getAll(
      assetPath: assetPath,
      storageKey: storageKey,
      collectionKey: collectionKey,
    );

    final index = list.indexWhere((e) => e[idKey]?.toString() == id);
    if (index >= 0) {
      list[index] = Map<String, dynamic>.from(item);
    } else {
      list.add(Map<String, dynamic>.from(item));
    }

    await _syncBack(
      assetPath: assetPath,
      storageKey: storageKey,
      collectionKey: collectionKey,
      updatedList: list,
    );

    return item;
  }

  /// Deletes a record from the collection.
  Future<bool> delete({
    required String assetPath,
    required String storageKey,
    required String id,
    String? collectionKey,
    String idKey = 'id',
  }) async {
    final list = await getAll(
      assetPath: assetPath,
      storageKey: storageKey,
      collectionKey: collectionKey,
    );

    final beforeLen = list.length;
    list.removeWhere((item) => item[idKey]?.toString() == id);
    final changed = list.length != beforeLen;

    if (changed) {
      await _syncBack(
        assetPath: assetPath,
        storageKey: storageKey,
        collectionKey: collectionKey,
        updatedList: list,
      );
    }

    return changed;
  }

  /// Synchronizes an entire collection to both disk JSON (if server is up)
  /// and SharedPreferences.
  Future<void> syncAll({
    required String assetPath,
    required String storageKey,
    String? collectionKey,
    required List<Map<String, dynamic>> items,
  }) async {
    await _syncBack(
      assetPath: assetPath,
      storageKey: storageKey,
      collectionKey: collectionKey,
      updatedList: items,
    );
  }

  /// Loads a full JSON object (map) from cache, local server, asset bundle,
  /// with SharedPreferences overlay for persistence.
  Future<Map<String, dynamic>?> getJsonObject({
    required String assetPath,
    required String storageKey,
  }) async {
    final cacheKey = '$assetPath:__object__';
    if (_memoryCache.containsKey(cacheKey)) {
      final cached = _memoryCache[cacheKey];
      if (cached is Map<String, dynamic>) {
        return Map<String, dynamic>.from(cached);
      }
    }

    Map<String, dynamic>? rawData;

    // 1. Try local server first (real disk data)
    final isServerUp = await checkServerHealth();
    if (isServerUp) {
      try {
        final res = await http
            .get(Uri.parse('$serverBaseUrl/api/data?file=$assetPath'))
            .timeout(serverTimeout);
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) rawData = decoded;
        }
      } catch (_) {}
    }

    // 2. Load from Flutter asset bundle if server didn't provide
    if (rawData == null) {
      try {
        final loaded = await _assetLoader.loadJsonObject(assetPath, delayMs: 0);
        rawData = loaded;
      } catch (_) {}
    }

    // 3. Overlay browser SharedPreferences (ensures offline/web persistence)
    try {
      final prefs = await _getPrefs();
      final savedStr = prefs?.getString(storageKey);
      if (savedStr != null && savedStr.isNotEmpty) {
        final dynamic decoded = jsonDecode(savedStr);
        if (decoded is Map<String, dynamic>) {
          rawData = decoded;
        }
      }
    } catch (_) {}

    if (rawData != null) {
      _memoryCache[cacheKey] = rawData;
      return Map<String, dynamic>.from(rawData);
    }
    return null;
  }

  /// Synchronizes a full JSON object (map) to both disk JSON (if server is up)
  /// and SharedPreferences.
  Future<void> syncJsonObject({
    required String assetPath,
    required String storageKey,
    required Map<String, dynamic> data,
  }) async {
    final cacheKey = '$assetPath:__object__';
    _memoryCache[cacheKey] = data;

    // 1. Save to SharedPreferences immediately (guarantees persistence across reloads on web)
    try {
      final prefs = await _getPrefs();
      await prefs?.setString(storageKey, jsonEncode(data));
    } catch (e) {
      debugPrint('[DynamicDataClient] SharedPreferences write warning: $e');
    }

    // 2. Sync to physical disk file via local server if reachable
    final isServerUp = await checkServerHealth();
    if (isServerUp) {
      try {
        await http.post(
          Uri.parse('$serverBaseUrl/api/data?file=$assetPath'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        ).timeout(serverTimeout);
      } catch (e) {
        debugPrint('[DynamicDataClient] Disk sync to server skipped: $e');
      }
    }
  }

  /// Writes back updated data both to the local sync server (disk JSON)
  /// and to browser SharedPreferences (offline safety).
  Future<void> _syncBack({
    required String assetPath,
    required String storageKey,
    required String? collectionKey,
    required List<Map<String, dynamic>> updatedList,
  }) async {
    final cacheKey = '$assetPath:$collectionKey';
    _memoryCache[cacheKey] = updatedList;

    // 1. Save to SharedPreferences immediately (guarantees persistence in browser)
    try {
      final prefs = await _getPrefs();
      await prefs?.setString(storageKey, jsonEncode(updatedList));
    } catch (e) {
      debugPrint('[DynamicDataClient] SharedPreferences write warning: $e');
    }

    // 2. Sync to physical disk file via local server if reachable
    final isServerUp = await checkServerHealth();
    if (isServerUp) {
      try {
        dynamic payload;
        if (collectionKey != null) {
          // If the file is an object with multiple collections, fetch current object
          final res = await http.get(Uri.parse('$serverBaseUrl/api/data?file=$assetPath')).timeout(serverTimeout);
          Map<String, dynamic> fullObject = {};
          if (res.statusCode == 200) {
            fullObject = jsonDecode(res.body) as Map<String, dynamic>;
          }
          fullObject[collectionKey] = updatedList;
          payload = fullObject;
        } else {
          payload = updatedList;
        }

        await http.post(
          Uri.parse('$serverBaseUrl/api/data?file=$assetPath'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(serverTimeout);
      } catch (e) {
        debugPrint('[DynamicDataClient] Disk sync to server skipped: $e');
      }
    }
  }

  /// Clears in-memory cache for a given collection or all caches
  void clearCache([String? assetPath, String? collectionKey]) {
    if (assetPath != null) {
      _memoryCache.remove('$assetPath:$collectionKey');
    } else {
      _memoryCache.clear();
    }
  }
}
