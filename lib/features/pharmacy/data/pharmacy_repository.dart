import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medilink/core/services/storage_service.dart';
import 'package:medilink/features/pharmacy/domain/entities/pharmacy.dart';

/// Plain Firestore-backed repository — Pharmacy's writes are direct client
/// writes guarded by firestore.rules (no state-machine Callable Functions
/// needed, unlike Emergency/Command Center), so the extra Clean
/// Architecture layers wouldn't pay for themselves here. See architecture
/// doc §13: "PharmacyInventoryScreen ... is straightforward CRUD ... guarded
/// by rules."
class PharmacyRepository {
  PharmacyRepository({FirebaseFirestore? firestore, StorageService? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? StorageService();

  final FirebaseFirestore _firestore;
  final StorageService _storage;

  // ---------- medicine inventory ----------

  Stream<List<Medicine>> watchHospitalInventory(String hospitalId) {
    return _firestore
        .collection('medicine_inventory')
        .doc(hospitalId)
        .collection('items')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Medicine.fromFirestore(d, hospitalId)).toList());
  }

  /// Patients browse across every hospital's inventory — `medicine_inventory`
  /// is a subcollection per hospital, so this uses a collection-group query
  /// (unique subcollection name, no risk of colliding with e.g.
  /// `beds/{hospitalId}/records`). Name filtering happens client-side, same
  /// pattern as the existing SearchScreen.
  Stream<List<Medicine>> watchAllActiveMedicines() {
    return _firestore
        .collectionGroup('items')
        .where('isActive', isEqualTo: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs
            .where((d) => d.reference.parent.parent != null)
            .map((d) => Medicine.fromFirestore(d, d.reference.parent.parent!.id))
            .toList());
  }

  Future<void> upsertMedicine(String hospitalId, String? medicineId, Medicine medicine) async {
    final collection = _firestore.collection('medicine_inventory').doc(hospitalId).collection('items');
    if (medicineId == null) {
      await collection.add(medicine.toFirestore());
    } else {
      await collection.doc(medicineId).set(medicine.toFirestore(), SetOptions(merge: true));
    }
  }

  Future<void> setMedicineActive(String hospitalId, String medicineId, bool isActive) {
    return _firestore
        .collection('medicine_inventory')
        .doc(hospitalId)
        .collection('items')
        .doc(medicineId)
        .update({'isActive': isActive, 'updatedAt': FieldValue.serverTimestamp()});
  }

  // ---------- prescriptions ----------

  Future<String> uploadPrescription({
    required String patientUid,
    required String hospitalId,
    required File imageFile,
  }) async {
    final imageUrl = await _storage.uploadPrescription(patientUid, imageFile);
    final ref = await _firestore.collection('prescriptions').add({
      'patientUid': patientUid,
      'hospitalId': hospitalId,
      'imageUrl': imageUrl,
      'status': 'pending_review',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<Prescription>> watchMyPrescriptions(String patientUid) {
    return _firestore
        .collection('prescriptions')
        .where('patientUid', isEqualTo: patientUid)
        .snapshots()
        .map((snap) => snap.docs.map(Prescription.fromFirestore).toList());
  }

  Stream<List<Prescription>> watchHospitalPrescriptions(String hospitalId) {
    return _firestore
        .collection('prescriptions')
        .where('hospitalId', isEqualTo: hospitalId)
        .snapshots()
        .map((snap) => snap.docs.map(Prescription.fromFirestore).toList());
  }

  Future<void> reviewPrescription(String prescriptionId, {required bool approve, String? note}) {
    return _firestore.collection('prescriptions').doc(prescriptionId).update({
      'status': approve ? 'approved' : 'rejected',
      'reviewNote': note,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------- orders ----------

  Future<String> placeOrder({
    required String patientUid,
    required String hospitalId,
    required List<PharmacyOrderItem> items,
    required String deliveryAddress,
    String? prescriptionId,
  }) async {
    final totalAmount = items.fold<double>(0, (total, item) => total + item.unitPrice * item.quantity);
    final ref = await _firestore.collection('orders').add({
      'patientUid': patientUid,
      'hospitalId': hospitalId,
      'prescriptionId': prescriptionId,
      'items': items.map((i) => i.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': 'placed',
      'deliveryAddress': deliveryAddress,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<PharmacyOrder>> watchMyOrders(String patientUid) {
    return _firestore
        .collection('orders')
        .where('patientUid', isEqualTo: patientUid)
        .snapshots()
        .map((snap) => snap.docs.map(PharmacyOrder.fromFirestore).toList());
  }

  Stream<List<PharmacyOrder>> watchHospitalOrders(String hospitalId) {
    return _firestore
        .collection('orders')
        .where('hospitalId', isEqualTo: hospitalId)
        .snapshots()
        .map((snap) => snap.docs.map(PharmacyOrder.fromFirestore).toList());
  }

  Stream<List<OrderTrackingEvent>> watchOrderTracking(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .collection('tracking')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs.map(OrderTrackingEvent.fromFirestore).toList());
  }

  /// Direct client write — allowed by rules for pharmacy/hospital_admin at
  /// the order's own hospital. `onOrderStatusChange` appends the matching
  /// tracking event and notifies the patient.
  Future<void> updateOrderStatus(String orderId, PharmacyOrderStatus status) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .update({'status': status.value, 'updatedAt': FieldValue.serverTimestamp()});
  }
}
