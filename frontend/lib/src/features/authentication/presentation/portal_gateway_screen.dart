import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/user_model.dart';
import '../application/auth_controller.dart';
import '../application/student_auth_controller.dart';
import '../application/parent_auth_controller.dart';
import '../../staff/application/staff_auth_controller.dart';
import '../../staff/domain/staff_menu_item.dart';
import '../../../themes/app_colors.dart';
import '../../auth/presentation/widgets/role_quick_login_grid.dart';

/// Single Unified Institutional Sign-In Gateway Screen
///
/// Provides a unified, tab-free entrypoint for all institutional user types:
/// Admin, Principal, Teaching Faculty, Support Staff, Students, and Parents.
class PortalGatewayScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final ValueChanged<UserRole>? onSelectRole;

  const PortalGatewayScreen({
    super.key,
    required this.isDark,
    this.onToggleTheme,
    this.onSelectRole,
  });

  @override
  ConsumerState<PortalGatewayScreen> createState() => _PortalGatewayScreenState();
}

class _PortalGatewayScreenState extends ConsumerState<PortalGatewayScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(text: '123456');

  String _searchQuery = '';
  UserRole _selectedManualRole = UserRole.admin;
  bool _obscurePassword = true;
  bool _isManualExpanded = false;
  bool _isAuthenticating = false;

  @override
  void dispose() {
    _searchController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleManualSignIn() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter an institutional email or user ID', style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAuthenticating = true);

    try {
      // 1. Try Staff Login first
      final staff = await ref.read(staffAuthControllerProvider).mockStaffLogin(email, pass);
      if (staff != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Authenticated as ${staff.fullName} (${staff.designation})',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );

          final targetRoute =
              isSuperAdmin(staff.effectiveRole) ? '/admin/staff' : '/staff/dashboard';
          try {
            context.go(targetRoute);
          } catch (_) {}
        }
        return;
      }

      // 2. Try Student Login
      final student = await ref.read(studentAuthControllerProvider).mockStudentLogin(email, pass);
      if (student != null) {
        if (mounted) {
          ref.read(activeUserRoleProvider.notifier).state = UserRole.student;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Authenticated as ${student.fullName} (${student.className})',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF06B6D4),
              behavior: SnackBarBehavior.floating,
            ),
          );
          try {
            context.go('/student/dashboard');
          } catch (_) {}
        }
        return;
      }

      // 3. Try Parent Login
      final parent = await ref.read(parentAuthControllerProvider).mockParentLogin(email, pass);
      if (parent != null) {
        if (mounted) {
          ref.read(activeUserRoleProvider.notifier).state = UserRole.parent;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Authenticated as ${parent.fullName} (Guardian)',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          try {
            context.go('/parent/dashboard');
          } catch (_) {}
        }
        return;
      }

      // 4. Fallback Role activation
      ref.read(activeUserRoleProvider.notifier).state = _selectedManualRole;
      widget.onSelectRole?.call(_selectedManualRole);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in error: $e', style: GoogleFonts.inter()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1100;
    final isMobile = screenWidth < 700;
    final isDark = widget.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isDark),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 28,
                  vertical: isMobile ? 14 : 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1280 : 860,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Section: Logo, Title, Subtitle, Search, and Info Banner
                        _buildGatewayHeader(isDark, isMobile),
                        const SizedBox(height: 24),

                        // Main Scrollable Grid grouped by the 8 User Types
                        RoleQuickLoginGrid(
                          isDark: isDark,
                          searchQuery: _searchQuery,
                        ),
                        const SizedBox(height: 28),

                        // Bottom Collapsible Section: Manual Sign-In Fallback
                        _buildCollapsibleManualSignIn(isDark, isMobile),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildFooter(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        return Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF109F83), Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'EduPulse',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  letterSpacing: -0.5,
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Unified Gateway',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (widget.onToggleTheme != null)
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                  ),
                  onPressed: widget.onToggleTheme,
                  tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGatewayHeader(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Brand Hero
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: isMobile ? 44 : 52,
              height: isMobile ? 44 : 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF109F83), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF109F83).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Institutional Sign In Gateway',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 20 : 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Select any identity to instantly sign in',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 12 : 14,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Real-Time Search Bar
        TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: 'Search by name, email, role, class...',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Demo Password Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: isDark ? 0.22 : 0.65),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryLight.withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.key_rounded,
                size: 18,
                color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demo Password for all: 123456',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.primaryDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : AppColors.primaryDark).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Pass: 123456',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white : AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsibleManualSignIn(bool isDark, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Collapsible Header Button
          InkWell(
            onTap: () {
              setState(() {
                _isManualExpanded = !_isManualExpanded;
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Or sign in manually',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Custom credentials fallback for testing manual authentication',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isManualExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content Form
          if (_isManualExpanded) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Email field
                  Text(
                    'Institutional Email or ID',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. admin@edupulse.edu.in, aarav.sharma@student...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                      prefixIcon: const Icon(Icons.email_outlined, size: 18),
                      filled: true,
                      fillColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password field
                  Text(
                    'Password',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Fallback Role Selector
                  Text(
                    'Target Portal Role (Fallback)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        UserRole.admin,
                        UserRole.teacher,
                        UserRole.student,
                        UserRole.parent,
                        UserRole.admissions,
                        UserRole.finance,
                      ].map((role) {
                        final isSelected = _selectedManualRole == role;
                        final label = RoleDirectory.registry[role]?.title ?? role.name.toUpperCase();
                        final color = RoleDirectory.registry[role]?.primaryColor ?? AppColors.primary;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            selectedColor: color.withValues(alpha: 0.2),
                            side: BorderSide(
                              color: isSelected ? color : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? color : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                            onSelected: (_) => setState(() => _selectedManualRole = role),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      icon: _isAuthenticating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login_rounded, size: 16),
                      label: Text(
                        _isAuthenticating ? 'Authenticating...' : 'Sign In with Credentials',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isAuthenticating ? null : _handleManualSignIn,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1.0,
          ),
        ),
      ),
      child: Center(
        child: Text(
          'EduPulse School Management ERP • Unified Institutional Gateway • 2026-27',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
