import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/admission_request_model.dart';
import '../domain/student_admission_model.dart';
import '../data/admissions_repository.dart';

final admissionsRepositoryProvider = Provider<AdmissionsRepository>((ref) {
  return MockAdmissionsRepository();
});

final admissionsListProvider =
    AsyncNotifierProvider<AdmissionsListNotifier, List<StudentAdmissionModel>>(
  AdmissionsListNotifier.new,
);

class AdmissionsListNotifier extends AsyncNotifier<List<StudentAdmissionModel>> {
  @override
  Future<List<StudentAdmissionModel>> build() async {
    final repository = ref.watch(admissionsRepositoryProvider);
    return repository.getAdmissions();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(admissionsRepositoryProvider);
      return repository.getAdmissions();
    });
  }

  Future<StudentAdmissionModel> saveAdmission(StudentAdmissionModel admission) async {
    final repository = ref.read(admissionsRepositoryProvider);
    final saved = await repository.saveAdmission(admission);
    await refresh();
    return saved;
  }

  Future<void> suspendStudent(String studentId) async {
    final repository = ref.read(admissionsRepositoryProvider);
    await repository.suspendAdmission(studentId);
    await refresh();
  }
}

final selectedStudentIdProvider = StateProvider<String?>((ref) => null);

final studentSearchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<List<StudentAdmissionModel>>((ref) {
  final query = ref.watch(studentSearchQueryProvider).toLowerCase().trim();
  final admissionsAsync = ref.watch(admissionsListProvider);
  return admissionsAsync.maybeWhen(
    data: (list) {
      if (query.isEmpty) return list;
      return list.where((item) {
        final name = item.user.fullName.toLowerCase();
        final admNo = item.student.admissionNumber.toLowerCase();
        final roll = (item.student.rollNumber ?? '').toLowerCase();
        final cls = item.student.className.toLowerCase();
        return name.contains(query) ||
            admNo.contains(query) ||
            roll.contains(query) ||
            cls.contains(query);
      }).toList();
    },
    orElse: () => [],
  );
});

final studentDetailsProvider =
    FutureProvider.family<StudentAdmissionModel?, String?>((ref, studentId) async {
  if (studentId == null || studentId.isEmpty) return null;
  // Watch admissionsListProvider so details auto-updates on any modification
  ref.watch(admissionsListProvider);
  final repository = ref.watch(admissionsRepositoryProvider);
  return repository.getAdmissionById(studentId);
});

// --- Admission Intake / Requests Pipeline Notifier & Providers ---

final admissionRequestsListProvider =
    AsyncNotifierProvider<AdmissionRequestsListNotifier, List<AdmissionRequestModel>>(
  AdmissionRequestsListNotifier.new,
);

class AdmissionRequestsListNotifier extends AsyncNotifier<List<AdmissionRequestModel>> {
  @override
  Future<List<AdmissionRequestModel>> build() async {
    final repository = ref.watch(admissionsRepositoryProvider);
    return repository.getAdmissionRequests();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(admissionsRepositoryProvider);
      return repository.getAdmissionRequests();
    });
  }

  Future<void> rejectRequest(String requestId, {String? reason}) async {
    final repository = ref.read(admissionsRepositoryProvider);
    await repository.updateRequestStatus(
      requestId,
      AdmissionRequestStatus.rejected,
      rejectionReason: reason,
    );
    await refresh();
  }

  Future<void> markApproved(String requestId) async {
    final repository = ref.read(admissionsRepositoryProvider);
    await repository.updateRequestStatus(
      requestId,
      AdmissionRequestStatus.approved,
    );
    await refresh();
  }

  Future<AdmissionRequestModel> createRequest(AdmissionRequestModel request) async {
    final repository = ref.read(admissionsRepositoryProvider);
    final created = await repository.createAdmissionRequest(request);
    await refresh();
    return created;
  }
}

final activeRequestFilterProvider =
    StateProvider<AdmissionRequestStatus?>((ref) => AdmissionRequestStatus.pending);

final requestSearchQueryProvider = StateProvider<String>((ref) => '');

final admissionRequestCountsProvider =
    Provider<Map<AdmissionRequestStatus, int>>((ref) {
  final requestsAsync = ref.watch(admissionRequestsListProvider);
  return requestsAsync.maybeWhen(
    data: (list) {
      return {
        AdmissionRequestStatus.pending:
            list.where((r) => r.status == AdmissionRequestStatus.pending).length,
        AdmissionRequestStatus.approved:
            list.where((r) => r.status == AdmissionRequestStatus.approved).length,
        AdmissionRequestStatus.rejected:
            list.where((r) => r.status == AdmissionRequestStatus.rejected).length,
      };
    },
    orElse: () => {
      AdmissionRequestStatus.pending: 0,
      AdmissionRequestStatus.approved: 0,
      AdmissionRequestStatus.rejected: 0,
    },
  );
});

final filteredAdmissionRequestsProvider =
    Provider<List<AdmissionRequestModel>>((ref) {
  final requestsAsync = ref.watch(admissionRequestsListProvider);
  final activeFilter = ref.watch(activeRequestFilterProvider);
  final query = ref.watch(requestSearchQueryProvider).toLowerCase().trim();

  return requestsAsync.maybeWhen(
    data: (list) {
      return list.where((r) {
        if (activeFilter != null && r.status != activeFilter) {
          return false;
        }
        if (query.isNotEmpty) {
          final matchesName = r.applicantFullName.toLowerCase().contains(query);
          final matchesParent = r.parentFullName.toLowerCase().contains(query);
          final matchesGrade = r.gradeApplied.toLowerCase().contains(query);
          final matchesId = r.id.toLowerCase().contains(query);
          return matchesName || matchesParent || matchesGrade || matchesId;
        }
        return true;
      }).toList();
    },
    orElse: () => [],
  );
});

// Holds a pending request that has been approved for pre-filling into the AddStudentFormScreen
final prefilledAdmissionDraftProvider =
    StateProvider<StudentAdmissionModel?>((ref) => null);

// Tracks the originating request ID when filling the form, so submission marks it approved
final originatingRequestIdProvider = StateProvider<String?>((ref) => null);

