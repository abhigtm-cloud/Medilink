/// Represents a booking made by a user
class Booking {
  final String? id;
  final String userId; // UID of the user who booked
  final String hospitalId;
  final String doctorId;
  final String slotId;
  final String date; // Format: "yyyy-MM-dd"
  final String time; // Format: "HH:mm - HH:mm"
  final DateTime createdAt;
  final BookingStatus status;

  const Booking({
    this.id,
    required this.userId,
    required this.hospitalId,
    required this.doctorId,
    required this.slotId,
    required this.date,
    required this.time,
    required this.createdAt,
    this.status = BookingStatus.confirmed,
  });

  Booking copyWith({
    String? id,
    String? userId,
    String? hospitalId,
    String? doctorId,
    String? slotId,
    String? date,
    String? time,
    DateTime? createdAt,
    BookingStatus? status,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      hospitalId: hospitalId ?? this.hospitalId,
      doctorId: doctorId ?? this.doctorId,
      slotId: slotId ?? this.slotId,
      date: date ?? this.date,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Booking(
      id: docId ?? json['id'] as String?,
      userId: json['userId'] as String,
      hospitalId: json['hospitalId'] as String,
      doctorId: json['doctorId'] as String,
      slotId: json['slotId'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == 'BookingStatus.${json['status']}',
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'hospitalId': hospitalId,
      'doctorId': doctorId,
      'slotId': slotId,
      'date': date,
      'time': time,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }
}

enum BookingStatus { confirmed, cancelled, completed }
