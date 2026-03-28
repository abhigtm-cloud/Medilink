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
      // Email to customer with doctor details
      final customerEmailParams = {
        'to_email': customerEmail,
        'to_name': customerName,
        'subject': 'Appointment Confirmation - Medilink',
        'doctor_name': doctorName,
        'doctor_specialization': specialization,
        'hospital_name': hospitalName,
        'appointment_date': appointmentDate,
        'appointment_time': appointmentTime,
        'message': 'Your appointment has been confirmed with Dr. $doctorName ($specialization) at $hospitalName on $appointmentDate at $appointmentTime. Please arrive 10 minutes early.',
      };

      await emailjs.send(
        serviceId,
        templateId,
        customerEmailParams,
        const emailjs.Options(
          publicKey: publicKey,
        ),
      );

      print('DEBUG: Customer confirmation email sent to: $customerEmail');

      // Email to doctor with patient details
      final doctorEmailParams = {
        'to_email': doctorEmail,
        'to_name': doctorName,
        'subject': 'New Appointment Booked - Medilink',
        'patient_name': customerName,
        'patient_email': customerEmail,
        'hospital_name': hospitalName,
        'appointment_date': appointmentDate,
        'appointment_time': appointmentTime,
        'message': 'A new appointment has been booked with patient $customerName on $appointmentDate at $appointmentTime at $hospitalName.',
      };

      await emailjs.send(
        serviceId,
        templateId,
        doctorEmailParams,
        const emailjs.Options(
          publicKey: publicKey,
        ),
      );

      print('DEBUG: Doctor confirmation email sent to: $doctorEmail');
      return true;
    } catch (e) {
      print('DEBUG: Error in booking confirmation email: $e');
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
      final reminderParams = {
        'to_email': email,
        'to_name': userName,
        'subject': 'Appointment Reminder - Medilink',
        'appointment_date': appointmentDate,
        'appointment_time': appointmentTime,
        'message': 'Reminder: You have an appointment on $appointmentDate at $appointmentTime. Please arrive 10 minutes early.',
      };

      await emailjs.send(
        serviceId,
        templateId,
        reminderParams,
        const emailjs.Options(
          publicKey: publicKey,
        ),
      );

      print('DEBUG: Reminder email sent to: $email');
      return true;
    } catch (e) {
      print('DEBUG: Error in reminder email: $e');
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
      final cancellationParams = {
        'to_email': email,
        'to_name': userName,
        'subject': 'Appointment Cancelled - Medilink',
        'reason': reason,
        'message': 'Your appointment has been cancelled. Reason: $reason. If you have any questions, please contact our support team.',
      };

      await emailjs.send(
        serviceId,
        templateId,
        cancellationParams,
        const emailjs.Options(
          publicKey: publicKey,
        ),
      );

      print('DEBUG: Cancellation email sent to: $email');
      return true;
    } catch (e) {
      print('DEBUG: Error in cancellation email: $e');
      return false;
    }
  }
}
