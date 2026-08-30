# HTML presentation parity matrix

This matrix keeps the design workbench aligned with the active Flutter presentation surface. “Covered” means the screen/state, information hierarchy, primary actions and responsive layout are represented in HTML. It does not mean that the HTML package owns game rules.

## Top-level screens

| Flutter presentation surface | HTML state | Coverage |
| --- | --- | --- |
| `features/main_menu/presentation/main_menu_screen.dart` | `main-menu` | Covered: continue, new game, multiplayer, replay, help, settings |
| `features/local_game/presentation/new_game_screen.dart` | `new-game` | Covered: scenario, countries, AI difficulty/persona, fog, start/cancel |
| `features/map/presentation/` | `map` | Covered: viewport, HUD, selection, actions, layers, turn state |
| `features/settings/presentation/settings_screen.dart` | `settings` | Covered: volume, camera sensitivity, reduced motion, high contrast, reset |
| `features/help/presentation/help_screen.dart` | `help` | Covered: objective, map, development, turns, save/replay, onboarding action |
| `features/onboarding/presentation/onboarding_screen.dart` | `onboarding` | Covered: four steps, progress, previous/next/finish/skip |
| `features/multiplayer/presentation/multiplayer_screen.dart` | `multiplayer-auth`, `multiplayer-lobby`, `multiplayer-match` | Covered: auth, account mode, lobby, create/join/refresh, match submission/reconnect-shaped state |
| `features/replay/presentation/replay_screen.dart` | `replay` | Covered: map viewport, back, play/pause, seek, progress, speed |

## Map modal and overlay surfaces

| Feature area | HTML modal | Important represented states |
| --- | --- | --- |
| Cities | `city` | yields, population, growth, housing, loyalty, worked territory, buildings |
| Production | `production` | queue, progress, units/buildings/wonders catalogue, confirmation |
| Research | `research` | current research, era progress, researched/available/locked nodes and dependencies |
| Diplomacy | `diplomacy` | civilization list, leader, relationship, agreements, deal/gift/war actions |
| Unit actions | `unit` | unit identity, stats, health, movement, attack, fortify, army and skip actions |
| Armies | `army` | formation, component units, power, supply and army orders |
| Workers | `worker` | only valid improvements, yields, duration and selected target |
| Combat | `combat` | attacker/defender, health, modifiers, prediction and confirmation |
| Objectives | `objectives` | objective progress, victory categories and score comparison |
| Artifacts | `artifact` | carrier, carry cost, rewards, bring-to-city and drop actions |
| Logistics | `logistics` | strategic stock, per-turn flow, demand, connections and exposed supply |
| Events | `event` | illustrated event, required choice and explicit consequences |
| Pause/session | `pause` | resume, save, load, settings, help, exit |
| Save/load | `save`, `load` | named slots, autosave/manual metadata, selection and destructive warning shape |
| Turn handoff | `end-turn`, `turn-processing` | unresolved-decision warning, ordered AI resolution and blocked input |
| Progress feedback | `tech-unlocked`, `city-founded` | unlock summary, next action, city name and founding yields |
| Diplomacy confirmation | `declare-war` | cancelled agreements, displaced units and reputation consequences |
| Developer tools | `developer` | selected hex payload, layer state and deterministic world diagnostics |

## Map acceptance checklist

- [x] Exactly 28 columns × 17 rows = **476 hexes**.
- [x] Terrain is deterministic for a displayed seed.
- [x] Regeneration changes terrain composition, cities, civilization assignment, territory, resources and units.
- [x] Six cities are present and territories are irregular rather than perfect circles.
- [x] Multiple land units are present; a naval unit is added when a coastal spawn can be found.
- [x] Selecting a unit and then a destination computes an A* route.
- [x] Land/naval passability and terrain movement costs are respected.
- [x] Roads reduce movement cost.
- [x] Route preview is curved, white and unevenly dashed, with endpoint markers and total cost.
- [x] Fog, territory and resource layers can be toggled independently.
- [x] Pointer drag pans; wheel and buttons zoom; reset restores the reference framing.
- [x] City click opens the matching city state; HUD actions open their corresponding modals.
- [x] Desktop, tablet and mobile frames are included without separate builds.
- [x] Workbench chrome can be hidden for clean screenshots.

## Intentional boundaries

The following are intentionally mocked as presentation state rather than duplicated domain logic:

- authoritative commands and validation,
- AI decisions and deterministic turn execution,
- save serialization and replay reconstruction,
- account authentication and network synchronization,
- combat resolution and city production completion,
- fog visibility calculated from the real match snapshot.

Those remain owned by the engine and adapters. The HTML package is safe to change freely during visual design work because it cannot alter production game state.
