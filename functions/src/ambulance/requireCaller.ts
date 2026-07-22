import * as functionsV1 from "firebase-functions/v1";
import { ALL_ROLES } from "../rbac/roles";

const HOSPITAL_STAFF_ROLES: string[] = ALL_ROLES.filter((r) => r !== "patient");

/** Shared auth guard: caller must be signed in and have a role+hospitalId
 * custom claim. Returns them for the caller to use in its own authorization
 * checks (e.g. "does this ambulance belong to my hospital"). */
export function requireStaffClaims(context: functionsV1.https.CallableContext) {
  if (!context.auth) {
    throw new functionsV1.https.HttpsError("unauthenticated", "Sign in required");
  }
  const role = context.auth.token.role as string | undefined;
  const hospitalId = context.auth.token.hospitalId as string | undefined;
  if (!role || !HOSPITAL_STAFF_ROLES.includes(role) || !hospitalId) {
    throw new functionsV1.https.HttpsError(
      "permission-denied",
      "Only hospital staff may perform this action"
    );
  }
  return { role, hospitalId, uid: context.auth.uid };
}
