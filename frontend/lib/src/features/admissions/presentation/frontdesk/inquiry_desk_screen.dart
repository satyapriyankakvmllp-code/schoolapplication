import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/frontdesk_controller.dart';
import '../../../staff/application/staff_auth_controller.dart';

class InquiryDeskScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final VoidCallback onConvertToApplication;

  const InquiryDeskScreen({
    super.key,
    required this.isDark,
    required this.onConvertToApplication,
  });

  @override
  ConsumerState<InquiryDeskScreen> createState() => _InquiryDeskScreenState();
}

class _InquiryDeskScreenState extends ConsumerState<InquiryDeskScreen> {
  String _selectedSourceFilter = 'All';
  String _selectedStatusFilter = 'All';
  String _searchQuery = '';
  bool _filterOnlyRemindersDue = false;

  void _showAddInquiryModal(BuildContext context) {
    final applicantCtrl = TextEditingController();
    final gradeCtrl = TextEditingController(text: 'Class 6');
    final parentCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+91 ');
    final emailCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    InquirySource source = InquirySource.walkIn;
    FrontDeskInquiry? duplicateWarning;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = widget.isDark;

            void checkDuplicates() {
              final dup = ref.read(frontDeskInquiriesProvider.notifier).checkDuplicateLead(
                    phone: phoneCtrl.text,
                    email: emailCtrl.text,
                  );
              setModalState(() => duplicateWarning = dup);
            }

            return Dialog(
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFFF59E0B)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Log New Admission Inquiry',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Record walk-in parent, telephone call or web referral lead',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Duplicate Lead Warning Card
                      if (duplicateWarning != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Potential Duplicate Lead Detected',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'An existing inquiry (${duplicateWarning!.id}) matches this contact: ${duplicateWarning!.applicantName} (${duplicateWarning!.gradeApplying}) by ${duplicateWarning!.parentName}.',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Applicant Name
                      Text('Applicant Student Name *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: applicantCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Advait Nair',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Grade & Source
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Grade Applying *',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: gradeCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Class 7',
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Inquiry Source',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<InquirySource>(
                                  initialValue: source,
                                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  items: InquirySource.values.map((s) {
                                    return DropdownMenuItem(value: s, child: Text(s.displayName, style: const TextStyle(fontSize: 12)));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => source = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Parent Name
                      Text('Parent / Guardian Name *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: parentCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Sunita Nair',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Phone & Email with duplicate checking
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Phone Number *',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  onChanged: (_) => checkDuplicates(),
                                  decoration: InputDecoration(
                                    hintText: '+91 98XXX XXXXX',
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Email Address',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  onChanged: (_) => checkDuplicates(),
                                  decoration: InputDecoration(
                                    hintText: 'parent@domain.com',
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Residential Area
                      Text('Residential Area / City',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: areaCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Whitefield, Bengaluru',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Remarks
                      Text('Inquiry Remarks & Notes',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g. Sibling transport routes, inquired regarding lab facilities',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Save Inquiry Record'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              if (applicantCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter applicant student name'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }
                              final newId = 'INQ-2026-${(DateTime.now().millisecondsSinceEpoch % 9000 + 1000)}';
                              ref.read(frontDeskInquiriesProvider.notifier).addInquiry(
                                    FrontDeskInquiry(
                                      id: newId,
                                      applicantName: applicantCtrl.text.trim(),
                                      gradeApplying: gradeCtrl.text.trim(),
                                      parentName: parentCtrl.text.trim().isEmpty ? 'Parent' : parentCtrl.text.trim(),
                                      parentPhone: phoneCtrl.text.trim(),
                                      parentEmail: emailCtrl.text.trim(),
                                      residentialArea: areaCtrl.text.trim(),
                                      source: source,
                                      status: InquiryStatus.newLead,
                                      notes: notesCtrl.text.trim().isEmpty ? 'Direct front-desk inquiry' : notesCtrl.text.trim(),
                                      createdAt: DateTime.now(),
                                    ),
                                  );
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Inquiry $newId recorded successfully!'),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFollowUpModal(BuildContext context, FrontDeskInquiry inq) {
    final noteCtrl = TextEditingController();
    String actionType = 'Phone Call';
    DateTime? reminderDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = widget.isDark;

            return Dialog(
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_toggle_off, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Follow-Up Timeline: ${inq.applicantName}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Existing Follow-Ups Timeline
                      if (inq.followUps.isNotEmpty) ...[
                        Text(
                          'Interaction History',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: inq.followUps.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final fu = inq.followUps[index];
                              return Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          fu.actionType,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3B82F6),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${fu.timestamp.day}/${fu.timestamp.month}/${fu.timestamp.year}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      fu.notes,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                                      ),
                                    ),
                                    if (fu.reminderDate != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.alarm, size: 12, color: Color(0xFFF59E0B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Reminder: ${fu.reminderDate!.day}/${fu.reminderDate!.month}/${fu.reminderDate!.year}',
                                            style: const TextStyle(fontSize: 10, color: Color(0xFFF59E0B)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(height: 24),
                      ],

                      Text(
                        'Log New Follow-Up Action',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        initialValue: actionType,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        decoration: InputDecoration(
                          labelText: 'Action Type',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: ['Phone Call', 'Walk-In Meeting', 'Email Sent', 'Campus Tour', 'SMS Reminder'].map((t) {
                          return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => actionType = val);
                        },
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: noteCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Follow-Up Notes *',
                          hintText: 'e.g. Parent requested brochure by email and confirmed attendance',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Reminder Picker
                      Text(
                        'Set Callback Reminder Date (Optional):',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Today', style: TextStyle(fontSize: 11)),
                            selected: reminderDate != null &&
                                DateUtils.isSameDay(reminderDate, DateTime.now()),
                            selectedColor: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                            onSelected: (_) {
                              final n = DateTime.now();
                              setModalState(() => reminderDate = DateTime(n.year, n.month, n.day, 18, 0));
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Tomorrow', style: TextStyle(fontSize: 11)),
                            selected: reminderDate != null &&
                                DateUtils.isSameDay(
                                    reminderDate, DateTime.now().add(const Duration(days: 1))),
                            selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                            onSelected: (_) {
                              final n = DateTime.now().add(const Duration(days: 1));
                              setModalState(() => reminderDate = DateTime(n.year, n.month, n.day, 11, 0));
                            },
                          ),
                          ChoiceChip(
                            label: const Text('In 3 Days', style: TextStyle(fontSize: 11)),
                            selected: reminderDate != null &&
                                DateUtils.isSameDay(
                                    reminderDate, DateTime.now().add(const Duration(days: 3))),
                            selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                            onSelected: (_) {
                              final n = DateTime.now().add(const Duration(days: 3));
                              setModalState(() => reminderDate = DateTime(n.year, n.month, n.day, 11, 0));
                            },
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_month, size: 13),
                            label: Text(
                              reminderDate == null
                                  ? 'Custom Date...'
                                  : '${reminderDate!.day}/${reminderDate!.month}/${reminderDate!.year}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            onPressed: () async {
                              final n = DateTime.now();
                              final today = DateTime(n.year, n.month, n.day);
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: reminderDate ?? today,
                                firstDate: today.subtract(const Duration(days: 7)),
                                lastDate: today.add(const Duration(days: 120)),
                              );
                              if (picked != null) {
                                setModalState(() => reminderDate = DateTime(picked.year, picked.month, picked.day, 12, 0));
                              }
                            },
                          ),
                          if (reminderDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: Colors.redAccent),
                              tooltip: 'Clear Reminder',
                              onPressed: () => setModalState(() => reminderDate = null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Close'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Add Log Entry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              if (noteCtrl.text.trim().isEmpty) return;
                              final loggedInOfficer = ref.read(currentLoggedInStaffProvider)?.fullName ?? 'Front Desk Staff';
                              final newFu = InquiryFollowUp(
                                id: 'FU-${DateTime.now().millisecondsSinceEpoch % 10000}',
                                timestamp: DateTime.now(),
                                actionType: actionType,
                                officerName: loggedInOfficer,
                                notes: noteCtrl.text.trim(),
                                reminderDate: reminderDate,
                              );
                              ref.read(frontDeskInquiriesProvider.notifier).addFollowUp(inq.id, newFu);
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Follow-up logged and saved to records!'),
                                  backgroundColor: Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final inquiries = ref.watch(frontDeskInquiriesProvider);
    final isDark = widget.isDark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final dueTodayOrOverdueCount = inquiries.where((inq) {
      if (inq.status == InquiryStatus.converted || inq.status == InquiryStatus.closed) return false;
      return inq.followUps.any((fu) {
        if (fu.reminderDate == null) return false;
        final r = fu.reminderDate!.isUtc ? fu.reminderDate!.toLocal() : fu.reminderDate!;
        return !r.isAfter(todayEnd);
      });
    }).length;

    final filtered = inquiries.where((inq) {
      final matchesSearch = inq.applicantName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inq.parentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inq.parentPhone.contains(_searchQuery) ||
          inq.id.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesSource = _selectedSourceFilter == 'All' || inq.source.displayName == _selectedSourceFilter;
      final matchesStatus = _filterOnlyRemindersDue || _selectedStatusFilter == 'All' || inq.status.displayName == _selectedStatusFilter;

      final matchesReminders = !_filterOnlyRemindersDue ||
          (inq.status != InquiryStatus.converted &&
              inq.status != InquiryStatus.closed &&
              inq.followUps.any((fu) {
                if (fu.reminderDate == null) return false;
                final r = fu.reminderDate!.isUtc ? fu.reminderDate!.toLocal() : fu.reminderDate!;
                return !r.isAfter(todayEnd);
              }));

      return matchesSearch && matchesSource && matchesStatus && matchesReminders;
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admission Inquiries & Walk-In Desk',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Log and manage incoming parent inquiries, calls, pipeline and prospective leads',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text(isMobile ? 'New' : 'Log New Inquiry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showAddInquiryModal(context),
              ),
            ],
          ),

          // Proactive Callback Reminders Banner
          if (dueTodayOrOverdueCount > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alarm_on_rounded, color: Color(0xFFB45309), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Attention: $dueTodayOrOverdueCount parent follow-up callback(s) are due today or pending!',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      _filterOnlyRemindersDue ? Icons.close : Icons.filter_list,
                      size: 14,
                      color: const Color(0xFFB45309),
                    ),
                    label: Text(
                      _filterOnlyRemindersDue ? 'Show All' : 'Filter Due Calls',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                    ),
                    onPressed: () {
                      setState(() => _filterOnlyRemindersDue = !_filterOnlyRemindersDue);
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Search and Filters Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131D31) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Search inquiries by ID, student name, parent, phone...',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0C1424) : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),

                // Status Filter Chips
                Text('Status Pipeline Filter:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Due Callbacks Special Chip
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          avatar: Icon(Icons.alarm, size: 14, color: _filterOnlyRemindersDue ? Colors.white : const Color(0xFFEF4444)),
                          label: Text('Due Reminders ($dueTodayOrOverdueCount)'),
                          selected: _filterOnlyRemindersDue,
                          selectedColor: const Color(0xFFEF4444),
                          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _filterOnlyRemindersDue ? Colors.white : const Color(0xFFEF4444),
                          ),
                          onSelected: (val) => setState(() => _filterOnlyRemindersDue = val),
                        ),
                      ),
                      ...[
                        'All',
                        'New Inquiry',
                        'Contacted',
                        'Interview Booked',
                        'Application Started',
                        'Converted to Application',
                        'Closed / Archived'
                      ].map((status) {
                        final isSelected = !_filterOnlyRemindersDue && _selectedStatusFilter == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(status),
                            selected: isSelected,
                            selectedColor: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFFF59E0B) : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            onSelected: (_) {
                              setState(() {
                                _filterOnlyRemindersDue = false;
                                _selectedStatusFilter = status;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Source Filter Chips
                Text('Lead Source:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Walk-In', 'Phone Call', 'Website Lead', 'Parent Referral'].map((source) {
                      final isSelected = _selectedSourceFilter == source;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(source),
                          selected: isSelected,
                          selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF3B82F6) : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          onSelected: (_) => setState(() => _selectedSourceFilter = source),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Inquiries List
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D31) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 40, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No inquiries matching your criteria'),
                ],
              ),
            )
          else
            ...filtered.map((inq) => _buildInquiryCard(inq, isMobile, isDark)),
        ],
      ),
    );
  }

  Widget _buildInquiryCard(FrontDeskInquiry inq, bool isMobile, bool isDark) {
    Color statusColor;
    switch (inq.status) {
      case InquiryStatus.newLead:
        statusColor = const Color(0xFFF59E0B);
        break;
      case InquiryStatus.contacted:
        statusColor = const Color(0xFF3B82F6);
        break;
      case InquiryStatus.interviewScheduled:
        statusColor = const Color(0xFF8B5CF6);
        break;
      case InquiryStatus.applicationStarted:
        statusColor = const Color(0xFFEC4899);
        break;
      case InquiryStatus.converted:
        statusColor = const Color(0xFF10B981);
        break;
      case InquiryStatus.closed:
      case InquiryStatus.dropped:
        statusColor = const Color(0xFF64748B);
        break;
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final reminders = inq.followUps.where((fu) => fu.reminderDate != null).toList();

    // Priority 1: Check if there's any active reminder that is Due Today or Overdue
    InquiryFollowUp? activeReminder;
    final dueOrOverdue = reminders.where((fu) {
      final r = fu.reminderDate!.isUtc ? fu.reminderDate!.toLocal() : fu.reminderDate!;
      return !r.isAfter(todayEnd) && inq.status != InquiryStatus.converted && inq.status != InquiryStatus.closed;
    }).toList();

    if (dueOrOverdue.isNotEmpty) {
      activeReminder = dueOrOverdue.first;
    } else if (reminders.isNotEmpty) {
      activeReminder = reminders.first;
    }

    final isOverdue = activeReminder != null &&
        (activeReminder.reminderDate!.isUtc ? activeReminder.reminderDate!.toLocal() : activeReminder.reminderDate!).isBefore(todayStart) &&
        inq.status != InquiryStatus.converted &&
        inq.status != InquiryStatus.closed;

    final isDueToday = activeReminder != null &&
        !(activeReminder.reminderDate!.isUtc ? activeReminder.reminderDate!.toLocal() : activeReminder.reminderDate!).isBefore(todayStart) &&
        !(activeReminder.reminderDate!.isUtc ? activeReminder.reminderDate!.toLocal() : activeReminder.reminderDate!).isAfter(todayEnd) &&
        inq.status != InquiryStatus.converted &&
        inq.status != InquiryStatus.closed;

    final isUpcoming = activeReminder != null &&
        (activeReminder.reminderDate!.isUtc ? activeReminder.reminderDate!.toLocal() : activeReminder.reminderDate!).isAfter(todayEnd) &&
        inq.status != InquiryStatus.converted &&
        inq.status != InquiryStatus.closed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Line: ID, Source, Status Dropdown
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inq.id,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inq.source.displayName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
              // Status Dropdown Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<InquiryStatus>(
                    value: inq.status,
                    isDense: true,
                    icon: Icon(Icons.arrow_drop_down, color: statusColor, size: 16),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    items: [
                      InquiryStatus.newLead,
                      InquiryStatus.contacted,
                      InquiryStatus.interviewScheduled,
                      InquiryStatus.applicationStarted,
                      InquiryStatus.converted,
                      InquiryStatus.closed,
                    ].map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(
                          s.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        ref.read(frontDeskInquiriesProvider.notifier).updateStatus(inq.id, newStatus);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          if (activeReminder != null && (isOverdue || isDueToday || isUpcoming)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isOverdue
                    ? const Color(0xFFFEF2F2)
                    : isDueToday
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOverdue
                      ? const Color(0xFFEF4444)
                      : isDueToday
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF3B82F6).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isOverdue
                        ? Icons.warning_amber_rounded
                        : isDueToday
                            ? Icons.alarm_on_rounded
                            : Icons.calendar_today_outlined,
                    size: 14,
                    color: isOverdue
                        ? const Color(0xFFDC2626)
                        : isDueToday
                            ? const Color(0xFFD97706)
                            : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOverdue
                          ? '⚠️ OVERDUE CALLBACK: Was scheduled for ${activeReminder.reminderDate!.day}/${activeReminder.reminderDate!.month}/${activeReminder.reminderDate!.year}'
                          : isDueToday
                              ? '🔔 CALLBACK DUE TODAY: ${activeReminder.notes}'
                              : '⏰ Scheduled Follow-Up: ${activeReminder.reminderDate!.day}/${activeReminder.reminderDate!.month}/${activeReminder.reminderDate!.year}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isOverdue
                            ? const Color(0xFF991B1B)
                            : isDueToday
                                ? const Color(0xFF92400E)
                                : const Color(0xFF1E40AF),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Applicant & Grade
          Text(
            inq.applicantName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Target Grade: ${inq.gradeApplying} • Parent: ${inq.parentName} (${inq.parentPhone})',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          if (inq.residentialArea.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Location: ${inq.residentialArea}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF64748B) : Colors.grey.shade600,
              ),
            ),
          ],

          // Notes
          if (inq.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0C1424) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sticky_note_2_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      inq.notes,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Action Buttons: Follow-Ups & Convert to Application
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.history_edu_outlined, size: 14),
                label: Text(
                  inq.followUps.isEmpty ? 'Log Follow-Up' : 'Timeline (${inq.followUps.length})',
                  style: const TextStyle(fontSize: 11),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3B82F6),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () => _showFollowUpModal(context, inq),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 14),
                label: const Text('Convert to Application', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  ref.read(frontDeskInquiriesProvider.notifier).updateStatus(inq.id, InquiryStatus.converted);
                  ref.read(frontDeskDraftInquiryProvider.notifier).state = inq;
                  widget.onConvertToApplication();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
