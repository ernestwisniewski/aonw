#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -e "${repo_root}/server/Dockerfile.dockerignore" ]]; then
  echo "server/Dockerfile.dockerignore would override the validated root .dockerignore." >&2
  exit 1
fi

if git -C "${repo_root}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  shopt -s nullglob
  migration_sql_files=(
    "${repo_root}"/server/migrations/*/definition.sql
    "${repo_root}"/server/migrations/*/migration.sql
  )
  for migration_file in "${migration_sql_files[@]}"; do
    relative_path="${migration_file#"${repo_root}/"}"
    git -C "${repo_root}" ls-files --error-unmatch -- "${relative_path}" >/dev/null 2>&1 || {
      echo "Canonical migration SQL must be tracked before it can enter Docker context: ${relative_path}" >&2
      exit 1
    }
  done
fi

fixture_root="$(mktemp -d)"
output_root="$(mktemp -d)"

cleanup() {
  rm -rf "${fixture_root}" "${output_root}"
}
trap cleanup EXIT INT TERM

write_fixture() {
  local relative_path="$1"
  mkdir -p "$(dirname "${fixture_root}/${relative_path}")"
  printf 'docker-context-guard\n' >"${fixture_root}/${relative_path}"
}

require_present() {
  local relative_path="$1"
  test -f "${output_root}/context/${relative_path}" || {
    echo "Required Docker context input was excluded: ${relative_path}" >&2
    exit 1
  }
}

require_absent() {
  local relative_path="$1"
  test ! -e "${output_root}/context/${relative_path}" || {
    echo "Sensitive or unrelated file entered Docker context: ${relative_path}" >&2
    exit 1
  }
}

cp "${repo_root}/.dockerignore" "${fixture_root}/.dockerignore"

allowed_paths=(
  server/pubspec.yaml
  server/pubspec.lock
  server/bin/main.dart
  server/lib/src/server.dart
  server/config/development.yaml
  server/config/staging.yaml
  server/config/production.yaml
  server/config/test.yaml
  server/docker-entrypoint.sh
  server/migrations/migration_registry.txt
  server/migrations/001/definition.sql
  server/migrations/001/migration.sql
  packages/aonw_core/pubspec.yaml
  packages/aonw_core/pubspec.lock
  packages/aonw_core/lib/domain.dart
  assets/maps/example/map.json
)

for path in "${allowed_paths[@]}"; do
  write_fixture "${path}"
done

forbidden_paths=(
  pubspec.yaml
  server/.env
  server/.env.production
  server/.env.example
  server/analysis_options.yaml
  server/compose.yml
  server/config/generator.yaml
  server/lib/runtime.env
  server/lib/.env.local
  server/lib/.envrc
  server/lib/.direnv/allow
  server/lib/debug.log
  server/lib/passwords.local.yaml
  server/lib/private.key
  server/lib/apple.p8
  server/lib/tls.pem
  server/lib/server.crt
  server/lib/chain.cer
  server/lib/signing.p12
  server/lib/signing.pfx
  server/lib/upload.jks
  server/lib/local.keystore
  server/lib/profile.mobileprovision
  server/lib/profile.provisionprofile
  server/lib/key.properties
  server/lib/id_rsa
  server/lib/id_ed25519
  server/lib/id_dsa
  server/lib/id_ecdsa
  server/lib/authorized_keys
  server/lib/known_hosts
  server/lib/ssh-private.ppk
  server/lib/private.pkcs8
  server/lib/private.pkcs12
  server/lib/signing.p7b
  server/lib/signing.p7c
  server/lib/.ssh/config
  server/lib/.aws/credentials
  server/lib/prod-credentials.json
  server/lib/aws-credentials.yaml
  server/lib/google-service-account.json
  server/lib/google-service-account.yml
  server/lib/google_service_account.json
  server/lib/client_secret.json
  server/lib/google-services.json
  server/lib/GoogleService-Info.plist
  server/lib/public.csr
  server/lib/chain.der
  server/lib/certs/chain.pem
  server/lib/certificates/chain.pem
  server/lib/backup/postgres.dump
  server/lib/backups/postgres.dump
  server/lib/database.backup
  server/lib/database.backup.gz
  server/lib/database.dmp
  server/lib/database.dmp.gz
  server/lib/database.pgdump
  server/lib/database.pgdump.gz
  server/lib/database.dump.gz
  server/lib/database.db
  server/lib/database.db-wal
  server/lib/database.sqlite
  server/lib/database.sqlite3
  server/lib/database.sqlite3-wal
  server/lib/archive.tar
  server/lib/archive.tar.gz
  server/lib/archive.tgz
  server/lib/archive.zip
  server/lib/archive.7z
  server/lib/archive.rar
  server/lib/raw.sql
  server/lib/raw.sql.gz
  server/lib/raw.sql.bz2
  server/lib/raw.sql.xz
  server/lib/raw.sql.zst
  server/migrations/001/seed.sql
  server/migrations/backups/migration.sql
  server/migrations/.ssh/definition.sql
  server/migrations/certs/migration.sql
  packages/aonw_core/analysis_options.yaml
  packages/aonw_core/tool/balance.dart
  packages/aonw_server_client/lib/client.dart
  assets/maps/.DS_Store
  assets/sounds/theme.wav
)

for path in "${forbidden_paths[@]}"; do
  write_fixture "${path}"
done

docker buildx build \
  --file - \
  --output "type=local,dest=${output_root}" \
  --progress=plain \
  "${fixture_root}" <<'DOCKERFILE'
FROM scratch
COPY . /context
DOCKERFILE

for path in "${allowed_paths[@]}"; do
  require_present "${path}"
done

for path in "${forbidden_paths[@]}"; do
  require_absent "${path}"
done

file_count="$(find "${output_root}/context" -type f | wc -l | tr -d ' ')"
if [[ "${file_count}" -ne "${#allowed_paths[@]}" ]]; then
  echo "Unexpected files entered Docker context: expected ${#allowed_paths[@]}, found ${file_count}." >&2
  exit 1
fi
echo "Docker context guard OK: ${file_count} required fixture files exported."
