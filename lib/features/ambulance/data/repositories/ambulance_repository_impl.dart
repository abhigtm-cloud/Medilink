import 'package:fpdart/fpdart.dart';
import 'package:medilink/core/error/exceptions.dart';
import 'package:medilink/core/error/failures.dart';
import 'package:medilink/features/ambulance/data/datasources/ambulance_remote_datasource.dart';
import 'package:medilink/features/ambulance/domain/entities/ambulance.dart';
import 'package:medilink/features/ambulance/domain/repositories/ambulance_repository.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';

class AmbulanceRepositoryImpl implements AmbulanceRepository {
  AmbulanceRepositoryImpl({required AmbulanceRemoteDataSource remote}) : _remote = remote;

  final AmbulanceRemoteDataSource _remote;

  Failure _mapException(Object e) {
    if (e is PermissionException) return PermissionFailure(e.message);
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ServerException) return UnknownFailure(e.message);
    return const UnknownFailure();
  }

  @override
  Stream<Either<Failure, List<Ambulance>>> watchHospitalFleet(String hospitalId) async* {
    try {
      await for (final list in _remote.watchHospitalFleet(hospitalId)) {
        yield Right(list);
      }
    } catch (e) {
      yield Left(_mapException(e));
    }
  }

  @override
  Stream<Either<Failure, Ambulance?>> watchDriverAmbulance(String driverUid) async* {
    try {
      await for (final ambulance in _remote.watchDriverAmbulance(driverUid)) {
        yield Right(ambulance);
      }
    } catch (e) {
      yield Left(_mapException(e));
    }
  }

  @override
  Stream<Either<Failure, Ambulance?>> watchAmbulanceById(String ambulanceId) async* {
    try {
      await for (final ambulance in _remote.watchAmbulanceById(ambulanceId)) {
        yield Right(ambulance);
      }
    } catch (e) {
      yield Left(_mapException(e));
    }
  }

  @override
  Stream<Either<Failure, AmbulanceTrip?>> watchTripForEmergency(
    String emergencyRequestId,
  ) async* {
    try {
      await for (final trip in _remote.watchTripForEmergency(emergencyRequestId)) {
        yield Right(trip);
      }
    } catch (e) {
      yield Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, String>> registerAmbulance({
    required String vehicleNumber,
    required String driverName,
    required String driverPhone,
    String? driverEmail,
  }) async {
    try {
      final id = await _remote.registerAmbulance(
        vehicleNumber: vehicleNumber,
        driverName: driverName,
        driverPhone: driverPhone,
        driverEmail: driverEmail,
      );
      return Right(id);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  Future<Either<Failure, Unit>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return const Right(unit);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> setAvailability(String ambulanceId, AmbulanceStatus status) =>
      _guard(() => _remote.setAvailability(ambulanceId, status.name));

  @override
  Future<Either<Failure, Unit>> dispatchAmbulance(String requestId, String ambulanceId) =>
      _guard(() => _remote.dispatchAmbulance(requestId, ambulanceId));

  @override
  Future<Either<Failure, Unit>> completeTrip(String tripId) =>
      _guard(() => _remote.completeTrip(tripId));

  @override
  Future<Either<Failure, Unit>> updateAmbulanceLocation(
    String ambulanceId,
    GeoPointValue location,
  ) =>
      _guard(() => _remote.updateAmbulanceLocation(ambulanceId, location));
}
