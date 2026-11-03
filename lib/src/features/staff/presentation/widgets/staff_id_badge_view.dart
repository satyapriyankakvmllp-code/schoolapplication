import 'package:flutter/material.dart';
import '../../domain/staff_member_model.dart';

class StaffIdBadgeView extends StatefulWidget {
  final StaffMemberModel staff;
  final bool isDark;

  const StaffIdBadgeView({
    super.key,
    required this.staff,
    required this.isDark,
  });

  @override
  State<StaffIdBadgeView> createState() => _StaffIdBadgeViewState();
}

class _StaffIdBadgeViewState extends State<StaffIdBadgeView> {
  bool _showFront = true;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final staff = widget.staff;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Side Selector Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Front Side', style: TextStyle(fontSize: 12)),
              selected: _showFront,
              selectedColor: const Color(0xFF109F83).withValues(alpha: 0.2),
              onSelected: (val) {
                if (val) setState(() => _showFront = true);
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Reverse Side', style: TextStyle(fontSize: 12)),
              selected: !_showFront,
              selectedColor: const Color(0xFF109F83).withValues(alpha: 0.2),
              onSelected: (val) {
                if (val) setState(() => _showFront = false);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Badge Container (Standard CR80 aspect ratio ~ 85.6mm x 53.98mm)
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: _showFront
                ? _buildFrontSide(staff, isDark)
                : _buildReverseSide(staff, isDark),
          ),
        ),

        const SizedBox(height: 16),

        // Print Action
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ID Badge for ${staff.fullName} sent to thermal card printer.'),
                backgroundColor: const Color(0xFF109F83),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.print_outlined, size: 16),
          label: const Text('Print Physical ID Badge', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF109F83),
            side: const BorderSide(color: Color(0xFF109F83)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildFrontSide(StaffMemberModel staff, bool isDark) {
    Color headerBg = const Color(0xFF0F172A);
    if (staff.category == StaffCategory.teaching) {
      headerBg = const Color(0xFF0F766E);
    } else if (staff.category == StaffCategory.administrative) {
      headerBg = const Color(0xFF1E3A8A);
    }

    return Container(
      key: const ValueKey('front_badge'),
      width: 280,
      height: 420,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(color: headerBg),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EDUPULSE ACADEMY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'FACULTY & STAFF IDENTIFICATION',
                      style: TextStyle(
                        fontSize: 7.5,
                        color: Colors.white70,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Photo / Monogram Avatar
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: headerBg, width: 3),
              gradient: LinearGradient(
                colors: [headerBg.withValues(alpha: 0.8), headerBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              staff.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Name & Designation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  staff.fullName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  staff.designation,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Department & Category Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: headerBg.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: headerBg.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${staff.department} • ${staff.category.label}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: headerBg,
              ),
            ),
          ),

          const Spacer(),

          // Staff ID and Barcode Mock
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Text(
                  'STAFF ID: ${staff.id}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: headerBg,
                    letterSpacing: 1.2,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                // Simulated barcode bars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    24,
                    (i) => Container(
                      width: (i % 3 == 0) ? 3 : (i % 2 == 0 ? 1.5 : 2),
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 1.2),
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReverseSide(StaffMemberModel staff, bool isDark) {
    return Container(
      key: const ValueKey('reverse_badge'),
      width: 280,
      height: 420,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'INSTITUTIONAL CREDENTIAL CARD',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          _buildInfoRow('Emergency Tel', staff.emergencyContact ?? staff.phone),
          _buildInfoRow('Official Email', staff.email),
          _buildInfoRow('Blood Group', staff.bloodGroup ?? 'O+'),
          _buildInfoRow('Date of Joining', '${staff.joiningDate.day}/${staff.joiningDate.month}/${staff.joiningDate.year}'),
          _buildInfoRow('Employment', staff.employmentType.label),

          const Spacer(),

          // Signature Block
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 25,
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'R.Swaminathan',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 10,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  Container(width: 80, height: 1, color: Colors.grey.shade400),
                  const SizedBox(height: 2),
                  const Text('Cardholder Sign', style: TextStyle(fontSize: 8, color: Colors.grey)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 70,
                    height: 25,
                    alignment: Alignment.centerRight,
                    child: const Text(
                      'Dr. V. Rao',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 10,
                        color: Color(0xFF0F766E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(width: 80, height: 1, color: Colors.grey.shade400),
                  const SizedBox(height: 2),
                  const Text('Principal / Registrar', style: TextStyle(fontSize: 8, color: Colors.grey)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'If found, please return to: EduPulse Academy, 12 Campus Boulevard, Bengaluru, KA. Tel: +91 80 2345 6789.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 7.5, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
