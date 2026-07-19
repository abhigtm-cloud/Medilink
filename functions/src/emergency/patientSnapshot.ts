import { rtdb } from "../admin";

export interface PatientSnapshot {
  name: string;
  phoneNumber: string | null;
  bloodGroup: string | null;
  age: number | null;
  medicalConditions: string[];
  emergencyContact: { name: string; phone: string } | null;
}

function ageFromDob(dateOfBirth: string | undefined): number | null {
  if (!dateOfBirth) return null;
  const dob = new Date(dateOfBirth);
  if (Number.isNaN(dob.getTime())) return null;
  const diffMs = Date.now() - dob.getTime();
  return Math.floor(diffMs / (1000 * 60 * 60 * 24 * 365.25));
}

/**
 * Denormalized snapshot captured at SOS-creation time so the hospital sees
 * it even if the patient's profile later changes (architecture doc §4.3).
 *
 * NOTE: the current `users/{uid}` RTDB profile (lib/features/auth/models/app_user.dart)
 * has no `medicalConditions` or `emergencyContact` fields yet — those default
 * to empty/null here until a profile screen collects them. Flagged as a gap,
 * not silently invented.
 */
export async function loadPatientSnapshot(uid: string): Promise<PatientSnapshot> {
  const snap = await rtdb.ref(`users/${uid}`).get();
  const data = (snap.val() ?? {}) as Record<string, unknown>;

  return {
    name: (data.displayName as string) || (data.email as string) || "Unknown Patient",
    phoneNumber: (data.phoneNumber as string) ?? null,
    bloodGroup: (data.bloodGroup as string) ?? null,
    age: ageFromDob(data.dateOfBirth as string | undefined),
    medicalConditions: [],
    emergencyContact: null,
  };
}
