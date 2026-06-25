# Protocols Implementation - Serverpod

Scope: multiplayer transport in the Flutter client (`lib/api/**`) and
Serverpod server (`server/lib/src/**`).

This branch replaces the legacy REST route table and custom WebSocket stream
with generated Serverpod client calls and Serverpod realtime streams. There is
no compatibility target for the previous `/auth/*`, `/matches/*`, or
`/matches/<id>/stream` contracts.

## Current Architecture

- Auth: custom Serverpod `emailIdp` endpoint backed by
  `serverpod_auth_core_server`; account creation and login are required before
  multiplayer.
- Token refresh: Serverpod Auth Core JWT refresh endpoint.
- Lobby and match lifecycle: generated Serverpod endpoint methods on
  `multiplayer`.
- Live match sync: Serverpod stream methods with generated protocol envelopes.
- Recovery: PostgreSQL is authoritative for match metadata, snapshots, events,
  and offsets; reconnecting clients can reload current state and backlog.
- Operations: Serverpod health endpoints (`/livez`, `/readyz`, `/startupz`) and
  Serverpod Insights are the operational surface.

## Operation Map

| Area | Client adapter | Serverpod surface | Notes |
| --- | --- | --- | --- |
| Account login | `NetworkSessionClient.login` | `emailIdp.login` | Throws generated `AccountAuthException` codes. |
| Account creation | `NetworkSessionClient.createAccount` | `emailIdp.createAccount` | Creates `serverpod_auth_core_user` plus `aonw_account`. |
| Token refresh | `NetworkSessionClient.refresh` | `jwtRefresh.refreshAccessToken` | Refresh token is persisted client-side when present. |
| List/create/join/start/leave match | `NetworkSessionClient` | `multiplayer` endpoint methods | Request/response is still correct for one-shot lobby actions. |
| Snapshot/event reads | `NetworkGameRepository`, `NetworkEventLog` | `multiplayer` endpoint methods | Used for recovery and deterministic replay boundaries. |
| Live match updates | `LiveEventSubscription` | `multiplayer.connect` bidirectional stream | Stream payloads carry authoritative offsets. |
| Player commands | `LiveWireCommandDispatcher` | Active `LiveEventSubscriptionHandle.sendCommand` | Commands are sent as `MultiplayerClientMessage.command`; ACKs return as `MultiplayerServerMessage.ack`. `NetworkCommandTransport` is only a pre-live-stream fallback. |

## Stream Direction Check

Serverpod supports bidirectional stream methods, and the current multiplayer
runtime already uses that shape for live match play. `LiveEventSubscription`
keeps a long-lived generated `multiplayer.connect` stream open for match
updates and owns the outbound `StreamController<MultiplayerClientMessage>`.
`LiveWireCommandDispatcher` sends player commands through the active
`LiveEventSubscriptionHandle.sendCommand` path and waits for the matching
`MultiplayerServerMessage.ack`. If gameplay dispatch races ahead of the live
stream startup, `NetworkCommandTransport` can still open the same generated
bidirectional stream contract for a single command/ACK exchange.

Completion criteria for that decision:

- every command has a client request id or tick for idempotent retry;
- server persists accepted command, event offset, and snapshot before broadcast;
- clients deduplicate stream events and command ACKs by offset;
- reconnect uses last seen offset and receives backlog plus latest snapshot
  when needed;
- two clients converge to the same state after backgrounding, browser tab
  suspension, app restart, or stream reconnect.

## Removed Legacy Surface

- `ApiHttpClient`, custom TLS pinning, and custom WebSocket client.
- Legacy anonymous session store.
- Legacy REST auth routes and custom JWT/password services.
- Legacy REST match routes and custom WebSocket broadcaster.
- Tests that asserted deleted REST/WebSocket contracts.

## Follow-Up

- Keep running the Serverpod Insights runbook for local and staging checks
  before multiplayer rollout decisions.
- Keep this document aligned with generated protocol names after every
  Serverpod model or endpoint rename.
