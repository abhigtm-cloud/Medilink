import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/home/providers/slot_provider.dart';
import 'package:medilink/features/home/providers/booking_provider.dart';
import 'package:medilink/features/home/models/booking.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';

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
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.doctorName),
            Text(
              widget.specialization,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date Picker
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Date',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                                  ? const Color(0xFF20B2AA)
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected
                                ? const Color(0xFF20B2AA).withOpacity(0.1)
                                : Colors.white,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                date.day.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                                    [date.weekday - 1],
                                style: const TextStyle(fontSize: 12),
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
          const Divider(),

          // Slots
          Expanded(
            child: slotsAsync.when(
              data: (slots) {
                if (slots.isEmpty) {
                  return const Center(
                    child: Text('No slots available for this date'),
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
                                ? const Color(0xFF20B2AA)
                                : (isBooked
                                    ? Colors.red[300]!
                                    : Colors.grey[300]!),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isBooked
                              ? Colors.red[100]
                              : (isSelected
                                  ? const Color(0xFF20B2AA).withOpacity(0.1)
                                  : Colors.white),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                slot.time,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isBooked ? Colors.red : Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isBooked ? 'Booked' : 'Available',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isBooked ? Colors.red : Colors.green,
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
                child: Text('Error: $error'),
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
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Book Appointment'),
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
