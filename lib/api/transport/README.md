# API transport

Network implementations of application ports and event-streaming adapters.
This layer bridges the generic game application ports to the generated
Serverpod multiplayer client.

- `NetworkCommandTransport` sends gameplay commands to the authoritative
  server and applies the acknowledged snapshot.
- `NetworkEventLog` reads server-owned command/event history.
- `NetworkSnapshotStore` reads the latest server snapshot for reconnect and
  bootstrap flows.
- `NetworkGameRepository` maps match list/create/load/delete calls onto
  Serverpod endpoints.
- `LiveEventSubscription` owns the active Serverpod two-way match stream for
  events, match updates, snapshot resync, and command ACKs.
- `LiveWireCommandDispatcher` routes gameplay commands through the active live
  stream once it is ready, with the transient Serverpod command stream kept as
  startup fallback only.

Server-side persistence is owned by Serverpod ORM tables for matches, players,
snapshots, and events. Client-side adapters should not depend on legacy REST
routes or custom WebSocket channels for multiplayer runtime state.
