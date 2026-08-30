"use strict";

const ASSET = "../../assets";

const icon = (name, extra = "") =>
  `<svg class="ui-icon ${extra}" aria-hidden="true"><use href="#icon-${name}"></use></svg>`;

const escapeHtml = (value) => String(value)
  .replaceAll("&", "&amp;")
  .replaceAll("<", "&lt;")
  .replaceAll(">", "&gt;")
  .replaceAll('"', "&quot;")
  .replaceAll("'", "&#039;");

const gameButton = (label, options = {}) => {
  const classes = ["game-button"];
  if (options.primary) classes.push("game-button--primary");
  if (options.text) classes.push("game-button--text");
  if (options.danger) classes.push("game-button--danger");
  const attrs = ["type=\"button\""];
  if (options.view) attrs.push(`data-view="${escapeHtml(options.view)}"`);
  if (options.modal) attrs.push(`data-modal="${escapeHtml(options.modal)}"`);
  if (options.close) attrs.push("data-close-modal");
  return `<button class="${classes.join(" ")}" ${attrs.join(" ")}>
    ${options.icon ? icon(options.icon) : ""}<span>${escapeHtml(label)}</span>
  </button>`;
};

const iconButton = (name, label, options = {}) => {
  const attrs = ["type=\"button\"", `aria-label="${escapeHtml(label)}"`, `title="${escapeHtml(label)}"`];
  if (options.view) attrs.push(`data-view="${escapeHtml(options.view)}"`);
  if (options.modal) attrs.push(`data-modal="${escapeHtml(options.modal)}"`);
  if (options.close) attrs.push("data-close-modal");
  return `<button class="icon-button${options.small ? " icon-button--small" : ""}" ${attrs.join(" ")}>${icon(name)}</button>`;
};

const goldDivider = (className = "") => `<div class="gold-divider ${className}"></div>`;
const progress = (value, extra = "") => `<div class="progress ${extra}" style="--value:${value}%"><span></span></div>`;
const chip = (label, options = {}) => `<span class="chip${options.active ? " is-active" : ""}">${options.icon ? icon(options.icon, "ui-icon--sm") : ""}${escapeHtml(label)}</span>`;

const mapMosaic = (extraClass = "") => `<div class="map-mosaic ${extraClass}" aria-hidden="true">
  <img class="map-page-00" src="${ASSET}/runtime/maps/dravonia/page_00.jpg" alt="" />
  <img class="map-page-01" src="${ASSET}/runtime/maps/dravonia/page_01.jpg" alt="" />
  <img class="map-page-02" src="${ASSET}/runtime/maps/dravonia/page_02.jpg" alt="" />
  <img class="map-page-03" src="${ASSET}/runtime/maps/dravonia/page_03.jpg" alt="" />
  <img class="map-page-04" src="${ASSET}/runtime/maps/dravonia/page_04.jpg" alt="" />
  <img class="map-page-05" src="${ASSET}/runtime/maps/dravonia/page_05.jpg" alt="" />
</div>`;

const mapMarker = ({ x, y, label, sub, color, markerIcon = "city", selected = false, type = "city" }) => `
  <div class="map-marker map-marker--${type}${selected ? " map-marker--selected" : ""}" style="left:${x}%;top:${y}%;--marker:${color}">
    <div class="map-marker__ring">${icon(markerIcon, "ui-icon--lg")}</div>
    <div class="map-marker__label">${escapeHtml(label)}</div>
    ${sub ? `<div class="map-marker__sub">${escapeHtml(sub)}</div>` : ""}
  </div>`;

const sectionTitle = (label) => `<h3 class="section-title">${escapeHtml(label)}</h3>`;

const statRow = (label, value, valueClass = "") => `<div class="stat-row"><span>${escapeHtml(label)}</span><strong class="${valueClass}">${escapeHtml(value)}</strong></div>`;

const entryRow = ({ iconName, title, subtitle, value = "" }) => `<div class="entry-row">
  <span class="entry-row__icon">${icon(iconName)}</span>
  <span><strong>${escapeHtml(title)}</strong><small>${escapeHtml(subtitle)}</small></span>
  ${value ? `<span class="entry-row__value">${escapeHtml(value)}</span>` : ""}
</div>`;

const screenRegistry = [
  { id: "main-menu", title: "Main menu", group: "Menu & setup", icon: "menu", source: ["lib/menu/main_menu_screen.dart", "lib/menu/main_menu_shell.dart"] },
  { id: "main-menu-developer", title: "Main menu · developer tools", group: "Menu & setup", icon: "code", source: ["lib/menu/main_menu_developer_tools.dart"] },
  { id: "new-game-plan", title: "New game · plan", group: "Menu & setup", icon: "plus", source: ["lib/game/presentation/screens/new_game/new_game_screen_plan_step.dart"] },
  { id: "new-game-map", title: "New game · map", group: "Menu & setup", icon: "map", source: ["lib/game/presentation/screens/new_game/new_game_screen_map_step.dart"] },
  { id: "new-game-review", title: "New game · review", group: "Menu & setup", icon: "check", source: ["lib/game/presentation/screens/new_game/new_game_screen_review_step.dart"] },
  { id: "load-game", title: "Load game", group: "Menu & setup", icon: "folder", source: ["lib/menu/load_game_screen.dart"] },
  { id: "options-screen", title: "Settings", group: "Menu & setup", icon: "settings", source: ["lib/menu/options_screen.dart"] },
  { id: "manual", title: "Manual", group: "Menu & setup", icon: "book", source: ["lib/menu/manual_screen.dart", "lib/menu/manual_content.dart"] },
  { id: "credits", title: "Credits", group: "Menu & setup", icon: "star", source: ["lib/menu/credits_screen.dart"] },
  { id: "multiplayer-lobby", title: "Multiplayer lobby", group: "Menu & setup", icon: "globe", source: ["lib/game/presentation/screens/lobby"] },
  { id: "game-map", title: "Game map · unit selected", group: "Game map states", icon: "map", source: ["lib/game/presentation/screens/game/game_screen.dart", "lib/game/presentation/widgets/hud/game_hud.dart"] },
  { id: "game-city", title: "Game map · city selected", group: "Game map states", icon: "city", source: ["lib/game/presentation/widgets/hud/action_deck", "lib/game/presentation/widgets/selection"] },
  { id: "game-worker", title: "Game map · worker action", group: "Game map states", icon: "worker", source: ["lib/game/presentation/widgets/bottom_toolbar", "lib/game/presentation/widgets/hud/action_deck"] },
  { id: "game-combat", title: "Game map · combat targeting", group: "Game map states", icon: "swords", source: ["lib/game/presentation/widgets/hud/combat", "lib/game/presentation/widgets/hud/action_deck/hud_action_deck_combat_modal.dart"] },
  { id: "game-inspection", title: "Game map · inspection", group: "Game map states", icon: "eye", source: ["lib/game/presentation/widgets/hud/map/hud_map_inspection_menu.dart"] },
  { id: "game-multiplayer", title: "Game map · multiplayer", group: "Game map states", icon: "globe", source: ["lib/game/presentation/widgets/multiplayer"] },
  { id: "game-loading", title: "Game loading", group: "System states", icon: "refresh", source: ["lib/game/presentation/widgets/screen/game_screen_state_views.dart"] },
  { id: "game-error", title: "Game load error", group: "System states", icon: "warning", source: ["lib/game/presentation/widgets/screen/game_screen_state_views.dart"] },
  { id: "replay", title: "Replay", group: "System states", icon: "play", source: ["lib/game/presentation/screens/replay/replay_screen.dart"] }
];

const modalRegistry = [
  { id: "activity-log", title: "Activity log", group: "Timeline & events", icon: "log", size: "regular", source: ["lib/game/presentation/widgets/activity_log/activity_log_dialog.dart"] },
  { id: "turn-timeline", title: "Turn timeline", group: "Timeline & events", icon: "log", size: "wide", source: ["lib/game/presentation/widgets/activity_log"] },
  { id: "event-notification", title: "Event notification", group: "Timeline & events", icon: "info", mode: "overlay", source: ["lib/game/presentation/widgets/hud/notifications/game_event_notifications_overlay.dart"] },
  { id: "city-production", title: "City production", group: "City", icon: "city", size: "wide", source: ["lib/game/presentation/widgets/city/city_production_dialog.dart"] },
  { id: "building-details", title: "Building details", group: "City", icon: "city", size: "regular", source: ["lib/game/presentation/widgets/city/building_details_dialog.dart"] },
  { id: "wonder-details", title: "Wonder details", group: "City", icon: "star", size: "regular", source: ["lib/game/presentation/widgets/city/wonder_details_dialog.dart"] },
  { id: "city-yields", title: "City yield breakdown", group: "City", icon: "resource", size: "regular", source: ["lib/game/presentation/widgets/city"] },
  { id: "city-expansion", title: "City expansion selection", group: "City", icon: "target", size: "compact", source: ["lib/game/presentation/widgets/hud/action_deck/hud_action_deck_layout.dart"] },
  { id: "diplomacy-player", title: "Diplomacy · civilization", group: "Diplomacy", icon: "diplomacy", size: "wide", source: ["lib/game/presentation/widgets/diplomacy/diplomacy_player_modal.dart"] },
  { id: "diplomacy-conversation", title: "Diplomatic conversation", group: "Diplomacy", icon: "chat", size: "regular", source: ["lib/game/presentation/widgets/diplomacy"] },
  { id: "diplomacy-trade", title: "Trade proposal", group: "Diplomacy", icon: "resource", size: "wide", source: ["lib/game/presentation/widgets/diplomacy"] },
  { id: "civilization-met", title: "Civilization met", group: "Diplomacy", icon: "globe", mode: "overlay", source: ["lib/game/presentation/widgets/diplomacy/civilization_met_popup_overlay.dart"] },
  { id: "diplomatic-message", title: "Diplomatic message", group: "Diplomacy", icon: "chat", mode: "overlay", source: ["lib/game/presentation/widgets/diplomacy/diplomatic_message_popup_overlay.dart"] },
  { id: "diplomatic-proposal", title: "Diplomatic proposal", group: "Diplomacy", icon: "diplomacy", size: "regular", source: ["lib/game/presentation/widgets/diplomacy"] },
  { id: "empire-overview", title: "Empire overview", group: "Empire", icon: "crown", size: "wide", source: ["lib/game/presentation/widgets/empire"] },
  { id: "empire-statistics", title: "Empire statistics", group: "Empire", icon: "log", size: "wide", source: ["lib/game/presentation/widgets/empire"] },
  { id: "technology-tree", title: "Technology tree", group: "Technology", icon: "tech", size: "wide", source: ["lib/game/presentation/widgets/technology"] },
  { id: "technology-details", title: "Technology details", group: "Technology", icon: "science", size: "regular", source: ["lib/game/presentation/widgets/technology"] },
  { id: "technology-discovery", title: "Technology discovered", group: "Technology", icon: "tech", mode: "overlay", source: ["lib/game/presentation/widgets/technology/technology_discovery_popup_overlay.dart"] },
  { id: "technology-recommendations", title: "Research recommendations", group: "Technology", icon: "science", size: "regular", source: ["lib/game/presentation/widgets/technology"] },
  { id: "unit-details", title: "Unit details", group: "Selection & units", icon: "army", size: "regular", source: ["lib/game/presentation/widgets/selection_info"] },
  { id: "selection-army", title: "Army details", group: "Selection & units", icon: "army", size: "regular", source: ["lib/game/presentation/widgets/selection_info"] },
  { id: "selection-terrain", title: "Terrain details", group: "Selection & units", icon: "map", size: "regular", source: ["lib/game/presentation/widgets/selection_info"] },
  { id: "selection-resources", title: "Tile resources", group: "Selection & units", icon: "resource", size: "regular", source: ["lib/game/presentation/widgets/selection_info"] },
  { id: "selection-buildings", title: "City buildings", group: "Selection & units", icon: "city", size: "wide", source: ["lib/game/presentation/widgets/selection_info"] },
  { id: "selection-improvements", title: "Tile improvements", group: "Selection & units", icon: "worker", size: "regular", source: ["lib/game/presentation/widgets/selection_info"] },
  { id: "worker-action", title: "Worker action", group: "Selection & units", icon: "worker", size: "regular", source: ["lib/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_view_model.dart"] },
  { id: "merchant-route", title: "Merchant route", group: "Selection & units", icon: "resource", size: "regular", source: ["lib/game/presentation/widgets/hud/selection"] },
  { id: "artifact-storage", title: "Store artifact", group: "Selection & units", icon: "star", size: "regular", source: ["lib/game/presentation/widgets/hud/selection"] },
  { id: "map-inspection", title: "Map inspection details", group: "Selection & units", icon: "eye", size: "regular", source: ["lib/game/presentation/widgets/hud/map"] },
  { id: "resource-gold", title: "Gold breakdown", group: "Economy & victory", icon: "coin", size: "regular", source: ["lib/game/presentation/widgets/resources/resource_breakdown_popup.dart"] },
  { id: "resource-science", title: "Science breakdown", group: "Economy & victory", icon: "science", size: "regular", source: ["lib/game/presentation/widgets/resources/resource_breakdown_popup.dart"] },
  { id: "resource-stability", title: "Stability breakdown", group: "Economy & victory", icon: "shield", size: "regular", source: ["lib/game/presentation/widgets/resources/resource_breakdown_popup.dart"] },
  { id: "resource-inventory", title: "Resource inventory", group: "Economy & victory", icon: "resource", size: "wide", source: ["lib/game/presentation/widgets/resources/resource_breakdown_popup.dart"] },
  { id: "strategic-economy", title: "Strategic resource economy", group: "Economy & victory", icon: "resource", size: "wide", source: ["lib/game/presentation/widgets/resources/strategic_resource_economy_dialog.dart"] },
  { id: "victory-status", title: "Victory status", group: "Economy & victory", icon: "trophy", size: "regular", source: ["lib/game/presentation/widgets/resources/victory_status_popup.dart"] },
  { id: "combat-forecast", title: "Combat forecast", group: "Combat", icon: "swords", size: "regular", source: ["lib/game/presentation/widgets/hud/action_deck/hud_action_deck_combat_modal.dart"] },
  { id: "combat-details", title: "Combat explanation", group: "Combat", icon: "info", size: "regular", source: ["lib/game/presentation/widgets/hud/action_deck/hud_action_deck_combat_explanation.dart"] },
  { id: "game-options", title: "In-game options", group: "Options & help", icon: "settings", size: "wide", source: ["lib/game/presentation/widgets/options/game_options_overlay.dart"] },
  { id: "game-help", title: "In-game help", group: "Options & help", icon: "book", size: "wide", source: ["lib/game/presentation/widgets/options/game_help_panel.dart"] },
  { id: "multiplayer-status", title: "Multiplayer status", group: "Multiplayer", icon: "globe", size: "regular", source: ["lib/game/presentation/widgets/multiplayer/multiplayer_status_sheet.dart"] },
  { id: "multiplayer-avatars", title: "Player avatars", group: "Multiplayer", icon: "globe", size: "regular", source: ["lib/game/presentation/widgets/multiplayer/multiplayer_avatars_sheet.dart"] },
  { id: "hot-seat-handoff", title: "Hot-seat handoff", group: "Multiplayer", icon: "hand", mode: "overlay", source: ["lib/game/presentation/widgets/multiplayer/hot_seat_handoff_overlay.dart"] },
  { id: "game-outcome-victory", title: "Victory outcome", group: "Outcomes & onboarding", icon: "trophy", mode: "overlay", source: ["lib/game/presentation/widgets/hud/outcome/hud_game_outcome_overlay.dart"] },
  { id: "game-outcome-defeat", title: "Defeat outcome", group: "Outcomes & onboarding", icon: "warning", mode: "overlay", source: ["lib/game/presentation/widgets/hud/outcome/hud_game_outcome_overlay.dart"] },
  { id: "first-turn-coachmark", title: "First-turn coachmark", group: "Outcomes & onboarding", icon: "info", mode: "overlay", source: ["lib/game/presentation/widgets/onboarding/first_turn_coachmarks.dart"] }
];

const routeFrame = ({ title, body, actions = "", activeStep = null }) => `
  <section class="game-screen route-screen">
    <div class="route-background"></div>
    <header class="route-appbar">
      ${iconButton("back", "Back to main menu", { view: activeStep === "plan" ? "main-menu" : activeStep === "map" ? "new-game-plan" : activeStep === "review" ? "new-game-plan" : "main-menu" })}
      <h1>${escapeHtml(title)}</h1>
    </header>
    <main class="route-content">${body}</main>
    ${actions ? `<footer class="route-actionbar">${actions}</footer>` : ""}
  </section>`;

const setupSteps = (active) => `<div class="route-actionbar__steps">
  ${["plan", "map", "review"].map((step, index) => `<button type="button" class="step-pill${active === step ? " is-active" : ""}" data-view="new-game-${step}"><b>${index + 1}</b>${step}</button>`).join("")}
</div>`;

const menuButton = ({ iconName, title, subtitle = "", view, modal, primary = false, chevron = true }) => `<button type="button" class="menu-button${primary ? " is-primary" : ""}" ${view ? `data-view="${view}"` : ""} ${modal ? `data-modal="${modal}"` : ""}>
  <span class="menu-button__icon">${icon(iconName)}</span>
  <span class="menu-button__copy"><strong>${escapeHtml(title)}</strong>${subtitle ? `<small>${escapeHtml(subtitle)}</small>` : ""}</span>
  ${chevron ? icon("chevron") : ""}
</button>`;
