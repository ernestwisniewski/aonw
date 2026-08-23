# AoNW Flutter Client

This is the standalone successor presentation client. It consumes the strict
Rust client protocol through `package:aonw_rust_client`; the hook setting in
this package always builds the native Rust backend for the host target. There
is no import of the legacy root application, `aonw_core`, or per-command Dart
fallback.

The first vertical slice renders the canonical `aonw2_starter` map with
`CustomPainter`/Canvas, the generated reference bundle, grid, hover, selection,
pan, and zoom. `GameSessionState` exposes loading, ready, and typed failure
states. Its ready state composes the recipient-safe Rust view with local map
interaction while keeping both distinct.

Flame `1.38.0` is the pinned target for the viewport migration and
`flame_test 2.3.0` is the matching component-test toolchain. Until the existing
gamepad plugin provides a qualified Swift Package Manager integration, macOS
intentionally stays on the committed CocoaPods path. `Podfile.lock` pins
`gamepads_darwin 0.1.1`, and the architecture guard rejects accidental removal
of that integration; an upgrade requires a device smoke test with real gamepad
input.

Composition lives under `lib/app/`; widgets do not construct FFI sessions or
repositories. `AppComposition.production()` is the only production composition
root: it creates one `RustMapRepository`, one owning `MapController`, and one
`AonwApp`. The root widget disposes its controller when it leaves the tree or
is replaced; the controller closes the retained Rust session idempotently. The
test constructor accepts only the application `MapRepository` port, so no DI
container or service locator is needed.

## Developer module map

| Module | Responsibility and entry points | Dependency rule |
| --- | --- | --- |
| `lib/app` | Bootstrap, production composition, routing, lifecycle and process errors. Start at `bootstrap/run_aonw_app.dart`; wire adapters only in `composition/app_composition.dart`. | May compose features and infrastructure. Features never import `app`. |
| `lib/design_system` | Brand tokens and accessible shared widgets. | Has no feature or Rust transport dependency. Feature-specific visuals stay in the feature. |
| `lib/features/map` | Map/session ports, `GameSessionState`, recipient and pending-action read models, Rust adapter, interaction controller and rendering. Enter through `application/map_controller.dart`; the state contract lives beside it in `application/game_session_state.dart`. | Application owns use cases, infrastructure maps the Rust protocol, presentation never evaluates game rules. Session status is represented by closed state variants; recipient data and local interaction remain separate. |
| `lib/features/settings` | Client-only preferences and their persistence. | Settings contain no gameplay state and do not depend on the map feature. |
| `lib/features/turns` | Immutable turn-presentation queue and the accessible turn banner. Start at `application/turn_presentation_queue.dart`; presentation is in `presentation/turn_banner.dart`. | Consumes only authoritative turn numbers from recipient snapshots. It may order and animate presentations, but never advances or reduces a turn. |
| `lib/game` | Flame-only viewport composition: `AonwFlameGame`, one `AonwWorld`, one camera and the typed `FlameSceneSink`. | Receives immutable presentation snapshots only. It cannot import repositories, infrastructure, FFI or wire DTOs. |
| `lib/l10n` | ARB catalogs, generated typed strings and locale helpers. | Edit ARB sources; never edit generated localization files manually. |

When adding a module, extend this table with its owner, entry point and allowed
dependencies. Keep implementation details in code and verification commands in
this README.

`AonwRouter` owns the small typed route table on top of Flutter's Navigator.
The current `/` route builds the map feature; unknown locations fail closed to
an accessible diagnostic page. `AonwApp` owns theme and lifecycle but does not
construct feature pages directly. New screens extend the route enum and router
without adding navigation decisions to feature widgets.

The map route owns exactly one `AonwFlameGame` instance for its lifetime. FM1
mounts its transparent, clipped `GameWidget` above the unchanged Canvas oracle;
terrain and input do not move to Flame before their later checkpoints. Flutter
keeps loading/error recovery, focus and semantics. Route and application
visibility are combined before changing the Flame lifecycle, while the empty
turn-based world keeps its continuous loop paused. Covering the map route does
not close the Rust session. Removing the application viewport disposes Flame
caches and its presentation snapshot; the application controller independently
closes the session when its owner is torn down.

FM2 keeps three coarse Flame components in fixed priority order: batched
terrain, decoded reference pages and one combined grid path. Their shared cache
is keyed by map id, content hash and dimensions; interaction-only snapshots and
reference visibility changes reuse the terrain/grid paths. Reference images are
owned by Flame's image cache and released with the world. The temporary
`renderStaticLayers` constructor switch is enabled only by migration goldens;
the shipped viewport still displays the Canvas oracle until FM5 removes both
the switch and the old renderer in one cutover.

FM3 gives Flame one bounded `CameraComponent`/`Viewfinder` backed by the same
framework-neutral fit and screen/world transform used by the Canvas oracle.
A single viewport-sized input surface maps Flame tap, hover, drag, scale and
scroll callbacks to typed intents; pointer bursts are coalesced into one camera
mutation per rendered frame and hex picking remains one geometry lookup, never
a hitbox per tile. That surface is installed only when a shadow/test intent
sink is injected. The production `GameWidget` therefore registers no pointer
callbacks and cannot intercept the still-authoritative `InteractiveViewer`
before the FM5 cutover; there is no user-facing renderer or input flag.

Bootstrap installs one typed process error boundary. Flutter framework errors
and unhandled asynchronous platform errors are classified separately and sent
to an `AppErrorReporter`; the default reporter writes developer diagnostics
only. Future crash reporting should implement that port without exposing game
state or teaching feature controllers about a telemetry SDK. The boundary can
be installed and restored independently in tests.

Client telemetry is deliberately closed and domain-free. The sink accepts only
the predefined `ClientTelemetryEvent` enum: app start, suspend/resume, framework
error and asynchronous error. It cannot accept attributes, exception text,
map identifiers, coordinates, player identifiers or game state. Production
currently uses a developer log sink; a remote sink may replace it only behind
the same allowlisted port.

The design system keeps brand color, spacing, radii and minimum interaction
sizes in small framework-level token groups. Shared panel, message and progress
components provide consistent theming and explicit semantics while remaining
independent of game features. Feature-specific colors stay with the map
presentation layer in `MapPalette`.

Flutter's generated localization boundary owns all app-shell and map-workflow
copy. English is the canonical ARB catalog and Polish is a fully generated
locale. Widgets consume typed placeholder methods, while `AonwApp` registers
the generated delegates and follows the platform locale by default.

Map input converges on one presentation command model. Pointer picking,
keyboard arrows/WASD with Enter/Escape, and normalized gamepad D-pad with
A/B/Y all drive the same local cursor, selection and reference actions. The
production composition root owns the gamepad adapter and closes it with the
retained Rust-backed map repository. Linux uses the repository's hardened
gamepads adapter; no input path evaluates game rules. `AonwApp` pauses
lifecycle-aware gamepad input whenever the application is not resumed and
reenables it on resume. Losing focus never tears down the Rust session.

The map feature opens the starter map and scenario on one retained Rust
backend. Its `MapScene` keeps the shared static `MapView` separate from the
recipient-safe player snapshot, so fog-filtered units never become authored
map content. Closing the controller closes that backend session; later queries
and commands reuse the same session instead of selecting a transport per
operation.

Recipient snapshots carry the authoritative positive turn number. The client
shows it through an immutable presentation queue that ignores duplicate or
older snapshots and serializes newer banners. Completing an animation only
advances that local queue; it never changes the game turn. Reduced-motion mode
removes the transition while preserving the live-region announcement.

The same recipient snapshot carries at most one closed `PendingActionView`.
Flutter validates its identifiers and coordinates at the adapter boundary, but
does not decide whether an action is required or legal. `GameSessionState`
exposes the value for the action deck; clearing or replacing it always comes
from a refreshed Rust snapshot.

Selecting a controlled unit requests its reachable tiles from Rust. Selecting
a highlighted destination requests the versioned route plan, and the client
dispatches `moveUnit` only after an explicit confirmation. The overlay and
panel display returned costs; they do not calculate movement legality. After
an accepted command the repository fetches a fresh recipient snapshot instead
of reducing authoritative state in Dart. Rejections use a closed client-owned
enum mapped exhaustively from the Rust wire enum. Unknown codes fail closed;
the shared code fixture and native stale-revision test keep Flutter and Godot
in parity.

Run from the repository root:

    make successor-flutter-check
    make map-stage-1-check
    make successor-flutter-device-test
    make successor-flutter-fm0-baseline
    make successor-flutter-run

`map-stage-1-check` exports the Rust-backed semantic map probe to a temporary
directory and compares it with Godot. It does not update this client's visual
goldens.

The committed starter assets are generated by
`tool/assets/compile/starter_map_bundle.dart` for both successor clients. The
canonical map document remains in `content/maps/`, and shared odd-q geometry
evidence remains in `aonw_tests/fixtures/geometry/`.

This client owns presentation, input, camera, interaction state, accessibility,
and client-side animation. Rules for movement, combat, economy, turns, AI,
save, and replay remain exclusively in Rust.
