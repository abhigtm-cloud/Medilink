# Serve APK with simple HTTP server
FROM node:18-alpine

WORKDIR /app

RUN npm init -y && npm install express

COPY ./public ./public

RUN cat > server.js << 'ENDSCRIPT'
const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.static('public'));

app.get('/', (req, res) => {
  res.send('<h1>Medilink APK</h1><p><a href="/medilink-release.apk">Download APK</a></p>');
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('Server running on port ' + PORT);
});
ENDSCRIPT

EXPOSE 3000
CMD ["node", "server.js"]
