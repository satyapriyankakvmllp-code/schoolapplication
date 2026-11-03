import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'classes_lookup.dart';
import 'classes_ui.dart';

/// Set by [ClassesHubScreen]; opens the Staff Details page for a Staff Directory id.
final classesStaffNavigatorProvider =
    StateProvider<void Function(String staffId)?>((ref) => null);

/// Set by [ClassesHubScreen]; opens the Classroom page for a specific room id.
final classesRoomNavigatorProvider =
    StateProvider<void Function(String roomId)?>((ref) => null);

/// Teacher name that opens that teacher's existing Staff Details page when tapped.
/// The teacher is resolved from the Staff Directory (no copies / duplicate profiles).
class StaffLink extends ConsumerWidget {
  final String? teacherId;
  final String? text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const StaffLink({
    super.key,
    required this.teacherId,
    this.text,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(classesLookupProvider);
    final open = ref.watch(classesStaffNavigatorProvider);
    final id = teacherId;
    final base = style ?? const TextStyle(fontSize: 12);
    if (id == null || id.isEmpty) {
      return Text(text ?? 'Unassigned', style: base.copyWith(color: Colors.grey));
    }
    final label = text ?? lookup.teacherName(id);
    final staff = lookup.teacherById(id);
    if (staff == null || open == null) {
      return Text(label, style: base, maxLines: maxLines, overflow: overflow);
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => open(staff.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
        child: Text(
          label,
          maxLines: maxLines,
          overflow: overflow,
          style: base.copyWith(
            decoration: TextDecoration.underline,
            color: isDark ? const Color(0xFF34D399) : const Color(0xFF0D9488),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Room number that opens the details of that specific classroom when tapped.
class RoomLink extends ConsumerWidget {
  final String? roomId;
  final String? text;
  final TextStyle? style;

  const RoomLink({super.key, required this.roomId, this.text, this.style});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(classesLookupProvider);
    final open = ref.watch(classesRoomNavigatorProvider);
    final base = style ?? const TextStyle(fontSize: 12);
    final id = roomId;
    final hasRoom = id != null && id.isNotEmpty && lookup.classrooms.any((r) => r.id == id);
    final label = text ?? lookup.roomName(id);
    if (!hasRoom || open == null) {
      return Text(label, style: base);
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => open(id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
        child: Text(
          label,
          style: base.copyWith(
            decoration: TextDecoration.underline,
            color: isDark ? const Color(0xFF34D399) : const Color(0xFF0D9488),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Column-sort state shared by the Classes module tables.
class ColumnSort {
  int? column;
  bool ascending = true;

  bool isSorted(int c) => column == c;

  /// Tap on the title toggles; the up / down arrows pass [ascending] explicitly.
  void apply(int c, {bool? ascending}) {
    if (ascending != null) {
      column = c;
      this.ascending = ascending;
    } else if (column == c) {
      this.ascending = !this.ascending;
    } else {
      column = c;
      this.ascending = true;
    }
  }

  /// Applies the sign for the current direction to a comparison result.
  int dir(int cmp) => ascending ? cmp : -cmp;
}

/// Header with the same up / down arrows used in Room Inventory and Subjects.
Widget sortableHeader(ColumnSort sort, String title, int column, VoidCallback onChanged) {
  return SortableHeader(
    title: title,
    isSorted: sort.isSorted(column),
    ascending: sort.ascending,
    onToggle: () {
      sort.apply(column);
      onChanged();
    },
    onAscending: () {
      sort.apply(column, ascending: true);
      onChanged();
    },
    onDescending: () {
      sort.apply(column, ascending: false);
      onChanged();
    },
  );
}

/// Case-insensitive compare that orders numbers naturally ("Class 2" < "Class 10").
int naturalCompare(String a, String b) {
  final re = RegExp(r'(\d+)|(\D+)');
  final pa = re.allMatches(a.toLowerCase()).map((m) => m.group(0)!).toList();
  final pb = re.allMatches(b.toLowerCase()).map((m) => m.group(0)!).toList();
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    final nx = int.tryParse(pa[i]);
    final ny = int.tryParse(pb[i]);
    final c = (nx != null && ny != null) ? nx.compareTo(ny) : pa[i].compareTo(pb[i]);
    if (c != 0) return c;
  }
  return pa.length.compareTo(pb.length);
}
