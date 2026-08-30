# Age of New Worlds — HTML design workbench

A dependency-free HTML/CSS/JavaScript port of the current game presentation surface. It exists for visual design work without starting Flutter, Flame, the Rust engine, a database, or the multiplayer server.

## Run

From the repository root:

```bash
python3 -m http.server 4173
```

Open `http://localhost:4173/design/html-game-workbench/`.

The files also work when `index.html` is opened directly, because the package has no module imports and no external runtime dependencies.

## What is included

### Application screens

- Main menu, including continue/new game/multiplayer/replay/help/settings actions.
- Local new-game setup with scenario, countries, AI difficulty/persona and fog-of-war state.
- Settings with audio, camera and accessibility states.
- Help and the four-step onboarding flow.
- Multiplayer authentication, lobby and active-match states.
- Replay viewport and playback controls.
- Full game map and HUD.

### Map and interaction states

- A deterministic 28 × 17 map: **476 interactive hexes**.
- Seeded terrain, resources and fog-of-war visibility.
- Six randomized civilizations/cities with irregular seeded territory.
- Seeded units, including workers, scouts, military units and a naval unit where a coast is available.
- Unit selection followed by target-hex selection.
- A* pathfinding with land/naval restrictions, terrain movement costs and road discounts.
- Rounded, white, dashed route preview with start/end markers and total movement cost.
- Pointer panning, wheel zoom, layer toggles, reset camera and minimap.
- City markers, territory tint, resources, unit action bar and end-turn state.

### Modal and overlay inventory

City overview, production queue, technology tree, diplomacy, unit details, army management, worker improvements, combat preview, objectives/victory, world artifacts, resources/logistics, world events, pause, save, load, end-turn confirmation, researched technology, founded city, AI turn processing, declaration of war and map diagnostics.

## Designer controls

- Use the left rail or top selectors to jump directly to any screen or modal.
- Switch between desktop, tablet and mobile frames.
- `↻ Świat` changes the deterministic seed and regenerates cities, territories, resources and units.
- On the map, select a unit and then a destination to preview the route.
- `G` toggles an 8 px design grid.
- `H` hides or restores workbench chrome for a clean full-screen capture.
- `Esc` closes the current modal.

## Scope and parity rule

The workbench mirrors the **presentation contract** of the Flutter client: information hierarchy, labels, controls, screen states, modal states and responsive composition. It is deliberately not a second game implementation. Commands only change local design state; authoritative rules, persistence, networking, AI and turn resolution remain in the Rust engine/server/client adapters.

When a Flutter presentation state changes, update both:

1. the corresponding HTML renderer in `app.js`, and
2. the matching row in `PARITY.md`.

The randomized world is reproducible by seed so designers can discuss the same composition and routes without checking fixture data into the engine.

## Files

- `index.html` — workbench shell and design navigation.
- `styles.css` — tokens, responsive game styling, map styling and modal layouts.
- `app.js` — screen renderers, seeded world model, SVG renderer, A* pathfinding and interactions.
- `PARITY.md` — source-to-workbench coverage matrix and acceptance checklist.
