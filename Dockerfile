# Build stage - Build Flutter web app
FROM cirrusci/flutter:3.16 as builder

WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release

# Serve stage - Serve with Node.js Express
FROM node:18-alpine

WORKDIR /app

RUN npm init -y && npm install express cors

COPY ./server.js ./server.js
COPY --from=builder /app/build/web ./public

EXPOSE 3000
CMD ["node", "server.js"]
