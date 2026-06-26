SHELL := /bin/sh

COMPOSE ?= docker compose
PROFILE ?= staging
SERVER_SERVICE ?= server
BRANCH ?=
HEALTH_URL ?= https://api.aonw.net/livez
WEB_HEALTH_URL ?= https://demo.aonw.net/
HOMEPAGE_HEALTH_URL ?= https://aonw.net/
HEALTH_ATTEMPTS ?= 30
HEALTH_SLEEP ?= 2
PRUNE ?= 1
CACHE_FLAGS ?=
CLEAN_BUILD_CACHE ?= 0
CHECK_MIGRATIONS ?= 0
SERVERPOD_CLI ?= $(HOME)/.pub-cache/bin/serverpod
SERVERPOD_TEST_DATABASE_PASSWORD ?= aonw_dev
SERVERPOD_SMOKE_HOST ?= http://127.0.0.1:8080/
SERVERPOD_SMOKE_MAP ?= myranth
SERVERPOD_SEED_HOST ?= http://127.0.0.1:8080/
SERVERPOD_SEED_PASSWORD ?= AonwTest123!
SERVERPOD_SEED_EMAIL_DOMAIN ?= example.test
COMPOSE_CHECK_PROFILES ?= dev staging prod
PULL ?= 1
ifeq ($(PULL),1)
PULL_FLAGS ?= --pull
else
PULL_FLAGS ?=
endif

# deploy-web (local-only): builds the Flutter web bundle on the developer
# machine and rsyncs build/web/ to the staging server, where Caddy serves
# it from /srv/demo (bind-mounted in compose.yml).
WEB_API_BASE_URL ?= https://api.aonw.net
WEB_DEPLOY_SSH_KEY ?=
WEB_DEPLOY_USER ?=
WEB_DEPLOY_HOST ?=
WEB_DEPLOY_DEST ?=
HOMEPAGE_DEPLOY_DEST ?=
REMOTE_DEPLOY_SSH_KEY ?= $(WEB_DEPLOY_SSH_KEY)
REMOTE_DEPLOY_USER ?= $(WEB_DEPLOY_USER)
REMOTE_DEPLOY_HOST ?= $(WEB_DEPLOY_HOST)
REMOTE_DEPLOY_PATH ?=
HOMEPAGE_SOURCE_DIR ?= deploy/homepage
HOMEPAGE_BUILD_DIR ?= build/homepage
IOS_API_BASE_URL ?= https://api.aonw.net
IOS_ARCHIVE_ON_DEPLOY ?= auto
IOS_ARCHIVE_WORKSPACE ?= ios/Runner.xcworkspace
IOS_ARCHIVE_SCHEME ?= Runner
IOS_ARCHIVE_CONFIGURATION ?= Release
IOS_ARCHIVE_ROOT ?= $(HOME)/Library/Developer/Xcode/Archives
ANDROID_API_BASE_URL ?= https://api.aonw.net
ANDROID_JAVA_HOME ?= /Applications/Android Studio.app/Contents/jbr/Contents/Home
ANDROID_KEY_PROPERTIES ?= android/key.properties
ANDROID_UPLOAD_KEYSTORE ?=
ANDROID_KEY_ALIAS ?= upload
ANDROID_KEYTOOL ?= $(ANDROID_JAVA_HOME)/bin/keytool
ANDROID_RELEASE_BUNDLE ?= build/app/outputs/bundle/release/app-release.aab
ANDROID_RELEASE_APK_DIR ?= build/app/outputs/flutter-apk
ANDROID_PACKAGE_NAME ?= aonw.net.game
ANDROID_PLAY_FASTLANE ?= fastlane
ANDROID_PLAY_JSON_KEY ?= $(HOME)/.config/aonw/google-play-service-account.json
ANDROID_PLAY_TRACK ?= internal
ANDROID_PLAY_CLOSED_TRACK ?= alpha
ANDROID_PLAY_RELEASE_STATUS ?= completed
ANDROID_PLAY_VALIDATE_ONLY ?= 0
ANDROID_PLAY_SUPPLY_ARGS ?=
PLATFORM_SMOKE_API_BASE_URL ?= https://api.aonw.net
PLATFORM_SMOKE_WEB ?= 1
PLATFORM_SMOKE_MACOS ?= auto
PLATFORM_SMOKE_IOS ?= auto
PLATFORM_SMOKE_ANDROID ?= 1
PLATFORM_SMOKE_WINDOWS ?= auto
STEAM_API_BASE_URL ?= https://api.aonw.net
STEAM_DIST_DIR ?= dist
STEAM_MACOS_APP_NAME ?= aonw.app
STEAM_MACOS_BUILD_DIR ?= build/macos/Build/Products/Release
STEAM_MACOS_APP ?= $(STEAM_MACOS_BUILD_DIR)/$(STEAM_MACOS_APP_NAME)
STEAM_MACOS_ZIP ?= $(STEAM_DIST_DIR)/aonw-macos-steam.zip
STEAM_WINDOWS_RELEASE_DIR ?= build/windows/x64/runner/Release
STEAM_WINDOWS_ZIP ?= $(STEAM_DIST_DIR)/aonw-windows-steam.zip
STEAM_WINDOWS_SOURCE ?= auto
STEAM_WINDOWS_WORKFLOW ?= windows-steam-build.yml
STEAM_WINDOWS_ARTIFACT_DIR ?= build/steam-windows-artifact
STEAM_GITHUB_RUN_LOOKUP_ATTEMPTS ?= 30
STEAM_GITHUB_RUN_LOOKUP_SLEEP ?= 5
STEAM_DEPLOY_DIR ?= $(HOME)/Desktop/steam-deploy
STEAM_CONTENT_DIR ?= $(STEAM_DEPLOY_DIR)/content
STEAM_SCRIPT_DIR ?= $(STEAM_DEPLOY_DIR)/scripts
STEAM_OUTPUT_DIR ?= $(STEAM_DEPLOY_DIR)/output
STEAM_WINDOWS_DIST_ZIP ?= $(STEAM_WINDOWS_ZIP)
STEAM_APP_ID ?= 4833240
STEAM_MACOS_DEPOT_ID ?= 4833241
STEAM_WINDOWS_DEPOT_ID ?= 4833242
STEAM_USER ?= ew2pl
STEAMCMD ?= steamcmd
STEAM_BUILD_DESC ?=

# bump-version: updates the marketing version and build number in pubspec.yaml,
# iOS Runner MARKETING_VERSION/CURRENT_PROJECT_VERSION, and the Windows fallback
# version string. By default it increments the patch marketing version and the
# build number, which creates a fresh App Store release train. Use NEW_BUILD=42
# to set the build explicitly, NEW_VERSION=1.2.3 to force a marketing version,
# or VERSION_BUMP=none to keep the current marketing version.
PUBSPEC ?= pubspec.yaml
PBXPROJ ?= ios/Runner.xcodeproj/project.pbxproj
WINDOWS_RC ?= windows/runner/Runner.rc
VERSION_BUMP ?= patch
RELEASE_VERSION ?= $(shell sed -n 's/^version:[[:space:]]*//p' "$(PUBSPEC)" 2>/dev/null | head -n 1)
ENV_RELEASE_CHANNEL ?= $(shell awk -F= '/^AONW_RELEASE_CHANNEL=/{print $$2; exit}' .env 2>/dev/null)
AONW_APP_VERSION ?= $(RELEASE_VERSION)
AONW_RELEASE_CHANNEL ?= $(if $(ENV_RELEASE_CHANNEL),$(ENV_RELEASE_CHANNEL),ALPHA)

.DEFAULT_GOAL := help

.PHONY: help ci format-check check flutter-test core-test client-test deploy deploy-all deploy-clean build-web deploy-web deploy-homepage build-homepage archive-ios archive-ios-if-possible android-keystore android-preflight android-play-preflight android-build-aab android-build-apk android-release android-upload-aab android-upload-closed android-deploy android-deploy-closed multiplayer-platform-smoke steam deploy-steam steam-macos steam-windows steam-windows-local steam-windows-github steam-package-windows steam-prepare-from-dist steam-upload steam-upload-command steam-release-from-dist bump-version preflight-release preflight pull build server-test server-integration-test serverpod-runtime-smoke serverpod-seed-test-users compose-check serverpod-ops-check check-migrations migrate up health health-web health-homepage prune status logs

help:
	@echo "AONW deploy helpers"
	@echo ""
	@echo "Quick release flow:"
	@echo "  make deploy-all    Bump build, archive iOS if possible, push, then deploy all"
	@echo "  make deploy steam  Build Steam macOS + Windows ZIPs into dist/"
	@echo ""
	@echo "Individual targets:"
	@echo "  make ci           LOCAL: format, analyze, and test the same local gate expected before PRs"
	@echo "  make check        LOCAL: analyze/test Flutter app, core package, client package, and server"
	@echo "  make deploy        Pull repo, rebuild Docker, restart staging, check health"
	@echo "  make deploy-clean  Same, but build server without cache and prune build cache"
	@echo "  make build-web     LOCAL: build Flutter web bundle without deploying"
	@echo "  make deploy-web    LOCAL: build Flutter web bundle and rsync to demo host dir"
	@echo "  make deploy-homepage LOCAL: stage static aonw.net homepage and rsync to staging"
	@echo "  make archive-ios   LOCAL: create an Xcode Organizer archive for current build"
	@echo "  make android-keystore Create an Android upload keystore"
	@echo "  make android-release LOCAL: test and build Play Store .aab"
	@echo "  make android-upload-aab LOCAL: upload existing .aab to Google Play"
	@echo "  make android-upload-closed LOCAL: upload existing .aab to closed test"
	@echo "  make android-deploy LOCAL: build .aab and upload it to Google Play"
	@echo "  make android-deploy-closed LOCAL: build .aab and upload it to closed test"
	@echo "  make android-build-apk LOCAL: build split release APKs for sideload testing"
	@echo "  make multiplayer-platform-smoke LOCAL: build web/macOS/iOS/Android/Windows smoke targets"
	@echo "  make steam        LOCAL/CI: build Steam ZIPs into dist/"
	@echo "  make steam-prepare-from-dist LOCAL: prepare SteamPipe content from dist/ ZIPs"
	@echo "  make steam-upload LOCAL: upload prepared SteamPipe content with steamcmd"
	@echo "  make deploy-steam LOCAL: build macOS, use Windows ZIP from dist/, upload Steam build"
	@echo "  make bump-version  Bump marketing/build version in pubspec.yaml + platform files"
	@echo "  make build         Build server image"
	@echo "  make server-test   LOCAL: analyze server and run non-integration Dart tests"
	@echo "  make server-integration-test LOCAL: run Serverpod integration tests"
	@echo "  make serverpod-runtime-smoke LOCAL: run two-account stream/reconnect smoke against a running Serverpod host"
	@echo "  make serverpod-seed-test-users LOCAL: create/update four local Serverpod test users"
	@echo "  make compose-check LOCAL: validate Docker Compose files without starting services"
	@echo "  make serverpod-ops-check LOCAL: validate Serverpod migrations and Compose config"
	@echo "  make check-migrations LOCAL: regenerate Serverpod code/migrations and fail if repo changed"
	@echo "  make migrate       Explain Serverpod startup migration flow"
	@echo "  make health        Check deployed Serverpod health endpoint"
	@echo "  make health-web    Check deployed demo web frontend"
	@echo "  make health-homepage Check deployed aonw.net homepage"
	@echo "  make status        Show Docker Compose service status"
	@echo "  make logs          Follow server logs"
	@echo ""
	@echo "Options:"
	@echo "  PROFILE=staging|prod|dev       Default: $(PROFILE)"
	@echo "  BRANCH=main                    Optional branch checkout before pull"
	@echo "  CHECK_MIGRATIONS=1             Run local Serverpod migration drift check after build"
	@echo "  SERVERPOD_TEST_DATABASE_PASSWORD=... server-integration-test only. Default: $(SERVERPOD_TEST_DATABASE_PASSWORD)"
	@echo "  SERVERPOD_SMOKE_HOST=http://... serverpod-runtime-smoke only. Default: $(SERVERPOD_SMOKE_HOST)"
	@echo "  SERVERPOD_SMOKE_MAP=myranth      serverpod-runtime-smoke only. Default: $(SERVERPOD_SMOKE_MAP)"
	@echo "  SERVERPOD_SEED_HOST=http://...  serverpod-seed-test-users only. Default: $(SERVERPOD_SEED_HOST)"
	@echo "  SERVERPOD_SEED_PASSWORD=...     serverpod-seed-test-users only. Default: $(SERVERPOD_SEED_PASSWORD)"
	@echo "  SERVERPOD_SEED_EMAIL_DOMAIN=... serverpod-seed-test-users only. Default: $(SERVERPOD_SEED_EMAIL_DOMAIN)"
	@echo "  SERVERPOD_PASSWORD_redis=...     Required by Compose when Redis is enabled"
	@echo "  COMPOSE_CHECK_PROFILES=\"dev staging prod\" compose-check profiles. Default: $(COMPOSE_CHECK_PROFILES)"
	@echo "  PULL=0                         Build from cached base images"
	@echo "  AONW_APP_VERSION=x.y.z+n      Server image app version. Default: $(AONW_APP_VERSION)"
	@echo "  HEALTH_URL=https://.../livez  Default: $(HEALTH_URL)"
	@echo "  WEB_HEALTH_URL=https://...    Default: $(WEB_HEALTH_URL)"
	@echo "  HOMEPAGE_HEALTH_URL=https://... Default: $(HOMEPAGE_HEALTH_URL)"
	@echo "  WEB_API_BASE_URL=https://...  deploy-web only. Default: $(WEB_API_BASE_URL)"
	@echo "  WEB_DEPLOY_SSH_KEY=/path      deploy-web/deploy-homepage only. Required"
	@echo "  WEB_DEPLOY_USER=user          deploy-web/deploy-homepage only. Required"
	@echo "  WEB_DEPLOY_HOST=host          deploy-web/deploy-homepage only. Required"
	@echo "  WEB_DEPLOY_DEST=/path         deploy-web only. Required"
	@echo "  HOMEPAGE_DEPLOY_DEST=/path    deploy-homepage only. Required"
	@echo "  REMOTE_DEPLOY_PATH=/path      deploy-all remote repo path. Required"
	@echo "  IOS_ARCHIVE_ON_DEPLOY=auto|1|0 deploy-all archive behavior. Default: $(IOS_ARCHIVE_ON_DEPLOY)"
	@echo "  IOS_API_BASE_URL=https://...  archive-ios only. Default: $(IOS_API_BASE_URL)"
	@echo "  ANDROID_API_BASE_URL=https://... android-release only. Default: $(ANDROID_API_BASE_URL)"
	@echo "  ANDROID_JAVA_HOME=/path/to/jdk android-release only. Default: $(ANDROID_JAVA_HOME)"
	@echo "  ANDROID_UPLOAD_KEYSTORE=path  android-keystore only. Required"
	@echo "  ANDROID_PLAY_JSON_KEY=path    Android Play upload only. Default: $(ANDROID_PLAY_JSON_KEY)"
	@echo "  ANDROID_PLAY_TRACK=internal|alpha|beta|production android-deploy only. Default: $(ANDROID_PLAY_TRACK)"
	@echo "  ANDROID_PLAY_CLOSED_TRACK=alpha Android closed test track. Default: $(ANDROID_PLAY_CLOSED_TRACK)"
	@echo "  ANDROID_PLAY_RELEASE_STATUS=completed|draft|inProgress|halted android-deploy only. Default: $(ANDROID_PLAY_RELEASE_STATUS)"
	@echo "  ANDROID_PLAY_VALIDATE_ONLY=1  Validate Google Play upload without committing it"
	@echo "  PLATFORM_SMOKE_API_BASE_URL=https://... multiplayer-platform-smoke only. Default: $(PLATFORM_SMOKE_API_BASE_URL)"
	@echo "  PLATFORM_SMOKE_WEB=1|0        multiplayer-platform-smoke web build. Default: $(PLATFORM_SMOKE_WEB)"
	@echo "  PLATFORM_SMOKE_MACOS=auto|1|0 multiplayer-platform-smoke macOS build. Default: $(PLATFORM_SMOKE_MACOS)"
	@echo "  PLATFORM_SMOKE_IOS=auto|1|0   multiplayer-platform-smoke iOS simulator build. Default: $(PLATFORM_SMOKE_IOS)"
	@echo "  PLATFORM_SMOKE_ANDROID=1|0    multiplayer-platform-smoke Android debug build. Default: $(PLATFORM_SMOKE_ANDROID)"
	@echo "  PLATFORM_SMOKE_WINDOWS=auto|1|0 multiplayer-platform-smoke Windows debug build. Default: $(PLATFORM_SMOKE_WINDOWS)"
	@echo "  STEAM_API_BASE_URL=https://... Steam builds only. Default: $(STEAM_API_BASE_URL)"
	@echo "  STEAM_WINDOWS_SOURCE=auto|local|github|existing Steam Windows source. Default: $(STEAM_WINDOWS_SOURCE)"
	@echo "  STEAM_DEPLOY_DIR=/path        SteamPipe working dir. Default: $(STEAM_DEPLOY_DIR)"
	@echo "  STEAM_WINDOWS_DIST_ZIP=path   Windows ZIP/artifact for steam-prepare-from-dist. Default: $(STEAM_WINDOWS_DIST_ZIP)"
	@echo "  STEAM_USER=user               SteamCMD username. Default: $(STEAM_USER)"
	@echo "  STEAM_BUILD_DESC=text         Steam build description. Default: Build N - x.y.z release"
	@echo "  VERSION_BUMP=patch|none       bump-version/deploy-all default: $(VERSION_BUMP)"
	@echo "  NEW_VERSION=x.y.z             bump-version/deploy-all only. Overrides VERSION_BUMP"
	@echo "  NEW_BUILD=N                   bump-version/deploy-all only. Default: current+1"

ifneq ($(filter steam,$(MAKECMDGOALS)),)
deploy: steam
	@echo "deploy steam finished."
else
deploy: preflight pull build up health
	@if [ "$(PRUNE)" = "1" ]; then \
		$(MAKE) --no-print-directory prune CLEAN_BUILD_CACHE="$(CLEAN_BUILD_CACHE)"; \
	fi
	@echo "Deploy finished."
endif

deploy-clean: CACHE_FLAGS := --no-cache
deploy-clean: CLEAN_BUILD_CACHE := 1
deploy-clean: deploy

preflight:
	@test -f compose.yml || { echo "compose.yml not found. Run make from repo root."; exit 1; }
	@test -f .env || { echo ".env not found. Create it from .env.example on the server."; exit 1; }
	@command -v git >/dev/null || { echo "git is required."; exit 1; }
	@command -v docker >/dev/null || { echo "docker is required."; exit 1; }
	@$(COMPOSE) version >/dev/null || { echo "docker compose is required."; exit 1; }
	@if [ -n "$$(git status --porcelain --untracked-files=no)" ]; then \
		echo "Tracked local changes detected. Commit/stash them before deploy:"; \
		git status --short --untracked-files=no; \
		exit 1; \
	fi

pull:
	@if [ -n "$(BRANCH)" ]; then git checkout "$(BRANCH)"; fi
	@git fetch --prune
	@git pull --ff-only

build:
	@test -n "$(AONW_APP_VERSION)" || { echo "Could not parse AONW_APP_VERSION from $(PUBSPEC)."; exit 1; }
	@echo "Building server image with AONW_APP_VERSION=$(AONW_APP_VERSION), AONW_RELEASE_CHANNEL=$(AONW_RELEASE_CHANNEL)"
	@AONW_APP_VERSION="$(AONW_APP_VERSION)" AONW_RELEASE_CHANNEL="$(AONW_RELEASE_CHANNEL)" $(COMPOSE) --profile "$(PROFILE)" build $(PULL_FLAGS) $(CACHE_FLAGS) "$(SERVER_SERVICE)"
	@if [ "$(CHECK_MIGRATIONS)" = "1" ]; then \
		$(MAKE) --no-print-directory check-migrations PROFILE="$(PROFILE)" SERVER_SERVICE="$(SERVER_SERVICE)" COMPOSE="$(COMPOSE)"; \
	fi

ci: format-check check

format-check:
	@dart format --set-exit-if-changed .

check: flutter-test core-test client-test server-test

flutter-test:
	@flutter analyze --no-pub
	@flutter test

core-test:
	@cd packages/aonw_core && dart analyze --fatal-infos
	@cd packages/aonw_core && dart test

client-test:
	@cd packages/aonw_server_client && dart analyze --fatal-infos
	@cd packages/aonw_server_client && dart test

server-test:
	@cd server && dart analyze --fatal-infos
	@cd server && dart test

server-integration-test:
	@cd server && \
		SERVERPOD_PASSWORD_database="$(SERVERPOD_TEST_DATABASE_PASSWORD)" \
		SERVERPOD_PASSWORD_emailSecretHashPepper="$${SERVERPOD_PASSWORD_emailSecretHashPepper:-test-email-secret-hash-pepper}" \
		SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey="$${SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey:-test-jwt-hmac-sha512-private-key}" \
		SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper="$${SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper:-test-jwt-refresh-token-hash-pepper}" \
		dart test test/integration/multiplayer_endpoint_smoke.dart -P integration --chain-stack-traces

serverpod-runtime-smoke:
	@dart run tool/serverpod_multiplayer_smoke.dart --host "$(SERVERPOD_SMOKE_HOST)" --map "$(SERVERPOD_SMOKE_MAP)"

serverpod-seed-test-users:
	@dart run tool/serverpod_seed_test_users.dart --host "$(SERVERPOD_SEED_HOST)" --password "$(SERVERPOD_SEED_PASSWORD)" --email-domain "$(SERVERPOD_SEED_EMAIL_DOMAIN)"

compose-check:
	@command -v docker >/dev/null || { echo "docker is required."; exit 1; }
	@$(COMPOSE) version >/dev/null || { echo "docker compose is required."; exit 1; }
		@for profile in $(COMPOSE_CHECK_PROFILES); do \
			echo "Checking root compose.yml for profile $$profile..."; \
			POSTGRES_PASSWORD="$${POSTGRES_PASSWORD:-compose-config-postgres-password}" \
			SERVERPOD_DATABASE_PASSWORD="$${SERVERPOD_DATABASE_PASSWORD:-compose-config-postgres-password}" \
			SERVERPOD_SERVICE_SECRET="$${SERVERPOD_SERVICE_SECRET:-compose-config-service-secret}" \
			SERVERPOD_PASSWORD_emailSecretHashPepper="$${SERVERPOD_PASSWORD_emailSecretHashPepper:-compose-config-email-pepper}" \
			SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey="$${SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey:-compose-config-jwt-key}" \
			SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper="$${SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper:-compose-config-refresh-pepper}" \
			SERVERPOD_PASSWORD_redis="$${SERVERPOD_PASSWORD_redis:-compose-config-redis-password}" \
			$(COMPOSE) --profile "$$profile" config >/dev/null; \
		done
		@echo "Checking server/compose.yml..."
		@cd server && \
			POSTGRES_PASSWORD="$${POSTGRES_PASSWORD:-compose-config-postgres-password}" \
			SERVERPOD_PASSWORD_redis="$${SERVERPOD_PASSWORD_redis:-compose-config-redis-password}" \
			$(COMPOSE) config >/dev/null
	@echo "Docker Compose config OK."

serverpod-ops-check: check-migrations compose-check

build-web:
	@command -v flutter >/dev/null || { echo "flutter SDK is required for build-web."; exit 1; }
	@command -v rg >/dev/null || { echo "rg is required for build-web."; exit 1; }
	@test -n "$(WEB_API_BASE_URL)" || { echo "WEB_API_BASE_URL is required."; exit 1; }
	@echo "Building Flutter web (wasm + js fallback) with API=$(WEB_API_BASE_URL)..."
	@flutter build web --wasm --release --dart-define=AONW_API_BASE_URL=$(WEB_API_BASE_URL)
	@rg -a -F "$(WEB_API_BASE_URL)" build/web >/dev/null
	@echo "Verified web build API: $(WEB_API_BASE_URL)"

# Local-only target. Runs on the developer machine: builds the Flutter web
# bundle and rsyncs build/web/ to the staging server. Caddy on the server
# bind-mounts build/demo read-only and serves it as static files, so no
# container restart is needed — overwriting files is enough.
deploy-web:
	@command -v rsync >/dev/null || { echo "rsync is required for deploy-web."; exit 1; }
	@test -n "$(WEB_DEPLOY_SSH_KEY)" || { echo "WEB_DEPLOY_SSH_KEY is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_USER)" || { echo "WEB_DEPLOY_USER is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_HOST)" || { echo "WEB_DEPLOY_HOST is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_DEST)" || { echo "WEB_DEPLOY_DEST is required."; exit 1; }
	@test -f "$(WEB_DEPLOY_SSH_KEY)" || { echo "SSH key not found: $(WEB_DEPLOY_SSH_KEY)"; exit 1; }
	@$(MAKE) --no-print-directory build-web WEB_API_BASE_URL="$(WEB_API_BASE_URL)"
	@echo "Uploading build/web/ -> $(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST):$(WEB_DEPLOY_DEST)/..."
	@ssh -i "$(WEB_DEPLOY_SSH_KEY)" $(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST) 'mkdir -p "$(WEB_DEPLOY_DEST)"'
	@rsync -avz --delete \
	  --exclude='Dockerfile*' \
	  -e "ssh -i $(WEB_DEPLOY_SSH_KEY)" \
	  build/web/ $(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST):$(WEB_DEPLOY_DEST)/
	@echo "deploy-web finished. Checking $(WEB_HEALTH_URL) ..."
	@$(MAKE) --no-print-directory health-web

build-homepage:
	@test -f "$(HOMEPAGE_SOURCE_DIR)/index.html" || { echo "$(HOMEPAGE_SOURCE_DIR)/index.html not found"; exit 1; }
	@test -f "$(HOMEPAGE_SOURCE_DIR)/privacy-policy/index.html" || { echo "$(HOMEPAGE_SOURCE_DIR)/privacy-policy/index.html not found"; exit 1; }
	@test -f assets/logo.png || { echo "assets/logo.png not found"; exit 1; }
	@test -f assets/aonw-mobile.png || { echo "assets/aonw-mobile.png not found"; exit 1; }
	@test -f assets/fonts/Cinzel-VariableFont_wght.ttf || { echo "assets/fonts/Cinzel-VariableFont_wght.ttf not found"; exit 1; }
	@test -f assets/fonts/Lato-Regular.ttf || { echo "assets/fonts/Lato-Regular.ttf not found"; exit 1; }
	@test -f assets/fonts/Lato-Bold.ttf || { echo "assets/fonts/Lato-Bold.ttf not found"; exit 1; }
	@test -f assets/main_menu/background.png || { echo "assets/main_menu/background.png not found"; exit 1; }
	@test -f web/favicon.png || { echo "web/favicon.png not found"; exit 1; }
	@test -f web/icons/Icon-192.png || { echo "web/icons/Icon-192.png not found"; exit 1; }
	@rm -rf "$(HOMEPAGE_BUILD_DIR)"
	@mkdir -p "$(HOMEPAGE_BUILD_DIR)/assets/main_menu" "$(HOMEPAGE_BUILD_DIR)/assets/fonts"
	@cp "$(HOMEPAGE_SOURCE_DIR)/index.html" "$(HOMEPAGE_BUILD_DIR)/index.html"
	@cp "$(HOMEPAGE_SOURCE_DIR)/privacy-policy/index.html" "$(HOMEPAGE_BUILD_DIR)/privacy-policy"
	@cp web/favicon.png "$(HOMEPAGE_BUILD_DIR)/favicon.png"
	@cp web/icons/Icon-192.png "$(HOMEPAGE_BUILD_DIR)/apple-touch-icon.png"
	@cp assets/logo.png "$(HOMEPAGE_BUILD_DIR)/assets/logo.png"
	@cp assets/aonw-mobile.png "$(HOMEPAGE_BUILD_DIR)/assets/aonw-mobile.png"
	@cp assets/fonts/Cinzel-VariableFont_wght.ttf "$(HOMEPAGE_BUILD_DIR)/assets/fonts/Cinzel-VariableFont_wght.ttf"
	@cp assets/fonts/Lato-Regular.ttf "$(HOMEPAGE_BUILD_DIR)/assets/fonts/Lato-Regular.ttf"
	@cp assets/fonts/Lato-Bold.ttf "$(HOMEPAGE_BUILD_DIR)/assets/fonts/Lato-Bold.ttf"
	@cp assets/main_menu/background.png "$(HOMEPAGE_BUILD_DIR)/assets/main_menu/background.png"
	@echo "Static homepage staged in $(HOMEPAGE_BUILD_DIR)/"

deploy-homepage: build-homepage
	@command -v rsync >/dev/null || { echo "rsync is required for deploy-homepage."; exit 1; }
	@test -n "$(WEB_DEPLOY_SSH_KEY)" || { echo "WEB_DEPLOY_SSH_KEY is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_USER)" || { echo "WEB_DEPLOY_USER is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_HOST)" || { echo "WEB_DEPLOY_HOST is required."; exit 1; }
	@test -n "$(HOMEPAGE_DEPLOY_DEST)" || { echo "HOMEPAGE_DEPLOY_DEST is required."; exit 1; }
	@test -f "$(WEB_DEPLOY_SSH_KEY)" || { echo "SSH key not found: $(WEB_DEPLOY_SSH_KEY)"; exit 1; }
	@echo "Uploading $(HOMEPAGE_BUILD_DIR)/ -> $(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST):$(HOMEPAGE_DEPLOY_DEST)/..."
	@ssh -i "$(WEB_DEPLOY_SSH_KEY)" $(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST) 'mkdir -p "$(HOMEPAGE_DEPLOY_DEST)"'
	@rsync -avz --delete \
	  -e "ssh -i $(WEB_DEPLOY_SSH_KEY)" \
	  "$(HOMEPAGE_BUILD_DIR)/" $(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST):$(HOMEPAGE_DEPLOY_DEST)/
	@echo "deploy-homepage finished. Checking $(HOMEPAGE_HEALTH_URL) ..."
	@$(MAKE) --no-print-directory health-homepage

archive-ios:
	@command -v flutter >/dev/null || { echo "flutter SDK is required for archive-ios."; exit 1; }
	@command -v xcodebuild >/dev/null || { echo "xcodebuild is required for archive-ios."; exit 1; }
	@test -d "$(IOS_ARCHIVE_WORKSPACE)" || { echo "Xcode workspace not found: $(IOS_ARCHIVE_WORKSPACE)"; exit 1; }
	@test -f "$(PUBSPEC)" || { echo "$(PUBSPEC) not found"; exit 1; }
	@set -e; \
	build_name=$$(sed -n 's/^version:[[:space:]]*\([^+]*\)+.*/\1/p' "$(PUBSPEC)" | head -n 1); \
	build_number=$$(sed -n 's/^version:.*+\([0-9][0-9]*\).*$$/\1/p' "$(PUBSPEC)" | head -n 1); \
	test -n "$$build_name" || { echo "Could not parse version name from $(PUBSPEC)"; exit 1; }; \
	test -n "$$build_number" || { echo "Could not parse build number from $(PUBSPEC)"; exit 1; }; \
	marketing_count=$$(grep -c "MARKETING_VERSION = $$build_name;" "$(PBXPROJ)" 2>/dev/null || true); \
	test "$$marketing_count" -gt 0 || { echo "iOS MARKETING_VERSION does not match $$build_name. Run: make bump-version NEW_VERSION=$$build_name NEW_BUILD=$$build_number"; exit 1; }; \
	project_build_count=$$(grep -c "CURRENT_PROJECT_VERSION = $$build_number;" "$(PBXPROJ)" 2>/dev/null || true); \
	test "$$project_build_count" -gt 0 || { echo "iOS CURRENT_PROJECT_VERSION does not match $$build_number. Run: make bump-version NEW_VERSION=$$build_name NEW_BUILD=$$build_number"; exit 1; }; \
	api_url="$(IOS_API_BASE_URL)"; \
	dart_defines=$$(printf 'AONW_API_BASE_URL=%s' "$$api_url" | base64 | tr -d '\n'); \
	archive_dir="$(IOS_ARCHIVE_ROOT)/$$(date +%Y-%m-%d)"; \
	archive_path="$$archive_dir/Runner $$(date '+%d-%m-%Y, %H.%M') build $$build_number.xcarchive"; \
	echo "Preparing Xcode archive $$build_name+$$build_number with API=$$api_url..."; \
	flutter pub get; \
	mkdir -p "$$archive_dir"; \
	xcodebuild archive \
	  -workspace "$(IOS_ARCHIVE_WORKSPACE)" \
	  -scheme "$(IOS_ARCHIVE_SCHEME)" \
	  -configuration "$(IOS_ARCHIVE_CONFIGURATION)" \
	  -destination 'generic/platform=iOS' \
	  -archivePath "$$archive_path" \
	  FLUTTER_BUILD_NAME="$$build_name" \
	  FLUTTER_BUILD_NUMBER="$$build_number" \
	  DART_DEFINES="$$dart_defines"; \
	echo "Verifying Xcode archive..."; \
	archive_build_name=$$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleShortVersionString' "$$archive_path/Info.plist"); \
	archive_build_number=$$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleVersion' "$$archive_path/Info.plist"); \
	echo "$$archive_build_name"; \
	echo "$$archive_build_number"; \
	test "$$archive_build_name" = "$$build_name" || { echo "Archive CFBundleShortVersionString $$archive_build_name does not match $$build_name"; exit 1; }; \
	test "$$archive_build_number" = "$$build_number" || { echo "Archive CFBundleVersion $$archive_build_number does not match $$build_number"; exit 1; }; \
	strings "$$archive_path/Products/Applications/Runner.app/Frameworks/App.framework/App" | rg -F "$$api_url" >/dev/null; \
	echo "Verified iOS archive API: $$api_url"; \
	echo "archive-ios finished: $$archive_path"; \
	open -a Xcode "$$archive_path"

archive-ios-if-possible:
	@if [ "$(IOS_ARCHIVE_ON_DEPLOY)" = "0" ]; then \
		echo "Skipping iOS archive because IOS_ARCHIVE_ON_DEPLOY=0."; \
	elif [ "$(IOS_ARCHIVE_ON_DEPLOY)" = "auto" ] && [ "$$(uname -s)" != "Darwin" ]; then \
		echo "Skipping iOS archive: Xcode archives are only available on macOS."; \
	elif [ "$(IOS_ARCHIVE_ON_DEPLOY)" = "auto" ] && ! command -v xcodebuild >/dev/null; then \
		echo "Skipping iOS archive: xcodebuild is not available."; \
	elif [ "$(IOS_ARCHIVE_ON_DEPLOY)" = "auto" ] && ! command -v flutter >/dev/null; then \
		echo "Skipping iOS archive: flutter SDK is not available."; \
	elif [ "$(IOS_ARCHIVE_ON_DEPLOY)" = "auto" ] && [ ! -d "$(IOS_ARCHIVE_WORKSPACE)" ]; then \
		echo "Skipping iOS archive: $(IOS_ARCHIVE_WORKSPACE) not found."; \
	elif [ "$(IOS_ARCHIVE_ON_DEPLOY)" = "auto" ]; then \
		$(MAKE) --no-print-directory archive-ios || echo "Skipping iOS archive: archive-ios failed in auto mode."; \
	else \
		$(MAKE) --no-print-directory archive-ios; \
	fi

android-keystore:
	@test -n "$(ANDROID_UPLOAD_KEYSTORE)" || { echo "ANDROID_UPLOAD_KEYSTORE is required."; exit 1; }
	@test ! -f "$(ANDROID_UPLOAD_KEYSTORE)" || { echo "Keystore already exists: $(ANDROID_UPLOAD_KEYSTORE)"; exit 1; }
	@echo "Creating Android upload keystore: $(ANDROID_UPLOAD_KEYSTORE)"
	@keytool_cmd="$(ANDROID_KEYTOOL)"; \
	if [ ! -x "$$keytool_cmd" ]; then keytool_cmd=$$(command -v keytool || true); fi; \
	test -n "$$keytool_cmd" || { echo "keytool is required. Install/use Android Studio JDK."; exit 1; }; \
	"$$keytool_cmd" -genkey -v \
	  -keystore "$(ANDROID_UPLOAD_KEYSTORE)" \
	  -storetype JKS \
	  -keyalg RSA \
	  -keysize 2048 \
	  -validity 10000 \
	  -alias "$(ANDROID_KEY_ALIAS)"
	@echo ""
	@echo "Create $(ANDROID_KEY_PROPERTIES) with:"
	@echo "storePassword=YOUR_STORE_PASSWORD"
	@echo "keyPassword=YOUR_KEY_PASSWORD"
	@echo "keyAlias=$(ANDROID_KEY_ALIAS)"
	@echo "storeFile=$(ANDROID_UPLOAD_KEYSTORE)"

android-preflight:
	@command -v flutter >/dev/null || { echo "flutter SDK is required for Android release builds."; exit 1; }
	@test -x "$(ANDROID_JAVA_HOME)/bin/java" || { echo "ANDROID_JAVA_HOME is invalid: $(ANDROID_JAVA_HOME)"; exit 1; }
	@test -f "$(PUBSPEC)" || { echo "$(PUBSPEC) not found"; exit 1; }
	@test -f android/app/build.gradle.kts || { echo "android/app/build.gradle.kts not found"; exit 1; }
	@test -f "$(ANDROID_KEY_PROPERTIES)" || { echo "$(ANDROID_KEY_PROPERTIES) not found. Run make android-keystore, then create this file."; exit 1; }
	@for key in storePassword keyPassword keyAlias storeFile; do \
		grep -q "^$$key=" "$(ANDROID_KEY_PROPERTIES)" || { echo "Missing $$key in $(ANDROID_KEY_PROPERTIES)"; exit 1; }; \
	done
	@set -e; \
	store_file=$$(sed -n 's/^storeFile=//p' "$(ANDROID_KEY_PROPERTIES)" | head -n 1); \
	if [ -z "$$store_file" ]; then \
		echo "storeFile is empty in $(ANDROID_KEY_PROPERTIES)"; \
		exit 1; \
	fi; \
	case "$$store_file" in \
		/*) resolved_store_file="$$store_file" ;; \
		*) resolved_store_file="android/$$store_file" ;; \
	esac; \
	test -f "$$resolved_store_file" || { echo "Keystore not found: $$resolved_store_file"; exit 1; }; \
	build_name=$$(sed -n 's/^version:[[:space:]]*\([^+]*\)+.*/\1/p' "$(PUBSPEC)" | head -n 1); \
	build_number=$$(sed -n 's/^version:.*+\([0-9][0-9]*\).*$$/\1/p' "$(PUBSPEC)" | head -n 1); \
	test -n "$$build_name" || { echo "Could not parse version name from $(PUBSPEC)"; exit 1; }; \
	test -n "$$build_number" || { echo "Could not parse build number from $(PUBSPEC)"; exit 1; }; \
	echo "Android release preflight OK: $$build_name+$$build_number"

android-play-preflight:
	@$(ANDROID_PLAY_FASTLANE) --version >/dev/null || { echo "fastlane is required. Install it with: brew install fastlane"; exit 1; }
	@test -n "$(ANDROID_PLAY_JSON_KEY)" || { echo "ANDROID_PLAY_JSON_KEY is required."; exit 1; }
	@test -f "$(ANDROID_PLAY_JSON_KEY)" || { echo "Google Play service account JSON not found: $(ANDROID_PLAY_JSON_KEY)"; exit 1; }
	@test -n "$(ANDROID_PACKAGE_NAME)" || { echo "ANDROID_PACKAGE_NAME is required."; exit 1; }
	@test -n "$(ANDROID_PLAY_TRACK)" || { echo "ANDROID_PLAY_TRACK is required."; exit 1; }
	@test -n "$(ANDROID_PLAY_RELEASE_STATUS)" || { echo "ANDROID_PLAY_RELEASE_STATUS is required."; exit 1; }
	@echo "Google Play preflight OK: package=$(ANDROID_PACKAGE_NAME), track=$(ANDROID_PLAY_TRACK), status=$(ANDROID_PLAY_RELEASE_STATUS)"

android-build-aab: android-preflight
	@echo "Building Android App Bundle with API=$(ANDROID_API_BASE_URL)..."
	@JAVA_HOME="$(ANDROID_JAVA_HOME)" flutter pub get
	@JAVA_HOME="$(ANDROID_JAVA_HOME)" flutter test
	@JAVA_HOME="$(ANDROID_JAVA_HOME)" flutter test "--dart-define=AONW_API_BASE_URL=$(ANDROID_API_BASE_URL)" test/game/repository_providers_test.dart
	@JAVA_HOME="$(ANDROID_JAVA_HOME)" flutter build appbundle --release "--dart-define=AONW_API_BASE_URL=$(ANDROID_API_BASE_URL)"
	@test -f "$(ANDROID_RELEASE_BUNDLE)" || { echo "Expected bundle not found: $(ANDROID_RELEASE_BUNDLE)"; exit 1; }
	@unzip -p "$(ANDROID_RELEASE_BUNDLE)" 'base/lib/*/libapp.so' | strings | rg -F "$(ANDROID_API_BASE_URL)" >/dev/null
	@echo "Verified Android App Bundle API: $(ANDROID_API_BASE_URL)"
	@echo "Android App Bundle ready: $(ANDROID_RELEASE_BUNDLE)"

android-build-apk: android-preflight
	@echo "Building split Android APKs with API=$(ANDROID_API_BASE_URL)..."
	@JAVA_HOME="$(ANDROID_JAVA_HOME)" flutter pub get
	@JAVA_HOME="$(ANDROID_JAVA_HOME)" flutter test "--dart-define=AONW_API_BASE_URL=$(ANDROID_API_BASE_URL)" test/game/repository_providers_test.dart
	@JAVA_HOME="$(ANDROID_JAVA_HOME)" flutter build apk --release --split-per-abi "--dart-define=AONW_API_BASE_URL=$(ANDROID_API_BASE_URL)"
	@apk=$$(find "$(ANDROID_RELEASE_APK_DIR)" -name '*-release.apk' -print -quit); \
	test -n "$$apk" || { echo "Expected release APK not found in $(ANDROID_RELEASE_APK_DIR)"; exit 1; }; \
	unzip -p "$$apk" 'lib/*/libapp.so' | strings | rg -F "$(ANDROID_API_BASE_URL)" >/dev/null
	@echo "Verified Android APK API: $(ANDROID_API_BASE_URL)"
	@echo "Android APKs ready in: $(ANDROID_RELEASE_APK_DIR)"

android-release: android-build-aab
	@echo "Upload this file in Play Console: $(ANDROID_RELEASE_BUNDLE)"
	@echo "Or upload with Play API: make android-deploy"

android-upload-aab: android-play-preflight
	@test -f "$(ANDROID_RELEASE_BUNDLE)" || { echo "Expected bundle not found: $(ANDROID_RELEASE_BUNDLE). Run make android-build-aab first."; exit 1; }
	@unzip -p "$(ANDROID_RELEASE_BUNDLE)" 'base/lib/*/libapp.so' | strings | rg -F "$(ANDROID_API_BASE_URL)" >/dev/null
	@echo "Uploading $(ANDROID_RELEASE_BUNDLE) to Google Play track $(ANDROID_PLAY_TRACK)..."
	@set -e; \
	supply_args="$(ANDROID_PLAY_SUPPLY_ARGS)"; \
	if [ "$(ANDROID_PLAY_VALIDATE_ONLY)" = "1" ]; then supply_args="$$supply_args --validate_only true"; fi; \
	JAVA_HOME="$(ANDROID_JAVA_HOME)" $(ANDROID_PLAY_FASTLANE) supply \
	  --aab "$(ANDROID_RELEASE_BUNDLE)" \
	  --json_key "$(ANDROID_PLAY_JSON_KEY)" \
	  --package_name "$(ANDROID_PACKAGE_NAME)" \
	  --track "$(ANDROID_PLAY_TRACK)" \
	  --release_status "$(ANDROID_PLAY_RELEASE_STATUS)" \
	  --skip_upload_metadata true \
	  --skip_upload_changelogs true \
	  --skip_upload_images true \
	  --skip_upload_screenshots true \
	  $$supply_args
	@echo "Google Play upload finished: package=$(ANDROID_PACKAGE_NAME), track=$(ANDROID_PLAY_TRACK)"

android-upload-closed:
	@$(MAKE) --no-print-directory android-upload-aab ANDROID_PLAY_TRACK="$(ANDROID_PLAY_CLOSED_TRACK)"

android-deploy: android-build-aab
	@$(MAKE) --no-print-directory android-upload-aab

android-deploy-closed: android-build-aab
	@$(MAKE) --no-print-directory android-upload-closed

multiplayer-platform-smoke:
	@command -v flutter >/dev/null || { echo "flutter SDK is required for multiplayer-platform-smoke."; exit 1; }
	@echo "Running multiplayer platform smoke builds with API=$(PLATFORM_SMOKE_API_BASE_URL)"
	@if [ "$(PLATFORM_SMOKE_WEB)" = "1" ]; then \
		echo "Building web release (wasm + js fallback)..."; \
		flutter build web --wasm --release "--dart-define=AONW_API_BASE_URL=$(PLATFORM_SMOKE_API_BASE_URL)"; \
	else \
		echo "Skipping web build because PLATFORM_SMOKE_WEB=$(PLATFORM_SMOKE_WEB)."; \
	fi
	@if [ "$(PLATFORM_SMOKE_MACOS)" = "1" ] || { [ "$(PLATFORM_SMOKE_MACOS)" = "auto" ] && [ "$$(uname -s)" = "Darwin" ]; }; then \
		echo "Building macOS debug app..."; \
		flutter build macos --debug "--dart-define=AONW_API_BASE_URL=$(PLATFORM_SMOKE_API_BASE_URL)"; \
	else \
		echo "Skipping macOS build because PLATFORM_SMOKE_MACOS=$(PLATFORM_SMOKE_MACOS) on $$(uname -s)."; \
	fi
	@if [ "$(PLATFORM_SMOKE_IOS)" = "1" ] || { [ "$(PLATFORM_SMOKE_IOS)" = "auto" ] && [ "$$(uname -s)" = "Darwin" ]; }; then \
		echo "Building iOS simulator debug app..."; \
		flutter build ios --debug --simulator "--dart-define=AONW_API_BASE_URL=$(PLATFORM_SMOKE_API_BASE_URL)"; \
	else \
		echo "Skipping iOS simulator build because PLATFORM_SMOKE_IOS=$(PLATFORM_SMOKE_IOS) on $$(uname -s)."; \
	fi
	@if [ "$(PLATFORM_SMOKE_ANDROID)" = "1" ]; then \
		echo "Building Android debug APK..."; \
		JAVA_HOME="$(ANDROID_JAVA_HOME)" flutter build apk --debug "--dart-define=AONW_API_BASE_URL=$(PLATFORM_SMOKE_API_BASE_URL)"; \
	else \
		echo "Skipping Android build because PLATFORM_SMOKE_ANDROID=$(PLATFORM_SMOKE_ANDROID)."; \
	fi
	@if [ "$(PLATFORM_SMOKE_WINDOWS)" = "1" ]; then \
		echo "Building Windows debug app..."; \
		flutter build windows --debug "--dart-define=AONW_API_BASE_URL=$(PLATFORM_SMOKE_API_BASE_URL)"; \
	elif [ "$(PLATFORM_SMOKE_WINDOWS)" = "auto" ]; then \
		case "$$(uname -s)" in \
			MINGW*|MSYS*|CYGWIN*) \
				echo "Building Windows debug app..."; \
				flutter build windows --debug "--dart-define=AONW_API_BASE_URL=$(PLATFORM_SMOKE_API_BASE_URL)";; \
			*) \
				echo "Skipping Windows/Steam Windows build: Flutter Windows builds require a Windows host.";; \
		esac; \
	else \
		echo "Skipping Windows build because PLATFORM_SMOKE_WINDOWS=$(PLATFORM_SMOKE_WINDOWS)."; \
	fi
	@echo "Steam macOS uses the macOS desktop artifact; Steam Windows uses the Windows desktop artifact."
	@echo "multiplayer-platform-smoke finished."

deploy-steam: steam-release-from-dist

steam: steam-macos steam-windows
	@test -f "$(STEAM_MACOS_ZIP)" || { echo "Missing Steam macOS ZIP: $(STEAM_MACOS_ZIP)"; exit 1; }
	@test -f "$(STEAM_WINDOWS_ZIP)" || { echo "Missing Steam Windows ZIP: $(STEAM_WINDOWS_ZIP)"; exit 1; }
	@echo "Steam ZIPs ready:"
	@ls -lh "$(STEAM_MACOS_ZIP)" "$(STEAM_WINDOWS_ZIP)"

steam-release-from-dist: steam-macos steam-prepare-from-dist steam-upload

steam-macos:
	@command -v flutter >/dev/null || { echo "flutter SDK is required for steam-macos."; exit 1; }
	@command -v ditto >/dev/null || { echo "ditto is required for steam-macos."; exit 1; }
	@command -v unzip >/dev/null || { echo "unzip is required for steam-macos."; exit 1; }
	@test "$$(uname -s)" = "Darwin" || { echo "steam-macos requires a macOS host."; exit 1; }
	@echo "Building macOS Steam release with API=$(STEAM_API_BASE_URL)..."
	@flutter pub get
	@flutter build macos --release --no-pub "--dart-define=AONW_API_BASE_URL=$(STEAM_API_BASE_URL)"
	@test -d "$(STEAM_MACOS_APP)" || { echo "Expected macOS app not found: $(STEAM_MACOS_APP)"; exit 1; }
	@app_binary=$$(find "$(STEAM_MACOS_APP)/Contents/Frameworks/App.framework" -type f -name App -print -quit); \
	test -n "$$app_binary" || { echo "Expected Flutter App.framework binary not found in $(STEAM_MACOS_APP)"; exit 1; }; \
	strings "$$app_binary" | rg -F "$(STEAM_API_BASE_URL)" >/dev/null
	@echo "Verified Steam macOS API: $(STEAM_API_BASE_URL)"
	@mkdir -p "$(STEAM_DIST_DIR)"
	@rm -f "$(STEAM_MACOS_ZIP)"
	@ditto -c -k --keepParent --norsrc --noextattr --noqtn --noacl "$(STEAM_MACOS_APP)" "$(STEAM_MACOS_ZIP)"
	@unzip -tq "$(STEAM_MACOS_ZIP)" >/dev/null
	@echo "Steam macOS ZIP ready: $(STEAM_MACOS_ZIP)"

steam-windows:
	@set -e; \
	mode="$(STEAM_WINDOWS_SOURCE)"; \
	if [ "$$mode" = "auto" ]; then \
		case "$$(uname -s 2>/dev/null || echo unknown)" in \
			MINGW*|MSYS*|CYGWIN*) mode="local" ;; \
			*) \
				if command -v gh >/dev/null; then \
					mode="github"; \
				elif [ -d "$(STEAM_WINDOWS_RELEASE_DIR)" ]; then \
					mode="existing"; \
				else \
					echo "Cannot build Steam Windows ZIP on this host."; \
					echo "Use STEAM_WINDOWS_SOURCE=github with gh installed, run this on Windows, or place a release in $(STEAM_WINDOWS_RELEASE_DIR)."; \
					exit 1; \
				fi ;; \
		esac; \
	fi; \
	case "$$mode" in \
		local) $(MAKE) --no-print-directory steam-windows-local ;; \
		github) $(MAKE) --no-print-directory steam-windows-github ;; \
		existing) $(MAKE) --no-print-directory steam-package-windows ;; \
		*) echo "Invalid STEAM_WINDOWS_SOURCE=$$mode. Use auto, local, github, or existing."; exit 1 ;; \
	esac

steam-windows-local:
	@command -v flutter >/dev/null || { echo "flutter SDK is required for steam-windows-local."; exit 1; }
	@case "$$(uname -s 2>/dev/null || echo unknown)" in \
		MINGW*|MSYS*|CYGWIN*) ;; \
		*) echo "steam-windows-local requires a Windows host."; exit 1 ;; \
	esac
	@echo "Building Windows Steam release with API=$(STEAM_API_BASE_URL)..."
	@flutter config --enable-windows-desktop
	@flutter pub get
	@flutter build windows --release --no-pub "--dart-define=AONW_API_BASE_URL=$(STEAM_API_BASE_URL)"
	@$(MAKE) --no-print-directory steam-package-windows

steam-windows-github:
	@command -v gh >/dev/null || { echo "gh is required for STEAM_WINDOWS_SOURCE=github."; exit 1; }
	@set -e; \
	branch=$$(git branch --show-current); \
	local_sha=$$(git rev-parse HEAD); \
	build_name=$$(sed -n 's/^version:[[:space:]]*\([^+]*\)+.*/\1/p' "$(PUBSPEC)" | head -n 1); \
	build_number=$$(sed -n 's/^version:.*+\([0-9][0-9]*\).*$$/\1/p' "$(PUBSPEC)" | head -n 1); \
	test -n "$$branch" || { echo "Could not detect current git branch."; exit 1; }; \
	test -n "$$build_name" || { echo "Could not parse version name from $(PUBSPEC)."; exit 1; }; \
	test -n "$$build_number" || { echo "Could not parse build number from $(PUBSPEC)."; exit 1; }; \
	git fetch origin "$$branch" >/dev/null; \
	remote_sha=$$(git rev-parse "origin/$$branch"); \
	test "$$local_sha" = "$$remote_sha" || { echo "Local HEAD is not pushed to origin/$$branch. Push first, then run make steam again."; exit 1; }; \
	echo "Dispatching $(STEAM_WINDOWS_WORKFLOW) on $$branch for $$build_name+$$build_number..."; \
	gh workflow run "$(STEAM_WINDOWS_WORKFLOW)" --ref "$$branch" -f build_name="$$build_name" -f build_number="$$build_number"; \
	echo "Waiting for GitHub Actions run to appear..."; \
	run_id=""; \
	i=1; \
	while [ "$$i" -le "$(STEAM_GITHUB_RUN_LOOKUP_ATTEMPTS)" ]; do \
		run_id=$$(gh run list --workflow "$(STEAM_WINDOWS_WORKFLOW)" --branch "$$branch" --event workflow_dispatch --json databaseId --limit 1 --jq '.[0].databaseId // ""'); \
		if [ -n "$$run_id" ]; then break; fi; \
		sleep "$(STEAM_GITHUB_RUN_LOOKUP_SLEEP)"; \
		i=$$((i + 1)); \
	done; \
	test -n "$$run_id" || { echo "Could not find GitHub Actions run for $(STEAM_WINDOWS_WORKFLOW)."; exit 1; }; \
	echo "Watching GitHub Actions run $$run_id..."; \
	gh run watch "$$run_id" --exit-status; \
	rm -rf "$(STEAM_WINDOWS_ARTIFACT_DIR)"; \
	mkdir -p "$(STEAM_WINDOWS_ARTIFACT_DIR)" "$(STEAM_DIST_DIR)"; \
	gh run download "$$run_id" --dir "$(STEAM_WINDOWS_ARTIFACT_DIR)" --pattern 'aonw-windows-steam-*'; \
	zip_file=$$(find "$(STEAM_WINDOWS_ARTIFACT_DIR)" -name 'aonw-windows-steam.zip' -print -quit); \
	test -n "$$zip_file" || { echo "Downloaded artifact did not contain aonw-windows-steam.zip."; exit 1; }; \
	cp "$$zip_file" "$(STEAM_WINDOWS_ZIP)"; \
	unzip -tq "$(STEAM_WINDOWS_ZIP)" >/dev/null; \
	tmp_dir=$$(mktemp -d); \
	trap 'rm -rf "$$tmp_dir"' EXIT; \
	unzip -q "$(STEAM_WINDOWS_ZIP)" -d "$$tmp_dir"; \
	rg -a -F "$(STEAM_API_BASE_URL)" "$$tmp_dir" >/dev/null; \
	echo "Steam Windows ZIP ready: $(STEAM_WINDOWS_ZIP)"

steam-package-windows:
	@command -v zip >/dev/null || { echo "zip is required for steam-package-windows."; exit 1; }
	@command -v unzip >/dev/null || { echo "unzip is required for steam-package-windows."; exit 1; }
	@test -d "$(STEAM_WINDOWS_RELEASE_DIR)" || { echo "Expected Windows release directory not found: $(STEAM_WINDOWS_RELEASE_DIR)"; exit 1; }
	@mkdir -p "$(STEAM_DIST_DIR)"
	@rm -f "$(STEAM_WINDOWS_ZIP)"
	@zip_path="$$(pwd)/$(STEAM_WINDOWS_ZIP)"; \
		cd "$(STEAM_WINDOWS_RELEASE_DIR)" && zip -qry "$$zip_path" .
	@unzip -tq "$(STEAM_WINDOWS_ZIP)" >/dev/null
	@tmp_dir=$$(mktemp -d); \
	trap 'rm -rf "$$tmp_dir"' EXIT; \
	unzip -q "$(STEAM_WINDOWS_ZIP)" -d "$$tmp_dir"; \
	rg -a -F "$(STEAM_API_BASE_URL)" "$$tmp_dir" >/dev/null
	@echo "Verified Steam Windows API: $(STEAM_API_BASE_URL)"
	@echo "Steam Windows ZIP ready: $(STEAM_WINDOWS_ZIP)"

steam-prepare-from-dist:
	@command -v ditto >/dev/null || { echo "ditto is required for steam-prepare-from-dist."; exit 1; }
	@command -v unzip >/dev/null || { echo "unzip is required for steam-prepare-from-dist."; exit 1; }
	@command -v rg >/dev/null || { echo "rg is required for steam-prepare-from-dist."; exit 1; }
	@command -v strings >/dev/null || { echo "strings is required for steam-prepare-from-dist."; exit 1; }
	@test -f "$(STEAM_MACOS_ZIP)" || { echo "Missing Steam macOS ZIP: $(STEAM_MACOS_ZIP). Run make steam-macos first."; exit 1; }
	@test -f "$(STEAM_WINDOWS_DIST_ZIP)" || { echo "Missing Steam Windows ZIP/artifact: $(STEAM_WINDOWS_DIST_ZIP). Copy the GitHub Actions artifact to dist/ or set STEAM_WINDOWS_DIST_ZIP=/path."; exit 1; }
	@set -e; \
	build_name=$$(sed -n 's/^version:[[:space:]]*\([^+]*\)+.*/\1/p' "$(PUBSPEC)" | head -n 1); \
	build_number=$$(sed -n 's/^version:.*+\([0-9][0-9]*\).*$$/\1/p' "$(PUBSPEC)" | head -n 1); \
	test -n "$$build_name" || { echo "Could not parse version name from $(PUBSPEC)."; exit 1; }; \
	test -n "$$build_number" || { echo "Could not parse build number from $(PUBSPEC)."; exit 1; }; \
	build_desc="$(STEAM_BUILD_DESC)"; \
	if [ -z "$$build_desc" ]; then build_desc="Build $$build_number - $$build_name release"; fi; \
	echo "Preparing SteamPipe content in $(STEAM_DEPLOY_DIR) ($$build_desc)..."; \
	rm -rf "$(STEAM_CONTENT_DIR)/macos" "$(STEAM_CONTENT_DIR)/windows"; \
	mkdir -p "$(STEAM_CONTENT_DIR)/macos" "$(STEAM_CONTENT_DIR)/windows" "$(STEAM_SCRIPT_DIR)" "$(STEAM_OUTPUT_DIR)"; \
	ditto -x -k "$(STEAM_MACOS_ZIP)" "$(STEAM_CONTENT_DIR)/macos"; \
	test -d "$(STEAM_CONTENT_DIR)/macos/$(STEAM_MACOS_APP_NAME)" || { echo "macOS depot must contain $(STEAM_MACOS_APP_NAME) at its root."; exit 1; }; \
	tmp_dir=$$(mktemp -d); \
	trap 'rm -rf "$$tmp_dir"' EXIT; \
	unzip -q "$(STEAM_WINDOWS_DIST_ZIP)" -d "$$tmp_dir"; \
	if [ -d "$$tmp_dir/steam-windows" ]; then \
		ditto "$$tmp_dir/steam-windows" "$(STEAM_CONTENT_DIR)/windows"; \
	elif [ -f "$$tmp_dir/aonw-windows-steam.zip" ]; then \
		unzip -q "$$tmp_dir/aonw-windows-steam.zip" -d "$(STEAM_CONTENT_DIR)/windows"; \
	elif [ -f "$$tmp_dir/aonw.exe" ]; then \
		ditto "$$tmp_dir" "$(STEAM_CONTENT_DIR)/windows"; \
	else \
		echo "Windows ZIP must contain steam-windows/, aonw-windows-steam.zip, or aonw.exe at root."; \
		exit 1; \
	fi; \
	test -f "$(STEAM_CONTENT_DIR)/windows/aonw.exe" || { echo "Windows depot must contain aonw.exe at its root."; exit 1; }; \
	macos_binary=$$(find "$(STEAM_CONTENT_DIR)/macos/$(STEAM_MACOS_APP_NAME)/Contents/Frameworks/App.framework" -type f -name App -print -quit); \
	test -n "$$macos_binary" || { echo "Expected Flutter App.framework binary not found in macOS depot."; exit 1; }; \
	strings "$$macos_binary" | rg -F "$(STEAM_API_BASE_URL)" >/dev/null; \
	rg -a -F "$(STEAM_API_BASE_URL)" "$(STEAM_CONTENT_DIR)/windows/data/app.so" >/dev/null; \
	{ \
		printf '%s\n' '"AppBuild"'; \
		printf '%s\n' '{'; \
		printf '  "AppID" "%s"\n' "$(STEAM_APP_ID)"; \
		printf '  "Desc" "%s"\n' "$$build_desc"; \
		printf '  "BuildOutput" "%s"\n' "$(STEAM_OUTPUT_DIR)"; \
		printf '  "ContentRoot" "%s"\n' "$(STEAM_CONTENT_DIR)"; \
		printf '%s\n' '  "Depots"'; \
		printf '%s\n' '  {'; \
		printf '    "%s" "%s/depot_build_%s_macos.vdf"\n' "$(STEAM_MACOS_DEPOT_ID)" "$(STEAM_SCRIPT_DIR)" "$(STEAM_MACOS_DEPOT_ID)"; \
		printf '    "%s" "%s/depot_build_%s_windows.vdf"\n' "$(STEAM_WINDOWS_DEPOT_ID)" "$(STEAM_SCRIPT_DIR)" "$(STEAM_WINDOWS_DEPOT_ID)"; \
		printf '%s\n' '  }'; \
		printf '%s\n' '}'; \
	} > "$(STEAM_SCRIPT_DIR)/app_build_$(STEAM_APP_ID).vdf"; \
	{ \
		printf '%s\n' '"DepotBuildConfig"'; \
		printf '%s\n' '{'; \
		printf '  "DepotID" "%s"\n' "$(STEAM_MACOS_DEPOT_ID)"; \
		printf '  "ContentRoot" "%s/macos"\n' "$(STEAM_CONTENT_DIR)"; \
		printf '%s\n' '  "FileMapping"'; \
		printf '%s\n' '  {'; \
		printf '%s\n' '    "LocalPath" "*"'; \
		printf '%s\n' '    "DepotPath" "."'; \
		printf '%s\n' '    "recursive" "1"'; \
		printf '%s\n' '  }'; \
		printf '%s\n' '}'; \
	} > "$(STEAM_SCRIPT_DIR)/depot_build_$(STEAM_MACOS_DEPOT_ID)_macos.vdf"; \
	{ \
		printf '%s\n' '"DepotBuildConfig"'; \
		printf '%s\n' '{'; \
		printf '  "DepotID" "%s"\n' "$(STEAM_WINDOWS_DEPOT_ID)"; \
		printf '  "ContentRoot" "%s/windows"\n' "$(STEAM_CONTENT_DIR)"; \
		printf '%s\n' '  "FileMapping"'; \
		printf '%s\n' '  {'; \
		printf '%s\n' '    "LocalPath" "*"'; \
		printf '%s\n' '    "DepotPath" "."'; \
		printf '%s\n' '    "recursive" "1"'; \
		printf '%s\n' '  }'; \
		printf '%s\n' '}'; \
	} > "$(STEAM_SCRIPT_DIR)/depot_build_$(STEAM_WINDOWS_DEPOT_ID)_windows.vdf"; \
	echo "Verified Steam macOS and Windows API: $(STEAM_API_BASE_URL)"; \
	echo "SteamPipe content ready in $(STEAM_DEPLOY_DIR)."

steam-upload-command:
	@echo 'cd "$(STEAM_SCRIPT_DIR)" && $(STEAMCMD) +login "$(STEAM_USER)" +run_app_build "$(STEAM_SCRIPT_DIR)/app_build_$(STEAM_APP_ID).vdf" +quit'

steam-upload:
	@command -v "$(STEAMCMD)" >/dev/null || { echo "$(STEAMCMD) is required for steam-upload."; exit 1; }
	@test -f "$(STEAM_SCRIPT_DIR)/app_build_$(STEAM_APP_ID).vdf" || { echo "Missing app build VDF. Run make steam-prepare-from-dist first."; exit 1; }
	@echo "Uploading Steam build with $(STEAMCMD) as $(STEAM_USER)..."
	@$(MAKE) --no-print-directory steam-upload-command
	@cd "$(STEAM_SCRIPT_DIR)" && "$(STEAMCMD)" +login "$(STEAM_USER)" +run_app_build "$(STEAM_SCRIPT_DIR)/app_build_$(STEAM_APP_ID).vdf" +quit

# Local-only target. Bumps the build number and, when NEW_VERSION is supplied,
# the marketing version in pubspec.yaml and platform version metadata. Stages
# and commits the changes. Override the build with NEW_BUILD=N; otherwise the
# current build is incremented by 1.
bump-version:
	@test -f "$(PUBSPEC)" || { echo "$(PUBSPEC) not found"; exit 1; }
	@test -f "$(PBXPROJ)" || { echo "$(PBXPROJ) not found"; exit 1; }
	@current_build=$$(sed -n 's/^version:.*+\([0-9][0-9]*\).*$$/\1/p' "$(PUBSPEC)" | head -n 1); \
	test -n "$$current_build" || { echo "Could not parse current build from $(PUBSPEC)"; exit 1; }; \
	current_name=$$(sed -n 's/^version:[[:space:]]*\([^+]*\)+.*/\1/p' "$(PUBSPEC)" | head -n 1); \
	test -n "$$current_name" || { echo "Could not parse version name from $(PUBSPEC)"; exit 1; }; \
	expected_build_count=$$(grep -c "CURRENT_PROJECT_VERSION = $$current_build;" "$(PBXPROJ)" 2>/dev/null || true); \
	test "$$expected_build_count" -gt 0 || { echo "No CURRENT_PROJECT_VERSION = $$current_build lines found in $(PBXPROJ)"; exit 1; }; \
	expected_marketing_count=$$(grep -c "MARKETING_VERSION = $$current_name;" "$(PBXPROJ)" 2>/dev/null || true); \
	test "$$expected_marketing_count" -gt 0 || { echo "No MARKETING_VERSION = $$current_name lines found in $(PBXPROJ)"; exit 1; }; \
	new_build="$(NEW_BUILD)"; \
	if [ -z "$$new_build" ]; then new_build=$$((current_build + 1)); fi; \
	new_name="$(NEW_VERSION)"; \
	if [ -z "$$new_name" ]; then \
		case "$(VERSION_BUMP)" in \
			patch) \
				major=$$(printf '%s' "$$current_name" | awk -F. 'NF == 3 && $$1 ~ /^[0-9]+$$/ && $$2 ~ /^[0-9]+$$/ && $$3 ~ /^[0-9]+$$/ { print $$1 }'); \
				minor=$$(printf '%s' "$$current_name" | awk -F. 'NF == 3 && $$1 ~ /^[0-9]+$$/ && $$2 ~ /^[0-9]+$$/ && $$3 ~ /^[0-9]+$$/ { print $$2 }'); \
				patch=$$(printf '%s' "$$current_name" | awk -F. 'NF == 3 && $$1 ~ /^[0-9]+$$/ && $$2 ~ /^[0-9]+$$/ && $$3 ~ /^[0-9]+$$/ { print $$3 }'); \
				test -n "$$major" || { echo "VERSION_BUMP=patch requires semantic version x.y.z, current is $$current_name. Use NEW_VERSION=x.y.z."; exit 1; }; \
				new_name="$$major.$$minor.$$((patch + 1))"; \
				;; \
			none) new_name="$$current_name" ;; \
			*) echo "Invalid VERSION_BUMP=$(VERSION_BUMP). Use patch or none."; exit 1 ;; \
		esac; \
	fi; \
	case "$$new_name" in *+*) echo "NEW_VERSION must not contain +build metadata: $$new_name"; exit 1;; esac; \
	echo "Bumping version $$current_name+$$current_build -> $$new_name+$$new_build..."; \
	sed -i.bak "s/^version:.*$$/version: $$new_name+$$new_build/" "$(PUBSPEC)" && rm "$(PUBSPEC).bak"; \
	sed -i.bak "s/CURRENT_PROJECT_VERSION = $$current_build;/CURRENT_PROJECT_VERSION = $$new_build;/g; s/MARKETING_VERSION = $$current_name;/MARKETING_VERSION = $$new_name;/g" "$(PBXPROJ)" && rm "$(PBXPROJ).bak"; \
	if [ -f "$(WINDOWS_RC)" ]; then \
		sed -i.bak "s/#define VERSION_AS_STRING \"$$current_name\"/#define VERSION_AS_STRING \"$$new_name\"/" "$(WINDOWS_RC)" && rm "$(WINDOWS_RC).bak"; \
	fi; \
	echo "Verifying changes..."; \
	grep "^version:" "$(PUBSPEC)"; \
	actual_build_count=$$(grep -c "CURRENT_PROJECT_VERSION = $$new_build;" "$(PBXPROJ)" 2>/dev/null || true); \
	actual_marketing_count=$$(grep -c "MARKETING_VERSION = $$new_name;" "$(PBXPROJ)" 2>/dev/null || true); \
	echo "  pbxproj CURRENT_PROJECT_VERSION = $$new_build matches: $$actual_build_count (expected: $$expected_build_count)"; \
	echo "  pbxproj MARKETING_VERSION = $$new_name matches: $$actual_marketing_count (expected: $$expected_marketing_count)"; \
	test "$$actual_build_count" = "$$expected_build_count" || { echo "Unexpected CURRENT_PROJECT_VERSION replacement count."; exit 1; }; \
	test "$$actual_marketing_count" = "$$expected_marketing_count" || { echo "Unexpected MARKETING_VERSION replacement count."; exit 1; }; \
	if [ -f "$(WINDOWS_RC)" ]; then \
		grep "#define VERSION_AS_STRING \"$$new_name\"" "$(WINDOWS_RC)" >/dev/null || { echo "$(WINDOWS_RC) fallback version did not update to $$new_name"; exit 1; }; \
	fi; \
	git add "$(PUBSPEC)" "$(PBXPROJ)"; \
	if [ -f "$(WINDOWS_RC)" ]; then git add "$(WINDOWS_RC)"; fi; \
	if [ "$$new_name" = "$$current_name" ]; then \
		git commit -m "Prepare build $$new_build"; \
	else \
		git commit -m "Prepare version $$new_name build $$new_build"; \
	fi; \
	echo "bump-version finished. Commit ready to push."

# Local + remote orchestration. Pushes main to origin, asks the staging
# server to make deploy (server image rebuild + restart + health), then
# deploys the static homepage and demo web app locally.
# Aborts on any step failure.
deploy-all:
	@$(MAKE) --no-print-directory preflight-release
	@test -n "$(REMOTE_DEPLOY_SSH_KEY)" || { echo "REMOTE_DEPLOY_SSH_KEY is required."; exit 1; }
	@test -n "$(REMOTE_DEPLOY_USER)" || { echo "REMOTE_DEPLOY_USER is required."; exit 1; }
	@test -n "$(REMOTE_DEPLOY_HOST)" || { echo "REMOTE_DEPLOY_HOST is required."; exit 1; }
	@test -n "$(REMOTE_DEPLOY_PATH)" || { echo "REMOTE_DEPLOY_PATH is required."; exit 1; }
	@test -f "$(REMOTE_DEPLOY_SSH_KEY)" || { echo "SSH key not found: $(REMOTE_DEPLOY_SSH_KEY)"; exit 1; }
	@echo "[1/7] Bumping build version..."
	@$(MAKE) --no-print-directory bump-version NEW_VERSION="$(NEW_VERSION)" NEW_BUILD="$(NEW_BUILD)"
	@echo "[2/7] Archiving iOS build for Xcode Organizer if possible..."
	@$(MAKE) --no-print-directory archive-ios-if-possible
	@echo "[3/7] Pushing local main to origin..."
	@git push origin main
	@echo "[4/7] Triggering server deploy via SSH..."
	@ssh -i "$(REMOTE_DEPLOY_SSH_KEY)" $(REMOTE_DEPLOY_USER)@$(REMOTE_DEPLOY_HOST) \
	  'cd "$(REMOTE_DEPLOY_PATH)" && make deploy'
	@echo "[5/7] Building and uploading static root homepage..."
	@$(MAKE) --no-print-directory deploy-homepage
	@echo "[6/7] Building and uploading demo web bundle..."
	@$(MAKE) --no-print-directory deploy-web
	@echo "[7/7] Final health checks..."
	@$(MAKE) --no-print-directory health
	@$(MAKE) --no-print-directory health-web
	@$(MAKE) --no-print-directory health-homepage
	@echo "deploy-all finished."

preflight-release:
	@command -v git >/dev/null || { echo "git is required."; exit 1; }
	@branch=$$(git branch --show-current); \
	test "$$branch" = "main" || { echo "deploy-all must run from main, current branch is '$$branch'."; exit 1; }
	@if [ -n "$$(git status --porcelain --untracked-files=no)" ]; then \
		echo "Tracked local changes detected. Commit/stash them before deploy-all:"; \
		git status --short --untracked-files=no; \
		exit 1; \
	fi

check-migrations:
	@test -x "$(SERVERPOD_CLI)" || { echo "Serverpod CLI not found: $(SERVERPOD_CLI)"; exit 1; }
	@cd server && "$(SERVERPOD_CLI)" generate
	@cd server && "$(SERVERPOD_CLI)" create-migration --force
	@dart format server/lib/src/generated packages/aonw_server_client/lib/src server/test/integration/test_tools >/dev/null
	@if ! git diff --quiet -- server/lib/src/generated packages/aonw_server_client/lib/src server/migrations; then \
		echo "Serverpod generated files or migrations changed. Review and commit them before deploy."; \
		git status --short -- server/lib/src/generated packages/aonw_server_client/lib/src server/migrations; \
		exit 1; \
	fi

migrate:
	@echo "Serverpod migrations are applied by the server at startup."
	@echo "Set SERVERPOD_APPLY_MIGRATIONS=true in .env and run: make up"

up:
	@$(COMPOSE) --profile "$(PROFILE)" up -d --remove-orphans

health:
	@echo "Checking $(HEALTH_URL)"
	@i=1; \
	while [ "$$i" -le "$(HEALTH_ATTEMPTS)" ]; do \
		if body=$$(curl -fsS --max-time 5 "$(HEALTH_URL)" 2>/tmp/aonw-health.err); then \
			echo "$$body"; \
			exit 0; \
		fi; \
		echo "Healthcheck attempt $$i/$(HEALTH_ATTEMPTS) failed; retrying..."; \
		sleep "$(HEALTH_SLEEP)"; \
		i=$$((i + 1)); \
	done; \
	echo "Healthcheck failed:"; \
	cat /tmp/aonw-health.err 2>/dev/null || true; \
	$(COMPOSE) --profile "$(PROFILE)" logs --tail=120 "$(SERVER_SERVICE)"; \
	exit 1

health-web:
	@echo "Checking $(WEB_HEALTH_URL)"
	@curl -fsS --max-time 5 -o /dev/null -w "%{http_code}\n" "$(WEB_HEALTH_URL)" \
	  || { echo "Web frontend not reachable"; exit 1; }

health-homepage:
	@echo "Checking $(HOMEPAGE_HEALTH_URL)"
	@curl -fsS --max-time 5 -o /dev/null -w "%{http_code}\n" "$(HOMEPAGE_HEALTH_URL)" \
	  || { echo "Static homepage not reachable"; exit 1; }

prune:
	@docker image prune -f
	@if [ "$(CLEAN_BUILD_CACHE)" = "1" ]; then \
		docker builder prune -af; \
	else \
		docker builder prune -f --filter until=168h; \
	fi

status:
	@$(COMPOSE) --profile "$(PROFILE)" ps

logs:
	@$(COMPOSE) --profile "$(PROFILE)" logs -f --tail=120 "$(SERVER_SERVICE)"
