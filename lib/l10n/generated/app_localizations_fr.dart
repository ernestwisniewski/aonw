// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Age of New Worlds';

  @override
  String defaultPlayerName(int index) {
    return 'Player $index';
  }

  @override
  String defaultCityName(int index) {
    return 'City $index';
  }

  @override
  String get newGameTitle => 'NEW GAME';

  @override
  String get gameModeSinglePlayerMenuLabel => 'Singleplayer';

  @override
  String get gameModeMultiplayerMenuLabel => 'Multiplayer';

  @override
  String get gameModeHotSeatMenuLabel => 'Hot Seat';

  @override
  String get gameModeSinglePlayerSummaryLabel => 'Singleplayer';

  @override
  String get gameModeMultiplayerSummaryLabel => 'Multiplayer';

  @override
  String get gameModeHotSeatSummaryLabel => 'Hot Seat';

  @override
  String get gameModeSinglePlayerMapTitle => 'Choose a map for solo play';

  @override
  String get gameModeMultiplayerMapTitle => 'Choose a map for online play';

  @override
  String get gameModeHotSeatMapTitle => 'Choose a map for hot seat play';

  @override
  String get gameModeSinglePlayerMapSubtitle => 'A local match against AI.';

  @override
  String get gameModeMultiplayerMapSubtitle =>
      'Starting scenario and world map for an online match.';

  @override
  String get gameModeHotSeatMapSubtitle =>
      'Starting scenario and world map for one-device hot seat play.';

  @override
  String get newGameIntroTitle => 'Prepare the expedition';

  @override
  String get newGameIntroSubtitle =>
      'Choose the play style first, then the map, then refine players and match pace.';

  @override
  String get newGameStepPlan => 'Game plan';

  @override
  String get newGameStepMap => 'Map';

  @override
  String get newGameStepReview => 'Review';

  @override
  String get newGamePlanTitle => 'What story do you want to begin?';

  @override
  String get newGamePremiseTitle => 'From settlement to empire';

  @override
  String get newGamePremiseBody =>
      'Every match starts with a few decisive choices: where to found the first city, how to shape research, when to risk expansion, and how to hold map control.';

  @override
  String get newGameCountryTitle => 'Choose civilization';

  @override
  String get newGameCountrySubtitle =>
      'Your ruler name follows the civilization you choose.';

  @override
  String get newGameSinglePlayerSettingsTitle => 'Match settings';

  @override
  String get newGameGameLengthLabel => 'Game length';

  @override
  String get newGameLeaderLabel => 'LEADER';

  @override
  String get newGamePillarCities => 'Cities';

  @override
  String get newGamePillarUnits => 'Units';

  @override
  String get newGamePillarResearch => 'Research';

  @override
  String get newGameVictoryTypesTitle => 'Victory paths';

  @override
  String get newGameVictoryDominationTitle => 'Domination';

  @override
  String newGameVictoryDominationBody(String controlPercent, int holdTurns) {
    return 'Control $controlPercent% of the map and hold it for $holdTurns turns. Conquest can still end the match by eliminating rivals.';
  }

  @override
  String get newGameVictoryArtifactsTitle => 'Artifacts';

  @override
  String newGameVictoryArtifactsBody(int artifactCount, int holdTurns) {
    return 'Place $artifactCount unique world artifacts in your cities and keep the full collection for $holdTurns turns.';
  }

  @override
  String get newGameModeSinglePlayerDescription =>
      'A calm match against AI. Best for learning systems, testing starts, and experimenting with growth.';

  @override
  String get newGameModeMultiplayerDescription =>
      'An online match with network lobby, player readiness, and a shared entry onto the map.';

  @override
  String get newGameModeMultiplayerAlphaDisabled =>
      'Unavailable in the alpha release.';

  @override
  String get newGameModeHotSeatDescription =>
      'Hot seat play on one device. Players pass the turn, while the screen guides each handoff.';

  @override
  String get newGameMapTitle => 'Choose the world';

  @override
  String get newGameMapSubtitle =>
      'The map defines first-contact pace, available resources, city space, and the shape of conflict.';

  @override
  String get newGameReviewTitle => 'Confirm the expedition';

  @override
  String get newGameReviewSubtitle =>
      'After confirming, you will enter the lobby to set game name, match length, and players.';

  @override
  String newGameReviewSinglePlayerSubtitle(int aiCount) {
    return 'Singleplayer starts immediately with you and $aiCount AI players.';
  }

  @override
  String get newGameReviewMissingMap =>
      'Choose a map before configuring players.';

  @override
  String get newGameExpeditionReady => 'Expedition ready';

  @override
  String get newGameSelectedMapLabel => 'Map';

  @override
  String get newGameMapPickLabel => 'Map pick';

  @override
  String get newGameMapPickRandom => 'Random default';

  @override
  String get newGameMapPickManual => 'Chosen manually';

  @override
  String get newGameWorldSourceLabel => 'Source';

  @override
  String newGameSinglePlayerAiSummary(int aiCount) {
    return 'You + $aiCount AI';
  }

  @override
  String get newGameChangeMapAction => 'Change map';

  @override
  String get newGameStartSetupAction => 'Go to lobby';

  @override
  String get mainMenuLoadGame => 'Charger une partie';

  @override
  String get mainMenuDeveloper => 'Outils';

  @override
  String get mainMenuSettings => 'Paramètres';

  @override
  String get mainMenuSettingsSublabel => 'Texte et audio';

  @override
  String get mainMenuExit => 'Quitter';

  @override
  String get mainMenuAiSublabel => 'IA';

  @override
  String get mainMenuOnlineSublabel => 'Réseau';

  @override
  String get mainMenuLocalSublabel => 'Local';

  @override
  String get mainMenuToolsSublabel => 'Éditeurs';

  @override
  String get mainMenuToolsTitle => 'Outils';

  @override
  String get mainMenuMapEditor => 'Éditeur de carte';

  @override
  String get mainMenuAssetsEditor => 'Éditeur de ressources';

  @override
  String get mainMenuTextSize => 'Taille du texte';

  @override
  String get mainMenuTextSample => 'Exemple de texte de jeu';

  @override
  String get mainMenuManual => 'Manuel';

  @override
  String get mainMenuCredits => 'Crédits';

  @override
  String get mainMenuFeedback => 'Retour';

  @override
  String get manualTitle => 'Controls manual';

  @override
  String get manualSubtitle =>
      'A quick reference for map movement, selection, orders, panels, and turn flow across desktop and mobile.';

  @override
  String get manualMetaDesktop => 'Desktop';

  @override
  String get manualMetaMobile => 'Mobile';

  @override
  String get manualMetaAlpha => 'Single-player alpha';

  @override
  String get manualCommandLoopTitle => 'Core command loop';

  @override
  String get manualCommandLoopSelectTitle => 'Select';

  @override
  String get manualCommandLoopSelectBody =>
      'Choose a unit, city, artifact, or map tile to reveal the actions that matter now.';

  @override
  String get manualCommandLoopPreviewTitle => 'Preview';

  @override
  String get manualCommandLoopPreviewBody =>
      'Hover or tap once to inspect targets, intent colors, routes, and blocked actions.';

  @override
  String get manualCommandLoopConfirmTitle => 'Confirm';

  @override
  String get manualCommandLoopConfirmBody =>
      'Use an action chip or choose the highlighted target again to commit the order.';

  @override
  String get manualCommandLoopAdvanceTitle => 'Advance';

  @override
  String get manualCommandLoopAdvanceBody =>
      'Use the bottom action button to jump to the next decision or finish the turn.';

  @override
  String get manualDesktopTitle => 'Desktop controls';

  @override
  String get manualDesktopSubtitle =>
      'Mouse-first play with fast map inspection, precise targeting, and persistent panels.';

  @override
  String get manualMobileTitle => 'Mobile controls';

  @override
  String get manualMobileSubtitle =>
      'Touch-first play tuned for readable panels, deliberate orders, and quick turn flow.';

  @override
  String get manualMapCameraGroup => 'Map & camera';

  @override
  String get manualOrdersGroup => 'Selection & orders';

  @override
  String get manualPanelsGroup => 'Panels & help';

  @override
  String get manualTurnFlowGroup => 'Turn flow';

  @override
  String get manualDesktopLeftClickAction => 'Left click';

  @override
  String get manualDesktopLeftClickBody =>
      'Select units, cities, artifacts, and tiles; with an active order, choose the target.';

  @override
  String get manualDesktopDragAction => 'Drag the map';

  @override
  String get manualDesktopDragBody =>
      'Pan the camera without changing the current selection or command mode.';

  @override
  String get manualDesktopZoomAction => 'Mouse wheel / trackpad';

  @override
  String get manualDesktopZoomBody =>
      'Zoom between strategic overview and tactical detail on the map.';

  @override
  String get manualDesktopHoverAction => 'Hover';

  @override
  String get manualDesktopHoverBody =>
      'Preview tooltips, target hints, and blocked-order reasons before committing.';

  @override
  String get manualDesktopActionChipsAction => 'Action chips';

  @override
  String get manualDesktopActionChipsBody =>
      'Move, attack, improve, found a city, skip, fortify, or cancel the current mode.';

  @override
  String get manualDesktopSecondClickAction => 'Same target twice';

  @override
  String get manualDesktopSecondClickBody =>
      'For movement, the first click previews the route; the second click executes or queues it.';

  @override
  String get manualDesktopHoldAction => 'Click and hold';

  @override
  String get manualDesktopHoldBody =>
      'Open detailed command explanations for actions, disabled options, and context chips.';

  @override
  String get manualDesktopRailAction => 'Left rail';

  @override
  String get manualDesktopRailBody =>
      'Open map options, help, objectives, activity log, research, and empire panels.';

  @override
  String get manualDesktopTopPillsAction => 'Top resources';

  @override
  String get manualDesktopTopPillsBody =>
      'Inspect economy, science, resources, and victory pressure breakdowns.';

  @override
  String get manualDesktopCloseAction => 'Click outside';

  @override
  String get manualDesktopCloseBody =>
      'Close popups, option panels, and help cards, then return focus to the map.';

  @override
  String get manualDesktopHelpAction => '?';

  @override
  String get manualDesktopHelpBody =>
      'Open every minimized hint and tutorial card at any time, regardless of selection.';

  @override
  String get manualDesktopTurnAction => 'Next decision';

  @override
  String get manualDesktopTurnBody =>
      'Focus the next unit, research, or city choice; end the turn when nothing blocks progress.';

  @override
  String get manualMobileTapAction => 'Tap';

  @override
  String get manualMobileTapBody =>
      'Select units, cities, artifacts, and tiles; with an active order, choose the target.';

  @override
  String get manualMobileDragAction => 'One-finger drag';

  @override
  String get manualMobileDragBody =>
      'Pan the camera while keeping the selected unit or panel state intact.';

  @override
  String get manualMobilePinchAction => 'Pinch';

  @override
  String get manualMobilePinchBody =>
      'Zoom the map for scouting, city work, movement planning, or battle targeting.';

  @override
  String get manualMobileSecondTapAction => 'Same target twice';

  @override
  String get manualMobileSecondTapBody =>
      'Preview a movement route first, then tap the same hex again to execute or queue it.';

  @override
  String get manualMobileActionChipsAction => 'Action chips';

  @override
  String get manualMobileActionChipsBody =>
      'Use the bottom command row for unit orders, city choices, workers, and cancel actions.';

  @override
  String get manualMobileHoldAction => 'Press and hold';

  @override
  String get manualMobileHoldBody =>
      'Open explanations for commands, disabled options, resources, and contextual UI.';

  @override
  String get manualMobileScrollAction => 'Scroll panels';

  @override
  String get manualMobileScrollBody =>
      'Browse long city, research, log, diplomacy, and help lists without losing map state.';

  @override
  String get manualMobileRailAction => 'Left rail';

  @override
  String get manualMobileRailBody =>
      'Tap to open map options, help, objectives, activity log, research, and empire panels.';

  @override
  String get manualMobileHelpAction => '?';

  @override
  String get manualMobileHelpBody =>
      'Review every minimized hint and tutorial card whenever you need a refresher.';

  @override
  String get manualMobileTurnAction => 'Bottom action';

  @override
  String get manualMobileTurnBody =>
      'Jump to the next required decision or end the turn once all action points are spent.';

  @override
  String get mainMenuWhatsNew => 'Nouveautés';

  @override
  String get mainMenuWhatsNewBody =>
      'Bienvenue dans Age of New Worlds. Construisez des villes, dirigez des commandants, découvrez de nouvelles terres et écrivez l\'histoire de votre civilisation.';

  @override
  String get mainMenuUpdateSoonTitle => 'Mise à jour en approche';

  @override
  String get mainMenuUpdateSoonBody =>
      'Une nouvelle version est prête et apparaîtra bientôt sur cette plateforme. Vérifiez à nouveau votre boutique ou lanceur sous peu.';

  @override
  String get gameModeLabel => 'MODE';

  @override
  String get gameNameLabel => 'GAME NAME';

  @override
  String get playersLabel => 'PLAYERS';

  @override
  String get countryLabel => 'COUNTRY';

  @override
  String get countryPoland => 'Poland';

  @override
  String get countryUkraine => 'Ukraine';

  @override
  String get countryGermany => 'Germany';

  @override
  String get countryFrance => 'France';

  @override
  String get countryUnitedKingdom => 'United Kingdom';

  @override
  String get countryItaly => 'Italy';

  @override
  String get countrySpain => 'Spain';

  @override
  String get countryNetherlands => 'Netherlands';

  @override
  String get countrySweden => 'Sweden';

  @override
  String get countryRussia => 'Russia';

  @override
  String get countryUnitedStates => 'United States';

  @override
  String get countryCanada => 'Canada';

  @override
  String get countryChina => 'China';

  @override
  String get countryKorea => 'Korea';

  @override
  String get countryJapan => 'Japan';

  @override
  String get countryPortugal => 'Portugal';

  @override
  String get countryLeaderPoland => 'Casimir III the Great';

  @override
  String get countryLeaderUkraine => 'Yaroslav the Wise';

  @override
  String get countryLeaderGermany => 'Otto von Bismarck';

  @override
  String get countryLeaderFrance => 'Napoleon Bonaparte';

  @override
  String get countryLeaderUnitedKingdom => 'Queen Victoria';

  @override
  String get countryLeaderItaly => 'Julius Caesar';

  @override
  String get countryLeaderSpain => 'Isabella I';

  @override
  String get countryLeaderNetherlands => 'William of Orange';

  @override
  String get countryLeaderSweden => 'Gustavus Adolphus';

  @override
  String get countryLeaderRussia => 'Catherine the Great';

  @override
  String get countryLeaderUnitedStates => 'Abraham Lincoln';

  @override
  String get countryLeaderCanada => 'Wilfrid Laurier';

  @override
  String get countryLeaderChina => 'Qin Shi Huang';

  @override
  String get countryLeaderKorea => 'Sejong the Great';

  @override
  String get countryLeaderJapan => 'Tokugawa Ieyasu';

  @override
  String get countryLeaderPortugal => 'Henry the Navigator';

  @override
  String get addPlayerAction => '+ ADD PLAYER';

  @override
  String get startGameAction => 'START';

  @override
  String get removePlayerTooltip => 'Remove player';

  @override
  String get multiplayerSearchTitle => 'SERVER SEARCH';

  @override
  String get multiplayerSearchBody =>
      'The list of online games will appear here.';

  @override
  String get multiplayerPlayersTitle => 'Players';

  @override
  String get multiplayerStatusTooltip => 'Player status';

  @override
  String multiplayerAvatarTooltip(String playerName, String status) {
    return '$playerName - $status';
  }

  @override
  String multiplayerAvatarTooltipWithRelation(
    String playerName,
    String status,
    String relation,
  ) {
    return '$playerName - $status\nRelations: $relation';
  }

  @override
  String multiplayerPlayerTooltip(String playerName, String defaultName) {
    return '$playerName\n$defaultName';
  }

  @override
  String multiplayerPlayerTooltipWithRelation(
    String playerName,
    String defaultName,
    String relation,
  ) {
    return '$playerName\n$defaultName\nRelations: $relation';
  }

  @override
  String get multiplayerStatusActive => 'playing now';

  @override
  String get multiplayerStatusSubmitted => 'turn sent';

  @override
  String get multiplayerStatusThinking => 'thinking';

  @override
  String get multiplayerStatusWaiting => 'waiting';

  @override
  String get multiplayerStatusTimeout => 'timeout';

  @override
  String get diplomacyRelationFriendly => 'friendly';

  @override
  String get diplomacyRelationNeutral => 'neutral';

  @override
  String get diplomacyRelationHostile => 'hostile';

  @override
  String get diplomacyRelationTruce => 'truce';

  @override
  String get diplomacyRelationWar => 'war';

  @override
  String get diplomacyRelationFriendlyShort => 'fr.';

  @override
  String get diplomacyRelationNeutralShort => 'neut.';

  @override
  String get diplomacyRelationHostileShort => 'host.';

  @override
  String get diplomacyRelationTruceShort => 'truce';

  @override
  String get diplomacyRelationWarShort => 'war';

  @override
  String get commonDiplomacy => 'Diplomacy';

  @override
  String get diplomacyScoreLabel => 'Relations';

  @override
  String get diplomacyScoreDriversTitle => 'What changes relations';

  @override
  String get diplomacyScoreReasonManual => 'Manual change';

  @override
  String get diplomacyScoreReasonUnitAttack => 'Unit attack';

  @override
  String get diplomacyScoreReasonCityAttack => 'City attack';

  @override
  String get diplomacyScoreReasonDeclarationOfWar => 'Declaration of war';

  @override
  String get diplomacyScoreReasonProposalAccepted => 'Proposal accepted';

  @override
  String get diplomacyScoreReasonProposalRejected => 'Proposal rejected';

  @override
  String get diplomacyScoreReasonMessageResponse => 'Dispatch response';

  @override
  String get diplomacyScoreReasonPromiseBroken => 'Promise broken';

  @override
  String get diplomacyStatsTitle => 'Stats';

  @override
  String get diplomacyHistoryTitle => 'History';

  @override
  String get diplomacyMessagesTitle => 'Dispatches';

  @override
  String get diplomacyIncomingMessageTitle => 'New dispatch';

  @override
  String diplomacyIncomingMessageFrom(String playerName) {
    return 'From: $playerName';
  }

  @override
  String get diplomacyIncomingProposalTitle => 'New proposal';

  @override
  String diplomacyIncomingProposalFrom(String playerName) {
    return 'From: $playerName';
  }

  @override
  String get diplomacyIncomingMessageLater => 'Later';

  @override
  String get diplomacyActionsTitle => 'Actions';

  @override
  String get diplomacyProposalsTitle => 'Proposals';

  @override
  String get diplomacyNoHistory => 'No recorded incidents.';

  @override
  String get diplomacyNoMessages => 'No dispatches.';

  @override
  String get diplomacyMilitaryStat => 'Military';

  @override
  String get diplomacyCitiesStat => 'Cities';

  @override
  String get diplomacyExpansionStat => 'Expansion';

  @override
  String get diplomacyArtifactsStat => 'Artifacts';

  @override
  String get diplomacyLastAggressionStat => 'Last aggression';

  @override
  String get diplomacyOwnArtifactsLabel => 'Your artifacts';

  @override
  String get diplomacyTargetArtifactsLabel => 'Rival artifacts';

  @override
  String diplomacyTurnsRemaining(int turns) {
    return 'Turns left: $turns';
  }

  @override
  String get diplomacyProposalFriendship => 'Friendship proposal';

  @override
  String get diplomacyProposalTruce => 'Truce proposal';

  @override
  String get diplomacySendFriendship => 'Propose friendship';

  @override
  String get diplomacySendTruce => 'Propose truce';

  @override
  String get diplomacyDeclareWar => 'Declare war';

  @override
  String get diplomacyAccept => 'Accept';

  @override
  String get diplomacyDecline => 'Decline';

  @override
  String get diplomacyMessageTroopsNearCities =>
      'Too many troops are positioned near my cities.';

  @override
  String get diplomacyMessageCitiesTooClose =>
      'You are founding cities too close to my borders.';

  @override
  String get diplomacyMessageBlockedRoutes =>
      'Your units are blocking my routes.';

  @override
  String get diplomacyMessageWithdrawScouts =>
      'Please withdraw your scouts from my territory.';

  @override
  String get diplomacyMessageAvoidEscalation =>
      'Our civilizations should avoid further escalation.';

  @override
  String get diplomacyMessageCommonEnemy => 'A common enemy threatens us both.';

  @override
  String get diplomacyMessageExpansionProvocation =>
      'Your expansion is seen as a provocation.';

  @override
  String get diplomacyMessagePeacefulPraise =>
      'We value the peaceful relations between our peoples.';

  @override
  String get diplomacyResponseConciliatory => 'Conciliatory';

  @override
  String get diplomacyResponseNeutral => 'Neutral';

  @override
  String get diplomacyResponseEvasive => 'Evasive';

  @override
  String get diplomacyResponseAggressive => 'Aggressive';

  @override
  String get diplomacyStrategicResourcesTitle => 'Strategic resources';

  @override
  String get diplomacyResourceTradeBlockedByWar =>
      'Resource trade is blocked by war.';

  @override
  String get diplomacyResourceTradeNoAvailableResources =>
      'No spare strategic resources are available for trade.';

  @override
  String diplomacyResourceTradeImportOffer(int goldPerTurn, int durationTurns) {
    return 'Import offer: $goldPerTurn gold/turn for $durationTurns turns.';
  }

  @override
  String diplomacyResourceTradeImportAction(String resourceName) {
    return 'Import $resourceName';
  }

  @override
  String diplomacyResourceTradeExchangeOffer(int durationTurns) {
    return 'Barter exchange: resource for resource for $durationTurns turns.';
  }

  @override
  String diplomacyResourceTradeExchangeAction(
    String offeredResource,
    String requestedResource,
  ) {
    return 'Trade $offeredResource for $requestedResource';
  }

  @override
  String get diplomacyResourceTradeNoActiveAgreements =>
      'No active resource agreements.';

  @override
  String get diplomacyResourceTradeImportDirection => 'Importing';

  @override
  String get diplomacyResourceTradeExportDirection => 'Exporting';

  @override
  String get diplomacyResourceTradeBarterPrice => 'barter';

  @override
  String diplomacyResourceTradeGoldPerTurnPrice(int goldPerTurn) {
    return '$goldPerTurn gold/turn';
  }

  @override
  String diplomacyResourceTradeAgreementLabel(
    String direction,
    String resourceName,
    String price,
    int remainingTurns,
  ) {
    return '$direction $resourceName · $price · $remainingTurns turns';
  }

  @override
  String get notFoundScreenTitle => 'Screen not found';

  @override
  String get notFoundBackToMenuAction => 'MENU';

  @override
  String get loadGameTitle => 'LOAD GAME';

  @override
  String get loadGameHeaderTitle => 'Saved games';

  @override
  String get loadGameHeaderEmptySubtitle => 'No game has been started yet.';

  @override
  String get loadGameHeaderSavesSubtitle =>
      'Return to recent matches and continue from the saved turn.';

  @override
  String loadGameSavesCount(int count) {
    return 'Saves: $count';
  }

  @override
  String get loadGameCorruptedStatus => 'Corrupted save';

  @override
  String get loadGameCorruptedAction => 'Unavailable';

  @override
  String get loadGameCorruptedBody =>
      'This save cannot be read. You can remove it from the list.';

  @override
  String get replayTitle => 'REPLAY';

  @override
  String get replayAction => 'REPLAY';

  @override
  String get replayUnavailableAction => 'NO REPLAY';

  @override
  String get replayErrorTitle => 'Replay unavailable';

  @override
  String replayErrorBody(String error) {
    return 'Replay cannot be opened: $error';
  }

  @override
  String get replayMissingInitialSnapshotBody =>
      'This save does not contain a replay seed snapshot. Start a new game to record full-match replay data.';

  @override
  String get replayCorruptLogBody =>
      'The replay command log is incomplete or cannot be read.';

  @override
  String replayStepCounter(int step, int total) {
    return 'Step $step/$total';
  }

  @override
  String endTurnButtonTurnLabel(int turn) {
    return 'TURN $turn';
  }

  @override
  String replayTurnLabel(int turn) {
    return 'Turn $turn';
  }

  @override
  String replayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events',
      one: '1 event',
      zero: '0 events',
    );
    return '$_temp0';
  }

  @override
  String get replayInitialStateLabel => 'Initial state';

  @override
  String get replayPreviousAction => 'Previous step';

  @override
  String get replayNextAction => 'Next step';

  @override
  String get replayPlayAction => 'Play replay';

  @override
  String get replayPauseAction => 'Pause replay';

  @override
  String get replaySpeedLabel => 'Speed';

  @override
  String get replayPerspectiveLabel => 'Perspective';

  @override
  String get replayAllPlayers => 'All players';

  @override
  String get replayShowTurnsLabel => 'Show turns';

  @override
  String get replayFreeCameraLabel => 'Free camera';

  @override
  String mapsLoadError(String error) {
    return 'Could not load maps: $error';
  }

  @override
  String get editorMapPickerTitle => 'Editor maps';

  @override
  String get editorMapPickerSubtitle =>
      'Create new worlds or refine existing maps.';

  @override
  String get editorMapPickerEmptyTitle => 'No saved maps';

  @override
  String get editorMapPickerEmptyMessage =>
      'Create a new map from the screen header.';

  @override
  String get editorNewMapAction => 'New map';

  @override
  String get editorDeleteMapTooltip => 'Delete map';

  @override
  String get editorDeleteMapTitle => 'Delete map?';

  @override
  String editorDeleteMapMessage(String name) {
    return 'This will permanently delete “$name” and all map files.';
  }

  @override
  String get editorOpenMapErrorTitle => 'Could not open map';

  @override
  String get editorCollapseToolbarTooltip => 'Collapse editor panel';

  @override
  String get editorExpandToolbarTooltip => 'Expand editor panel';

  @override
  String officialMapsCount(int count) {
    return 'Official: $count';
  }

  @override
  String yourMapsCount(int count) {
    return 'Yours: $count';
  }

  @override
  String get officialMapsSection => 'Official';

  @override
  String get yourMapsSection => 'Your maps';

  @override
  String get playAction => 'Play';

  @override
  String get editAction => 'Edit';

  @override
  String get noMapsTitle => 'No maps';

  @override
  String get noMapsMessage => 'No maps were found to start a game.';

  @override
  String get gameLengthLabel => 'Game length';

  @override
  String get gameLengthPresetHint => 'Game preset';

  @override
  String get gameLengthPresetUnlimited => 'Unlimited';

  @override
  String get gameLengthPresetShort60 => 'Short';

  @override
  String get gameLengthPresetNormal90 => 'Normal';

  @override
  String get gameLengthPresetStandard60 => 'Standard 60 min';

  @override
  String get gameLengthPresetLong120 => 'Long';

  @override
  String get gameLengthPresetVeryLong => 'Very long';

  @override
  String get gameLengthUnlimitedSummary => 'No turn limit - current game pace';

  @override
  String gameLengthTimedSummary(int minutes, int turns) {
    return '$minutes min target - $turns turn limit';
  }

  @override
  String get gameLengthScoreFallbackOn => 'with score fallback';

  @override
  String get gameLengthScoreFallbackOff => 'without score fallback';

  @override
  String get aiDifficultyLabel => 'AI difficulty';

  @override
  String get aiDifficultyEasy => 'Easy';

  @override
  String get aiDifficultyNormal => 'Normal';

  @override
  String get aiDifficultyHard => 'Hard';

  @override
  String get aiDifficultyVeryHard => 'Very hard';

  @override
  String gameLengthVictoryRules(
    String controlPercent,
    int holdTurns,
    String fallback,
  ) {
    return 'Conquest + domination $controlPercent%/$holdTurns turns - $fallback';
  }

  @override
  String get mapValidationErrorTitle => 'Map needs fixes';

  @override
  String get mapValidationLoadingTitle => 'Checking map';

  @override
  String get mapValidationWarningTitle => 'Map may be too slow for this preset';

  @override
  String mapValidationLoadError(String error) {
    return 'Could not check map: $error';
  }

  @override
  String get mapValidationLoadingMessage =>
      'Validating starts, resources, and first-contact pacing.';

  @override
  String get mapValidationIssueSlowFirstContact =>
      'Starting positions are far apart; 60 min may delay first contact too much.';

  @override
  String get mapValidationIssueLargeMap =>
      'The map has many tiles per player; add players or choose a longer game.';

  @override
  String get mapValidationIssueInvalidPlayerCount =>
      'Player count does not match the range supported by this map.';

  @override
  String get mapValidationIssueNoTiles => 'The map has no tiles.';

  @override
  String get mapValidationIssueLowPassableTileRatio =>
      'The map has too few tiles passable by land units.';

  @override
  String get mapValidationIssueLowFoodResourceDensity =>
      'The map has too few food resources for this player count.';

  @override
  String get mapValidationIssueLowStrategicResourceDensity =>
      'The map has too few strategic resources.';

  @override
  String get mapValidationIssueLowLuxuryResourceDensity =>
      'The map has too few luxury resources.';

  @override
  String get mapValidationIssueStartSiteNotFoundable =>
      'The starting settler cannot found a city on its tile.';

  @override
  String get mapValidationIssueStartSiteLowLandRing =>
      'The start has too few passable tiles in the first ring.';

  @override
  String get mapValidationIssueStartSiteLowFood =>
      'The start has no visible food resource nearby.';

  @override
  String get mapValidationIssueStartSiteLowCityControl =>
      'The start has too few legal tiles for initial city control.';

  @override
  String get mapValidationIssueStartSitesTooClose =>
      'Player starts are too close to each other.';

  @override
  String lobbyMapPlayersSummary(String mapName, int playerCount) {
    return '$mapName - $playerCount players';
  }

  @override
  String get lobbyHeaderTitle => 'Prepare the table';

  @override
  String get lobbyHeaderSubtitle =>
      'Confirm civilization first, then tune the match and seats before the first turn.';

  @override
  String get lobbyCivilizationTitle => 'Choose civilization';

  @override
  String get lobbyCivilizationSubtitle =>
      'This is player one\'s identity for the opening turn.';

  @override
  String get lobbyStepCivilization => 'Civilization';

  @override
  String get lobbyStepSetup => 'Setup';

  @override
  String get lobbyStepOnline => 'Online';

  @override
  String get lobbyStepPlayers => 'Players';

  @override
  String get lobbySetupTitle => 'Match setup';

  @override
  String get lobbySetupSubtitle =>
      'Name the game, choose the pace, and check whether the map fits the selected player count.';

  @override
  String get lobbyPlayersSetupTitle => 'Players at the table';

  @override
  String get lobbyPlayersSetupSubtitle =>
      'The first player takes the opening turn. Extra seats can be people on this device or AI.';

  @override
  String get lobbyPlayerYou => 'You';

  @override
  String get lobbyPlayerHost => 'Host';

  @override
  String get lobbyPlayerReady => 'ready';

  @override
  String get lobbyPlayerConnected => 'connected';

  @override
  String get lobbyPlayerConnecting => 'connecting';

  @override
  String get lobbyPlayerReconnecting => 'reconnecting';

  @override
  String get lobbyPlayerOffline => 'offline';

  @override
  String lobbyPlayerOpenSlot(int slotNumber) {
    return 'Open seat $slotNumber';
  }

  @override
  String get lobbyPlayerRequiredSlot => 'Needed to start';

  @override
  String get lobbyPlayerOptionalSlot => 'Can join before start';

  @override
  String get playerKindHuman => 'Human';

  @override
  String get playerKindAi => 'AI';

  @override
  String get multiplayerServerTitle => 'Online game server';

  @override
  String get connectAction => 'Connect';

  @override
  String get refreshAction => 'Refresh';

  @override
  String get createMatchAction => 'Create match';

  @override
  String get noOpenMatches => 'No open matches';

  @override
  String get matchStatusRunning => 'Ready';

  @override
  String get matchStatusFinished => 'Finished';

  @override
  String get matchStatusAbandoned => 'Abandoned';

  @override
  String matchPlayersCount(int players, int maxPlayers) {
    return '$players/$maxPlayers players';
  }

  @override
  String matchReadyCount(int readyPlayers, int players) {
    return '$readyPlayers/$players ready';
  }

  @override
  String matchTurnInfo(String mapName, String status, int turn) {
    return '$mapName - $status - turn $turn';
  }

  @override
  String openMatchInfo(String mapName, int players, int maxPlayers, int turn) {
    return '$mapName - $players/$maxPlayers - turn $turn';
  }

  @override
  String get enterMatchAction => 'Enter';

  @override
  String get hideMatchAction => 'Hide';

  @override
  String get joinMatchAction => 'Join';

  @override
  String get cancelAction => 'CANCEL';

  @override
  String get copyAction => 'Copy';

  @override
  String get shareAction => 'Share';

  @override
  String get multiplayerHomeSubtitle =>
      'Choose a quick queue or a private code match for friends.';

  @override
  String get multiplayerProfileTitle => 'Your profile';

  @override
  String get multiplayerProfileSubtitle =>
      'Set the name and civilization you will use in online matches.';

  @override
  String get multiplayerProfileOptionsSubtitle =>
      'Your nickname is used in multiplayer matches and must be unique.';

  @override
  String get multiplayerProfileSaveAction => 'Save nickname';

  @override
  String get multiplayerProfileSaved => 'Nickname saved.';

  @override
  String get multiplayerLobbyHeaderTitle => 'Online lobby';

  @override
  String get multiplayerLobbyHeaderSubtitle =>
      'Choose civilization first, then enter quickplay or create a private table. The map is selected automatically.';

  @override
  String get multiplayerCountryPickTitle => 'Choose civilization';

  @override
  String get multiplayerCountryPickSubtitle =>
      'This is the key choice before entering the queue. Multiplayer maps are selected at random.';

  @override
  String get multiplayerRandomMapLabel => 'Random map';

  @override
  String get multiplayerNicknameLabel => 'Nickname';

  @override
  String get multiplayerQuickplayTitle => 'Quick game';

  @override
  String get multiplayerQuickplaySubtitle =>
      'Finds players automatically and starts from 2 players.';

  @override
  String get multiplayerCreatePrivateTitle => 'Create code';

  @override
  String get multiplayerCreatePrivateSubtitle =>
      'Private match with no time limit, only for friends.';

  @override
  String get multiplayerJoinPrivateTitle => 'Join with code';

  @override
  String get multiplayerJoinPrivateSubtitle =>
      'Enter a friend\'s code and wait for the host.';

  @override
  String get multiplayerQueueReadyTitle => 'Match ready';

  @override
  String get multiplayerQueueSearchingTitle => 'Searching for players';

  @override
  String get multiplayerQueueCountdownTitle => 'Starting soon';

  @override
  String get multiplayerQueueConnectingSubtitle =>
      'Connecting to the server and looking for a queue.';

  @override
  String multiplayerQueueWaitingForPlayers(int minPlayers) {
    return 'Waiting for at least $minPlayers players.';
  }

  @override
  String get multiplayerQueuePreparingStart =>
      'Players found. Preparing match start.';

  @override
  String get multiplayerQueueStartingNow => 'Starting match...';

  @override
  String multiplayerQueueStartingIn(int seconds) {
    return 'Starting in ${seconds}s. More players can still join.';
  }

  @override
  String get multiplayerPrivateTitle => 'Friends match';

  @override
  String get multiplayerPrivateHostReady => 'You can start the match now.';

  @override
  String get multiplayerPrivateWaitingForHost =>
      'Waiting for the host to start the match.';

  @override
  String get multiplayerJoinCodeHelp =>
      'Enter the code you received from a friend.';

  @override
  String get multiplayerInviteCodeHint => 'Match code';

  @override
  String get multiplayerInviteCodeLabel => 'Match code';

  @override
  String get multiplayerInviteCopied => 'Match code copied.';

  @override
  String multiplayerInviteShareText(String inviteCode) {
    return 'Join my AONW match. Code: $inviteCode';
  }

  @override
  String get multiplayerInviteCodeRequired => 'Enter a match code.';

  @override
  String get multiplayerMapNotReady => 'This map is not ready for multiplayer.';

  @override
  String multiplayerRequestRejected(int statusCode) {
    return 'The server rejected the request ($statusCode).';
  }

  @override
  String multiplayerRequestRejectedWithReason(int statusCode, String reason) {
    return 'The server rejected the request ($statusCode: $reason).';
  }

  @override
  String multiplayerConnectionError(String host) {
    return 'Could not connect to $host. Check your internet connection and try again.';
  }

  @override
  String get multiplayerSignInRequired =>
      'Sign in or create an account to play multiplayer.';

  @override
  String get multiplayerSessionExpired =>
      'Your multiplayer session expired. Sign in again and retry.';

  @override
  String get multiplayerAccountTitle => 'Multiplayer account';

  @override
  String get multiplayerAccountSubtitle =>
      'Sign in or create an account to continue.';

  @override
  String get multiplayerAccountEmailLabel => 'Email';

  @override
  String get multiplayerAccountPasswordLabel => 'Password';

  @override
  String get multiplayerAccountSignInTab => 'Sign in';

  @override
  String get multiplayerAccountCreateTab => 'Create account';

  @override
  String get multiplayerAccountSignInAction => 'Sign in';

  @override
  String get multiplayerAccountCreateAction => 'Create account';

  @override
  String get multiplayerAccountSignOutAction => 'Sign out';

  @override
  String get multiplayerAccountSignedOut => 'Signed out of multiplayer.';

  @override
  String get multiplayerAccountInvalidEmail => 'Enter a valid email address.';

  @override
  String get multiplayerAccountInvalidCredentials =>
      'Invalid email or password.';

  @override
  String get multiplayerAccountExists =>
      'An account with this email already exists.';

  @override
  String get multiplayerAccountWeakPassword =>
      'Password must be at least 8 characters long.';

  @override
  String get multiplayerAccountInvalidNickname =>
      'Use 3-24 letters, numbers, spaces, _ or -.';

  @override
  String get multiplayerAccountNicknameTaken =>
      'This nickname is already taken.';

  @override
  String get multiplayerAccountGenericError =>
      'Could not authenticate. Try again.';

  @override
  String get multiplayerMatchUnavailable =>
      'This match is no longer available.';

  @override
  String get multiplayerMatchFull => 'This match is full.';

  @override
  String get multiplayerCountryUnavailable =>
      'Multiple players picked your civilization. Try another one.';

  @override
  String get multiplayerMatchNotReady => 'The match is not ready to start yet.';

  @override
  String get multiplayerMatchAccessDenied =>
      'You are not a player in this match.';

  @override
  String get multiplayerQueueGenericError =>
      'Could not enter the multiplayer queue. Try again.';

  @override
  String get multiplayerResumeAction => 'Resume game';

  @override
  String get multiplayerResumeSublabel =>
      'Return to the last multiplayer session';

  @override
  String get multiplayerResumeLoading => 'Connecting to match...';

  @override
  String get multiplayerResumeFailed =>
      'Could not resume the last multiplayer session.';

  @override
  String get optionsTooltip => 'Options';

  @override
  String get optionsOpenMenuTooltip => 'Ouvrir le menu';

  @override
  String optionsTooltipWithCollapseHint(String tooltip) {
    return '$tooltip. Maintenez pour réduire le menu.';
  }

  @override
  String get optionsTitle => 'Options';

  @override
  String get optionsSubtitle => 'Texte, langue, audio et performances';

  @override
  String get languageSectionTitle => 'Langue';

  @override
  String get languagePolish => 'Polonais';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Allemand';

  @override
  String get languageSpanish => 'Espagnol';

  @override
  String get languageDutch => 'Néerlandais';

  @override
  String get textScaleStandard => 'Standard';

  @override
  String get textScaleLarge => 'Grand';

  @override
  String get textScaleExtraLarge => 'Très grand';

  @override
  String textScaleSemanticLabel(String label) {
    return 'Taille du texte $label';
  }

  @override
  String textScaleTooltip(String label) {
    return 'Taille du texte: $label';
  }

  @override
  String languageSemanticLabel(String label) {
    return 'Langue $label';
  }

  @override
  String languageTooltip(String label) {
    return 'Langue: $label';
  }

  @override
  String get audioSectionTitle => 'Audio';

  @override
  String get gameSoundsLabel => 'Sons du jeu';

  @override
  String get soundVolumeLabel => 'Volume des sons';

  @override
  String get gameMusicLabel => 'Musique du jeu';

  @override
  String get musicVolumeLabel => 'Volume de la musique';

  @override
  String get natureSoundsLabel => 'Ambiance naturelle';

  @override
  String get natureVolumeLabel => 'Volume de l\'ambiance';

  @override
  String get aiSectionTitle => 'IA';

  @override
  String get aiBatterySaverLabel => 'Économie de batterie pour l\'IA';

  @override
  String get gameplaySectionTitle => 'Gameplay';

  @override
  String get followUnitMovementCameraLabel =>
      'Suivre les déplacements des unités avec la caméra';

  @override
  String get followEnemyUnitCameraLabel =>
      'Suivre les unités ennemies avec la caméra';

  @override
  String get cinematicCameraLabel => 'Caméra cinématique';

  @override
  String get performanceSectionTitle => 'Performances';

  @override
  String get showFpsLabel => 'Afficher les FPS';

  @override
  String get showMapZoomLabel => 'Afficher le zoom de la carte';

  @override
  String get mapViewModeTooltip => 'Change map view mode';

  @override
  String get mapViewGraphicUnavailableTooltip =>
      'Graphic mode is unavailable for this map';

  @override
  String get mapViewModeGraphic => 'Graphic';

  @override
  String get mapViewModeTiles => 'Tiles';

  @override
  String get gameOptionTerrain => 'Terrain';

  @override
  String get gameOptionResources => 'Resources';

  @override
  String get gameOptionHeight => 'Height';

  @override
  String get gameOptionCitySites => 'City sites';

  @override
  String get gameOptionCityGrowth => 'City growth';

  @override
  String get gameOptionShowHexes => 'Show hexes';

  @override
  String get gameOptionShowHeight => 'Show height';

  @override
  String get gameOptionDiceTest => 'Dice test';

  @override
  String get gameOptionAutoActionFlow => 'Auto action completion';

  @override
  String get gameOptionAutoTurnFlow => 'Auto turn completion';

  @override
  String get helpPopupsTitle => 'Hints';

  @override
  String get autoTurnHintTitle => 'Auto turn completion';

  @override
  String get autoTurnHintBody =>
      'Auto turn completion submits the turn when no important actions remain. Auto action completion can be controlled separately in map options.';

  @override
  String get autoTurnHintEnableAction => 'Enable';

  @override
  String get autoTurnHintDisableAction => 'Disable';

  @override
  String get autoTurnHintStatusOn => 'Enabled';

  @override
  String get autoTurnHintStatusOff => 'Disabled';

  @override
  String get autoTurnHintMinimizedSubtitle =>
      'Quick toggle for automatic turn flow.';

  @override
  String visibilityShowAction(String label) {
    return 'Show $label';
  }

  @override
  String visibilityHideAction(String label) {
    return 'Hide $label';
  }

  @override
  String get resignAction => 'Resign';

  @override
  String get resignMatchTitle => 'Resign from match?';

  @override
  String get resignMatchMessage => 'The match will be ended.';

  @override
  String get resignMatchError => 'Could not resign from the match.';

  @override
  String get creditsTitle => 'Credits';

  @override
  String creditsCreatedBy(String name) {
    return 'Created by $name';
  }

  @override
  String get deleteGameTitle => 'Delete game';

  @override
  String deleteGameMessage(String name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String get deleteAction => 'DELETE';

  @override
  String get retryAction => 'RETRY';

  @override
  String get noSavedGames => 'No saved games.';

  @override
  String get resumeAction => 'RESUME';

  @override
  String get newGameAction => 'NOUVELLE PARTIE';

  @override
  String get turnActionButtonLabel => 'Action';

  @override
  String get endTurnButtonLabel => 'End turn';

  @override
  String get waitingTurnButtonLabel => 'Waiting';

  @override
  String get waitingForPlayersTooltip => 'Waiting for other players';

  @override
  String submitTurnTooltip(int turn) {
    return 'Submit readiness on turn $turn';
  }

  @override
  String endTurnTooltip(int turn) {
    return 'End turn $turn';
  }

  @override
  String get nextActionTooltip => 'Go to the next action';

  @override
  String nextActionWithCountTooltip(int count) {
    return 'Go to the next action ($count left)';
  }

  @override
  String get turnActionListTooltip => 'Choose an action from the list';

  @override
  String get hudActionDeckCollapseTooltip => 'Collapse bottom toolbar';

  @override
  String get hudActionDeckExpandTooltip => 'Expand bottom toolbar';

  @override
  String get turnActionUnitKind => 'Unit';

  @override
  String get turnActionCityProductionKind => 'City';

  @override
  String get turnActionResearchKind => 'Research';

  @override
  String turnActionCityProductionLabel(String cityName) {
    return '$cityName production';
  }

  @override
  String get turnActionResearchLabel => 'Choose research';

  @override
  String turnLabel(int turn) {
    return 'TURN $turn';
  }

  @override
  String loadGameError(String error) {
    return 'Load error: $error';
  }

  @override
  String get backAction => 'Back';

  @override
  String get continueAction => 'Continue';

  @override
  String get gameLoadingTitle => 'Loading world';

  @override
  String get gameLoadingMessage =>
      'Preparing the map, units, and interface. The game will appear once the assets are ready.';

  @override
  String get firstTurnTutorialPopupTitle => 'Tutorial';

  @override
  String get firstTurnTutorialPopupSubtitle => 'First-turn guide';

  @override
  String firstTurnTutorialSemantics(String title) {
    return 'First turn: $title';
  }

  @override
  String firstTurnCoachmarkProgressLabel(int current, int total) {
    return 'Step $current/$total';
  }

  @override
  String get firstTurnCoachmarkMinimizeTooltip => 'Minimize';

  @override
  String get firstTurnCoachmarkSkipAction => 'Skip';

  @override
  String get firstTurnCoachmarkNextAction => 'Next';

  @override
  String get firstTurnCoachmarkDoneAction => 'Done';

  @override
  String get firstTurnCoachmarkSelectionTitle => 'Step 1: read the selection';

  @override
  String get firstTurnCoachmarkSelectionBody =>
      'The game begins by selecting your first unit automatically. The bottom panel tells you what you command, how many actions remain, and which orders you can give now.';

  @override
  String get firstTurnCoachmarkSelectionBodyUnit =>
      'The bottom toolbar describes the selected unit: type, movement, action queue, and available orders. Use it to enter Move mode and cancel it when you want hex taps to return to inspection.';

  @override
  String get firstTurnCoachmarkSelectionBodyCity =>
      'You have a city selected. The bottom panel shows its production, population, buildings, and economic decisions. That is a different context than unit orders, so the tutorial will talk about the city.';

  @override
  String get firstTurnCoachmarkSelectionBodyNone =>
      'When nothing is selected, the bottom panel shows the general turn state. Tap one of your units or cities to see concrete orders and information.';

  @override
  String get firstTurnCoachmarkResourcesTitle => 'Step 2: check your empire';

  @override
  String get firstTurnCoachmarkResourcesBody =>
      'The top bar shows the turn, gold, science, and resources. Gold sustains the economy, science drives research, and resources hint at what is worth building.';

  @override
  String get firstTurnCoachmarkMenuTitle => 'Step 3: learn the left menu';

  @override
  String get firstTurnCoachmarkMenuBody =>
      'The left menu gathers views you revisit every turn: map options, minimized popup replies, objectives, log, research, and empire. Long-press the menu button to collapse the rail, then tap the single button to open it again.';

  @override
  String get firstTurnCoachmarkActionTitle => 'Step 4: give the right order';

  @override
  String get firstTurnCoachmarkActionBodyActive =>
      'If the settler stands on a good tile, use the found-city action. If the location is weak, move the unit and reveal terrain. Movement and special actions spend that unit\'s turn.';

  @override
  String get firstTurnCoachmarkActionBodyWaiting =>
      'When a unit has an order, it appears here. In the first turns, move through units and cities one by one until no important decision is left behind.';

  @override
  String get firstTurnCoachmarkActionBodySettler =>
      'The settler decides the start of your empire. If the tile offers growth, production, and room to expand, found a city. If the terrain is weak, move the settler and inspect nearby land first.';

  @override
  String get firstTurnCoachmarkActionBodyWorker =>
      'A worker does not found cities. Its job is to improve tiles inside city borders: farms help growth, mines boost production, and resource improvements strengthen the economy.';

  @override
  String get firstTurnCoachmarkActionBodyUnit =>
      'For combat and scouting units, movement, vision, and safety matter most. Reveal terrain, protect city borders, and attack only when the predicted result is favorable.';

  @override
  String get firstTurnCoachmarkActionBodyCity =>
      'With a city selected, this area leads to production and management. Choose a build target, check city growth, and keep the city from sitting idle.';

  @override
  String get firstTurnCoachmarkResearchTitle => 'Step 5: choose research';

  @override
  String get firstTurnCoachmarkResearchBody =>
      'Open Research before ending the turn. Agriculture supports growth, Mining boosts production, and Hunting improves scouting and defense. Most importantly, science should not run without a target.';

  @override
  String get firstTurnCoachmarkResearchBodyAvailable =>
      'Research is ready to choose. Open Research before ending the turn: Agriculture supports growth, Mining boosts production, and Hunting improves scouting and defense.';

  @override
  String get firstTurnCoachmarkCityTitle => 'Step 6: set up the city';

  @override
  String get firstTurnCoachmarkCityBody =>
      'After founding the capital, choose production. A worker develops tiles, a warrior secures the area, and buildings strengthen the economy. The city should always be building something.';

  @override
  String get firstTurnCoachmarkCityBodySelected =>
      'This is the city panel. Check production, growth, buildings, and available projects. The main rule for new turns: every city should have a production target.';

  @override
  String get firstTurnCoachmarkCityBodyNeedsProduction =>
      'One of your cities is waiting for production. Use the action button or select the city, choose a unit, building, or project, and only then end the turn.';

  @override
  String get firstTurnCoachmarkCityBodyExisting =>
      'Your cities already have production assigned. In later turns, return here to watch growth, buildings, specialization, and defense needs.';

  @override
  String get firstTurnCoachmarkCityBodyFuture =>
      'After you found the first city, you will return here to choose production. A worker develops tiles, a warrior secures the area, and buildings strengthen the economy.';

  @override
  String get firstTurnCoachmarkActionFlowTitle =>
      'Step 7: clear the action queue';

  @override
  String get firstTurnCoachmarkActionFlowBodyReady =>
      'All key decisions for this turn are ready. Before ending the turn, quickly confirm that research and city production both have a target.';

  @override
  String get firstTurnCoachmarkActionFlowBodyPending =>
      'The action button leads to the next unit, city, or missing choice. Keep pressing it until the game shows that it is safe to end the turn.';

  @override
  String get firstTurnCoachmarkEndTurnTitle =>
      'Step 8: end the turn and repeat';

  @override
  String get firstTurnCoachmarkEndTurnBody =>
      'When nothing needs your response, end the turn. The rhythm of the next turns is the same: resources, units, city, research, then end turn.';

  @override
  String get firstTurnCoachmarkVictoryBody =>
      'You can win by domination or by artifacts: place 6 unique artifacts in your cities and hold the collection for 5 turns.';

  @override
  String get firstTurnCoachmarkHexTapBody =>
      'Click or tap the same hex several times to cycle its information: tile selection, artifact, map objective, and hex description.';

  @override
  String get gameLoadMapErrorTitle => 'Could not load map';

  @override
  String gameLoadMapErrorMessage(String mapName, String error) {
    return 'Could not load map \"$mapName\": $error';
  }

  @override
  String get gameOutcomeVictoryTitle => 'Victory';

  @override
  String get gameOutcomeDefeatTitle => 'Defeat';

  @override
  String get gameOutcomeDrawTitle => 'Draw';

  @override
  String get gameOutcomeCompleteTitle => 'Game over';

  @override
  String get gameOutcomeConditionConquest => 'Conquest';

  @override
  String get gameOutcomeConditionScore => 'Score';

  @override
  String get gameOutcomeConditionScoreDraw => 'Score draw';

  @override
  String get gameOutcomeConditionDomination => 'Domination';

  @override
  String get gameOutcomeConquestNoWinner => 'One empire remains on the map.';

  @override
  String gameOutcomeConquestWinner(String winner) {
    return '$winner is the last empire on the map.';
  }

  @override
  String get gameOutcomeScoreNoWinner => 'The turn limit decided the result.';

  @override
  String gameOutcomeScoreWinner(String winner) {
    return '$winner wins after the turn limit.';
  }

  @override
  String get gameOutcomeScoreDrawSubtitle =>
      'Turn limit reached. The highest score is tied.';

  @override
  String get gameOutcomeDominationNoWinner => 'Map control was held.';

  @override
  String gameOutcomeDominationWinner(String winner) {
    return '$winner holds territorial domination.';
  }

  @override
  String get gameOutcomeWinnerMetric => 'Winner';

  @override
  String get gameOutcomeConditionMetric => 'Condition';

  @override
  String get gameOutcomeEliminationMetric => 'Elimination';

  @override
  String get gameOutcomeMapControlMetric => 'Map control';

  @override
  String get gameOutcomeHoldMetric => 'Hold';

  @override
  String get gameOutcomeThresholdMetric => 'Threshold';

  @override
  String gameOutcomeTurnsValue(int held, int required) {
    return '$held/$required turns';
  }

  @override
  String get victoryConquestPrimary => 'Conquest';

  @override
  String get victoryGoalCompact => 'Goal';

  @override
  String get victoryNoLimit => 'No limit';

  @override
  String get victoryConquestTooltip => 'Goal: eliminate rivals. No turn limit.';

  @override
  String get victoryLimitLabel => 'Limit';

  @override
  String get victoryNoneValue => 'None';

  @override
  String get victoryScoreCapPrimary => 'SCORE CAP';

  @override
  String victoryScoreRemainingPrimary(int turns) {
    return 'SCORE ${turns}T';
  }

  @override
  String get victoryScoreCapCompact => 'CAP';

  @override
  String victoryTurnsCompact(int turns) {
    return '${turns}T';
  }

  @override
  String victoryTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turns',
      one: '1 turn',
    );
    return '$_temp0';
  }

  @override
  String get victoryRemainingLabel => 'Remaining';

  @override
  String get victoryScoreLeaderLabel => 'Score leader';

  @override
  String victoryScoreDrawLabel(int score) {
    return 'DRAW $score';
  }

  @override
  String victoryScoreLimitReachedTooltip(int turnLimit) {
    return 'Turn limit $turnLimit reached. Score decides the result.';
  }

  @override
  String victoryScoreFallbackTooltip(int remainingTurns, int turnLimit) {
    return 'Score fallback in $remainingTurns turns. Limit: $turnLimit.';
  }

  @override
  String victoryLeaderTooltip(String leader) {
    return 'Leader: $leader.';
  }

  @override
  String victoryDominationTooltip(
    String leader,
    String control,
    String required,
    String hold,
  ) {
    return 'Domination: $leader controls $control% of the map. Threshold: $required%, hold: $hold.';
  }

  @override
  String get victoryLeaderLabel => 'Leader';

  @override
  String get victoryControlLabel => 'Control';

  @override
  String get victoryHoldLabel => 'Hold';

  @override
  String get victoryYouLabel => 'You';

  @override
  String get victoryPressureLabel => 'Pressure';

  @override
  String get victoryFallbackLabel => 'Fallback';

  @override
  String victoryYourGoalGainControl(int points) {
    return 'Your goal: gain $points pp more map control.';
  }

  @override
  String get victoryYourGoalReady =>
      'Your goal: the domination condition is ready to resolve.';

  @override
  String victoryYourGoalHold(String turns) {
    return 'Your goal: hold the threshold for $turns more.';
  }

  @override
  String victoryLeaderAboveThreshold(String leader) {
    return '$leader is above the threshold; break that control before the goal is held.';
  }

  @override
  String victoryYourProgress(String control, String required) {
    return 'Your progress: $control% / $required%.';
  }

  @override
  String victoryPressureReachThreshold(int points) {
    return 'Reach the threshold: missing $points pp';
  }

  @override
  String get victoryConditionReady => 'Condition ready';

  @override
  String victoryPressureHold(String turns) {
    return 'Hold for $turns';
  }

  @override
  String victoryPressureLeaderHolding(String leader, String turns) {
    return '$leader above threshold: $turns';
  }

  @override
  String victoryPressureYourGap(int points) {
    return 'Your goal: missing $points pp';
  }

  @override
  String victoryPressureLeaderGap(String leader, int points) {
    return '$leader leads: missing $points pp';
  }

  @override
  String victoryThreatApproaching(
    String player,
    String control,
    String required,
    int points,
  ) {
    return 'Rival approaches domination: $player controls $control% at the $required% threshold; missing $points pp.';
  }

  @override
  String victoryThreatHolding(String player, String hold) {
    return 'Rival is holding the domination threshold: $player $hold.';
  }

  @override
  String victoryThreatImminent(String player, String hold) {
    return 'Rival is close to domination: $player $hold.';
  }

  @override
  String victoryThreatPressureApproaching(String player, int points) {
    return '$player near threshold: missing $points pp';
  }

  @override
  String victoryThreatPressureBreak(String player, String turns) {
    return 'Break $player: $turns';
  }

  @override
  String get victoryBelowThreshold => 'below threshold';

  @override
  String victoryHoldProgress(int held, int required) {
    return '$held/$required turns';
  }

  @override
  String victoryHoldCompact(int held, int required) {
    return '$held/${required}T';
  }

  @override
  String get victoryReady => 'ready';

  @override
  String victoryRemainingTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turns left',
      one: '1 turn left',
    );
    return '$_temp0';
  }

  @override
  String get returnToMenuAction => 'Return to menu';

  @override
  String get today => 'today';

  @override
  String get yesterday => 'yesterday';

  @override
  String get objectivesPanelTitle => 'OBJECTIVES';

  @override
  String get objectivesCloseTooltip => 'Close objectives';

  @override
  String get objectivesMenuClosePrefix => 'Close objectives';

  @override
  String get objectivesMenuOpenPrefix => 'Objectives';

  @override
  String objectivesMenuTooltip(
    String prefix,
    String descriptor,
    String title,
    String progress,
    String count,
  ) {
    return '$prefix: $descriptor - $title ($progress, $count)';
  }

  @override
  String objectivesMenuCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objectives',
      one: '1 objective',
    );
    return '$_temp0';
  }

  @override
  String get objectivesMenuBadgeScore => 'PTS';

  @override
  String get objectivesMenuBadgeDomination => 'DOM';

  @override
  String get objectivesMenuDescriptorDomination => 'domination';

  @override
  String get objectivesMenuDescriptorDominationThreat => 'domination threat';

  @override
  String get objectivesMenuDescriptorScoreLead => 'lead defense';

  @override
  String get objectivesMenuDescriptorScorePressure => 'score pressure';

  @override
  String get objectivesMenuDescriptorActiveObjective => 'active objective';

  @override
  String get objectiveMicroTooltipLabel => 'Why';

  @override
  String get objectiveOverviewGuidanceLabel => 'ACTIVE OBJECTIVE';

  @override
  String get objectiveOverviewStrategicLabel => 'URGENT';

  @override
  String get objectiveOverviewScoreCatchUpLabel => 'SCORE PRESSURE';

  @override
  String get objectiveOverviewScoreProtectLabel => 'DEFEND LEAD';

  @override
  String get objectiveOverviewDominationHoldLabel => 'DOMINATION';

  @override
  String get objectiveOverviewDominationThreatLabel => 'DOMINATION THREAT';

  @override
  String objectiveOverviewTitleLabel(String title) {
    return 'Top priority: $title';
  }

  @override
  String objectiveOverviewProgressLabel(String progress) {
    return 'Progress $progress';
  }

  @override
  String get objectivePhaseFoundation => 'Foundation';

  @override
  String get objectivePhaseExpansion => 'Expansion';

  @override
  String get objectivePhasePressure => 'Pressure';

  @override
  String get objectivePhaseEndgame => 'Endgame';

  @override
  String get objectiveChooseResearchTitle => 'Choose research';

  @override
  String get objectiveChooseResearchHint =>
      'Set your development direction before the first turn ends.';

  @override
  String get objectiveChooseResearchReward => '+ science tempo';

  @override
  String get objectiveChooseResearchTooltip =>
      'Research turns every following turn toward a specific development path.';

  @override
  String get objectiveFoundCapitalTitle => 'Found your first city';

  @override
  String get objectiveFoundCapitalHint =>
      'Your settler should quickly turn good terrain into a capital.';

  @override
  String get objectiveFoundCapitalReward => '+ production base';

  @override
  String get objectiveFoundCapitalTooltip =>
      'The capital unlocks production, growth, and territorial reach.';

  @override
  String get objectiveExploreNearbyTitle => 'Explore nearby land';

  @override
  String get objectiveExploreNearbyHint =>
      'Your warrior should reveal nearby resources and city sites.';

  @override
  String get objectiveExploreNearbyReward => '+ better decisions';

  @override
  String get objectiveExploreNearbyTooltip =>
      'Early scouting helps choose city sites and avoid blind moves.';

  @override
  String get objectiveQueueWorkerTitle => 'Queue a worker';

  @override
  String get objectiveQueueWorkerHint =>
      'A worker turns food and production on the map into a real advantage.';

  @override
  String get objectiveQueueWorkerReward => '+ field development';

  @override
  String get objectiveQueueWorkerTooltip =>
      'A worker turns good tiles into steady resource growth.';

  @override
  String get objectiveImproveFirstHexTitle => 'Improve your first tile';

  @override
  String get objectiveImproveFirstHexHint =>
      'The first improvement should support food, production, or gold.';

  @override
  String get objectiveImproveFirstHexReward => '+ stronger economy';

  @override
  String get objectiveImproveFirstHexTooltip =>
      'The first improvement shows which part of the city economy should grow fastest.';

  @override
  String get objectiveFoundSecondCityTitle => 'Found a second city';

  @override
  String get objectiveFoundSecondCityHint =>
      'A second settlement opens expansion without flooding the map with units.';

  @override
  String get objectiveFoundSecondCityReward => '+ empire scale';

  @override
  String get objectiveFoundSecondCityTooltip =>
      'A second city increases production pace without waiting on one capital.';

  @override
  String get objectiveBuildFirstBuildingTitle => 'Build your first building';

  @override
  String get objectiveBuildFirstBuildingHint =>
      'The first building should strengthen food, production, or gold.';

  @override
  String get objectiveBuildFirstBuildingReward => '+ lasting city advantage';

  @override
  String get objectiveBuildFirstBuildingTooltip =>
      'Buildings stay in the city and scale across many turns.';

  @override
  String get objectiveImproveThreeHexesTitle => 'Improve three tiles';

  @override
  String get objectiveImproveThreeHexesHint =>
      'Several improvements turn a starting camp into an economy.';

  @override
  String get objectiveImproveThreeHexesReward => '+ stable income';

  @override
  String get objectiveImproveThreeHexesTooltip =>
      'Three improvements create a stable base for armies, research, or expansion.';

  @override
  String get objectiveFoundThirdCityTitle => 'Found a third city';

  @override
  String get objectiveFoundThirdCityHint =>
      'A third settlement creates a true empire and a second expansion direction.';

  @override
  String get objectiveFoundThirdCityReward => '+ map scale';

  @override
  String get objectiveFoundThirdCityTooltip =>
      'A third city gives you a second development front and more decisions every turn.';

  @override
  String get objectiveExploreRegionTitle => 'Explore the region';

  @override
  String get objectiveExploreRegionHint =>
      'A wider map reveals resources, rivals, and places worth defending.';

  @override
  String get objectiveExploreRegionReward => '+ strategic plan';

  @override
  String get objectiveExploreRegionTooltip =>
      'A wider map reveals rivals, strategic resources, and safe borders.';

  @override
  String get objectiveBuildCombatForceTitle => 'Build a defensive force';

  @override
  String get objectiveBuildCombatForceHint =>
      'Several troops let you protect expansion and pressure rivals.';

  @override
  String get objectiveBuildCombatForceReward => '+ border security';

  @override
  String get objectiveBuildCombatForceTooltip =>
      'A steady screen protects settlers, workers, and developed cities.';

  @override
  String get objectiveHoldDominationTitle => 'Hold domination';

  @override
  String get objectiveHoldDominationHint =>
      'You are above the map threshold. Keep control until the countdown ends.';

  @override
  String get objectiveHoldDominationReward => '+ map victory';

  @override
  String get objectiveHoldDominationTooltip =>
      'Domination ends the game before the score cap if you hold the required map percentage for consecutive turns.';

  @override
  String get objectiveBreakDominationHoldTitle => 'Break a rival\'s domination';

  @override
  String get objectiveBreakDominationHoldHint =>
      'A rival is above the map threshold. Take territory before they hold the objective.';

  @override
  String get objectiveBreakDominationHoldReward => '+ countdown stopped';

  @override
  String get objectiveBreakDominationHoldTooltip =>
      'If a rival falls below the control threshold, their hold turns reset to zero.';

  @override
  String get objectiveHoldScoreLeadTitle => 'Hold the lead';

  @override
  String get objectiveHoldScoreLeadHint =>
      'The turn limit is close. Protect your score and avoid losing your edge in the final turns.';

  @override
  String get objectiveHoldScoreLeadReward => '+ score-cap win';

  @override
  String get objectiveHoldScoreLeadTooltip =>
      'The score cap decides the match when the turn limit passes, so the point lead must last to the end.';

  @override
  String get objectiveOvertakeScoreLeaderTitle => 'Catch the score leader';

  @override
  String get objectiveOvertakeScoreLeaderHint =>
      'The turn limit is close. You need fast score growth or a weaker leader.';

  @override
  String get objectiveOvertakeScoreLeaderReward => '+ score-cap chance';

  @override
  String get objectiveOvertakeScoreLeaderTooltip =>
      'Build cities, population, technologies, units, and improvements; if scores tie, the score cap ends in a draw.';

  @override
  String get objectiveSecureMapObjectiveTitle => 'Secure the map objective';

  @override
  String get objectiveSecureMapObjectiveHint =>
      'Keep a unit or city influence on the objective until the hold completes.';

  @override
  String get objectiveSecureMapObjectiveReward => '+ objective rewards';

  @override
  String get objectiveSecureMapObjectiveTooltip =>
      'Map objectives use triangle markers and grant their victory points or gold only after consecutive control.';

  @override
  String get objectiveBreakMapObjectiveHoldTitle => 'Break the rival objective';

  @override
  String get objectiveBreakMapObjectiveHoldHint =>
      'A rival is holding a map objective. Contest the triangle marker before the hold completes.';

  @override
  String get objectiveBreakMapObjectiveHoldReward => '+ denied objective';

  @override
  String get objectiveBreakMapObjectiveHoldTooltip =>
      'Moving onto the objective with your own force contests control and resets the rival\'s progress.';

  @override
  String get objectiveAdviceFoundCity => 'Biggest gap: a new or captured city.';

  @override
  String get objectiveAdviceGrowPopulation => 'Biggest gap: population growth.';

  @override
  String get objectiveAdviceClaimTerritory =>
      'Biggest gap: more controlled tiles.';

  @override
  String get objectiveAdviceConstructBuilding =>
      'Biggest gap: a city building.';

  @override
  String get objectiveAdviceTrainUnit => 'Biggest gap: a quick unit.';

  @override
  String get objectiveAdviceUnlockTechnology =>
      'Biggest gap: completing a technology.';

  @override
  String get objectiveAdviceImproveField => 'Biggest gap: a tile improvement.';

  @override
  String get objectiveAdviceCollectGold => 'Biggest gap: gold for score.';

  @override
  String get objectiveAdviceProtectLead =>
      'Priority: do not give up cities, and secure the next score gain.';

  @override
  String objectiveScoreBreakdownCatchUpHeader(int delta) {
    return 'Score gap: $delta pts';
  }

  @override
  String objectiveScoreBreakdownProtectHeader(int delta) {
    return 'Score lead: $delta pts';
  }

  @override
  String objectiveScoreBreakdownCatchUpTotals(
    int playerScore,
    int comparisonScore,
  ) {
    return 'You $playerScore / leader $comparisonScore';
  }

  @override
  String objectiveScoreBreakdownProtectTotals(
    int playerScore,
    int comparisonScore,
  ) {
    return 'You $playerScore / rival $comparisonScore';
  }

  @override
  String objectiveScoreBreakdownCatchUpDelta(int delta) {
    return 'short by $delta';
  }

  @override
  String objectiveScoreBreakdownProtectDelta(int delta) {
    return '+$delta';
  }

  @override
  String get objectiveScoreCategoryCity => 'Cities';

  @override
  String get objectiveScoreCategoryPopulation => 'Population';

  @override
  String get objectiveScoreCategoryTerritory => 'Territory';

  @override
  String get objectiveScoreCategoryBuilding => 'Buildings';

  @override
  String get objectiveScoreCategoryUnit => 'Units';

  @override
  String get objectiveScoreCategoryTechnology => 'Technologies';

  @override
  String get objectiveScoreCategoryImprovement => 'Improvements';

  @override
  String get objectiveScoreCategoryGold => 'Gold';

  @override
  String get cityBuildingGranary => 'Granary';

  @override
  String get cityBuildingWaterMill => 'Water Mill';

  @override
  String get cityBuildingWorkshop => 'Workshop';

  @override
  String get cityBuildingStorehouse => 'Storehouse';

  @override
  String get cityBuildingHousing => 'Housing';

  @override
  String get cityBuildingMerchantHall => 'Merchant Hall';

  @override
  String get cityBuildingStonemason => 'Stonemason';

  @override
  String get cityBuildingBarracks => 'Barracks';

  @override
  String get cityBuildingMarketplace => 'Marketplace';

  @override
  String get cityBuildingPort => 'Port';

  @override
  String get cityBuildingAqueduct => 'Aqueduct';

  @override
  String get cityBuildingForge => 'Forge';

  @override
  String get cityBuildingStable => 'Stable';

  @override
  String get cityBuildingBank => 'Bank';

  @override
  String get cityBuildingBuildersGuild => 'Builders\' Guild';

  @override
  String get cityBuildingFactory => 'Factory';

  @override
  String get cityBuildingLighthouse => 'Lighthouse';

  @override
  String get cityBuildingTrainingGrounds => 'Training Grounds';

  @override
  String get cityBuildingTownHall => 'Town Hall';

  @override
  String get cityBuildingMonument => 'Monument';

  @override
  String get cityBuildingArchive => 'Archive';

  @override
  String get cityBuildingAcademy => 'Academy';

  @override
  String get cityBuildingUniversity => 'University';

  @override
  String get cityBuildingObservatory => 'Observatory';

  @override
  String get cityBuildingLaboratory => 'Laboratory';

  @override
  String get cityBuildingReactor => 'Reactor';

  @override
  String get cityBuildingCourthouse => 'Courthouse';

  @override
  String get cityBuildingCourt => 'Court';

  @override
  String get cityBuildingGovernorsOffice => 'Governor\'s Office';

  @override
  String get cityBuildingSurveyorsOffice => 'Surveyor\'s Office';

  @override
  String get cityBuildingPlanningOffice => 'Planning Office';

  @override
  String get cityBuildingApothecary => 'Apothecary';

  @override
  String get cityBuildingPublicBaths => 'Public Baths';

  @override
  String get cityBuildingHospital => 'Hospital';

  @override
  String get cityBuildingMinistries => 'Ministries';

  @override
  String get cityBuildingWalls => 'Walls';

  @override
  String get cityBuildingArmory => 'Armory';

  @override
  String get cityBuildingSiegeWorkshop => 'Siege Workshop';

  @override
  String get cityBuildingCitadel => 'Citadel';

  @override
  String get cityBuildingWarCollege => 'War College';

  @override
  String get cityBuildingConscriptionOffice => 'Conscription Office';

  @override
  String get cityBuildingBorderFort => 'Border Fort';

  @override
  String get cityBuildingAirfield => 'Airfield';

  @override
  String get cityBuildingArtisansGuild => 'Artisans\' Guild';

  @override
  String get cityBuildingMasterWorkshop => 'Master Workshop';

  @override
  String get cityBuildingSteelworks => 'Steelworks';

  @override
  String get cityBuildingRailDepot => 'Rail Depot';

  @override
  String get cityBuildingPowerPlant => 'Power Plant';

  @override
  String get cityBuildingAssemblyPlant => 'Assembly Plant';

  @override
  String get cityBuildingRefinery => 'Refinery';

  @override
  String get cityBuildingMapRoom => 'Map Room';

  @override
  String get cityBuildingShipyard => 'Shipyard';

  @override
  String get cityBuildingDryDock => 'Dry Dock';

  @override
  String get cityBuildingNavalAcademy => 'Naval Academy';

  @override
  String get cityBuildingHarborCustoms => 'Harbor Customs';

  @override
  String get cityBuildingMuseum => 'Museum';

  @override
  String get cityBuildingParliament => 'Parliament';

  @override
  String get cityBuildingBroadcastTower => 'Broadcast Tower';

  @override
  String get cityBuildingWorldFairGrounds => 'World Fair Grounds';

  @override
  String get cityBuildingGranaryDescription =>
      'An early food building that stabilizes city growth.';

  @override
  String get cityBuildingWaterMillDescription =>
      'Uses controlled river tiles to increase city food.';

  @override
  String get cityBuildingWorkshopDescription =>
      'A basic craft center that raises city production.';

  @override
  String get cityBuildingStorehouseDescription =>
      'Improves harvest storage and increases stored food.';

  @override
  String get cityBuildingHousingDescription =>
      'Expands living space and lets the city control more tiles.';

  @override
  String get cityBuildingMerchantHallDescription =>
      'Organizes local trade and increases city income.';

  @override
  String get cityBuildingStonemasonDescription =>
      'Strengthens the city construction and defensive base.';

  @override
  String get cityBuildingBarracksDescription =>
      'Provides military infrastructure and additional defense.';

  @override
  String get cityBuildingMarketplaceDescription =>
      'Develops urban trade and greatly increases gold income.';

  @override
  String get cityBuildingPortDescription =>
      'Opens the city to sea trade and coastal food.';

  @override
  String get cityBuildingAqueductDescription =>
      'Delivers water, supporting growth and further city expansion.';

  @override
  String get cityBuildingForgeDescription =>
      'Concentrates metalworking and greatly increases production.';

  @override
  String get cityBuildingStableDescription =>
      'Supports breeding and logistics, adding food and production.';

  @override
  String get cityBuildingBankDescription =>
      'Centralizes finance and significantly increases city income.';

  @override
  String get cityBuildingBuildersGuildDescription =>
      'Gathers construction specialists, accelerating production and territorial growth.';

  @override
  String get cityBuildingFactoryDescription =>
      'A later-game industrial building that grants a large production bonus.';

  @override
  String get cityBuildingLighthouseDescription =>
      'Strengthens the coastal economy through navigation and trade.';

  @override
  String get cityBuildingTrainingGroundsDescription =>
      'Develops military training and improves city defense.';

  @override
  String get cityBuildingTownHallDescription =>
      'The city administration center, strengthening economy and territorial control.';

  @override
  String get cityBuildingMonumentDescription =>
      'A symbol of city prestige, providing gold and defense.';

  @override
  String get cityBuildingArchiveDescription =>
      'The first knowledge building, organizing records and supporting research.';

  @override
  String get cityBuildingAcademyDescription =>
      'Strengthens science cities and prepares the path to higher education.';

  @override
  String get cityBuildingUniversityDescription =>
      'A later science building for large, developed cities.';

  @override
  String get cityBuildingObservatoryDescription =>
      'Links geography with science and supports advanced research.';

  @override
  String get cityBuildingLaboratoryDescription =>
      'Support for late technology projects and modern science.';

  @override
  String get cityBuildingReactorDescription =>
      'A powerful endgame building requiring uranium and strong infrastructure.';

  @override
  String get cityBuildingCourthouseDescription =>
      'Stabilizes large or captured cities through legal administration.';

  @override
  String get cityBuildingCourtDescription =>
      'Develops law, city policies, and civilian control.';

  @override
  String get cityBuildingGovernorsOfficeDescription =>
      'Strengthens city specialization and territorial management.';

  @override
  String get cityBuildingSurveyorsOfficeDescription =>
      'Eases border planning and increases city control range.';

  @override
  String get cityBuildingPlanningOfficeDescription =>
      'Develops the city through planning, production, and territorial control.';

  @override
  String get cityBuildingApothecaryDescription =>
      'Early city health that helps maintain steady growth.';

  @override
  String get cityBuildingPublicBathsDescription =>
      'Improve stability and growth in larger cities.';

  @override
  String get cityBuildingHospitalDescription =>
      'Late population infrastructure for long-term development.';

  @override
  String get cityBuildingMinistriesDescription =>
      'A limited empire building that strengthens administration and gold.';

  @override
  String get cityBuildingWallsDescription =>
      'Early city defense against the first attacks.';

  @override
  String get cityBuildingArmoryDescription =>
      'A better recruitment and equipment center for troops.';

  @override
  String get cityBuildingSiegeWorkshopDescription =>
      'Produces and maintains the support base for siege engines.';

  @override
  String get cityBuildingCitadelDescription =>
      'Late strategic defense for cities on important borders.';

  @override
  String get cityBuildingWarCollegeDescription =>
      'A military academy that strengthens army and general coordination.';

  @override
  String get cityBuildingConscriptionOfficeDescription =>
      'Mobilizes the army and speeds preparation of new troops.';

  @override
  String get cityBuildingBorderFortDescription =>
      'Strengthens defense and visibility on empire borders.';

  @override
  String get cityBuildingAirfieldDescription =>
      'A military airfield for aviation, reconnaissance, and modern force projection.';

  @override
  String get cityBuildingArtisansGuildDescription =>
      'A production stage before the factory, based on crafts and workshops.';

  @override
  String get cityBuildingMasterWorkshopDescription =>
      'A specialized workshop for production-focused cities.';

  @override
  String get cityBuildingSteelworksDescription =>
      'Heavy industry based on iron or coal.';

  @override
  String get cityBuildingRailDepotDescription =>
      'A rail depot improving logistics and mobility between cities.';

  @override
  String get cityBuildingPowerPlantDescription =>
      'Late energy infrastructure for strong industrial production.';

  @override
  String get cityBuildingAssemblyPlantDescription =>
      'An endgame industrial building for mass production.';

  @override
  String get cityBuildingRefineryDescription =>
      'Processes oil for modern armies and late projects.';

  @override
  String get cityBuildingMapRoomDescription =>
      'Supports exploration, visibility, and expedition planning.';

  @override
  String get cityBuildingShipyardDescription =>
      'Develops fleets and production in port cities.';

  @override
  String get cityBuildingDryDockDescription =>
      'A late naval port for larger warships.';

  @override
  String get cityBuildingNavalAcademyDescription =>
      'A naval military academy for specialized ports.';

  @override
  String get cityBuildingHarborCustomsDescription =>
      'A port office strengthening trade and coastal control.';

  @override
  String get cityBuildingMuseumDescription =>
      'A prestigious empire building that strengthens city influence.';

  @override
  String get cityBuildingParliamentDescription =>
      'A limited civic building for a mature state.';

  @override
  String get cityBuildingBroadcastTowerDescription =>
      'Strengthens empire influence, visibility, and communication.';

  @override
  String get cityBuildingWorldFairGroundsDescription =>
      'A peaceful prestige project for a rich, developed city.';

  @override
  String get unitCommander => 'General';

  @override
  String get unitWarrior => 'Warrior';

  @override
  String get unitArcher => 'Archer';

  @override
  String get unitSettler => 'Settler';

  @override
  String get unitWorker => 'Worker';

  @override
  String get unitMerchant => 'Merchant';

  @override
  String get unitScout => 'Scout';

  @override
  String get unitSpearman => 'Spearman';

  @override
  String get unitCavalry => 'Cavalry';

  @override
  String get unitCatapult => 'Catapult';

  @override
  String get unitHeavyInfantry => 'Heavy Infantry';

  @override
  String get unitFieldCannon => 'Field Cannon';

  @override
  String get unitRifleman => 'Rifleman';

  @override
  String get unitTank => 'Tank';

  @override
  String get unitScoutShip => 'Scout Ship';

  @override
  String get unitWarship => 'Warship';

  @override
  String get unitReconPlane => 'Recon Plane';

  @override
  String get unitCommanderDescription =>
      'A general commands an army, leads reconnaissance, and can act faster than regular troops.';

  @override
  String get unitWarriorDescription =>
      'A basic combat unit for city defense and melee fighting.';

  @override
  String get unitArcherDescription =>
      'A ranged unit that attacks from farther away but defends poorly in melee.';

  @override
  String get unitSettlerDescription =>
      'Founds new cities and expands the empire, but needs protection on the road.';

  @override
  String get unitWorkerDescription =>
      'Improves tiles around cities, increasing food, production, and gold.';

  @override
  String get unitMerchantDescription =>
      'Travels automatically between your cities along a trade route and can enter occupied friendly city centers.';

  @override
  String get unitScoutDescription =>
      'A fast reconnaissance unit for exploring the map and detecting threats.';

  @override
  String get unitSpearmanDescription =>
      'Early defensive infantry, good for covering cities and stopping charges.';

  @override
  String get unitCavalryDescription =>
      'A mobile strike unit that quickly responds to weak points on the front.';

  @override
  String get unitCatapultDescription =>
      'A siege engine with longer range, effective against fortifications.';

  @override
  String get unitHeavyInfantryDescription =>
      'Durable frontline infantry with high defense and solid attack.';

  @override
  String get unitFieldCannonDescription =>
      'Modern field artillery for ranged bombardment.';

  @override
  String get unitRiflemanDescription =>
      'A modern ranged soldier, steady in attack and defense.';

  @override
  String get unitTankDescription =>
      'A heavy armored unit with high strength and high mobility.';

  @override
  String get unitScoutShipDescription =>
      'A light ship for coastal reconnaissance and protecting early sea routes.';

  @override
  String get unitWarshipDescription =>
      'A strong combat ship for sea control and ranged bombardment.';

  @override
  String get unitReconPlaneDescription =>
      'A reconnaissance aircraft with long vision range and very high mobility.';

  @override
  String get unitRankRecruit => 'Recruit';

  @override
  String get unitRankSeasoned => 'Seasoned';

  @override
  String get unitRankVeteran => 'Veteran';

  @override
  String get unitRankElite => 'Elite';

  @override
  String get troopWarrior => 'Warriors';

  @override
  String get troopArcher => 'Archers';

  @override
  String get troopSettler => 'Settlers';

  @override
  String get fieldImprovementFarm => 'Farm';

  @override
  String get fieldImprovementRiverFarm => 'River Farm';

  @override
  String get fieldImprovementMine => 'Mine';

  @override
  String get fieldImprovementLumberMill => 'Lumber Mill';

  @override
  String get fieldImprovementPasture => 'Pasture';

  @override
  String get fieldImprovementCamp => 'Camp';

  @override
  String get fieldImprovementQuarry => 'Quarry';

  @override
  String get fieldImprovementFishingBoats => 'Fishing Boats';

  @override
  String get fieldImprovementOrchard => 'Orchard';

  @override
  String get fieldImprovementPlantation => 'Plantation';

  @override
  String get fieldImprovementVineyard => 'Vineyard';

  @override
  String get fieldImprovementTradingPost => 'Trading Post';

  @override
  String get fieldImprovementProspectorCamp => 'Prospector Camp';

  @override
  String get fieldImprovementHorseRanch => 'Horse Ranch';

  @override
  String get fieldImprovementPearlDivers => 'Pearl Divers';

  @override
  String get fieldImprovementCoalShaft => 'Coal Shaft';

  @override
  String get fieldImprovementOilWell => 'Oil Well';

  @override
  String get fieldImprovementBauxiteMine => 'Bauxite Mine';

  @override
  String get fieldImprovementUraniumMine => 'Uranium Mine';

  @override
  String get resourceWheat => 'wheat';

  @override
  String get resourceFish => 'fish';

  @override
  String get resourceDeer => 'deer';

  @override
  String get resourceSheep => 'sheep';

  @override
  String get resourceRice => 'rice';

  @override
  String get resourceCow => 'cattle';

  @override
  String get resourceApple => 'apples';

  @override
  String get resourceBanana => 'bananas';

  @override
  String get resourceCitrus => 'citrus';

  @override
  String get resourceGold => 'gold';

  @override
  String get resourceSilver => 'silver';

  @override
  String get resourceGems => 'gems';

  @override
  String get resourceSilk => 'silk';

  @override
  String get resourceSpices => 'spices';

  @override
  String get resourceCotton => 'cotton';

  @override
  String get resourceGrapes => 'grapes';

  @override
  String get resourceIvory => 'ivory';

  @override
  String get resourcePearls => 'pearls';

  @override
  String get resourceCoffee => 'coffee';

  @override
  String get resourceCocoa => 'cocoa';

  @override
  String get resourceTobacco => 'tobacco';

  @override
  String get resourceSugar => 'sugar';

  @override
  String get resourceIron => 'iron';

  @override
  String get resourceCoal => 'coal';

  @override
  String get resourceOil => 'oil';

  @override
  String get resourceAluminium => 'aluminum';

  @override
  String get resourceUranium => 'uranium';

  @override
  String get resourceHorses => 'horses';

  @override
  String get resourceMarble => 'marble';

  @override
  String get technologyAgriculture => 'Agriculture';

  @override
  String get technologyWoodworking => 'Woodworking';

  @override
  String get technologyMining => 'Mining';

  @override
  String get technologyAnimalHusbandry => 'Animal Husbandry';

  @override
  String get technologyHunting => 'Hunting';

  @override
  String get technologyFishing => 'Fishing';

  @override
  String get technologyCraftsmanship => 'Craftsmanship';

  @override
  String get technologyTrade => 'Trade';

  @override
  String get technologyStorage => 'Storage';

  @override
  String get technologyWaterEngineering => 'Water Engineering';

  @override
  String get technologyStoneworking => 'Stoneworking';

  @override
  String get technologyMilitaryOrganization => 'Military Organization';

  @override
  String get technologyAdvancedTrade => 'Advanced Trade';

  @override
  String get technologyConstruction => 'Construction';

  @override
  String get technologyNavigation => 'Navigation';

  @override
  String get technologyIrrigation => 'Irrigation';

  @override
  String get technologyBanking => 'Banking';

  @override
  String get technologyEngineering => 'Engineering';

  @override
  String get technologyMetallurgy => 'Metallurgy';

  @override
  String get technologyHorsebackRiding => 'Horseback Riding';

  @override
  String get technologyIronWorking => 'Iron Working';

  @override
  String get technologyCoalMining => 'Coal Mining';

  @override
  String get technologyMachinery => 'Machinery';

  @override
  String get technologyAdministration => 'Administration';

  @override
  String get technologyLogistics => 'Logistics';

  @override
  String get technologyShipbuilding => 'Shipbuilding';

  @override
  String get technologyTactics => 'Tactics';

  @override
  String get technologyEconomy => 'Economy';

  @override
  String get technologyUrbanization => 'Urbanization';

  @override
  String get technologyFortifications => 'Fortifications';

  @override
  String get technologyStrategy => 'Strategy';

  @override
  String get technologySpecialization => 'Specialization';

  @override
  String get technologyWriting => 'Writing';

  @override
  String get technologyMathematics => 'Mathematics';

  @override
  String get technologyMedicine => 'Medicine';

  @override
  String get technologyCivilService => 'Civil Service';

  @override
  String get technologySiegecraft => 'Siegecraft';

  @override
  String get technologyCartography => 'Cartography';

  @override
  String get technologyGuilds => 'Guilds';

  @override
  String get technologyLaw => 'Law';

  @override
  String get technologyEducation => 'Education';

  @override
  String get technologyUrbanPlanning => 'Urban Planning';

  @override
  String get technologyNavalDoctrine => 'Naval Doctrine';

  @override
  String get technologySteel => 'Steel';

  @override
  String get technologyBureaucracy => 'Bureaucracy';

  @override
  String get technologyNationalism => 'Nationalism';

  @override
  String get technologyScientificMethod => 'Scientific Method';

  @override
  String get technologySteamPower => 'Steam Power';

  @override
  String get technologyElectricity => 'Electricity';

  @override
  String get technologyCombustion => 'Combustion';

  @override
  String get technologyFlight => 'Flight';

  @override
  String get technologyMassProduction => 'Mass Production';

  @override
  String get technologyRadio => 'Radio';

  @override
  String get technologyNuclearPhysics => 'Nuclear Physics';

  @override
  String get technologyAgricultureDescription =>
      'Opens the basic growth path. Farms and river farms let population grow faster and stabilize the first city.';

  @override
  String get technologyWoodworkingDescription =>
      'Develops the production side of mining. Lumber mills turn forests into production without going deep into metallurgy.';

  @override
  String get technologyMiningDescription =>
      'Opens the path of industry and infrastructure. Mines are the first major jump in city production.';

  @override
  String get technologyAnimalHusbandryDescription =>
      'Strengthens growth through animal resources. Pastures build a food economy and prepare the way to horseback riding.';

  @override
  String get technologyHuntingDescription =>
      'Opens the military and exploration branch. Provides camps and the first ranged unit for city production.';

  @override
  String get technologyFishingDescription =>
      'Develops cities near water. Fishing boats help coastal cities grow faster and prepare the way to the port.';

  @override
  String get technologyCraftsmanshipDescription =>
      'The first city production upgrade. The workshop keeps later buildings and units from blocking the queue too long.';

  @override
  String get technologyTradeDescription =>
      'The first step in the gold economy. The merchant hall gives a city a simple financial payoff after choosing a growth branch.';

  @override
  String get technologyStorageDescription =>
      'Stabilizes city growth. Storage helps maintain food pace and reduces the risk of development stalls.';

  @override
  String get technologyWaterEngineeringDescription =>
      'Expands the water growth path. The water mill rewards cities that control rivers.';

  @override
  String get technologyStoneworkingDescription =>
      'Combines production and defense. Quarries and the stonemason strengthen cities in the infrastructure branch.';

  @override
  String get technologyMilitaryOrganizationDescription =>
      'Builds the first military core of a city. Barracks strengthen production and defense before later army bonuses appear.';

  @override
  String get technologyAdvancedTradeDescription =>
      'Develops the economy after trade. The marketplace is a stronger gold building and prepares the path to banking.';

  @override
  String get technologyConstructionDescription =>
      'Expands territory and city maturity. Housing increases tile control and leads to administration and engineering.';

  @override
  String get technologyNavigationDescription =>
      'Opens a city payoff for the coast. The port requires coast/ocean access and rewards waterfront cities with food and gold.';

  @override
  String get technologyIrrigationDescription =>
      'Specializes water-based growth. The aqueduct grants a strong food bonus and additional territorial control.';

  @override
  String get technologyBankingDescription =>
      'Specializes the trade branch. The bank turns earlier markets into strong city income and unlocks the wider economy.';

  @override
  String get technologyEngineeringDescription =>
      'Construction specialization. The builders guild speeds production and increases the controlled tile limit.';

  @override
  String get technologyMetallurgyDescription =>
      'A strong industrial payoff after stoneworking. The forge raises production and prepares the path to iron and coal.';

  @override
  String get technologyHorsebackRidingDescription =>
      'A technology linking growth and war. The stable supports cities that invested earlier in animals and hunting.';

  @override
  String get technologyIronWorkingDescription =>
      'An industrial resource effect. Each controlled iron resource increases city production.';

  @override
  String get technologyCoalMiningDescription =>
      'A later industrial resource effect. Controlled coal increases city production and supports the factory path.';

  @override
  String get technologyMachineryDescription =>
      'A late infrastructure payoff. The factory gives a large production increase to cities that entered engineering.';

  @override
  String get technologyAdministrationDescription =>
      'Links infrastructure with economy. Town halls and monuments strengthen mature cities and lead to urbanization.';

  @override
  String get technologyLogisticsDescription =>
      'Speeds unit production. This is the main technology for players who want to field armies from cities more often.';

  @override
  String get technologyShipbuildingDescription =>
      'Develops the coastal/exploration subbranch. The lighthouse requires coast access and strengthens waterfront cities.';

  @override
  String get technologyTacticsDescription =>
      'Military city specialization. Training grounds add defense and production for military centers.';

  @override
  String get technologyEconomyDescription =>
      'A systemic payoff for banking. Increases gold generated by city economies.';

  @override
  String get technologyUrbanizationDescription =>
      'The final direction for large-city growth. Increases the population limit once the population system starts using hard caps.';

  @override
  String get technologyFortificationsDescription =>
      'Strengthens city defense. Grants a defensive bonus to the city economy, with its full meaning growing after combat and siege expansion.';

  @override
  String get technologyStrategyDescription =>
      'The final military direction. Strengthens army effectiveness as a late-game payoff after logistics.';

  @override
  String get technologySpecializationDescription =>
      'The final civic/economy payoff. Unlocks city specializations, adds city science, and helps finish late technologies in longer matches.';

  @override
  String get technologyWritingDescription =>
      'The first step toward science, law, and administration. The archive gives a city a permanent research base.';

  @override
  String get technologyMathematicsDescription =>
      'Connects science with territorial planning. The surveyor office helps cities control borders more effectively.';

  @override
  String get technologyMedicineDescription =>
      'Develops health and long-term growth in large cities through apothecaries, baths, and hospitals.';

  @override
  String get technologyCivilServiceDescription =>
      'Improves management of a large empire and unlocks courts that stabilize cities.';

  @override
  String get technologySiegecraftDescription =>
      'Opens siege warfare. Catapults and siege workshops break fortress cities.';

  @override
  String get technologyCartographyDescription =>
      'Develops exploration, maps, and the coast. Grants the map room and the first scout ships.';

  @override
  String get technologyGuildsDescription =>
      'Gives production cities a stage between the workshop and industry.';

  @override
  String get technologyLawDescription =>
      'Introduces order, policies, and civilian governance through courts.';

  @override
  String get technologyEducationDescription =>
      'Builds the full science path for cities through academies and universities.';

  @override
  String get technologyUrbanPlanningDescription =>
      'Develops great cities and territorial control through spatial planning.';

  @override
  String get technologyNavalDoctrineDescription =>
      'Turns ports into centers of fleets, shipyards, and force projection at sea.';

  @override
  String get technologySteelDescription =>
      'Introduces heavy industry and heavy infantry for the later front.';

  @override
  String get technologyBureaucracyDescription =>
      'Provides a major civic goal after administration: offices, ministries, museums, and parliament.';

  @override
  String get technologyNationalismDescription =>
      'Combines border defense, mobilization, and empire identity.';

  @override
  String get technologyScientificMethodDescription =>
      'Prepares late science, laboratories, observatories, and technology projects.';

  @override
  String get technologySteamPowerDescription =>
      'Opens rail, heavier logistics, and steam industry.';

  @override
  String get technologyElectricityDescription =>
      'Introduces power, infrastructure, and information reach.';

  @override
  String get technologyCombustionDescription =>
      'Gives oil importance and unlocks modern frontline units.';

  @override
  String get technologyFlightDescription =>
      'Introduces aviation, reconnaissance, and force projection over the front.';

  @override
  String get technologyMassProductionDescription =>
      'Develops final industrial production, tanks, and assembly plants.';

  @override
  String get technologyRadioDescription =>
      'Strengthens empire communication, visibility, and influence through broadcast towers.';

  @override
  String get technologyNuclearPhysicsDescription =>
      'Opens the reactor, uranium, and late endgame projects.';

  @override
  String get technologyEraFoundation => 'Foundation';

  @override
  String get technologyEraSettlement => 'Settlement';

  @override
  String get technologyEraExpansion => 'Expansion';

  @override
  String get technologyEraSpecialization => 'Specialization';

  @override
  String get technologyEraIndustry => 'Industry';

  @override
  String get technologyEraStrategy => 'Strategy';

  @override
  String get technologyUnlockEffect => 'Effect';

  @override
  String get technologyPrerequisitesNone => 'None';

  @override
  String get technologyStateCompleted => 'Completed';

  @override
  String get technologyStateInProgress => 'In progress';

  @override
  String get technologyStateAvailable => 'Available';

  @override
  String get technologyButtonResearched => 'RESEARCHED';

  @override
  String get technologyButtonActive => 'ACTIVE';

  @override
  String get technologyButtonResearch => 'RESEARCH';

  @override
  String get technologyButtonLocked => 'LOCKED';

  @override
  String get technologyTreeTitle => 'TECHNOLOGY TREE';

  @override
  String get technologyTreeEmptyTitle => 'No technologies to display';

  @override
  String get technologyTreeEmptyBody =>
      'The research tree will appear here when the ruleset provides technologies for this era.';

  @override
  String technologyResearchPointsShort(int points) {
    return '$points pts';
  }

  @override
  String get technologyDetailsTooltip => 'Technology details';

  @override
  String get technologyDetailsStatus => 'Status';

  @override
  String get technologyDetailsCost => 'Cost';

  @override
  String get technologyDetailsProgress => 'Progress';

  @override
  String get technologyDetailsPrerequisites => 'Requirements';

  @override
  String get technologyDetailsUnlocks => 'Unlocks';

  @override
  String get technologyDetailsEffects => 'Effects';

  @override
  String get technologyDetailsBoosts => 'Boosts';

  @override
  String get technologyDetailsUnlockStatus => 'Unlock';

  @override
  String get technologyDetailsNoEffects => 'No passive effects';

  @override
  String get technologyDetailsNoBoosts => 'No boosts';

  @override
  String get technologyUnlocksNone => 'No direct unlocks';

  @override
  String get technologyBoostActiveBadge => 'Boost';

  @override
  String get technologyBoostActiveBest => 'The best available boost is active.';

  @override
  String technologyBoostLine(String condition, String discount) {
    return '$condition (-$discount cost)';
  }

  @override
  String get technologyUnlockFieldImprovementCategory => 'Field improvement';

  @override
  String technologyEffectStrategicResourceProductionBonus(
    int production,
    String resource,
  ) {
    return '+$production production for each controlled resource: $resource';
  }

  @override
  String technologyEffectGlobalGoldMultiplier(String percent) {
    return '+$percent gold in city economy';
  }

  @override
  String technologyEffectCityDefenseBonus(int amount) {
    return '+$amount city defense';
  }

  @override
  String technologyEffectArmyProductionMultiplier(String percent) {
    return '+$percent unit production in cities';
  }

  @override
  String technologyEffectArmyStrengthMultiplier(String percent) {
    return '+$percent army strength';
  }

  @override
  String technologyEffectMaxCityPopulationBonus(int amount) {
    return '+$amount max city population';
  }

  @override
  String technologyEffectMaxControlledHexesBonus(int amount) {
    return '+$amount max city territory';
  }

  @override
  String technologyEffectCityScienceBonus(int amount) {
    return '+$amount science per city';
  }

  @override
  String technologyBoostConditionImprovementCount(
    int count,
    String improvement,
  ) {
    return 'Have ${count}x $improvement';
  }

  @override
  String technologyBoostConditionHasImprovement(String improvement) {
    return 'Have $improvement';
  }

  @override
  String technologyBoostConditionControlsResource(String resource) {
    return 'Control $resource';
  }

  @override
  String technologyBoostConditionControlsAnyResource(String resources) {
    return 'Control: $resources';
  }

  @override
  String technologyEffectAttackBonus(String value) {
    return '$value attack';
  }

  @override
  String technologyEffectDefenseBonus(String value) {
    return '$value defense';
  }

  @override
  String get technologyEffectNoArmyStatsBonus => 'No army stat bonus';

  @override
  String technologyEffectArmyStatsBonus(String parts) {
    return '$parts for armies';
  }

  @override
  String commonListOr(String first, String last) {
    return '$first or $last';
  }

  @override
  String get buildingDetailsTooltip => 'Building details';

  @override
  String get buildingDetailsNoRequirements => 'None';

  @override
  String get buildingDetailsYieldImpact => 'City impact';

  @override
  String buildingDetailsRequirementTechnology(String technology) {
    return 'Technology: $technology';
  }

  @override
  String get buildingDetailsRequirementCoastalAccess => 'Coastal access';

  @override
  String buildingDetailsRequirementResources(String resources) {
    return 'Resource: $resources';
  }

  @override
  String buildingDetailsFlatYieldEffect(String yield) {
    return '$yield to city yield';
  }

  @override
  String buildingDetailsRiverHexYieldEffect(String yield) {
    return '$yield per controlled river tile';
  }

  @override
  String buildingDetailsRiverHexYieldEffectWithMax(
    String yield,
    int maxApplications,
  ) {
    return '$yield per controlled river tile (max $maxApplications)';
  }

  @override
  String buildingDetailsMaxControlledHexesEffect(int amount) {
    return '+$amount city controlled tile limit';
  }

  @override
  String buildingDetailsFoodDepositMultiplierEffect(int percent) {
    return '+$percent% food stored after turn';
  }

  @override
  String buildingDetailsYieldFood(String value) {
    return '$value food';
  }

  @override
  String buildingDetailsYieldProduction(String value) {
    return '$value production';
  }

  @override
  String buildingDetailsYieldGold(String value) {
    return '$value gold';
  }

  @override
  String buildingDetailsYieldDefense(String value) {
    return '$value defense';
  }

  @override
  String buildingDetailsYieldScience(String value) {
    return '$value science';
  }

  @override
  String get buildingDetailsNoYieldChange => 'No resource change';

  @override
  String get unitDetailsTooltip => 'Unit details';

  @override
  String get unitDetailsMovement => 'Movement';

  @override
  String get unitDetailsCombat => 'Combat';

  @override
  String unitDetailsMovementPerTurn(int movement) {
    return '$movement tiles/turn';
  }

  @override
  String get unitDetailsPace => 'Pace';

  @override
  String unitDetailsRequirementTechnology(String technology) {
    return 'Technology: $technology';
  }

  @override
  String unitDetailsAttackLine(int value) {
    return 'Attack: $value';
  }

  @override
  String unitDetailsDefenseLine(int value) {
    return 'Defense: $value';
  }

  @override
  String unitDetailsHpLine(int value) {
    return 'HP: $value';
  }

  @override
  String unitDetailsRangeLine(int value) {
    return 'Range: $value';
  }

  @override
  String sciencePerTurn(int science) {
    return '$science science/turn';
  }

  @override
  String get activeResearchLabel => 'RESEARCHING';

  @override
  String get requirementTechnology => 'Requires technology';

  @override
  String requirementTechnologyName(String technology) {
    return 'Requires: $technology';
  }

  @override
  String requirementResourcesName(String resources) {
    return 'Requires: $resources';
  }

  @override
  String technologyBlockedBy(String technology) {
    return 'Blocked by: $technology';
  }

  @override
  String get requirementCoastalAccess => 'Requires: coastal access';

  @override
  String get productionCategoryBuilding => 'Building';

  @override
  String get productionCategoryUnit => 'Unit';

  @override
  String get productionTitle => 'PRODUCTION';

  @override
  String get productionInProgressLabel => 'IN PROGRESS';

  @override
  String productionPerTurn(int production) {
    return '$production production/turn';
  }

  @override
  String get productionNoProduction => 'no production';

  @override
  String get productionButtonProduce => 'PRODUCE';

  @override
  String get productionButtonLocked => 'LOCKED';

  @override
  String get productionEmptyState => 'No production is currently available.';

  @override
  String get buildingsSection => 'Buildings';

  @override
  String get unitsSection => 'Units';

  @override
  String futureBuildingsSection(int count) {
    return 'Future buildings ($count)';
  }

  @override
  String get futureBuildingsSubtitle => 'Unlocked by technologies';

  @override
  String workerPanelTitle(String unitName) {
    return 'Worker - $unitName';
  }

  @override
  String get commonOpenAction => 'Open';

  @override
  String get commonShowDetailsAction => 'Show details';

  @override
  String get commonExecuteAction => 'Execute';

  @override
  String colorPickerChangeTooltip(String label) {
    return 'Change color: $label';
  }

  @override
  String colorPickerColorSelected(String hex) {
    return '#$hex selected';
  }

  @override
  String colorPickerSelectColor(String hex) {
    return 'Select #$hex';
  }

  @override
  String get commonDescription => 'Description';

  @override
  String get commonSummary => 'Summary';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonTerrain => 'Terrain';

  @override
  String get commonResources => 'Resources';

  @override
  String get commonImprovements => 'Improvements';

  @override
  String get commonCities => 'Cities';

  @override
  String get commonBuildings => 'Buildings';

  @override
  String get commonGold => 'Gold';

  @override
  String get commonScience => 'Science';

  @override
  String get commonProduction => 'Production';

  @override
  String get commonResearch => 'Research';

  @override
  String get commonEmpire => 'Empire';

  @override
  String get commonTurn => 'Turn';

  @override
  String get commonProjects => 'Projects';

  @override
  String get commonPopulation => 'Population';

  @override
  String get commonTechnologies => 'Technologies';

  @override
  String get commonFields => 'Fields';

  @override
  String get commonMultipliers => 'Multipliers';

  @override
  String get commonOther => 'Other';

  @override
  String get commonReady => 'Ready';

  @override
  String get commonDone => 'Done';

  @override
  String get commonDefault => 'Default';

  @override
  String get commonAvailable => 'Available';

  @override
  String get commonBlocked => 'Blocked';

  @override
  String get commonSelectAction => 'Select';

  @override
  String get commonSelectedAction => 'Selected';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDoNotShowAgain => 'Do not show again';

  @override
  String get commonNoneLower => 'none';

  @override
  String get visualCurrentLabel => 'Now';

  @override
  String get visualAfterLabel => 'After change';

  @override
  String get terrainDetailEmpty => 'No terrain information';

  @override
  String get yieldFoodShort => 'FOOD';

  @override
  String get yieldProductionShort => 'PROD';

  @override
  String get yieldGoldShort => 'GOLD';

  @override
  String get yieldDefenseShort => 'DEF';

  @override
  String selectionChipBadgeSuffix(String badge) {
    return ' Visible counter: $badge.';
  }

  @override
  String selectionChipDisabledDescription(String badge) {
    return 'This information shortcut is not available for the current selection.$badge';
  }

  @override
  String selectionChipOpenDescription(String label, String badge) {
    return 'Opens “$label” details for the current map context.$badge';
  }

  @override
  String get gameGoalTitle => 'Game goal';

  @override
  String get globalHudCloseResearch => 'Close research';

  @override
  String globalHudResearchActive(String technologyName) {
    return 'Research: $technologyName';
  }

  @override
  String globalHudResearchActiveWithEta(String technologyName, String eta) {
    return 'Research: $technologyName · $eta';
  }

  @override
  String get globalHudChooseResearch => 'Choose research';

  @override
  String get globalHudCloseEmpire => 'Close empire';

  @override
  String get globalHudCloseActivityLog => 'Close activity log';

  @override
  String get bottomToolbarWaiting => 'Waiting';

  @override
  String get bottomToolbarPlan => 'Plan';

  @override
  String get bottomToolbarMove => 'Move';

  @override
  String get bottomToolbarResolvingTurn => 'Resolving turn';

  @override
  String bottomToolbarWaitingFor(String players) {
    return 'Waiting: $players';
  }

  @override
  String turnHintNextUnit(String unit) {
    return 'Next step: $unit';
  }

  @override
  String turnHintNextCityProduction(String city) {
    return 'Next step: production in $city';
  }

  @override
  String get turnHintChooseResearch => 'Next step: choose research';

  @override
  String get turnHintCheckAction => 'Next step: check action';

  @override
  String turnHintObjective(String objective) {
    return 'Objective: $objective';
  }

  @override
  String turnHintObjectiveWithAdvice(String objective, String advice) {
    return 'Objective: $objective · $advice';
  }

  @override
  String get turnHintImproveFieldWithWorker =>
      'Objective: improve a tile with a worker';

  @override
  String get turnHintFoundCityWithSettler =>
      'Objective: found a city with a settler';

  @override
  String get turnHintClaimTerritoryWithSettler =>
      'Objective: claim territory with a settler';

  @override
  String turnHintTrainUnit(String unit) {
    return 'Objective: set unit: $unit';
  }

  @override
  String turnHintProtectLeadUnit(String unit) {
    return 'Objective: secure the lead: $unit';
  }

  @override
  String turnHintConstructBuildingInCity(String city) {
    return 'Objective: queue a building in $city';
  }

  @override
  String turnHintTrainUnitInCity(String city) {
    return 'Objective: queue a unit in $city';
  }

  @override
  String turnHintPrepareSettlerInCity(String city) {
    return 'Objective: prepare a settler in $city';
  }

  @override
  String turnHintGrowPopulationInCity(String city) {
    return 'Objective: set growth in $city';
  }

  @override
  String turnHintPrepareWorkerInCity(String city) {
    return 'Objective: prepare a worker in $city';
  }

  @override
  String turnHintCollectGoldInCity(String city) {
    return 'Objective: close gold in $city';
  }

  @override
  String turnHintProtectLeadProductionInCity(String city) {
    return 'Objective: secure production in $city';
  }

  @override
  String get turnHintUnlockTechnologyForScore =>
      'Objective: choose a scoring technology';

  @override
  String get turnHintProtectLeadResearch => 'Objective: finish safe research';

  @override
  String topResourceTurnShortLabel(int turn) {
    return 'T$turn';
  }

  @override
  String topResourceTurnTooltip(int turn) {
    return 'Turn $turn';
  }

  @override
  String topResourceScienceTooltip(String scienceTurnLabel) {
    return 'Science: $scienceTurnLabel / turn';
  }

  @override
  String topResourceResourcesTooltip(int resourceTotal, int resourceTypes) {
    return 'Resources: $resourceTotal deposits • $resourceTypes controlled types';
  }

  @override
  String topResourceGoldTooltip(
    int gold,
    int goldIncome,
    int unitUpkeep,
    String net,
  ) {
    return 'Gold: $gold • income +$goldIncome • upkeep -$unitUpkeep • net $net / turn';
  }

  @override
  String topResourceGoldTooltipNegativeTreasury(String base) {
    return '$base • treasury below zero';
  }

  @override
  String topResourceGoldTooltipBankruptcy(String base) {
    return '$base • bankruptcy risk within 3 turns';
  }

  @override
  String get resourceBreakdownTreasury => 'Treasury';

  @override
  String get resourceBreakdownCityIncome => 'City income';

  @override
  String get resourceBreakdownUpkeep => 'Upkeep';

  @override
  String get resourceBreakdownNetPerTurn => 'Net / turn';

  @override
  String get resourceBreakdownNoCityIncome => 'No city income';

  @override
  String get resourceBreakdownFreeLimit => 'Free limit';

  @override
  String get resourceBreakdownNextWorkerUpkeep => 'Next worker upkeep';

  @override
  String resourceBreakdownNextWorkerUpkeepValue(int upkeep) {
    return '-$upkeep gold/turn';
  }

  @override
  String get resourceBreakdownInsideFreeLimit => 'Inside free limit';

  @override
  String get resourceBreakdownNoActiveTechnology => 'No technology selected';

  @override
  String get resourceBreakdownScienceTitle => 'Science and research';

  @override
  String get resourceBreakdownSciencePerTurn => 'Science / turn';

  @override
  String get resourceBreakdownActiveResearch => 'Active research';

  @override
  String get resourceBreakdownTurnsToComplete => 'To complete';

  @override
  String get resourceBreakdownNoScienceSources => 'No science sources';

  @override
  String resourceBreakdownCityResearchProject(String cityName) {
    return '$cityName: Research';
  }

  @override
  String get resourceBreakdownNoControlledResources =>
      'No controlled resources';

  @override
  String get resourceBreakdownGrowCitiesWithFood => 'Grow cities with food';

  @override
  String get resourceBreakdownControlledDeposits => 'Controlled deposits';

  @override
  String get resourceBreakdownResourceTypes => 'Resource types';

  @override
  String get resourceBreakdownTypesSection => 'Types';

  @override
  String get resourceBreakdownSourcesSection => 'Sources';

  @override
  String get technologyRecommendationsTitle => 'Recommended research';

  @override
  String get technologyShowTreeAction => 'Show tree';

  @override
  String technologyShowTreeCountAction(int count) {
    return 'Show tree ($count)';
  }

  @override
  String get technologyRecommendationUnlocks => 'Unlocks';

  @override
  String get technologyRecommendationReasonBoost =>
      'Active boost lowers the research cost.';

  @override
  String get technologyRecommendationReasonSection => 'Why now';

  @override
  String get technologyRecommendationReasonImprovements =>
      'New tile improvements quickly turn resources into yield.';

  @override
  String get technologyRecommendationReasonBuilding =>
      'A new city building opens another development direction.';

  @override
  String get technologyRecommendationReasonUnit =>
      'A new unit strengthens safety and map control.';

  @override
  String get technologyRecommendationReasonEffect =>
      'A permanent bonus applies to the whole economy.';

  @override
  String get technologyRecommendationReasonFast =>
      'Fast research with no extra requirements.';

  @override
  String get technologyRecommendationReasonDefault =>
      'Available research that neatly closes the next step.';

  @override
  String get technologyNoRecommendations =>
      'No new research is currently available.';

  @override
  String get technologyFullTreeTitle => 'Full technology tree';

  @override
  String get technologyRecommendationsBackAction => 'Recommendations';

  @override
  String get empireUnitsEmptyTitle => 'No units';

  @override
  String get empireUnitsEmptyBody =>
      'New units will appear here after city production or event recruitment.';

  @override
  String get empireCitiesEmptyTitle => 'No cities';

  @override
  String get empireCitiesEmptyBody =>
      'Found your first city with a settler to unlock production, science, and empire borders.';

  @override
  String get empireCityCenters => 'City centers';

  @override
  String get empireShowFirstUnitTooltip => 'Show the first unit on the map';

  @override
  String get empireShowUnitTooltip => 'Show unit on the map';

  @override
  String get empireShowFirstCityTooltip => 'Show the first city on the map';

  @override
  String get empireShowCityTooltip => 'Show city on the map';

  @override
  String empireUnitCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count units',
      one: '1 unit',
    );
    return '$_temp0';
  }

  @override
  String empireCityCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cities',
      one: '1 city',
    );
    return '$_temp0';
  }

  @override
  String empireUnitMovement(int movement) {
    return 'Movement $movement';
  }

  @override
  String get empireUnitBuilding => 'Building';

  @override
  String get empireUnitWorking => 'Working';

  @override
  String get empireUnitFortifying => 'Fortifying';

  @override
  String get empireUnitHealing => 'Healing';

  @override
  String get empireUnitEnRoute => 'En route';

  @override
  String get empireUnitNoMovement => 'no movement';

  @override
  String empireUnitsWithMovement(int count) {
    return '$count with movement';
  }

  @override
  String empireCitySubtitle(
    int population,
    int hexes,
    int buildings,
    String production,
  ) {
    return 'Population $population - $hexes tiles - $buildings bldg. - producing: $production';
  }

  @override
  String empireCityStoredArtifact(String artifactName) {
    return 'Artifact: $artifactName';
  }

  @override
  String empireCityGroupSubtitle(String cityLabel, int population) {
    return '$cityLabel - population $population';
  }

  @override
  String get empireStatsTitle => 'Empire status';

  @override
  String get empireStatsSubtitle =>
      'A quick read of readiness, composition, and city growth';

  @override
  String get empireStatsReadinessTitle => 'Unit readiness';

  @override
  String get empireStatsUnitCompositionTitle => 'Unit composition';

  @override
  String get empireStatsCityDevelopmentTitle => 'City development';

  @override
  String get empireStatsCityComparisonTitle => 'City comparison';

  @override
  String get empireStatsOrders => 'With orders';

  @override
  String get empireStatsNoMovement => 'No movement';

  @override
  String get empireStatsAveragePopulation => 'Avg. pop.';

  @override
  String get empireStatsTotalBuildings => 'Buildings';

  @override
  String get empireStatsStoredArtifacts => 'Artifacts';

  @override
  String get empireStatsTerritory => 'Territory';

  @override
  String get empireStatsCitiesProducing => 'Production';

  @override
  String get empireStatsOther => 'Other';

  @override
  String get empireStatsEmptyUnits => 'No units to analyze';

  @override
  String get empireStatsEmptyCities => 'No cities to analyze';

  @override
  String empireStatsCityBarDetail(int population, int buildings) {
    return 'Pop. $population • bldg. $buildings';
  }

  @override
  String empireStatsCityComparisonDetail(
    int population,
    int production,
    int food,
    int gold,
  ) {
    return 'Pop. $population • Prod. $production • Food $food • Gold $gold';
  }

  @override
  String get empireStatsMetricPopulation => 'Pop.';

  @override
  String get empireStatsMetricProduction => 'Prod.';

  @override
  String get empireStatsMetricFood => 'Food';

  @override
  String get empireStatsMetricGold => 'Gold';

  @override
  String get activityLogTitle => 'Activity log';

  @override
  String get activityLogShowAllAction => 'Show all';

  @override
  String activityLogShowMoreAction(int visible, int total) {
    return 'Show more ($visible/$total)';
  }

  @override
  String get activityLogLoadingHistory => 'Loading full history...';

  @override
  String get activityLogHistoryErrorTitle => 'Could not load history';

  @override
  String activityLogHistoryErrorBody(String error) {
    return 'The event journal is unavailable: $error';
  }

  @override
  String get activityLogFilterAll => 'All';

  @override
  String get activityLogFilterAllShort => 'All';

  @override
  String get activityLogFilterCombat => 'Combat';

  @override
  String get activityLogFilterCities => 'Cities';

  @override
  String get activityLogFilterDiplomacy => 'Diplomacy';

  @override
  String get activityLogFilterDiplomacyShort => 'Diplo';

  @override
  String get activityLogFilterTechnology => 'Science';

  @override
  String get activityLogEmptyAllTitle => 'No recorded events';

  @override
  String get activityLogEmptyCombatTitle => 'No recorded battles';

  @override
  String get activityLogEmptyCityTitle => 'No recorded city events';

  @override
  String get activityLogEmptyDiplomacyTitle => 'No recorded diplomacy';

  @override
  String get activityLogEmptyTechnologyTitle => 'No recorded discoveries';

  @override
  String get activityLogEmptyAllBody =>
      'First discoveries, battles, and builds will appear here after you play actions.';

  @override
  String get activityLogEmptyCombatBody =>
      'Battles are recorded after attacks or defenses visible to the player.';

  @override
  String get activityLogEmptyCityBody =>
      'Founded cities, builds, and claimed tiles will create the empire timeline here.';

  @override
  String get activityLogEmptyDiplomacyBody =>
      'Dispatches, proposals, replies, and relation changes will appear here after diplomatic actions.';

  @override
  String get activityLogEmptyTechnologyBody =>
      'Discovered technologies will appear here after research completes.';

  @override
  String get turnTimelineTitle => 'Turn timeline';

  @override
  String turnTimelineSubtitle(int turn, int count) {
    return 'Turn $turn • events: $count';
  }

  @override
  String get turnTimelineChartTitle => 'Events across turns';

  @override
  String get turnTimelineMetricEvents => 'Events';

  @override
  String get turnTimelineMetricActiveTurns => 'Active turns';

  @override
  String get turnTimelineMetricCurrentTurn => 'Current turn';

  @override
  String get technologyDiscoveryEyebrow => 'Technology discovered';

  @override
  String unitSelectionMovementSubtitle(int current, int max) {
    return 'Move $current/$max';
  }

  @override
  String unitSelectionMovementHpSubtitle(
    int current,
    int max,
    int hp,
    int maxHp,
  ) {
    return 'Move $current/$max • HP $hp/$maxHp';
  }

  @override
  String get unitSelectionAttackLabel => 'Attack';

  @override
  String get unitSelectionDefenseLabel => 'Defense';

  @override
  String get unitSelectionHpLabel => 'HP';

  @override
  String get unitSelectionRangeLabel => 'Range';

  @override
  String get unitSelectionConstructionLabel => 'Construction';

  @override
  String get unitSelectionWorkLabel => 'Work';

  @override
  String get unitSelectionFieldBonusValue => 'Field bonus';

  @override
  String get tileSelectionYieldTitle => 'Tile potential';

  @override
  String get tileSelectionYieldTooltip =>
      'Inspection estimate for this tile, not actual city yield.';

  @override
  String get tileSelectionBonusLabel => 'Bonus';

  @override
  String get tileSelectionDefenseBonusValue => '+defense';

  @override
  String get tileSelectionRiverBonusValue => '+river';

  @override
  String get citySelectionYieldTitle => 'City income';

  @override
  String get citySelectionYieldTooltip =>
      'Actual city yield per turn from the city economy.';

  @override
  String citySelectionSubtitle(
    int population,
    int territoryHexCount,
    int maxHexes,
    String production,
  ) {
    return 'Population $population • $territoryHexCount/$maxHexes fields • Production: $production';
  }

  @override
  String get citySelectionTerritoryLabel => 'Territory';

  @override
  String get citySelectionFoodLabel => 'Food';

  @override
  String get citySelectionNetFoodLabel => 'Net food';

  @override
  String get citySelectionBuildingsLabel => 'Buildings';

  @override
  String get citySelectionArtifactLabel => 'Artifact';

  @override
  String get worldArtifactBonusTitle => 'Bonus';

  @override
  String get worldArtifactHeritageTitle => 'Heritage';

  @override
  String get worldArtifactHeritageBody =>
      'Collect and place 6 unique artifacts in your cities, then hold the collection for 5 turns.';

  @override
  String get worldArtifactAncientImperialCrown => 'Ancient Imperial Crown';

  @override
  String get worldArtifactAstronomersTablets => 'Astronomers\' Tablets';

  @override
  String get worldArtifactProphetMask => 'Prophet\'s Mask';

  @override
  String get worldArtifactHeroSword => 'Hero\'s Sword';

  @override
  String get worldArtifactMerchantsSeal => 'Merchant\'s Seal';

  @override
  String get worldArtifactFirstPeoplesChronicle => 'First Peoples\' Chronicle';

  @override
  String get worldArtifactTempleReliquary => 'Temple Reliquary';

  @override
  String get worldArtifactQueensMirror => 'Queen\'s Mirror';

  @override
  String get worldArtifactAncientImperialCrownShortBonus => '+1 defense';

  @override
  String get worldArtifactAstronomersTabletsShortBonus => '+1 science';

  @override
  String get worldArtifactProphetMaskShortBonus => '+1 gold, diplomacy';

  @override
  String get worldArtifactHeroSwordShortBonus => '+2 XP for produced units';

  @override
  String get worldArtifactMerchantsSealShortBonus => '+2 gold';

  @override
  String get worldArtifactFirstPeoplesChronicleShortBonus => '+1 food';

  @override
  String get worldArtifactTempleReliquaryShortBonus => '+1 food, +1 defense';

  @override
  String get worldArtifactQueensMirrorShortBonus => '+1 gold, diplomacy';

  @override
  String get worldArtifactAncientImperialCrownDescription =>
      'A symbol of old rule. Once stored in a city, it strengthens defense and the prestige of the collection.';

  @override
  String get worldArtifactAstronomersTabletsDescription =>
      'Stone tablets with ancient maps of the sky. In a city, they support science.';

  @override
  String get worldArtifactProphetMaskDescription =>
      'A ritual mask of great political weight. In a city, it grants gold and diplomatic value.';

  @override
  String get worldArtifactHeroSwordDescription =>
      'The weapon of a legendary commander. Units produced in this city gain extra experience.';

  @override
  String get worldArtifactMerchantsSealDescription =>
      'The mark of the first merchant guilds. In a city, it strengthens gold income.';

  @override
  String get worldArtifactFirstPeoplesChronicleDescription =>
      'A record of the oldest lineages and borders. In a city, it supports growth.';

  @override
  String get worldArtifactTempleReliquaryDescription =>
      'A sacred reliquary that gives the city stability, food, and defense.';

  @override
  String get worldArtifactQueensMirrorDescription =>
      'A court treasure joining trade with diplomacy. In a city, it grants gold and prestige.';

  @override
  String get worldArtifactLocationMap => 'Artifact on the map';

  @override
  String get worldArtifactLocationExcavation => 'Excavation in progress';

  @override
  String get worldArtifactLocationCarried => 'Carried by a unit';

  @override
  String get worldArtifactLocationStored => 'Stored in a city';

  @override
  String get worldArtifactStepExcavate => 'Excavate';

  @override
  String get worldArtifactStepMove => 'Move';

  @override
  String get worldArtifactStepStore => 'Store';

  @override
  String get artifactGuidanceUnknownCityName => 'a city';

  @override
  String get artifactGuidanceStoredTitle => 'Artifact stored';

  @override
  String artifactGuidanceStoredBody(String artifactName, String cityName) {
    return '$artifactName strengthens $cityName. Cultural victory needs 6 artifacts in cities for 5 turns.';
  }

  @override
  String get artifactGuidanceCarriedTitle => 'Artifact carried';

  @override
  String artifactGuidanceCarriedBody(String artifactName) {
    return 'The unit carries $artifactName. Bring it to one of your cities with a free slot and use the store action.';
  }

  @override
  String get artifactGuidanceReachedTitle => 'Artifact discovered';

  @override
  String artifactGuidanceReachedBody(String artifactName) {
    return '$artifactName is under the unit. Use the Excavation action to pick it up.';
  }

  @override
  String get citySelectionSpecializationLabel => 'Specialization';

  @override
  String get fieldImprovementOutsideActiveCity => 'Outside active city';

  @override
  String get fieldImprovementYieldTitle => 'Improvement bonus';

  @override
  String get fieldImprovementYieldTooltip =>
      'Additional yield from the field improvement.';

  @override
  String get hexKindIdealCitySite => 'Ideal city site';

  @override
  String get hexKindGoodCitySite => 'Good city site';

  @override
  String get hexKindFertileField => 'Fertile field';

  @override
  String get hexKindFertilePlains => 'Fertile plains';

  @override
  String get hexKindRichPlain => 'Rich plain';

  @override
  String get hexKindStrategicBorderland => 'Strategic borderland';

  @override
  String get hexKindStrategicField => 'Strategic field';

  @override
  String get hexKindDefensivePosition => 'Defensive position';

  @override
  String get hexKindFertileForest => 'Fertile forest';

  @override
  String get hexKindForestBackline => 'Forest backline';

  @override
  String get hexKindForestForge => 'Forest forge';

  @override
  String get hexKindWildLand => 'Wild land';

  @override
  String get hexKindRichWilds => 'Rich wilds';

  @override
  String get hexKindExoticBackline => 'Exotic backline';

  @override
  String get hexKindDifficultStrategicTerrain => 'Difficult strategic terrain';

  @override
  String get hexKindHighGround => 'High ground';

  @override
  String get hexKindRiverHills => 'River hills';

  @override
  String get hexKindIndustrialStronghold => 'Industrial stronghold';

  @override
  String get hexKindRichHills => 'Rich hills';

  @override
  String get hexKindBarrenLand => 'Barren land';

  @override
  String get hexKindOasis => 'Oasis';

  @override
  String get hexKindTradeOasis => 'Trade oasis';

  @override
  String get hexKindDesertDeposits => 'Desert deposits';

  @override
  String get hexKindHarshLand => 'Harsh land';

  @override
  String get hexKindColdPastures => 'Cold pastures';

  @override
  String get hexKindResourceOutpost => 'Resource outpost';

  @override
  String get hexKindHostileLand => 'Hostile land';

  @override
  String get hexKindArcticDeposits => 'Arctic deposits';

  @override
  String get hexKindCoast => 'Coast';

  @override
  String get hexKindFishingCoast => 'Fishing coast';

  @override
  String get hexKindRichCoast => 'Rich coast';

  @override
  String get hexKindRiverPort => 'River port';

  @override
  String get hexKindRegionalPortHeart => 'Regional port hub';

  @override
  String get hexKindOpenSea => 'Open sea';

  @override
  String get hexKindNaturalBarrier => 'Natural barrier';

  @override
  String get hexKindPromisingLand => 'Promising land';

  @override
  String get hexKindWeakLand => 'Weak land';

  @override
  String get hexKindOrdinaryLand => 'Ordinary land';

  @override
  String get hexKindMapTile => 'Map tile';

  @override
  String get hexKindIdealCitySiteDescription =>
      'A high-value settlement tile with food, growth, and expansion pressure already lined up.';

  @override
  String get hexKindGoodCitySiteDescription =>
      'Solid terrain for a city center with enough baseline value to support early growth.';

  @override
  String get hexKindFertileFieldDescription =>
      'River-fed grassland that favors food, population growth, and worker improvements.';

  @override
  String get hexKindFertilePlainsDescription =>
      'Open plains with river support, useful for balanced food and production.';

  @override
  String get hexKindRichPlainDescription =>
      'A valuable open tile with luxury or trade value worth bringing inside borders.';

  @override
  String get hexKindStrategicBorderlandDescription =>
      'Good land with strategic value, useful for expansion before rivals claim it.';

  @override
  String get hexKindStrategicFieldDescription =>
      'A plains tile tied to strategic resources or pressure on the frontier.';

  @override
  String get hexKindDefensivePositionDescription =>
      'Terrain that improves defensive control and helps hold nearby approaches.';

  @override
  String get hexKindFertileForestDescription =>
      'A forest with river support, mixing growth potential with natural cover.';

  @override
  String get hexKindForestBacklineDescription =>
      'A safer forest tile that can support growth or hunting-oriented improvements.';

  @override
  String get hexKindForestForgeDescription =>
      'Forest with industrial resource value, promising for production once improved.';

  @override
  String get hexKindWildLandDescription =>
      'Dense terrain with friction; useful only when you have a clear worker or expansion plan.';

  @override
  String get hexKindRichWildsDescription =>
      'Wild terrain with enough fertility or resources to justify careful development.';

  @override
  String get hexKindExoticBacklineDescription =>
      'A jungle or wetland tile carrying luxury value for later borders and trade.';

  @override
  String get hexKindDifficultStrategicTerrainDescription =>
      'Hard terrain with strategic resource value; powerful later, awkward early.';

  @override
  String get hexKindHighGroundDescription =>
      'Hills that favor defense and map control more than fast growth.';

  @override
  String get hexKindRiverHillsDescription =>
      'Hills beside a river, combining defense with better economic potential.';

  @override
  String get hexKindIndustrialStrongholdDescription =>
      'Hills with industrial resources, a strong production target for a city.';

  @override
  String get hexKindRichHillsDescription =>
      'Hills with wealth resources, useful for gold or production-focused expansion.';

  @override
  String get hexKindBarrenLandDescription =>
      'Dry land with little immediate value unless later tech or borders change the plan.';

  @override
  String get hexKindOasisDescription =>
      'Desert softened by river access, turning weak land into a usable growth tile.';

  @override
  String get hexKindTradeOasisDescription =>
      'A desert trade pocket that can become valuable with the right improvement.';

  @override
  String get hexKindDesertDepositsDescription =>
      'Poor settlement land with a strategic deposit that matters more in later eras.';

  @override
  String get hexKindHarshLandDescription =>
      'Cold or rough land with limited early economy and slow development.';

  @override
  String get hexKindColdPasturesDescription =>
      'Cold terrain with enough pasture value to support a border city.';

  @override
  String get hexKindResourceOutpostDescription =>
      'Remote cold land worth claiming mainly for the resource it protects.';

  @override
  String get hexKindHostileLandDescription =>
      'Unfriendly ground with weak settlement value and few immediate returns.';

  @override
  String get hexKindArcticDepositsDescription =>
      'Snowy resource land that is hard to use but can matter strategically.';

  @override
  String get hexKindCoastDescription =>
      'Coastal land that opens naval access and flexible city growth.';

  @override
  String get hexKindFishingCoastDescription =>
      'Coast with food value, a strong reason to work or settle near the water.';

  @override
  String get hexKindRichCoastDescription =>
      'Coastal luxury or trade value worth folding into city borders.';

  @override
  String get hexKindRiverPortDescription =>
      'A river mouth with trade and movement value for a coastal city.';

  @override
  String get hexKindRegionalPortHeartDescription =>
      'A strong coastal center where river and resource value stack together.';

  @override
  String get hexKindOpenSeaDescription =>
      'Water that is useful for ships and scouting, but not for land settlement.';

  @override
  String get hexKindNaturalBarrierDescription =>
      'Blocked terrain that shapes movement and defense rather than economy.';

  @override
  String get hexKindPromisingLandDescription =>
      'A generally useful tile with enough value to inspect before moving on.';

  @override
  String get hexKindWeakLandDescription =>
      'Low-return terrain that rarely deserves early worker time.';

  @override
  String get hexKindOrdinaryLandDescription =>
      'A normal tile with no standout strength, useful when it fits the city plan.';

  @override
  String get hexKindMapTileDescription =>
      'A plain map tile without enough information to make a strong judgment.';

  @override
  String get hexTagCity => 'City site';

  @override
  String get hexTagDefense => 'Defensive position';

  @override
  String get hexTagTrade => 'Trade route';

  @override
  String get hexTagFertile => 'Fertile field';

  @override
  String get hexTagProduction => 'Good production';

  @override
  String get hexTagHostile => 'Hostile land';

  @override
  String get hexTagStrategic => 'Strategic resource';

  @override
  String get hexTagWater => 'Water passage';

  @override
  String get hexRecommendationFoundCity => 'Good development site';

  @override
  String get hexRecommendationDefendHere => 'Good defensive position';

  @override
  String get hexRecommendationExploitEconomy => 'Worth exploiting';

  @override
  String get hexRecommendationAvoid => 'Avoid without a plan';

  @override
  String get hexRecommendationNeutral => 'Inspect before moving';

  @override
  String get hexRecommendationFoundCityDetail =>
      'If borders are free, consider founding or steering a settler here.';

  @override
  String get hexRecommendationDefendHereDetail =>
      'Use it to anchor units, protect borders, or cover nearby cities.';

  @override
  String get hexRecommendationExploitEconomyDetail =>
      'Bring it inside borders and assign a worker when the city can benefit.';

  @override
  String get hexRecommendationAvoidDetail =>
      'Skip it early unless a resource, route, or military need changes the value.';

  @override
  String get hexRecommendationNeutralDetail =>
      'Scout neighboring tiles and compare resources before committing a worker or settler.';

  @override
  String get selectionActionLockedReason => 'You cannot issue orders now.';

  @override
  String get selectionActionFoundCity => 'Found city';

  @override
  String get selectionActionCancel => 'Cancel';

  @override
  String get selectionActionCancelAttack => 'Cancel attack';

  @override
  String get selectionActionCancelWorkerBuild => 'Cancel improvement build';

  @override
  String get selectionActionCancelCityFounding => 'Cancel city founding';

  @override
  String get selectionActionCancelAutoExplore => 'Cancel exploration';

  @override
  String get selectionActionCancelArtifactExcavation =>
      'Cancel artifact excavation';

  @override
  String get selectionActionCancelTradeRouteSelection =>
      'Cancel trade route selection';

  @override
  String get selectionActionCancelMerchantMoveToCity => 'Cancel city travel';

  @override
  String get selectionActionCancelCommanderMerge => 'Cancel troop merge';

  @override
  String get selectionActionConfirm => 'Confirm';

  @override
  String selectionActionConfirmWithTurns(String turns) {
    return 'Confirm ($turns)';
  }

  @override
  String get selectionActionMinimize => 'Minimize';

  @override
  String get selectionActionConfirmAttack => 'Confirm attack';

  @override
  String get selectionActionCaptureCity => 'Capture city';

  @override
  String get selectionActionDestroyCity => 'Destroy city';

  @override
  String get selectionActionStopFortifying => 'Stop fortifying';

  @override
  String get selectionActionStopHealing => 'Stop healing';

  @override
  String get selectionActionMove => 'Move';

  @override
  String get selectionActionAttack => 'Attack';

  @override
  String get selectionActionAutoExplore => 'Explore';

  @override
  String get selectionActionTradeRoute => 'Trade route';

  @override
  String selectionActionTradeRouteToCity(String cityName) {
    return 'Trade with $cityName';
  }

  @override
  String get selectionActionMerchantMoveToCity => 'Go to city';

  @override
  String selectionActionMerchantMoveToCityTarget(String cityName) {
    return 'Go to $cityName';
  }

  @override
  String get selectionActionArmy => 'Army';

  @override
  String get selectionArmyEmpty => 'No troops';

  @override
  String selectionTroopDetachTooltip(String troop) {
    return 'Detach $troop';
  }

  @override
  String get selectionActionImprove => 'Improve';

  @override
  String get selectionActionSkip => 'Skip';

  @override
  String get selectionActionFortify => 'Fortify';

  @override
  String get selectionActionHeal => 'Heal';

  @override
  String get selectionActionCancelCityGrowth => 'Cancel growth';

  @override
  String get selectionActionCityGrowth => 'City growth';

  @override
  String get selectionActionProduction => 'Production';

  @override
  String get selectionActionExcavateArtifact => 'Excavate';

  @override
  String get selectionActionStoreArtifact => 'Store';

  @override
  String get selectionActionCancelCurrentMoveFirst =>
      'Cancel the current move first.';

  @override
  String get selectionActionArtifactAlreadyCarried =>
      'The unit already carries an artifact.';

  @override
  String get selectionActionStoreArtifactOwnCityRequired =>
      'Move to one of your cities.';

  @override
  String get selectionActionStoreArtifactCityOccupied =>
      'This city already stores an artifact.';

  @override
  String get selectionActionNoBuildAvailable =>
      'No build is available on this tile.';

  @override
  String get selectionActionUnitWorking => 'The unit is already working.';

  @override
  String get selectionActionUnitFortified => 'The unit is fortified.';

  @override
  String get selectionActionUnitHealing => 'The unit is healing.';

  @override
  String get selectionActionNoMovement => 'No movement points left this turn.';

  @override
  String get selectionActionNoAttack => 'This unit has no attack.';

  @override
  String get selectionActionNoVisibleEnemy => 'No visible enemy in range.';

  @override
  String get selectionActionMerchantNoOriginCity =>
      'Move the merchant into one of your cities.';

  @override
  String get selectionActionMerchantNoDestinationCity =>
      'You need another connected city.';

  @override
  String get selectionActionMerchantNoRoute =>
      'No trade route can reach this city.';

  @override
  String get selectionActionMerchantNoCityPath =>
      'The merchant cannot reach this city.';

  @override
  String get selectionActionCannotFoundCityHere => 'Cannot found a city here.';

  @override
  String get selectionActionFoundCityNoCommander =>
      'Only a settler or a commander with settlers can found a city.';

  @override
  String get selectionActionFoundCityNoSettlers =>
      'Settlers are required to found a city.';

  @override
  String get selectionActionFoundCityInvalidCenter =>
      'A city cannot be founded on this tile.';

  @override
  String get selectionActionFoundCityCityAlreadyExists =>
      'There is already a city on this tile.';

  @override
  String get selectionActionFoundCityCenterOccupied =>
      'This tile already belongs to a city.';

  @override
  String get selectionActionFoundCityTooCloseToCity =>
      'A city cannot be adjacent to another city.';

  @override
  String get selectionActionFoundCityInvalidControlledHexes =>
      'Choose valid city tiles first.';

  @override
  String get selectionActionCannotImproveCityCenter =>
      'Cannot build improvements on the city center.';

  @override
  String get selectionActionTileAlreadyImproved =>
      'This tile already has an improvement.';

  @override
  String get selectionActionTileMustBelongToCity =>
      'The tile must belong to a city.';

  @override
  String get selectionActionNoWorkerTile => 'No tile under the worker.';

  @override
  String get hudFeedbackNoTurnCostDetail => 'Action did not consume the turn';

  @override
  String get hudFeedbackAutoExploreNoTargetTitle => 'No exploration route';

  @override
  String get hudFeedbackAutoExploreNoTargetBody =>
      'The scout has no move that would reveal new tiles this turn.';

  @override
  String get hudFeedbackArtifactGuidanceTitle => 'World artifact';

  @override
  String get hudFeedbackArtifactGuidanceBody =>
      'Deliver it to one of your cities and place it in an empty artifact slot.';

  @override
  String get hudFeedbackActionBlockedTitle => 'Action unavailable';

  @override
  String get hudFeedbackActionBlockedBody =>
      'This action is blocked right now. Choose another tile or another command.';

  @override
  String get hudFeedbackAttackProtectedByTreatyTitle => 'Treaty blocks attack';

  @override
  String get hudFeedbackAttackProtectedByTreatyBody =>
      'You cannot attack a unit from a civilization that has an alliance or a truce with you. Change diplomatic relations first.';

  @override
  String get hudFeedbackMovementCityOccupiedTitle => 'City occupied';

  @override
  String get hudFeedbackMovementCityOccupiedBody =>
      'Only one unit can stand in a city. Move the garrison out first or choose another tile.';

  @override
  String get hudFeedbackMovementEnemyOccupiedTitle => 'Enemy on this tile';

  @override
  String get hudFeedbackMovementEnemyOccupiedBody =>
      'You cannot enter an enemy tile with a normal move. Use Attack or choose an adjacent tile.';

  @override
  String get hudFeedbackMovementForeignCityTitle => 'Foreign city';

  @override
  String get hudFeedbackMovementForeignCityBody =>
      'You cannot enter a foreign city with a normal move. Use Attack or choose another tile.';

  @override
  String get hudFeedbackMovementHiddenRouteTooFarTitle => 'Route too far';

  @override
  String get hudFeedbackMovementHiddenRouteTooFarBody =>
      'You cannot plot such a long route through undiscovered terrain. Pick a shorter segment or use scout auto-exploration.';

  @override
  String get hudFeedbackMovementBlockedTerrainTitle =>
      'Terrain blocks movement';

  @override
  String get hudFeedbackMovementBlockedTerrainBody =>
      'This unit cannot enter that terrain type. Choose another tile or a route around it.';

  @override
  String get hudFeedbackMovementInsufficientUnitMovementTitle =>
      'Not enough movement';

  @override
  String get hudFeedbackMovementInsufficientUnitMovementBody =>
      'This unit does not have enough movement to enter that area. Upgrade it or use another unit.';

  @override
  String get hudFeedbackMovementNoRouteTitle => 'No route';

  @override
  String get hudFeedbackMovementNoRouteBody =>
      'There is no available route to that tile. Try a closer target or another approach.';

  @override
  String selectionCommandUnavailableDescription(String label) {
    return 'Action \"$label\" is unavailable for the current selection.';
  }

  @override
  String selectionCommandActiveDescription(String label) {
    return 'Action \"$label\" is an active mode. Choose a target on the map or cancel the mode if you changed your mind.';
  }

  @override
  String selectionCommandProminentDescription(String label) {
    return 'Action \"$label\" is currently the most important command for this selection.';
  }

  @override
  String selectionCommandDefaultDescription(String label) {
    return 'Runs action \"$label\" for the currently selected unit, city, or tile.';
  }

  @override
  String get selectionInfoChipDisabledDescription =>
      'This information panel is not available for the current selection.';

  @override
  String selectionInfoChipOpenDescription(String label) {
    return 'Opens \"$label\" details for the currently selected tile, unit, or city.';
  }

  @override
  String turnCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turns',
      one: '1 turn',
      zero: '0 turns',
    );
    return '$_temp0';
  }

  @override
  String turnPillLabel(int turn) {
    return 'T$turn';
  }

  @override
  String get turnEtaNoProgress => 'no progress';

  @override
  String turnEtaDetailLabel(String turnsLabel, int turn) {
    return '$turnsLabel • turn $turn';
  }

  @override
  String turnEtaTooltipNoTurn(String turnsLabel) {
    return '$turnsLabel to complete';
  }

  @override
  String turnEtaTooltipExpectedTurn(String turnsLabel, int turn) {
    return '$turnsLabel to complete • expected turn $turn';
  }

  @override
  String get modeBannerWorkedTilesTitle => 'Worked tiles';

  @override
  String get modeBannerWorkedTilesInstruction =>
      'Tap controlled tiles to toggle city work.';

  @override
  String get modeBannerCityGrowthTitle => 'City growth';

  @override
  String get modeBannerCityGrowthInstructionSelected =>
      'The selected tile will be claimed on the next city growth. Confirm it or choose another tile.';

  @override
  String get modeBannerCityGrowthInstructionEmpty =>
      'Tap an outlined tile to choose the next growth hex. Without a choice, the city will use its recommendation.';

  @override
  String get modeBannerWorkerActionTitle => 'Tile improvement';

  @override
  String get modeBannerWorkerActionInstructionPicked =>
      'Confirm the improvement in the worker popup.';

  @override
  String get modeBannerWorkerActionInstructionEmpty =>
      'Choose an improvement type in the worker popup.';

  @override
  String get modeBannerMerchantTradeRouteTitle => 'Trade route';

  @override
  String get modeBannerMerchantTradeRouteInstruction =>
      'Choose one of your cities. The merchant will travel there automatically and turn back after arrival.';

  @override
  String get modeBannerMerchantMoveToCityTitle => 'Go to city';

  @override
  String get modeBannerMerchantMoveToCityInstruction =>
      'Choose one of your cities. The merchant will plot a path to its center without creating a trade route.';

  @override
  String workerActionSelectedImprovement(String title) {
    return 'Selected: $title';
  }

  @override
  String get workerActionSelectImprovement => 'Choose improvement';

  @override
  String get workerActionBuildDetailTitle => 'Tile improvement';

  @override
  String workerActionBuildImprovement(String title) {
    return 'Build $title';
  }

  @override
  String get workerActionSelectionHint =>
      'Click an improvement for this tile, inspect yields, and confirm the build.';

  @override
  String get workerActionNoYieldChange => 'no yield change';

  @override
  String get modeBannerResearchSelectionTitle => 'Choose research';

  @override
  String get modeBannerResearchSelectionInstruction =>
      'Open the technology tree and choose a research target to continue the turn.';

  @override
  String get modeBannerUnitTurnSkipTitle => 'Turn skipped';

  @override
  String get modeBannerUnitTurnSkipInstruction =>
      'The unit waits until the next turn. Its state is visible in the bottom bar.';

  @override
  String get modeBannerCommanderMergeTitle => 'Merge troops';

  @override
  String get modeBannerCommanderMergeInstruction =>
      'Select a friendly unit for the commander to add to the army.';

  @override
  String get modeBannerAttackTargetingTitle => 'Attack';

  @override
  String get modeBannerAttackTargetingInstructionSelected =>
      'Check the combat forecast in the popup and confirm the attack.';

  @override
  String get modeBannerAttackTargetingInstructionEmpty =>
      'Select an enemy in range or its hex to see the combat forecast.';

  @override
  String get modeBannerAttackRetreatProgress => 'Retreat';

  @override
  String get modeBannerActionToolbarHint =>
      'Use the bottom toolbar for actions when you need them.';

  @override
  String get combatPreviewConfirmBody =>
      'The selected unit will attack immediately after confirmation.';

  @override
  String get combatPreviewOutcomeLabel => 'Outcome';

  @override
  String get combatPreviewTargetLabel => 'Target';

  @override
  String get combatPreviewRetaliationLabel => 'Retaliation';

  @override
  String get combatPreviewStrengthLabel => 'Strength';

  @override
  String get combatPreviewAttackerRole => 'Attacker';

  @override
  String get combatPreviewDefenderRole => 'Defender';

  @override
  String get combatPreviewCityRole => 'City';

  @override
  String combatPreviewOutcomeLine(String outcome) {
    return 'Outcome: $outcome';
  }

  @override
  String get combatPreviewOutcomeCityFalls => 'city falls';

  @override
  String get combatPreviewOutcomeDefenderKilled => 'defender dies';

  @override
  String get combatPreviewOutcomeAttackerKilled =>
      'attacker dies in retaliation';

  @override
  String get combatPreviewOutcomeDefenderRetreated => 'defender will retreat';

  @override
  String get combatPreviewOutcomeCitySurvives => 'city survives';

  @override
  String get combatPreviewOutcomeDefenderSurvives => 'defender survives';

  @override
  String combatPreviewTargetLine(
    int hpBefore,
    int hpAfter,
    int hpMax,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Target: HP $hpBefore->$hpAfter/$hpMax, Attack $attack vs Defense $defense (-$damage)';
  }

  @override
  String combatPreviewNoRetaliationLine(int distance, int range) {
    return 'Retaliation: none (ranged attack, distance $distance, range $range)';
  }

  @override
  String combatPreviewRetaliationLine(
    int attack,
    int defense,
    int damage,
    int hpBefore,
    int hpAfter,
    int hpMax,
  ) {
    return 'Retaliation: Attack $attack vs Defense $defense (-$damage), HP $hpBefore->$hpAfter/$hpMax';
  }

  @override
  String combatPreviewHpDamageValue(
    int hpBefore,
    int hpAfter,
    int hpMax,
    int damage,
  ) {
    return '$hpBefore → $hpAfter/$hpMax HP, -$damage';
  }

  @override
  String get combatPreviewForecastTitle => 'Combat forecast';

  @override
  String get combatPreviewNoHpLoss => 'no damage';

  @override
  String combatPreviewHpAfterSemantics(int hpAfter, int hpMax, int loss) {
    return '$hpAfter of $hpMax HP after combat, $loss HP lost';
  }

  @override
  String combatPreviewStrengthValue(int attack, int defense) {
    return '$attack attack vs $defense defense';
  }

  @override
  String get combatPreviewAdvantageTitle => 'Why this forecast?';

  @override
  String combatPreviewAdvantageAttacker(
    String country,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Attack advantage: $country has $attack attack against $defense defense; the target loses about $damage HP.';
  }

  @override
  String combatPreviewAdvantageDefender(
    String country,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Defense advantage: $country has $defense defense against $attack attack; the hit deals about $damage HP.';
  }

  @override
  String combatPreviewAdvantageEven(int attack, int defense, int damage) {
    return 'Even fight: $attack attack against $defense defense; forecast damage is about $damage HP.';
  }

  @override
  String combatPreviewTerrainLine(
    String attackerCountry,
    String attackerTerrain,
    String defenderCountry,
    String defenderTerrain,
  ) {
    return 'Positions: $attackerCountry attacks from $attackerTerrain. $defenderCountry defends on $defenderTerrain.';
  }

  @override
  String combatPreviewSourcesLine(String sources) {
    return 'The edge comes from: $sources.';
  }

  @override
  String combatPreviewPositiveSourcesLine(
    String attackerCountry,
    String sources,
  ) {
    return 'Helps the attack ($attackerCountry): $sources.';
  }

  @override
  String combatPreviewNegativeSourcesLine(
    String defenderCountry,
    String sources,
  ) {
    return 'Helps the defense ($defenderCountry): $sources.';
  }

  @override
  String get combatPreviewNoSourcesLine =>
      'No modifiers apply: base unit stats and the combat result decide this forecast.';

  @override
  String combatPreviewNoRetaliationReason(int distance, int range) {
    return 'No retaliation: this is a ranged attack (distance $distance, attack range $range).';
  }

  @override
  String get combatPreviewNoRetaliationDefenderDefeated =>
      'No retaliation: the target is defeated before it can answer.';

  @override
  String get combatPreviewNoRetaliationDefenderRetreats =>
      'No retaliation: the target retreats after the hit.';

  @override
  String get combatPreviewNoRetaliationNoAttack =>
      'No retaliation: the target has no attack strength in this forecast.';

  @override
  String combatPreviewRetaliationRisk(
    String defenderCountry,
    String attackerCountry,
    int damage,
  ) {
    return 'Retaliation: $defenderCountry answers and $attackerCountry loses about $damage HP.';
  }

  @override
  String get combatPreviewSourceAttackTerrain => 'attacker terrain';

  @override
  String get combatPreviewSourceDefenseTerrain => 'defender terrain';

  @override
  String get combatPreviewSourceTechnology => 'technology';

  @override
  String get combatPreviewSourceVeterancy => 'experience';

  @override
  String get combatPreviewSourceCityGarrison => 'city garrison';

  @override
  String get combatPreviewSourceMixedArmy => 'unit composition';

  @override
  String get combatCounterSpearmanVsMountedAttack =>
      'spearmen against mounted units';

  @override
  String get combatCounterSpearmanVsMountedDefense =>
      'spearmen holding against mounted units';

  @override
  String get combatCounterArcherDefensiveTerrainDefense =>
      'archers in defensive terrain';

  @override
  String get combatCounterCavalryRoughAttack =>
      'cavalry slowed by rough terrain';

  @override
  String get combatCounterCavalryOpenRaid => 'cavalry raid on open terrain';

  @override
  String get combatCounterHeavyInfantryBreakthrough =>
      'heavy infantry breaking the line';

  @override
  String get terrainOcean => 'ocean';

  @override
  String get terrainCoast => 'coast';

  @override
  String get terrainLake => 'lake';

  @override
  String get terrainPlains => 'plains';

  @override
  String get terrainGrassland => 'grassland';

  @override
  String get terrainDesert => 'desert';

  @override
  String get terrainTundra => 'tundra';

  @override
  String get terrainSnow => 'snow';

  @override
  String get terrainMountain => 'mountains';

  @override
  String get terrainHills => 'hills';

  @override
  String get terrainWetlands => 'wetlands';

  @override
  String get terrainJungle => 'jungle';

  @override
  String get terrainForest => 'forest';

  @override
  String get terrainRiver => 'river';

  @override
  String get modeBannerMoveTargetingTitle => 'Movement mode';

  @override
  String get modeBannerMoveTargetingInstruction =>
      'The first tap on a hex plots the route. Tap the same hex again to move; a longer route is queued for future turns.';

  @override
  String get modeBannerMoveTargetingCancelAction => 'Exit movement';

  @override
  String get modeBannerWorkerFindTileTitle => 'Worker: find a tile';

  @override
  String modeBannerWorkerFindTileInstruction(String reason) {
    return '$reason Move the worker to one of your city tiles without an improvement, or to terrain that matches an unlocked build.';
  }

  @override
  String get modeBannerWorkerFindTileDetailOwnCity => 'Own city tile';

  @override
  String get modeBannerWorkerFindTileDetailNoImprovement => 'No improvement';

  @override
  String get modeBannerWorkerFindTileDetailMatchingTerrain =>
      'Matching terrain';

  @override
  String get modeBannerWorkerImproveTileTitle => 'Worker: improve tile';

  @override
  String get modeBannerWorkerImproveTileInstruction =>
      'This tile can be improved. If you want to act, use the bottom toolbar, choose the best build, and confirm it in the bottom panel.';

  @override
  String get modeBannerWorkerImproveTileDetailYields => 'Increases tile yields';

  @override
  String get modeBannerWorkerImproveTileDetailMovement => 'Uses movement';

  @override
  String get modeBannerScoutExploreTitle => 'Scout: explore';

  @override
  String get modeBannerScoutExploreInstruction =>
      'Enable exploration from the bottom toolbar so the scout discovers the nearest unknown tiles automatically. You can cancel it later from unit actions.';

  @override
  String get modeBannerScoutExploreDetailAuto => 'Auto exploration';

  @override
  String get modeBannerScoutExploreDetailReveal => 'Reveals the map';

  @override
  String get modeBannerSettlerFindSiteTitle => 'Settler: find a site';

  @override
  String modeBannerSettlerFindSiteInstruction(String reason) {
    return '$reason Move the settler to a free tile outside city borders; avoid water, mountains, and occupied centers.';
  }

  @override
  String get modeBannerSettlerFindSiteDetailFreeHex => 'Free hex';

  @override
  String get modeBannerSettlerFindSiteDetailOutsideBorders => 'Outside borders';

  @override
  String get modeBannerSettlerFindSiteDetailLandOrCoast => 'Land or coast';

  @override
  String get modeBannerSettlerFoundCityTitle => 'Settler: found city';

  @override
  String get modeBannerSettlerFoundCityInstruction =>
      'This tile can become a city. If you want to found one, use the bottom toolbar, then choose the city\'s starting tiles on the map.';

  @override
  String get modeBannerSettlerFoundCityDetailNewCity => 'New city';

  @override
  String get modeBannerSettlerFoundCityDetailChooseTiles =>
      'Choose tiles after tapping';

  @override
  String get modeBannerCityFoundingTitle => 'Founding a city';

  @override
  String get modeBannerCityFoundingInstructionReady =>
      'Ready. Confirm founding the city in the bottom toolbar or change the selected tiles on the map.';

  @override
  String modeBannerCityFoundingInstructionPick(int count) {
    return 'Choose $count connected tiles around the settler. After choosing them, the found-city action will be available in the bottom toolbar.';
  }

  @override
  String get selectionImprovementListTitle => 'Tile improvements';

  @override
  String get mapInspectionPossibleImprovementsTitle => 'Possible improvements';

  @override
  String get mapInspectionNoPossibleImprovements => 'No possible improvements';

  @override
  String get mapInspectionImprovementAvailableFromStart => 'from start';

  @override
  String get mapInspectionObjectiveTitle => 'Map objective';

  @override
  String get mapObjectiveRuins => 'Ruins';

  @override
  String get mapObjectiveStrategicPass => 'Strategic pass';

  @override
  String get mapObjectiveHolySite => 'Holy site';

  @override
  String get mapObjectiveLegendaryResource => 'Legendary deposit';

  @override
  String get mapObjectiveRuinsDescription =>
      'A neutral exploration point. Holding it adds victory pressure.';

  @override
  String get mapObjectiveStrategicPassDescription =>
      'A key passage through the terrain. Control turns movement into leverage.';

  @override
  String get mapObjectiveHolySiteDescription =>
      'A culturally important site. Control grants gold and victory points.';

  @override
  String get mapObjectiveLegendaryResourceDescription =>
      'A rare deposit worth expansion or conflict. Control grants the largest reward.';

  @override
  String mapObjectiveStatusNeutral(int turns) {
    return 'Hold $turns turns';
  }

  @override
  String mapObjectiveStatusHolding(int held, int required) {
    return 'Holding $held/$required';
  }

  @override
  String mapObjectiveStatusCompleted(int held, int required) {
    return 'Controlled $held/$required';
  }

  @override
  String get mapObjectiveStatusContested => 'Contested';

  @override
  String mapObjectiveRewardVictoryPoints(int points) {
    return '+$points VP';
  }

  @override
  String mapObjectiveRewardGoldPerTurn(int gold) {
    return '+$gold gold/turn';
  }

  @override
  String get selectionImprovementStateBuilt => 'BUILT';

  @override
  String get selectionImprovementStateAvailable => 'AVAILABLE';

  @override
  String get selectionImprovementStateNeedsTechnology => 'TECH';

  @override
  String get selectionImprovementStateNeedsCity => 'CITY';

  @override
  String get selectionImprovementStateBlocked => 'LIMIT';

  @override
  String get selectionImprovementNoBonus => 'No bonus';

  @override
  String workerImprovementYieldFood(int value) {
    return '+$value food';
  }

  @override
  String workerImprovementYieldProduction(int value) {
    return '+$value production';
  }

  @override
  String workerImprovementYieldGold(int value) {
    return '+$value gold';
  }

  @override
  String workerImprovementYieldDefense(int value) {
    return '+$value defense';
  }

  @override
  String get workerImprovementNoBonus => 'No extra bonus.';

  @override
  String get workerImprovementOnlyWorker => 'Only a worker can build this.';

  @override
  String get workerImprovementWorkerBusy => 'The worker is already building.';

  @override
  String get workerImprovementStopQueuedMove =>
      'Stop the planned movement first.';

  @override
  String get workerImprovementMissingTile => 'No tile under the unit.';

  @override
  String get workerImprovementMissingResource =>
      'This improvement requires a matching resource.';

  @override
  String get workerImprovementInvalidTerrain =>
      'Wrong base terrain for this improvement.';

  @override
  String get workerImprovementMissingRiver =>
      'This improvement requires a river.';

  @override
  String get workerImprovementBlocked => 'This action is blocked now.';

  @override
  String unitSelectionWorkerJobTurns(String name, int turns) {
    return '$name (${turns}T)';
  }

  @override
  String get resourceValueNoMatchingImprovement => 'No matching improvement';

  @override
  String get resourceValueSelectWorkerOrCity => 'Select worker or city';

  @override
  String get resourceValueTileAlreadyImproved =>
      'Tile already has an improvement';

  @override
  String get resourceValueCityCenter => 'City center';

  @override
  String resourceValueWorksForCity(String city) {
    return 'Works for: $city';
  }

  @override
  String get resourceValueOutsideCityBorders => 'Outside city borders';

  @override
  String get resourceValueNoLegalImprovementForTile =>
      'No legal improvement for this tile';

  @override
  String resourceValueRequiresTechnology(String technology) {
    return 'Requires: $technology';
  }

  @override
  String get resourceValueAvailableForWorker => 'Available for worker';

  @override
  String get resourceDetailNoResourcesOnTile => 'No resources on this tile';

  @override
  String get resourceDetailValueSection => 'Value';

  @override
  String get resourceDetailCurrentSection => 'Now';

  @override
  String get resourceDetailAfterImprovementSection => 'After improvement';

  @override
  String get resourceDetailYieldComparison => 'Tile yields';

  @override
  String get resourceDetailRequiresSection => 'Requires';

  @override
  String get resourceDetailBestMoveSection => 'Best move';

  @override
  String get resourceDetailNoMatchingImprovementBody =>
      'No matching improvement for this resource.';

  @override
  String get resourceDetailRequirementNoneCanBuild =>
      'Nothing. You can build immediately.';

  @override
  String get resourceDetailRequirementOutsideCity =>
      'The tile must be inside city borders.';

  @override
  String get resourceDetailRequirementAlreadyImproved =>
      'Nothing. The tile is already improved.';

  @override
  String get resourceDetailRequirementCityCenter =>
      'No worker build in the city center.';

  @override
  String get resourceDetailRequirementSelectWorkerOrCity =>
      'A worker or city selection.';

  @override
  String get resourceDetailRequirementNoLegalImprovement =>
      'No available build for this tile.';

  @override
  String resourceDetailBestMoveRequiresTechnology(
    String technology,
    String improvement,
  ) {
    return 'Unlock $technology first, then build $improvement.';
  }

  @override
  String resourceDetailBestMoveAvailable(String improvement) {
    return 'Send a worker and build $improvement.';
  }

  @override
  String get resourceDetailBestMoveOutsideCity =>
      'Expand city borders or found a city closer to the resource.';

  @override
  String get resourceDetailBestMoveAlreadyImproved =>
      'Keep the tile in borders and work it when it fits the city plan.';

  @override
  String get resourceDetailBestMoveCityCenter =>
      'Treat the resource as city-center value; workers do not improve this tile.';

  @override
  String get resourceDetailBestMoveSelectWorkerOrCity =>
      'Select a worker or city to check the legal build.';

  @override
  String get resourceDetailBestMoveNoLegalImprovement =>
      'Treat the resource as an expansion target; there is no separate build here.';

  @override
  String resourceValueUnlockedByTechnology(
    String technology,
    String improvement,
  ) {
    return 'Unlocked by $technology: $improvement.';
  }

  @override
  String resourceValueUnlocksFullYieldAfterTechnology(
    String technology,
    String improvement,
  ) {
    return 'After $technology: $improvement unlocks the full tile yield.';
  }

  @override
  String resourceValueResearchBoostLine(String technology, String discount) {
    return 'Research boost: controlling this resource accelerates $technology (-$discount cost).';
  }

  @override
  String resourceValueTechnologyControlledResourceBonus(
    String technology,
    int production,
  ) {
    return 'After $technology: +$production PROD for each controlled resource.';
  }

  @override
  String resourceValueNoBaseYieldSummary(String yield) {
    return 'The resource itself adds no base yield. The whole hex now has $yield; full value comes from improvements and unlocks.';
  }

  @override
  String resourceValueBaseYieldSummary(String resourceYield, String tileYield) {
    return 'The resource gives $resourceYield. The whole hex now has $tileYield before improvement.';
  }

  @override
  String get resourceValueExpansionStrategic =>
      'Claim it before a rival does: this is a strategic resource for production, armies, or later technologies.';

  @override
  String get resourceValueExpansionFood =>
      'A good expansion target for city growth: more food means faster population and more worked tiles.';

  @override
  String get resourceValueExpansionProduction =>
      'A good expansion target for production tempo: buildings, units, and map pressure arrive faster.';

  @override
  String get resourceValueExpansionTrade =>
      'A good expansion target for trade: after improvement it strongly supports gold and continued growth upkeep.';

  @override
  String get resourceValueExpansionEconomy =>
      'A good expansion target for the economy: gold helps maintain armies, build reserves, and close score goals.';

  @override
  String resourceValueYieldFood(int amount) {
    return '+$amount FOOD';
  }

  @override
  String resourceValueYieldProduction(int amount) {
    return '+$amount PROD';
  }

  @override
  String resourceValueYieldGold(int amount) {
    return '+$amount GOLD';
  }

  @override
  String resourceValueYieldDefense(int amount) {
    return '+$amount DEF';
  }

  @override
  String get resourceValueZeroBaseYield => '0 base yield';

  @override
  String get resourceValueCategoryBonus => 'Bonus';

  @override
  String get resourceValueCategoryLuxury => 'Luxury';

  @override
  String get resourceValueCategoryStrategic => 'Strategic';

  @override
  String get resourceValueCategoryBonusFuture =>
      'Value works mostly right away: faster growth and a better city start.';

  @override
  String get resourceValueCategoryLuxuryFuture =>
      'The largest value appears after border claim and the proper improvement.';

  @override
  String get resourceValueCategoryStrategicFuture =>
      'This is a strategic resource: secure it for later production and military pressure.';

  @override
  String get cityYieldBreakdownTitle => 'City economy';

  @override
  String cityYieldBreakdownSubtitle(String growth, String eta) {
    return 'Real yield/turn • growth $growth • $eta';
  }

  @override
  String get cityYieldBreakdownProductionSources => 'Production sources';

  @override
  String get cityYieldBreakdownScienceSources => 'Science sources';

  @override
  String get cityYieldBreakdownPerTurnSuffix => '/turn';

  @override
  String get cityYieldBreakdownNoProduction => 'No production';

  @override
  String get cityYieldBreakdownNoScience => 'No science';

  @override
  String get cityYieldBreakdownCenter => 'Center';

  @override
  String get cityYieldBreakdownPopulationFields => 'Population fields';

  @override
  String get cityYieldBreakdownWorkers => 'Workers';

  @override
  String get cityYieldBreakdownBuildings => 'Buildings';

  @override
  String get cityYieldBreakdownTechnologies => 'Technologies';

  @override
  String get cityYieldBreakdownSpecialization => 'Specialization';

  @override
  String get cityYieldBreakdownGoldMultiplier => 'Gold multiplier';

  @override
  String get cityYieldBreakdownUpkeep => 'Upkeep';

  @override
  String get cityYieldBreakdownFieldsBucket => 'Fields';

  @override
  String get cityYieldBreakdownCenterDetail =>
      'Fixed yield from the city center';

  @override
  String get cityYieldBreakdownGoldMultiplierDetail =>
      'Percentage bonus after summing gold sources';

  @override
  String get cityYieldBreakdownBaseScience => 'City base';

  @override
  String get cityYieldBreakdownBaseScienceDetail =>
      'Fixed science generated by each city';

  @override
  String get cityYieldBreakdownResearchProject => 'Research project';

  @override
  String get cityYieldBreakdownResearchProjectDetail =>
      'Current city production converted into science';

  @override
  String get cityYieldBreakdownScienceSpecializationDetail =>
      'City science profile';

  @override
  String get cityYieldBreakdownScienceTechnologyDetail =>
      'Science bonus from unlocked technologies';

  @override
  String get cityYieldBreakdownNoWorkedPopulationFields =>
      'No worked population fields';

  @override
  String get cityYieldBreakdownOneWorkedPopulationField =>
      '1 worked population field';

  @override
  String cityYieldBreakdownManyWorkedPopulationFields(int count) {
    return '$count worked population fields';
  }

  @override
  String get cityYieldBreakdownNoAssignedWorkers => 'No assigned workers';

  @override
  String get cityYieldBreakdownOneAssignedWorker =>
      '1 field activated by a worker';

  @override
  String cityYieldBreakdownManyAssignedWorkers(int count) {
    return '$count fields activated by workers';
  }

  @override
  String get cityYieldBreakdownNoPassiveImprovements =>
      'No passive improvements';

  @override
  String get cityYieldBreakdownOnePassiveImprovement =>
      '1 unworked improvement, half yield';

  @override
  String cityYieldBreakdownManyPassiveImprovements(int count) {
    return '$count unworked improvements, half yield';
  }

  @override
  String get cityYieldBreakdownNoBuildings => 'No buildings';

  @override
  String get cityYieldBreakdownBuildingsNoDirectYield =>
      'Buildings without direct yield';

  @override
  String get cityYieldBreakdownOneBuildingEconomicEffect =>
      '1 building with an economy effect';

  @override
  String cityYieldBreakdownManyBuildingEconomicEffects(int count) {
    return '$count buildings with economy effects';
  }

  @override
  String get cityYieldBreakdownNoTechnologyYield => 'No technology yield bonus';

  @override
  String get cityYieldBreakdownTechnologyYield =>
      'Bonuses from unlocked technologies';

  @override
  String get cityYieldBreakdownNoScienceBuildings => 'No science buildings';

  @override
  String get cityYieldBreakdownOneScienceBuilding => '1 science building';

  @override
  String cityYieldBreakdownManyScienceBuildings(int count) {
    return '$count science buildings with diminishing returns';
  }

  @override
  String cityYieldBreakdownGrowthFood(int storedFood, int growthCost) {
    return '$storedFood/$growthCost food';
  }

  @override
  String get cityYieldBreakdownStagnation => 'stagnation';

  @override
  String cityYieldBreakdownUpkeepBlocked(int population, int cost) {
    return 'Population $population: cost $cost, growth halted';
  }

  @override
  String cityYieldBreakdownUpkeepCost(int population) {
    return 'Food upkeep for population $population';
  }

  @override
  String get cityYieldBreakdownGrowthSpecializationDetail =>
      'City growth profile';

  @override
  String get cityYieldBreakdownIndustrySpecializationDetail =>
      'City industry profile';

  @override
  String get cityYieldBreakdownCommerceSpecializationDetail =>
      'City trade profile';

  @override
  String get cityYieldBreakdownScienceSpecializationCityDetail =>
      'City science profile';

  @override
  String get cityYieldBreakdownMilitarySpecializationDetail =>
      'City garrison profile';

  @override
  String get cityYieldBreakdownNoSpecialization => 'No specialization';

  @override
  String get cityProjectWealth => 'Wealth';

  @override
  String get cityProjectResearch => 'Research';

  @override
  String get cityProductionProjectsSection => 'City projects';

  @override
  String get cityProductionSpecializationSection => 'City specialization';

  @override
  String get cityProductionSortLabel => 'Sort';

  @override
  String cityProductionHeaderSubtitle(
    String title,
    String productionPerTurn,
    int gold,
  ) {
    return '$title • $productionPerTurn • $gold gold';
  }

  @override
  String get cityProductionBuiltLabel => 'Built';

  @override
  String get cityProductionAvailableLabel => 'Available';

  @override
  String get cityProductionAvailableUnitLabel => 'Available';

  @override
  String cityProductionUnitSupplyLimit(int used, int capacity) {
    return 'Food limit $used/$capacity';
  }

  @override
  String cityProductionUnitSupplyCost(int cost) {
    return 'food $cost';
  }

  @override
  String cityProductionUnitSupplyUsed(int used, int capacity) {
    return 'limit $used/$capacity';
  }

  @override
  String cityProductionNextWorkerUpkeep(int upkeep) {
    return 'next upkeep: $upkeep';
  }

  @override
  String cityProductionCostShort(int production) {
    return '$production prod.';
  }

  @override
  String cityProductionPaceShort(int production) {
    return '$production prod./turn';
  }

  @override
  String get cityBuildingSortRecommended => 'Recommended';

  @override
  String cityBuildingReplaceProgressWarning(String building) {
    return 'Choosing another building will replace $building. Progress will be preserved.';
  }

  @override
  String get cityBuildingSortFastestImpact => 'Fastest impact';

  @override
  String get cityBuildingSortBestReturn => 'Best return';

  @override
  String get cityBuildingSortGrowth => 'Growth';

  @override
  String get cityBuildingSortIndustry => 'Industry';

  @override
  String get cityBuildingSortScience => 'Science';

  @override
  String get cityBuildingSortDefenseMilitary => 'Defense / military';

  @override
  String get cityBuildingSortEconomy => 'Economy';

  @override
  String get cityBuildingRequiresTechnology => 'Requires technology';

  @override
  String get cityProductionContinuous => 'continuous';

  @override
  String get cityProductionNoProduction => 'no production';

  @override
  String get cityProductionReady => 'ready';

  @override
  String get cityProductionTurnOne => '1 turn';

  @override
  String cityProductionTurns(int turns) {
    return '$turns turns';
  }

  @override
  String cityProductionTreasuryGold(int gold) {
    return 'Treasury: $gold gold';
  }

  @override
  String cityProductionRushAction(int gold) {
    return 'Rush -$gold';
  }

  @override
  String cityProjectGoldPerTurn(int gold) {
    return '+$gold gold / turn';
  }

  @override
  String cityProjectSciencePerTurn(int science) {
    return '+$science science / turn';
  }

  @override
  String get citySpecializationGrowth => 'Growth';

  @override
  String get citySpecializationIndustry => 'Industry';

  @override
  String get citySpecializationCommerce => 'Commerce';

  @override
  String get citySpecializationMilitary => 'Garrison';

  @override
  String get citySpecializationGrowthBonus => '+2 food';

  @override
  String get citySpecializationIndustryBonus => '+2 production';

  @override
  String get citySpecializationCommerceBonus => '+3 gold';

  @override
  String get citySpecializationScienceBonus => '+2 science';

  @override
  String get citySpecializationMilitaryProductionBonus => '+1 production';

  @override
  String get citySpecializationMilitaryDefenseBonus => '+2 defense';

  @override
  String get citySpecializationMilitaryUnitProductionBonus => '+1 unit prod.';

  @override
  String get citySpecializationBestFit => 'Best fit';

  @override
  String get eventCityFoundedTitle => 'City founded';

  @override
  String get eventCityBuiltBuildingTitle => 'Construction complete';

  @override
  String get eventCityProducedUnitTitle => 'Unit trained';

  @override
  String get eventCityClaimedHexTitle => 'City borders';

  @override
  String eventCityClaimedHexBody(String cityName) {
    return '$cityName: new tile';
  }

  @override
  String get eventUnitMovedTitle => 'Unit movement';

  @override
  String get eventUnitPromotedTitle => 'Unit promoted';

  @override
  String get eventUnitExperienceTitle => 'Experience';

  @override
  String eventUnitExperienceBody(String unitName, int amount, String rank) {
    return '$unitName: +$amount XP ($rank)';
  }

  @override
  String get eventUnitAttackedTitle => 'Attack';

  @override
  String get eventCombatTitle => 'Combat';

  @override
  String eventCombatDamageLine(String unitName, int damage, String result) {
    return '$unitName: -$damage HP -> $result';
  }

  @override
  String eventCombatNoRetaliationLine(String unitName) {
    return '$unitName: no retaliation';
  }

  @override
  String eventCombatSimpleBody(
    String attackerCountry,
    String attackerName,
    String defenderCountry,
    String defenderName,
    int attackerHp,
    int defenderHp,
  ) {
    return '$attackerName ($attackerCountry) attacked $defenderName ($defenderCountry) - HP $attackerHp:$defenderHp';
  }

  @override
  String get eventDiplomaticProposalAcceptedStatus => 'Accepted';

  @override
  String get eventDiplomaticProposalRejectedStatus => 'Declined';

  @override
  String get eventDiplomaticProposalExpiredStatus => 'Expired';

  @override
  String get eventUnitKilledTitle => 'Unit defeated';

  @override
  String get eventUnitRetreatedTitle => 'Retreat';

  @override
  String get eventCityCapturedTitle => 'City captured';

  @override
  String get eventCityDestroyedTitle => 'City destroyed';

  @override
  String get eventTurnEndedTitle => 'Turn ended';

  @override
  String get eventWorkerCompletedJobTitle => 'Work complete';

  @override
  String get eventResearchPointsTitle => 'Science';

  @override
  String eventResearchPointsBody(String playerName, int points) {
    return '$playerName: +$points science';
  }

  @override
  String get eventTechnologyResearchedTitle => 'Technology discovered';

  @override
  String get eventStrategicResourceDiscoveredTitle =>
      'Strategic resource discovered';

  @override
  String eventStrategicResourceDiscoveredBody(
    String playerName,
    String resourceName,
  ) {
    return '$playerName: $resourceName';
  }

  @override
  String eventStrategicResourceControlledDetail(int count) {
    return 'Controlled: $count';
  }

  @override
  String eventStrategicResourceRivalDetail(int count) {
    return 'Rivals: $count';
  }

  @override
  String eventStrategicResourceUnclaimedDetail(int count) {
    return 'Unclaimed: $count';
  }

  @override
  String get eventStrategicResourcePressureSecured =>
      'Supply secured; defend the source.';

  @override
  String get eventStrategicResourcePressureExpansionRace =>
      'Settlement race: claim the nearest deposit before rivals.';

  @override
  String get eventStrategicResourcePressureContested =>
      'Contested supply: rivals also control sources.';

  @override
  String get eventStrategicResourcePressureRivalMonopoly =>
      'Rival monopoly: prepare trade or an expedition.';

  @override
  String eventStrategicResourceSettleHint(int col, int row) {
    return 'Deposit outside borders at $col:$row; consider founding a city.';
  }

  @override
  String get eventMapObjectiveSecuredTitle => 'Map objective secured';

  @override
  String eventMapObjectiveSecuredBody(String playerName, String objectiveName) {
    return '$playerName: $objectiveName';
  }

  @override
  String eventMapObjectiveHoldDetail(int holdTurns, int requiredHoldTurns) {
    return 'Held: $holdTurns/$requiredHoldTurns';
  }

  @override
  String eventMapObjectiveLocationDetail(int col, int row) {
    return 'Position: $col:$row';
  }

  @override
  String eventMapObjectiveVictoryRewardDetail(int points) {
    return '+$points victory points';
  }

  @override
  String eventMapObjectiveGoldRewardDetail(int gold) {
    return '+$gold gold/turn';
  }

  @override
  String get eventCivilizationMetTitle => 'New civilization';

  @override
  String eventCivilizationMetBody(String civilizationName, String playerName) {
    return '$civilizationName ($playerName)';
  }

  @override
  String get civilizationMetPopupEyebrow => 'Civilization encountered';

  @override
  String civilizationMetPopupBody(String civilizationName) {
    return 'The civilization of $civilizationName has appeared on the horizon. A new neighbor, rival, or future ally is now part of your world.';
  }

  @override
  String get civilizationMetPopupOk => 'OK';

  @override
  String get eventCommandRejectedTitle => 'Command rejected';

  @override
  String get eventAllPlayersSubmittedTitle => 'Everyone ready';

  @override
  String eventAllPlayersSubmittedBody(int turn, int players) {
    return 'Turn $turn ($players)';
  }

  @override
  String get eventPlayerTimedOutTitle => 'Auto-submit';

  @override
  String eventPlayerTimedOutBody(String playerName, int turn) {
    return '$playerName: timed out on turn $turn';
  }

  @override
  String get eventCombatDefenderKilledDetail => 'Defender defeated';

  @override
  String get eventCombatAttackerKilledDetail => 'Attacker defeated';

  @override
  String get eventCombatDefenderRetreatedDetail => 'Defender retreated';

  @override
  String eventCombatAttackDamageDetail(int damage) {
    return 'Attack: -$damage HP';
  }

  @override
  String eventCombatRetaliationDamageDetail(int damage) {
    return 'Retaliation: -$damage HP';
  }

  @override
  String eventCombatRollDetail(int value) {
    return 'Roll $value';
  }

  @override
  String get eventCombatNoRetaliationDetail => 'No retaliation';

  @override
  String get eventDominationStartedTitle => 'Domination started';

  @override
  String get eventDominationRivalAboveTitle => 'Rival above threshold';

  @override
  String eventDominationBody(
    String playerName,
    String control,
    String required,
  ) {
    return '$playerName: $control% / $required%';
  }

  @override
  String eventDominationHoldProgressDetail(int held, int required) {
    return 'Held $held/$required turns';
  }

  @override
  String get eventDominationReadyDetail => 'Condition ready';

  @override
  String eventDominationKeepHoldingDetail(String turns) {
    return 'Hold for $turns more';
  }

  @override
  String eventDominationInterruptDetail(String turns) {
    return 'Interrupt within $turns';
  }

  @override
  String eventTurnCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turns',
      one: '1 turn',
      zero: '0 turns',
    );
    return '$_temp0';
  }

  @override
  String get eventCombatDefeatedResult => 'defeated';

  @override
  String eventCombatDefenderRetreatedResult(int hp) {
    return '$hp HP, retreat';
  }

  @override
  String eventCombatHpResult(int hp) {
    return '$hp HP';
  }

  @override
  String eventCombatTerrainModifierLabel(Object terrain) {
    return 'Terrain $terrain';
  }

  @override
  String eventCombatTechModifierLabel(Object technology) {
    return 'Technology $technology';
  }

  @override
  String eventCombatRankModifierLabel(Object rank) {
    return 'Rank $rank';
  }

  @override
  String get eventCombatCityGarrisonModifier => 'City garrison';

  @override
  String get eventCombatMixedArmyModifier => 'Mixed army';

  @override
  String get eventCombatStatAttack => 'attack';

  @override
  String get eventCombatStatDefense => 'defense';

  @override
  String get eventCombatStatHp => 'HP';

  @override
  String get eventCombatStatRange => 'range';

  @override
  String get eventCombatStatMobility => 'movement';

  @override
  String get closeAction => 'Close';
}
