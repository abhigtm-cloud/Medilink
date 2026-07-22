import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {
  final String id;
  final String hospitalId;
  final String name;
  final String? genericName;
  final String? manufacturer;
  final String? category;
  final double unitPrice;
  final int stockQuantity;
  final bool requiresPrescription;
  final bool isActive;

  const Medicine({
    required this.id,
    required this.hospitalId,
    required this.name,
    required this.unitPrice,
    required this.stockQuantity,
    this.genericName,
    this.manufacturer,
    this.category,
    this.requiresPrescription = false,
    this.isActive = true,
  });

  factory Medicine.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, String hospitalId) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Medicine(
      id: doc.id,
      hospitalId: hospitalId,
      name: data['name'] as String? ?? '',
      genericName: data['genericName'] as String?,
      manufacturer: data['manufacturer'] as String?,
      category: data['category'] as String?,
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
      stockQuantity: (data['stockQuantity'] as num?)?.toInt() ?? 0,
      requiresPrescription: data['requiresPrescription'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'genericName': genericName,
        'manufacturer': manufacturer,
        'category': category,
        'unitPrice': unitPrice,
        'stockQuantity': stockQuantity,
        'requiresPrescription': requiresPrescription,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

enum PrescriptionStatus {
  pendingReview,
  approved,
  rejected;

  static PrescriptionStatus fromValue(String? value) {
    switch (value) {
      case 'approved':
        return PrescriptionStatus.approved;
      case 'rejected':
        return PrescriptionStatus.rejected;
      default:
        return PrescriptionStatus.pendingReview;
    }
  }

  String get value {
    switch (this) {
      case PrescriptionStatus.approved:
        return 'approved';
      case PrescriptionStatus.rejected:
        return 'rejected';
      case PrescriptionStatus.pendingReview:
        return 'pending_review';
    }
  }

  String get label {
    switch (this) {
      case PrescriptionStatus.approved:
        return 'Approved';
      case PrescriptionStatus.rejected:
        return 'Rejected';
      case PrescriptionStatus.pendingReview:
        return 'Pending Review';
    }
  }
}

class Prescription {
  final String id;
  final String patientUid;
  final String? hospitalId;
  final String imageUrl;
  final PrescriptionStatus status;
  final String? reviewNote;
  final DateTime? createdAt;

  const Prescription({
    required this.id,
    required this.patientUid,
    required this.imageUrl,
    required this.status,
    this.hospitalId,
    this.reviewNote,
    this.createdAt,
  });

  factory Prescription.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Prescription(
      id: doc.id,
      patientUid: data['patientUid'] as String? ?? '',
      hospitalId: data['hospitalId'] as String?,
      imageUrl: data['imageUrl'] as String? ?? '',
      status: PrescriptionStatus.fromValue(data['status'] as String?),
      reviewNote: data['reviewNote'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class PharmacyOrderItem {
  final String medicineId;
  final String name;
  final int quantity;
  final double unitPrice;

  const PharmacyOrderItem({
    required this.medicineId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() => {
        'medicineId': medicineId,
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory PharmacyOrderItem.fromJson(Map<String, dynamic> json) => PharmacyOrderItem(
        medicineId: json['medicineId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      );
}

enum PharmacyOrderStatus {
  placed,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled;

  static PharmacyOrderStatus fromValue(String? value) {
    switch (value) {
      case 'confirmed':
        return PharmacyOrderStatus.confirmed;
      case 'preparing':
        return PharmacyOrderStatus.preparing;
      case 'out_for_delivery':
        return PharmacyOrderStatus.outForDelivery;
      case 'delivered':
        return PharmacyOrderStatus.delivered;
      case 'cancelled':
        return PharmacyOrderStatus.cancelled;
      default:
        return PharmacyOrderStatus.placed;
    }
  }

  String get value {
    switch (this) {
      case PharmacyOrderStatus.placed:
        return 'placed';
      case PharmacyOrderStatus.confirmed:
        return 'confirmed';
      case PharmacyOrderStatus.preparing:
        return 'preparing';
      case PharmacyOrderStatus.outForDelivery:
        return 'out_for_delivery';
      case PharmacyOrderStatus.delivered:
        return 'delivered';
      case PharmacyOrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case PharmacyOrderStatus.placed:
        return 'Placed';
      case PharmacyOrderStatus.confirmed:
        return 'Confirmed';
      case PharmacyOrderStatus.preparing:
        return 'Preparing';
      case PharmacyOrderStatus.outForDelivery:
        return 'Out for Delivery';
      case PharmacyOrderStatus.delivered:
        return 'Delivered';
      case PharmacyOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isTerminal => this == PharmacyOrderStatus.delivered || this == PharmacyOrderStatus.cancelled;
}

class PharmacyOrder {
  final String id;
  final String patientUid;
  final String hospitalId;
  final String? prescriptionId;
  final List<PharmacyOrderItem> items;
  final double totalAmount;
  final PharmacyOrderStatus status;
  final String deliveryAddress;
  final DateTime? createdAt;

  const PharmacyOrder({
    required this.id,
    required this.patientUid,
    required this.hospitalId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    this.prescriptionId,
    this.createdAt,
  });

  factory PharmacyOrder.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PharmacyOrder(
      id: doc.id,
      patientUid: data['patientUid'] as String? ?? '',
      hospitalId: data['hospitalId'] as String? ?? '',
      prescriptionId: data['prescriptionId'] as String?,
      items: (data['items'] as List?)
              ?.map((e) => PharmacyOrderItem.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      status: PharmacyOrderStatus.fromValue(data['status'] as String?),
      deliveryAddress: data['deliveryAddress'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class OrderTrackingEvent {
  final String status;
  final String note;
  final DateTime? timestamp;

  const OrderTrackingEvent({required this.status, required this.note, this.timestamp});

  factory OrderTrackingEvent.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return OrderTrackingEvent(
      status: data['status'] as String? ?? '',
      note: data['note'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}
