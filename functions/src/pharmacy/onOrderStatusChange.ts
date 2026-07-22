import * as functionsV1 from "firebase-functions/v1";
import { admin } from "../admin";
import { notifyUser } from "../notifications/sendFcm";

const STATUS_LABELS: Record<string, string> = {
  placed: "Order Placed",
  confirmed: "Order Confirmed",
  preparing: "Preparing Your Order",
  out_for_delivery: "Out for Delivery",
  delivered: "Delivered",
  cancelled: "Order Cancelled",
};

/** Same append-only-subcollection pattern as the emergency timeline —
 * `orders/{orderId}/tracking` is what OrderTrackingScreen listens to. See
 * architecture doc §4.10/§13. */
export const onOrderStatusChange = functionsV1.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status === after.status) return;

    const status = after.status as string;
    const label = STATUS_LABELS[status] ?? status;

    await change.after.ref.collection("tracking").add({
      status,
      note: label,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    await notifyUser(after.patientUid as string, {
      type: "pharmacy",
      title: label,
      body: `Your order is now: ${label}`,
      data: { orderId: context.params.orderId as string },
    });
  });
