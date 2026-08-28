SHELL := /bin/sh

RUST_WORKSPACE ?= engine
RUST_CARGO ?= $(if $(wildcard $(HOME)/.cargo/bin/cargo),$(HOME)/.cargo/bin/cargo,cargo)
RUST_DEPENDENCY_REPORT_PATH ?= /tmp/aonw-rust-dependencies.json
RUST_COVERAGE_REPORT_PATH ?= /tmp/aonw-rust-coverage.json
RUST_COVERAGE_LCOV_PATH ?= /tmp/aonw-rust-coverage.lcov
RUST_COVERAGE_SNAPSHOT_PATH ?= /tmp/aonw-rust-coverage-baseline.json
RUST_PERFORMANCE_REPORT_PATH ?= /tmp/aonw-rust-performance.json
RUST_PERFORMANCE_SNAPSHOT_PATH ?= /tmp/aonw-rust-performance-baseline.json
GODOT_PROJECT ?= clients/aonw_godot
GODOT_PINNED_VERSION := $(strip $(shell cat .godot-version 2>/dev/null))
GODOT_BOOTSTRAPPED_BIN := $(CURDIR)/.toolchains/godot/$(GODOT_PINNED_VERSION)/godot
GODOT_BIN ?= $(if $(wildcard $(GODOT_BOOTSTRAPPED_BIN)),$(GODOT_BOOTSTRAPPED_BIN),$(if $(wildcard /Applications/Godot.app/Contents/MacOS/Godot),/Applications/Godot.app/Contents/MacOS/Godot,godot))
GODOT_TEST_LOG ?= /tmp/aonw-godot-test.log
GODOT_CHECK_ONLY_LOG ?= /tmp/aonw-godot-check-only.log
GODOT_RUNTIME_LOG ?= /tmp/aonw-godot-runtime.log
GODOT_EDITOR_LOG ?= /tmp/aonw-godot-editor.log
GODOT_PROBE_LOG ?= /tmp/aonw-godot-map-render-probe.log
GODOT_VISUAL_EVIDENCE_LOG ?= /tmp/aonw-godot-stage-1-visual-evidence.log
MAP_RENDER_PROBE_DIR ?= /tmp/aonw-map-render-probes
MAP_RENDER_PROBE_SCENARIO := $(CURDIR)/aonw_tests/fixtures/render/map_render_probe_scenarios.json
FLUTTER_MAP_RENDER_PROBE := $(abspath $(MAP_RENDER_PROBE_DIR))/flutter.json
FLUTTER_MAP_RENDER_DIAGNOSTICS := $(abspath $(MAP_RENDER_PROBE_DIR))/flutter-diagnostics.json
GODOT_MAP_RENDER_PROBE := $(abspath $(MAP_RENDER_PROBE_DIR))/godot.json
GODOT_MAP_RENDER_DIAGNOSTICS := $(abspath $(MAP_RENDER_PROBE_DIR))/godot-diagnostics.json
STAGE_1_EVIDENCE_DIR := $(CURDIR)/docs/acceptance/stage-1

LOCAL_FLUTTER_BIN := $(CURDIR)/.fvm/flutter_sdk/bin
ifneq ($(wildcard $(LOCAL_FLUTTER_BIN)/flutter),)
export PATH := $(LOCAL_FLUTTER_BIN):$(PATH)
endif

COMPOSE ?= docker compose
COMPOSE_BASE_FILES = -f compose.yml
COMPOSE_STAGING_FILES = $(COMPOSE_BASE_FILES) -f compose.staging.yml
COMPOSE_PROD_FILES = $(COMPOSE_BASE_FILES) -f compose.prod.yml
COMPOSE_PROFILE_FILES = $(if $(filter prod,$(PROFILE)),$(COMPOSE_PROD_FILES),$(if $(filter staging,$(PROFILE)),$(COMPOSE_STAGING_FILES),$(COMPOSE_BASE_FILES)))
COMPOSE_PROFILE = $(COMPOSE) $(COMPOSE_PROFILE_FILES) --profile "$(PROFILE)"
PROFILE ?= staging
SERVER_SERVICE ?= server
BRANCH ?=
HEALTH_URL ?= https://api.aonw.net/readyz
WEB_HEALTH_URL ?= https://demo.aonw.net/
HOMEPAGE_HEALTH_URL ?= https://aonw.net/
ARCHITECTURE_HEALTH_URL ?= https://aonw.net/architecture
STATS_HEALTH_URL ?= https://aonw.net/stats
STATS_API_HEALTH_URL ?= https://aonw.net/api/stats
ENGINE_DOCS_HEALTH_URL ?= https://engine.aonw.net/
ENGINE_DOCS_API_HEALTH_URL ?= https://engine.aonw.net/aonw_engine/
HEALTH_ATTEMPTS ?= 30
HEALTH_SLEEP ?= 2
PRUNE ?= 1
CACHE_FLAGS ?=
CLEAN_BUILD_CACHE ?= 0
CHECK_MIGRATIONS ?= 0
COVERAGE_BASE_REF ?= origin/main
COVERAGE_RATCHET_REF ?= @{upstream}
COVERAGE_SNAPSHOT_PATH ?= /tmp/aonw-coverage-baseline.json
ARCHITECTURE_RATCHET_REF ?= @{upstream}
ARCHITECTURE_SNAPSHOT_PATH ?= /tmp/aonw-architecture-baseline.json
ARCHITECTURE_AGGREGATE_SNAPSHOT_PATH ?= /tmp/aonw-architecture-aggregate-baseline.json
MUTATION_RATCHET_REF ?= @{upstream}
MUTATION_SNAPSHOT_PATH ?= /tmp/aonw-mutation-baseline.json
PERFORMANCE_REPORT_PATH ?= /tmp/aonw-performance-report.json
PERFORMANCE_SNAPSHOT_PATH ?= /tmp/aonw-performance-baseline.json
PERFORMANCE_FRAME_REPORT_PATH ?= /tmp/aonw-reference-frame-report.json
PERFORMANCE_FRAME_DEVICE_ID ?=
PERFORMANCE_BASELINE ?= tool/performance_baseline.json
PERFORMANCE_POLICY ?= tool/performance_policy.json
PUB_CACHE ?= $(HOME)/.pub-cache
SERVERPOD_CLI ?= $(PUB_CACHE)/bin/serverpod
AONW_SERVERPOD_CRITICAL_E2E_PORT ?=
SERVERPOD_SMOKE_HOST ?= http://127.0.0.1:8080/
SERVERPOD_SMOKE_MAP ?= myranth
SERVERPOD_SEED_HOST ?= http://127.0.0.1:8080/
SERVERPOD_SEED_PASSWORD ?= AonwTest123!
SERVERPOD_SEED_EMAIL_DOMAIN ?= example.test
LOCAL_API_HOST ?= localhost
LOCAL_API_PORT ?= 8080
LOCAL_API_BASE_URL ?= http://$(LOCAL_API_HOST):$(LOCAL_API_PORT)
LOCAL_INSIGHTS_PORT ?= 8081
LOCAL_SERVER_WEB_PORT ?= 8082
LOCAL_WEB_HOST ?= localhost
LOCAL_WEB_PORT ?= 7357
LOCAL_WEB_DEVICE ?= chrome
LOCAL_HEALTH_URL ?= $(LOCAL_API_BASE_URL)/readyz
CADDY_VALIDATE_IMAGE ?= caddy:2-alpine@sha256:5f5c8640aae01df9654968d946d8f1a56c497f1dd5c5cda4cf95ab7c14d58648
PROMTOOL_IMAGE ?= prom/prometheus:latest@sha256:3c42b892cf723fa54d2f262c37a0e1f80aa8c8ddb1da7b9b0df9455a35a7f893
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
ENGINE_DOCS_SOURCE_DIR ?= deploy/engine-docs
ENGINE_DOCS_BUILD_DIR ?= build/engine-docs
ENGINE_DOCS_DEPLOY_DEST ?=
IOS_API_BASE_URL ?= https://api.aonw.net
DEPLOY_ALL_IOS_MODE ?= best-effort
# Removed aggregate-release option. A non-empty legacy value is rejected by
# deploy-all-plan so an old invocation cannot silently change behavior.
IOS_ARCHIVE_ON_DEPLOY ?=
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
STEAM_MACOS_ARCHIVE ?= build/macos/aonw-steam.xcarchive
STEAM_MACOS_EXPORT_DIR ?= build/macos/developer-id
STEAM_MACOS_BUILD_DIR ?= $(STEAM_MACOS_EXPORT_DIR)
STEAM_MACOS_APP ?= $(STEAM_MACOS_BUILD_DIR)/$(STEAM_MACOS_APP_NAME)
STEAM_MACOS_ZIP ?= $(STEAM_DIST_DIR)/aonw-macos-steam.zip
MACOS_EXPORT_OPTIONS ?= macos/DeveloperIDExportOptions.plist
MACOS_DEVELOPER_ID_ENTITLEMENTS ?= macos/Runner/DeveloperID.entitlements
MACOS_DEVELOPER_IDENTITY ?= Developer ID Application: Ernest Wisniewski (H64KBQ6T2S)
MACOS_DEVELOPMENT_TEAM ?= H64KBQ6T2S
MACOS_NOTARY_PROFILE ?= aonw-notary
STEAM_WINDOWS_RELEASE_DIR ?= build/windows/x64/runner/Release
STEAM_WINDOWS_ZIP ?= $(STEAM_DIST_DIR)/aonw-windows-steam.zip
STEAM_WINDOWS_SOURCE ?= auto
STEAM_WINDOWS_WORKFLOW ?= windows-steam-build.yml
STEAM_WINDOWS_ARTIFACT_DIR ?= build/steam-windows-artifact
STEAM_LINUX_RELEASE_DIR ?= build/linux/x64/release/bundle
STEAM_LINUX_BUNDLE_DIR ?= build/steam-linux-bundle
STEAM_LINUX_ZIP ?= $(STEAM_DIST_DIR)/aonw-linux-steam.zip
STEAM_LINUX_SOURCE ?= auto
STEAM_LINUX_WORKFLOW ?= linux-steam-build.yml
STEAM_LINUX_ARTIFACT_DIR ?= build/steam-linux-artifact
STEAMRT4_SDK_IMAGE ?= registry.gitlab.steamos.cloud/steamrt/steamrt4/sdk@sha256:2c4c6520a268ef53255d511ae5988e35855b39a4b6c1e9865d56e5011c76ec3e
STEAMRT4_PLATFORM_IMAGE ?= registry.gitlab.steamos.cloud/steamrt/steamrt4/platform@sha256:bd63a41c2007626ca954c4ffbd82417aae91e3a7cfe251fffd6e286ae85e3fd7
STEAMRT4_PLATFORM_SONAMES ?= build/steamrt4-contract/platform-sonames.txt
STEAM_GITHUB_RUN_LOOKUP_ATTEMPTS ?= 30
STEAM_GITHUB_RUN_LOOKUP_SLEEP ?= 5
STEAM_DEPLOY_DIR ?= $(HOME)/Desktop/steam-deploy
STEAM_CONTENT_DIR ?= $(STEAM_DEPLOY_DIR)/content
STEAM_SCRIPT_DIR ?= $(STEAM_DEPLOY_DIR)/scripts
STEAM_OUTPUT_DIR ?= $(STEAM_DEPLOY_DIR)/output
STEAM_WINDOWS_DIST_ZIP ?= $(STEAM_WINDOWS_ZIP)
STEAM_LINUX_DIST_ZIP ?= $(STEAM_LINUX_ZIP)
STEAM_APP_ID ?= 4833240
STEAM_MACOS_DEPOT_ID ?= 4833241
STEAM_WINDOWS_DEPOT_ID ?= 4833242
STEAM_LINUX_DEPOT_ID ?= 4833243
STEAM_INCLUDE_LINUX ?= 0
STEAM_USER ?= ew2pl
STEAMCMD ?= steamcmd
STEAM_BUILD_DESC ?=
ITCH_TARGET ?=
ITCH_DIST_DIR ?= $(STEAM_DIST_DIR)
ITCH_BUILD_DIR ?= build/itch
ITCH_MACOS_DIR ?= $(ITCH_BUILD_DIR)/macos
ITCH_WINDOWS_DIR ?= $(ITCH_BUILD_DIR)/windows
ITCH_LINUX_DIR ?= $(ITCH_BUILD_DIR)/linux
ITCH_ANDROID_APK ?= $(ITCH_DIST_DIR)/aonw-android.apk
ITCH_MACOS_CHANNEL ?= macos
ITCH_WINDOWS_CHANNEL ?= windows
ITCH_LINUX_CHANNEL ?= linux
ITCH_ANDROID_CHANNEL ?= android
ITCH_INCLUDE_LINUX ?= 0
ITCH_USER_VERSION ?= $(RELEASE_VERSION)
ITCH_UPLOAD_ARGS ?=
DOWNLOAD_BUILD_DIR ?= build/download
DOWNLOAD_DEPLOY_DEST ?= $(if $(HOMEPAGE_DEPLOY_DEST),$(HOMEPAGE_DEPLOY_DEST)/download,)
DOWNLOAD_BASE_URL ?= https://aonw.net/download
DOWNLOAD_MACOS_FILE ?= aonw-macos.zip
DOWNLOAD_WINDOWS_FILE ?= aonw-windows.zip
DOWNLOAD_LINUX_FILE ?= aonw-linux.zip
DOWNLOAD_ANDROID_FILE ?= aonw-android.apk
DOWNLOAD_MACOS_ZIP ?= $(DOWNLOAD_BUILD_DIR)/$(DOWNLOAD_MACOS_FILE)
DOWNLOAD_WINDOWS_ZIP ?= $(DOWNLOAD_BUILD_DIR)/$(DOWNLOAD_WINDOWS_FILE)
DOWNLOAD_LINUX_ZIP ?= $(DOWNLOAD_BUILD_DIR)/$(DOWNLOAD_LINUX_FILE)
DOWNLOAD_ANDROID_APK ?= $(DOWNLOAD_BUILD_DIR)/$(DOWNLOAD_ANDROID_FILE)
DOWNLOAD_INCLUDE_LINUX ?= 0
DEPLOY_ENV ?= staging
DEPLOY_ALL_STEAMWORKS ?= 0
DEPLOY_ALL_GOOGLE_PLAY ?= 0
DEPLOY_ALL_GOOGLE_PLAY_MODE ?= closed
DEPLOY_ALL_GOOGLE_PLAY_VALIDATE_ONLY ?= 0
DEPLOY_ALL_ITCH ?= 0
DEPLOY_ALL_PLAN_FORMAT ?= human
DEPLOY_ALL_INCLUDE_LINUX = $(if $(filter 1,$(STEAM_INCLUDE_LINUX) $(ITCH_INCLUDE_LINUX) $(DOWNLOAD_INCLUDE_LINUX)),1,0)

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
NEW_VERSION ?=
NEW_BUILD ?=
RELEASE_VERSION ?= $(shell sed -n 's/^version:[[:space:]]*//p' "$(PUBSPEC)" 2>/dev/null | head -n 1)
ENV_RELEASE_CHANNEL ?= $(shell awk -F= '/^AONW_RELEASE_CHANNEL=/{print $$2; exit}' .env 2>/dev/null)
AONW_APP_VERSION ?= $(RELEASE_VERSION)
AONW_RELEASE_CHANNEL ?= $(if $(ENV_RELEASE_CHANNEL),$(ENV_RELEASE_CHANNEL),ALPHA)

.DEFAULT_GOAL := help

.PHONY: help bootstrap toolchain-check p0-check legacy-freeze dependency-boundaries successor-boundary-test rust-engine-inventory-check rust-engine-inventory-test rust-engine-inventory-ast-check rust-determinism-inventory-check rust-determinism-inventory-test rust-determinism-check rust-fixture-disposition-check rust-fixture-disposition-test rust-corpus-parity-check rust-architecture-check rust-architecture-policy-check rust-architecture-policy-test rust-dependency-check rust-dependency-policy-check rust-dependency-policy-test rust-check rust-format-check rust-clippy rust-test rust-doc rust-release-compile-smoke rust-benchmark rust-flutter-test rust-godot-build godot-native-config godot-check godot-editor-check godot-editor godot-run godot-test godot-map-sync dependencies root-dependencies core-dependencies client-dependencies server-dependencies profile-check local local-start local-up local-health local-seed local-multiplayer-smoke local-web local-down ci generated-code-check assets-compile assets-verify assets-check assets-reproduce format-check analyze flutter-analyze core-analyze client-analyze server-analyze architecture architecture-check architecture-snapshot mutation mutation-check mutation-snapshot performance performance-check performance-report performance-snapshot performance-frame-check check flutter-test core-test client-test coverage coverage-directory coverage-reports coverage-check coverage-snapshot flutter-coverage-report core-coverage-report server-coverage-report flutter-coverage core-coverage server-coverage reducer-parity-test critical-e2e-test local-game-e2e-test native-local-game-smoke serverpod-critical-e2e-test release-check deploy deploy-all deploy-all-plan deploy-all-preflight deploy-clean build-web deploy-web deploy-web-files deploy-homepage deploy-homepage-files build-homepage stage-engine-docs build-engine-docs deploy-engine-docs deploy-engine-docs-files download-artifacts download-package deploy-downloads deploy-download-files health-downloads archive-ios archive-ios-if-possible android-keystore android-preflight android-play-preflight android-build-aab android-build-apk android-build-itch android-release android-upload-aab android-upload-closed android-deploy android-deploy-closed multiplayer-platform-smoke steam deploy-steam macos-distribution-preflight steam-macos steam-windows steam-windows-local steam-windows-github steam-package-windows steam-runtime-contract steam-linux steam-linux-local steam-linux-github steam-package-linux steam-prepare-from-dist steam-upload steam-upload-command steam-release-from-dist itch deploy-itch itch-desktop itch-prepare itch-upload bump-version preflight-release preflight pull build server-test server-integration-test serverpod-runtime-smoke serverpod-seed-test-users compose-check docker-context-check infra-config-check serverpod-config-check serverpod-ops-check serverpod-version serverpod-cli-install serverpod-cli-ensure serverpod-cli-check check-migrations migrate up health health-web health-homepage health-architecture health-stats health-engine-docs prune status logs godot-toolchain-check terrain3d-check godot-terrain-compile successor-map-contract-test successor-flutter-dependencies successor-flutter-format-check successor-flutter-analyze successor-flutter-test successor-flutter-check successor-flutter-coverage-report successor-flutter-device-test successor-flutter-fm4-pilot successor-flutter-fm5-baseline successor-flutter-run godot-map-bundle-check map-stage-1-check stage-1-visual-evidence rust-tool-versions rust-evidence-tool-versions rust-coverage-check rust-coverage-report rust-coverage-policy-test rust-coverage-snapshot rust-performance-check rust-performance-report rust-performance-policy-test rust-performance-snapshot rust-test-release rust-native-assets-contract-test rust-foundation-check rust-turn-kernel-check rust-diplomacy-policy-check rust-tech-gate-check rust-movement-logistics-check rust-combat-check rust-city-check rust-worker-check successor-engine-check successor-engine-evidence-check successor-engine-quality-check successor-engine-deep-check

.PHONY: rust-integrated-turn-check rust-ai-ledger-check rust-ai-strength-check rust-ai-check rust-persistence-check
.PHONY: rust-security-policy-test rust-security-policy-check rust-security-tool-versions rust-mutation-check rust-fuzz-smoke rust-miri-check rust-ffi-sanitizer-check rust-engine-security-check rust-release-metadata-policy-test rust-release-metadata-policy-check rust-release-metadata-tool-versions rust-release-metadata-check rust-engine-completion-check

help:
	@echo "AONW deploy helpers"
	@echo ""
	@echo "Quick release flow:"
	@echo "  make deploy-all-plan Validate inputs and print the release plan without mutations"
	@echo "  make deploy-all    Preflight, bump, prepare, deploy backend, publish, and verify"
	@echo "  make deploy steam  Build Steam macOS + Windows ZIPs into dist/"
	@echo ""
	@echo "Individual targets:"
	@echo "  make bootstrap    LOCAL: install pinned toolchains and all locked dependencies"
	@echo "  make toolchain-check LOCAL: verify .fvmrc Flutter and its bundled Dart are active"
	@echo "  make p0-check      LOCAL: verify legacy freeze, successor boundaries and Rust migration inventory"
	@echo "  make successor-map-contract-test LOCAL: verify shared geometry and deterministic starter bundle"
	@echo "  make successor-flutter-check LOCAL: format, analyze, and test the Rust-backed successor client"
	@echo "  make successor-flutter-coverage-report LOCAL: write successor client LCOV after the full test suite"
	@echo "  make successor-flutter-device-test LOCAL: build and exercise the standalone client on macOS"
	@echo "  make successor-flutter-fm5-baseline LOCAL: validate the production Flame cutover performance budget"
	@echo "  make successor-flutter-run LOCAL: run the standalone Rust-backed client on macOS"
	@echo "  make map-stage-1-check LOCAL: compare Flutter and Godot semantic map probes"
	@echo "  make stage-1-visual-evidence LOCAL: regenerate the reviewed map screenshots"
	@echo "  make rust-check   LOCAL: format, lint, test, and document the Rust workspace"
	@echo "  make stage-engine-docs LOCAL: refresh the landing page around the last successful Rust API docs"
	@echo "  make build-engine-docs LOCAL: generate current Rust API docs with the AoNW Engine landing page"
	@echo "  make deploy-engine-docs LOCAL: build and rsync current local Rust docs to engine.aonw.net"
	@echo "  make rust-determinism-check LOCAL: verify named inputs and debug/release replay parity"
	@echo "  make rust-corpus-parity-check LOCAL: verify reviewed 120-case dispositions and active Rust parity"
	@echo "  make rust-architecture-check LOCAL: verify Rust crate edges, pure boundaries, unsafe census and source ratchet"
	@echo "  make rust-dependency-check LOCAL: verify pinned Rust licenses, sources and duplicate ratchet"
	@echo "  make rust-coverage-check LOCAL: generate LCOV/JSON and enforce the per-crate Rust ratchet"
	@echo "  make rust-performance-check LOCAL: enforce Rust signatures, work, payload and allocation ceilings"
	@echo "  make rust-turn-kernel-check LOCAL: verify T1 player/system lifecycle, replay and budgets"
	@echo "  make rust-diplomacy-policy-check LOCAL: verify DP hostility, entry, attack, automation, trade and disclosure"
	@echo "  make rust-tech-gate-check LOCAL: verify canonical technology catalog, costs, prerequisites and unlock gates"
	@echo "  make rust-combat-check LOCAL: verify C3 combat, deterministic rolls, replay and budgets"
	@echo "  make rust-city-check LOCAL: verify C4 city founding, territory, replay and budgets"
	@echo "  make rust-worker-check LOCAL: verify W5 workers, automation, infrastructure, replay and budgets"
	@echo "  make rust-integrated-turn-check LOCAL: verify O9 outcome, integrated turn, replay and bounded soak"
	@echo "  make rust-ai-check LOCAL: verify A10 deterministic planners through public runtime commands"
	@echo "  make rust-ai-strength-check LOCAL: verify the pinned AI league and full multi-AI game"
	@echo "  make successor-engine-check LOCAL: run the fast successor engine quality gate"
	@echo "  make successor-engine-evidence-check LOCAL: generate parity, coverage and performance evidence"
	@echo "  make successor-engine-deep-check LOCAL: run scheduled release-mode successor checks"
	@echo "  make rust-benchmark LOCAL: report Rust map and movement baseline timings"
	@echo "  make rust-flutter-test LOCAL: test Flutter package_ffi stub and Rust adapter"
	@echo "  make rust-godot-build LOCAL: build the Rust GDExtension for Godot"
	@echo "  make godot-toolchain-check LOCAL: verify the exact pinned Godot build"
	@echo "  make terrain3d-check LOCAL: verify the pinned Terrain3D addon"
	@echo "  make godot-terrain-compile LOCAL: compile versioned terrain profiles for Terrain3D"
	@echo "  make godot-editor LOCAL: open AoNW with the Map Workbench dock"
	@echo "  make godot-run    LOCAL: run the AoNW map preview"
	@echo "  make godot-check  LOCAL: run Godot map tests and an editor/plugin smoke test"
	@echo "  make godot-map-sync LOCAL: compile the self-contained starter map bundle"
	@echo "  make godot-map-bundle-check LOCAL: verify the committed starter bundle is reproducible"
	@echo "  make dependencies LOCAL: install all five package graphs from committed lockfiles"
	@echo "  make local        LOCAL: start Docker API, seed users, and run Flutter Web on OAuth origin localhost:7357"
	@echo "  make local-start  LOCAL: start Docker API and seed four reusable multiplayer users"
	@echo "  make local-multiplayer-smoke LOCAL: verify quickplay, streams, commands, reconnect, and event history"
	@echo "  make local-down   LOCAL: stop the Docker development stack without deleting data"
	@echo "  make ci           LOCAL: generated drift, static, architecture, mutation, performance, and coverage gates"
	@echo "  make architecture LOCAL: full Dart census, AST targets, and legacy-debt ratchet"
	@echo "  make architecture-snapshot LOCAL: write a reviewed architecture baseline candidate to /tmp"
	@echo "  make mutation     LOCAL: deterministic mutation gate for critical domain and auth code"
	@echo "  make mutation-snapshot LOCAL: write a reviewed mutation baseline candidate to /tmp"
	@echo "  make performance  LOCAL: deterministic map, persistence, replay, AI, and renderer performance gate"
	@echo "  make performance-report LOCAL: write stable metrics and diagnostic timings to /tmp"
	@echo "  make performance-snapshot LOCAL: write a reviewed stable baseline candidate to /tmp"
	@echo "  make performance-frame-check LOCAL: validate timings captured on the pinned profile device"
	@echo "  make coverage     LOCAL: deterministic line coverage, exact ratchet, and 90% diff gate"
	@echo "  make coverage-snapshot LOCAL: write a reviewed candidate baseline to /tmp"
	@echo "  make flutter-coverage/core-coverage/server-coverage LOCAL: run one coverage scope"
	@echo "  make generated-code-check LOCAL: verify every committed generator in an isolated snapshot"
	@echo "  make analyze      LOCAL: run the fatal shared analysis policy in all four packages"
	@echo "  make release-check LOCAL: run CI, configuration checks, and PostgreSQL-backed critical E2E"
	@echo "  make check        LOCAL: analyze/test Flutter app, core package, client package, and server"
	@echo "  make reducer-parity-test LOCAL: run local/server reducer fixtures against one oracle"
	@echo "  make profile-check LOCAL: validate the selected Compose deployment profile"
	@echo "  make deploy        Pull repo, rebuild Docker, restart staging, check health"
	@echo "  make deploy-clean  Same, but build server without cache and prune build cache"
	@echo "  make build-web     LOCAL: build Flutter web bundle without deploying"
	@echo "  make deploy-web    LOCAL: build Flutter web bundle and rsync to demo host dir"
	@echo "  make deploy-web-files LOCAL: upload the existing web bundle without rebuilding"
	@echo "  make deploy-homepage LOCAL: stage static aonw.net homepage and rsync to staging"
	@echo "  make deploy-homepage-files LOCAL: upload the staged homepage without rebuilding"
	@echo "  make deploy-downloads LOCAL: publish latest downloadable builds under aonw.net/download/"
	@echo "  make archive-ios   LOCAL: create an Xcode Organizer archive for current build"
	@echo "  make macos-distribution-preflight LOCAL: verify Developer ID and notarization credentials"
	@echo "  make android-keystore Create an Android upload keystore"
	@echo "  make android-release LOCAL: test and build Play Store .aab"
	@echo "  make android-upload-aab LOCAL: upload existing .aab to Google Play"
	@echo "  make android-upload-closed LOCAL: upload existing .aab to closed test"
	@echo "  make android-deploy LOCAL: build .aab and upload it to Google Play"
	@echo "  make android-deploy-closed LOCAL: build .aab and upload it to closed test"
	@echo "  make android-build-itch LOCAL: build universal Android APK for itch.io into dist/"
	@echo "  make android-build-apk LOCAL: build split release APKs for sideload testing"
	@echo "  make multiplayer-platform-smoke LOCAL: build web/macOS/iOS/Android/Windows smoke targets"
	@echo "  make steam        LOCAL/CI: build Steam ZIPs into dist/"
	@echo "  make steam-prepare-from-dist LOCAL: prepare SteamPipe content from dist/ ZIPs"
	@echo "  make steam-upload LOCAL: upload prepared SteamPipe content with steamcmd"
	@echo "  make deploy-steam LOCAL: build macOS, use Windows ZIP from dist/, upload Steam build"
	@echo "  make itch         LOCAL: build/download Windows/macOS/Android artifacts and upload to itch.io"
	@echo "  make deploy-all DEPLOY_ALL_STEAMWORKS=1 DEPLOY_ALL_GOOGLE_PLAY=1 DEPLOY_ALL_ITCH=1  Explicitly enable store uploads"
	@echo "  make bump-version  Bump marketing/build version in pubspec.yaml + platform files"
	@echo "  make build         Build server image"
	@echo "  make server-test   LOCAL: analyze server and run non-integration Dart tests"
	@echo "  make server-integration-test LOCAL: run Serverpod integration tests"
	@echo "  make critical-e2e-test LOCAL: run local persistence and live Serverpod critical journeys"
	@echo "  make local-game-e2e-test LOCAL: run create, command, save, and fresh-runtime reload journey"
	@echo "  make serverpod-critical-e2e-test LOCAL: run public auth, match, command, and reconnect journey"
	@echo "  make serverpod-runtime-smoke LOCAL: run two-account stream/reconnect smoke against a running Serverpod host"
	@echo "  make serverpod-seed-test-users LOCAL: create/update four local Serverpod test users"
	@echo "  make compose-check LOCAL: validate Docker Compose files without starting services"
	@echo "  make docker-context-check LOCAL: prove secrets stay out of the server build context"
	@echo "  make infra-config-check LOCAL: validate Caddy, Prometheus, Dockerfile, and build context"
	@echo "  make serverpod-ops-check LOCAL: validate generated code and deployment configs"
	@echo "  make serverpod-version LOCAL: print the runtime pin required by the Serverpod CLI"
	@echo "  make serverpod-cli-install LOCAL: install the CLI version required by the runtime"
	@echo "  make serverpod-cli-check LOCAL: verify the installed Serverpod CLI matches the runtime"
	@echo "  make check-migrations LOCAL: alias for the complete generated-code drift gate"
	@echo "  make migrate       Explain Serverpod startup migration flow"
	@echo "  make health        Check deployed Serverpod health endpoint"
	@echo "  make health-web    Check deployed demo web frontend"
	@echo "  make health-homepage Check deployed aonw.net homepage"
	@echo "  make health-architecture Check deployed aonw.net architecture atlas"
	@echo "  make health-stats  Check deployed aonw.net multiplayer statistics page"
	@echo "  make status        Show Docker Compose service status"
	@echo "  make logs          Follow server logs"
	@echo ""
	@echo "Options:"
	@echo "  LOCAL_API_BASE_URL=http://... Local Flutter/Serverpod API. Default: $(LOCAL_API_BASE_URL)"
	@echo "  LOCAL_WEB_PORT=7357            Stable Google OAuth web origin port. Default: $(LOCAL_WEB_PORT)"
	@echo "  PROFILE=dev|tunnel|staging|prod Default: $(PROFILE)"
	@echo "  BRANCH=main                    Optional branch checkout before pull"
	@echo "  CHECK_MIGRATIONS=1             Run the complete generated-code drift gate after build"
	@echo "  COVERAGE_BASE_REF=origin/main  Git ref used for changed-line coverage. Default: $(COVERAGE_BASE_REF)"
	@echo "  COVERAGE_RATCHET_REF=@{upstream} Trusted previous baseline and incremental-diff ref. Default: $(COVERAGE_RATCHET_REF)"
	@echo "  COVERAGE_SNAPSHOT_PATH=/tmp/... Candidate baseline output. Default: $(COVERAGE_SNAPSHOT_PATH)"
	@echo "  ARCHITECTURE_RATCHET_REF=@{upstream} Trusted architecture baseline ref. Default: $(ARCHITECTURE_RATCHET_REF)"
	@echo "  ARCHITECTURE_SNAPSHOT_PATH=/tmp/... Candidate architecture baseline output. Default: $(ARCHITECTURE_SNAPSHOT_PATH)"
	@echo "  ARCHITECTURE_AGGREGATE_SNAPSHOT_PATH=/tmp/... Candidate library aggregate baseline. Default: $(ARCHITECTURE_AGGREGATE_SNAPSHOT_PATH)"
	@echo "  MUTATION_RATCHET_REF=@{upstream} Trusted mutation survivor baseline ref. Default: $(MUTATION_RATCHET_REF)"
	@echo "  MUTATION_SNAPSHOT_PATH=/tmp/... Candidate mutation baseline output. Default: $(MUTATION_SNAPSHOT_PATH)"
	@echo "  PERFORMANCE_REPORT_PATH=/tmp/... Full benchmark report output. Default: $(PERFORMANCE_REPORT_PATH)"
	@echo "  PERFORMANCE_SNAPSHOT_PATH=/tmp/... Candidate stable benchmark baseline. Default: $(PERFORMANCE_SNAPSHOT_PATH)"
	@echo "  PERFORMANCE_FRAME_REPORT_PATH=/tmp/... Pinned-device frame report input. Default: $(PERFORMANCE_FRAME_REPORT_PATH)"
	@echo "  PERFORMANCE_FRAME_DEVICE_ID=... Required pinned-device identifier for the frame gate"
	@echo "  PUB_CACHE=/path/to/cache      Dart global package cache. Default: $(PUB_CACHE)"
	@echo "  SERVERPOD_CLI=/path/to/serverpod Override the CLI binary. Default: $(SERVERPOD_CLI)"
	@echo "  AONW_TEST_DATABASE_PASSWORD=... PostgreSQL test password; falls back to SERVERPOD_TEST_DATABASE_PASSWORD, then aonw_dev"
	@echo "  AONW_TEST_DATABASE_PORT=... PostgreSQL test port. Default: 5432"
	@echo "  SERVERPOD_TEST_DATABASE_PASSWORD=... Legacy PostgreSQL test password fallback"
	@echo "  AONW_SERVERPOD_CRITICAL_E2E_PORT=... optional critical E2E API port; default allocates and locks a free triplet"
	@echo "  SERVERPOD_SMOKE_HOST=http://... serverpod-runtime-smoke only. Default: $(SERVERPOD_SMOKE_HOST)"
	@echo "  SERVERPOD_SMOKE_MAP=myranth      serverpod-runtime-smoke only. Default: $(SERVERPOD_SMOKE_MAP)"
	@echo "  SERVERPOD_SEED_HOST=http://...  serverpod-seed-test-users only. Default: $(SERVERPOD_SEED_HOST)"
	@echo "  SERVERPOD_SEED_PASSWORD=...     serverpod-seed-test-users only. Default: $(SERVERPOD_SEED_PASSWORD)"
	@echo "  SERVERPOD_SEED_EMAIL_DOMAIN=... serverpod-seed-test-users only. Default: $(SERVERPOD_SEED_EMAIL_DOMAIN)"
	@echo "  SERVERPOD_PASSWORD_redis=...     Required by Compose when Redis is enabled"
	@echo "  PULL=0                         Build from cached base images"
	@echo "  AONW_APP_VERSION=x.y.z+n      Server image app version. Default: $(AONW_APP_VERSION)"
	@echo "  HEALTH_URL=https://.../readyz Default: $(HEALTH_URL)"
	@echo "  WEB_HEALTH_URL=https://...    Default: $(WEB_HEALTH_URL)"
	@echo "  HOMEPAGE_HEALTH_URL=https://... Default: $(HOMEPAGE_HEALTH_URL)"
	@echo "  ARCHITECTURE_HEALTH_URL=https://... Default: $(ARCHITECTURE_HEALTH_URL)"
	@echo "  STATS_HEALTH_URL=https://... Default: $(STATS_HEALTH_URL)"
	@echo "  STATS_API_HEALTH_URL=https://... Default: $(STATS_API_HEALTH_URL)"
	@echo "  WEB_API_BASE_URL=https://...  deploy-web only. Default: $(WEB_API_BASE_URL)"
	@echo "  WEB_DEPLOY_SSH_KEY=/path      deploy-web/deploy-homepage only. Required"
	@echo "  WEB_DEPLOY_USER=user          deploy-web/deploy-homepage only. Required"
	@echo "  WEB_DEPLOY_HOST=host          deploy-web/deploy-homepage only. Required"
	@echo "  WEB_DEPLOY_DEST=/path         deploy-web only. Required"
	@echo "  HOMEPAGE_DEPLOY_DEST=/path    deploy-homepage only. Required"
	@echo "  DOWNLOAD_DEPLOY_DEST=/path    deploy-downloads only. Default: HOMEPAGE_DEPLOY_DEST/download"
	@echo "  DOWNLOAD_INCLUDE_LINUX=0|1    publish aonw-linux.zip too. Default: $(DOWNLOAD_INCLUDE_LINUX)"
	@echo "  DOWNLOAD_BASE_URL=https://... public download URL. Default: $(DOWNLOAD_BASE_URL)"
	@echo "  REMOTE_DEPLOY_PATH=/path      deploy-all remote repo path. Required"
	@echo "  DEPLOY_ENV=staging|prod       deploy-all backend environment. Default: $(DEPLOY_ENV)"
	@echo "  DEPLOY_ALL_IOS_MODE=off|best-effort|required Default: $(DEPLOY_ALL_IOS_MODE)"
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
	@echo "  MACOS_EXPORT_OPTIONS=path      Developer ID export plist. Default: $(MACOS_EXPORT_OPTIONS)"
	@echo "  MACOS_DEVELOPER_IDENTITY=...   Developer ID identity. Default: $(MACOS_DEVELOPER_IDENTITY)"
	@echo "  MACOS_DEVELOPMENT_TEAM=...     Apple Developer team. Default: $(MACOS_DEVELOPMENT_TEAM)"
	@echo "  MACOS_NOTARY_PROFILE=name      notarytool Keychain profile. Default: $(MACOS_NOTARY_PROFILE)"
	@echo "  STEAM_WINDOWS_SOURCE=auto|local|github|existing Steam Windows source. Default: $(STEAM_WINDOWS_SOURCE)"
	@echo "  STEAM_LINUX_SOURCE=auto|local|github|existing Steam Linux source. Default: $(STEAM_LINUX_SOURCE)"
	@echo "  STEAM_INCLUDE_LINUX=0|1     include Linux ZIP/depot in Steam prepare/upload. Default: $(STEAM_INCLUDE_LINUX)"
	@echo "  STEAM_LINUX_DEPOT_ID=...    Linux depot for STEAM_INCLUDE_LINUX=1. Default: $(STEAM_LINUX_DEPOT_ID)"
	@echo "  STEAM_DEPLOY_DIR=/path        SteamPipe working dir. Default: $(STEAM_DEPLOY_DIR)"
	@echo "  STEAM_WINDOWS_DIST_ZIP=path   Windows ZIP/artifact for steam-prepare-from-dist. Default: $(STEAM_WINDOWS_DIST_ZIP)"
	@echo "  STEAM_LINUX_DIST_ZIP=path     Linux ZIP/artifact for steam-prepare-from-dist. Default: $(STEAM_LINUX_DIST_ZIP)"
	@echo "  STEAM_USER=user               SteamCMD username. Default: $(STEAM_USER)"
	@echo "  STEAM_BUILD_DESC=text         Steam build description. Default: Build N - x.y.z release"
	@echo "  ITCH_TARGET=user/game|empty   required only with DEPLOY_ALL_ITCH=1"
	@echo "  ITCH_MACOS_CHANNEL=macos      itch macOS channel. Default: $(ITCH_MACOS_CHANNEL)"
	@echo "  ITCH_WINDOWS_CHANNEL=windows  itch Windows channel. Default: $(ITCH_WINDOWS_CHANNEL)"
	@echo "  ITCH_INCLUDE_LINUX=0|1        include Linux folder in itch prepare/upload. Default: $(ITCH_INCLUDE_LINUX)"
	@echo "  ITCH_LINUX_CHANNEL=linux      itch Linux channel. Default: $(ITCH_LINUX_CHANNEL)"
	@echo "  ITCH_ANDROID_CHANNEL=android  itch Android channel. Default: $(ITCH_ANDROID_CHANNEL)"
	@echo "  ITCH_USER_VERSION=x.y.z+n     itch build version. Default: $(ITCH_USER_VERSION)"
	@echo "  DEPLOY_ALL_STEAMWORKS=0|1     deploy-all Steamworks upload. Default: $(DEPLOY_ALL_STEAMWORKS)"
	@echo "  DEPLOY_ALL_GOOGLE_PLAY=0|1    deploy-all Google Play action. Default: $(DEPLOY_ALL_GOOGLE_PLAY)"
	@echo "  DEPLOY_ALL_GOOGLE_PLAY_MODE=closed|internal|alpha|beta|production Google Play mode. Default: $(DEPLOY_ALL_GOOGLE_PLAY_MODE)"
	@echo "  DEPLOY_ALL_GOOGLE_PLAY_VALIDATE_ONLY=0|1 validate without publishing. Default: $(DEPLOY_ALL_GOOGLE_PLAY_VALIDATE_ONLY)"
	@echo "  DEPLOY_ALL_ITCH=0|1          deploy-all itch.io upload; requires ITCH_TARGET. Default: $(DEPLOY_ALL_ITCH)"
	@echo "  DEPLOY_ALL_PLAN_FORMAT=human|json|artifact-json deploy-all-plan output. Default: $(DEPLOY_ALL_PLAN_FORMAT)"
	@echo "  VERSION_BUMP=patch|none       bump-version/deploy-all default: $(VERSION_BUMP)"
	@echo "  NEW_VERSION=x.y.z|empty       optional override; empty follows VERSION_BUMP"
	@echo "  NEW_BUILD=integer>current|empty optional override; empty means current+1"

profile-check:
	@case "$(PROFILE)" in \
		dev|tunnel|staging|prod) ;; \
		*) echo "Unsupported PROFILE=$(PROFILE). Expected dev, tunnel, staging, or prod."; exit 1 ;; \
	esac

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

preflight: profile-check
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

build: profile-check
	@test -n "$(AONW_APP_VERSION)" || { echo "Could not parse AONW_APP_VERSION from $(PUBSPEC)."; exit 1; }
	@echo "Building server image with AONW_APP_VERSION=$(AONW_APP_VERSION), AONW_RELEASE_CHANNEL=$(AONW_RELEASE_CHANNEL)"
	@AONW_APP_VERSION="$(AONW_APP_VERSION)" AONW_RELEASE_CHANNEL="$(AONW_RELEASE_CHANNEL)" $(COMPOSE_PROFILE) build $(PULL_FLAGS) $(CACHE_FLAGS) "$(SERVER_SERVICE)"
	@if [ "$(CHECK_MIGRATIONS)" = "1" ]; then \
		$(MAKE) --no-print-directory check-migrations PROFILE="$(PROFILE)" SERVER_SERVICE="$(SERVER_SERVICE)" COMPOSE="$(COMPOSE)"; \
	fi

bootstrap:
	@tool/bootstrap_workspace.sh
	@$(MAKE) --no-print-directory serverpod-cli-ensure

toolchain-check:
	@tool/check_toolchain.sh

p0-check: legacy-freeze dependency-boundaries successor-boundary-test rust-engine-inventory-check rust-engine-inventory-test rust-determinism-inventory-check rust-determinism-inventory-test rust-fixture-disposition-check rust-fixture-disposition-test

legacy-freeze:
	@tool/check_legacy_freeze.sh

dependency-boundaries:
	@tool/check_successor_dependencies.sh

successor-boundary-test:
	@tool/test_successor_boundaries.sh

rust-engine-inventory-check:
	@tool/check_rust_engine_inventory.sh

rust-engine-inventory-test:
	@tool/test_rust_engine_inventory.sh

rust-engine-inventory-ast-check: root-dependencies
	@flutter test --no-pub test/architecture/rust_engine_migration_inventory_test.dart

rust-determinism-inventory-check:
	@tool/check_rust_determinism_inventory.sh

rust-determinism-inventory-test:
	@tool/test_rust_determinism_inventory.sh

rust-determinism-check: rust-determinism-inventory-check rust-determinism-inventory-test
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_local_runtime --test local_session deterministic_replay_signature_is_stable
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked --release -p aonw_local_runtime --test local_session deterministic_replay_signature_is_stable

rust-fixture-disposition-check:
	@tool/check_rust_fixture_dispositions.sh

rust-fixture-disposition-test:
	@tool/test_rust_fixture_dispositions.sh

rust-corpus-parity-check: rust-fixture-disposition-check rust-fixture-disposition-test
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_engine --test canonical_fixture_engine review::reviewed_reducer_dispositions_gate_execution_by_capability -- --exact

rust-architecture-policy-check:
	@tool/check_rust_architecture.py

rust-architecture-policy-test:
	@tool/test_rust_architecture.py

rust-architecture-check: rust-architecture-policy-check rust-architecture-policy-test

rust-dependency-policy-check:
	@tool/check_rust_dependencies.py --report "$(RUST_DEPENDENCY_REPORT_PATH)"

rust-dependency-policy-test:
	@tool/test_rust_dependencies.py

rust-dependency-check: rust-dependency-policy-check rust-dependency-policy-test

rust-coverage-policy-test:
	@tool/test_rust_coverage.py

rust-coverage-report: rust-evidence-tool-versions
	@tool/check_rust_coverage.py report --report "$(RUST_COVERAGE_REPORT_PATH)" --lcov "$(RUST_COVERAGE_LCOV_PATH)"

rust-coverage-check: rust-coverage-policy-test rust-evidence-tool-versions
	@tool/check_rust_coverage.py check --report "$(RUST_COVERAGE_REPORT_PATH)" --lcov "$(RUST_COVERAGE_LCOV_PATH)"

rust-coverage-snapshot: rust-evidence-tool-versions
	@tool/check_rust_coverage.py snapshot --report "$(RUST_COVERAGE_REPORT_PATH)" --lcov "$(RUST_COVERAGE_LCOV_PATH)" --snapshot "$(RUST_COVERAGE_SNAPSHOT_PATH)"

rust-performance-policy-test:
	@tool/test_rust_performance.py

rust-performance-report:
	@tool/check_rust_performance.py report --report "$(RUST_PERFORMANCE_REPORT_PATH)"

rust-performance-check: rust-performance-policy-test
	@tool/check_rust_performance.py check --report "$(RUST_PERFORMANCE_REPORT_PATH)"

rust-performance-snapshot:
	@tool/check_rust_performance.py snapshot --report "$(RUST_PERFORMANCE_REPORT_PATH)" --snapshot "$(RUST_PERFORMANCE_SNAPSHOT_PATH)"

rust-tool-versions:
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) --version
	@cd "$(RUST_WORKSPACE)" && rustc --version
	@cargo-deny --version

rust-evidence-tool-versions:
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) --version
	@cd "$(RUST_WORKSPACE)" && rustc --version
	@cd "$(RUST_WORKSPACE)" && cargo llvm-cov --version

rust-native-assets-contract-test: root-dependencies
	@dart test packages/aonw_rust_client/test/build_hook_test.dart

rust-foundation-check: rust-corpus-parity-check rust-performance-check

rust-turn-kernel-check: rust-engine-inventory-check rust-performance-check
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_engine --test turn_kernel
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_local_runtime --test turn_kernel_runtime
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_contracts --test client_contract

rust-diplomacy-policy-check: rust-engine-inventory-check
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_engine --test diplomacy_policy

rust-tech-gate-check: rust-engine-inventory-check
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_content
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_engine --test technology_gate

rust-movement-logistics-check: rust-engine-inventory-check rust-performance-check
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_engine --test movement_logistics
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_local_runtime --test movement_logistics_runtime
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_contracts

rust-combat-check: rust-engine-inventory-check rust-determinism-check rust-diplomacy-policy-check rust-tech-gate-check rust-performance-check
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_engine --test combat
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_local_runtime --test combat_runtime
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_contracts

rust-city-check: rust-engine-inventory-check rust-corpus-parity-check rust-performance-check
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_engine --test city
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_local_runtime --test city_runtime
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_contracts

rust-worker-check: rust-engine-inventory-check rust-corpus-parity-check rust-tech-gate-check rust-performance-check
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_engine --test worker
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_local_runtime --test worker_runtime
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_contracts

rust-integrated-turn-check: rust-engine-inventory-check rust-corpus-parity-check rust-determinism-check rust-performance-check
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_domain --test outcome_invariants
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_engine --test outcome
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_engine --test turn_kernel
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_local_runtime --test turn_kernel_runtime
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_contract_mapping --test game_state_contract
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_contracts

rust-ai-ledger-check:
	@tool/check_rust_ai_ledger.py

rust-ai-strength-check: rust-ai-ledger-check rust-performance-check
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_ai --test strength_gate
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_ai --test full_game

rust-ai-check: rust-ai-ledger-check rust-engine-inventory-check rust-determinism-inventory-check rust-determinism-inventory-test rust-performance-check
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_ai --all-features
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked --release -p aonw_ai --test deterministic_search mcts_is_identical_for_the_same_state_seed_and_budget -- --exact

rust-replacement-surface-check:
	@tool/check_rust_replacement_surface.py

rust-restore-matrix-check:
	@tool/check_rust_restore_matrix.py
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_local_runtime \
		--test artifact_runtime \
		--test city_runtime \
		--test combat_runtime \
		--test diplomacy_runtime \
		--test movement_logistics_runtime \
		--test production_runtime \
		--test research_runtime \
		--test turn_kernel_runtime \
		--test worker_runtime

rust-persistence-check: rust-replacement-surface-check rust-restore-matrix-check rust-engine-inventory-check rust-determinism-inventory-check rust-determinism-inventory-test rust-performance-check
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_contracts persistence::tests
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_local_runtime --lib persistence_file::tests
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_local_runtime --test persistence_hardening
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked -p aonw_local_runtime --test local_session deterministic_replay_signature_is_stable -- --exact

rust-security-policy-test:
	@tool/test_rust_security.py

rust-security-policy-check: rust-security-policy-test
	@tool/check_rust_security.py policy

rust-security-tool-versions: rust-security-policy-check
	@tool/check_rust_security.py tools

rust-mutation-check: rust-security-policy-check
	@tool/check_rust_security.py mutation

rust-fuzz-smoke: rust-security-policy-check
	@cargo fmt --manifest-path engine/fuzz/Cargo.toml -- --check
	@cargo metadata --manifest-path engine/fuzz/Cargo.toml --locked --no-deps --format-version 1 >/dev/null
	@tool/check_rust_security.py fuzz

rust-miri-check: rust-security-policy-check
	@tool/check_rust_security.py miri

rust-ffi-sanitizer-check: rust-security-policy-check
	@tool/check_rust_security.py sanitizers

rust-engine-security-check: rust-mutation-check rust-fuzz-smoke rust-miri-check rust-ffi-sanitizer-check

rust-release-metadata-policy-test:
	@tool/test_rust_release_metadata.py

rust-release-metadata-policy-check: rust-release-metadata-policy-test
	@tool/check_rust_release_metadata.py policy

rust-release-metadata-tool-versions: rust-release-metadata-policy-check
	@tool/check_rust_release_metadata.py tools

rust-release-metadata-check: rust-release-metadata-policy-check
	@tool/check_rust_release_metadata.py check

successor-engine-check: rust-tool-versions p0-check rust-check rust-architecture-check rust-dependency-check rust-determinism-check rust-security-policy-check rust-release-metadata-policy-check

successor-engine-evidence-check: rust-evidence-tool-versions rust-engine-inventory-ast-check rust-corpus-parity-check rust-coverage-check rust-performance-check

successor-engine-quality-check: successor-engine-check successor-engine-evidence-check rust-native-assets-contract-test

successor-engine-deep-check: successor-engine-check rust-test-release rust-foundation-check rust-release-metadata-check

rust-engine-completion-check: successor-engine-quality-check rust-test-release rust-foundation-check rust-integrated-turn-check rust-ai-strength-check rust-persistence-check rust-engine-security-check rust-release-metadata-check

successor-map-contract-test: root-dependencies successor-flutter-dependencies
	@cd clients/aonw_flutter && flutter test --no-pub test/features/map/presentation/geometry/odd_q_flat_top_geometry_test.dart
	@flutter test --no-pub test/tool/map_asset_bundle_compiler_test.dart
	@dart run tool/assets/compile/starter_map_bundle.dart check

successor-flutter-dependencies: toolchain-check
	@cd clients/aonw_flutter && flutter pub get --enforce-lockfile

successor-flutter-format-check:
	@cd clients/aonw_flutter && dart format --output=none --set-exit-if-changed lib test integration_test

successor-flutter-analyze: successor-flutter-dependencies
	@cd clients/aonw_flutter && flutter analyze --no-pub --fatal-infos --fatal-warnings

successor-flutter-test: successor-flutter-analyze
	@cd clients/aonw_flutter && flutter test --no-pub

successor-flutter-check: successor-flutter-format-check successor-flutter-test successor-map-contract-test dependency-boundaries

successor-flutter-coverage-report: successor-flutter-dependencies
	@cd clients/aonw_flutter && flutter test --coverage --no-pub

map-stage-1-check: successor-flutter-dependencies godot-editor-check
	@mkdir -p "$(abspath $(MAP_RENDER_PROBE_DIR))"
	@tool/test_compare_map_render_probes.sh
	@cd clients/aonw_flutter && dart run test/tool/export_map_render_probe.dart \
		"$(MAP_RENDER_PROBE_SCENARIO)" \
		"$(FLUTTER_MAP_RENDER_PROBE)" \
		"$(FLUTTER_MAP_RENDER_DIAGNOSTICS)"
	@"$(GODOT_BIN)" --headless --log-file "$(GODOT_PROBE_LOG)" \
		--path "$(GODOT_PROJECT)" \
		--script res://tests/export_map_render_probe.gd -- \
		"$(MAP_RENDER_PROBE_SCENARIO)" \
		"$(GODOT_MAP_RENDER_PROBE)" \
		"$(GODOT_MAP_RENDER_DIAGNOSTICS)"
	@tool/check_godot_log.sh "$(GODOT_PROBE_LOG)" "Godot map render probe: OK"
	@dart tool/compare_map_render_probes.dart \
		"$(FLUTTER_MAP_RENDER_PROBE)" \
		"$(GODOT_MAP_RENDER_PROBE)" \
		"$(MAP_RENDER_PROBE_SCENARIO)" \
		"$(FLUTTER_MAP_RENDER_DIAGNOSTICS)" \
		"$(GODOT_MAP_RENDER_DIAGNOSTICS)"

stage-1-visual-evidence: successor-flutter-dependencies godot-editor-check
	@mkdir -p "$(STAGE_1_EVIDENCE_DIR)"
	@cd clients/aonw_flutter && flutter test --no-pub \
		--update-goldens \
		test/visual/stage_1_visual_evidence.dart \
		--dart-define=AONW_STAGE_1_EVIDENCE_DIR="$(STAGE_1_EVIDENCE_DIR)"
	@"$(GODOT_BIN)" --log-file "$(GODOT_VISUAL_EVIDENCE_LOG)" \
		--path "$(GODOT_PROJECT)" \
		--resolution 1280x720 \
		--script res://tests/export_stage_1_visual_evidence.gd -- \
		"$(STAGE_1_EVIDENCE_DIR)"
	@tool/check_godot_log.sh \
		"$(GODOT_VISUAL_EVIDENCE_LOG)" \
		"Godot stage 1 visual evidence: OK"

successor-flutter-device-test: successor-flutter-dependencies
	@cd clients/aonw_flutter && flutter test --no-pub integration_test/inspect_map_native_test.dart

successor-flutter-fm4-pilot: successor-flutter-dependencies
	@cd clients/aonw_flutter && flutter test --no-dds --no-pub integration_test/fm4_flame_gameplay_pilot_test.dart

successor-flutter-fm5-baseline: successor-flutter-dependencies
	@cd clients/aonw_flutter && flutter test --no-dds --no-pub integration_test/fm4_flame_gameplay_pilot_test.dart

successor-flutter-run: successor-flutter-dependencies
	@cd clients/aonw_flutter && flutter run --no-pub -d macos

rust-check: rust-format-check rust-clippy rust-test rust-doc rust-release-compile-smoke

rust-format-check:
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) fmt --all -- --check

rust-clippy:
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) clippy --locked --workspace --all-targets --all-features -- -D warnings

rust-test:
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked --workspace --all-features

rust-test-release:
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) test --locked --release --workspace --all-features

rust-doc:
	@cd "$(RUST_WORKSPACE)" && RUSTDOCFLAGS="-D warnings" $(RUST_CARGO) doc --locked --workspace --all-features --no-deps

rust-release-compile-smoke:
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) build --locked --release --all-features -p aonw_flutter -p aonw_godot

rust-benchmark:
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) bench --locked -p aonw_engine --bench movement
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) bench --locked -p aonw_local_runtime --bench runtime

rust-flutter-test: root-dependencies successor-flutter-dependencies
	@dart test packages/aonw_rust_client/test
	@cd clients/aonw_flutter && flutter test --no-pub test/features/map/infrastructure/native_large_map_smoke_test.dart

rust-godot-build:
	@cd "$(RUST_WORKSPACE)" && $(RUST_CARGO) build --locked -p aonw_godot

godot-terrain-compile:
	@tool/compile_godot_terrain.sh

godot-toolchain-check:
	@GODOT_BIN="$(GODOT_BIN)" tool/check_godot_toolchain.sh

terrain3d-check:
	@tool/check_terrain3d.sh

godot-native-config: terrain3d-check
	@mkdir -p "$(GODOT_PROJECT)/.godot"
	@printf '%s\n' 'res://aonw_engine.gdextension' 'res://addons/terrain_3d/terrain.gdextension' > "$(GODOT_PROJECT)/.godot/extension_list.cfg"

godot-check: godot-test

godot-editor-check: godot-toolchain-check terrain3d-check rust-godot-build godot-terrain-compile godot-native-config
	@"$(GODOT_BIN)" --headless --log-file "$(GODOT_EDITOR_LOG)" --editor --path "$(GODOT_PROJECT)" --quit
	@tool/check_godot_log.sh "$(GODOT_EDITOR_LOG)"

godot-editor: godot-toolchain-check terrain3d-check rust-godot-build godot-terrain-compile godot-native-config
	@"$(GODOT_BIN)" --editor --path "$(GODOT_PROJECT)"

godot-run: godot-toolchain-check terrain3d-check rust-godot-build godot-terrain-compile godot-native-config
	@"$(GODOT_BIN)" --path "$(GODOT_PROJECT)"

godot-test: godot-editor-check
	@"$(GODOT_BIN)" --headless --log-file "$(GODOT_CHECK_ONLY_LOG)" --path "$(GODOT_PROJECT)" --check-only --script res://tests/test_map_pipeline.gd
	@tool/check_godot_log.sh "$(GODOT_CHECK_ONLY_LOG)"
	@"$(GODOT_BIN)" --headless --log-file "$(GODOT_TEST_LOG)" --path "$(GODOT_PROJECT)" --script res://tests/test_map_pipeline.gd
	@tool/check_godot_log.sh "$(GODOT_TEST_LOG)" "map pipeline: OK"
	@"$(GODOT_BIN)" --headless --log-file "$(GODOT_RUNTIME_LOG)" --path "$(GODOT_PROJECT)" --quit-after 5
	@tool/check_godot_log.sh "$(GODOT_RUNTIME_LOG)"

godot-map-sync:
	@dart run tool/assets/compile/starter_map_bundle.dart compile

godot-map-bundle-check:
	@dart run tool/assets/compile/starter_map_bundle.dart check

dependencies: root-dependencies successor-flutter-dependencies core-dependencies client-dependencies server-dependencies

root-dependencies: toolchain-check
	@flutter pub get --enforce-lockfile

core-dependencies: toolchain-check
	@cd packages/aonw_core && dart pub get --enforce-lockfile

client-dependencies: toolchain-check
	@cd packages/aonw_server_client && dart pub get --enforce-lockfile

server-dependencies: toolchain-check
	@cd server && dart pub get --enforce-lockfile

ci: successor-engine-quality-check generated-code-check format-check analyze architecture-check mutation-check performance-check coverage-check client-test

format-check: dependencies
	@files=$$(git ls-files -- '*.dart' \
		':(exclude)server/lib/src/generated/**' \
		':(exclude)server/test/integration/test_tools/**' \
		':(exclude)packages/aonw_server_client/lib/src/protocol/**' | \
		while IFS= read -r file; do \
			if test -f "$$file"; then printf '%s\n' "$$file"; fi; \
		done); \
		test -n "$$files" || { echo "No tracked Dart files found."; exit 1; }; \
		dart format --output=none --set-exit-if-changed $$files

check: toolchain-check flutter-test core-test client-test server-test

analyze: flutter-analyze core-analyze client-analyze server-analyze

flutter-analyze: root-dependencies
	@flutter analyze --no-pub --fatal-infos --fatal-warnings

core-analyze: core-dependencies
	@cd packages/aonw_core && dart analyze --fatal-infos --fatal-warnings

client-analyze: client-dependencies
	@cd packages/aonw_server_client && dart analyze --fatal-infos --fatal-warnings

server-analyze: server-dependencies
	@cd server && dart analyze --fatal-infos --fatal-warnings

architecture: architecture-check

architecture-check: root-dependencies rust-engine-inventory-ast-check
	@dart run tool/check_architecture.dart check --ratchet-ref "$(ARCHITECTURE_RATCHET_REF)"
	@dart run tool/check_architecture_aggregates.dart check --ratchet-ref "$(ARCHITECTURE_RATCHET_REF)"

architecture-snapshot: root-dependencies
	@dart run tool/check_architecture.dart snapshot > "$(ARCHITECTURE_SNAPSHOT_PATH)"
	@echo "Wrote architecture baseline candidate to $(ARCHITECTURE_SNAPSHOT_PATH)"
	@dart run tool/check_architecture_aggregates.dart snapshot > "$(ARCHITECTURE_AGGREGATE_SNAPSHOT_PATH)"
	@echo "Wrote architecture aggregate baseline candidate to $(ARCHITECTURE_AGGREGATE_SNAPSHOT_PATH)"

mutation: mutation-check

mutation-check: root-dependencies core-dependencies server-dependencies
	@if [ "$$(uname -s 2>/dev/null || echo unknown)" = "Darwin" ]; then \
		exec caffeinate -i dart run tool/check_mutations.dart check --ratchet-ref "$(MUTATION_RATCHET_REF)"; \
	else \
		exec dart run tool/check_mutations.dart check --ratchet-ref "$(MUTATION_RATCHET_REF)"; \
	fi

mutation-snapshot: root-dependencies core-dependencies server-dependencies
	@if [ "$$(uname -s 2>/dev/null || echo unknown)" = "Darwin" ]; then \
		exec caffeinate -i dart run tool/check_mutations.dart snapshot > "$(MUTATION_SNAPSHOT_PATH)"; \
	else \
		exec dart run tool/check_mutations.dart snapshot > "$(MUTATION_SNAPSHOT_PATH)"; \
	fi
	@echo "Wrote mutation baseline candidate to $(MUTATION_SNAPSHOT_PATH)"

performance: performance-check

performance-check: performance-report
	@dart run tool/check_performance.dart check \
		--report "$(PERFORMANCE_REPORT_PATH)" \
		--baseline "$(PERFORMANCE_BASELINE)" \
		--policy "$(PERFORMANCE_POLICY)"

performance-report: root-dependencies
	@flutter test --no-pub --reporter=failures-only \
		--dart-define=AONW_RUN_PERFORMANCE=true \
		--dart-define=AONW_PERFORMANCE_REPORT="$(PERFORMANCE_REPORT_PATH)" \
		test/performance/performance_suite_test.dart
	@test -f "$(PERFORMANCE_REPORT_PATH)"
	@echo "Wrote performance report to $(PERFORMANCE_REPORT_PATH)"

performance-snapshot: performance-report
	@dart run tool/check_performance.dart snapshot \
		--report "$(PERFORMANCE_REPORT_PATH)" > "$(PERFORMANCE_SNAPSHOT_PATH)"
	@echo "Wrote performance baseline candidate to $(PERFORMANCE_SNAPSHOT_PATH)"

performance-frame-check: root-dependencies
	@test -n "$(PERFORMANCE_FRAME_DEVICE_ID)" || { echo "PERFORMANCE_FRAME_DEVICE_ID is required."; exit 1; }
	@dart run tool/check_frame_budget.dart \
		--report "$(PERFORMANCE_FRAME_REPORT_PATH)" \
		--device-id "$(PERFORMANCE_FRAME_DEVICE_ID)"

release-check:
	@$(MAKE) --no-print-directory ci
	@$(MAKE) --no-print-directory native-local-game-smoke
	@$(MAKE) --no-print-directory serverpod-config-check
	@tool/run_postgres_smoke.sh

flutter-test: flutter-analyze
	@flutter test --no-pub

core-test: core-analyze
	@cd packages/aonw_core && dart test

client-test: client-analyze
	@cd packages/aonw_server_client && dart test

server-test: server-analyze
	@cd server && dart test

coverage: coverage-check

coverage-directory:
	@mkdir -p coverage

coverage-reports: flutter-coverage-report core-coverage-report server-coverage-report

coverage-check: coverage-reports
	@dart run tool/check_coverage.dart check --base-ref "$(COVERAGE_BASE_REF)" --ratchet-ref "$(COVERAGE_RATCHET_REF)"

coverage-snapshot: coverage-reports
	@dart run tool/check_coverage.dart snapshot > "$(COVERAGE_SNAPSHOT_PATH)"
	@echo "Wrote coverage baseline candidate to $(COVERAGE_SNAPSHOT_PATH)"

flutter-coverage-report: root-dependencies coverage-directory
	@rm -rf "$(CURDIR)/build/test_cache"
	@flutter test --no-pub --concurrency=2 --coverage --coverage-package='^aonw$$' --coverage-path="$(CURDIR)/coverage/root.lcov.info" --reporter=failures-only

core-coverage-report: core-dependencies coverage-directory
	@cd packages/aonw_core && dart test --concurrency=1 --coverage-package='^aonw_core$$' --coverage-path="$(CURDIR)/coverage/core.lcov.info" --reporter=failures-only

server-coverage-report: server-dependencies coverage-directory
	@rm -rf "$(CURDIR)/server/.dart_tool/test"
	@cd server && dart test --concurrency=1 --coverage-package='^aonw_server$$' --coverage-path="$(CURDIR)/coverage/server.lcov.info" --reporter=failures-only

flutter-coverage: flutter-coverage-report
	@dart run tool/check_coverage.dart check --scope root --base-ref "$(COVERAGE_BASE_REF)" --ratchet-ref "$(COVERAGE_RATCHET_REF)"

core-coverage: core-coverage-report
	@dart run tool/check_coverage.dart check --scope core --base-ref "$(COVERAGE_BASE_REF)" --ratchet-ref "$(COVERAGE_RATCHET_REF)"

server-coverage: server-coverage-report
	@dart run tool/check_coverage.dart check --scope server --base-ref "$(COVERAGE_BASE_REF)" --ratchet-ref "$(COVERAGE_RATCHET_REF)"

reducer-parity-test:
	@flutter test test/game/domain/reducer/local_reducer_parity_fixture_test.dart
	@cd server && dart test test/multiplayer/server_reducer_parity_fixture_test.dart

critical-e2e-test: local-game-e2e-test serverpod-critical-e2e-test

local-game-e2e-test: root-dependencies
	@flutter test --no-pub test/game/local_game_persistence_flow_test.dart
	@$(MAKE) --no-print-directory native-local-game-smoke

native-local-game-smoke: root-dependencies
	@log="/tmp/aonw-native-local-smoke-$$$$.log"; \
		flutter run --no-pub -d macos -t tool/native_local_game_smoke.dart \
			2>&1 | tee "$$log"; \
		result=0; \
		grep -F "Native local-game smoke passed:" "$$log" >/dev/null \
			|| result=1; \
		rm -f "$$log"; \
		exit $$result

serverpod-critical-e2e-test: root-dependencies client-dependencies server-dependencies
	@AONW_SERVERPOD_CRITICAL_E2E_PORT="$(AONW_SERVERPOD_CRITICAL_E2E_PORT)" \
		tool/run_serverpod_critical_e2e.sh

server-integration-test:
	@cd server && \
		tests=$$(find test/integration -type f -name '*_smoke.dart' | sort); \
		test -n "$$tests" || { echo "No Serverpod integration smokes found."; exit 1; }; \
		test_database_password="$${AONW_TEST_DATABASE_PASSWORD:-$${SERVERPOD_TEST_DATABASE_PASSWORD:-aonw_dev}}"; \
		test -n "$$test_database_password" || { echo "PostgreSQL test password must not be empty."; exit 1; }; \
		test_database_port="$${AONW_TEST_DATABASE_PORT:-5432}"; \
		case "$$test_database_port" in \
			''|*[!0-9]*|??????*) echo "AONW_TEST_DATABASE_PORT must be an integer from 1 to 65535." >&2; exit 64 ;; \
		esac; \
		if [ "$$test_database_port" -lt 1 ] || [ "$$test_database_port" -gt 65535 ]; then \
			echo "AONW_TEST_DATABASE_PORT must be an integer from 1 to 65535." >&2; \
			exit 64; \
		fi; \
		env -i \
			PATH="$$PATH" \
			HOME="$${HOME:?HOME is required}" \
			TMPDIR="$${TMPDIR:-/tmp}" \
			SERVERPOD_DATABASE_PORT="$$test_database_port" \
			SERVERPOD_PASSWORD_database="$$test_database_password" \
			SERVERPOD_PASSWORD_emailSecretHashPepper="test-email-secret-hash-pepper" \
			SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey="test-jwt-hmac-sha512-private-key" \
			SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper="test-jwt-refresh-token-hash-pepper" \
			dart test $$tests -P integration --chain-stack-traces --concurrency=1

serverpod-runtime-smoke:
	@dart run tool/serverpod_multiplayer_smoke.dart --host "$(SERVERPOD_SMOKE_HOST)" --map "$(SERVERPOD_SMOKE_MAP)"

serverpod-seed-test-users:
	@dart run tool/serverpod_seed_test_users.dart --host "$(SERVERPOD_SEED_HOST)" --password "$(SERVERPOD_SEED_PASSWORD)" --email-domain "$(SERVERPOD_SEED_EMAIL_DOMAIN)"

local: local-web

local-start: local-seed

local-up:
	@test -f .env || { echo "Missing .env. Run: cp .env.example .env, then replace placeholder secrets."; exit 1; }
	@SERVERPOD_SERVER_ID=local \
		SERVERPOD_API_SERVER_PUBLIC_HOST="$(LOCAL_API_HOST)" \
		SERVERPOD_API_SERVER_PUBLIC_PORT="$(LOCAL_API_PORT)" \
		SERVERPOD_API_SERVER_PUBLIC_SCHEME=http \
		SERVERPOD_WEB_SERVER_PUBLIC_HOST="$(LOCAL_API_HOST)" \
		SERVERPOD_WEB_SERVER_PUBLIC_PORT="$(LOCAL_SERVER_WEB_PORT)" \
		SERVERPOD_WEB_SERVER_PUBLIC_SCHEME=http \
		AONW_SERVER_PUBLIC_PORT="$(LOCAL_API_PORT)" \
		AONW_INSIGHTS_PUBLIC_PORT="$(LOCAL_INSIGHTS_PORT)" \
		AONW_WEB_PUBLIC_PORT="$(LOCAL_SERVER_WEB_PORT)" \
		AONW_APP_VERSION="$(AONW_APP_VERSION)" \
		AONW_RELEASE_CHANNEL="$(AONW_RELEASE_CHANNEL)" \
		$(COMPOSE) $(COMPOSE_BASE_FILES) --profile dev up -d --build --remove-orphans
	@$(MAKE) --no-print-directory local-health

local-health:
	@$(MAKE) --no-print-directory health PROFILE=dev HEALTH_URL="$(LOCAL_HEALTH_URL)"

local-seed: local-up
	@$(MAKE) --no-print-directory serverpod-seed-test-users SERVERPOD_SEED_HOST="$(LOCAL_API_BASE_URL)/"

local-multiplayer-smoke: local-up
	@$(MAKE) --no-print-directory serverpod-runtime-smoke SERVERPOD_SMOKE_HOST="$(LOCAL_API_BASE_URL)/"

local-web: local-start
	@echo "Starting Flutter Web at http://$(LOCAL_WEB_HOST):$(LOCAL_WEB_PORT) with API=$(LOCAL_API_BASE_URL)"
	@flutter run -d "$(LOCAL_WEB_DEVICE)" \
		--web-hostname "$(LOCAL_WEB_HOST)" \
		--web-port "$(LOCAL_WEB_PORT)" \
		"--dart-define=AONW_API_BASE_URL=$(LOCAL_API_BASE_URL)"

local-down:
	@$(COMPOSE) $(COMPOSE_BASE_FILES) --profile dev down --remove-orphans

compose-check:
	@command -v docker >/dev/null || { echo "docker is required."; exit 1; }
	@command -v bash >/dev/null || { echo "bash is required."; exit 1; }
	@$(COMPOSE) version >/dev/null || { echo "docker compose is required."; exit 1; }
	@COMPOSE="$(COMPOSE)" tool/check_compose_run_modes.sh
	@echo "Checking server/compose.yml..."
	@cd server && \
			POSTGRES_PASSWORD="$${POSTGRES_PASSWORD:-compose-config-postgres-password}" \
			SERVERPOD_PASSWORD_redis="$${SERVERPOD_PASSWORD_redis:-compose-config-redis-password}" \
			$(COMPOSE) -f compose.yml config >/dev/null
	@echo "Docker Compose config OK."

docker-context-check:
	@command -v docker >/dev/null || { echo "docker is required."; exit 1; }
	@tool/check_docker_context.sh

infra-config-check: docker-context-check
	@command -v docker >/dev/null || { echo "docker is required."; exit 1; }
	@docker run --rm --entrypoint /usr/bin/caddy \
		-e AONW_API_HOST=api.example.test \
		-e AONW_HOMEPAGE_HOST=example.test \
		-e AONW_ENGINE_DOCS_HOST=engine.example.test \
		-e AONW_DEMO_HOST=demo.example.test \
		-e AONW_UPSTREAM=server:8080 \
		-e AONW_WEB_UPSTREAM=server:8082 \
		-v "$(CURDIR)/deploy/caddy/Caddyfile:/etc/caddy/Caddyfile:ro" \
		"$(CADDY_VALIDATE_IMAGE)" validate --config /etc/caddy/Caddyfile --adapter caddyfile
	@docker run --rm --entrypoint /usr/bin/caddy \
		-e AONW_WEB_UPSTREAM=host.docker.internal:8082 \
		-v "$(CURDIR)/deploy/caddy/Caddyfile.local:/etc/caddy/Caddyfile:ro" \
		"$(CADDY_VALIDATE_IMAGE)" validate --config /etc/caddy/Caddyfile --adapter caddyfile
	@docker run --rm --entrypoint /bin/promtool \
		-v "$(CURDIR)/deploy/prometheus:/etc/prometheus:ro" \
		"$(PROMTOOL_IMAGE)" check rules /etc/prometheus/aonw-alerts.yml
	@docker buildx build --check --file server/Dockerfile .
	@echo "Infrastructure config OK."

serverpod-config-check: compose-check infra-config-check

serverpod-ops-check: generated-code-check serverpod-config-check

build-web:
	@command -v flutter >/dev/null || { echo "flutter SDK is required for build-web."; exit 1; }
	@command -v rg >/dev/null || { echo "rg is required for build-web."; exit 1; }
	@test -n "$(WEB_API_BASE_URL)" || { echo "WEB_API_BASE_URL is required."; exit 1; }
	@echo "Building Flutter web (wasm + js fallback) with API=$(WEB_API_BASE_URL)..."
	@flutter build web --wasm --release --pwa-strategy=none --dart-define=AONW_API_BASE_URL=$(WEB_API_BASE_URL)
	@build_id="$$(date -u +%Y%m%d%H%M%S)"; \
	  printf '%s\n' "$$build_id" > build/web/.last_build_id; \
	  perl -0pi -e 's/"mainWasmPath":"main\.dart\.wasm"/"mainWasmPath":"main.dart.wasm?v='"$$build_id"'"/g; s/"jsSupportRuntimePath":"main\.dart\.mjs"/"jsSupportRuntimePath":"main.dart.mjs?v='"$$build_id"'"/g; s/"mainJsPath":"main\.dart\.js"/"mainJsPath":"main.dart.js?v='"$$build_id"'"/g' build/web/flutter_bootstrap.js; \
	  perl -0pi -e 's/src="flutter_bootstrap\.js(?:\?v=[^"]*)?"/src="flutter_bootstrap.js?v='"$$build_id"'"/g' build/web/index.html
	@rg -a -F "$(WEB_API_BASE_URL)" build/web >/dev/null
	@rg -F "https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js" build/web/index.html >/dev/null
	@echo "Verified web build API: $(WEB_API_BASE_URL)"
	@echo "Verified web Apple sign-in SDK."

# Compatibility wrapper for one-off deployments. The aggregate immutable
# release flow can build once and call deploy-web-files separately.
deploy-web:
	@$(MAKE) --no-print-directory build-web WEB_API_BASE_URL="$(WEB_API_BASE_URL)"
	@$(MAKE) --no-print-directory deploy-web-files

# Upload-only target. It must consume the already prepared build/web tree and
# never rebuild bytes between manifest verification and publication.
deploy-web-files:
	@command -v rsync >/dev/null || { echo "rsync is required for deploy-web."; exit 1; }
	@test -n "$(WEB_DEPLOY_SSH_KEY)" || { echo "WEB_DEPLOY_SSH_KEY is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_USER)" || { echo "WEB_DEPLOY_USER is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_HOST)" || { echo "WEB_DEPLOY_HOST is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_DEST)" || { echo "WEB_DEPLOY_DEST is required."; exit 1; }
	@test -f "$(WEB_DEPLOY_SSH_KEY)" || { echo "SSH key not found: $(WEB_DEPLOY_SSH_KEY)"; exit 1; }
	@echo "Uploading build/web/ -> $(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST):$(WEB_DEPLOY_DEST)/..."
	@ssh -i "$(WEB_DEPLOY_SSH_KEY)" $(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST) 'mkdir -p "$(WEB_DEPLOY_DEST)"'
	@rsync -avz --delete \
	  --exclude='Dockerfile*' \
	  -e "ssh -i $(WEB_DEPLOY_SSH_KEY)" \
	  build/web/ $(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST):$(WEB_DEPLOY_DEST)/
	@echo "deploy-web finished. Checking $(WEB_HEALTH_URL) ..."
	@$(MAKE) --no-print-directory health-web

build-homepage:
	@command -v rg >/dev/null || { echo "rg is required for build-homepage."; exit 1; }
	@test -f "$(HOMEPAGE_SOURCE_DIR)/index.html" || { echo "$(HOMEPAGE_SOURCE_DIR)/index.html not found"; exit 1; }
	@test -f "$(HOMEPAGE_SOURCE_DIR)/privacy-policy/index.html" || { echo "$(HOMEPAGE_SOURCE_DIR)/privacy-policy/index.html not found"; exit 1; }
	@test -f "$(HOMEPAGE_SOURCE_DIR)/architecture/index.html" || { echo "$(HOMEPAGE_SOURCE_DIR)/architecture/index.html not found"; exit 1; }
	@test -f "$(HOMEPAGE_SOURCE_DIR)/stats/index.html" || { echo "$(HOMEPAGE_SOURCE_DIR)/stats/index.html not found"; exit 1; }
	@test -f assets/logo.png || { echo "assets/logo.png not found"; exit 1; }
	@test -f assets/aonw-mobile.png || { echo "assets/aonw-mobile.png not found"; exit 1; }
	@test -f assets/fonts/AlbertSans-VariableFont_wght.ttf || { echo "assets/fonts/AlbertSans-VariableFont_wght.ttf not found"; exit 1; }
	@test -f assets/fonts/AlbertSans-OFL.txt || { echo "assets/fonts/AlbertSans-OFL.txt not found"; exit 1; }
	@test -f assets/fonts/Cinzel-VariableFont_wght.ttf || { echo "assets/fonts/Cinzel-VariableFont_wght.ttf not found"; exit 1; }
	@test -f assets/fonts/Lato-Light.ttf || { echo "assets/fonts/Lato-Light.ttf not found"; exit 1; }
	@test -f assets/fonts/Lato-Regular.ttf || { echo "assets/fonts/Lato-Regular.ttf not found"; exit 1; }
	@test -f assets/fonts/Lato-Bold.ttf || { echo "assets/fonts/Lato-Bold.ttf not found"; exit 1; }
	@test -f assets/main_menu/background.png || { echo "assets/main_menu/background.png not found"; exit 1; }
	@test -f assets/main_menu/background.jpg || { echo "assets/main_menu/background.jpg not found"; exit 1; }
	@test -f assets/homepage/platform-icons/android.svg || { echo "assets/homepage/platform-icons/android.svg not found"; exit 1; }
	@test -f assets/homepage/platform-icons/apple.svg || { echo "assets/homepage/platform-icons/apple.svg not found"; exit 1; }
	@test -f assets/homepage/platform-icons/contact.svg || { echo "assets/homepage/platform-icons/contact.svg not found"; exit 1; }
	@test -f assets/homepage/platform-icons/devlog.svg || { echo "assets/homepage/platform-icons/devlog.svg not found"; exit 1; }
	@test -f assets/homepage/platform-icons/github.svg || { echo "assets/homepage/platform-icons/github.svg not found"; exit 1; }
	@test -f assets/homepage/platform-icons/reddit.svg || { echo "assets/homepage/platform-icons/reddit.svg not found"; exit 1; }
	@test -f assets/homepage/platform-icons/steam.svg || { echo "assets/homepage/platform-icons/steam.svg not found"; exit 1; }
	@test -f assets/homepage/platform-icons/stats.svg || { echo "assets/homepage/platform-icons/stats.svg not found"; exit 1; }
	@test -f assets/homepage/platform-icons/web.svg || { echo "assets/homepage/platform-icons/web.svg not found"; exit 1; }
	@test -f web/favicon.png || { echo "web/favicon.png not found"; exit 1; }
	@test -f web/icons/Icon-192.png || { echo "web/icons/Icon-192.png not found"; exit 1; }
	@rm -rf "$(HOMEPAGE_BUILD_DIR)"
	@mkdir -p "$(HOMEPAGE_BUILD_DIR)/assets/main_menu" "$(HOMEPAGE_BUILD_DIR)/assets/fonts" "$(HOMEPAGE_BUILD_DIR)/assets/platform-icons"
	@cp "$(HOMEPAGE_SOURCE_DIR)/index.html" "$(HOMEPAGE_BUILD_DIR)/index.html"
	@cp "$(HOMEPAGE_SOURCE_DIR)/privacy-policy/index.html" "$(HOMEPAGE_BUILD_DIR)/privacy-policy"
	@cp "$(HOMEPAGE_SOURCE_DIR)/architecture/index.html" "$(HOMEPAGE_BUILD_DIR)/architecture"
	@cp "$(HOMEPAGE_SOURCE_DIR)/stats/index.html" "$(HOMEPAGE_BUILD_DIR)/stats"
	@cp web/favicon.png "$(HOMEPAGE_BUILD_DIR)/favicon.png"
	@cp web/icons/Icon-192.png "$(HOMEPAGE_BUILD_DIR)/apple-touch-icon.png"
	@cp assets/logo.png "$(HOMEPAGE_BUILD_DIR)/assets/logo.png"
	@cp assets/aonw-mobile.png "$(HOMEPAGE_BUILD_DIR)/assets/aonw-mobile.png"
	@cp assets/fonts/AlbertSans-VariableFont_wght.ttf "$(HOMEPAGE_BUILD_DIR)/assets/fonts/AlbertSans-VariableFont_wght.ttf"
	@cp assets/fonts/AlbertSans-OFL.txt "$(HOMEPAGE_BUILD_DIR)/assets/fonts/AlbertSans-OFL.txt"
	@cp assets/fonts/Cinzel-VariableFont_wght.ttf "$(HOMEPAGE_BUILD_DIR)/assets/fonts/Cinzel-VariableFont_wght.ttf"
	@cp assets/fonts/Lato-Light.ttf "$(HOMEPAGE_BUILD_DIR)/assets/fonts/Lato-Light.ttf"
	@cp assets/fonts/Lato-Regular.ttf "$(HOMEPAGE_BUILD_DIR)/assets/fonts/Lato-Regular.ttf"
	@cp assets/fonts/Lato-Bold.ttf "$(HOMEPAGE_BUILD_DIR)/assets/fonts/Lato-Bold.ttf"
	@cp assets/main_menu/background.png "$(HOMEPAGE_BUILD_DIR)/assets/main_menu/background.png"
	@cp assets/main_menu/background.jpg "$(HOMEPAGE_BUILD_DIR)/assets/main_menu/background.jpg"
	@cp assets/homepage/platform-icons/*.svg "$(HOMEPAGE_BUILD_DIR)/assets/platform-icons/"
	@rg -F 'data-page="architecture"' "$(HOMEPAGE_BUILD_DIR)/architecture" >/dev/null || { echo "Architecture page marker missing from $(HOMEPAGE_BUILD_DIR)/architecture"; exit 1; }
	@rg -F 'data-page="multiplayer-stats"' "$(HOMEPAGE_BUILD_DIR)/stats" >/dev/null || { echo "Stats page marker missing from $(HOMEPAGE_BUILD_DIR)/stats"; exit 1; }
	@echo "Static homepage staged in $(HOMEPAGE_BUILD_DIR)/"

# Compatibility wrapper for one-off deployments. Release orchestration uses
# build-homepage and deploy-homepage-files as separate stages.
deploy-homepage:
	@$(MAKE) --no-print-directory build-homepage
	@$(MAKE) --no-print-directory deploy-homepage-files

# Upload-only target for a previously staged homepage tree.
deploy-homepage-files:
	@command -v rsync >/dev/null || { echo "rsync is required for deploy-homepage."; exit 1; }
	@test -n "$(WEB_DEPLOY_SSH_KEY)" || { echo "WEB_DEPLOY_SSH_KEY is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_USER)" || { echo "WEB_DEPLOY_USER is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_HOST)" || { echo "WEB_DEPLOY_HOST is required."; exit 1; }
	@test -n "$(HOMEPAGE_DEPLOY_DEST)" || { echo "HOMEPAGE_DEPLOY_DEST is required."; exit 1; }
	@test -f "$(WEB_DEPLOY_SSH_KEY)" || { echo "SSH key not found: $(WEB_DEPLOY_SSH_KEY)"; exit 1; }
	@echo "Uploading $(HOMEPAGE_BUILD_DIR)/ -> $(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST):$(HOMEPAGE_DEPLOY_DEST)/..."
	@ssh -i "$(WEB_DEPLOY_SSH_KEY)" $(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST) 'mkdir -p "$(HOMEPAGE_DEPLOY_DEST)"'
	@rsync -avz --delete \
	  --exclude='download/***' \
	  -e "ssh -i $(WEB_DEPLOY_SSH_KEY)" \
	  "$(HOMEPAGE_BUILD_DIR)/" $(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST):$(HOMEPAGE_DEPLOY_DEST)/
	@echo "deploy-homepage finished. Checking homepage, architecture, and statistics routes..."
	@$(MAKE) --no-print-directory health-homepage
	@$(MAKE) --no-print-directory health-architecture
	@$(MAKE) --no-print-directory health-stats

# Generates rustdoc from the current local workspace, including uncommitted
# engine changes, then replaces rustdoc's root with the public presentation page.
build-engine-docs: rust-doc
	@$(MAKE) --no-print-directory stage-engine-docs

stage-engine-docs:
	@command -v perl >/dev/null || { echo "perl is required for build-engine-docs."; exit 1; }
	@test -f "$(ENGINE_DOCS_SOURCE_DIR)/index.html" || { echo "$(ENGINE_DOCS_SOURCE_DIR)/index.html not found"; exit 1; }
	@test -f "$(ENGINE_DOCS_SOURCE_DIR)/architecture/index.html" || { echo "$(ENGINE_DOCS_SOURCE_DIR)/architecture/index.html not found"; exit 1; }
	@test -f "$(RUST_WORKSPACE)/target/doc/aonw_engine/index.html" || { echo "aonw_engine rustdoc output not found"; exit 1; }
	@test -f assets/logo.png || { echo "assets/logo.png not found"; exit 1; }
	@test -f assets/main_menu/background.jpg || { echo "assets/main_menu/background.jpg not found"; exit 1; }
	@test -f assets/fonts/AlbertSans-VariableFont_wght.ttf || { echo "AoNW body font not found"; exit 1; }
	@test -f assets/fonts/AlbertSans-OFL.txt || { echo "AoNW body font license not found"; exit 1; }
	@test -f assets/fonts/Cinzel-VariableFont_wght.ttf || { echo "AoNW display font not found"; exit 1; }
	@test -f web/favicon.png || { echo "web/favicon.png not found"; exit 1; }
	@rm -rf "$(ENGINE_DOCS_BUILD_DIR)"
	@mkdir -p "$(ENGINE_DOCS_BUILD_DIR)/architecture" "$(ENGINE_DOCS_BUILD_DIR)/assets/fonts" "$(ENGINE_DOCS_BUILD_DIR)/assets/main_menu"
	@cp -R "$(RUST_WORKSPACE)/target/doc/." "$(ENGINE_DOCS_BUILD_DIR)/"
	@cp "$(ENGINE_DOCS_SOURCE_DIR)/index.html" "$(ENGINE_DOCS_BUILD_DIR)/index.html"
	@cp "$(ENGINE_DOCS_SOURCE_DIR)/architecture/index.html" "$(ENGINE_DOCS_BUILD_DIR)/architecture/index.html"
	@cp web/favicon.png "$(ENGINE_DOCS_BUILD_DIR)/favicon.png"
	@cp assets/logo.png "$(ENGINE_DOCS_BUILD_DIR)/assets/logo.png"
	@cp assets/main_menu/background.jpg "$(ENGINE_DOCS_BUILD_DIR)/assets/main_menu/background.jpg"
	@cp assets/fonts/AlbertSans-VariableFont_wght.ttf "$(ENGINE_DOCS_BUILD_DIR)/assets/fonts/AlbertSans-VariableFont_wght.ttf"
	@cp assets/fonts/AlbertSans-OFL.txt "$(ENGINE_DOCS_BUILD_DIR)/assets/fonts/AlbertSans-OFL.txt"
	@cp assets/fonts/Cinzel-VariableFont_wght.ttf "$(ENGINE_DOCS_BUILD_DIR)/assets/fonts/Cinzel-VariableFont_wght.ttf"
	@perl -0pi -e 's#\.\./\.\./assets/#assets/#g; s#\.\./\.\./web/favicon\.png#favicon.png#g' \
	  "$(ENGINE_DOCS_BUILD_DIR)/index.html"
	@rg -F 'data-page="engine-docs-home"' "$(ENGINE_DOCS_BUILD_DIR)/index.html" >/dev/null || { echo "Engine presentation page marker missing"; exit 1; }
	@rg -F 'data-page="engine-architecture"' "$(ENGINE_DOCS_BUILD_DIR)/architecture/index.html" >/dev/null || { echo "Engine architecture atlas marker missing"; exit 1; }
	@rg -F 'assets/main_menu/background.jpg' "$(ENGINE_DOCS_BUILD_DIR)/index.html" >/dev/null || { echo "Engine presentation background missing"; exit 1; }
	@rg -F 'data-current-crate="aonw_engine"' "$(ENGINE_DOCS_BUILD_DIR)/aonw_engine/index.html" >/dev/null || { echo "aonw_engine rustdoc output is invalid"; exit 1; }
	@echo "Current local Rust documentation staged in $(ENGINE_DOCS_BUILD_DIR)/"

deploy-engine-docs:
	@$(MAKE) --no-print-directory build-engine-docs
	@$(MAKE) --no-print-directory deploy-engine-docs-files

# Upload-only target for a previously staged engine documentation tree.
deploy-engine-docs-files:
	@command -v rsync >/dev/null || { echo "rsync is required for deploy-engine-docs."; exit 1; }
	@test -n "$(WEB_DEPLOY_SSH_KEY)" || { echo "WEB_DEPLOY_SSH_KEY is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_USER)" || { echo "WEB_DEPLOY_USER is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_HOST)" || { echo "WEB_DEPLOY_HOST is required."; exit 1; }
	@test -n "$(ENGINE_DOCS_DEPLOY_DEST)" || { echo "ENGINE_DOCS_DEPLOY_DEST is required."; exit 1; }
	@test -f "$(WEB_DEPLOY_SSH_KEY)" || { echo "SSH key not found: $(WEB_DEPLOY_SSH_KEY)"; exit 1; }
	@test -f "$(ENGINE_DOCS_BUILD_DIR)/index.html" || { echo "Run make build-engine-docs first."; exit 1; }
	@test -f "$(ENGINE_DOCS_BUILD_DIR)/architecture/index.html" || { echo "Staged engine architecture atlas not found."; exit 1; }
	@test -f "$(ENGINE_DOCS_BUILD_DIR)/aonw_engine/index.html" || { echo "Staged aonw_engine rustdoc output not found."; exit 1; }
	@echo "Uploading $(ENGINE_DOCS_BUILD_DIR)/ -> $(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST):$(ENGINE_DOCS_DEPLOY_DEST)/..."
	@ssh -i "$(WEB_DEPLOY_SSH_KEY)" "$(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST)" 'mkdir -p "$(ENGINE_DOCS_DEPLOY_DEST)"'
	@rsync -avz --delete-delay --delay-updates \
	  -e "ssh -i $(WEB_DEPLOY_SSH_KEY)" \
	  "$(ENGINE_DOCS_BUILD_DIR)/" "$(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST):$(ENGINE_DOCS_DEPLOY_DEST)/"
	@echo "deploy-engine-docs finished. Checking $(ENGINE_DOCS_HEALTH_URL) ..."
	@$(MAKE) --no-print-directory health-engine-docs

download-artifacts: itch-prepare download-package
	@echo "download artifacts ready."

download-package:
	@command -v ditto >/dev/null || { echo "ditto is required for download-package."; exit 1; }
	@command -v rg >/dev/null || { echo "rg is required for download-package."; exit 1; }
	@command -v zip >/dev/null || { echo "zip is required for download-package."; exit 1; }
	@command -v unzip >/dev/null || { echo "unzip is required for download-package."; exit 1; }
	@test -d "$(ITCH_MACOS_DIR)" || { echo "Missing itch macOS folder: $(ITCH_MACOS_DIR). Run make itch-prepare first."; exit 1; }
	@test -d "$(ITCH_WINDOWS_DIR)" || { echo "Missing itch Windows folder: $(ITCH_WINDOWS_DIR). Run make itch-prepare first."; exit 1; }
	@if [ "$(DOWNLOAD_INCLUDE_LINUX)" = "1" ]; then test -d "$(ITCH_LINUX_DIR)" || { echo "Missing itch Linux folder: $(ITCH_LINUX_DIR). Run make itch-prepare ITCH_INCLUDE_LINUX=1 first."; exit 1; }; fi
	@test -f "$(ITCH_ANDROID_APK)" || { echo "Missing Android APK: $(ITCH_ANDROID_APK). Run make android-build-itch first."; exit 1; }
	@rm -rf "$(DOWNLOAD_BUILD_DIR)"
	@mkdir -p "$(DOWNLOAD_BUILD_DIR)/macos" "$(DOWNLOAD_BUILD_DIR)/windows"
	@if [ "$(DOWNLOAD_INCLUDE_LINUX)" = "1" ]; then mkdir -p "$(DOWNLOAD_BUILD_DIR)/linux"; fi
	@ditto "$(ITCH_MACOS_DIR)" "$(DOWNLOAD_BUILD_DIR)/macos"
	@ditto "$(ITCH_WINDOWS_DIR)" "$(DOWNLOAD_BUILD_DIR)/windows"
	@if [ "$(DOWNLOAD_INCLUDE_LINUX)" = "1" ]; then ditto "$(ITCH_LINUX_DIR)" "$(DOWNLOAD_BUILD_DIR)/linux"; fi
	@rm -f "$(DOWNLOAD_BUILD_DIR)/macos/.itch.toml" "$(DOWNLOAD_BUILD_DIR)/windows/.itch.toml" "$(DOWNLOAD_BUILD_DIR)/linux/.itch.toml"
	@test -d "$(DOWNLOAD_BUILD_DIR)/macos/$(STEAM_MACOS_APP_NAME)" || { echo "Download macOS folder must contain $(STEAM_MACOS_APP_NAME)."; exit 1; }
	@test -f "$(DOWNLOAD_BUILD_DIR)/windows/aonw.exe" || { echo "Download Windows folder must contain aonw.exe."; exit 1; }
	@if [ "$(DOWNLOAD_INCLUDE_LINUX)" = "1" ]; then test -f "$(DOWNLOAD_BUILD_DIR)/linux/aonw" || { echo "Download Linux folder must contain aonw."; exit 1; }; fi
	@if find "$(DOWNLOAD_BUILD_DIR)" -name '.itch.toml' -print -quit | rg . >/dev/null; then \
		echo "Public download packages should not include itch manifests."; \
		exit 1; \
	fi
	@if find "$(DOWNLOAD_BUILD_DIR)" -iname '*steam*' \
		! -path "$(DOWNLOAD_BUILD_DIR)/linux/STEAM_RUNTIME_MANIFEST.txt" \
		! -path "$(DOWNLOAD_BUILD_DIR)/linux/licenses/steamrt-container-host-compat.copyright" \
		-print -quit | rg . >/dev/null; then \
		echo "Public download packages contain steam-named paths."; \
		exit 1; \
	fi
	@ditto -c -k --keepParent --norsrc --noextattr --noqtn --noacl \
		"$(DOWNLOAD_BUILD_DIR)/macos/$(STEAM_MACOS_APP_NAME)" "$(DOWNLOAD_MACOS_ZIP)"
	@zip_path="$$(pwd)/$(DOWNLOAD_WINDOWS_ZIP)"; \
		cd "$(DOWNLOAD_BUILD_DIR)/windows" && zip -qry "$$zip_path" .
	@if [ "$(DOWNLOAD_INCLUDE_LINUX)" = "1" ]; then \
		zip_path="$$(pwd)/$(DOWNLOAD_LINUX_ZIP)"; \
		cd "$(DOWNLOAD_BUILD_DIR)/linux" && zip -qry "$$zip_path" .; \
	fi
	@cp "$(ITCH_ANDROID_APK)" "$(DOWNLOAD_ANDROID_APK)"
	@unzip -tq "$(DOWNLOAD_MACOS_ZIP)" >/dev/null
	@if unzip -Z1 "$(DOWNLOAD_MACOS_ZIP)" | rg '(^|/)(\._|__MACOSX/)' >/dev/null; then \
		echo "Public macOS download must not contain AppleDouble or __MACOSX entries."; \
		exit 1; \
	fi
	@tmp_dir=$$(mktemp -d); \
	trap 'rm -rf "$$tmp_dir"' EXIT; \
	ditto -x -k "$(DOWNLOAD_MACOS_ZIP)" "$$tmp_dir"; \
	codesign --verify --deep --strict --verbose=2 "$$tmp_dir/$(STEAM_MACOS_APP_NAME)"; \
	spctl --assess --type execute --verbose=2 "$$tmp_dir/$(STEAM_MACOS_APP_NAME)"
	@unzip -tq "$(DOWNLOAD_WINDOWS_ZIP)" >/dev/null
	@if [ "$(DOWNLOAD_INCLUDE_LINUX)" = "1" ]; then unzip -tq "$(DOWNLOAD_LINUX_ZIP)" >/dev/null; fi
	@unzip -tq "$(DOWNLOAD_ANDROID_APK)" >/dev/null
	@rm -rf "$(DOWNLOAD_BUILD_DIR)/macos" "$(DOWNLOAD_BUILD_DIR)/windows" "$(DOWNLOAD_BUILD_DIR)/linux"
	@echo "Public download artifacts ready:"
	@files="$(DOWNLOAD_MACOS_ZIP) $(DOWNLOAD_WINDOWS_ZIP) $(DOWNLOAD_ANDROID_APK)"; \
	if [ "$(DOWNLOAD_INCLUDE_LINUX)" = "1" ]; then files="$$files $(DOWNLOAD_LINUX_ZIP)"; fi; \
	ls -lh $$files

deploy-downloads: download-artifacts deploy-download-files
	@echo "deploy-downloads finished."

deploy-download-files:
	@command -v rsync >/dev/null || { echo "rsync is required for deploy-download-files."; exit 1; }
	@test -n "$(WEB_DEPLOY_SSH_KEY)" || { echo "WEB_DEPLOY_SSH_KEY is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_USER)" || { echo "WEB_DEPLOY_USER is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_HOST)" || { echo "WEB_DEPLOY_HOST is required."; exit 1; }
	@test -n "$(DOWNLOAD_DEPLOY_DEST)" || { echo "DOWNLOAD_DEPLOY_DEST is required."; exit 1; }
	@test -f "$(WEB_DEPLOY_SSH_KEY)" || { echo "SSH key not found: $(WEB_DEPLOY_SSH_KEY)"; exit 1; }
	@test -f "$(DOWNLOAD_MACOS_ZIP)" || { echo "Missing public macOS download: $(DOWNLOAD_MACOS_ZIP). Run make download-package first."; exit 1; }
	@test -f "$(DOWNLOAD_WINDOWS_ZIP)" || { echo "Missing public Windows download: $(DOWNLOAD_WINDOWS_ZIP). Run make download-package first."; exit 1; }
	@test -f "$(DOWNLOAD_ANDROID_APK)" || { echo "Missing public Android download: $(DOWNLOAD_ANDROID_APK). Run make download-package first."; exit 1; }
	@if [ "$(DOWNLOAD_INCLUDE_LINUX)" = "1" ]; then test -f "$(DOWNLOAD_LINUX_ZIP)" || { echo "Missing public Linux download: $(DOWNLOAD_LINUX_ZIP). Run make download-package DOWNLOAD_INCLUDE_LINUX=1 first."; exit 1; }; fi
	@echo "Uploading $(DOWNLOAD_BUILD_DIR)/ -> $(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST):$(DOWNLOAD_DEPLOY_DEST)/..."
	@ssh -i "$(WEB_DEPLOY_SSH_KEY)" $(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST) 'mkdir -p "$(DOWNLOAD_DEPLOY_DEST)"'
	@rsync -avz --delete \
	  -e "ssh -i $(WEB_DEPLOY_SSH_KEY)" \
	  "$(DOWNLOAD_BUILD_DIR)/" $(WEB_DEPLOY_USER)@$(WEB_DEPLOY_HOST):$(DOWNLOAD_DEPLOY_DEST)/
	@$(MAKE) --no-print-directory health-downloads

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
	@set -e; \
	mode="$(DEPLOY_ALL_IOS_MODE)"; \
	case "$$mode" in \
		off) echo "Skipping iOS archive because DEPLOY_ALL_IOS_MODE=off." ;; \
		best-effort) \
			if [ "$$(uname -s)" != "Darwin" ]; then \
				echo "Skipping iOS archive: Xcode archives are only available on macOS."; \
			elif ! command -v xcodebuild >/dev/null; then \
				echo "Skipping iOS archive: xcodebuild is not available."; \
			elif ! command -v flutter >/dev/null; then \
				echo "Skipping iOS archive: flutter SDK is not available."; \
			elif [ ! -d "$(IOS_ARCHIVE_WORKSPACE)" ]; then \
				echo "Skipping iOS archive: $(IOS_ARCHIVE_WORKSPACE) not found."; \
			else \
				$(MAKE) --no-print-directory archive-ios; \
			fi ;; \
		required) $(MAKE) --no-print-directory archive-ios ;; \
		*) echo "Invalid DEPLOY_ALL_IOS_MODE=$$mode. Use off, best-effort, or required."; exit 1 ;; \
	esac

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

android-build-itch: android-preflight
	@echo "Building universal Android APK for itch.io with API=$(ANDROID_API_BASE_URL)..."
	@JAVA_HOME="$(ANDROID_JAVA_HOME)" flutter pub get
	@JAVA_HOME="$(ANDROID_JAVA_HOME)" flutter test "--dart-define=AONW_API_BASE_URL=$(ANDROID_API_BASE_URL)" test/game/repository_providers_test.dart
	@JAVA_HOME="$(ANDROID_JAVA_HOME)" flutter build apk --release "--dart-define=AONW_API_BASE_URL=$(ANDROID_API_BASE_URL)"
	@test -f "$(ANDROID_RELEASE_APK_DIR)/app-release.apk" || { echo "Expected release APK not found: $(ANDROID_RELEASE_APK_DIR)/app-release.apk"; exit 1; }
	@unzip -p "$(ANDROID_RELEASE_APK_DIR)/app-release.apk" 'lib/*/libapp.so' | strings | rg -F "$(ANDROID_API_BASE_URL)" >/dev/null
	@mkdir -p "$(ITCH_DIST_DIR)"
	@cp "$(ANDROID_RELEASE_APK_DIR)/app-release.apk" "$(ITCH_ANDROID_APK)"
	@unzip -tq "$(ITCH_ANDROID_APK)" >/dev/null
	@echo "Verified itch Android APK API: $(ANDROID_API_BASE_URL)"
	@echo "itch Android APK ready: $(ITCH_ANDROID_APK)"

android-release: android-build-aab
	@echo "Upload this file in Play Console: $(ANDROID_RELEASE_BUNDLE)"
	@echo "Or upload with Play API: make android-deploy"

android-upload-aab: android-play-preflight
	@test -f "$(ANDROID_RELEASE_BUNDLE)" || { echo "Expected bundle not found: $(ANDROID_RELEASE_BUNDLE). Run make android-build-aab first."; exit 1; }
	@unzip -p "$(ANDROID_RELEASE_BUNDLE)" 'base/lib/*/libapp.so' | strings | rg -F "$(ANDROID_API_BASE_URL)" >/dev/null
	@echo "Uploading $(ANDROID_RELEASE_BUNDLE) to Google Play track $(ANDROID_PLAY_TRACK)..."
	@set -e; \
	case "$(ANDROID_PLAY_VALIDATE_ONLY)" in 0|1) ;; *) echo "ANDROID_PLAY_VALIDATE_ONLY must be 0 or 1."; exit 1 ;; esac; \
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
	@if [ "$(ANDROID_PLAY_VALIDATE_ONLY)" = "1" ]; then \
		echo "Google Play validation finished; no release was published: package=$(ANDROID_PACKAGE_NAME), track=$(ANDROID_PLAY_TRACK)"; \
	else \
		echo "Google Play upload finished: package=$(ANDROID_PACKAGE_NAME), track=$(ANDROID_PLAY_TRACK)"; \
	fi

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
	@if [ "$(STEAM_INCLUDE_LINUX)" = "1" ]; then \
		$(MAKE) --no-print-directory steam-linux; \
	fi
	@test -f "$(STEAM_MACOS_ZIP)" || { echo "Missing Steam macOS ZIP: $(STEAM_MACOS_ZIP)"; exit 1; }
	@test -f "$(STEAM_WINDOWS_ZIP)" || { echo "Missing Steam Windows ZIP: $(STEAM_WINDOWS_ZIP)"; exit 1; }
	@if [ "$(STEAM_INCLUDE_LINUX)" = "1" ]; then \
		test -f "$(STEAM_LINUX_ZIP)" || { echo "Missing Steam Linux ZIP: $(STEAM_LINUX_ZIP)"; exit 1; }; \
	fi
	@echo "Steam ZIPs ready:"
	@files="$(STEAM_MACOS_ZIP) $(STEAM_WINDOWS_ZIP)"; \
	if [ "$(STEAM_INCLUDE_LINUX)" = "1" ]; then files="$$files $(STEAM_LINUX_ZIP)"; fi; \
	ls -lh $$files

steam-release-from-dist: steam-macos steam-prepare-from-dist steam-upload

macos-distribution-preflight:
	@test "$$(uname -s)" = "Darwin" || { echo "macOS distribution requires a macOS host."; exit 1; }
	@for command in codesign security spctl xcodebuild xcrun ditto plutil rg strings; do \
		command -v "$$command" >/dev/null || { echo "$$command is required for macOS distribution."; exit 1; }; \
	done
	@test -f "$(MACOS_EXPORT_OPTIONS)" || { echo "Developer ID export options not found: $(MACOS_EXPORT_OPTIONS)"; exit 1; }
	@test -f "$(MACOS_DEVELOPER_ID_ENTITLEMENTS)" || { echo "Developer ID entitlements not found: $(MACOS_DEVELOPER_ID_ENTITLEMENTS)"; exit 1; }
	@if rg -F 'com.apple.developer.applesignin' "$(MACOS_DEVELOPER_ID_ENTITLEMENTS)" >/dev/null; then \
		echo "Developer ID entitlements must not request Sign in with Apple."; \
		exit 1; \
	fi
	@case "$(STEAM_MACOS_ARCHIVE)" in \
		build/macos/*.xcarchive) ;; \
		*) echo "STEAM_MACOS_ARCHIVE must be a .xcarchive below build/macos."; exit 1 ;; \
	esac
	@case "$(STEAM_MACOS_EXPORT_DIR)" in \
		build/macos/?*) ;; \
		*) echo "STEAM_MACOS_EXPORT_DIR must be below build/macos."; exit 1 ;; \
	esac
	@case "$(STEAM_MACOS_ARCHIVE) $(STEAM_MACOS_EXPORT_DIR)" in \
		*..*) echo "macOS archive and export paths must not contain '..'."; exit 1 ;; \
	esac
	@test -n "$(MACOS_DEVELOPER_IDENTITY)" || { echo "MACOS_DEVELOPER_IDENTITY is required."; exit 1; }
	@test -n "$(MACOS_DEVELOPMENT_TEAM)" || { echo "MACOS_DEVELOPMENT_TEAM is required."; exit 1; }
	@test -n "$(MACOS_NOTARY_PROFILE)" || { echo "MACOS_NOTARY_PROFILE is required."; exit 1; }
	@security find-identity -v -p codesigning \
		| rg -F '"$(MACOS_DEVELOPER_IDENTITY)"' >/dev/null \
		|| { echo "Developer ID identity with private key not found: $(MACOS_DEVELOPER_IDENTITY)"; exit 1; }
	@xcrun notarytool history --keychain-profile "$(MACOS_NOTARY_PROFILE)" >/dev/null 2>&1 \
		|| { echo "Invalid notarytool Keychain profile: $(MACOS_NOTARY_PROFILE)"; \
			echo "Create it with: xcrun notarytool store-credentials $(MACOS_NOTARY_PROFILE)"; \
			exit 1; }
	@echo "macOS distribution preflight OK: team=$(MACOS_DEVELOPMENT_TEAM), profile=$(MACOS_NOTARY_PROFILE)"

steam-macos: macos-distribution-preflight
	@command -v flutter >/dev/null || { echo "flutter SDK is required for steam-macos."; exit 1; }
	@command -v ditto >/dev/null || { echo "ditto is required for steam-macos."; exit 1; }
	@command -v unzip >/dev/null || { echo "unzip is required for steam-macos."; exit 1; }
	@test "$$(uname -s)" = "Darwin" || { echo "steam-macos requires a macOS host."; exit 1; }
	@echo "Building macOS Steam release with API=$(STEAM_API_BASE_URL)..."
	@set -e; \
	build_name=$$(sed -n 's/^version:[[:space:]]*\([^+]*\)+.*/\1/p' "$(PUBSPEC)" | head -n 1); \
	build_number=$$(sed -n 's/^version:.*+\([0-9][0-9]*\).*$$/\1/p' "$(PUBSPEC)" | head -n 1); \
	test -n "$$build_name" || { echo "Could not parse version name from $(PUBSPEC)"; exit 1; }; \
	test -n "$$build_number" || { echo "Could not parse build number from $(PUBSPEC)"; exit 1; }; \
	api_define=$$(printf 'AONW_API_BASE_URL=%s' "$(STEAM_API_BASE_URL)" | base64 | tr -d '\n'); \
	flutter pub get; \
	rm -rf "$(STEAM_MACOS_ARCHIVE)" "$(STEAM_MACOS_EXPORT_DIR)"; \
	xcodebuild -quiet archive \
	  -workspace macos/Runner.xcworkspace \
	  -scheme Runner \
	  -configuration Release \
	  -destination 'generic/platform=macOS' \
	  -archivePath "$(STEAM_MACOS_ARCHIVE)" \
	  -allowProvisioningUpdates \
	  DEVELOPMENT_TEAM="$(MACOS_DEVELOPMENT_TEAM)" \
	  CODE_SIGN_ENTITLEMENTS="$(CURDIR)/$(MACOS_DEVELOPER_ID_ENTITLEMENTS)" \
	  FLUTTER_BUILD_NAME="$$build_name" \
	  FLUTTER_BUILD_NUMBER="$$build_number" \
	  DART_DEFINES="$$api_define"; \
	xcodebuild -exportArchive \
	  -archivePath "$(STEAM_MACOS_ARCHIVE)" \
	  -exportPath "$(STEAM_MACOS_EXPORT_DIR)" \
	  -exportOptionsPlist "$(MACOS_EXPORT_OPTIONS)" \
	  -allowProvisioningUpdates
	@test -d "$(STEAM_MACOS_APP)" || { echo "Expected macOS app not found: $(STEAM_MACOS_APP)"; exit 1; }
	@app_binary=$$(find "$(STEAM_MACOS_APP)/Contents/Frameworks/App.framework" -type f -name App -print -quit); \
	test -n "$$app_binary" || { echo "Expected Flutter App.framework binary not found in $(STEAM_MACOS_APP)"; exit 1; }; \
	strings "$$app_binary" | rg -F "$(STEAM_API_BASE_URL)" >/dev/null
	@echo "Verified Steam macOS API: $(STEAM_API_BASE_URL)"
	@set -e; \
	submission_dir=$$(mktemp -d "$${TMPDIR:-/tmp}/aonw-notary.XXXXXX"); \
	verification_dir=$$(mktemp -d "$${TMPDIR:-/tmp}/aonw-macos-verify.XXXXXX"); \
	trap 'rm -rf "$$submission_dir" "$$verification_dir"' EXIT HUP INT TERM; \
	submission_zip="$$submission_dir/aonw-macos-notary.zip"; \
	codesign --verify --deep --strict --verbose=2 "$(STEAM_MACOS_APP)"; \
	signature=$$(codesign -d --verbose=4 "$(STEAM_MACOS_APP)" 2>&1); \
	printf '%s\n' "$$signature" | rg '^CodeDirectory .* flags=.*runtime' >/dev/null \
		|| { echo "Exported macOS app is missing the hardened runtime signature flag."; exit 1; }; \
	printf '%s\n' "$$signature" | rg -F 'Authority=$(MACOS_DEVELOPER_IDENTITY)' >/dev/null \
		|| { echo "Exported macOS app was signed by an unexpected identity."; exit 1; }; \
	printf '%s\n' "$$signature" | rg -F 'TeamIdentifier=$(MACOS_DEVELOPMENT_TEAM)' >/dev/null \
		|| { echo "Exported macOS app has an unexpected team identifier."; exit 1; }; \
	printf '%s\n' "$$signature" | rg '^Timestamp=.+$$' >/dev/null \
		|| { echo "Exported macOS app signature is missing a trusted timestamp."; exit 1; }; \
	entitlements_file="$$submission_dir/aonw-entitlements.plist"; \
	codesign -d --xml --entitlements "$$entitlements_file" "$(STEAM_MACOS_APP)" >/dev/null 2>&1; \
	test "$$(plutil -extract 'com\.apple\.security\.app-sandbox' raw -o - "$$entitlements_file")" = true \
		|| { echo "Exported macOS app is missing the sandbox entitlement."; exit 1; }; \
	test "$$(plutil -extract 'com\.apple\.security\.network\.client' raw -o - "$$entitlements_file")" = true \
		|| { echo "Exported macOS app is missing the network client entitlement."; exit 1; }; \
	test "$$(plutil -extract keychain-access-groups.0 raw -o - "$$entitlements_file")" = "$(MACOS_DEVELOPMENT_TEAM).com.google.GIDSignIn" \
		|| { echo "Exported macOS app has an unexpected Google Keychain access group."; exit 1; }; \
	if plutil -extract 'com\.apple\.security\.get-task-allow' raw -o - "$$entitlements_file" >/dev/null 2>&1; then \
		echo "Developer ID app must not carry get-task-allow."; \
		exit 1; \
	fi; \
	ditto -c -k --keepParent --norsrc --noextattr --noqtn --noacl "$(STEAM_MACOS_APP)" "$$submission_zip"; \
	xcrun notarytool submit "$$submission_zip" --wait \
		--keychain-profile "$(MACOS_NOTARY_PROFILE)"; \
	xcrun stapler staple "$(STEAM_MACOS_APP)"; \
	xcrun stapler validate "$(STEAM_MACOS_APP)"; \
	spctl --assess --type execute --verbose=2 "$(STEAM_MACOS_APP)"; \
	mkdir -p "$(STEAM_DIST_DIR)"; \
	rm -f "$(STEAM_MACOS_ZIP)"; \
	ditto -c -k --keepParent --norsrc --noextattr --noqtn --noacl "$(STEAM_MACOS_APP)" "$(STEAM_MACOS_ZIP)"; \
	unzip -tq "$(STEAM_MACOS_ZIP)" >/dev/null; \
	if unzip -Z1 "$(STEAM_MACOS_ZIP)" | rg '(^|/)(\._|__MACOSX/)' >/dev/null; then \
		echo "Steam macOS ZIP must not contain AppleDouble or __MACOSX entries."; \
		exit 1; \
	fi; \
	ditto -x -k "$(STEAM_MACOS_ZIP)" "$$verification_dir"; \
	codesign --verify --deep --strict --verbose=2 "$$verification_dir/$(STEAM_MACOS_APP_NAME)"; \
	spctl --assess --type execute --verbose=2 "$$verification_dir/$(STEAM_MACOS_APP_NAME)"
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
	worktree_status=$$(git status --porcelain --untracked-files=normal); \
	build_name=$$(sed -n 's/^version:[[:space:]]*\([^+]*\)+.*/\1/p' "$(PUBSPEC)" | head -n 1); \
	build_number=$$(sed -n 's/^version:.*+\([0-9][0-9]*\).*$$/\1/p' "$(PUBSPEC)" | head -n 1); \
	test -n "$$branch" || { echo "Could not detect current git branch."; exit 1; }; \
	test -z "$$worktree_status" || { echo "Working tree must be clean before dispatching a Windows Steam build:"; printf '%s\n' "$$worktree_status"; exit 1; }; \
	test -n "$$build_name" || { echo "Could not parse version name from $(PUBSPEC)."; exit 1; }; \
	test -n "$$build_number" || { echo "Could not parse build number from $(PUBSPEC)."; exit 1; }; \
	git fetch origin "$$branch" >/dev/null; \
	remote_sha=$$(git rev-parse "origin/$$branch"); \
	test "$$local_sha" = "$$remote_sha" || { echo "Local HEAD is not pushed to origin/$$branch. Push first, then run make steam again."; exit 1; }; \
	dispatch_token="$${local_sha}-$$(date -u +%Y%m%dT%H%M%SZ)-$$$$"; \
	echo "Dispatching $(STEAM_WINDOWS_WORKFLOW) on $$branch for $$build_name+$$build_number..."; \
	gh workflow run "$(STEAM_WINDOWS_WORKFLOW)" --ref "$$branch" -f build_name="$$build_name" -f build_number="$$build_number" -f source_sha="$$local_sha" -f dispatch_token="$$dispatch_token"; \
	echo "Waiting for GitHub Actions run to appear..."; \
	run_id=""; \
	i=1; \
	while [ "$$i" -le "$(STEAM_GITHUB_RUN_LOOKUP_ATTEMPTS)" ]; do \
		run_id=$$(gh run list --workflow "$(STEAM_WINDOWS_WORKFLOW)" --branch "$$branch" --event workflow_dispatch --json databaseId,displayTitle,headSha --limit 20 --jq ".[] | select(.headSha == \"$$local_sha\" and (.displayTitle | contains(\"[$$dispatch_token]\"))) | .databaseId" | head -n 1); \
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

steam-runtime-contract:
	@command -v docker >/dev/null || { echo "docker is required for steam-runtime-contract."; exit 1; }
	@mkdir -p "$(dir $(STEAMRT4_PLATFORM_SONAMES))"
	@docker pull "$(STEAMRT4_PLATFORM_IMAGE)"
	@docker run --rm "$(STEAMRT4_PLATFORM_IMAGE)" \
		sh -c "ldconfig -p | awk '/x86-64/ && /=>/ { print \$$1 }' | sort -u" \
		> "$(STEAMRT4_PLATFORM_SONAMES)"
	@test -s "$(STEAMRT4_PLATFORM_SONAMES)"
	@echo "Steam Runtime 4 contract ready: $(STEAMRT4_PLATFORM_SONAMES)"

steam-linux:
	@set -e; \
	mode="$(STEAM_LINUX_SOURCE)"; \
	if [ "$$mode" = "auto" ]; then \
		case "$$(uname -s 2>/dev/null || echo unknown)" in \
			Linux*) \
				if [ "$${AONW_STEAMRT4_SDK:-0}" = "1" ]; then \
					mode="local"; \
				elif command -v gh >/dev/null; then \
					mode="github"; \
				else \
					echo "A local Steam Linux build must run inside the pinned Steam Runtime 4 SDK."; \
					echo "Use STEAM_LINUX_SOURCE=github, or enter the SDK and set AONW_STEAMRT4_SDK=1."; \
					exit 1; \
				fi ;; \
			*) \
				if command -v gh >/dev/null; then \
					mode="github"; \
				else \
					echo "Cannot build Steam Linux ZIP on this host."; \
					echo "Use STEAM_LINUX_SOURCE=github with gh installed."; \
					exit 1; \
				fi ;; \
		esac; \
	fi; \
	case "$$mode" in \
		local) $(MAKE) --no-print-directory steam-linux-local ;; \
		github) $(MAKE) --no-print-directory steam-linux-github ;; \
		existing) $(MAKE) --no-print-directory steam-package-linux ;; \
		*) echo "Invalid STEAM_LINUX_SOURCE=$$mode. Use auto, local, github, or existing."; exit 1 ;; \
	esac

steam-linux-local:
	@command -v flutter >/dev/null || { echo "flutter SDK is required for steam-linux-local."; exit 1; }
	@test "$${AONW_STEAMRT4_SDK:-0}" = "1" || { echo "steam-linux-local must run inside the pinned Steam Runtime 4 SDK with AONW_STEAMRT4_SDK=1."; exit 1; }
	@test -s "$(STEAMRT4_PLATFORM_SONAMES)" || { echo "Missing Steam Runtime contract: $(STEAMRT4_PLATFORM_SONAMES). Run make steam-runtime-contract on the Docker host first."; exit 1; }
	@case "$$(uname -s 2>/dev/null || echo unknown)" in \
		Linux*) ;; \
		*) echo "steam-linux-local requires a Linux host."; exit 1 ;; \
	esac
	@echo "Building Linux Steam release with API=$(STEAM_API_BASE_URL)..."
	@flutter config --enable-linux-desktop
	@flutter pub get --enforce-lockfile
	@flutter build linux --release --no-pub "--dart-define=AONW_API_BASE_URL=$(STEAM_API_BASE_URL)"
	@$(MAKE) --no-print-directory steam-package-linux

steam-linux-github:
	@command -v gh >/dev/null || { echo "gh is required for STEAM_LINUX_SOURCE=github."; exit 1; }
	@set -e; \
	branch=$$(git branch --show-current); \
	local_sha=$$(git rev-parse HEAD); \
	worktree_status=$$(git status --porcelain --untracked-files=normal); \
	build_name=$$(sed -n 's/^version:[[:space:]]*\([^+]*\)+.*/\1/p' "$(PUBSPEC)" | head -n 1); \
	build_number=$$(sed -n 's/^version:.*+\([0-9][0-9]*\).*$$/\1/p' "$(PUBSPEC)" | head -n 1); \
	test -n "$$branch" || { echo "Could not detect current git branch."; exit 1; }; \
	test -z "$$worktree_status" || { echo "Working tree must be clean before dispatching a Linux Steam build:"; printf '%s\n' "$$worktree_status"; exit 1; }; \
	test -n "$$build_name" || { echo "Could not parse version name from $(PUBSPEC)."; exit 1; }; \
	test -n "$$build_number" || { echo "Could not parse build number from $(PUBSPEC)."; exit 1; }; \
	git fetch origin "$$branch" >/dev/null; \
	remote_sha=$$(git rev-parse "origin/$$branch"); \
	test "$$local_sha" = "$$remote_sha" || { echo "Local HEAD is not pushed to origin/$$branch. Push first, then run make steam-linux again."; exit 1; }; \
	dispatch_token="$${local_sha}-$$(date -u +%Y%m%dT%H%M%SZ)-$$$$"; \
	echo "Dispatching $(STEAM_LINUX_WORKFLOW) on $$branch for $$build_name+$$build_number..."; \
	gh workflow run "$(STEAM_LINUX_WORKFLOW)" --ref "$$branch" -f build_name="$$build_name" -f build_number="$$build_number" -f source_sha="$$local_sha" -f dispatch_token="$$dispatch_token"; \
	echo "Waiting for GitHub Actions run to appear..."; \
	run_id=""; \
	i=1; \
	while [ "$$i" -le "$(STEAM_GITHUB_RUN_LOOKUP_ATTEMPTS)" ]; do \
		run_id=$$(gh run list --workflow "$(STEAM_LINUX_WORKFLOW)" --branch "$$branch" --event workflow_dispatch --json databaseId,displayTitle,headSha --limit 20 --jq ".[] | select(.headSha == \"$$local_sha\" and (.displayTitle | contains(\"[$$dispatch_token]\"))) | .databaseId" | head -n 1); \
		if [ -n "$$run_id" ]; then break; fi; \
		sleep "$(STEAM_GITHUB_RUN_LOOKUP_SLEEP)"; \
		i=$$((i + 1)); \
	done; \
	test -n "$$run_id" || { echo "Could not find GitHub Actions run for $(STEAM_LINUX_WORKFLOW)."; exit 1; }; \
	echo "Watching GitHub Actions run $$run_id..."; \
	gh run watch "$$run_id" --exit-status; \
	rm -rf "$(STEAM_LINUX_ARTIFACT_DIR)"; \
	mkdir -p "$(STEAM_LINUX_ARTIFACT_DIR)" "$(STEAM_DIST_DIR)"; \
	gh run download "$$run_id" --dir "$(STEAM_LINUX_ARTIFACT_DIR)" --pattern 'aonw-linux-steam-*'; \
	zip_file=$$(find "$(STEAM_LINUX_ARTIFACT_DIR)" -name 'aonw-linux-steam.zip' -print -quit); \
	test -n "$$zip_file" || { echo "Downloaded artifact did not contain aonw-linux-steam.zip."; exit 1; }; \
	cp "$$zip_file" "$(STEAM_LINUX_ZIP)"; \
	unzip -tq "$(STEAM_LINUX_ZIP)" >/dev/null; \
	tmp_dir=$$(mktemp -d); \
	trap 'rm -rf "$$tmp_dir"' EXIT; \
	unzip -q "$(STEAM_LINUX_ZIP)" -d "$$tmp_dir"; \
	test -f "$$tmp_dir/aonw" || { echo "Linux ZIP must contain aonw at root."; exit 1; }; \
	rg -a -F "$(STEAM_API_BASE_URL)" "$$tmp_dir" >/dev/null; \
	echo "Steam Linux ZIP ready: $(STEAM_LINUX_ZIP)"

steam-package-linux:
	@command -v zip >/dev/null || { echo "zip is required for steam-package-linux."; exit 1; }
	@command -v unzip >/dev/null || { echo "unzip is required for steam-package-linux."; exit 1; }
	@command -v grep >/dev/null || { echo "grep is required for steam-package-linux."; exit 1; }
	@test "$${AONW_STEAMRT4_SDK:-0}" = "1" || { echo "steam-package-linux must run inside the pinned Steam Runtime 4 SDK."; exit 1; }
	@test -x tool/linux/package_steamrt4_bundle.sh || { echo "Missing Linux runtime packager."; exit 1; }
	@test -s "$(STEAMRT4_PLATFORM_SONAMES)" || { echo "Missing Steam Runtime contract: $(STEAMRT4_PLATFORM_SONAMES)."; exit 1; }
	@test -d "$(STEAM_LINUX_RELEASE_DIR)" || { echo "Expected Linux release directory not found: $(STEAM_LINUX_RELEASE_DIR)"; exit 1; }
	@test -f "$(STEAM_LINUX_RELEASE_DIR)/aonw" || { echo "Expected Linux executable not found: $(STEAM_LINUX_RELEASE_DIR)/aonw"; exit 1; }
	@mkdir -p "$(STEAM_DIST_DIR)"
	@STEAMRT_SDK_IMAGE="$(STEAMRT4_SDK_IMAGE)" \
		STEAMRT_PLATFORM_IMAGE="$(STEAMRT4_PLATFORM_IMAGE)" \
		tool/linux/package_steamrt4_bundle.sh \
		"$(STEAM_LINUX_RELEASE_DIR)" \
		"$(STEAM_LINUX_BUNDLE_DIR)" \
		"$(STEAMRT4_PLATFORM_SONAMES)"
	@rm -f "$(STEAM_LINUX_ZIP)"
	@zip_path="$$(pwd)/$(STEAM_LINUX_ZIP)"; \
		cd "$(STEAM_LINUX_BUNDLE_DIR)" && zip -qry "$$zip_path" .
	@unzip -tq "$(STEAM_LINUX_ZIP)" >/dev/null
	@tmp_dir=$$(mktemp -d); \
	trap 'rm -rf "$$tmp_dir"' EXIT; \
	unzip -q "$(STEAM_LINUX_ZIP)" -d "$$tmp_dir"; \
	grep -R -a -F "$(STEAM_API_BASE_URL)" "$$tmp_dir" >/dev/null
	@echo "Verified Steam Linux API: $(STEAM_API_BASE_URL)"
	@echo "Steam Linux ZIP ready: $(STEAM_LINUX_ZIP)"

steam-prepare-from-dist:
	@command -v ditto >/dev/null || { echo "ditto is required for steam-prepare-from-dist."; exit 1; }
	@command -v unzip >/dev/null || { echo "unzip is required for steam-prepare-from-dist."; exit 1; }
	@command -v rg >/dev/null || { echo "rg is required for steam-prepare-from-dist."; exit 1; }
	@command -v strings >/dev/null || { echo "strings is required for steam-prepare-from-dist."; exit 1; }
	@test -f "$(STEAM_MACOS_ZIP)" || { echo "Missing Steam macOS ZIP: $(STEAM_MACOS_ZIP). Run make steam-macos first."; exit 1; }
	@test -f "$(STEAM_WINDOWS_DIST_ZIP)" || { echo "Missing Steam Windows ZIP/artifact: $(STEAM_WINDOWS_DIST_ZIP). Copy the GitHub Actions artifact to dist/ or set STEAM_WINDOWS_DIST_ZIP=/path."; exit 1; }
	@if [ "$(STEAM_INCLUDE_LINUX)" = "1" ]; then \
		test -n "$(STEAM_LINUX_DEPOT_ID)" || { echo "STEAM_LINUX_DEPOT_ID is required when STEAM_INCLUDE_LINUX=1."; exit 1; }; \
		test -f "$(STEAM_LINUX_DIST_ZIP)" || { echo "Missing Steam Linux ZIP/artifact: $(STEAM_LINUX_DIST_ZIP). Run make steam-linux, download the GitHub Actions artifact, or set STEAM_LINUX_DIST_ZIP=/path."; exit 1; }; \
	fi
	@set -e; \
	build_name=$$(sed -n 's/^version:[[:space:]]*\([^+]*\)+.*/\1/p' "$(PUBSPEC)" | head -n 1); \
	build_number=$$(sed -n 's/^version:.*+\([0-9][0-9]*\).*$$/\1/p' "$(PUBSPEC)" | head -n 1); \
	test -n "$$build_name" || { echo "Could not parse version name from $(PUBSPEC)."; exit 1; }; \
	test -n "$$build_number" || { echo "Could not parse build number from $(PUBSPEC)."; exit 1; }; \
	build_desc="$(STEAM_BUILD_DESC)"; \
	if [ -z "$$build_desc" ]; then build_desc="Build $$build_number - $$build_name release"; fi; \
	echo "Preparing SteamPipe content in $(STEAM_DEPLOY_DIR) ($$build_desc)..."; \
	rm -rf "$(STEAM_CONTENT_DIR)/macos" "$(STEAM_CONTENT_DIR)/windows" "$(STEAM_CONTENT_DIR)/linux"; \
	mkdir -p "$(STEAM_CONTENT_DIR)/macos" "$(STEAM_CONTENT_DIR)/windows" "$(STEAM_SCRIPT_DIR)" "$(STEAM_OUTPUT_DIR)"; \
	if [ "$(STEAM_INCLUDE_LINUX)" = "1" ]; then mkdir -p "$(STEAM_CONTENT_DIR)/linux"; fi; \
	ditto -x -k "$(STEAM_MACOS_ZIP)" "$(STEAM_CONTENT_DIR)/macos"; \
	test -d "$(STEAM_CONTENT_DIR)/macos/$(STEAM_MACOS_APP_NAME)" || { echo "macOS depot must contain $(STEAM_MACOS_APP_NAME) at its root."; exit 1; }; \
	tmp_dir=$$(mktemp -d); \
	trap 'rm -rf "$$tmp_dir"' EXIT; \
	windows_tmp_dir="$$tmp_dir/windows"; \
	mkdir -p "$$windows_tmp_dir"; \
	unzip -q "$(STEAM_WINDOWS_DIST_ZIP)" -d "$$windows_tmp_dir"; \
	if [ -d "$$windows_tmp_dir/steam-windows" ]; then \
		ditto "$$windows_tmp_dir/steam-windows" "$(STEAM_CONTENT_DIR)/windows"; \
	elif [ -f "$$windows_tmp_dir/aonw-windows-steam.zip" ]; then \
		unzip -q "$$windows_tmp_dir/aonw-windows-steam.zip" -d "$(STEAM_CONTENT_DIR)/windows"; \
	elif [ -f "$$windows_tmp_dir/aonw.exe" ]; then \
		ditto "$$windows_tmp_dir" "$(STEAM_CONTENT_DIR)/windows"; \
	else \
		echo "Windows ZIP must contain steam-windows/, aonw-windows-steam.zip, or aonw.exe at root."; \
		exit 1; \
	fi; \
	test -f "$(STEAM_CONTENT_DIR)/windows/aonw.exe" || { echo "Windows depot must contain aonw.exe at its root."; exit 1; }; \
	if [ "$(STEAM_INCLUDE_LINUX)" = "1" ]; then \
		linux_tmp_dir="$$tmp_dir/linux"; \
		mkdir -p "$$linux_tmp_dir"; \
		unzip -q "$(STEAM_LINUX_DIST_ZIP)" -d "$$linux_tmp_dir"; \
		if [ -d "$$linux_tmp_dir/steam-linux" ]; then \
			ditto "$$linux_tmp_dir/steam-linux" "$(STEAM_CONTENT_DIR)/linux"; \
		elif [ -f "$$linux_tmp_dir/aonw-linux-steam.zip" ]; then \
			unzip -q "$$linux_tmp_dir/aonw-linux-steam.zip" -d "$(STEAM_CONTENT_DIR)/linux"; \
		elif [ -f "$$linux_tmp_dir/aonw" ]; then \
			ditto "$$linux_tmp_dir" "$(STEAM_CONTENT_DIR)/linux"; \
		else \
			echo "Linux ZIP must contain steam-linux/, aonw-linux-steam.zip, or aonw at root."; \
			exit 1; \
		fi; \
		test -f "$(STEAM_CONTENT_DIR)/linux/aonw" || { echo "Linux depot must contain aonw at its root."; exit 1; }; \
	fi; \
	macos_binary=$$(find "$(STEAM_CONTENT_DIR)/macos/$(STEAM_MACOS_APP_NAME)/Contents/Frameworks/App.framework" -type f -name App -print -quit); \
	test -n "$$macos_binary" || { echo "Expected Flutter App.framework binary not found in macOS depot."; exit 1; }; \
	strings "$$macos_binary" | rg -F "$(STEAM_API_BASE_URL)" >/dev/null; \
	rg -a -F "$(STEAM_API_BASE_URL)" "$(STEAM_CONTENT_DIR)/windows/data/app.so" >/dev/null; \
	if [ "$(STEAM_INCLUDE_LINUX)" = "1" ]; then rg -a -F "$(STEAM_API_BASE_URL)" "$(STEAM_CONTENT_DIR)/linux" >/dev/null; fi; \
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
		if [ "$(STEAM_INCLUDE_LINUX)" = "1" ]; then printf '    "%s" "%s/depot_build_%s_linux.vdf"\n' "$(STEAM_LINUX_DEPOT_ID)" "$(STEAM_SCRIPT_DIR)" "$(STEAM_LINUX_DEPOT_ID)"; fi; \
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
	if [ "$(STEAM_INCLUDE_LINUX)" = "1" ]; then \
		{ \
			printf '%s\n' '"DepotBuildConfig"'; \
			printf '%s\n' '{'; \
			printf '  "DepotID" "%s"\n' "$(STEAM_LINUX_DEPOT_ID)"; \
			printf '  "ContentRoot" "%s/linux"\n' "$(STEAM_CONTENT_DIR)"; \
			printf '%s\n' '  "FileMapping"'; \
			printf '%s\n' '  {'; \
			printf '%s\n' '    "LocalPath" "*"'; \
			printf '%s\n' '    "DepotPath" "."'; \
			printf '%s\n' '    "recursive" "1"'; \
			printf '%s\n' '  }'; \
			printf '%s\n' '}'; \
		} > "$(STEAM_SCRIPT_DIR)/depot_build_$(STEAM_LINUX_DEPOT_ID)_linux.vdf"; \
		echo "Verified Steam macOS, Windows, and Linux API: $(STEAM_API_BASE_URL)"; \
	else \
		echo "Verified Steam macOS and Windows API: $(STEAM_API_BASE_URL)"; \
	fi; \
	echo "SteamPipe content ready in $(STEAM_DEPLOY_DIR)."

steam-upload-command:
	@echo 'cd "$(STEAM_SCRIPT_DIR)" && $(STEAMCMD) +login "$(STEAM_USER)" +run_app_build "$(STEAM_SCRIPT_DIR)/app_build_$(STEAM_APP_ID).vdf" +quit'

steam-upload:
	@command -v "$(STEAMCMD)" >/dev/null || { echo "$(STEAMCMD) is required for steam-upload."; exit 1; }
	@test -f "$(STEAM_SCRIPT_DIR)/app_build_$(STEAM_APP_ID).vdf" || { echo "Missing app build VDF. Run make steam-prepare-from-dist first."; exit 1; }
	@echo "Uploading Steam build with $(STEAMCMD) as $(STEAM_USER)..."
	@$(MAKE) --no-print-directory steam-upload-command
	@cd "$(STEAM_SCRIPT_DIR)" && "$(STEAMCMD)" +login "$(STEAM_USER)" +run_app_build "$(STEAM_SCRIPT_DIR)/app_build_$(STEAM_APP_ID).vdf" +quit

deploy-itch: itch

itch: itch-prepare itch-upload
	@echo "itch finished."

itch-prepare: steam itch-desktop android-build-itch
	@echo "itch artifacts ready:"
	@files="$(ITCH_MACOS_DIR) $(ITCH_WINDOWS_DIR) $(ITCH_ANDROID_APK)"; \
	if [ "$(ITCH_INCLUDE_LINUX)" = "1" ]; then files="$$files $(ITCH_LINUX_DIR)"; fi; \
	ls -ldh $$files

itch-desktop:
	@command -v butler >/dev/null || { echo "butler is required for itch-desktop validation."; exit 1; }
	@test -f "$(STEAM_MACOS_ZIP)" || { echo "Missing Steam macOS ZIP: $(STEAM_MACOS_ZIP). Run make steam first."; exit 1; }
	@test -f "$(STEAM_WINDOWS_ZIP)" || { echo "Missing Steam Windows ZIP: $(STEAM_WINDOWS_ZIP). Run make steam first."; exit 1; }
	@if [ "$(ITCH_INCLUDE_LINUX)" = "1" ] && [ ! -f "$(STEAM_LINUX_ZIP)" ]; then \
		$(MAKE) --no-print-directory steam-linux; \
	fi
	@if [ "$(ITCH_INCLUDE_LINUX)" = "1" ]; then \
		test -f "$(STEAM_LINUX_ZIP)" || { echo "Missing Steam Linux ZIP: $(STEAM_LINUX_ZIP). Run make steam-linux first."; exit 1; }; \
	fi
	@rm -rf "$(ITCH_MACOS_DIR)" "$(ITCH_WINDOWS_DIR)" "$(ITCH_LINUX_DIR)"
	@rm -f "$(ITCH_DIST_DIR)/aonw-macos-itch.zip" "$(ITCH_DIST_DIR)/aonw-windows-itch.zip" "$(ITCH_DIST_DIR)/aonw-linux-itch.zip"
	@mkdir -p "$(ITCH_MACOS_DIR)" "$(ITCH_WINDOWS_DIR)"
	@if [ "$(ITCH_INCLUDE_LINUX)" = "1" ]; then mkdir -p "$(ITCH_LINUX_DIR)"; fi
	@ditto -x -k "$(STEAM_MACOS_ZIP)" "$(ITCH_MACOS_DIR)"
	@if find "$(ITCH_MACOS_DIR)" -name '._*' -print -quit | rg . >/dev/null; then \
		echo "itch macOS folder must not contain AppleDouble entries."; \
		exit 1; \
	fi
	@codesign --verify --deep --strict --verbose=2 "$(ITCH_MACOS_DIR)/$(STEAM_MACOS_APP_NAME)"
	@spctl --assess --type execute --verbose=2 "$(ITCH_MACOS_DIR)/$(STEAM_MACOS_APP_NAME)"
	@unzip -q "$(STEAM_WINDOWS_ZIP)" -d "$(ITCH_WINDOWS_DIR)"
	@if [ "$(ITCH_INCLUDE_LINUX)" = "1" ]; then unzip -q "$(STEAM_LINUX_ZIP)" -d "$(ITCH_LINUX_DIR)"; fi
	@test -d "$(ITCH_MACOS_DIR)/$(STEAM_MACOS_APP_NAME)" || { echo "itch macOS folder must contain $(STEAM_MACOS_APP_NAME)."; exit 1; }
	@test -f "$(ITCH_WINDOWS_DIR)/aonw.exe" || { echo "itch Windows folder must contain aonw.exe."; exit 1; }
	@if [ "$(ITCH_INCLUDE_LINUX)" = "1" ]; then test -f "$(ITCH_LINUX_DIR)/aonw" || { echo "itch Linux folder must contain aonw."; exit 1; }; fi
	@printf '%s\n' '[[actions]]' 'name = "play"' 'path = "$(STEAM_MACOS_APP_NAME)"' > "$(ITCH_MACOS_DIR)/.itch.toml"
	@printf '%s\n' '[[actions]]' 'name = "play"' 'path = "aonw.exe"' > "$(ITCH_WINDOWS_DIR)/.itch.toml"
	@if [ "$(ITCH_INCLUDE_LINUX)" = "1" ]; then printf '%s\n' '[[actions]]' 'name = "play"' 'path = "aonw"' > "$(ITCH_LINUX_DIR)/.itch.toml"; fi
	@butler validate --platform osx "$(ITCH_MACOS_DIR)"
	@butler validate --platform windows "$(ITCH_WINDOWS_DIR)"
	@if [ "$(ITCH_INCLUDE_LINUX)" = "1" ]; then butler validate --platform linux "$(ITCH_LINUX_DIR)"; fi
	@find_dirs="$(ITCH_MACOS_DIR) $(ITCH_WINDOWS_DIR)"; \
	if [ "$(ITCH_INCLUDE_LINUX)" = "1" ]; then find_dirs="$$find_dirs $(ITCH_LINUX_DIR)"; fi; \
	if find $$find_dirs -iname '*steam*' \
		! -path "$(ITCH_LINUX_DIR)/STEAM_RUNTIME_MANIFEST.txt" \
		! -path "$(ITCH_LINUX_DIR)/licenses/steamrt-container-host-compat.copyright" \
		-print -quit | rg . >/dev/null; then \
		echo "itch desktop folders contain steam-named paths."; \
		exit 1; \
	fi
	@if [ "$(ITCH_INCLUDE_LINUX)" = "1" ]; then \
		echo "itch desktop folders ready: $(ITCH_MACOS_DIR), $(ITCH_WINDOWS_DIR), $(ITCH_LINUX_DIR)"; \
	else \
		echo "itch desktop folders ready: $(ITCH_MACOS_DIR), $(ITCH_WINDOWS_DIR)"; \
	fi

itch-upload:
	@command -v butler >/dev/null || { echo "butler is required for itch-upload."; exit 1; }
	@test -n "$(ITCH_TARGET)" || { echo "ITCH_TARGET is required, e.g. ITCH_TARGET=user/game."; exit 1; }
	@test -d "$(ITCH_MACOS_DIR)" || { echo "Missing itch macOS folder: $(ITCH_MACOS_DIR). Run make itch-prepare first."; exit 1; }
	@test -d "$(ITCH_WINDOWS_DIR)" || { echo "Missing itch Windows folder: $(ITCH_WINDOWS_DIR). Run make itch-prepare first."; exit 1; }
	@if [ "$(ITCH_INCLUDE_LINUX)" = "1" ]; then test -d "$(ITCH_LINUX_DIR)" || { echo "Missing itch Linux folder: $(ITCH_LINUX_DIR). Run make itch-prepare first."; exit 1; }; fi
	@test -f "$(ITCH_ANDROID_APK)" || { echo "Missing itch Android APK: $(ITCH_ANDROID_APK). Run make android-build-itch first."; exit 1; }
	@set -e; \
	version="$(ITCH_USER_VERSION)"; \
	test -n "$$version" || { echo "ITCH_USER_VERSION could not be resolved."; exit 1; }; \
	echo "Uploading macOS build to itch: $(ITCH_TARGET):$(ITCH_MACOS_CHANNEL) ($$version)..."; \
	butler push "$(ITCH_MACOS_DIR)" "$(ITCH_TARGET):$(ITCH_MACOS_CHANNEL)" --userversion "$$version" $(ITCH_UPLOAD_ARGS); \
	echo "Uploading Windows build to itch: $(ITCH_TARGET):$(ITCH_WINDOWS_CHANNEL) ($$version)..."; \
	butler push "$(ITCH_WINDOWS_DIR)" "$(ITCH_TARGET):$(ITCH_WINDOWS_CHANNEL)" --userversion "$$version" $(ITCH_UPLOAD_ARGS); \
	if [ "$(ITCH_INCLUDE_LINUX)" = "1" ]; then \
		echo "Uploading Linux build to itch: $(ITCH_TARGET):$(ITCH_LINUX_CHANNEL) ($$version)..."; \
		butler push "$(ITCH_LINUX_DIR)" "$(ITCH_TARGET):$(ITCH_LINUX_CHANNEL)" --userversion "$$version" $(ITCH_UPLOAD_ARGS); \
	fi; \
	echo "Uploading Android build to itch: $(ITCH_TARGET):$(ITCH_ANDROID_CHANNEL) ($$version)..."; \
	butler push "$(ITCH_ANDROID_APK)" "$(ITCH_TARGET):$(ITCH_ANDROID_CHANNEL)" --userversion "$$version" $(ITCH_UPLOAD_ARGS); \
	echo "itch.io uploads finished."

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
	printf '%s\n' "$$new_build" | grep -Eq '^[1-9][0-9]*$$' || { echo "NEW_BUILD must be a positive integer without leading zeroes: $$new_build"; exit 1; }; \
	test "$$new_build" -gt "$$current_build" || { echo "NEW_BUILD ($$new_build) must be greater than current build ($$current_build)."; exit 1; }; \
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
	printf '%s\n' "$$new_name" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$$' || { echo "NEW_VERSION must be semantic x.y.z without leading zeroes or metadata: $$new_name"; exit 1; }; \
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

# Pure planner: validates the complete public option contract and prints the
# selected release without checking credentials, changing Git, or running a
# build/upload command. It is intentionally usable from feature branches.
deploy-all-plan:
	@command -v dart >/dev/null || { echo "dart is required for deploy-all-plan."; exit 1; }
	@test -z "$(IOS_ARCHIVE_ON_DEPLOY)" || { echo "IOS_ARCHIVE_ON_DEPLOY was removed. Use DEPLOY_ALL_IOS_MODE=off|best-effort|required."; exit 1; }
	@set -e; \
	current_version=$$(sed -n 's/^version:[[:space:]]*\([^+]*\)+.*/\1/p' "$(PUBSPEC)" | head -n 1); \
	current_build=$$(sed -n 's/^version:.*+\([0-9][0-9]*\).*$$/\1/p' "$(PUBSPEC)" | head -n 1); \
	test -n "$$current_version" || { echo "Could not parse current version from $(PUBSPEC)."; exit 1; }; \
	test -n "$$current_build" || { echo "Could not parse current build from $(PUBSPEC)."; exit 1; }; \
	case "$$(uname -s 2>/dev/null || echo unknown)" in \
		Darwin) host=macos ;; \
		Linux*) host=linux ;; \
		MINGW*|MSYS*|CYGWIN*) host=windows ;; \
		*) echo "Unsupported deploy-all host."; exit 1 ;; \
	esac; \
	gh_available=0; if command -v gh >/dev/null; then gh_available=1; fi; \
	windows_artifact_available=0; if [ -d "$(STEAM_WINDOWS_RELEASE_DIR)" ]; then windows_artifact_available=1; fi; \
	linux_artifact_available=0; if [ -d "$(STEAM_LINUX_RELEASE_DIR)" ]; then linux_artifact_available=1; fi; \
	dart tool/release/deploy_all_plan.dart \
	  --environment "$(DEPLOY_ENV)" \
	  --host "$$host" \
	  --steam "$(DEPLOY_ALL_STEAMWORKS)" \
	  --google "$(DEPLOY_ALL_GOOGLE_PLAY)" \
	  --google-validate-only "$(DEPLOY_ALL_GOOGLE_PLAY_VALIDATE_ONLY)" \
	  --itch "$(DEPLOY_ALL_ITCH)" \
	  --itch-target "$(ITCH_TARGET)" \
	  --steam-linux "$(STEAM_INCLUDE_LINUX)" \
	  --itch-linux "$(ITCH_INCLUDE_LINUX)" \
	  --download-linux "$(DOWNLOAD_INCLUDE_LINUX)" \
	  --ios "$(DEPLOY_ALL_IOS_MODE)" \
	  --google-track "$(DEPLOY_ALL_GOOGLE_PLAY_MODE)" \
	  --windows-source "$(STEAM_WINDOWS_SOURCE)" \
	  --linux-source "$(STEAM_LINUX_SOURCE)" \
	  --github-cli-available "$$gh_available" \
	  --windows-artifact-available "$$windows_artifact_available" \
	  --linux-artifact-available "$$linux_artifact_available" \
	  --version-bump "$(VERSION_BUMP)" \
	  --current-version "$$current_version" \
	  --current-build "$$current_build" \
	  --new-version "$(NEW_VERSION)" \
	  --new-build "$(NEW_BUILD)" \
	  --format "$(DEPLOY_ALL_PLAN_FORMAT)"

# Environment and credential checks that must pass before release-check or the
# version commit. It deliberately performs no publication or remote mutation.
deploy-all-preflight:
	@$(MAKE) --no-print-directory deploy-all-plan
	@$(MAKE) --no-print-directory preflight-release
	@$(MAKE) --no-print-directory macos-distribution-preflight
	@for command in flutter ssh rsync rg zip unzip ditto butler; do \
		command -v "$$command" >/dev/null || { echo "$$command is required for deploy-all."; exit 1; }; \
	done
	@test -n "$(REMOTE_DEPLOY_SSH_KEY)" || { echo "REMOTE_DEPLOY_SSH_KEY is required."; exit 1; }
	@test -n "$(REMOTE_DEPLOY_USER)" || { echo "REMOTE_DEPLOY_USER is required."; exit 1; }
	@test -n "$(REMOTE_DEPLOY_HOST)" || { echo "REMOTE_DEPLOY_HOST is required."; exit 1; }
	@test -n "$(REMOTE_DEPLOY_PATH)" || { echo "REMOTE_DEPLOY_PATH is required."; exit 1; }
	@test -f "$(REMOTE_DEPLOY_SSH_KEY)" || { echo "SSH key not found: $(REMOTE_DEPLOY_SSH_KEY)"; exit 1; }
	@test -n "$(WEB_DEPLOY_SSH_KEY)" || { echo "WEB_DEPLOY_SSH_KEY is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_USER)" || { echo "WEB_DEPLOY_USER is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_HOST)" || { echo "WEB_DEPLOY_HOST is required."; exit 1; }
	@test -n "$(WEB_DEPLOY_DEST)" || { echo "WEB_DEPLOY_DEST is required."; exit 1; }
	@test -n "$(HOMEPAGE_DEPLOY_DEST)" || { echo "HOMEPAGE_DEPLOY_DEST is required."; exit 1; }
	@test -n "$(DOWNLOAD_DEPLOY_DEST)" || { echo "DOWNLOAD_DEPLOY_DEST is required."; exit 1; }
	@test -f "$(WEB_DEPLOY_SSH_KEY)" || { echo "SSH key not found: $(WEB_DEPLOY_SSH_KEY)"; exit 1; }
	@$(MAKE) --no-print-directory android-preflight
	@if [ "$(DEPLOY_ALL_IOS_MODE)" = "required" ]; then \
		command -v xcodebuild >/dev/null || { echo "xcodebuild is required for DEPLOY_ALL_IOS_MODE=required."; exit 1; }; \
		test -d "$(IOS_ARCHIVE_WORKSPACE)" || { echo "Xcode workspace not found: $(IOS_ARCHIVE_WORKSPACE)"; exit 1; }; \
	fi
	@if [ "$(DEPLOY_ALL_STEAMWORKS)" = "1" ]; then \
		command -v "$(STEAMCMD)" >/dev/null || { echo "$(STEAMCMD) is required for Steamworks upload."; exit 1; }; \
	fi
	@if [ "$(DEPLOY_ALL_GOOGLE_PLAY)" = "1" ]; then \
		case "$(DEPLOY_ALL_GOOGLE_PLAY_MODE)" in closed) track="$(ANDROID_PLAY_CLOSED_TRACK)" ;; *) track="$(DEPLOY_ALL_GOOGLE_PLAY_MODE)" ;; esac; \
		$(MAKE) --no-print-directory android-play-preflight ANDROID_PLAY_TRACK="$$track"; \
	fi
	@set -e; \
	case "$(STEAM_WINDOWS_SOURCE)" in \
		github) command -v gh >/dev/null || { echo "gh is required for STEAM_WINDOWS_SOURCE=github."; exit 1; } ;; \
		existing) test -d "$(STEAM_WINDOWS_RELEASE_DIR)" || { echo "Missing Windows release directory: $(STEAM_WINDOWS_RELEASE_DIR)"; exit 1; } ;; \
		auto) command -v gh >/dev/null || test -d "$(STEAM_WINDOWS_RELEASE_DIR)" || { echo "Windows source auto needs gh or $(STEAM_WINDOWS_RELEASE_DIR)."; exit 1; } ;; \
	esac; \
	if [ "$(DEPLOY_ALL_INCLUDE_LINUX)" = "1" ]; then \
		case "$(STEAM_LINUX_SOURCE)" in \
			github) command -v gh >/dev/null || { echo "gh is required for STEAM_LINUX_SOURCE=github."; exit 1; } ;; \
			existing) test -d "$(STEAM_LINUX_RELEASE_DIR)" || { echo "Missing Linux release directory: $(STEAM_LINUX_RELEASE_DIR)"; exit 1; } ;; \
			auto) command -v gh >/dev/null || test -d "$(STEAM_LINUX_RELEASE_DIR)" || { echo "Linux source auto needs gh or $(STEAM_LINUX_RELEASE_DIR)."; exit 1; } ;; \
		esac; \
	fi

# Local + remote orchestration. Every public option and required capability is
# validated before the quality gate or version commit. Artifacts are prepared,
# the backend is deployed and checked, then explicitly enabled stores and the
# static clients are published. Aborts on any step failure.
deploy-all:
	@$(MAKE) --no-print-directory deploy-all-preflight
	@echo "Running mandatory release quality gate..."
	@$(MAKE) --no-print-directory release-check
	@echo "[1/13] Bumping build version..."
	@$(MAKE) --no-print-directory bump-version NEW_VERSION="$(NEW_VERSION)" NEW_BUILD="$(NEW_BUILD)"
	@echo "Re-running mandatory release quality gate for the release commit..."
	@$(MAKE) --no-print-directory release-check
	@echo "[2/13] Applying the selected iOS archive policy..."
	@$(MAKE) --no-print-directory archive-ios-if-possible
	@echo "[3/13] Pushing local main to origin..."
	@git push origin main
	@echo "[4/13] Preparing desktop, Android, and public-download artifacts..."
	@$(MAKE) --no-print-directory steam STEAM_INCLUDE_LINUX="$(DEPLOY_ALL_INCLUDE_LINUX)"
	@$(MAKE) --no-print-directory itch-desktop ITCH_INCLUDE_LINUX="$(DEPLOY_ALL_INCLUDE_LINUX)"
	@$(MAKE) --no-print-directory android-build-itch
	@$(MAKE) --no-print-directory download-package
	@if [ "$(DEPLOY_ALL_GOOGLE_PLAY)" = "1" ]; then $(MAKE) --no-print-directory android-build-aab; fi
	@echo "[5/13] Triggering the $(DEPLOY_ENV) backend deploy via SSH..."
	@ssh -i "$(REMOTE_DEPLOY_SSH_KEY)" $(REMOTE_DEPLOY_USER)@$(REMOTE_DEPLOY_HOST) \
	  'cd "$(REMOTE_DEPLOY_PATH)" && make deploy PROFILE="$(DEPLOY_ENV)" BRANCH=main'
	@echo "[6/13] Verifying backend readiness before client publication..."
	@$(MAKE) --no-print-directory health
	@echo "[7/13] Uploading Steamworks build if enabled..."
	@set -e; \
	if [ "$(DEPLOY_ALL_STEAMWORKS)" = "1" ]; then \
		$(MAKE) --no-print-directory steam-prepare-from-dist; \
		$(MAKE) --no-print-directory steam-upload; \
	else \
		echo "DEPLOY_ALL_STEAMWORKS=0; skipping Steamworks upload."; \
	fi
	@echo "[8/13] Running the selected Google Play action if enabled..."
	@if [ "$(DEPLOY_ALL_GOOGLE_PLAY)" = "1" ]; then \
		case "$(DEPLOY_ALL_GOOGLE_PLAY_MODE)" in \
			closed) \
				$(MAKE) --no-print-directory android-upload-closed ANDROID_PLAY_VALIDATE_ONLY="$(DEPLOY_ALL_GOOGLE_PLAY_VALIDATE_ONLY)" ;; \
			*) \
				$(MAKE) --no-print-directory android-upload-aab ANDROID_PLAY_TRACK="$(DEPLOY_ALL_GOOGLE_PLAY_MODE)" ANDROID_PLAY_VALIDATE_ONLY="$(DEPLOY_ALL_GOOGLE_PLAY_VALIDATE_ONLY)" ;; \
		esac; \
	else \
		echo "DEPLOY_ALL_GOOGLE_PLAY=0; skipping Google Play."; \
	fi
	@echo "[9/13] Uploading itch.io artifacts if explicitly enabled..."
	@if [ "$(DEPLOY_ALL_ITCH)" = "1" ]; then \
		echo "Uploading itch.io artifacts to target $(ITCH_TARGET)..."; \
		$(MAKE) --no-print-directory itch-upload; \
	else \
		echo "DEPLOY_ALL_ITCH=0; skipping itch.io upload."; \
	fi
	@echo "[10/13] Building and uploading static root homepage..."
	@$(MAKE) --no-print-directory deploy-homepage
	@echo "[11/13] Uploading public download artifacts..."
	@$(MAKE) --no-print-directory deploy-download-files
	@echo "[12/13] Building and uploading demo web bundle..."
	@$(MAKE) --no-print-directory deploy-web
	@echo "[13/13] Final health checks..."
	@$(MAKE) --no-print-directory health
	@$(MAKE) --no-print-directory health-web
	@$(MAKE) --no-print-directory health-homepage
	@$(MAKE) --no-print-directory health-architecture
	@$(MAKE) --no-print-directory health-stats
	@$(MAKE) --no-print-directory health-downloads
	@echo "deploy-all finished."

preflight-release:
	@command -v git >/dev/null || { echo "git is required."; exit 1; }
	@branch=$$(git branch --show-current); \
	test "$$branch" = "main" || { echo "deploy-all must run from main, current branch is '$$branch'."; exit 1; }
	@if [ -n "$$(git status --porcelain --untracked-files=normal)" ]; then \
		echo "Local changes detected. Commit/stash them before deploy-all:"; \
		git status --short --untracked-files=normal; \
		exit 1; \
	fi

serverpod-version:
	@version=$$(awk '/^dependencies:[[:space:]]*$$/ { in_dependencies = 1; next } in_dependencies && /^[^[:space:]#]/ { exit } in_dependencies && $$1 == "serverpod:" && NF == 2 { print $$2; exit }' server/pubspec.yaml); \
		test -n "$$version" || { echo "Could not parse the exact Serverpod runtime version from server/pubspec.yaml." >&2; exit 1; }; \
		printf '%s\n' "$$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$$' || { echo "Invalid exact Serverpod runtime version in server/pubspec.yaml: $$version" >&2; exit 1; }; \
		printf '%s\n' "$$version"

serverpod-cli-install:
	@set -e; \
		version=$$($(MAKE) --no-print-directory serverpod-version); \
		PUB_CACHE="$(PUB_CACHE)" dart pub global activate serverpod_cli "$$version"; \
		$(MAKE) --no-print-directory serverpod-cli-check

serverpod-cli-ensure:
	@if $(MAKE) --no-print-directory serverpod-cli-check >/dev/null 2>&1; then \
		echo "Serverpod CLI already matches $$($(MAKE) --no-print-directory serverpod-version)."; \
	else \
		$(MAKE) --no-print-directory serverpod-cli-install; \
	fi

serverpod-cli-check:
	@command -v "$(SERVERPOD_CLI)" >/dev/null 2>&1 || { echo "Serverpod CLI not found: $(SERVERPOD_CLI)"; exit 1; }
	@set -e; \
		expected=$$($(MAKE) --no-print-directory serverpod-version); \
		output=$$("$(SERVERPOD_CLI)" --version 2>&1) || { echo "Could not read Serverpod CLI version from $(SERVERPOD_CLI)."; printf '%s\n' "$$output"; exit 1; }; \
		actual=$$(printf '%s\n' "$$output" | sed -n 's/^Serverpod version:[[:space:]]*//p' | head -n 1); \
		test -n "$$actual" || { echo "Could not parse Serverpod CLI version from $(SERVERPOD_CLI)."; printf '%s\n' "$$output"; exit 1; }; \
		if [ "$$actual" != "$$expected" ]; then \
			echo "Serverpod CLI version mismatch: expected $$expected from server/pubspec.yaml, found $$actual."; \
			echo "Install the matching CLI with: make serverpod-cli-install"; \
			echo "If SERVERPOD_CLI is overridden, update that binary or remove the override."; \
			exit 1; \
		fi

generated-code-check: toolchain-check serverpod-cli-check
	@SERVERPOD_CLI="$(SERVERPOD_CLI)" tool/check_generated_code.sh
	@dart run tool/assets/compile/main.dart verify-runtime

assets-compile: root-dependencies
	@dart run tool/assets/compile/main.dart compile

assets-verify: root-dependencies
	@dart run tool/assets/compile/main.dart verify-runtime

assets-check: root-dependencies
	@dart run tool/assets/compile/main.dart check

assets-reproduce: root-dependencies
	@dart run tool/assets/compile/main.dart reproduce

check-migrations: generated-code-check

migrate:
	@echo "Serverpod migrations are applied by the server at startup."
	@echo "Set SERVERPOD_APPLY_MIGRATIONS=true in .env and run: make up"

up: profile-check
	@$(COMPOSE_PROFILE) up -d --remove-orphans
	@case "$(PROFILE)" in \
		staging|prod) \
			$(COMPOSE_PROFILE) up -d --force-recreate --no-deps caddy ;; \
		*) : ;; \
	esac

health: profile-check
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
	$(COMPOSE_PROFILE) logs --tail=120 "$(SERVER_SERVICE)"; \
	exit 1

health-web:
	@echo "Checking $(WEB_HEALTH_URL)"
	@curl -fsS --max-time 5 -o /dev/null -w "%{http_code}\n" "$(WEB_HEALTH_URL)" \
	  || { echo "Web frontend not reachable"; exit 1; }

health-homepage:
	@echo "Checking $(HOMEPAGE_HEALTH_URL)"
	@curl -fsS --max-time 5 -o /dev/null -w "%{http_code}\n" "$(HOMEPAGE_HEALTH_URL)" \
	  || { echo "Static homepage not reachable"; exit 1; }

health-architecture:
	@command -v rg >/dev/null || { echo "rg is required for health-architecture."; exit 1; }
	@echo "Checking $(ARCHITECTURE_HEALTH_URL)"
	@curl -fsS --max-time 5 "$(ARCHITECTURE_HEALTH_URL)" \
	  | rg -F 'data-page="architecture"' >/dev/null \
	  || { echo "Architecture atlas missing or invalid"; exit 1; }

health-stats:
	@command -v rg >/dev/null || { echo "rg is required for health-stats."; exit 1; }
	@echo "Checking $(STATS_HEALTH_URL)"
	@curl -fsS --max-time 5 "$(STATS_HEALTH_URL)" \
	  | rg -F 'data-page="multiplayer-stats"' >/dev/null \
	  || { echo "Multiplayer statistics page missing or invalid"; exit 1; }
	@echo "Checking $(STATS_API_HEALTH_URL)"
	@body=$$(curl -fsS --max-time 5 "$(STATS_API_HEALTH_URL)") \
	  || { echo "Multiplayer statistics API not reachable"; exit 1; }; \
	printf '%s' "$$body" | rg -F '"schemaVersion":1' >/dev/null \
	  && printf '%s' "$$body" | rg -F '"totals":{' >/dev/null \
	  && printf '%s' "$$body" | rg -F '"activity":[' >/dev/null \
	  && printf '%s' "$$body" | rg -F '"outcomes":[' >/dev/null \
	  && printf '%s' "$$body" | rg -F '"turns":{' >/dev/null \
	  || { echo "Multiplayer statistics API payload is invalid"; exit 1; }

health-engine-docs:
	@command -v rg >/dev/null || { echo "rg is required for health-engine-docs."; exit 1; }
	@echo "Checking $(ENGINE_DOCS_HEALTH_URL)"
	@curl -fsS --max-time 5 "$(ENGINE_DOCS_HEALTH_URL)" \
	  | rg -F 'data-page="engine-docs-home"' >/dev/null \
	  || { echo "AoNW Engine presentation page missing or invalid"; exit 1; }
	@echo "Checking $(ENGINE_DOCS_API_HEALTH_URL)"
	@curl -fsS --max-time 5 "$(ENGINE_DOCS_API_HEALTH_URL)" \
	  | rg -F 'data-current-crate="aonw_engine"' >/dev/null \
	  || { echo "AoNW Engine Rust API documentation missing or invalid"; exit 1; }

health-downloads:
	@set -e; \
	files="$(DOWNLOAD_MACOS_FILE) $(DOWNLOAD_WINDOWS_FILE) $(DOWNLOAD_ANDROID_FILE)"; \
	if [ "$(DOWNLOAD_INCLUDE_LINUX)" = "1" ]; then files="$$files $(DOWNLOAD_LINUX_FILE)"; fi; \
	for file in $$files; do \
		url="$(DOWNLOAD_BASE_URL)/$$file"; \
		echo "Checking $$url"; \
		curl -fsSI --max-time 10 "$$url" >/dev/null || { echo "Download not reachable: $$url"; exit 1; }; \
	done

prune:
	@docker image prune -f
	@if [ "$(CLEAN_BUILD_CACHE)" = "1" ]; then \
		docker builder prune -af; \
	else \
		docker builder prune -f --filter until=168h; \
	fi

status: profile-check
	@$(COMPOSE_PROFILE) ps

logs: profile-check
	@$(COMPOSE_PROFILE) logs -f --tail=120 "$(SERVER_SERVICE)"
