import * as functionsV1 from "firebase-functions/v1";
import { admin, rtdb } from "../admin";
import { requireHospitalStaff } from "./requireHospitalStaff";
import { appendTimeline } from "./timeline";

/**
 * Doctors already live in RTDB (`doctors/{hospitalId}/{doctorId}`, owned by
 * the existing appointments feature — untouched per the hybrid decision).
 * No new picker data source needed; this just looks up the name for the
 * timeline/patient-facing label.
 */
export const assignDoctor = functionsV1.https.onCall(async (data, context) => {
  const requestId = data.requestId as string;
  const doctorId = data.doctorId as string;
  if (!doctorId) {
    throw new functionsV1.https.HttpsError("invalid-argument", "doctorId is required");
  }

  const { ref, hospitalId, role } = await requireHospitalStaff(context, requestId, [
    "accepted",
    "doctorAssigned",
  ]);

  const doctorSnap = await rtdb.ref(`doctors/${hospitalId}/${doctorId}`).get();
  const doctorName = (doctorSnap.val()?.name as string) ?? "Assigned Doctor";

  await ref.update({
    assignedDoctorId: doctorId,
    status: "doctorAssigned",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await appendTimeline(requestId, "doctorAssigned", `Doctor Assigned: ${doctorName}`, role, {
    doctorId,
    doctorName,
  });

  return { status: "doctorAssigned", doctorName };
});
