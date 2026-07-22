import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/analytics/domain/entities/daily_analytics_snapshot.dart';
import 'package:medilink/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';

/// Live KPI tiles (from `hospital_status`, no aggregation needed) + a
/// 7-day trend for emergency case volume (from `analytics_daily`). Uses
/// plain Flutter widgets for the trend bars rather than a new charting
/// dependency — see architecture doc §14.
class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitalIdAsync = ref.watch(currentHospitalIdProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(title: const Text('Analytics')),
      body: hospitalIdAsync.when(
        data: (hospitalId) {
          if (hospitalId == null) {
            return const Center(child: Text('No hospital linked to your account yet.'));
          }
          return _DashboardBody(hospitalId: hospitalId);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load: $error')),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.hospitalId});

  final String hospitalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(hospitalStatusProvider(hospitalId));
    final historyAsync = ref.watch(recentAnalyticsProvider(hospitalId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          statusAsync.when(
            data: (status) => status == null
                ? const Text('No live status recorded for this hospital yet.')
                : _KpiGrid(status: status),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Unable to load: $error'),
          ),
          const SizedBox(height: 24),
          const Text('Last 7 Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          historyAsync.when(
            data: (history) => history.isEmpty
                ? const Text(
                    'No analytics recorded yet — the hourly rollup populates this once '
                    'emergencies start flowing.',
                  )
                : _TrendSection(history: history),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Unable to load: $error'),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.status});

  final HospitalStatusSnapshot status;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _KpiTile(
        label: 'ICU Beds',
        value: '${status.icuBedsAvailable}/${status.icuBedsTotal}',
        icon: Icons.bed,
        color: AppColors.error,
      ),
      _KpiTile(
        label: 'General Beds',
        value: '${status.generalBedsAvailable}/${status.generalBedsTotal}',
        icon: Icons.hotel,
        color: AppColors.info,
      ),
      _KpiTile(
        label: 'Ambulances',
        value: '${status.ambulancesAvailable}/${status.ambulancesTotal}',
        icon: Icons.local_shipping,
        color: AppColors.warning,
      ),
      _KpiTile(
        label: 'Active Emergencies',
        value: '${status.activeEmergencyCount}',
        icon: Icons.emergency,
        color: AppColors.primary,
      ),
    ];
    return Wrap(spacing: 12, runSpacing: 12, children: tiles);
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 12)),
        ],
      ),
    );
  }
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.history});

  final List<DailyAnalyticsSnapshot> history;

  @override
  Widget build(BuildContext context) {
    final maxCases = history.fold<int>(0, (max, d) => d.emergencyCasesCount > max ? d.emergencyCasesCount : max);
    final totalTrips = history.fold<int>(0, (sum, d) => sum + d.ambulanceTripsCount);
    final totalSales = history.fold<double>(0, (sum, d) => sum + d.medicineSalesTotal);
    final avgWait = history.isEmpty
        ? 0.0
        : history.fold<double>(0, (sum, d) => sum + d.avgWaitingMinutes) / history.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Emergency Cases', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            for (final day in history) _BarRow(day: day, maxCases: maxCases == 0 ? 1 : maxCases),
            const Divider(height: 24),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _SummaryStat(label: 'Avg. Wait', value: '${avgWait.toStringAsFixed(0)} min'),
                _SummaryStat(label: 'Ambulance Trips', value: '$totalTrips'),
                _SummaryStat(label: 'Medicine Sales', value: totalSales.toStringAsFixed(0)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.day, required this.maxCases});

  final DailyAnalyticsSnapshot day;
  final int maxCases;

  @override
  Widget build(BuildContext context) {
    final fraction = day.emergencyCasesCount / maxCases;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(day.date.substring(5), style: const TextStyle(fontSize: 12))),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 16,
                    width: constraints.maxWidth * fraction,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Text('${day.emergencyCasesCount}', style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 12)),
      ],
    );
  }
}
