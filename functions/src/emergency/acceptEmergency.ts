import * as functionsV1 from "firebase-functions/v1";
import { admin } from "../admin";
import { requireHospitalStaff } from "./requireHospitalStaff";
import { appendTimeline } from "./timeline";

export const acceptEmergency = functionsV1.https.onCall(async (data, context) => {
  const requestId = data.requestId as string;
  const { ref, role } = await requireHospitalStaff(context, requestId, ["hospitalAssigned"]);

  await ref.update({
    status: "accepted",
    acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await appendTimeline(requestId, "accepted", "Hospital Accepted", role);

  return { status: "accepted" };
});
