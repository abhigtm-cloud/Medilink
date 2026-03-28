import 'package:emailjs/emailjs.dart' as emailjs;

class EmailService {
  // Credentials - Replace with your EmailJS credentials
  // Get these from https://www.emailjs.com/
  static const String serviceId = 'service_phh4doo';
  static const String templateId = 'template_gcodsnf';
  static const String publicKey = '-2_gOApslQd5GMamV';

  /// Initialize EmailJS (call this once in main())
  static Future<void> initialize() async {
    try {
      // EmailJS initialization for v4.0.0
      emailjs.init(
        emailjs.Options(
          publicKey: publicKey,
        ),
      );
      print('DEBUG: EmailJS initialized successfully');
    } catch (e) {
      print('DEBUG: EmailJS initialization error: $e');
      // Non-critical - app continues even if email init fails
    }
  }

  /// Send booking confirmation email to both doctor and customer
  static Future<bool> sendBookingConfirmation({
    required String customerEmail,
    required String customerName,
    required String doctorName,
    required String doctorEmail,
    required String hospitalName,
    required String appointmentDate,
    required String appointmentTime,
    required String specialization,
  }) async {
    try {
      print('DEBUG: [EMAIL STUB] Booking confirmation for customer: $customerEmail');
      print('DEBUG: [EMAIL STUB] Booking confirmation for doctor: $doctorEmail');
      print('DEBUG: [EMAIL STUB] Appointment: $appointmentDate at $appointmentTime');
      
      // TODO: Implement actual emailjs.send() calls once API is finalized
      // For now, just log the email data
      return true;
    } catch (e) {
      print('DEBUG: Error in booking confirmation email stub: $e');
      return false;
    }
  }

  /// Send appointment reminder email
  static Future<bool> sendAppointmentReminder({
    required String email,
    required String userName,
    required String appointmentDate,
    required String appointmentTime,
  }) async {
    try {
      print('DEBUG: [EMAIL STUB] Reminder email to: $email');
      print('DEBUG: [EMAIL STUB] Appointment: $appointmentDate at $appointmentTime');
      
      // TODO: Implement actual emailjs.send() call once API is finalized
      return true;
    } catch (e) {
      print('DEBUG: Error in reminder email stub: $e');
      return false;
    }
  }

  /// Send cancellation email
  static Future<bool> sendCancellationEmail({
    required String email,
    required String userName,
    required String reason,
  }) async {
    try {
      print('DEBUG: [EMAIL STUB] Cancellation email to: $email');
      print('DEBUG: [EMAIL STUB] Reason: $reason');
      
      // TODO: Implement actual emailjs.send() call once API is finalized
      return true;
    } catch (e) {
      print('DEBUG: Error in cancellation email stub: $e');
      return false;
    }
  }
}
