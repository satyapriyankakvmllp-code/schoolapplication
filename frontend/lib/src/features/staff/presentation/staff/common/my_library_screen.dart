import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';
import 'package:frontend/src/themes/app_colors.dart';
import 'package:frontend/src/utils/dynamic_data_client.dart';
import '../../../application/staff_auth_controller.dart';

class MyLibraryScreen extends ConsumerStatefulWidget {
  final bool isDark;

  const MyLibraryScreen({
    super.key,
    this.isDark = false,
  });

  @override
  ConsumerState<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends ConsumerState<MyLibraryScreen> {
  late final List<Map<String, dynamic>> _myBooks;

  @override
  void initState() {
    super.initState();
    _myBooks = [
      {
        'accession': 'BK-MATH-401',
        'title': 'Advanced Engineering Mathematics (10th Edition)',
        'author': 'Erwin Kreyszig',
        'category': 'Mathematics Reference',
        'takenOn': '04 Oct 2026',
        'dueDate': '04 Nov 2026',
        'status': 'Issued',
        'color': const Color(0xFF109F83),
      },
      {
        'accession': 'BK-PED-102',
        'title': 'Effective Classroom Pedagogy & Cognitive Learning',
        'author': 'Dr. Anita Woolfolk',
        'category': 'Faculty Development',
        'takenOn': '12 Sep 2026',
        'dueDate': '12 Oct 2026',
        'status': 'Returned',
        'color': const Color(0xFF3B82F6),
      },
      {
        'accession': 'BK-SCI-884',
        'title': 'NCERT Exemplar Problems & Solutions: Class 10 & 12',
        'author': 'CBSE National Board',
        'category': 'Curriculum Reference',
        'takenOn': '18 Aug 2026',
        'dueDate': '18 Sep 2026',
        'status': 'Returned',
        'color': const Color(0xFF8B5CF6),
      },
    ];
    _loadSharedLibraryRecords();
  }

  Future<void> _loadSharedLibraryRecords() async {
    try {
      final records = await DynamicDataClient.instance.getAll(
        assetPath: 'assets/data/staff/staff_library.json',
        storageKey: 'edupulse_staff_library_records',
      );
      if (records.isNotEmpty && mounted) {
        final staff = ref.read(currentLoggedInStaffProvider);
        final staffRecords = records.where((r) => r['staff_id'] == staff?.id).toList();
        final effective = staffRecords.isNotEmpty ? staffRecords : records;
        setState(() {
          _myBooks.clear();
          for (final r in effective) {
            _myBooks.add({
              'accession': r['book_number'] ?? 'BK-LIB-001',
              'title': r['book_name'] ?? 'Academic Book',
              'author': r['author'] ?? 'Educational Publishing House',
              'category': r['book_category'] ?? 'Reference',
              'takenOn': r['taken_on'] ?? '01 Oct 2026',
              'dueDate': r['last_date'] ?? '01 Nov 2026',
              'status': r['status'] ?? 'Issued',
              'color': const Color(0xFF109F83),
            });
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentLoggedInStaffProvider);
    final dark = Theme.of(context).brightness == Brightness.dark || widget.isDark;

    final cardBg = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = dark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final isMobile = ResponsiveLayout.isMobile(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'My Library & Academic References',
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Borrowed institutional reference texts, research journals, and syllabus guides for ${staff?.fullName ?? 'Faculty'}',
            style: TextStyle(fontSize: 12, color: subColor),
          ),
          const SizedBox(height: 20),

          // Active Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book, color: AppColors.secondary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Circulation: 1 Volume Borrowed',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Borrowing Limit: Up to 5 books concurrently for permanent faculty',
                        style: TextStyle(fontSize: 11, color: subColor),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Renewal request dispatched to Chief Librarian Meenakshi Sundaram.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                  ),
                  child: const Text('Renew Active Book'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Books Roster
          Text(
            'Circulation History & Borrowing Log',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _myBooks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final book = _myBooks[index];
              final isIssued = book['status'] == 'Issued';
              final color = book['color'] as Color;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isIssued ? color.withValues(alpha: 0.5) : borderColor,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.book_outlined, color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  book['title'] as String,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isIssued
                                      ? AppColors.primary.withValues(alpha: 0.14)
                                      : AppColors.success.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  book['status'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isIssued ? AppColors.primary : AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Author: ${book['author']} • Section: ${book['category']}',
                            style: TextStyle(fontSize: 11, color: subColor),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Accession: ${book['accession']} • Borrowed: ${book['takenOn']} • Return Due: ${book['dueDate']}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
