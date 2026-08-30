"use strict";

const techNode = (iconName, title, subtitle, state = "") => `<button class="tech-node${state ? ` ${state}` : ""}" type="button" data-modal="technology-details"><span class="tech-icon">${icon(iconName)}</span><span><h4>${title}</h4><p>${subtitle}</p>${state === "is-active" ? progress(56, "progress--science") : ""}</span></button>`;

const renderTechnologyTree = (meta) => modalShell(meta, `
  <div style="display:flex;align-items:center;justify-content:space-between;gap:12px;margin-bottom:12px"><div><span class="game-eyebrow">Current research</span><strong style="display:block;color:var(--gold-light);font-family:var(--font-display);margin-top:3px">Engineering · 4 turns</strong></div><div class="yield-strip">${chip("61 / 108 science")}${chip("+18 / turn")}</div></div>
  <div class="tech-tree">
    <div class="tech-era-labels"><span>Ancient era</span><span>Classical era</span><span>Medieval era</span><span>Renaissance era</span></div>
    <div class="tech-lanes">
      <div class="tech-column">${techNode("worker", "Agriculture", "Farms · Granary", "is-complete")}${techNode("army", "Bronze Working", "Spearmen · Iron", "is-complete")}${techNode("map", "Sailing", "Galleys · Harbours", "is-complete")}</div>
      <div class="tech-column">${techNode("coin", "Currency", "Markets · Trade", "is-complete")}${techNode("tech", "Engineering", "Roads · Workshops", "is-active")}${techNode("science", "Philosophy", "Libraries · Policies")}</div>
      <div class="tech-column">${techNode("city", "Architecture", "Aqueducts · Wonders")}${techNode("army", "Steel", "Swordsmen · Armour", "is-locked")}${techNode("resource", "Guilds", "Merchants · Workshops", "is-locked")}</div>
      <div class="tech-column">${techNode("science", "Navigation", "Ocean travel", "is-locked")}${techNode("coin", "Banking", "Banks · Loans", "is-locked")}${techNode("swords", "Gunpowder", "Muskets · Cannons", "is-locked")}</div>
    </div>
  </div>`,
  `${gameButton("Recommendations", { modal: "technology-recommendations", icon: "science" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Choose research and inspect future unlocks" });

const renderTechnologyDetails = (meta) => modalShell(meta, `
  <div class="hero-detail"><div class="hero-detail__art">${icon("tech", "ui-icon--lg")}</div><div><span class="game-eyebrow">Classical technology</span><h3>Engineering</h3><p>Standardizes large construction, durable roads and the workshops needed for a stronger productive economy.</p><div style="margin-top:10px">${progress(56, "progress--science")}<small style="display:block;color:var(--text-tertiary);margin-top:5px">61 / 108 science · 4 turns remaining</small></div></div></div>
  <section class="modal-section" style="margin-top:14px">${sectionTitle("Unlocks")}<div class="unlock-grid">
    <div class="unlock-card">${icon("worker")}<strong>Improved roads</strong></div>
    <div class="unlock-card">${icon("city")}<strong>Workshop</strong></div>
    <div class="unlock-card">${icon("shield")}<strong>Fortification</strong></div>
  </div></section>
  <section class="modal-section">${statRow("Research cost", "108 science")}${statRow("Prerequisites", "Bronze Working · Currency")}${statRow("Leads to", "Architecture · Steel")}</section>`,
  `${gameButton("Open tree", { modal: "technology-tree" })}${gameButton("Close", { close: true })}${gameButton("Research", { primary: true, icon: "science" })}`,
  { subtitle: "Research progress and unlocks" });

const renderTechnologyDiscovery = () => `<div class="discovery-overlay">
  <section class="discovery-card"><div class="tech-icon">${icon("tech", "ui-icon--lg")}</div><span class="game-eyebrow">Technology discovered</span><h2>Engineering</h2><p class="game-subtitle">Your builders can now construct improved roads and Workshops. New research choices are available.</p><div class="unlock-grid" style="margin:18px auto;max-width:430px"><div class="unlock-card">${icon("worker")}<strong>Improved roads</strong></div><div class="unlock-card">${icon("city")}<strong>Workshop</strong></div><div class="unlock-card">${icon("shield")}<strong>Fortification</strong></div></div><div style="display:flex;justify-content:center;gap:8px">${gameButton("View details", { modal: "technology-details" })}${gameButton("Choose research", { primary: true, icon: "science", modal: "technology-recommendations" })}</div></section>
</div>`;

const renderTechnologyRecommendations = (meta) => modalShell(meta, `
  <p class="game-subtitle" style="margin-top:0">Research suggestions are based on your current cities, army, known resources and victory progress.</p>
  <div class="entry-list">
    ${entryRow({ iconName: "city", title: "Architecture", subtitle: "Recommended for Amsterdam’s growth and wonder production", value: "7 turns" })}
    ${entryRow({ iconName: "army", title: "Steel", subtitle: "Improves frontline units near Poland", value: "8 turns" })}
    ${entryRow({ iconName: "resource", title: "Guilds", subtitle: "Expands trade and merchant capacity", value: "6 turns" })}
    ${entryRow({ iconName: "science", title: "Philosophy", subtitle: "Cheapest route to stronger science", value: "5 turns" })}
  </div>`,
  `${gameButton("Open full tree", { modal: "technology-tree" })}${gameButton("Close", { close: true })}${gameButton("Research Architecture", { primary: true, icon: "science" })}`,
  { subtitle: "Choose the next technology" });

const renderUnitDetails = (meta) => modalShell(meta, `
  <div class="hero-detail"><div class="hero-detail__art">${icon("army", "ui-icon--lg")}</div><div><span class="game-eyebrow">Netherlands · melee unit</span><h3>1st Legion</h3><p>Veteran swordsmen commanded from Amsterdam. The unit is healthy, supplied and ready to move.</p><div class="yield-strip" style="margin-top:10px">${chip("Veteran")}${chip("Fortified +10%")}${chip("Supplied")}</div></div></div>
  <div class="unit-stat-grid" style="margin-top:14px">${[["Strength","18"],["Movement","3 / 3"],["Health","100 / 100"],["Upkeep","2 gold"],["Vision","2 hexes"],["Experience","42 / 60"],["Supply","Connected"],["Era","Classical"]].map(([l,v]) => `<div class="unit-stat"><span>${l}</span><b>${v}</b></div>`).join("")}</div>
  <section class="modal-section" style="margin-top:12px">${sectionTitle("Promotions")}${entryRow({ iconName: "shield", title: "Shield wall", subtitle: "+10% defense on open terrain", value: "Active" })}${entryRow({ iconName: "swords", title: "Drill", subtitle: "+5% attack against melee units", value: "Active" })}</section>`,
  `${gameButton("Army", { modal: "selection-army" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Unit statistics, status and promotions" });

const renderSelectionArmy = (meta) => modalShell(meta, `
  <div class="hero-detail"><div class="hero-detail__art">${icon("army", "ui-icon--lg")}</div><div><span class="game-eyebrow">Selected formation</span><h3>1st Army</h3><p>Three units move under one command. Formation speed is limited by the slowest member.</p><div class="yield-strip" style="margin-top:10px">${chip("3 units")}${chip("Power 47")}${chip("Movement 2")}</div></div></div>
  <div class="entry-list" style="margin-top:14px">
    ${entryRow({ iconName: "army", title: "1st Legion", subtitle: "Swordsmen · Veteran · 100 health", value: "18" })}
    ${entryRow({ iconName: "shield", title: "Amsterdam Guard", subtitle: "Spearmen · Regular · 92 health", value: "14" })}
    ${entryRow({ iconName: "target", title: "River Archers", subtitle: "Ranged · Regular · 100 health", value: "15" })}
  </div>`,
  `${gameButton("Disband formation", { danger: true })}${gameButton("Close", { close: true })}${gameButton("Manage army", { primary: true, icon: "army" })}`,
  { subtitle: "Formation composition and combined strength" });

const renderSelectionTerrain = (meta) => modalShell(meta, `
  <div class="hero-detail"><div class="hero-detail__art">${icon("map", "ui-icon--lg")}</div><div><span class="game-eyebrow">Hex 14, 11</span><h3>River grassland</h3><p>Open fertile terrain beside a navigable river. Controlled by the Netherlands and worked by Amsterdam.</p><div class="yield-strip" style="margin-top:10px">${chip("Food +2")}${chip("Production +1")}${chip("Gold +1")}</div></div></div>
  <section class="modal-section" style="margin-top:14px">${statRow("Elevation", "42 m")}${statRow("Movement cost", "1")}${statRow("Defense modifier", "0%")}${statRow("Fresh water", "Yes", "positive")}${statRow("Road", "Connected")}${statRow("Owner", "Amsterdam")}</section>`,
  `${gameButton("Resources", { modal: "selection-resources" })}${gameButton("Improvements", { modal: "selection-improvements" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Terrain, yields and movement rules" });

const renderSelectionResources = (meta) => modalShell(meta, `
  <div class="resource-summary-hero"><div class="resource-summary-hero__icon">${icon("resource", "ui-icon--lg")}</div><div><span class="game-eyebrow">Luxury resource</span><strong>Wheat</strong><span>Improved and connected to Amsterdam</span></div><div class="yield-strip">${chip("3 copies")}${chip("No shortage")}</div></div>
  <div class="modal-two-column">
    <section class="modal-section">${sectionTitle("Local effects")}${statRow("Tile food", "+1", "positive")}${statRow("City growth", "+5%", "positive")}${statRow("Stability", "+1 per unique luxury", "positive")}</section>
    <section class="modal-section">${sectionTitle("Empire network")}${statRow("Produced", "3 / turn")}${statRow("Consumed", "2 / turn")}${statRow("Stockpile", "11")}${statRow("Connected cities", "4 / 4")}</section>
  </div>`,
  `${gameButton("Economy", { modal: "strategic-economy" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Tile resource and empire connection" });

const renderSelectionBuildings = (meta) => modalShell(meta, `
  <div class="city-header"><div class="city-emblem">${icon("city", "ui-icon--lg")}</div><div><h3>Amsterdam buildings</h3><p>6 completed · 1 in production · 4 gold maintenance</p></div><div>${gameButton("Production", { modal: "city-production", icon: "city" })}</div></div>
  <div class="production-grid">
    ${[
      ["city","Palace","Capital administration · +3 gold","Free"],
      ["city","Granary","+2 food · +10% growth","1g"],
      ["science","Library","+4 science","1g"],
      ["shield","Walls","+25 city defense","1g"],
      ["resource","Workshop","+3 production","1g"],
      ["coin","Harbour","Coastal trade routes","0g"]
    ].map(([i,t,s,v]) => `<button type="button" class="production-card" data-modal="building-details"><span class="building-icon">${icon(i)}</span><span><h4>${t}</h4><p>${s}</p></span><span class="production-card__turns">${v}</span></button>`).join("")}
  </div>`,
  `${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Completed infrastructure and maintenance" });

const renderSelectionImprovements = (meta) => modalShell(meta, `
  <div class="hero-detail"><div class="hero-detail__art">${icon("worker", "ui-icon--lg")}</div><div><span class="game-eyebrow">River grassland</span><h3>Farm</h3><p>A worked agricultural improvement connected to Amsterdam by road.</p><div class="yield-strip" style="margin-top:10px">${chip("Food +2")}${chip("Road")}${chip("Worked")}</div></div></div>
  <section class="modal-section" style="margin-top:14px">${statRow("Base terrain", "Grassland · 2 food")}${statRow("Farm improvement", "+2 food", "positive")}${statRow("Wheat resource", "+1 food", "positive")}${statRow("River commerce", "+1 gold", "positive")}${goldDivider()}${statRow("Total yield", "5 food · 1 production · 1 gold", "gold")}</section>`,
  `${gameButton("Terrain", { modal: "selection-terrain" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Worked tile improvement" });

const renderWorkerAction = (meta) => modalShell(meta, `
  <div class="hero-detail"><div class="hero-detail__art">${icon("worker", "ui-icon--lg")}</div><div><span class="game-eyebrow">Selected unit</span><h3>Worker</h3><p>Choose a valid improvement for this grassland tile. Unavailable actions explain their missing requirements.</p></div></div>
  <div class="entry-list" style="margin-top:14px">
    ${entryRow({ iconName: "resource", title: "Build farm", subtitle: "+2 food · 3 turns", value: "Available" })}
    ${entryRow({ iconName: "map", title: "Build road", subtitle: "Connects movement and trade · 2 turns", value: "Selected" })}
    ${entryRow({ iconName: "resource", title: "Build mine", subtitle: "Requires hills terrain", value: "Locked" })}
    ${entryRow({ iconName: "city", title: "Build outpost", subtitle: "Requires Engineering", value: "Locked" })}
  </div>`,
  `${gameButton("Cancel job", { danger: true })}${gameButton("Close", { close: true })}${gameButton("Build road", { primary: true, icon: "worker" })}`,
  { subtitle: "Improvement selection and job progress" });

const renderMerchantRoute = (meta) => modalShell(meta, `
  <div class="hero-detail"><div class="hero-detail__art">${icon("resource", "ui-icon--lg")}</div><div><span class="game-eyebrow">Merchant</span><h3>Choose trade route</h3><p>Assign the selected merchant to a connected city. Longer routes earn more but are vulnerable to disruption.</p></div></div>
  <div class="entry-list" style="margin-top:14px">
    ${entryRow({ iconName: "city", title: "Rotterdam", subtitle: "Road · 7 hexes · Safe", value: "+8g" })}
    ${entryRow({ iconName: "city", title: "Kraków", subtitle: "Open borders · 13 hexes · Foreign", value: "+14g" })}
    ${entryRow({ iconName: "city", title: "Breda", subtitle: "Road incomplete · 9 hexes", value: "+6g" })}
  </div>`,
  `${gameButton("Cancel", { close: true })}${gameButton("Assign Kraków", { primary: true, icon: "check" })}`,
  { subtitle: "Available connected cities" });

const renderArtifactStorage = (meta) => modalShell(meta, `
  <div class="hero-detail"><div class="hero-detail__art">${icon("star", "ui-icon--lg")}</div><div><span class="game-eyebrow">World artifact</span><h3>Astral Compass</h3><p>The explorer carries an ancient navigational instrument. Store it in one of your cities to activate its empire bonus.</p><div class="yield-strip" style="margin-top:10px">${chip("+1 naval vision")}${chip("+2 science")}</div></div></div>
  <div class="entry-list" style="margin-top:14px">${entryRow({ iconName: "city", title: "Amsterdam", subtitle: "Capital · 6 hexes away", value: "Recommended" })}${entryRow({ iconName: "city", title: "Rotterdam", subtitle: "Coastal · 9 hexes away", value: "9" })}</div>`,
  `${gameButton("Keep carrying", { close: true })}${gameButton("Store in Amsterdam", { primary: true, icon: "star" })}`,
  { subtitle: "Choose a permanent city collection" });

const renderMapInspection = (meta) => modalShell(meta, `
  <div class="hero-detail"><div class="hero-detail__art">${icon("eye", "ui-icon--lg")}</div><div><span class="game-eyebrow">Map inspection</span><h3>Central River Valley</h3><p>Visible grassland controlled by the Netherlands, adjacent to Amsterdam and within working range.</p></div></div>
  <div class="modal-three-column" style="margin-top:14px"><section class="modal-section">${sectionTitle("Terrain")}${statRow("Type", "Grassland")}${statRow("Feature", "River")}${statRow("Elevation", "42 m")}</section><section class="modal-section">${sectionTitle("Yield")}${statRow("Food", "+2")}${statRow("Production", "+1")}${statRow("Gold", "+1")}</section><section class="modal-section">${sectionTitle("Control")}${statRow("Owner", "Netherlands")}${statRow("City", "Amsterdam")}${statRow("Visibility", "Current")}</section></div>`,
  `${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Anchored hex details" });
const renderResourceBreakdown = (meta, type) => {
  const configs = {
    gold: {
      icon: "coin", total: "842", delta: "+34 / turn", subtitle: "Treasury and recurring income", rows: [
        ["City income", "+28", "positive"], ["Trade routes", "+17", "positive"], ["Agreements", "+4", "positive"], ["Unit upkeep", "−9", "negative"], ["Building maintenance", "−6", "negative"]
      ], cities: [["Amsterdam", "+14"], ["Rotterdam", "+8"], ["Utrecht", "+7"], ["Breda", "+5"]]
    },
    science: {
      icon: "science", total: "+18", delta: "Engineering · 4 turns", subtitle: "Research yield and active technology", rows: [
        ["City population", "+8", "positive"], ["Libraries", "+6", "positive"], ["Terrain yields", "+3", "positive"], ["Diplomatic agreement", "+1", "positive"], ["Penalty", "0", ""]
      ], cities: [["Utrecht", "+7"], ["Amsterdam", "+6"], ["Rotterdam", "+3"], ["Breda", "+2"]]
    },
    stability: {
      icon: "shield", total: "+7", delta: "Stable", subtitle: "Empire order and pressure", rows: [
        ["Base order", "+10", "positive"], ["Buildings", "+5", "positive"], ["Luxury resources", "+4", "positive"], ["City cost", "−6", "negative"], ["Population pressure", "−4", "negative"], ["Border tension", "−2", "negative"]
      ], cities: [["Amsterdam", "+3"], ["Utrecht", "+2"], ["Rotterdam", "+1"], ["Breda", "+1"]]
    }
  };
  const cfg = configs[type];
  return modalShell(meta, `
    <div class="resource-summary-hero"><div class="resource-summary-hero__icon">${icon(cfg.icon, "ui-icon--lg")}</div><div><span class="game-eyebrow">${cfg.subtitle}</span><strong>${cfg.total}</strong><span>${cfg.delta}</span></div><div>${progress(type === "stability" ? 68 : type === "science" ? 56 : 78, type === "science" ? "progress--science" : "")}</div></div>
    <div class="modal-two-column">
      <section class="modal-section">${sectionTitle("Breakdown")}${cfg.rows.map(([l,v,c]) => statRow(l,v,c)).join("")}${goldDivider()}${statRow("Net total", type === "gold" ? "+34" : type === "science" ? "+18" : "+7", "gold")}</section>
      <aside class="modal-section">${sectionTitle("By city")}${cfg.cities.map(([l,v]) => statRow(l,v)).join("")}${type === "science" ? `<div style="margin-top:12px">${gameButton("Research details", { modal: "technology-details" })}</div>` : ""}</aside>
    </div>`,
    `${gameButton("Close", { close: true, primary: true })}`,
    { subtitle: cfg.subtitle });
};
