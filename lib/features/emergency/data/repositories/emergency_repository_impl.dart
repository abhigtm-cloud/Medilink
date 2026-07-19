import 'package:fpdart/fpdart.dart';
import 'package:medilink/core/error/exceptions.dart';
import 'package:medilink/core/error/failures.dart';
import 'package:medilink/features/emergency/data/datasources/emergency_local_datasource.dart';
import 'package:medilink/features/emergency/data/datasources/emergency_remote_datasource.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_timeline_event.dart';
import 'package:medilink/features/emergency/domain/repositories/emergency_repository.dart';

class EmergencyRepositoryImpl implements EmergencyRepository {
  EmergencyRepositoryImpl({
    required EmergencyRemoteDataSource remote,
    required EmergencyLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final EmergencyRemoteDataSource _remote;
  final EmergencyLocalDataSource _local;

  Failure _mapException(Object e) {
    if (e is NoHospitalFoundException) return NoHospitalFoundFailure(e.message);
    if (e is PermissionException) return PermissionFailure(e.message);
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ServerException) return UnknownFailure(e.message);
    return const UnknownFailure();
  }

  @override
  Future<Either<Failure, String>> triggerSos({
    required EmergencyType type,
    required GeoPointValue location,
  }) async {
    try {
      final requestId = await _remote.triggerSos(type: type, location: location);
      await _local.setActiveRequestId(requestId);
      return Right(requestId);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Stream<Either<Failure, EmergencyRequest>> watchEmergency(String requestId) async* {
    try {
      await for (final model in _remote.watchEmergency(requestId)) {
        await _local.cacheLastKnownRequest(model);
        if (model.status.isTerminal) {
          await _local.setActiveRequestId(null);
        }
        yield Right(model);
      }
    } catch (e) {
      yield Left(_mapException(e));
    }
  }

  @override
  Stream<Either<Failure, List<EmergencyTimelineEvent>>> watchTimeline(
    String requestId,
  ) async* {
    try {
      await for (final events in _remote.watchTimeline(requestId)) {
        yield Right(events);
      }
    } catch (e) {
      yield Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateLiveLocation(
    String requestId,
    GeoPointValue location,
  ) async {
    try {
      await _remote.updateLiveLocation(requestId, location);
      return const Right(unit);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelEmergency(String requestId, String reason) async {
    try {
      await _remote.cancelEmergency(requestId, reason);
      await _local.setActiveRequestId(null);
      return const Right(unit);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<String?> getCachedActiveRequestId() => _local.getActiveRequestId();

  @override
  Future<void> cacheActiveRequestId(String? requestId) =>
      _local.setActiveRequestId(requestId);
}
