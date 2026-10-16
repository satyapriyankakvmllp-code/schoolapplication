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
          ? EmptyStateView(title: emptyTitle, subtitle: emptySubtitle, action: emptyAction)
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
                      Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                  if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: actions),
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

/// Runs a mutation and surfaces permission / validation errors as a snackbar.
Future<bool> runClassesAction(BuildContext context, Future<void> Function() action, {String? success}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    if (success != null) messenger.showSnackBar(SnackBar(content: Text(success)));
    return true;
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    return false;
  }
}

Future<bool> confirmDelete(BuildContext context, String what) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Delete $what?'),
      content: const Text('This also removes data that depends on it and cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
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
        if (allowNone) const DropdownMenuItem<String?>(value: null, child: Text('None')),
        for (final e in options.entries)
          DropdownMenuItem<String?>(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: onChanged,
    );
  }
}

const weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
