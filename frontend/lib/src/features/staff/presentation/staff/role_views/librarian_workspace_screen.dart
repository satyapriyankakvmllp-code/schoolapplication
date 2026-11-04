import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';
import 'package:frontend/src/themes/app_colors.dart';
import 'package:frontend/src/utils/dynamic_data_client.dart';
import '../../../application/staff_auth_controller.dart';

class LibrarianWorkspaceScreen extends ConsumerStatefulWidget {
  final bool isDark;

  const LibrarianWorkspaceScreen({
    super.key,
    this.isDark = false,
  });

  @override
  ConsumerState<LibrarianWorkspaceScreen> createState() => _LibrarianWorkspaceScreenState();
}

class _LibrarianWorkspaceScreenState extends ConsumerState<LibrarianWorkspaceScreen> {
  final _searchCtrl = TextEditingController();
  final _borrowerCtrl = TextEditingController(text: 'Aarav Sharma (STU-2026-001)');
  final _bookTitleCtrl = TextEditingController(text: 'Brief Answers to the Big Questions');
  final _accessionCtrl = TextEditingController(text: 'BK-SCI-902');

  final List<Map<String, dynamic>> _circulationDesk = [
    {'acc': 'BK-MATH-401', 'title': 'Advanced Engineering Mathematics', 'borrower': 'Dr. Rajeshwari (Faculty)', 'dueDate': '04 Nov 2026', 'status': 'Issued'},
    {'acc': 'BK-LIT-204', 'title': 'The Great Gatsby', 'borrower': 'Diya Patel (Grade 10-A)', 'dueDate': '24 Oct 2026', 'status': 'Issued'},
    {'acc': 'BK-HIST-112', 'title': 'India After Gandhi (Ramachandra Guha)', 'borrower': 'Rohan Verma (Grade 10-A)', 'dueDate': '18 Oct 2026', 'status': 'Overdue'},
    {'acc': 'BK-CS-505', 'title': 'Introduction to Algorithms (CLRS)', 'borrower': 'Kalyan Iyer (Faculty)', 'dueDate': '28 Oct 2026', 'status': 'Issued'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCirculationRecords();
  }

  Future<void> _loadCirculationRecords() async {
    try {
      final records = await DynamicDataClient.instance.getAll(
        assetPath: 'assets/data/staff/staff_library.json',
        storageKey: 'edupulse_staff_library_records',
      );
      if (records.isNotEmpty && mounted) {
        setState(() {
          for (final r in records.take(6)) {
            _circulationDesk.insert(0, {
              'acc': r['book_number'] ?? 'BK-ACC-001',
              'title': r['book_name'] ?? 'Library Text',
              'borrower': 'Faculty Borrower',
              'dueDate': r['last_date'] ?? '04 Nov 2026',
              'status': r['status'] ?? 'Issued',
            });
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _borrowerCtrl.dispose();
    _bookTitleCtrl.dispose();
    _accessionCtrl.dispose();
    super.dispose();
  }

  void _issueBook() {
    if (_borrowerCtrl.text.isEmpty || _bookTitleCtrl.text.isEmpty) return;

    final acc = _accessionCtrl.text.isNotEmpty ? _accessionCtrl.text : 'BK-NEW-101';
    final title = _bookTitleCtrl.text;
    final borrower = _borrowerCtrl.text;

    setState(() {
      _circulationDesk.insert(0, {
        'acc': acc,
        'title': title,
        'borrower': borrower,
        'dueDate': '04 Nov 2026',
        'status': 'Issued',
      });
    });

    try {
      DynamicDataClient.instance.getAll(
        assetPath: 'assets/data/staff/staff_library.json',
        storageKey: 'edupulse_staff_library_records',
      ).then((records) {
        records.insert(0, {
          'id': 'bk-${DateTime.now().millisecondsSinceEpoch}',
          'sl': '${records.length + 1}',
          'book_name': title,
          'book_category': 'General Circulation',
          'book_number': acc,
          'taken_on': 'Today',
          'last_date': '04 Nov 2026',
          'status': 'Issued',
          'staff_id': '',
          'cover_color_hex': '0xFF109F83',
        });
        DynamicDataClient.instance.syncAll(
          assetPath: 'assets/data/staff/staff_library.json',
          storageKey: 'edupulse_staff_library_records',
          items: records,
        );
      });
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Book "$title" issued to $borrower!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withValues(alpha: dark ? 0.25 : 0.12),
                  cardBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 24 : 32,
                  backgroundColor: const Color(0xFF8B5CF6),
                  child: const Icon(Icons.local_library, color: Colors.white, size: 28),
                ),
                SizedBox(width: isMobile ? 12 : 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Library Circulation & Archival Desk',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'LIBRARIAN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chief Librarian: ${staff?.fullName ?? 'Meenakshi Sundaram'} • Accession cataloging, circulation & returns',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Library KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final kpiTotal = _buildKpiCard('Total Volumes', '14,850', const Color(0xFF8B5CF6), Icons.menu_book, cardBg, borderColor, dark);
              final kpiIssued = _buildKpiCard('Active Borrowed', '342', AppColors.primary, Icons.bookmark_added_outlined, cardBg, borderColor, dark);
              final kpiOverdue = _buildKpiCard('Overdue Fines', '18 Books', AppColors.error, Icons.alarm_outlined, cardBg, borderColor, dark);
              final kpiMembers = _buildKpiCard('Cardholders', '1,120', AppColors.success, Icons.badge_outlined, cardBg, borderColor, dark);

              if (isNarrow) {
                return Column(
                  children: [
                    Row(children: [Expanded(child: kpiTotal), const SizedBox(width: 10), Expanded(child: kpiIssued)]),
                    const SizedBox(height: 10),
                    Row(children: [Expanded(child: kpiOverdue), const SizedBox(width: 10), Expanded(child: kpiMembers)]),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: kpiTotal),
                  const SizedBox(width: 12),
                  Expanded(child: kpiIssued),
                  const SizedBox(width: 12),
                  Expanded(child: kpiOverdue),
                  const SizedBox(width: 12),
                  Expanded(child: kpiMembers),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Issue / Return Form
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_shopping_cart, color: Color(0xFF8B5CF6), size: 20),
                    const SizedBox(width: 8),
                    Text('Circulation Issue Desk (Borrower Book Checkout)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 650;
                    final borrowerField = TextFormField(controller: _borrowerCtrl, decoration: const InputDecoration(labelText: 'Borrower (Student / Staff) *', border: OutlineInputBorder()));
                    final bookField = TextFormField(controller: _bookTitleCtrl, decoration: const InputDecoration(labelText: 'Book Title *', border: OutlineInputBorder()));
                    final accField = TextFormField(controller: _accessionCtrl, decoration: const InputDecoration(labelText: 'Accession / Barcode *', border: OutlineInputBorder()));

                    if (isNarrow) {
                      return Column(children: [borrowerField, const SizedBox(height: 12), bookField, const SizedBox(height: 12), accField]);
                    }
                    return Row(children: [Expanded(child: borrowerField), const SizedBox(width: 10), Expanded(child: bookField), const SizedBox(width: 10), SizedBox(width: 160, child: accField)]);
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _issueBook,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Checkout Book (Issue)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Active Circulation Table
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Circulation Log & Overdue Roster', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _circulationDesk.length,
                  separatorBuilder: (_, _) => Divider(color: borderColor.withValues(alpha: 0.5)),
                  itemBuilder: (context, index) {
                    final item = _circulationDesk[index];
                    final isOverdue = item['status'] == 'Overdue';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(isOverdue ? Icons.warning_rounded : Icons.menu_book, color: isOverdue ? AppColors.error : const Color(0xFF8B5CF6), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['title'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                                Text('Borrower: ${item['borrower']} • Accession: ${item['acc']} • Due: ${item['dueDate']}', style: TextStyle(fontSize: 11, color: subColor)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isOverdue ? AppColors.error : AppColors.primary).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['status'] as String,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOverdue ? AppColors.error : AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                item['status'] = 'Returned';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Book "${item['title']}" checked in!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
                              );
                            },
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                            child: const Text('Return', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, Color accent, IconData icon, Color cardBg, Color borderColor, bool dark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text(title, style: TextStyle(fontSize: 11, color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
