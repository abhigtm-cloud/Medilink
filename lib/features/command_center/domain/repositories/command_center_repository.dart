import 'package:fpdart/fpdart.dart';
import 'package:medilink/core/error/failures.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';

abstract class CommandCenterRepository {
  /// Every emergency ever assigned to this hospital, newest first. The
  /// dashboard's Active/History tabs filter this client-side by status —
  /// deliberately not three separate queries (see architecture doc §4 "Notes
  /// on geoqueries" for the same per-hospital-scale reasoning).
  Stream<Either<Failure, List<EmergencyRequest>>> watchHospitalEmergencies(
    String hospitalId,
  );

  Future<Either<Failure, Unit>> acceptEmergency(String requestId);
  Future<Either<Failure, Unit>> rejectEmergency(String requestId, String reason);
  Future<Either<Failure, Unit>> assignDoctor(String requestId, String doctorId);
  Future<Either<Failure, Unit>> sendInstruction(String requestId, String text);
  Future<Either<Failure, Unit>> markArrived(String requestId);
  Future<Either<Failure, Unit>> closeEmergency(String requestId, String outcome);
}
