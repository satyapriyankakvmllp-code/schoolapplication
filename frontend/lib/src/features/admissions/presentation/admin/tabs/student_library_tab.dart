import 'package:flutter/material.dart';
import '../../../domain/student_admission_model.dart';

/// Library book issue circulation record for a student.
class StudentBookIssueItem {
  final String id;
  final String sl;
  final String bookName;
  final String bookCategory;
  final String bookNumber;
  final String takenOn;
  final String lastDate;
  final Color coverColor;
  final IconData coverIcon;

  const StudentBookIssueItem({
    required this.id,
    required this.sl,
    required this.bookName,
    required this.bookCategory,
    required this.bookNumber,
    required this.takenOn,
    required this.lastDate,
    required this.coverColor,
    required this.coverIcon,
  });
}

/// Library Tab View for Student 360° Profile.
/// Features dynamic pagination ("slide btns" « ‹ 1 2 › »), full screen width table,
/// real-time row slicing, and entries counter.
class StudentLibraryTab extends StatefulWidget {
  final StudentAdmissionModel admission;
  final bool isDark;

  const StudentLibraryTab({
    super.key,
    required this.admission,
    this.isDark = false,
  });

  @override
  State<StudentLibraryTab> createState() => _StudentLibraryTabState();
}

class _StudentLibraryTabState extends State<StudentLibraryTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedYear = 'Year 2025/2026';
  int _rowsPerPage = 5;
  int _currentPage = 1;

  final List<String> _academicYears = [
    'Year 2025/2026',
    'Year 2024/2025',
    'Year 2026/2027',
  ];

  late List<StudentBookIssueItem> _books;

  @override
  void initState() {
    super.initState();
    _books = _buildInitialBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudentBookIssueItem> _buildInitialBooks() {
    return const [
      StudentBookIssueItem(
        id: 'bk-01',
        sl: '01',
        bookName: 'Marigold (NCERT)',
        bookCategory: 'English',
        bookNumber: '8512',
        takenOn: '05 May 2025',
        lastDate: '05 Jun 2025',
        coverColor: Color(0xFF16A34A),
        coverIcon: Icons.menu_book_rounded,
      ),
      StudentBookIssueItem(
        id: 'bk-02',
        sl: '02',
        bookName: 'Number Magic',
        bookCategory: 'Mathematics',
        bookNumber: '85620',
        takenOn: '05 May 2025',
        lastDate: '05 Jun 2025',
        coverColor: Color(0xFFD97706),
        coverIcon: Icons.calculate_rounded,
      ),
      StudentBookIssueItem(
        id: 'bk-03',
        sl: '03',
        bookName: 'Mental Math',
        bookCategory: 'Mathematics',
        bookNumber: '8512',
        takenOn: '05 May 2025',
        lastDate: '05 Jun 2025',
        coverColor: Color(0xFF0284C7),
        coverIcon: Icons.psychology_rounded,
      ),
      StudentBookIssueItem(
        id: 'bk-04',
        sl: '04',
        bookName: 'Our Environment',
        bookCategory: 'Environmental Studies',
        bookNumber: '85620',
        takenOn: '05 May 2025',
        lastDate: '05 Jun 2025',
        coverColor: Color(0xFF0D9488),
        coverIcon: Icons.eco_rounded,
      ),
      StudentBookIssueItem(
        id: 'bk-05',
        sl: '05',
        bookName: 'Brainvita',
        bookCategory: 'General Knowledge',
        bookNumber: '8512',
        takenOn: '05 May 2025',
        lastDate: '05 Jun 2025',
        coverColor: Color(0xFF8B5CF6),
        coverIcon: Icons.lightbulb_rounded,
      ),
      StudentBookIssueItem(
        id: 'bk-06',
        sl: '06',
        bookName: 'Wings of Fire',
        bookCategory: 'Biography',
        bookNumber: '9214',
        takenOn: '10 Jun 2025',
        lastDate: '10 Jul 2025',
        coverColor: Color(0xFFEA580C),
        coverIcon: Icons.auto_stories_rounded,
      ),
      StudentBookIssueItem(
        id: 'bk-07',
        sl: '07',
        bookName: 'Science Spectrum',
        bookCategory: 'Science',
        bookNumber: '9432',
        takenOn: '12 Jul 2025',
        lastDate: '12 Aug 2025',
        coverColor: Color(0xFF059669),
        coverIcon: Icons.biotech_rounded,
      ),
      StudentBookIssueItem(
        id: 'bk-08',
        sl: '08',
        bookName: 'Oxford School Atlas',
        bookCategory: 'Geography',
        bookNumber: '7611',
        takenOn: '01 Aug 2025',
        lastDate: '01 Sep 2025',
        coverColor: Color(0xFF4F46E5),
        coverIcon: Icons.public_rounded,
      ),
      StudentBookIssueItem(
        id: 'bk-09',
        sl: '09',
        bookName: 'Coding with Python',
        bookCategory: 'Computer Science',
        bookNumber: '6540',
        takenOn: '15 Aug 2025',
        lastDate: '15 Sep 2025',
        coverColor: Color(0xFF0891B2),
        coverIcon: Icons.code_rounded,
      ),
      StudentBookIssueItem(
        id: 'bk-10',
        sl: '10',
        bookName: 'Art & Craft Explorer',
        bookCategory: 'Fine Arts',
        bookNumber: '3321',
        takenOn: '01 Sep 2025',
        lastDate: '01 Oct 2025',
        coverColor: Color(0xFFDB2777),
        coverIcon: Icons.palette_rounded,
      ),
      StudentBookIssueItem(
        id: 'bk-11',
        sl: '11',
        bookName: 'English Grammar & Comp',
        bookCategory: 'English',
        bookNumber: '5420',
        takenOn: '10 Sep 2025',
        lastDate: '10 Oct 2025',
        coverColor: Color(0xFF7C3AED),
        coverIcon: Icons.spellcheck_rounded,
      ),
      StudentBookIssueItem(
        id: 'bk-12',
        sl: '12',
        bookName: 'World History Digest',
        bookCategory: 'Social Studies',
        bookNumber: '8876',
        takenOn: '01 Oct 2025',
        lastDate: '01 Nov 2025',
        coverColor: Color(0xFFCA8A04),
        coverIcon: Icons.history_edu_rounded,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    final filtered = _books.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      return item.bookName.toLowerCase().contains(q) ||
          item.bookCategory.toLowerCase().contains(q) ||
          item.bookNumber.toLowerCase().contains(q);
    }).toList();

    // Dynamic Pagination calculations
    final totalPages = (filtered.length / _rowsPerPage).ceil().clamp(1, 9999);
    final currentPage = _currentPage.clamp(1, totalPages);
    final startIndex = (currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, filtered.length);
    final pagedBooks = filtered.isEmpty ? <StudentBookIssueItem>[] : filtered.sublist(startIndex, endIndex);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Text(
                'Library',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 14, color: Color(0xFF8B5CF6)),
                    const SizedBox(width: 5),
                    Text(
                      '${filtered.length} Books Issued',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Control Bar: Search, Year dropdown, Export, Rows per page
          LayoutBuilder(
            builder: (context, constraints) {
              final isWrap = constraints.maxWidth < 980;

              final searchBox = SizedBox(
                width: isWrap ? double.infinity : 260,
                height: 38,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _currentPage = 1;
                    });
                  },
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
                    ),
                  ),
                ),
              );

              final rightControls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Year Dropdown
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedYear,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF334155),
                        ),
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: _academicYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedYear = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Export Button
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Exporting book history as $val...'),
                          backgroundColor: const Color(0xFF109F83),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'PDF', child: Text('Export PDF')),
                      PopupMenuItem(value: 'Excel', child: Text('Export Excel / CSV')),
                    ],
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.file_upload_outlined, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            'Export',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Rows per page
                  Text(
                    'Rows per page:',
                    style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _rowsPerPage,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF334155),
                        ),
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: const [
                          DropdownMenuItem(value: 5, child: Text('5')),
                          DropdownMenuItem(value: 10, child: Text('10')),
                          DropdownMenuItem(value: 20, child: Text('20')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _rowsPerPage = val;
                              _currentPage = 1;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );

              if (isWrap) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchBox,
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: rightControls,
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  searchBox,
                  rightControls,
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Library Data Table - Covers full screen width with LayoutBuilder
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: LayoutBuilder(
                builder: (context, tableConstraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: tableConstraints.maxWidth),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        ),
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 56,
                        headingRowHeight: 46,
                        horizontalMargin: 16,
                        columnSpacing: 28,
                        columns: [
                          DataColumn(label: _buildSortHeader('S.L', isDark)),
                          DataColumn(label: _buildSortHeader('Book Name', isDark)),
                          DataColumn(label: _buildSortHeader('Book Category', isDark)),
                          DataColumn(label: _buildSortHeader('Book No', isDark)),
                          DataColumn(label: _buildSortHeader('Taken On', isDark)),
                          DataColumn(label: _buildSortHeader('Last Date', isDark)),
                        ],
                        rows: pagedBooks.map((item) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  item.sl,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: item.coverColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(item.coverIcon, color: item.coverColor, size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      item.bookName,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.bookCategory,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.bookNumber,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.takenOn,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.lastDate,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pagination Footer with fully interactive slide buttons
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;

              final entriesText = Text(
                'Showing ${filtered.isEmpty ? 0 : startIndex + 1} to $endIndex of ${filtered.length} entries',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              );

              final paginationButtons = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // First page button «
                  _buildPageNavButton(
                    '«',
                    isDark,
                    isEnabled: currentPage > 1,
                    onTap: currentPage > 1 ? () => setState(() => _currentPage = 1) : null,
                  ),
                  const SizedBox(width: 4),

                  // Previous page button ‹
                  _buildPageNavButton(
                    '‹',
                    isDark,
                    isEnabled: currentPage > 1,
                    onTap: currentPage > 1 ? () => setState(() => _currentPage--) : null,
                  ),
                  const SizedBox(width: 4),

                  // Numbered Page Buttons
                  for (int pageNo = 1; pageNo <= totalPages; pageNo++) ...[
                    if (pageNo == currentPage)
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '$pageNo',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      InkWell(
                        onTap: () => setState(() => _currentPage = pageNo),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          ),
                          child: Center(
                            child: Text(
                              '$pageNo',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                  ],

                  // Next page button ›
                  _buildPageNavButton(
                    '›',
                    isDark,
                    isEnabled: currentPage < totalPages,
                    onTap: currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                  ),
                  const SizedBox(width: 4),

                  // Last page button »
                  _buildPageNavButton(
                    '»',
                    isDark,
                    isEnabled: currentPage < totalPages,
                    onTap: currentPage < totalPages ? () => setState(() => _currentPage = totalPages) : null,
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    entriesText,
                    const SizedBox(height: 10),
                    paginationButtons,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  entriesText,
                  paginationButtons,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPageNavButton(
    String text,
    bool isDark, {
    required bool isEnabled,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isEnabled
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortHeader(String title, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.unfold_more, size: 14, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
      ],
    );
  }
}
