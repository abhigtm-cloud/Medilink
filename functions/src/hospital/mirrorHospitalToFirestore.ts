import * as functionsV1 from "firebase-functions/v1";
import { admin, db } from "../admin";

interface RtdbHospital {
  name?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
}

/**
 * One-directional sync: Realtime Database `hospitals/{hospitalId}` (still
 * the authoritative source for hospital identity — untouched, per the
 * hybrid data-layer decision) mirrors its geo-relevant fields into Cloud
 * Firestore `hospital_directory/{hospitalId}` so the emergency SOS hot path
 * only ever has to query Firestore. See docs/EMERGENCY_PLATFORM_ARCHITECTURE.md §0.
 */
export const mirrorHospitalToFirestore = functionsV1.database
  .ref("/hospitals/{hospitalId}")
  .onWrite(async (change, context) => {
    const hospitalId = context.params.hospitalId as string;
    const directoryRef = db.doc(`hospital_directory/${hospitalId}`);

    if (!change.after.exists()) {
      await directoryRef.delete().catch(() => undefined);
      return;
    }

    const after = change.after.val() as RtdbHospital;
    if (
      !after.name ||
      !after.address ||
      typeof after.latitude !== "number" ||
      typeof after.longitude !== "number"
    ) {
      // Incomplete hospital record (e.g. lat/lng not geocoded yet) —
      // nothing usable to mirror until it's filled in on a later write.
      return;
    }

    await directoryRef.set({
      hospitalId,
      name: after.name,
      address: after.address,
      location: new admin.firestore.GeoPoint(after.latitude, after.longitude),
      syncedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
