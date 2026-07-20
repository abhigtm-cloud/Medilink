import { admin, db } from "../admin";

/** Removes the hospital's queue pointer doc and decrements its active
 * count — shared by every function that takes an emergency out of the
 * hospital's active queue (cancel, reject, close). */
export async function releaseQueueSlot(hospitalId: string, requestId: string): Promise<void> {
  await db
    .doc(`hospital_status/${hospitalId}/queue/${requestId}`)
    .delete()
    .catch(() => undefined);
  await db
    .doc(`hospital_status/${hospitalId}`)
    .update({ activeEmergencyCount: admin.firestore.FieldValue.increment(-1) })
    .catch(() => undefined);
}
