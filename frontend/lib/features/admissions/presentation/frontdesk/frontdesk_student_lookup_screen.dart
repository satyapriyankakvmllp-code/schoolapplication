import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/admissions_controller.dart';
import '../../application/frontdesk_controller.dart';
import '../../domain/student_admission_model.dart';

class FrontDeskStudentLookupScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final ValueChanged<FrontDeskPage> onNavigateFrontDesk;

  const FrontDeskStudentLookupScreen({
    super.key,
    required this.isDark,
    required this.onNavigateFrontDesk,
  });

  @override
  ConsumerState<FrontDeskStudentLookupScreen> createState() => _FrontDeskStudentLookupScreenState();
}

class _FrontDeskStudentLookupScreenState extends ConsumerState<FrontDeskStudentLookupScreen> {
  String _searchQuery = '';
  final String _gradeFilter = 'All';

  final List<Map<String, String>> _studentsDirectory = [
    {
      'id': 'ADM-2026-0042',
      'name': 'Aarav Rajesh Sharma',
      'grade': 'Class 10 - Sec A',
      'roll': '#12',
      'parent': 'Rajesh Sharma (Father)',
      'phone': '+91 98765 43210',
      'blood': 'O+',
      'status': 'Enrolled',
    },
    {
      'id': 'ADM-2026-0089',
      'name': 'Meera Kalyan Iyer',
      'grade': 'Class 9 - Sec C',
      'roll': '#19',
      'parent': 'Kalyan Iyer (Father)',
      'phone': '+91 98222 33445',
      'blood': 'B+',
      'status': 'Enrolled',
    },
    {
      'id': 'ADM-2026-0101',
      'name': 'Kabir Rajesh Sharma',
      'grade': 'Class 6 - Sec B',
      'roll': '#07',
      'parent': 'Rajesh Sharma (Father)',
      'phone': '+91 98765 43210',
      'blood': 'O+',
      'status': 'Draft Intake',
    },
    {
      'id': 'ADM-2026-0031',
      'name': 'Ananya Deshmukh',
      'grade': 'Class 8 - Sec A',
      'roll': '#04',
      'parent': 'Vikram Deshmukh (Father)',
      'phone': '+91 97665 44112',
      'blood': 'A+',
      'status': 'Enrolled',
    },
  ];

  List<Map<String, String>> _getCombinedDirectory(List<StudentAdmissionModel> admissions) {
    final list = List<Map<String, String>>.from(_studentsDirectory);

    // Live newly enrolled students from admissionsListProvider prepended at the top
    for (final adm in admissions) {
      final alreadyExists = list.any((s) =>
          s['id'] == adm.student.admissionNumber ||
          s['name'] == adm.user.fullName);

      if (!alreadyExists) {
        final parentName = adm.father?.fullName ??
            adm.guardian?.fullName ??
            adm.mother?.fullName ??
            'Parent / Guardian';
        final parentRel = adm.father != null
            ? 'Father'
            : (adm.mother != null ? 'Mother' : (adm.guardian?.relationship ?? 'Guardian'));
        final grade =
            '${adm.student.className}${adm.student.section != null && adm.student.section!.isNotEmpty ? " - Sec ${adm.student.section}" : ""}';
        final roll = adm.student.rollNumber != null && adm.student.rollNumber!.isNotEmpty
            ? '#${adm.student.rollNumber}'
            : '#Pending';
        final phone = adm.student.emergencyContactPhone ??
            adm.father?.phoneNumber ??
            adm.user.phoneNumber;

        list.insert(0, {
          'id': adm.student.admissionNumber,
          'name': adm.user.fullName,
          'grade': grade,
          'roll': roll,
          'parent': '$parentName ($parentRel)',
          'phone': phone,
          'blood': adm.student.bloodGroup ?? 'O+',
          'status': 'Enrolled',
        });
      }
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    final admissionsAsync = ref.watch(admissionsListProvider);
    final combinedDirectory = _getCombinedDirectory(admissionsAsync.valueOrNull ?? []);

    final filtered = combinedDirectory.where((s) {
      final matchesQuery = s['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s['id']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s['phone']!.contains(_searchQuery);
      if (_gradeFilter == 'All') return matchesQuery;
      return matchesQuery && s['grade']!.startsWith(_gradeFilter);
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Directory & Visitor Verification',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Fast student and parent identity verification for front-desk reception',
                      style: TextStyle(fontSize: isMobile ? 11 : 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search input
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by student name, admission number (ADM-...), or parent phone...',
              filled: true,
              fillColor: isDark ? const Color(0xFF131D31) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // Directory cards
          ...filtered.map((s) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D31) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                    child: Text(
                      s['name']![0],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              s['name']!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                s['status']!,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${s['id']} • ${s['grade']} • Roll: ${s['roll']} • Blood: ${s['blood']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          'Guardian: ${s['parent']} • Phone: ${s['phone']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.badge_outlined, size: 14),
                      label: const Text('View Badge', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B5CF6),
                        side: const BorderSide(color: Color(0xFF8B5CF6)),
                      ),
                      onPressed: () {
                        ref.read(frontDeskSelectedStudentBadgeProvider.notifier).state = s['name'];
                        widget.onNavigateFrontDesk(FrontDeskPage.idBadgeStudio);
                      },
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.badge_outlined, color: Color(0xFF8B5CF6), size: 20),
                      tooltip: 'View Badge',
                      onPressed: () {
                        ref.read(frontDeskSelectedStudentBadgeProvider.notifier).state = s['name'];
                        widget.onNavigateFrontDesk(FrontDeskPage.idBadgeStudio);
                      },
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
