import * as functionsV1 from "firebase-functions/v1";
import { admin, db, rtdb } from "../admin";

function todayDateString(): string {
  return new Date().toISOString().slice(0, 10); // yyyy-MM-dd, UTC
}

function isWithinDay(timestamp: admin.firestore.Timestamp | undefined, dateString: string): boolean {
  if (!timestamp) return false;
  return timestamp.toDate().toISOString().slice(0, 10) === dateString;
}

/**
 * Deliberately single-equality-filter Firestore queries (hospitalId only),
 * filtering the date range in memory — avoids requiring a composite index
 * deploy, and at this request-volume scale (one hospital, one day) the
 * extra reads are cheap. Same pragmatic tradeoff as
 * functions/src/notifications/sendFcm.ts's notifyHospitalStaff. Several
 * fields (doctorUtilizationPct, revenueTotal beyond pharmacy sales,
 * patientSatisfactionAvg) have no data source anywhere in the app yet — no
 * doctor-schedule-utilization or ratings feature exists — so they're left
 * at 0/null rather than fabricated.
 */
async function aggregateForHospital(hospitalId: string, dateString: string): Promise<void> {
  const [emergencySnap, tripsSnap, statusSnap, bookingsSnap, ordersSnap] = await Promise.all([
    db.collection("emergency_requests").where("selectedHospitalId", "==", hospitalId).get(),
    db.collection("ambulance_trips").where("hospitalId", "==", hospitalId).get(),
    db.doc(`hospital_status/${hospitalId}`).get(),
    rtdb.ref("bookings").get(),
    db.collection("orders").where("hospitalId", "==", hospitalId).get(),
  ]);

  const todaysEmergencies = emergencySnap.docs
    .map((d) => d.data())
    .filter((e) => isWithinDay(e.createdAt, dateString));
  const emergencyCasesCount = todaysEmergencies.length;

  const waitMinutes = todaysEmergencies
    .filter((e) => e.acceptedAt && e.createdAt)
    .map(
      (e) =>
        ((e.acceptedAt as admin.firestore.Timestamp).toMillis() -
          (e.createdAt as admin.firestore.Timestamp).toMillis()) /
        60000
    );
  const avgWaitingMinutes = waitMinutes.length
    ? waitMinutes.reduce((a, b) => a + b, 0) / waitMinutes.length
    : 0;

  const ambulanceTripsCount = tripsSnap.docs.filter((d) =>
    isWithinDay(d.data().dispatchedAt, dateString)
  ).length;

  const status = statusSnap.data() ?? {};
  const bedOccupancyPct = status.generalBedsTotal
    ? ((status.generalBedsTotal - (status.generalBedsAvailable ?? 0)) / status.generalBedsTotal) * 100
    : 0;
  const icuOccupancyPct = status.icuBedsTotal
    ? ((status.icuBedsTotal - (status.icuBedsAvailable ?? 0)) / status.icuBedsTotal) * 100
    : 0;

  // Bookings live in RTDB (existing appointments feature, untouched — see
  // architecture doc §0 hybrid decision).
  const allBookings = (bookingsSnap.val() as Record<string, Record<string, unknown>>) ?? {};
  const appointmentsCount = Object.values(allBookings).filter(
    (b) => b.hospitalId === hospitalId && b.date === dateString
  ).length;

  const medicineSalesTotal = ordersSnap.docs
    .filter((d) => isWithinDay(d.data().createdAt, dateString) && d.data().status === "delivered")
    .reduce((sum, d) => sum + ((d.data().totalAmount as number) ?? 0), 0);

  await db.doc(`analytics_daily/${hospitalId}_${dateString}`).set(
    {
      hospitalId,
      date: dateString,
      patientsCount: emergencyCasesCount + appointmentsCount,
      emergencyCasesCount,
      appointmentsCount,
      doctorUtilizationPct: 0,
      bedOccupancyPct,
      icuOccupancyPct,
      revenueTotal: medicineSalesTotal,
      medicineSalesTotal,
      ambulanceTripsCount,
      avgWaitingMinutes,
      patientSatisfactionAvg: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

/** Runs hourly so "today" stays fresh throughout the day (see architecture
 * doc §14) — the Analytics dashboard's live counters read straight from
 * `hospital_status` instead of waiting on this rollup. */
export const aggregateDailyAnalytics = functionsV1.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    const dateString = todayDateString();
    const hospitalsSnap = await db.collection("hospital_directory").get();
    await Promise.all(hospitalsSnap.docs.map((doc) => aggregateForHospital(doc.id, dateString)));
    return null;
  });
