# API session adapters

Serverpod and platform implementations of the multiplayer application ports.
Application-owned session values, failures, storage contracts, and lobby
operations live in `lib/game/application/ports`; the UI consumes those ports
and never imports generated `sp.*` types.

Compatibility entrypoints such as `auth_token.dart`, `network_session.dart`,
and `connection_state.dart` re-export their application-owned replacements so
code outside the game layers can migrate without duplicating state models.

`NetworkSessionClient`, `NetworkSessionStore`, and
`ServerpodNativeSocialAuthSession` are concrete adapters and are wired only by
the Riverpod composition root in `repository_providers.dart`.
