"use strict";

const renderMainMenu = (developerOpen = false) => `
  <section class="game-screen main-menu">
    <div class="menu-background"></div>
    <aside class="menu-panel">
      <img class="menu-logo" src="${ASSET}/runtime/ui/logo.webp" alt="Age of New Worlds" />
      ${goldDivider("menu-logo-divider")}
      <p class="menu-synopsis">Build an empire across a living hex world. Explore, expand, research and lead your civilization through the ages.</p>
      <div class="menu-buttons">
        ${menuButton({ iconName: "plus", title: "New game", subtitle: "Choose a world and begin your campaign", view: "new-game-plan", primary: true })}
        ${menuButton({ iconName: "folder", title: "Load game", view: "load-game" })}
        ${menuButton({ iconName: "settings", title: "Settings", subtitle: "Audio, display, gameplay and controls", view: "options-screen" })}
        ${menuButton({ iconName: "code", title: "Developer", subtitle: "Map, replay and diagnostics tools", view: developerOpen ? "main-menu" : "main-menu-developer", chevron: false })}
        ${developerOpen ? `<div class="menu-info-card" style="margin:-2px 0 1px 47px;padding:9px 10px">
          <div style="display:grid;gap:6px">
            <button class="dialogue-option" type="button" data-view="replay">Replay viewer</button>
            <button class="dialogue-option" type="button" data-view="game-map">Map renderer preview</button>
            <button class="dialogue-option" type="button" data-modal="first-turn-coachmark">Coachmark preview</button>
          </div>
        </div>` : ""}
        ${menuButton({ iconName: "exit", title: "Exit", chevron: false })}
      </div>
      <div class="menu-bottom-links">
        <button type="button" data-view="manual">${icon("book")}<span>Manual</span></button>
        <button type="button" data-view="credits">${icon("star")}<span>Credits</span></button>
        <button type="button" data-toast="Feedback link copied">${icon("chat")}<span>Feedback</span></button>
      </div>
    </aside>
    <span class="menu-version">v1.1.17 · dev</span>
    <div class="menu-info-column">
      <section class="menu-info-card">
        <div class="game-eyebrow">What’s new</div>
        ${goldDivider("")}
        <p>Shared Rust engine foundation, Godot map workbench, deterministic runtime assets and improved map feedback.</p>
      </section>
      <section class="menu-info-card">
        <div class="game-eyebrow">Open source</div>
        <p>Game source, engine contracts and documentation are available from the project repository.</p>
      </section>
    </div>
  </section>`;

const renderNewGamePlan = () => routeFrame({
  title: "New game",
  activeStep: "plan",
  body: `
    <div class="route-hero">
      <span class="game-eyebrow">Choose how the world will be ruled</span>
      <h1 class="game-title">Plan your campaign</h1>
      <p>Select a game mode, your civilization and the pace of the campaign. You can review every choice before the map is created.</p>
    </div>
    <div class="new-game-mode-grid">
      <article class="mode-card is-selected" data-selectable>
        <div class="mode-card__icon">${icon("crown", "ui-icon--lg")}</div>
        <h2>Single player</h2>
        <p>Lead one civilization against adaptive AI opponents in a complete turn-based campaign.</p>
        <div class="mode-card__meta">${chip("1 human")}${chip("3 AI")}${chip("90 turns")}</div>
      </article>
      <article class="mode-card" data-selectable>
        <div class="mode-card__icon">${icon("hand", "ui-icon--lg")}</div>
        <h2>Hot seat</h2>
        <p>Pass the device between local players while the game protects each private turn.</p>
        <div class="mode-card__meta">${chip("2–4 players")}${chip("Local")}</div>
      </article>
      <article class="mode-card" data-selectable>
        <div class="mode-card__icon">${icon("globe", "ui-icon--lg")}</div>
        <h2>Multiplayer</h2>
        <p>Create or join a persistent match designed for long-running campaigns across devices.</p>
        <div class="mode-card__meta">${chip("2–4 players")}${chip("Online")}</div>
      </article>
    </div>
    <div class="setup-grid" style="margin-top:18px">
      <section class="panel-surface setup-panel">
        ${sectionTitle("Civilization")}
        <div class="country-grid">
          <button class="country-card is-selected" type="button" data-selectable><span class="country-flag" style="--country:#2f6e9d">NL</span><span><strong>Netherlands</strong><small>Trade and coastal growth</small></span></button>
          <button class="country-card" type="button" data-selectable><span class="country-flag" style="--country:#b24a43">PL</span><span><strong>Poland</strong><small>Stability and cavalry</small></span></button>
          <button class="country-card" type="button" data-selectable><span class="country-flag" style="--country:#627c42">DR</span><span><strong>Dravonia</strong><small>Industry and defense</small></span></button>
        </div>
      </section>
      <section class="panel-surface setup-panel">
        ${sectionTitle("Campaign settings")}
        <div class="setup-panel__grid">
          <div class="field"><span class="field__label">Game length</span><select class="game-select"><option>Normal · 90 turns</option><option>Quick · 60 turns</option><option>Epic · 150 turns</option></select></div>
          <div class="field"><span class="field__label">AI difficulty</span><select class="game-select"><option>Normal</option><option>Easy</option><option>Hard</option></select></div>
          <div class="field"><span class="field__label">Your leader</span><input class="game-input" value="William" /></div>
          <div class="field"><span class="field__label">Opponents</span><select class="game-select"><option>3 civilizations</option></select></div>
        </div>
      </section>
    </div>`,
  actions: `${setupSteps("plan")}<div>${gameButton("Continue", { primary: true, icon: "chevron", view: "new-game-review" })}</div>`
});

const renderNewGameMap = () => routeFrame({
  title: "New game · map",
  activeStep: "map",
  body: `
    <div class="route-hero">
      <span class="game-eyebrow">World selection</span>
      <h1 class="game-title">Choose a map</h1>
      <p>Official maps use authored terrain, resources and start positions. Every preview uses the same runtime map pages as the game renderer.</p>
    </div>
    <div class="map-selection-grid">
      ${[{
        name: "Dravonia", description: "40 × 30 · continental world", selected: true
      }, {
        name: "Northern Passage", description: "36 × 28 · island chains", selected: false
      }, {
        name: "New World", description: "44 × 32 · wide frontier", selected: false
      }].map((map, index) => `<button class="map-card${map.selected ? " is-selected" : ""}" type="button" data-selectable>
        <div class="map-card__preview">${mapMosaic(index === 1 ? "map-preview-alt" : "")}</div>
        <div class="map-card__body"><h2>${map.name}</h2><p>${map.description}</p><div class="yield-strip">${chip("4 players")}${chip(index === 0 ? "Official" : "Prototype")}</div></div>
      </button>`).join("")}
    </div>`,
  actions: `${setupSteps("map")}<div style="display:flex;gap:8px">${gameButton("Back", { view: "new-game-plan" })}${gameButton("Use selected map", { primary: true, view: "new-game-review" })}</div>`
});

const renderNewGameReview = () => routeFrame({
  title: "New game · review",
  activeStep: "review",
  body: `
    <div class="route-hero">
      <span class="game-eyebrow">Final review</span>
      <h1 class="game-title">Your campaign is ready</h1>
    </div>
    <div class="review-grid">
      <section class="panel-surface review-preview">
        ${mapMosaic()}
        <div class="review-preview__overlay"><span class="game-eyebrow">Official world</span><h2>Dravonia</h2><p class="game-subtitle">A broad continent split by rivers, mountain ranges and strategic coastal passages.</p></div>
      </section>
      <section class="panel-surface review-summary">
        ${sectionTitle("Campaign")}
        <div class="review-summary__country"><span class="country-flag" style="--country:#2f6e9d">NL</span><span><strong style="font-family:var(--font-display);color:var(--gold-light)">Netherlands</strong><small style="display:block;color:var(--text-tertiary);margin-top:3px">Leader: William</small></span></div>
        ${statRow("Mode", "Single player")}
        ${statRow("World", "Dravonia")}
        ${statRow("Players", "1 human · 3 AI")}
        ${statRow("Difficulty", "Normal")}
        ${statRow("Game length", "90 turns")}
        ${statRow("Victory paths", "All enabled")}
        <div class="modal-section" style="margin-top:14px"><strong style="color:var(--gold-light);font-size:10px">Starting focus</strong><p>Expand toward fertile river valleys, connect cities and secure iron before rival empires reach the central pass.</p></div>
      </section>
    </div>`,
  actions: `${setupSteps("review")}<div style="display:flex;gap:8px">${gameButton("Change map", { view: "new-game-map" })}${gameButton("Start campaign", { primary: true, icon: "play", view: "game-loading" })}</div>`
});

const renderLoadGame = () => routeFrame({
  title: "Load game",
  body: `
    <div class="route-hero"><span class="game-eyebrow">Saved campaigns</span><h1 class="game-title">Continue your story</h1><p>Local and multiplayer saves share the same deterministic game state format.</p></div>
    <div class="saved-games">
      ${[
        ["Dravonia · Netherlands", "Turn 37 · Classical age · 4 cities", "Today, 18:42"],
        ["Northern Passage · Poland", "Turn 18 · Ancient age · 2 cities", "Yesterday, 23:14"],
        ["Hot seat · New World", "Turn 52 · Medieval age · 3 players", "27 Aug 2026"]
      ].map((save, index) => `<article class="save-row">
        <div class="save-row__preview"></div>
        <div><h3>${save[0]}</h3><p>${save[1]} · ${save[2]}</p></div>
        <div class="save-row__actions">${iconButton("trash", "Delete save", { small: true })}${gameButton(index === 0 ? "Continue" : "Load", { primary: index === 0, view: "game-map" })}</div>
      </article>`).join("")}
    </div>`,
  actions: `<div></div><div>${gameButton("Back", { view: "main-menu" })}</div>`
});

const renderOptionsScreen = () => routeFrame({
  title: "Settings",
  body: `<div class="options-layout">
    <nav class="panel-surface options-tabs">
      <button class="is-active" type="button">${icon("volume")}Audio</button>
      <button type="button">${icon("display")}Display</button>
      <button type="button">${icon("settings")}Gameplay</button>
      <button type="button">${icon("gamepad")}Controls</button>
      <button type="button">${icon("globe")}Language</button>
    </nav>
    <section class="panel-surface options-content">
      <div class="options-section">${sectionTitle("Audio")}
        <div class="slider-row"><strong>Master volume</strong><input type="range" value="82" /><output>82%</output></div>
        <div class="slider-row"><strong>Music</strong><input type="range" value="64" /><output>64%</output></div>
        <div class="slider-row"><strong>Sound effects</strong><input type="range" value="76" /><output>76%</output></div>
        <div class="slider-row"><strong>Ambient nature</strong><input type="range" value="70" /><output>70%</output></div>
      </div>
      <div class="options-section">${sectionTitle("Playback")}
        <div class="toggle-row"><span><strong>Menu click sounds</strong><small style="display:block;color:var(--text-tertiary)">Audible confirmation for menu actions</small></span><span class="switch is-on"></span></div>
        <div class="toggle-row"><span><strong>Mute when unfocused</strong><small style="display:block;color:var(--text-tertiary)">Pause audio when the window loses focus</small></span><span class="switch"></span></div>
      </div>
    </section>
  </div>`,
  actions: `<div>${gameButton("Restore defaults", { text: true, icon: "refresh" })}</div><div>${gameButton("Cancel", { view: "main-menu" })}${gameButton("Save settings", { primary: true, view: "main-menu" })}</div>`
});

const renderManual = () => routeFrame({
  title: "Manual",
  body: `<div class="manual-layout">
    <nav class="panel-surface manual-toc">
      <button class="is-active" type="button">Getting started</button>
      <button type="button">Map & camera</button>
      <button type="button">Cities</button>
      <button type="button">Units & combat</button>
      <button type="button">Research</button>
      <button type="button">Diplomacy</button>
      <button type="button">Victory</button>
    </nav>
    <article class="panel-surface manual-article">
      <span class="game-eyebrow">Chapter 1</span><h2>Getting started</h2>
      <p>Age of New Worlds is a turn-based 4X strategy game. During each turn you manage cities, move units, choose research and react to other civilizations.</p>
      <h3>Core turn loop</h3>
      <ol><li>Review the top resource strip and current research.</li><li>Resolve highlighted unit and city actions in the action deck.</li><li>Inspect the map, issue optional orders, then end the turn.</li></ol>
      <h3>Desktop controls</h3>
      <div class="control-grid">
        <div class="control-card"><span>Pan map</span><kbd>W A S D</kbd></div>
        <div class="control-card"><span>Zoom</span><kbd>Wheel</kbd></div>
        <div class="control-card"><span>Confirm</span><kbd>Enter</kbd></div>
        <div class="control-card"><span>Cancel</span><kbd>Esc</kbd></div>
        <div class="control-card"><span>Next action</span><kbd>Space</kbd></div>
        <div class="control-card"><span>End turn</span><kbd>Shift + Enter</kbd></div>
      </div>
    </article>
  </div>`,
  actions: `<div></div><div>${gameButton("Back", { view: "main-menu" })}</div>`
});

const renderCredits = () => routeFrame({
  title: "Credits",
  body: `<div class="route-hero"><img src="${ASSET}/runtime/ui/logo.webp" alt="Age of New Worlds" style="width:220px;filter:drop-shadow(0 10px 18px rgba(0,0,0,.6))" /><p>A hobby strategy project developed openly with a shared deterministic engine.</p></div>
    <div class="credits-grid">
      <article class="panel-surface credit-card"><strong>Design & development</strong><span>Ernest Wiśniewski</span></article>
      <article class="panel-surface credit-card"><strong>Engine</strong><span>Rust · deterministic authoritative rules</span></article>
      <article class="panel-surface credit-card"><strong>Presentation clients</strong><span>Flutter / Flame · Godot</span></article>
      <article class="panel-surface credit-card"><strong>Community</strong><span>Players, testers and open-source contributors</span></article>
    </div>`,
  actions: `<div></div><div>${gameButton("Back", { view: "main-menu" })}</div>`
});

const renderLobby = () => routeFrame({
  title: "Multiplayer lobby",
  body: `<div class="route-hero"><span class="game-eyebrow">Persistent multiplayer</span><h1 class="game-title">Dravonia campaign</h1><p>Invite players, choose civilizations and confirm that everyone is ready.</p></div>
    <div class="lobby-layout">
      <section class="panel-surface lobby-players">${sectionTitle("Players")}
        ${[
          ["EW", "Ernest", "Netherlands", "#2f6e9d", "Ready"],
          ["AK", "Anna", "Poland", "#b24a43", "Ready"],
          ["MK", "Marek", "Dravonia", "#627c42", "Choosing"],
          ["+", "Open slot", "Invite a player", "#3b4250", "Waiting"]
        ].map((p, i) => `<div class="player-row"><span class="player-avatar" style="--player:${p[3]}">${p[0]}</span><span><strong>${p[1]}</strong><small>${p[2]}</small></span><span class="${i < 2 ? "ready-state" : "muted"}">${p[4]}</span></div>`).join("")}
      </section>
      <aside class="panel-surface lobby-settings">${sectionTitle("Match")}
        ${statRow("Map", "Dravonia")}${statRow("Game length", "90 turns")}${statRow("Turn timer", "24 hours")}${statRow("Visibility", "Invite only")}${statRow("Host", "Ernest")}
        <div class="modal-section" style="margin-top:14px"><strong style="color:var(--gold-light);font-size:10px">Invite code</strong><div style="display:flex;gap:7px;margin-top:7px"><input class="game-input" value="AONW-4X7M" readonly />${iconButton("link", "Copy invite code")}</div></div>
      </aside>
    </div>`,
  actions: `<div>${gameButton("Leave lobby", { danger: true, view: "main-menu" })}</div><div>${gameButton("Ready", { primary: true, icon: "check", view: "game-multiplayer" })}</div>`
});
const renderResourceStrip = (multiplayer = false) => `<div class="hud-top-fade"></div>
  <div class="hud-menu-button">${iconButton("menu", "Return to main menu", { view: "main-menu" })}</div>
  <div class="resource-strip">
    <button class="resource-pill resource-pill--player" type="button" data-modal="empire-overview"><span class="player-color-dot" style="--player:#2f6e9d"></span><strong>Netherlands</strong><small>Turn 37</small></button>
    <button class="resource-pill" type="button" data-modal="resource-gold">${icon("coin")}<strong>842</strong><small>+34</small></button>
    <button class="resource-pill resource-pill--science" type="button" data-modal="resource-science">${icon("science")}<strong>61</strong><small>+18</small></button>
    <button class="resource-pill resource-pill--stability" type="button" data-modal="resource-stability">${icon("shield")}<strong>+7</strong><small>Stable</small></button>
    <button class="resource-pill resource-pill--resources" type="button" data-modal="resource-inventory">${icon("resource")}<strong>12</strong><small>5 types</small></button>
    <button class="resource-pill resource-pill--victory" type="button" data-modal="victory-status">${icon("trophy")}<strong>38%</strong></button>
    <button class="resource-pill resource-pill--science" type="button" data-modal="technology-details">${icon("tech")}<strong>Engineering</strong><small>4 turns</small></button>
  </div>
  ${multiplayer ? `<div class="connection-banner">${icon("refresh", "ui-icon--sm")} Synchronized · next deadline in 18h 24m</div>` : ""}`;

const renderAvatarRail = (multiplayer = false) => `<div class="hud-avatar-rail">
  <button class="hud-avatar is-active" style="--player:#2f6e9d" type="button" data-modal="${multiplayer ? "multiplayer-status" : "empire-overview"}">EW<span class="hud-avatar__status"></span></button>
  <button class="hud-avatar" style="--player:#b24a43" type="button" data-modal="diplomacy-player">AK<span class="hud-avatar__status"></span></button>
  <button class="hud-avatar" style="--player:#627c42" type="button" data-modal="diplomacy-player">DR<span class="hud-avatar__status" style="background:var(--warning)"></span></button>
  <button class="hud-avatar" style="--player:#805f9a" type="button" data-modal="diplomacy-player">NV${multiplayer ? `<span class="hud-avatar__status" style="background:var(--text-tertiary)"></span>` : ""}</button>
</div>`;

const renderSideActions = () => `<div class="hud-side-actions">
  ${iconButton("log", "Activity log", { modal: "activity-log" })}
  ${iconButton("tech", "Technology tree", { modal: "technology-tree" })}
  ${iconButton("diplomacy", "Diplomacy", { modal: "diplomacy-player" })}
  ${iconButton("settings", "Game options", { modal: "game-options" })}
</div>`;

const renderMapMarkers = (variant) => {
  const citySelected = variant === "city";
  const workerSelected = variant === "worker";
  const combat = variant === "combat";
  return `
    ${mapMarker({ x: 40, y: 54, label: "Amsterdam", sub: "Population 7 · Capital", color: "#2f6e9d", markerIcon: "city", selected: citySelected })}
    ${mapMarker({ x: 58, y: 38, label: "Rotterdam", sub: "Population 4", color: "#2f6e9d", markerIcon: "city" })}
    ${mapMarker({ x: 69, y: 57, label: "Kraków", sub: "Population 6", color: "#b24a43", markerIcon: "city" })}
    ${mapMarker({ x: 31, y: 39, label: workerSelected ? "Worker" : "1st Legion", sub: workerSelected ? "Building a road · 2 turns" : "3 / 3 movement", color: "#2f6e9d", markerIcon: workerSelected ? "worker" : "army", selected: !citySelected && !combat, type: "unit" })}
    ${mapMarker({ x: 63, y: 49, label: "Polish Spearmen", sub: "Fortified", color: "#b24a43", markerIcon: "army", selected: combat, type: "unit" })}
    <div class="map-highlight${combat ? " map-highlight--danger" : ""}" style="left:${combat ? 63 : citySelected ? 40 : 31}%;top:${combat ? 49 : citySelected ? 54 : 39}%"></div>
    ${combat ? `<div class="map-route" style="left:33%;top:40%;width:410px;transform:rotate(11deg)"></div>` : ""}`;
};

const selectionContext = (variant) => {
  if (variant === "city") {
    return `<div class="selection-context">
      <div class="selection-context__portrait">${icon("city", "ui-icon--lg")}</div>
      <div class="selection-context__copy"><strong>Amsterdam</strong><small>Capital · Population 7 · Producing Market</small></div>
      <div class="selection-context__stats"><button class="context-stat" data-modal="city-yields">Food<b>+11</b></button><button class="context-stat" data-modal="city-production">Prod.<b>+8</b></button><button class="context-stat" data-modal="selection-buildings">Build.<b>6</b></button><button class="context-stat" data-modal="city-expansion">Tiles<b>13</b></button></div>
    </div>`;
  }
  if (variant === "worker") {
    return `<div class="selection-context">
      <div class="selection-context__portrait">${icon("worker", "ui-icon--lg")}</div>
      <div class="selection-context__copy"><strong>Worker</strong><small>Grassland · Road in progress · 2 turns remaining</small></div>
      <div class="selection-context__stats"><button class="context-stat" data-modal="unit-details">Move<b>2 / 2</b></button><button class="context-stat" data-modal="selection-terrain">Tile<b>2F 1P</b></button><button class="context-stat" data-modal="worker-action">Job<b>Road</b></button></div>
    </div>`;
  }
  if (variant === "combat") {
    return `<div class="selection-context">
      <div class="selection-context__portrait">${icon("army", "ui-icon--lg")}</div>
      <div class="selection-context__copy"><strong>1st Legion</strong><small>Attack targeting · choose an adjacent enemy</small></div>
      <div class="selection-context__stats"><button class="context-stat" data-modal="unit-details">Strength<b>18</b></button><button class="context-stat" data-modal="combat-forecast">Forecast<b>Minor</b></button><button class="context-stat" data-modal="selection-army">Army<b>3</b></button></div>
    </div>`;
  }
  return `<div class="selection-context">
    <div class="selection-context__portrait">${icon("army", "ui-icon--lg")}</div>
    <div class="selection-context__copy"><strong>1st Legion</strong><small>Swordsmen · Veteran · Grassland</small></div>
    <div class="selection-context__stats"><button class="context-stat" data-modal="unit-details">Move<b>3 / 3</b></button><button class="context-stat" data-modal="unit-details">Strength<b>18</b></button><button class="context-stat" data-modal="selection-army">Army<b>3</b></button><button class="context-stat" data-modal="selection-terrain">Tile<b>2F 1P</b></button></div>
  </div>`;
};

const actionChips = (variant) => {
  if (variant === "city") {
    return [
      ["city", "Production", "city-production"],
      ["resource", "Expand city", "city-expansion"],
      ["eye", "Description", "map-inspection"],
      ["city", "Buildings", "selection-buildings"]
    ];
  }
  if (variant === "worker") {
    return [
      ["worker", "Build improvement", "worker-action"],
      ["map", "Build road", "worker-action"],
      ["play", "Automate", "worker-action"],
      ["skip", "Skip", null]
    ];
  }
  if (variant === "combat") {
    return [
      ["swords", "Confirm attack", "combat-forecast"],
      ["close", "Cancel targeting", null],
      ["info", "Combat rules", "combat-details"]
    ];
  }
  return [
    ["map", "Move", null],
    ["eye", "Auto explore", null],
    ["swords", "Attack", "combat-forecast"],
    ["shield", "Fortify", null],
    ["skip", "Skip", null],
    ["army", "Army", "selection-army"]
  ];
};

const renderActionDeck = (variant) => `<div class="hud-action-deck">
  <div class="hud-action-line">
    ${actionChips(variant).map(([iconName, label, modal]) => `<button class="action-chip${variant === "combat" && label === "Confirm attack" ? " is-active" : ""}" type="button" ${modal ? `data-modal="${modal}"` : `data-toast="${escapeHtml(label)} selected"`}>${icon(iconName)}${escapeHtml(label)}</button>`).join("")}
  </div>
  ${selectionContext(variant)}
  <div class="command-line">
    <div class="command-line__hint"><span>${variant === "combat" ? "Targeting mode" : "Current objective"}</span><strong>${variant === "city" ? "Choose production in Amsterdam" : variant === "worker" ? "Complete the worker action or skip it" : variant === "combat" ? "Review the forecast before confirming the attack" : "Move or give orders to the selected legion"}</strong></div>
    <button class="end-turn-button" type="button" data-toast="Turn submitted">${icon(variant === "combat" ? "swords" : "skip")}${variant === "combat" ? "Attack" : "Next action"}<span class="badge">${variant === "city" ? 3 : 2}</span></button>
  </div>
</div>`;

const renderInspectionCard = () => `<aside class="map-inspection-card">
  <div class="map-inspection-card__header"><span class="selection-context__portrait">${icon("map", "ui-icon--lg")}</span><div><h2>River grassland</h2><p>Hex 14, 11 · Netherlands</p></div>${iconButton("close", "Close inspection", { small: true })}</div>
  <div class="yield-strip" style="margin:11px 0">${["Food +2", "Production +1", "Gold +1"].map(label => chip(label)).join("")}</div>
  ${statRow("Terrain", "Grassland")}${statRow("Feature", "River")}${statRow("Elevation", "42 m")}${statRow("Resource", "Wheat")}${statRow("Improvement", "Farm")}
  <div style="display:flex;gap:7px;margin-top:12px">${gameButton("Terrain", { modal: "selection-terrain" })}${gameButton("Resources", { modal: "selection-resources" })}</div>
</aside>`;

const renderCombatSideForecast = () => `<aside class="panel-surface combat-side-forecast">
  ${sectionTitle("Combat forecast")}
  <div class="combat-versus"><div class="combat-unit"><div class="combat-unit__portrait" style="--unit:#2f6e9d">${icon("army", "ui-icon--lg")}</div><strong>1st Legion</strong></div><strong class="gold">VS</strong><div class="combat-unit"><div class="combat-unit__portrait" style="--unit:#b24a43">${icon("shield", "ui-icon--lg")}</div><strong>Spearmen</strong></div></div>
  <div class="combat-result">Minor victory expected</div>
  <div style="margin-top:10px">${statRow("Damage dealt", "27–36", "positive")}${statRow("Damage taken", "18–24", "warning")}${statRow("Win chance", "74%", "gold")}</div>
  <button class="game-button game-button--text" style="width:100%;margin-top:6px" type="button" data-modal="combat-details">Show calculation</button>
</aside>`;

const renderGameMap = (variant = "unit") => {
  const multiplayer = variant === "multiplayer";
  return `<section class="game-screen map-screen">
    ${mapMosaic()}
    <div class="hex-grid-overlay"></div>
    <div class="fog-bank fog-bank--1"></div><div class="fog-bank fog-bank--2"></div>
    ${renderMapMarkers(variant)}
    <div class="map-vignette"></div>
    ${renderResourceStrip(multiplayer)}
    ${renderAvatarRail(multiplayer)}
    ${renderSideActions()}
    ${variant === "worker" ? `<div class="hud-mode-banner">${icon("worker")} Worker action · choose an improvement or continue the current road</div>` : ""}
    ${variant === "combat" ? `<div class="hud-mode-banner">${icon("target")} Attack targeting · valid enemy hexes are highlighted</div>${renderCombatSideForecast()}` : ""}
    ${variant === "inspection" ? renderInspectionCard() : ""}
    ${multiplayer ? `<div class="notification-stack"><article class="notification-card"><span class="entry-row__icon">${icon("globe")}</span><span><h4>Anna ended her turn</h4><p>The match is waiting for Marek.</p></span>${iconButton("close", "Dismiss", { small: true })}</article></div>` : ""}
    ${renderActionDeck(variant === "inspection" || multiplayer ? "unit" : variant)}
  </section>`;
};

const renderGameLoading = () => `<section class="game-screen loading-screen">
  <div><div class="loading-compass"><img src="${ASSET}/runtime/ui/logo.webp" alt="" /></div><div class="loading-copy"><h1>Preparing Dravonia</h1><p>Loading deterministic map pages, units and player state…</p>${progress(68)}<p style="margin-top:9px">Building renderer · 68%</p></div></div>
</section>`;

const renderGameError = () => `<section class="game-screen error-screen">
  <div class="panel-surface error-panel">${icon("warning")}<h1>Unable to load Dravonia</h1><p>The saved campaign could not be restored. No local data was changed. Retry loading or return to the map selection screen.</p><div style="display:flex;justify-content:center;gap:8px;margin-top:18px">${gameButton("Back", { view: "load-game" })}${gameButton("Retry", { primary: true, icon: "refresh", view: "game-loading" })}</div></div>
</section>`;

const renderReplay = () => `<section class="game-screen map-screen">
  ${mapMosaic()}<div class="hex-grid-overlay"></div>${renderMapMarkers("unit")}<div class="map-vignette"></div>
  <header class="route-appbar" style="position:absolute;z-index:20;left:0;right:0;background:linear-gradient(180deg,rgba(10,10,14,.78),transparent)">${iconButton("back", "Back", { view: "main-menu" })}<h1>Replay · Dravonia</h1><span class="chip" style="margin-left:auto">Turn 18 · event 42 / 116</span></header>
  <div class="replay-controls">
    <div class="replay-buttons">${iconButton("back", "Previous turn", { small: true })}${iconButton("pause", "Pause", { small: true })}${iconButton("chevron", "Next event", { small: true })}</div>
    <div class="replay-timeline"><div class="replay-timeline__labels"><span>Turn 1</span><strong class="gold">Turn 18 · Amsterdam founded Market</strong><span>Turn 37</span></div>${progress(48)}</div>
    <div class="segmented" style="width:150px"><button class="is-active" type="button">1×</button><button type="button">2×</button><button type="button">4×</button></div>
  </div>
</section>`;
