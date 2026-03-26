# Build stage - Flutter APK compilation
FROM cirrusci/flutter:3.9.2 AS builder

WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get Flutter dependencies
RUN flutter pub get

# Copy entire project
COPY . .

# Build release APK
RUN flutter build apk --release

# Server stage - Serve the APK
FROM node:18-alpine

WORKDIR /app

# Install a simple HTTP server
RUN npm install -g http-server

# Copy APK from builder stage
COPY --from=builder /app/build/app/outputs/flutter-app-release.apk ./public/medilink-release.apk

# Create a simple HTML interface for download
RUN mkdir -p public && cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Medilink - APK Download</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            padding: 40px;
            max-width: 500px;
            text-align: center;
        }
        
        h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 2.5em;
        }
        
        .subtitle {
            color: #666;
            font-size: 1.1em;
            margin-bottom: 30px;
        }
        
        .app-info {
            background: #f5f5f5;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 30px;
            text-align: left;
        }
        
        .info-item {
            margin: 10px 0;
            color: #555;
        }
        
        .info-label {
            font-weight: 600;
            color: #333;
        }
        
        .download-btn {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px 40px;
            border-radius: 50px;
            text-decoration: none;
            font-size: 1.1em;
            font-weight: 600;
            transition: transform 0.3s, box-shadow 0.3s;
            box-shadow: 0 10px 25px rgba(102, 126, 234, 0.4);
        }
        
        .download-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 15px 35px rgba(102, 126, 234, 0.6);
        }
        
        .instructions {
            margin-top: 40px;
            text-align: left;
            background: #e8f4f8;
            padding: 20px;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }
        
        .instructions h3 {
            color: #333;
            margin-bottom: 10px;
        }
        
        .instructions ol {
            margin-left: 20px;
            color: #555;
        }
        
        .instructions li {
            margin-bottom: 8px;
        }
        
        .footer {
            margin-top: 30px;
            color: #999;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📱 Medilink</h1>
        <p class="subtitle">Healthcare at Your Fingertips</p>
        
        <div class="app-info">
            <div class="info-item">
                <span class="info-label">Version:</span> 1.0.0
            </div>
            <div class="info-item">
                <span class="info-label">Platform:</span> Android
            </div>
            <div class="info-item">
                <span class="info-label">Build Type:</span> Release
            </div>
        </div>
        
        <a href="./medilink-release.apk" class="download-btn" download>
            ⬇️ Download APK
        </a>
        
        <div class="instructions">
            <h3>Installation Instructions:</h3>
            <ol>
                <li>Download the APK file above</li>
                <li>Transfer it to your Android device</li>
                <li>Go to Settings → Security → Unknown Sources (enable if needed)</li>
                <li>Open the APK file and tap Install</li>
                <li>Grant necessary permissions when prompted</li>
                <li>Open Medilink and enjoy!</li>
            </ol>
        </div>
        
        <div class="footer">
            <p>Last Build: <span id="buildTime"></span></p>
        </div>
    </div>
    
    <script>
        // Display current build time
        const now = new Date();
        document.getElementById('buildTime').textContent = now.toLocaleString();
    </script>
</body>
</html>
EOF

# Expose port
EXPOSE 3000

# Start HTTP server
CMD ["http-server", "public", "-p", "3000", "-g"]
