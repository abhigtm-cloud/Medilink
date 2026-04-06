# Build stage - Build Flutter web app
FROM ubuntu:22.04 as builder

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_SKIP_DOWNLOAD_LOCK=true
ENV FLUTTER_SKIP_DOWNLOAD=false

RUN apt-get update && apt-get install -y \
    git curl unzip xz-utils libgconf-2-4 libstdc++6 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /flutter
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 . && \
    chmod -R 755 /flutter && \
    ./bin/flutter config --enable-web && \
    ./bin/flutter config --no-analytics && \
    ./bin/flutter doctor -v && \
    ./bin/flutter precache --web

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN /flutter/bin/flutter pub get

COPY . .
RUN /flutter/bin/flutter build web --release --no-tree-shake-icons

# Serve stage - Serve with Node.js Express
FROM node:18-alpine

WORKDIR /app

RUN npm init -y && npm install express cors

COPY ./server.js ./server.js
COPY --from=builder /app/build/web ./public

EXPOSE 3000
CMD ["node", "server.js"]
