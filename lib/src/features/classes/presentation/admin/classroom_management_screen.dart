import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../admissions/application/admissions_controller.dart';
import '../../../admissions/domain/student_admission_model.dart';
import '../../application/classes_access.dart';
import '../../domain/classes_actor.dart';
import '../../application/classroom_controller.dart';
import '../../domain/classroom_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Classroom Management Screen: dedicated section for rooms & labs,
/// dynamic enrollment & strength calculation, clickable room and class navigation,
/// column sorting, status filtering, and inline Add/Edit modal.
class ClassroomManagementScreen extends ConsumerStatefulWidget {
  final String? initialRoomId;
  final void Function(String? classId)? onOpenClass;

  const ClassroomManagementScreen({
    super.key,
    this.initialRoomId,
    this.onOpenClass,
  });

  @override
  ConsumerState<ClassroomManagementScreen> createState() =>
      _ClassroomManagementScreenState();
}

class _ClassroomManagementScreenState
    extends ConsumerState<ClassroomManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Assigned, Unassigned
  String? _selectedRoomId;

  // Sorting state:
  // 0: Room Number, 1: Room Type, 2: Floor, 3: Assigned Class / Sections,
  // 4: Total (Class Strength / Room Capacity), 5: Status
  int _sortColumn = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.initialRoomId;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void didUpdateWidget(covariant ClassroomManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRoomId != oldWidget.initialRoomId &&
        widget.initialRoomId != null) {
      setState(() {
        _selectedRoomId = widget.initialRoomId;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Calculates total defined class strength across all sections/classes assigned to this room
  int _computeClassStrength(ClassroomModel r, ClassesLookup lookup) {
    final assignedSections = lookup.sections
        .where((s) => s.classroomId == r.id)
        .toList();
    final assignedClasses = lookup.classes
        .where(
          (c) =>
              c.classroomId == r.id &&
              !assignedSections.any((s) => s.classId == c.id),
        )
        .toList();

    int classStrength = 0;
    for (final s in assignedSections) {
      final parentClass = lookup.classes
          .where((c) => c.id == s.classId)
          .firstOrNull;
      final secSeats =
          (s.capacity > 0 && s.capacity != r.capacity && s.capacity != 40)
          ? s.capacity
          : (parentClass != null && parentClass.capacity > 0
                ? parentClass.capacity
                : (s.capacity > 0 ? s.capacity : 0));
      classStrength += secSeats;
    }
    for (final c in assignedClasses) {
      final clsSeats = c.capacity > 0 ? c.capacity : (c.studentCount ?? 0);
      classStrength += clsSeats;
    }
    return classStrength;
  }

  /// Counts actual unique enrolled students in all sections & classes assigned to this room
  int _computeActualEnrolledStudents(
    ClassroomModel r,
    ClassesLookup lookup,
    List<StudentAdmissionModel> allAdmissions,
  ) {
    final assignedSections = lookup.sections
        .where((s) => s.classroomId == r.id)
        .toList();
    final assignedClasses = lookup.classes
        .where(
          (c) =>
              c.classroomId == r.id &&
              !assignedSections.any((s) => s.classId == c.id),
        )
        .toList();

    final countedAdmissionIds = <String>{};
    for (final s in assignedSections) {
      final secAdmissions = allAdmissions.where((a) {
        if (countedAdmissionIds.contains(a.user.id)) return false;
        final matchesSectionId = a.student.sectionId == s.id;
        final normStudentClass = a.student.className
            .toLowerCase()
            .replaceAll('class', '')
            .replaceAll('th', '')
            .replaceAll('st', '')
            .replaceAll('nd', '')
            .replaceAll('rd', '')
            .trim();
        final normSectionClass = lookup
            .className(s.classId)
            .toLowerCase()
            .replaceAll('class', '')
            .replaceAll('th', '')
            .replaceAll('st', '')
            .replaceAll('nd', '')
            .replaceAll('rd', '')
            .trim();
        final matchesClassAndSec =
            (a.student.currentClassId == s.classId ||
                normStudentClass == normSectionClass) &&
            a.student.section.toUpperCase() == s.name.toUpperCase();
        return matchesSectionId || matchesClassAndSec;
      });
      for (final a in secAdmissions) {
        countedAdmissionIds.add(a.user.id);
      }
    }

    for (final c in assignedClasses) {
      final classAdmissions = allAdmissions.where((a) {
        if (countedAdmissionIds.contains(a.user.id)) return false;
        final matchesId = a.student.currentClassId == c.id;
        final normStudentClass = a.student.className
            .toLowerCase()
            .replaceAll('class', '')
            .replaceAll('th', '')
            .replaceAll('st', '')
            .replaceAll('nd', '')
            .replaceAll('rd', '')
            .trim();
        final normClassName = c.name
            .toLowerCase()
            .replaceAll('class', '')
            .replaceAll('th', '')
            .replaceAll('st', '')
            .replaceAll('nd', '')
            .replaceAll('rd', '')
            .trim();
        return matchesId ||
            (normStudentClass.isNotEmpty && normStudentClass == normClassName);
      });
      for (final a in classAdmissions) {
        countedAdmissionIds.add(a.user.id);
      }
    }

    return countedAdmissionIds.length;
  }

  /// Calculates available seats: Room Capacity - Total Actual Enrolled Students
  /// If admissions data is not loaded (e.g. isolated test harness), falls back to class strength.
  int _computeAvailableSeats(
    ClassroomModel r,
    int actualEnrolled,
    int classStrength,
    bool hasAdmissionsData,
  ) {
    if (hasAdmissionsData) {
      return (r.capacity - actualEnrolled).clamp(0, r.capacity);
    }
    final effectiveOccupied = actualEnrolled > 0
        ? actualEnrolled
        : classStrength;
    return (r.capacity - effectiveOccupied).clamp(0, r.capacity);
  }

  /// Calculates assignment status from actual class and section usage.
  String _computeRoomStatus(ClassroomModel r, ClassesLookup lookup) {
    final isAssigned =
        lookup.sections.any((s) => s.classroomId == r.id) ||
        lookup.classes.any((c) => c.classroomId == r.id);
    return isAssigned ? 'Assigned' : 'Unassigned';
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(classesPermissionsProvider);
    final roomsAsync = ref.watch(classroomControllerProvider);
    final lookup = ref.watch(classesLookupProvider);
    final allAdmissions =
        ref.watch(admissionsListProvider).valueOrNull ?? const [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return AccessGuard(
      allowed: perms.canAccessClasses,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedRoomId != null)
              roomsAsync.when(
                data: (items) {
                  final selectedRoom = items
                      .where((r) => r.id == _selectedRoomId)
                      .firstOrNull;
                  if (selectedRoom != null) {
                    return _buildClassroomDetailsView(
                      selectedRoom,
                      lookup,
                      allAdmissions,
                      perms,
                      isDark,
                      isMobile,
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Error: $e'),
              )
            else ...[
              // Top Bar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perms.canManageClassrooms
                              ? 'Classroom Management'
                              : 'Classrooms Directory',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dashboard / Classes / Classrooms',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (perms.canManageClassrooms)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF109F83),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 8 : 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        'Add Classroom',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => _openRoomModal(context, ref),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Card Container
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.04,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(isMobile ? 12 : 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Toolbar: Room Inventory on left; [ Status: All ▼ ] [ Search Room / Class... 🔍 ] on right
                    LayoutBuilder(
                      builder: (context, boxConstraints) {
                        final isNarrow = boxConstraints.maxWidth < 600;

                        final statusDropdown = Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _statusFilter,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              dropdownColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              items: const [
                                DropdownMenuItem(
                                  value: 'All',
                                  child: Text('All'),
                                ),
                                DropdownMenuItem(
                                  value: 'Assigned',
                                  child: Text('Assigned'),
                                ),
                                DropdownMenuItem(
                                  value: 'Unassigned',
                                  child: Text('Unassigned'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _statusFilter = val);
                                }
                              },
                            ),
                          ),
                        );

                        final searchField = SizedBox(
                          height: 36,
                          width: isNarrow ? double.infinity : 220,
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Search Room / Class...',
                              hintStyle: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 16,
                                color: Colors.grey,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 14),
                                      onPressed: () =>
                                          _searchController.clear(),
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ),
                        );

                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Room Inventory',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  statusDropdown,
                                  const SizedBox(width: 8),
                                  Expanded(child: searchField),
                                ],
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Text(
                              'Room Inventory',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            statusDropdown,
                            const SizedBox(width: 8),
                            searchField,
                          ],
                        );
                      },
                    ),
                    const Divider(height: 24),

                    // Table
                    roomsAsync.when(
                      data: (items) {
                        // 1. Status and Search Filter work together
                        final filtered = items.where((r) {
                          final status = _computeRoomStatus(r, lookup);
                          if (_statusFilter != 'All' &&
                              status != _statusFilter) {
                            return false;
                          }
                          if (_searchQuery.isEmpty) return true;
                          final name = r.name.toLowerCase();
                          final roomType = r.roomType.toLowerCase();
                          final floor = r.displayFloor.toLowerCase();
                          final assigned =
                              (lookup.roomAssignmentSummary(r.id) ?? '')
                                  .toLowerCase();
                          final assignedSections = lookup.sections.where(
                            (s) => s.classroomId == r.id,
                          );
                          final sectionNames = assignedSections
                              .map((s) => s.name.toLowerCase())
                              .join(' ');
                          final classNames = assignedSections
                              .map(
                                (s) =>
                                    lookup.className(s.classId).toLowerCase(),
                              )
                              .join(' ');

                          return name.contains(_searchQuery) ||
                              roomType.contains(_searchQuery) ||
                              floor.contains(_searchQuery) ||
                              assigned.contains(_searchQuery) ||
                              sectionNames.contains(_searchQuery) ||
                              classNames.contains(_searchQuery);
                        }).toList();

                        // 2. Sort filtered items
                        filtered.sort((a, b) {
                          int cmp = 0;
                          switch (_sortColumn) {
                            case 0: // Room Number
                              cmp = a.name.toLowerCase().compareTo(
                                b.name.toLowerCase(),
                              );
                              break;
                            case 1: // Room Type
                              cmp = a.roomType.toLowerCase().compareTo(
                                b.roomType.toLowerCase(),
                              );
                              break;
                            case 2: // Floor
                              cmp = a.displayFloor.toLowerCase().compareTo(
                                b.displayFloor.toLowerCase(),
                              );
                              break;
                            case 3: // Assigned Class / Sections
                              final aAssigned =
                                  lookup.roomAssignmentSummary(a.id) ?? '';
                              final bAssigned =
                                  lookup.roomAssignmentSummary(b.id) ?? '';
                              cmp = aAssigned.toLowerCase().compareTo(
                                bAssigned.toLowerCase(),
                              );
                              break;
                            case 4: // Total (Class Strength / Room Capacity)
                              final aStrength = _computeClassStrength(
                                a,
                                lookup,
                              );
                              final bStrength = _computeClassStrength(
                                b,
                                lookup,
                              );
                              cmp = aStrength != bStrength
                                  ? aStrength.compareTo(bStrength)
                                  : a.capacity.compareTo(b.capacity);
                              break;
                            case 5: // Status
                              final aStatus = _computeRoomStatus(a, lookup);
                              final bStatus = _computeRoomStatus(b, lookup);
                              cmp = aStatus.compareTo(bStatus);
                              break;
                            default:
                              cmp = 0;
                          }
                          return _sortAscending ? cmp : -cmp;
                        });

                        if (filtered.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            child: Text(
                              _searchQuery.isNotEmpty || _statusFilter != 'All'
                                  ? 'No classrooms matching the selected filters.'
                                  : 'No classrooms registered yet.',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        Widget buildTableHeader(String title, int? colIndex) {
                          final isSorted =
                              colIndex != null && _sortColumn == colIndex;
                          final activeColor = isDark
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF0284C7);
                          final inactiveColor = isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8);

                          if (colIndex == null) {
                            return Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF334155),
                              ),
                            );
                          }

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_sortColumn == colIndex) {
                                      _sortAscending = !_sortAscending;
                                    } else {
                                      _sortColumn = colIndex;
                                      _sortAscending = true;
                                    }
                                  });
                                },
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    color: isSorted
                                        ? activeColor
                                        : (isDark
                                              ? const Color(0xFFCBD5E1)
                                              : const Color(0xFF334155)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _sortColumn = colIndex;
                                        _sortAscending = true;
                                      });
                                    },
                                    child: Icon(
                                      Icons.arrow_drop_up,
                                      size: 14,
                                      color: isSorted && _sortAscending
                                          ? activeColor
                                          : inactiveColor,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _sortColumn = colIndex;
                                        _sortAscending = false;
                                      });
                                    },
                                    child: Icon(
                                      Icons.arrow_drop_down,
                                      size: 14,
                                      color: isSorted && !_sortAscending
                                          ? activeColor
                                          : inactiveColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final double minTableWidth =
                                constraints.maxWidth > 920
                                ? constraints.maxWidth
                                : 920;

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: minTableWidth,
                                    ),
                                    child: DataTable(
                                      horizontalMargin: 16,
                                      columnSpacing: 24,
                                      headingRowHeight: 46,
                                      dataRowMinHeight: 64,
                                      dataRowMaxHeight: 74,
                                      headingRowColor: WidgetStateProperty.all(
                                        isDark
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFFF1F5F9),
                                      ),
                                      columns: [
                                        // 1. Room Number
                                        DataColumn(
                                          label: buildTableHeader(
                                            'Room Number',
                                            0,
                                          ),
                                        ),
                                        // 2. Room Type
                                        DataColumn(
                                          label: buildTableHeader(
                                            'Room Type',
                                            1,
                                          ),
                                        ),
                                        // 3. Floor
                                        DataColumn(
                                          label: buildTableHeader('Floor', 2),
                                        ),
                                        // 4. Assigned Class / Sections
                                        DataColumn(
                                          label: buildTableHeader(
                                            'Assigned Class / Sections',
                                            3,
                                          ),
                                        ),
                                        // 5. Total (Class Strength / Room Capacity)
                                        DataColumn(
                                          label: buildTableHeader(
                                            'Total (Class Strength / Room Capacity)',
                                            4,
                                          ),
                                        ),
                                        // 6. Status
                                        DataColumn(
                                          label: buildTableHeader('Status', 5),
                                        ),
                                        // 7. Actions (if allowed)
                                        if (perms.canManageClassrooms)
                                          DataColumn(
                                            label: buildTableHeader(
                                              'Actions',
                                              null,
                                            ),
                                          ),
                                      ],
                                      rows: filtered.map((r) {
                                        final isLab = r.roomType == 'Practical';
                                        final assigned = lookup
                                            .roomAssignmentSummary(r.id);
                                        final floorStr =
                                            r.displayFloor.isNotEmpty &&
                                                r.displayFloor != '—'
                                            ? r.displayFloor
                                            : 'Ground Floor';
                                        final assignedStr =
                                            (assigned != null &&
                                                assigned.isNotEmpty)
                                            ? assigned
                                            : 'Unassigned';

                                        // Assigned sections/classes for clickable navigation
                                        final assignedSections = lookup.sections
                                            .where((s) => s.classroomId == r.id)
                                            .toList();
                                        final assignedClasses = lookup.classes
                                            .where(
                                              (c) =>
                                                  c.classroomId == r.id &&
                                                  !assignedSections.any(
                                                    (s) => s.classId == c.id,
                                                  ),
                                            )
                                            .toList();
                                        final primaryClassId =
                                            assignedSections
                                                .firstOrNull
                                                ?.classId ??
                                            assignedClasses.firstOrNull?.id;

                                        // Dynamic calculations
                                        final classStrength =
                                            _computeClassStrength(r, lookup);
                                        final actualEnrolled =
                                            _computeActualEnrolledStudents(
                                              r,
                                              lookup,
                                              allAdmissions,
                                            );
                                        final availableSeats =
                                            _computeAvailableSeats(
                                              r,
                                              actualEnrolled,
                                              classStrength,
                                              allAdmissions.isNotEmpty,
                                            );
                                        final calculatedStatus =
                                            _computeRoomStatus(r, lookup);

                                        Color statusColor;
                                        IconData statusIcon;
                                        switch (calculatedStatus) {
                                          case 'Assigned':
                                            statusColor = const Color(
                                              0xFF10B981,
                                            );
                                            statusIcon =
                                                Icons.check_circle_outline;
                                            break;
                                          case 'Unassigned':
                                          default:
                                            statusColor = const Color(
                                              0xFF64748B,
                                            );
                                            statusIcon =
                                                Icons.pause_circle_outline;
                                            break;
                                        }

                                        return DataRow(
                                          cells: [
                                            // 1. Room Number (clickable to Room Details)
                                            DataCell(
                                              InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                onTap: () => setState(
                                                  () => _selectedRoomId = r.id,
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 6,
                                                        horizontal: 2,
                                                      ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isLab
                                                            ? Icons
                                                                  .science_outlined
                                                            : Icons
                                                                  .meeting_room_outlined,
                                                        size: 16,
                                                        color: isLab
                                                            ? const Color(
                                                                0xFF3B82F6,
                                                              )
                                                            : const Color(
                                                                0xFF10B981,
                                                              ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        r.name,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 13,
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFF38BDF8,
                                                                )
                                                              : const Color(
                                                                  0xFF0284C7,
                                                                ),
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // 2. Room Type
                                            DataCell(
                                              Text(
                                                r.roomType.isNotEmpty
                                                    ? r.roomType
                                                    : 'Theory',
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark
                                                      ? const Color(0xFFCBD5E1)
                                                      : const Color(0xFF334155),
                                                ),
                                              ),
                                            ),

                                            // 3. Floor
                                            DataCell(
                                              Text(
                                                floorStr,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark
                                                      ? const Color(0xFFCBD5E1)
                                                      : const Color(0xFF334155),
                                                ),
                                              ),
                                            ),

                                            // 4. Assigned Class / Sections (clickable to Academic Class)
                                            DataCell(
                                              primaryClassId != null &&
                                                      assignedStr !=
                                                          'Unassigned'
                                                  ? InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                      onTap: () {
                                                        widget.onOpenClass
                                                            ?.call(
                                                              primaryClassId,
                                                            );
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 4,
                                                              horizontal: 2,
                                                            ),
                                                        child: Text(
                                                          assignedStr,
                                                          style: TextStyle(
                                                            fontSize: 12.5,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: isDark
                                                                ? const Color(
                                                                    0xFF38BDF8,
                                                                  )
                                                                : const Color(
                                                                    0xFF0284C7,
                                                                  ),
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : Text(
                                                      assignedStr,
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color: isDark
                                                            ? const Color(
                                                                0xFF64748B,
                                                              )
                                                            : const Color(
                                                                0xFF94A3B8,
                                                              ),
                                                      ),
                                                    ),
                                            ),

                                            // 5. Total (Class Strength / Room Capacity) (clickable to Academic Class page)
                                            DataCell(
                                              InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                onTap: () {
                                                  // Navigates directly to Academic Class page
                                                  widget.onOpenClass?.call(
                                                    primaryClassId,
                                                  );
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 4,
                                                        horizontal: 2,
                                                      ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        '$classStrength / ${r.capacity}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 12.5,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFF38BDF8,
                                                                )
                                                              : const Color(
                                                                  0xFF0284C7,
                                                                ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 1),
                                                      Text(
                                                        'Class Strength: $classStrength',
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFF94A3B8,
                                                                )
                                                              : const Color(
                                                                  0xFF64748B,
                                                                ),
                                                        ),
                                                      ),
                                                      Text(
                                                        'Students Enrolled: $actualEnrolled',
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFF94A3B8,
                                                                )
                                                              : const Color(
                                                                  0xFF64748B,
                                                                ),
                                                        ),
                                                      ),
                                                      Text(
                                                        '$availableSeats Seats Available',
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              availableSeats <=
                                                                  0
                                                              ? const Color(
                                                                  0xFFEF4444,
                                                                )
                                                              : const Color(
                                                                  0xFF10B981,
                                                                ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // 6. Status
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: statusColor
                                                        .withValues(
                                                          alpha: 0.28,
                                                        ),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      statusIcon,
                                                      size: 13,
                                                      color: statusColor,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      calculatedStatus,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: statusColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // 7. Actions
                                            if (perms.canManageClassrooms)
                                              DataCell(
                                                PopupMenuButton<String>(
                                                  icon: const Icon(
                                                    Icons.more_vert,
                                                    size: 18,
                                                    color: Colors.grey,
                                                  ),
                                                  tooltip: 'Actions',
                                                  padding: EdgeInsets.zero,
                                                  itemBuilder: (ctx) => [
                                                    const PopupMenuItem(
                                                      value: 'view',
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .visibility_outlined,
                                                            size: 15,
                                                            color: Color(
                                                              0xFF109F83,
                                                            ),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            'View',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuItem(
                                                      value: 'edit',
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.edit_outlined,
                                                            size: 15,
                                                            color: Color(
                                                              0xFF3B82F6,
                                                            ),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            'Edit',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    PopupMenuItem(
                                                      value: 'toggle_status',
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            r.isAvailable
                                                                ? Icons
                                                                      .block_outlined
                                                                : Icons
                                                                      .check_circle_outline,
                                                            size: 15,
                                                            color: r.isAvailable
                                                                ? const Color(
                                                                    0xFFEF4444,
                                                                  )
                                                                : const Color(
                                                                    0xFF10B981,
                                                                  ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            r.isAvailable
                                                                ? 'Deactivate (Not Available)'
                                                                : 'Activate (Available)',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuItem(
                                                      value: 'delete',
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .delete_outline,
                                                            size: 15,
                                                            color: Colors.red,
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            'Delete',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                  onSelected: (action) async {
                                                    if (action == 'view') {
                                                      _showRoomDetailsDialog(
                                                        context,
                                                        r,
                                                      );
                                                    } else if (action ==
                                                        'edit') {
                                                      _openRoomModal(
                                                        context,
                                                        ref,
                                                        existing: r,
                                                      );
                                                    } else if (action ==
                                                        'toggle_status') {
                                                      final nextStatus =
                                                          r.isAvailable
                                                          ? 'Not Available'
                                                          : 'Available';
                                                      await runClassesAction(
                                                        context,
                                                        () => ref
                                                            .read(
                                                              classroomControllerProvider
                                                                  .notifier,
                                                            )
                                                            .save(
                                                              r.copyWith(
                                                                status:
                                                                    nextStatus,
                                                              ),
                                                              isNew: false,
                                                            ),
                                                        success:
                                                            nextStatus ==
                                                                'Available'
                                                            ? 'Classroom "${r.name}" activated (Available)'
                                                            : 'Classroom "${r.name}" marked as Not Available',
                                                      );
                                                    } else if (action ==
                                                        'delete') {
                                                      if (await confirmDelete(
                                                        context,
                                                        r.name,
                                                      )) {
                                                        if (!context.mounted) {
                                                          return;
                                                        }
                                                        await runClassesAction(
                                                          context,
                                                          () => ref
                                                              .read(
                                                                classroomControllerProvider
                                                                    .notifier,
                                                              )
                                                              .delete(r.id),
                                                          success:
                                                              'Classroom "${r.name}" deleted',
                                                        );
                                                      }
                                                    }
                                                  },
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
          ],
        ),
      ),
    );
  }

  Widget _buildClassroomDetailsView(
    ClassroomModel r,
    ClassesLookup lookup,
    List<StudentAdmissionModel> allAdmissions,
    ClassesPermissions perms,
    bool isDark,
    bool isMobile,
  ) {
    final classStrength = _computeClassStrength(r, lookup);
    final actualEnrolled = _computeActualEnrolledStudents(
      r,
      lookup,
      allAdmissions,
    );
    final availableSeats = _computeAvailableSeats(
      r,
      actualEnrolled,
      classStrength,
      allAdmissions.isNotEmpty,
    );
    final calculatedStatus = _computeRoomStatus(r, lookup);

    final floorStr = r.displayFloor.isNotEmpty && r.displayFloor != '—'
        ? r.displayFloor
        : 'Ground Floor';
    final assignedSections = lookup.sections
        .where((s) => s.classroomId == r.id)
        .toList();
    final assignedClasses = lookup.classes
        .where(
          (c) =>
              c.classroomId == r.id &&
              !assignedSections.any((s) => s.classId == c.id),
        )
        .toList();

    // Unique students in assigned sections and classes
    final countedStudents = <StudentAdmissionModel>[];
    final countedIds = <String>{};
    for (final s in assignedSections) {
      final secAdmissions = allAdmissions.where((a) {
        if (countedIds.contains(a.user.id)) return false;
        final matchesSectionId = a.student.sectionId == s.id;
        final normStudentClass = a.student.className
            .toLowerCase()
            .replaceAll('class', '')
            .replaceAll('th', '')
            .replaceAll('st', '')
            .replaceAll('nd', '')
            .replaceAll('rd', '')
            .trim();
        final normSectionClass = lookup
            .className(s.classId)
            .toLowerCase()
            .replaceAll('class', '')
            .replaceAll('th', '')
            .replaceAll('st', '')
            .replaceAll('nd', '')
            .replaceAll('rd', '')
            .trim();
        final matchesClassAndSec =
            (a.student.currentClassId == s.classId ||
                normStudentClass == normSectionClass) &&
            a.student.section.toUpperCase() == s.name.toUpperCase();
        return matchesSectionId || matchesClassAndSec;
      });
      for (final a in secAdmissions) {
        countedIds.add(a.user.id);
        countedStudents.add(a);
      }
    }
    for (final c in assignedClasses) {
      final classAdmissions = allAdmissions.where((a) {
        if (countedIds.contains(a.user.id)) return false;
        final matchesId = a.student.currentClassId == c.id;
        final normStudentClass = a.student.className
            .toLowerCase()
            .replaceAll('class', '')
            .replaceAll('th', '')
            .replaceAll('st', '')
            .replaceAll('nd', '')
            .replaceAll('rd', '')
            .trim();
        final normClassName = c.name
            .toLowerCase()
            .replaceAll('class', '')
            .replaceAll('th', '')
            .replaceAll('st', '')
            .replaceAll('nd', '')
            .replaceAll('rd', '')
            .trim();
        return matchesId ||
            (normStudentClass.isNotEmpty && normStudentClass == normClassName);
      });
      for (final a in classAdmissions) {
        countedIds.add(a.user.id);
        countedStudents.add(a);
      }
    }

    final statusColor = calculatedStatus == 'Assigned'
        ? const Color(0xFF10B981)
        : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Navigation Bar & Back Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Classroom Details: ${r.name}',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dashboard / Classes / Classrooms / ${r.name}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() => _selectedRoomId = null),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Classroom Inventory'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Summary Metric Cards
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricCard(
              'Room Number',
              r.name,
              Icons.meeting_room_outlined,
              const Color(0xFF109F83),
              isDark,
            ),
            _buildMetricCard(
              'Room Type',
              r.roomType.isNotEmpty ? r.roomType : 'Theory',
              Icons.category_outlined,
              const Color(0xFF8B5CF6),
              isDark,
            ),
            _buildMetricCard(
              'Floor',
              floorStr,
              Icons.layers_outlined,
              const Color(0xFF3B82F6),
              isDark,
            ),
            _buildMetricCard(
              'Capacity',
              '${r.capacity} Seats',
              Icons.chair_outlined,
              const Color(0xFF6366F1),
              isDark,
            ),
            _buildMetricCard(
              'Class Strength / Room Capacity',
              '$classStrength / ${r.capacity}',
              Icons.groups_outlined,
              const Color(0xFFEC4899),
              isDark,
            ),
            _buildMetricCard(
              'Enrolled Students',
              '$actualEnrolled Students',
              Icons.people_outline,
              const Color(0xFFF59E0B),
              isDark,
            ),
            _buildMetricCard(
              'Available Seats',
              '$availableSeats Seats',
              Icons.event_seat_outlined,
              const Color(0xFF10B981),
              isDark,
            ),
            if (r.building.isNotEmpty)
              _buildMetricCard(
                'Building',
                r.building,
                Icons.business_outlined,
                const Color(0xFF64748B),
                isDark,
              ),
            _buildMetricCard(
              'Status',
              calculatedStatus,
              Icons.info_outline,
              statusColor,
              isDark,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Assigned Classes and Sections Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assigned Classes & Sections',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              if (assignedSections.isEmpty && assignedClasses.isEmpty)
                Text(
                  'No classes or sections are currently assigned to this classroom.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                )
              else ...[
                for (final s in assignedSections) ...[
                  Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.class_outlined,
                        color: Color(0xFF109F83),
                      ),
                      title: Text(
                        '${lookup.className(s.classId)} — Section ${s.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Builder(
                        builder: (context) {
                          final parentClass = lookup.classes
                              .where((c) => c.id == s.classId)
                              .firstOrNull;
                          final secCap =
                              (parentClass != null && parentClass.capacity > 0)
                              ? (s.capacity > 0 &&
                                        s.capacity != r.capacity &&
                                        s.capacity != 40
                                    ? s.capacity
                                    : parentClass.capacity)
                              : (s.capacity > 0
                                    ? s.capacity
                                    : (parentClass?.capacity ?? 0));
                          return Text(
                            'Class Teacher: ${lookup.teacherName(s.classTeacherId)} | Capacity: ${secCap > 0 ? secCap : "Standard"}',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                      trailing: Chip(
                        label: Text(s.status),
                        backgroundColor: s.status.toLowerCase() == 'active'
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                      ),
                      onTap: () {
                        widget.onOpenClass?.call(s.classId);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                ],
                for (final c in assignedClasses) ...[
                  Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.school_outlined,
                        color: Color(0xFF3B82F6),
                      ),
                      title: Text(
                        '${c.name} (${c.code.isNotEmpty ? c.code : "Standard"})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        'Academic Year: ${c.academicYear} | Strength: ${c.capacity}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Chip(
                        label: Text(c.status),
                        backgroundColor: c.status.toLowerCase() == 'active'
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                      ),
                      onTap: () {
                        widget.onOpenClass?.call(c.id);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Enrolled Students Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enrolled Students (${countedStudents.length})',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              if (countedStudents.isEmpty)
                Text(
                  'No students enrolled in the assigned classes/sections yet.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: countedStudents.length,
                  separatorBuilder: (ctx, idx) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final adm = countedStudents[idx];
                    return Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(
                            0xFF109F83,
                          ).withValues(alpha: 0.1),
                          child: Text(
                            adm.user.firstName.isNotEmpty
                                ? adm.user.firstName[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF109F83),
                            ),
                          ),
                        ),
                        title: Text(
                          '${adm.user.firstName} ${adm.user.lastName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          'Adm No: ${adm.student.admissionNumber} | Class: ${adm.student.className} | Sec: ${adm.student.section}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Text(
                          adm.student.enrollmentStatus.displayName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRoomDetailsDialog(BuildContext context, ClassroomModel r) {
    final lookup = ref.read(classesLookupProvider);
    final assigned = lookup.roomAssignmentSummary(r.id);
    final allAdmissions =
        ref.read(admissionsListProvider).valueOrNull ?? const [];
    final classStrength = _computeClassStrength(r, lookup);
    final actualEnrolled = _computeActualEnrolledStudents(
      r,
      lookup,
      allAdmissions,
    );
    final availableSeats = _computeAvailableSeats(
      r,
      actualEnrolled,
      classStrength,
      allAdmissions.isNotEmpty,
    );
    final calculatedStatus = _computeRoomStatus(r, lookup);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isAssigned = calculatedStatus == 'Assigned';
    final statusColor = isAssigned
        ? const Color(0xFF10B981)
        : const Color(0xFF64748B);
    final statusIcon = isAssigned
        ? Icons.check_circle_outline
        : Icons.pause_circle_outline;

    final floorStr = r.displayFloor.isNotEmpty && r.displayFloor != '—'
        ? r.displayFloor
        : 'Ground Floor';
    final assignedStr = (assigned != null && assigned.isNotEmpty)
        ? assigned
        : 'Unassigned';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.meeting_room_outlined,
              color: Color(0xFF109F83),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Classroom: ${r.name}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Room Number', r.name, isDark),
              const SizedBox(height: 10),
              _detailRow(
                'Room Type',
                r.roomType.isNotEmpty ? r.roomType : 'Theory',
                isDark,
              ),
              const SizedBox(height: 10),
              _detailRow('Floor', floorStr, isDark),
              const SizedBox(height: 10),
              _detailRow('Assigned Class / Sections', assignedStr, isDark),
              const SizedBox(height: 10),
              _detailRow(
                'Total (Class Strength / Room Capacity)',
                '$classStrength / ${r.capacity}',
                isDark,
              ),
              const SizedBox(height: 10),
              _detailRow('Class Strength', '$classStrength Seats', isDark),
              const SizedBox(height: 10),
              _detailRow(
                'Enrolled Students',
                '$actualEnrolled Students',
                isDark,
              ),
              const SizedBox(height: 10),
              _detailRow('Available Seats', '$availableSeats Seats', isDark),
              const SizedBox(height: 10),
              _detailRow(
                'Status',
                calculatedStatus,
                isDark,
                isStatus: true,
                statusColor: statusColor,
                statusIcon: statusIcon,
              ),
              if (r.building.isNotEmpty) ...[
                const SizedBox(height: 10),
                _detailRow('Building', r.building, isDark),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF109F83),
            ),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _openRoomModal(context, ref, existing: r);
            },
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
    bool isDark, {
    bool isStatus = false,
    Color? statusColor,
    IconData? statusIcon,
  }) {
    final effectiveColor = statusColor ?? const Color(0xFF10B981);
    final effectiveIcon = statusIcon ?? Icons.check_circle_outline;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: isStatus
              ? Row(
                  children: [
                    Icon(effectiveIcon, size: 13, color: effectiveColor),
                    const SizedBox(width: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: effectiveColor,
                      ),
                    ),
                  ],
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
        ),
      ],
    );
  }

  /// Inline modal form to add or edit classroom directly on page
  Future<void> _openRoomModal(
    BuildContext context,
    WidgetRef ref, {
    ClassroomModel? existing,
  }) => openRoomModal(context, ref, existing: existing);
}

/// Modal for creating or editing a classroom with fields in exact order:
/// 1. Room Number
/// 2. Room Type (Theory, Practical, Others -> custom text field)
/// 3. Floor
/// 4. Total Seats (Room Capacity)
/// 5. Status (Display auto-calculated status; user cannot manually override)
Future<void> openRoomModal(
  BuildContext context,
  WidgetRef ref, {
  ClassroomModel? existing,
}) async {
  final nameCtrl = TextEditingController(text: existing?.name ?? '');

  // Room Type dropdown options: Theory, Practical, Others
  String selectedRoomTypeOption;
  final customRoomTypeCtrl = TextEditingController();

  if (existing == null) {
    selectedRoomTypeOption = 'Theory';
  } else if (existing.roomType == 'Theory' ||
      existing.roomType == 'Practical') {
    selectedRoomTypeOption = existing.roomType;
  } else {
    selectedRoomTypeOption = 'Others';
    customRoomTypeCtrl.text = existing.roomType;
  }

  final floorCtrl = TextEditingController(
    text: existing?.floor.isNotEmpty == true
        ? existing!.floor
        : (existing != null && existing.displayFloor != '—'
              ? existing.displayFloor
              : ''),
  );

  final capacityCtrl = TextEditingController(
    text: existing == null ? '' : '${existing.capacity}',
  );
  var selectedAssignmentStatus = 'Unassigned';

  // Assignment status is derived from actual class and section usage.
  final lookup = ref.read(classesLookupProvider);

  String initialCalculatedStatus = 'Unassigned';
  if (existing != null) {
    final assignedSection = lookup.sections.any(
      (section) => section.classroomId == existing.id,
    );
    final assignedClass = lookup.classes.any(
      (classModel) => classModel.classroomId == existing.id,
    );
    initialCalculatedStatus = assignedSection || assignedClass
        ? 'Assigned'
        : 'Unassigned';
  }

  String? formError;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final statusColor = initialCalculatedStatus == 'Assigned'
            ? const Color(0xFF10B981)
            : const Color(0xFF64748B);
        final statusIcon = initialCalculatedStatus == 'Assigned'
            ? Icons.check_circle_outline
            : Icons.pause_circle_outline;

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                existing == null
                    ? Icons.add_circle_outline
                    : Icons.edit_outlined,
                color: const Color(0xFF109F83),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                existing == null ? 'Add Classroom' : 'Edit Classroom',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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

                  // 1. Room Number
                  const Text(
                    'Room Number',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 205',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Room Type (Theory, Practical, Others)
                  const Text(
                    'Room Type',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRoomTypeOption,
                    items: const [
                      DropdownMenuItem(
                        value: 'Theory',
                        child: Text('Theory', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'Practical',
                        child: Text(
                          'Practical',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Others',
                        child: Text('Others', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRoomTypeOption = val);
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                  if (selectedRoomTypeOption == 'Others') ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Custom Room Type',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: customRoomTypeCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Enter custom room type (e.g. Computer Lab)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // 3. Floor
                  const Text(
                    'Floor',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: floorCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 1st Floor',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Total Seats (Room Capacity)
                  const Text(
                    'Total Seats (Room Capacity)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: capacityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '40',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. Assignment Status
                  const Text(
                    'Assignment Status',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  if (existing == null)
                    DropdownButtonFormField<String>(
                      initialValue: selectedAssignmentStatus,
                      items: const [
                        DropdownMenuItem(
                          value: 'Assigned',
                          child: Text('Assigned'),
                        ),
                        DropdownMenuItem(
                          value: 'Unassigned',
                          child: Text('Unassigned'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(
                            () => selectedAssignmentStatus = value,
                          );
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  initialCalculatedStatus,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Assignment status is calculated from current class and section usage.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (existing == null) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Status updates automatically from class and section assignments.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
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
                if (name.isEmpty) {
                  setDialogState(() => formError = 'Room number is required');
                  return;
                }

                // Determine final room type
                String finalRoomType = selectedRoomTypeOption;
                if (selectedRoomTypeOption == 'Others') {
                  final customType = customRoomTypeCtrl.text.trim();
                  if (customType.isEmpty) {
                    setDialogState(
                      () => formError =
                          'Please enter a custom room type when "Others" is selected.',
                    );
                    return;
                  }
                  finalRoomType = customType;
                }

                final capacity = int.tryParse(capacityCtrl.text.trim());
                if (capacity == null || capacity <= 0) {
                  setDialogState(
                    () => formError =
                        'Enter total seats (capacity) greater than zero.',
                  );
                  return;
                }

                try {
                  final model = ClassroomModel(
                    id: existing?.id ?? '',
                    name: name,
                    building: existing?.building ?? '',
                    capacity: capacity,
                    floor: floorCtrl.text.trim(),
                    roomType: finalRoomType,
                    status: existing == null
                        ? selectedAssignmentStatus
                        : existing.status,
                  );
                  await ref
                      .read(classroomControllerProvider.notifier)
                      .save(model, isNew: existing == null);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    showCompactSnackBar(
                      context,
                      existing == null
                          ? 'Classroom registered'
                          : 'Classroom updated',
                    );
                  }
                } catch (e) {
                  setDialogState(() {
                    formError = e
                        .toString()
                        .replaceAll('Exception:', '')
                        .trim();
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
