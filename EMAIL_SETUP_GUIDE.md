# EmailJS Setup Guide for MediLink

## Step 1: Create EmailJS Account

1. Go to **https://www.emailjs.com/**
2. Click **Sign Up** (free plan available)
3. Verify your email address
4. Login to your account

---

## Step 2: Get Your Credentials

1. **Go to Admin Dashboard** → **Account Settings**
2. Copy your **Public Key** (you'll need this)
3. Go to **Email Services** → Click **Gmail** or your email provider
4. Create a new service:
   - Service Name: `gmail_service` (or any name)
   - Gmail Address: Your Gmail address
   - Click **Connect Gmail Account**
   - Authorize EmailJS to send from your Gmail
5. **Copy the Service ID** (looks like `service_xxxxx`)

---

## Step 3: Create Email Template

1. Go to **Email Templates**
2. Click **Create New Template**
3. Template Name: `booking_confirmation` (or any name)
4. Subject: `Appointment Confirmation - {{subject}}`
5. In the email body, use these variables:
```
Dear {{to_name}},

Your appointment has been confirmed!

Details:
- Doctor: {{doctor_name}} ({{doctor_specialization}})
- Hospital: {{hospital_name}}
- Date: {{appointment_date}}
- Time: {{appointment_time}}
- Patient/Doctor: {{patient_name}} / {{patient_email}}

{{message}}

Thank you for using Medilink!
```

6. Click **Create**
7. **Copy the Template ID** (looks like `template_xxxxx`)

---

## Step 4: Update MediLink Code

Open: `lib/core/services/email_service.dart`

Replace these lines with YOUR credentials:

```dart
static const String serviceId = 'service_YOUR_SERVICE_ID_HERE';
static const String templateId = 'template_YOUR_TEMPLATE_ID_HERE';
static const String publicKey = 'YOUR_PUBLIC_KEY_HERE';
```

**Example:**
```dart
static const String serviceId = 'service_abc123xyz';
static const String templateId = 'template_def456uid';
static const String publicKey = 'pqr789stuvwxyz-public-key';
```

---

## Step 5: Test the Setup

1. Run: `flutter run`
2. Try booking an appointment
3. **Check your Gmail inbox** (and Spam folder)
4. You should receive the confirmation email within 5-10 seconds

---

## Troubleshooting

### ❌ No Email Received

**Check 1: Is EmailJS initialized?**
- Run app and check console logs for: `DEBUG: EmailJS initialized successfully`
- If NOT showing, EmailJS failed to initialize

**Check 2: Are credentials correct?**
- Go back to EmailJS Dashboard and verify Service ID, Template ID, and Public Key
- Make sure they're copied exactly (no extra spaces)

**Check 3: Is Gmail account connected?**
- Go to EmailJS → Email Services → Check if Gmail shows as "Connected"
- If not connected, click Gmail and authorize again

**Check 4: Gmail security**
- EmailJS needs permission to send from your Gmail
- Check your Gmail → Account → Less secure app access (or generate App Password)
- Some accounts may need this enabled

**Check 5: Check EmailJS console logs**
```
Email service: ✓ Connected
Template: ✓ Active
Emails sent/month: Check limit (free = 200/month)
```

### 📧 Email sent to wrong address

- Check: Is the user's email saved correctly in their profile?
- User must have a valid email in Firebase for booking confirmation to work

### 🚫 "Token invalid" Error

- Your Public Key might be wrong
- Copy it again from EmailJS Dashboard
- Make sure there are no extra spaces or characters

---

## Step 6: Deploy to Production

After testing locally:

```bash
flutter build apk --release
git add -A
git commit -m "Add EmailJS credentials for production"
git push origin main
```

Download the APK and test on a real device to ensure emails work.

---

## Email Variables Reference

When booking, these variables are passed to EmailJS:

| Variable | Example |
|----------|---------|
| `to_email` | user@gmail.com |
| `to_name` | John Doe |
| `doctor_name` | Dr. Sharma |
| `doctor_specialization` | Cardiologist |
| `hospital_name` | City Medical Hospital |
| `appointment_date` | 2026-04-15 |
| `appointment_time` | 10:30 AM |
| `patient_name` | Patient Name |
| `patient_email` | patient@gmail.com |
| `message` | Custom message |

Make sure your EmailJS template includes these variables with `{{variable_name}}` format.

---

## Notes

- **Free plan**: 200 emails/month (enough for testing)
- **Paid plans**: Unlimited emails
- **Gmail limit**: ~500 emails/day (EmailJS respects this)
- **Delivery time**: Usually 1-5 seconds
- **Spam folder**: Sometimes emails go to spam initially (add to contacts to fix)

---

## Support

If emails still don't work:

1. Check console logs for specific error messages
2. Verify credentials in EmailJS Dashboard
3. Test direct EmailJS API from their website
4. Check Gmail spam/promotions folder
5. Verify user email is correct in Firebase

**Debug Command** (run in app):
```dart
// This will print your EmailJS configuration (hide public key!)
print('Service: $serviceId');
print('Template: $templateId');
print('Public Key: ${publicKey.substring(0, 10)}...');
```
