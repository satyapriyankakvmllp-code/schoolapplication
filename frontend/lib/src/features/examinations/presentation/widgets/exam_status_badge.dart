import 'package:flutter/material.dart';

class ExamStatusBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const ExamStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    final Color textColor;
    final Color bgColor;
    final Color borderColor;
    final IconData icon;

    switch (s) {
      case 'ONGOING':
        textColor = const Color(0xFFD97706); // amber-600
        bgColor = const Color(0xFFFEF3C7); // amber-100
        borderColor = const Color(0xFFFDE68A); // amber-200
        icon = Icons.play_circle_filled;
        break;
      case 'COMPLETED':
        textColor = const Color(0xFF059669); // emerald-600
        bgColor = const Color(0xFFD1FAE5); // emerald-100
        borderColor = const Color(0xFFA7F3D0); // emerald-200
        icon = Icons.check_circle;
        break;
      case 'CANCELLED':
        textColor = const Color(0xFFDC2626); // red-600
        bgColor = const Color(0xFFFEE2E2); // red-100
        borderColor = const Color(0xFFFECACA); // red-200
        icon = Icons.cancel;
        break;
      case 'PLANNED':
      default:
        textColor = const Color(0xFF2563EB); // blue-600
        bgColor = const Color(0xFFDBEAFE); // blue-100
        borderColor = const Color(0xFFBFDBFE); // blue-200
        icon = Icons.event_available;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 10 : 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            s,
            style: TextStyle(
              color: textColor,
              fontSize: isCompact ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

