import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/admissions_controller.dart';
import '../../application/frontdesk_controller.dart';
import '../../domain/student_admission_model.dart';

class IdBadgeStudioScreen extends ConsumerStatefulWidget {
  final bool isDark;

  const IdBadgeStudioScreen({
    super.key,
    required this.isDark,
  });

  @override
  ConsumerState<IdBadgeStudioScreen> createState() => _IdBadgeStudioScreenState();
}

class _IdBadgeStudioScreenState extends ConsumerState<IdBadgeStudioScreen> {
  String _selectedStudent = 'Aarav Sharma';
  bool _showBackSide = false;

  final Map<String, Map<String, String>> _mockBadgeData = {
    'Aarav Sharma': {
      'name': 'Aarav Rajesh Sharma',
      'id': 'ADM-2026-0042',
      'roll': '#12',
      'class': 'Class 10 - Sec A',
      'dob': '14 Aug 2010',
      'blood': 'O+ (Positive)',
      'parent': 'Rajesh Sharma',
      'phone': '+91 98765 43210',
      'address': 'Flat 402, Green Valley Apts, Model Town',
      'emergency': '+91 98765 43210 (Father)',
    },
    'Kabir Sharma': {
      'name': 'Kabir Rajesh Sharma',
      'id': 'ADM-2026-0101',
      'roll': '#07',
      'class': 'Class 6 - Sec B',
      'dob': '22 Oct 2014',
      'blood': 'O+ (Positive)',
      'parent': 'Rajesh Sharma',
      'phone': '+91 98765 43210',
      'address': 'Flat 402, Green Valley Apts, Model Town',
      'emergency': '+91 98765 43210 (Father)',
    },
    'Meera Iyer': {
      'name': 'Meera Kalyan Iyer',
      'id': 'ADM-2026-0089',
      'roll': '#19',
      'class': 'Class 9 - Sec C',
      'dob': '05 Mar 2011',
      'blood': 'B+ (Positive)',
      'parent': 'Kalyan Iyer',
      'phone': '+91 98222 33445',
      'address': 'Villa 18, Palm Meadows, Whitefield',
      'emergency': '+91 98222 33445 (Father)',
    },
  };

  Map<String, Map<String, String>> _getCombinedBadgeData(List<StudentAdmissionModel> admissions) {
    final map = Map<String, Map<String, String>>.from(_mockBadgeData);

    // Live enrolled admissions (adds new students not already in baseline badge list)
    for (final adm in admissions) {
      final name = adm.user.fullName;
      final alreadyExists = map.containsKey(name) ||
          map.values.any((v) => v['id'] == adm.student.admissionNumber);

      if (!alreadyExists) {
        final parentName = adm.father?.fullName ??
            adm.guardian?.fullName ??
            adm.mother?.fullName ??
            'Parent / Guardian';
        final phone = adm.student.emergencyContactPhone ??
            adm.father?.phoneNumber ??
            adm.user.phoneNumber;
        final parentRel = adm.father != null
            ? 'Father'
            : (adm.mother != null ? 'Mother' : (adm.guardian?.relationship ?? 'Guardian'));
        final grade =
            '${adm.student.className}${adm.student.section != null && adm.student.section!.isNotEmpty ? " - Sec ${adm.student.section}" : ""}';
        final roll = adm.student.rollNumber != null && adm.student.rollNumber!.isNotEmpty
            ? '#${adm.student.rollNumber}'
            : '#Pending';
        final dobStr = adm.user.dateOfBirth != null
            ? DateFormat('dd MMM yyyy').format(adm.user.dateOfBirth!)
            : '14 Aug 2014';
        final address = adm.student.currentAddress.isNotEmpty
            ? adm.student.currentAddress
            : 'Registered Residential Address';

        map[name] = {
          'name': name,
          'id': adm.student.admissionNumber,
          'roll': roll,
          'class': grade,
          'dob': dobStr,
          'blood': '${adm.student.bloodGroup ?? "O+"} (Positive)',
          'parent': parentName,
          'phone': phone,
          'address': address,
          'emergency': '$phone ($parentRel)',
        };
      }
    }

    return map;
  }

  void _printBadge() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ID Badge for $_selectedStudent sent to Front-Desk Thermal Badge Printer!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    final admissionsAsync = ref.watch(admissionsListProvider);
    final badgeData = _getCombinedBadgeData(admissionsAsync.valueOrNull ?? []);

    final externalSelected = ref.watch(frontDeskSelectedStudentBadgeProvider);
    if (externalSelected != null && badgeData.containsKey(externalSelected) && _selectedStudent != externalSelected) {
      _selectedStudent = externalSelected;
    } else if (!badgeData.containsKey(_selectedStudent) && badgeData.isNotEmpty) {
      _selectedStudent = badgeData.keys.first;
    }

    final studentData = badgeData[_selectedStudent] ??
        (badgeData.isNotEmpty ? badgeData.values.first : _mockBadgeData.values.first);

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
                      'Student Photo ID Badge Studio',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Generate institutional NFC/Barcode identity cards with instant printer dispatch',
                      style: TextStyle(fontSize: isMobile ? 11 : 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.print_outlined, size: 16),
                label: const Text('Print Badge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _printBadge,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Student selector bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131D31) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.badge_outlined, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 10),
                Text('Select Enrolled Scholar:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: badgeData.keys.map((name) {
                        final isSelected = _selectedStudent == name;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(name),
                            selected: isSelected,
                            selectedColor: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF8B5CF6) : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            onSelected: (_) {
                              ref.read(frontDeskSelectedStudentBadgeProvider.notifier).state = name;
                              setState(() => _selectedStudent = name);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ID Card View Controls
          Center(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Front Side (Identity)'), icon: Icon(Icons.person_pin_outlined, size: 16)),
                ButtonSegment(value: true, label: Text('Back Side (Emergency & Address)'), icon: Icon(Icons.contact_emergency_outlined, size: 16)),
              ],
              selected: {_showBackSide},
              onSelectionChanged: (set) => setState(() => _showBackSide = set.first),
            ),
          ),
          const SizedBox(height: 24),

          // Interactive Badge Card Canvas
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showBackSide
                  ? _buildBadgeBack(studentData, isDark, isMobile)
                  : _buildBadgeFront(studentData, isDark, isMobile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeFront(Map<String, String> data, bool isDark, bool isMobile) {
    return Container(
      key: const ValueKey('front'),
      width: isMobile ? 320 : 380,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header band
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EDUPULSE ACADEMY',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                      ),
                      Text(
                        'AFFILIATED TO CBSE • SEC 14',
                        style: TextStyle(fontSize: 8, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.verified, color: Colors.white, size: 16),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  child: Text(
                    data['name']![0],
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data['name']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${data['class']} • Roll ${data['roll']}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBadgeField('ADMISSION NO', data['id']!),
                    _buildBadgeField('BLOOD GROUP', data['blood']!),
                  ],
                ),
                const SizedBox(height: 14),
                // Barcode simulation
                Container(
                  height: 36,
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      24,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: (i % 3 == 0) ? 3 : 1.5,
                        height: 24,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(data['id']!, style: const TextStyle(fontSize: 9, letterSpacing: 2, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeBack(Map<String, String> data, bool isDark, bool isMobile) {
    return Container(
      key: const ValueKey('back'),
      width: isMobile ? 320 : 380,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'EMERGENCY & GUARDIAN DIRECTORY',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
            ),
          ),
          const Divider(height: 20),
          _buildBackField('Primary Guardian', data['parent']!),
          const SizedBox(height: 8),
          _buildBackField('Emergency Contact', data['emergency']!),
          const SizedBox(height: 8),
          _buildBackField('Residential Address', data['address']!),
          const SizedBox(height: 8),
          _buildBackField('Date of Birth', data['dob']!),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. Sarah Jenkins', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text('Principal Signature', style: TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black54),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.qr_code_2, size: 36, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeField(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildBackField(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
      ],
    );
  }
}
