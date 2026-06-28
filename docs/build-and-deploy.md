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
ZIP preparation, Steamworks upload, Google Play upload, itch.io Android APK
preparation, optional itch.io upload, a remote server deploy, homepage upload,
web upload, and health checks. It requires all remote values to be provided
explicitly:

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
`STEAM_WINDOWS_SOURCE`. Linux packaging is available as an opt-in path through
`STEAM_INCLUDE_LINUX=1` and `STEAM_LINUX_SOURCE`, but it should stay disabled
until the Linux Steam depot has been created in Steamworks. The helper then
expands neutral itch.io desktop folders and builds a universal Android APK for
itch.io.

By default, `deploy-all` uploads the prepared desktop build to Steamworks and
uploads an Android App Bundle to the Google Play closed-test track. Set
`DEPLOY_ALL_STEAMWORKS=0` or `DEPLOY_ALL_GOOGLE_PLAY=0` to skip either upload.
Google Play defaults to `DEPLOY_ALL_GOOGLE_PLAY_MODE=closed`, which uses
`ANDROID_PLAY_CLOSED_TRACK`; set it to a track name such as `internal`, `alpha`,
`beta`, or `production` to upload via `ANDROID_PLAY_TRACK`.

Set `ITCH_TARGET=user/game` to upload the prepared macOS, Windows, and Android
artifacts to itch.io during `deploy-all`. Set `ITCH_INCLUDE_LINUX=1` after the
itch Linux channel is ready to include the Linux desktop folder as well. If
`ITCH_TARGET` is omitted, the desktop upload folders are left in `build/itch/`,
the Android APK is left in `dist/`, and the itch.io upload is skipped. Uploading
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

itch.io packaging and upload:

```sh
make itch ITCH_TARGET=your-itch-user/age-of-new-worlds
```

This reuses the Steam desktop build flow, expands neutral itch desktop folders
under `build/itch/macos` and `build/itch/windows`, adds `.itch.toml` launch
manifests for the itch app, validates them with `butler validate`, builds
`dist/aonw-android-itch.apk`, and pushes only the two desktop folders plus the
Android APK to the `macos`, `windows`, and `android` itch channels. Set
`ITCH_INCLUDE_LINUX=1` to add `build/itch/linux` and push the `linux` channel.
Override channels with `ITCH_MACOS_CHANNEL`, `ITCH_WINDOWS_CHANNEL`,
`ITCH_LINUX_CHANNEL`, and `ITCH_ANDROID_CHANNEL`.

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
