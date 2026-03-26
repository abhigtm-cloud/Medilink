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
    return Hospital(
      id: docId ?? json['id'] as String?,
      name: json['name'] as String,
      address: json['address'] as String,
      contact: json['contact'] as String,
      adminId: json['adminId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      photoUrl: json['photoUrl'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
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
