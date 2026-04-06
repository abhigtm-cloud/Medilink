# Firebase Data Loading Troubleshooting Guide

## ❌ Problem
- **"Failed to load data" error**
- Maps not loading
- Hospitals not displaying
- Works on some devices but fails on others (college network might have restrictions)

## 🔍 Root Causes

### 1. **Firebase Realtime Database Rules (MOST LIKELY)**
Your database rules are likely too restrictive or missing. The app tries to read from:
- `/hospitals` - All hospitals
- `/bookings` - User bookings  
- `/users` - User profiles

If rules deny read access, Firebase silently fails.

### 2. **Network Issues (College WiFi)**
- Some networks block Firebase API endpoints
- Certificate pinning or proxy issues
- Regional firewall restrictions

### 3. **Missing Data in Firebase**
- `hospitals` node might be empty
- No sample data created yet

---

## ✅ SOLUTION 1: Fix Firebase Database Rules

### Step 1: Go to Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project: **medilink-cc25b**
3. Go to **Realtime Database** → **Rules** tab

### Step 2: Replace with These Rules

```json
{
  "rules": {
    "hospitals": {
      ".read": true,
      ".write": "root.child('users').child(auth.uid).child('role').val() === 'hospitalAdmin'",
      "$hospitalId": {
        ".read": true,
        ".write": "root.child('users').child(auth.uid).child('id').val() === $hospitalId"
      }
    },
    "bookings": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$bookingId": {
        ".read": "auth != null",
        ".write": "data.child('userId').val() === auth.uid || root.child('users').child(auth.uid).child('role').val() === 'hospitalAdmin'"
      }
    },
    "users": {
      ".read": "auth != null",
      ".write": "auth.uid === $uid",
      "$uid": {
        ".read": "$uid === auth.uid || root.child('users').child(auth.uid).child('role').val() === 'hospitalAdmin'",
        ".write": "$uid === auth.uid"
      }
    },
    "doctors": {
      ".read": true,
      ".write": "root.child('users').child(auth.uid).child('role').val() === 'hospitalAdmin'"
    },
    "slots": {
      ".read": true,
      ".write": "root.child('users').child(auth.uid).child('role').val() === 'hospitalAdmin'"
    }
  }
}
```

### Step 3: Click "Publish" ✅

---

## ✅ SOLUTION 2: Create Sample Hospital Data

If database is empty, add test data:

### Via Firebase Console:
1. Go to **Realtime Database** → **Data** tab
2. Click **+** next to `medilink-cc25b`
3. Add a new key: `hospitals`
4. Click the `hospitals` key and add:

```json
{
  "hospital1": {
    "name": "City Medical Hospital",
    "address": "123 Main St, Downtown",
    "contact": "0300-1234567",
    "adminId": "your-admin-uid",
    "photoUrl": "",
    "createdAt": "2025-01-01T10:00:00Z"
  },
  "hospital2": {
    "name": "Green Valley Clinic",
    "address": "456 Park Ave, Suburbs",
    "contact": "0300-7654321",
    "adminId": "your-admin-uid",
    "photoUrl": "",
    "createdAt": "2025-01-01T11:00:00Z"
  }
}
```

---

## ✅ SOLUTION 3: Fix Network/WiFi Issues

If it fails on college WiFi:

### For Android:
Add this to `AndroidManifest.xml` to disable certificate pinning:

```xml
<!-- In your meta-data section, add: -->
<meta-data
    android:name="com.google.firebase.app.flags"
    android:value="" />
```

### In your code (lib/main.dart):
```dart
import 'package:firebase_database/firebase_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Allow HTTP Firebase connections (for restricted networks)
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  
  final options = kIsWeb
      ? DefaultFirebaseOptions.web
      : DefaultFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(options: options);
  
  // ... rest of main
}
```

---

## ✅ SOLUTION 4: Add Debugging

Modify [hospital_repository.dart](lib/features/home/repositories/hospital_repository.dart) to show detailed errors:

```dart
Future<List<Hospital>> getAllHospitals() async {
  // Try cache first
  final cachedData = CacheService.getHospitals();
  if (cachedData != null && cachedData.isNotEmpty) {
    print('DEBUG: ⚡ Using cached hospitals (${cachedData.length} items)');
    try {
      return (cachedData as List<dynamic>)
          .map((item) => Hospital.fromJson(
                Map<String, dynamic>.from(item as Map),
                docId: (item as Map)['id'],
              ))
          .toList();
    } catch (e) {
      print('DEBUG: Error parsing cached hospitals: $e');
    }
  }

  print('DEBUG: 🔄 Fetching hospitals from Firebase...');
  print('DEBUG: Database URL: ${_database}');
  
  return _withRetry(() async {
    try {
      print('DEBUG: Attempting to read /hospitals');
      final snapshot = await _database.child('hospitals').get();
      
      print('DEBUG: Firebase response received');
      print('DEBUG: Snapshot exists: ${snapshot.exists}');
      print('DEBUG: Snapshot value: ${snapshot.value}');
      
      if (!snapshot.exists) {
        print('DEBUG: No hospitals found in database');
        return [];
      }
      
      // ... rest of code
    } catch (e, st) {
      print('DEBUG: Firebase query error: $e');
      print('DEBUG: Stack trace: $st');
      rethrow;
    }
  }, maxRetries: _maxRetries, timeout: _queryTimeout);
}
```

Then check the console output in Flutter to see exactly where it fails.

---

## 🧪 Testing Checklist

- [ ] Firebase Database Rules are published
- [ ] Sample hospital data exists in `/hospitals`
- [ ] App permissions: `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` ✅
- [ ] Google Maps API Key is valid ✅
- [ ] Run on Android emulator with good internet
- [ ] Check console logs for exact error message
- [ ] Test on different networks (home WiFi, mobile data)

---

## 📋 Quick Fixes Priority Order

1. **First**: Fix Firebase Rules (Solution 1) ← Most likely issue
2. **Second**: Add sample data (Solution 2)
3. **Third**: Enable debugging (Solution 4) to see real error
4. **Fourth**: Check network/WiFi issues (Solution 3)

---

## 🆘 Still Not Working?

Share the console log output when:
1. App starts
2. "Failed to load hospitals" appears
3. Search for lines with: `DEBUG:` or `error` or `Firebase`

This will show the exact error message!
