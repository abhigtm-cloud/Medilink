import * as functionsV1 from "firebase-functions/v1";
import { admin } from "../admin";
import { requireHospitalStaff } from "./requireHospitalStaff";
import { appendTimeline } from "./timeline";

/**
 * Ambulance-dispatch/hospital-prep states (preparing, icuReserved,
 * ambulanceDispatched, hospitalReady, patientEnRoute) aren't reachable yet —
 * ICU/ambulance management ships in a later roadmap step (architecture doc
 * §23 steps 3-4). Until then, "arrived" is reachable directly from
 * accepted/doctorAssigned (e.g. a self-arriving or ambulance-outside-the-app
 * patient).
 */
export const markArrived = functionsV1.https.onCall(async (data, context) => {
  const requestId = data.requestId as string;
  const { ref, role } = await requireHospitalStaff(context, requestId, [
    "accepted",
    "doctorAssigned",
  ]);

  await ref.update({
    status: "reachedHospital",
    arrivedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await appendTimeline(requestId, "reachedHospital", "Patient Reached Hospital", role);

  return { status: "reachedHospital" };
});
