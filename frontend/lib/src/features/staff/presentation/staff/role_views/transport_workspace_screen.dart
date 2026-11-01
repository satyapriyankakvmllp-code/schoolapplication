import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';
import 'package:frontend/src/themes/app_colors.dart';
import '../../../application/staff_auth_controller.dart';

class TransportWorkspaceScreen extends ConsumerStatefulWidget {
  final bool isDark;

  const TransportWorkspaceScreen({
    super.key,
    this.isDark = false,
  });

  @override
  ConsumerState<TransportWorkspaceScreen> createState() => _TransportWorkspaceScreenState();
}

class _TransportWorkspaceScreenState extends ConsumerState<TransportWorkspaceScreen> {
  final List<Map<String, dynamic>> _buses = [
    {'busNo': 'Bus 01', 'reg': 'KA-01-F-4412', 'route': 'Route 1: Indiranagar - Ulsoor - Campus', 'driver': 'M. Guruswamy', 'phone': '+91 98450 11223', 'capacity': '42/45', 'status': 'En Route'},
    {'busNo': 'Bus 02', 'reg': 'KA-01-F-4413', 'route': 'Route 2: Whitefield - ITPL - Campus', 'driver': 'R. Jagannath', 'phone': '+91 98450 22334', 'capacity': '45/45', 'status': 'Parked'},
    {'busNo': 'Bus 03', 'reg': 'KA-01-F-4414', 'route': 'Route 3: Koramangala - HSR Layout - Campus', 'driver': 'S. Mahendran', 'phone': '+91 98450 33445', 'capacity': '38/45', 'status': 'En Route'},
    {'busNo': 'Bus 04', 'reg': 'KA-01-F-4415', 'route': 'Route 4: Malleshwaram - Rajajinagar - Campus', 'driver': 'K. Venkatesh', 'phone': '+91 98450 44556', 'capacity': '40/45', 'status': 'Maintenance'},
  ];

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
          // Header
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF97316).withValues(alpha: dark ? 0.25 : 0.12),
                  cardBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 24 : 32,
                  backgroundColor: const Color(0xFFF97316),
                  child: const Icon(Icons.directions_bus, color: Colors.white, size: 28),
                ),
                SizedBox(width: isMobile ? 12 : 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Fleet Logistics & Bus Transit Operations',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'TRANSPORT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF97316),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fleet Manager: ${staff?.fullName ?? 'Harpreet Singh Gill'} • Bus routes, driver dispatch & student transit',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Transport KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final kpiFleet = _buildKpiCard('Total Buses', '12 Vehicles', const Color(0xFFF97316), Icons.directions_bus_outlined, cardBg, borderColor, dark);
              final kpiEnRoute = _buildKpiCard('En Route Live', '08 Active', AppColors.success, Icons.gps_fixed, cardBg, borderColor, dark);
              final kpiStudents = _buildKpiCard('Transit Scholars', '486 Students', AppColors.primary, Icons.group_outlined, cardBg, borderColor, dark);
              final kpiSafety = _buildKpiCard('Safety Compliance', '100% Verified', AppColors.secondary, Icons.verified_user_outlined, cardBg, borderColor, dark);

              if (isNarrow) {
                return Column(
                  children: [
                    Row(children: [Expanded(child: kpiFleet), const SizedBox(width: 10), Expanded(child: kpiEnRoute)]),
                    const SizedBox(height: 10),
                    Row(children: [Expanded(child: kpiStudents), const SizedBox(width: 10), Expanded(child: kpiSafety)]),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: kpiFleet),
                  const SizedBox(width: 12),
                  Expanded(child: kpiEnRoute),
                  const SizedBox(width: 12),
                  Expanded(child: kpiStudents),
                  const SizedBox(width: 12),
                  Expanded(child: kpiSafety),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Bus Fleet Roster Cards
          Text('Live Institutional Vehicle Fleet & Route Roster', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _buses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final bus = _buses[index];
              final isEnRoute = bus['status'] == 'En Route';
              final isMaintenance = bus['status'] == 'Maintenance';
              final statusColor = isEnRoute ? AppColors.success : (isMaintenance ? AppColors.error : AppColors.primary);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.directions_bus_rounded, color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(bus['busNo'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                              const SizedBox(width: 8),
                              Text('(${bus['reg']})', style: TextStyle(fontSize: 11, color: subColor)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(bus['status'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(bus['route'] as String, style: TextStyle(fontSize: 12, color: subColor)),
                          const SizedBox(height: 4),
                          Text(
                            'Driver: ${bus['driver']} • Contact: ${bus['phone']} • Capacity: ${bus['capacity']}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
                          ),
                        ],
                      ),
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

  Widget _buildKpiCard(String title, String value, Color accent, IconData icon, Color cardBg, Color borderColor, bool dark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text(title, style: TextStyle(fontSize: 11, color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
