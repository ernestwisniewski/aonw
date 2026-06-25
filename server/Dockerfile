# syntax=docker/dockerfile:1.7

FROM dart:stable AS builder

WORKDIR /workspace

COPY packages/aonw_core/pubspec.yaml packages/aonw_core/pubspec.lock ./packages/aonw_core/
COPY server/pubspec.yaml server/pubspec.lock ./server/

WORKDIR /workspace/server
RUN --mount=type=cache,target=/root/.pub-cache dart pub get --offline || dart pub get

WORKDIR /workspace
COPY packages/aonw_core ./packages/aonw_core
COPY server ./server

WORKDIR /workspace/server
ARG AONW_APP_VERSION
ARG AONW_RELEASE_CHANNEL=ALPHA
RUN --mount=type=cache,target=/root/.pub-cache \
    dart pub get \
 && APP_VERSION="${AONW_APP_VERSION:-0.0.0}" \
 && dart compile exe \
      -DAONW_APP_VERSION="$APP_VERSION" \
      -DAONW_RELEASE_CHANNEL="$AONW_RELEASE_CHANNEL" \
      bin/main.dart \
      -o /workspace/server_bin

FROM debian:bookworm-slim AS runtime

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --uid 10001 --user-group --home-dir /app --create-home --shell /usr/sbin/nologin aonw

WORKDIR /app
COPY --from=builder --chown=aonw:aonw /workspace/server_bin /app/server
# Copy only the non-secret run-mode config files. Secrets are never baked into
# the image; they are supplied through the environment at runtime.
COPY --from=builder --chown=aonw:aonw \
  /workspace/server/config/development.yaml \
  /workspace/server/config/staging.yaml \
  /workspace/server/config/production.yaml \
  /workspace/server/config/test.yaml \
  /app/config/
COPY --from=builder --chown=aonw:aonw /workspace/server/migrations /app/migrations
COPY --from=builder --chown=aonw:aonw /workspace/server/lib/src/generated/protocol.yaml /app/lib/src/generated/protocol.yaml
COPY --chown=aonw:aonw server/docker-entrypoint.sh /app/docker-entrypoint.sh
COPY --chown=aonw:aonw assets/maps /app/assets/maps

USER aonw

EXPOSE 8080
EXPOSE 8081
EXPOSE 8082

ENV SERVERPOD_RUN_MODE=production \
    SERVERPOD_SERVER_ID=default \
    SERVERPOD_LOGGING_MODE=normal \
    SERVERPOD_SERVER_ROLE=monolith \
    SERVERPOD_API_SERVER_PORT=8080 \
    SERVERPOD_INSIGHTS_SERVER_PORT=8081 \
    SERVERPOD_WEB_SERVER_PORT=8082

HEALTHCHECK --interval=10s --timeout=3s --start-period=15s --retries=5 \
  CMD curl -fsS "http://127.0.0.1:${SERVERPOD_API_SERVER_PORT:-8080}/livez" >/dev/null || exit 1

ENTRYPOINT ["/app/docker-entrypoint.sh"]
