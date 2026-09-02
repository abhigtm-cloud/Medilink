import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/features/auth/models/app_user.dart';
import 'package:medilink/features/home/models/doctor.dart';
import 'package:medilink/features/home/models/slot.dart';
import 'package:medilink/features/home/screens/add_doctor_screen.dart';

void main() {
  group('A. AppUser & Role-Based Routing Tests', () {
    test('UserRole contains doctor, hospitalAdmin, and normalUser', () {
      expect(UserRole.values.contains(UserRole.doctor), isTrue);
      expect(UserRole.values.contains(UserRole.hospitalAdmin), isTrue);
      expect(UserRole.values.contains(UserRole.normalUser), isTrue);

      expect(UserRole.doctor.isDoctor, isTrue);
      expect(UserRole.doctor.isHospitalAdmin, isFalse);
      expect(UserRole.doctor.isNormalUser, isFalse);
      expect(UserRole.doctor.displayName, equals('Doctor'));
    });

    test('AppUser.fromJson extracts doctor role from explicit role or email', () {
      final jsonDoctor = {
        'uid': 'doc_123',
        'email': 'dr.vikram@alpha.com',
        'displayName': 'Dr. Vikram',
        'role': 'doctor',
      };

      final user = AppUser.fromJson(jsonDoctor);
      expect(user.role, equals(UserRole.doctor));
      expect(user.role.isDoctor, isTrue);
      expect(user.displayName, equals('Dr. Vikram'));

      final jsonDocEmail = {
        'uid': 'doc_456',
        'email': 'doctor.sharma@hospital.org',
        'displayName': 'Dr. Sharma',
      };
      final user2 = AppUser.fromJson(jsonDocEmail);
      expect(user2.role, equals(UserRole.doctor));
    });
  });

  group('B. Doctor Model & Absent System Tests', () {
    test('Doctor model instantiates with default isAbsent = false', () {
      const doctor = Doctor(
        id: 'doc_1',
        hospitalId: 'hosp_alpha',
        name: 'Dr. Anita Roy',
        specialization: 'Cardiology',
        startTime: '09:00',
        endTime: '17:00',
        slotDurationMinutes: 30,
        email: 'anita@alpha.com',
      );

      expect(doctor.isAbsent, isFalse);
      expect(doctor.absentReason, isNull);
      expect(doctor.email, equals('anita@alpha.com'));
    });

    test('Doctor copyWith and toJson/fromJson preserves isAbsent & authUid', () {
      const doctor = Doctor(
        id: 'doc_1',
        hospitalId: 'hosp_alpha',
        name: 'Dr. Anita Roy',
        specialization: 'Cardiology',
        startTime: '09:00',
        endTime: '17:00',
        slotDurationMinutes: 30,
        email: 'anita@alpha.com',
        isAbsent: false,
      );

      final absentDoctor = doctor.copyWith(
        isAbsent: true,
        absentReason: 'Medical Leave',
        authUid: 'firebase_auth_uid_999',
      );

      expect(absentDoctor.isAbsent, isTrue);
      expect(absentDoctor.absentReason, equals('Medical Leave'));
      expect(absentDoctor.authUid, equals('firebase_auth_uid_999'));

      final json = absentDoctor.toJson();
      expect(json['isAbsent'], isTrue);
      expect(json['absentReason'], equals('Medical Leave'));
      expect(json['authUid'], equals('firebase_auth_uid_999'));

      final restored = Doctor.fromJson(json, docId: 'doc_1');
      expect(restored.isAbsent, isTrue);
      expect(restored.absentReason, equals('Medical Leave'));
      expect(restored.authUid, equals('firebase_auth_uid_999'));
      expect(restored.name, equals('Dr. Anita Roy'));
    });
  });

  group('C. Admin Add Doctor Form Data Validation Tests', () {
    test('DoctorFormData requires name, specialization, email and password >= 6 chars', () {
      final form = DoctorFormData();
      expect(form.validate(), isFalse);

      form.nameController.text = 'Dr. Rajiv Malhotra';
      expect(form.validate(), isFalse);

      form.specializationController.text = 'Orthopedics';
      expect(form.validate(), isFalse);

      form.emailController.text = 'rajiv@alpha.com';
      expect(form.validate(), isFalse); // password still missing

      form.passwordController.text = '123'; // too short (< 6 chars)
      expect(form.validate(), isFalse);

      form.passwordController.text = 'doctorPass123';
      expect(form.validate(), isTrue);

      form.dispose();
    });
  });

  group('D. Slot Booking & Sunday Closure Tests', () {
    test('Sunday dates return weekday == 7 and must be closed from booking', () {
      final sunday = DateTime(2026, 9, 6); // September 6, 2026 is Sunday
      expect(sunday.weekday, equals(7));

      final monday = DateTime(2026, 9, 7); // September 7, 2026 is Monday
      expect(monday.weekday, equals(1));
    });

    test('Slot bookedBy != null indicates Doctor Busy', () {
      final availableSlot = Slot(
        id: 'slot_1',
        doctorId: 'doc_1',
        hospitalId: 'hosp_1',
        date: '2026-09-07',
        time: '09:00 - 09:30',
        bookedBy: null,
      );
      expect(availableSlot.isAvailable, isTrue);

      final bookedSlot = Slot(
        id: 'slot_2',
        doctorId: 'doc_1',
        hospitalId: 'hosp_1',
        date: '2026-09-07',
        time: '09:30 - 10:00',
        bookedBy: 'patient_uid_888',
      );
      expect(bookedSlot.isAvailable, isFalse);

      final blockedSlot = Slot(
        id: 'slot_3',
        doctorId: 'doc_1',
        hospitalId: 'hosp_1',
        date: '2026-09-07',
        time: '10:00 - 10:30',
        bookedBy: 'BLOCKED_BY_ADMIN',
      );
      expect(blockedSlot.isAvailable, isFalse);
    });
  });

  group('E. Hospital Phone Dialing Tests', () {
    test('Sanitizes raw contact phone into valid tel: URI', () {
      const rawContact = '+91 (11) 2658-8500';
      final cleanPhone = rawContact.replaceAll(RegExp(r'[^0-9+]'), '');
      expect(cleanPhone, equals('+911126588500'));

      final uri = Uri.parse('tel:$cleanPhone');
      expect(uri.scheme, equals('tel'));
      expect(uri.path, equals('+911126588500'));
    });
  });
}
