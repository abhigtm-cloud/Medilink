/// Live operational snapshot from `hospital_status/{hospitalId}` — used for
/// the dashboard's "today" KPI tiles, which read this directly rather than
/// waiting on the hourly rollup (see architecture doc §14).
class HospitalStatusSnapshot {
  final bool isOpen;
  final bool emergencyDeptOpen;
  final int icuBedsTotal;
  final int icuBedsAvailable;
  final int generalBedsTotal;
  final int generalBedsAvailable;
  final int ambulancesTotal;
  final int ambulancesAvailable;
  final int activeEmergencyCount;

  const HospitalStatusSnapshot({
    required this.isOpen,
    required this.emergencyDeptOpen,
    required this.icuBedsTotal,
    required this.icuBedsAvailable,
    required this.generalBedsTotal,
    required this.generalBedsAvailable,
    required this.ambulancesTotal,
    required this.ambulancesAvailable,
    required this.activeEmergencyCount,
  });
}

/// One day's rollup from `analytics_daily/{hospitalId}_{date}`, written by
/// the scheduled `aggregateDailyAnalytics` Cloud Function. Some fields have
/// no data source anywhere in the app yet (doctor utilization, patient
/// satisfaction) — they come through as 0/null rather than fabricated.
class DailyAnalyticsSnapshot {
  final String hospitalId;
  final String date;
  final int patientsCount;
  final int emergencyCasesCount;
  final int appointmentsCount;
  final double doctorUtilizationPct;
  final double bedOccupancyPct;
  final double icuOccupancyPct;
  final double revenueTotal;
  final double medicineSalesTotal;
  final int ambulanceTripsCount;
  final double avgWaitingMinutes;
  final double? patientSatisfactionAvg;

  const DailyAnalyticsSnapshot({
    required this.hospitalId,
    required this.date,
    required this.patientsCount,
    required this.emergencyCasesCount,
    required this.appointmentsCount,
    required this.doctorUtilizationPct,
    required this.bedOccupancyPct,
    required this.icuOccupancyPct,
    required this.revenueTotal,
    required this.medicineSalesTotal,
    required this.ambulanceTripsCount,
    required this.avgWaitingMinutes,
    this.patientSatisfactionAvg,
  });
}
