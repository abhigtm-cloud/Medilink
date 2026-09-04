/// Represents a hospital in the system
class Hospital {
  final String? id;
  final String name;
  final String address;
  final String contact;
  final String? adminId; // UID of the hospital admin who created it
  final DateTime? createdAt;
  final String? photoUrl; // Photo URL or base64 encoded image
  final double? latitude;
  final double? longitude;

  const Hospital({
    this.id,
    required this.name,
    required this.address,
    required this.contact,
    this.adminId,
    this.createdAt,
    this.photoUrl,
    this.latitude,
    this.longitude,
  });

  Hospital copyWith({
    String? id,
    String? name,
    String? address,
    String? contact,
    String? adminId,
    DateTime? createdAt,
    String? photoUrl,
    double? latitude,
    double? longitude,
  }) {
    return Hospital(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory Hospital.fromJson(Map<String, dynamic> json, {String? docId}) {
    double? lat = (json['latitude'] as num?)?.toDouble();
    double? lng = (json['longitude'] as num?)?.toDouble();

    // Auto-resolve known city/area coordinates if lat/lng were not set during creation
    if (lat == null || lng == null) {
      final addr = (json['address'] as String? ?? '').toLowerCase();
      final name = (json['name'] as String? ?? '').toLowerCase();
      if (addr.contains('kharar') || name.contains('kharar')) {
        lat = 30.7441;
        lng = 76.6471;
      } else if (addr.contains('chandigarh') || name.contains('chandigarh')) {
        lat = 30.7333;
        lng = 76.7794;
      } else if (addr.contains('mohali') || name.contains('mohali')) {
        lat = 30.7046;
        lng = 76.7179;
      } else if (addr.contains('panchkula') || name.contains('panchkula')) {
        lat = 30.6942;
        lng = 76.8606;
      } else if (addr.contains('delhi') || name.contains('delhi')) {
        lat = 28.6139;
        lng = 77.2090;
      }
    }

    return Hospital(
      id: docId ?? json['id'] as String?,
      name: json['name'] as String? ?? 'Hospital',
      address: json['address'] as String? ?? 'Address not specified',
      contact: json['contact'] as String? ?? '',
      adminId: json['adminId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      photoUrl: json['photoUrl'] as String?,
      latitude: lat,
      longitude: lng,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'contact': contact,
      'adminId': adminId,
      'createdAt': createdAt?.toIso8601String(),
      'photoUrl': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
