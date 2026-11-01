import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/src/themes/app_colors.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';
import 'package:frontend/src/features/admissions/application/admissions_controller.dart';
import 'package:frontend/src/features/admissions/domain/admission_request_model.dart';
import 'package:frontend/src/features/admissions/domain/student_admission_model.dart';

class PrincipalAdmissionsScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final int initialTabIndex;

  const PrincipalAdmissionsScreen({
    super.key,
    required this.isDark,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<PrincipalAdmissionsScreen> createState() => _PrincipalAdmissionsScreenState();
}

class _PrincipalAdmissionsScreenState extends ConsumerState<PrincipalAdmissionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final String _selectedClassFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void didUpdateWidget(covariant PrincipalAdmissionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showConfirmSeatDialog(AdmissionRequestModel request) {
    final remarksController = TextEditingController(text: 'Seat confirmed and enrollment granted.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.verified, color: AppColors.success),
            const SizedBox(width: 8),
            Text(
              'Final Seat Confirmation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Candidate: ${request.applicantFullName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Grade Applied: ${request.gradeApplied} • Parent: ${request.parentFullName}',
              style: TextStyle(fontSize: 12, color: widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: remarksController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Executive Admission Remarks',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
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
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(admissionRequestsListProvider.notifier).markApproved(request.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Seat granted for ${request.applicantFullName}! Admission successfully approved.'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Grant Admission'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(admissionRequestsListProvider);
    final admissionsAsync = ref.watch(admissionsListProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    final cardBg = widget.isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = widget.isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = widget.isDark ? Colors.white : AppColors.textPrimaryLight;
    final subColor = widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final pendingRequests = (requestsAsync.valueOrNull ?? [])
        .where((r) => r.status.isPendingReview)
        .toList();
    final recentUpdates = ref.watch(recent30DayRequestsProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Executive Admissions Banner
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF109F83).withValues(alpha: widget.isDark ? 0.25 : 0.12),
                  cardBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF109F83).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 22 : 28,
                  backgroundColor: const Color(0xFF109F83),
                  child: const Icon(Icons.how_to_reg, color: Colors.white, size: 26),
                ),
                SizedBox(width: isMobile ? 12 : 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student Admissions & Enrollment Hub',
                        style: TextStyle(
                          fontSize: isMobile ? 17 : 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Candidate pipeline review, interview schedule inspection, and primary seat confirmation sign-off.',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: isMobile,
            labelColor: const Color(0xFF109F83),
            unselectedLabelColor: subColor,
            indicatorColor: const Color(0xFF109F83),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Admissions Pipeline & Approvals', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: pendingRequests.isNotEmpty ? AppColors.warning : Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${pendingRequests.length}',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Last 30 Days Updates', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: recentUpdates.isNotEmpty ? const Color(0xFF109F83) : Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${recentUpdates.length}',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const Tab(text: 'Enrolled Student Directory'),
            ],
          ),

          const SizedBox(height: 18),

          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 0) {
                // Admissions Pipeline View
                if (pendingRequests.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.verified_outlined, size: 48, color: AppColors.success),
                        const SizedBox(height: 12),
                        Text(
                          'Admissions Pipeline Clear',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All submitted application requests have been processed or seated.',
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: pendingRequests.map((req) => _buildPipelineCard(req, cardBg, borderColor, textColor, subColor, isMobile)).toList(),
                );
              } else if (_tabController.index == 1) {
                // Last 30 Days Updates View (Pending, Approved, Rejected, Correction Requested)
                if (recentUpdates.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.history_toggle_off_rounded, size: 48, color: AppColors.info),
                        const SizedBox(height: 12),
                        Text(
                          'No Updates in the Last 30 Days',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All candidate status changes (Pending, Approved, Rejected) within the last 30 days will appear here.',
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: recentUpdates.map((req) {
                    final updateDate = req.reviewedAt ?? req.appliedAt;
                    final isApproved = req.status == AdmissionRequestStatus.approved;
                    final isRejected = req.status == AdmissionRequestStatus.rejected;
                    final isPending = req.status.isPendingReview;
                    final isCorrection = req.status == AdmissionRequestStatus.correctionRequested;

                    Color statusColor;
                    IconData statusIcon;
                    String statusLabel;
                    String updateNote;

                    if (isApproved) {
                      statusColor = const Color(0xFF059669);
                      statusIcon = Icons.check_circle_outline;
                      statusLabel = 'Approved';
                      updateNote = 'Approved on ${DateFormat("dd MMM yyyy, hh:mm a").format(updateDate)}${req.notes != null && req.notes!.isNotEmpty ? " • ${req.notes}" : ""}';
                    } else if (isRejected) {
                      statusColor = const Color(0xFFDC2626);
                      statusIcon = Icons.cancel_outlined;
                      statusLabel = 'Rejected';
                      updateNote = 'Rejected on ${DateFormat("dd MMM yyyy, hh:mm a").format(updateDate)}${req.notes != null && req.notes!.isNotEmpty ? " • Reason: ${req.notes}" : ""}';
                    } else if (isCorrection) {
                      statusColor = const Color(0xFF8B5CF6);
                      statusIcon = Icons.feedback_outlined;
                      statusLabel = 'Correction Requested';
                      updateNote = 'Correction Requested on ${DateFormat("dd MMM yyyy, hh:mm a").format(updateDate)}${req.notes != null && req.notes!.isNotEmpty ? " • Notes: ${req.notes}" : ""}';
                    } else {
                      statusColor = const Color(0xFFD97706);
                      statusIcon = Icons.hourglass_top_rounded;
                      statusLabel = 'Pending Review';
                      updateNote = 'Submitted on ${DateFormat("dd MMM yyyy, hh:mm a").format(updateDate)} • Pending Review';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isPending
                              ? AppColors.warning.withValues(alpha: 0.35)
                              : borderColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: statusColor.withValues(alpha: 0.15),
                                backgroundImage: req.studentPhotoUrl != null && req.studentPhotoUrl!.startsWith('http')
                                    ? NetworkImage(req.studentPhotoUrl!)
                                    : null,
                                child: req.studentPhotoUrl != null && req.studentPhotoUrl!.startsWith('http')
                                    ? null
                                    : Text(
                                        req.applicantFirstName.isNotEmpty ? req.applicantFirstName[0] : 'S',
                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          req.applicantFullName,
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF109F83).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Grade ${req.gradeApplied}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF109F83)),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            req.id,
                                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: subColor),
                                          ),
                                        ),
                                        // Status badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(statusIcon, size: 12, color: statusColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                statusLabel,
                                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: statusColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Parent: ${req.parentFullName} (${req.parentPhone}) • Source: ${req.source.displayName}',
                                      style: TextStyle(fontSize: 12, color: subColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: widget.isDark ? 0.12 : 0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(statusIcon, size: 14, color: statusColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    updateNote,
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: statusColor),
                                  ),
                                ),
                                if (isPending) ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _showConfirmSeatDialog(req),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Grant Seat',
                                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              } else {
                // Enrolled Student Directory
                final allAdmissions = admissionsAsync.valueOrNull ?? [];
                final query = _searchController.text.trim().toLowerCase();

                final filtered = allAdmissions.where((item) {
                  final nameMatches = item.user.fullName.toLowerCase().contains(query);
                  final admMatches = item.student.admissionNumber.toLowerCase().contains(query);
                  final rollMatches = (item.student.rollNumber ?? '').toLowerCase().contains(query);
                  final classMatches = _selectedClassFilter == 'All' || item.student.className == _selectedClassFilter;

                  return (nameMatches || admMatches || rollMatches) && classMatches;
                }).toList();

                return Column(
                  children: [
                    // Search and Filter Bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Search by student name, roll number, or admission ID...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                border: InputBorder.none,
                                isDense: true,
                                hintStyle: TextStyle(fontSize: 12.5, color: subColor),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(30),
                        alignment: Alignment.center,
                        child: Text('No enrolled students matched your query.', style: TextStyle(color: subColor)),
                      )
                    else
                      ...filtered.map((adm) => _buildStudentCard(adm, cardBg, borderColor, textColor, subColor, isMobile)),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineCard(
    AdmissionRequestModel req,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    req.applicantFullName,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF109F83).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Grade ${req.gradeApplied}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF109F83)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Source: ${req.source.displayName}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Parent: ${req.parentFullName} (${req.parentPhone}) • Email: ${req.parentEmail}',
                style: TextStyle(fontSize: 11.5, color: subColor),
              ),
              const SizedBox(height: 3),
              Text(
                'Applied: ${req.appliedAt.day}/${req.appliedAt.month}/${req.appliedAt.year} • Documents: Verified',
                style: TextStyle(fontSize: 11.5, color: subColor),
              ),
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 15),
                label: const Text('Confirm Seat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showConfirmSeatDialog(req),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.close, size: 15),
                label: const Text('Decline'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await ref.read(admissionRequestsListProvider.notifier).rejectRequest(req.id, reason: 'Declined by Principal');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Application for ${req.applicantFullName} has been declined.')),
                    );
                  }
                },
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: 12),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 14),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildStudentCard(
    StudentAdmissionModel adm,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF109F83).withValues(alpha: 0.15),
            child: Text(
              adm.user.fullName.substring(0, adm.user.fullName.isNotEmpty ? 1 : 0),
              style: const TextStyle(color: Color(0xFF109F83), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adm.user.fullName,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 3),
                Text(
                  'Adm No: ${adm.student.admissionNumber} • Class: ${adm.student.className} (Sec ${adm.student.section}) • Roll: ${adm.student.rollNumber ?? 'N/A'}',
                  style: TextStyle(fontSize: 11, color: subColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Enrolled',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
