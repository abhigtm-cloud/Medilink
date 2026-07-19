import * as functionsV1 from "firebase-functions/v1";
import { db, admin } from "../admin";

/**
 * Every new Firebase Auth user gets a default `patient` role written to
 * `user_roles/{uid}`. Patients never need manual role assignment — only
 * hospital staff roles are assigned later by a hospital_admin.
 * See docs/EMERGENCY_PLATFORM_ARCHITECTURE.md §3.
 */
export const onUserCreate = functionsV1.auth.user().onCreate(async (user) => {
  await db.doc(`user_roles/${user.uid}`).set({
    uid: user.uid,
    role: "patient",
    hospitalId: null,
    isActive: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});
