import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:medilink/features/home/models/doctor.dart';
import 'package:medilink/features/home/providers/doctor_provider.dart';

class AddDoctorScreen extends ConsumerStatefulWidget {
  final String hospitalId;
  final String hospitalName;

  const AddDoctorScreen({
    super.key,
    required this.hospitalId,
    required this.hospitalName,
  });

  @override
  ConsumerState<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends ConsumerState<AddDoctorScreen> {
  final List<DoctorFormData> _doctors = [];
  bool _isSaving = false;

  @override
  void dispose() {
    for (final doctor in _doctors) {
      doctor.dispose();
    }
    super.dispose();
  }

  void _addDoctorForm() {
    setState(() {
      _doctors.add(DoctorFormData());
    });
  }

  void _removeDoctorForm(int index) {
    setState(() {
      _doctors[index].dispose();
      _doctors.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (_isSaving) return;
    if (_doctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one doctor')),
      );
      return;
    }

    // Validate all doctor forms
    for (final doctor in _doctors) {
      if (!doctor.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all doctor details')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      // Create doctors with custom credentials
      for (final doctorForm in _doctors) {
        final email = doctorForm.emailController.text.trim();
        final password = doctorForm.passwordController.text.trim();
        String? authUid;

        // Provision Firebase Auth account for doctor using secondary FirebaseApp so current admin session is NOT disrupted
        try {
          final appName = 'DocAuth_${DateTime.now().microsecondsSinceEpoch}';
          final secondaryApp = await Firebase.initializeApp(
            name: appName,
            options: Firebase.app().options,
          );
          try {
            final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
            final userCred = await secondaryAuth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
            authUid = userCred.user?.uid;
            await userCred.user?.updateDisplayName(doctorForm.nameController.text.trim());
          } finally {
            await secondaryApp.delete();
          }
        } catch (authErr) {
          debugPrint('Doctor auth creation note: $authErr');
        }

        final doctor = Doctor(
          hospitalId: widget.hospitalId,
          name: doctorForm.nameController.text.trim(),
          specialization: doctorForm.specializationController.text.trim(),
          startTime: doctorForm.startTime,
          endTime: doctorForm.endTime,
          slotDurationMinutes: doctorForm.slotDuration,
          photoUrl: doctorForm.photoBase64,
          email: email,
          authUid: authUid,
        );

        final createdDoctor = await ref.read(doctorRepositoryProvider).createDoctor(doctor);

        // Store user and staff records in RTDB
        if (authUid != null) {
          final db = FirebaseDatabase.instance.ref();
          try {
            await db.child('users').child(authUid).set({
              'uid': authUid,
              'email': email,
              'displayName': doctor.name,
              'role': 'doctor',
              'hospitalId': widget.hospitalId,
              'doctorId': createdDoctor.id,
              'createdAt': DateTime.now().toIso8601String(),
            });
          } catch (userErr) {
            debugPrint('User profile record note: $userErr');
          }

          try {
            await db.child('hospitals').child(widget.hospitalId).child('staff').child(authUid).set({
              'email': email,
              'role': 'doctor',
              'name': doctor.name,
              'doctorId': createdDoctor.id,
              'assignedAt': DateTime.now().toIso8601String(),
            });
          } catch (_) {}
        }
        if (!mounted) return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Doctor(s) added successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Invalidate doctor list provider to ensure instant refresh
      ref.invalidate(getDoctorsByHospitalProvider(widget.hospitalId));

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Doctors to ${widget.hospitalName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: const Color(0xFF20B2AA).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF20B2AA)),
                        SizedBox(width: 8),
                        Text(
                          'Add doctors to your hospital',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Booking slots will be auto-generated in background for the next 30 days',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Doctors Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Doctors',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_doctors.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_add_outlined,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No doctors added yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._doctors.asMap().entries.map(
                    (entry) {
                      final index = entry.key;
                      final doctorForm = entry.value;
                      return _DoctorFormWidget(
                        key: ValueKey(index),
                        doctorForm: doctorForm,
                        onRemove: () => _removeDoctorForm(index),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Add More Doctor Button
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _addDoctorForm,
              icon: const Icon(Icons.add),
              label: const Text('Add Another Doctor'),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: (_doctors.isEmpty || _isSaving) ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF20B2AA),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Doctors',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class DoctorFormData {
  final nameController = TextEditingController();
  final specializationController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String startTime = '09:00';
  String endTime = '17:00';
  int slotDuration = 30;
  String? photoBase64; // Base64 encoded doctor photo
  File? photoFile; // Temporary file reference

  bool validate() {
    return nameController.text.trim().isNotEmpty &&
        specializationController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        passwordController.text.trim().length >= 6;
  }

  void dispose() {
    nameController.dispose();
    specializationController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }
}

class _DoctorFormWidget extends StatefulWidget {
  final DoctorFormData doctorForm;
  final VoidCallback onRemove;

  const _DoctorFormWidget({
    super.key,
    required this.doctorForm,
    required this.onRemove,
  });

  @override
  State<_DoctorFormWidget> createState() => _DoctorFormWidgetState();
}

class _DoctorFormWidgetState extends State<_DoctorFormWidget> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Doctor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.doctorForm.nameController,
              decoration: const InputDecoration(
                labelText: 'Doctor Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.doctorForm.specializationController,
              decoration: const InputDecoration(
                labelText: 'Specialization (e.g. Cardiologist)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.doctorForm.emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Doctor Login Email',
                hintText: 'e.g. dr.smith@medilink.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.doctorForm.passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Assign Password (min 6 characters)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimePickerField(
                    label: 'Start Time',
                    initialTime: widget.doctorForm.startTime,
                    onTimeChanged: (time) {
                      widget.doctorForm.startTime = time;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePickerField(
                    label: 'End Time',
                    initialTime: widget.doctorForm.endTime,
                    onTimeChanged: (time) {
                      widget.doctorForm.endTime = time;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: widget.doctorForm.slotDuration,
              decoration: const InputDecoration(
                labelText: 'Slot Duration (minutes)',
                border: OutlineInputBorder(),
              ),
              items: [15, 20, 25, 30, 45, 60].map((value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text('$value minutes'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    widget.doctorForm.slotDuration = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Doctor Photo Section
            const Text(
              'Doctor Photo (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.doctorForm.photoFile != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      widget.doctorForm.photoFile!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.doctorForm.photoFile = null;
                          widget.doctorForm.photoBase64 = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: () => _pickDoctorPhoto(context),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to upload doctor photo',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDoctorPhoto(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 60,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        setState(() {
          widget.doctorForm.photoFile = imageFile;
          widget.doctorForm.photoBase64 = base64Image;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Photo selected')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }
}

class _TimePickerField extends StatefulWidget {
  final String label;
  final String initialTime;
  final Function(String) onTimeChanged;

  const _TimePickerField({
    required this.label,
    required this.initialTime,
    required this.onTimeChanged,
  });

  @override
  State<_TimePickerField> createState() => _TimePickerFieldState();
}

class _TimePickerFieldState extends State<_TimePickerField> {
  late String _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final parts = _selectedTime.split(':');
        final initial = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );

        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
        );

        if (picked != null) {
          final timeStr =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          setState(() {
            _selectedTime = timeStr;
          });
          widget.onTimeChanged(timeStr);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          _selectedTime,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
