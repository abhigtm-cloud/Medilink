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
      await emailjs.init(
        publicKey: publicKey,
      );
      print('DEBUG: EmailJS initialized successfully');
    } catch (e) {
      print('DEBUG: EmailJS initialization error: $e');
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
      // Email to Customer
      await emailjs.send(
        serviceId,
        templateId,
        {
          'to_email': customerEmail,
          'customer_name': customerName,
          'doctor_name': doctorName,
          'hospital_name': hospitalName,
          'appointment_date': appointmentDate,
          'appointment_time': appointmentTime,
          'specialization': specialization,
          'email_type': 'customer',
        },
      );
      print('DEBUG: Booking confirmation sent to customer: $customerEmail');

      // Email to Doctor
      await emailjs.send(
        serviceId,
        templateId,
        {
          'to_email': doctorEmail,
          'customer_name': customerName,
          'doctor_name': doctorName,
          'hospital_name': hospitalName,
          'appointment_date': appointmentDate,
          'appointment_time': appointmentTime,
          'specialization': specialization,
          'email_type': 'doctor',
        },
      );
      print('DEBUG: Booking confirmation sent to doctor: $doctorEmail');

      return true;
    } catch (e) {
      print('DEBUG: Error sending booking confirmation email: $e');
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
      await emailjs.send(
        serviceId,
        'reminder_template', // Different template for reminders
        {
          'to_email': email,
          'user_name': userName,
          'appointment_date': appointmentDate,
          'appointment_time': appointmentTime,
        },
      );
      print('DEBUG: Reminder email sent to: $email');
      return true;
    } catch (e) {
      print('DEBUG: Error sending reminder email: $e');
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
      await emailjs.send(
        serviceId,
        'cancellation_template', // Different template for cancellations
        {
          'to_email': email,
          'user_name': userName,
          'reason': reason,
        },
      );
      print('DEBUG: Cancellation email sent to: $email');
      return true;
    } catch (e) {
      print('DEBUG: Error sending cancellation email: $e');
      return false;
    }
  }
}
