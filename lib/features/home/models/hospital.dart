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
      final text = '$addr $name';

      if (text.contains('kharar')) {
        lat = 30.7441;
        lng = 76.6471;
      } else if (text.contains('chandigarh')) {
        lat = 30.7333;
        lng = 76.7794;
      } else if (text.contains('mohali') || text.contains('sas nagar')) {
        lat = 30.7046;
        lng = 76.7179;
      } else if (text.contains('panchkula')) {
        lat = 30.6942;
        lng = 76.8606;
      } else if (text.contains('zirakpur')) {
        lat = 30.6425;
        lng = 76.8173;
      } else if (text.contains('patiala')) {
        lat = 30.3398;
        lng = 76.3869;
      } else if (text.contains('ludhiana')) {
        lat = 30.9010;
        lng = 75.8573;
      } else if (text.contains('jalandhar')) {
        lat = 31.3260;
        lng = 75.5762;
      } else if (text.contains('amritsar')) {
        lat = 31.6340;
        lng = 74.8723;
      } else if (text.contains('delhi') || text.contains('ncr')) {
        lat = 28.6139;
        lng = 77.2090;
      } else if (text.contains('noida')) {
        lat = 28.5355;
        lng = 77.3910;
      } else if (text.contains('gurugram') || text.contains('gurgaon')) {
        lat = 28.4595;
        lng = 77.0266;
      } else if (text.contains('mumbai') || text.contains('bombay')) {
        lat = 19.0760;
        lng = 72.8777;
      } else if (text.contains('pune')) {
        lat = 18.5204;
        lng = 73.8567;
      } else if (text.contains('bangalore') || text.contains('bengaluru')) {
        lat = 12.9716;
        lng = 77.5946;
      } else if (text.contains('hyderabad')) {
        lat = 17.3850;
        lng = 78.4867;
      } else if (text.contains('chennai') || text.contains('madras')) {
        lat = 13.0827;
        lng = 80.2707;
      } else if (text.contains('kolkata') || text.contains('calcutta')) {
        lat = 22.5726;
        lng = 88.3639;
      } else if (text.contains('jaipur')) {
        lat = 26.9124;
        lng = 75.7873;
      } else if (text.contains('lucknow')) {
        lat = 26.8467;
        lng = 80.9462;
      } else if (text.contains('ahmedabad')) {
        lat = 23.0225;
        lng = 72.5714;
      } else {
        // Default to regional hub rather than null
        lat = 30.7441;
        lng = 76.6471;
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
      'id': id,
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
