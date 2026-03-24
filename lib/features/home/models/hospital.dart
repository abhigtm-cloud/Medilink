/// Represents a hospital in the system
class Hospital {
  final String? id;
  final String name;
  final String address;
  final String contact;
  final String? adminId; // UID of the hospital admin who created it
  final DateTime? createdAt;
  final String? photoUrl; // Photo URL or base64 encoded image

  const Hospital({
    this.id,
    required this.name,
    required this.address,
    required this.contact,
    this.adminId,
    this.createdAt,
    this.photoUrl,
  });

  Hospital copyWith({
    String? id,
    String? name,
    String? address,
    String? contact,
    String? adminId,
    DateTime? createdAt,
    String? photoUrl,
  }) {
    return Hospital(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
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
    };
  }
}
