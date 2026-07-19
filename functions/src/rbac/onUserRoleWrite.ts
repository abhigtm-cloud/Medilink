import * as functionsV1 from "firebase-functions/v1";
import { admin } from "../admin";
import { UserRoleDoc } from "./roles";

/**
 * Mirrors `user_roles/{uid}` into Firebase Auth custom claims (`role`,
 * `hospitalId`) so Firestore security rules — which can only trust
 * `request.auth.token.*`, never client-supplied fields — can rely on them.
 * Deleting the doc, or setting `isActive: false`, clears claims entirely
 * (used for staff off-boarding). See docs/EMERGENCY_PLATFORM_ARCHITECTURE.md §3.
 *
 * Clients must force an ID token refresh (`getIdTokenResult(true)`, wrapped
 * by `RbacService.refreshClaims()`) after their own role changes — claims
 * only take effect on the next token mint.
 */
export const onUserRoleWrite = functionsV1.firestore
  .document("user_roles/{uid}")
  .onWrite(async (change, context) => {
    const uid = context.params.uid as string;
    const after = change.after.exists
      ? (change.after.data() as UserRoleDoc)
      : undefined;

    if (!after || after.isActive === false) {
      await admin.auth().setCustomUserClaims(uid, null);
      return;
    }

    await admin.auth().setCustomUserClaims(uid, {
      role: after.role,
      hospitalId: after.hospitalId ?? null,
    });
  });
