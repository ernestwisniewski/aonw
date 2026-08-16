# Architecture decision records

ADRs explain why a long-lived boundary exists and what new code must preserve. Runbooks describe procedures; ADRs describe decisions.

## Index

| ADR | Decision | Status | Implementation |
| --- | --- | --- | --- |
| [0001](0001-map-and-state-ownership.md) | Map and state ownership | Superseded by 0008 | In progress |
| [0002](0002-deterministic-game-engine.md) | Deterministic game engine | Superseded by 0008 | In progress |
| [0003](0003-command-boundaries.md) | Command boundaries | Accepted | Implemented |
| [0004](0004-versioned-multiplayer-protocol.md) | Versioned multiplayer protocol | Accepted | Implemented |
| [0005](0005-immutable-deployment.md) | Immutable deployment promotion | Accepted | In progress |
| [0006](0006-transport-infrastructure.md) | Transport infrastructure and traversal | Accepted | Implemented |
| [0007](0007-strategic-resource-stockpiles.md) | Strategic stockpiles and production allocation | Accepted | Implemented |
| [0008](0008-rust-engine-ownership-and-strangler-migration.md) | Rust engine ownership and strangler migration | Accepted | In progress |

## Status

- **Proposed** — under review and not binding.
- **Accepted** — binding for new code.
- **Rejected** — considered but not adopted.
- **Superseded** — replaced by a later ADR.

Implementation is tracked separately as `Planned`, `In progress`, or `Implemented`.

Create an ADR when a change affects authoritative state ownership, determinism, command semantics, persisted or network compatibility, or the deployment trust boundary. A local implementation detail belongs in code and tests instead.

An accepted decision is not rewritten when the architecture changes. Create a new ADR, link both records, mark the old one superseded, and update architecture guards and runbooks in the same change.
