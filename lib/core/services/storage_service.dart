import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Cloud Storage upload for prescriptions/reports (see storage.rules — each
/// user's files live under their own uid). New for Feature 7 — the rest of
/// the app still stores images as base64 strings in RTDB/Firestore fields
/// directly; prescriptions/reports use real Storage instead since photos
/// can exceed Firestore's 1MB document size limit.
class StorageService {
  StorageService({FirebaseStorage? storage}) : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadPrescription(String uid, File file) async {
    final ref = _storage.ref('prescriptions/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadMedicalReport(String uid, File file, String extension) async {
    final ref = _storage.ref(
      'medical_reports/$uid/${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
