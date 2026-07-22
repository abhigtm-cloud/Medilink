import * as functionsV1 from "firebase-functions/v1";
import { admin } from "../admin";
import { requireHospitalStaff } from "./requireHospitalStaff";
import { appendTimeline } from "./timeline";
import { releaseQueueSlot } from "./queue";
import { notifyUser } from "../notifications/sendFcm";

const CLOSABLE_STATUSES = [
  "accepted",
  "doctorAssigned",
  "reachedHospital",
  "treatmentStarted",
];

/** `outcome` is a free-text audit note (e.g. "Treated and discharged",
 * "Transferred to City Hospital", "Deceased") — kept separate from the
 * `EmergencyStatus` enum, which only needs to know it's now terminal. */
export const closeEmergency = functionsV1.https.onCall(async (data, context) => {
  const requestId = data.requestId as string;
  const outcome = (data.outcome as string)?.trim();
  if (!outcome) {
    throw new functionsV1.https.HttpsError("invalid-argument", "outcome is required");
  }

  const { ref, emergency, hospitalId, role } = await requireHospitalStaff(
    context,
    requestId,
    CLOSABLE_STATUSES
  );

  await ref.update({
    status: "completed",
    outcome,
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await releaseQueueSlot(hospitalId, requestId);
  await appendTimeline(requestId, "completed", `Closed: ${outcome}`, role);
  await notifyUser(emergency.patientUid as string, {
    type: "emergency",
    title: "Emergency Closed",
    body: outcome,
    data: { requestId },
  });

  return { status: "completed" };
});
