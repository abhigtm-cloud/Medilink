import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/analytics/data/analytics_repository.dart';
import 'package:medilink/features/analytics/domain/entities/daily_analytics_snapshot.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepository(),
);

final hospitalStatusProvider =
    StreamProvider.autoDispose.family<HospitalStatusSnapshot?, String>((ref, hospitalId) {
  return ref.watch(analyticsRepositoryProvider).watchHospitalStatus(hospitalId);
});

final recentAnalyticsProvider =
    FutureProvider.autoDispose.family<List<DailyAnalyticsSnapshot>, String>((ref, hospitalId) {
  return ref.watch(analyticsRepositoryProvider).getRecentDailyAnalytics(hospitalId);
});
