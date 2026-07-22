import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/ambulance/data/datasources/ambulance_remote_datasource.dart';
import 'package:medilink/features/ambulance/data/repositories/ambulance_repository_impl.dart';
import 'package:medilink/features/ambulance/domain/entities/ambulance.dart';
import 'package:medilink/features/ambulance/domain/repositories/ambulance_repository.dart';

final ambulanceRemoteDataSourceProvider = Provider<AmbulanceRemoteDataSource>(
  (ref) => AmbulanceRemoteDataSource(),
);

final ambulanceRepositoryProvider = Provider<AmbulanceRepository>((ref) {
  return AmbulanceRepositoryImpl(remote: ref.watch(ambulanceRemoteDataSourceProvider));
});

final hospitalFleetProvider =
    StreamProvider.autoDispose.family<List<Ambulance>, String>((ref, hospitalId) {
  return ref
      .watch(ambulanceRepositoryProvider)
      .watchHospitalFleet(hospitalId)
      .map((e) => e.match((f) => throw f, (r) => r));
});

final driverAmbulanceProvider =
    StreamProvider.autoDispose.family<Ambulance?, String>((ref, driverUid) {
  return ref
      .watch(ambulanceRepositoryProvider)
      .watchDriverAmbulance(driverUid)
      .map((e) => e.match((f) => throw f, (r) => r));
});

final ambulanceByIdProvider =
    StreamProvider.autoDispose.family<Ambulance?, String>((ref, ambulanceId) {
  return ref
      .watch(ambulanceRepositoryProvider)
      .watchAmbulanceById(ambulanceId)
      .map((e) => e.match((f) => throw f, (r) => r));
});

final tripForEmergencyProvider =
    StreamProvider.autoDispose.family<AmbulanceTrip?, String>((ref, requestId) {
  return ref
      .watch(ambulanceRepositoryProvider)
      .watchTripForEmergency(requestId)
      .map((e) => e.match((f) => throw f, (r) => r));
});
