# Medilink - Render.com Deployment Guide

## 📱 GitHub Repository
**Repository URL:** `https://github.com/abhigtm-cloud/Medilink.git`

**Latest Commit:** Booking Confirmation Workflow Implementation
- ✅ Pending booking status
- ✅ Hospital admin confirmation panel
- ✅ Real user profile data
- ✅ Booking status tracking

---

## 🚀 Deploy to Render.com (Step-by-Step)

### 1. **Connect GitHub to Render**
   - Go to [render.com](https://render.com)
   - Click **"New +"** → **"Web Service"**
   - Select **"Build and deploy from a Git repository"**
   - Click **"Connect Accounts"** → Authorize GitHub
   - Select repository: `abhigtm-cloud/Medilink`

### 2. **Configure the Web Service**
   
   **Name:** `medilink-app`
   
   **Environment:** `Docker`
   
   **Build Command:** (leave default - Docker handles it)
   
   **Start Command:** (leave default)
   
   **Plan:** Free (upgrade to Starter for better performance)
   
   **Region:** Oregon (or your preferred region)
   
   **Branch:** `main`

### 3. **Environment Variables** (Add these)
   ```
   PORT = 3000
   NODE_ENV = production
   ```

### 4. **Deploy**
   - Click **"Create Web Service"**
   - Render will automatically:
     - Build Docker image
     - Build Flutter web app
     - Deploy Node.js server
     - Start serving on `https://medilink-app.onrender.com`

---

## 📦 Build Process

The deployment uses a **multi-stage Docker build**:

1. **Build Stage:** 
   - Uses `cirrusci/flutter:latest`
   - Runs `flutter pub get`
   - Builds Flutter web app: `flutter build web --release`

2. **Serve Stage:**
   - Uses `node:18-alpine` (lightweight)
   - Copies web build from builder
   - Runs Express server on port 3000
   - Serves from `/public` directory

---

## 🔗 Access Your App

After deployment completes:
- **Web URL:** `https://medilink-app.onrender.com`
- **Test endpoints:**
  - `https://medilink-app.onrender.com/` - Main app
  - `https://medilink-app.onrender.com/health` - Health check

---

## 📱 Mobile Testing

### Test Accounts:

**Hospital Admin (Booking Approver):**
```
Email: test@hospital.com
Password: [your_password]
```

**Normal User (Patient):**
```
Email: patient@example.com
Password: [your_password]
```

### Testing Workflow:
1. Login as patient
2. Browse hospitals and book appointment
3. Booking status: **"⏳ Waiting Approval"**
4. Login as hospital admin
5. Go to **Admin Dashboard** → **"Pending Bookings"** tab
6. Click **Approve** or **Reject**
7. Logout and login as patient
8. Check **"My Bookings"** → Status updated!

---

## 🔄 Continuous Deployment

- **Auto-deploy:** Enabled on `main` branch
- **Each push to GitHub** automatically triggers:
  1. New build
  2. Docker image creation
  3. Deployment update
- **Deployment status:** Check in Render Dashboard

---

## 🛠 Troubleshooting

### Build Fails
```
Check logs in Render → Logs tab
Common issues:
- Dart SDK version mismatch (use Flutter 3.13+)
- pubspec.yaml conflicts
- Firebase credentials missing
```

### App Won't Load
```
1. Check health endpoint: /
2. Verify PORT environment variable = 3000
3. Check Node.js server.js is running
4. Look at "Logs" tab in Render dashboard
```

### Slow Performance (Free Plan)
```
Upgrade to Starter or Standard plan for:
- Dedicated resources
- Better performance
- Custom domain support
```

---

## 📊 Monitoring

**Render Dashboard provides:**
- Real-time logs
- CPU/Memory usage
- Deployment history
- Restart options
- Environment management

---

## 🔐 Production Checklist

- [x] GitHub repository linked
- [x] Dockerfile configured
- [x] Server.js setup for Express
- [x] Firebase credentials secured
- [x] Environment variables set
- [x] Main branch protected
- [x] Auto-deploy enabled

---

## 💡 Post-Deployment

1. **Test all features:**
   - User registration & login
   - Hospital/Doctor creation
   - Booking workflow
   - Admin confirmation panel
   - Profile updates

2. **Monitor:**
   - Check logs for errors
   - Monitor response times
   - Track error rates

3. **Updates:**
   - Push changes to GitHub
   - Render auto-deploys
   - No manual restart needed

---

## 📞 Support

For issues:
1. Check Render Logs
2. Review GitHub commits
3. Verify Firebase rules
4. Test locally: `flutter run -d chrome`

---

**Last Updated:** April 6, 2026
**Status:** ✅ Ready for Production
