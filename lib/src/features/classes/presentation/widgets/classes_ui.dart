import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/src/commonwidgets/empty_state_view.dart';
import 'package:frontend/src/commonwidgets/error_state_view.dart';
import 'package:frontend/src/commonwidgets/loading_indicator.dart';

/// Renders an AsyncValue list with the app's shared loading / error / empty views.
class AsyncListBody<T> extends StatelessWidget {
  final AsyncValue<List<T>> value;
  final Widget Function(List<T> items) builder;
  final VoidCallback onRetry;
  final String emptyTitle;
  final String? emptySubtitle;
  final Widget? emptyAction;

  const AsyncListBody({
    super.key,
    required this.value,
    required this.builder,
    required this.onRetry,
    required this.emptyTitle,
    this.emptySubtitle,
    this.emptyAction,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorStateView(message: e.toString(), onRetry: onRetry),
      data: (items) => items.isEmpty
          ? EmptyStateView(
              title: emptyTitle,
              subtitle: emptySubtitle,
              action: emptyAction,
            )
          : builder(items),
    );
  }
}

/// Centers content and caps width so tablet/desktop layouts do not stretch.
class ClassesPageFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;

  const ClassesPageFrame({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                spacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                  if (actions.isNotEmpty)
                    Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown instead of a screen when the signed-in role is not allowed to see it.
/// Screens wrap themselves in this so direct navigation cannot bypass the tabs.
class AccessGuard extends StatelessWidget {
  final bool allowed;
  final Widget child;
  const AccessGuard({super.key, required this.allowed, required this.child});

  @override
  Widget build(BuildContext context) {
    if (allowed) return child;
    return const EmptyStateView(
      title: 'Access restricted',
      subtitle: 'Your role does not have permission to view this screen.',
      icon: Icons.lock_outline,
    );
  }
}

/// Compact, readable SnackBar styled to avoid unnecessary screen space.
SnackBar buildCompactSnackBar(
  String message, {
  Color? backgroundColor,
  IconData icon = Icons.check_circle_outline,
  Duration duration = const Duration(seconds: 2),
}) {
  return SnackBar(
    content: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
    backgroundColor: backgroundColor ?? const Color(0xFF109F83),
    behavior: SnackBarBehavior.floating,
    width: 300,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    duration: duration,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  );
}

void showCompactSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  IconData icon = Icons.check_circle_outline,
  Duration duration = const Duration(seconds: 2),
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    buildCompactSnackBar(
      message,
      backgroundColor: backgroundColor,
      icon: icon,
      duration: duration,
    ),
  );
}

/// Runs a mutation and surfaces permission / validation errors with compact notifications.
Future<bool> runClassesAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) {
      showCompactSnackBar(context, success);
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      showCompactSnackBar(
        context,
        e
            .toString()
            .replaceAll('Exception:', '')
            .replaceAll('ClassesDataException:', '')
            .trim(),
        backgroundColor: Colors.red.shade700,
        icon: Icons.error_outline,
      );
    }
    return false;
  }
}

Future<bool> confirmDelete(BuildContext context, String what) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Delete $what?'),
      content: const Text(
        'This also removes data that depends on it and cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Small dropdown helper used by the admin forms.
class IdDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final Map<String, String> options;
  final bool allowNone;
  final ValueChanged<String?> onChanged;

  const IdDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.allowNone = true,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = options.containsKey(value) ? value : null;
    return DropdownButtonFormField<String?>(
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (allowNone)
          const DropdownMenuItem<String?>(value: null, child: Text('None')),
        for (final e in options.entries)
          DropdownMenuItem<String?>(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Searchable picker that stores the selected item's **id** (not its label).
/// Tap to expand the list directly under the field (no popup box) and type to
/// filter (case-insensitive). Options in [disabled] (id -> reason) stay visible
/// but cannot be picked, e.g. a room already assigned to another class.
class SearchableIdDropdown extends StatefulWidget {
  final String label;
  final String? value;
  final Map<String, String> options;
  final Map<String, String> disabled;
  final bool allowNone;
  final String noneLabel;
  final String? hint;
  final bool inlineLabel;
  final ValueChanged<String?> onChanged;

  const SearchableIdDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.disabled = const {},
    this.allowNone = true,
    this.noneLabel = 'None',
    this.hint,
    this.inlineLabel = true,
  });

  @override
  State<SearchableIdDropdown> createState() => _SearchableIdDropdownState();
}

class _SearchableIdDropdownState extends State<SearchableIdDropdown> {
  bool _open = false;
  String _q = '';
  String? _pendingSelectedId;
  bool _hasPendingSelection = false;
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _selectedLabel);
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  String get _selectedLabel =>
      widget.options[_hasPendingSelection
          ? _pendingSelectedId
          : widget.value] ??
      '';

  @override
  void didUpdateWidget(covariant SearchableIdDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    final valueChanged = oldWidget.value != widget.value;
    final optionsChanged = !_sameOptions(oldWidget.options, widget.options);
    if (valueChanged) {
      _hasPendingSelection = false;
    }
    if (_hasPendingSelection &&
        !widget.options.containsKey(_pendingSelectedId)) {
      _hasPendingSelection = false;
    }
    if ((valueChanged || optionsChanged) && !_focusNode.hasFocus) {
      _searchController.text = _selectedLabel;
    }
  }

  bool _sameOptions(Map<String, String> first, Map<String, String> second) {
    if (identical(first, second)) return true;
    if (first.length != second.length) return false;
    for (final entry in first.entries) {
      if (second[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    // Do NOT close the list here. On web/desktop, pressing an option moves
    // focus away from the text field *before* the tap completes; closing here
    // removed the option and the selection was never made. The list is closed
    // by _pick() or by a tap outside the whole widget (see TapRegion below).
    if (_focusNode.hasFocus && !_open) {
      setState(() {
        _open = true;
        _q = '';
      });
    }
  }

  void _closeList() {
    if (!_open) return;
    setState(() {
      _open = false;
      _q = '';
      _searchController.text = _selectedLabel;
    });
  }

  void _openSearch() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
    setState(() {
      _open = true;
      _q = '';
    });
  }

  void _pick(String? id) {
    if (id != null && !widget.options.containsKey(id)) return;
    if (id != null && widget.disabled.containsKey(id)) return;
    _pendingSelectedId = id;
    _hasPendingSelection = true;
    widget.onChanged(id);
    setState(() {
      _open = false;
      _q = '';
      _searchController.text = id == null ? '' : widget.options[id] ?? '';
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final entries = widget.options.entries.where((e) {
      final assignment = widget.disabled[e.key] ?? '';
      return q.isEmpty ||
          e.value.toLowerCase().contains(q) ||
          assignment.toLowerCase().contains(q);
    }).toList();
    final border = Theme.of(context).dividerColor;
    // TapRegion: a tap anywhere inside the field or its option list is
    // "inside"; only a tap outside the whole widget closes the list.
    return TapRegion(
      onTapOutside: (_) {
        if (_open) {
          _focusNode.unfocus();
          _closeList();
        }
      },
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onTapOutside: (_) {},
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: widget.inlineLabel ? widget.label : null,
            hintText: widget.hint ?? 'Select ${widget.label}',
            prefixIcon: _open ? const Icon(Icons.search, size: 18) : null,
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              tooltip: _open ? 'Close suggestions' : 'Show suggestions',
              onPressed: () {
                if (_open) {
                  _focusNode.unfocus();
                  _closeList();
                } else {
                  _openSearch();
                }
              },
              icon: Icon(
                _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
              ),
            ),
          ),
          onTap: _openSearch,
          onChanged: (value) {
            setState(() {
              _q = value;
              _open = true;
            });
          },
        ),
        if (_open)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      if (widget.allowNone && q.isEmpty)
                        InkWell(
                          onTap: () => _pick(null),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.noneLabel,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      for (final e in entries)
                        Builder(
                          builder: (context) {
                            final disabled = widget.disabled.containsKey(e.key);
                            final selected =
                                e.key ==
                                (_hasPendingSelection
                                    ? _pendingSelectedId
                                    : widget.value);
                            return InkWell(
                              key: ValueKey('searchable-option-${e.key}'),
                              onTap: disabled ? null : () => _pick(e.key),
                              child: Container(
                                width: double.infinity,
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.08)
                                    : null,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.value,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: disabled
                                                  ? Theme.of(
                                                      context,
                                                    ).disabledColor
                                                  : null,
                                            ),
                                          ),
                                          if (disabled)
                                            Text(
                                              widget.disabled[e.key]!,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(Icons.check, size: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      if (entries.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'No matches',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
      ),
    );
  }
}

/// Rooms that cannot be picked for [classId]: Unavailable rooms, and rooms held by another class.
Map<String, String> roomsBlockedFor({
  required String? classId,
  required List<dynamic> classes,
  required List<dynamic> sections,
  required List<dynamic> classrooms,
}) {
  final blocked = <String, String>{};
  String nameOf(String id) {
    for (final c in classes) {
      if (c.id == id) return c.name as String;
    }
    return id;
  }

  for (final r in classrooms) {
    if (!(r.isAvailable as bool)) blocked[r.id as String] = 'Unavailable';
  }
  for (final c in classes) {
    final rid = c.classroomId as String?;
    if (rid != null && rid.isNotEmpty && c.id != classId)
      blocked.putIfAbsent(rid, () => 'Assigned to ${c.name}');
  }
  for (final s in sections) {
    final rid = s.classroomId as String?;
    if (rid != null && rid.isNotEmpty && s.classId != classId) {
      blocked.putIfAbsent(
        rid,
        () => 'Assigned to ${nameOf(s.classId as String)}',
      );
    }
  }
  return blocked;
}

const weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Column header with the same up/down sort arrows used in Room Inventory.
/// Tap the title to toggle, or tap the up (A→Z) / down (Z→A) arrow directly.
class SortableHeader extends StatelessWidget {
  final String title;
  final bool isSorted;
  final bool ascending;
  final VoidCallback onToggle;
  final VoidCallback onAscending;
  final VoidCallback onDescending;

  const SortableHeader({
    super.key,
    required this.title,
    required this.isSorted,
    required this.ascending,
    required this.onToggle,
    required this.onAscending,
    required this.onDescending,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final inactiveColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final textColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggle,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: isSorted ? activeColor : textColor,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAscending,
              child: Icon(
                Icons.arrow_drop_up,
                size: 16,
                color: isSorted && ascending ? activeColor : inactiveColor,
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDescending,
              child: Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: isSorted && !ascending ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
