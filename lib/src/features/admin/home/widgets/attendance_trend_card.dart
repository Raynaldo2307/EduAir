import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:edu_air/src/features/admin/home/widgets/dashboard_card.dart';
import 'package:edu_air/src/features/admin/home/application/admin_home_provider.dart';

// Displays the 30-day attendance trend as a line chart.
// Receives pre-parsed data from adminHomeProvider — does zero fetching itself.
class AttendanceTrendCard extends StatelessWidget {
  const AttendanceTrendCard({
    super.key,
    required this.trendData,   // 30 AttendanceTrendPoints, one per school day
    required this.trendLabel,  // e.g. "+3.2% increase from last week"
  });

  final List<AttendanceTrendPoint> trendData;
  final String trendLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Convert each AttendanceTrendPoint into an (x, y) coordinate for fl_chart.
    // x = day index (0 = oldest, 29 = most recent) — the horizontal position on the chart.
    // y = totalPresent (present + late) — everyone who physically showed up that day.
    //
    // If trendData is empty (loading state or new school with zero records),
    // fall back to a single zero point so fl_chart doesn't crash with an empty list.
    final spots = trendData.isEmpty
        ? [const FlSpot(0, 0)]
        : trendData
            .asMap()          // converts List into Map<int, AttendanceTrendPoint>
            .entries           // gives us (index, value) pairs
            .map((e) => FlSpot(
                  e.key.toDouble(),              // x = day index as double
                  e.value.totalPresent.toDouble(), // y = attendance count as double
                ))
            .toList();

    // Decide the label colour based on the trend direction.
    // If we don't have enough data yet, use a muted grey — it's informational, not alarming.
    // If the trend is up → green. If down → red.
    final notEnoughData = trendData.length < 14;
    final isUp          = trendLabel.contains('increase');
    final labelColor = notEnoughData
        ? cs.onSurface.withValues(alpha: 0.4)   // muted — not enough data to judge
        : isUp
            ? const Color(0xFF27AE60)            // green — attendance improving
            : const Color(0xFFE65D7B);           // red — attendance declining

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'Attendance Trend',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // The line chart — 120px tall, no grid/borders/labels for a clean look.
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData:      const FlGridData(show: false),   // no background grid lines
                titlesData:    const FlTitlesData(show: false),  // no axis labels
                borderData:    FlBorderData(show: false),        // no border box
                lineTouchData: const LineTouchData(enabled: false), // no tap tooltip

                lineBarsData: [
                  LineChartBarData(
                    spots:     spots,
                    isCurved:  true,   // smooth curve instead of sharp angles
                    color:     const Color(0xFF0059BA), // EduAir brand blue
                    barWidth:  3,
                    dotData:   const FlDotData(show: false), // no dot on each point

                    // Shaded area under the line — fades from blue to transparent downward.
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0059BA).withValues(alpha: 0.3), // top — semi-transparent blue
                          const Color(0xFF0059BA).withValues(alpha: 0.0), // bottom — fully transparent
                        ],
                        begin: Alignment.topCenter,
                        end:   Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Week-over-week label row.
          // Only shows the up/down arrow when there's enough data to have a real direction.
          Row(
            children: [
              if (!notEnoughData) ...[
                // Arrow icon — only rendered when we have a valid comparison
                Icon(
                  isUp ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: labelColor,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  trendLabel,
                  style: TextStyle(fontSize: 12, color: labelColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
