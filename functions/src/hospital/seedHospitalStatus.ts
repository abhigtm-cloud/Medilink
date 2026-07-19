import * as functionsV1 from "firebase-functions/v1";
import { admin, db } from "../admin";

/**
 * Seeds `hospital_status/{hospitalId}` with safe defaults the first time a
 * hospital shows up in `hospital_directory` (i.e. the first time it's
 * mirrored from RTDB — see mirrorHospitalToFirestore.ts). Guarded with a
 * transaction so it never clobbers staff-entered bed/ICU/ambulance counts if
 * a hospital is ever deleted and recreated. `isOpen`/`emergencyDeptOpen`
 * default to false — a hospital only becomes SOS-eligible once staff
 * explicitly opens it from the Command Center (built in a later step).
 */
export const seedHospitalStatus = functionsV1.firestore
  .document("hospital_directory/{hospitalId}")
  .onCreate(async (_snap, context) => {
    const hospitalId = context.params.hospitalId as string;
    const statusRef = db.doc(`hospital_status/${hospitalId}`);

    await db.runTransaction(async (tx) => {
      const existing = await tx.get(statusRef);
      if (existing.exists) return;

      tx.set(statusRef, {
        hospitalId,
        isOpen: false,
        emergencyDeptOpen: false,
        icuBedsTotal: 0,
        icuBedsAvailable: 0,
        generalBedsTotal: 0,
        generalBedsAvailable: 0,
        otRoomsTotal: 0,
        otRoomsAvailable: 0,
        emergencyDoctorsOnDuty: 0,
        emergencyDoctorsAvailable: 0,
        ambulancesTotal: 0,
        ambulancesAvailable: 0,
        activeEmergencyCount: 0,
        avgTreatmentMinutes: 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedBy: null,
      });
    });
  });
