import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_controller.dart';
import '../../authentication/domain/user_model.dart';

/// Permissions helper for the Fees module.
/// Only Admin and Finance roles can view or route to fees management.
bool canRoleAccessFees(UserRole? role) {
  return role == UserRole.admin || role == UserRole.finance;
}

final feesAccessProvider = Provider<bool>((ref) {
  final role = ref.watch(activeUserRoleProvider);
  return canRoleAccessFees(role);
});

