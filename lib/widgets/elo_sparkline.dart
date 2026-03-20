import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/elo_history_provider.dart';
import '../theme/app_colors.dart';

/// A sparkline of the player's last 50 ELO ratings.
///
/// Data is read from Hive via [eloHistoryProvider] — no network call.
/// If fewer than 2 data points exist the chart is replaced by placeholder
/// text prompting the user to play a round.
class EloSparkline extends ConsumerWidget {
  const EloSparkline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(eloHistoryProvider);

    return historyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (history) {
        if (history.length < 2) {
          return const Center(
            child: Text(
              'Play your first round to see your rating history',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          );
        }

        final spots = history
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.rating.toDouble()))
            .toList();

        final ratings = history.map((r) => r.rating);
        final minY = ratings.reduce(math.min).toDouble() - 10;
        final maxY = ratings.reduce(math.max).toDouble() + 10;

        return LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: AppColors.teal,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.accentGlow, AppColors.accentTransparent],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
