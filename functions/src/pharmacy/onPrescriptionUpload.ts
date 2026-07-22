import * as functionsV1 from "firebase-functions/v1";
import { notifyHospitalStaff } from "../notifications/sendFcm";

/** Notifies the target pharmacy's staff (pharmacy + hospital_admin roles
 * only — not every doctor/emergency_staff at that hospital) that a new
 * prescription needs review. See architecture doc §13. */
export const onPrescriptionUpload = functionsV1.firestore
  .document("prescriptions/{prescriptionId}")
  .onCreate(async (snap, context) => {
    const prescription = snap.data();
    const hospitalId = prescription.hospitalId as string | undefined;
    if (!hospitalId) return;

    await notifyHospitalStaff(
      hospitalId,
      {
        type: "pharmacy",
        title: "New Prescription Uploaded",
        body: "A patient uploaded a prescription for review.",
        data: { prescriptionId: context.params.prescriptionId as string },
      },
      { roles: ["pharmacy", "hospital_admin"] }
    );
  });
