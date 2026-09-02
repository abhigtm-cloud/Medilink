import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/home/models/doctor.dart';
import 'package:medilink/features/home/models/slot.dart';
import 'package:medilink/features/home/providers/doctor_provider.dart';
import 'package:medilink/features/home/providers/slot_provider.dart';

class ManageDoctorSlotsScreen extends ConsumerStatefulWidget {
  final Doctor doctor;

  const ManageDoctorSlotsScreen({
    super.key,
    required this.doctor,
  });

  @override
  ConsumerState<ManageDoctorSlotsScreen> createState() =>
      _ManageDoctorSlotsScreenState();
}

class _ManageDoctorSlotsScreenState extends ConsumerState<ManageDoctorSlotsScreen> {
  late DateTime _selectedDate;
  late Doctor _currentDoctor;

  @override
  void initState() {
    super.initState();
    _currentDoctor = widget.doctor;
    _selectedDate = DateTime.now();
    if (_selectedDate.weekday == 7) {
      _selectedDate = _selectedDate.add(const Duration(days: 1)); // Skip Sunday
    }
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _getDateString(_selectedDate);
    final isSunday = _selectedDate.weekday == 7;
    final slotsAsync = isSunday
        ? null
        : ref.watch(
            getSlotsByDoctorAndDateProvider(
              (_currentDoctor.hospitalId, _currentDoctor.id ?? '', dateStr),
            ),
          );

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Manage Slots & Schedule',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _currentDoctor.name,
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Edit Working Hours',
            onPressed: _openEditScheduleDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Doctor Schedule Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardLight,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  radius: 24,
                  child: Icon(Icons.medical_services, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentDoctor.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_currentDoctor.specialization} • Slot: ${_currentDoctor.slotDurationMinutes} min',
                        style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hours: ${_currentDoctor.startTime} - ${_currentDoctor.endTime} (Mon - Sat)',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _openEditScheduleDialog,
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Date Selector (Next 21 Days, Mon-Sat)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: AppColors.cardLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Date to Manage Slots',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'No Sundays',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: 21,
                    itemBuilder: (context, index) {
                      final date = DateTime.now().add(Duration(days: index));
                      final dateFormatted = _getDateString(date);
                      final isSelected = dateFormatted == dateStr;
                      final isSun = date.weekday == 7;

                      return GestureDetector(
                        onTap: () {
                          if (isSun) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('⚠️ Sundays are closed. Doctors do not hold OPD on Sundays.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        child: Container(
                          width: 68,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSun
                                ? AppColors.surfaceLight.withOpacity(0.5)
                                : (isSelected
                                    ? AppColors.primary.withOpacity(0.12)
                                    : AppColors.surfaceLight),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSun
                                  ? AppColors.borderLight
                                  : (isSelected
                                      ? AppColors.primary
                                      : AppColors.borderLight),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSun
                                      ? AppColors.error
                                      : (isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondaryLight),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSun
                                      ? AppColors.textSecondaryLight
                                      : (isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimaryLight),
                                ),
                              ),
                              if (isSun)
                                const Text(
                                  'Closed',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Action Toolbar for Selected Date
          if (!isSunday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.surfaceLight,
              child: Row(
                children: [
                  Text(
                    'Slots on ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const Spacer(),
                  // Regenerate Day Slots
                  TextButton.icon(
                    onPressed: () => _regenerateSlotsForDate(dateStr),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset Day'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  // Delete All Slots for this date
                  TextButton.icon(
                    onPressed: () => _confirmDeleteDaySlots(dateStr),
                    icon: const Icon(Icons.delete_sweep, size: 16),
                    label: const Text('Block Day'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),

          // Slots List
          Expanded(
            child: isSunday
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.weekend_outlined, size: 54, color: AppColors.error.withOpacity(0.7)),
                        const SizedBox(height: 12),
                        const Text(
                          'Hospital Closed on Sunday',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No slots exist or can be booked on Sundays.',
                          style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : (slotsAsync?.when(
                      data: (slots) {
                        if (slots.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.schedule, size: 48, color: AppColors.borderLight),
                                const SizedBox(height: 12),
                                const Text(
                                  'No slots configured for this date',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _regenerateSlotsForDate(dateStr),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Generate Slots for this Date'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: slots.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final slot = slots[index];
                            final isBooked = !slot.isAvailable;
                            final isBlockedByAdmin = slot.bookedBy == 'BLOCKED_BY_ADMIN';

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isBooked
                                    ? AppColors.error.withOpacity(0.06)
                                    : AppColors.cardLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isBooked
                                      ? AppColors.error.withOpacity(0.4)
                                      : AppColors.borderLight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isBooked ? Icons.event_busy : Icons.schedule,
                                    color: isBooked ? AppColors.error : AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          slot.time,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isBooked
                                                ? AppColors.error
                                                : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isBlockedByAdmin
                                              ? 'Marked Busy by Admin'
                                              : (isBooked ? 'Booked by Patient' : 'Available for Booking'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isBooked
                                                ? AppColors.error
                                                : AppColors.success,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Toggle Busy Button
                                  IconButton(
                                    icon: Icon(
                                      isBooked ? Icons.check_circle_outline : Icons.block,
                                      color: isBooked ? AppColors.success : AppColors.warning,
                                      size: 20,
                                    ),
                                    tooltip: isBooked ? 'Make Available' : 'Mark Doctor Busy',
                                    onPressed: () => _toggleSlotBusy(slot, dateStr),
                                  ),
                                  // Delete Slot Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                    tooltip: 'Delete Slot',
                                    onPressed: () => _deleteSingleSlot(slot, dateStr),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err')),
                    ) ??
                    const SizedBox.shrink()),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSlotBusy(Slot slot, String dateStr) async {
    final markBusy = slot.isAvailable;
    await ref.read(slotControllerProvider.notifier).toggleSlotBusy(
          hospitalId: _currentDoctor.hospitalId,
          doctorId: _currentDoctor.id ?? '',
          date: dateStr,
          slotId: slot.id!,
          markBusy: markBusy,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(markBusy ? 'Slot marked Busy' : 'Slot made Available'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _deleteSingleSlot(Slot slot, String dateStr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Slot?'),
        content: Text('Delete ${slot.time} slot for this date?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(slotControllerProvider.notifier).deleteSlot(
            hospitalId: _currentDoctor.hospitalId,
            doctorId: _currentDoctor.id ?? '',
            date: dateStr,
            slotId: slot.id!,
          );
    }
  }

  Future<void> _confirmDeleteDaySlots(String dateStr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block Entire Day?'),
        content: Text('This will delete all slots on $dateStr. Patients won\'t be able to book this day.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Block Day'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(slotControllerProvider.notifier).deleteSlotsForDate(
            hospitalId: _currentDoctor.hospitalId,
            doctorId: _currentDoctor.id ?? '',
            date: dateStr,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All slots for this day removed.')),
      );
    }
  }

  Future<void> _regenerateSlotsForDate(String dateStr) async {
    await ref
        .read(slotControllerProvider.notifier)
        .regenerateDateSlots(_currentDoctor, dateStr);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Slots refreshed for $dateStr based on working hours.')),
    );
  }

  Future<void> _openEditScheduleDialog() async {
    final startController = TextEditingController(text: _currentDoctor.startTime);
    final endController = TextEditingController(text: _currentDoctor.endTime);
    final durationController =
        TextEditingController(text: _currentDoctor.slotDurationMinutes.toString());

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Doctor Working Hours'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startController,
                decoration: const InputDecoration(
                  labelText: 'Start Time (HH:mm, 24-hr)',
                  hintText: '09:00',
                  prefixIcon: Icon(Icons.access_time),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endController,
                decoration: const InputDecoration(
                  labelText: 'End Time (HH:mm, 24-hr)',
                  hintText: '17:00',
                  prefixIcon: Icon(Icons.access_time_filled),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Slot Duration (minutes)',
                  hintText: '30',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save & Update'),
          ),
        ],
      ),
    );

    if (updated == true) {
      final newDuration = int.tryParse(durationController.text.trim()) ?? 30;
      final updatedDoctor = _currentDoctor.copyWith(
        startTime: startController.text.trim(),
        endTime: endController.text.trim(),
        slotDurationMinutes: newDuration,
      );

      await ref.read(doctorControllerProvider.notifier).updateDoctor(updatedDoctor);
      setState(() {
        _currentDoctor = updatedDoctor;
      });

      // Regenerate today's slots with the new schedule
      final dateStr = _getDateString(_selectedDate);
      if (_selectedDate.weekday != 7) {
        await ref
            .read(slotControllerProvider.notifier)
            .regenerateDateSlots(updatedDoctor, dateStr);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor working schedule updated!')),
      );
    }
  }
}
