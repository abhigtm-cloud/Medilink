import * as functionsV1 from "firebase-functions/v1";
import { admin } from "../admin";
import { requireHospitalStaff } from "./requireHospitalStaff";
import { appendTimeline } from "./timeline";
import { releaseQueueSlot } from "./queue";
import { notifyUser } from "../notifications/sendFcm";

export const rejectEmergency = functionsV1.https.onCall(async (data, context) => {
  const requestId = data.requestId as string;
  const reason = (data.reason as string) ?? "Unable to accommodate";
  const { ref, emergency, hospitalId, role } = await requireHospitalStaff(context, requestId, [
    "hospitalAssigned",
  ]);

  await ref.update({
    status: "rejected",
    rejectReason: reason,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await releaseQueueSlot(hospitalId, requestId);
  await appendTimeline(requestId, "rejected", "Hospital Unable to Accept", role, { reason });
  await notifyUser(emergency.patientUid as string, {
    type: "emergency",
    title: "Hospital Unable to Accept",
    body: reason,
    data: { requestId },
  });

  return { status: "rejected" };
});
