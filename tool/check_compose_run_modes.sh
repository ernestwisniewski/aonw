#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
base_file="${repo_root}/compose.yml"
staging_file="${repo_root}/compose.staging.yml"
prod_file="${repo_root}/compose.prod.yml"

read -r -a compose_command <<<"${COMPOSE:-docker compose}"
if [[ "${#compose_command[@]}" -eq 0 ]]; then
  echo "COMPOSE must name a Docker Compose command." >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
poison_env="${tmp_dir}/poison.env"

cat >"${poison_env}" <<'EOF'
POSTGRES_PASSWORD=compose-run-mode-postgres
SERVERPOD_DATABASE_PASSWORD=compose-run-mode-postgres
SERVERPOD_SERVICE_SECRET=compose-run-mode-service-secret
SERVERPOD_PASSWORD_emailSecretHashPepper=compose-run-mode-email-pepper
SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey=compose-run-mode-jwt-key
SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper=compose-run-mode-refresh-pepper
SERVERPOD_PASSWORD_redis=compose-run-mode-redis
SERVERPOD_RUN_MODE=development
AONW_COMPOSE_RUN_MODE=test
AONW_STAGING_OVERLAY=1
AONW_PROD_OVERLAY=1
EOF

compose_config() {
  SERVERPOD_RUN_MODE=test \
    AONW_COMPOSE_RUN_MODE=test \
    AONW_STAGING_OVERLAY=1 \
    AONW_PROD_OVERLAY=1 \
    "${compose_command[@]}" \
    --project-directory "${repo_root}" \
    --env-file "${poison_env}" \
    "$@"
}

check_profile() {
  local profile="$1"
  local expected_mode="$2"
  local expected_services="$3"
  local expected_staging_overlay="$4"
  local expected_prod_overlay="$5"
  shift 5
  local -a files=("$@")

  echo "Checking Compose profile ${profile} -> ${expected_mode}..."
  local render
  render="$(compose_config "${files[@]}" --profile "${profile}" config)"

  local rendered_modes
  rendered_modes="$(
    printf '%s\n' "${render}" |
      awk '$1 == "AONW_COMPOSE_RUN_MODE:" { print $2 }'
  )"
  local rendered_mode_count
  rendered_mode_count="$(printf '%s\n' "${rendered_modes}" | awk 'NF { count++ } END { print count + 0 }')"
  if [[ "${rendered_mode_count}" -ne 1 || "${rendered_modes}" != "${expected_mode}" ]]; then
    echo "Profile ${profile} rendered unexpected AONW_COMPOSE_RUN_MODE values: ${rendered_modes:-<none>}" >&2
    exit 1
  fi

  if printf '%s\n' "${render}" | grep -Eq '^[[:space:]]+SERVERPOD_RUN_MODE:'; then
    echo "Profile ${profile} imported ambient SERVERPOD_RUN_MODE." >&2
    exit 1
  fi

  local rendered_staging_overlay
  rendered_staging_overlay="$(
    printf '%s\n' "${render}" |
      awk '$1 == "AONW_STAGING_OVERLAY:" { gsub(/"/, "", $2); print $2 }'
  )"
  local rendered_prod_overlay
  rendered_prod_overlay="$(
    printf '%s\n' "${render}" |
      awk '$1 == "AONW_PROD_OVERLAY:" { gsub(/"/, "", $2); print $2 }'
  )"
  if [[ "${rendered_staging_overlay:-absent}" != "${expected_staging_overlay}" ]]; then
    echo "Profile ${profile} rendered an unexpected staging overlay marker: ${rendered_staging_overlay:-<none>}" >&2
    exit 1
  fi
  if [[ "${rendered_prod_overlay:-absent}" != "${expected_prod_overlay}" ]]; then
    echo "Profile ${profile} rendered an unexpected production overlay marker: ${rendered_prod_overlay:-<none>}" >&2
    exit 1
  fi

  local services
  services="$(compose_config "${files[@]}" --profile "${profile}" config --services | sort)"
  if [[ "${services}" != "${expected_services}" ]]; then
    echo "Profile ${profile} rendered an unexpected service set." >&2
    printf 'Expected:\n%s\nActual:\n%s\n' "${expected_services}" "${services}" >&2
    exit 1
  fi
}

expect_config_failure() {
  local label="$1"
  local profile="$2"
  shift 2
  local -a files=("$@")

  if compose_config "${files[@]}" --profile "${profile}" config >/dev/null 2>&1; then
    echo "Compose config unexpectedly accepted ${label}." >&2
    exit 1
  fi
}

expect_no_active_services() {
  local label="$1"
  local profile="$2"
  shift 2
  local -a files=("$@")
  local services
  services="$(compose_config "${files[@]}" --profile "${profile}" config --services)"
  if [[ -n "${services}" ]]; then
    echo "Compose unexpectedly activated services for ${label}:" >&2
    printf '%s\n' "${services}" >&2
    exit 1
  fi
}

check_make_profile() {
  local profile="$1"
  local required_overlay="${2:-}"
  local forbidden_overlay="${3:-}"
  local dry_run
  dry_run="$(make --no-print-directory -C "${repo_root}" -n up PROFILE="${profile}")"

  if ! printf '%s\n' "${dry_run}" | grep -Fq -- "-f compose.yml"; then
    echo "Make did not select the base Compose file for ${profile}." >&2
    exit 1
  fi
  if ! printf '%s\n' "${dry_run}" | grep -Fq -- "--profile \"${profile}\""; then
    echo "Make did not select Compose profile ${profile}." >&2
    exit 1
  fi
  if [[ -n "${required_overlay}" ]] &&
    ! printf '%s\n' "${dry_run}" | grep -Fq -- "-f ${required_overlay}"; then
    echo "Make omitted ${required_overlay} for ${profile}." >&2
    exit 1
  fi
  if [[ -n "${forbidden_overlay}" ]] &&
    printf '%s\n' "${dry_run}" | grep -Fq -- "-f ${forbidden_overlay}"; then
    echo "Make selected forbidden ${forbidden_overlay} for ${profile}." >&2
    exit 1
  fi
}

expect_entrypoint_usage_failure() {
  local label="$1"
  shift

  set +e
  "$@" >/dev/null 2>&1
  local status=$?
  set -e
  if [[ "${status}" -ne 64 ]]; then
    echo "Entrypoint ${label} returned ${status}, expected 64." >&2
    exit 1
  fi
}

expect_combined_overlays_rejected() {
  local label="$1"
  local profile="$2"
  shift 2
  local -a files=("$@")
  local render
  render="$(compose_config "${files[@]}" --profile "${profile}" config)"

  local mode
  mode="$(printf '%s\n' "${render}" | awk '$1 == "AONW_COMPOSE_RUN_MODE:" { print $2 }')"
  local staging_overlay
  staging_overlay="$(printf '%s\n' "${render}" | awk '$1 == "AONW_STAGING_OVERLAY:" { gsub(/"/, "", $2); print $2 }')"
  local prod_overlay
  prod_overlay="$(printf '%s\n' "${render}" | awk '$1 == "AONW_PROD_OVERLAY:" { gsub(/"/, "", $2); print $2 }')"

  expect_entrypoint_usage_failure \
    "${label}" \
    env \
    AONW_COMPOSE_RUN_MODE="${mode}" \
    AONW_STAGING_OVERLAY="${staging_overlay}" \
    AONW_PROD_OVERLAY="${prod_overlay}" \
    sh "${repo_root}/server/docker-entrypoint.sh"
}

check_profile \
  dev \
  development \
  $'postgres\nredis\nserver' \
  absent \
  absent \
  -f "${base_file}"
check_profile \
  tunnel \
  development \
  $'cloudflared\npostgres\nredis\nserver' \
  absent \
  absent \
  -f "${base_file}"
check_profile \
  staging \
  staging \
  $'caddy\npostgres\nredis\nserver' \
  1 \
  absent \
  -f "${base_file}" -f "${staging_file}"
check_profile \
  prod \
  production \
  $'caddy\npostgres\nredis\nserver' \
  absent \
  1 \
  -f "${base_file}" -f "${prod_file}"

expect_config_failure "staging without its overlay" staging -f "${base_file}"
expect_config_failure "production without its overlay" prod -f "${base_file}"
expect_config_failure \
  "staging with the production overlay" \
  staging \
  -f "${base_file}" -f "${prod_file}"
expect_config_failure \
  "production with the staging overlay" \
  prod \
  -f "${base_file}" -f "${staging_file}"
expect_no_active_services \
  "development with the staging overlay" \
  dev \
  -f "${base_file}" -f "${staging_file}"
expect_no_active_services \
  "development with the production overlay" \
  dev \
  -f "${base_file}" -f "${prod_file}"
expect_config_failure \
  "tunnel with the staging overlay" \
  tunnel \
  -f "${base_file}" -f "${staging_file}"
expect_config_failure \
  "tunnel with the production overlay" \
  tunnel \
  -f "${base_file}" -f "${prod_file}"
expect_config_failure \
  "production with both overlays" \
  prod \
  -f "${base_file}" -f "${prod_file}" -f "${staging_file}"
expect_config_failure \
  "staging with both overlays" \
  staging \
  -f "${base_file}" -f "${staging_file}" -f "${prod_file}"
expect_combined_overlays_rejected \
  "accepted production and staging overlays together" \
  staging \
  -f "${base_file}" -f "${prod_file}" -f "${staging_file}"
expect_combined_overlays_rejected \
  "accepted staging and production overlays together" \
  prod \
  -f "${base_file}" -f "${staging_file}" -f "${prod_file}"

check_make_profile dev "" compose.staging.yml
check_make_profile dev "" compose.prod.yml
check_make_profile tunnel "" compose.staging.yml
check_make_profile tunnel "" compose.prod.yml
check_make_profile staging compose.staging.yml compose.prod.yml
check_make_profile prod compose.prod.yml compose.staging.yml

if make --no-print-directory -C "${repo_root}" profile-check PROFILE=invalid >/dev/null 2>&1; then
  echo "Make accepted an unsupported Compose profile." >&2
  exit 1
fi

expect_entrypoint_usage_failure \
  "accepted an invalid managed mode" \
  env AONW_COMPOSE_RUN_MODE=invalid sh "${repo_root}/server/docker-entrypoint.sh"
expect_entrypoint_usage_failure \
  "accepted an invalid direct-image mode" \
  env SERVERPOD_RUN_MODE=invalid sh "${repo_root}/server/docker-entrypoint.sh"
expect_entrypoint_usage_failure \
  "accepted caller-controlled arguments" \
  env AONW_COMPOSE_RUN_MODE=production sh "${repo_root}/server/docker-entrypoint.sh" --mode=development

echo "Compose run modes are deterministic and fail closed."
