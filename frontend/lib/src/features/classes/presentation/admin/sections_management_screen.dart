import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/sections_controller.dart';
import '../../domain/section_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Sections Management Screen with Class, Section Name, Room Number, Capacity,
/// working search filter, and duplicate prevention for the same class.
class SectionsManagementScreen extends ConsumerStatefulWidget {
  const SectionsManagementScreen({super.key});

  @override
  ConsumerState<SectionsManagementScreen> createState() => _SectionsManagementScreenState();
}

class _SectionsManagementScreenState extends ConsumerState<SectionsManagementScreen> {
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
    final sectionsAsync = ref.watch(sectionsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return AccessGuard(
      allowed: perms.isAdmin || perms.isTeacher,
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
                        'Sections',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dashboard / Academic / Sections',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (perms.canManageSections)
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
                      'Add Section',
                      style: TextStyle(fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.w600),
                    ),
                    onPressed: lookup.classes.isEmpty
                        ? null
                        : () => _openSectionModal(context, ref, lookup),
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
                  // Centered Search row
                  Row(
                    children: [
                      Text(
                        'Section Directory',
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
                              hintText: 'Search sections...',
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
                  sectionsAsync.when(
                    data: (items) {
                      final filtered = items.where((s) {
                        if (_searchQuery.isEmpty) return true;
                        final className = lookup.className(s.classId).toLowerCase();
                        final secName = s.name.toLowerCase();
                        final room = lookup.roomName(s.classroomId).toLowerCase();
                        return className.contains(_searchQuery) ||
                            secName.contains(_searchQuery) ||
                            room.contains(_searchQuery);
                      }).toList();

                      if (filtered.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Text(
                            _searchQuery.isNotEmpty
                                ? 'No sections matching "$_searchQuery"'
                                : 'No sections enrolled yet.',
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
                                  const DataColumn(label: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  const DataColumn(label: Text('Section Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  const DataColumn(label: Text('Room Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  const DataColumn(label: Text('Capacity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  if (perms.canManageSections)
                                    const DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                ],
                                rows: filtered.map((s) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          lookup.className(s.classId),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.5,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF109F83).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Section ${s.name}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Color(0xFF109F83),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          lookup.roomName(s.classroomId),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${s.capacity} Students',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                                              SizedBox(width: 4),
                                              Text(
                                                'Active',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF10B981),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (perms.canManageSections)
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 16),
                                                tooltip: 'Edit Section',
                                                onPressed: () => _openSectionModal(
                                                  context,
                                                  ref,
                                                  lookup,
                                                  existing: s,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                                tooltip: 'Delete Section',
                                                onPressed: () async {
                                                  if (await confirmDelete(context, 'Section ${s.name}')) {
                                                    if (!context.mounted) return;
                                                    await runClassesAction(
                                                      context,
                                                      () => ref.read(sectionsControllerProvider.notifier).delete(s.id),
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

  /// Inline modal form to add or edit section without navigating away
  Future<void> _openSectionModal(
    BuildContext context,
    WidgetRef ref,
    ClassesLookup lookup, {
    SectionModel? existing,
  }) async {
    var classId = existing?.classId ?? lookup.classes.first.id;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final capacityCtrl = TextEditingController(text: (existing?.capacity ?? 40).toString());
    String? roomId = existing?.classroomId ?? (lookup.classrooms.isNotEmpty ? lookup.classrooms.first.id : null);
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
                  existing == null ? 'Add Section' : 'Edit Section',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
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
                    // Class selector
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

                    // Section Name with quick selection chips
                    const Text('Section Name (e.g. A, B, C)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: ['A', 'B', 'C', 'D'].map((sec) {
                        return ActionChip(
                          label: Text('Section $sec', style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setDialogState(() {
                              nameCtrl.text = sec;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Enter section (e.g. A, B, C)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Room Number
                    IdDropdown(
                      label: 'Room Number',
                      value: roomId,
                      options: {for (final r in lookup.classrooms) r.id: '${r.name} (${r.building})'},
                      onChanged: (v) => setDialogState(() => roomId = v),
                    ),
                    const SizedBox(height: 12),

                    // Capacity
                    const Text('Student Capacity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: capacityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '40',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
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
                  final sectionName = nameCtrl.text.trim();
                  if (sectionName.isEmpty) {
                    setDialogState(() => formError = 'Section name is required');
                    return;
                  }
                  // Duplicate check for the same class
                  final isDuplicate = lookup.sections.any((s) =>
                      (existing == null || s.id != existing.id) &&
                      s.classId == classId &&
                      s.name.trim().toLowerCase() == sectionName.toLowerCase());
                  if (isDuplicate) {
                    setDialogState(() => formError = 'Section "$sectionName" already exists for this class.');
                    return;
                  }

                  try {
                    final model = SectionModel(
                      id: existing?.id ?? '',
                      classId: classId,
                      name: sectionName,
                      capacity: int.tryParse(capacityCtrl.text.trim()) ?? 40,
                      classroomId: roomId,
                    );
                    await ref.read(sectionsControllerProvider.notifier).save(
                          model,
                          isNew: existing == null,
                        );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(existing == null ? 'Section created successfully' : 'Section updated'),
                          backgroundColor: const Color(0xFF10B981),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() {
                      formError = e.toString().replaceAll('Exception:', '').trim();
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
