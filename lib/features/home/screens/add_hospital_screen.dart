import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:medilink/features/home/models/hospital.dart';
import 'package:medilink/features/home/models/doctor.dart';
import 'package:medilink/features/home/providers/hospital_provider.dart';
import 'package:medilink/features/home/providers/doctor_provider.dart';
import 'package:medilink/core/services/location_service.dart';

class AddHospitalAndDoctorsScreen extends ConsumerStatefulWidget {
  const AddHospitalAndDoctorsScreen({super.key});

  @override
  ConsumerState<AddHospitalAndDoctorsScreen> createState() => _AddHospitalAndDoctorsScreenState();
}

class _AddHospitalAndDoctorsScreenState extends ConsumerState<AddHospitalAndDoctorsScreen> {
  final _hospitalFormKey = GlobalKey<FormState>();
  final _hospitalNameController = TextEditingController();
  final _hospitalAddressController = TextEditingController();
  final _hospitalContactController = TextEditingController();

  // Image picker state
  File? _hospitalImage;
  String? _hospitalPhotoBase64;
  bool _isUploadingImage = false;

  final List<DoctorFormData> _doctors = [];
  double? _geocodedLatitude;
  double? _geocodedLongitude;
  bool _geocodingAddress = false;

  @override
  void dispose() {
    _hospitalNameController.dispose();
    _hospitalAddressController.dispose();
    _hospitalContactController.dispose();
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

  Future<void> _geocodeAddress() async {
    final address = _hospitalAddressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an address first')),
      );
      return;
    }

    setState(() => _geocodingAddress = true);

    try {
      final coords = await LocationService.getCoordinatesFromPlace(address);
      if (coords != null) {
        setState(() {
          _geocodedLatitude = coords.latitude;
          _geocodedLongitude = coords.longitude;
          _geocodingAddress = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Location found: ${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _geocodingAddress = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Address not found. Please check and try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _geocodingAddress = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pickHospitalPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _isUploadingImage = true;
        });

        final File imageFile = File(image.path);
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        setState(() {
          _hospitalImage = imageFile;
          _hospitalPhotoBase64 = base64Image;
          _isUploadingImage = false;
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

  void _clearHospitalPhoto() {
    setState(() {
      _hospitalImage = null;
      _hospitalPhotoBase64 = null;
    });
  }

  Future<void> _submitForm() async {
    if (!(_hospitalFormKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all hospital details')),
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

    if (_doctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one doctor')),
      );
      return;
    }

    // Create hospital
    try {
      final hospital = Hospital(
        name: _hospitalNameController.text.trim(),
        address: _hospitalAddressController.text.trim(),
        contact: _hospitalContactController.text.trim(),
        photoUrl: _hospitalPhotoBase64,
        latitude: _geocodedLatitude,
        longitude: _geocodedLongitude,
      );

      await ref.read(hospitalControllerProvider.notifier).createHospital(hospital);

      if (!mounted) return;

      // Get the created hospital from the controller state
      final hospitalState = ref.read(hospitalControllerProvider);
      final createdHospital = hospitalState.maybeWhen(
        data: (hospital) => hospital,
        orElse: () => null,
      );

      if (createdHospital == null) {
        throw Exception('Failed to create hospital - please try again');
      }
      
      // Invalidate the admin hospitals provider cache to refresh when user navigates back
      ref.invalidate(getAdminHospitalsProvider);

      // Create doctors - slots are automatically generated by the repository
      for (final doctorForm in _doctors) {
        final doctor = Doctor(
          hospitalId: createdHospital.id!,
          name: doctorForm.nameController.text.trim(),
          specialization: doctorForm.specializationController.text.trim(),
          startTime: doctorForm.startTime,
          endTime: doctorForm.endTime,
          slotDurationMinutes: doctorForm.slotDuration,
          photoUrl: doctorForm.photoBase64,
        );

        await ref.read(doctorControllerProvider.notifier).createDoctor(doctor);

        if (!mounted) return;

        // Small delay to ensure Firebase write completes
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Hospital and doctors created successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Clear form
      _hospitalNameController.clear();
      _hospitalAddressController.clear();
      _hospitalContactController.clear();
      setState(() {
        for (final doctor in _doctors) {
          doctor.dispose();
        }
        _doctors.clear();
        _geocodedLatitude = null;
        _geocodedLongitude = null;
      });
      
      // Wait for Firebase to save
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        // Show option to add more doctors or go back
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hospital Created!'),
            content: const Text('Would you like to add more doctors to this hospital?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to hospital list
                },
                child: const Text('Go Back'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  // Refresh and stay on form to add more hospitals
                  _addDoctorForm();
                },
                child: const Text('Add More Doctors'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      print('Error creating hospital: $e'); // Debug log
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
    final hospitalState = ref.watch(hospitalControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Hospital & Doctors'),
      ),
      body: hospitalState.when(
        data: (_) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hospital Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hospital Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _hospitalFormKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _hospitalNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Hospital Name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Please enter hospital name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _hospitalAddressController,
                                decoration: const InputDecoration(
                                  labelText: 'Address',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Please enter address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              // Geocode Button
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _geocodingAddress ? null : _geocodeAddress,
                                  icon: _geocodingAddress
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.location_on),
                                  label: Text(
                                    _geocodingAddress
                                        ? 'Finding Location...'
                                        : (_geocodedLatitude != null
                                            ? '✅ Location Found'
                                            : '📍 Find Location on Map'),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _geocodedLatitude != null
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _hospitalContactController,
                                decoration: const InputDecoration(
                                  labelText: 'Contact',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Please enter contact';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Hospital Photo Section
                              const Text(
                                'Hospital Photo (Optional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_hospitalImage != null)
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _hospitalImage!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: _clearHospitalPhoto,
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
                                  onTap: _isUploadingImage ? null : _pickHospitalPhoto,
                                  child: Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey.shade50,
                                    ),
                                    child: Center(
                                      child: _isUploadingImage
                                          ? const CircularProgressIndicator()
                                          : Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.image_outlined,
                                                  size: 48,
                                                  color: Colors.grey.shade400,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Tap to upload hospital photo',
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
                  onPressed: _addDoctorForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Doctor'),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Create Hospital & Schedule'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, st) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

class DoctorFormData {
  final nameController = TextEditingController();
  final specializationController = TextEditingController();
  String startTime = '09:00';
  String endTime = '17:00';
  int slotDuration = 30;
  String? photoBase64; // Base64 encoded doctor photo
  File? photoFile; // Temporary file reference

  bool validate() {
    return nameController.text.isNotEmpty &&
        specializationController.text.isNotEmpty;
  }

  void dispose() {
    nameController.dispose();
    specializationController.dispose();
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
                  icon: const Icon(Icons.close),
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
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.doctorForm.specializationController,
              decoration: const InputDecoration(
                labelText: 'Specialization',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimePickerField(
                    label: 'Start Time',
                    initialTime: widget.doctorForm.startTime,
                    onChanged: (value) {
                      setState(() {
                        widget.doctorForm.startTime = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePickerField(
                    label: 'End Time',
                    initialTime: widget.doctorForm.endTime,
                    onChanged: (value) {
                      setState(() {
                        widget.doctorForm.endTime = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Slot Duration (minutes)'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: widget.doctorForm.slotDuration,
                        items: [15, 30, 45, 60]
                            .map(
                              (duration) => DropdownMenuItem(
                                value: duration,
                                child: Text('$duration min'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              widget.doctorForm.slotDuration = value;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
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
  final Function(String) onChanged;

  const _TimePickerField({
    required this.label,
    required this.initialTime,
    required this.onChanged,
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

  Future<void> _pickTime() async {
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
      widget.onChanged(timeStr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickTime,
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            child: Text(_selectedTime),
          ),
        ),
      ],
    );
  }
}
