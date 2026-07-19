/** Keep in sync with firestore.rules and lib/core/services/rbac_service.dart. */
export const STAFF_ROLES = [
  "doctor",
  "ambulance_driver",
  "pharmacy",
  "emergency_staff",
] as const;

export const ALL_ROLES = ["patient", "hospital_admin", ...STAFF_ROLES] as const;

export type AppRole = (typeof ALL_ROLES)[number];

export interface UserRoleDoc {
  uid: string;
  role: AppRole;
  hospitalId?: string | null;
  employeeId?: string | null;
  permissions?: string[];
  isActive?: boolean;
}
