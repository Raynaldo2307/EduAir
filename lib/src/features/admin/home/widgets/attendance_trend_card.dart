import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:edu_air/src/features/admin/home/widgets/dashboard_card.dart';

class AttendanceTrendCard extends StatelessWidget {
  const AttendanceTrendCard({super.key});

  static const _spots = [
    FlSpot(0, 60),
    FlSpot(1, 65),
    FlSpot(2, 58),
    FlSpot(3, 72),
    FlSpot(4, 68),
    FlSpot(5, 75),
    FlSpot(6, 82),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Trend',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
                    isCurved: true,
                    color: const Color(0xFF0059BA),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0059BA).withValues(alpha: 0.3),
                          const Color(0xFF0059BA).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.arrow_upward, size: 14, color: Color(0xFF27AE60)),
              const SizedBox(width: 4),
              Text(
                '8.2% increase from last week',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
