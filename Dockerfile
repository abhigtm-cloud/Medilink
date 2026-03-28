# Serve APK with Node.js Express server
FROM node:18-alpine

WORKDIR /app

RUN npm init -y && npm install express

COPY ./public ./public
COPY ./server.js ./server.js

EXPOSE 3000
CMD ["node", "server.js"]
