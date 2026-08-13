# Architecture Decision Records

Architecture Decision Records (ADRs) capture decisions that must remain stable
across refactors. They explain why a boundary exists, what new code must do,
which transitional exceptions still exist, and how conformance is verified.
Runbooks describe procedures; ADRs describe constraints and ownership.

## Decision Index

| ADR | Decision | Status | Implementation |
| --- | --- | --- | --- |
| [0001](0001-map-and-state-ownership.md) | Map and state ownership | Superseded | In progress |
| [0002](0002-deterministic-game-engine.md) | Deterministic game engine | Superseded | In progress |
| [0003](0003-command-boundaries.md) | Command boundaries | Accepted | Implemented |
| [0004](0004-versioned-multiplayer-protocol.md) | Versioned multiplayer protocol | Accepted | Implemented |
| [0005](0005-immutable-deployment.md) | Immutable deployment promotion | Accepted | In progress |
| [0006](0006-transport-infrastructure.md) | Transport infrastructure ownership and traversal | Accepted | Implemented |
| [0007](0007-strategic-resource-stockpiles.md) | Strategic resource stockpiles and production allocation | Accepted | Implemented |
| [0008](0008-rust-engine-ownership-and-strangler-migration.md) | Rust engine ownership and strangler migration | Accepted | In progress |

## Status And Lifecycle

- `Proposed`: under review and not yet binding.
- `Accepted`: binding for new code and migrations.
- `Rejected`: considered but not adopted.
- `Superseded`: replaced by a later ADR that links back to it.

`Implementation` is tracked separately from decision status. An accepted ADR
can describe a target architecture while an incremental migration is still in
progress. Its migration section must name current exceptions so documentation
never implies that unfinished work is complete.

Allowed implementation values are `Planned`, `In progress`, and `Implemented`.

Create an ADR when a change affects ownership of domain state, determinism,
command semantics, persisted or network compatibility, or the deployment trust
boundary. Small implementation details that do not change those contracts
belong in code and tests instead.

Every ADR contains:

1. status, date, and implementation state;
2. context and the forces behind the decision;
3. the decision and explicit invariants;
4. consequences and rejected alternatives;
5. migration and verification requirements.

An accepted record may be amended only for implementation status/evidence,
links, or non-semantic corrections. Changing its decision, invariants, or
consequences requires a new ADR that supersedes the old one. The replacement
links back to the old record; the old record changes to `Superseded` and links
forward to its replacement. Update the index, contributor documentation,
architecture tests, and affected runbooks in the same change.
