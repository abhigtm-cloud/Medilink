import 'package:fpdart/fpdart.dart';
import 'package:medilink/core/error/exceptions.dart';
import 'package:medilink/core/error/failures.dart';
import 'package:medilink/features/command_center/data/datasources/command_center_remote_datasource.dart';
import 'package:medilink/features/command_center/domain/repositories/command_center_repository.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';

class CommandCenterRepositoryImpl implements CommandCenterRepository {
  CommandCenterRepositoryImpl({required CommandCenterRemoteDataSource remote})
      : _remote = remote;

  final CommandCenterRemoteDataSource _remote;

  Failure _mapException(Object e) {
    if (e is PermissionException) return PermissionFailure(e.message);
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ServerException) return UnknownFailure(e.message);
    return const UnknownFailure();
  }

  @override
  Stream<Either<Failure, List<EmergencyRequest>>> watchHospitalEmergencies(
    String hospitalId,
  ) async* {
    try {
      await for (final list in _remote.watchHospitalEmergencies(hospitalId)) {
        yield Right(list);
      }
    } catch (e) {
      yield Left(_mapException(e));
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
  Future<Either<Failure, Unit>> acceptEmergency(String requestId) =>
      _guard(() => _remote.acceptEmergency(requestId));

  @override
  Future<Either<Failure, Unit>> rejectEmergency(String requestId, String reason) =>
      _guard(() => _remote.rejectEmergency(requestId, reason));

  @override
  Future<Either<Failure, Unit>> assignDoctor(String requestId, String doctorId) =>
      _guard(() => _remote.assignDoctor(requestId, doctorId));

  @override
  Future<Either<Failure, Unit>> sendInstruction(String requestId, String text) =>
      _guard(() => _remote.sendInstruction(requestId, text));

  @override
  Future<Either<Failure, Unit>> markArrived(String requestId) =>
      _guard(() => _remote.markArrived(requestId));

  @override
  Future<Either<Failure, Unit>> closeEmergency(String requestId, String outcome) =>
      _guard(() => _remote.closeEmergency(requestId, outcome));
}
