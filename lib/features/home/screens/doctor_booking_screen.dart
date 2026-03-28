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
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(
      getSlotsByDoctorAndDateProvider(
        (widget.hospitalId, widget.doctorId, _getDateString(_selectedDate)),
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
              return IconButton(
                icon: Icon(Icons.directions, color: AppColors.primary),
                onPressed: () async {
                  try {
                    final hospitalAsync = ref.read(
                      getHospitalByIdProvider(widget.hospitalId),
                    );
                    hospitalAsync.whenData((hospital) {
                      if (hospital != null && 
                          hospital.latitude != null && 
                          hospital.longitude != null) {
                        LocationService.openGoogleMaps(
                          latitude: hospital.latitude!,
                          longitude: hospital.longitude!,
                          locationName: hospital.name,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hospital location not available'),
                          ),
                        );
                      }
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                tooltip: 'Get Directions',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Picker
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Date',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final date = DateTime.now().add(Duration(days: index));
                      final isSelected = _getDateString(date) ==
                          _getDateString(_selectedDate);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                            _selectedSlotId = null;
                          });
                        },
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.borderLight,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.surfaceLight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                date.day.toString(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                                    [date.weekday - 1],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight,
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
          Divider(color: AppColors.borderLight),

          // Slots
          Expanded(
            child: slotsAsync.when(
              data: (slots) {
                if (slots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule_outlined, size: 48, color: AppColors.borderLight),
                        const SizedBox(height: 12),
                        Text(
                          'No slots available for this date',
                          style: TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
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
                          ? null
                          : () {
                              setState(() {
                                _selectedSlotId = slot.id;
                              });
                            },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isBooked
                                    ? AppColors.error
                                    : AppColors.borderLight),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isBooked
                              ? AppColors.error.withOpacity(0.1)
                              : (isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : AppColors.surfaceLight),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                slot.time,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isBooked
                                      ? AppColors.error
                                      : AppColors.textPrimaryLight,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isBooked ? 'Booked' : 'Available',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isBooked
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
                      'Error loading slots',
                      style: TextStyle(
                        color: AppColors.textPrimaryLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error: $error',
                      style: TextStyle(
                        color: AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _selectedSlotId == null ? null : _bookSlot,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.borderLight,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Book Appointment',
            style: TextStyle(
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

      final slotsAsync = ref.watch(
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
        const SnackBar(content: Text('Appointment booked successfully!')),
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
