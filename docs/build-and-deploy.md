# Build And Deploy Runbook

This document describes the public, repeatable build and deploy flow for Age of
New Worlds. It intentionally uses placeholders for private infrastructure. Keep
real hosts, SSH keys, service accounts, signing material, and `.env` files out
of source control.

## Local Quality Gate

From the repository root:

```sh
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
make check
```

For backend operations, also run:

```sh
make serverpod-ops-check
```

`serverpod-ops-check` validates generated Serverpod migrations and Docker
Compose config. It requires Docker and the Serverpod CLI.

## Local Docker Stack

Create a local environment file from placeholders:

```sh
cp .env.example .env
```

Replace every `replace-with-*` value before starting services:

```sh
docker compose --profile dev up --build
curl -fsS http://localhost:8080/livez
```

Stop the stack:

```sh
docker compose --profile dev down
```

Reset local database volumes:

```sh
docker compose --profile dev down -v
```

## Web And Homepage Builds

The Flutter web demo is built locally and uploaded to a static directory served
by Caddy or another web server:

```sh
flutter build web --wasm --release \
  --dart-define=AONW_API_BASE_URL=https://api.aonw.net
```

The static homepage is staged by:

```sh
make build-homepage
```

`make deploy-web` and `make deploy-homepage` are intentionally generic. Provide
the remote details at runtime:

```sh
make deploy-web \
  WEB_DEPLOY_SSH_KEY=/path/to/private-key \
  WEB_DEPLOY_USER=deploy \
  WEB_DEPLOY_HOST=example.com \
  WEB_DEPLOY_DEST=/srv/aonw/demo

make deploy-homepage \
  WEB_DEPLOY_SSH_KEY=/path/to/private-key \
  WEB_DEPLOY_USER=deploy \
  WEB_DEPLOY_HOST=example.com \
  HOMEPAGE_DEPLOY_DEST=/srv/aonw/homepage
```

## Server Deploy

Production and staging deploys should use a private environment file on the
host. Do not commit it.

Minimum production-style values:

```env
SERVERPOD_RUN_MODE=production
SERVERPOD_SERVER_ID=default
SERVERPOD_LOGGING_MODE=normal
SERVERPOD_SERVER_ROLE=monolith
SERVERPOD_APPLY_MIGRATIONS=true
SERVERPOD_DATABASE_HOST=<database-host>
SERVERPOD_DATABASE_PORT=5432
SERVERPOD_DATABASE_NAME=aonw
SERVERPOD_DATABASE_USER=aonw
SERVERPOD_DATABASE_PASSWORD=<database-password>
SERVERPOD_SERVICE_SECRET=<long-random-secret>
SERVERPOD_REDIS_ENABLED=true
SERVERPOD_REDIS_HOST=<redis-host>
SERVERPOD_PASSWORD_redis=<redis-password>
SERVERPOD_PASSWORD_emailSecretHashPepper=<long-random-secret>
SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey=<long-random-secret>
SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper=<long-random-secret>
AONW_SERVER_IMAGE=ghcr.io/<owner>/<image>:<tag>
```

Deploy with:

```sh
docker compose --env-file .env.prod --profile prod pull
docker compose --env-file .env.prod --profile prod up -d
curl -fsS https://api.aonw.net/livez
```

TLS and public routing should terminate in Caddy, a reverse proxy, or a cloud
load balancer. The included `deploy/caddy/Caddyfile` can serve the API,
Insights, homepage, and web demo when the corresponding environment variables
are set.

## Full Release Helper

`make deploy-all` coordinates version bumping, optional iOS archiving, desktop
ZIP preparation, itch.io Android APK preparation, optional itch.io upload, a
remote server deploy, homepage upload, web upload, and health checks. It
requires all remote values to be provided explicitly:

```sh
make deploy-all \
  REMOTE_DEPLOY_SSH_KEY=/path/to/private-key \
  REMOTE_DEPLOY_USER=deploy \
  REMOTE_DEPLOY_HOST=example.com \
  REMOTE_DEPLOY_PATH=/srv/aonw/repo \
  WEB_DEPLOY_SSH_KEY=/path/to/private-key \
  WEB_DEPLOY_USER=deploy \
  WEB_DEPLOY_HOST=example.com \
  HOMEPAGE_DEPLOY_DEST=/srv/aonw/homepage \
  WEB_DEPLOY_DEST=/srv/aonw/demo
```

The helper expects a clean `main` checkout and pushes `main` before triggering
artifact preparation and remote deploy. The desktop ZIP step runs `make steam`,
so macOS is built locally and Windows is built locally, downloaded from GitHub
Actions, or packaged from an existing release according to
`STEAM_WINDOWS_SOURCE`. It then copies neutral itch.io desktop ZIPs and builds a
universal Android APK for itch.io.

Set `ITCH_TARGET=user/game` to upload the prepared macOS, Windows, and Android
artifacts to itch.io during `deploy-all`. If `ITCH_TARGET` is omitted, the ZIPs
and APK are left in `dist/` and the itch.io upload is skipped. Uploading
requires `butler` to be installed and authenticated with `butler login` or
`BUTLER_API_KEY`.

## Platform Builds

Web:

```sh
flutter build web --wasm --release \
  --dart-define=AONW_API_BASE_URL=https://api.aonw.net
```

macOS:

```sh
flutter build macos --release \
  --dart-define=AONW_API_BASE_URL=https://api.aonw.net
```

Android release builds require local signing files that are not committed:

```sh
make android-keystore ANDROID_UPLOAD_KEYSTORE=/path/to/upload-keystore.jks
make android-release
```

iOS archives require local Xcode signing setup:

```sh
make archive-ios IOS_API_BASE_URL=https://api.aonw.net
```

Steam packaging:

```sh
make steam
```

On non-Windows hosts, `make steam` can download the Windows build from GitHub
Actions when `gh` is available and the workflow is configured.

itch.io packaging and upload:

```sh
make itch ITCH_TARGET=your-itch-user/age-of-new-worlds
```

This reuses the Steam desktop ZIP build flow, copies neutral itch archives to
`dist/aonw-macos-itch.zip` and `dist/aonw-windows-itch.zip`, builds
`dist/aonw-android-itch.apk`, and pushes them to the `macos`, `windows`, and
`android` itch channels. Override channels with `ITCH_MACOS_CHANNEL`,
`ITCH_WINDOWS_CHANNEL`, and `ITCH_ANDROID_CHANNEL`.

## Backups

PostgreSQL backup and restore helpers live under `deploy/postgres/`.

```sh
DATABASE_URL="$AONW_PRODUCTION_DATABASE_URL" \
  deploy/postgres/backup.sh

AONW_RESTORE_DATABASE_URL="$AONW_EMPTY_RESTORE_DATABASE_URL" \
  deploy/postgres/restore.sh <backup.dump>
```

Keep backups outside the repository. The default local backup directory is
ignored by `.gitignore`.

## Troubleshooting

- If Compose fails validation, run `make compose-check` with the same profile.
- If Serverpod migrations drift, run `make check-migrations` and review the
  generated diff.
- If the web app points to the wrong API, inspect the built artifact for the
  `AONW_API_BASE_URL` value used at build time.
- If remote deploy targets fail immediately, confirm the required
  `WEB_DEPLOY_*` and `REMOTE_DEPLOY_*` variables are set.
