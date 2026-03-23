ARG REGISTRY_PREFIX=harbor.pg.innopolis.university/docker-hub-cache/
FROM ${REGISTRY_PREFIX}instrumentisto/flutter:3.29.3 AS builder

WORKDIR /app

# Flutter warns about running as root, but this is safe in a build-only container.
# Resolve dependencies first for layer caching.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --base-href /flutter/

ARG REGISTRY_PREFIX=harbor.pg.innopolis.university/docker-hub-cache/
FROM ${REGISTRY_PREFIX}alpine:3.21
COPY --from=builder /app/build/web /flutter-web
CMD ["cp", "-r", "/flutter-web/.", "/output/"]
