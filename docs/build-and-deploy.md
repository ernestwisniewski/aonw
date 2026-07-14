# Build And Deploy Runbook

This runbook describes the repeatable build and deploy flow for Age of New
Worlds. It uses placeholders for private infrastructure; keep real hosts, SSH
keys, service accounts, signing material, and `.env` files out of source
control.

[ADR 0005](adr/0005-immutable-deployment.md) records the accepted build-once,
digest-promotion, migration, and rollback target. This runbook describes the
currently implemented workflow while that migration remains in progress.

## Release Principles

- Build from a clean `main` checkout.
- Pass local checks before release packaging.
- Keep secrets in local environment files or CI secrets.
- Use stable public download filenames without version numbers.
- Verify health endpoints after server, web, and homepage deploys.

## Common Commands

| Task | Command |
| --- | --- |
| Bootstrap pinned workspace | `make bootstrap` |
| Static analysis for every package | `make analyze` |
| Full local quality gate | `make ci` |
| Generated-code drift gate | `make generated-code-check` |
| Backend/deploy config checks | `make serverpod-ops-check` |
| Docker context secret guard | `make docker-context-check` |
| Stage homepage and `/stats` | `make build-homepage` |
| Deploy static homepage | `make deploy-homepage ...` |
| Deploy web demo | `make deploy-web ...` |
| Full release flow | `make deploy-all ...` |
| Publish latest downloads | `make deploy-downloads ...` |

## Local Checks

From the repository root:

```sh
make bootstrap
make ci
```

`.fvmrc` is the single Flutter SDK pin used locally and by every GitHub build;
Dart comes from that Flutter release. FVM is optional, and Make prefers its
ignored `.fvm/flutter_sdk` when present. Bootstrap checks the toolchain before
resolving the four committed lockfiles and ensuring the exact Serverpod CLI.
It does not generate code or start infrastructure.

`make ci` and repository CI both run `make generated-code-check`. The gate
recreates root and `aonw_core` build-runner output, Flutter localizations,
Serverpod protocol/client/test output, and migrations in an isolated snapshot
of the current workspace. It reports drift without rewriting the active
checkout and requires the Serverpod CLI version pinned in
`server/pubspec.yaml`.

When generator inputs change, regenerate only the affected artifacts in the
real checkout, then review and commit the diff:

```sh
flutter pub run build_runner build
(cd packages/aonw_core && dart run build_runner build)
flutter gen-l10n
(cd server && dart pub global run serverpod_cli:serverpod_cli generate)
(cd server && dart pub global run serverpod_cli:serverpod_cli create-migration)
make generated-code-check
```

For backend operations, also run:

```sh
make serverpod-ops-check
```

`serverpod-ops-check` validates all committed generated code and migrations,
Docker Compose config, and the server image context. The context guard uses
BuildKit with
synthetic secret, key, certificate, credential, and backup files to prove that
the checked-in `.dockerignore` excludes them while preserving required source,
map, and migration inputs. It requires Docker and the Serverpod CLI.
Root deployment profiles require Docker Compose 2.24.4 or newer because their
overlays use `!override` to replace, rather than merge, service profile lists.
The CLI must exactly match the runtime pin in `server/pubspec.yaml`. A normal
workspace bootstrap ensures it; the dedicated install remains available for
CLI-only repair:

```sh
make bootstrap
# or, for CLI-only repair:
make serverpod-cli-install
```

Before any multi-platform release, run the mandatory aggregate gate:

```sh
make release-check
```

`release-check` runs the full local CI suite (including generated-code and
migration drift), Compose validation, the PostgreSQL-backed endpoint smokes,
and the public auth/match/command/reconnect E2E journey.
`make deploy-all` invokes
this gate before changing the version, then invokes it again on the committed
release version before pushing `main` or uploading any artifacts.

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
docker compose -f compose.yml --profile dev down -v
```

## Static Sites

The Flutter web demo and public homepage are static assets served by Caddy or
another web server.

Build the web demo:

```sh
flutter build web --wasm --release \
  --dart-define=AONW_API_BASE_URL=https://api.aonw.net
```

Stage the homepage, including the extensionless `/stats` dashboard:

```sh
make build-homepage
```

The dashboard reads its aggregate, non-personal payload from the same-origin
`GET /api/stats` route. Caddy serves `/stats` as HTML, redirects `/stats/` to
the canonical path, and proxies only that exact API route to the Serverpod web
port. After a deploy, `make health-stats` validates both the page marker and
the versioned JSON contract.

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

The server image uses a default-deny build context. New compiler or runtime
inputs must be added explicitly to `.dockerignore`; never broaden it back to an
entire package or server tree. Run `make docker-context-check` after changing
the Dockerfile, migrations, map layout, or context rules. Secrets excluded from
the final runtime stage are still unsafe if they enter a remote builder or its
cache, so multi-stage builds do not replace this guard.

Minimum production-style values:

```env
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

Do not set `SERVERPOD_RUN_MODE` in this file. The required Compose overlay owns
that value: `compose.staging.yml` selects `staging`, while `compose.prod.yml`
selects `production`. This prevents a stale `.env` file or shell export from
silently starting a production stack in development mode.
For a direct image deployment outside the root Compose stack,
`SERVERPOD_RUN_MODE` remains the supported explicit override and defaults to
`production` when absent.

Deploy with:

```sh
docker compose --env-file .env.prod -f compose.yml -f compose.prod.yml --profile prod pull
docker compose --env-file .env.prod -f compose.yml -f compose.prod.yml --profile prod up -d
curl -fsS https://api.aonw.net/readyz
```

The production overlay is mandatory. Omitting it, or using the staging overlay
with the `prod` profile, leaves the application service inactive and the
Compose command fails instead of falling back to another run mode. The
canonical `make deploy PROFILE=prod` command selects the correct files
automatically.

Use `/livez` for process liveness and `/readyz` as the deploy gate. Readiness
also verifies the configured PostgreSQL and Redis dependencies, so a deploy
must not be considered complete until it returns successfully.

The bundled PostgreSQL and Redis services use unencrypted container-network
connections. Set `SERVERPOD_DATABASE_REQUIRE_SSL=true` and/or
`SERVERPOD_REDIS_REQUIRE_SSL=true` when an external managed service requires
TLS.

TLS and public routing should terminate in Caddy, a reverse proxy, or a cloud
load balancer. The included `deploy/caddy/Caddyfile` can serve the API,
homepage, multiplayer statistics dashboard, and web demo when the corresponding
environment variables are set. Insights is deliberately excluded from every
public route and bound to host loopback; use the SSH local-forward described in
`docs/serverpod-insights-runbook.md`. Production and staging `make up` runs
force a Caddy recreation so bind-mounted route changes take effect reliably.

## Full Release Flow

Start every release by reviewing the side-effect-free plan:

```sh
make deploy-all-plan
make deploy-all-plan DEPLOY_ALL_PLAN_FORMAT=json
```

The planner reads the current version, validates every public option, resolves
the requested next version/build, and prints the exact channel and step
selection. It does not require `main` or deployment credentials and does not
run Git mutations, quality gates, builds, SSH, or uploads. Unknown booleans and
enum values fail instead of behaving like a disabled option.

`make deploy-all` is the aggregate release command. The current artifact flow
always builds the macOS app locally, so its supported host is macOS. Windows and
Linux artifacts can come from a native workflow, GitHub Actions, or an existing
release directory according to the selected source. Provide remote values
explicitly:

```sh
make deploy-all \
  DEPLOY_ENV=staging \
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

Before the first quality gate or version commit, preflight requires a clean
`main`, validates the complete plan, host, credentials, destinations,
toolchains, Android signing setup, and selected artifact sources. The flow then:

1. runs the full quality gate on the current revision;
2. creates one version/build commit and runs the gate again;
3. applies the `off`, `best-effort`, or `required` iOS archive policy;
4. pushes the reviewed release commit to `origin/main`;
5. prepares desktop, Android, and public-download artifacts;
6. deploys the explicitly selected backend environment and verifies readiness;
7. performs only the explicitly enabled store actions;
8. promotes downloads, the homepage, and the web client, then runs final health
   checks.

Backend deployment therefore precedes client publication. `best-effort` skips
iOS only for a recognized missing environment (non-macOS host, no Flutter or
Xcode, or no workspace); once the environment is available, a build/signing
failure is fatal. Steam preparation and upload are fail-fast in one shell, so a
failed prepare cannot fall through to an upload using stale SteamPipe content.

Steamworks, Google Play, and itch.io are all disabled by default. Setting
`ITCH_TARGET` alone does not publish anything; `DEPLOY_ALL_ITCH=1` is required.
Google Play validate-only runs are reported as validation and never as a
published release.

### Release Options

This table mirrors the canonical registry in `tool/release/options.dart`.
Empty version/build overrides mean “use the documented default”.

| Variable | Allowed values | Default | Purpose |
| --- | --- | --- | --- |
| `DEPLOY_ENV` | `staging`, `prod` | `staging` | Backend deployment environment. |
| `DEPLOY_ALL_IOS_MODE` | `off`, `best-effort`, `required` | `best-effort` | iOS archive policy. |
| `DEPLOY_ALL_STEAMWORKS` | `0`, `1` | `0` | Enable Steamworks upload. |
| `DEPLOY_ALL_GOOGLE_PLAY` | `0`, `1` | `0` | Enable the Google Play action. |
| `DEPLOY_ALL_GOOGLE_PLAY_MODE` | `closed`, `internal`, `alpha`, `beta`, `production` | `closed` | Google Play destination track. |
| `DEPLOY_ALL_GOOGLE_PLAY_VALIDATE_ONLY` | `0`, `1` | `0` | Validate the Play upload without publishing. |
| `DEPLOY_ALL_ITCH` | `0`, `1` | `0` | Enable itch.io uploads. |
| `ITCH_TARGET` | `user/game`, empty | empty | Required only when itch.io is enabled. |
| `STEAM_INCLUDE_LINUX` | `0`, `1` | `0` | Include Linux in the Steam depot. |
| `ITCH_INCLUDE_LINUX` | `0`, `1` | `0` | Include Linux in itch.io uploads. |
| `DOWNLOAD_INCLUDE_LINUX` | `0`, `1` | `0` | Include Linux in public downloads. |
| `STEAM_WINDOWS_SOURCE` | `auto`, `local`, `github`, `existing` | `auto` | Windows artifact source. |
| `STEAM_LINUX_SOURCE` | `auto`, `local`, `github`, `existing` | `auto` | Linux artifact source. |
| `VERSION_BUMP` | `patch`, `none` | `patch` | Marketing-version policy. |
| `NEW_VERSION` | `x.y.z`, empty | empty | Optional semantic-version override. |
| `NEW_BUILD` | integer greater than current, empty | empty | Optional build override; empty means current + 1. |
| `DEPLOY_ALL_PLAN_FORMAT` | `human`, `json` | `human` | Planner output format. |

The three Linux flags are independent consumer decisions. Their logical OR
causes one Linux artifact/folder to be prepared; each destination still receives
Linux only when its own flag is `1`. In particular, public Linux downloads no
longer depend on enabling itch.io Linux.

The current slice makes planning and preflight strict and moves the backend
before client publication. A content-addressed release manifest, immutable
server image promotion, resumable partial releases, and automated rollback are
the next delivery stage; this command does not yet claim those guarantees.

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
- `make check-migrations` is a compatibility alias for the complete generated
  gate and verifies the Serverpod CLI before generation. If it reports drift,
  regenerate the affected output in the real checkout with the commands above
  and review that diff; the gate itself never rewrites the checkout.
- If the web app points to the wrong API, inspect the built artifact for the
  `AONW_API_BASE_URL` value used at build time.
- If remote deploy targets fail immediately, confirm the required
  `WEB_DEPLOY_*` and `REMOTE_DEPLOY_*` variables are set.
