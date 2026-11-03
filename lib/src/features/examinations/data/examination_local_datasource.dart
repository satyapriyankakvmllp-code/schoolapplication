import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExaminationLocalDataSource {
  static const List<String> _seedExaminationAssets = [
    'assets/data/examination/examination.json',
    'assets/data/examinations/examinations.json',
    'assets/data/examination.json',
  ];

  static const List<String> _seedGlobalAssets = [
    'assets/data/global_school_database.json',
    'assets/data/global.json',
  ];

  static const String _storageKeyExamination = 'examination_local_json_data';
  static const String _storageKeyGlobal = 'global_school_database_local_json_data';

  static const String _examFileName = 'examination.json';
  static const String _globalFileName = 'global_school_database.json';

  // In-memory caches for fast, synchronous reads
  String? _cachedExamJson;
  String? _cachedGlobalJson;

  Future<String> _loadAssetWithFallback(List<String> paths) async {
    for (final p in paths) {
      try {
        final content = await rootBundle.loadString(p);
        if (content.trim().isNotEmpty) return content;
      } catch (_) {}
    }
    throw StateError('Unable to load any seed asset from: $paths');
  }

  Future<File?> _getLocalFile(String filename) async {
    if (kIsWeb) return null;
    try {
      final directory = await getApplicationDocumentsDirectory();
      return File('${directory.path}/$filename');
    } catch (e) {
      debugPrint('[ExaminationLocalDataSource] File access warning: $e');
      return null;
    }
  }

  /// Read Examination JSON (seeded from asset on first run)
  Future<String> readExaminationJson() async {
    if (_cachedExamJson != null) {
      return _cachedExamJson!;
    }

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKeyExamination);
      if (stored != null && stored.trim().isNotEmpty) {
        _cachedExamJson = stored;
        return stored;
      }
      // Seed from asset
      final seed = await _loadAssetWithFallback(_seedExaminationAssets);
      await prefs.setString(_storageKeyExamination, seed);
      _cachedExamJson = seed;
      return seed;
    }

    // Native desktop / mobile
    final file = await _getLocalFile(_examFileName);
    if (file != null && await file.exists()) {
      final content = await file.readAsString();
      if (content.trim().isNotEmpty) {
        _cachedExamJson = content;
        return content;
      }
    }

    // Seed file if missing or empty
    final seed = await _loadAssetWithFallback(_seedExaminationAssets);
    if (file != null) {
      try {
        await file.writeAsString(seed, flush: true);
      } catch (e) {
        debugPrint('[ExaminationLocalDataSource] Failed to write seed file: $e');
      }
    }
    _cachedExamJson = seed;
    return seed;
  }

  /// Write Examination JSON to local persisted storage
  Future<void> writeExaminationJson(String jsonString) async {
    _cachedExamJson = jsonString;

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKeyExamination, jsonString);
      return;
    }

    final file = await _getLocalFile(_examFileName);
    if (file != null) {
      await file.writeAsString(jsonString, flush: true);
    } else {
      // Fallback to SharedPreferences if file access failed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKeyExamination, jsonString);
    }
  }

  /// Read Global School Database JSON (shared school information and existing master data)
  Future<String> readGlobalSchoolDatabaseJson() => readGlobalJson();

  /// Read Global JSON
  Future<String> readGlobalJson() async {
    if (_cachedGlobalJson != null) {
      return _cachedGlobalJson!;
    }

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKeyGlobal);
      if (stored != null && stored.trim().isNotEmpty) {
        _cachedGlobalJson = stored;
        return stored;
      }
      final seed = await _loadAssetWithFallback(_seedGlobalAssets);
      await prefs.setString(_storageKeyGlobal, seed);
      _cachedGlobalJson = seed;
      return seed;
    }

    final file = await _getLocalFile(_globalFileName);
    if (file != null && await file.exists()) {
      final content = await file.readAsString();
      if (content.trim().isNotEmpty) {
        _cachedGlobalJson = content;
        return content;
      }
    }

    final seed = await _loadAssetWithFallback(_seedGlobalAssets);
    if (file != null) {
      try {
        await file.writeAsString(seed, flush: true);
      } catch (e) {
        debugPrint('[ExaminationLocalDataSource] Failed to write global seed file: $e');
      }
    }
    _cachedGlobalJson = seed;
    return seed;
  }

  /// Write Global JSON (e.g. updating current_user_id)
  Future<void> writeGlobalJson(String jsonString) async {
    _cachedGlobalJson = jsonString;

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKeyGlobal, jsonString);
      return;
    }

    final file = await _getLocalFile(_globalFileName);
    if (file != null) {
      await file.writeAsString(jsonString, flush: true);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKeyGlobal, jsonString);
    }
  }

  /// Reset demo data: re-copies the bundled seed asset to local storage
  Future<void> resetDemoData() async {
    final seedExam = await _loadAssetWithFallback(_seedExaminationAssets);
    await writeExaminationJson(seedExam);

    final seedGlobal = await _loadAssetWithFallback(_seedGlobalAssets);
    await writeGlobalJson(seedGlobal);
  }
}
