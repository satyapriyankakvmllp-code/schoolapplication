import 'package:flutter/material.dart';
import 'package:frontend/src/utils/dynamic_data_client.dart';
import '../../../domain/staff_member_model.dart';

class StaffBookBorrowRecord {
  final String id;
  final String sl;
  final String bookName;
  final String bookCategory;
  final String bookNumber;
  final String takenOn;
  final String lastDate;
  final String status; // 'Issued', 'Returned', 'Overdue'
  final Color coverColor;
  final IconData coverIcon;

  const StaffBookBorrowRecord({
    required this.id,
    required this.sl,
    required this.bookName,
    required this.bookCategory,
    required this.bookNumber,
    required this.takenOn,
    required this.lastDate,
    required this.status,
    required this.coverColor,
    required this.coverIcon,
  });

  StaffBookBorrowRecord copyWith({
    String? id,
    String? sl,
    String? bookName,
    String? bookCategory,
    String? bookNumber,
    String? takenOn,
    String? lastDate,
    String? status,
    Color? coverColor,
    IconData? coverIcon,
  }) {
    return StaffBookBorrowRecord(
      id: id ?? this.id,
      sl: sl ?? this.sl,
      bookName: bookName ?? this.bookName,
      bookCategory: bookCategory ?? this.bookCategory,
      bookNumber: bookNumber ?? this.bookNumber,
      takenOn: takenOn ?? this.takenOn,
      lastDate: lastDate ?? this.lastDate,
      status: status ?? this.status,
      coverColor: coverColor ?? this.coverColor,
      coverIcon: coverIcon ?? this.coverIcon,
    );
  }
}

/// Tab 6: Library Circulation & Borrowing
/// Features search, year filter, dynamic pagination slide buttons,
/// and live return/renewal actions for faculty borrowed reference books.
class StaffLibraryTab extends StatefulWidget {
  final StaffMemberModel staff;
  final bool isDark;

  const StaffLibraryTab({
    super.key,
    required this.staff,
    required this.isDark,
  });

  @override
  State<StaffLibraryTab> createState() => _StaffLibraryTabState();
}

class _StaffLibraryTabState extends State<StaffLibraryTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedYear = 'Year 2026/2027';
  int _rowsPerPage = 5;
  int _currentPage = 1;

  final List<String> _academicYears = [
    'Year 2026/2027',
    'Year 2025/2026',
    'Year 2024/2025',
  ];

  late List<StaffBookBorrowRecord> _books;

  @override
  void initState() {
    super.initState();
    _books = _buildInitialBooks();
    _loadBooks();
  }

  @override
  void didUpdateWidget(covariant StaffLibraryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.staff.id != widget.staff.id) {
      _loadBooks();
    }
  }

  Future<void> _loadBooks() async {
    try {
      final records = await DynamicDataClient.instance.getAll(
        assetPath: 'assets/data/staff/staff_library.json',
        storageKey: 'edupulse_staff_library_records',
      );
      if (records.isNotEmpty) {
        final staffRecords = records.where((r) => r['staff_id'] == widget.staff.id).toList();
        final effectiveRecords = staffRecords.isNotEmpty ? staffRecords : records;
        if (mounted) {
          setState(() {
            _books = effectiveRecords.map((r) {
              final cat = (r['book_category'] ?? 'General').toString();
              IconData icon = Icons.book;
              if (cat.contains('Math')) {
                icon = Icons.functions;
              } else if (cat.contains('Science')) {
                icon = Icons.science;
              } else if (cat.contains('Computer')) {
                icon = Icons.terminal;
              } else if (cat.contains('Language')) {
                icon = Icons.menu_book;
              } else if (cat.contains('Pedagogy') || cat.contains('Education')) {
                icon = Icons.psychology;
              } else if (cat.contains('Humanities')) {
                icon = Icons.gavel;
              }

              Color col = const Color(0xFF109F83);
              final hexStr = r['cover_color_hex']?.toString();
              if (hexStr != null && hexStr.startsWith('0x')) {
                col = Color(int.tryParse(hexStr) ?? 0xFF109F83);
              }

              return StaffBookBorrowRecord(
                id: (r['id'] ?? '').toString(),
                sl: (r['sl'] ?? '').toString(),
                bookName: (r['book_name'] ?? '').toString(),
                bookCategory: cat,
                bookNumber: (r['book_number'] ?? '').toString(),
                takenOn: (r['taken_on'] ?? '').toString(),
                lastDate: (r['last_date'] ?? '').toString(),
                status: (r['status'] ?? 'Issued').toString(),
                coverColor: col,
                coverIcon: icon,
              );
            }).toList();
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StaffBookBorrowRecord> _buildInitialBooks() {
    return const [
      StaffBookBorrowRecord(
        id: 'bk-01',
        sl: '01',
        bookName: 'Advanced Engineering Mathematics (E. Kreyszig)',
        bookCategory: 'Mathematics',
        bookNumber: 'LIB-MATH-8821',
        takenOn: '04 Oct 2026',
        lastDate: '04 Nov 2026',
        status: 'Issued',
        coverColor: Color(0xFF6366F1),
        coverIcon: Icons.functions,
      ),
      StaffBookBorrowRecord(
        id: 'bk-02',
        sl: '02',
        bookName: 'University Physics with Modern Physics',
        bookCategory: 'Science',
        bookNumber: 'LIB-PHY-3419',
        takenOn: '12 Sep 2026',
        lastDate: '12 Oct 2026',
        status: 'Overdue',
        coverColor: Color(0xFF0284C7),
        coverIcon: Icons.science,
      ),
      StaffBookBorrowRecord(
        id: 'bk-03',
        sl: '03',
        bookName: 'Educational Psychology & Pedagogy Practice',
        bookCategory: 'Education / Pedagogy',
        bookNumber: 'LIB-EDU-1044',
        takenOn: '15 Aug 2026',
        lastDate: '15 Sep 2026',
        status: 'Returned',
        coverColor: Color(0xFF109F83),
        coverIcon: Icons.psychology,
      ),
      StaffBookBorrowRecord(
        id: 'bk-04',
        sl: '04',
        bookName: 'Introduction to Algorithms (CLRS 4th Ed)',
        bookCategory: 'Computer Science',
        bookNumber: 'LIB-CS-9902',
        takenOn: '20 Jul 2026',
        lastDate: '20 Aug 2026',
        status: 'Returned',
        coverColor: Color(0xFF8B5CF6),
        coverIcon: Icons.terminal,
      ),
      StaffBookBorrowRecord(
        id: 'bk-05',
        sl: '05',
        bookName: 'Oxford Companion to English Literature',
        bookCategory: 'Languages',
        bookNumber: 'LIB-ENG-5120',
        takenOn: '01 Jul 2026',
        lastDate: '01 Aug 2026',
        status: 'Returned',
        coverColor: Color(0xFFF59E0B),
        coverIcon: Icons.menu_book,
      ),
      StaffBookBorrowRecord(
        id: 'bk-06',
        sl: '06',
        bookName: 'Indian Constitutional Law (M.P. Jain)',
        bookCategory: 'Humanities',
        bookNumber: 'LIB-HUM-7731',
        takenOn: '10 Jun 2026',
        lastDate: '10 Jul 2026',
        status: 'Returned',
        coverColor: Color(0xFFEC4899),
        coverIcon: Icons.gavel,
      ),
      StaffBookBorrowRecord(
        id: 'bk-07',
        sl: '07',
        bookName: 'Organic Chemistry Reactions & Mechanisms',
        bookCategory: 'Science',
        bookNumber: 'LIB-CHEM-4412',
        takenOn: '18 May 2026',
        lastDate: '18 Jun 2026',
        status: 'Returned',
        coverColor: Color(0xFF14B8A6),
        coverIcon: Icons.biotech,
      ),
    ];
  }

  Future<void> _renewBook(StaffBookBorrowRecord record) async {
    setState(() {
      _books = _books.map((b) {
        if (b.id == record.id) {
          return b.copyWith(
            lastDate: '04 Dec 2026',
            status: 'Issued',
          );
        }
        return b;
      }).toList();
    });

    try {
      final allRaw = await DynamicDataClient.instance.getAll(
        assetPath: 'assets/data/staff/staff_library.json',
        storageKey: 'edupulse_staff_library_records',
      );
      final updatedRaw = allRaw.map((item) {
        if (item['id'] == record.id) {
          item['last_date'] = '04 Dec 2026';
          item['status'] = 'Issued';
        }
        return item;
      }).toList();
      await DynamicDataClient.instance.syncAll(
        assetPath: 'assets/data/staff/staff_library.json',
        storageKey: 'edupulse_staff_library_records',
        items: updatedRaw,
      );
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Renewed "${record.bookName}" for 30 more days.'),
          backgroundColor: const Color(0xFF109F83),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _returnBook(StaffBookBorrowRecord record) async {
    setState(() {
      _books = _books.map((b) {
        if (b.id == record.id) {
          return b.copyWith(status: 'Returned');
        }
        return b;
      }).toList();
    });

    try {
      final allRaw = await DynamicDataClient.instance.getAll(
        assetPath: 'assets/data/staff/staff_library.json',
        storageKey: 'edupulse_staff_library_records',
      );
      final updatedRaw = allRaw.map((item) {
        if (item['id'] == record.id) {
          item['status'] = 'Returned';
        }
        return item;
      }).toList();
      await DynamicDataClient.instance.syncAll(
        assetPath: 'assets/data/staff/staff_library.json',
        storageKey: 'edupulse_staff_library_records',
        items: updatedRaw,
      );
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked "${record.bookName}" as returned to Central Library.'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final filtered = _books.where((b) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = b.bookName.toLowerCase().contains(q);
        final matchesCat = b.bookCategory.toLowerCase().contains(q);
        final matchesNum = b.bookNumber.toLowerCase().contains(q);
        final matchesStatus = b.status.toLowerCase().contains(q);
        if (!matchesTitle && !matchesCat && !matchesNum && !matchesStatus) return false;
      }
      return true;
    }).toList();

    final totalEntries = filtered.length;
    final totalPages = (totalEntries / _rowsPerPage).ceil().clamp(1, 999);
    final startIdx = ((_currentPage - 1) * _rowsPerPage).clamp(0, totalEntries);
    final endIdx = (startIdx + _rowsPerPage).clamp(0, totalEntries);
    final pageRecords = filtered.sublist(startIdx, endIdx);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.25 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Library Circulation & Borrowing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),

          // Search, Filter & Rows Per Page
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 750;

              final searchField = SizedBox(
                width: isNarrow ? double.infinity : 240,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() {
                    _searchQuery = val;
                    _currentPage = 1;
                  }),
                  style: TextStyle(fontSize: 13, color: textColor),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 18, color: subColor),
                    hintText: 'Search books...',
                    hintStyle: TextStyle(fontSize: 13, color: subColor),
                    filled: true,
                    fillColor: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF109F83)),
                    ),
                  ),
                ),
              );

              final controls = Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedYear,
                        icon: const Icon(Icons.arrow_drop_down, size: 18),
                        dropdownColor: cardBg,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                        items: _academicYears.map((y) {
                          return DropdownMenuItem(value: y, child: Text(y));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedYear = v);
                        },
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Rows per page: ', style: TextStyle(fontSize: 12, color: subColor)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _rowsPerPage,
                            isDense: true,
                            dropdownColor: cardBg,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                            items: [5, 10, 20].map((count) {
                              return DropdownMenuItem(value: count, child: Text('$count'));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _rowsPerPage = v;
                                  _currentPage = 1;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    controls,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  searchField,
                  controls,
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Library Circulation Table (Covers full screen width with LayoutBuilder)
          LayoutBuilder(
            builder: (context, constraints) {
              final double tableWidth = constraints.maxWidth > 1040 ? constraints.maxWidth : 1040;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 45, child: Text('S.L', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                        Expanded(flex: 3, child: Text('Book Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                        Expanded(flex: 2, child: Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                        Expanded(flex: 2, child: Text('Accession No', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                        Expanded(flex: 2, child: Text('Taken On', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                        Expanded(flex: 2, child: Text('Last Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                        Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                        Expanded(flex: 3, child: Text('Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Table Rows
                  ...pageRecords.map((b) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: borderColor.withValues(alpha: 0.6)),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 45, child: Text(b.sl, style: TextStyle(fontSize: 12, color: subColor))),
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: b.coverColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(b.coverIcon, color: b.coverColor, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    b.bookName,
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(b.bookCategory, style: TextStyle(fontSize: 12, color: textColor)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              b.bookNumber,
                              style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(b.takenOn, style: TextStyle(fontSize: 12, color: textColor)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(b.lastDate, style: TextStyle(fontSize: 12, color: textColor)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildStatusBadge(b.status),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: b.status == 'Issued' || b.status == 'Overdue'
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => _renewBook(b),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Renew',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0284C7),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => _returnBook(b),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Return',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF16A34A),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Archived',
                                    style: TextStyle(fontSize: 11.5, color: subColor, fontStyle: FontStyle.italic),
                                  ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 16),

          // Pagination Info & Dynamic Sliding Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${totalEntries == 0 ? 0 : startIdx + 1} to $endIdx of $totalEntries entries',
                style: TextStyle(fontSize: 12, color: subColor),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.first_page, size: 20),
                    tooltip: 'First page',
                    onPressed: _currentPage > 1 ? () => setState(() => _currentPage = 1) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    tooltip: 'Previous page',
                    onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                  ),
                  ...List.generate(totalPages, (i) {
                    final p = i + 1;
                    final isSel = p == _currentPage;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () => setState(() => _currentPage = p),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF109F83) : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSel ? const Color(0xFF109F83) : borderColor,
                            ),
                          ),
                          child: Text(
                            '$p',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    tooltip: 'Next page',
                    onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page, size: 20),
                    tooltip: 'Last page',
                    onPressed: _currentPage < totalPages ? () => setState(() => _currentPage = totalPages) : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFE0F2FE);
    Color fg = const Color(0xFF0284C7);

    if (status == 'Returned') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
    } else if (status == 'Overdue') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    }

    if (widget.isDark) {
      if (status == 'Issued') bg = const Color(0xFF0C4A6E);
      if (status == 'Returned') bg = const Color(0xFF14532D);
      if (status == 'Overdue') bg = const Color(0xFF7F1D1D);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
