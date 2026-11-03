import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_controller.dart';

class ExamSummaryCards extends ConsumerWidget {
  const ExamSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(examSummaryStatsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final isTablet = constraints.maxWidth >= 650 && constraints.maxWidth < 950;

        final items = [
          _SummaryCardData(
            title: 'Total Exams',
            count: stats.total,
            icon: Icons.assignment_outlined,
            color: const Color(0xFF6366F1), // Indigo
            bgColor: const Color(0xFFEEF2FF),
            darkBgColor: const Color(0xFF1E1E38),
          ),
          _SummaryCardData(
            title: 'Upcoming (Planned)',
            count: stats.upcoming,
            icon: Icons.schedule,
            color: const Color(0xFF2563EB), // Blue
            bgColor: const Color(0xFFEFF6FF),
            darkBgColor: const Color(0xFF172554),
          ),
          _SummaryCardData(
            title: 'Ongoing',
            count: stats.ongoing,
            icon: Icons.play_circle_outline,
            color: const Color(0xFFD97706), // Amber
            bgColor: const Color(0xFFFFFBEB),
            darkBgColor: const Color(0xFF2E230B),
          ),
          _SummaryCardData(
            title: 'Completed',
            count: stats.completed,
            icon: Icons.check_circle_outline,
            color: const Color(0xFF059669), // Emerald
            bgColor: const Color(0xFFECFDF5),
            darkBgColor: const Color(0xFF064E3B),
          ),
        ];

        if (isMobile) {
          // 2x2 grid for mobile
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 80,
            ),
            itemBuilder: (context, index) {
              return _buildCard(items[index], isDark);
            },
          );
        } else if (isTablet) {
          // 2x2 with wider aspect
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 84,
            ),
            itemBuilder: (context, index) {
              return _buildCard(items[index], isDark);
            },
          );
        } else {
          // 4 cards in a row
          return Row(
            children: items
                .map((item) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: _buildCard(item, isDark),
                      ),
                    ))
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildCard(_SummaryCardData data, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? data.darkBgColor : data.bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${data.count}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCardData {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color darkBgColor;

  const _SummaryCardData({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.darkBgColor,
  });
}

