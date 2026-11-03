import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';
import 'auth_controller.dart';

/// Lightweight representation for quick parent demo authentication
class ParentDemoModel {
  final String id;
  final String fullName;
  final String email;
  final String childName;
  final String childClass;
  final String childStudentId;
  final String initials;
  final String? photoUrl;

  const ParentDemoModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.childName,
    required this.childClass,
    required this.childStudentId,
    required this.initials,
    this.photoUrl,
  });
}

final selectedParentUserIdProvider = StateProvider<String?>((ref) => null);

final parentListProvider = FutureProvider<List<ParentDemoModel>>((ref) async {
  return const [
    ParentDemoModel(
      id: 'usr-par-601',
      fullName: 'Ramesh Sharma',
      email: 'ramesh.sharma@gmail.com',
      childName: 'Aarav Sharma',
      childClass: 'Class 10-A',
      childStudentId: 'usr-std-501',
      initials: 'RS',
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
    ),
    ParentDemoModel(
      id: 'usr-par-602',
      fullName: 'Sunita Sharma',
      email: 'sunita.sharma@gmail.com',
      childName: 'Kabir Mehta',
      childClass: 'Class 12-A',
      childStudentId: 'usr-std-505',
      initials: 'SS',
      photoUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=300&q=80',
    ),
    ParentDemoModel(
      id: 'usr-par-603',
      fullName: 'Bhavin Patel',
      email: 'bhavin.patel@gmail.com',
      childName: 'Diya Patel',
      childClass: 'Class 10-A',
      childStudentId: 'usr-std-502',
      initials: 'BP',
      photoUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80',
    ),
    ParentDemoModel(
      id: 'usr-par-604',
      fullName: 'Sanjay Gupta',
      email: 'sanjay.gupta@gmail.com',
      childName: 'Rohan Gupta',
      childClass: 'Class 10-B',
      childStudentId: 'usr-std-503',
      initials: 'SG',
    ),
    ParentDemoModel(
      id: 'usr-par-605',
      fullName: 'Venkat Reddy',
      email: 'venkat.reddy@gmail.com',
      childName: 'Ananya Reddy',
      childClass: 'Class 11-A',
      childStudentId: 'usr-std-504',
      initials: 'VR',
    ),
  ];
});

class ParentAuthController {
  final Ref _ref;
  ParentAuthController(this._ref);

  Future<ParentDemoModel?> mockParentLogin(String email, String password) async {
    final list = await _ref.read(parentListProvider.future);
    final cleanEmail = email.trim().toLowerCase();

    ParentDemoModel? matched;
    for (final p in list) {
      if (p.email.toLowerCase().trim() == cleanEmail) {
        matched = p;
        break;
      }
    }
    matched ??= list.first;

    _ref.read(selectedParentUserIdProvider.notifier).state = matched.id;
    _ref.read(activeUserRoleProvider.notifier).state = UserRole.parent;
    _ref.read(parentActiveChildIdProvider.notifier).state = matched.childStudentId;
    return matched;
  }

  void logout() {
    _ref.read(selectedParentUserIdProvider.notifier).state = null;
    _ref.read(activeUserRoleProvider.notifier).state = null;
  }
}

final parentAuthControllerProvider = Provider<ParentAuthController>((ref) {
  return ParentAuthController(ref);
});

final currentLoggedInParentProvider = Provider<ParentDemoModel?>((ref) {
  final userId = ref.watch(selectedParentUserIdProvider);
  if (userId == null) return null;
  final list = ref.watch(parentListProvider).valueOrNull ?? [];
  try {
    return list.firstWhere((p) => p.id == userId);
  } catch (_) {
    return null;
  }
});
