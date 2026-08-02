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
created in the session repository provider composition root. Compatibility
files in `lib/api/session` and `lib/api/transport` may re-export these contracts
but must not become their owner again.
