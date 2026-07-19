import { admin, db } from "../admin";

/** Appends one entry to `emergency_requests/{requestId}/timeline` — the
 * append-only audit trail the patient's tracking screen listens to. Always
 * Cloud-Function-only (see firestore.rules). */
export async function appendTimeline(
  requestId: string,
  status: string,
  label: string,
  actorRole: string | null,
  metadata?: Record<string, unknown>
): Promise<void> {
  await db.collection("emergency_requests").doc(requestId).collection("timeline").add({
    status,
    label,
    actorRole,
    metadata: metadata ?? null,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}
