# API session adapters

Serverpod and platform implementations of the multiplayer application ports.
Application-owned session values, failures, storage contracts, and lobby
operations live in `lib/game/application/ports`; the UI consumes those ports
and never imports generated `sp.*` types.

Consumers import application ports directly. API adapters may implement those
ports, but do not re-export them or provide compatibility aliases.

`NetworkSessionClient`, `NetworkSessionStore`, and
`ServerpodNativeSocialAuthSession` are concrete adapters and are wired only by
the Riverpod composition root in `repository_providers.dart`.
