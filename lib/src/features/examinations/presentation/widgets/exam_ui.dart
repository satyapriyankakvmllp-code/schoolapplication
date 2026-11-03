import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color kExamTeal = Color(0xFF109F83);

bool examIsDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

/// Clean readable text from an exception.
String examErrorText(Object e) {
  return e
      .toString()
      .replaceAll('Exception:', '')
      .replaceAll('ExamValidationException:', '')
      .replaceAll('ExamPermissionException:', '')
      .trim();
}

void showExamSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red.shade700 : null,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ---------------------------------------------------------------------------
// FORM FIELDS: always a visible, filled box with a clear border
// ---------------------------------------------------------------------------
InputDecoration examInputDecoration(
  BuildContext context, {
  String? hint,
  Widget? suffixIcon,
  bool enabled = true,
}) {
  final dark = examIsDark(context);
  final borderColor = dark ? const Color(0xFF64748B) : const Color(0xFFB8C0CC);
  OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontSize: 13,
      color: dark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
    ),
    filled: true,
    fillColor: enabled
        ? (dark ? const Color(0xFF1E293B) : Colors.white)
        : (dark ? const Color(0xFF172033) : const Color(0xFFF3F4F6)),
    isDense: true,
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    suffixIcon: suffixIcon,
    border: border(borderColor, 1.2),
    enabledBorder: border(borderColor, 1.2),
    disabledBorder: border(borderColor.withValues(alpha: 0.6), 1),
    focusedBorder: border(kExamTeal, 1.8),
    errorBorder: border(Colors.red.shade400, 1.4),
    focusedErrorBorder: border(Colors.red.shade600, 1.8),
  );
}

class ExamLabel extends StatelessWidget {
  final String text;
  const ExamLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: examIsDark(context) ? const Color(0xFFE2E8F0) : const Color(0xFF1F2937),
        ),
      ),
    );
  }
}

class ExamTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  const ExamTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExamLabel(label),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13.5),
          decoration: examInputDecoration(
            context,
            hint: hint,
            enabled: enabled,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

class ExamOption<T> {
  final T value;
  final String label;
  const ExamOption(this.value, this.label);
}

class ExamDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<ExamOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? Function(T?)? validator;

  const ExamDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final dark = examIsDark(context);
    final safe = options.any((o) => o.value == value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExamLabel(label),
        DropdownButtonFormField<T>(
          key: ValueKey('$label-$safe-${options.length}'),
          initialValue: safe,
          isExpanded: true,
          validator: validator,
          hint: hint == null
              ? null
              : Text(hint!, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
          style: TextStyle(
            fontSize: 13.5,
            color: dark ? Colors.white : const Color(0xFF0F172A),
          ),
          dropdownColor: dark ? const Color(0xFF1E293B) : Colors.white,
          decoration: examInputDecoration(context, enabled: onChanged != null),
          items: options
              .map((o) => DropdownMenuItem<T>(
                    value: o.value,
                    child: Text(o.label, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class ExamDateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool enabled;
  final ValueChanged<String>? onPicked;
  final String? Function(String?)? validator;

  const ExamDateField({
    super.key,
    required this.label,
    required this.controller,
    required this.firstDate,
    required this.lastDate,
    this.enabled = true,
    this.onPicked,
    this.validator,
  });

  Future<void> _pick(BuildContext context) async {
    DateTime initial = DateTime.now();
    try {
      final p = controller.text.split('-').map(int.parse).toList();
      initial = DateTime(p[0], p[1], p[2]);
    } catch (_) {}
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      final text = DateFormat('yyyy-MM-dd').format(picked);
      controller.text = text;
      onPicked?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExamLabel(label),
        TextFormField(
          controller: controller,
          readOnly: true,
          enabled: enabled,
          validator: validator,
          style: const TextStyle(fontSize: 13.5),
          decoration: examInputDecoration(
            context,
            hint: 'yyyy-MM-dd',
            enabled: enabled,
            suffixIcon: const Icon(Icons.calendar_today, size: 17),
          ),
          onTap: enabled ? () => _pick(context) : null,
        ),
      ],
    );
  }
}

class ExamTimeField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onPicked;
  final String? Function(String?)? validator;

  const ExamTimeField({
    super.key,
    required this.label,
    required this.controller,
    this.enabled = true,
    this.onPicked,
    this.validator,
  });

  Future<void> _pick(BuildContext context) async {
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 30);
    try {
      final p = controller.text.split(':').map(int.parse).toList();
      initial = TimeOfDay(hour: p[0], minute: p[1]);
    } catch (_) {}
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = text;
      onPicked?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExamLabel(label),
        TextFormField(
          controller: controller,
          readOnly: true,
          enabled: enabled,
          validator: validator,
          style: const TextStyle(fontSize: 13.5),
          decoration: examInputDecoration(
            context,
            hint: 'HH:mm',
            enabled: enabled,
            suffixIcon: const Icon(Icons.access_time, size: 18),
          ),
          onTap: enabled ? () => _pick(context) : null,
        ),
      ],
    );
  }
}

/// Two fields side by side on wide screens, stacked on narrow ones.
class ExamFieldRow extends StatelessWidget {
  final List<Widget> children;
  const ExamFieldRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 420) {
        return Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              children[i],
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: children[i]),
          ],
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// DIALOG FRAME (every form opens inside this, never on a new page)
// ---------------------------------------------------------------------------
Future<T?> showExamDialog<T>(BuildContext context, WidgetBuilder builder) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: builder,
  );
}

class ExamDialogFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final bool scrollBody;

  const ExamDialogFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon = Icons.add_circle_outline,
    this.actions = const [],
    this.maxWidth = 560,
    this.scrollBody = true,
  });

  @override
  Widget build(BuildContext context) {
    final dark = examIsDark(context);
    final height = MediaQuery.sizeOf(context).height;
    return Dialog(
      backgroundColor: dark ? const Color(0xFF0F172A) : const Color(0xFFEEF0F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: height * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 10, 6),
              child: Row(
                children: [
                  Icon(icon, color: kExamTeal, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: dark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: scrollBody
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: child,
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: child,
                    ),
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: actions,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Primary button used in dialog footers (teal, rounded).
class ExamPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  final Color? color;

  const ExamPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color ?? kExamTeal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      ),
      child: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
    );
  }
}

class ExamCancelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const ExamCancelButton({super.key, this.label = 'Cancel', this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

/// Red error box shown inside a form.
class ExamNotice extends StatelessWidget {
  final String message;
  final bool warning;
  final bool info;
  const ExamNotice(this.message, {super.key, this.warning = false, this.info = false});

  @override
  Widget build(BuildContext context) {
    final color = info ? Colors.blue : (warning ? Colors.orange : Colors.red);
    final icon = info
        ? Icons.info_outline
        : (warning ? Icons.warning_amber_rounded : Icons.error_outline);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STATUS BADGES
// ---------------------------------------------------------------------------
({Color fg, Color bg}) examStatusStyle(String status) {
  switch (status.toUpperCase()) {
    case 'ONGOING':
    case 'SUBMITTED':
    case 'UNDER_REVIEW':
    case 'PENDING_APPROVAL':
      return (fg: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7));
    case 'COMPLETED':
    case 'APPROVED':
    case 'REVIEWED':
    case 'PUBLISHED':
    case 'PRESENT':
    case 'ISSUED':
    case 'ACTIVE':
    case 'LOCKED':
    case 'PASS':
      return (fg: const Color(0xFF059669), bg: const Color(0xFFD1FAE5));
    case 'CANCELLED':
    case 'ABSENT':
    case 'REVOKED':
    case 'CORRECTION_REQUIRED':
    case 'SENT_BACK':
    case 'FAIL':
      return (fg: const Color(0xFFDC2626), bg: const Color(0xFFFEE2E2));
    case 'NOT_STARTED':
      return (fg: const Color(0xFF475569), bg: const Color(0xFFE2E8F0));
    default:
      return (fg: const Color(0xFF2563EB), bg: const Color(0xFFDBEAFE));
  }
}

class ExamBadge extends StatelessWidget {
  final String label;
  final String? status;
  final Color? color;
  const ExamBadge(this.label, {super.key, this.status, this.color});

  @override
  Widget build(BuildContext context) {
    final style = examStatusStyle(status ?? label);
    final fg = color ?? style.fg;
    final bg = color != null ? color!.withValues(alpha: 0.14) : style.bg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.replaceAll('_', ' '),
        style: TextStyle(
          color: fg,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LAYOUT HELPERS
// ---------------------------------------------------------------------------
class ExamCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  const ExamCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dark = examIsDark(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (dark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}

class ExamPanelHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  const ExamPanelHeader({super.key, required this.title, this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final dark = examIsDark(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        spacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
            ],
          ),
          if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }
}

class ExamEmpty extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;
  const ExamEmpty({super.key, required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return ExamCard(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: [
          Icon(icon, size: 44, color: Colors.grey),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5)),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

class ExamLoading extends StatelessWidget {
  const ExamLoading({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
      );
}

class ExamErrorView extends StatelessWidget {
  final Object error;
  const ExamErrorView(this.error, {super.key});
  @override
  Widget build(BuildContext context) =>
      ExamNotice('Something went wrong: ${examErrorText(error)}');
}

/// Scrollable table with consistent styling.
class ExamTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final double? minWidth;
  const ExamTable({super.key, required this.columns, required this.rows, this.minWidth});

  @override
  Widget build(BuildContext context) {
    final dark = examIsDark(context);
    return ExamCard(
      padding: EdgeInsets.zero,
      child: Scrollbar(
        thumbVisibility: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth ?? 0),
            child: DataTable(
              headingRowHeight: 42,
              dataRowMinHeight: 46,
              dataRowMaxHeight: 64,
              columnSpacing: 22,
              horizontalMargin: 14,
              headingRowColor: WidgetStatePropertyAll(
                dark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              ),
              columns: columns
                  .map((c) => DataColumn(
                        label: Text(
                          c,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ))
                  .toList(),
              rows: rows
                  .map((r) => DataRow(
                        cells: r.map((w) => DataCell(w)).toList(),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SMALL DIALOGS
// ---------------------------------------------------------------------------
Future<bool> confirmExam(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirm',
  bool danger = false,
  IconData icon = Icons.help_outline,
}) async {
  final result = await showExamDialog<bool>(
    context,
    (ctx) => ExamDialogFrame(
      title: title,
      icon: danger ? Icons.warning_amber_rounded : icon,
      maxWidth: 460,
      actions: [
        ExamCancelButton(onPressed: () => Navigator.of(ctx).pop(false)),
        ExamPrimaryButton(
          label: confirmText,
          color: danger ? Colors.red.shade600 : null,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
      child: Text(message, style: const TextStyle(fontSize: 13.5, height: 1.4)),
    ),
  );
  return result ?? false;
}

/// Asks for a text (reason, comment). Returns null when cancelled.
Future<String?> askExamText(
  BuildContext context, {
  required String title,
  required String label,
  String? hint,
  String confirmText = 'Save',
  bool required = true,
  String initial = '',
  bool danger = false,
  String? message,
}) {
  final controller = TextEditingController(text: initial);
  final formKey = GlobalKey<FormState>();
  return showExamDialog<String>(
    context,
    (ctx) => ExamDialogFrame(
      title: title,
      icon: danger ? Icons.warning_amber_rounded : Icons.edit_note,
      maxWidth: 480,
      actions: [
        ExamCancelButton(onPressed: () => Navigator.of(ctx).pop()),
        ExamPrimaryButton(
          label: confirmText,
          color: danger ? Colors.red.shade600 : null,
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(ctx).pop(controller.text.trim());
            }
          },
        ),
      ],
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[
              Text(message, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
            ],
            ExamTextField(
              label: label,
              controller: controller,
              hint: hint,
              maxLines: 3,
              validator: (v) =>
                  required && (v == null || v.trim().isEmpty) ? 'This field is required.' : null,
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// FORMATTING
// ---------------------------------------------------------------------------
String examFmtMarks(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

String examFmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  try {
    final p = iso.split('-').map(int.parse).toList();
    return DateFormat('d MMM yyyy').format(DateTime(p[0], p[1], p[2]));
  } catch (_) {
    return iso;
  }
}

String examFmtDay(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final p = iso.split('-').map(int.parse).toList();
    return DateFormat('EEE').format(DateTime(p[0], p[1], p[2]));
  } catch (_) {
    return '';
  }
}

String examFmtTime(String t) {
  try {
    final p = t.split(':').map(int.parse).toList();
    return DateFormat('h:mm a').format(DateTime(2000, 1, 1, p[0], p[1]));
  } catch (_) {
    return t;
  }
}

/// Deterministic pseudo QR code (placeholder drawing, not scannable).
class ExamQrPlaceholder extends StatelessWidget {
  final String data;
  final double size;
  const ExamQrPlaceholder({super.key, required this.data, this.size = 84});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _QrPainter(data));
  }
}

class _QrPainter extends CustomPainter {
  final String data;
  _QrPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 21;
    final cell = size.width / n;
    final paint = Paint()..color = Colors.black;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    var seed = 0;
    for (final c in data.codeUnits) {
      seed = (seed * 31 + c) & 0x7fffffff;
    }
    bool inFinder(int x, int y) =>
        (x < 8 && y < 8) || (x >= n - 8 && y < 8) || (x < 8 && y >= n - 8);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (inFinder(x, y)) continue;
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        if ((seed >> 16) % 2 == 0) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
        }
      }
    }
    void finder(int ox, int oy) {
      canvas.drawRect(Rect.fromLTWH(ox * cell, oy * cell, 7 * cell, 7 * cell), paint);
      canvas.drawRect(
        Rect.fromLTWH((ox + 1) * cell, (oy + 1) * cell, 5 * cell, 5 * cell),
        Paint()..color = Colors.white,
      );
      canvas.drawRect(
        Rect.fromLTWH((ox + 2) * cell, (oy + 2) * cell, 3 * cell, 3 * cell),
        paint,
      );
    }

    finder(0, 0);
    finder(n - 7, 0);
    finder(0, n - 7);
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.data != data;
}

class ExamInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  const ExamInfoRow(this.label, this.value, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final dark = examIsDark(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Small icon button with a tooltip, used in table action cells.
class ExamIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  const ExamIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}
