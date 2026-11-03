import 'package:flutter/material.dart';

/// AdminShellLayout provides the structural shell for the /admin/* routes.
/// Inner screens in the admin module embed their own EdupluseScaffold
/// containing the Dr. Sarah Jenkins administrator sidebar.
class AdminShellLayout extends StatelessWidget {
  final Widget child;

  const AdminShellLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
