import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../classes/presentation/widgets/classes_ui.dart';
import '../application/fees_controller.dart';
import '../data/fees_repository.dart';
import '../domain/fee_structure.dart';
import '../domain/fees_calculator.dart';
import '../domain/money.dart';

/// Right-side panel on desktop/tablet, full-screen on mobile.
/// Allows creating, editing, and inspecting a FeeStructure with live total calculation.
class FeeStructureFormPanel extends ConsumerStatefulWidget {
  final FeeStructure? existing;
  final bool isViewOnly;
  final VoidCallback onClose;
  final ValueChanged<FeeStructure>? onSaved;

  const FeeStructureFormPanel({
    super.key,
    this.existing,
    this.isViewOnly = false,
    required this.onClose,
    this.onSaved,
  });

  @override
  ConsumerState<FeeStructureFormPanel> createState() =>
      _FeeStructureFormPanelState();
}

class _FeeStructureFormPanelState extends ConsumerState<FeeStructureFormPanel> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedClass;
  String _selectedTerm = 'Term 1';
  String _selectedAcademicYear = '2026-2027';
  String _dueDate = '';
  bool _isActive = true;

  late final TextEditingController _tuitionController;
  late final TextEditingController _labComputerController;
  late final TextEditingController _developmentController;
  late final TextEditingController _otherController;

  bool _isSaving = false;
  String? _errorMessage;

  static const List<String> _terms = ['Term 1', 'Term 2', 'Term 3'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _selectedClass = e.className;
      _selectedTerm = e.termName.isNotEmpty ? e.termName : 'Term 1';
      _selectedAcademicYear = e.academicYear.isNotEmpty ? e.academicYear : '2026-2027';
      _dueDate = e.dueDate;
      _isActive = e.isActive;
      _tuitionController = TextEditingController(
        text: e.tuitionFee > 0 ? e.tuitionFee.toStringAsFixed(0) : '',
      );
      _labComputerController = TextEditingController(
        text: e.labComputerFee > 0 ? e.labComputerFee.toStringAsFixed(0) : '0',
      );
      _developmentController = TextEditingController(
        text: e.developmentFee > 0 ? e.developmentFee.toStringAsFixed(0) : '0',
      );
      _otherController = TextEditingController(
        text: e.otherFee > 0 ? e.otherFee.toStringAsFixed(0) : '0',
      );
    } else {
      _dueDate = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 30)));
      _tuitionController = TextEditingController();
      _labComputerController = TextEditingController(text: '0');
      _developmentController = TextEditingController(text: '0');
      _otherController = TextEditingController(text: '0');
    }

    _tuitionController.addListener(_onAmountChanged);
    _labComputerController.addListener(_onAmountChanged);
    _developmentController.addListener(_onAmountChanged);
    _otherController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _tuitionController.dispose();
    _labComputerController.dispose();
    _developmentController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  double _getCalculatedTotalRupees() {
    final tuition = double.tryParse(_tuitionController.text.trim()) ?? 0.0;
    final lab = double.tryParse(_labComputerController.text.trim()) ?? 0.0;
    final dev = double.tryParse(_developmentController.text.trim()) ?? 0.0;
    final other = double.tryParse(_otherController.text.trim()) ?? 0.0;

    return FeesCalculator.calculateStructureTotalRupees(
      tuition: tuition,
      labComputer: lab,
      development: dev,
      other: other,
    );
  }

  Future<void> _pickDueDate() async {
    if (widget.isViewOnly) return;
    DateTime initial = DateTime.tryParse(_dueDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF109F83),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dueDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _errorMessage = null);

    if (_selectedClass == null || _selectedClass!.trim().isEmpty) {
      setState(() => _errorMessage = 'Please select a Class.');
      return;
    }
    if (_dueDate.trim().isEmpty) {
      setState(() => _errorMessage = 'Please specify a Due Date.');
      return;
    }

    final tuition = double.tryParse(_tuitionController.text.trim()) ?? 0.0;
    if (tuition <= 0) {
      setState(() => _errorMessage = 'Tuition fee must be greater than 0.');
      return;
    }

    final lab = double.tryParse(_labComputerController.text.trim()) ?? 0.0;
    final dev = double.tryParse(_developmentController.text.trim()) ?? 0.0;
    final other = double.tryParse(_otherController.text.trim()) ?? 0.0;

    if (lab < 0 || dev < 0 || other < 0) {
      setState(() => _errorMessage = 'Fee components cannot be negative.');
      return;
    }

    final total = FeesCalculator.calculateStructureTotalRupees(
      tuition: tuition,
      labComputer: lab,
      development: dev,
      other: other,
    );

    final isNew = widget.existing == null;
    final structure = FeeStructure(
      id: widget.existing?.id ?? '',
      className: _selectedClass!.trim(),
      termName: _selectedTerm.trim(),
      academicYear: _selectedAcademicYear.trim(),
      tuitionFee: tuition,
      labComputerFee: lab,
      developmentFee: dev,
      otherFee: other,
      totalFee: total,
      dueDate: _dueDate.trim(),
      isActive: _isActive,
      createdAt: widget.existing?.createdAt ?? '',
      updatedAt: DateTime.now().toIso8601String(),
    );

    setState(() => _isSaving = true);

    try {
      final saved = await ref.read(feeStructuresControllerProvider.notifier).save(
            structure,
            isNew: isNew,
          );
      if (mounted) {
        showCompactSnackBar(
          context,
          isNew
              ? 'Fee structure created successfully.'
              : 'Fee structure updated successfully.',
        );
        widget.onSaved?.call(saved);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e
              .toString()
              .replaceAll('Exception:', '')
              .replaceAll('FeesValidationException:', '')
              .trim();
        });
        showCompactSnackBar(
          context,
          _errorMessage!,
          backgroundColor: Colors.red.shade700,
          icon: Icons.error_outline,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final availableClassesAsync = ref.watch(feeAvailableClassesProvider);
    final academicYearsAsync = ref.watch(feeAcademicYearsProvider);
    final isNew = widget.existing == null;
    final title = widget.isViewOnly
        ? 'Fee Structure Details'
        : (isNew ? 'Create Fee Structure' : 'Edit Fee Structure');

    final calculatedTotal = _getCalculatedTotalRupees();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF109F83).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFF109F83),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        widget.isViewOnly
                            ? 'Inspection of class fee components'
                            : 'Configure term fee components and due dates',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close Panel',
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Scrollable Form Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Section 1: Academic Scope
                    _buildSectionHeader('ACADEMIC SCOPE', isDark),
                    const SizedBox(height: 12),

                    // Class Dropdown
                    availableClassesAsync.when(
                      data: (classes) {
                        final items = classes.isNotEmpty
                            ? classes
                            : ['Class 10', 'Class 11', 'Class 12'];
                        if (_selectedClass == null && items.isNotEmpty) {
                          _selectedClass = items.first;
                        }
                        return DropdownButtonFormField<String>(
                          value: items.contains(_selectedClass) ? _selectedClass : items.firstOrNull,
                          decoration: _inputDecoration(
                            labelText: 'Class *',
                            prefixIcon: Icons.class_outlined,
                            isDark: isDark,
                          ),
                          items: items.map((c) {
                            return DropdownMenuItem<String>(
                              value: c,
                              child: Text(c),
                            );
                          }).toList(),
                          onChanged: widget.isViewOnly
                              ? null
                              : (v) => setState(() => _selectedClass = v),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => TextFormField(
                        initialValue: _selectedClass ?? 'Class 10',
                        readOnly: widget.isViewOnly,
                        decoration: _inputDecoration(
                          labelText: 'Class *',
                          prefixIcon: Icons.class_outlined,
                          isDark: isDark,
                        ),
                        onChanged: (v) => _selectedClass = v,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Term and Academic Year Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedTerm,
                            decoration: _inputDecoration(
                              labelText: 'Term *',
                              prefixIcon: Icons.calendar_view_day_outlined,
                              isDark: isDark,
                            ),
                            items: _terms.map((t) {
                              return DropdownMenuItem(value: t, child: Text(t));
                            }).toList(),
                            onChanged: widget.isViewOnly
                                ? null
                                : (v) {
                                    if (v != null) setState(() => _selectedTerm = v);
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: academicYearsAsync.when(
                            data: (years) {
                              final list = years.isNotEmpty
                                  ? years
                                  : ['2025-2026', '2026-2027', '2027-2028'];
                              final val = list.contains(_selectedAcademicYear)
                                  ? _selectedAcademicYear
                                  : list.first;
                              return DropdownButtonFormField<String>(
                                value: val,
                                decoration: _inputDecoration(
                                  labelText: 'Academic Year *',
                                  prefixIcon: Icons.school_outlined,
                                  isDark: isDark,
                                ),
                                items: list.map((y) {
                                  return DropdownMenuItem(value: y, child: Text(y));
                                }).toList(),
                                onChanged: widget.isViewOnly
                                    ? null
                                    : (v) {
                                        if (v != null) setState(() => _selectedAcademicYear = v);
                                      },
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (_, __) => DropdownButtonFormField<String>(
                              value: _selectedAcademicYear,
                              decoration: _inputDecoration(
                                labelText: 'Academic Year *',
                                prefixIcon: Icons.school_outlined,
                                isDark: isDark,
                              ),
                              items: const [
                                DropdownMenuItem(value: '2026-2027', child: Text('2026-2027')),
                              ],
                              onChanged: widget.isViewOnly
                                  ? null
                                  : (v) {
                                      if (v != null) setState(() => _selectedAcademicYear = v);
                                    },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Fee Breakdown
                    _buildSectionHeader('FEE COMPONENTS (IN RUPEES)', isDark),
                    const SizedBox(height: 12),

                    // Tuition Fee
                    TextFormField(
                      controller: _tuitionController,
                      readOnly: widget.isViewOnly,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration(
                        labelText: 'Tuition Fee (₹) *',
                        prefixIcon: Icons.menu_book_outlined,
                        helperText: 'Primary academic and curriculum fee (Required > 0)',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Lab / Computer Fee
                    TextFormField(
                      controller: _labComputerController,
                      readOnly: widget.isViewOnly,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration(
                        labelText: 'Lab & Computer Fee (₹)',
                        prefixIcon: Icons.computer_outlined,
                        helperText: 'IT infrastructure and science lab charges',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Development Fee
                    TextFormField(
                      controller: _developmentController,
                      readOnly: widget.isViewOnly,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration(
                        labelText: 'Development Fee (₹)',
                        prefixIcon: Icons.domain_outlined,
                        helperText: 'School campus and sports amenities upkeep',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Other Fee
                    TextFormField(
                      controller: _otherController,
                      readOnly: widget.isViewOnly,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration(
                        labelText: 'Other / Exam Charges (₹)',
                        prefixIcon: Icons.receipt_long_outlined,
                        helperText: 'Miscellaneous co-curricular activity fee',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Total Calculation Banner (Auto, Read-Only)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF109F83).withValues(alpha: 0.25),
                                  const Color(0xFF0F172A),
                                ]
                              : [
                                  const Color(0xFF109F83).withValues(alpha: 0.12),
                                  const Color(0xFFF0FDF4),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF109F83).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL TERM FEE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: Color(0xFF109F83),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Auto-calculated sum (read-only)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            Money.formatRupees(calculatedTotal),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF109F83),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Schedule & Lifecycle
                    _buildSectionHeader('DUE DATE & LIFECYCLE', isDark),
                    const SizedBox(height: 12),

                    // Due Date Picker Field
                    InkWell(
                      onTap: widget.isViewOnly ? null : _pickDueDate,
                      borderRadius: BorderRadius.circular(8),
                      child: IgnorePointer(
                        child: TextFormField(
                          key: ValueKey(_dueDate),
                          initialValue: _dueDate,
                          decoration: _inputDecoration(
                            labelText: 'Due Date *',
                            prefixIcon: Icons.calendar_today_outlined,
                            helperText: 'Last date for invoice clearance without fine',
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Status Switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
                            color: _isActive ? const Color(0xFF109F83) : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isActive ? 'Active Structure' : 'Inactive Structure',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  _isActive
                                      ? 'Applicable to new invoice generation'
                                      : 'Archived; preserved for historical invoices',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!widget.isViewOnly)
                            Switch.adaptive(
                              value: _isActive,
                              activeColor: const Color(0xFF109F83),
                              onChanged: (val) => setState(() => _isActive = val),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: widget.onClose,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    widget.isViewOnly ? 'Close' : 'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ),
                if (!widget.isViewOnly) ...[
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF109F83),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isNew ? 'Create Structure' : 'Save Changes'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? helperText,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: labelText,
      helperText: helperText,
      prefixIcon: Icon(prefixIcon, size: 18, color: const Color(0xFF109F83)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF109F83), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

/// Helper function to display the FeeStructureFormPanel as a smooth right-side sheet on
/// desktop/tablet or full screen on mobile.
Future<void> showFeeStructurePanel({
  required BuildContext context,
  FeeStructure? existing,
  bool isViewOnly = false,
  VoidCallback? onRefresh,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss Fee Structure Panel',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, anim1, anim2) {
      final width = MediaQuery.sizeOf(ctx).width;
      final isMobile = width < 768;
      return Align(
        alignment: isMobile ? Alignment.center : Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: isMobile ? width : 520,
            height: double.infinity,
            child: SafeArea(
              child: FeeStructureFormPanel(
                existing: existing,
                isViewOnly: isViewOnly,
                onClose: () => Navigator.of(ctx).pop(),
                onSaved: (_) {
                  Navigator.of(ctx).pop();
                  onRefresh?.call();
                },
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim1, anim2, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

