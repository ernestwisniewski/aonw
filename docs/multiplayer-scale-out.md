# Multiplayer scale-out

The current safe operating mode is one active API/maintenance instance for live multiplayer.

PostgreSQL stores authoritative state, but the application subscriber registry is process-local. Redis supports Serverpod infrastructure; the game does not yet publish committed match events through a shared application event bus. Two unrestricted active instances can therefore persist correct state while missing each other's live broadcasts.

## Current contract

- Run one active multiplayer mutation and maintenance instance.
- Keep the API private behind the reverse proxy.
- Preserve WebSocket upgrade headers.
- Route traffic only to instances whose `/readyz` returns `200`.
- Use `/livez` for process health and `/startupz` for startup completion.
- Rely on recipient-projected snapshot recovery after reconnect, not on canonical event replay in the client.

Load-balancer affinity alone is not enough. A durable maintenance job can execute on a different process and commit a lifecycle change that the owning process cannot broadcast.

## Presence during restart

Lobby presence is backed by PostgreSQL leases, not only by the in-process stream count. Losing a process does not prove that every member left. Reconnecting clients can renew their lease within the normal recovery window; maintenance handles leases that really expire.

## Deployment drain

Graceful drain is a target automation contract, not a fully proven property of the current Compose recreate path.

A correct drain should:

1. start and verify the replacement outside live mutation traffic;
2. mark the old instance unready and stop accepting new mutations;
3. settle accepted calls, close streams, and establish one new mutation target;
4. let clients reconnect and install the latest projected snapshot;
5. terminate the old instance only after cutover.

Do not run both old and new instances as active command targets during the handoff.

## Exit criteria for active-active

Before lifting the single-instance restriction, implement and test a shared committed event bus:

1. persist the command event and snapshot in PostgreSQL;
2. publish the committed offset after the transaction succeeds;
3. have each instance load the event from PostgreSQL by offset;
4. broadcast only recipient-projected data;
5. prove reconnect, maintenance, duplicate delivery, process loss, and drain behavior end to end.

The related deployment target is recorded in [ADR 0005](adr/0005-immutable-deployment.md).
