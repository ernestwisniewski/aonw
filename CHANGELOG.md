# Changelog

## Unreleased

- Improved online session recovery so reconnects and multiplayer actions use
  the latest credentials after an access token expires.
- Made multiplayer sign-out more reliable when a session refresh or network
  request is already in progress.
- Made long multiplayer histories load across multiple pages so established
  matches can resume and replay beyond the first history page.
- Improved matchmaking and multiplayer match-list stability under larger
  queues by bounding how much stale-lobby and discovery work one request does.

## 1.1.4 - 2026-07-08

- Improved multiplayer synchronization so live matches recover more reliably
  after reconnects, delayed updates, duplicate messages, or stale snapshots.
- Preserved visible multiplayer action effects during sync updates so opponent
  moves, attacks, and other turn events are easier to follow.
- Hardened turn handling around timeouts, resignations, leaving matches, and
  reconnecting players so stalled multiplayer games are less likely to get
  stuck.
- Improved matchmaking and connection cleanup for stale lobbies and active
  multiplayer sessions.
- Expanded multiplayer smoke tests and protocol coverage to reduce regressions
  in online matches.

## 1.1.3 - 2026-07-08

- Added the first version of world wonders, including unique wonder projects,
  requirements, completion effects, map-ready artwork, and localized names.
- Expanded city production with dedicated wonder details, clearer production
  sections, and better explanations for why buildings, units, or wonders are
  available or locked.
- Improved technology details so unlocks, wonder requirements, and future
  production options are easier to understand before choosing research.
- Improved AI production planning so computer players can reason about wonder
  opportunities alongside units, buildings, and economy needs.
- Made saved games and multiplayer command handling preserve more production
  and wonder state across turns.
- Added clearer event messages for production, rush actions, wonder completion,
  and visibility-limited activity updates.
- Improved asset loading for wonder artwork and kept release packaging aligned
  with the latest public download builds.

## 1.1.2 - 2026-07-07

- Expanded the civilization roster to 24 playable countries, each with
  localized country and ruler names.
- Added civilization-specific city names and AI tendencies so new matches feel
  less uniform.
- Improved new-game setup around choosing a civilization and reading the match
  plan before starting.
- Expanded gamepad options with persistent settings for input enablement,
  deadzone, camera sensitivity, inverted camera Y, and button/axis bindings.
- Improved gamepad navigation across diplomacy popups, technology discoveries,
  city production, first-turn guidance, HUD actions, and end-turn flow.
- Made first-turn guidance clearer so founding the capital, choosing research,
  assigning production, and clearing pending actions are easier to follow.

## 1.1.1 - 2026-07-05

- Fixed controller targeting so unit move mode stays active while moving the
  hex cursor and confirming a destination.
- Improved gamepad navigation across the HUD, city production, technology tree,
  main menu, and load-game cards.
- Improved controller focus feedback so selected panels, rows, and cards are
  easier to follow after gamepad input.
- Prevented held controller input from accidentally carrying into newly opened
  panels.
- Fixed a turn-start panel flicker that could appear while the game state was
  updating.

## 1.1.0 - 2026-07-05

- Added gamepad controls for moving around the map, selecting tiles, confirming
  primary actions, opening key panels, and playing more comfortably from a
  couch or handheld-style setup.
- Added in-game manual guidance for gamepad controls across supported
  languages.
- Improved HUD economy breakdown performance so gold, science, and city
  economy details are calculated more efficiently when opened.
- Improved combat fog handling so combat updates reveal only the affected
  visibility changes instead of doing unnecessary full-map work.
- Tightened city production and ruleset calculations behind the HUD so economy
  forecasts stay clearer and cheaper to update.

## 1.0.9 - 2026-07-04

- Added the first version of empire stability, cohesion, and war-weariness
  systems, including clearer city and empire readouts in the HUD.
- Deepened combat with point-blank ranged retaliation, counter-battery fire,
  tuned damage variance, and a more distinct rifleman battlefield role.
- Improved combat previews and battle notifications so retaliation, modifiers,
  and combat outcomes are easier to understand before and after an attack.
- Improved AI tactical choices around retaliation, city defense, expansion, and
  long-term stability so computer players behave more consistently.
- Made multiplayer and saved-game snapshots preserve more empire state,
  including stability and war-weariness data.
- Improved HUD performance by deferring detailed resource breakdown work until
  it is actually opened.
- Reduced map and unit rendering overhead with incremental fog updates, cached
  unit badge text, and lighter preferred unit sprite atlases.
- Tightened unit rules, production data, and upkeep handling so unit behavior is
  more consistent across gameplay, AI planning, and UI previews.

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
