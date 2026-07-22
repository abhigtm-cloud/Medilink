import * as functionsV1 from "firebase-functions/v1";
import { admin } from "../admin";
import { requireHospitalStaff } from "./requireHospitalStaff";
import { appendTimeline } from "./timeline";
import { notifyUser } from "../notifications/sendFcm";

export const acceptEmergency = functionsV1.https.onCall(async (data, context) => {
  const requestId = data.requestId as string;
  const { ref, emergency, role } = await requireHospitalStaff(context, requestId, [
    "hospitalAssigned",
  ]);

  await ref.update({
    status: "accepted",
    acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await appendTimeline(requestId, "accepted", "Hospital Accepted", role);
  await notifyUser(emergency.patientUid as string, {
    type: "emergency",
    title: "Hospital Accepted Your Emergency",
    body: "The hospital is preparing to receive you.",
    data: { requestId },
  });

  return { status: "accepted" };
});
