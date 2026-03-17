import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/home/models/hospital.dart';
import 'package:medilink/features/home/models/doctor.dart';
import 'package:medilink/features/home/models/slot.dart';
import 'package:medilink/features/home/providers/hospital_provider.dart';
import 'package:medilink/features/home/providers/doctor_provider.dart';
import 'package:medilink/core/utils/slot_generator.dart';
import 'package:medilink/features/home/providers/slot_provider.dart';

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

  final List<DoctorFormData> _doctors = [];

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
      );

      await ref.read(hospitalControllerProvider.notifier).createHospital(hospital);

      if (!mounted) return;

      // Invalidate the admin hospitals provider cache to force refresh
      ref.invalidate(getAdminHospitalsProvider);
      
      // Get the created hospital  
      await Future.delayed(const Duration(milliseconds: 300));
      final hospitalsAsync = await ref.read(getAdminHospitalsProvider.future);
      final createdHospital = hospitalsAsync.lastOrNull;

      if (createdHospital == null) {
        throw Exception('Failed to create hospital');
      }

      // Create doctors with slots
      for (final doctorForm in _doctors) {
        final doctor = Doctor(
          hospitalId: createdHospital.id!,
          name: doctorForm.nameController.text.trim(),
          specialization: doctorForm.specializationController.text.trim(),
          startTime: doctorForm.startTime,
          endTime: doctorForm.endTime,
          slotDurationMinutes: doctorForm.slotDuration,
        );

        await ref.read(doctorControllerProvider.notifier).createDoctor(doctor);

        if (!mounted) return;

        // Invalidate the doctors provider cache
        ref.invalidate(getDoctorsByHospitalProvider(createdHospital.id!));

        // Get the created doctor
        final doctorsAsync = await ref.read(
          getDoctorsByHospitalProvider(createdHospital.id!).future,
        );
        final createdDoctor = doctorsAsync.lastOrNull;

        if (createdDoctor != null) {
          // Generate slots for today and next 7 days
          final slots = <Slot>[];
          for (int i = 0; i < 7; i++) {
            final date = DateTime.now().add(Duration(days: i));
            final dateStr =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

            slots.addAll(
              SlotGenerator.generateSlots(
                doctorId: createdDoctor.id!,
                hospitalId: createdHospital.id!,
                date: dateStr,
                startTime: createdDoctor.startTime,
                endTime: createdDoctor.endTime,
                durationMinutes: createdDoctor.slotDurationMinutes,
              ),
            );
          }

          // Create slots
          await ref.read(slotControllerProvider.notifier).createSlots(
                slots,
                createdHospital.id!,
                createdDoctor.id!,
                '',
              );
          
          // Invalidate the slots provider cache
          ref.invalidate(getSlotsByDoctorAndDateProvider((
            createdHospital.id!,
            createdDoctor.id!,
            DateTime.now().toIso8601String().split('T')[0],
          )));
        }
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
      });
      
      // Wait for Firebase to save, then navigate back to hospital listing
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show a brief message  
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading hospital details...'),
            duration: Duration(seconds: 1),
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
          ],
        ),
      ),
    );
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
