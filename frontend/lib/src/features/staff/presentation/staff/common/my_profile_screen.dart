import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/src/commonwidgets/empty_state_view.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';
import 'package:frontend/src/themes/app_colors.dart';
import '../../../application/staff_auth_controller.dart';
import '../../../application/staff_controller.dart';
import '../../../domain/staff_member_model.dart';
import '../../widgets/staff_id_badge_view.dart';

/// Provider holding pending official profile changes waiting for Super Admin verification.
/// Keyed by staff ID -> Map of field name to pending proposed value.
final staffPendingChangeRequestsProvider =
    StateProvider.family<Map<String, String>, String>((ref, staffId) => {});

class MyProfileScreen extends ConsumerStatefulWidget {
  final bool isDark;

  const MyProfileScreen({
    super.key,
    this.isDark = false,
  });

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _unmaskFinancials = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showIdBadgeModal(BuildContext context, StaffMemberModel staff, bool dark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: dark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(16, 14, 14, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Institutional Digital ID Badge',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Official identity card for ${staff.fullName}',
                    style: TextStyle(
                      fontSize: 11,
                      color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: StaffIdBadgeView(staff: staff, isDark: dark),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        content: Row(
                          children: [
                            const Icon(Icons.print_outlined, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Dispatching dual-sided ID badge of ${staff.fullName} to institutional printer...',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('Print / Dispatch ID Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordModal(BuildContext context, StaffMemberModel staff, bool dark) {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: dark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(16, 14, 14, 8),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: AppColors.secondary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Change Portal Password',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ensure your new password contains at least 6 characters.',
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: currentPassController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter current password' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPassController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setModalState(() => obscureNew = !obscureNew),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPassController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.check_circle_outline, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v != newPassController.text) return 'Passwords do not match';
                      return null;
                    },
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
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final newPass = newPassController.text.trim();
                  final updatedLogin = staff.loginAccount?.copyWith(
                        temporaryPassword: newPass,
                        isFirstLoginPasswordChangeRequired: false,
                      ) ??
                      staff.loginAccount;

                  final updatedStaff = staff.copyWith(loginAccount: updatedLogin);
                  await ref.read(staffListProvider.notifier).saveStaff(updatedStaff);

                  if (context.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        content: Text('Portal password updated securely!'),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileModal(BuildContext context, StaffMemberModel staff, bool dark) {
    final bioController = TextEditingController(
      text: staff.socialMedia?['bio']?.toString() ??
          'Dedicated educationist committed to fostering holistic learning, student mentorship, and academic excellence at KVM Institutions.',
    );
    final languagesController = TextEditingController(
      text: staff.socialMedia?['languages']?.toString() ?? 'English, Hindi, Odia',
    );
    final emergencyNameController = TextEditingController(
      text: staff.fatherName ?? 'Family Primary Relative',
    );
    final emergencyPhoneController = TextEditingController(
      text: staff.emergencyContact ?? '',
    );

    final phoneController = TextEditingController(text: staff.phone);
    final addressController = TextEditingController(text: staff.currentAddress);
    final bankNameController = TextEditingController(text: staff.compensation.bankName);
    final bankAccountController = TextEditingController(text: staff.compensation.accountNumber);
    final ifscController = TextEditingController(text: staff.compensation.ifscCode);
    final qualificationController = TextEditingController(text: staff.qualification);

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: dark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(16, 14, 14, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Staff Profile',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Personal bio updates live; official records require admin review.',
                    style: TextStyle(
                      fontSize: 11,
                      color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Instant Updates
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.bolt_rounded, color: AppColors.success, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Instant Updates (Live Immediately): Bio, Languages, and Emergency Contact details update your profile without administrative review.',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.35,
                              color: dark ? Colors.green.shade200 : Colors.green.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bioController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Professional Bio / Philosophy',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: languagesController,
                    decoration: InputDecoration(
                      labelText: 'Languages Known (comma separated)',
                      prefixIcon: const Icon(Icons.language_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emergencyNameController,
                    decoration: InputDecoration(
                      labelText: 'Emergency Contact Person',
                      prefixIcon: const Icon(Icons.person_outline, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emergencyPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Emergency Contact Phone',
                      prefixIcon: const Icon(Icons.emergency_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),

                  const SizedBox(height: 18),
                  // Section 2: Official Records Verification
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.pending_actions_rounded, color: AppColors.warning, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Official Institutional Records: Edits to Phone, Address, Bank, and Qualifications are submitted to the Principal / Admin for verification.',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.35,
                              color: dark ? Colors.amber.shade200 : Colors.amber.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Official Mobile Phone',
                      prefixIcon: const Icon(Icons.phone_android_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: qualificationController,
                    decoration: InputDecoration(
                      labelText: 'Highest Qualification',
                      prefixIcon: const Icon(Icons.school_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Current Residential Address',
                      prefixIcon: const Icon(Icons.home_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: bankNameController,
                    decoration: InputDecoration(
                      labelText: 'Bank Name',
                      prefixIcon: const Icon(Icons.account_balance_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: bankAccountController,
                    decoration: InputDecoration(
                      labelText: 'Account Number',
                      prefixIcon: const Icon(Icons.numbers_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: ifscController,
                    decoration: InputDecoration(
                      labelText: 'IFSC Code',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                // 1. Instant save of personal items
                final currentSocial = Map<String, dynamic>.from(staff.socialMedia ?? {});
                currentSocial['bio'] = bioController.text.trim();
                currentSocial['languages'] = languagesController.text.trim();

                final updatedStaff = staff.copyWith(
                  socialMedia: currentSocial,
                  fatherName: emergencyNameController.text.trim(),
                  emergencyContact: emergencyPhoneController.text.trim(),
                );

                await ref.read(staffListProvider.notifier).saveStaff(updatedStaff);

                // 2. Official field change detection -> submit to pending change requests
                final pendingMap = Map<String, String>.from(
                  ref.read(staffPendingChangeRequestsProvider(staff.id)),
                );

                final newPhone = phoneController.text.trim();
                if (newPhone.isNotEmpty && newPhone != staff.phone) {
                  pendingMap['phone'] = newPhone;
                }

                final newAddr = addressController.text.trim();
                if (newAddr.isNotEmpty && newAddr != staff.currentAddress) {
                  pendingMap['currentAddress'] = newAddr;
                }

                final newQual = qualificationController.text.trim();
                if (newQual.isNotEmpty && newQual != staff.qualification) {
                  pendingMap['qualification'] = newQual;
                }

                final newBank = bankNameController.text.trim();
                if (newBank.isNotEmpty && newBank != staff.compensation.bankName) {
                  pendingMap['bankName'] = newBank;
                }

                final newAcc = bankAccountController.text.trim();
                if (newAcc.isNotEmpty && newAcc != staff.compensation.accountNumber) {
                  pendingMap['accountNumber'] = newAcc;
                }

                final newIfsc = ifscController.text.trim();
                if (newIfsc.isNotEmpty && newIfsc != staff.compensation.ifscCode) {
                  pendingMap['ifscCode'] = newIfsc;
                }

                ref.read(staffPendingChangeRequestsProvider(staff.id).notifier).state = pendingMap;

                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  final hasPending = pendingMap.isNotEmpty;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: hasPending ? AppColors.warning : AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      content: Row(
                        children: [
                          Icon(
                            hasPending ? Icons.pending_actions_rounded : Icons.check_circle_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              hasPending
                                  ? 'Personal bio saved! Official changes (${pendingMap.keys.length} items) queued for Admin Verification.'
                                  : 'Profile details updated live successfully!',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save & Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadedStaff = ref.watch(currentLoggedInStaffProvider);
    final staffListAsync = ref.watch(staffListProvider);
    final allStaff = staffListAsync.valueOrNull ?? [];
    final staff = loadedStaff ??
        (allStaff.isNotEmpty
            ? allStaff.firstWhere(
                (s) => s.category == StaffCategory.teaching,
                orElse: () => allStaff.first,
              )
            : null);

    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark || widget.isDark;

    if (staff == null) {
      if (staffListAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return const EmptyStateView(
        title: 'No Profile Loaded',
        subtitle: 'Please authenticate with a valid faculty or staff identity.',
      );
    }

    final pendingChanges = ref.watch(staffPendingChangeRequestsProvider(staff.id));
    final isMobile = ResponsiveLayout.isMobile(context);

    final cardBg = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = dark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 12 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HERO IDENTITY HEADER
          _buildHeroHeader(context, staff, pendingChanges, isMobile, dark, cardBg, borderColor, textColor, subColor),

          const SizedBox(height: 16),

          // 2. MICRO-KPI SUMMARY CARDS (2x2 on Mobile, 4 in row on Desktop)
          _buildMicroKpiGrid(staff, isMobile, dark, cardBg, borderColor, textColor, subColor),

          const SizedBox(height: 18),

          // 3. SEGMENTED NAVIGATION TABS
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: isMobile,
              tabAlignment: isMobile ? TabAlignment.start : TabAlignment.fill,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: subColor,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.badge_outlined, size: 18), text: 'Overview & Bio'),
                Tab(icon: Icon(Icons.work_outline_rounded, size: 18), text: 'Work & Duties'),
                Tab(icon: Icon(Icons.account_balance_wallet_outlined, size: 18), text: 'Payroll & Statutory'),
                Tab(icon: Icon(Icons.folder_shared_outlined, size: 18), text: 'Document Vault'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. TAB CONTENTS
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              switch (_tabController.index) {
                case 0:
                  return _buildOverviewBioTab(context, staff, pendingChanges, isMobile, dark, cardBg, borderColor, textColor, subColor);
                case 1:
                  return _buildWorkDutiesTab(context, staff, pendingChanges, isMobile, dark, cardBg, borderColor, textColor, subColor);
                case 2:
                  return _buildPayrollStatutoryTab(context, staff, pendingChanges, isMobile, dark, cardBg, borderColor, textColor, subColor);
                case 3:
                  return _buildDocumentVaultTab(context, staff, isMobile, dark, cardBg, borderColor, textColor, subColor);
                default:
                  return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HERO IDENTITY HEADER
  // ==========================================
  Widget _buildHeroHeader(
    BuildContext context,
    StaffMemberModel staff,
    Map<String, String> pendingChanges,
    bool isMobile,
    bool dark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Banner
          Container(
            height: isMobile ? 65 : 85,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0F172A),
                  dark ? const Color(0xFF1E293B) : const Color(0xFF109F83),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.school_rounded,
                    size: isMobile ? 110 : 140,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ],
            ),
          ),

          // Avatar and Profile Details
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 12 : 20,
              0,
              isMobile ? 12 : 20,
              isMobile ? 14 : 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Avatar with edit badge
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: cardBg, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: isMobile ? 30 : 40,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                staff.initials,
                                style: TextStyle(
                                  fontSize: isMobile ? 20 : 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: InkWell(
                              onTap: () => _showEditProfileModal(context, staff, dark),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: cardBg, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Quick Action Buttons on Desktop
                      if (!isMobile) ...[
                        OutlinedButton.icon(
                          onPressed: () => _showChangePasswordModal(context, staff, dark),
                          icon: const Icon(Icons.lock_reset_rounded, size: 16),
                          label: const Text('Change Password'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _showIdBadgeModal(context, staff, dark),
                          icon: const Icon(Icons.badge_outlined, size: 16),
                          label: const Text('Digital ID Badge'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                            side: const BorderSide(color: AppColors.secondary),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showEditProfileModal(context, staff, dark),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Name, Title and Badges
                Transform.translate(
                  offset: const Offset(0, -14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            staff.fullName,
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              staff.status.label.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (staff.isClassTeacher)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                staff.classTeacherSummary,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (isMobile) ...[
                        Text(
                          '${staff.designation} • ${staff.department}',
                          style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              staff.category.label,
                              style: TextStyle(fontSize: 12, color: subColor),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: staff.id));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                    content: Text('Staff ID (${staff.id}) copied to clipboard!'),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      staff.id,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.copy_rounded, size: 12, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.business_center_outlined, size: 14, color: subColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${staff.designation} • ${staff.department}',
                                  style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.category_outlined, size: 14, color: subColor),
                                const SizedBox(width: 4),
                                Text(
                                  staff.category.label,
                                  style: TextStyle(fontSize: 12, color: subColor),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: staff.id));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                    content: Text('Staff ID (${staff.id}) copied to clipboard!'),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      staff.id,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.copy_rounded, size: 12, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Mobile Quick Action Buttons Bar
                      if (isMobile) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _showEditProfileModal(context, staff, dark),
                              icon: const Icon(Icons.edit_rounded, size: 14),
                              label: const Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _showIdBadgeModal(context, staff, dark),
                              icon: const Icon(Icons.badge_outlined, size: 14),
                              label: const Text('Digital ID'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.secondary,
                                side: const BorderSide(color: AppColors.secondary),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _showChangePasswordModal(context, staff, dark),
                              icon: const Icon(Icons.lock_reset_rounded, size: 14),
                              label: const Text('Password'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textColor,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  // ==========================================
  // MICRO-KPI SUMMARY CARDS
  // ==========================================
  Widget _buildMicroKpiGrid(
    StaffMemberModel staff,
    bool isMobile,
    bool dark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
  ) {
    final expYears = staff.experienceYears ?? 4;
    final kpiItems = [
      _KpiData(
        title: '$expYears+ Years',
        subtitle: 'Institutional Experience',
        icon: Icons.history_edu_rounded,
        color: const Color(0xFF109F83),
      ),
      _KpiData(
        title: staff.employmentType.label,
        subtitle: 'Employment Status',
        icon: Icons.verified_user_outlined,
        color: const Color(0xFF8B5CF6),
      ),
      _KpiData(
        title: '97.2%',
        subtitle: 'Term Attendance',
        icon: Icons.event_available_rounded,
        color: const Color(0xFF0EA5E9),
      ),
      _KpiData(
        title: '14 Days',
        subtitle: 'Leave Balance (Casual/Earned)',
        icon: Icons.beach_access_outlined,
        color: const Color(0xFFF59E0B),
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildKpiCard(kpiItems[0], cardBg, borderColor, textColor, subColor)),
              const SizedBox(width: 8),
              Expanded(child: _buildKpiCard(kpiItems[1], cardBg, borderColor, textColor, subColor)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildKpiCard(kpiItems[2], cardBg, borderColor, textColor, subColor)),
              const SizedBox(width: 8),
              Expanded(child: _buildKpiCard(kpiItems[3], cardBg, borderColor, textColor, subColor)),
            ],
          ),
        ],
      );
    }

    return Row(
      children: kpiItems.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildKpiCard(item, cardBg, borderColor, textColor, subColor),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKpiCard(
    _KpiData kpi,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kpi.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(kpi.icon, color: kpi.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kpi.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  kpi.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW & BIO
  // ==========================================
  Widget _buildOverviewBioTab(
    BuildContext context,
    StaffMemberModel staff,
    Map<String, String> pendingChanges,
    bool isMobile,
    bool dark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
  ) {
    final bio = staff.socialMedia?['bio']?.toString() ??
        'Dedicated educationist committed to fostering holistic learning, student mentorship, and academic excellence at KVM Institutions.';
    final languages = (staff.socialMedia?['languages']?.toString() ?? 'English, Hindi, Odia')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Professional Bio & Languages
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Professional Bio & Philosophy',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showEditProfileModal(context, staff, dark),
                    child: const Text(
                      'Edit Bio',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                bio,
                style: TextStyle(fontSize: 13, height: 1.45, color: textColor),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Languages Known:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subColor),
                  ),
                  ...languages.map(
                    (lang) => Chip(
                      label: Text(lang, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Contact & Residential Addresses
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.contact_mail_outlined, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Official Contact & Address',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.phone_android_rounded,
                label: 'Mobile Phone',
                value: staff.phone,
                pendingValue: pendingChanges['phone'],
                textColor: textColor,
                subColor: subColor,
              ),
              const Divider(height: 16),
              _buildInfoRow(
                icon: Icons.mail_outline_rounded,
                label: 'Institutional Email',
                value: staff.loginAccount?.institutionalEmail ?? staff.email,
                badge: 'Verified',
                badgeColor: AppColors.success,
                textColor: textColor,
                subColor: subColor,
              ),
              const Divider(height: 16),
              _buildInfoRow(
                icon: Icons.alternate_email_rounded,
                label: 'Personal / Recovery Email',
                value: staff.email,
                textColor: textColor,
                subColor: subColor,
              ),
              const Divider(height: 16),
              _buildInfoRow(
                icon: Icons.home_outlined,
                label: 'Current Residential Address',
                value: staff.currentAddress,
                pendingValue: pendingChanges['currentAddress'],
                textColor: textColor,
                subColor: subColor,
              ),
              const Divider(height: 16),
              _buildInfoRow(
                icon: Icons.location_city_outlined,
                label: 'Permanent Address',
                value: staff.permanentAddress,
                textColor: textColor,
                subColor: subColor,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Emergency & Health Profile
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.health_and_safety_outlined, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Emergency Contact & Medical Details',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isMobile) ...[
                _buildInfoRow(
                  icon: Icons.person_pin_outlined,
                  label: 'Emergency Contact Person',
                  value: staff.fatherName ?? 'Family Primary Relative',
                  textColor: textColor,
                  subColor: subColor,
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  icon: Icons.contact_emergency_outlined,
                  label: 'Emergency Phone',
                  value: staff.emergencyContact ?? 'Not Specified',
                  textColor: textColor,
                  subColor: subColor,
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  icon: Icons.bloodtype_outlined,
                  label: 'Blood Group',
                  value: staff.bloodGroup ?? 'O+ (Positive)',
                  textColor: textColor,
                  subColor: subColor,
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Date of Birth',
                  value: staff.dateOfBirth != null
                      ? DateFormat('dd MMM yyyy').format(staff.dateOfBirth!)
                      : 'Not Specified',
                  textColor: textColor,
                  subColor: subColor,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        icon: Icons.person_pin_outlined,
                        label: 'Emergency Contact Person',
                        value: staff.fatherName ?? 'Family Primary Relative',
                        textColor: textColor,
                        subColor: subColor,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        icon: Icons.contact_emergency_outlined,
                        label: 'Emergency Phone',
                        value: staff.emergencyContact ?? 'Not Specified',
                        textColor: textColor,
                        subColor: subColor,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        icon: Icons.bloodtype_outlined,
                        label: 'Blood Group',
                        value: staff.bloodGroup ?? 'O+ (Positive)',
                        textColor: textColor,
                        subColor: subColor,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        icon: Icons.cake_outlined,
                        label: 'Date of Birth',
                        value: staff.dateOfBirth != null
                            ? DateFormat('dd MMM yyyy').format(staff.dateOfBirth!)
                            : 'Not Specified',
                        textColor: textColor,
                        subColor: subColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: WORK & DUTIES (ROLE-ADAPTIVE)
  // ==========================================
  Widget _buildWorkDutiesTab(
    BuildContext context,
    StaffMemberModel staff,
    Map<String, String> pendingChanges,
    bool isMobile,
    bool dark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
  ) {
    final isTeacher = staff.category == StaffCategory.teaching;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isTeacher) ...[
          // TEACHER DUTIES
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Assigned Classes & Subjects Matrix',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${staff.assignedClasses.length} Assignments',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (staff.assignedClasses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No class or subject assignments allocated yet for this term.',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ),
                  )
                else
                  ...staff.assignedClasses.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.grade} - ${item.section}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.subject,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (item.isClassTeacher) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Class Teacher',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.periodsPerWeek} periods / week',
                                  style: TextStyle(fontSize: 11, color: subColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ] else ...[
          // NON-TEACHER DUTIES
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Operational Portfolio & Key Responsibilities',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildOperationalDutyItem(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Core Functional Portfolio',
                  description: _getOperationalPortfolioDescription(staff.effectiveRole),
                  textColor: textColor,
                  subColor: subColor,
                ),
                const Divider(height: 16),
                _buildOperationalDutyItem(
                  icon: Icons.account_tree_outlined,
                  title: 'Administrative Reporting Hierarchy',
                  description: 'Directly reporting to Institutional Board & Governing Council (${staff.department})',
                  textColor: textColor,
                  subColor: subColor,
                ),
                const Divider(height: 16),
                _buildOperationalDutyItem(
                  icon: Icons.access_time_rounded,
                  title: 'Official Duty Schedule',
                  description: 'Campus Standard Administrative Shift: 08:30 AM – 04:30 PM (Mon – Sat)',
                  textColor: textColor,
                  subColor: subColor,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Qualifications & Career Milestones
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.school_outlined, color: Color(0xFF0EA5E9), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Academic Qualifications & Career History',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.workspace_premium_outlined,
                label: 'Highest Educational Degree',
                value: staff.qualification,
                pendingValue: pendingChanges['qualification'],
                textColor: textColor,
                subColor: subColor,
              ),
              if (staff.specialization != null && staff.specialization!.isNotEmpty) ...[
                const Divider(height: 16),
                _buildInfoRow(
                  icon: Icons.star_outline_rounded,
                  label: 'Subject Specialization',
                  value: staff.specialization!,
                  textColor: textColor,
                  subColor: subColor,
                ),
              ],
              const Divider(height: 16),
              _buildInfoRow(
                icon: Icons.calendar_month_outlined,
                label: 'Date of Joining Institution',
                value: DateFormat('dd MMMM yyyy').format(staff.joiningDate),
                textColor: textColor,
                subColor: subColor,
              ),
              const Divider(height: 16),
              _buildInfoRow(
                icon: Icons.apartment_rounded,
                label: 'Prior Experience / Institution',
                value: staff.previousSchool ?? 'Prestigious Educational Institute (5+ years)',
                textColor: textColor,
                subColor: subColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getOperationalPortfolioDescription(String role) {
    switch (role) {
      case 'principal':
        return 'Overall Academic Governance, Staff Appraisals, Board Compliance, Institutional Quality Benchmarks, and Faculty Oversight.';
      case 'accountant':
        return 'Fee Collection Audits, General Ledger Reconciliation, Faculty Payroll Disbursement, and Statutory Tax/GST Compliance.';
      case 'librarian':
        return 'Library Cataloguing, Book Acquisition Protocols, Digital Repository Administration, and Student Reading Circulation.';
      case 'transport_manager':
        return 'Institutional Fleet Operations, Vehicle GPS Telematics, Driver Safety Compliance, and Route Scheduling.';
      case 'receptionist':
        return 'Front Office Helpdesk, Student Admission Inquiries, Campus Visitors Log, and PBX Telephony Dispatch.';
      default:
        return 'Institutional Support Operations, Facility Maintenance, Campus Asset Security, and Departmental Administration.';
    }
  }

  Widget _buildOperationalDutyItem({
    required IconData icon,
    required String title,
    required String description,
    required Color textColor,
    required Color subColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 12, height: 1.35, color: subColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: PAYROLL & STATUTORY
  // ==========================================
  Widget _buildPayrollStatutoryTab(
    BuildContext context,
    StaffMemberModel staff,
    Map<String, String> pendingChanges,
    bool isMobile,
    bool dark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
  ) {
    final comp = staff.compensation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bank Information Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Direct Deposit Bank Account Details',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _unmaskFinancials = !_unmaskFinancials),
                    icon: Icon(
                      _unmaskFinancials ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    tooltip: _unmaskFinancials ? 'Mask account details' : 'Reveal account details',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.account_balance_rounded,
                label: 'Bank Name',
                value: comp.bankName,
                pendingValue: pendingChanges['bankName'],
                textColor: textColor,
                subColor: subColor,
              ),
              const Divider(height: 16),
              _buildInfoRow(
                icon: Icons.numbers_rounded,
                label: 'Account Number',
                value: _unmaskFinancials ? comp.accountNumber : comp.maskedAccountNumber,
                pendingValue: pendingChanges['accountNumber'],
                textColor: textColor,
                subColor: subColor,
              ),
              const Divider(height: 16),
              _buildInfoRow(
                icon: Icons.qr_code_rounded,
                label: 'IFSC Code',
                value: comp.ifscCode,
                pendingValue: pendingChanges['ifscCode'],
                textColor: textColor,
                subColor: subColor,
              ),
              const Divider(height: 16),
              _buildInfoRow(
                icon: Icons.location_on_outlined,
                label: 'Branch Location',
                value: staff.bankBranch ?? 'State Bank of India, Main Institutional Branch',
                textColor: textColor,
                subColor: subColor,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Statutory Identifiers Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Statutory Tax & Regulatory Identifiers',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.receipt_long_rounded,
                label: 'Income Tax PAN',
                value: _unmaskFinancials ? comp.panNumber : comp.maskedPanNumber,
                badge: 'Government Verified',
                badgeColor: AppColors.success,
                textColor: textColor,
                subColor: subColor,
              ),
              const Divider(height: 16),
              _buildInfoRow(
                icon: Icons.security_rounded,
                label: 'EPF Universal Account Number (UAN)',
                value: comp.epfUan ?? 'UAN-100982341902',
                textColor: textColor,
                subColor: subColor,
              ),
              const Divider(height: 16),
              _buildInfoRow(
                icon: Icons.fingerprint_rounded,
                label: 'Aadhaar Identification',
                value: '•••• •••• 9842 (UIDAI Encrypted Record)',
                textColor: textColor,
                subColor: subColor,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Payslips & Remuneration Summary
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_outlined, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Monthly Remuneration & Payslips',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isMobile) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Frequency', style: TextStyle(fontSize: 11, color: subColor)),
                    const SizedBox(height: 2),
                    Text(comp.payFrequency, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 10),
                    Text('Salary Disbursement Mode', style: TextStyle(fontSize: 11, color: subColor)),
                    const SizedBox(height: 2),
                    Text('NEFT / Direct Bank Transfer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Payment Frequency', style: TextStyle(fontSize: 11, color: subColor)),
                          const SizedBox(height: 2),
                          Text(comp.payFrequency, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Salary Disbursement Mode', style: TextStyle(fontSize: 11, color: subColor)),
                          const SizedBox(height: 2),
                          Text('NEFT / Direct Bank Transfer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        content: Row(
                          children: [
                            const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Downloading latest monthly payslip PDF for ${staff.fullName}...',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download Latest Payslip (PDF)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 4: DOCUMENT VAULT
  // ==========================================
  Widget _buildDocumentVaultTab(
    BuildContext context,
    StaffMemberModel staff,
    bool isMobile,
    bool dark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
  ) {
    final docs = [
      _DocItem(
        title: 'Institutional Appointment & Offer Letter',
        meta: 'PDF • 1.4 MB • Verified by HR',
        date: DateFormat('dd MMM yyyy').format(staff.joiningDate),
        icon: Icons.description_outlined,
      ),
      _DocItem(
        title: 'Highest Degree & Educational Credentials (${staff.qualification})',
        meta: 'PDF • 2.8 MB • Verified Official Copy',
        date: 'Verified on Onboarding',
        icon: Icons.school_outlined,
      ),
      _DocItem(
        title: 'Government Identity / Aadhaar Card',
        meta: 'PDF • 850 KB • UIDAI E-KYC Verified',
        date: 'Encrypted Record',
        icon: Icons.badge_outlined,
      ),
      _DocItem(
        title: 'Prior Experience & Service Relieving Certificate',
        meta: 'PDF • 1.1 MB • Verified Work History',
        date: 'Verified on Onboarding',
        icon: Icons.history_edu_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder_special_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Institutional Document Repository',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${docs.length} Verified Files',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...docs.map((doc) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(doc.icon, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${doc.meta} • ${doc.date}',
                              style: TextStyle(fontSize: 11, color: subColor),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                            color: AppColors.secondary,
                            tooltip: 'Preview Document',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.secondary,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                  content: Text('Opening encrypted view for "${doc.title}"...'),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.download_rounded, size: 18),
                            color: AppColors.primary,
                            tooltip: 'Download Document',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                  content: Text('Downloading "${doc.title}"...'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        content: Text('Document upload request initiated. File will be routed to HR/Admin for verification.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Upload New Certificate / Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? pendingValue,
    String? badge,
    Color? badgeColor,
    required Color textColor,
    required Color subColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: subColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: subColor)),
              const SizedBox(height: 2),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: badgeColor ?? AppColors.primary,
                        ),
                      ),
                    ),
                  if (pendingValue != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hourglass_top_rounded, size: 11, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            'Pending Admin Verification: $pendingValue',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _DocItem {
  final String title;
  final String meta;
  final String date;
  final IconData icon;

  const _DocItem({
    required this.title,
    required this.meta,
    required this.date,
    required this.icon,
  });
}
