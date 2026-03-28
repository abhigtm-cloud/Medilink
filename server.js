const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();
const PORT = process.env.PORT || 3000;

// Enable static file serving with proper mime types
app.use(express.static('public', {
  setHeaders: (res, path) => {
    if (path.endsWith('.apk')) {
      res.setHeader('Content-Type', 'application/vnd.android.package-archive');
      res.setHeader('Content-Disposition', 'attachment; filename="medilink-release.apk"');
    }
  }
}));

// Home page
app.get('/', (req, res) => {
  const apkPath = path.join(__dirname, 'public', 'medilink-release.apk');
  const apkExists = fs.existsSync(apkPath);
  const apkSize = apkExists ? fs.statSync(apkPath).size : 0;
  
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <title>Medilink APK Download</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 600px; margin: 0 auto; }
        h1 { color: #2196F3; }
        .status { padding: 10px; background: ${apkExists ? '#4CAF50' : '#f44336'}; color: white; border-radius: 4px; margin: 10px 0; }
        a { display: inline-block; padding: 10px 20px; background: #2196F3; color: white; text-decoration: none; border-radius: 4px; }
        a:hover { background: #1976D2; }
        .info { margin: 20px 0; font-size: 14px; color: #666; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Medilink Healthcare App</h1>
        <div class="status">
          ${apkExists ? '✓ APK Available for Download' : '✗ APK Not Found'}
        </div>
        ${apkExists ? `
          <p><strong>Download:</strong><br/>
          <a href="/medilink-release.apk">📱 Download Medilink APK (${(apkSize / 1024 / 1024).toFixed(1)}MB)</a></p>
          <div class="info">
            <p><strong>Installation:</strong></p>
            <ol>
              <li>Download the APK file above</li>
              <li>On your Android device, go to Settings → Security</li>
              <li>Enable "Unknown Sources"</li>
              <li>Open the downloaded APK file and tap Install</li>
              <li>Launch the app and sign in</li>
            </ol>
          </div>
          <div class="info">
            <p><strong>Features:</strong></p>
            <ul>
              <li>Hospital and doctor management</li>
              <li>Location-based hospital finder with place names</li>
              <li>Appointment booking system</li>
              <li>Photo uploads for hospitals and doctors</li>
              <li>Real-time notifications</li>
            </ul>
          </div>
          <div class="info">
            <p><strong>File Info:</strong></p>
            <ul>
              <li>Size: ${(apkSize / 1024 / 1024).toFixed(1)}MB</li>
              <li>Type: Android App Bundle</li>
              <li>Architecture: ARM64</li>
            </ul>
          </div>
        ` : `
          <p style="color: #f44336;">APK file not found on server. Please contact support.</p>
        `}
      </div>
    </body>
    </html>
  `;
  res.send(html);
});

// Direct APK download endpoint
app.get('/download', (req, res) => {
  const apkPath = path.join(__dirname, 'public', 'medilink-release.apk');
  if (fs.existsSync(apkPath)) {
    res.download(apkPath, 'medilink-release.apk');
  } else {
    res.status(404).send('APK file not found');
  }
});

// Health check
app.get('/health', (req, res) => {
  const apkPath = path.join(__dirname, 'public', 'medilink-release.apk');
  res.json({
    status: 'healthy',
    apk_available: fs.existsSync(apkPath),
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Medilink APK Server running on port ${PORT}`);
  console.log(`📥 Download at: http://localhost:${PORT}/medilink-release.apk`);
  console.log(`🏠 Home page: http://localhost:${PORT}/`);
});
