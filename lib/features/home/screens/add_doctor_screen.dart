import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/home/models/doctor.dart';
import 'package:medilink/features/home/models/slot.dart';
import 'package:medilink/features/home/providers/doctor_provider.dart';
import 'package:medilink/core/utils/slot_generator.dart';
import 'package:medilink/features/home/providers/slot_provider.dart';

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
  final _formKey = GlobalKey<FormState>();
  final List<DoctorFormData> _doctors = [];

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

    try {
      // Create doctors with slots
      for (final doctorForm in _doctors) {
        final doctor = Doctor(
          hospitalId: widget.hospitalId,
          name: doctorForm.nameController.text.trim(),
          specialization: doctorForm.specializationController.text.trim(),
          startTime: doctorForm.startTime,
          endTime: doctorForm.endTime,
          slotDurationMinutes: doctorForm.slotDuration,
        );

        await ref.read(doctorControllerProvider.notifier).createDoctor(doctor);

        if (!mounted) return;

        // Invalidate the doctors provider cache
        ref.invalidate(getDoctorsByHospitalProvider(widget.hospitalId));

        // Get the created doctor
        final doctorsAsync = await ref.read(
          getDoctorsByHospitalProvider(widget.hospitalId).future,
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
                hospitalId: widget.hospitalId,
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
                widget.hospitalId,
                createdDoctor.id!,
                '',
              );

          // Invalidate the slots provider cache
          ref.invalidate(getSlotsByDoctorAndDateProvider((
            widget.hospitalId,
            createdDoctor.id!,
            DateTime.now().toIso8601String().split('T')[0],
          )));
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Doctors added successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Clear form
      setState(() {
        for (final doctor in _doctors) {
          doctor.dispose();
        }
        _doctors.clear();
      });

      // Wait for Firebase to save, then navigate back
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      print('Error adding doctors: $e');
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
    final doctorState = ref.watch(doctorControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Doctors to ${widget.hospitalName}'),
      ),
      body: doctorState.when(
        data: (_) {
          return SingleChildScrollView(
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
                              'Add more doctors to your hospital',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Slots will be automatically generated for the next 7 days',
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
                  onPressed: _addDoctorForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Doctor'),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _doctors.isEmpty ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF20B2AA),
                  ),
                  child: const Text(
                    'Save Doctors',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
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
              value: widget.doctorForm.slotDuration,
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
          ],
        ),
      ),
    );
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
