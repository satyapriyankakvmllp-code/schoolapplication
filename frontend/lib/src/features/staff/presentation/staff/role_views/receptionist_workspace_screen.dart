import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';
import 'package:frontend/src/themes/app_colors.dart';
import '../../../application/staff_auth_controller.dart';
import '../../../../admissions/presentation/frontdesk/frontdesk_dashboard_screen.dart';
import '../../../../admissions/presentation/frontdesk/inquiry_desk_screen.dart';
import '../../../../admissions/presentation/frontdesk/frontdesk_new_application_screen.dart';
import '../../../../admissions/presentation/frontdesk/document_verification_queue_screen.dart';
import '../../../../admissions/presentation/frontdesk/interview_scheduler_screen.dart';
import '../../../../admissions/presentation/frontdesk/id_badge_studio_screen.dart';
import '../../../../admissions/application/frontdesk_controller.dart';

class ReceptionistWorkspaceScreen extends ConsumerStatefulWidget {
  final bool isDark;

  const ReceptionistWorkspaceScreen({
    super.key,
    this.isDark = false,
  });

  @override
  ConsumerState<ReceptionistWorkspaceScreen> createState() => _ReceptionistWorkspaceScreenState();
}

class _ReceptionistWorkspaceScreenState extends ConsumerState<ReceptionistWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentLoggedInStaffProvider);
    final dark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    final cardBg = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = dark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final isMobile = ResponsiveLayout.isMobile(context);


    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Hub Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admissions & Front-Desk Operations Hub',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Officer on Duty: ${staff?.fullName ?? "Priya Sharma"} | Senior Admissions Desk',
                      style: TextStyle(fontSize: isMobile ? 11 : 13, color: subColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge_outlined, size: 14, color: AppColors.warning),
                    SizedBox(width: 6),
                    Text(
                      'FRONT-DESK OFFICER',
                      style: TextStyle(
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
          const SizedBox(height: 16),

          // Tab Selector
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.warning,
              unselectedLabelColor: subColor,
              indicatorColor: AppColors.warning,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Admissions Cockpit'),
                Tab(icon: Icon(Icons.support_agent_outlined, size: 18), text: 'Inquiry Pipeline Desk'),
                Tab(icon: Icon(Icons.assignment_ind_outlined, size: 18), text: 'Assisted Intake Form'),
                Tab(icon: Icon(Icons.fact_check_outlined, size: 18), text: 'Document Verification'),
                Tab(icon: Icon(Icons.event_available_outlined, size: 18), text: 'Interview Scheduler'),
                Tab(icon: Icon(Icons.badge_outlined, size: 18), text: 'Student ID Badges'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Views
          SizedBox(
            height: isMobile ? 860 : 720,
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Admissions Cockpit & Funnel
                FrontDeskDashboardScreen(
                  isDark: dark,
                  onNavigateFrontDesk: (page) {
                    switch (page) {
                      case FrontDeskPage.inquiries:
                        _tabController.animateTo(1);
                        break;
                      case FrontDeskPage.draftIntake:
                        _tabController.animateTo(2);
                        break;
                      case FrontDeskPage.documentQueue:
                        _tabController.animateTo(3);
                        break;
                      case FrontDeskPage.interviewScheduler:
                        _tabController.animateTo(4);
                        break;
                      case FrontDeskPage.idBadgeStudio:
                        _tabController.animateTo(5);
                        break;
                      default:
                        _tabController.animateTo(0);
                    }
                  },
                  onNewInquiry: () => _tabController.animateTo(1),
                ),

                // 2. Inquiry Desk & Lead Pipeline (Rows 1 & 2)
                InquiryDeskScreen(
                  isDark: dark,
                  onConvertToApplication: () => _tabController.animateTo(2),
                ),

                // 3. Assisted Application Intake (Rows 3, 4, 7, 8, 9)
                FrontDeskNewApplicationScreen(
                  isDark: dark,
                  onCancel: () {
                    ref.read(frontDeskDraftInquiryProvider.notifier).state = null;
                    _tabController.animateTo(0);
                  },
                  onSubmittedSuccess: () {
                    ref.read(frontDeskDraftInquiryProvider.notifier).state = null;
                    _tabController.animateTo(0);
                  },
                ),

                // 4. Document Verification Queue (Row 10)
                DocumentVerificationQueueScreen(isDark: dark),

                // 5. Interview Scheduler & Assessment Rubric (Rows 11 & 12)
                InterviewSchedulerScreen(isDark: dark),

                // 6. Student ID Badge Studio (Row 20)
                IdBadgeStudioScreen(isDark: dark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
