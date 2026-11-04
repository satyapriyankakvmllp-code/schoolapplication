import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../commonwidgets/edupluse_scaffold.dart';
import '../../application/admissions_controller.dart';
import '../../domain/admission_request_model.dart';

class StudentCategoriesScreen extends ConsumerStatefulWidget {
  final ValueChanged<EdupluseNavPage>? onNavigate;
  final VoidCallback? onToggleTheme;
  final bool isDark;
  final VoidCallback? onExitToGateway;
  final bool isEmbedded;

  const StudentCategoriesScreen({
    super.key,
    this.onNavigate,
    this.onToggleTheme,
    this.isDark = false,
    this.onExitToGateway,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<StudentCategoriesScreen> createState() =>
      _StudentCategoriesScreenState();
}

class _StudentCategoriesScreenState
    extends ConsumerState<StudentCategoriesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatRelativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays <= 0) {
      if (diff.inHours <= 0) {
        return 'just now';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 30) {
      return '${diff.inDays}d ago';
    } else {
      return '${(diff.inDays / 30).floor()}mo ago';
    }
  }

  void _showRecentApprovalsSheet(bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RecentApprovalsTimelineSheet(
        isDark: isDark,
        onOpenDetail: (req) {
          Navigator.of(ctx).pop();
          _openReviewModal(req, isDark);
        },
      ),
    );
  }

  void _openReviewModal(AdmissionRequestModel request, bool isDark) {

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReviewRequestSheet(
        request: request,
        isDark: isDark,
        onApprove: (req) async {
          Navigator.of(ctx).pop();
          // Generate an official admission number preview safely
          final digits = req.id.replaceAll(RegExp(r'[^0-9]'), '');
          final idNum = digits.isNotEmpty ? (int.tryParse(digits) ?? 1001) % 10000 : 1001;
          final admNumber = 'ADM-2026-${1000 + idNum}';
          final prefilledAdmission = req.toStudentAdmissionDraft(
            newAdmissionNumber: admNumber,
          );

          // Store prefilled draft and originating request ID in Riverpod
          ref.read(prefilledAdmissionDraftProvider.notifier).state =
              prefilledAdmission;
          ref.read(originatingRequestIdProvider.notifier).state = req.id;

          // Navigate to Add Student form
          widget.onNavigate?.call(EdupluseNavPage.addNewStudent);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Application for ${req.applicantFullName} approved! Pre-filled in registration form for class & roll number assignment.',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF109F83),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        },
        onReject: (req, reason) async {
          Navigator.of(ctx).pop();
          await ref
              .read(admissionRequestsListProvider.notifier)
              .rejectRequest(req.id, reason: reason);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Application ${req.id} rejected and moved to the Rejected catalog.',
                ),
                backgroundColor: const Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark || widget.isDark;
    final counts = ref.watch(admissionRequestCountsProvider);
    final activeFilter = ref.watch(activeRequestFilterProvider);
    final filteredRequests = ref.watch(filteredAdmissionRequestsProvider);
    final requestsAsync = ref.watch(admissionRequestsListProvider);
    final is30DayApprovals = ref.watch(is30DayApprovalsFilterActiveProvider);
    final recentApprovals = ref.watch(recent30DayApprovalsProvider);

    return EdupluseScaffold(
      activePage: EdupluseNavPage.studentPipeline,
      onNavigate: widget.onNavigate,
      onToggleTheme: widget.onToggleTheme,
      onExitToGateway: widget.onExitToGateway,
      isDark: widget.isDark,
      isEmbedded: widget.isEmbedded,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 850;
          final isTablet = constraints.maxWidth >= 850 && constraints.maxWidth < 1100;

          return Container(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: isMobile ? 14 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER BAR ---
                  _buildHeaderBar(
                    isMobile: isMobile,
                    isDark: isDark,
                    recentApprovalsCount: recentApprovals.length,
                  ),
                  const SizedBox(height: 20),

                  // --- TOP MATRIX CARDS ---
                  _buildMatrixCards(
                    counts: counts,
                    activeFilter: activeFilter,
                    is30DayApprovals: is30DayApprovals,
                    isDark: isDark,
                    isMobile: isMobile,
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 24),

                  // --- SEARCH & FILTER BAR ---
                  _buildFilterBar(
                    activeFilter: activeFilter,
                    isDark: isDark,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 16),

                  // --- REQUESTS LIST / TABLE ---
                  requestsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: Color(0xFF109F83)),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text('Error loading requests: $err'),
                      ),
                    ),
                    data: (_) {
                      if (filteredRequests.isEmpty) {
                        return _buildEmptyState(
                          activeFilter: activeFilter,
                          is30DayApprovals: is30DayApprovals,
                          isDark: isDark,
                        );
                      }
                      return _buildRequestsTableCard(
                        requests: filteredRequests,
                        isDark: isDark,
                        isMobile: isMobile,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- HEADER BAR ---
  Widget _buildHeaderBar({
    required bool isMobile,
    required bool isDark,
    required int recentApprovalsCount,
  }) {
    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Students',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            Flexible(
              child: Text(
                'Student Pipeline',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF109F83),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Admission Requests & Pipeline',
          style: TextStyle(
            fontSize: isMobile ? 18 : 24,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final actionButton = OutlinedButton.icon(
      onPressed: () => _showRecentApprovalsSheet(isDark),
      icon: const Icon(Icons.history_edu_rounded, size: 17, color: Color(0xFF109F83)),
      label: Text(
        'Last 30 Days Updates ($recentApprovalsCount)',
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF109F83),
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF109F83), width: 1.2),
        backgroundColor: const Color(0xFF109F83).withValues(alpha: isDark ? 0.15 : 0.08),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleColumn,
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: actionButton),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: titleColumn),
        const SizedBox(width: 16),
        actionButton,
      ],
    );
  }

  // --- TOP 3 MATRIX CARDS (Pending, Approved, Rejected) ---
  Widget _buildMatrixCards({
    required Map<AdmissionRequestStatus, int> counts,
    required AdmissionRequestStatus? activeFilter,
    required bool is30DayApprovals,
    required bool isDark,
    required bool isMobile,
    required bool isTablet,
  }) {
    final pendingCount = counts[AdmissionRequestStatus.pendingReview] ??
        counts[AdmissionRequestStatus.pending] ??
        0;
    final approvedCount = counts[AdmissionRequestStatus.approved] ?? 0;
    final rejectedCount = counts[AdmissionRequestStatus.rejected] ?? 0;

    final isPendingActive = !is30DayApprovals && (activeFilter?.isPendingReview == true);
    final isApprovedActive = !is30DayApprovals && (activeFilter == AdmissionRequestStatus.approved);
    final isRejectedActive = !is30DayApprovals && (activeFilter == AdmissionRequestStatus.rejected);

    final pendingCard = _buildSingleMatrixCard(
      title: 'Pending Requests',
      sublabel: 'Assigned by Parent & Frontdesk',
      count: pendingCount,
      icon: Icons.hourglass_top_rounded,
      color: const Color(0xFFF59E0B),
      gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      isSelected: isPendingActive,
      isDark: isDark,
      onTap: () {
        ref.read(is30DayApprovalsFilterActiveProvider.notifier).state = false;
        ref.read(activeRequestFilterProvider.notifier).state =
            isPendingActive ? null : AdmissionRequestStatus.pendingReview;
      },
    );

    final approvedCard = _buildSingleMatrixCard(
      title: 'Approved Students',
      sublabel: 'Enrolled & Verified by Admin',
      count: approvedCount,
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF109F83),
      gradientColors: [const Color(0xFF109F83), const Color(0xFF059669)],
      isSelected: isApprovedActive,
      isDark: isDark,
      onTap: () {
        ref.read(is30DayApprovalsFilterActiveProvider.notifier).state = false;
        ref.read(activeRequestFilterProvider.notifier).state =
            isApprovedActive ? null : AdmissionRequestStatus.approved;
      },
    );

    final rejectedCard = _buildSingleMatrixCard(
      title: 'Rejected Catalog',
      sublabel: 'Declined by Admin with reasons',
      count: rejectedCount,
      icon: Icons.cancel_rounded,
      color: const Color(0xFFEF4444),
      gradientColors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
      isSelected: isRejectedActive,
      isDark: isDark,
      onTap: () {
        ref.read(is30DayApprovalsFilterActiveProvider.notifier).state = false;
        ref.read(activeRequestFilterProvider.notifier).state =
            isRejectedActive ? null : AdmissionRequestStatus.rejected;
      },
    );

    if (isMobile) {
      return Column(
        children: [
          pendingCard,
          const SizedBox(height: 10),
          approvedCard,
          const SizedBox(height: 10),
          rejectedCard,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: pendingCard),
        const SizedBox(width: 16),
        Expanded(child: approvedCard),
        const SizedBox(width: 16),
        Expanded(child: rejectedCard),
      ],
    );
  }

  Widget _buildSingleMatrixCard({
    required String title,
    required String sublabel,
    required int count,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2.2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? color.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    isSelected ? 'FILTER ACTIVE' : 'CLICK TO VIEW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isSelected
                          ? color
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Students',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- SEARCH & FILTER BAR ---
  Widget _buildFilterBar({
    required AdmissionRequestStatus? activeFilter,
    required bool isDark,
    required bool isMobile,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchField(isDark, isMobile),
                const SizedBox(height: 10),
                _buildFilterChips(activeFilter, isDark),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildSearchField(isDark, isMobile)),
                const SizedBox(width: 16),
                _buildFilterChips(activeFilter, isDark),
              ],
            ),
    );
  }

  Widget _buildSearchField(bool isDark, bool isMobile) {
    return TextField(
      controller: _searchController,
      onChanged: (val) {
        ref.read(requestSearchQueryProvider.notifier).state = val;
      },
      decoration: InputDecoration(
        hintText: isMobile
            ? 'Search applicants, parents, grade...'
            : 'Search applicant name, parent, grade, or request ID...',
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          fontSize: 13,
        ),
        prefixIcon: Icon(
          Icons.search,
          size: 18,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: () {
                  _searchController.clear();
                  ref.read(requestSearchQueryProvider.notifier).state = '';
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF109F83), width: 1.5),
        ),
      ),
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildFilterChips(AdmissionRequestStatus? activeFilter, bool isDark) {
    final isPendingActive = activeFilter?.isPendingReview == true;
    final isApprovedActive = activeFilter == AdmissionRequestStatus.approved;
    final isRejectedActive = activeFilter == AdmissionRequestStatus.rejected;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildChip(
            label: 'All Requests',
            isSelected: activeFilter == null,
            color: const Color(0xFF64748B),
            isDark: isDark,
            onTap: () {
              ref.read(is30DayApprovalsFilterActiveProvider.notifier).state = false;
              ref.read(activeRequestFilterProvider.notifier).state = null;
            },
          ),
          const SizedBox(width: 6),
          _buildChip(
            label: 'Pending',
            isSelected: isPendingActive,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
            onTap: () {
              ref.read(is30DayApprovalsFilterActiveProvider.notifier).state = false;
              ref.read(activeRequestFilterProvider.notifier).state =
                  isPendingActive ? null : AdmissionRequestStatus.pendingReview;
            },
          ),
          const SizedBox(width: 6),
          _buildChip(
            label: 'Approved',
            isSelected: isApprovedActive,
            color: const Color(0xFF109F83),
            isDark: isDark,
            onTap: () {
              ref.read(is30DayApprovalsFilterActiveProvider.notifier).state = false;
              ref.read(activeRequestFilterProvider.notifier).state =
                  isApprovedActive ? null : AdmissionRequestStatus.approved;
            },
          ),
          const SizedBox(width: 6),
          _buildChip(
            label: 'Rejected',
            isSelected: isRejectedActive,
            color: const Color(0xFFEF4444),
            isDark: isDark,
            onTap: () {
              ref.read(is30DayApprovalsFilterActiveProvider.notifier).state = false;
              ref.read(activeRequestFilterProvider.notifier).state =
                  isRejectedActive ? null : AdmissionRequestStatus.rejected;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? color
                    : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- REQUESTS TABLE CARD ---
  Widget _buildRequestsTableCard({
    required List<AdmissionRequestModel> requests,
    required bool isDark,
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          // Table header for desktop
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: const [
                  Expanded(flex: 3, child: _HeaderCell('APPLICANT NAME')),
                  Expanded(flex: 2, child: _HeaderCell('GRADE APPLIED')),
                  Expanded(flex: 3, child: _HeaderCell('PARENT / CONTACT')),
                  Expanded(flex: 2, child: _HeaderCell('INTAKE SOURCE')),
                  Expanded(flex: 2, child: _HeaderCell('STATUS')),
                  SizedBox(width: 120, child: _HeaderCell('ACTION')),
                ],
              ),
            ),

          // List of items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: requests.length,
            separatorBuilder: (ctx, i) => Divider(
              height: 1,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            ),
            itemBuilder: (ctx, i) {
              final req = requests[i];
              if (isMobile) {
                return _buildMobileRequestItem(req, isDark);
              }
              return _buildDesktopRequestItem(req, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRequestItem(AdmissionRequestModel req, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Applicant
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF109F83).withValues(alpha: 0.15),
                  backgroundImage: req.studentPhotoUrl != null && req.studentPhotoUrl!.startsWith('http')
                      ? NetworkImage(req.studentPhotoUrl!)
                      : null,
                  child: req.studentPhotoUrl != null && req.studentPhotoUrl!.startsWith('http')
                      ? null
                      : Text(
                          req.applicantFirstName.isNotEmpty
                              ? req.applicantFirstName[0]
                              : 'S',
                          style: const TextStyle(
                            color: Color(0xFF109F83),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.applicantFullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${req.id} • ${req.gender}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Grade
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF109F83).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    req.gradeApplied,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF109F83),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Year: ${req.academicYear}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Parent
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.parentFullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  req.parentPhone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Source
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildSourceBadge(req.source, isDark),
            ),
          ),

          // Status
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusBadge(req.status, isDark),
                if (req.status == AdmissionRequestStatus.approved && req.reviewedAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Approved ${_formatRelativeDate(req.reviewedAt!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Action
          SizedBox(
            width: 120,
            child: ElevatedButton.icon(
              onPressed: () => _openReviewModal(req, isDark),
              icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
              label: const Text('Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileRequestItem(AdmissionRequestModel req, bool isDark) {
    return InkWell(
      onTap: () => _openReviewModal(req, isDark),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name & Class + Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF109F83).withValues(alpha: 0.15),
                  backgroundImage: req.studentPhotoUrl != null && req.studentPhotoUrl!.startsWith('http')
                      ? NetworkImage(req.studentPhotoUrl!)
                      : null,
                  child: req.studentPhotoUrl != null && req.studentPhotoUrl!.startsWith('http')
                      ? null
                      : Text(
                          req.applicantFirstName.isNotEmpty
                              ? req.applicantFirstName[0]
                              : 'S',
                          style: const TextStyle(
                            color: Color(0xFF109F83),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.applicantFullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Class ${req.gradeApplied} • ID: ${req.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusBadge(req.status, isDark),
                    if (req.status == AdmissionRequestStatus.approved && req.reviewedAt != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        _formatRelativeDate(req.reviewedAt!),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Subtle divider line
            Container(
              height: 1,
              color: isDark
                  ? const Color(0xFF334155).withValues(alpha: 0.4)
                  : const Color(0xFFF1F5F9),
            ),
            const SizedBox(height: 10),

            // Bottom Row: Parent contact + Intake source + Chevron
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${req.parentFullName} (${req.parentPhone})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildSourceBadge(req.source, isDark),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBadge(AdmissionRequestSource source, bool isDark) {
    final isParent = source == AdmissionRequestSource.parentPortal;
    final color = isParent ? const Color(0xFF8B5CF6) : const Color(0xFF0284C7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isParent ? Icons.phone_android : Icons.support_agent, size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              source.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AdmissionRequestStatus status, bool isDark) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case AdmissionRequestStatus.pending:
      case AdmissionRequestStatus.pendingReview:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        icon = Icons.hourglass_top_rounded;
        break;
      case AdmissionRequestStatus.correctionRequested:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFB45309);
        icon = Icons.edit_note_rounded;
        break;
      case AdmissionRequestStatus.approved:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF059669);
        icon = Icons.check_circle_outline;
        break;
      case AdmissionRequestStatus.rejected:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required AdmissionRequestStatus? activeFilter,
    required bool is30DayApprovals,
    required bool isDark,
  }) {
    String label = 'No admission requests found';
    if (is30DayApprovals) {
      label = 'No student approvals recorded in the last 30 days.';
    } else if (activeFilter != null) {
      label = 'No ${activeFilter.displayName.toLowerCase()} requests currently.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 48,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try switching category filter chips or clearing your search.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }
}

// =========================================================================
// SLIDE-OVER REVIEW DRAWER / MODAL SHEET
// =========================================================================

class _ReviewRequestSheet extends StatefulWidget {
  final AdmissionRequestModel request;
  final bool isDark;
  final ValueChanged<AdmissionRequestModel> onApprove;
  final void Function(AdmissionRequestModel request, String reason) onReject;

  const _ReviewRequestSheet({
    required this.request,
    required this.isDark,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_ReviewRequestSheet> createState() => _ReviewRequestSheetState();
}

class _ReviewRequestSheetState extends State<_ReviewRequestSheet> {
  final _reasonController = TextEditingController(text: 'Incomplete documents / seat quota full');

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _promptRejectDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        String selectedReason = 'Class capacity full';
        final isDark = widget.isDark;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
                  SizedBox(width: 8),
                  Text('Reject Application?'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to reject the application for ${widget.request.applicantFullName}? It will automatically move to the Rejected catalog.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Rejection Reason:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    items: const [
                      DropdownMenuItem(
                        value: 'Class capacity full',
                        child: Text('Class capacity full'),
                      ),
                      DropdownMenuItem(
                        value: 'Age criteria not met',
                        child: Text('Age criteria not met'),
                      ),
                      DropdownMenuItem(
                        value: 'Incomplete documentation',
                        child: Text('Incomplete documentation'),
                      ),
                      DropdownMenuItem(
                        value: 'Other / Custom reason',
                        child: Text('Other / Custom reason'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedReason = val;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    widget.onReject(widget.request, selectedReason);
                  },
                  child: const Text('Confirm Reject'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final req = widget.request;
    final dobFormatted = DateFormat('dd MMM yyyy').format(req.dateOfBirth);
    final appliedFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(req.appliedAt);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Modal Top Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF109F83).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school, color: Color(0xFF109F83), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Application Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'ID: ${req.id} • Applied on $appliedFormatted',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner if Approved / Rejected
                  if (req.status == AdmissionRequestStatus.rejected)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Declined by Admin: ${req.rejectionReason ?? "No reason provided"}',
                              style: const TextStyle(
                                color: Color(0xFF991B1B),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (req.status == AdmissionRequestStatus.approved)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF6EE7B7)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle_outline, color: Color(0xFF059669)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Approved by Admin & Enrolled into active student directory.',
                              style: TextStyle(
                                color: Color(0xFF065F46),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Section 1: Student Information
                  _buildSectionCard(
                    title: 'Student Basic Profile',
                    icon: Icons.person_outline,
                    isDark: isDark,
                    children: [
                      if (req.studentPhotoUrl != null && req.studentPhotoUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF109F83).withValues(alpha: 0.15),
                                backgroundImage: req.studentPhotoUrl!.startsWith('http')
                                    ? NetworkImage(req.studentPhotoUrl!)
                                    : null,
                                child: req.studentPhotoUrl!.startsWith('http')
                                    ? null
                                    : const Icon(Icons.person, color: Color(0xFF109F83), size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Passport Photo Attached',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF109F83),
                                      ),
                                    ),
                                    Text(
                                      req.studentPhotoUrl!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      _buildDetailRow('Full Name', req.applicantFullName, isDark),
                      _buildDetailRow('Gender', req.gender, isDark),
                      _buildDetailRow('Date of Birth', dobFormatted, isDark),
                      _buildDetailRow('Blood Group', req.bloodGroup ?? 'Not specified', isDark),
                      _buildDetailRow('Grade Applied', req.gradeApplied, isDark),
                      _buildDetailRow('Academic Year', req.academicYear, isDark),
                      _buildDetailRow('Intake Source', req.source.displayName, isDark),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Section 2: Parent / Guardian Information
                  _buildSectionCard(
                    title: 'Parent & Guardian Information',
                    icon: Icons.family_restroom_outlined,
                    isDark: isDark,
                    children: [
                      _buildDetailRow('Parent Name', req.parentFullName, isDark),
                      _buildDetailRow('Relationship', req.parentRelationship, isDark),
                      _buildDetailRow('Phone Number', req.parentPhone, isDark),
                      _buildDetailRow('Email Address', req.parentEmail, isDark),
                      _buildDetailRow('Occupation', req.parentOccupation ?? 'N/A', isDark),
                      _buildDetailRow('Emergency Contact', req.emergencyContactPhone, isDark),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Section 3: Address & Previous School
                  _buildSectionCard(
                    title: 'Address & Prior Schooling',
                    icon: Icons.location_on_outlined,
                    isDark: isDark,
                    children: [
                      _buildDetailRow('Current Address', req.currentAddress, isDark),
                      if (req.permanentAddress != null)
                        _buildDetailRow('Permanent Address', req.permanentAddress!, isDark),
                      _buildDetailRow(
                        'Previous School',
                        req.previousSchoolName ?? 'None / Fresh Admission',
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Section 4: Attached Documents
                  _buildSectionCard(
                    title: 'Submitted Documents',
                    icon: Icons.attach_file,
                    isDark: isDark,
                    children: [
                      if (req.documents.isEmpty)
                        Text(
                          'No documents submitted yet.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: req.documents.map((doc) {
                            return Chip(
                              avatar: const Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFFDC2626)),
                              label: Text(doc, style: const TextStyle(fontSize: 12)),
                              backgroundColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9),
                            );
                          }).toList(),
                        ),
                    ],
                  ),

                  if (req.notes != null && req.notes!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildSectionCard(
                      title: 'Additional Notes & Remarks',
                      icon: Icons.notes,
                      isDark: isDark,
                      children: [
                        Text(
                          req.notes!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // --- BOTTOM STICKY ACTION BAR ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: req.status.isPendingReview
                ? LayoutBuilder(
                    builder: (context, actionConstraints) {
                      final isNarrow = actionConstraints.maxWidth < 420;
                      if (isNarrow) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => widget.onApprove(req),
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text(
                                  'Approve & Pre-fill Form',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF109F83),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _promptRejectDialog,
                                icon: const Icon(Icons.cancel_outlined, size: 16),
                                label: const Text(
                                  'Reject Request',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                  side: const BorderSide(color: Color(0xFFEF4444)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _promptRejectDialog,
                              icon: const Icon(Icons.cancel_outlined, size: 16),
                              label: const Text('Reject Request', style: TextStyle(fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(color: Color(0xFFEF4444)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () => widget.onApprove(req),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text(
                                'Approve & Pre-fill Form',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF109F83),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Close Details'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF109F83)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// LAST 30 DAYS STUDENT APPROVALS TIMELINE & INSIGHTS SHEET
// =========================================================================

class _RecentApprovalsTimelineSheet extends ConsumerStatefulWidget {
  final bool isDark;
  final void Function(AdmissionRequestModel request) onOpenDetail;

  const _RecentApprovalsTimelineSheet({
    required this.isDark,
    required this.onOpenDetail,
  });

  @override
  ConsumerState<_RecentApprovalsTimelineSheet> createState() =>
      _RecentApprovalsTimelineSheetState();
}

class _RecentApprovalsTimelineSheetState
    extends ConsumerState<_RecentApprovalsTimelineSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  String _statusTab = 'ALL'; // 'ALL', 'PENDING', 'APPROVED', 'REJECTED'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays <= 0) {
      if (diff.inHours <= 0) {
        return 'just now';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 30) {
      return '${diff.inDays} days ago';
    } else {
      return '${(diff.inDays / 30).floor()} months ago';
    }
  }

  Widget _buildStatusBadge(AdmissionRequestStatus status, bool isDark) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case AdmissionRequestStatus.pending:
      case AdmissionRequestStatus.pendingReview:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        icon = Icons.hourglass_top_rounded;
        break;
      case AdmissionRequestStatus.correctionRequested:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFB45309);
        icon = Icons.edit_note_rounded;
        break;
      case AdmissionRequestStatus.approved:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF059669);
        icon = Icons.check_circle_outline;
        break;
      case AdmissionRequestStatus.rejected:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all30Days = ref.watch(recent30DayRequestsProvider);
    final isDark = widget.isDark;

    final pendingCount = all30Days.where((r) => r.status.isPendingReview).length;
    final approvedCount = all30Days.where((r) => r.status == AdmissionRequestStatus.approved).length;
    final rejectedCount = all30Days.where((r) => r.status == AdmissionRequestStatus.rejected).length;

    final tabFiltered = all30Days.where((r) {
      if (_statusTab == 'PENDING') return r.status.isPendingReview;
      if (_statusTab == 'APPROVED') return r.status == AdmissionRequestStatus.approved;
      if (_statusTab == 'REJECTED') return r.status == AdmissionRequestStatus.rejected;
      return true;
    }).toList();

    final filtered = tabFiltered.where((r) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return r.applicantFullName.toLowerCase().contains(q) ||
          r.gradeApplied.toLowerCase().contains(q) ||
          r.parentFullName.toLowerCase().contains(q) ||
          r.id.toLowerCase().contains(q);
    }).toList();

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A),
          textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF109F83).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_edu_rounded,
                        color: Color(0xFF109F83),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Student Updates (Last 30 Days)',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF109F83),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${all30Days.length} Total',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'All candidate pipeline activity: Pending, Approved, and Rejected',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(color: borderColor, height: 1),

              // Scrollable Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 4 KPI Cards (Responsive Layout)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 650;
                        final isTablet = constraints.maxWidth >= 650 && constraints.maxWidth < 900;

                        final kpiTotal = _buildKpiCard(
                          title: 'Total 30d Updates',
                          value: '${all30Days.length} Requests',
                          subtitle: 'Past 30 calendar days',
                          icon: Icons.all_inbox_rounded,
                          color: const Color(0xFF0D9488),
                          isDark: isDark,
                        );
                        final kpiPending = _buildKpiCard(
                          title: 'Pending Review',
                          value: '$pendingCount Students',
                          subtitle: 'Awaiting decision',
                          icon: Icons.hourglass_top_rounded,
                          color: const Color(0xFFF59E0B),
                          isDark: isDark,
                        );
                        final kpiApproved = _buildKpiCard(
                          title: 'Approved',
                          value: '$approvedCount Enrolled',
                          subtitle: 'Seats confirmed',
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF109F83),
                          isDark: isDark,
                        );
                        final kpiRejected = _buildKpiCard(
                          title: 'Rejected',
                          value: '$rejectedCount Declined',
                          subtitle: 'Reasons logged',
                          icon: Icons.cancel_outlined,
                          color: const Color(0xFFEF4444),
                          isDark: isDark,
                        );

                        if (isNarrow) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: kpiTotal),
                                  const SizedBox(width: 8),
                                  Expanded(child: kpiPending),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(child: kpiApproved),
                                  const SizedBox(width: 8),
                                  Expanded(child: kpiRejected),
                                ],
                              ),
                            ],
                          );
                        } else if (isTablet) {
                          return Row(
                            children: [
                              Expanded(child: kpiTotal),
                              const SizedBox(width: 8),
                              Expanded(child: kpiPending),
                              const SizedBox(width: 8),
                              Expanded(child: kpiApproved),
                              const SizedBox(width: 8),
                              Expanded(child: kpiRejected),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: kpiTotal),
                            const SizedBox(width: 12),
                            Expanded(child: kpiPending),
                            const SizedBox(width: 12),
                            Expanded(child: kpiApproved),
                            const SizedBox(width: 12),
                            Expanded(child: kpiRejected),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Filter tabs inside sheet
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildSheetTab(
                            label: 'All (${all30Days.length})',
                            isSelected: _statusTab == 'ALL',
                            color: const Color(0xFF0D9488),
                            isDark: isDark,
                            onTap: () => setState(() => _statusTab = 'ALL'),
                          ),
                          const SizedBox(width: 6),
                          _buildSheetTab(
                            label: 'Pending ($pendingCount)',
                            isSelected: _statusTab == 'PENDING',
                            color: const Color(0xFFF59E0B),
                            isDark: isDark,
                            onTap: () => setState(() => _statusTab = 'PENDING'),
                          ),
                          const SizedBox(width: 6),
                          _buildSheetTab(
                            label: 'Approved ($approvedCount)',
                            isSelected: _statusTab == 'APPROVED',
                            color: const Color(0xFF109F83),
                            isDark: isDark,
                            onTap: () => setState(() => _statusTab = 'APPROVED'),
                          ),
                          const SizedBox(width: 6),
                          _buildSheetTab(
                            label: 'Rejected ($rejectedCount)',
                            isSelected: _statusTab == 'REJECTED',
                            color: const Color(0xFFEF4444),
                            isDark: isDark,
                            onTap: () => setState(() => _statusTab = 'REJECTED'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Search within 30-day updates
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _search = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search updates by candidate, parent, grade, or ticket ID...',
                        hintStyle: TextStyle(fontSize: 12.5, color: textSecondary),
                        prefixIcon: Icon(Icons.search, size: 18, color: textSecondary),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _search = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: cardBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF109F83), width: 1.5),
                        ),
                      ),
                      style: TextStyle(fontSize: 13, color: textPrimary),
                    ),
                    const SizedBox(height: 16),

                    // Updates List
                    if (filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 40, color: textSecondary),
                            const SizedBox(height: 8),
                            Text(
                              'No updates found',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _search.isEmpty
                                  ? 'No student updates in this category for the last 30 days.'
                                  : 'No updates matched "$_search".',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final item = filtered[i];
                          final activityDate = item.reviewedAt ?? item.appliedAt;

                          Color bannerBg;
                          Color bannerBorder;
                          Color bannerIconColor;
                          IconData bannerIcon;
                          String bannerText;

                          if (item.status == AdmissionRequestStatus.approved) {
                            bannerBg = const Color(0xFF109F83).withValues(alpha: isDark ? 0.14 : 0.07);
                            bannerBorder = const Color(0xFF109F83).withValues(alpha: 0.25);
                            bannerIconColor = const Color(0xFF059669);
                            bannerIcon = Icons.check_circle_outline;
                            bannerText = 'Approved ${_relativeTime(activityDate)} • ${_formatTimestamp(activityDate)}${item.notes != null && item.notes!.isNotEmpty ? " • ${item.notes}" : ""}';
                          } else if (item.status == AdmissionRequestStatus.rejected) {
                            bannerBg = const Color(0xFFEF4444).withValues(alpha: isDark ? 0.14 : 0.07);
                            bannerBorder = const Color(0xFFEF4444).withValues(alpha: 0.25);
                            bannerIconColor = const Color(0xFFDC2626);
                            bannerIcon = Icons.cancel_outlined;
                            bannerText = 'Declined ${_relativeTime(activityDate)} • Reason: ${item.rejectionReason ?? "Declined by Admin"}';
                          } else if (item.status == AdmissionRequestStatus.correctionRequested) {
                            bannerBg = const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.14 : 0.07);
                            bannerBorder = const Color(0xFFF59E0B).withValues(alpha: 0.25);
                            bannerIconColor = const Color(0xFFD97706);
                            bannerIcon = Icons.edit_note_rounded;
                            bannerText = 'Correction Requested ${_relativeTime(activityDate)} • ${item.correctionNotes ?? "Awaiting parent edit"}';
                          } else {
                            bannerBg = const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.14 : 0.07);
                            bannerBorder = const Color(0xFFF59E0B).withValues(alpha: 0.25);
                            bannerIconColor = const Color(0xFFD97706);
                            bannerIcon = Icons.hourglass_top_rounded;
                            bannerText = 'Submitted ${_relativeTime(item.appliedAt)} • In Review${item.notes != null && item.notes!.isNotEmpty ? " • ${item.notes}" : ""}';
                          }

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Avatar + Name + Class + Status Badge
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 17,
                                      backgroundColor: const Color(0xFF109F83).withValues(alpha: 0.15),
                                      child: Text(
                                        item.applicantFirstName.isNotEmpty
                                            ? item.applicantFirstName[0]
                                            : 'S',
                                        style: const TextStyle(
                                          color: Color(0xFF109F83),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              Text(
                                                item.applicantFullName,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: textPrimary,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF109F83).withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  item.gradeApplied,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF109F83),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  item.id,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Parent: ${item.parentFullName} • ${item.parentPhone}',
                                            style: TextStyle(fontSize: 12, color: textSecondary),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatusBadge(item.status, isDark),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Activity Banner
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: bannerBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: bannerBorder),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(bannerIcon, size: 15, color: bannerIconColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          bannerText,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: bannerIconColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Action footer
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => widget.onOpenDetail(item),
                                    icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                                    label: const Text('View Application Details'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF109F83),
                                      visualDensity: VisualDensity.compact,
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetTab({
    required String label,
    required bool isSelected,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.3 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


