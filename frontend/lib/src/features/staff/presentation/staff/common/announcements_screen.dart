import 'package:flutter/material.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';
import 'package:frontend/src/themes/app_colors.dart';

class AnnouncementsScreen extends StatefulWidget {
  final bool isDark;

  const AnnouncementsScreen({
    super.key,
    this.isDark = false,
  });

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _announcements = [
    {
      'id': 'ANN-01',
      'title': 'Mandatory Mid-Term Syllabus Submission Deadline',
      'category': 'Academic',
      'date': '21 Oct 2026',
      'postedBy': 'Office of the Principal',
      'body':
          'All Teaching Faculty members are requested to upload their revised term syllabi, question bank blueprint, and remedial class plans on the portal by 28th October 2026, 5:00 PM.',
      'priority': 'High',
    },
    {
      'id': 'ANN-02',
      'title': 'Annual Sports Day 2026: Faculty Committee Formation',
      'category': 'Events',
      'date': '19 Oct 2026',
      'postedBy': 'Physical Education Department',
      'body':
          'Preparations for the Inter-House Athletics Meet are underway. Staff interested in joining the track coordination, scoring, or medical liaison sub-committees may reach out to Gurpreet Singh Gill.',
      'priority': 'Medium',
    },
    {
      'id': 'ANN-03',
      'title': 'Diwali Festive Vacation & Institutional Holiday Calendar',
      'category': 'Holidays',
      'date': '15 Oct 2026',
      'postedBy': 'School Administration',
      'body':
          'The school campus will remain closed for the Diwali holidays from 31st October 2026 to 03rd November 2026. Regular academic sessions will resume on Monday, 04th November 2026.',
      'priority': 'Normal',
    },
    {
      'id': 'ANN-04',
      'title': 'Faculty Health Screening & Eye Checkup Camp',
      'category': 'Staff Welfare',
      'date': '10 Oct 2026',
      'postedBy': 'Human Resources & Infirmary',
      'body':
          'A comprehensive health screening and retina scan camp will be hosted at the campus medical center this Saturday from 9:30 AM to 1:00 PM for all permanent and contractual staff members.',
      'priority': 'Normal',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark || widget.isDark;

    final cardBg = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = dark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final isMobile = ResponsiveLayout.isMobile(context);

    final filtered = _selectedCategory == 'All'
        ? _announcements
        : _announcements.where((a) => a['category'] == _selectedCategory).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Institutional Announcements & Circulars',
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Official directives, academic timelines, and campus notices from the Executive Directorate',
            style: TextStyle(fontSize: 12, color: subColor),
          ),
          const SizedBox(height: 20),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Academic', 'Events', 'Holidays', 'Staff Welfare'].map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : textColor,
                    ),
                    onSelected: (val) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Announcements List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ann = filtered[index];
              final isHigh = ann['priority'] == 'High';

              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isHigh ? AppColors.warning.withValues(alpha: 0.6) : borderColor,
                    width: isHigh ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ann['category'] as String,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (isHigh) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'URGENT',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          ann['date'] as String,
                          style: TextStyle(fontSize: 11, color: subColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ann['title'] as String,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ann['body'] as String,
                      style: TextStyle(fontSize: 12, height: 1.45, color: subColor),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.account_circle_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Posted by: ${ann['postedBy']}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
