import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/pharmacy/data/pharmacy_repository.dart';
import 'package:medilink/features/pharmacy/domain/entities/pharmacy.dart';

final pharmacyRepositoryProvider = Provider<PharmacyRepository>((ref) => PharmacyRepository());

final hospitalInventoryProvider =
    StreamProvider.autoDispose.family<List<Medicine>, String>((ref, hospitalId) {
  return ref.watch(pharmacyRepositoryProvider).watchHospitalInventory(hospitalId);
});

final allActiveMedicinesProvider = StreamProvider.autoDispose<List<Medicine>>((ref) {
  return ref.watch(pharmacyRepositoryProvider).watchAllActiveMedicines();
});

final myPrescriptionsProvider =
    StreamProvider.autoDispose.family<List<Prescription>, String>((ref, patientUid) {
  return ref.watch(pharmacyRepositoryProvider).watchMyPrescriptions(patientUid);
});

final hospitalPrescriptionsProvider =
    StreamProvider.autoDispose.family<List<Prescription>, String>((ref, hospitalId) {
  return ref.watch(pharmacyRepositoryProvider).watchHospitalPrescriptions(hospitalId);
});

final myOrdersProvider =
    StreamProvider.autoDispose.family<List<PharmacyOrder>, String>((ref, patientUid) {
  return ref.watch(pharmacyRepositoryProvider).watchMyOrders(patientUid);
});

final hospitalOrdersProvider =
    StreamProvider.autoDispose.family<List<PharmacyOrder>, String>((ref, hospitalId) {
  return ref.watch(pharmacyRepositoryProvider).watchHospitalOrders(hospitalId);
});

final orderTrackingProvider =
    StreamProvider.autoDispose.family<List<OrderTrackingEvent>, String>((ref, orderId) {
  return ref.watch(pharmacyRepositoryProvider).watchOrderTracking(orderId);
});
