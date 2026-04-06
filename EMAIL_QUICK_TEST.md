# 📧 EmailJS Quick Test Guide - MediLink

## ⚡ 30-Second Test

Want to quickly verify if EmailJS works? Follow these steps:

---

## **Step 1: Open Flutter Console**

Run your app:
```bash
flutter run
```

Keep terminal open where you can see debug logs.

---

## **Step 2: Add a Debug Button (Temporary)**

Add this button to any screen (like home screen or settings):

**File:** `lib/features/home/screens/home_screen.dart` (or any screen.dart)

Find the `build()` method and add this button (in your FloatingActionButton or debug section):

```dart
// Add this import at top of file:
import 'package:medilink/core/services/email_service.dart';

// In your FloatingActionButton or in a test section:
FloatingActionButton(
  onPressed: () async {
    EmailService.printConfiguration();  // Shows current settings
    final result = await EmailService.sendTestEmail('your.gmail@gmail.com');
    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Test email sent! Check inbox')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Test email failed - check logs')),
      );
    }
  },
  child: const Icon(Icons.mail),
  tooltip: 'Test Email',
)
```

Or add a simple debug button in a test screen.

---

## **Step 3: Run and Test**

1. **Rebuild app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Look for this in your console output:**
   ```
   📋 Current EmailJS Configuration:
   ========================================
   Service ID: service_ph...
   Template ID: template_gc...
   Public Key: -2_gOAp...
   ========================================
   ```

   If you see blank or just `service_` / `template_` → Credentials are wrong

3. **Click the debug button** (or trigger `sendTestEmail()`)

4. **Watch console for messages:**
   
   ✅ **Success:**
   ```
   🧪 TEST EMAIL: Starting test email to your.email@gmail.com
   📤 Sending test email with parameters:
      doctor_name: Dr. Test
      appointment_date: 2026-04-20
      ...
   ✅ TEST EMAIL: Sent successfully!
   ⏱️  Check your inbox and spam folder within 5-10 seconds
   ```

   ❌ **Failure:**
   ```
   ❌ TEST EMAIL: Failed with error
   Error type: SocketException
   Error message: [Details here]
   💡 Hint: Check if Service ID, Template ID, or Public Key is correct
   ```

---

## **Step 4: Check Email**

1. Open **Gmail** at https://mail.google.com/
2. Look for email from `noreply@emailjs.com`
3. Check these places:
   - Inbox (most recent at top)
   - Spam folder
   - Promotions tab
   - Other/More tabs

---

## **📊 Expected Results**

| Scenario | Console Output | Email | Action |
|----------|---|---|---|
| ✅ Working | `✅ TEST EMAIL: Sent successfully!` | Arrives in 5 sec | Success! Ship it |
| ❌ Wrong creds | `Error type: SocketException` | Nothing | Update Service/Template IDs |
| ❌ Gmail not connected | `Gmail Error` or timeout | Nothing | Go to EmailJS → Connect Gmail |
| ❌ Template archived | `404 not found` | Nothing | Go to EmailJS → Activate template |
| ✅ Sent but spam | `✅ Sent successfully!` | In Spam folder | Mark as "Not Spam" |

---

## **🔧 Real Booking Test**

Once test email works:

1. Go to home screen
2. Select a hospital
3. Select a doctor
4. Pick a date and time slot
5. Click "Book Appointment"
6. **Watch console** for:
   ```
   DEBUG: Customer confirmation email sent to: user@gmail.com
   DEBUG: Doctor confirmation email sent to: doctor@gmail.com
   ```
7. **Check Gmail** - you should get 2 emails:
   - One for the patient (you)
   - One for the doctor (should go to doctor's email if available)

---

## **🚀 Console Commands (Advanced)**

If you have access to Dart console/debugger, you can run:

```dart
// Test EmailJS is initialized
EmailService.printConfiguration();

// Send test email
await EmailService.sendTestEmail('your.gmail@gmail.com');

// Or trigger full booking email
await EmailService.sendBookingConfirmation(
  customerEmail: 'patient@gmail.com',
  customerName: 'Patient Name',
  doctorName: 'Dr. Smith',
  doctorEmail: 'doctor@gmail.com',
  hospitalName: 'City Hospital',
  appointmentDate: '2026-04-20',
  appointmentTime: '10:00 AM',
  specialization: 'Cardiologist',
);
```

---

## **❓ Common Issues**

### **Issue: Console shows sanitized credentials (like `service_ph...`)**
✅ This is NORMAL and GOOD - means credentials are safely stored

### **Issue: Test email sent successfully but not in inbox**
- Check Spam folder and mark as "Not Spam"
- Add `noreply@emailjs.com` to contacts
- Wait 10 seconds and refresh Gmail

### **Issue: Error contains "invalid public key"**
- Go to EmailJS Dashboard
- Copy Public Key again (exact copy)
- Update `email_service.dart` line 8
- Rebuild: `flutter clean && flutter pub get && flutter run`

### **Issue: Error contains "service not found"**
- Check Service ID in EmailJS (should start with `service_`)
- Verify it exists in Email Services list
- Copy exact ID to code

### **Issue: Timeout error after 30 seconds**
- Gmail account may not be connected
- Go to EmailJS Dashboard → Email Services
- Click Gmail service
- Click "Re-authorize" 
- Wait 1 minute after authorizing

---

## **✅ Success Indicators**

You'll know it's working when:

1. ✅ Test email arrives within 5 seconds
2. ✅ Console shows `✅ TEST EMAIL: Sent successfully!`
3. ✅ Booking confirmation emails visible in both patient & doctor inboxes
4. ✅ No "authentication" or "timeout" errors in logs

---

## **📞 If Still Not Working**

1. **Take a screenshot** of the console error message
2. **Copy these details:**
   - Error type (e.g., SocketException, Authentication Error)
   - Full error message
   - What you did before the error (booking, test email, etc.)
3. **Check:**
   - [ ] Gmail connected in EmailJS dashboard? (Shows ✓)
   - [ ] Service ID and Template ID exist?
   - [ ] Did you rebuild after changing credentials?
   - [ ] Is your Gmail account the same one authorized in EmailJS?

---

## **🎯 Next Steps**

### If test email works (✅):
```bash
# Build APK with working email
flutter build apk --release

# Test on real device
# Deploy to production
```

### If test email fails (❌):
1. Review checklist in `EMAIL_DEBUGGING_CHECKLIST.md`
2. Try different Email Service in EmailJS (e.g., SendGrid, Resend)
3. Or we implement alternative (Firebase Cloud Functions)

---

## **⏱️ Timeline**

```
0s:  Click "Test Email" button
5s:  Email should arrive
15s: Check console for ✅ or ❌ message
30s: If ❌, review error message
60s: Apply fix (usually credential update)
120s: Retry test
```

Good luck! 🚀
