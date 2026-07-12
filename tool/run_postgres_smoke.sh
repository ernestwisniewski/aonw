#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

read -r -a compose_command <<<"${COMPOSE:-docker compose}"
compose=(
  "${compose_command[@]}"
  --project-directory "${repo_root}"
  --project-name aonw
  -f "${repo_root}/compose.yml"
)

export SERVERPOD_SERVICE_SECRET="${SERVERPOD_SERVICE_SECRET:-local-smoke-service-secret}"
export SERVERPOD_PASSWORD_emailSecretHashPepper="${SERVERPOD_PASSWORD_emailSecretHashPepper:-local-smoke-email-secret}"
export SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey="${SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey:-local-smoke-jwt-private-key}"
export SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper="${SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper:-local-smoke-refresh-pepper}"
export SERVERPOD_PASSWORD_redis="${SERVERPOD_PASSWORD_redis:-local-smoke-redis-password}"

postgres_user="${POSTGRES_USER:-aonw}"
main_database="${POSTGRES_DB:-aonw}"
test_database="${SERVERPOD_TEST_DATABASE:-aonw_test}"
database_exists() {
  local database="$1"
  "${compose[@]}" exec -T postgres psql \
    -U "${postgres_user}" \
    -d postgres \
    -tAc "SELECT 1 FROM pg_database WHERE datname='${database}'" | grep -q 1
}

ensure_fresh_test_database() {
  if database_exists "${test_database}"; then
    echo "Resetting ${test_database} for a hermetic integration run."
    "${compose[@]}" exec -T postgres dropdb \
      --force \
      -U "${postgres_user}" \
      "${test_database}"
  fi
  "${compose[@]}" exec -T postgres createdb \
    -U "${postgres_user}" \
    "${test_database}"
}

"${compose[@]}" --profile dev up -d postgres

for _ in {1..30}; do
  if "${compose[@]}" exec -T postgres pg_isready -U "${postgres_user}" -d "${main_database}" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
"${compose[@]}" exec -T postgres pg_isready -U "${postgres_user}" -d "${main_database}"

ensure_fresh_test_database

make server-integration-test
