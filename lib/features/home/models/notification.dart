/// Notification model for bookings and system updates
class Notification {
  final String? id;
  final String userId; // Hospital admin or user ID
  final String type; // 'booking', 'cancellation', 'system'
  final String title;
  final String message;
  final Map<String, dynamic>? data; // Booking details, etc
  final DateTime createdAt;
  final bool isRead;

  const Notification({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.createdAt,
    this.isRead = false,
  });

  Notification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory Notification.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Notification(
      id: docId ?? json['id'] as String?,
      userId: json['userId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }
}
