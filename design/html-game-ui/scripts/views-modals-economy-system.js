"use strict";

const renderResourceInventory = (meta) => modalShell(meta, `
  <div class="resource-summary-hero"><div class="resource-summary-hero__icon">${icon("resource", "ui-icon--lg")}</div><div><span class="game-eyebrow">Empire inventory</span><strong>12</strong><span>units across 5 connected resource types</span></div><div class="yield-strip">${chip("4 cities")}${chip("No active shortage")}</div></div>
  <div class="modal-two-column">
    <section>${sectionTitle("Resource network")}<table class="strategic-table"><thead><tr><th>Resource</th><th>Produced</th><th>Consumed</th><th>Stockpile</th><th>Status</th></tr></thead><tbody>
      <tr><td>Iron</td><td class="positive">+3</td><td>−2</td><td>8</td><td class="positive">Surplus</td></tr>
      <tr><td>Horses</td><td class="positive">+2</td><td>−1</td><td>5</td><td class="positive">Surplus</td></tr>
      <tr><td>Coal</td><td>0</td><td>0</td><td>0</td><td class="muted">Undiscovered</td></tr>
      <tr><td>Oil</td><td>0</td><td>0</td><td>0</td><td class="warning">Unavailable</td></tr>
      <tr><td>Wheat</td><td class="positive">+3</td><td>−2</td><td>11</td><td class="positive">Connected</td></tr>
    </tbody></table></section>
    <aside class="modal-section">${sectionTitle("Network summary")}${statRow("Connected cities", "4 / 4")}${statRow("Trade imports", "Horses +1")}${statRow("Trade exports", "Iron −1")}${statRow("Pillaged links", "0")}${statRow("Strategic reserve", "13 turns")}</aside>
  </div>`,
  `${gameButton("Strategic economy", { modal: "strategic-economy", icon: "resource" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Luxury and strategic resources" });

const renderStrategicEconomy = (meta) => modalShell(meta, `
  <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:12px;margin-bottom:12px"><div><span class="game-eyebrow">Strategic resource economy</span><strong style="display:block;color:var(--gold-light);font-family:var(--font-display);font-size:17px;margin-top:3px">Production, stockpiles and demand</strong></div><div class="yield-strip">${chip("2 surpluses")}${chip("1 unavailable")}</div></div>
  <table class="strategic-table"><thead><tr><th>Resource</th><th>Sources</th><th>Output</th><th>Demand</th><th>Stock</th><th>Turns</th><th>Status</th></tr></thead><tbody>
    <tr><td>Iron</td><td>Amsterdam mine</td><td class="positive">+3</td><td>−2</td><td>8</td><td>8</td><td class="positive">Healthy</td></tr>
    <tr><td>Horses</td><td>Utrecht pasture · trade</td><td class="positive">+2</td><td>−1</td><td>5</td><td>5</td><td class="positive">Healthy</td></tr>
    <tr><td>Coal</td><td>Not revealed</td><td>0</td><td>0</td><td>0</td><td>—</td><td class="muted">Future era</td></tr>
    <tr><td>Oil</td><td>No known source</td><td>0</td><td>−1</td><td>0</td><td>0</td><td class="negative">Shortage</td></tr>
    <tr><td>Aluminium</td><td>Not revealed</td><td>0</td><td>0</td><td>0</td><td>—</td><td class="muted">Future era</td></tr>
    <tr><td>Uranium</td><td>Not revealed</td><td>0</td><td>0</td><td>0</td><td>—</td><td class="muted">Future era</td></tr>
  </tbody></table>
  <div class="modal-three-column" style="margin-top:12px"><section class="modal-section">${sectionTitle("Military demand")}${statRow("Swordsmen", "Iron −1")}${statRow("Heavy cavalry", "Horses −1")}${statRow("Future tank", "Oil −1", "warning")}</section><section class="modal-section">${sectionTitle("Trade")}${statRow("Imported", "Horses +1")}${statRow("Exported", "Iron −1")}${statRow("Net gold", "+4")}</section><section class="modal-section">${sectionTitle("Recommendations")}<p>Secure an oil source before researching combustion-era units, or negotiate a long-term import agreement.</p></section></div>`,
  `${gameButton("Open diplomacy", { modal: "diplomacy-trade", icon: "diplomacy" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Empire-wide production and consumption" });

const renderVictoryStatus = (meta) => modalShell(meta, `
  <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:12px"><div><span class="game-eyebrow">Campaign progress</span><strong style="display:block;color:var(--gold-light);font-family:var(--font-display);font-size:18px;margin-top:3px">Victory paths</strong></div>${chip("Overall rank 2 / 4", { active: true })}</div>
  <div class="victory-path"><span class="victory-path__icon">${icon("crown")}</span><span><h4>Conquest</h4>${progress(42)}<small class="muted">Control 2 of 4 rival capitals</small></span><strong class="gold">42%</strong></div>
  <div class="victory-path"><span class="victory-path__icon">${icon("map")}</span><span><h4>Territorial domination</h4>${progress(38)}<small class="muted">Control 38% of claimable land</small></span><strong class="gold">38%</strong></div>
  <div class="victory-path"><span class="victory-path__icon">${icon("science")}</span><span><h4>Knowledge</h4>${progress(31, "progress--science")}<small class="muted">Lead the technology race and complete the final project</small></span><strong class="science">31%</strong></div>
  <div class="victory-path"><span class="victory-path__icon">${icon("star")}</span><span><h4>World artifacts</h4>${progress(50)}<small class="muted">Store 3 of 6 artifacts in your cities</small></span><strong class="gold">50%</strong></div>
  <section class="modal-section" style="margin-top:12px">${statRow("Score fallback", "712 · rank 2")}${statRow("Turns remaining", "53")}${statRow("Current leader", "Poland · 738")}</section>`,
  `${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Conquest, territory, knowledge and artifacts" });

const renderCombatForecast = (meta) => modalShell(meta, `
  <div class="combat-versus"><div class="combat-unit"><div class="combat-unit__portrait" style="--unit:#2f6e9d">${icon("army", "ui-icon--lg")}</div><strong>1st Legion</strong><div class="muted" style="font-size:9px;margin-top:3px">18 strength · 100 HP</div></div><strong class="gold" style="font-family:var(--font-display);font-size:18px">VS</strong><div class="combat-unit"><div class="combat-unit__portrait" style="--unit:#b24a43">${icon("shield", "ui-icon--lg")}</div><strong>Polish Spearmen</strong><div class="muted" style="font-size:9px;margin-top:3px">15 strength · 92 HP</div></div></div>
  <div class="combat-result">Minor victory expected · 74% favorable</div>
  <div class="modal-two-column" style="margin-top:12px"><section class="modal-section">${sectionTitle("Expected result")}${statRow("Damage dealt", "27–36", "positive")}${statRow("Damage taken", "18–24", "warning")}${statRow("Defender health", "56–65")}${statRow("Attacker health", "76–82")}</section><section class="modal-section">${sectionTitle("Key modifiers")}${statRow("Veteran promotion", "+10%", "positive")}${statRow("River crossing", "−15%", "negative")}${statRow("Defender fortified", "+10% defense", "warning")}${statRow("Support bonus", "+5%", "positive")}</section></div>`,
  `${gameButton("Calculation", { modal: "combat-details", icon: "info" })}${gameButton("Cancel", { close: true })}${gameButton("Attack", { primary: true, icon: "swords", close: true })}`,
  { subtitle: "Projected damage before committing" });

const renderCombatDetails = (meta) => modalShell(meta, `
  <section class="modal-section">${sectionTitle("Combat calculation")}${statRow("Attacker base strength", "18.0")}${statRow("Veteran promotion", "+1.8", "positive")}${statRow("Friendly support", "+0.9", "positive")}${statRow("River crossing", "−2.7", "negative")}${goldDivider()}${statRow("Effective attack", "18.0", "gold")}</section>
  <section class="modal-section">${statRow("Defender base strength", "15.0")}${statRow("Fortified", "+1.5", "warning")}${statRow("Terrain defense", "+0.0")}${goldDivider()}${statRow("Effective defense", "16.5", "gold")}</section>
  <section class="modal-section"><p>Damage uses the deterministic engine combat curve. The displayed range includes all known modifiers but not hidden effects that the active player has not discovered.</p></section>`,
  `${gameButton("Back to forecast", { modal: "combat-forecast" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Transparent deterministic modifiers" });

const renderGameOptions = (meta) => modalShell(meta, `
  <div class="options-layout" style="grid-template-columns:200px minmax(0,1fr)">
    <nav class="options-tabs panel-surface" style="box-shadow:none"><button class="is-active" type="button">${icon("eye")}Map display</button><button type="button">${icon("settings")}Gameplay</button><button type="button">${icon("volume")}Audio</button><button type="button">${icon("gamepad")}Controls</button><button type="button">${icon("book")}Help</button></nav>
    <section class="options-content panel-surface" style="box-shadow:none">${sectionTitle("Map display")}
      <div class="toggle-row"><span><strong>Terrain labels</strong><small style="display:block;color:var(--text-tertiary)">Show terrain names at close zoom</small></span><span class="switch is-on"></span></div>
      <div class="toggle-row"><span><strong>Resources</strong><small style="display:block;color:var(--text-tertiary)">Show map resource icons</small></span><span class="switch is-on"></span></div>
      <div class="toggle-row"><span><strong>Height badges</strong><small style="display:block;color:var(--text-tertiary)">Show authored elevation values</small></span><span class="switch"></span></div>
      <div class="toggle-row"><span><strong>City growth</strong><small style="display:block;color:var(--text-tertiary)">Show preferred expansion tiles</small></span><span class="switch is-on"></span></div>
      <div class="toggle-row"><span><strong>Hex borders</strong><small style="display:block;color:var(--text-tertiary)">Render the strategic grid</small></span><span class="switch is-on"></span></div>
      <div class="field" style="margin-top:12px"><span class="field__label">Map view</span><div class="segmented"><button class="is-active" type="button">Graphic</button><button type="button">Strategic</button></div></div>
    </section>
  </div>`,
  `${gameButton("Resign match", { danger: true })}${gameButton("Help", { modal: "game-help", icon: "book" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Map, gameplay, audio and match controls" });

const renderGameHelp = (meta) => modalShell(meta, `
  <div class="manual-layout" style="grid-template-columns:190px minmax(0,1fr)"><nav class="manual-toc panel-surface" style="box-shadow:none"><button class="is-active" type="button">Current HUD</button><button type="button">Cities</button><button type="button">Units</button><button type="button">Research</button><button type="button">Diplomacy</button></nav><article class="manual-article panel-surface" style="box-shadow:none"><span class="game-eyebrow">Context help</span><h2>Using the game HUD</h2><p>The top strip contains your empire resources, current research and victory progress. Select a pill for a detailed breakdown.</p><h3>Action deck</h3><p>The bottom deck follows the selected city or unit. Mandatory turn actions remain visible until resolved. The main command advances to the next unresolved action and changes to End turn when everything is complete.</p><h3>Map inspection</h3><p>Select an empty hex to inspect terrain, resources, improvements and ownership without changing the active unit selection.</p></article></div>`,
  `${gameButton("Open full manual", { view: "manual" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Controls and context-sensitive guidance" });

const renderMultiplayerStatus = (meta) => modalShell(meta, `
  <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:12px"><div><span class="game-eyebrow">Dravonia campaign</span><strong style="display:block;color:var(--gold-light);font-family:var(--font-display);font-size:16px;margin-top:3px">Turn 37 · waiting for 1 player</strong></div>${chip("Synchronized", { active: true, icon: "check" })}</div>
  <div class="entry-list">
    ${entryRow({ iconName: "check", title: "Ernest · Netherlands", subtitle: "Turn submitted 4 minutes ago", value: "Ready" })}
    ${entryRow({ iconName: "check", title: "Anna · Poland", subtitle: "Turn submitted 18 minutes ago", value: "Ready" })}
    ${entryRow({ iconName: "refresh", title: "Marek · Dravonia", subtitle: "Currently playing · online", value: "Playing" })}
    ${entryRow({ iconName: "warning", title: "Nina · Novaria", subtitle: "Offline · last seen 2 hours ago", value: "Pending" })}
  </div>
  <section class="modal-section" style="margin-top:12px">${statRow("Turn deadline", "31 Aug 2026 · 14:00")}${statRow("Time remaining", "18h 24m")}${statRow("Network revision", "37.4")}${statRow("Last synchronization", "Just now", "positive")}</section>`,
  `${gameButton("Player list", { modal: "multiplayer-avatars" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Persistent match connection and turn ownership" });

const renderMultiplayerAvatars = (meta) => modalShell(meta, `
  <div class="entry-list">
    ${[["EW","Ernest","Netherlands","#2f6e9d","Active player"],["AK","Anna","Poland","#b24a43","Ready"],["MK","Marek","Dravonia","#627c42","Playing"],["NV","Nina","Novaria","#805f9a","Offline"]].map(([initial,name,country,color,status]) => `<div class="player-row"><span class="player-avatar" style="--player:${color}">${initial}</span><span><strong>${name}</strong><small>${country}</small></span><span class="${status === "Ready" ? "ready-state" : status === "Offline" ? "muted" : "gold"}" style="font-size:9px">${status}</span></div>`).join("")}
  </div>`,
  `${gameButton("Match status", { modal: "multiplayer-status" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Players and current turn state" });

const renderHotSeatHandoff = () => `<div class="handoff-overlay"><section class="panel-surface handoff-card"><div class="player-avatar" style="--player:#b24a43">AK</div><span class="game-eyebrow">Turn 38</span><h2>Pass to Anna</h2><p class="game-subtitle">The previous player’s private map and decisions are hidden. Anna should confirm before the next turn is revealed.</p><div style="margin-top:17px">${gameButton("Begin Anna’s turn", { primary: true, icon: "hand", close: true })}</div></section></div>`;

const renderGameOutcome = (victory) => `<div class="outcome-overlay"><section class="outcome-panel"><div class="outcome-panel__crest">${icon(victory ? "trophy" : "warning", "ui-icon--lg")}</div><span class="game-eyebrow">Campaign complete · Turn 90</span><h1>${victory ? "Victory" : "Defeat"}</h1><p>${victory ? "The Netherlands controls the world’s decisive trade routes and has secured enough territory to establish a lasting new order." : "Poland completed the final territorial objective before the Netherlands could close the score gap."}</p><div class="empire-metric-grid" style="margin:18px 0">${[["Final rank",victory ? "1 / 4" : "2 / 4"],["Score",victory ? "1,428" : "1,164"],["Cities","8"],["Artifacts","4"]].map(([l,v]) => `<div class="metric-card"><span>${l}</span><strong>${v}</strong></div>`).join("")}</div><div style="display:flex;justify-content:center;gap:8px">${gameButton("View timeline", { modal: "turn-timeline" })}${gameButton("Return to menu", { primary: true, view: "main-menu" })}</div></section></div>`;

const renderFirstTurnCoachmark = () => `<div class="coachmark-overlay"><div class="coachmark-hole"></div><section class="panel-surface coachmark-card"><span class="game-eyebrow">First turn · 2 of 4</span><h3>The action deck follows your selection</h3><p>Choose one of the available orders, inspect details, or use Next action to move to another unresolved decision.</p><div style="display:flex;justify-content:center;gap:8px;margin-top:12px">${gameButton("Skip tutorial", { text: true, close: true })}${gameButton("Next", { primary: true, icon: "chevron", close: true })}</div></section></div>`;
