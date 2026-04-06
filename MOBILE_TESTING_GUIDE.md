# 📱 Medilink Mobile App - Testing Guide

## 🎯 Current Version Features

### ✅ Implemented Features
- **User Authentication** - Registration & Login with role detection
- **Hospital Management** - Create & manage hospitals (admin only)
- **Doctor Management** - Add doctors with specializations (admin only)
- **Appointment Slots** - Auto-generated 7-day slot system
- **Appointment Booking** - Full booking workflow with slots
- **Booking Confirmation** - Hospital admin approval/rejection system 🆕
- **User Profiles** - Real data loading from Firebase 🆕
- **Professional UI Theme** - Medical-grade design with colors
- **Email Notifications** - Booking confirmations via EmailJS
- **My Bookings** - View appointment history with status

---

## 🧪 Testing Scenarios

### **Scenario 1: User Registration & Profile Setup**

**Steps:**
1. Launch app → **Register**
2. Email: `patient1@example.com`
3. Set password: `Test@123`
4. Agree to terms
5. Go to **My Account**
6. Click **Edit**
7. Fill all profile details:
   - Full Name: John Doe
   - Phone: +92-300-1234567
   - DOB: 01/01/1990
   - Gender: Male
   - Blood Group: O+
   - Address: Karachi, Pakistan
8. Click **Save** ✅

**Expected:** Profile data saved to Firebase

---

### **Scenario 2: Hospital Admin Setup**

**Steps:**
1. Register with admin email: `admin@hospital.com`
2. System automatically detects role (Hospital Admin)
3. See **Admin Dashboard**
4. Click **"+"** → **Add Hospital**
5. Fill details:
   - Hospital Name: City Medical Center
   - Address: 123 Main Street
   - Contact: +92-21-111-2222
   - Upload Photo (optional)
6. Add 2 Doctors:
   - **Doctor 1:** Dr. Ahmed (Cardiologist)
   - **Doctor 2:** Dr. Fatima (Pediatrician)
7. Click **Save**

**Expected:** Hospital with doctors visible in dashboard

---

### **Scenario 3: Book Appointment Flow (Patient)**

**Steps (as `patient1@example.com`):**
1. **Home Screen** → Browse hospitals
2. Tap on hospital → View doctors
3. Tap doctor → **Select Appointment**
4. Choose date (next 7 days)
5. Select time slot (30-min intervals)
6. Click **Book now**
7. Confirmation dialog appears

**Status:** 🟠 **"Waiting Approval"**

**Expected:** 
- Email sent to patient
- Email sent to doctor  
- Admin gets notification

---

### **Scenario 4: Hospital Admin Approval (NEW!)**

**Steps (as `admin@hospital.com`):**
1. Login as admin
2. **Admin Dashboard**
3. Click **"Pending Bookings"** tab
4. See pending bookings listed with:
   - Booking ID
   - Patient email
   - Doctor name
   - Date & time
5. Click **Approve** button

**Status:** 🟢 Updated to **"Confirmed"**

**Result:**
- Admin notification dismissed
- Patient gets approval notification
- Status visible in patient's bookings

---

### **Scenario 5: Patient Views My Bookings**

**Steps (as `patient1@example.com`):**
1. **Bottom Menu** → **My Bookings**
2. See booking with status

**Status Display:**
- 🟠 **Waiting Approval** (pending - hospital hasn't acted)
- 🟢 **Confirmed** (approved by hospital)
- 🔴 **Cancelled** (rejected by hospital)
- ✅ **Completed** (past appointment)

---

### **Scenario 6: Make Changes & Auto-Deploy**

**Steps (Dev):**
1. Make code changes locally
2. Commit & push to GitHub
3. Render detects changes
4. Auto-builds & deploys
5. App updates in 2-3 minutes

**Testing:**
- Visit `https://medilink-app.onrender.com`
- Verify changes live

---

## 📋 Test Credentials

### Hospital Admin
```
Email: test@hospital.com
Password: [Use your Firebase password]
Role: Hospital Admin (auto-detected by @hospital.com domain)

Can do:
✓ Create hospitals
✓ Add doctors
✓ Approve/Reject bookings
✓ View pending bookings
✓ See total bookings per doctor
```

### Normal User
```
Email: patient@example.com
Password: [Any password]
Role: Normal User (auto-detected by any other domain)

Can do:
✓ Browse hospitals
✓ View doctors
✓ Book appointments
✓ See booking status
✓ View appointment history
✓ Edit profile
```

---

## 🔄 Full Test Workflow (5-10 minutes)

**Time: ~8 minutes total**

1. **2 min** - Create hospital admin account
2. **2 min** - Create hospital + doctors
3. **2 min** - Create patient account
4. **2 min** - Book appointment as patient
5. **1 min** - Approve booking as admin
6. **1 min** - View updated status as patient

**Result:** Full cycle demonstrating all features

---

## ✅ Verification Checklist

### Account & Profile
- [ ] Registration works
- [ ] Login works for both roles
- [ ] Profile loads real data from Firebase
- [ ] Profile edits save correctly
- [ ] Admin vs User roles detected correctly

### Hospital & Doctor Management
- [ ] Admin can create hospital
- [ ] Admin can add multiple doctors
- [ ] Doctors appear in patient view
- [ ] Doctors have correct specializations

### Booking System
- [ ] Slots load correctly
- [ ] Booking saves to Firebase
- [ ] Initial status is "Pending" ✅ NEW
- [ ] Email notifications sent

### Confirmation System (NEW!)
- [ ] Admin sees pending bookings ✅ NEW
- [ ] Approve button works ✅ NEW
- [ ] Reject button works ✅ NEW
- [ ] Status updates patient view ✅ NEW

### Status Display (NEW!)
- [ ] Pending shows "⏳ Waiting Approval" ✅ NEW
- [ ] Confirmed shows "🟢 Confirmed" ✅ NEW
- [ ] Cancelled shows "🔴 Cancelled" ✅ NEW
- [ ] Color coding correct ✅ NEW

---

## 🚨 Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| Can't login | Check Firebase rules, verify email format |
| Booking fails | Check slots are available, verify date format |
| Admin panel empty | Ensure email ends with @hospital.com |
| Status not updating | Refresh app or pull down to refresh |
| Profile shows empty | Firebase write rules may need update |

---

## 📸 Key Screens to Test

1. **Login Screen** - Professional gradient design
2. **Home Screen (Patient)** - Hospital list
3. **Booking Screen** - Date & slot selection
4. **Admin Dashboard** - Hospital management + **NEW: Pending Bookings Tab** 🆕
5. **My Bookings** - Status display with colors 🆕
6. **My Account** - Real profile data 🆕

---

## 🎥 Demo Points

When testing, highlight:
- ✅ Smooth role-based routing
- ✅ Real-time status updates
- ✅ Professional medical UI
- ✅ **NEW: Pending confirmation workflow**
- ✅ **NEW: Admin approval system**
- ✅ **NEW: Real user profiles from Firebase**

---

## 📊 Performance Notes

- **Load Time:** ~2-3 seconds (first load)
- **Slot Loading:** Instant (cached)
- **Booking:** ~1-2 seconds
- **Status Update:** ~500ms after approval

---

**Last Updated:** April 6, 2026
**Status:** Ready for Production Testing 🚀
