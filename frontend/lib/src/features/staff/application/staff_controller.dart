import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/staff_repository.dart';
import '../domain/staff_member_model.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return MockStaffRepository();
});

class StaffListNotifier extends AsyncNotifier<List<StaffMemberModel>> {
  @override
  Future<List<StaffMemberModel>> build() async {
    final repo = ref.read(staffRepositoryProvider);
    return repo.getStaffList();
  }

  Future<StaffMemberModel> saveStaff(StaffMemberModel staff) async {
    final repo = ref.read(staffRepositoryProvider);
    final saved = await repo.saveStaff(staff);
    // Reload state after saving
    state = AsyncValue.data(await repo.getStaffList());
    return saved;
  }

  Future<bool> deactivateStaff(String id) async {
    final repo = ref.read(staffRepositoryProvider);
    final success = await repo.deleteOrDeactivateStaff(id);
    if (success) {
      state = AsyncValue.data(await repo.getStaffList());
    }
    return success;
  }

  Future<String> getNextStaffId() async {
    final repo = ref.read(staffRepositoryProvider);
    return repo.generateNextStaffId();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(staffRepositoryProvider);
      return repo.getStaffList();
    });
  }
}

final staffListProvider =
    AsyncNotifierProvider<StaffListNotifier, List<StaffMemberModel>>(() {
  return StaffListNotifier();
});

final selectedStaffIdProvider = StateProvider<String?>((ref) => null);

final staffDetailsProvider = Provider.family<StaffMemberModel?, String?>((ref, staffId) {
  if (staffId == null) return null;
  final staffList = ref.watch(staffListProvider).valueOrNull ?? [];
  try {
    return staffList.firstWhere((s) => s.id == staffId);
  } catch (_) {
    return null;
  }
});

// Filters
final staffSearchQueryProvider = StateProvider<String>((ref) => '');
final staffCategoryFilterProvider = StateProvider<StaffCategory?>((ref) => null);
final staffDepartmentFilterProvider = StateProvider<String?>((ref) => null);
final staffStatusFilterProvider = StateProvider<StaffStatus?>((ref) => null);

// Filtered Staff Provider
final filteredStaffListProvider = Provider<List<StaffMemberModel>>((ref) {
  final allStaff = ref.watch(staffListProvider).valueOrNull ?? [];
  final query = ref.watch(staffSearchQueryProvider).trim().toLowerCase();
  final categoryFilter = ref.watch(staffCategoryFilterProvider);
  final departmentFilter = ref.watch(staffDepartmentFilterProvider);
  final statusFilter = ref.watch(staffStatusFilterProvider);

  return allStaff.where((staff) {
    // 1. Text Search query
    if (query.isNotEmpty) {
      final matchName = staff.fullName.toLowerCase().contains(query);
      final matchId = staff.id.toLowerCase().contains(query);
      final matchPhone = staff.phone.toLowerCase().contains(query);
      final matchDesignation = staff.designation.toLowerCase().contains(query);
      final matchDepartment = staff.department.toLowerCase().contains(query);
      if (!matchName && !matchId && !matchPhone && !matchDesignation && !matchDepartment) {
        return false;
      }
    }

    // 2. Category filter
    if (categoryFilter != null && staff.category != categoryFilter) {
      return false;
    }

    // 3. Department filter
    if (departmentFilter != null &&
        departmentFilter.isNotEmpty &&
        departmentFilter != 'All' &&
        staff.department != departmentFilter) {
      return false;
    }

    // 4. Status filter
    if (statusFilter != null && staff.status != statusFilter) {
      return false;
    }

    return true;
  }).toList();
});

class StaffCounts {
  final int total;
  final int teaching;
  final int administrative;
  final int support;
  final int onLeave;
  final int active;

  const StaffCounts({
    required this.total,
    required this.teaching,
    required this.administrative,
    required this.support,
    required this.onLeave,
    required this.active,
  });
}

final staffCountsProvider = Provider<StaffCounts>((ref) {
  final allStaff = ref.watch(staffListProvider).valueOrNull ?? [];
  int teaching = 0;
  int administrative = 0;
  int support = 0;
  int onLeave = 0;
  int active = 0;

  for (final s in allStaff) {
    if (s.category == StaffCategory.teaching) teaching++;
    if (s.category == StaffCategory.administrative) administrative++;
    if (s.category == StaffCategory.support) support++;
    if (s.status == StaffStatus.onLeave) onLeave++;
    if (s.status == StaffStatus.active) active++;
  }

  return StaffCounts(
    total: allStaff.length,
    teaching: teaching,
    administrative: administrative,
    support: support,
    onLeave: onLeave,
    active: active,
  );
});
