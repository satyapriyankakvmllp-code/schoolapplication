import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../commonwidgets/edupluse_scaffold.dart';
import '../../application/admissions_controller.dart';
import '../../domain/student_profile_model.dart';
import '../../../classes/application/classes_controller.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  final ValueChanged<EdupluseNavPage>? onNavigate;
  final ValueChanged<String>? onSelectStudent;
  final VoidCallback? onToggleTheme;
  final bool isDark;

  const StudentListScreen({
    super.key,
    this.onNavigate,
    this.onSelectStudent,
    this.onToggleTheme,
    this.isDark = false,
  });

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final _searchController = TextEditingController();
  String _selectedClassFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admissionsAsync = ref.watch(admissionsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;

    return EdupluseScaffold(
      activePage: EdupluseNavPage.studentList,
      onNavigate: widget.onNavigate,
      onToggleTheme: widget.onToggleTheme,
      isDark: widget.isDark,
      body: admissionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF109F83)),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (allStudents) {
          final query = _searchController.text.toLowerCase().trim();
          final filteredStudents = allStudents.where((item) {
            final matchesQuery = query.isEmpty ||
                item.user.fullName.toLowerCase().contains(query) ||
                item.student.admissionNumber.toLowerCase().contains(query) ||
                (item.student.rollNumber ?? '').toLowerCase().contains(query);

            final matchesClass = _selectedClassFilter == 'All' ||
                item.student.className.toLowerCase() == _selectedClassFilter.toLowerCase();

            return matchesQuery && matchesClass;
          }).toList();

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width < 600 ? 12 : 24,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(allStudents.length, isDark),
                const SizedBox(height: 20),
                _buildFilterBar(isDark),
                const SizedBox(height: 20),
                _buildStudentsTable(filteredStudents, isDark),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(int totalCount, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Directory',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Dashboard / Student / ', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500, fontSize: 13)),
                Text(
                  'All Students ($totalCount)',
                  style: const TextStyle(color: Color(0xFF109F83), fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ],
        );

        final addBtn = ElevatedButton.icon(
          onPressed: () => widget.onNavigate?.call(EdupluseNavPage.addNewStudent),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add New Student', style: TextStyle(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF109F83),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 12),
              addBtn,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            title,
            addBtn,
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;

          final searchInput = TextField(
            controller: _searchController,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by Student Name, Admission No, or Roll No...',
              hintStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(Icons.search, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                      onPressed: () => setState(() => _searchController.clear()),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          );

          final classesAsync = ref.watch(classesControllerProvider);
          final dynamicClassNames = classesAsync.value?.map((c) => c.name).where((n) => n.trim().isNotEmpty) ?? [];
          final allStudents = ref.watch(admissionsListProvider).value ?? [];
          final studentClassNames = allStudents.map((s) => s.student.className).where((n) => n.trim().isNotEmpty);
          final mergedClasses = <String>{'All', ...dynamicClassNames, ...studentClassNames}.toList();

          final effectiveFilter = mergedClasses.contains(_selectedClassFilter) ? _selectedClassFilter : 'All';

          final classDropdown = DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              value: effectiveFilter,
              items: mergedClasses
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          'Class: $c',
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedClassFilter = val ?? 'All'),
            ),
          );

          if (isMobile) {
            return Column(
              children: [
                searchInput,
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: classDropdown,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: searchInput),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: classDropdown,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStudentsTable(List<dynamic> students, bool isDark) {
    if (students.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: isDark ? const Color(0xFF64748B) : Colors.grey),
              const SizedBox(height: 12),
              Text(
                'No students found matching your search',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                'Try searching with a different name or admission number.',
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: students.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        itemBuilder: (context, index) {
          final studentData = students[index];
          final user = studentData.user;
          final student = studentData.student;
          final isEnrolled = student.enrollmentStatus == EnrollmentStatus.enrolled;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;

              if (isNarrow) {
                return InkWell(
                  onTap: () {
                    ref.read(selectedStudentIdProvider.notifier).state = student.id;
                    widget.onSelectStudent?.call(student.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                              child: Text(
                                user.firstName.isNotEmpty ? user.firstName[0] : 'S',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF109F83), fontSize: 15),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    '${student.admissionNumber} • Roll: ${student.rollNumber ?? '10'}',
                                    style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isEnrolled
                                    ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                                    : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                isEnrolled ? 'Active' : 'Suspended',
                                style: TextStyle(
                                  color: isEnrolled
                                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A))
                                      : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${student.className} - ${student.section}',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                ref.read(selectedStudentIdProvider.notifier).state = student.id;
                                widget.onSelectStudent?.call(student.id);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF109F83),
                                side: const BorderSide(color: Color(0xFF109F83)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('View Profile', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              return InkWell(
                onTap: () {
                  ref.read(selectedStudentIdProvider.notifier).state = student.id;
                  widget.onSelectStudent?.call(student.id);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                        child: Text(
                          user.firstName.isNotEmpty ? user.firstName[0] : 'S',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF109F83), fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  student.admissionNumber,
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0284C7), fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '• Roll No: ${student.rollNumber ?? '10'}',
                                  style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${student.className} - ${student.section}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isEnrolled
                              ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                              : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isEnrolled ? 'Active' : 'Suspended',
                          style: TextStyle(
                            color: isEnrolled
                                ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A))
                                : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(selectedStudentIdProvider.notifier).state = student.id;
                          widget.onSelectStudent?.call(student.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('View Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
