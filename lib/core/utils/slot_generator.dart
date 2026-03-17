import 'package:medilink/features/home/models/slot.dart';

/// Utility class for generating time slots
class SlotGenerator {
  /// Generates time slots based on doctor's schedule
  /// 
  /// Parameters:
  /// - doctorId: ID of the doctor
  /// - hospitalId: ID of the hospital
  /// - date: Date in format "yyyy-MM-dd"
  /// - startTime: Start time in format "HH:mm" (24-hour)
  /// - endTime: End time in format "HH:mm" (24-hour)
  /// - durationMinutes: Duration of each slot in minutes
  static List<Slot> generateSlots({
    required String doctorId,
    required String hospitalId,
    required String date,
    required String startTime,
    required String endTime,
    required int durationMinutes,
  }) {
    final slots = <Slot>[];
    
    try {
      // Parse times
      final start = _parseTime(startTime);
      final end = _parseTime(endTime);
      
      if (start == null || end == null) {
        return slots;
      }
      
      var currentTime = start;
      
      while (currentTime.add(Duration(minutes: durationMinutes)).isBefore(end) ||
             currentTime.add(Duration(minutes: durationMinutes)) == end) {
        final slotEnd = currentTime.add(Duration(minutes: durationMinutes));
        
        final slotTime = '${_formatTime(currentTime)} - ${_formatTime(slotEnd)}';
        
        slots.add(
          Slot(
            doctorId: doctorId,
            hospitalId: hospitalId,
            date: date,
            time: slotTime,
            bookedBy: null,
          ),
        );
        
        currentTime = slotEnd;
      }
    } catch (e) {
      print('Error generating slots: $e');
    }
    
    return slots;
  }
  
  /// Parses time string in format "HH:mm" to DateTime
  static DateTime? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;
      
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      
      return DateTime(2024, 1, 1, hours, minutes);
    } catch (e) {
      print('Error parsing time: $e');
      return null;
    }
  }
  
  /// Formats DateTime to "HH:mm" string
  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
