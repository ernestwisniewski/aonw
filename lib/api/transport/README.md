# API transport

Network implementations of application ports and event-streaming adapters.
This layer bridges the generic game application ports to the generated
Serverpod multiplayer client.

- `NetworkCommandTransport` sends gameplay commands to the authoritative
  server and applies the acknowledged snapshot.
- `NetworkEventLog` reads server-owned command/domain-event history. It does
  not turn exact movement execution plans and costs into renderer replay;
  coarse movement domain events remain available for activity history.
- `NetworkGameRepository` maps match list/create/load/delete calls onto
  Serverpod endpoints, including snapshot reads for bootstrap and reconnect.
- `LiveEventSubscription` owns the active Serverpod two-way match stream for
  events, match updates, snapshot resync, and command ACKs.
- `LiveWireCommandDispatcher` routes gameplay commands through the active live
  stream once it is ready, with the transient Serverpod command stream kept as
  startup fallback only.

Server-side persistence is owned by Serverpod ORM tables for matches, players,
snapshots, and events. Client-side adapters should stay behind application
ports and use the generated Serverpod endpoint and stream contracts for
multiplayer runtime state.

See [ADR 0003](../../../docs/adr/0003-command-boundaries.md) and
[ADR 0004](../../../docs/adr/0004-versioned-multiplayer-protocol.md) for the
accepted command and wire boundaries that this adapter is migrating toward.
