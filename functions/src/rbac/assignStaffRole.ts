import * as functionsV1 from "firebase-functions/v1";
import { admin, db } from "../admin";
import { STAFF_ROLES } from "./roles";

/**
 * The only client-reachable path to grant a staff role. Firestore rules
 * deliberately don't let a client write `user_roles` for a role picked out
 * of thin air (see firestore.rules) — this Callable Function is the
 * server-validated front door: caller must already be a hospital_admin
 * (custom claim), and the new role always inherits the caller's own
 * hospitalId, never a client-supplied one.
 *
 * Looks the target user up by email via the Admin SDK (not exposed to
 * clients directly) rather than requiring a UID, since a hospital_admin
 * won't know a new hire's Firebase uid.
 */
export const assignStaffRole = functionsV1.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functionsV1.https.HttpsError("unauthenticated", "Sign in required");
  }
  if (context.auth.token.role !== "hospital_admin") {
    throw new functionsV1.https.HttpsError(
      "permission-denied",
      "Only a hospital_admin may assign staff roles"
    );
  }
  const hospitalId = context.auth.token.hospitalId as string | undefined;
  if (!hospitalId) {
    throw new functionsV1.https.HttpsError(
      "failed-precondition",
      "Create your hospital before assigning staff"
    );
  }

  const email = (data.email as string)?.trim().toLowerCase();
  const role = data.role as string;
  if (!email || !STAFF_ROLES.includes(role as (typeof STAFF_ROLES)[number])) {
    throw new functionsV1.https.HttpsError(
      "invalid-argument",
      `email and a role in [${STAFF_ROLES.join(", ")}] are required`
    );
  }

  let targetUser;
  try {
    targetUser = await admin.auth().getUserByEmail(email);
  } catch {
    throw new functionsV1.https.HttpsError(
      "not-found",
      "No MediLink account exists for that email yet — ask them to sign up first"
    );
  }

  await db.doc(`user_roles/${targetUser.uid}`).set(
    {
      uid: targetUser.uid,
      role,
      hospitalId,
      isActive: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { mergeFields: ["role", "hospitalId", "isActive", "updatedAt"] }
  );

  return { uid: targetUser.uid, role, hospitalId };
});
