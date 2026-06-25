#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

export SERVERPOD_SERVICE_SECRET="${SERVERPOD_SERVICE_SECRET:-local-smoke-service-secret}"
export SERVERPOD_PASSWORD_emailSecretHashPepper="${SERVERPOD_PASSWORD_emailSecretHashPepper:-local-smoke-email-secret}"
export SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey="${SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey:-local-smoke-jwt-private-key}"
export SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper="${SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper:-local-smoke-refresh-pepper}"
export SERVERPOD_PASSWORD_redis="${SERVERPOD_PASSWORD_redis:-local-smoke-redis-password}"

postgres_user="${POSTGRES_USER:-aonw}"
main_database="${POSTGRES_DB:-aonw}"
test_database="${SERVERPOD_TEST_DATABASE:-aonw_test}"
current_migration="$(
  awk '
    $0 !~ /^#/ && NF {
      version = $1
    }
    END {
      print version
    }
  ' server/migrations/migration_registry.txt
)"

database_exists() {
  local database="$1"
  docker compose exec -T postgres psql \
    -U "${postgres_user}" \
    -d postgres \
    -tAc "SELECT 1 FROM pg_database WHERE datname='${database}'" | grep -q 1
}

ensure_fresh_test_database() {
  if ! database_exists "${test_database}"; then
    docker compose exec -T postgres createdb \
      -U "${postgres_user}" \
      "${test_database}"
    return
  fi

  local applied_migration
  applied_migration="$(
    docker compose exec -T postgres psql \
      -U "${postgres_user}" \
      -d "${test_database}" \
      -tAc "SELECT version FROM serverpod_migrations WHERE module='aonw'" \
      2>/dev/null || true
  )"

  if [ -n "${applied_migration}" ] &&
    [ "${applied_migration}" != "${current_migration}" ]; then
    echo "Resetting ${test_database}: migration ${applied_migration} is not the current clean test migration ${current_migration}."
    docker compose exec -T postgres dropdb \
      -U "${postgres_user}" \
      "${test_database}"
    docker compose exec -T postgres createdb \
      -U "${postgres_user}" \
      "${test_database}"
  fi
}

docker compose --profile dev up -d postgres

for _ in {1..30}; do
  if docker compose exec -T postgres pg_isready -U "${postgres_user}" -d "${main_database}" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
docker compose exec -T postgres pg_isready -U "${postgres_user}" -d "${main_database}"

ensure_fresh_test_database

make server-integration-test
