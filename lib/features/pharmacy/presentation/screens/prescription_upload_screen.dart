import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/home/models/hospital.dart';
import 'package:medilink/features/home/providers/hospital_provider.dart';
import 'package:medilink/features/pharmacy/domain/entities/pharmacy.dart';
import 'package:medilink/features/pharmacy/presentation/providers/pharmacy_providers.dart';

class PrescriptionUploadScreen extends ConsumerStatefulWidget {
  const PrescriptionUploadScreen({super.key});

  @override
  ConsumerState<PrescriptionUploadScreen> createState() => _PrescriptionUploadScreenState();
}

class _PrescriptionUploadScreenState extends ConsumerState<PrescriptionUploadScreen> {
  Hospital? _selectedHospital;
  File? _imageFile;
  bool _uploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _imageFile = File(image.path));
  }

  Future<void> _upload() async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null || _selectedHospital?.id == null || _imageFile == null) return;

    setState(() => _uploading = true);
    try {
      await ref.read(pharmacyRepositoryProvider).uploadPrescription(
            patientUid: uid,
            hospitalId: _selectedHospital!.id!,
            imageFile: _imageFile!,
          );
      if (!mounted) return;
      setState(() {
        _imageFile = null;
        _selectedHospital = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription uploaded — the pharmacy will review it shortly')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
    final hospitalsAsync = ref.watch(getAllHospitalsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(title: const Text('Upload Prescription')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            hospitalsAsync.when(
              data: (hospitals) => DropdownButtonFormField<Hospital>(
                initialValue: _selectedHospital,
                decoration: const InputDecoration(labelText: 'Pharmacy (Hospital)', border: OutlineInputBorder()),
                items: hospitals
                    .map((h) => DropdownMenuItem(value: h, child: Text(h.name)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedHospital = value),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Unable to load hospitals: $error'),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: _imageFile == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file, size: 40),
                            SizedBox(height: 8),
                            Text('Tap to select prescription photo'),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_uploading || _selectedHospital == null || _imageFile == null) ? null : _upload,
                child: _uploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Upload'),
              ),
            ),
            const SizedBox(height: 24),
            const Text('My Prescriptions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (uid != null) _MyPrescriptionsList(uid: uid),
          ],
        ),
      ),
    );
  }
}

class _MyPrescriptionsList extends ConsumerWidget {
  const _MyPrescriptionsList({required this.uid});

  final String uid;

  Color _statusColor(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.approved:
        return AppColors.success;
      case PrescriptionStatus.rejected:
        return AppColors.error;
      case PrescriptionStatus.pendingReview:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptionsAsync = ref.watch(myPrescriptionsProvider(uid));

    return prescriptionsAsync.when(
      data: (prescriptions) {
        if (prescriptions.isEmpty) return const Text('No prescriptions uploaded yet.');
        final sorted = [...prescriptions]
          ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        return Column(
          children: sorted
              .map((p) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(p.status.label, style: TextStyle(color: _statusColor(p.status))),
                      subtitle: p.reviewNote != null ? Text(p.reviewNote!) : null,
                    ),
                  ))
              .toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Unable to load: $error'),
    );
  }
}
