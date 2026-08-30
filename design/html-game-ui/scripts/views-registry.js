"use strict";

const renderScreen = (id) => {
  switch (id) {
    case "main-menu": return renderMainMenu(false);
    case "main-menu-developer": return renderMainMenu(true);
    case "new-game-plan": return renderNewGamePlan();
    case "new-game-map": return renderNewGameMap();
    case "new-game-review": return renderNewGameReview();
    case "load-game": return renderLoadGame();
    case "options-screen": return renderOptionsScreen();
    case "manual": return renderManual();
    case "credits": return renderCredits();
    case "multiplayer-lobby": return renderLobby();
    case "game-map": return renderGameMap("unit");
    case "game-city": return renderGameMap("city");
    case "game-worker": return renderGameMap("worker");
    case "game-combat": return renderGameMap("combat");
    case "game-inspection": return renderGameMap("inspection");
    case "game-multiplayer": return renderGameMap("multiplayer");
    case "game-loading": return renderGameLoading();
    case "game-error": return renderGameError();
    case "replay": return renderReplay();
    default: return renderMainMenu(false);
  }
};

const renderModal = (id) => {
  const meta = modalRegistry.find((entry) => entry.id === id);
  if (!meta) return "";
  switch (id) {
    case "activity-log": return renderActivityLog(meta);
    case "turn-timeline": return renderTurnTimeline(meta);
    case "event-notification": return renderEventNotification();
    case "city-production": return renderCityProduction(meta);
    case "building-details": return renderBuildingDetails(meta);
    case "wonder-details": return renderWonderDetails(meta);
    case "city-yields": return renderCityYields(meta);
    case "city-expansion": return renderCityExpansion(meta);
    case "diplomacy-player": return renderDiplomacyPlayer(meta);
    case "diplomacy-conversation": return renderDiplomacyConversation(meta);
    case "diplomacy-trade": return renderDiplomacyTrade(meta);
    case "civilization-met": return renderCivilizationMet();
    case "diplomatic-message": return renderDiplomaticMessage();
    case "diplomatic-proposal": return renderDiplomaticProposal(meta);
    case "empire-overview": return renderEmpireOverview(meta);
    case "empire-statistics": return renderEmpireStatistics(meta);
    case "technology-tree": return renderTechnologyTree(meta);
    case "technology-details": return renderTechnologyDetails(meta);
    case "technology-discovery": return renderTechnologyDiscovery();
    case "technology-recommendations": return renderTechnologyRecommendations(meta);
    case "unit-details": return renderUnitDetails(meta);
    case "selection-army": return renderSelectionArmy(meta);
    case "selection-terrain": return renderSelectionTerrain(meta);
    case "selection-resources": return renderSelectionResources(meta);
    case "selection-buildings": return renderSelectionBuildings(meta);
    case "selection-improvements": return renderSelectionImprovements(meta);
    case "worker-action": return renderWorkerAction(meta);
    case "merchant-route": return renderMerchantRoute(meta);
    case "artifact-storage": return renderArtifactStorage(meta);
    case "map-inspection": return renderMapInspection(meta);
    case "resource-gold": return renderResourceBreakdown(meta, "gold");
    case "resource-science": return renderResourceBreakdown(meta, "science");
    case "resource-stability": return renderResourceBreakdown(meta, "stability");
    case "resource-inventory": return renderResourceInventory(meta);
    case "strategic-economy": return renderStrategicEconomy(meta);
    case "victory-status": return renderVictoryStatus(meta);
    case "combat-forecast": return renderCombatForecast(meta);
    case "combat-details": return renderCombatDetails(meta);
    case "game-options": return renderGameOptions(meta);
    case "game-help": return renderGameHelp(meta);
    case "multiplayer-status": return renderMultiplayerStatus(meta);
    case "multiplayer-avatars": return renderMultiplayerAvatars(meta);
    case "hot-seat-handoff": return renderHotSeatHandoff();
    case "game-outcome-victory": return renderGameOutcome(true);
    case "game-outcome-defeat": return renderGameOutcome(false);
    case "first-turn-coachmark": return renderFirstTurnCoachmark();
    default: return "";
  }
};

const preferredScreenForModal = (id) => {
  if (["civilization-met", "diplomatic-message", "diplomatic-proposal"].includes(id)) return "game-map";
  if (["hot-seat-handoff"].includes(id)) return "game-map";
  if (["multiplayer-status", "multiplayer-avatars"].includes(id)) return "game-multiplayer";
  if (["combat-forecast", "combat-details"].includes(id)) return "game-combat";
  if (["city-production", "building-details", "wonder-details", "city-yields", "city-expansion", "selection-buildings"].includes(id)) return "game-city";
  if (["worker-action", "selection-improvements"].includes(id)) return "game-worker";
  if (["map-inspection", "selection-terrain", "selection-resources"].includes(id)) return "game-inspection";
  return "game-map";
};

window.AONW_UI = Object.freeze({
  screens: screenRegistry,
  modals: modalRegistry,
  renderScreen,
  renderModal,
  preferredScreenForModal,
  icon
});
