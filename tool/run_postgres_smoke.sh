#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

random_hex() {
  local byte_count="$1"
  local expected_length=$((byte_count * 2))
  local value
  value="$(LC_ALL=C od -An -N"${byte_count}" -tx1 /dev/urandom | tr -d '[:space:]')"
  if ((${#value} != expected_length)) || [[ ! "${value}" =~ ^[0-9a-f]+$ ]]; then
    echo "Could not generate secure PostgreSQL smoke randomness." >&2
    return 1
  fi
  printf '%s' "${value}"
}

project_name="aonw-critical-e2e-$(random_hex 8)"
postgres_password="$(random_hex 32)"

read -r -a compose_command <<<"${COMPOSE:-docker compose}"
compose=(
  "${compose_command[@]}"
  --project-directory "${repo_root}"
  --project-name "${project_name}"
  -f "${repo_root}/compose.yml"
)

export POSTGRES_DB='aonw'
export POSTGRES_USER='aonw'
export POSTGRES_PASSWORD="${postgres_password}"
export SERVERPOD_DATABASE_PASSWORD="${postgres_password}"
export AONW_POSTGRES_BIND='127.0.0.1'
export AONW_POSTGRES_PORT='0'
export SERVERPOD_SERVICE_SECRET="${SERVERPOD_SERVICE_SECRET:-local-smoke-service-secret}"
export SERVERPOD_PASSWORD_emailSecretHashPepper="${SERVERPOD_PASSWORD_emailSecretHashPepper:-local-smoke-email-secret}"
export SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey="${SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey:-local-smoke-jwt-private-key}"
export SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper="${SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper:-local-smoke-refresh-pepper}"
export SERVERPOD_PASSWORD_redis="${SERVERPOD_PASSWORD_redis:-local-smoke-redis-password}"

test_database='aonw_test'
critical_e2e_port_override="${AONW_SERVERPOD_CRITICAL_E2E_PORT:-}"
postgres_user=''
main_database=''
container_postgres_password=''
postgres_port=''

if [[ -n "${SERVERPOD_TEST_DATABASE:-}" ]] &&
  [[ "${SERVERPOD_TEST_DATABASE}" != "${test_database}" ]]; then
  echo "SERVERPOD_TEST_DATABASE must be exactly ${test_database}." >&2
  exit 64
fi

read_container_value() {
  local name="$1"
  local value
  if ! value="$("${compose[@]}" exec -T postgres printenv "${name}")"; then
    echo "PostgreSQL container does not expose ${name}." >&2
    return 1
  fi
  if [[ -z "${value}" ]]; then
    echo "PostgreSQL container exposes an empty ${name}." >&2
    return 1
  fi
  printf '%s' "${value}"
}

validate_identifier() {
  local name="$1"
  local value="$2"
  if [[ ! "${value}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "PostgreSQL ${name} must be a simple SQL identifier." >&2
    exit 64
  fi
}

normalize_port() {
  local name="$1"
  local raw="$2"
  if [[ ! "${raw}" =~ ^[0-9]{1,5}$ ]]; then
    echo "${name} must be an integer from 1 to 65535; got ${raw:-empty}." >&2
    return 64
  fi
  local value=$((10#${raw}))
  if ((value < 1 || value > 65535)); then
    echo "${name} must be an integer from 1 to 65535; got ${raw}." >&2
    return 64
  fi
  printf '%s' "${value}"
}

if [[ -n "${critical_e2e_port_override}" ]]; then
  critical_e2e_port_override="$(normalize_port 'AONW_SERVERPOD_CRITICAL_E2E_PORT' "${critical_e2e_port_override}")"
  if ((critical_e2e_port_override < 1024 || critical_e2e_port_override > 65533)); then
    echo "AONW_SERVERPOD_CRITICAL_E2E_PORT must be an integer from 1024 to 65533; got ${critical_e2e_port_override}." >&2
    exit 64
  fi
fi

database_exists() {
  "${compose[@]}" exec -T postgres psql \
    -U "${postgres_user}" \
    -d postgres \
    -tAc "SELECT 1 FROM pg_database WHERE datname='aonw_test'" | grep -q 1
}

ensure_fresh_test_database() {
  if database_exists; then
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

cleanup() {
  local status=$?
  trap - EXIT INT TERM
  if ((status != 0)); then
    echo "PostgreSQL smoke failed in isolated project ${project_name}." >&2
    "${compose[@]}" --profile dev ps >&2 || true
    "${compose[@]}" --profile dev logs --tail=160 postgres >&2 || true
  fi
  if ! "${compose[@]}" --profile dev down --volumes --remove-orphans; then
    echo "Failed to remove isolated PostgreSQL smoke project ${project_name}." >&2
    if ((status == 0)); then
      status=1
    fi
  fi
  exit "${status}"
}

trap cleanup EXIT
trap 'exit 130' INT TERM

"${compose[@]}" --profile dev up -d postgres

published_endpoint="$("${compose[@]}" port postgres 5432)"
if [[ ! "${published_endpoint}" =~ ^127\.0\.0\.1:([0-9]{1,5})$ ]]; then
  echo "PostgreSQL must be published only on a random IPv4 loopback port; got ${published_endpoint:-no mapping}." >&2
  exit 64
fi
postgres_port="$(normalize_port 'Published PostgreSQL port' "${BASH_REMATCH[1]}")"

postgres_user="$(read_container_value POSTGRES_USER)"
main_database="$(read_container_value POSTGRES_DB)"
container_postgres_password="$(read_container_value POSTGRES_PASSWORD)"
validate_identifier user "${postgres_user}"
validate_identifier main-database "${main_database}"
if [[ "${postgres_user}" != 'aonw' ]]; then
  echo "PostgreSQL test user must be exactly aonw; got ${postgres_user}." >&2
  exit 64
fi
if [[ "${main_database}" != 'aonw' ]]; then
  echo "PostgreSQL main database must be exactly aonw; got ${main_database}." >&2
  exit 64
fi
if [[ "${main_database}" == "${test_database}" ]]; then
  echo "Refusing to replace the PostgreSQL main database ${main_database}." >&2
  exit 64
fi
if [[ "${container_postgres_password}" != "${postgres_password}" ]]; then
  echo "PostgreSQL container password does not match the per-run secret." >&2
  exit 64
fi

postgres_ready=false
for _ in {1..60}; do
  if password_probe="$("${compose[@]}" exec -T postgres sh -eu -c '
      export PGPASSWORD="$POSTGRES_PASSWORD"
      exec psql \
        -h 127.0.0.1 \
        -p 5432 \
        -U "$POSTGRES_USER" \
        -d "$POSTGRES_DB" \
        -v ON_ERROR_STOP=1 \
        -Atqc "SELECT 1"
    ' 2>/dev/null)" && [[ "${password_probe}" == '1' ]]; then
    postgres_ready=true
    break
  fi
  sleep 1
done
if [[ "${postgres_ready}" != true ]]; then
  echo "PostgreSQL did not accept an authenticated TCP query within 60 seconds." >&2
  exit 1
fi

ensure_fresh_test_database

for target in server-integration-test serverpod-critical-e2e-test; do
  env -i \
    PATH="${PATH:?PATH is required}" \
    HOME="${HOME:?HOME is required}" \
    TMPDIR="${TMPDIR:-/tmp}" \
    AONW_TEST_DATABASE_PASSWORD="${postgres_password}" \
    AONW_TEST_DATABASE_PORT="${postgres_port}" \
    AONW_SERVERPOD_CRITICAL_E2E_PORT="${critical_e2e_port_override}" \
    make "${target}"
done
