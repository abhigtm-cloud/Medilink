import * as functionsV1 from "firebase-functions/v1";
import { admin, db } from "../admin";
import { loadOpenHospitalCandidates } from "./candidates";
import { enrichWithEta } from "./eta";
import { loadPatientSnapshot } from "./patientSnapshot";
import { rankHospitals, ScoredHospital } from "./scoring";
import { appendTimeline } from "./timeline";

const MAX_RADIUS_KM = 50;

type EmergencyType = "cardiac" | "accident" | "breathing" | "unspecified";

function derivePriority(type: EmergencyType): "critical" | "high" | "medium" {
  switch (type) {
    case "cardiac":
    case "breathing":
      return "critical";
    case "accident":
      return "high";
    default:
      return "medium";
  }
}

function toCandidateRecord(scored: ScoredHospital) {
  return {
    hospitalId: scored.candidate.hospitalId,
    score: scored.score,
    distanceKm: scored.candidate.distanceKm,
    etaMinutes: scored.candidate.etaMinutes,
  };
}

/**
 * The whole "GPS -> candidates -> score -> select -> create request" pipeline
 * is server-authoritative — the client never picks the hospital itself. See
 * docs/EMERGENCY_PLATFORM_ARCHITECTURE.md §8 for the full rationale.
 */
export const triggerEmergencySOS = functionsV1.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functionsV1.https.HttpsError("unauthenticated", "Sign in required");
  }
  const uid = context.auth.uid;
  const lat = data.lat as number;
  const lng = data.lng as number;
  const emergencyType = (data.emergencyType as EmergencyType) ?? "unspecified";

  if (typeof lat !== "number" || typeof lng !== "number") {
    throw new functionsV1.https.HttpsError("invalid-argument", "lat/lng are required");
  }

  const patientSnapshot = await loadPatientSnapshot(uid);
  const priority = derivePriority(emergencyType);

  const candidates = await loadOpenHospitalCandidates(lat, lng, MAX_RADIUS_KM);
  if (candidates.length === 0) {
    const ref = await db.collection("emergency_requests").add({
      patientUid: uid,
      patientSnapshot,
      status: "noHospitalFound",
      priority,
      emergencyType,
      patientLocation: new admin.firestore.GeoPoint(lat, lng),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await appendTimeline(ref.id, "noHospitalFound", "No hospital found within range", null);
    return { requestId: ref.id, status: "noHospitalFound" };
  }

  const withEta = await enrichWithEta(lat, lng, candidates);
  const ranked = rankHospitals(withEta);
  const winner = ranked[0];

  const ref = db.collection("emergency_requests").doc();
  await db.runTransaction(async (tx) => {
    tx.set(ref, {
      patientUid: uid,
      patientSnapshot,
      status: "hospitalAssigned",
      priority,
      emergencyType,
      patientLocation: new admin.firestore.GeoPoint(lat, lng),
      patientLocationUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      selectedHospitalId: winner.candidate.hospitalId,
      hospitalCandidates: ranked.slice(0, 5).map(toCandidateRecord),
      distanceKm: winner.candidate.distanceKm,
      etaMinutes: winner.candidate.etaMinutes,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(db.doc(`hospital_status/${winner.candidate.hospitalId}/queue/${ref.id}`), {
      requestId: ref.id,
      priority,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(db.doc(`hospital_status/${winner.candidate.hospitalId}`), {
      activeEmergencyCount: admin.firestore.FieldValue.increment(1),
    });
  });
  await appendTimeline(ref.id, "hospitalAssigned", "Hospital selected and notified", null);

  // Push notification to hospital staff is deferred to the "Notification
  // flow hardening" roadmap step (architecture doc §23 step 5) — FCM
  // topics/tokens aren't wired up yet. Command Center picks this request up
  // via the `hospital_status/{hospitalId}/queue` pointer doc in the
  // meantime.

  return {
    requestId: ref.id,
    status: "hospitalAssigned",
    selectedHospitalId: winner.candidate.hospitalId,
    distanceKm: winner.candidate.distanceKm,
    etaMinutes: winner.candidate.etaMinutes,
  };
});
