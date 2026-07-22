import * as functionsV1 from "firebase-functions/v1";
import { admin, db } from "../admin";
import { requireStaffClaims } from "./requireCaller";
import { appendTimeline } from "../emergency/timeline";
import { notifyUser } from "../notifications/sendFcm";

/**
 * Callable by the assigned driver or any hospital staff. Frees the
 * ambulance back to `available` and — since a completed trip means the
 * patient reached the hospital — advances the emergency straight to
 * `reachedHospital` (the driver-side trip status machine is intentionally
 * simplified to dispatched -> completed for this feature's scope; no
 * separate "arrived at patient" / "transporting" granularity yet).
 */
export const completeTrip = functionsV1.https.onCall(async (data, context) => {
  const { hospitalId, uid, role } = requireStaffClaims(context);
  const tripId = data.tripId as string;
  if (!tripId) {
    throw new functionsV1.https.HttpsError("invalid-argument", "tripId is required");
  }

  const mirrorTripRef = db.collection("ambulance_trips").doc(tripId);
  let emergencyRequestId = "";
  let patientUid = "";

  await db.runTransaction(async (tx) => {
    const tripSnap = await tx.get(mirrorTripRef);
    if (!tripSnap.exists) {
      throw new functionsV1.https.HttpsError("not-found", "Trip not found");
    }
    const trip = tripSnap.data()!;
    if (trip.hospitalId !== hospitalId) {
      throw new functionsV1.https.HttpsError(
        "permission-denied",
        "This trip does not belong to your hospital"
      );
    }
    if (trip.status === "completed") {
      throw new functionsV1.https.HttpsError("failed-precondition", "Trip already completed");
    }

    const ambulanceRef = db.doc(`ambulances/${trip.ambulanceId}`);
    const ambulanceSnap = await tx.get(ambulanceRef);
    if (role === "ambulance_driver" && ambulanceSnap.data()?.driverUid !== uid) {
      throw new functionsV1.https.HttpsError(
        "permission-denied",
        "You are not the assigned driver for this ambulance"
      );
    }

    const emergencyRef = db.doc(`emergency_requests/${trip.emergencyRequestId}`);
    const emergencySnap = await tx.get(emergencyRef);

    const subTripRef = db.doc(`ambulances/${trip.ambulanceId}/trips/${tripId}`);
    const completedAt = admin.firestore.FieldValue.serverTimestamp();
    tx.update(mirrorTripRef, { status: "completed", completedAt });
    tx.update(subTripRef, { status: "completed", completedAt });
    tx.update(ambulanceRef, { status: "available", activeTripId: null });
    tx.update(db.doc(`hospital_status/${hospitalId}`), {
      ambulancesAvailable: admin.firestore.FieldValue.increment(1),
    });
    tx.update(emergencyRef, {
      status: "reachedHospital",
      arrivedAt: completedAt,
      updatedAt: completedAt,
    });
    emergencyRequestId = trip.emergencyRequestId as string;
    patientUid = (emergencySnap.data()?.patientUid as string) ?? "";
  });

  await appendTimeline(
    emergencyRequestId,
    "reachedHospital",
    "Patient Reached Hospital (Ambulance)",
    role
  );
  if (patientUid) {
    await notifyUser(patientUid, {
      type: "ambulance",
      title: "Ambulance Arrived",
      body: "You've arrived at the hospital.",
      data: { requestId: emergencyRequestId },
    });
  }

  return { status: "completed" };
});
