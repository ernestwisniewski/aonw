"use strict";

const modalShell = (meta, body, actions = null, options = {}) => {
  const sizeClass = meta.size === "wide" ? " game-modal--wide" : meta.size === "compact" ? " game-modal--compact" : "";
  const shapeClass = options.bottomSheet ? " game-modal--bottom-sheet" : "";
  const footer = actions === false ? "" : `<footer class="game-modal__actions">${actions ?? gameButton("Close", { close: true })}</footer>`;
  return `<div class="modal-backdrop" data-modal-backdrop>
    <section class="game-modal${sizeClass}${shapeClass}" role="dialog" aria-modal="true" aria-label="${escapeHtml(meta.title)}">
      <header class="game-modal__header">
        <div class="game-modal__title-row"><span class="header-diamond"></span>${icon(meta.icon || "info")}<div class="game-modal__title-copy"><h2>${escapeHtml(meta.title)}</h2>${options.subtitle ? `<p>${escapeHtml(options.subtitle)}</p>` : ""}</div></div>
        ${iconButton("close", "Close", { close: true, small: true })}
      </header>
      <div class="game-modal__body">${body}</div>
      ${footer}
    </section>
  </div>`;
};

const logEntries = () => [
  ["Turn 37", "Amsterdam completed a Market. Gold income increased by 5."],
  ["Turn 37", "The 1st Legion entered the central valley and revealed an iron deposit."],
  ["Turn 36", "Anna proposed an open borders agreement."],
  ["Turn 35", "Engineering research advanced to 61 / 108 science."],
  ["Turn 34", "Rotterdam grew to population 4."],
  ["Turn 33", "A worker began constructing the Amsterdam–Rotterdam road."]
].map(([turn, text], index) => `<div class="log-entry"><span class="log-entry__turn">${turn}</span><span class="log-entry__dot" style="background:${index === 2 ? "var(--info)" : index === 3 ? "var(--science)" : "var(--gold)"}"></span><p>${text}</p></div>`).join("");

const renderActivityLog = (meta) => modalShell(meta, `
  <div class="segmented" style="margin-bottom:12px"><button class="is-active" type="button">All events</button><button type="button">Empire</button><button type="button">Diplomacy</button><button type="button">Combat</button></div>
  <section class="modal-section">${logEntries()}</section>`,
  `${gameButton("Turn timeline", { modal: "turn-timeline" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Events visible to the active player" });

const renderTurnTimeline = (meta) => modalShell(meta, `
  <div class="modal-two-column">
    <section>
      ${sectionTitle("Empire development")}
      <div class="chart"><svg viewBox="0 0 600 190" preserveAspectRatio="none"><polyline points="0,168 70,155 130,150 200,128 280,132 350,94 425,82 500,55 600,29"></polyline><polyline class="chart-secondary" points="0,176 70,166 130,142 200,150 280,112 350,118 425,90 500,78 600,46"></polyline></svg></div>
      <div style="display:flex;gap:10px;margin-top:8px">${chip("Score", { active: true })}${chip("Science")}${chip("Cities")}</div>
    </section>
    <section class="modal-section">${sectionTitle("Turn 37")}${logEntries()}</section>
  </div>`,
  `${gameButton("Previous turn", { icon: "back" })}${gameButton("Next turn", { icon: "chevron" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Campaign history and visible milestones" });

const renderEventNotification = () => `<div class="notification-stack" style="top:72px;right:18px">
  <article class="notification-card"><span class="entry-row__icon">${icon("city")}</span><span><h4>Amsterdam completed Market</h4><p>Gold income increased by 5 per turn.</p></span>${iconButton("close", "Dismiss", { close: true, small: true })}</article>
  <article class="notification-card"><span class="entry-row__icon">${icon("science")}</span><span><h4>Research advanced</h4><p>Engineering will be completed in 4 turns.</p></span>${iconButton("close", "Dismiss", { close: true, small: true })}</article>
</div>`;

const renderCityProduction = (meta) => modalShell(meta, `
  <div class="city-header"><div class="city-emblem">${icon("city", "ui-icon--lg")}</div><div><h3>Amsterdam</h3><p>Capital · Population 7 · Stable</p></div><div class="yield-strip">${["Food +11", "Prod. +8", "Gold +14", "Science +7"].map(label => chip(label)).join("")}</div></div>
  <div class="modal-two-column">
    <section>
      ${sectionTitle("Current production")}
      <div class="production-current"><div class="production-current__row"><span class="production-icon">${icon("city", "ui-icon--lg")}</span><span><strong>Market</strong><small style="display:block;color:var(--text-tertiary);margin:3px 0 7px">Commercial building · +5 gold</small>${progress(64)}</span><b class="gold number">3 turns</b></div></div>
      <div class="segmented" style="margin:12px 0"><button class="is-active" type="button">Buildings</button><button type="button">Units</button><button type="button">Wonders</button><button type="button">Projects</button></div>
      <div class="production-grid">
        ${[
          ["city", "Granary", "+2 food · +10% growth", "4 turns"],
          ["science", "Library", "+4 science", "5 turns"],
          ["shield", "Walls", "+25 city defense", "6 turns"],
          ["resource", "Workshop", "+3 production", "6 turns"],
          ["coin", "Mint", "+20% gold", "7 turns"],
          ["star", "Great Lighthouse", "Naval wonder", "15 turns"]
        ].map(([i,t,s,v]) => `<button type="button" class="production-card" data-modal="${t === "Great Lighthouse" ? "wonder-details" : "building-details"}"><span class="building-icon">${icon(i)}</span><span><h4>${t}</h4><p>${s}</p></span><span class="production-card__turns">${v}</span></button>`).join("")}
      </div>
    </section>
    <aside class="modal-section">${sectionTitle("City overview")}${statRow("Population", "7")}${statRow("Housing", "8 / 10")}${statRow("Growth", "6 turns")}${statRow("Production", "+8")}${statRow("Maintenance", "−4 gold")}${statRow("Stability", "+3", "positive")}<div style="margin-top:12px">${gameButton("Yield details", { modal: "city-yields" })}</div></aside>
  </div>`,
  `${gameButton("Manage buildings", { modal: "selection-buildings" })}${gameButton("Close", { close: true })}${gameButton("Queue selected", { primary: true, icon: "check" })}`,
  { subtitle: "Choose the next construction project" });

const renderBuildingDetails = (meta) => modalShell(meta, `
  <div class="hero-detail"><div class="hero-detail__art">${icon("coin", "ui-icon--lg")}</div><div><span class="game-eyebrow">Commercial building</span><h3>Market</h3><p>A permanent trading center that increases local income and connects the city more strongly to the empire economy.</p><div class="yield-strip" style="margin-top:11px">${chip("+5 gold")}${chip("+1 merchant slot")}${chip("80 production")}</div></div></div>
  <section class="modal-section" style="margin-top:14px">${sectionTitle("Effects")}${statRow("City gold", "+5", "positive")}${statRow("Trade route income", "+10%", "positive")}${statRow("Maintenance", "−1 gold", "negative")}${statRow("Required technology", "Currency")}</section>`,
  `${gameButton("Back", { close: true })}${gameButton("Add to queue", { primary: true, icon: "check" })}`,
  { subtitle: "Amsterdam · available construction" });

const renderWonderDetails = (meta) => modalShell(meta, `
  <div class="hero-detail"><div class="hero-detail__art">${icon("star", "ui-icon--lg")}</div><div><span class="game-eyebrow">World wonder</span><h3>Great Lighthouse</h3><p>A monumental beacon that extends naval vision and enriches every coastal trade route controlled by its builder.</p><div class="yield-strip" style="margin-top:11px">${chip("+2 naval vision")}${chip("+3 trade gold")}${chip("240 production")}</div></div></div>
  <section class="modal-section" style="margin-top:14px"><p class="warning">Only one civilization can complete this wonder. Poland has already invested 42 production.</p>${statRow("Your completion", "15 turns")}${statRow("Fastest rival estimate", "13–17 turns")}${statRow("Required terrain", "Coastal city")}</section>`,
  `${gameButton("Cancel", { close: true })}${gameButton("Begin wonder", { primary: true, icon: "star" })}`,
  { subtitle: "Unique construction · global race" });

const renderCityYields = (meta) => modalShell(meta, `
  <div class="city-header"><div class="city-emblem">${icon("city", "ui-icon--lg")}</div><div><h3>Amsterdam</h3><p>Yield sources per turn</p></div><div class="yield-strip">${chip("Net +31")}</div></div>
  <div class="modal-three-column">
    <section class="modal-section">${sectionTitle("Food")}${statRow("Worked tiles", "+14")}${statRow("Granary", "+2")}${statRow("Population", "−7", "negative")}${goldDivider()}${statRow("Net food", "+9", "positive")}</section>
    <section class="modal-section">${sectionTitle("Production")}${statRow("Worked tiles", "+6")}${statRow("Workshop", "+3")}${statRow("Stability", "+1")}${goldDivider()}${statRow("Net production", "+10", "positive")}</section>
    <section class="modal-section">${sectionTitle("Commerce")}${statRow("Worked tiles", "+7")}${statRow("Market", "+5")}${statRow("Trade routes", "+4")}${statRow("Maintenance", "−2", "negative")}${goldDivider()}${statRow("Net gold", "+14", "positive")}</section>
  </div>`,
  `${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Detailed local economy" });

const renderCityExpansion = (meta) => modalShell(meta, `
  <div class="hero-detail"><div class="hero-detail__art">${icon("target", "ui-icon--lg")}</div><div><span class="game-eyebrow">Amsterdam</span><h3>Choose expansion tile</h3><p>Select one highlighted adjacent hex. The preferred tile will be claimed when the city has accumulated enough culture.</p></div></div>
  <div class="entry-list" style="margin-top:14px">
    ${entryRow({ iconName: "resource", title: "River wheat", subtitle: "Grassland · Food +3 · 48 culture", value: "Recommended" })}
    ${entryRow({ iconName: "map", title: "Forested hills", subtitle: "Production +2 · 42 culture", value: "42" })}
    ${entryRow({ iconName: "coin", title: "Coastal plains", subtitle: "Gold +2 · 39 culture", value: "39" })}
  </div>`,
  `${gameButton("Cancel", { close: true })}${gameButton("Confirm tile", { primary: true, icon: "check" })}`,
  { subtitle: "Preferred cultural growth" });

const renderDiplomacyPlayer = (meta) => modalShell(meta, `
  <div class="diplomacy-leader"><div class="leader-portrait">AK</div><div><span class="game-eyebrow">Poland</span><h3>Queen Anna</h3><p>Friendly · Met 16 turns ago · Classical age</p></div></div>
  <div class="modal-two-column">
    <section>
      ${sectionTitle("Relationship")}
      <div class="relation-meter" style="--relation:67%"></div>
      <div style="display:flex;justify-content:space-between;margin:6px 0 13px;color:var(--text-tertiary);font-size:8px"><span>Hostile</span><strong class="positive">Friendly +34</strong><span>Allied</span></div>
      <div class="entry-list">
        ${entryRow({ iconName: "check", title: "Open borders", subtitle: "Active for 12 more turns", value: "+8" })}
        ${entryRow({ iconName: "resource", title: "Mutual trade", subtitle: "Two active routes", value: "+6" })}
        ${entryRow({ iconName: "swords", title: "Border pressure", subtitle: "Kraków claims a contested tile", value: "−5" })}
      </div>
    </section>
    <aside class="modal-section">${sectionTitle("Civilization")}${statRow("Score", "684")}${statRow("Cities", "4")}${statRow("Known army", "Strong")}${statRow("Technology", "Comparable")}${statRow("Trade balance", "+7 gold")}${statRow("Current wars", "None")}</aside>
  </div>`,
  `${gameButton("Trade", { modal: "diplomacy-trade", icon: "resource" })}${gameButton("Talk", { modal: "diplomacy-conversation", icon: "chat" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Relations, agreements and visible intelligence" });

const renderDiplomacyConversation = (meta) => modalShell(meta, `
  <div class="diplomacy-leader"><div class="leader-portrait">AK</div><div><span class="game-eyebrow">Audience with Poland</span><h3>Queen Anna</h3><p>Friendly relationship</p></div></div>
  <div class="dialogue-bubble">Your merchants are welcome in Kraków, William. The passes remain uncertain, but our people profit when the roads stay open.</div>
  <div class="dialogue-options">
    <button class="dialogue-option" type="button">We would like to extend our open borders agreement.</button>
    <button class="dialogue-option" type="button">Let us discuss trade between our empires.</button>
    <button class="dialogue-option" type="button">Your settlement near the central pass concerns us.</button>
    <button class="dialogue-option" type="button">There is nothing more to discuss.</button>
  </div>`,
  `${gameButton("Back to overview", { modal: "diplomacy-player" })}${gameButton("Close", { close: true })}`,
  { subtitle: "Choose a diplomatic response" });

const renderDiplomacyTrade = (meta) => modalShell(meta, `
  <div class="trade-columns">
    <section class="trade-side">${sectionTitle("Netherlands offers")}
      <div class="entry-list">${entryRow({ iconName: "coin", title: "Gold per turn", subtitle: "10 turns", value: "5" })}${entryRow({ iconName: "resource", title: "Iron", subtitle: "Strategic resource", value: "2" })}${entryRow({ iconName: "map", title: "Open borders", subtitle: "20 turns", value: "" })}</div>
      <button class="game-button game-button--text" style="width:100%;margin-top:8px" type="button">+ Add item</button>
    </section>
    <div class="trade-exchange">${icon("refresh", "ui-icon--lg")}</div>
    <section class="trade-side">${sectionTitle("Poland offers")}
      <div class="entry-list">${entryRow({ iconName: "resource", title: "Horses", subtitle: "Strategic resource", value: "3" })}${entryRow({ iconName: "coin", title: "Immediate gold", subtitle: "One-time payment", value: "45" })}${entryRow({ iconName: "diplomacy", title: "Research agreement", subtitle: "20 turns", value: "" })}</div>
      <button class="game-button game-button--text" style="width:100%;margin-top:8px" type="button">+ Request item</button>
    </section>
  </div>
  <div class="modal-section" style="margin-top:12px">${statRow("Estimated balance", "+4 in your favor", "positive")}${statRow("Polish response", "Likely to accept", "positive")}</div>`,
  `${gameButton("Clear", { text: true })}${gameButton("Cancel", { close: true })}${gameButton("Propose trade", { primary: true, icon: "diplomacy" })}`,
  { subtitle: "Build a balanced bilateral agreement" });

const renderCivilizationMet = () => `<div class="discovery-overlay">
  <section class="discovery-card"><div class="leader-portrait" style="margin:0 auto 14px">AK</div><span class="game-eyebrow">A new civilization has been encountered</span><h2>Poland</h2><p class="game-subtitle">Queen Anna rules a disciplined realm beyond the eastern river. First impressions will shape future diplomacy.</p><div class="yield-strip" style="justify-content:center;margin:16px 0">${chip("Expansionist")}${chip("Cavalry tradition")}${chip("Neutral +0")}</div>${gameButton("Open diplomacy", { primary: true, icon: "diplomacy", modal: "diplomacy-player" })}</section>
</div>`;

const renderDiplomaticMessage = () => `<div class="discovery-overlay">
  <section class="panel-surface handoff-card"><div class="leader-portrait" style="margin:0 auto 14px">AK</div><span class="game-eyebrow">Message from Poland</span><h2>Our borders are too close</h2><div class="dialogue-bubble">Your new settlement presses against lands we consider ours. Move carefully, or our friendship will not last.</div><div style="display:flex;justify-content:center;gap:8px;margin-top:15px">${gameButton("We understand", { close: true })}${gameButton("The land is ours", { danger: true, close: true })}</div></section>
</div>`;

const renderDiplomaticProposal = (meta) => modalShell(meta, `
  <div class="diplomacy-leader"><div class="leader-portrait">AK</div><div><span class="game-eyebrow">Proposal from Poland</span><h3>Open borders</h3><p>Duration: 20 turns</p></div></div>
  <div class="dialogue-bubble">Let our merchants and scouts cross freely. Poland proposes mutual open borders for the next twenty turns.</div>
  <section class="modal-section" style="margin-top:12px">${statRow("Your relation", "Friendly +34", "positive")}${statRow("Trade route effect", "+6 gold / turn", "positive")}${statRow("Military access", "Mutual")}</section>`,
  `${gameButton("Decline", { danger: true, close: true })}${gameButton("Negotiate", { modal: "diplomacy-trade" })}${gameButton("Accept", { primary: true, icon: "check", close: true })}`,
  { subtitle: "Review the terms before responding" });
const renderEmpireOverview = (meta) => modalShell(meta, `
  <div class="empire-header"><div class="empire-emblem">${icon("crown", "ui-icon--lg")}</div><div><span class="game-eyebrow">Your civilization</span><h3>Kingdom of the Netherlands</h3><p class="game-subtitle">William · Classical age · Turn 37</p></div><div class="yield-strip">${chip("Rank 2 / 4")}${chip("Score 712")}</div></div>
  <div class="empire-metric-grid">
    ${[["Cities","4"],["Population","19"],["Territory","57"],["Army","142"],["Gold / turn","+34"],["Science / turn","+18"],["Stability","+7"],["Victory","38%"]].map(([l,v]) => `<div class="metric-card"><span>${l}</span><strong>${v}</strong></div>`).join("")}
  </div>
  <div class="modal-two-column" style="margin-top:14px">
    <section class="modal-section">${sectionTitle("Cities")}
      <div class="entry-list">
        ${entryRow({ iconName: "city", title: "Amsterdam", subtitle: "Capital · Population 7 · Market in 3 turns", value: "+14g" })}
        ${entryRow({ iconName: "city", title: "Rotterdam", subtitle: "Coastal · Population 4 · Galley in 2 turns", value: "+8g" })}
        ${entryRow({ iconName: "city", title: "Utrecht", subtitle: "River · Population 5 · Library in 4 turns", value: "+9s" })}
        ${entryRow({ iconName: "city", title: "Breda", subtitle: "Frontier · Population 3 · Walls in 5 turns", value: "+6p" })}
      </div>
    </section>
    <aside class="modal-section">${sectionTitle("Empire status")}${statRow("Government", "Merchant Council")}${statRow("Current research", "Engineering")}${statRow("Known civilizations", "3")}${statRow("Active trade routes", "4 / 5")}${statRow("Strategic shortages", "Oil · unavailable", "warning")}${statRow("Next policy", "8 turns")}</aside>
  </div>`,
  `${gameButton("Statistics", { modal: "empire-statistics", icon: "log" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Cities, economy and strategic standing" });

const renderEmpireStatistics = (meta) => modalShell(meta, `
  <div class="segmented" style="margin-bottom:12px"><button class="is-active" type="button">Score</button><button type="button">Economy</button><button type="button">Science</button><button type="button">Military</button><button type="button">Territory</button></div>
  <div class="modal-two-column">
    <section><div class="chart" style="min-height:280px"><svg viewBox="0 0 600 260" preserveAspectRatio="none"><polyline points="0,230 70,218 130,206 190,178 250,164 310,142 370,128 430,92 500,68 600,34"></polyline><polyline class="chart-secondary" points="0,238 70,222 130,190 190,196 250,165 310,158 370,111 430,118 500,88 600,77"></polyline><polyline style="stroke:#c6675d" points="0,244 70,230 130,223 190,190 250,198 310,174 370,160 430,140 500,127 600,108"></polyline></svg></div><div style="display:flex;gap:10px;margin-top:9px">${chip("Netherlands", { active: true })}${chip("Poland")}${chip("Dravonia")}</div></section>
    <aside class="modal-section">${sectionTitle("Current ranking")}${statRow("1. Poland", "738")}${statRow("2. Netherlands", "712", "gold")}${statRow("3. Dravonia", "641")}${statRow("4. Novaria", "599")}<div style="margin-top:14px">${sectionTitle("Trend")}${statRow("Last 10 turns", "+96", "positive")}${statRow("Gap to leader", "−26", "warning")}${statRow("Projected rank", "1–2")}</div></aside>
  </div>`,
  `${gameButton("Back to empire", { modal: "empire-overview" })}${gameButton("Close", { close: true, primary: true })}`,
  { subtitle: "Comparative campaign metrics through turn 37" });
