import * as functionsV1 from "firebase-functions/v1";
import { admin, db } from "../admin";
import { requireStaffClaims } from "./requireCaller";

const TOGGLEABLE_STATUSES = ["available", "offline", "maintenance"];

export const setAmbulanceAvailability = functionsV1.https.onCall(async (data, context) => {
  const { hospitalId } = requireStaffClaims(context);
  const ambulanceId = data.ambulanceId as string;
  const status = data.status as string;

  if (!TOGGLEABLE_STATUSES.includes(status)) {
    throw new functionsV1.https.HttpsError(
      "invalid-argument",
      `status must be one of ${TOGGLEABLE_STATUSES.join(", ")}`
    );
  }

  const ref = db.collection("ambulances").doc(ambulanceId);
  const snap = await ref.get();
  if (!snap.exists || snap.data()!.hospitalId !== hospitalId) {
    throw new functionsV1.https.HttpsError("not-found", "Ambulance not found");
  }
  const current = snap.data()!;
  if (current.activeTripId) {
    throw new functionsV1.https.HttpsError(
      "failed-precondition",
      "Cannot change availability while on an active trip"
    );
  }

  const wasAvailable = current.status === "available";
  const nowAvailable = status === "available";

  await db.runTransaction(async (tx) => {
    tx.update(ref, { status });
    if (wasAvailable !== nowAvailable) {
      tx.update(db.doc(`hospital_status/${hospitalId}`), {
        ambulancesAvailable: admin.firestore.FieldValue.increment(nowAvailable ? 1 : -1),
      });
    }
  });

  return { status };
});
