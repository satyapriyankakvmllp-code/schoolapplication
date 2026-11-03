import 'package:flutter/material.dart';

const Color kExamGreen = Color(0xFF109F83);

/// Standardized outlined input decoration with visible borders for all examination forms.
InputDecoration flowDecoration(
  BuildContext context,
  String label, {
  String? hint,
  Widget? suffix,
  Widget? prefix,
}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffix,
    prefixIcon: prefix,
    isDense: true,
    filled: true,
    fillColor: dark ? const Color(0xFF1E293B) : Colors.white,
    border: const OutlineInputBorder(),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: dark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
        width: 1.2,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: kExamGreen, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 1.2),
      borderRadius: BorderRadius.circular(8),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

/// Unified compact floating snackbar across the entire Examination module.
/// Narrow width on desktop, 2.5s duration, compact padding, and small font.
void flowSnack(BuildContext context, String msg, {bool error = false}) {
  final isDesktop = MediaQuery.sizeOf(context).width >= 768;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        msg,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
      ),
      duration: const Duration(milliseconds: 2500),
      backgroundColor: error ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      width: isDesktop ? 340 : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    ),
  );
}

String flowError(Object e) =>
    e.toString().replaceFirst('Exception: ', '').replaceAll('ExamValidationException: ', '');

class FlowEmpty extends StatelessWidget {
  final IconData icon;
  final String text;
  const FlowEmpty(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
        border: Border.all(color: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: dark ? Colors.white38 : Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: dark ? Colors.white70 : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class FlowChip extends StatelessWidget {
  final String label;
  final Color color;
  const FlowChip(this.label, this.color, {super.key});

  static Color forStatus(String s) {
    switch (s.toUpperCase()) {
      case 'PRESENT':
      case 'ISSUED':
      case 'APPROVED':
      case 'PUBLISHED':
      case 'SCHEDULED':
        return const Color(0xFF059669);
      case 'SUBMITTED':
      case 'UNDER_REVIEW':
      case 'PENDING_APPROVAL':
        return const Color(0xFF2563EB);
      case 'ABSENT':
      case 'REVOKED':
      case 'FLAGGED':
      case 'REJECTED':
      case 'CANCELLED':
      case 'MALPRACTICE':
        return const Color(0xFFDC2626);
      case 'DRAFT':
        return const Color(0xFFD97706);
      case 'COMPLETED':
        return const Color(0xFF475569);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      );
}

FlowChip statusChip(String status) =>
    FlowChip(status.replaceAll('_', ' '), FlowChip.forStatus(status));
