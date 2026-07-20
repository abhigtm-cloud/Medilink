import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/command_center/data/datasources/command_center_remote_datasource.dart';
import 'package:medilink/features/command_center/data/repositories/command_center_repository_impl.dart';
import 'package:medilink/features/command_center/domain/repositories/command_center_repository.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';

final commandCenterRemoteDataSourceProvider = Provider<CommandCenterRemoteDataSource>(
  (ref) => CommandCenterRemoteDataSource(),
);

final commandCenterRepositoryProvider = Provider<CommandCenterRepository>((ref) {
  return CommandCenterRepositoryImpl(
    remote: ref.watch(commandCenterRemoteDataSourceProvider),
  );
});

/// Every emergency ever assigned to this hospital, newest first — the
/// dashboard tabs filter this client-side by status.
final hospitalEmergenciesProvider =
    StreamProvider.autoDispose.family<List<EmergencyRequest>, String>((ref, hospitalId) {
  return ref
      .watch(commandCenterRepositoryProvider)
      .watchHospitalEmergencies(hospitalId)
      .map((e) => e.match((f) => throw f, (r) => r));
});

const incomingStatuses = {'hospitalAssigned'};

const activeStatuses = {
  'accepted',
  'preparing',
  'doctorAssigned',
  'icuReserved',
  'ambulanceDispatched',
  'hospitalReady',
  'patientEnRoute',
  'reachedHospital',
  'treatmentStarted',
};

const historyStatuses = {'completed', 'cancelled', 'rejected', 'noHospitalFound'};
