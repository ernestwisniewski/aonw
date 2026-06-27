# Multiplayer Protocol

Scope: multiplayer transport in the Flutter client (`lib/api/**`), generated
Serverpod client package (`packages/aonw_server_client/**`), shared wire models
(`packages/aonw_core/lib/protocol/**`), and Serverpod server
(`server/lib/src/**`).

This document describes the current Serverpod multiplayer protocol used by the
app. One-shot lobby and recovery operations use generated Serverpod endpoint
methods. Live matches use Serverpod bidirectional streams with generated
protocol envelopes and shared `aonw_core` wire DTOs.

## Architecture

- Auth: custom Serverpod `emailIdp` endpoint backed by
  `serverpod_auth_core_server`; account creation and login are required before
  multiplayer.
- Token refresh: Serverpod Auth Core JWT refresh endpoint.
- Lobby and match lifecycle: generated Serverpod endpoint methods on
  `multiplayer`.
- Shared wire DTOs: `packages/aonw_core/lib/protocol/**` owns command,
  snapshot, event, match, player, and protocol-version payloads.
- Live match sync: Serverpod stream methods with generated protocol envelopes.
- Recovery: PostgreSQL is authoritative for match metadata, snapshots, events,
  and offsets; reconnecting clients can reload current state and backlog.
- Operations: Serverpod health endpoints (`/livez`, `/readyz`, `/startupz`) and
  Serverpod Insights are the operational surface.

## Protocol Surface

| Area | Client adapter | Serverpod surface | Notes |
| --- | --- | --- | --- |
| Account login | `NetworkSessionClient.login` | `emailIdp.login` | Throws generated `AccountAuthException` codes. |
| Account creation | `NetworkSessionClient.createAccount` | `emailIdp.createAccount` | Creates `serverpod_auth_core_user` plus `aonw_account`. |
| Token refresh | `NetworkSessionClient.refresh` | `jwtRefresh.refreshAccessToken` | Refresh token is persisted client-side when present. |
| List/create/join/start/leave match | `NetworkSessionClient` | `multiplayer` endpoint methods | Request/response operations for lobby actions. |
| Snapshot/event reads | `NetworkGameRepository`, `NetworkEventLog` | `multiplayer` endpoint methods | Used for recovery and deterministic replay boundaries. |
| Live match updates | `LiveEventSubscription` | `multiplayer.connect` bidirectional stream | Stream payloads carry authoritative offsets. |
| Player commands | `LiveWireCommandDispatcher` | Active `LiveEventSubscriptionHandle.sendCommand` | Commands are sent as `MultiplayerClientMessage.command`; ACKs return as `MultiplayerServerMessage.ack`. `NetworkCommandTransport` is a startup fallback before the live stream is ready. |

## Command And Stream Flow

Serverpod supports bidirectional stream methods, and live match play uses that
shape. `LiveEventSubscription` keeps a long-lived generated
`multiplayer.connect` stream open for match updates and owns the outbound
`StreamController<MultiplayerClientMessage>`.

`LiveWireCommandDispatcher` sends player commands through the active
`LiveEventSubscriptionHandle.sendCommand` path and waits for the matching
`MultiplayerServerMessage.ack`. If gameplay dispatch races ahead of live stream
startup, `NetworkCommandTransport` can open the same generated bidirectional
stream contract for a single command/ACK exchange.

The runtime keeps these synchronization invariants:

- every command has a client request id or tick for idempotent retry;
- server persists accepted command, event offset, and snapshot before broadcast;
- clients deduplicate stream events and command ACKs by offset;
- reconnect uses last seen offset and receives backlog plus latest snapshot
  when needed;
- two clients converge to the same state after backgrounding, browser tab
  suspension, app restart, or stream reconnect.

## Protocol Versioning

All wire payloads carry `v: 1` and are validated by `kProtocolVersion`.

Use this path for the first coordinated protocol bump:

1. Pause new multiplayer match creation during the deploy window.
2. Update the shared wire models, bump `kProtocolVersion`, and regenerate the
   Serverpod protocol output in the same change.
3. Update the Flutter client, generated Serverpod client package, and Serverpod
   server together so they read and write the same version.
4. Clear or migrate persisted match snapshots/events that still carry the
   earlier version when sessions requiring replay exist.
5. Re-run command retry, reconnect, generated client, and server tests before
   enabling matchmaking again.

Once long-lived public multiplayer sessions are common, revisit this section
before a protocol bump. At that point the project may need a temporary
dual-version reader, replay migration, or forced client update policy.

## Maintenance

- Keep this document aligned with generated protocol names after every
  Serverpod model or endpoint rename.
- Keep `packages/aonw_core/lib/protocol/**`, `server/lib/src/generated/**`, and
  `packages/aonw_server_client/lib/src/protocol/**` in sync whenever wire models
  or endpoint YAML changes.
- Keep running the Serverpod Insights runbook for local and staging checks
  before multiplayer rollout decisions.
