import * as functionsV1 from "firebase-functions/v1";
import { admin } from "../admin";
import { requireHospitalStaff } from "./requireHospitalStaff";
import { appendTimeline } from "./timeline";

const ACTIVE_STATUSES = [
  "accepted",
  "preparing",
  "doctorAssigned",
  "icuReserved",
  "ambulanceDispatched",
  "hospitalReady",
  "patientEnRoute",
  "reachedHospital",
  "treatmentStarted",
];

export const sendInstruction = functionsV1.https.onCall(async (data, context) => {
  const requestId = data.requestId as string;
  const text = (data.text as string)?.trim();
  if (!text) {
    throw new functionsV1.https.HttpsError("invalid-argument", "text is required");
  }

  const { ref, emergency, role } = await requireHospitalStaff(context, requestId, ACTIVE_STATUSES);

  await ref.update({
    staffInstructions: admin.firestore.FieldValue.arrayUnion({
      text,
      sentBy: role,
      sentAt: admin.firestore.Timestamp.now(),
    }),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  // Timeline `status` stays a valid EmergencyStatus (the status this
  // instruction was sent under) — `label` carries the actual message. See
  // lib/features/emergency/domain/entities/emergency_timeline_event.dart,
  // which only ever renders `label`, never re-derives text from `status`.
  await appendTimeline(requestId, emergency.status as string, `Hospital: "${text}"`, role);

  return { status: "sent" };
});
