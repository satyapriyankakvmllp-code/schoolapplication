import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../constants/app_constants.dart';

/// Service responsible for loading, parsing local mock JSON assets,
/// and simulating network latency for backend readiness.
class AssetLoader {
  const AssetLoader();

  /// Loads and decodes a JSON asset from [assetPath].
  /// Optionally simulates realistic network delay via [delayMs].
  Future<dynamic> loadJson(
    String assetPath, {
    int delayMs = AppConstants.defaultMockDelayMs,
  }) async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().toLowerCase().contains('test');
    if (delayMs > 0 && !isTest) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }

    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      return jsonDecode(jsonString);
    } catch (e) {
      throw AssetLoaderException('Failed to load JSON asset from: $assetPath. Error: $e');
    }
  }

  /// Convenience method for loading a `Map<String, dynamic>` from JSON asset.
  Future<Map<String, dynamic>> loadJsonObject(
    String assetPath, {
    int delayMs = AppConstants.defaultMockDelayMs,
  }) async {
    final dynamic data = await loadJson(assetPath, delayMs: delayMs);
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw AssetLoaderException('Expected JSON Object at $assetPath, but found ${data.runtimeType}');
  }

  /// Convenience method for loading a `List<dynamic>` from JSON asset.
  Future<List<dynamic>> loadJsonList(
    String assetPath, {
    int delayMs = AppConstants.defaultMockDelayMs,
  }) async {
    final dynamic data = await loadJson(assetPath, delayMs: delayMs);
    if (data is List<dynamic>) {
      return data;
    }
    throw AssetLoaderException('Expected JSON List at $assetPath, but found ${data.runtimeType}');
  }
}

class AssetLoaderException implements Exception {
  final String message;
  const AssetLoaderException(this.message);

  @override
  String toString() => 'AssetLoaderException: $message';
}
