import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dynamic_data_client.dart';
import '../domain/staff_leave_model.dart';
import '../application/staff_auth_controller.dart';
import '../application/staff_controller.dart';

abstract class LeaveRepository {
  Future<List<StaffLeaveModel>> getLeaves();
  Future<StaffLeaveModel> applyLeave(StaffLeaveModel leave);
  Future<bool> approveLeave(String id, {String? remarks});
  Future<bool> rejectLeave(String id, {String? remarks});
  Future<bool> cancelLeave(String id);
}

class MockLeaveRepository implements LeaveRepository {
  final DynamicDataClient _dataClient;
  static const String _mockDataPath = 'assets/data/staff/staff_leaves.json';
  static const String _prefsKey = 'edupulse_saved_staff_leaves';

  List<StaffLeaveModel>? _cachedLeaves;
  bool _isLoaded = false;

  MockLeaveRepository({DynamicDataClient? dataClient})
      : _dataClient = dataClient ?? DynamicDataClient.instance;

  Future<void> _ensureLoaded() async {
    if (_isLoaded && _cachedLeaves != null) return;
    _isLoaded = true;

    try {
      final raw = await _dataClient.getAll(
        assetPath: _mockDataPath,
        storageKey: _prefsKey,
      );
      if (raw.isNotEmpty) {
        _cachedLeaves = raw.map((item) => StaffLeaveModel.fromMap(item)).toList();
        return;
      }
    } catch (_) {}

    _cachedLeaves = _buildDefaultLeaves();
  }

  Future<void> _persistCache() async {
    if (_cachedLeaves == null) return;
    try {
      final rawList = _cachedLeaves!.map((l) => l.toMap()).toList();
      await _dataClient.syncAll(
        assetPath: _mockDataPath,
        storageKey: _prefsKey,
        items: rawList,
      );
    } catch (_) {}
  }

  @override
  Future<List<StaffLeaveModel>> getLeaves() async {
    await _ensureLoaded();
    return List.unmodifiable(_cachedLeaves ?? _buildDefaultLeaves());
  }

  @override
  Future<StaffLeaveModel> applyLeave(StaffLeaveModel leave) async {
    await _ensureLoaded();
    _cachedLeaves ??= _buildDefaultLeaves();

    // Insert at front of the list
    _cachedLeaves!.insert(0, leave);
    await _persistCache();
    return leave;
  }

  @override
  Future<bool> approveLeave(String id, {String? remarks}) async {
    await _ensureLoaded();
    if (_cachedLeaves == null) return false;

    final index = _cachedLeaves!.indexWhere((l) => l.id == id);
    if (index >= 0) {
      final current = _cachedLeaves![index];
      _cachedLeaves![index] = current.copyWith(
        status: 'Approved',
        adminRemarks: remarks ?? 'Approved by Principal',
      );
      await _persistCache();
      return true;
    }
    return false;
  }

  @override
  Future<bool> rejectLeave(String id, {String? remarks}) async {
    await _ensureLoaded();
    if (_cachedLeaves == null) return false;

    final index = _cachedLeaves!.indexWhere((l) => l.id == id);
    if (index >= 0) {
      final current = _cachedLeaves![index];
      _cachedLeaves![index] = current.copyWith(
        status: 'Rejected',
        adminRemarks: remarks ?? 'Application declined due to administrative commitments',
      );
      await _persistCache();
      return true;
    }
    return false;
  }

  @override
  Future<bool> cancelLeave(String id) async {
    await _ensureLoaded();
    if (_cachedLeaves == null) return false;

    final index = _cachedLeaves!.indexWhere((l) => l.id == id);
    if (index >= 0) {
      final current = _cachedLeaves![index];
      _cachedLeaves![index] = current.copyWith(
        status: 'Cancelled',
        adminRemarks: 'Withdrawn by applicant',
      );
      await _persistCache();
      return true;
    }
    return false;
  }

  List<StaffLeaveModel> _buildDefaultLeaves() {
    return [
      StaffLeaveModel(
        id: 'sl-0101-01',
        staffId: 'STF-2026-0101',
        staffName: 'Dr. Rajeshwari Swaminathan',
        leaveType: 'Medical Leave',
        dateRange: '19 Oct 2026 - 20 Oct 2026',
        fromDate: DateTime(2026, 10, 19),
        toDate: DateTime(2026, 10, 20),
        durationDays: 2,
        applyDate: '15 Oct 2026',
        status: 'Approved',
        reason: 'Scheduled medical checkup and dental treatment',
        adminRemarks: 'Approved by Principal; substitute coverage assigned to Amit Chatterjee',
      ),
      StaffLeaveModel(
        id: 'sl-0101-02',
        staffId: 'STF-2026-0101',
        staffName: 'Dr. Rajeshwari Swaminathan',
        leaveType: 'Special Duty Leave',
        dateRange: '04 Nov 2026 - 05 Nov 2026',
        fromDate: DateTime(2026, 11, 4),
        toDate: DateTime(2026, 11, 5),
        durationDays: 2,
        applyDate: '16 Oct 2026',
        status: 'Pending',
        reason: 'Attending national mathematics Olympiad committee meeting as keynote delegate',
      ),
      StaffLeaveModel(
        id: 'sl-0101-03',
        staffId: 'STF-2026-0101',
        staffName: 'Dr. Rajeshwari Swaminathan',
        leaveType: 'Casual Leave',
        dateRange: '12 Sep 2026 - 13 Sep 2026',
        fromDate: DateTime(2026, 9, 12),
        toDate: DateTime(2026, 9, 13),
        durationDays: 2,
        applyDate: '08 Sep 2026',
        status: 'Approved',
        reason: 'Family religious ceremony in hometown',
        adminRemarks: 'Approved with advance syllabus coverage verified',
      ),
      StaffLeaveModel(
        id: 'sl-0102-01',
        staffId: 'STF-2026-0102',
        staffName: 'Vikramaditya Sen',
        leaveType: 'Medical Leave',
        dateRange: '22 Oct 2026 - 23 Oct 2026',
        fromDate: DateTime(2026, 10, 22),
        toDate: DateTime(2026, 10, 23),
        durationDays: 2,
        applyDate: '18 Oct 2026',
        status: 'Pending',
        reason: 'Ophthalmology retina scan and recovery',
      ),
      StaffLeaveModel(
        id: 'sl-0103-01',
        staffId: 'STF-2026-0103',
        staffName: 'Ananya Deshmukh',
        leaveType: 'Casual Leave',
        dateRange: '28 Oct 2026 - 29 Oct 2026',
        fromDate: DateTime(2026, 10, 28),
        toDate: DateTime(2026, 10, 29),
        durationDays: 2,
        applyDate: '20 Oct 2026',
        status: 'Pending',
        reason: 'Personal family matter requiring travel to hometown',
      ),
      StaffLeaveModel(
        id: 'sl-0002-01',
        staffId: 'STF-2026-0002',
        staffName: 'Dr. Anand Roy',
        leaveType: 'Special Duty Leave',
        dateRange: '10 Nov 2026 - 12 Nov 2026',
        fromDate: DateTime(2026, 11, 10),
        toDate: DateTime(2026, 11, 12),
        durationDays: 3,
        applyDate: '21 Oct 2026',
        status: 'Pending',
        reason: 'CBSE Annual Principals Leadership Conclave in New Delhi',
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// RIVERPOD PROVIDERS
// ---------------------------------------------------------------------------

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return MockLeaveRepository();
});

class LeaveListNotifier extends AsyncNotifier<List<StaffLeaveModel>> {
  @override
  Future<List<StaffLeaveModel>> build() async {
    final repo = ref.read(leaveRepositoryProvider);
    return repo.getLeaves();
  }

  Future<StaffLeaveModel> applyLeave(StaffLeaveModel leave) async {
    final repo = ref.read(leaveRepositoryProvider);
    final applied = await repo.applyLeave(leave);
    state = AsyncValue.data(await repo.getLeaves());
    return applied;
  }

  Future<bool> approveLeave(String id, {String? remarks}) async {
    final repo = ref.read(leaveRepositoryProvider);
    final success = await repo.approveLeave(id, remarks: remarks);
    if (success) {
      state = AsyncValue.data(await repo.getLeaves());
    }
    return success;
  }

  Future<bool> rejectLeave(String id, {String? remarks}) async {
    final repo = ref.read(leaveRepositoryProvider);
    final success = await repo.rejectLeave(id, remarks: remarks);
    if (success) {
      state = AsyncValue.data(await repo.getLeaves());
    }
    return success;
  }

  Future<bool> cancelLeave(String id) async {
    final repo = ref.read(leaveRepositoryProvider);
    final success = await repo.cancelLeave(id);
    if (success) {
      state = AsyncValue.data(await repo.getLeaves());
    }
    return success;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(leaveRepositoryProvider);
      return repo.getLeaves();
    });
  }
}

final leaveListProvider =
    AsyncNotifierProvider<LeaveListNotifier, List<StaffLeaveModel>>(() {
  return LeaveListNotifier();
});

final filteredLeavesByStaffProvider =
    Provider.family<List<StaffLeaveModel>, String>((ref, staffId) {
  final allLeaves = ref.watch(leaveListProvider).valueOrNull ?? [];
  return allLeaves.where((l) => l.staffId == staffId).toList();
});

final pendingLeavesProvider = Provider<List<StaffLeaveModel>>((ref) {
  final allLeaves = ref.watch(leaveListProvider).valueOrNull ?? [];
  return allLeaves.where((l) => l.isPending).toList();
});

/// Pending faculty leaves specifically for Principal review.
/// Excludes the Principal's own applications so the Principal cannot self-approve.
final pendingLeavesForPrincipalProvider = Provider<List<StaffLeaveModel>>((ref) {
  final allLeaves = ref.watch(leaveListProvider).valueOrNull ?? [];
  final currentStaff = ref.watch(currentLoggedInStaffProvider);
  return allLeaves.where((l) {
    if (!l.isPending) return false;
    // Exclude currently logged in user's own application
    if (currentStaff != null && l.staffId == currentStaff.id) return false;
    return true;
  }).toList();
});

/// Pending leaves of institutional executives (Principal) awaiting Super Admin sign-off.
final pendingPrincipalLeavesForAdminProvider = Provider<List<StaffLeaveModel>>((ref) {
  final allLeaves = ref.watch(leaveListProvider).valueOrNull ?? [];
  final staffList = ref.watch(staffListProvider).valueOrNull ?? [];
  final principalIds = staffList
      .where((s) => s.effectiveRole.toLowerCase() == 'principal')
      .map((s) => s.id)
      .toSet();

  return allLeaves.where((l) {
    if (!l.isPending) return false;
    // Match either known principal IDs or fallback ID for Dr. Anand Roy
    return principalIds.contains(l.staffId) || l.staffId == 'STF-2026-0002';
  }).toList();
});
