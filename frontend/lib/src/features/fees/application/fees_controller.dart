import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/fees_repository.dart';
import '../domain/fee_structure.dart';

final feesRepositoryProvider = Provider<FeesRepository>((ref) {
  return FeesRepository();
});

class FeeStructureFilterState {
  final String searchQuery;
  final String academicYear;
  final String className;
  final String termName;
  final String status; // 'All' | 'Active' | 'Inactive'
  final String sortColumn; // 'class' | 'term' | 'year' | 'tuition' | 'total' | 'due_date'
  final bool sortAscending;

  const FeeStructureFilterState({
    this.searchQuery = '',
    this.academicYear = 'All',
    this.className = 'All',
    this.termName = 'All',
    this.status = 'All',
    this.sortColumn = 'class',
    this.sortAscending = true,
  });

  FeeStructureFilterState copyWith({
    String? searchQuery,
    String? academicYear,
    String? className,
    String? termName,
    String? status,
    String? sortColumn,
    bool? sortAscending,
  }) {
    return FeeStructureFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      academicYear: academicYear ?? this.academicYear,
      className: className ?? this.className,
      termName: termName ?? this.termName,
      status: status ?? this.status,
      sortColumn: sortColumn ?? this.sortColumn,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

final feeStructureFilterProvider = StateProvider<FeeStructureFilterState>((ref) {
  return const FeeStructureFilterState();
});

final feeAcademicYearsProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(feesRepositoryProvider).getAcademicYears();
});

final feeCurrentAcademicYearProvider = FutureProvider<String>((ref) {
  return ref.watch(feesRepositoryProvider).getCurrentAcademicYear();
});

final feeAvailableClassesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(feesRepositoryProvider).getAvailableClasses();
});

final feeStructuresControllerProvider =
    AsyncNotifierProvider<FeeStructuresController, List<FeeStructure>>(
  FeeStructuresController.new,
);

class FeeStructuresController extends AsyncNotifier<List<FeeStructure>> {
  @override
  Future<List<FeeStructure>> build() {
    return ref.watch(feesRepositoryProvider).getFeeStructures();
  }

  Future<FeeStructure> save(FeeStructure structure, {bool isNew = false}) async {
    final repo = ref.read(feesRepositoryProvider);
    final saved = await repo.saveFeeStructure(structure, isNew: isNew);
    ref.invalidateSelf();
    return saved;
  }

  Future<FeeStructure> toggleActive(String id, bool makeActive) async {
    final repo = ref.read(feesRepositoryProvider);
    final updated = await repo.toggleActive(id, makeActive);
    ref.invalidateSelf();
    return updated;
  }

  Future<void> delete(String id) async {
    final repo = ref.read(feesRepositoryProvider);
    await repo.deleteFeeStructure(id);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final filteredFeeStructuresProvider = Provider<AsyncValue<List<FeeStructure>>>((ref) {
  final asyncStructures = ref.watch(feeStructuresControllerProvider);
  final filter = ref.watch(feeStructureFilterProvider);

  return asyncStructures.whenData((structures) {
    var list = structures.where((s) {
      // 1. Academic Year filter
      if (filter.academicYear != 'All' && s.academicYear != filter.academicYear) {
        return false;
      }

      // 2. Class filter
      if (filter.className != 'All' &&
          s.className.toLowerCase() != filter.className.toLowerCase()) {
        return false;
      }

      // 3. Term filter
      if (filter.termName != 'All' &&
          s.termName.toLowerCase() != filter.termName.toLowerCase()) {
        return false;
      }

      // 4. Status filter
      if (filter.status == 'Active' && !s.isActive) return false;
      if (filter.status == 'Inactive' && s.isActive) return false;

      // 5. Search query
      if (filter.searchQuery.isNotEmpty) {
        final q = filter.searchQuery.toLowerCase();
        final matchesClass = s.className.toLowerCase().contains(q);
        final matchesTerm = s.termName.toLowerCase().contains(q);
        final matchesYear = s.academicYear.toLowerCase().contains(q);
        final matchesTotal = s.totalFee.toString().contains(q);
        if (!matchesClass && !matchesTerm && !matchesYear && !matchesTotal) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort
    list.sort((a, b) {
      int cmp = 0;
      switch (filter.sortColumn) {
        case 'class':
          final aNum = int.tryParse(RegExp(r'\d+').firstMatch(a.className)?.group(0) ?? '');
          final bNum = int.tryParse(RegExp(r'\d+').firstMatch(b.className)?.group(0) ?? '');
          if (aNum != null && bNum != null) {
            cmp = aNum.compareTo(bNum);
          } else {
            cmp = a.className.compareTo(b.className);
          }
          break;
        case 'term':
          cmp = a.termName.compareTo(b.termName);
          break;
        case 'year':
          cmp = a.academicYear.compareTo(b.academicYear);
          break;
        case 'tuition':
          cmp = a.tuitionFee.compareTo(b.tuitionFee);
          break;
        case 'total':
          cmp = a.totalFee.compareTo(b.totalFee);
          break;
        case 'due_date':
          cmp = a.dueDate.compareTo(b.dueDate);
          break;
        default:
          cmp = a.className.compareTo(b.className);
      }
      return filter.sortAscending ? cmp : -cmp;
    });

    return list;
  });
});

