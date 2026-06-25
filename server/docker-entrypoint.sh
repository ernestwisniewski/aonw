#!/bin/sh
set -eu

mode="${SERVERPOD_RUN_MODE:-production}"
server_id="${SERVERPOD_SERVER_ID:-default}"
logging="${SERVERPOD_LOGGING_MODE:-normal}"
role="${SERVERPOD_SERVER_ROLE:-monolith}"

# Multi-line OAuth secrets (the Google client JSON and the Apple sign-in PEM key)
# cannot be expressed on a single .env line, so they are provided base64-encoded
# and decoded here into the SERVERPOD_PASSWORD_* names that Serverpod reads.
if [ -n "${AONW_GOOGLE_CLIENT_SECRET_B64:-}" ]; then
  SERVERPOD_PASSWORD_googleClientSecret="$(printf '%s' "$AONW_GOOGLE_CLIENT_SECRET_B64" | base64 -d)"
  export SERVERPOD_PASSWORD_googleClientSecret
fi
if [ -n "${AONW_APPLE_KEY_B64:-}" ]; then
  SERVERPOD_PASSWORD_appleKey="$(printf '%s' "$AONW_APPLE_KEY_B64" | base64 -d)"
  export SERVERPOD_PASSWORD_appleKey
fi

set -- \
  --mode="$mode" \
  --server-id="$server_id" \
  --logging="$logging" \
  --role="$role" \
  "$@"

if [ "${SERVERPOD_APPLY_MIGRATIONS:-false}" = "true" ]; then
  set -- --apply-migrations "$@"
fi

exec /app/server "$@"
