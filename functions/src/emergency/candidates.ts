import { db } from "../admin";
import { haversineDistanceKm } from "./geo";
import { HospitalCandidate } from "./scoring";

/** A scoring candidate plus the hospital's coordinates, needed for the
 * Distance Matrix API lookup in eta.ts (not part of [HospitalCandidate]
 * itself, which stays a pure scoring input). */
export type CandidateWithLocation = HospitalCandidate & {
  location: { latitude: number; longitude: number };
};

/**
 * v1 candidate search per docs/EMERGENCY_PLATFORM_ARCHITECTURE.md §4 "Notes
 * on geoqueries": fetch all `hospital_directory` docs joined with
 * `hospital_status`, compute Haversine distance in-function, filter to
 * radius. Cheap at hospital-directory-in-the-hundreds scale; revisit with
 * geohashing only if the directory grows past a few thousand hospitals.
 */
export async function loadOpenHospitalCandidates(
  lat: number,
  lng: number,
  radiusKm: number
): Promise<CandidateWithLocation[]> {
  const [directorySnap, statusSnap] = await Promise.all([
    db.collection("hospital_directory").get(),
    db.collection("hospital_status").get(),
  ]);

  const statusById = new Map(statusSnap.docs.map((d) => [d.id, d.data()]));
  const candidates: CandidateWithLocation[] = [];

  for (const doc of directorySnap.docs) {
    const status = statusById.get(doc.id);
    if (!status || status.isOpen !== true || status.emergencyDeptOpen !== true) {
      continue;
    }

    const location = doc.data().location;
    if (!location) continue;

    const distanceKm = haversineDistanceKm(lat, lng, location.latitude, location.longitude);
    if (distanceKm > radiusKm) continue;

    candidates.push({
      hospitalId: doc.id,
      distanceKm,
      etaMinutes: 0, // filled in by enrichWithEta
      icuBedsAvailable: status.icuBedsAvailable ?? 0,
      icuBedsTotal: status.icuBedsTotal ?? 0,
      emergencyDoctorsAvailable: status.emergencyDoctorsAvailable ?? 0,
      ambulancesAvailable: status.ambulancesAvailable ?? 0,
      activeEmergencyCount: status.activeEmergencyCount ?? 0,
      location: { latitude: location.latitude, longitude: location.longitude },
    });
  }

  return candidates;
}
