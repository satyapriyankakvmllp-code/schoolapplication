import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admissions/application/admissions_controller.dart';
import '../domain/user_model.dart';
import 'auth_controller.dart';

/// Lightweight representation for quick student demo authentication
class StudentDemoModel {
  final String id;
  final String fullName;
  final String email;
  final String admissionNumber;
  final String rollNumber;
  final String className;
  final String initials;
  final String? photoUrl;

  const StudentDemoModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.admissionNumber,
    required this.rollNumber,
    required this.className,
    required this.initials,
    this.photoUrl,
  });
}

final selectedStudentUserIdProvider = StateProvider<String?>((ref) => null);

final studentListProvider = FutureProvider<List<StudentDemoModel>>((ref) async {
  return const [
    StudentDemoModel(
      id: 'usr-std-501',
      fullName: 'Aarav Sharma',
      email: 'aarav.sharma@student.edupulse.edu.in',
      admissionNumber: 'ADM-2026-0042',
      rollNumber: '10',
      className: 'Class 10-A',
      initials: 'AS',
      photoUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=300&q=80',
    ),
    StudentDemoModel(
      id: 'usr-std-502',
      fullName: 'Diya Patel',
      email: 'diya.patel@student.edupulse.edu.in',
      admissionNumber: 'ADM-2026-0043',
      rollNumber: '11',
      className: 'Class 10-A',
      initials: 'DP',
      photoUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=300&q=80',
    ),
    StudentDemoModel(
      id: 'usr-std-503',
      fullName: 'Rohan Gupta',
      email: 'rohan.gupta@student.edupulse.edu.in',
      admissionNumber: 'ADM-2026-0044',
      rollNumber: '12',
      className: 'Class 10-B',
      initials: 'RG',
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
    ),
    StudentDemoModel(
      id: 'usr-std-504',
      fullName: 'Ananya Reddy',
      email: 'ananya.reddy@student.edupulse.edu.in',
      admissionNumber: 'ADM-2025-0019',
      rollNumber: '05',
      className: 'Class 11-A',
      initials: 'AR',
      photoUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=300&q=80',
    ),
    StudentDemoModel(
      id: 'usr-std-505',
      fullName: 'Kabir Mehta',
      email: 'kabir.mehta@student.edupulse.edu.in',
      admissionNumber: 'ADM-2024-0008',
      rollNumber: '02',
      className: 'Class 12-A',
      initials: 'KM',
      photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
    ),
    StudentDemoModel(
      id: 'usr-std-506',
      fullName: 'Siddharth Varma',
      email: 'siddharth.varma@student.edupulse.edu.in',
      admissionNumber: 'ADM-2026-0088',
      rollNumber: '24',
      className: 'Class 10-A',
      initials: 'SV',
      photoUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=300&q=80',
    ),
  ];
});

class StudentAuthController {
  final Ref _ref;
  StudentAuthController(this._ref);

  Future<StudentDemoModel?> mockStudentLogin(String email, String password) async {
    final list = await _ref.read(studentListProvider.future);
    final cleanEmail = email.trim().toLowerCase();

    StudentDemoModel? matched;
    for (final s in list) {
      if (s.email.toLowerCase().trim() == cleanEmail ||
          s.admissionNumber.toLowerCase().trim() == cleanEmail) {
        matched = s;
        break;
      }
    }
    matched ??= list.first;

    _ref.read(selectedStudentUserIdProvider.notifier).state = matched.id;
    _ref.read(selectedStudentIdProvider.notifier).state = matched.id;
    _ref.read(activeUserRoleProvider.notifier).state = UserRole.student;
    return matched;
  }

  void logout() {
    _ref.read(selectedStudentUserIdProvider.notifier).state = null;
    _ref.read(activeUserRoleProvider.notifier).state = null;
  }
}

final studentAuthControllerProvider = Provider<StudentAuthController>((ref) {
  return StudentAuthController(ref);
});

final currentLoggedInStudentProvider = Provider<StudentDemoModel?>((ref) {
  final userId = ref.watch(selectedStudentUserIdProvider);
  if (userId == null) return null;
  final list = ref.watch(studentListProvider).valueOrNull ?? [];
  try {
    return list.firstWhere((s) => s.id == userId);
  } catch (_) {
    return null;
  }
});
