# Changelog

## Unreleased

- No unreleased player-facing changes yet.

## 1.0.8 - 2026-06-30

- Expanded diplomacy with clearer relationship information, better proposal
  feedback, gold gifts, shared-war context, and visible reasons behind diplomatic
  reactions.
- Improved AI turn planning so computer players defend cities and important
  units more reliably, avoid wasting idle military actions, and make steadier
  strategic choices.
- Made game popups less disruptive so outcome screens, guidance, and modal
  messages no longer dim or hide the map unnecessarily.
- Improved city and production requirement labels across supported languages,
  including clearer missing-resource messages.
- Strengthened map validation to catch broken or incomplete map data before it
  can cause confusing in-game behavior.
- Added Linux release support for Steam and itch.io.

## 1.0.7 - 2026-06-28

- Prepared the repository for open-source publication.
- Added MIT license, contribution guidance, security policy, and third-party
  notice files.
- Added a project code of conduct.
- Removed local development-agent planning notes and benchmark traces from the
  tracked source tree.
- Moved store icon collateral into `docs/marketing/`.
- Scrubbed public deployment documentation and Makefile defaults so private
  infrastructure values must be supplied explicitly.
- Removed tracked iOS build-time dart-define state.
- Removed the internal Serverpod multiplayer refactor plan from `docs/`.
- Added GitHub issue and pull-request templates and a funding placeholder.
