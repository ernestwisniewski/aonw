# Multiplayer application ports

The multiplayer boundary is owned by the game application layer:

- `MultiplayerSessionGateway` covers authentication and lobby operations.
- `NetworkSessionStorePort` covers durable credentials and active-match
  metadata.
- `LiveMultiplayerEvents` and `WireCommandDispatcher` cover live events and
  command delivery.
- `NativeSocialAuthSession` keeps the generated social-auth client opaque.
- `MultiplayerFailure` is the stable error contract exposed to presentation.

Concrete Serverpod and platform implementations live under `lib/api` and are
created in the session repository provider composition root. Adapter libraries
must not re-export these contracts: callers import the application-owned port
and the concrete adapter separately when they compose the runtime.

## Planned Local Engine Seam

The [Rust Engine Migration Plan](../../../../docs/rust-engine-migration.md)
introduces an application-owned `LocalEnginePort` beneath the existing
`LocalCommandTransport`. During migration the local transport will select a
Dart, Rust native, or Rust WASM engine; an internal differential decorator may
run a shadow comparison. This seam must not route individual command families
to different primary engines inside one live session, and its DTOs must not
expose Rust FFI handles or Dart domain implementation types to presentation.

The existing composition root continues to choose `LocalCommandTransport` or
`NetworkCommandTransport`. Remote multiplayer remains on `CommandTransport`,
`WireCommandDispatcher`, and `MultiplayerSessionGateway`; it does not become an
engine backend. The target recipient replica must not depend on canonical
`DomainState`.

Today Serverpod already sends a recipient-scoped projection, but
`NetworkGameRepository` and `SnapshotCodec` still decode it through the shared
`CanonicalGameSnapshot` compatibility envelope. Removing that nominal-type
exception belongs to the remote-replica migration; it is not a reason to put
authoritative rules in the Flutter network adapter.

This is a target boundary, not a claim that the Rust backend is currently
implemented. Add the concrete port and adapters together with their first
executable slice and architecture tests.
