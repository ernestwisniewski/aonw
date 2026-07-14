# Age of New Worlds Documentation

This directory contains the durable project documentation for contributors,
operators, release work, and gameplay design. Documents describe current
behavior unless they explicitly call out historical context or future work.

## Start Here

| Need | Read |
| --- | --- |
| Understand the codebase | [Architecture](#architecture), then [Multiplayer Protocol](multiplayer-protocol.md) if networking is involved. |
| Change an architectural contract | [Architecture Decision Records](adr/README.md) before changing ownership, determinism, commands, compatibility, or deployment policy. |
| Refactor or split Dart code | [Architecture Budgets](architecture-budgets.md) for the complete census, role-specific targets, and legacy-debt ratchet. |
| Build or release the game | [Build And Deploy Runbook](build-and-deploy.md). |
| Work on tests or coverage | [Test Coverage](test-coverage.md) for line coverage, [Mutation Testing](mutation-testing.md) for critical behavioral assertions, and [Critical End-to-End Journeys](critical-e2e.md) for real persistence and network boundaries. |
| Change gameplay balance | [Pace Profiles](game-design/pace-profiles.md), [Scoring and Outcomes](game-design/scoring-and-outcomes.md), and the relevant gameplay-system document. |
| Work on backend operations | [Data Retention](data-retention.md), [Serverpod Insights Runbook](serverpod-insights-runbook.md), [PostgreSQL Backup And Restore](postgres-backup.md), and [Serverpod Social Auth Setup](serverpod-social-auth-setup.md). |
| Prepare public assets | [Marketing Assets](marketing/README.md) and [Asset Templates](templates/README.md). |

## Architecture

| Area | Responsibility |
| --- | --- |
| `packages/aonw_core/` | Shared Dart-only game rules, protocol models, and AI planning. |
| `lib/game/domain/` | Client-side domain aggregates, save-state reducers, commands, events, and value objects. |
| `lib/game/application/` | Use cases and ports around persistence, logging, clocks, ids, and transport. |
| `lib/game/infrastructure/` | Persistence, migrations, local transport, and system adapters. |
| `lib/game/presentation/` | Riverpod providers, Flutter UI, Flame rendering, view models, and user-facing formatting. |
| `lib/map/` | Map data, loading, topology, terrain rendering, and editor-facing map support. |
| `server/lib/` | Serverpod endpoints, Auth Core adapters, multiplayer services, ORM persistence, and realtime streams. |

```mermaid
flowchart LR
  Server["server/lib"]
  Core["packages/aonw_core"]
  Domain["lib/game/domain"]
  Application["lib/game/application"]
  Infrastructure["lib/game/infrastructure"]
  Presentation["lib/game/presentation"]
  Map["lib/map"]
  Api["lib/api"]

  Server --> Core
  Presentation --> Application
  Presentation --> Domain
  Presentation --> Map
  Application --> Domain
  Infrastructure --> Application
  Infrastructure --> Domain
  Domain --> Core
  Domain --> Map
  Api --> Core
```

Architecture boundaries are enforced by
`test/architecture/layer_boundaries_test.dart`. When a cross-layer dependency is
intentional, update this document and the architecture test in the same change.

## Architecture Decisions

The architecture table above describes the current repository. The accepted
target boundaries and their migration constraints are recorded in the
[ADR index](adr/README.md):

- [map and state ownership](adr/0001-map-and-state-ownership.md);
- [the deterministic game engine](adr/0002-deterministic-game-engine.md);
- [command boundaries](adr/0003-command-boundaries.md);
- [multiplayer protocol versioning](adr/0004-versioned-multiplayer-protocol.md);
- [immutable deployment promotion](adr/0005-immutable-deployment.md).

An accepted ADR is binding for new code even when its implementation is still
in progress. Do not edit history to change a decision; add a superseding ADR.

## Document Index

### Architecture

| Document | Use It For |
| --- | --- |
| [Architecture Decision Records](adr/README.md) | Durable ownership, determinism, command, compatibility, and deployment decisions. |
| [Multiplayer Protocol](multiplayer-protocol.md) | Current client/server protocol surface and rollout procedure. |
| [Static Analysis](static-analysis.md) | Shared strict analyzer policy, generated-code boundaries, and canonical commands. |
| [Architecture Budgets](architecture-budgets.md) | Repository-wide Dart census, role-specific size/complexity targets, callable AST metrics, and exact legacy-debt ratchet. |
| [Test Coverage](test-coverage.md) | Line-coverage scopes, exact totals, portable coverage floors, historical ratchet, and changed-line gate. |
| [Mutation Testing](mutation-testing.md) | Critical scopes, AST mutation operators, deterministic execution, exact baseline, and survivor ratchet. |
| [Critical End-to-End Journeys](critical-e2e.md) | Local create/save/reload and public Serverpod auth/match/command/reconnect gates. |

### Release And Operations

| Document | Use It For |
| --- | --- |
| [Build And Deploy Runbook](build-and-deploy.md) | Local builds, release packaging, server deploys, web deploys, store uploads, and public downloads. |
| [Data Retention](data-retention.md) | Automatic cleanup, data without retention, and backup-lifecycle boundaries. |
| [PostgreSQL Backup And Restore](postgres-backup.md) | Database backup, restore, and recovery procedures. |
| [Serverpod Insights Runbook](serverpod-insights-runbook.md) | Insights setup, health checks, and production visibility. |

### Multiplayer And Backend

| Document | Use It For |
| --- | --- |
| [Multiplayer Protocol](multiplayer-protocol.md) | Client/server protocol boundaries, generated Serverpod surfaces, and stream invariants. |
| [Multiplayer TestFlight Readiness](multiplayer-testflight.md) | Staging setup and mobile multiplayer readiness checks. |
| [Multiplayer Scale-Out Contract](multiplayer-scale-out.md) | Constraints for scaling multiplayer services. |
| [Multiplayer Serverpod Smoke And Alerts](multiplayer-chaos-alerts.md) | Smoke-test coverage, failure modes, and alerting expectations. |
| [Critical End-to-End Journeys](critical-e2e.md) | Canonical real-boundary persistence and multiplayer release journeys. |
| [Serverpod Social Auth Setup](serverpod-social-auth-setup.md) | Google, Apple, and Steam auth configuration. |

### Game Design

| Document | Use It For |
| --- | --- |
| [Asset Icon Rendering](game-design/asset-icon-rendering.md) | Shared icon rendering rules for gameplay assets. |
| [Balance Telemetry](game-design/balance-telemetry.md) | Telemetry hooks, balance signals, and simulation output. |
| [Combat Feedback](game-design/combat-feedback.md) | UI, audio, timing, and notification feedback for combat. |
| [Combat Preview](game-design/combat-preview.md) | Attack forecast behavior and presentation. |
| [Event Notifications and Popups](game-design/event-notifications-and-popups.md) | Notification behavior, popup layering, and activity feedback. |
| [Gamepad Controls](game-design/gamepad-controls.md) | Controller input mapping and in-game manual contract. |
| [Map Display Preferences](game-design/map-display-preferences.md) | Player display toggles and map visualization options. |
| [Map Validation](game-design/map-validation.md) | Bundled map validation rules and failure handling. |
| [Mobile QoL Automation](game-design/mobile-qol-automation.md) | Mobile-first turn flow and automation quality-of-life behavior. |
| [Objective Chain](game-design/objective-chain.md) | Objective progression, guidance, and player-facing prompts. |
| [Pace Profiles](game-design/pace-profiles.md) | Pacing presets and expected game rhythm. |
| [Per-System ETA](game-design/per-system-eta.md) | Turn ETA display behavior for research, production, and growth. |
| [Resource Value Cards](game-design/resource-value-cards.md) | Resource presentation and valuation cards. |
| [Scoring and Outcomes](game-design/scoring-and-outcomes.md) | Scoring, victory, and end-state behavior. |
| [Turn Flow and Action Focus](game-design/turn-flow-and-action-focus.md) | Turn progression, action focus, and next-action behavior. |
| [World Wonders](game-design/world-wonders.md) | Wonder production, race resolution, effects, UI, AI, and serialization. |
| [Yield Unification](game-design/yield-unification.md) | Yield model consolidation across city, tile, and resource systems. |

### Assets And Publishing

| Document | Use It For |
| --- | --- |
| [Asset Templates](templates/README.md) | Source templates for generated or exported game art. |
| [Marketing Assets](marketing/README.md) | Store and brand collateral. |

## Maintenance Notes

- `.fvmrc` is the single Flutter SDK pin for local Make commands and GitHub
  builds; Dart must be the SDK bundled by that Flutter release. Start from
  `make bootstrap`, which resolves every committed workspace lockfile and
  ensures the matching Serverpod CLI without generating tracked code.
- Keep generated files such as `*.g.dart`, `*.freezed.dart`, localization
  output, Serverpod protocol output, and migrations in sync with their sources.
  `make generated-code-check` verifies root and `aonw_core` build-runner output,
  l10n, Serverpod output, and migrations in an isolated snapshot without
  rewriting the active checkout. It runs as part of `make ci` and CI and
  requires the matching Serverpod CLI from `make bootstrap`. When
  it reports drift, use the relevant deliberate regeneration command in
  [CONTRIBUTING.md](../CONTRIBUTING.md), review the diff, and commit it.
- Keep generated build artifacts, editor state, local environment files, and
  machine-specific output out of the repository.
- Avoid committing operating-system files, asset-export sidecars, local
  environment files, signing material, or credentials.
- Update docs when behavior, persistence, APIs, game rules, or release flows
  change.

Run `make ci` before handoff. Run `make serverpod-ops-check` before backend
deployments when Docker and the Serverpod CLI are available.
