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

  /// DEBUGGING FUNCTION - Send a test email to verify EmailJS setup
  /// Call this from anywhere in the app to test email functionality:
  /// 
  /// Usage in console: 
  /// await EmailService.sendTestEmail('your.email@gmail.com');
  /// 
  /// Or in a button in your UI to trigger this function
  static Future<bool> sendTestEmail(String recipientEmail) async {
    print('🧪 TEST EMAIL: Starting test email to $recipientEmail');
    print('📋 Using credentials:');
    print('   Service ID: $serviceId');
    print('   Template ID: $templateId');
    print('   Public Key: ${publicKey.substring(0, 10)}...');
    
    try {
      final testParams = {
        'to_email': recipientEmail,
        'to_name': 'Test User',
        'subject': 'Medilink - Test Email',
        'doctor_name': 'Dr. Test',
        'doctor_specialization': 'General Practitioner',
        'hospital_name': 'Test Hospital',
        'appointment_date': '2026-04-20',
        'appointment_time': '10:00 AM',
        'patient_name': 'Test Patient',
        'patient_email': recipientEmail,
        'message': 'This is a test email to verify EmailJS is working correctly with Medilink. If you received this, EmailJS is properly configured!',
      };

      print('📤 Sending test email with parameters:');
      testParams.forEach((key, value) {
        if (key != 'to_email') {
          print('   $key: $value');
        }
      });

      await emailjs.send(
        serviceId,
        templateId,
        testParams,
        const emailjs.Options(
          publicKey: publicKey,
        ),
      );

      print('✅ TEST EMAIL: Sent successfully!');
      print('⏱️  Check your inbox and spam folder within 5-10 seconds');
      return true;
    } catch (e) {
      print('❌ TEST EMAIL: Failed with error');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      
      // Helpful debugging suggestions
      if (e.toString().contains('invalid') || e.toString().contains('unauthorized')) {
        print('💡 Hint: Check if Service ID, Template ID, or Public Key is correct');
      } else if (e.toString().contains('not found') || e.toString().contains('404')) {
        print('💡 Hint: Service or Template may not exist or be archived');
      } else if (e.toString().contains('Gmail')) {
        print('💡 Hint: Gmail account not connected in EmailJS dashboard');
      }
      
      return false;
    }
  }

  /// DEBUGGING FUNCTION - Get current EmailJS configuration
  /// Prints sanitized credentials (hides sensitive parts)
  static void printConfiguration() {
    print('📋 Current EmailJS Configuration:');
    print('========================================');
    print('Service ID: ${serviceId.substring(0, 10)}...');
    print('Template ID: ${templateId.substring(0, 10)}...');
    print('Public Key: ${publicKey.substring(0, 10)}...');
    print('========================================');
    print('✅ If these are blank or show "service_", "template_", "Key..."');
    print('   then credentials are properly set in email_service.dart');
  }
}
