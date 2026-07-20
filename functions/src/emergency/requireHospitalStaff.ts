import * as functionsV1 from "firebase-functions/v1";
import { db } from "../admin";

const HOSPITAL_STAFF_ROLES = [
  "hospital_admin",
  "doctor",
  "ambulance_driver",
  "pharmacy",
  "emergency_staff",
];

/**
 * Shared guard for every Command Center Callable Function: verifies the
 * caller is hospital staff for the request's `selectedHospitalId` (custom
 * claims, never a client-supplied hospitalId — see architecture doc §3),
 * loads the request, and checks it's in one of the caller's allowed
 * `fromStatuses`. Throws `HttpsError` otherwise so every action function
 * gets the same precondition enforcement in one place.
 */
export async function requireHospitalStaff(
  context: functionsV1.https.CallableContext,
  requestId: string,
  fromStatuses?: string[]
) {
  if (!context.auth) {
    throw new functionsV1.https.HttpsError("unauthenticated", "Sign in required");
  }
  const role = context.auth.token.role as string | undefined;
  const hospitalId = context.auth.token.hospitalId as string | undefined;
  if (!role || !HOSPITAL_STAFF_ROLES.includes(role) || !hospitalId) {
    throw new functionsV1.https.HttpsError(
      "permission-denied",
      "Only hospital staff may perform this action"
    );
  }

  const ref = db.collection("emergency_requests").doc(requestId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new functionsV1.https.HttpsError("not-found", "Emergency request not found");
  }
  const emergency = snap.data()!;

  if (emergency.selectedHospitalId !== hospitalId) {
    throw new functionsV1.https.HttpsError(
      "permission-denied",
      "This emergency was not assigned to your hospital"
    );
  }
  if (fromStatuses && !fromStatuses.includes(emergency.status)) {
    throw new functionsV1.https.HttpsError(
      "failed-precondition",
      `This action isn't valid from status "${emergency.status}"`
    );
  }

  return { ref, emergency, role, hospitalId };
}
