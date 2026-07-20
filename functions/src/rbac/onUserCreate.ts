import * as functionsV1 from "firebase-functions/v1";
import { db, admin } from "../admin";

/**
 * Every new Firebase Auth user gets a default role written to
 * `user_roles/{uid}`: `hospital_admin` for the existing `@hospital.com`
 * convention (see `_getRoleFromEmail` in lib/features/auth/models/app_user.dart
 * — this bridges that pre-existing, client-trust-only convention onto the
 * new server-verified custom claim), `patient` otherwise. Other hospital
 * staff roles (doctor/ambulance_driver/pharmacy/emergency_staff) are always
 * assigned later by a hospital_admin — never inferred automatically.
 *
 * `hospitalId` starts null even for admins — at signup time they haven't
 * created their hospital yet. It gets filled in by
 * `linkHospitalAdminOnHospitalCreate` (mirrorHospitalToFirestore.ts) once
 * they do. See docs/EMERGENCY_PLATFORM_ARCHITECTURE.md §3.
 */
export const onUserCreate = functionsV1.auth.user().onCreate(async (user) => {
  const isHospitalDomain = (user.email ?? "").trim().toLowerCase().endsWith("@hospital.com");

  await db.doc(`user_roles/${user.uid}`).set({
    uid: user.uid,
    role: isHospitalDomain ? "hospital_admin" : "patient",
    hospitalId: null,
    isActive: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});
