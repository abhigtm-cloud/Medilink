# EmailJS Debugging Checklist for MediLink

## 🔍 Quick Diagnosis

Before booking an appointment, run through this checklist:

---

## **Step 1: Verify EmailJS Credentials in Code**

File: `lib/core/services/email_service.dart`

```dart
static const String serviceId = 'service_phh4doo';
static const String templateId = 'template_gcodsnf';
static const String publicKey = '-2_gOApslQd5GMamV';
```

**❓ What to check:**
- [ ] Service ID starts with `service_`
- [ ] Template ID starts with `template_`
- [ ] Public Key is present (not empty)
- [ ] No extra spaces or special characters

---

## **Step 2: Check EmailJS Dashboard**

Go to **https://dashboard.emailjs.com/** and login:

**Check 1: Service Connection**
- [ ] Go to **Email Services**
- [ ] Is **Gmail** showing as "✓ Connected"?
- [ ] If NO: Click Gmail → Authorize again and wait 30 seconds

**Check 2: Verify Service ID**
- [ ] Service name and ID match your code
- [ ] Example: If code has `service_phh4doo`, this should exist in your services list

**Check 3: Verify Template**
- [ ] Go to **Email Templates**
- [ ] Template `template_gcodsnf` exists
- [ ] Template is **Active** (not draft/archived)
- [ ] Template body contains: `{{to_email}}`, `{{doctor_name}}`, `{{appointment_date}}`, etc.

**Check 4: Account Status**
- [ ] Go to **Account → Billing**
- [ ] Free plan shows "200 emails/month remaining"
- [ ] Not exceeded monthly limit

---

## **Step 3: Check Your Gmail Account**

1. Open **https://mail.google.com/**
2. Login with the Gmail account you authorized in EmailJS
3. Look for emails from:
   - Inbox (most recent)
   - Spam folder
   - Promotions tab
4. **If emails are in Spam:**
   - Mark as "Not Spam"
   - Add `noreply@emailjs.com` to your contacts

---

## **Step 4: Check Gmail Security Settings**

For Gmail to allow EmailJS:

1. Go to **https://myaccount.google.com/security**
2. Scroll to **How you sign in to Google**
3. **If you use 2-factor authentication:**
   - Go to **App passwords** (if available)
   - Create app password for "Mail" on "Windows Computer"
   - Use this password in EmailJS instead of your Gmail password
4. **If no 2-factor:**
   - Go to **Less secure app access**
   - Enable "Turn on access to less secure apps"

---

## **Step 5: Run the App and Book an Appointment**

1. Run: `flutter run`
2. Choose a doctor and book appointment
3. Open Android Studio logcat: `flutter logs`
4. **Look for these messages:**

✅ **Success indicators:**
```
DEBUG: EmailJS initialized successfully
DEBUG: Customer confirmation email sent to: user@gmail.com
DEBUG: Doctor confirmation email sent to: doctor@gmail.com
DEBUG: Booking confirmation email sent successfully
```

❌ **Error indicators:**
```
DEBUG: EmailJS initialization error: [Error message]
DEBUG: Error in booking confirmation email: [Error message]
```

---

## **Step 6: Identify the Problem**

### **Scenario A: "EmailJS initialization error"**
- [ ] Public Key might be wrong
- [ ] Go back to EmailJS Dashboard → Account → Copy Public Key again
- [ ] Update `email_service.dart` with new public key
- [ ] Rebuild app: `flutter clean && flutter pub get && flutter run`

### **Scenario B: "Token invalid" or "Service not found"**
- [ ] Service ID might be wrong
- [ ] Go to EmailJS Dashboard → Email Services
- [ ] Copy the exact Service ID (starts with `service_`)
- [ ] Update code and rebuild

### **Scenario C: "Template not found"**
- [ ] Template ID wrong or template is archived
- [ ] Go to EmailJS Dashboard → Email Templates
- [ ] Verify template `template_gcodsnf` exists and is "Active"
- [ ] Copy exact Template ID to code

### **Scenario D: "Gmail not connected" error**
- [ ] EmailJS can't send from your Gmail account
- [ ] Go to EmailJS → Email Services → Gmail
- [ ] Click "Connect Gmail Account" again
- [ ] Re-authorize and wait 1 minute

### **Scenario E: Email sent but NOT in inbox**
- [ ] Email sent successfully but going to spam
- [ ] Check: Gmail → Spam folder
- [ ] Mark as "Not Spam"
- [ ] Next email should go to inbox
- [ ] Add EmailJS to your contacts

---

## **🧪 Manual Test (Advanced)**

If booking an appointment doesn't work, test EmailJS directly:

### **From Flutter Console (pub dev test)**

Create a test file: `test/email_test.dart`

```dart
import 'package:emailjs/emailjs.dart' as emailjs;

void main() async {
  // Initialize
  emailjs.init(
    emailjs.Options(
      publicKey: '-2_gOApslQd5GMamV',
    ),
  );

  // Send test email
  try {
    await emailjs.send(
      'service_phh4doo',
      'template_gcodsnf',
      {
        'to_email': 'your.email@gmail.com',
        'to_name': 'Test User',
        'subject': 'EmailJS Test',
        'doctor_name': 'Dr. Test',
        'doctor_specialization': 'Testing',
        'hospital_name': 'Test Hospital',
        'appointment_date': '2026-04-15',
        'appointment_time': '10:00 AM',
        'message': 'This is a test email from EmailJS',
      },
      const emailjs.Options(
        publicKey: '-2_gOApslQd5GMamV',
      ),
    );
    print('✅ Test email sent successfully!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

Run: `dart test/email_test.dart`

---

## **📋 Email Template Checklist**

Your EmailJS template MUST have these variables:

**Required fields in HTML:**
- `{{to_email}}` - Recipient email
- `{{to_name}}` - Recipient name
- `{{doctor_name}}` - Doctor's name
- `{{doctor_specialization}}` - Doctor's specialty
- `{{hospital_name}}` - Hospital name
- `{{appointment_date}}` - Date (YYYY-MM-DD)
- `{{appointment_time}}` - Time (HH:MM AM/PM)
- `{{message}}` - Custom message

**Example template HTML:**
```html
<h2>Hello {{to_name}},</h2>

<p>Your appointment has been confirmed!</p>

<p><strong>Appointment Details:</strong></p>
<ul>
  <li>Doctor: {{doctor_name}} ({{doctor_specialization}})</li>
  <li>Hospital: {{hospital_name}}</li>
  <li>Date: {{appointment_date}}</li>
  <li>Time: {{appointment_time}}</li>
</ul>

<p>{{message}}</p>

<p>Thank you for using Medilink!</p>
```

---

## **✅ Validation Checklist - Run This**

Before reporting the issue as "not working":

- [ ] EmailJS account created and logged in
- [ ] Gmail service connected (shows ✓)
- [ ] Email template is "Active" (not archived)
- [ ] Service ID, Template ID, Public Key match your code exactly
- [ ] Gmail account has "Less secure app access" enabled OR "App password" set up
- [ ] Rebuilt app after any code changes: `flutter clean && flutter pub get && flutter run`
- [ ] Booked appointment and checked logcat for debug messages
- [ ] Checked Gmail spam folder
- [ ] Waited 30+ seconds for email to arrive
- [ ] Verified doctor has email address in their profile

---

## **🚀 If Everything Passes the Checklist**

Your email should be working! If still failing:

1. **Screenshot the error message** from logcat
2. **Copy these details from EmailJS Dashboard:**
   - Service ID (redacted)
   - Template ID (redacted)
   - Public Key (first 10 chars + `...`)
3. **Check EmailJS Email Logs:**
   - Go to Email Services → Your Gmail Service
   - Click "Logs" tab
   - See if email is being recorded as sent

---

## **📞 Alternative: If EmailJS Fails**

If you can't get EmailJS working, we can switch to:

1. **Firebase Cloud Functions** - Send emails directly from backend
2. **Resend.dev** - Modern email API (very reliable)
3. **Supabase** - Built-in email support with free tier
4. **SendGrid** - Industry standard (free credits for startups)

We can implement any of these as alternatives.

---

## **Debug Output Example**

**When booking works perfectly:**
```
I/flutter ( 1234): DEBUG: EmailJS initialized successfully
I/flutter ( 1234): DEBUG: Email service initialized
I/flutter ( 1234): Loading slots for 2026-04-15...
I/flutter ( 1234): Selected slot: slot_007
I/flutter ( 1234): Booked successfully!
I/flutter ( 1234): DEBUG: Customer confirmation email sent to: user@gmail.com
I/flutter ( 1234): DEBUG: Doctor confirmation email sent to: doctor@email.com
I/flutter ( 1234): DEBUG: Booking confirmation email sent successfully
✅ Success! Check your Gmail inbox in 5 seconds
```

**When there's an email issue:**
```
I/flutter ( 1234): DEBUG: Error in booking confirmation email: [ErrorType] Message here
I/flutter ( 1234): DEBUG: Booking confirmation email sent successfully  ← Misleading!
```

Check logs carefully!

---

## **Quick Reference - Credentials Location**

| Item | Location | How to Find |
|------|----------|------------|
| Service ID | `email_service.dart` line ~6 | EmailJS Dashboard → Email Services |
| Template ID | `email_service.dart` line ~7 | EmailJS Dashboard → Email Templates |
| Public Key | `email_service.dart` line ~8 | EmailJS Dashboard → Account |
| Gmail | EmailJS → Email Services | Must show "Connected" ✓ |
| Template Variables | EmailJS Dashboard → Template Body | Must include `{{variable_name}}` |

---

## **Next Steps**

1. Go through checklist above ☝️
2. Run app and check logcat for errors
3. Test booking and verify email arrives
4. If still failing → Share error message + screenshot
5. We'll debug from there!
