import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/src/themes/app_colors.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';

class PrincipalFinanceScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final bool isWaiversView;

  const PrincipalFinanceScreen({
    super.key,
    required this.isDark,
    this.isWaiversView = false,
  });

  @override
  ConsumerState<PrincipalFinanceScreen> createState() => _PrincipalFinanceScreenState();
}

class _PrincipalFinanceScreenState extends ConsumerState<PrincipalFinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _feeWaiverRequests = [
    {
      'id': 'fw-2026-001',
      'student': 'Aarav Sharma',
      'class': 'Class 9 - A',
      'parent': 'Manoj Sharma',
      'category': 'Merit Scholarship Waiver',
      'requestedWaiver': '35% Tuition Concession',
      'currentFee': '₹48,000 / year',
      'reason': 'State Level Science Olympiad 1st Rank Holder',
      'status': 'Pending Approval',
    },
    {
      'id': 'fw-2026-002',
      'student': 'Rohan & Priya Verma (Siblings)',
      'class': 'Class 7 & Class 4',
      'parent': 'Sunil Verma',
      'category': 'Sibling Concession',
      'requestedWaiver': '20% Sibling Discount on 2nd Child',
      'currentFee': '₹42,000 / year',
      'reason': 'Enrolled in same institution for > 3 years',
      'status': 'Pending Approval',
    },
    {
      'id': 'fw-2026-003',
      'student': 'Sneha Patil',
      'class': 'Class 11 - Science',
      'parent': 'Girish Patil',
      'category': 'EWS / Financial Hardship',
      'requestedWaiver': '50% Need-Based Grant',
      'currentFee': '₹55,000 / year',
      'reason': 'Family medical emergency documentation verified by Social Welfare desk',
      'status': 'Pending Approval',
    },
  ];

  final List<Map<String, dynamic>> _defaultersList = [
    {
      'student': 'Aditya Roy',
      'class': 'Class 10 - B',
      'parent': 'Prakash Roy',
      'phone': '+91 98301 23456',
      'overdue': '₹18,500',
      'daysOverdue': '42 days',
    },
    {
      'student': 'Simran Kaur',
      'class': 'Class 8 - A',
      'parent': 'Gurpreet Singh',
      'phone': '+91 98111 87654',
      'overdue': '₹12,000',
      'daysOverdue': '28 days',
    },
    {
      'student': 'Tanmay Kulkarni',
      'class': 'Class 12 - Commerce',
      'parent': 'Vijay Kulkarni',
      'phone': '+91 94220 54321',
      'overdue': '₹24,000',
      'daysOverdue': '60 days',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.isWaiversView ? 1 : 0);
  }

  @override
  void didUpdateWidget(covariant PrincipalFinanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isWaiversView != widget.isWaiversView) {
      _tabController.animateTo(widget.isWaiversView ? 1 : 0);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  const Color(0xFFF59E0B).withValues(alpha: widget.isDark ? 0.25 : 0.12),
                  cardBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 22 : 28,
                  backgroundColor: const Color(0xFFF59E0B),
                  child: const Icon(Icons.account_balance, color: Colors.white, size: 26),
                ),
                SizedBox(width: isMobile ? 12 : 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Institutional Finance Analytics & Fee Waivers',
                        style: TextStyle(
                          fontSize: isMobile ? 17 : 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Executive revenue trends, fee defaulter monitoring, and merit/hardship fee waiver recommendations.',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFF59E0B),
            unselectedLabelColor: subColor,
            indicatorColor: const Color(0xFFF59E0B),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insights_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Fee Analytics & Defaulters', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.request_quote_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Fee Waiver Approvals', style: TextStyle(fontWeight: FontWeight.bold)),
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
                // Fee Analytics & Defaulters
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 600;
                        final kpi1 = _buildFinanceKpi('Total Annual Billed', '₹2.84 Cr', AppColors.primary, cardBg, borderColor, textColor, subColor);
                        final kpi2 = _buildFinanceKpi('Collected to Date', '₹2.19 Cr (77.1%)', AppColors.success, cardBg, borderColor, textColor, subColor);
                        final kpi3 = _buildFinanceKpi('Overdue Defaulters', '₹14.2 L', AppColors.error, cardBg, borderColor, textColor, subColor);

                        if (isNarrow) {
                          return Column(
                            children: [
                              kpi1,
                              const SizedBox(height: 10),
                              kpi2,
                              const SizedBox(height: 10),
                              kpi3,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: kpi1),
                            const SizedBox(width: 12),
                            Expanded(child: kpi2),
                            const SizedBox(width: 12),
                            Expanded(child: kpi3),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Chart Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Quarterly Institutional Revenue Realization',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              const Text('FY 2026-2027', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 180,
                            child: BarChart(
                              BarChartData(
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 38,
                                      getTitlesWidget: (v, m) => Text('₹${v.toInt()}L', style: TextStyle(fontSize: 9, color: subColor)),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (v, m) {
                                        const quarters = ['Apr-Jun', 'Jul-Sep', 'Oct-Dec', 'Jan-Mar'];
                                        final i = v.toInt();
                                        if (i >= 0 && i < quarters.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(quarters[i], style: TextStyle(fontSize: 10, color: subColor)),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                ),
                                barGroups: [
                                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 65, color: const Color(0xFF109F83), width: 22, borderRadius: BorderRadius.circular(4))]),
                                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 78, color: const Color(0xFF3B82F6), width: 22, borderRadius: BorderRadius.circular(4))]),
                                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 82, color: const Color(0xFF6366F1), width: 22, borderRadius: BorderRadius.circular(4))]),
                                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 42, color: const Color(0xFFF59E0B), width: 22, borderRadius: BorderRadius.circular(4))]),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Defaulters List
                    Text(
                      'Outstanding Overdue Defaulters Alert',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 10),

                    ..._defaultersList.map((d) {
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
                            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${d['student']} • ${d['class']}',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Parent: ${d['parent']} (${d['phone']}) • Overdue: ${d['overdue']} (${d['daysOverdue']})',
                                    style: TextStyle(fontSize: 11.5, color: subColor),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.sms_outlined, size: 14),
                              label: const Text('Send Alert'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Payment reminder dispatched to ${d['parent']}')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              } else {
                // Fee Waiver Approvals
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Fee Concession & Waiver Applications',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 10),

                    ..._feeWaiverRequests.map((req) {
                      final isHandled = req['status'] != 'Pending Approval';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${req['student']} • ${req['class']}',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    req['category'],
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Requested Waiver: ${req['requestedWaiver']} (Standard: ${req['currentFee']})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF109F83)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Verification Note: ${req['reason']}',
                              style: TextStyle(fontSize: 11.5, color: subColor),
                            ),
                            const SizedBox(height: 12),
                            if (!isHandled) ...[
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.check, size: 15),
                                    label: const Text('Approve Concession'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        req['status'] = 'Approved by Principal';
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Waiver for ${req['student']} APPROVED and sent to Accounts!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.close, size: 15),
                                    label: const Text('Decline'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(color: AppColors.error),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        req['status'] = 'Declined';
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Waiver for ${req['student']} declined.')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  req['status'],
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
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

  Widget _buildFinanceKpi(String label, String value, Color accent, Color cardBg, Color borderColor, Color textColor, Color subColor) {
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
          Text(label, style: TextStyle(fontSize: 11.5, color: subColor)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accent),
          ),
        ],
      ),
    );
  }
}
