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
