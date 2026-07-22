import * as functionsV1 from "firebase-functions/v1";
import { admin, db } from "../admin";
import { requireStaffClaims } from "./requireCaller";
import { appendTimeline } from "../emergency/timeline";
import { notifyUser } from "../notifications/sendFcm";

const DISPATCHABLE_EMERGENCY_STATUSES = ["accepted", "doctorAssigned"];

export const dispatchAmbulance = functionsV1.https.onCall(async (data, context) => {
  const { hospitalId, role } = requireStaffClaims(context);
  const requestId = data.requestId as string;
  const ambulanceId = data.ambulanceId as string;
  if (!requestId || !ambulanceId) {
    throw new functionsV1.https.HttpsError(
      "invalid-argument",
      "requestId and ambulanceId are required"
    );
  }

  const emergencyRef = db.collection("emergency_requests").doc(requestId);
  const ambulanceRef = db.collection("ambulances").doc(ambulanceId);
  const tripRef = ambulanceRef.collection("trips").doc();
  const mirrorTripRef = db.collection("ambulance_trips").doc(tripRef.id);
  let patientUid = "";

  await db.runTransaction(async (tx) => {
    const [emergencySnap, ambulanceSnap] = await Promise.all([
      tx.get(emergencyRef),
      tx.get(ambulanceRef),
    ]);

    if (!emergencySnap.exists) {
      throw new functionsV1.https.HttpsError("not-found", "Emergency request not found");
    }
    if (!ambulanceSnap.exists) {
      throw new functionsV1.https.HttpsError("not-found", "Ambulance not found");
    }
    const emergency = emergencySnap.data()!;
    const ambulance = ambulanceSnap.data()!;

    if (emergency.selectedHospitalId !== hospitalId || ambulance.hospitalId !== hospitalId) {
      throw new functionsV1.https.HttpsError(
        "permission-denied",
        "This emergency or ambulance does not belong to your hospital"
      );
    }
    if (!DISPATCHABLE_EMERGENCY_STATUSES.includes(emergency.status)) {
      throw new functionsV1.https.HttpsError(
        "failed-precondition",
        `Cannot dispatch an ambulance while status is "${emergency.status}"`
      );
    }
    if (ambulance.status !== "available") {
      throw new functionsV1.https.HttpsError(
        "failed-precondition",
        "This ambulance is not available"
      );
    }

    patientUid = emergency.patientUid as string;

    const tripData = {
      emergencyRequestId: requestId,
      hospitalId,
      ambulanceId,
      status: "dispatched",
      dispatchedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    tx.set(tripRef, tripData);
    tx.set(mirrorTripRef, tripData);

    tx.update(ambulanceRef, { status: "dispatched", activeTripId: tripRef.id });
    tx.update(emergencyRef, {
      assignedAmbulanceId: ambulanceId,
      status: "ambulanceDispatched",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(db.doc(`hospital_status/${hospitalId}`), {
      ambulancesAvailable: admin.firestore.FieldValue.increment(-1),
    });
  });

  await appendTimeline(requestId, "ambulanceDispatched", "Ambulance Dispatched", role, {
    ambulanceId,
    tripId: tripRef.id,
  });
  await notifyUser(patientUid, {
    type: "ambulance",
    title: "Ambulance Dispatched",
    body: "An ambulance is on its way to you.",
    data: { requestId },
  });

  return { tripId: tripRef.id };
});
