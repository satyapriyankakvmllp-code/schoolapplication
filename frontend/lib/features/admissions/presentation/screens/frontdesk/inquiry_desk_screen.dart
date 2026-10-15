import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/frontdesk_controller.dart';

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
  String _searchQuery = '';

  void _showAddInquiryModal(BuildContext context) {
    final applicantCtrl = TextEditingController();
    final gradeCtrl = TextEditingController(text: 'Class 6');
    final parentCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+91 ');
    final emailCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    InquirySource source = InquirySource.walkIn;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = widget.isDark;

            return Dialog(
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 540),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                  'Record walk-in parent, telephone call or referral lead',
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
                      const SizedBox(height: 20),
                      Text('Applicant Student Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
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
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Grade Applying *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
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
                                Text('Inquiry Source', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
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
                      Text('Parent / Guardian Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
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
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Phone Number *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: phoneCtrl,
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
                                Text('Email Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: emailCtrl,
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
                      Text('Inquiry Remarks & Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g. Wants sibling bus route, inquired regarding lab facilities',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                              if (applicantCtrl.text.trim().isEmpty) return;
                              final newId = 'INQ-2026-${(DateTime.now().millisecondsSinceEpoch % 9000 + 1000)}';
                              ref.read(frontDeskInquiriesProvider.notifier).addInquiry(
                                    FrontDeskInquiry(
                                      id: newId,
                                      applicantName: applicantCtrl.text.trim(),
                                      gradeApplying: gradeCtrl.text.trim(),
                                      parentName: parentCtrl.text.trim().isEmpty ? 'Parent' : parentCtrl.text.trim(),
                                      parentPhone: phoneCtrl.text.trim(),
                                      parentEmail: emailCtrl.text.trim(),
                                      source: source,
                                      status: InquiryStatus.newLead,
                                      notes: notesCtrl.text.trim().isEmpty ? 'Direct front desk inquiry' : notesCtrl.text.trim(),
                                      createdAt: DateTime.now(),
                                    ),
                                  );
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Inquiry $newId logged successfully!'),
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

  @override
  Widget build(BuildContext context) {
    final inquiries = ref.watch(frontDeskInquiriesProvider);
    final isDark = widget.isDark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    final filtered = inquiries.where((inq) {
      final matchesSearch = inq.applicantName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inq.parentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inq.parentPhone.contains(_searchQuery);
      if (_selectedSourceFilter == 'All') return matchesSearch;
      return matchesSearch && inq.source.displayName == _selectedSourceFilter;
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                      'Log and manage incoming parent inquiries, calls, and prospective leads',
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
          const SizedBox(height: 20),

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
                    hintText: 'Search inquiries by student name, parent, phone...',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0C1424) : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Walk-In', 'Phone Call', 'Website Lead', 'Parent Referral'].map((source) {
                      final isSelected = _selectedSourceFilter == source;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(source),
                          selected: isSelected,
                          selectedColor: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFFF59E0B) : (isDark ? Colors.white70 : Colors.black87),
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
          const SizedBox(height: 20),

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
          Row(
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
              const SizedBox(width: 8),
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
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inq.status.displayName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 14),
                label: const Text('Convert to Application', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
