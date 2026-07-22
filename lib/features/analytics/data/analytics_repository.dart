import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medilink/features/analytics/domain/entities/daily_analytics_snapshot.dart';

/// Plain Firestore-backed repository (no Callable Functions, no offline
/// concerns beyond Firestore's own cache) — same precedent as
/// notifications/data/notification_center_repository.dart.
class AnalyticsRepository {
  AnalyticsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<HospitalStatusSnapshot?> watchHospitalStatus(String hospitalId) {
    return _firestore.collection('hospital_status').doc(hospitalId).snapshots().map(
          (doc) => doc.exists ? _statusFromFirestore(doc) : null,
        );
  }

  /// `analytics_daily` doc IDs are `{hospitalId}_{date}` with `date` in
  /// sortable `yyyy-MM-dd` form, so a document-ID range query gets the last
  /// [days] days without a composite index (two range clauses on the same
  /// field — `__name__` — never need one; equality-plus-range across
  /// different fields would).
  Future<List<DailyAnalyticsSnapshot>> getRecentDailyAnalytics(
    String hospitalId, {
    int days = 7,
  }) async {
    final today = DateTime.now();
    final cutoff = today.subtract(Duration(days: days - 1));
    final startId = '${hospitalId}_${_dateString(cutoff)}';
    final endId = '${hospitalId}_${_dateString(today)}_z';

    final snap = await _firestore
        .collection('analytics_daily')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startId)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endId)
        .get();

    final results = snap.docs.map(_dailyFromFirestore).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return results;
  }

  String _dateString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  HospitalStatusSnapshot _statusFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    int asInt(String key) => (data[key] as num?)?.toInt() ?? 0;
    return HospitalStatusSnapshot(
      isOpen: data['isOpen'] as bool? ?? false,
      emergencyDeptOpen: data['emergencyDeptOpen'] as bool? ?? false,
      icuBedsTotal: asInt('icuBedsTotal'),
      icuBedsAvailable: asInt('icuBedsAvailable'),
      generalBedsTotal: asInt('generalBedsTotal'),
      generalBedsAvailable: asInt('generalBedsAvailable'),
      ambulancesTotal: asInt('ambulancesTotal'),
      ambulancesAvailable: asInt('ambulancesAvailable'),
      activeEmergencyCount: asInt('activeEmergencyCount'),
    );
  }

  DailyAnalyticsSnapshot _dailyFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    double asDouble(String key) => (data[key] as num?)?.toDouble() ?? 0;
    int asInt(String key) => (data[key] as num?)?.toInt() ?? 0;
    return DailyAnalyticsSnapshot(
      hospitalId: data['hospitalId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      patientsCount: asInt('patientsCount'),
      emergencyCasesCount: asInt('emergencyCasesCount'),
      appointmentsCount: asInt('appointmentsCount'),
      doctorUtilizationPct: asDouble('doctorUtilizationPct'),
      bedOccupancyPct: asDouble('bedOccupancyPct'),
      icuOccupancyPct: asDouble('icuOccupancyPct'),
      revenueTotal: asDouble('revenueTotal'),
      medicineSalesTotal: asDouble('medicineSalesTotal'),
      ambulanceTripsCount: asInt('ambulanceTripsCount'),
      avgWaitingMinutes: asDouble('avgWaitingMinutes'),
      patientSatisfactionAvg: (data['patientSatisfactionAvg'] as num?)?.toDouble(),
    );
  }
}
