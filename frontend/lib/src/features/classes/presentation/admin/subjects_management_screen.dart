import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/subjects_controller.dart';
import '../../domain/subject_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Subjects Management Screen: organized table/card layout, working search,
/// and inline Add/Edit modal dialog.
class SubjectsManagementScreen extends ConsumerStatefulWidget {
  const SubjectsManagementScreen({super.key});

  @override
  ConsumerState<SubjectsManagementScreen> createState() => _SubjectsManagementScreenState();
}

class _SubjectsManagementScreenState extends ConsumerState<SubjectsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(classesPermissionsProvider);
    final lookup = ref.watch(classesLookupProvider);
    final subjectsAsync = ref.watch(subjectsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return AccessGuard(
      allowed: perms.canAccessClasses,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        perms.isAdmin ? 'Subjects Management' : 'Assigned Subjects',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        perms.isAdmin
                            ? 'Dashboard / Academic / Subjects'
                            : 'Classes / My Subjects',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (perms.canManageSubjects)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF109F83),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: isMobile ? 8 : 10,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'Add Subject',
                      style: TextStyle(fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.w600),
                    ),
                    onPressed: lookup.classes.isEmpty
                        ? null
                        : () => _openSubjectModal(context, ref, lookup),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Card Container
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(isMobile ? 12 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Centered search row
                  Row(
                    children: [
                      Text(
                        'Subject Catalog',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      // Center smaller search bar
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isMobile ? 160 : 200),
                        child: SizedBox(
                          height: 32,
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Search subjects...',
                              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                              prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 14),
                                      onPressed: () => _searchController.clear(),
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(width: isMobile ? 0 : 120),
                    ],
                  ),
                  const Divider(height: 24),

                  // Table
                  subjectsAsync.when(
                    data: (items) {
                      final filtered = items.where((s) {
                        if (_searchQuery.isEmpty) return true;
                        final name = s.name.toLowerCase();
                        final code = s.code.toLowerCase();
                        final className = lookup.className(s.classId).toLowerCase();
                        final teacher = lookup.teacherName(s.teacherId).toLowerCase();
                        return name.contains(_searchQuery) ||
                            code.contains(_searchQuery) ||
                            className.contains(_searchQuery) ||
                            teacher.contains(_searchQuery);
                      }).toList();

                      if (filtered.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Text(
                            _searchQuery.isNotEmpty
                                ? 'No subjects matching "$_searchQuery"'
                                : 'No subjects enrolled yet.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: isMobile ? 600 : (screenWidth - (isMobile ? 50 : 80)).clamp(750, 2400),
                              ),
                              child: DataTable(
                                showCheckboxColumn: false,
                                horizontalMargin: 16,
                                columnSpacing: 24,
                                headingRowHeight: 40,
                                dataRowMinHeight: 44,
                                dataRowMaxHeight: 50,
                                headingRowColor: WidgetStateProperty.all(
                                  isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                ),
                                columns: [
                                  const DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  const DataColumn(label: Text('Subject Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  const DataColumn(label: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  const DataColumn(label: Text('Assigned Teacher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  if (perms.canManageSubjects)
                                    const DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                ],
                                rows: filtered.map((s) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            s.code,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11.5,
                                              color: Color(0xFF6366F1),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          s.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.5,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          lookup.className(s.classId),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          lookup.teacherName(s.teacherId),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      if (perms.canManageSubjects)
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 16),
                                                tooltip: 'Edit Subject',
                                                onPressed: () => _openSubjectModal(
                                                  context,
                                                  ref,
                                                  lookup,
                                                  existing: s,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                                tooltip: 'Delete Subject',
                                                onPressed: () async {
                                                  if (await confirmDelete(context, s.name)) {
                                                    if (!context.mounted) return;
                                                    await runClassesAction(
                                                      context,
                                                      () => ref.read(subjectsControllerProvider.notifier).delete(s.id),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => Text('Error: $err'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Inline modal form to add or edit subject without navigating away
  Future<void> _openSubjectModal(
    BuildContext context,
    WidgetRef ref,
    ClassesLookup lookup, {
    SubjectModel? existing,
  }) async {
    var classId = existing?.classId ?? lookup.classes.first.id;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    String? teacherId = existing?.teacherId ?? (lookup.teachers.isNotEmpty ? lookup.teachers.first.id : null);
    String? formError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  existing == null ? Icons.add_circle_outline : Icons.edit_outlined,
                  color: const Color(0xFF109F83),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  existing == null ? 'Add Subject' : 'Edit Subject',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (formError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          formError!,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    // Class selector containing created classes
                    const Text('Class', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: classId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: lookup.classes.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => classId = v);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Quick suggestion chips for standard subjects
                    const Text('Quick Select Subject:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: ['Mathematics', 'Science', 'Physics', 'Chemistry', 'Biology'].map((preset) {
                        return ActionChip(
                          label: Text(preset, style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setDialogState(() {
                              nameCtrl.text = preset;
                              if (codeCtrl.text.isEmpty) {
                                codeCtrl.text = '${preset.substring(0, 3).toUpperCase()}-101';
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    // Subject Name
                    const Text('Subject Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Mathematics, Science, Physics',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (v) {
                        if (codeCtrl.text.isEmpty && v.trim().length >= 3) {
                          codeCtrl.text = '${v.trim().substring(0, 3).toUpperCase()}-101';
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Subject Code
                    const Text('Subject Code (auto-generated if empty)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        hintText: 'MTH-101',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Teacher
                    IdDropdown(
                      label: 'Subject Teacher',
                      value: teacherId,
                      options: {for (final t in lookup.teachers) t.id: t.name},
                      onChanged: (v) => setDialogState(() => teacherId = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF109F83),
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  var code = codeCtrl.text.trim();
                  if (name.isEmpty) {
                    setDialogState(() => formError = 'Subject name is required');
                    return;
                  }
                  if (code.isEmpty) {
                    code = name.length >= 3
                        ? '${name.substring(0, 3).toUpperCase()}-101'
                        : '${name.toUpperCase()}-101';
                  }

                  try {
                    final model = SubjectModel(
                      id: existing?.id ?? '',
                      classId: classId,
                      name: name,
                      code: code,
                      teacherId: teacherId,
                    );
                    await ref.read(subjectsControllerProvider.notifier).save(
                          model,
                          isNew: existing == null,
                        );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(existing == null ? 'Subject "$name" created successfully' : 'Subject updated successfully'),
                          backgroundColor: const Color(0xFF10B981),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() {
                      formError = e.toString().replaceAll('Exception:', '').replaceAll('ClassesDataException:', '').trim();
                    });
                  }
                },
                child: Text(existing == null ? 'Create' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
