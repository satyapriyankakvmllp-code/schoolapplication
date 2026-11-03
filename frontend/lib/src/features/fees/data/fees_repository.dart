import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../utils/dynamic_data_client.dart';
import '../domain/fee_structure.dart';
import '../domain/fees_calculator.dart';
import '../domain/student_fee_invoice.dart';

class FeesValidationException implements Exception {
  final String message;
  const FeesValidationException(this.message);

  @override
  String toString() => message;
}

class FeesReferenceException implements Exception {
  final String message;
  const FeesReferenceException(this.message);

  @override
  String toString() => message;
}

class FeesRepository {
  static const String assetPath = 'assets/data/global_school_database.json';
  static const String storageKey = 'edupulse_saved_global_school_database';

  final DynamicDataClient _dataClient;
  Map<String, dynamic> _globalJson = {};
  List<FeeStructure> _structures = [];
  List<StudentFeeInvoice> _invoices = [];
  Future<void>? _loading;

  FeesRepository({DynamicDataClient? dataClient})
      : _dataClient = dataClient ?? DynamicDataClient.instance;

  Future<void> _ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    final json = await _dataClient.getJsonObject(
      assetPath: assetPath,
      storageKey: storageKey,
    );

    _globalJson = json != null ? Map<String, dynamic>.from(json) : {};

    final rawStructures = (_globalJson['fee_structures'] as List<dynamic>? ?? const []);
    _structures = rawStructures
        .whereType<Map<String, dynamic>>()
        .map(FeeStructure.fromJson)
        .toList();

    final rawInvoices = (_globalJson['student_fee_invoices'] as List<dynamic>? ?? const []);
    _invoices = rawInvoices
        .whereType<Map<String, dynamic>>()
        .map(StudentFeeInvoice.fromJson)
        .toList();
  }

  Future<void> _persist() async {
    _globalJson['fee_structures'] = _structures.map((s) => s.toJson()).toList();
    // Invoices are never changed by fee structure modifications (invoice base_amount is a copy)
    await _dataClient.syncJsonObject(
      assetPath: assetPath,
      storageKey: storageKey,
      data: _globalJson,
    );
  }

  Future<List<FeeStructure>> getFeeStructures() async {
    await _ensureLoaded();
    return List.unmodifiable(_structures);
  }

  Future<FeeStructure?> getFeeStructureById(String id) async {
    await _ensureLoaded();
    return _structures.where((s) => s.id == id).firstOrNull;
  }

  Future<List<StudentFeeInvoice>> getInvoices() async {
    await _ensureLoaded();
    return List.unmodifiable(_invoices);
  }

  Future<String> getCurrentAcademicYear() async {
    await _ensureLoaded();
    final inst = _globalJson['institution'];
    if (inst is Map<String, dynamic> && inst['academic_year'] != null) {
      return inst['academic_year'].toString();
    }
    return '2026-2027';
  }

  Future<List<String>> getAcademicYears() async {
    await _ensureLoaded();
    final years = <String>{};

    final inst = _globalJson['institution'];
    if (inst is Map<String, dynamic> && inst['academic_year'] != null) {
      years.add(inst['academic_year'].toString());
    }

    if (_globalJson['academic_years'] is List) {
      for (final y in _globalJson['academic_years']) {
        years.add(y.toString());
      }
    }

    for (final s in _structures) {
      if (s.academicYear.isNotEmpty) years.add(s.academicYear);
    }

    if (years.isEmpty) {
      years.addAll(['2025-2026', '2026-2027', '2027-2028']);
    }

    final sorted = years.toList()..sort();
    return sorted;
  }

  Future<List<String>> getAvailableClasses() async {
    await _ensureLoaded();
    final classes = <String>{};

    if (_globalJson['academic_classes'] is List) {
      for (final c in _globalJson['academic_classes']) {
        if (c is Map && c['name'] != null) {
          classes.add(c['name'].toString());
        }
      }
    }

    for (final s in _structures) {
      if (s.className.isNotEmpty) classes.add(s.className);
    }

    if (classes.isEmpty) {
      for (var i = 1; i <= 12; i++) {
        classes.add('Class $i');
      }
    }

    final sorted = classes.toList()..sort((a, b) {
      final aNum = int.tryParse(RegExp(r'\d+').firstMatch(a)?.group(0) ?? '');
      final bNum = int.tryParse(RegExp(r'\d+').firstMatch(b)?.group(0) ?? '');
      if (aNum != null && bNum != null) return aNum.compareTo(bNum);
      return a.compareTo(b);
    });
    return sorted;
  }

  /// Saves (create or update) a FeeStructure.
  /// Enforces validation and the invariant:
  /// "No two ACTIVE structures with the same class_name + term_name + academic_year."
  /// "Editing or deactivating a structure must NEVER change existing invoices (invoice base_amount is a copy)."
  Future<FeeStructure> saveFeeStructure(
    FeeStructure structure, {
    bool isNew = false,
  }) async {
    await _ensureLoaded();

    // 1. Validations
    final cleanClass = structure.className.trim();
    final cleanTerm = structure.termName.trim();
    final cleanYear = structure.academicYear.trim();
    final cleanDueDate = structure.dueDate.trim();

    if (cleanClass.isEmpty) {
      throw const FeesValidationException('Class name is required.');
    }
    if (cleanTerm.isEmpty) {
      throw const FeesValidationException('Term name is required.');
    }
    if (cleanYear.isEmpty) {
      throw const FeesValidationException('Academic year is required.');
    }
    if (cleanDueDate.isEmpty) {
      throw const FeesValidationException('Due date is required.');
    }
    if (structure.tuitionFee <= 0) {
      throw const FeesValidationException('Tuition fee must be greater than 0.');
    }
    if (structure.labComputerFee < 0) {
      throw const FeesValidationException('Lab & Computer fee cannot be negative.');
    }
    if (structure.developmentFee < 0) {
      throw const FeesValidationException('Development fee cannot be negative.');
    }
    if (structure.otherFee < 0) {
      throw const FeesValidationException('Other fee cannot be negative.');
    }

    // Auto-calculate total fee
    final total = FeesCalculator.calculateStructureTotalRupees(
      tuition: structure.tuitionFee,
      labComputer: structure.labComputerFee,
      development: structure.developmentFee,
      other: structure.otherFee,
    );

    // 2. Check duplicate-active invariant:
    // "No two ACTIVE structures with the same class_name + term_name + academic_year."
    if (structure.isActive) {
      final duplicate = _structures.where((s) {
        if (!s.isActive) return false;
        if (s.id == structure.id) return false;
        return s.className.trim().toLowerCase() == cleanClass.toLowerCase() &&
            s.termName.trim().toLowerCase() == cleanTerm.toLowerCase() &&
            s.academicYear.trim().toLowerCase() == cleanYear.toLowerCase();
      }).firstOrNull;

      if (duplicate != null) {
        throw FeesValidationException(
          'An active fee structure already exists for $cleanClass, $cleanTerm ($cleanYear). '
          'Deactivate the existing one before activating this structure.',
        );
      }
    }

    final now = DateTime.now().toIso8601String();
    final String targetId = isNew || structure.id.isEmpty
        ? 'fee-str-${cleanClass.replaceAll(RegExp(r'\s+'), '-').toLowerCase()}-${cleanTerm.replaceAll(RegExp(r'\s+'), '-').toLowerCase()}-${DateTime.now().millisecondsSinceEpoch}'
        : structure.id;

    final resolved = structure.copyWith(
      id: targetId,
      className: cleanClass,
      termName: cleanTerm,
      academicYear: cleanYear,
      dueDate: cleanDueDate,
      totalFee: total,
      createdAt: structure.createdAt.isNotEmpty ? structure.createdAt : now,
      updatedAt: now,
    );

    final index = _structures.indexWhere((s) => s.id == targetId);
    if (index >= 0) {
      _structures[index] = resolved;
    } else {
      _structures.insert(0, resolved);
    }

    await _persist();
    return resolved;
  }

  /// Toggles active status of a fee structure.
  /// If activating, ensures no other structure is active for the same class+term+year.
  Future<FeeStructure> toggleActive(String id, bool makeActive) async {
    await _ensureLoaded();

    final index = _structures.indexWhere((s) => s.id == id);
    if (index < 0) {
      throw FeesValidationException('Fee structure not found: $id');
    }

    final target = _structures[index];

    if (makeActive) {
      final duplicate = _structures.where((s) {
        if (!s.isActive) return false;
        if (s.id == target.id) return false;
        return s.className.trim().toLowerCase() == target.className.trim().toLowerCase() &&
            s.termName.trim().toLowerCase() == target.termName.trim().toLowerCase() &&
            s.academicYear.trim().toLowerCase() == target.academicYear.trim().toLowerCase();
      }).firstOrNull;

      if (duplicate != null) {
        throw FeesValidationException(
          'An active fee structure already exists for ${target.className}, ${target.termName} (${target.academicYear}). '
          'Deactivate it first before activating this structure.',
        );
      }
    }

    final updated = target.copyWith(
      isActive: makeActive,
      updatedAt: DateTime.now().toIso8601String(),
    );

    _structures[index] = updated;
    await _persist();
    return updated;
  }

  /// Deletes a fee structure.
  /// Invariant: "Block deleting a structure referenced by any invoice; offer Deactivate instead."
  Future<void> deleteFeeStructure(String id) async {
    await _ensureLoaded();

    final referenced = _invoices.any((inv) => inv.feeStructureId == id);
    if (referenced) {
      throw FeesReferenceException(
        'Cannot delete this fee structure because it is referenced by existing student invoices. '
        'Please deactivate it instead.',
      );
    }

    _structures.removeWhere((s) => s.id == id);
    await _persist();
  }

  /// Test helper to preload in-memory state
  @visibleForTesting
  void preloadData({
    required List<FeeStructure> structures,
    required List<StudentFeeInvoice> invoices,
  }) {
    _structures = List.from(structures);
    _invoices = List.from(invoices);
    _globalJson = {
      'fee_structures': _structures.map((s) => s.toJson()).toList(),
      'student_fee_invoices': _invoices.map((i) => i.toJson()).toList(),
    };
    _loading = Future.value();
  }
}

