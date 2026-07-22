import 'package:fpdart/fpdart.dart';
import 'package:medilink/core/error/failures.dart';
import 'package:medilink/features/ambulance/domain/entities/ambulance.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';

abstract class AmbulanceRepository {
  /// Hospital's own fleet — for AmbulanceManagementScreen and the Command
  /// Center's dispatch picker.
  Stream<Either<Failure, List<Ambulance>>> watchHospitalFleet(String hospitalId);

  /// The single ambulance this driver is assigned to, if any — for
  /// AmbulanceDriverHomeScreen.
  Stream<Either<Failure, Ambulance?>> watchDriverAmbulance(String driverUid);

  /// A single ambulance by id — for the patient's AmbulanceTrackingCard
  /// once `assignedAmbulanceId` is set.
  Stream<Either<Failure, Ambulance?>> watchAmbulanceById(String ambulanceId);

  /// The active/most recent trip for an emergency request, if an ambulance
  /// has been dispatched — for the patient's tracking card.
  Stream<Either<Failure, AmbulanceTrip?>> watchTripForEmergency(String emergencyRequestId);

  Future<Either<Failure, String>> registerAmbulance({
    required String vehicleNumber,
    required String driverName,
    required String driverPhone,
    String? driverEmail,
  });

  Future<Either<Failure, Unit>> setAvailability(String ambulanceId, AmbulanceStatus status);
  Future<Either<Failure, Unit>> dispatchAmbulance(String requestId, String ambulanceId);
  Future<Either<Failure, Unit>> completeTrip(String tripId);

  /// Driver-side self-reported location ping — a narrow direct Firestore
  /// write permitted by rules (see firestore.rules), not a Cloud Function.
  Future<Either<Failure, Unit>> updateAmbulanceLocation(
    String ambulanceId,
    GeoPointValue location,
  );
}
