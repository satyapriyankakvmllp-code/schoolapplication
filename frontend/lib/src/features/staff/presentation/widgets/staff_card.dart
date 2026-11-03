import 'package:flutter/material.dart';
import '../../domain/staff_member_model.dart';

class StaffCard extends StatelessWidget {
  final StaffMemberModel staff;
  final bool isDark;
  final VoidCallback? onViewProfile;
  final VoidCallback? onEdit;
  final VoidCallback? onPrintBadge;
  final VoidCallback? onToggleStatus;

  const StaffCard({
    super.key,
    required this.staff,
    required this.isDark,
    this.onViewProfile,
    this.onEdit,
    this.onPrintBadge,
    this.onToggleStatus,
  });

  Color _getCategoryColor(StaffCategory cat) {
    switch (cat) {
      case StaffCategory.teaching:
        return const Color(0xFF109F83);
      case StaffCategory.administrative:
        return const Color(0xFF3B82F6);
      case StaffCategory.support:
        return const Color(0xFFF59E0B);
    }
  }

  Color _getStatusColor(StaffStatus status) {
    switch (status) {
      case StaffStatus.active:
        return const Color(0xFF10B981);
      case StaffStatus.onLeave:
        return const Color(0xFFF59E0B);
      case StaffStatus.inactive:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(staff.category);
    final statusColor = _getStatusColor(staff.status);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Avatar + Name/Designation + Status & Category Chips
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      catColor.withValues(alpha: 0.85),
                      catColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: catColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  staff.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name & Designation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      staff.designation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      staff.id,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: catColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      staff.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Department & Category Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  staff.department,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: catColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  staff.category.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: catColor,
                  ),
                ),
              ),
              if (staff.isClassTeacher)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          staff.classTeacherSummary.isNotEmpty
                              ? staff.classTeacherSummary
                              : 'Class Teacher (${staff.primaryClassAssignment?.grade}-${staff.primaryClassAssignment?.section})',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Assigned Classes Preview (for teachers)
          if (staff.category == StaffCategory.teaching && staff.assignedClasses.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Classes: ${staff.assignedClasses.map((a) => '${a.grade}-${a.section}').take(3).join(', ')}${staff.assignedClasses.length > 3 ? ' +${staff.assignedClasses.length - 3} more' : ''}',
              style: TextStyle(
                fontSize: 11,
                color: subtitleColor,
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Contact coordinates row
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 13, color: subtitleColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  staff.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: subtitleColor),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.email_outlined, size: 13, color: subtitleColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  staff.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: subtitleColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewProfile,
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('Profile', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onPrintBadge,
                tooltip: 'ID Badge',
                icon: const Icon(Icons.badge_outlined, size: 18),
                color: const Color(0xFF109F83),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF109F83).withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit Record',
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: const Color(0xFF3B82F6),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
