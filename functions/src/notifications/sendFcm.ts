import { admin, db, rtdb } from "../admin";

export interface NotificationPayload {
  type: "emergency" | "ambulance" | "pharmacy" | "system";
  title: string;
  body: string;
  /** FCM data payloads must be string-only — keep this shape. */
  data?: Record<string, string>;
}

async function writeNotificationDoc(uid: string, payload: NotificationPayload): Promise<void> {
  await db.collection("notifications").doc(uid).collection("items").add({
    type: payload.type,
    title: payload.title,
    body: payload.body,
    data: payload.data ?? {},
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/** Push is best-effort (OS can throttle/kill it) — prune tokens FCM reports
 * as no-longer-registered so the token set doesn't grow stale forever. */
async function sendToTokens(uid: string, payload: NotificationPayload): Promise<void> {
  const snap = await rtdb.ref(`users/${uid}/fcmTokens`).get();
  if (!snap.exists()) return;
  const tokens = Object.keys(snap.val() as Record<string, boolean>);
  if (tokens.length === 0) return;

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title: payload.title, body: payload.body },
    data: payload.data ?? {},
  });

  const staleTokens = response.responses
    .map((r, i) => (!r.success && r.error?.code === "messaging/registration-token-not-registered" ? tokens[i] : null))
    .filter((t): t is string => t !== null);

  await Promise.all(
    staleTokens.map((t) => rtdb.ref(`users/${uid}/fcmTokens/${t}`).remove().catch(() => undefined))
  );
}

/** Every push always has a matching Firestore write — push delivery is
 * best-effort, the in-app notification center is the reliable fallback. See
 * architecture doc §16. */
export async function notifyUser(uid: string, payload: NotificationPayload): Promise<void> {
  await Promise.all([
    writeNotificationDoc(uid, payload),
    sendToTokens(uid, payload).catch((err) => {
      console.error(`notifyUser: push failed for ${uid}`, err);
    }),
  ]);
}

/** Notifies every active staff member of a hospital: one FCM topic push
 * (staff devices subscribe to `hospital_{hospitalId}_emergency` on login —
 * see fcm_service.dart) plus a per-staff Firestore notification doc, so the
 * in-app notification center stays reliable even when push delivery isn't.
 * Deliberately a single equality query (no composite index needed) — active
 * filtering happens in memory since hospital staff counts are small. */
export async function notifyHospitalStaff(
  hospitalId: string,
  payload: NotificationPayload,
  options?: { roles?: string[] }
): Promise<void> {
  const staffSnap = await db.collection("user_roles").where("hospitalId", "==", hospitalId).get();
  const activeStaffUids = staffSnap.docs
    .filter((doc) => doc.data().isActive !== false)
    .filter((doc) => !options?.roles || options.roles.includes(doc.data().role))
    .map((doc) => doc.id);

  await Promise.all([
    admin
      .messaging()
      .send({
        topic: `hospital_${hospitalId}_emergency`,
        notification: { title: payload.title, body: payload.body },
        data: payload.data ?? {},
      })
      .catch((err) => {
        console.error(`notifyHospitalStaff: topic push failed for ${hospitalId}`, err);
      }),
    ...activeStaffUids.map((uid) => writeNotificationDoc(uid, payload)),
  ]);
}
