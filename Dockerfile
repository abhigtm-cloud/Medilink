# Build stage - Build Flutter web app
FROM ubuntu:22.04 as builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    git curl unzip xz-utils libgconf-2-4 libstdc++6 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /flutter
ENV PATH="/flutter/bin:${PATH}"
RUN flutter config --enable-web && flutter doctor

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

# Serve stage - Serve with Node.js Express
FROM node:18-alpine

WORKDIR /app

RUN npm init -y && npm install express cors

COPY ./server.js ./server.js
COPY --from=builder /app/build/web ./public

EXPOSE 3000
CMD ["node", "server.js"]
