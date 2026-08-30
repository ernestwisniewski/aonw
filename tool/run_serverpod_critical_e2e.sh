#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

base_port="${AONW_SERVERPOD_CRITICAL_E2E_PORT:-}"
runtime_path="${PATH:?PATH is required}"
runtime_home="${HOME:?HOME is required}"
runtime_tmpdir="${TMPDIR:-/tmp}"
database_password="${AONW_TEST_DATABASE_PASSWORD:-${SERVERPOD_TEST_DATABASE_PASSWORD:-aonw_dev}}"
database_port="${AONW_TEST_DATABASE_PORT:-5432}"
port_lock_root="${runtime_tmpdir%/}/aonw-critical-e2e-port-locks"
port_locks=()

normalize_base_port() {
  local raw="$1"
  if [[ ! "${raw}" =~ ^[0-9]{1,5}$ ]]; then
    echo "AONW_SERVERPOD_CRITICAL_E2E_PORT must be an integer from 1024 to 65533." >&2
    return 64
  fi
  local value=$((10#${raw}))
  if ((value < 1024 || value > 65533)); then
    echo "AONW_SERVERPOD_CRITICAL_E2E_PORT must be an integer from 1024 to 65533." >&2
    return 64
  fi
  printf '%s' "${value}"
}

if [[ -n "${base_port}" ]]; then
  base_port="$(normalize_base_port "${base_port}")"
fi

if [[ -z "${database_password}" ]]; then
  echo "PostgreSQL test password must not be empty." >&2
  exit 64
fi

if [[ ! "${database_port}" =~ ^[0-9]{1,5}$ ]]; then
  echo "AONW_TEST_DATABASE_PORT must be an integer from 1 to 65535." >&2
  exit 64
fi
database_port=$((10#${database_port}))
if ((database_port < 1 || database_port > 65535)); then
  echo "AONW_TEST_DATABASE_PORT must be an integer from 1 to 65535." >&2
  exit 64
fi

random_secret() {
  local secret
  secret="$(LC_ALL=C od -An -N32 -tx1 /dev/urandom | tr -d '[:space:]')"
  if [[ ! "${secret}" =~ ^[0-9a-f]{64}$ ]]; then
    echo "Could not generate a cryptographically random test secret." >&2
    return 1
  fi
  printf '%s' "${secret}"
}

service_secret="$(random_secret)"
email_hash_pepper="$(random_secret)"
jwt_private_key="$(random_secret)"
refresh_hash_pepper="$(random_secret)"
ready_nonce="$(random_secret)"
ready_marker="AONW_CRITICAL_E2E_READY ${ready_nonce}"

server_log="$(mktemp "${runtime_tmpdir}/aonw-critical-e2e.XXXXXX")"
server_pid=''

terminate_server() {
  if [[ -z "${server_pid}" ]]; then
    return
  fi
  if ! kill -0 "${server_pid}" 2>/dev/null; then
    wait "${server_pid}" 2>/dev/null || true
    return
  fi

  kill -TERM "${server_pid}" 2>/dev/null || true
  local attempts=0
  while kill -0 "${server_pid}" 2>/dev/null && ((attempts < 5)); do
    sleep 1
    attempts=$((attempts + 1))
  done
  if kill -0 "${server_pid}" 2>/dev/null; then
    echo "Critical E2E server did not stop after TERM; sending KILL." >&2
    kill -KILL "${server_pid}" 2>/dev/null || true
  fi
  wait "${server_pid}" 2>/dev/null || true
}

cleanup() {
  local status=$?
  trap - EXIT INT TERM
  terminate_server
  if ((status != 0)); then
    echo "Critical E2E server log:" >&2
    sed -n '1,240p' "${server_log}" >&2
  fi
  rm -f "${server_log}"
  for port_lock in "${port_locks[@]}"; do
    if ! rm -f -- "${port_lock}"; then
      echo "Could not remove critical E2E port lock ${port_lock}." >&2
      if ((status == 0)); then
        status=1
      fi
    fi
  done
  exit "${status}"
}

trap cleanup EXIT
trap 'exit 130' INT TERM

if [[ -z "${base_port}" ]]; then
  allocated_base_port="$(
    dart run tool/allocate_loopback_port_triplet.dart \
      --lock-directory "${port_lock_root}"
  )"
  base_port="$(normalize_base_port "${allocated_base_port}")"
  port_locks=(
    "${port_lock_root}/${base_port}.lock"
    "${port_lock_root}/$((base_port + 1)).lock"
    "${port_lock_root}/$((base_port + 2)).lock"
  )
fi

(
  cd "${repo_root}/server"
  exec env -i \
    PATH="${runtime_path}" \
    HOME="${runtime_home}" \
    TMPDIR="${runtime_tmpdir}" \
    AONW_SERVERPOD_CRITICAL_E2E_PORT="${base_port}" \
    AONW_SERVERPOD_CRITICAL_E2E_READY_NONCE="${ready_nonce}" \
    AONW_TEST_DATABASE_PORT="${database_port}" \
    SERVERPOD_RUN_MODE=test \
    SERVERPOD_SERVER_ID=critical-e2e \
    SERVERPOD_SERVER_ROLE=monolith \
    SERVERPOD_LOGGING_MODE=normal \
    SERVERPOD_APPLY_MIGRATIONS=true \
    SERVERPOD_APPLY_REPAIR_MIGRATION=false \
    SERVERPOD_API_SERVER_PORT="${base_port}" \
    SERVERPOD_API_SERVER_PUBLIC_HOST=127.0.0.1 \
    SERVERPOD_API_SERVER_PUBLIC_PORT="${base_port}" \
    SERVERPOD_API_SERVER_PUBLIC_SCHEME=http \
    SERVERPOD_INSIGHTS_SERVER_PORT="$((base_port + 1))" \
    SERVERPOD_INSIGHTS_SERVER_PUBLIC_HOST=127.0.0.1 \
    SERVERPOD_INSIGHTS_SERVER_PUBLIC_PORT="$((base_port + 1))" \
    SERVERPOD_INSIGHTS_SERVER_PUBLIC_SCHEME=http \
    SERVERPOD_WEB_SERVER_PORT="$((base_port + 2))" \
    SERVERPOD_WEB_SERVER_PUBLIC_HOST=127.0.0.1 \
    SERVERPOD_WEB_SERVER_PUBLIC_PORT="$((base_port + 2))" \
    SERVERPOD_WEB_SERVER_PUBLIC_SCHEME=http \
    SERVERPOD_DATABASE_HOST=localhost \
    SERVERPOD_DATABASE_PORT="${database_port}" \
    SERVERPOD_DATABASE_NAME=aonw_test \
    SERVERPOD_DATABASE_USER=aonw \
    SERVERPOD_DATABASE_DIALECT=postgres \
    SERVERPOD_DATABASE_REQUIRE_SSL=false \
    SERVERPOD_DATABASE_IS_UNIX_SOCKET=false \
    SERVERPOD_REDIS_ENABLED=false \
    SERVERPOD_FUTURE_CALL_EXECUTION_ENABLED=false \
    SERVERPOD_SESSION_PERSISTENT_LOG_ENABLED=false \
    SERVERPOD_SESSION_CONSOLE_LOG_ENABLED=false \
    SERVERPOD_PASSWORD_database="${database_password}" \
    SERVERPOD_SERVICE_SECRET="${service_secret}" \
    SERVERPOD_PASSWORD_emailSecretHashPepper="${email_hash_pepper}" \
    SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey="${jwt_private_key}" \
    SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper="${refresh_hash_pepper}" \
    dart run test/support/critical_e2e_server.dart
) >"${server_log}" 2>&1 &
server_pid=$!

host="http://127.0.0.1:${base_port}/"
ready=false
for _ in {1..90}; do
  if ! kill -0 "${server_pid}" 2>/dev/null; then
    echo "Critical E2E server exited before becoming ready." >&2
    exit 1
  fi
  if grep -Fqx -- "${ready_marker}" "${server_log}" &&
    curl --fail --silent --show-error --noproxy '*' \
      --connect-timeout 1 --max-time 1 "${host}livez" >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 1
done

if [[ "${ready}" != true ]]; then
  echo "Critical E2E server did not become ready at ${host}." >&2
  exit 1
fi

cd "${repo_root}"
env -i \
  PATH="${runtime_path}" \
  HOME="${runtime_home}" \
  TMPDIR="${runtime_tmpdir}" \
  dart run tool/serverpod_critical_e2e.dart --host "${host}"

(
  cd "${repo_root}/clients/aonw_flutter"
  env -i \
    PATH="${runtime_path}" \
    HOME="${runtime_home}" \
    TMPDIR="${runtime_tmpdir}" \
    flutter test --no-pub \
      --dart-define="AONW_MULTIPLAYER_TEST_HOST=${host}" \
      test_live/multiplayer_server_test.dart
)
