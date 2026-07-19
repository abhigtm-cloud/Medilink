/**
 * TS port of lib/core/services/geo_scoring_service.dart — keep both in sync.
 * Weights and normalization per docs/EMERGENCY_PLATFORM_ARCHITECTURE.md §7.
 */
export interface HospitalCandidate {
  hospitalId: string;
  distanceKm: number;
  etaMinutes: number;
  icuBedsAvailable: number;
  icuBedsTotal: number;
  emergencyDoctorsAvailable: number;
  ambulancesAvailable: number;
  activeEmergencyCount: number;
}

export interface ScoredHospital {
  candidate: HospitalCandidate;
  score: number;
}

const DISTANCE_WEIGHT = 0.25;
const ETA_WEIGHT = 0.2;
const ED_WEIGHT = 0.15;
const ICU_WEIGHT = 0.15;
const DOCTOR_WEIGHT = 0.1;
const AMBULANCE_WEIGHT = 0.1;
const QUEUE_WEIGHT = 0.05;
const QUEUE_SATURATION_THRESHOLD = 10;

function clamp01(v: number): number {
  if (Number.isNaN(v)) return 0;
  return Math.min(1, Math.max(0, v));
}

export function rankHospitals(candidates: HospitalCandidate[]): ScoredHospital[] {
  if (candidates.length === 0) return [];

  const maxDistance = Math.max(...candidates.map((c) => c.distanceKm));
  const maxEta = Math.max(...candidates.map((c) => c.etaMinutes));

  const scored = candidates.map((c) => {
    const distanceScore = maxDistance === 0 ? 1 : clamp01(1 - c.distanceKm / maxDistance);
    const etaScore = maxEta === 0 ? 1 : clamp01(1 - c.etaMinutes / maxEta);
    const edScore = 1; // hard-filtered upstream to only-open hospitals
    const icuScore = clamp01(c.icuBedsAvailable / (c.icuBedsTotal === 0 ? 1 : c.icuBedsTotal));
    const doctorScore = clamp01(c.emergencyDoctorsAvailable / 2);
    const ambulanceScore = c.ambulancesAvailable > 0 ? 1 : 0.3;
    const queueScore = clamp01(1 - c.activeEmergencyCount / QUEUE_SATURATION_THRESHOLD);

    const total =
      distanceScore * DISTANCE_WEIGHT +
      etaScore * ETA_WEIGHT +
      edScore * ED_WEIGHT +
      icuScore * ICU_WEIGHT +
      doctorScore * DOCTOR_WEIGHT +
      ambulanceScore * AMBULANCE_WEIGHT +
      queueScore * QUEUE_WEIGHT;

    return { candidate: c, score: total };
  });

  scored.sort((a, b) => b.score - a.score);
  return scored;
}
