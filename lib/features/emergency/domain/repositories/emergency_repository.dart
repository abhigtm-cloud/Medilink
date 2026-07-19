import 'package:fpdart/fpdart.dart';
import 'package:medilink/core/error/failures.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_timeline_event.dart';

abstract class EmergencyRepository {
  /// Triggers the server-authoritative SOS pipeline. Returns the new
  /// request's id. The client never picks the hospital itself — see
  /// architecture doc §8.
  Future<Either<Failure, String>> triggerSos({
    required EmergencyType type,
    required GeoPointValue location,
  });

  Stream<Either<Failure, EmergencyRequest>> watchEmergency(String requestId);

  Stream<Either<Failure, List<EmergencyTimelineEvent>>> watchTimeline(
    String requestId,
  );

  Future<Either<Failure, Unit>> updateLiveLocation(
    String requestId,
    GeoPointValue location,
  );

  Future<Either<Failure, Unit>> cancelEmergency(
    String requestId,
    String reason,
  );

  /// The last known active request id, cached locally so a killed/reopened
  /// app can resume straight into tracking before the network responds.
  Future<String?> getCachedActiveRequestId();

  Future<void> cacheActiveRequestId(String? requestId);
}
