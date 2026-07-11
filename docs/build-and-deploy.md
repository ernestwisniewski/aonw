# Build And Deploy Runbook

This runbook describes the repeatable build and deploy flow for Age of New
Worlds. It uses placeholders for private infrastructure; keep real hosts, SSH
keys, service accounts, signing material, and `.env` files out of source
control.

## Release Principles

- Build from a clean `main` checkout.
- Pass local checks before release packaging.
- Keep secrets in local environment files or CI secrets.
- Use stable public download filenames without version numbers.
- Verify health endpoints after server, web, and homepage deploys.

## Common Commands

| Task | Command |
| --- | --- |
| Full local quality gate | `make ci` |
| Backend/deploy config checks | `make serverpod-ops-check` |
| Stage static homepage | `make build-homepage` |
| Deploy static homepage | `make deploy-homepage ...` |
| Deploy web demo | `make deploy-web ...` |
| Full release flow | `make deploy-all ...` |
| Publish latest downloads | `make deploy-downloads ...` |

## Local Checks

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

Before any multi-platform release, run the mandatory aggregate gate:

```sh
make release-check
```

`release-check` runs the full local CI suite, Serverpod migration and Compose
validation, and the PostgreSQL-backed endpoint smoke. `make deploy-all` invokes
this gate before changing the version, pushing `main`, or uploading artifacts.

## Local Backend Stack

Create a local environment file from placeholders:

```sh
cp .env.example .env
```

Replace every `replace-with-*` value before starting services:

```sh
make local-start
```

This starts the Docker development profile, waits for
`http://localhost:8080/readyz`, and seeds four reusable multiplayer users. Run
the Flutter web client on the stable Google OAuth origin with:

```sh
make local
```

The web origin is `http://localhost:7357`; its API is the Docker Serverpod
service at `http://localhost:8080`. Exercise the automated multiplayer flow
against that same stack with `make local-multiplayer-smoke`.

Stop the stack:

```sh
make local-down
```

Reset local database volumes:

```sh
docker compose --profile dev down -v
```

## Static Sites

The Flutter web demo and public homepage are static assets served by Caddy or
another web server.

Build the web demo:

```sh
flutter build web --wasm --release \
  --dart-define=AONW_API_BASE_URL=https://api.aonw.net
```

Stage the homepage:

```sh
make build-homepage
```

Deploy targets are intentionally generic. Provide the remote values at runtime:

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
host. Do not commit that file.

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
SERVERPOD_DATABASE_REQUIRE_SSL=false
SERVERPOD_SERVICE_SECRET=<long-random-secret>
SERVERPOD_REDIS_ENABLED=true
SERVERPOD_REDIS_HOST=<redis-host>
SERVERPOD_REDIS_REQUIRE_SSL=false
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
curl -fsS https://api.aonw.net/readyz
```

Use `/livez` for process liveness and `/readyz` as the deploy gate. Readiness
also verifies the configured PostgreSQL and Redis dependencies, so a deploy
must not be considered complete until it returns successfully.

The bundled PostgreSQL and Redis services use unencrypted container-network
connections. Set `SERVERPOD_DATABASE_REQUIRE_SSL=true` and/or
`SERVERPOD_REDIS_REQUIRE_SSL=true` when an external managed service requires
TLS.

TLS and public routing should terminate in Caddy, a reverse proxy, or a cloud
load balancer. The included `deploy/caddy/Caddyfile` can serve the API,
Insights, homepage, and web demo when the corresponding environment variables
are set.

## Full Release Flow

`make deploy-all` is the main release command. It coordinates version bumping,
store packaging, server deploy, homepage deploy, public downloads, web deploy,
and health checks. Provide remote values explicitly:

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

The helper expects a clean `main` checkout and pushes `main` before release
work starts. By default it uploads the prepared desktop build to Steamworks and
an Android App Bundle to the Google Play closed-test track.

### Release Options

| Variable | Purpose |
| --- | --- |
| `DEPLOY_ALL_STEAMWORKS=0` | Skip Steamworks upload. |
| `DEPLOY_ALL_GOOGLE_PLAY=0` | Skip Google Play upload. |
| `DEPLOY_ALL_GOOGLE_PLAY_MODE=closed` | Upload to the configured closed-test track. |
| `DEPLOY_ALL_GOOGLE_PLAY_MODE=internal` | Upload to a named Play track instead. |
| `ITCH_TARGET=user/game` | Upload prepared macOS, Windows, and Android builds to itch.io. |
| `ITCH_INCLUDE_LINUX=1` | Include Linux after the itch Linux channel exists. |
| `STEAM_INCLUDE_LINUX=1` | Include Linux after the Steam Linux depot exists. |
| `DOWNLOAD_INCLUDE_LINUX=1` | Publish `aonw-linux.zip` under public downloads. |

### Public Downloads

The release flow can publish stable latest-download files under
`https://aonw.net/download/`. These filenames are overwritten on each release:

- `aonw-macos.zip`
- `aonw-windows.zip`
- `aonw-android.apk`
- `aonw-linux.zip` when `DOWNLOAD_INCLUDE_LINUX=1`

`deploy-homepage` excludes `/download/` from its `--delete` rsync pass so a
homepage-only deploy does not remove public build downloads.

Publish downloads without running the full release:

```sh
make deploy-downloads \
  WEB_DEPLOY_SSH_KEY=/path/to/private-key \
  WEB_DEPLOY_USER=deploy \
  WEB_DEPLOY_HOST=example.com \
  HOMEPAGE_DEPLOY_DEST=/srv/aonw/homepage \
  DOWNLOAD_INCLUDE_LINUX=1
```

## Store And Portal Packaging

### itch.io

`make itch` prepares neutral desktop folders, adds itch launch manifests,
validates them with `butler`, builds the Android APK, and uploads configured
channels when `ITCH_TARGET` is provided:

```sh
make itch ITCH_TARGET=your-itch-user/age-of-new-worlds
```

Uploading requires `butler` to be installed and authenticated with
`butler login` or `BUTLER_API_KEY`.

### Game Jolt

Game Jolt uses uploadable build files in packages/releases rather than the
`butler` folder push flow. `make gamejolt` writes neutral artifacts to `dist/`:

```sh
make gamejolt GAMEJOLT_INCLUDE_LINUX=1
```

Upload the generated `aonw-macos.zip`, `aonw-windows.zip`,
`aonw-linux.zip`, and `aonw-android.apk` manually in the Game Jolt
package/release dashboard, or upload them locally with GJPush:

```sh
make deploy-gamejolt \
  GAMEJOLT_TOKEN="$GJPUSH_TOKEN" \
  GAMEJOLT_PACKAGE_MACOS=... \
  GAMEJOLT_PACKAGE_WINDOWS=... \
  GAMEJOLT_PACKAGE_LINUX=... \
  GAMEJOLT_PACKAGE_ANDROID=... \
  GAMEJOLT_INCLUDE_LINUX=1
```

Package IDs are visible in the Game Jolt manage-package URLs.

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

Linux:

```sh
sudo apt-get install -y \
  clang cmake libgtk-3-dev libgstreamer-plugins-base1.0-dev \
  libgstreamer1.0-dev libsecret-1-dev libwebkit2gtk-4.1-dev \
  liblzma-dev ninja-build pkg-config unzip zip

flutter config --enable-linux-desktop
flutter build linux --release \
  --dart-define=AONW_API_BASE_URL=https://api.aonw.net
```

The release workflow `.github/workflows/linux-steam-build.yml` performs this on
Ubuntu 24.04 and publishes `dist/aonw-linux-steam.zip` as a GitHub Actions
artifact.

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

Linux Steam packaging is separate until the Steamworks Linux depot exists:

```sh
make steam-linux STEAM_LINUX_SOURCE=github
make steam STEAM_INCLUDE_LINUX=1
```

`steamcmd` uploads builds to depots that already exist. Create the Linux depot
first in Steamworks under **SteamPipe > Depots**, save and publish the partner
site changes, add the depot to the same packages as the macOS and Windows
depots, then rerun the command above. The default Linux depot id is `4833243`;
override `STEAM_LINUX_DEPOT_ID` if Steamworks assigns a different id in another
app. See the Steamworks
[Depots](https://partner.steamgames.com/doc/store/application/depots),
[Packages](https://partner.steamgames.com/doc/store/application/packages), and
[Builds](https://partner.steamgames.com/doc/store/application/builds)
documentation for the Steam object model.

Linux runtime notes:

- OAuth web login depends on `desktop_webview_window` and the system WebKitGTK
  runtime.
- Saved login state depends on Secret Service through
  `flutter_secure_storage_linux`.
- Audio playback depends on GStreamer runtime plugins.

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
