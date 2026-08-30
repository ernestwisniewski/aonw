# Age of New Worlds — HTML UI design sandbox

A dependency-free HTML/CSS/JavaScript mirror of the current Flutter presentation layer. It is intended for visual design work without running the game client or engine.

The package contains:

- 19 complete screen states, including the main menu, new-game flow, load/settings/manual/credits/lobby, six map/HUD states, loading/error and replay;
- 46 dialogs, popovers and transient overlays covering city management, diplomacy, empire, technology, units, tile inspection, economy, combat, multiplayer, outcomes and onboarding;
- the project’s existing Cinzel/Lato fonts, palette, gradients, borders, modal dimensions and HUD placement through references to the canonical repository assets;
- desktop, tablet, portrait mobile and landscape mobile previews;
- stable representative game data so designers can compare changes without depending on a save file;
- deep links for every view and a machine-readable source map in `view-manifest.json`.

## Run

Keep this directory at `design/html-game-ui/` inside an AoNW repository checkout, then run:

```bash
cd design/html-game-ui
python3 server.py
```

Open:

```text
http://127.0.0.1:4173/design/html-game-ui/
```

The server intentionally serves the repository root because the HTML package references canonical files from `assets/` instead of duplicating them. The downloadable ZIP therefore needs to be extracted back to `design/html-game-ui/` in the repository.

A generic repository-root server also works:

```bash
python3 -m http.server 4173
```

## Designer workflow

Use the left index to select any screen, dialog or overlay. The viewport selector switches between the reference sizes:

- Desktop: 1440 × 900
- Small desktop: 1280 × 720
- Tablet: 1024 × 768
- Mobile: 390 × 844
- Mobile landscape: 844 × 390

`Clean preview` removes the sandbox navigation. Press `Esc` to close a dialog; press it again to leave clean preview. `Ctrl/Cmd + K` focuses the view filter. `Copy link` creates a deep link containing the current screen, dialog and viewport.

Examples:

```text
#screen=game-city&modal=city-production&viewport=desktop
#screen=game-combat&modal=combat-forecast&viewport=mobile-landscape&clean=1
#screen=main-menu&viewport=mobile
```

## Files

- `index.html` — sandbox shell and shared SVG icon sprite;
- `design-tokens.css` — AoNW palette, fonts, radius and motion tokens;
- `styles/` — host, primitives, menu, routes, map, system, modal and responsive presentation rules;
- `scripts/views-core.js` — shared fixtures, primitives and helpers;
- `scripts/views-screens.js` — complete screen renderers;
- `scripts/views-modals-*.js` — city, diplomacy, technology, selection, economy and system modal renderers;
- `scripts/views-registry.js` — screen/dialog registry and public rendering API;
- `app.js` — navigation, deep linking, preview scaling and interactions;
- `view-manifest.json` — coverage and Dart-source mapping;
- `audit.mjs` — dependency-free completeness and rendering audit;
- `server.py` — local repository-root static server.

## Fidelity boundaries

The package mirrors the source-level presentation structure and canonical assets. Static HTML cannot execute Flame’s canvas renderer, Riverpod state, engine commands, gamepad focus or runtime animations. Those behaviors are represented with fixed visual states rather than reimplemented as a second game client. The fixture deliberately covers each visible state so CSS/design changes can be evaluated consistently.

When a Flutter view is added or removed, update the appropriate module under `scripts/`, the registry in `scripts/views-registry.js`, its source paths in `view-manifest.json`, and run the audit.

## Audit

```bash
node audit.mjs
```

The audit fails when a registered screen/dialog renders empty markup, produces `undefined`/`null`, lacks source mapping, has duplicate IDs, or diverges from the manifest counts.
