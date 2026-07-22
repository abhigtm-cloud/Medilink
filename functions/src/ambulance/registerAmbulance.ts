import * as functionsV1 from "firebase-functions/v1";
import { admin, db } from "../admin";
import { requireStaffClaims } from "./requireCaller";

/**
 * Driver assignment is folded into registration rather than a separate
 * `assignDriver` action — an ambulance with no driver isn't dispatchable
 * anyway, so splitting it into two calls would just be two round-trips for
 * no behavioral difference at this feature's current scope.
 */
export const registerAmbulance = functionsV1.https.onCall(async (data, context) => {
  const { hospitalId } = requireStaffClaims(context);
  const vehicleNumber = (data.vehicleNumber as string)?.trim();
  const driverName = (data.driverName as string)?.trim();
  const driverPhone = (data.driverPhone as string)?.trim();
  const driverEmail = (data.driverEmail as string)?.trim().toLowerCase();

  if (!vehicleNumber || !driverName || !driverPhone) {
    throw new functionsV1.https.HttpsError(
      "invalid-argument",
      "vehicleNumber, driverName, and driverPhone are required"
    );
  }

  let driverUid: string | null = null;
  if (driverEmail) {
    try {
      driverUid = (await admin.auth().getUserByEmail(driverEmail)).uid;
    } catch {
      // Driver hasn't signed up yet, or wasn't assigned the ambulance_driver
      // role — location-sharing rules require driverUid to match, so this
      // ambulance just won't self-report location until that's sorted out.
      driverUid = null;
    }
  }

  const ref = db.collection("ambulances").doc();
  await db.runTransaction(async (tx) => {
    tx.set(ref, {
      hospitalId,
      vehicleNumber,
      driverUid,
      driverName,
      driverPhone,
      status: "available",
      currentLocation: null,
      activeTripId: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(db.doc(`hospital_status/${hospitalId}`), {
      ambulancesTotal: admin.firestore.FieldValue.increment(1),
      ambulancesAvailable: admin.firestore.FieldValue.increment(1),
    });
  });

  return { ambulanceId: ref.id };
});
