import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/src/themes/app_colors.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';

class PrincipalExaminationsScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final bool isMarksModeration;

  const PrincipalExaminationsScreen({
    super.key,
    required this.isDark,
    this.isMarksModeration = false,
  });

  @override
  ConsumerState<PrincipalExaminationsScreen> createState() => _PrincipalExaminationsScreenState();
}

class _PrincipalExaminationsScreenState extends ConsumerState<PrincipalExaminationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isReportCardsPublished = false;

  final List<Map<String, dynamic>> _examTerms = [
    {
      'term': 'Term 1 / Mid-Term Assessments',
      'dates': '15 Sep 2026 - 28 Sep 2026',
      'status': 'Completed & Moderated',
      'classes': 'Classes 1 - 12',
      'published': true,
    },
    {
      'term': 'Term 2 / Pre-Board & Half-Yearly',
      'dates': '10 Dec 2026 - 22 Dec 2026',
      'status': 'Grading in Progress',
      'classes': 'Classes 9 - 12',
      'published': false,
    },
    {
      'term': 'Annual Institutional Final Board',
      'dates': '05 Mar 2027 - 24 Mar 2027',
      'status': 'Scheduled',
      'classes': 'All Classes',
      'published': false,
    },
  ];

  final List<Map<String, dynamic>> _moderationQueue = [
    {
      'class': 'Class 10 - Section A',
      'subject': 'Mathematics (Standard)',
      'teacher': 'Dr. Rajeshwari Swaminathan',
      'submitted': '42 / 42 Students',
      'avgScore': '84.6%',
      'highestScore': '99/100',
      'status': 'Ready for Executive Sign-off',
      'locked': false,
    },
    {
      'class': 'Class 10 - Section B',
      'subject': 'Physics & Chemistry',
      'teacher': 'Vikramaditya Sen',
      'submitted': '39 / 40 Students',
      'avgScore': '78.2%',
      'highestScore': '96/100',
      'status': '1 Student Pending (Medical)',
      'locked': false,
    },
    {
      'class': 'Class 12 - Section A',
      'subject': 'Advanced Mathematics',
      'teacher': 'Ananya Deshmukh',
      'submitted': '35 / 35 Students',
      'avgScore': '88.1%',
      'highestScore': '100/100',
      'status': 'Ready for Executive Sign-off',
      'locked': true,
    },
    {
      'class': 'Class 8 - Section C',
      'subject': 'Social Science',
      'teacher': 'Amit Chatterjee',
      'submitted': '38 / 38 Students',
      'avgScore': '76.4%',
      'highestScore': '92/100',
      'status': 'Ready for Executive Sign-off',
      'locked': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.isMarksModeration ? 1 : 0);
  }

  @override
  void didUpdateWidget(covariant PrincipalExaminationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMarksModeration != widget.isMarksModeration) {
      _tabController.animateTo(widget.isMarksModeration ? 1 : 0);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _publishAllReportCards() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('Publish Term Report Cards', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to lock all moderated subject marks and release electronic report cards to Student and Parent portals? This action dispatches the Principal electronic stamp.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _isReportCardsPublished = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report Cards successfully PUBLISHED with Principal seal to Student & Parent Portals!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Confirm & Publish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final cardBg = widget.isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = widget.isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = widget.isDark ? Colors.white : AppColors.textPrimaryLight;
    final subColor = widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withValues(alpha: widget.isDark ? 0.25 : 0.12),
                  cardBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 22 : 28,
                  backgroundColor: const Color(0xFF8B5CF6),
                  child: const Icon(Icons.quiz, color: Colors.white, size: 26),
                ),
                SizedBox(width: isMobile ? 12 : 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Examinations, Grading & Report Cards',
                        style: TextStyle(
                          fontSize: isMobile ? 17 : 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Exam schedule configuration, teacher mark entry moderation, grade locking, and digital report card release.',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF8B5CF6),
            unselectedLabelColor: subColor,
            indicatorColor: const Color(0xFF8B5CF6),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_note_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Exam Terms & Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fact_check_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Marks Moderation & Publishing', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 0) {
                // Exam Terms
                return Column(
                  children: _examTerms.map((term) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.school, color: Color(0xFF8B5CF6), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  term['term'],
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Dates: ${term['dates']} • Applicable: ${term['classes']}',
                                  style: TextStyle(fontSize: 12, color: subColor),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (term['published'] as bool)
                                  ? AppColors.success.withValues(alpha: 0.14)
                                  : const Color(0xFF8B5CF6).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              term['status'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: (term['published'] as bool) ? AppColors.success : const Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              } else {
                // Marks Moderation & Publishing
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Term 1 Institutional Assessment Moderation',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '3 of 4 classes have all grades moderated. Report cards are ready for digital seal.',
                                  style: TextStyle(fontSize: 11.5, color: subColor),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: Icon(_isReportCardsPublished ? Icons.check_circle : Icons.send, size: 16),
                            label: Text(_isReportCardsPublished ? 'Report Cards Published' : 'Publish Report Cards'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isReportCardsPublished ? AppColors.success : const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _isReportCardsPublished ? null : _publishAllReportCards,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Moderation Queue Cards
                    ..._moderationQueue.map((item) {
                      final isLocked = item['locked'] as bool;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isLocked
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isLocked ? Icons.lock_outline : Icons.pending_actions,
                                color: isLocked ? AppColors.success : const Color(0xFF8B5CF6),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item['class']} • ${item['subject']}',
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Faculty: ${item['teacher']} • Submissions: ${item['submitted']} • Avg: ${item['avgScore']}',
                                    style: TextStyle(fontSize: 11.5, color: subColor),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLocked) ...[
                              OutlinedButton.icon(
                                icon: const Icon(Icons.lock, size: 14),
                                label: const Text('Lock Grades'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  setState(() {
                                    item['locked'] = true;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Grades for ${item['class']} locked successfully!')),
                                  );
                                },
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Locked & Sealed',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
