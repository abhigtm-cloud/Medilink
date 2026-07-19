/// Pure Hospital Suitability Score function — zero Firebase imports, so it's
/// unit-testable on its own and safe to use for an optimistic client-side
/// preview while the authoritative server-side pick comes back. Mirrored
/// line-for-line in functions/src/emergency/scoring.ts for the Cloud
/// Function that actually selects the hospital. Weights and normalization
/// per docs/EMERGENCY_PLATFORM_ARCHITECTURE.md §7 — keep both in sync.
class HospitalCandidate {
  final String hospitalId;
  final double distanceKm;
  final double etaMinutes;
  final int icuBedsAvailable;
  final int icuBedsTotal;
  final int emergencyDoctorsAvailable;
  final int ambulancesAvailable;
  final int activeEmergencyCount;

  const HospitalCandidate({
    required this.hospitalId,
    required this.distanceKm,
    required this.etaMinutes,
    required this.icuBedsAvailable,
    required this.icuBedsTotal,
    required this.emergencyDoctorsAvailable,
    required this.ambulancesAvailable,
    required this.activeEmergencyCount,
  });
}

class ScoredHospital {
  final HospitalCandidate candidate;
  final double score;
  const ScoredHospital(this.candidate, this.score);
}

class GeoScoringService {
  static const double kDistanceWeight = 0.25;
  static const double kEtaWeight = 0.20;
  static const double kEdWeight = 0.15;
  static const double kIcuWeight = 0.15;
  static const double kDoctorWeight = 0.10;
  static const double kAmbulanceWeight = 0.10;
  static const double kQueueWeight = 0.05;
  static const int kQueueSaturationThreshold = 10;

  static double _clamp01(double v) => v.isNaN ? 0 : v.clamp(0.0, 1.0);

  static List<ScoredHospital> rank(List<HospitalCandidate> candidates) {
    if (candidates.isEmpty) return [];
    final maxDistance =
        candidates.map((c) => c.distanceKm).reduce((a, b) => a > b ? a : b);
    final maxEta =
        candidates.map((c) => c.etaMinutes).reduce((a, b) => a > b ? a : b);

    final scored = candidates.map((c) {
      final distanceScore =
          maxDistance == 0 ? 1.0 : _clamp01(1 - (c.distanceKm / maxDistance));
      final etaScore = maxEta == 0 ? 1.0 : _clamp01(1 - (c.etaMinutes / maxEta));
      const edScore = 1.0; // hard-filtered upstream to only-open hospitals
      final icuScore = _clamp01(
          c.icuBedsAvailable / (c.icuBedsTotal == 0 ? 1 : c.icuBedsTotal));
      final doctorScore = _clamp01(c.emergencyDoctorsAvailable / 2.0);
      final ambulanceScore = c.ambulancesAvailable > 0 ? 1.0 : 0.3;
      final queueScore =
          _clamp01(1 - (c.activeEmergencyCount / kQueueSaturationThreshold));

      final total = distanceScore * kDistanceWeight +
          etaScore * kEtaWeight +
          edScore * kEdWeight +
          icuScore * kIcuWeight +
          doctorScore * kDoctorWeight +
          ambulanceScore * kAmbulanceWeight +
          queueScore * kQueueWeight;

      return ScoredHospital(c, total);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored;
  }
}
