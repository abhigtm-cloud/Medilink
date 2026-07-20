import * as functionsV1 from "firebase-functions/v1";
import { admin, db } from "../admin";
import { appendTimeline } from "./timeline";
import { releaseQueueSlot } from "./queue";

const CANCELLABLE_STATUSES = ["requested", "searchingHospital", "hospitalAssigned"];

/**
 * Status transitions are Cloud-Function-only (firestore.rules only lets the
 * patient touch `patientLocation` directly), so cancellation goes through
 * here rather than a raw client Firestore write — this also lets the
 * function append the matching timeline entry and release the hospital's
 * queue slot.
 */
export const cancelEmergency = functionsV1.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functionsV1.https.HttpsError("unauthenticated", "Sign in required");
  }
  const requestId = data.requestId as string;
  const reason = (data.reason as string) ?? "Cancelled by patient";
  if (!requestId) {
    throw new functionsV1.https.HttpsError("invalid-argument", "requestId is required");
  }

  const ref = db.collection("emergency_requests").doc(requestId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new functionsV1.https.HttpsError("not-found", "Emergency request not found");
  }
  const emergency = snap.data()!;

  if (emergency.patientUid !== context.auth.uid) {
    throw new functionsV1.https.HttpsError(
      "permission-denied",
      "You may only cancel your own emergency request"
    );
  }
  if (!CANCELLABLE_STATUSES.includes(emergency.status)) {
    throw new functionsV1.https.HttpsError(
      "failed-precondition",
      "This emergency can no longer be cancelled"
    );
  }

  await ref.update({
    status: "cancelled",
    cancelReason: reason,
    cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  if (emergency.selectedHospitalId) {
    await releaseQueueSlot(emergency.selectedHospitalId as string, requestId);
  }

  await appendTimeline(requestId, "cancelled", "Cancelled by patient", "patient", { reason });

  return { status: "cancelled" };
});
