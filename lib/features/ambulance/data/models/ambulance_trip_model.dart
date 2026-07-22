import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medilink/features/ambulance/domain/entities/ambulance.dart';

class AmbulanceTripModel extends AmbulanceTrip {
  const AmbulanceTripModel({
    required super.id,
    required super.emergencyRequestId,
    required super.hospitalId,
    required super.ambulanceId,
    required super.status,
    super.dispatchedAt,
    super.completedAt,
  });

  factory AmbulanceTripModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    DateTime? ts(String key) => (data[key] as Timestamp?)?.toDate();

    return AmbulanceTripModel(
      id: doc.id,
      emergencyRequestId: data['emergencyRequestId'] as String? ?? '',
      hospitalId: data['hospitalId'] as String? ?? '',
      ambulanceId: data['ambulanceId'] as String? ?? '',
      status: AmbulanceTripStatus.fromValue(data['status'] as String?),
      dispatchedAt: ts('dispatchedAt'),
      completedAt: ts('completedAt'),
    );
  }
}
