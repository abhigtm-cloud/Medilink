import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/home/providers/slot_provider.dart';
import 'package:medilink/features/home/providers/booking_provider.dart';
import 'package:medilink/features/home/models/booking.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/core/services/location_service.dart';
import 'package:medilink/features/home/providers/hospital_provider.dart';

class DoctorBookingScreen extends ConsumerStatefulWidget {
  final String hospitalId;
  final String doctorId;
  final String doctorName;
  final String specialization;

  const DoctorBookingScreen({
    super.key,
    required this.hospitalId,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
  });

  @override
  ConsumerState<DoctorBookingScreen> createState() =>
      _DoctorBookingScreenState();
}

class _DoctorBookingScreenState extends ConsumerState<DoctorBookingScreen> {
  late DateTime _selectedDate;
  String? _selectedSlotId;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    // If today is Sunday, automatically advance to Monday
    if (_selectedDate.weekday == 7) {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    }
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isSunday = _selectedDate.weekday == 7;
    final dateStr = _getDateString(_selectedDate);
    final doctorAsync = ref.watch(watchDoctorProvider((widget.hospitalId, widget.doctorId)));
    final isDoctorAbsent = doctorAsync.valueOrNull?.isAbsent ?? false;
    final slotsAsync = (isSunday || isDoctorAbsent)
        ? null
        : ref.watch(
            getSlotsByDoctorAndDateProvider(
              (widget.hospitalId, widget.doctorId, dateStr),
            ),
          );

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardLight,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.doctorName,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.specialization,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ],
        ),
        actions: [
          // Directions Button
          Consumer(
            builder: (context, ref, _) {
              return FutureBuilder(
                future: ref.read(getHospitalByIdProvider(widget.hospitalId).future),
                builder: (context, snapshot) {
                  return IconButton(
                    icon: Icon(Icons.directions, color: AppColors.primary),
                    onPressed: () async {
                      try {
                        final hospital = snapshot.data;
                        if (hospital != null && 
                            hospital.latitude != null && 
                            hospital.longitude != null) {
                          LocationService.openGoogleMaps(
                            latitude: hospital.latitude!,
                            longitude: hospital.longitude!,
                            locationName: hospital.name,
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hospital location not available'),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    tooltip: 'Get Directions',
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Doctor & Legend Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.cardLight,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  radius: 20,
                  child: Icon(Icons.medical_services, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select an Appointment Slot',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Available', style: TextStyle(fontSize: 11, color: AppColors.success)),
                          const SizedBox(width: 12),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Doctor Busy', style: TextStyle(fontSize: 11, color: AppColors.error)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Date Selector (Next 21 Days Rolling)
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const Text(
                      'Mon - Sat (Sundays Closed)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 86,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
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
                                content: Text('🏥 Hospital & OPD are closed on Sundays. Please choose Mon - Sat.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _selectedDate = date;
                            _selectedSlotId = null;
                          });
                        },
                        child: Container(
                          width: 72,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSun
                                  ? AppColors.borderLight
                                  : (isSelected
                                      ? AppColors.primary
                                      : AppColors.borderLight),
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            color: isSun
                                ? AppColors.surfaceLight.withOpacity(0.5)
                                : (isSelected
                                    ? AppColors.primary.withOpacity(0.12)
                                    : AppColors.surfaceLight),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
                                style: TextStyle(
                                  fontSize: 12,
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
                                date.day.toString(),
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
                              const SizedBox(height: 2),
                              Text(
                                isSun ? 'Closed' : '${date.month}/${date.day}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSun ? FontWeight.bold : FontWeight.normal,
                                  color: isSun ? AppColors.error : AppColors.textSecondaryLight,
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

          // Slots View
          Expanded(
            child: isDoctorAbsent
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 58, color: AppColors.error.withOpacity(0.8)),
                          const SizedBox(height: 14),
                          const Text(
                            'Doctor is Marked Absent',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.doctorName} has marked themselves absent on duty.\nAppointment booking is temporarily disabled.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : (isSunday
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 54, color: AppColors.error.withOpacity(0.8)),
                              const SizedBox(height: 14),
                              const Text(
                                'Hospital Closed on Sunday',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Doctors do not take appointments on Sundays.\nPlease pick a date from Monday to Saturday above.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : (slotsAsync?.when(
                      data: (slots) {
                        if (slots.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.schedule_outlined, size: 48, color: AppColors.borderLight),
                                const SizedBox(height: 12),
                                Text(
                                  'No slots scheduled for this date',
                                  style: TextStyle(
                                    color: AppColors.textSecondaryLight,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final availableCount = slots.where((s) => s.isAvailable).length;
                        final busyCount = slots.length - availableCount;

                        return Column(
                          children: [
                            // Availability Counter bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$availableCount Available Slots',
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (busyCount > 0)
                                    Text(
                                      '$busyCount Doctor Busy',
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 2.2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: slots.length,
                                itemBuilder: (context, index) {
                                  final slot = slots[index];
                                  final isSelected = _selectedSlotId == slot.id;
                                  final isBooked = !slot.isAvailable;

                                  return GestureDetector(
                                    onTap: isBooked
                                        ? () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('⚠️ Doctor is busy / already booked at this time. Please select another slot.'),
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          }
                                        : () {
                                            setState(() {
                                              _selectedSlotId = slot.id;
                                            });
                                          },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isBooked
                                              ? AppColors.error.withOpacity(0.4)
                                              : (isSelected
                                                  ? AppColors.primary
                                                  : AppColors.borderLight),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        color: isBooked
                                            ? AppColors.error.withOpacity(0.06)
                                            : (isSelected
                                                ? AppColors.primary.withOpacity(0.12)
                                                : AppColors.cardLight),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.primary.withOpacity(0.15),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                )
                                              ]
                                            : null,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isBooked
                                                ? Icons.do_not_disturb_on
                                                : (isSelected
                                                    ? Icons.check_circle
                                                    : Icons.access_time),
                                            size: 20,
                                            color: isBooked
                                                ? AppColors.error
                                                : (isSelected
                                                    ? AppColors.primary
                                                    : AppColors.textSecondaryLight),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  slot.time,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: isBooked
                                                        ? AppColors.error
                                                        : AppColors.textPrimaryLight,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isBooked
                                                        ? AppColors.error.withOpacity(0.15)
                                                        : AppColors.success.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    isBooked ? 'Doctor Busy' : 'Available',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: isBooked
                                                          ? AppColors.error
                                                          : AppColors.success,
                                                    ),
                                                  ),
                                                ),
                                              ],
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
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, st) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(
                              'Error loading slots: $error',
                              style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ) ??
                    const SizedBox.shrink()),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: (isDoctorAbsent || _selectedSlotId == null) ? null : _bookSlot,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.borderLight,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            isDoctorAbsent ? 'Doctor is Marked Absent' : 'Book Appointment',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _bookSlot() async {
    if (_selectedSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a slot')),
      );
      return;
    }

    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) throw Exception('User not authenticated');

      final slotsAsync = ref.read(
        getSlotsByDoctorAndDateProvider(
          (widget.hospitalId, widget.doctorId, _getDateString(_selectedDate)),
        ),
      );

      final slots = slotsAsync.value ?? [];
      final slot = slots.firstWhere((s) => s.id == _selectedSlotId);

      // Book the slot
      await ref.read(slotControllerProvider.notifier).bookSlot(
            _selectedSlotId!,
            widget.hospitalId,
            widget.doctorId,
            _getDateString(_selectedDate),
            user.uid,
          );

      // Create booking record
      final booking = Booking(
        userId: user.uid,
        hospitalId: widget.hospitalId,
        doctorId: widget.doctorId,
        slotId: _selectedSlotId!,
        date: _getDateString(_selectedDate),
        time: slot.time,
        createdAt: DateTime.now(),
      );

      await ref.read(bookingControllerProvider.notifier).createBooking(booking);

      // Invalidate slots cache to refresh and show the booked slot immediately
      ref.invalidate(
        getSlotsByDoctorAndDateProvider(
          (widget.hospitalId, widget.doctorId, _getDateString(_selectedDate)),
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Appointment booked! Details sent to your email'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Wait a moment for the cache to refresh before navigating
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
