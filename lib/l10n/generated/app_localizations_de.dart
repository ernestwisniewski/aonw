// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Age of New Worlds';

  @override
  String defaultPlayerName(int index) {
    return 'Spieler $index';
  }

  @override
  String defaultCityName(int index) {
    return 'Stadt $index';
  }

  @override
  String get newGameTitle => 'NEUES SPIEL';

  @override
  String get gameModeSinglePlayerMenuLabel => 'Einzelspieler';

  @override
  String get gameModeMultiplayerMenuLabel => 'Mehrspieler';

  @override
  String get gameModeHotSeatMenuLabel => 'Hot Seat';

  @override
  String get gameModeSinglePlayerSummaryLabel => 'Einzelspieler';

  @override
  String get gameModeMultiplayerSummaryLabel => 'Mehrspieler';

  @override
  String get gameModeHotSeatSummaryLabel => 'Hot Seat';

  @override
  String get gameModeSinglePlayerMapTitle =>
      'Wähle eine Karte für das Solospiel';

  @override
  String get gameModeMultiplayerMapTitle =>
      'Wähle eine Karte für das Onlinespiel';

  @override
  String get gameModeHotSeatMapTitle => 'Wähle eine Karte für Hot-Seat-Spiel';

  @override
  String get gameModeSinglePlayerMapSubtitle =>
      'Ein lokales Spiel gegen die KI.';

  @override
  String get gameModeMultiplayerMapSubtitle =>
      'Start-Szenario und Weltkarte für ein Onlinespiel.';

  @override
  String get gameModeHotSeatMapSubtitle =>
      'Start-Szenario und Weltkarte für Hot-Seat-Spiel auf einem Gerät.';

  @override
  String get newGameIntroTitle => 'Bereite die Expedition vor';

  @override
  String get newGameIntroSubtitle =>
      'Wähle zuerst den Spielstil, dann die Karte, und passe anschließend Spieler und Spieltempo an.';

  @override
  String get newGameStepPlan => 'Spielplan';

  @override
  String get newGameStepMap => 'Karte';

  @override
  String get newGameStepReview => 'Überprüfung';

  @override
  String get newGamePlanTitle => 'Welche Geschichte möchtest du beginnen?';

  @override
  String get newGamePremiseTitle => 'Von der Siedlung zum Imperium';

  @override
  String get newGamePremiseBody =>
      'Jede Partie beginnt mit einigen entscheidenden Entscheidungen: wo die erste Stadt gegründet wird, wie die Forschung ausgerichtet wird, wann Expansion riskiert wird und wie die Kartenkontrolle gehalten wird.';

  @override
  String get newGameCountryTitle => 'Zivilisation wählen';

  @override
  String get newGameCountrySubtitle =>
      'Dein Herrschername richtet sich nach der gewählten Zivilisation.';

  @override
  String get newGameSinglePlayerSettingsTitle => 'Partieeinstellungen';

  @override
  String get newGameGameLengthLabel => 'Spieldauer';

  @override
  String get newGameLeaderLabel => 'HERRSCHER';

  @override
  String get newGamePillarCities => 'Städte';

  @override
  String get newGamePillarUnits => 'Einheiten';

  @override
  String get newGamePillarResearch => 'Forschung';

  @override
  String get newGameVictoryTypesTitle => 'Siegpfade';

  @override
  String get newGameVictoryDominationTitle => 'Dominanz';

  @override
  String newGameVictoryDominationBody(String controlPercent, int holdTurns) {
    return 'Kontrolliere $controlPercent% der Karte und halte sie $holdTurns Züge lang. Eroberung kann die Partie weiterhin beenden, indem Rivalen ausgeschaltet werden.';
  }

  @override
  String get newGameVictoryArtifactsTitle => 'Artefakte';

  @override
  String newGameVictoryArtifactsBody(int artifactCount, int holdTurns) {
    return 'Platziere $artifactCount einzigartige Weltartefakte in deinen Städten und halte die vollständige Sammlung $holdTurns Züge lang.';
  }

  @override
  String get newGameModeSinglePlayerDescription =>
      'Eine ruhige Partie gegen die KI. Ideal, um Systeme zu lernen, Starts zu testen und mit Wachstum zu experimentieren.';

  @override
  String get newGameModeMultiplayerDescription =>
      'Eine Onlinepartie mit Netzwerk-Lobby, Bereitschaft der Spieler und gemeinsamem Einstieg auf die Karte.';

  @override
  String get newGameModeMultiplayerAlphaDisabled =>
      'In der Alpha-Version nicht verfügbar.';

  @override
  String get newGameModeHotSeatDescription =>
      'Hot-Seat-Spiel auf einem Gerät. Die Spieler geben den Zug weiter, während der Bildschirm jede Übergabe erklärt.';

  @override
  String get newGameMapTitle => 'Welt wählen';

  @override
  String get newGameMapSubtitle =>
      'Die Karte bestimmt das Tempo des Erstkontakts, verfügbare Ressourcen, Stadtraum und die Form des Konflikts.';

  @override
  String get newGameReviewTitle => 'Expedition bestätigen';

  @override
  String get newGameReviewSubtitle =>
      'Nach der Bestätigung gelangst du in die Lobby, um Spielname, Spieldauer und Spieler festzulegen.';

  @override
  String newGameReviewSinglePlayerSubtitle(int aiCount) {
    return 'Der Einzelspieler startet sofort mit dir und $aiCount KI-Spielern.';
  }

  @override
  String get newGameReviewMissingMap =>
      'Wähle eine Karte, bevor du die Spieler konfigurierst.';

  @override
  String get newGameExpeditionReady => 'Expedition bereit';

  @override
  String get newGameSelectedMapLabel => 'Karte';

  @override
  String get newGameMapPickLabel => 'Kartenauswahl';

  @override
  String get newGameMapPickRandom => 'Zufälliger Standard';

  @override
  String get newGameMapPickManual => 'Manuell gewählt';

  @override
  String get newGameWorldSourceLabel => 'Quelle';

  @override
  String newGameSinglePlayerAiSummary(int aiCount) {
    return 'Du + $aiCount KI';
  }

  @override
  String get newGameChangeMapAction => 'Karte ändern';

  @override
  String get newGameStartSetupAction => 'Zur Lobby';

  @override
  String get mainMenuLoadGame => 'Spiel laden';

  @override
  String get mainMenuDeveloper => 'Werkzeuge';

  @override
  String get mainMenuSettings => 'Einstellungen';

  @override
  String get mainMenuSettingsSublabel => 'Text und Audio';

  @override
  String get mainMenuExit => 'Beenden';

  @override
  String get mainMenuAiSublabel => 'KI';

  @override
  String get mainMenuOnlineSublabel => 'Netzwerk';

  @override
  String get mainMenuLocalSublabel => 'Lokal';

  @override
  String get mainMenuToolsSublabel => 'Editoren';

  @override
  String get mainMenuToolsTitle => 'Werkzeuge';

  @override
  String get mainMenuMapEditor => 'Karteneditor';

  @override
  String get mainMenuAssetsEditor => 'Asset-Editor';

  @override
  String get mainMenuTextSize => 'Textgröße';

  @override
  String get mainMenuTextSample => 'Beispiel-Spieltext';

  @override
  String get mainMenuManual => 'Handbuch';

  @override
  String get mainMenuCredits => 'Credits';

  @override
  String get mainMenuFeedback => 'Feedback';

  @override
  String get manualTitle => 'Steuerungshandbuch';

  @override
  String get manualSubtitle =>
      'Eine kurze Übersicht zu Kartenbewegung, Auswahl, Befehlen, Bereichen und Zugablauf auf Desktop und Mobilgerät.';

  @override
  String get manualMetaDesktop => 'Desktop';

  @override
  String get manualMetaMobile => 'Mobil';

  @override
  String get manualMetaAlpha => 'Einzelspieler-Alpha';

  @override
  String get manualCommandLoopTitle => 'Zentraler Befehlsablauf';

  @override
  String get manualCommandLoopSelectTitle => 'Auswählen';

  @override
  String get manualCommandLoopSelectBody =>
      'Wähle eine Einheit, Stadt, ein Artefakt oder Kartenfeld aus, um die jetzt wichtigen Aktionen anzuzeigen.';

  @override
  String get manualCommandLoopPreviewTitle => 'Vorschau';

  @override
  String get manualCommandLoopPreviewBody =>
      'Fahre darüber oder tippe einmal, um Ziele, Absichtsfarben, Routen und blockierte Aktionen zu prüfen.';

  @override
  String get manualCommandLoopConfirmTitle => 'Bestätigen';

  @override
  String get manualCommandLoopConfirmBody =>
      'Nutze einen Aktionschip oder wähle das hervorgehobene Ziel erneut, um den Befehl auszuführen.';

  @override
  String get manualCommandLoopAdvanceTitle => 'Fortfahren';

  @override
  String get manualCommandLoopAdvanceBody =>
      'Nutze die untere Aktionstaste, um zur nächsten Entscheidung zu springen oder den Zug zu beenden.';

  @override
  String get manualDesktopTitle => 'Desktop-Steuerung';

  @override
  String get manualDesktopSubtitle =>
      'Mausorientiertes Spiel mit schneller Kartenprüfung, präziser Zielwahl und dauerhaften Bereichen.';

  @override
  String get manualMobileTitle => 'Mobilsteuerung';

  @override
  String get manualMobileSubtitle =>
      'Touchorientiertes Spiel, abgestimmt auf gut lesbare Bereiche, bewusste Befehle und schnellen Zugablauf.';

  @override
  String get manualMapCameraGroup => 'Karte & Kamera';

  @override
  String get manualOrdersGroup => 'Auswahl & Befehle';

  @override
  String get manualPanelsGroup => 'Bereiche & Hilfe';

  @override
  String get manualTurnFlowGroup => 'Zugablauf';

  @override
  String get manualDesktopLeftClickAction => 'Linksklick';

  @override
  String get manualDesktopLeftClickBody =>
      'Wähle Einheiten, Städte, Artefakte und Felder; bei aktivem Befehl wählst du das Ziel.';

  @override
  String get manualDesktopDragAction => 'Karte ziehen';

  @override
  String get manualDesktopDragBody =>
      'Verschiebe die Kamera, ohne die aktuelle Auswahl oder den Befehlsmodus zu ändern.';

  @override
  String get manualDesktopZoomAction => 'Mausrad / Trackpad';

  @override
  String get manualDesktopZoomBody =>
      'Zoome auf der Karte zwischen strategischer Übersicht und taktischen Details.';

  @override
  String get manualDesktopHoverAction => 'Darüberfahren';

  @override
  String get manualDesktopHoverBody =>
      'Zeige Tooltips, Zielhinweise und Gründe für blockierte Befehle an, bevor du bestätigst.';

  @override
  String get manualDesktopActionChipsAction => 'Aktionschips';

  @override
  String get manualDesktopActionChipsBody =>
      'Bewegen, angreifen, verbessern, eine Stadt gründen, überspringen, befestigen oder den aktuellen Modus abbrechen.';

  @override
  String get manualDesktopSecondClickAction => 'Dasselbe Ziel zweimal';

  @override
  String get manualDesktopSecondClickBody =>
      'Bei Bewegung zeigt der erste Klick die Route an; der zweite Klick führt sie aus oder reiht sie ein.';

  @override
  String get manualDesktopHoldAction => 'Klicken und halten';

  @override
  String get manualDesktopHoldBody =>
      'Öffne detaillierte Befehlserklärungen für Aktionen, deaktivierte Optionen und Kontextchips.';

  @override
  String get manualDesktopRailAction => 'Linke Leiste';

  @override
  String get manualDesktopRailBody =>
      'Öffne Kartenoptionen, Hilfe, Ziele, Aktivitätsprotokoll, Forschung und Imperiumsbereiche.';

  @override
  String get manualDesktopTopPillsAction => 'Obere Ressourcen';

  @override
  String get manualDesktopTopPillsBody =>
      'Prüfe Aufschlüsselungen zu Wirtschaft, Wissenschaft, Ressourcen und Siegdruck.';

  @override
  String get manualDesktopCloseAction => 'Außerhalb klicken';

  @override
  String get manualDesktopCloseBody =>
      'Schließe Pop-ups, Optionsbereiche und Hilfekarten und setze den Fokus zurück auf die Karte.';

  @override
  String get manualDesktopHelpAction => '?';

  @override
  String get manualDesktopHelpBody =>
      'Öffne jederzeit alle minimierten Hinweise und Tutorialkarten, unabhängig von der Auswahl.';

  @override
  String get manualDesktopTurnAction => 'Nächste Entscheidung';

  @override
  String get manualDesktopTurnBody =>
      'Fokussiere die nächste Einheit, Forschung oder Stadtentscheidung; beende den Zug, wenn nichts den Fortschritt blockiert.';

  @override
  String get manualMobileTapAction => 'Tippen';

  @override
  String get manualMobileTapBody =>
      'Wähle Einheiten, Städte, Artefakte und Felder; bei aktivem Befehl wählst du das Ziel.';

  @override
  String get manualMobileDragAction => 'Mit einem Finger ziehen';

  @override
  String get manualMobileDragBody =>
      'Verschiebe die Kamera, während die ausgewählte Einheit oder der Bereichszustand erhalten bleibt.';

  @override
  String get manualMobilePinchAction => 'Zusammenziehen';

  @override
  String get manualMobilePinchBody =>
      'Zoome die Karte für Erkundung, Stadtarbeit, Bewegungsplanung oder Zielwahl im Kampf.';

  @override
  String get manualMobileSecondTapAction => 'Dasselbe Ziel zweimal';

  @override
  String get manualMobileSecondTapBody =>
      'Zeige zuerst eine Bewegungsroute an und tippe dann erneut auf dasselbe Hex-Feld, um sie auszuführen oder einzureihen.';

  @override
  String get manualMobileActionChipsAction => 'Aktionschips';

  @override
  String get manualMobileActionChipsBody =>
      'Nutze die untere Befehlsreihe für Einheitsbefehle, Stadtentscheidungen, Arbeiter und Abbrechen-Aktionen.';

  @override
  String get manualMobileHoldAction => 'Drücken und halten';

  @override
  String get manualMobileHoldBody =>
      'Öffne Erklärungen zu Befehlen, deaktivierten Optionen, Ressourcen und kontextbezogener Oberfläche.';

  @override
  String get manualMobileScrollAction => 'Bereiche scrollen';

  @override
  String get manualMobileScrollBody =>
      'Durchsuche lange Stadt-, Forschungs-, Protokoll-, Diplomatie- und Hilfelisten, ohne den Kartenzustand zu verlieren.';

  @override
  String get manualMobileRailAction => 'Linke Leiste';

  @override
  String get manualMobileRailBody =>
      'Tippe, um Kartenoptionen, Hilfe, Ziele, Aktivitätsprotokoll, Forschung und Imperiumsbereiche zu öffnen.';

  @override
  String get manualMobileHelpAction => '?';

  @override
  String get manualMobileHelpBody =>
      'Sieh dir alle minimierten Hinweise und Tutorialkarten erneut an, wenn du eine Auffrischung brauchst.';

  @override
  String get manualMobileTurnAction => 'Untere Aktion';

  @override
  String get manualMobileTurnBody =>
      'Springe zur nächsten erforderlichen Entscheidung oder beende den Zug, sobald alle Aktionspunkte ausgegeben sind.';

  @override
  String get mainMenuWhatsNew => 'Was ist neu?';

  @override
  String get mainMenuWhatsNewBody =>
      'Willkommen bei Age of New Worlds. Baue Städte, führe Kommandanten, entdecke neue Länder und schreibe die Geschichte deiner Zivilisation.';

  @override
  String get mainMenuUpdateSoonTitle => 'Update unterwegs';

  @override
  String get mainMenuUpdateSoonBody =>
      'Eine neuere Version ist bereit und erscheint bald auf dieser Plattform. Prüfe deinen Store oder Launcher in Kürze erneut.';

  @override
  String get gameModeLabel => 'MODUS';

  @override
  String get gameNameLabel => 'SPIELNAME';

  @override
  String get playersLabel => 'SPIELER';

  @override
  String get countryLabel => 'LAND';

  @override
  String get countryPoland => 'Polen';

  @override
  String get countryUkraine => 'Ukraine';

  @override
  String get countryGermany => 'Deutschland';

  @override
  String get countryFrance => 'Frankreich';

  @override
  String get countryUnitedKingdom => 'Vereinigtes Königreich';

  @override
  String get countryItaly => 'Italien';

  @override
  String get countrySpain => 'Spanien';

  @override
  String get countryNetherlands => 'Niederlande';

  @override
  String get countrySweden => 'Schweden';

  @override
  String get countryRussia => 'Russland';

  @override
  String get countryUnitedStates => 'Vereinigte Staaten';

  @override
  String get countryCanada => 'Kanada';

  @override
  String get countryChina => 'China';

  @override
  String get countryKorea => 'Korea';

  @override
  String get countryJapan => 'Japan';

  @override
  String get countryPortugal => 'Portugal';

  @override
  String get countryLeaderPoland => 'Kasimir III. der Große';

  @override
  String get countryLeaderUkraine => 'Jaroslaw der Weise';

  @override
  String get countryLeaderGermany => 'Otto von Bismarck';

  @override
  String get countryLeaderFrance => 'Napoleon Bonaparte';

  @override
  String get countryLeaderUnitedKingdom => 'Königin Victoria';

  @override
  String get countryLeaderItaly => 'Julius Cäsar';

  @override
  String get countryLeaderSpain => 'Isabella I.';

  @override
  String get countryLeaderNetherlands => 'Wilhelm von Oranien';

  @override
  String get countryLeaderSweden => 'Gustav II. Adolf';

  @override
  String get countryLeaderRussia => 'Katharina die Große';

  @override
  String get countryLeaderUnitedStates => 'Abraham Lincoln';

  @override
  String get countryLeaderCanada => 'Wilfrid Laurier';

  @override
  String get countryLeaderChina => 'Qin Shi Huang';

  @override
  String get countryLeaderKorea => 'Sejong der Große';

  @override
  String get countryLeaderJapan => 'Tokugawa Ieyasu';

  @override
  String get countryLeaderPortugal => 'Heinrich der Seefahrer';

  @override
  String get addPlayerAction => '+ SPIELER HINZUFÜGEN';

  @override
  String get startGameAction => 'START';

  @override
  String get removePlayerTooltip => 'Spieler entfernen';

  @override
  String get multiplayerSearchTitle => 'SERVERSUCHE';

  @override
  String get multiplayerSearchBody =>
      'Die Liste der Onlinepartien wird hier angezeigt.';

  @override
  String get multiplayerPlayersTitle => 'Spieler';

  @override
  String get multiplayerStatusTooltip => 'Spielerstatus';

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
    return '$playerName - $status\nBeziehungen: $relation';
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
    return '$playerName\n$defaultName\nBeziehungen: $relation';
  }

  @override
  String get multiplayerStatusActive => 'spielt gerade';

  @override
  String get multiplayerStatusSubmitted => 'Zug gesendet';

  @override
  String get multiplayerStatusThinking => 'überlegt';

  @override
  String get multiplayerStatusWaiting => 'wartet';

  @override
  String get multiplayerStatusTimeout => 'Zeitüberschreitung';

  @override
  String get diplomacyRelationFriendly => 'freundlich';

  @override
  String get diplomacyRelationNeutral => 'neutral';

  @override
  String get diplomacyRelationHostile => 'feindselig';

  @override
  String get diplomacyRelationTruce => 'Waffenruhe';

  @override
  String get diplomacyRelationWar => 'Krieg';

  @override
  String get diplomacyRelationFriendlyShort => 'frdl.';

  @override
  String get diplomacyRelationNeutralShort => 'neutr.';

  @override
  String get diplomacyRelationHostileShort => 'feindl.';

  @override
  String get diplomacyRelationTruceShort => 'Waffenr.';

  @override
  String get diplomacyRelationWarShort => 'Krieg';

  @override
  String get commonDiplomacy => 'Diplomatie';

  @override
  String get diplomacyScoreLabel => 'Beziehungen';

  @override
  String get diplomacyTreatyLabel => 'Vertrag';

  @override
  String get diplomacyAttitudeLabel => 'Haltung';

  @override
  String get diplomacyTreatyBenefitsLabel => 'Vertragsvorteile';

  @override
  String get diplomacyFriendlyBenefits =>
      '+1 Gold aus Ressourcenhandel · Durchmarschrecht';

  @override
  String get diplomacyNoTreatyBenefits => 'Keine Vertragsvorteile';

  @override
  String get diplomacyScoreDriversTitle => 'Was Beziehungen verändert';

  @override
  String get diplomacyScoreReasonManual => 'Manuelle Änderung';

  @override
  String get diplomacyScoreReasonUnitAttack => 'Angriff auf Einheit';

  @override
  String get diplomacyScoreReasonCityAttack => 'Angriff auf Stadt';

  @override
  String get diplomacyScoreReasonDeclarationOfWar => 'Kriegserklärung';

  @override
  String get diplomacyScoreReasonWarmongerPenalty => 'Aggressor-Malus';

  @override
  String get diplomacyScoreReasonProposalAccepted => 'Vorschlag angenommen';

  @override
  String get diplomacyScoreReasonProposalRejected => 'Vorschlag abgelehnt';

  @override
  String get diplomacyScoreReasonMessageResponse => 'Antwort auf Depesche';

  @override
  String get diplomacyScoreReasonCommonEnemyCooperation =>
      'Zusammenarbeit gegen gemeinsamen Feind';

  @override
  String get diplomacyScoreReasonGoldGift => 'Goldgeschenk';

  @override
  String get diplomacyScoreReasonPromiseBroken => 'Versprechen gebrochen';

  @override
  String get diplomacyStatsTitle => 'Statistiken';

  @override
  String get diplomacyHistoryTitle => 'Verlauf';

  @override
  String get diplomacyMessagesTitle => 'Depeschen';

  @override
  String get diplomacyIncomingMessageTitle => 'Neue Depesche';

  @override
  String diplomacyIncomingMessageFrom(String playerName) {
    return 'Von: $playerName';
  }

  @override
  String get diplomacyIncomingProposalTitle => 'Neuer Vorschlag';

  @override
  String diplomacyIncomingProposalFrom(String playerName) {
    return 'Von: $playerName';
  }

  @override
  String get diplomacyIncomingMessageLater => 'Später';

  @override
  String get diplomacyActionsTitle => 'Aktionen';

  @override
  String get diplomacyProposalsTitle => 'Vorschläge';

  @override
  String get diplomacyNoHistory => 'Keine Vorfälle aufgezeichnet.';

  @override
  String get diplomacyNoMessages => 'Keine Depeschen.';

  @override
  String get diplomacyMilitaryStat => 'Militär';

  @override
  String get diplomacyCitiesStat => 'Städte';

  @override
  String get diplomacyExpansionStat => 'Expansion';

  @override
  String get diplomacyArtifactsStat => 'Artefakte';

  @override
  String get diplomacyLastAggressionStat => 'Letzte Aggression';

  @override
  String get diplomacyOwnArtifactsLabel => 'Deine Artefakte';

  @override
  String get diplomacyTargetArtifactsLabel => 'Artefakte des Rivalen';

  @override
  String diplomacyTurnsRemaining(int turns) {
    return 'Verbleibende Züge: $turns';
  }

  @override
  String get diplomacyProposalFriendship => 'Freundschaftsvorschlag';

  @override
  String get diplomacyProposalTruce => 'Waffenstillstandsvorschlag';

  @override
  String diplomacyProposalForecastLine(
    String proposal,
    String outcome,
    String reasons,
  ) {
    return '$proposal: $outcome · $reasons';
  }

  @override
  String get diplomacyProposalForecastAccepted => 'wahrscheinlich akzeptiert';

  @override
  String get diplomacyProposalForecastRejected => 'wahrscheinlich abgelehnt';

  @override
  String get diplomacyProposalForecastReasonAcceptableRelations =>
      'Beziehungen reichen aus';

  @override
  String get diplomacyProposalForecastReasonActiveWar => 'aktiver Krieg';

  @override
  String get diplomacyProposalForecastReasonAtWar =>
      'Freundschaft durch Krieg blockiert';

  @override
  String get diplomacyProposalForecastReasonGoldPayment => 'Friedenszahlung';

  @override
  String get diplomacyProposalForecastReasonLowRelations =>
      'Beziehungen zu niedrig';

  @override
  String get diplomacyProposalForecastReasonMilitaryPressure =>
      'militärischer Druck';

  @override
  String get diplomacyProposalForecastReasonRecentHostility =>
      'jüngste Feindseligkeit';

  @override
  String diplomacyTruceGoldPayment(int gold) {
    return 'Friedensbedingungen: $gold Gold';
  }

  @override
  String diplomacyGoldGiftAmount(int gold) {
    return 'Goldgeschenk: $gold Gold';
  }

  @override
  String get diplomacySendFriendship => 'Freundschaft vorschlagen';

  @override
  String get diplomacySendTruce => 'Waffenruhe vorschlagen';

  @override
  String get diplomacySendGoldGift => 'Goldgeschenk senden';

  @override
  String get diplomacyDeclareWar => 'Krieg erklären';

  @override
  String get diplomacyAccept => 'Annehmen';

  @override
  String get diplomacyDecline => 'Ablehnen';

  @override
  String get diplomacyMessageTroopsNearCities =>
      'Zu viele Truppen stehen nahe bei meinen Städten.';

  @override
  String get diplomacyMessageCitiesTooClose =>
      'Du gründest Städte zu nahe an meinen Grenzen.';

  @override
  String get diplomacyMessageBlockedRoutes =>
      'Deine Einheiten blockieren meine Routen.';

  @override
  String get diplomacyMessageWithdrawScouts =>
      'Bitte ziehe deine Späher aus meinem Gebiet zurück.';

  @override
  String get diplomacyMessageAvoidEscalation =>
      'Unsere Zivilisationen sollten eine weitere Eskalation vermeiden.';

  @override
  String get diplomacyMessageCommonEnemy =>
      'Ein gemeinsamer Feind bedroht uns beide.';

  @override
  String get diplomacyMessageExpansionProvocation =>
      'Deine Expansion wird als Provokation gesehen.';

  @override
  String get diplomacyMessagePeacefulPraise =>
      'Wir schätzen die friedlichen Beziehungen zwischen unseren Völkern.';

  @override
  String get diplomacyResponseConciliatory => 'Versöhnlich';

  @override
  String get diplomacyResponseNeutral => 'Neutral';

  @override
  String get diplomacyResponseEvasive => 'Ausweichend';

  @override
  String get diplomacyResponseAggressive => 'Aggressiv';

  @override
  String get diplomacyStrategicResourcesTitle => 'Strategische Ressourcen';

  @override
  String get diplomacyResourceTradeBlockedByWar =>
      'Ressourcenhandel ist durch Krieg blockiert.';

  @override
  String get diplomacyResourceTradeNoAvailableResources =>
      'Keine freien strategischen Ressourcen für den Handel verfügbar.';

  @override
  String diplomacyResourceTradeImportOffer(int goldPerTurn, int durationTurns) {
    return 'Importangebot: $goldPerTurn Gold/Zug für $durationTurns Züge.';
  }

  @override
  String diplomacyResourceTradeImportAction(String resourceName) {
    return '$resourceName importieren';
  }

  @override
  String diplomacyResourceTradeExchangeOffer(int durationTurns) {
    return 'Tauschhandel: Ressource gegen Ressource für $durationTurns Züge.';
  }

  @override
  String diplomacyResourceTradeExchangeAction(
    String offeredResource,
    String requestedResource,
  ) {
    return '$offeredResource gegen $requestedResource tauschen';
  }

  @override
  String get diplomacyResourceTradeNoActiveAgreements =>
      'Keine aktiven Ressourcenabkommen.';

  @override
  String get diplomacyResourceTradeImportDirection => 'Importiert';

  @override
  String get diplomacyResourceTradeExportDirection => 'Exportiert';

  @override
  String get diplomacyResourceTradeBarterPrice => 'Tausch';

  @override
  String diplomacyResourceTradeGoldPerTurnPrice(int goldPerTurn) {
    return '$goldPerTurn Gold/Zug';
  }

  @override
  String diplomacyResourceTradeAgreementLabel(
    String direction,
    String resourceName,
    String price,
    int remainingTurns,
  ) {
    return '$direction $resourceName · $price · $remainingTurns Züge';
  }

  @override
  String get notFoundScreenTitle => 'Bildschirm nicht gefunden';

  @override
  String get notFoundBackToMenuAction => 'MENÜ';

  @override
  String get loadGameTitle => 'SPIEL LADEN';

  @override
  String get loadGameHeaderTitle => 'Gespeicherte Spiele';

  @override
  String get loadGameHeaderEmptySubtitle =>
      'Es wurde noch kein Spiel gestartet.';

  @override
  String get loadGameHeaderSavesSubtitle =>
      'Kehre zu aktuellen Partien zurück und setze beim gespeicherten Zug fort.';

  @override
  String loadGameSavesCount(int count) {
    return 'Spielstände: $count';
  }

  @override
  String get loadGameCorruptedStatus => 'Beschädigter Spielstand';

  @override
  String get loadGameCorruptedAction => 'Nicht verfügbar';

  @override
  String get loadGameCorruptedBody =>
      'Dieser Spielstand kann nicht gelesen werden. Du kannst ihn aus der Liste entfernen.';

  @override
  String get replayTitle => 'WIEDERHOLUNG';

  @override
  String get replayAction => 'WIEDERHOLUNG';

  @override
  String get replayUnavailableAction => 'KEINE WIEDERHOLUNG';

  @override
  String get replayErrorTitle => 'Wiederholung nicht verfügbar';

  @override
  String replayErrorBody(String error) {
    return 'Wiederholung kann nicht geöffnet werden: $error';
  }

  @override
  String get replayMissingInitialSnapshotBody =>
      'Dieser Spielstand enthält keinen Start-Snapshot für die Wiederholung. Starte ein neues Spiel, um Wiederholungsdaten für die ganze Partie aufzuzeichnen.';

  @override
  String get replayCorruptLogBody =>
      'Das Befehlsprotokoll der Wiederholung ist unvollständig oder kann nicht gelesen werden.';

  @override
  String replayStepCounter(int step, int total) {
    return 'Schritt $step/$total';
  }

  @override
  String endTurnButtonTurnLabel(int turn) {
    return 'ZUG $turn';
  }

  @override
  String replayTurnLabel(int turn) {
    return 'Zug $turn';
  }

  @override
  String replayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ereignisse',
      one: '1 Ereignis',
      zero: '0 Ereignisse',
    );
    return '$_temp0';
  }

  @override
  String get replayInitialStateLabel => 'Ausgangszustand';

  @override
  String get replayPreviousAction => 'Vorheriger Schritt';

  @override
  String get replayNextAction => 'Nächster Schritt';

  @override
  String get replayPlayAction => 'Wiederholung abspielen';

  @override
  String get replayPauseAction => 'Wiederholung pausieren';

  @override
  String get replaySpeedLabel => 'Geschwindigkeit';

  @override
  String get replayPerspectiveLabel => 'Perspektive';

  @override
  String get replayAllPlayers => 'Alle Spieler';

  @override
  String get replayShowTurnsLabel => 'Züge anzeigen';

  @override
  String get replayFreeCameraLabel => 'Freie Kamera';

  @override
  String mapsLoadError(String error) {
    return 'Karten konnten nicht geladen werden: $error';
  }

  @override
  String get editorMapPickerTitle => 'Editorkarten';

  @override
  String get editorMapPickerSubtitle =>
      'Erstelle neue Welten oder verfeinere bestehende Karten.';

  @override
  String get editorMapPickerEmptyTitle => 'Keine gespeicherten Karten';

  @override
  String get editorMapPickerEmptyMessage =>
      'Erstelle eine neue Karte über die Kopfzeile des Bildschirms.';

  @override
  String get editorNewMapAction => 'Neue Karte';

  @override
  String get editorDeleteMapTooltip => 'Karte löschen';

  @override
  String get editorDeleteMapTitle => 'Karte löschen?';

  @override
  String editorDeleteMapMessage(String name) {
    return 'Dadurch werden „$name“ und alle Kartendateien dauerhaft gelöscht.';
  }

  @override
  String get editorOpenMapErrorTitle => 'Karte konnte nicht geöffnet werden';

  @override
  String get editorCollapseToolbarTooltip => 'Editorbereich einklappen';

  @override
  String get editorExpandToolbarTooltip => 'Editorbereich ausklappen';

  @override
  String officialMapsCount(int count) {
    return 'Offiziell: $count';
  }

  @override
  String yourMapsCount(int count) {
    return 'Deine: $count';
  }

  @override
  String get officialMapsSection => 'Offiziell';

  @override
  String get yourMapsSection => 'Deine Karten';

  @override
  String get playAction => 'Spielen';

  @override
  String get editAction => 'Bearbeiten';

  @override
  String get noMapsTitle => 'Keine Karten';

  @override
  String get noMapsMessage =>
      'Es wurden keine Karten gefunden, um ein Spiel zu starten.';

  @override
  String get gameLengthLabel => 'Spieldauer';

  @override
  String get gameLengthPresetHint => 'Spielvoreinstellung';

  @override
  String get gameLengthPresetUnlimited => 'Unbegrenzt';

  @override
  String get gameLengthPresetShort60 => 'Kurz';

  @override
  String get gameLengthPresetNormal90 => 'Normal';

  @override
  String get gameLengthPresetStandard60 => 'Standard 60 Min.';

  @override
  String get gameLengthPresetLong120 => 'Lang';

  @override
  String get gameLengthPresetVeryLong => 'Sehr lang';

  @override
  String get gameLengthUnlimitedSummary =>
      'Kein Zuglimit - aktuelles Spieltempo';

  @override
  String gameLengthTimedSummary(int minutes, int turns) {
    return 'Ziel $minutes Min. - Limit $turns Züge';
  }

  @override
  String get gameLengthScoreFallbackOn => 'mit Punkte-Ausweichwertung';

  @override
  String get gameLengthScoreFallbackOff => 'ohne Punkte-Ausweichwertung';

  @override
  String get aiDifficultyLabel => 'KI-Schwierigkeit';

  @override
  String get aiDifficultyEasy => 'Einfach';

  @override
  String get aiDifficultyNormal => 'Normal';

  @override
  String get aiDifficultyHard => 'Schwer';

  @override
  String get aiDifficultyVeryHard => 'Sehr schwer';

  @override
  String gameLengthVictoryRules(
    String controlPercent,
    int holdTurns,
    String fallback,
  ) {
    return 'Eroberung + Dominanz $controlPercent%/$holdTurns Züge - $fallback';
  }

  @override
  String get mapValidationErrorTitle => 'Karte braucht Korrekturen';

  @override
  String get mapValidationLoadingTitle => 'Karte wird geprüft';

  @override
  String get mapValidationWarningTitle =>
      'Karte könnte für diese Voreinstellung zu langsam sein';

  @override
  String mapValidationLoadError(String error) {
    return 'Karte konnte nicht geprüft werden: $error';
  }

  @override
  String get mapValidationLoadingMessage =>
      'Starts, Ressourcen und Tempo des Erstkontakts werden validiert.';

  @override
  String get mapValidationIssueSlowFirstContact =>
      'Startpositionen liegen weit auseinander; 60 Min. könnten den Erstkontakt zu stark verzögern.';

  @override
  String get mapValidationIssueLargeMap =>
      'Die Karte hat viele Felder pro Spieler; füge Spieler hinzu oder wähle ein längeres Spiel.';

  @override
  String get mapValidationIssueInvalidPlayerCount =>
      'Die Spielerzahl passt nicht zum von dieser Karte unterstützten Bereich.';

  @override
  String get mapValidationIssueNoTiles => 'Die Karte hat keine Felder.';

  @override
  String get mapValidationIssueLowPassableTileRatio =>
      'Die Karte hat zu wenige Felder, die von Landeinheiten passiert werden können.';

  @override
  String get mapValidationIssueLowFoodResourceDensity =>
      'Die Karte hat für diese Spielerzahl zu wenige Nahrungsressourcen.';

  @override
  String get mapValidationIssueLowStrategicResourceDensity =>
      'Die Karte hat zu wenige strategische Ressourcen.';

  @override
  String get mapValidationIssueLowLuxuryResourceDensity =>
      'Die Karte hat zu wenige Luxusressourcen.';

  @override
  String get mapValidationIssueStartSiteNotFoundable =>
      'Der Start-Siedler kann auf seinem Feld keine Stadt gründen.';

  @override
  String get mapValidationIssueStartSiteLowLandRing =>
      'Der Start hat zu wenige passierbare Felder im ersten Ring.';

  @override
  String get mapValidationIssueStartSiteLowFood =>
      'In der Nähe des Starts ist keine sichtbare Nahrungsressource.';

  @override
  String get mapValidationIssueStartSiteLowCityControl =>
      'Der Start hat zu wenige gültige Felder für die anfängliche Stadtkontrolle.';

  @override
  String get mapValidationIssueStartSitesTooClose =>
      'Die Spielerstarts liegen zu nah beieinander.';

  @override
  String lobbyMapPlayersSummary(String mapName, int playerCount) {
    return '$mapName - $playerCount Spieler';
  }

  @override
  String get lobbyHeaderTitle => 'Bereite den Tisch vor';

  @override
  String get lobbyHeaderSubtitle =>
      'Bestätige zuerst die Zivilisation und passe dann Partie und Plätze vor dem ersten Zug an.';

  @override
  String get lobbyCivilizationTitle => 'Zivilisation wählen';

  @override
  String get lobbyCivilizationSubtitle =>
      'Dies ist die Identität von Spieler eins für den Eröffnungszug.';

  @override
  String get lobbyStepCivilization => 'Zivilisation';

  @override
  String get lobbyStepSetup => 'Einrichtung';

  @override
  String get lobbyStepOnline => 'Online';

  @override
  String get lobbyStepPlayers => 'Spieler';

  @override
  String get lobbySetupTitle => 'Partie einrichten';

  @override
  String get lobbySetupSubtitle =>
      'Benenne das Spiel, wähle das Tempo und prüfe, ob die Karte zur ausgewählten Spielerzahl passt.';

  @override
  String get lobbyPlayersSetupTitle => 'Spieler am Tisch';

  @override
  String get lobbyPlayersSetupSubtitle =>
      'Der erste Spieler übernimmt den Eröffnungszug. Zusätzliche Plätze können Personen auf diesem Gerät oder KI sein.';

  @override
  String get lobbyPlayerYou => 'Du';

  @override
  String get lobbyPlayerHost => 'Host';

  @override
  String get lobbyPlayerReady => 'bereit';

  @override
  String get lobbyPlayerConnected => 'verbunden';

  @override
  String get lobbyPlayerConnecting => 'verbindet';

  @override
  String get lobbyPlayerReconnecting => 'verbindet erneut';

  @override
  String get lobbyPlayerOffline => 'offline';

  @override
  String lobbyPlayerOpenSlot(int slotNumber) {
    return 'Offener Platz $slotNumber';
  }

  @override
  String get lobbyPlayerRequiredSlot => 'Zum Start erforderlich';

  @override
  String get lobbyPlayerOptionalSlot => 'Kann vor dem Start beitreten';

  @override
  String get playerKindHuman => 'Mensch';

  @override
  String get playerKindAi => 'KI';

  @override
  String get multiplayerServerTitle => 'Online-Spielserver';

  @override
  String get connectAction => 'Verbinden';

  @override
  String get refreshAction => 'Aktualisieren';

  @override
  String get createMatchAction => 'Partie erstellen';

  @override
  String get noOpenMatches => 'Keine offenen Partien';

  @override
  String get matchStatusRunning => 'Bereit';

  @override
  String get matchStatusFinished => 'Beendet';

  @override
  String get matchStatusAbandoned => 'Aufgegeben';

  @override
  String matchPlayersCount(int players, int maxPlayers) {
    return '$players/$maxPlayers Spieler';
  }

  @override
  String matchReadyCount(int readyPlayers, int players) {
    return '$readyPlayers/$players bereit';
  }

  @override
  String matchTurnInfo(String mapName, String status, int turn) {
    return '$mapName - $status - Zug $turn';
  }

  @override
  String openMatchInfo(String mapName, int players, int maxPlayers, int turn) {
    return '$mapName - $players/$maxPlayers - Zug $turn';
  }

  @override
  String get enterMatchAction => 'Betreten';

  @override
  String get hideMatchAction => 'Ausblenden';

  @override
  String get joinMatchAction => 'Beitreten';

  @override
  String get cancelAction => 'ABBRECHEN';

  @override
  String get copyAction => 'Kopieren';

  @override
  String get shareAction => 'Teilen';

  @override
  String get multiplayerHomeSubtitle =>
      'Wähle eine schnelle Warteschlange oder eine private Code-Partie für Freunde.';

  @override
  String get multiplayerProfileTitle => 'Dein Profil';

  @override
  String get multiplayerProfileSubtitle =>
      'Lege den Namen und die Zivilisation fest, die du in Onlinepartien verwendest.';

  @override
  String get multiplayerProfileOptionsSubtitle =>
      'Dein Spitzname wird in Mehrspielerpartien verwendet und muss eindeutig sein.';

  @override
  String get multiplayerProfileSaveAction => 'Spitzname speichern';

  @override
  String get multiplayerProfileSaved => 'Spitzname gespeichert.';

  @override
  String get multiplayerLobbyHeaderTitle => 'Online-Lobby';

  @override
  String get multiplayerLobbyHeaderSubtitle =>
      'Wähle zuerst die Zivilisation und tritt dann dem Schnellspiel bei oder erstelle einen privaten Tisch. Die Karte wird automatisch ausgewählt.';

  @override
  String get multiplayerCountryPickTitle => 'Zivilisation wählen';

  @override
  String get multiplayerCountryPickSubtitle =>
      'Dies ist die zentrale Wahl vor dem Betreten der Warteschlange. Mehrspielerkarten werden zufällig ausgewählt.';

  @override
  String get multiplayerRandomMapLabel => 'Zufällige Karte';

  @override
  String get multiplayerNicknameLabel => 'Spitzname';

  @override
  String get multiplayerQuickplayTitle => 'Schnelles Spiel';

  @override
  String get multiplayerQuickplaySubtitle =>
      'Findet Spieler automatisch und startet ab 2 Spielern.';

  @override
  String get multiplayerCreatePrivateTitle => 'Code erstellen';

  @override
  String get multiplayerCreatePrivateSubtitle =>
      'Private Partie ohne Zeitlimit, nur für Freunde.';

  @override
  String get multiplayerJoinPrivateTitle => 'Mit Code beitreten';

  @override
  String get multiplayerJoinPrivateSubtitle =>
      'Gib den Code eines Freundes ein und warte auf den Host.';

  @override
  String get multiplayerQueueReadyTitle => 'Partie bereit';

  @override
  String get multiplayerQueueSearchingTitle => 'Suche nach Spielern';

  @override
  String get multiplayerQueueCountdownTitle => 'Startet bald';

  @override
  String get multiplayerQueueConnectingSubtitle =>
      'Verbindung zum Server wird hergestellt und nach einer Warteschlange gesucht.';

  @override
  String multiplayerQueueWaitingForPlayers(int minPlayers) {
    return 'Warte auf mindestens $minPlayers Spieler.';
  }

  @override
  String get multiplayerQueuePreparingStart =>
      'Spieler gefunden. Partiestart wird vorbereitet.';

  @override
  String get multiplayerQueueStartingNow => 'Partie startet...';

  @override
  String multiplayerQueueStartingIn(int seconds) {
    return 'Start in ${seconds}s. Weitere Spieler können noch beitreten.';
  }

  @override
  String get multiplayerPrivateTitle => 'Freundespartie';

  @override
  String get multiplayerPrivateHostReady =>
      'Du kannst die Partie jetzt starten.';

  @override
  String get multiplayerPrivateWaitingForHost =>
      'Warte darauf, dass der Host die Partie startet.';

  @override
  String get multiplayerJoinCodeHelp =>
      'Gib den Code ein, den du von einem Freund erhalten hast.';

  @override
  String get multiplayerInviteCodeHint => 'Partiecode';

  @override
  String get multiplayerInviteCodeLabel => 'Partiecode';

  @override
  String get multiplayerInviteCopied => 'Partiecode kopiert.';

  @override
  String multiplayerInviteShareText(String inviteCode) {
    return 'Tritt meiner AONW-Partie bei. Code: $inviteCode';
  }

  @override
  String get multiplayerInviteCodeRequired => 'Gib einen Partiecode ein.';

  @override
  String get multiplayerMapNotReady =>
      'Diese Karte ist nicht bereit für Mehrspieler.';

  @override
  String multiplayerRequestRejected(int statusCode) {
    return 'Der Server hat die Anfrage abgelehnt ($statusCode).';
  }

  @override
  String multiplayerRequestRejectedWithReason(int statusCode, String reason) {
    return 'Der Server hat die Anfrage abgelehnt ($statusCode: $reason).';
  }

  @override
  String multiplayerConnectionError(String host) {
    return 'Verbindung zu $host konnte nicht hergestellt werden. Prüfe deine Internetverbindung und versuche es erneut.';
  }

  @override
  String get multiplayerSignInRequired =>
      'Melde dich an oder erstelle ein Konto, um Mehrspieler zu spielen.';

  @override
  String get multiplayerSessionExpired =>
      'Deine Mehrspielersitzung ist abgelaufen. Melde dich erneut an und versuche es noch einmal.';

  @override
  String get multiplayerAccountTitle => 'Mehrspieler-Konto';

  @override
  String get multiplayerAccountSubtitle =>
      'Melde dich an oder erstelle ein Konto, um fortzufahren.';

  @override
  String get multiplayerAccountEmailLabel => 'E-Mail';

  @override
  String get multiplayerAccountPasswordLabel => 'Passwort';

  @override
  String get multiplayerAccountSignInTab => 'Anmelden';

  @override
  String get multiplayerAccountCreateTab => 'Konto erstellen';

  @override
  String get multiplayerAccountSignInAction => 'Anmelden';

  @override
  String get multiplayerAccountCreateAction => 'Konto erstellen';

  @override
  String get multiplayerAccountSignOutAction => 'Abmelden';

  @override
  String get multiplayerAccountSignedOut => 'Vom Mehrspieler abgemeldet.';

  @override
  String get multiplayerAccountInvalidEmail =>
      'Gib eine gültige E-Mail-Adresse ein.';

  @override
  String get multiplayerAccountInvalidCredentials =>
      'E-Mail oder Passwort ist ungültig.';

  @override
  String get multiplayerAccountExists =>
      'Ein Konto mit dieser E-Mail existiert bereits.';

  @override
  String get multiplayerAccountWeakPassword =>
      'Das Passwort muss mindestens 8 Zeichen lang sein.';

  @override
  String get multiplayerAccountInvalidNickname =>
      'Verwende 3-24 Buchstaben, Zahlen, Leerzeichen, _ oder -.';

  @override
  String get multiplayerAccountNicknameTaken =>
      'Dieser Spitzname ist bereits vergeben.';

  @override
  String get multiplayerAccountGenericError =>
      'Authentifizierung fehlgeschlagen. Versuche es erneut.';

  @override
  String get multiplayerMatchUnavailable =>
      'Diese Partie ist nicht mehr verfügbar.';

  @override
  String get multiplayerMatchFull => 'Diese Partie ist voll.';

  @override
  String get multiplayerCountryUnavailable =>
      'Mehrere Spieler haben deine Zivilisation gewählt. Versuch eine andere.';

  @override
  String get multiplayerMatchNotReady =>
      'Die Partie ist noch nicht startbereit.';

  @override
  String get multiplayerMatchAccessDenied =>
      'Du bist kein Spieler in dieser Partie.';

  @override
  String get multiplayerQueueGenericError =>
      'Mehrspieler-Warteschlange konnte nicht betreten werden. Versuche es erneut.';

  @override
  String get multiplayerResumeAction => 'Spiel fortsetzen';

  @override
  String get multiplayerResumeSublabel =>
      'Zur letzten Mehrspielersitzung zurückkehren';

  @override
  String get multiplayerResumeLoading =>
      'Verbindung zur Partie wird hergestellt...';

  @override
  String get multiplayerResumeFailed =>
      'Die letzte Mehrspielersitzung konnte nicht fortgesetzt werden.';

  @override
  String get optionsTooltip => 'Optionen';

  @override
  String get optionsOpenMenuTooltip => 'Menü öffnen';

  @override
  String optionsTooltipWithCollapseHint(String tooltip) {
    return '$tooltip. Halten, um das Menü einzuklappen.';
  }

  @override
  String get optionsTitle => 'Optionen';

  @override
  String get optionsSubtitle => 'Text, Sprache, Audio und Leistung';

  @override
  String get languageSectionTitle => 'Sprache';

  @override
  String get languagePolish => 'Polnisch';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languageFrench => 'Französisch';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageSpanish => 'Spanisch';

  @override
  String get languageDutch => 'Niederländisch';

  @override
  String get textScaleStandard => 'Standard';

  @override
  String get textScaleLarge => 'Groß';

  @override
  String get textScaleExtraLarge => 'Sehr groß';

  @override
  String textScaleSemanticLabel(String label) {
    return 'Textgröße $label';
  }

  @override
  String textScaleTooltip(String label) {
    return 'Textgröße: $label';
  }

  @override
  String languageSemanticLabel(String label) {
    return 'Sprache $label';
  }

  @override
  String languageTooltip(String label) {
    return 'Sprache: $label';
  }

  @override
  String get audioSectionTitle => 'Audio';

  @override
  String get gameSoundsLabel => 'Spielgeräusche';

  @override
  String get soundVolumeLabel => 'Lautstärke der Geräusche';

  @override
  String get gameMusicLabel => 'Spielmusik';

  @override
  String get musicVolumeLabel => 'Musiklautstärke';

  @override
  String get natureSoundsLabel => 'Naturgeräusche';

  @override
  String get natureVolumeLabel => 'Naturlautstärke';

  @override
  String get aiSectionTitle => 'KI';

  @override
  String get aiBatterySaverLabel => 'KI-Akkusparmodus';

  @override
  String get gameplaySectionTitle => 'Gameplay';

  @override
  String get followUnitMovementCameraLabel =>
      'Einheitenbewegung mit der Kamera verfolgen';

  @override
  String get followEnemyUnitCameraLabel =>
      'Feindeinheiten mit der Kamera verfolgen';

  @override
  String get cinematicCameraLabel => 'Filmische Kamera';

  @override
  String get performanceSectionTitle => 'Leistung';

  @override
  String get showFpsLabel => 'FPS anzeigen';

  @override
  String get showMapZoomLabel => 'Kartenzoom anzeigen';

  @override
  String get mapViewModeTooltip => 'Kartenansichtsmodus ändern';

  @override
  String get mapViewGraphicUnavailableTooltip =>
      'Grafikmodus ist für diese Karte nicht verfügbar';

  @override
  String get mapViewModeGraphic => 'Grafik';

  @override
  String get mapViewModeTiles => 'Kacheln';

  @override
  String get gameOptionTerrain => 'Gelände';

  @override
  String get gameOptionResources => 'Ressourcen';

  @override
  String get gameOptionHeight => 'Höhe';

  @override
  String get gameOptionCitySites => 'Stadtstandorte';

  @override
  String get gameOptionCityGrowth => 'Stadtwachstum';

  @override
  String get gameOptionShowHexes => 'Hexfelder anzeigen';

  @override
  String get gameOptionShowHeight => 'Höhe anzeigen';

  @override
  String get gameOptionDiceTest => 'Würfeltest';

  @override
  String get gameOptionAutoActionFlow => 'Aktionen automatisch abschließen';

  @override
  String get gameOptionAutoTurnFlow => 'Züge automatisch beenden';

  @override
  String get helpPopupsTitle => 'Hinweise';

  @override
  String get autoTurnHintTitle => 'Züge automatisch beenden';

  @override
  String get autoTurnHintBody =>
      'Das automatische Beenden von Zügen schickt den Zug ab, wenn keine wichtigen Aktionen mehr übrig sind. Das automatische Abschließen von Aktionen kannst du separat in den Kartenoptionen steuern.';

  @override
  String get autoTurnHintEnableAction => 'Aktivieren';

  @override
  String get autoTurnHintDisableAction => 'Deaktivieren';

  @override
  String get autoTurnHintStatusOn => 'Aktiviert';

  @override
  String get autoTurnHintStatusOff => 'Deaktiviert';

  @override
  String get autoTurnHintMinimizedSubtitle =>
      'Schneller Schalter für automatischen Zugablauf.';

  @override
  String visibilityShowAction(String label) {
    return '$label anzeigen';
  }

  @override
  String visibilityHideAction(String label) {
    return '$label ausblenden';
  }

  @override
  String get resignAction => 'Aufgeben';

  @override
  String get resignMatchTitle => 'Partie aufgeben?';

  @override
  String get resignMatchMessage => 'Die Partie wird beendet.';

  @override
  String get resignMatchError => 'Partie konnte nicht aufgegeben werden.';

  @override
  String get creditsTitle => 'Credits';

  @override
  String creditsCreatedBy(String name) {
    return 'Erstellt von $name';
  }

  @override
  String get deleteGameTitle => 'Spiel löschen';

  @override
  String deleteGameMessage(String name) {
    return '„$name“ löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get deleteAction => 'LÖSCHEN';

  @override
  String get retryAction => 'ERNEUT VERSUCHEN';

  @override
  String get noSavedGames => 'Keine gespeicherten Spiele.';

  @override
  String get resumeAction => 'FORTSETZEN';

  @override
  String get newGameAction => 'NEUES SPIEL';

  @override
  String get turnActionButtonLabel => 'Aktion';

  @override
  String get endTurnButtonLabel => 'Zug beenden';

  @override
  String get waitingTurnButtonLabel => 'Warten';

  @override
  String get waitingForPlayersTooltip => 'Warte auf andere Spieler';

  @override
  String submitTurnTooltip(int turn) {
    return 'Bereitschaft in Zug $turn senden';
  }

  @override
  String endTurnTooltip(int turn) {
    return 'Zug $turn beenden';
  }

  @override
  String get nextActionTooltip => 'Zur nächsten Aktion gehen';

  @override
  String nextActionWithCountTooltip(int count) {
    return 'Zur nächsten Aktion gehen ($count übrig)';
  }

  @override
  String get turnActionListTooltip => 'Eine Aktion aus der Liste wählen';

  @override
  String get hudActionDeckCollapseTooltip => 'Untere Werkzeugleiste einklappen';

  @override
  String get hudActionDeckExpandTooltip => 'Untere Werkzeugleiste ausklappen';

  @override
  String get turnActionUnitKind => 'Einheit';

  @override
  String get turnActionCityProductionKind => 'Stadt';

  @override
  String get turnActionResearchKind => 'Forschung';

  @override
  String turnActionCityProductionLabel(String cityName) {
    return 'Produktion von $cityName';
  }

  @override
  String get turnActionResearchLabel => 'Forschung wählen';

  @override
  String turnLabel(int turn) {
    return 'ZUG $turn';
  }

  @override
  String loadGameError(String error) {
    return 'Ladefehler: $error';
  }

  @override
  String get backAction => 'Zurück';

  @override
  String get continueAction => 'Weiter';

  @override
  String get gameLoadingTitle => 'Welt wird geladen';

  @override
  String get gameLoadingMessage =>
      'Karte, Einheiten und Oberfläche werden vorbereitet. Das Spiel erscheint, sobald die Assets bereit sind.';

  @override
  String get firstTurnTutorialPopupTitle => 'Tutorial';

  @override
  String get firstTurnTutorialPopupSubtitle => 'Anleitung für den ersten Zug';

  @override
  String firstTurnTutorialSemantics(String title) {
    return 'Erster Zug: $title';
  }

  @override
  String firstTurnCoachmarkProgressLabel(int current, int total) {
    return 'Schritt $current/$total';
  }

  @override
  String get firstTurnCoachmarkMinimizeTooltip => 'Minimieren';

  @override
  String get firstTurnCoachmarkSkipAction => 'Überspringen';

  @override
  String get firstTurnCoachmarkNextAction => 'Weiter';

  @override
  String get firstTurnCoachmarkDoneAction => 'Fertig';

  @override
  String get firstTurnCoachmarkSelectionTitle => 'Schritt 1: Auswahl lesen';

  @override
  String get firstTurnCoachmarkSelectionBody =>
      'Das Spiel beginnt, indem deine erste Einheit automatisch ausgewählt wird. Der untere Bereich zeigt, was du befehligst, wie viele Aktionen übrig sind und welche Befehle du jetzt geben kannst.';

  @override
  String get firstTurnCoachmarkSelectionBodyUnit =>
      'Die untere Werkzeugleiste beschreibt die ausgewählte Einheit: Typ, Bewegung, Aktionswarteschlange und verfügbare Befehle. Nutze sie, um den Bewegungsmodus zu starten, und brich ihn ab, wenn Tippen auf Hex-Felder wieder zur Prüfung dienen soll.';

  @override
  String get firstTurnCoachmarkSelectionBodyCity =>
      'Du hast eine Stadt ausgewählt. Der untere Bereich zeigt ihre Produktion, Bevölkerung, Gebäude und wirtschaftlichen Entscheidungen. Das ist ein anderer Kontext als Einheitsbefehle, daher behandelt das Tutorial die Stadt.';

  @override
  String get firstTurnCoachmarkSelectionBodyNone =>
      'Wenn nichts ausgewählt ist, zeigt der untere Bereich den allgemeinen Zugstatus. Tippe eine deiner Einheiten oder Städte an, um konkrete Befehle und Informationen zu sehen.';

  @override
  String get firstTurnCoachmarkResourcesTitle => 'Schritt 2: Imperium prüfen';

  @override
  String get firstTurnCoachmarkResourcesBody =>
      'Die obere Leiste zeigt Zug, Gold, Wissenschaft und Ressourcen. Gold stützt die Wirtschaft, Wissenschaft treibt Forschung an und Ressourcen zeigen, was sich zu bauen lohnt.';

  @override
  String get firstTurnCoachmarkMenuTitle =>
      'Schritt 3: linkes Menü kennenlernen';

  @override
  String get firstTurnCoachmarkMenuBody =>
      'Das linke Menü sammelt Ansichten, die du in jedem Zug erneut nutzt: Kartenoptionen, minimierte Pop-up-Antworten, Ziele, Protokoll, Forschung und Imperium. Halte die Menütaste gedrückt, um die Leiste einzuklappen, und tippe dann auf die einzelne Taste, um sie wieder zu öffnen.';

  @override
  String get firstTurnCoachmarkActionTitle =>
      'Schritt 4: richtigen Befehl geben';

  @override
  String get firstTurnCoachmarkActionBodyActive =>
      'Wenn der Siedler auf einem guten Feld steht, nutze die Stadtgründungsaktion. Ist der Standort schwach, bewege die Einheit und decke Gelände auf. Bewegung und Spezialaktionen verbrauchen den Zug dieser Einheit.';

  @override
  String get firstTurnCoachmarkActionBodyWaiting =>
      'Wenn eine Einheit einen Befehl hat, erscheint er hier. Gehe in den ersten Zügen Einheiten und Städte nacheinander durch, bis keine wichtige Entscheidung zurückbleibt.';

  @override
  String get firstTurnCoachmarkActionBodySettler =>
      'Der Siedler entscheidet über den Start deines Imperiums. Wenn das Feld Wachstum, Produktion und Raum zur Expansion bietet, gründe eine Stadt. Ist das Gelände schwach, bewege den Siedler und prüfe zuerst das nahe Land.';

  @override
  String get firstTurnCoachmarkActionBodyWorker =>
      'Ein Arbeiter gründet keine Städte. Seine Aufgabe ist es, Felder innerhalb von Stadtgrenzen zu verbessern: Bauernhöfe fördern Wachstum, Minen erhöhen Produktion und Ressourcenverbesserungen stärken die Wirtschaft.';

  @override
  String get firstTurnCoachmarkActionBodyUnit =>
      'Bei Kampf- und Späheinheiten zählen Bewegung, Sicht und Sicherheit am meisten. Decke Gelände auf, schütze Stadtgrenzen und greife nur an, wenn das vorhergesagte Ergebnis günstig ist.';

  @override
  String get firstTurnCoachmarkActionBodyCity =>
      'Bei ausgewählter Stadt führt dieser Bereich zu Produktion und Verwaltung. Wähle ein Bauziel, prüfe Stadtwachstum und verhindere, dass die Stadt untätig bleibt.';

  @override
  String get firstTurnCoachmarkResearchTitle => 'Schritt 5: Forschung wählen';

  @override
  String get firstTurnCoachmarkResearchBody =>
      'Öffne die Forschung vor dem Beenden des Zuges. Landwirtschaft unterstützt Wachstum, Bergbau erhöht Produktion und Jagd verbessert Erkundung und Verteidigung. Vor allem sollte Wissenschaft nicht ohne Ziel laufen.';

  @override
  String get firstTurnCoachmarkResearchBodyAvailable =>
      'Forschung kann gewählt werden. Öffne die Forschung vor dem Beenden des Zuges: Landwirtschaft unterstützt Wachstum, Bergbau erhöht Produktion und Jagd verbessert Erkundung und Verteidigung.';

  @override
  String get firstTurnCoachmarkCityTitle => 'Schritt 6: Stadt einrichten';

  @override
  String get firstTurnCoachmarkCityBody =>
      'Nach der Gründung der Hauptstadt wählst du Produktion. Ein Arbeiter entwickelt Felder, ein Krieger sichert das Gebiet und Gebäude stärken die Wirtschaft. Die Stadt sollte immer etwas bauen.';

  @override
  String get firstTurnCoachmarkCityBodySelected =>
      'Dies ist der Stadtbereich. Prüfe Produktion, Wachstum, Gebäude und verfügbare Projekte. Die Hauptregel für neue Züge: Jede Stadt sollte ein Produktionsziel haben.';

  @override
  String get firstTurnCoachmarkCityBodyNeedsProduction =>
      'Eine deiner Städte wartet auf Produktion. Nutze die Aktionstaste oder wähle die Stadt, entscheide dich für eine Einheit, ein Gebäude oder Projekt und beende erst dann den Zug.';

  @override
  String get firstTurnCoachmarkCityBodyExisting =>
      'Deinen Städten ist bereits Produktion zugewiesen. Kehre in späteren Zügen hierher zurück, um Wachstum, Gebäude, Spezialisierung und Verteidigungsbedarf zu beobachten.';

  @override
  String get firstTurnCoachmarkCityBodyFuture =>
      'Nachdem du die erste Stadt gegründet hast, kehrst du hierher zurück, um Produktion zu wählen. Ein Arbeiter entwickelt Felder, ein Krieger sichert das Gebiet und Gebäude stärken die Wirtschaft.';

  @override
  String get firstTurnCoachmarkActionFlowTitle =>
      'Schritt 7: Aktionswarteschlange leeren';

  @override
  String get firstTurnCoachmarkActionFlowBodyReady =>
      'Alle wichtigen Entscheidungen für diesen Zug sind bereit. Bestätige vor dem Beenden des Zuges kurz, dass Forschung und Stadtproduktion jeweils ein Ziel haben.';

  @override
  String get firstTurnCoachmarkActionFlowBodyPending =>
      'Die Aktionstaste führt zur nächsten Einheit, Stadt oder fehlenden Wahl. Drücke sie weiter, bis das Spiel zeigt, dass der Zug sicher beendet werden kann.';

  @override
  String get firstTurnCoachmarkEndTurnTitle =>
      'Schritt 8: Zug beenden und wiederholen';

  @override
  String get firstTurnCoachmarkEndTurnBody =>
      'Wenn nichts deine Reaktion erfordert, beende den Zug. Der Rhythmus der nächsten Züge ist derselbe: Ressourcen, Einheiten, Stadt, Forschung, dann Zug beenden.';

  @override
  String get firstTurnCoachmarkVictoryBody =>
      'Du kannst durch Dominanz oder Artefakte gewinnen: Platziere 6 einzigartige Artefakte in deinen Städten und halte die Sammlung 5 Züge lang.';

  @override
  String get firstTurnCoachmarkHexTapBody =>
      'Klicke oder tippe denselben Hex mehrmals an, um seine Informationen zu wechseln: Feldauswahl, Artefakt, Kartenziel und Hexbeschreibung.';

  @override
  String get gameLoadMapErrorTitle => 'Karte konnte nicht geladen werden';

  @override
  String gameLoadMapErrorMessage(String mapName, String error) {
    return 'Karte „$mapName“ konnte nicht geladen werden: $error';
  }

  @override
  String get gameOutcomeVictoryTitle => 'Sieg';

  @override
  String get gameOutcomeDefeatTitle => 'Niederlage';

  @override
  String get gameOutcomeDrawTitle => 'Unentschieden';

  @override
  String get gameOutcomeCompleteTitle => 'Spiel vorbei';

  @override
  String get gameOutcomeConditionConquest => 'Eroberung';

  @override
  String get gameOutcomeConditionScore => 'Punktzahl';

  @override
  String get gameOutcomeConditionScoreDraw => 'Punkte-Unentschieden';

  @override
  String get gameOutcomeConditionDomination => 'Dominanz';

  @override
  String get gameOutcomeConquestNoWinner =>
      'Ein Imperium bleibt auf der Karte.';

  @override
  String gameOutcomeConquestWinner(String winner) {
    return '$winner ist das letzte Imperium auf der Karte.';
  }

  @override
  String get gameOutcomeScoreNoWinner =>
      'Das Zuglimit hat das Ergebnis entschieden.';

  @override
  String gameOutcomeScoreWinner(String winner) {
    return '$winner gewinnt nach Erreichen des Zuglimits.';
  }

  @override
  String get gameOutcomeScoreDrawSubtitle =>
      'Zuglimit erreicht. Die höchste Punktzahl ist gleichauf.';

  @override
  String get gameOutcomeDominationNoWinner => 'Kartenkontrolle wurde gehalten.';

  @override
  String gameOutcomeDominationWinner(String winner) {
    return '$winner hält territoriale Dominanz.';
  }

  @override
  String get gameOutcomeWinnerMetric => 'Gewinner';

  @override
  String get gameOutcomeConditionMetric => 'Bedingung';

  @override
  String get gameOutcomeEliminationMetric => 'Ausschaltung';

  @override
  String get gameOutcomeMapControlMetric => 'Kartenkontrolle';

  @override
  String get gameOutcomeHoldMetric => 'Halten';

  @override
  String get gameOutcomeThresholdMetric => 'Schwelle';

  @override
  String gameOutcomeTurnsValue(int held, int required) {
    return '$held/$required Züge';
  }

  @override
  String get victoryConquestPrimary => 'Eroberung';

  @override
  String get victoryGoalCompact => 'Ziel';

  @override
  String get victoryNoLimit => 'Kein Limit';

  @override
  String get victoryConquestTooltip =>
      'Ziel: Rivalen ausschalten. Kein Zuglimit.';

  @override
  String get victoryLimitLabel => 'Limit';

  @override
  String get victoryNoneValue => 'Keine';

  @override
  String get victoryScoreCapPrimary => 'PUNKTELIMIT';

  @override
  String victoryScoreRemainingPrimary(int turns) {
    return 'PUNKTE ${turns}Z';
  }

  @override
  String get victoryScoreCapCompact => 'LIMIT';

  @override
  String victoryTurnsCompact(int turns) {
    return '${turns}Z';
  }

  @override
  String victoryTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Züge',
      one: '1 Zug',
    );
    return '$_temp0';
  }

  @override
  String get victoryRemainingLabel => 'Verbleibend';

  @override
  String get victoryScoreLeaderLabel => 'Punkteführer';

  @override
  String victoryScoreDrawLabel(int score) {
    return 'UNENTSCHIEDEN $score';
  }

  @override
  String victoryScoreLimitReachedTooltip(int turnLimit) {
    return 'Zuglimit $turnLimit erreicht. Die Punktzahl entscheidet das Ergebnis.';
  }

  @override
  String victoryScoreFallbackTooltip(int remainingTurns, int turnLimit) {
    return 'Punkte-Ausweichwertung in $remainingTurns Zügen. Limit: $turnLimit.';
  }

  @override
  String victoryLeaderTooltip(String leader) {
    return 'Führender: $leader.';
  }

  @override
  String victoryDominationTooltip(
    String leader,
    String control,
    String required,
    String hold,
  ) {
    return 'Dominanz: $leader kontrolliert $control% der Karte. Schwelle: $required%, halten: $hold.';
  }

  @override
  String get victoryLeaderLabel => 'Führender';

  @override
  String get victoryControlLabel => 'Kontrolle';

  @override
  String get victoryHoldLabel => 'Halten';

  @override
  String get victoryYouLabel => 'Du';

  @override
  String get victoryPressureLabel => 'Druck';

  @override
  String get victoryFallbackLabel => 'Ausweichwertung';

  @override
  String victoryYourGoalGainControl(int points) {
    return 'Dein Ziel: $points PP mehr Kartenkontrolle gewinnen.';
  }

  @override
  String get victoryYourGoalReady =>
      'Dein Ziel: Die Dominanzbedingung ist bereit zur Auswertung.';

  @override
  String victoryYourGoalHold(String turns) {
    return 'Dein Ziel: die Schwelle noch $turns halten.';
  }

  @override
  String victoryLeaderAboveThreshold(String leader) {
    return '$leader liegt über der Schwelle; brich diese Kontrolle, bevor das Ziel gehalten wird.';
  }

  @override
  String victoryYourProgress(String control, String required) {
    return 'Dein Fortschritt: $control% / $required%.';
  }

  @override
  String victoryPressureReachThreshold(int points) {
    return 'Schwelle erreichen: es fehlen $points PP';
  }

  @override
  String get victoryConditionReady => 'Bedingung bereit';

  @override
  String victoryPressureHold(String turns) {
    return 'Für $turns halten';
  }

  @override
  String victoryPressureLeaderHolding(String leader, String turns) {
    return '$leader über Schwelle: $turns';
  }

  @override
  String victoryPressureYourGap(int points) {
    return 'Dein Ziel: es fehlen $points PP';
  }

  @override
  String victoryPressureLeaderGap(String leader, int points) {
    return '$leader führt: es fehlen $points PP';
  }

  @override
  String victoryThreatApproaching(
    String player,
    String control,
    String required,
    int points,
  ) {
    return 'Rivale nähert sich der Dominanz: $player kontrolliert $control% bei einer Schwelle von $required%; es fehlen $points PP.';
  }

  @override
  String victoryThreatHolding(String player, String hold) {
    return 'Rivale hält die Dominanzschwelle: $player $hold.';
  }

  @override
  String victoryThreatImminent(String player, String hold) {
    return 'Rivale steht kurz vor der Dominanz: $player $hold.';
  }

  @override
  String victoryThreatPressureApproaching(String player, int points) {
    return '$player nahe an der Schwelle: es fehlen $points PP';
  }

  @override
  String victoryThreatPressureBreak(String player, String turns) {
    return '$player brechen: $turns';
  }

  @override
  String get victoryBelowThreshold => 'unter der Schwelle';

  @override
  String victoryHoldProgress(int held, int required) {
    return '$held/$required Züge';
  }

  @override
  String victoryHoldCompact(int held, int required) {
    return '$held/${required}Z';
  }

  @override
  String get victoryReady => 'bereit';

  @override
  String victoryRemainingTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Züge übrig',
      one: '1 Zug übrig',
    );
    return '$_temp0';
  }

  @override
  String get returnToMenuAction => 'Zurück zum Menü';

  @override
  String get today => 'heute';

  @override
  String get yesterday => 'gestern';

  @override
  String get objectivesPanelTitle => 'ZIELE';

  @override
  String get objectivesCloseTooltip => 'Ziele schließen';

  @override
  String get objectivesMenuClosePrefix => 'Ziele schließen';

  @override
  String get objectivesMenuOpenPrefix => 'Ziele';

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
      other: '$count Ziele',
      one: '1 Ziel',
    );
    return '$_temp0';
  }

  @override
  String get objectivesMenuBadgeScore => 'PTS';

  @override
  String get objectivesMenuBadgeDomination => 'DOM';

  @override
  String get objectivesMenuDescriptorDomination => 'Dominanz';

  @override
  String get objectivesMenuDescriptorDominationThreat => 'Dominanzbedrohung';

  @override
  String get objectivesMenuDescriptorScoreLead => 'Führung verteidigen';

  @override
  String get objectivesMenuDescriptorScorePressure => 'Punktedruck';

  @override
  String get objectivesMenuDescriptorActiveObjective => 'aktives Ziel';

  @override
  String get objectiveMicroTooltipLabel => 'Warum';

  @override
  String get objectiveOverviewGuidanceLabel => 'AKTIVES ZIEL';

  @override
  String get objectiveOverviewStrategicLabel => 'DRINGEND';

  @override
  String get objectiveOverviewScoreCatchUpLabel => 'PUNKTEDRUCK';

  @override
  String get objectiveOverviewScoreProtectLabel => 'FÜHRUNG VERTEIDIGEN';

  @override
  String get objectiveOverviewDominationHoldLabel => 'DOMINANZ';

  @override
  String get objectiveOverviewDominationThreatLabel => 'DOMINANZBEDROHUNG';

  @override
  String objectiveOverviewTitleLabel(String title) {
    return 'Höchste Priorität: $title';
  }

  @override
  String objectiveOverviewProgressLabel(String progress) {
    return 'Fortschritt $progress';
  }

  @override
  String get objectivePhaseFoundation => 'Fundament';

  @override
  String get objectivePhaseExpansion => 'Expansion';

  @override
  String get objectivePhasePressure => 'Druck';

  @override
  String get objectivePhaseEndgame => 'Endspiel';

  @override
  String get objectiveChooseResearchTitle => 'Forschung wählen';

  @override
  String get objectiveChooseResearchHint =>
      'Lege deine Entwicklungsrichtung fest, bevor der erste Zug endet.';

  @override
  String get objectiveChooseResearchReward => '+ Wissenschaftstempo';

  @override
  String get objectiveChooseResearchTooltip =>
      'Forschung richtet jeden folgenden Zug auf einen bestimmten Entwicklungspfad aus.';

  @override
  String get objectiveFoundCapitalTitle => 'Gründe deine erste Stadt';

  @override
  String get objectiveFoundCapitalHint =>
      'Dein Siedler sollte gutes Gelände schnell in eine Hauptstadt verwandeln.';

  @override
  String get objectiveFoundCapitalReward => '+ Produktionsbasis';

  @override
  String get objectiveFoundCapitalTooltip =>
      'Die Hauptstadt schaltet Produktion, Wachstum und territoriale Reichweite frei.';

  @override
  String get objectiveExploreNearbyTitle => 'Nahegelegenes Land erkunden';

  @override
  String get objectiveExploreNearbyHint =>
      'Dein Krieger sollte nahe Ressourcen und Stadtstandorte aufdecken.';

  @override
  String get objectiveExploreNearbyReward => '+ bessere Entscheidungen';

  @override
  String get objectiveExploreNearbyTooltip =>
      'Frühe Erkundung hilft bei der Wahl von Stadtstandorten und vermeidet blinde Züge.';

  @override
  String get objectiveQueueWorkerTitle => 'Arbeiter einreihen';

  @override
  String get objectiveQueueWorkerHint =>
      'Ein Arbeiter verwandelt Nahrung und Produktion auf der Karte in einen echten Vorteil.';

  @override
  String get objectiveQueueWorkerReward => '+ Feldentwicklung';

  @override
  String get objectiveQueueWorkerTooltip =>
      'Ein Arbeiter verwandelt gute Felder in stetiges Ressourcenwachstum.';

  @override
  String get objectiveImproveFirstHexTitle => 'Verbessere dein erstes Feld';

  @override
  String get objectiveImproveFirstHexHint =>
      'Die erste Verbesserung sollte Nahrung, Produktion oder Gold unterstützen.';

  @override
  String get objectiveImproveFirstHexReward => '+ stärkere Wirtschaft';

  @override
  String get objectiveImproveFirstHexTooltip =>
      'Die erste Verbesserung zeigt, welcher Teil der Stadtwirtschaft am schnellsten wachsen sollte.';

  @override
  String get objectiveFoundSecondCityTitle => 'Gründe eine zweite Stadt';

  @override
  String get objectiveFoundSecondCityHint =>
      'Eine zweite Siedlung eröffnet Expansion, ohne die Karte mit Einheiten zu überfluten.';

  @override
  String get objectiveFoundSecondCityReward => '+ Imperiumsgröße';

  @override
  String get objectiveFoundSecondCityTooltip =>
      'Eine zweite Stadt erhöht das Produktionstempo, ohne auf eine einzige Hauptstadt warten zu müssen.';

  @override
  String get objectiveBuildFirstBuildingTitle => 'Baue dein erstes Gebäude';

  @override
  String get objectiveBuildFirstBuildingHint =>
      'Das erste Gebäude sollte Nahrung, Produktion oder Gold stärken.';

  @override
  String get objectiveBuildFirstBuildingReward => '+ dauerhafter Stadtvorteil';

  @override
  String get objectiveBuildFirstBuildingTooltip =>
      'Gebäude bleiben in der Stadt und skalieren über viele Züge.';

  @override
  String get objectiveImproveThreeHexesTitle => 'Verbessere drei Felder';

  @override
  String get objectiveImproveThreeHexesHint =>
      'Mehrere Verbesserungen verwandeln ein Startlager in eine Wirtschaft.';

  @override
  String get objectiveImproveThreeHexesReward => '+ stabiles Einkommen';

  @override
  String get objectiveImproveThreeHexesTooltip =>
      'Drei Verbesserungen schaffen eine stabile Basis für Armeen, Forschung oder Expansion.';

  @override
  String get objectiveFoundThirdCityTitle => 'Gründe eine dritte Stadt';

  @override
  String get objectiveFoundThirdCityHint =>
      'Eine dritte Siedlung schafft ein echtes Imperium und eine zweite Expansionsrichtung.';

  @override
  String get objectiveFoundThirdCityReward => '+ Kartenmaßstab';

  @override
  String get objectiveFoundThirdCityTooltip =>
      'Eine dritte Stadt gibt dir eine zweite Entwicklungsfront und mehr Entscheidungen in jedem Zug.';

  @override
  String get objectiveExploreRegionTitle => 'Region erkunden';

  @override
  String get objectiveExploreRegionHint =>
      'Eine weitere Karte enthüllt Ressourcen, Rivalen und verteidigungswerte Orte.';

  @override
  String get objectiveExploreRegionReward => '+ strategischer Plan';

  @override
  String get objectiveExploreRegionTooltip =>
      'Eine weitere Karte enthüllt Rivalen, strategische Ressourcen und sichere Grenzen.';

  @override
  String get objectiveBuildCombatForceTitle => 'Defensive Streitmacht aufbauen';

  @override
  String get objectiveBuildCombatForceHint =>
      'Mehrere Truppen lassen dich Expansion schützen und Rivalen unter Druck setzen.';

  @override
  String get objectiveBuildCombatForceReward => '+ Grenzsicherheit';

  @override
  String get objectiveBuildCombatForceTooltip =>
      'Ein stabiler Schutzschirm schützt Siedler, Arbeiter und entwickelte Städte.';

  @override
  String get objectiveRaiseStabilityTitle => 'Restore stability';

  @override
  String get objectiveRaiseStabilityHint =>
      'Your empire is strained. Add order buildings, connect luxuries, or consolidate before it slips into unrest.';

  @override
  String get objectiveRaiseStabilityReward => '+ steady growth';

  @override
  String get objectiveRaiseStabilityTooltip =>
      'Strained and unrest empires lose city growth and part of their yields until stability recovers.';

  @override
  String get objectiveHoldDominationTitle => 'Dominanz halten';

  @override
  String get objectiveHoldDominationHint =>
      'Du liegst über der Kartenschwelle. Behalte die Kontrolle, bis der Countdown endet.';

  @override
  String get objectiveHoldDominationReward => '+ Kartensieg';

  @override
  String get objectiveHoldDominationTooltip =>
      'Dominanz beendet das Spiel vor dem Punktelimit, wenn du den erforderlichen Kartenanteil über aufeinanderfolgende Züge hältst.';

  @override
  String get objectiveBreakDominationHoldTitle =>
      'Dominanz eines Rivalen brechen';

  @override
  String get objectiveBreakDominationHoldHint =>
      'Ein Rivale liegt über der Kartenschwelle. Nimm Gebiet ein, bevor er das Ziel hält.';

  @override
  String get objectiveBreakDominationHoldReward => '+ Countdown gestoppt';

  @override
  String get objectiveBreakDominationHoldTooltip =>
      'Wenn ein Rivale unter die Kontrollschwelle fällt, werden seine Haltezüge auf null zurückgesetzt.';

  @override
  String get objectiveHoldScoreLeadTitle => 'Führung halten';

  @override
  String get objectiveHoldScoreLeadHint =>
      'Das Zuglimit ist nahe. Schütze deine Punktzahl und verliere deinen Vorsprung in den letzten Zügen nicht.';

  @override
  String get objectiveHoldScoreLeadReward => '+ Punktelimit-Sieg';

  @override
  String get objectiveHoldScoreLeadTooltip =>
      'Das Punktelimit entscheidet die Partie, wenn das Zuglimit überschritten wird; daher muss die Punktführung bis zum Ende halten.';

  @override
  String get objectiveOvertakeScoreLeaderTitle => 'Punkteführer einholen';

  @override
  String get objectiveOvertakeScoreLeaderHint =>
      'Das Zuglimit ist nahe. Du brauchst schnelles Punktewachstum oder einen schwächeren Führenden.';

  @override
  String get objectiveOvertakeScoreLeaderReward => '+ Chance auf Punktelimit';

  @override
  String get objectiveOvertakeScoreLeaderTooltip =>
      'Baue Städte, Bevölkerung, Technologien, Einheiten und Verbesserungen; bei Gleichstand endet das Punktelimit unentschieden.';

  @override
  String get objectiveSecureMapObjectiveTitle => 'Kartenziel sichern';

  @override
  String get objectiveSecureMapObjectiveHint =>
      'Halte eine Einheit oder Stadteinfluss auf dem Ziel, bis das Halten abgeschlossen ist.';

  @override
  String get objectiveSecureMapObjectiveReward => '+ Zielbelohnungen';

  @override
  String get objectiveSecureMapObjectiveTooltip =>
      'Kartenziele nutzen Dreiecksmarker und geben Siegpunkte oder Gold erst nach aufeinanderfolgender Kontrolle.';

  @override
  String get objectiveBreakMapObjectiveHoldTitle =>
      'Kartenziel des Rivalen brechen';

  @override
  String get objectiveBreakMapObjectiveHoldHint =>
      'Ein Rivale hält ein Kartenziel. Bestreite den Dreiecksmarker, bevor das Halten abgeschlossen ist.';

  @override
  String get objectiveBreakMapObjectiveHoldReward => '+ Ziel verweigert';

  @override
  String get objectiveBreakMapObjectiveHoldTooltip =>
      'Eine eigene Einheit auf dem Ziel bestreitet die Kontrolle und setzt den Fortschritt des Rivalen zurück.';

  @override
  String get objectiveAdviceFoundCity =>
      'Größte Lücke: eine neue oder eroberte Stadt.';

  @override
  String get objectiveAdviceGrowPopulation =>
      'Größte Lücke: Bevölkerungswachstum.';

  @override
  String get objectiveAdviceClaimTerritory =>
      'Größte Lücke: mehr kontrollierte Felder.';

  @override
  String get objectiveAdviceConstructBuilding =>
      'Größte Lücke: ein Stadtgebäude.';

  @override
  String get objectiveAdviceTrainUnit => 'Größte Lücke: eine schnelle Einheit.';

  @override
  String get objectiveAdviceUnlockTechnology =>
      'Größte Lücke: eine Technologie abschließen.';

  @override
  String get objectiveAdviceImproveField =>
      'Größte Lücke: eine Feldverbesserung.';

  @override
  String get objectiveAdviceCollectGold => 'Größte Lücke: Gold für Punkte.';

  @override
  String get objectiveAdviceProtectLead =>
      'Priorität: Städte nicht aufgeben und den nächsten Punktegewinn sichern.';

  @override
  String objectiveScoreBreakdownCatchUpHeader(int delta) {
    return 'Punkterückstand: $delta Pkt.';
  }

  @override
  String objectiveScoreBreakdownProtectHeader(int delta) {
    return 'Punktevorsprung: $delta Pkt.';
  }

  @override
  String objectiveScoreBreakdownCatchUpTotals(
    int playerScore,
    int comparisonScore,
  ) {
    return 'Du $playerScore / Führender $comparisonScore';
  }

  @override
  String objectiveScoreBreakdownProtectTotals(
    int playerScore,
    int comparisonScore,
  ) {
    return 'Du $playerScore / Rivale $comparisonScore';
  }

  @override
  String objectiveScoreBreakdownCatchUpDelta(int delta) {
    return 'um $delta zurück';
  }

  @override
  String objectiveScoreBreakdownProtectDelta(int delta) {
    return '+$delta';
  }

  @override
  String get objectiveScoreCategoryCity => 'Städte';

  @override
  String get objectiveScoreCategoryPopulation => 'Bevölkerung';

  @override
  String get objectiveScoreCategoryTerritory => 'Gebiet';

  @override
  String get objectiveScoreCategoryBuilding => 'Gebäude';

  @override
  String get objectiveScoreCategoryUnit => 'Einheiten';

  @override
  String get objectiveScoreCategoryTechnology => 'Technologien';

  @override
  String get objectiveScoreCategoryImprovement => 'Verbesserungen';

  @override
  String get objectiveScoreCategoryGold => 'Gold';

  @override
  String get cityBuildingGranary => 'Kornspeicher';

  @override
  String get cityBuildingWaterMill => 'Wassermühle';

  @override
  String get cityBuildingWorkshop => 'Werkstatt';

  @override
  String get cityBuildingStorehouse => 'Lagerhaus';

  @override
  String get cityBuildingHousing => 'Wohnraum';

  @override
  String get cityBuildingMerchantHall => 'Kaufmannshalle';

  @override
  String get cityBuildingStonemason => 'Steinmetz';

  @override
  String get cityBuildingBarracks => 'Kaserne';

  @override
  String get cityBuildingMarketplace => 'Marktplatz';

  @override
  String get cityBuildingPort => 'Hafen';

  @override
  String get cityBuildingAqueduct => 'Aquädukt';

  @override
  String get cityBuildingForge => 'Schmiede';

  @override
  String get cityBuildingStable => 'Stall';

  @override
  String get cityBuildingBank => 'Bank';

  @override
  String get cityBuildingBuildersGuild => 'Baumeistergilde';

  @override
  String get cityBuildingFactory => 'Fabrik';

  @override
  String get cityBuildingLighthouse => 'Leuchtturm';

  @override
  String get cityBuildingTrainingGrounds => 'Übungsplätze';

  @override
  String get cityBuildingTownHall => 'Rathaus';

  @override
  String get cityBuildingMonument => 'Monument';

  @override
  String get cityBuildingArchive => 'Archiv';

  @override
  String get cityBuildingAcademy => 'Akademie';

  @override
  String get cityBuildingUniversity => 'Universität';

  @override
  String get cityBuildingObservatory => 'Observatorium';

  @override
  String get cityBuildingLaboratory => 'Labor';

  @override
  String get cityBuildingReactor => 'Reaktor';

  @override
  String get cityBuildingCourthouse => 'Gerichtsgebäude';

  @override
  String get cityBuildingCourt => 'Gericht';

  @override
  String get cityBuildingGovernorsOffice => 'Gouverneursbüro';

  @override
  String get cityBuildingSurveyorsOffice => 'Vermessungsbüro';

  @override
  String get cityBuildingPlanningOffice => 'Planungsbüro';

  @override
  String get cityBuildingApothecary => 'Apotheke';

  @override
  String get cityBuildingPublicBaths => 'Öffentliche Bäder';

  @override
  String get cityBuildingHospital => 'Krankenhaus';

  @override
  String get cityBuildingMinistries => 'Ministerien';

  @override
  String get cityBuildingWalls => 'Mauern';

  @override
  String get cityBuildingArmory => 'Waffenkammer';

  @override
  String get cityBuildingSiegeWorkshop => 'Belagerungswerkstatt';

  @override
  String get cityBuildingCitadel => 'Zitadelle';

  @override
  String get cityBuildingWarCollege => 'Kriegsakademie';

  @override
  String get cityBuildingConscriptionOffice => 'Rekrutierungsbüro';

  @override
  String get cityBuildingBorderFort => 'Grenzfort';

  @override
  String get cityBuildingAirfield => 'Flugfeld';

  @override
  String get cityBuildingArtisansGuild => 'Handwerkergilde';

  @override
  String get cityBuildingMasterWorkshop => 'Meisterwerkstatt';

  @override
  String get cityBuildingSteelworks => 'Stahlwerk';

  @override
  String get cityBuildingRailDepot => 'Bahndepot';

  @override
  String get cityBuildingPowerPlant => 'Kraftwerk';

  @override
  String get cityBuildingAssemblyPlant => 'Montagewerk';

  @override
  String get cityBuildingRefinery => 'Raffinerie';

  @override
  String get cityBuildingMapRoom => 'Kartenraum';

  @override
  String get cityBuildingShipyard => 'Werft';

  @override
  String get cityBuildingDryDock => 'Trockendock';

  @override
  String get cityBuildingNavalAcademy => 'Marineakademie';

  @override
  String get cityBuildingHarborCustoms => 'Hafenzoll';

  @override
  String get cityBuildingMuseum => 'Museum';

  @override
  String get cityBuildingParliament => 'Parlament';

  @override
  String get cityBuildingBroadcastTower => 'Sendeturm';

  @override
  String get cityBuildingWorldFairGrounds => 'Weltausstellungsgelände';

  @override
  String get cityBuildingGranaryDescription =>
      'Ein frühes Nahrungsgebäude, das das Stadtwachstum stabilisiert.';

  @override
  String get cityBuildingWaterMillDescription =>
      'Nutzt kontrollierte Flussfelder, um die Stadtnahrung zu erhöhen.';

  @override
  String get cityBuildingWorkshopDescription =>
      'Ein einfaches Handwerkszentrum, das die Stadtproduktion steigert.';

  @override
  String get cityBuildingStorehouseDescription =>
      'Verbessert die Lagerung der Ernte und erhöht gespeicherte Nahrung.';

  @override
  String get cityBuildingHousingDescription =>
      'Erweitert den Wohnraum und lässt die Stadt mehr Felder kontrollieren.';

  @override
  String get cityBuildingMerchantHallDescription =>
      'Organisiert lokalen Handel und erhöht das Stadteinkommen.';

  @override
  String get cityBuildingStonemasonDescription =>
      'Stärkt Stadtbau und Verteidigungsbasis.';

  @override
  String get cityBuildingBarracksDescription =>
      'Bietet militärische Infrastruktur und zusätzliche Verteidigung.';

  @override
  String get cityBuildingMarketplaceDescription =>
      'Entwickelt städtischen Handel und erhöht das Goldeinkommen stark.';

  @override
  String get cityBuildingPortDescription =>
      'Öffnet die Stadt für Seehandel und Küstennahrung.';

  @override
  String get cityBuildingAqueductDescription =>
      'Leitet Wasser heran und unterstützt Wachstum sowie weitere Stadterweiterung.';

  @override
  String get cityBuildingForgeDescription =>
      'Bündelt Metallverarbeitung und erhöht die Produktion stark.';

  @override
  String get cityBuildingStableDescription =>
      'Unterstützt Zucht und Logistik und fügt Nahrung sowie Produktion hinzu.';

  @override
  String get cityBuildingBankDescription =>
      'Zentralisiert Finanzen und erhöht das Stadteinkommen deutlich.';

  @override
  String get cityBuildingBuildersGuildDescription =>
      'Versammelt Bauspezialisten und beschleunigt Produktion und territoriales Wachstum.';

  @override
  String get cityBuildingFactoryDescription =>
      'Ein Industriegebäude für das spätere Spiel, das einen großen Produktionsbonus gewährt.';

  @override
  String get cityBuildingLighthouseDescription =>
      'Stärkt die Küstenwirtschaft durch Navigation und Handel.';

  @override
  String get cityBuildingTrainingGroundsDescription =>
      'Entwickelt militärische Ausbildung und verbessert die Stadtverteidigung.';

  @override
  String get cityBuildingTownHallDescription =>
      'Das Verwaltungszentrum der Stadt stärkt Wirtschaft und territoriale Kontrolle.';

  @override
  String get cityBuildingMonumentDescription =>
      'Ein Symbol städtischen Prestiges, das Gold und Verteidigung bietet.';

  @override
  String get cityBuildingArchiveDescription =>
      'Das erste Wissensgebäude, das Aufzeichnungen organisiert und Forschung unterstützt.';

  @override
  String get cityBuildingAcademyDescription =>
      'Stärkt Wissenschaftsstädte und bereitet den Weg zu höherer Bildung.';

  @override
  String get cityBuildingUniversityDescription =>
      'Ein späteres Wissenschaftsgebäude für große, entwickelte Städte.';

  @override
  String get cityBuildingObservatoryDescription =>
      'Verbindet Geografie mit Wissenschaft und unterstützt fortgeschrittene Forschung.';

  @override
  String get cityBuildingLaboratoryDescription =>
      'Unterstützung für späte Technologieprojekte und moderne Wissenschaft.';

  @override
  String get cityBuildingReactorDescription =>
      'Ein mächtiges Endspielgebäude, das Uran und starke Infrastruktur erfordert.';

  @override
  String get cityBuildingCourthouseDescription =>
      'Stabilisiert große oder eroberte Städte durch Rechtsverwaltung.';

  @override
  String get cityBuildingCourtDescription =>
      'Entwickelt Recht, Stadtpolitik und zivile Kontrolle.';

  @override
  String get cityBuildingGovernorsOfficeDescription =>
      'Stärkt Stadtspezialisierung und Gebietsverwaltung.';

  @override
  String get cityBuildingSurveyorsOfficeDescription =>
      'Erleichtert Grenzplanung und erhöht die Kontrollreichweite der Stadt.';

  @override
  String get cityBuildingPlanningOfficeDescription =>
      'Entwickelt die Stadt durch Planung, Produktion und territoriale Kontrolle.';

  @override
  String get cityBuildingApothecaryDescription =>
      'Frühe Stadtgesundheit, die stetiges Wachstum unterstützt.';

  @override
  String get cityBuildingPublicBathsDescription =>
      'Verbessern Stabilität und Wachstum in größeren Städten.';

  @override
  String get cityBuildingHospitalDescription =>
      'Späte Bevölkerungsinfrastruktur für langfristige Entwicklung.';

  @override
  String get cityBuildingMinistriesDescription =>
      'Ein begrenztes Imperiumsgebäude, das Verwaltung und Gold stärkt.';

  @override
  String get cityBuildingWallsDescription =>
      'Frühe Stadtverteidigung gegen die ersten Angriffe.';

  @override
  String get cityBuildingArmoryDescription =>
      'Ein besseres Rekrutierungs- und Ausrüstungszentrum für Truppen.';

  @override
  String get cityBuildingSiegeWorkshopDescription =>
      'Produziert und unterhält die Unterstützungsbasis für Belagerungsmaschinen.';

  @override
  String get cityBuildingCitadelDescription =>
      'Späte strategische Verteidigung für Städte an wichtigen Grenzen.';

  @override
  String get cityBuildingWarCollegeDescription =>
      'Eine Militärakademie, die Armee und Koordination der Generäle stärkt.';

  @override
  String get cityBuildingConscriptionOfficeDescription =>
      'Mobilisiert die Armee und beschleunigt die Vorbereitung neuer Truppen.';

  @override
  String get cityBuildingBorderFortDescription =>
      'Stärkt Verteidigung und Sicht an Imperiumsgrenzen.';

  @override
  String get cityBuildingAirfieldDescription =>
      'Ein militärisches Flugfeld für Luftfahrt, Aufklärung und moderne Machtprojektion.';

  @override
  String get cityBuildingArtisansGuildDescription =>
      'Eine Produktionsstufe vor der Fabrik, basierend auf Handwerk und Werkstätten.';

  @override
  String get cityBuildingMasterWorkshopDescription =>
      'Eine spezialisierte Werkstatt für produktionsorientierte Städte.';

  @override
  String get cityBuildingSteelworksDescription =>
      'Schwerindustrie auf Grundlage von Eisen oder Kohle.';

  @override
  String get cityBuildingRailDepotDescription =>
      'Ein Bahndepot, das Logistik und Mobilität zwischen Städten verbessert.';

  @override
  String get cityBuildingPowerPlantDescription =>
      'Späte Energieinfrastruktur für starke Industrieproduktion.';

  @override
  String get cityBuildingAssemblyPlantDescription =>
      'Ein Endspiel-Industriegebäude für Massenproduktion.';

  @override
  String get cityBuildingRefineryDescription =>
      'Verarbeitet Öl für moderne Armeen und späte Projekte.';

  @override
  String get cityBuildingMapRoomDescription =>
      'Unterstützt Erkundung, Sicht und Expeditionsplanung.';

  @override
  String get cityBuildingShipyardDescription =>
      'Entwickelt Flotten und Produktion in Hafenstädten.';

  @override
  String get cityBuildingDryDockDescription =>
      'Ein später Marinehafen für größere Kriegsschiffe.';

  @override
  String get cityBuildingNavalAcademyDescription =>
      'Eine Marineakademie für spezialisierte Häfen.';

  @override
  String get cityBuildingHarborCustomsDescription =>
      'Ein Hafenamt, das Handel und Küstenkontrolle stärkt.';

  @override
  String get cityBuildingMuseumDescription =>
      'Ein prestigeträchtiges Imperiumsgebäude, das den Stadteinfluss stärkt.';

  @override
  String get cityBuildingParliamentDescription =>
      'Ein begrenztes Zivilgebäude für einen reifen Staat.';

  @override
  String get cityBuildingBroadcastTowerDescription =>
      'Stärkt Imperiumseinfluss, Sicht und Kommunikation.';

  @override
  String get cityBuildingWorldFairGroundsDescription =>
      'Ein friedliches Prestigeprojekt für eine reiche, entwickelte Stadt.';

  @override
  String get unitCommander => 'General';

  @override
  String get unitWarrior => 'Krieger';

  @override
  String get unitArcher => 'Bogenschütze';

  @override
  String get unitSettler => 'Siedler';

  @override
  String get unitWorker => 'Arbeiter';

  @override
  String get unitMerchant => 'Händler';

  @override
  String get unitScout => 'Späher';

  @override
  String get unitSpearman => 'Speerträger';

  @override
  String get unitCavalry => 'Kavallerie';

  @override
  String get unitCatapult => 'Katapult';

  @override
  String get unitHeavyInfantry => 'Schwere Infanterie';

  @override
  String get unitFieldCannon => 'Feldkanone';

  @override
  String get unitRifleman => 'Schütze';

  @override
  String get unitTank => 'Panzer';

  @override
  String get unitScoutShip => 'Spähschiff';

  @override
  String get unitWarship => 'Kriegsschiff';

  @override
  String get unitReconPlane => 'Aufklärungsflugzeug';

  @override
  String get unitCommanderDescription =>
      'Ein General befehligt eine Armee, führt Aufklärung an und kann schneller handeln als reguläre Truppen.';

  @override
  String get unitWarriorDescription =>
      'Eine grundlegende Kampfeinheit für Stadtverteidigung und Nahkampf.';

  @override
  String get unitArcherDescription =>
      'Eine Fernkampfeinheit, die aus größerer Entfernung angreift, sich im Nahkampf aber schlecht verteidigt.';

  @override
  String get unitSettlerDescription =>
      'Gründet neue Städte und erweitert das Imperium, braucht unterwegs aber Schutz.';

  @override
  String get unitWorkerDescription =>
      'Verbessert Felder rund um Städte und erhöht Nahrung, Produktion und Gold.';

  @override
  String get unitMerchantDescription =>
      'Reist automatisch zwischen deinen Städten auf einer Handelsroute und kann besetzte befreundete Stadtzentren betreten.';

  @override
  String get unitScoutDescription =>
      'Eine schnelle Aufklärungseinheit zum Erkunden der Karte und Erkennen von Bedrohungen.';

  @override
  String get unitSpearmanDescription =>
      'Frühe Verteidigungsinfanterie, gut zum Abdecken von Städten und Stoppen von Angriffen.';

  @override
  String get unitCavalryDescription =>
      'Eine mobile Angriffseinheit, die schnell auf Schwachpunkte an der Front reagiert.';

  @override
  String get unitCatapultDescription =>
      'Eine Belagerungsmaschine mit größerer Reichweite, effektiv gegen Befestigungen.';

  @override
  String get unitHeavyInfantryDescription =>
      'Robuste Frontinfanterie mit hoher Verteidigung und solidem Angriff.';

  @override
  String get unitFieldCannonDescription =>
      'Moderne Feldartillerie für Fernbeschuss.';

  @override
  String get unitRiflemanDescription =>
      'Ein moderner Fernkampfsoldat, zuverlässig in Angriff und Verteidigung.';

  @override
  String get unitTankDescription =>
      'Eine schwere gepanzerte Einheit mit hoher Stärke und hoher Mobilität.';

  @override
  String get unitScoutShipDescription =>
      'Ein leichtes Schiff für Küstenaufklärung und den Schutz früher Seewege.';

  @override
  String get unitWarshipDescription =>
      'Ein starkes Kampfschiff für Seekontrolle und Fernbeschuss.';

  @override
  String get unitReconPlaneDescription =>
      'Ein Aufklärungsflugzeug mit großer Sichtweite und sehr hoher Mobilität.';

  @override
  String get unitRankRecruit => 'Rekrut';

  @override
  String get unitRankSeasoned => 'Erfahren';

  @override
  String get unitRankVeteran => 'Veteran';

  @override
  String get unitRankElite => 'Elite';

  @override
  String get troopWarrior => 'Krieger';

  @override
  String get troopArcher => 'Bogenschützen';

  @override
  String get troopSettler => 'Siedler';

  @override
  String get fieldImprovementFarm => 'Bauernhof';

  @override
  String get fieldImprovementRiverFarm => 'Flussbauernhof';

  @override
  String get fieldImprovementMine => 'Mine';

  @override
  String get fieldImprovementLumberMill => 'Sägewerk';

  @override
  String get fieldImprovementPasture => 'Weide';

  @override
  String get fieldImprovementCamp => 'Lager';

  @override
  String get fieldImprovementQuarry => 'Steinbruch';

  @override
  String get fieldImprovementFishingBoats => 'Fischerboote';

  @override
  String get fieldImprovementOrchard => 'Obstgarten';

  @override
  String get fieldImprovementPlantation => 'Plantage';

  @override
  String get fieldImprovementVineyard => 'Weinberg';

  @override
  String get fieldImprovementTradingPost => 'Handelsposten';

  @override
  String get fieldImprovementProspectorCamp => 'Prospektorenlager';

  @override
  String get fieldImprovementHorseRanch => 'Pferderanch';

  @override
  String get fieldImprovementPearlDivers => 'Perlentaucher';

  @override
  String get fieldImprovementCoalShaft => 'Kohleschacht';

  @override
  String get fieldImprovementOilWell => 'Ölquelle';

  @override
  String get fieldImprovementBauxiteMine => 'Bauxitmine';

  @override
  String get fieldImprovementUraniumMine => 'Uranmine';

  @override
  String get resourceWheat => 'Weizen';

  @override
  String get resourceFish => 'Fisch';

  @override
  String get resourceDeer => 'Wild';

  @override
  String get resourceSheep => 'Schafe';

  @override
  String get resourceRice => 'Reis';

  @override
  String get resourceCow => 'Rinder';

  @override
  String get resourceApple => 'Äpfel';

  @override
  String get resourceBanana => 'Bananen';

  @override
  String get resourceCitrus => 'Zitrusfrüchte';

  @override
  String get resourceGold => 'Gold';

  @override
  String get resourceSilver => 'Silber';

  @override
  String get resourceGems => 'Edelsteine';

  @override
  String get resourceSilk => 'Seide';

  @override
  String get resourceSpices => 'Gewürze';

  @override
  String get resourceCotton => 'Baumwolle';

  @override
  String get resourceGrapes => 'Trauben';

  @override
  String get resourceIvory => 'Elfenbein';

  @override
  String get resourcePearls => 'Perlen';

  @override
  String get resourceCoffee => 'Kaffee';

  @override
  String get resourceCocoa => 'Kakao';

  @override
  String get resourceTobacco => 'Tabak';

  @override
  String get resourceSugar => 'Zucker';

  @override
  String get resourceIron => 'Eisen';

  @override
  String get resourceCoal => 'Kohle';

  @override
  String get resourceOil => 'Öl';

  @override
  String get resourceAluminium => 'Aluminium';

  @override
  String get resourceUranium => 'Uran';

  @override
  String get resourceHorses => 'Pferde';

  @override
  String get resourceMarble => 'Marmor';

  @override
  String get technologyAgriculture => 'Landwirtschaft';

  @override
  String get technologyWoodworking => 'Holzbearbeitung';

  @override
  String get technologyMining => 'Bergbau';

  @override
  String get technologyAnimalHusbandry => 'Tierhaltung';

  @override
  String get technologyHunting => 'Jagd';

  @override
  String get technologyFishing => 'Fischerei';

  @override
  String get technologyCraftsmanship => 'Handwerkskunst';

  @override
  String get technologyTrade => 'Handel';

  @override
  String get technologyStorage => 'Lagerung';

  @override
  String get technologyWaterEngineering => 'Wasserbau';

  @override
  String get technologyStoneworking => 'Steinbearbeitung';

  @override
  String get technologyMilitaryOrganization => 'Militärorganisation';

  @override
  String get technologyAdvancedTrade => 'Fortgeschrittener Handel';

  @override
  String get technologyConstruction => 'Bauwesen';

  @override
  String get technologyNavigation => 'Navigation';

  @override
  String get technologyIrrigation => 'Bewässerung';

  @override
  String get technologyBanking => 'Bankwesen';

  @override
  String get technologyEngineering => 'Ingenieurwesen';

  @override
  String get technologyMetallurgy => 'Metallurgie';

  @override
  String get technologyHorsebackRiding => 'Reitkunst';

  @override
  String get technologyIronWorking => 'Eisenverarbeitung';

  @override
  String get technologyCoalMining => 'Kohlebergbau';

  @override
  String get technologyMachinery => 'Maschinenbau';

  @override
  String get technologyAdministration => 'Verwaltung';

  @override
  String get technologyLogistics => 'Logistik';

  @override
  String get technologyShipbuilding => 'Schiffbau';

  @override
  String get technologyTactics => 'Taktik';

  @override
  String get technologyEconomy => 'Wirtschaft';

  @override
  String get technologyUrbanization => 'Urbanisierung';

  @override
  String get technologyFortifications => 'Befestigungen';

  @override
  String get technologyStrategy => 'Strategie';

  @override
  String get technologySpecialization => 'Spezialisierung';

  @override
  String get technologyWriting => 'Schrift';

  @override
  String get technologyMathematics => 'Mathematik';

  @override
  String get technologyMedicine => 'Medizin';

  @override
  String get technologyCivilService => 'Staatsdienst';

  @override
  String get technologySiegecraft => 'Belagerungskunst';

  @override
  String get technologyCartography => 'Kartografie';

  @override
  String get technologyGuilds => 'Gilden';

  @override
  String get technologyLaw => 'Recht';

  @override
  String get technologyEducation => 'Bildung';

  @override
  String get technologyUrbanPlanning => 'Stadtplanung';

  @override
  String get technologyNavalDoctrine => 'Marinedoktrin';

  @override
  String get technologySteel => 'Stahl';

  @override
  String get technologyBureaucracy => 'Bürokratie';

  @override
  String get technologyNationalism => 'Nationalismus';

  @override
  String get technologyScientificMethod => 'Wissenschaftliche Methode';

  @override
  String get technologySteamPower => 'Dampfkraft';

  @override
  String get technologyElectricity => 'Elektrizität';

  @override
  String get technologyCombustion => 'Verbrennung';

  @override
  String get technologyFlight => 'Flug';

  @override
  String get technologyMassProduction => 'Massenproduktion';

  @override
  String get technologyRadio => 'Radio';

  @override
  String get technologyNuclearPhysics => 'Kernphysik';

  @override
  String get technologyAgricultureDescription =>
      'Öffnet den grundlegenden Wachstumspfad. Bauernhöfe und Flussbauernhöfe lassen die Bevölkerung schneller wachsen und stabilisieren die erste Stadt.';

  @override
  String get technologyWoodworkingDescription =>
      'Entwickelt die Produktionsseite des Bergbaus. Sägewerke verwandeln Wälder in Produktion, ohne tief in die Metallurgie einzusteigen.';

  @override
  String get technologyMiningDescription =>
      'Öffnet den Pfad von Industrie und Infrastruktur. Minen sind der erste große Sprung in der Stadtproduktion.';

  @override
  String get technologyAnimalHusbandryDescription =>
      'Stärkt Wachstum durch Tierressourcen. Weiden bauen eine Nahrungswirtschaft auf und bereiten den Weg zur Reitkunst.';

  @override
  String get technologyHuntingDescription =>
      'Öffnet den Militär- und Erkundungszweig. Bietet Lager und die erste Fernkampfeinheit für Stadtproduktion.';

  @override
  String get technologyFishingDescription =>
      'Entwickelt Städte am Wasser. Fischerboote helfen Küstenstädten, schneller zu wachsen, und bereiten den Weg zum Hafen.';

  @override
  String get technologyCraftsmanshipDescription =>
      'Die erste Aufwertung der Stadtproduktion. Die Werkstatt verhindert, dass spätere Gebäude und Einheiten die Warteschlange zu lange blockieren.';

  @override
  String get technologyTradeDescription =>
      'Der erste Schritt in der Goldwirtschaft. Die Kaufmannshalle gibt einer Stadt nach der Wahl eines Wachstumspfads einen einfachen finanziellen Nutzen.';

  @override
  String get technologyStorageDescription =>
      'Stabilisiert Stadtwachstum. Lagerung hilft, das Nahrungstempo zu halten und das Risiko von Entwicklungsstillständen zu senken.';

  @override
  String get technologyWaterEngineeringDescription =>
      'Erweitert den wasserbasierten Wachstumspfad. Die Wassermühle belohnt Städte, die Flüsse kontrollieren.';

  @override
  String get technologyStoneworkingDescription =>
      'Verbindet Produktion und Verteidigung. Steinbrüche und der Steinmetz stärken Städte im Infrastrukturzweig.';

  @override
  String get technologyMilitaryOrganizationDescription =>
      'Baut den ersten militärischen Kern einer Stadt auf. Kasernen stärken Produktion und Verteidigung, bevor spätere Armeeboni erscheinen.';

  @override
  String get technologyAdvancedTradeDescription =>
      'Entwickelt die Wirtschaft nach dem Handel. Der Marktplatz ist ein stärkeres Goldgebäude und bereitet den Weg zum Bankwesen.';

  @override
  String get technologyConstructionDescription =>
      'Erweitert Gebiet und Stadtreife. Wohnraum erhöht die Feldkontrolle und führt zu Verwaltung und Ingenieurwesen.';

  @override
  String get technologyNavigationDescription =>
      'Öffnet einen Stadtnutzen für die Küste. Der Hafen erfordert Küsten-/Ozeanzugang und belohnt Uferstädte mit Nahrung und Gold.';

  @override
  String get technologyIrrigationDescription =>
      'Spezialisiert wasserbasiertes Wachstum. Das Aquädukt gewährt einen starken Nahrungsbonus und zusätzliche territoriale Kontrolle.';

  @override
  String get technologyBankingDescription =>
      'Spezialisiert den Handelszweig. Die Bank macht frühere Märkte zu starkem Stadteinkommen und schaltet die breitere Wirtschaft frei.';

  @override
  String get technologyEngineeringDescription =>
      'Spezialisierung im Bauwesen. Die Baumeistergilde beschleunigt Produktion und erhöht das Limit kontrollierter Felder.';

  @override
  String get technologyMetallurgyDescription =>
      'Ein starker industrieller Ertrag nach Steinbearbeitung. Die Schmiede erhöht Produktion und bereitet den Weg zu Eisen und Kohle.';

  @override
  String get technologyHorsebackRidingDescription =>
      'Eine Technologie, die Wachstum und Krieg verbindet. Der Stall unterstützt Städte, die zuvor in Tiere und Jagd investiert haben.';

  @override
  String get technologyIronWorkingDescription =>
      'Ein Effekt industrieller Ressourcen. Jede kontrollierte Eisenressource erhöht die Stadtproduktion.';

  @override
  String get technologyCoalMiningDescription =>
      'Ein späterer Effekt industrieller Ressourcen. Kontrollierte Kohle erhöht die Stadtproduktion und unterstützt den Fabrikpfad.';

  @override
  String get technologyMachineryDescription =>
      'Ein später Infrastrukturertrag. Die Fabrik gibt Städten, die Ingenieurwesen erreicht haben, einen großen Produktionszuwachs.';

  @override
  String get technologyAdministrationDescription =>
      'Verbindet Infrastruktur mit Wirtschaft. Rathäuser und Monumente stärken reife Städte und führen zur Urbanisierung.';

  @override
  String get technologyLogisticsDescription =>
      'Beschleunigt Einheitsproduktion. Dies ist die Haupttechnologie für Spieler, die häufiger Armeen aus Städten aufstellen wollen.';

  @override
  String get technologyShipbuildingDescription =>
      'Entwickelt den Küsten-/Erkundungsunterzweig. Der Leuchtturm benötigt Küstenzugang und stärkt Uferstädte.';

  @override
  String get technologyTacticsDescription =>
      'Militärische Stadtspezialisierung. Übungsplätze fügen Verteidigung und Produktion für Militärzentren hinzu.';

  @override
  String get technologyEconomyDescription =>
      'Ein systemischer Ertrag für Bankwesen. Erhöht das von Stadtwirtschaften erzeugte Gold.';

  @override
  String get technologyUrbanizationDescription =>
      'Die finale Richtung für Großstadtwachstum. Erhöht das Bevölkerungslimit, sobald das Bevölkerungssystem harte Grenzen nutzt.';

  @override
  String get technologyFortificationsDescription =>
      'Stärkt die Stadtverteidigung. Gewährt der Stadtwirtschaft einen Verteidigungsbonus, dessen volle Bedeutung mit Kampf- und Belagerungserweiterung wächst.';

  @override
  String get technologyStrategyDescription =>
      'Die finale militärische Richtung. Stärkt die Armeewirksamkeit als später Ertrag nach Logistik.';

  @override
  String get technologySpecializationDescription =>
      'Der finale zivile/wirtschaftliche Ertrag. Schaltet Stadtspezialisierungen frei, fügt Stadtwissenschaft hinzu und hilft, späte Technologien in längeren Partien abzuschließen.';

  @override
  String get technologyWritingDescription =>
      'Der erste Schritt zu Wissenschaft, Recht und Verwaltung. Das Archiv gibt einer Stadt eine dauerhafte Forschungsbasis.';

  @override
  String get technologyMathematicsDescription =>
      'Verbindet Wissenschaft mit Gebietsplanung. Das Vermessungsbüro hilft Städten, Grenzen wirksamer zu kontrollieren.';

  @override
  String get technologyMedicineDescription =>
      'Entwickelt Gesundheit und langfristiges Wachstum in großen Städten durch Apotheken, Bäder und Krankenhäuser.';

  @override
  String get technologyCivilServiceDescription =>
      'Verbessert die Verwaltung eines großen Imperiums und schaltet Gerichte frei, die Städte stabilisieren.';

  @override
  String get technologySiegecraftDescription =>
      'Öffnet die Belagerungskriegsführung. Katapulte und Belagerungswerkstätten brechen Festungsstädte.';

  @override
  String get technologyCartographyDescription =>
      'Entwickelt Erkundung, Karten und die Küste. Gewährt den Kartenraum und die ersten Spähschiffe.';

  @override
  String get technologyGuildsDescription =>
      'Gibt Produktionsstädten eine Stufe zwischen Werkstatt und Industrie.';

  @override
  String get technologyLawDescription =>
      'Führt Ordnung, Politik und zivile Verwaltung durch Gerichte ein.';

  @override
  String get technologyEducationDescription =>
      'Baut den vollständigen Wissenschaftspfad für Städte über Akademien und Universitäten auf.';

  @override
  String get technologyUrbanPlanningDescription =>
      'Entwickelt große Städte und territoriale Kontrolle durch räumliche Planung.';

  @override
  String get technologyNavalDoctrineDescription =>
      'Macht Häfen zu Zentren für Flotten, Werften und Machtprojektion auf See.';

  @override
  String get technologySteelDescription =>
      'Führt Schwerindustrie und schwere Infanterie für die spätere Front ein.';

  @override
  String get technologyBureaucracyDescription =>
      'Bietet nach Verwaltung ein großes ziviles Ziel: Büros, Ministerien, Museen und Parlament.';

  @override
  String get technologyNationalismDescription =>
      'Kombiniert Grenzverteidigung, Mobilisierung und Imperiumsidentität.';

  @override
  String get technologyScientificMethodDescription =>
      'Bereitet späte Wissenschaft, Labore, Observatorien und Technologieprojekte vor.';

  @override
  String get technologySteamPowerDescription =>
      'Öffnet Bahn, schwerere Logistik und Dampfindustrie.';

  @override
  String get technologyElectricityDescription =>
      'Führt Strom, Infrastruktur und Informationsreichweite ein.';

  @override
  String get technologyCombustionDescription =>
      'Gibt Öl Bedeutung und schaltet moderne Fronteinheiten frei.';

  @override
  String get technologyFlightDescription =>
      'Führt Luftfahrt, Aufklärung und Machtprojektion über die Front ein.';

  @override
  String get technologyMassProductionDescription =>
      'Entwickelt finale Industrieproduktion, Panzer und Montagewerke.';

  @override
  String get technologyRadioDescription =>
      'Stärkt Imperiumskommunikation, Sicht und Einfluss durch Sendetürme.';

  @override
  String get technologyNuclearPhysicsDescription =>
      'Öffnet Reaktor, Uran und späte Endspielprojekte.';

  @override
  String get technologyEraFoundation => 'Fundament';

  @override
  String get technologyEraSettlement => 'Siedlung';

  @override
  String get technologyEraExpansion => 'Expansion';

  @override
  String get technologyEraSpecialization => 'Spezialisierung';

  @override
  String get technologyEraIndustry => 'Industrie';

  @override
  String get technologyEraStrategy => 'Strategie';

  @override
  String get technologyUnlockEffect => 'Effekt';

  @override
  String get technologyPrerequisitesNone => 'Keine';

  @override
  String get technologyStateCompleted => 'Abgeschlossen';

  @override
  String get technologyStateInProgress => 'In Arbeit';

  @override
  String get technologyStateAvailable => 'Verfügbar';

  @override
  String get technologyButtonResearched => 'ERFORSCHT';

  @override
  String get technologyButtonActive => 'AKTIV';

  @override
  String get technologyButtonResearch => 'ERFORSCHEN';

  @override
  String get technologyButtonLocked => 'GESPERRT';

  @override
  String get technologyTreeTitle => 'TECHNOLOGIEBAUM';

  @override
  String get technologyTreeEmptyTitle => 'Keine Technologien anzuzeigen';

  @override
  String get technologyTreeEmptyBody =>
      'Der Forschungsbaum wird hier angezeigt, sobald das Regelwerk Technologien für diese Ära bereitstellt.';

  @override
  String technologyResearchPointsShort(int points) {
    return '$points Pkt.';
  }

  @override
  String get technologyDetailsTooltip => 'Technologiedetails';

  @override
  String get technologyDetailsStatus => 'Status';

  @override
  String get technologyDetailsCost => 'Kosten';

  @override
  String get technologyDetailsProgress => 'Fortschritt';

  @override
  String get technologyDetailsPrerequisites => 'Voraussetzungen';

  @override
  String get technologyDetailsUnlocks => 'Schaltet frei';

  @override
  String get technologyDetailsEffects => 'Effekte';

  @override
  String get technologyDetailsBoosts => 'Boosts';

  @override
  String get technologyDetailsUnlockStatus => 'Freischaltung';

  @override
  String get technologyDetailsNoEffects => 'Keine passiven Effekte';

  @override
  String get technologyDetailsNoBoosts => 'Keine Boosts';

  @override
  String get technologyUnlocksNone => 'Keine direkten Freischaltungen';

  @override
  String get technologyBoostActiveBadge => 'Boost';

  @override
  String get technologyBoostActiveBest =>
      'Der beste verfügbare Boost ist aktiv.';

  @override
  String technologyBoostLine(String condition, String discount) {
    return '$condition (-$discount Kosten)';
  }

  @override
  String get technologyUnlockFieldImprovementCategory => 'Feldverbesserung';

  @override
  String technologyEffectStrategicResourceProductionBonus(
    int production,
    String resource,
  ) {
    return '+$production Produktion für jede kontrollierte Ressource: $resource';
  }

  @override
  String technologyEffectGlobalGoldMultiplier(String percent) {
    return '+$percent Gold in der Stadtwirtschaft';
  }

  @override
  String technologyEffectCityDefenseBonus(int amount) {
    return '+$amount Stadtverteidigung';
  }

  @override
  String technologyEffectArmyProductionMultiplier(String percent) {
    return '+$percent Einheitsproduktion in Städten';
  }

  @override
  String technologyEffectArmyStrengthMultiplier(String percent) {
    return '+$percent Armeestärke';
  }

  @override
  String technologyEffectMaxCityPopulationBonus(int amount) {
    return '+$amount max. Stadtbevölkerung';
  }

  @override
  String technologyEffectMaxControlledHexesBonus(int amount) {
    return '+$amount max. Stadtgebiet';
  }

  @override
  String technologyEffectCityScienceBonus(int amount) {
    return '+$amount Wissenschaft pro Stadt';
  }

  @override
  String technologyBoostConditionImprovementCount(
    int count,
    String improvement,
  ) {
    return 'Habe ${count}x $improvement';
  }

  @override
  String technologyBoostConditionHasImprovement(String improvement) {
    return 'Habe $improvement';
  }

  @override
  String technologyBoostConditionControlsResource(String resource) {
    return 'Kontrolliere $resource';
  }

  @override
  String technologyBoostConditionControlsAnyResource(String resources) {
    return 'Kontrolliere: $resources';
  }

  @override
  String technologyEffectAttackBonus(String value) {
    return '$value Angriff';
  }

  @override
  String technologyEffectDefenseBonus(String value) {
    return '$value Verteidigung';
  }

  @override
  String get technologyEffectNoArmyStatsBonus => 'Kein Armeewert-Bonus';

  @override
  String technologyEffectArmyStatsBonus(String parts) {
    return '$parts für Armeen';
  }

  @override
  String commonListOr(String first, String last) {
    return '$first oder $last';
  }

  @override
  String get buildingDetailsTooltip => 'Gebäudedetails';

  @override
  String get buildingDetailsNoRequirements => 'Keine';

  @override
  String get buildingDetailsYieldImpact => 'Stadtauswirkung';

  @override
  String buildingDetailsRequirementTechnology(String technology) {
    return 'Technologie: $technology';
  }

  @override
  String get buildingDetailsRequirementCoastalAccess => 'Küstenzugang';

  @override
  String buildingDetailsRequirementResources(String resources) {
    return 'Ressource: $resources';
  }

  @override
  String buildingDetailsFlatYieldEffect(String yield) {
    return '$yield zum Stadtertrag';
  }

  @override
  String buildingDetailsRiverHexYieldEffect(String yield) {
    return '$yield pro kontrolliertem Flussfeld';
  }

  @override
  String buildingDetailsRiverHexYieldEffectWithMax(
    String yield,
    int maxApplications,
  ) {
    return '$yield pro kontrolliertem Flussfeld (max. $maxApplications)';
  }

  @override
  String buildingDetailsMaxControlledHexesEffect(int amount) {
    return '+$amount Limit kontrollierter Stadtfelder';
  }

  @override
  String buildingDetailsFoodDepositMultiplierEffect(int percent) {
    return '+$percent% Nahrung nach dem Zug gespeichert';
  }

  @override
  String buildingDetailsYieldFood(String value) {
    return '$value Nahrung';
  }

  @override
  String buildingDetailsYieldProduction(String value) {
    return '$value Produktion';
  }

  @override
  String buildingDetailsYieldGold(String value) {
    return '$value Gold';
  }

  @override
  String buildingDetailsYieldDefense(String value) {
    return '$value Verteidigung';
  }

  @override
  String buildingDetailsYieldScience(String value) {
    return '$value Wissenschaft';
  }

  @override
  String get buildingDetailsNoYieldChange => 'Keine Ressourcenänderung';

  @override
  String get unitDetailsTooltip => 'Einheitsdetails';

  @override
  String get unitDetailsMovement => 'Bewegung';

  @override
  String get unitDetailsCombat => 'Kampf';

  @override
  String unitDetailsMovementPerTurn(int movement) {
    return '$movement Felder/Zug';
  }

  @override
  String get unitDetailsPace => 'Tempo';

  @override
  String unitDetailsRequirementTechnology(String technology) {
    return 'Technologie: $technology';
  }

  @override
  String unitDetailsAttackLine(int value) {
    return 'Angriff: $value';
  }

  @override
  String unitDetailsDefenseLine(int value) {
    return 'Verteidigung: $value';
  }

  @override
  String unitDetailsHpLine(int value) {
    return 'LP: $value';
  }

  @override
  String unitDetailsRangeLine(int value) {
    return 'Reichweite: $value';
  }

  @override
  String sciencePerTurn(int science) {
    return '$science Wissenschaft/Zug';
  }

  @override
  String get activeResearchLabel => 'FORSCHUNG';

  @override
  String get requirementTechnology => 'Benötigt Technologie';

  @override
  String requirementTechnologyName(String technology) {
    return 'Benötigt: $technology';
  }

  @override
  String requirementResourceAnyOf(String leading, String last) {
    return '$leading oder $last';
  }

  @override
  String requirementResourcesName(String resources) {
    return 'Benötigt: $resources';
  }

  @override
  String technologyBlockedBy(String technology) {
    return 'Blockiert durch: $technology';
  }

  @override
  String get requirementCoastalAccess => 'Benötigt: Küstenzugang';

  @override
  String get productionCategoryBuilding => 'Gebäude';

  @override
  String get productionCategoryUnit => 'Einheit';

  @override
  String get productionTitle => 'PRODUKTION';

  @override
  String get productionInProgressLabel => 'IN ARBEIT';

  @override
  String productionPerTurn(int production) {
    return '$production Produktion/Zug';
  }

  @override
  String get productionNoProduction => 'keine Produktion';

  @override
  String get productionButtonProduce => 'PRODUZIEREN';

  @override
  String get productionButtonLocked => 'GESPERRT';

  @override
  String get productionEmptyState => 'Derzeit ist keine Produktion verfügbar.';

  @override
  String get buildingsSection => 'Gebäude';

  @override
  String get unitsSection => 'Einheiten';

  @override
  String futureBuildingsSection(int count) {
    return 'Künftige Gebäude ($count)';
  }

  @override
  String get futureBuildingsSubtitle => 'Durch Technologien freigeschaltet';

  @override
  String workerPanelTitle(String unitName) {
    return 'Arbeiter - $unitName';
  }

  @override
  String get commonOpenAction => 'Öffnen';

  @override
  String get commonShowDetailsAction => 'Details anzeigen';

  @override
  String get commonExecuteAction => 'Ausführen';

  @override
  String colorPickerChangeTooltip(String label) {
    return 'Farbe ändern: $label';
  }

  @override
  String colorPickerColorSelected(String hex) {
    return '#$hex ausgewählt';
  }

  @override
  String colorPickerSelectColor(String hex) {
    return '#$hex auswählen';
  }

  @override
  String get commonDescription => 'Beschreibung';

  @override
  String get commonSummary => 'Zusammenfassung';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonTerrain => 'Gelände';

  @override
  String get commonResources => 'Ressourcen';

  @override
  String get commonImprovements => 'Verbesserungen';

  @override
  String get commonCities => 'Städte';

  @override
  String get commonBuildings => 'Gebäude';

  @override
  String get commonGold => 'Gold';

  @override
  String get commonScience => 'Wissenschaft';

  @override
  String get commonStability => 'Stability';

  @override
  String get commonProduction => 'Produktion';

  @override
  String get commonResearch => 'Forschung';

  @override
  String get commonEmpire => 'Imperium';

  @override
  String get commonTurn => 'Zug';

  @override
  String get commonProjects => 'Projekte';

  @override
  String get commonPopulation => 'Bevölkerung';

  @override
  String get commonTechnologies => 'Technologien';

  @override
  String get commonFields => 'Felder';

  @override
  String get commonMultipliers => 'Multiplikatoren';

  @override
  String get commonOther => 'Sonstiges';

  @override
  String get commonReady => 'Bereit';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonDefault => 'Standard';

  @override
  String get commonAvailable => 'Verfügbar';

  @override
  String get commonBlocked => 'Blockiert';

  @override
  String get commonSelectAction => 'Auswählen';

  @override
  String get commonSelectedAction => 'Ausgewählt';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDoNotShowAgain => 'Nicht erneut anzeigen';

  @override
  String get commonNoneLower => 'keine';

  @override
  String get visualCurrentLabel => 'Jetzt';

  @override
  String get visualAfterLabel => 'Nach Änderung';

  @override
  String get terrainDetailEmpty => 'Keine Geländeinformationen';

  @override
  String get yieldFoodShort => 'NAHRUNG';

  @override
  String get yieldProductionShort => 'PROD';

  @override
  String get yieldGoldShort => 'GOLD';

  @override
  String get yieldDefenseShort => 'VER';

  @override
  String selectionChipBadgeSuffix(String badge) {
    return ' Sichtbarer Zähler: $badge.';
  }

  @override
  String selectionChipDisabledDescription(String badge) {
    return 'Diese Informationsabkürzung ist für die aktuelle Auswahl nicht verfügbar.$badge';
  }

  @override
  String selectionChipOpenDescription(String label, String badge) {
    return 'Öffnet Details zu „$label“ für den aktuellen Kartenkontext.$badge';
  }

  @override
  String get gameGoalTitle => 'Spielziel';

  @override
  String get globalHudCloseResearch => 'Forschung schließen';

  @override
  String globalHudResearchActive(String technologyName) {
    return 'Forschung: $technologyName';
  }

  @override
  String globalHudResearchActiveWithEta(String technologyName, String eta) {
    return 'Forschung: $technologyName · $eta';
  }

  @override
  String get globalHudChooseResearch => 'Forschung wählen';

  @override
  String get globalHudCloseEmpire => 'Imperium schließen';

  @override
  String get globalHudCloseActivityLog => 'Aktivitätsprotokoll schließen';

  @override
  String get bottomToolbarWaiting => 'Warten';

  @override
  String get bottomToolbarPlan => 'Plan';

  @override
  String get bottomToolbarMove => 'Bewegen';

  @override
  String get bottomToolbarResolvingTurn => 'Zug wird ausgewertet';

  @override
  String bottomToolbarWaitingFor(String players) {
    return 'Warte auf: $players';
  }

  @override
  String turnHintNextUnit(String unit) {
    return 'Nächster Schritt: $unit';
  }

  @override
  String turnHintNextCityProduction(String city) {
    return 'Nächster Schritt: Produktion in $city';
  }

  @override
  String get turnHintChooseResearch => 'Nächster Schritt: Forschung wählen';

  @override
  String get turnHintCheckAction => 'Nächster Schritt: Aktion prüfen';

  @override
  String turnHintObjective(String objective) {
    return 'Ziel: $objective';
  }

  @override
  String turnHintObjectiveWithAdvice(String objective, String advice) {
    return 'Ziel: $objective · $advice';
  }

  @override
  String get turnHintImproveFieldWithWorker =>
      'Ziel: ein Feld mit einem Arbeiter verbessern';

  @override
  String get turnHintFoundCityWithSettler =>
      'Ziel: eine Stadt mit einem Siedler gründen';

  @override
  String get turnHintClaimTerritoryWithSettler =>
      'Ziel: Gebiet mit einem Siedler beanspruchen';

  @override
  String turnHintTrainUnit(String unit) {
    return 'Ziel: Einheit festlegen: $unit';
  }

  @override
  String turnHintProtectLeadUnit(String unit) {
    return 'Ziel: Führung sichern: $unit';
  }

  @override
  String turnHintConstructBuildingInCity(String city) {
    return 'Ziel: ein Gebäude in $city einreihen';
  }

  @override
  String turnHintTrainUnitInCity(String city) {
    return 'Ziel: eine Einheit in $city einreihen';
  }

  @override
  String turnHintPrepareSettlerInCity(String city) {
    return 'Ziel: einen Siedler in $city vorbereiten';
  }

  @override
  String turnHintGrowPopulationInCity(String city) {
    return 'Ziel: Wachstum in $city festlegen';
  }

  @override
  String turnHintPrepareWorkerInCity(String city) {
    return 'Ziel: einen Arbeiter in $city vorbereiten';
  }

  @override
  String turnHintCollectGoldInCity(String city) {
    return 'Ziel: Gold in $city sichern';
  }

  @override
  String turnHintProtectLeadProductionInCity(String city) {
    return 'Ziel: Produktion in $city sichern';
  }

  @override
  String get turnHintUnlockTechnologyForScore =>
      'Ziel: eine punktbringende Technologie wählen';

  @override
  String get turnHintProtectLeadResearch =>
      'Ziel: sichere Forschung abschließen';

  @override
  String topResourceTurnShortLabel(int turn) {
    return 'Z$turn';
  }

  @override
  String topResourceTurnTooltip(int turn) {
    return 'Zug $turn';
  }

  @override
  String topResourceScienceTooltip(String scienceTurnLabel) {
    return 'Wissenschaft: $scienceTurnLabel / Zug';
  }

  @override
  String topResourceStabilityTooltip(int net) {
    return 'Empire stability: $net';
  }

  @override
  String get stabilityBandContent => 'Content';

  @override
  String get stabilityBandStable => 'Stable';

  @override
  String get stabilityBandStrained => 'Strained';

  @override
  String get stabilityBandUnrest => 'Unrest';

  @override
  String get stabilityBreakdownBand => 'Current state';

  @override
  String get stabilityBreakdownNet => 'Net stability';

  @override
  String get stabilityBreakdownSources => 'Sources';

  @override
  String get stabilityBreakdownCosts => 'Costs';

  @override
  String get stabilityBreakdownBaseOrder => 'Base order';

  @override
  String get stabilityBreakdownBuildings => 'Order buildings';

  @override
  String get stabilityBreakdownLuxuries => 'Luxury resources';

  @override
  String get stabilityBreakdownTechnologies => 'Technologies';

  @override
  String get stabilityBreakdownArtifacts => 'Stored artifacts';

  @override
  String get stabilityBreakdownCities => 'Empire size';

  @override
  String get stabilityBreakdownPopulation => 'Population';

  @override
  String get stabilityBreakdownCohesion => 'Frontier cohesion';

  @override
  String get stabilityBreakdownConqueredCities => 'Conquered cities';

  @override
  String get stabilityBreakdownWarWeariness => 'War weariness';

  @override
  String get stabilityBreakdownHegemony => 'Hegemony pressure';

  @override
  String get stabilityBreakdownRelativeStanding => 'Relative standing';

  @override
  String topResourceResourcesTooltip(int resourceTotal, int resourceTypes) {
    return 'Ressourcen: $resourceTotal Vorkommen • $resourceTypes kontrollierte Typen';
  }

  @override
  String topResourceGoldTooltip(
    int gold,
    int goldIncome,
    int unitUpkeep,
    String net,
  ) {
    return 'Gold: $gold • Einkommen +$goldIncome • Unterhalt -$unitUpkeep • Netto $net / Zug';
  }

  @override
  String topResourceGoldTooltipNegativeTreasury(String base) {
    return '$base • Schatzkammer unter null';
  }

  @override
  String topResourceGoldTooltipBankruptcy(String base) {
    return '$base • Insolvenzrisiko innerhalb von 3 Zügen';
  }

  @override
  String get resourceBreakdownTreasury => 'Schatzkammer';

  @override
  String get resourceBreakdownCityIncome => 'Stadteinkommen';

  @override
  String get resourceBreakdownUpkeep => 'Unterhalt';

  @override
  String get resourceBreakdownNetPerTurn => 'Netto / Zug';

  @override
  String get resourceBreakdownNoCityIncome => 'Kein Stadteinkommen';

  @override
  String get resourceBreakdownFreeLimit => 'Freigrenze';

  @override
  String get resourceBreakdownNextWorkerUpkeep =>
      'Unterhalt des nächsten Arbeiters';

  @override
  String resourceBreakdownNextWorkerUpkeepValue(int upkeep) {
    return '-$upkeep Gold/Zug';
  }

  @override
  String get resourceBreakdownInsideFreeLimit => 'Innerhalb der Freigrenze';

  @override
  String get resourceBreakdownNoActiveTechnology =>
      'Keine Technologie ausgewählt';

  @override
  String get resourceBreakdownScienceTitle => 'Wissenschaft und Forschung';

  @override
  String get resourceBreakdownSciencePerTurn => 'Wissenschaft / Zug';

  @override
  String get resourceBreakdownActiveResearch => 'Aktive Forschung';

  @override
  String get resourceBreakdownTurnsToComplete => 'Bis Abschluss';

  @override
  String get resourceBreakdownNoScienceSources => 'Keine Wissenschaftsquellen';

  @override
  String resourceBreakdownCityResearchProject(String cityName) {
    return '$cityName: Forschung';
  }

  @override
  String get resourceBreakdownNoControlledResources =>
      'Keine kontrollierten Ressourcen';

  @override
  String get resourceBreakdownGrowCitiesWithFood =>
      'Städte mit Nahrung wachsen lassen';

  @override
  String get resourceBreakdownControlledDeposits => 'Kontrollierte Vorkommen';

  @override
  String get resourceBreakdownResourceTypes => 'Ressourcentypen';

  @override
  String get resourceBreakdownTypesSection => 'Typen';

  @override
  String get resourceBreakdownSourcesSection => 'Quellen';

  @override
  String get technologyRecommendationsTitle => 'Empfohlene Forschung';

  @override
  String get technologyShowTreeAction => 'Baum anzeigen';

  @override
  String technologyShowTreeCountAction(int count) {
    return 'Baum anzeigen ($count)';
  }

  @override
  String get technologyRecommendationUnlocks => 'Schaltet frei';

  @override
  String get technologyRecommendationReasonBoost =>
      'Aktiver Boost senkt die Forschungskosten.';

  @override
  String get technologyRecommendationReasonSection => 'Warum jetzt';

  @override
  String get technologyRecommendationReasonImprovements =>
      'Neue Feldverbesserungen verwandeln Ressourcen schnell in Ertrag.';

  @override
  String get technologyRecommendationReasonBuilding =>
      'Ein neues Stadtgebäude eröffnet eine weitere Entwicklungsrichtung.';

  @override
  String get technologyRecommendationReasonUnit =>
      'Eine neue Einheit stärkt Sicherheit und Kartenkontrolle.';

  @override
  String get technologyRecommendationReasonEffect =>
      'Ein dauerhafter Bonus gilt für die gesamte Wirtschaft.';

  @override
  String get technologyRecommendationReasonFast =>
      'Schnelle Forschung ohne zusätzliche Voraussetzungen.';

  @override
  String get technologyRecommendationReasonDefault =>
      'Verfügbare Forschung, die den nächsten Schritt sauber abschließt.';

  @override
  String get technologyNoRecommendations =>
      'Derzeit ist keine neue Forschung verfügbar.';

  @override
  String get technologyFullTreeTitle => 'Vollständiger Technologiebaum';

  @override
  String get technologyRecommendationsBackAction => 'Empfehlungen';

  @override
  String get empireUnitsEmptyTitle => 'Keine Einheiten';

  @override
  String get empireUnitsEmptyBody =>
      'Neue Einheiten erscheinen hier nach Stadtproduktion oder Ereignisrekrutierung.';

  @override
  String get empireCitiesEmptyTitle => 'Keine Städte';

  @override
  String get empireCitiesEmptyBody =>
      'Gründe deine erste Stadt mit einem Siedler, um Produktion, Wissenschaft und Imperiumsgrenzen freizuschalten.';

  @override
  String get empireCityCenters => 'Stadtzentren';

  @override
  String get empireShowFirstUnitTooltip =>
      'Erste Einheit auf der Karte anzeigen';

  @override
  String get empireShowUnitTooltip => 'Einheit auf der Karte anzeigen';

  @override
  String get empireShowFirstCityTooltip => 'Erste Stadt auf der Karte anzeigen';

  @override
  String get empireShowCityTooltip => 'Stadt auf der Karte anzeigen';

  @override
  String empireUnitCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einheiten',
      one: '1 Einheit',
    );
    return '$_temp0';
  }

  @override
  String empireCityCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Städte',
      one: '1 Stadt',
    );
    return '$_temp0';
  }

  @override
  String empireUnitMovement(int movement) {
    return 'Bewegung $movement';
  }

  @override
  String get empireUnitBuilding => 'Baut';

  @override
  String get empireUnitWorking => 'Arbeitet';

  @override
  String get empireUnitFortifying => 'Befestigt';

  @override
  String get empireUnitHealing => 'Heilt';

  @override
  String get empireUnitEnRoute => 'Unterwegs';

  @override
  String get empireUnitNoMovement => 'keine Bewegung';

  @override
  String empireUnitsWithMovement(int count) {
    return '$count mit Bewegung';
  }

  @override
  String empireCitySubtitle(
    int population,
    int hexes,
    int buildings,
    String production,
  ) {
    return 'Bevölkerung $population - $hexes Felder - $buildings Geb. - produziert: $production';
  }

  @override
  String empireCityStoredArtifact(String artifactName) {
    return 'Artefakt: $artifactName';
  }

  @override
  String empireCityGroupSubtitle(String cityLabel, int population) {
    return '$cityLabel - Bevölkerung $population';
  }

  @override
  String get empireStatsTitle => 'Imperiumsstatus';

  @override
  String get empireStatsSubtitle =>
      'Ein schneller Überblick über Bereitschaft, Zusammensetzung und Stadtwachstum';

  @override
  String get empireStatsReadinessTitle => 'Einheitsbereitschaft';

  @override
  String get empireStatsUnitCompositionTitle => 'Einheitszusammensetzung';

  @override
  String get empireStatsCityDevelopmentTitle => 'Stadtentwicklung';

  @override
  String get empireStatsCityComparisonTitle => 'Stadtvergleich';

  @override
  String get empireStatsOrders => 'Mit Befehlen';

  @override
  String get empireStatsNoMovement => 'Keine Bewegung';

  @override
  String get empireStatsAveragePopulation => 'Ø Bev.';

  @override
  String get empireStatsTotalBuildings => 'Gebäude';

  @override
  String get empireStatsStoredArtifacts => 'Artefakte';

  @override
  String get empireStatsTerritory => 'Gebiet';

  @override
  String get empireStatsCitiesProducing => 'Produktion';

  @override
  String get empireStatsOther => 'Sonstiges';

  @override
  String get empireStatsEmptyUnits => 'Keine Einheiten zur Analyse';

  @override
  String get empireStatsEmptyCities => 'Keine Städte zur Analyse';

  @override
  String empireStatsCityBarDetail(int population, int buildings) {
    return 'Bev. $population • Geb. $buildings';
  }

  @override
  String empireStatsCityComparisonDetail(
    int population,
    int production,
    int food,
    int gold,
  ) {
    return 'Bev. $population • Prod. $production • Nahrung $food • Gold $gold';
  }

  @override
  String get empireStatsMetricPopulation => 'Bev.';

  @override
  String get empireStatsMetricProduction => 'Prod.';

  @override
  String get empireStatsMetricFood => 'Nahrung';

  @override
  String get empireStatsMetricGold => 'Gold';

  @override
  String get activityLogTitle => 'Aktivitätsprotokoll';

  @override
  String get activityLogShowAllAction => 'Alle anzeigen';

  @override
  String activityLogShowMoreAction(int visible, int total) {
    return 'Mehr anzeigen ($visible/$total)';
  }

  @override
  String get activityLogLoadingHistory =>
      'Vollständiger Verlauf wird geladen...';

  @override
  String get activityLogHistoryErrorTitle =>
      'Verlauf konnte nicht geladen werden';

  @override
  String activityLogHistoryErrorBody(String error) {
    return 'Das Ereignisjournal ist nicht verfügbar: $error';
  }

  @override
  String get activityLogFilterAll => 'Alle';

  @override
  String get activityLogFilterAllShort => 'Alle';

  @override
  String get activityLogFilterCombat => 'Kampf';

  @override
  String get activityLogFilterCities => 'Städte';

  @override
  String get activityLogFilterDiplomacy => 'Diplomatie';

  @override
  String get activityLogFilterDiplomacyShort => 'Dipl.';

  @override
  String get activityLogFilterTechnology => 'Wissenschaft';

  @override
  String get activityLogEmptyAllTitle => 'Keine Ereignisse aufgezeichnet';

  @override
  String get activityLogEmptyCombatTitle => 'Keine Kämpfe aufgezeichnet';

  @override
  String get activityLogEmptyCityTitle => 'Keine Stadtereignisse aufgezeichnet';

  @override
  String get activityLogEmptyDiplomacyTitle => 'Keine Diplomatie aufgezeichnet';

  @override
  String get activityLogEmptyTechnologyTitle =>
      'Keine Entdeckungen aufgezeichnet';

  @override
  String get activityLogEmptyAllBody =>
      'Erste Entdeckungen, Kämpfe und Bauvorhaben erscheinen hier, nachdem du Aktionen spielst.';

  @override
  String get activityLogEmptyCombatBody =>
      'Kämpfe werden nach Angriffen oder Verteidigungen aufgezeichnet, die für den Spieler sichtbar sind.';

  @override
  String get activityLogEmptyCityBody =>
      'Gegründete Städte, Bauvorhaben und beanspruchte Felder erstellen hier die Zeitleiste des Imperiums.';

  @override
  String get activityLogEmptyDiplomacyBody =>
      'Depeschen, Vorschläge, Antworten und Beziehungsänderungen erscheinen hier nach diplomatischen Aktionen.';

  @override
  String get activityLogEmptyTechnologyBody =>
      'Entdeckte Technologien erscheinen hier, nachdem die Forschung abgeschlossen ist.';

  @override
  String get turnTimelineTitle => 'Zugzeitleiste';

  @override
  String turnTimelineSubtitle(int turn, int count) {
    return 'Zug $turn • Ereignisse: $count';
  }

  @override
  String get turnTimelineChartTitle => 'Ereignisse über Züge hinweg';

  @override
  String get turnTimelineMetricEvents => 'Ereignisse';

  @override
  String get turnTimelineMetricActiveTurns => 'Aktive Züge';

  @override
  String get turnTimelineMetricCurrentTurn => 'Aktueller Zug';

  @override
  String get technologyDiscoveryEyebrow => 'Technologie entdeckt';

  @override
  String unitSelectionMovementSubtitle(int current, int max) {
    return 'Bewegung $current/$max';
  }

  @override
  String unitSelectionMovementHpSubtitle(
    int current,
    int max,
    int hp,
    int maxHp,
  ) {
    return 'Bewegung $current/$max • LP $hp/$maxHp';
  }

  @override
  String get unitSelectionAttackLabel => 'Angriff';

  @override
  String get unitSelectionDefenseLabel => 'Verteidigung';

  @override
  String get unitSelectionHpLabel => 'LP';

  @override
  String get unitSelectionRangeLabel => 'Reichweite';

  @override
  String get unitSelectionConstructionLabel => 'Bau';

  @override
  String get unitSelectionWorkLabel => 'Arbeit';

  @override
  String get unitSelectionFieldBonusValue => 'Feldbonus';

  @override
  String get tileSelectionYieldTitle => 'Feldpotenzial';

  @override
  String get tileSelectionYieldTooltip =>
      'Schätzung bei der Prüfung dieses Feldes, nicht der tatsächliche Stadtertrag.';

  @override
  String get tileSelectionBonusLabel => 'Bonus';

  @override
  String get tileSelectionDefenseBonusValue => '+Verteidigung';

  @override
  String get tileSelectionRiverBonusValue => '+Fluss';

  @override
  String get citySelectionYieldTitle => 'Stadteinkommen';

  @override
  String get citySelectionYieldTooltip =>
      'Tatsächlicher Stadtertrag pro Zug aus der Stadtwirtschaft.';

  @override
  String citySelectionSubtitle(
    int population,
    int territoryHexCount,
    int maxHexes,
    String production,
  ) {
    return 'Bevölkerung $population • $territoryHexCount/$maxHexes Felder • Produktion: $production';
  }

  @override
  String get citySelectionTerritoryLabel => 'Gebiet';

  @override
  String get citySelectionFoodLabel => 'Nahrung';

  @override
  String get citySelectionNetFoodLabel => 'Nettonahrung';

  @override
  String get citySelectionBuildingsLabel => 'Gebäude';

  @override
  String get citySelectionCohesionLabel => 'Cohesion';

  @override
  String get citySelectionCohesionCore => 'Core';

  @override
  String citySelectionCohesionIntegrated(int distance) {
    return 'Integrated • $distance hexes from core';
  }

  @override
  String citySelectionCohesionFrontier(int distance, int cost) {
    return 'Frontier • $distance hexes • -$cost stability';
  }

  @override
  String get citySelectionArtifactLabel => 'Artefakt';

  @override
  String get worldArtifactBonusTitle => 'Bonus';

  @override
  String get worldArtifactHeritageTitle => 'Erbe';

  @override
  String get worldArtifactHeritageBody =>
      'Sammle und platziere 6 einzigartige Artefakte in deinen Städten und halte die Sammlung dann 5 Züge lang.';

  @override
  String get worldArtifactAncientImperialCrown => 'Alte Kaiserkrone';

  @override
  String get worldArtifactAstronomersTablets => 'Tafeln der Astronomen';

  @override
  String get worldArtifactProphetMask => 'Maske des Propheten';

  @override
  String get worldArtifactHeroSword => 'Schwert des Helden';

  @override
  String get worldArtifactMerchantsSeal => 'Siegel des Kaufmanns';

  @override
  String get worldArtifactFirstPeoplesChronicle => 'Chronik der ersten Völker';

  @override
  String get worldArtifactTempleReliquary => 'Tempelreliquiar';

  @override
  String get worldArtifactQueensMirror => 'Spiegel der Königin';

  @override
  String get worldArtifactAncientImperialCrownShortBonus => '+1 Verteidigung';

  @override
  String get worldArtifactAstronomersTabletsShortBonus => '+1 Wissenschaft';

  @override
  String get worldArtifactProphetMaskShortBonus => '+1 Gold, Diplomatie';

  @override
  String get worldArtifactHeroSwordShortBonus =>
      '+2 EP für produzierte Einheiten';

  @override
  String get worldArtifactMerchantsSealShortBonus => '+2 Gold';

  @override
  String get worldArtifactFirstPeoplesChronicleShortBonus => '+1 Nahrung';

  @override
  String get worldArtifactTempleReliquaryShortBonus =>
      '+1 Nahrung, +1 Verteidigung';

  @override
  String get worldArtifactQueensMirrorShortBonus => '+1 Gold, Diplomatie';

  @override
  String get worldArtifactAncientImperialCrownDescription =>
      'Ein Symbol alter Herrschaft. In einer Stadt gelagert, stärkt es die Verteidigung und das Prestige der Sammlung.';

  @override
  String get worldArtifactAstronomersTabletsDescription =>
      'Steintafeln mit alten Karten des Himmels. In einer Stadt unterstützen sie die Wissenschaft.';

  @override
  String get worldArtifactProphetMaskDescription =>
      'Eine rituelle Maske von großem politischem Gewicht. In einer Stadt gewährt sie Gold und diplomatischen Wert.';

  @override
  String get worldArtifactHeroSwordDescription =>
      'Die Waffe eines legendären Kommandanten. Einheiten, die in dieser Stadt produziert werden, erhalten zusätzliche Erfahrung.';

  @override
  String get worldArtifactMerchantsSealDescription =>
      'Das Zeichen der ersten Kaufmannsgilden. In einer Stadt stärkt es das Goldeinkommen.';

  @override
  String get worldArtifactFirstPeoplesChronicleDescription =>
      'Eine Aufzeichnung der ältesten Abstammungslinien und Grenzen. In einer Stadt unterstützt sie Wachstum.';

  @override
  String get worldArtifactTempleReliquaryDescription =>
      'Ein heiliges Reliquiar, das der Stadt Stabilität, Nahrung und Verteidigung gibt.';

  @override
  String get worldArtifactQueensMirrorDescription =>
      'Ein Hofschatz, der Handel mit Diplomatie verbindet. In einer Stadt gewährt er Gold und Prestige.';

  @override
  String get worldArtifactLocationMap => 'Artefakt auf der Karte';

  @override
  String get worldArtifactLocationExcavation => 'Ausgrabung läuft';

  @override
  String get worldArtifactLocationCarried => 'Von einer Einheit getragen';

  @override
  String get worldArtifactLocationStored => 'In einer Stadt gelagert';

  @override
  String get worldArtifactStepExcavate => 'Ausgraben';

  @override
  String get worldArtifactStepMove => 'Bewegen';

  @override
  String get worldArtifactStepStore => 'Lagern';

  @override
  String get artifactGuidanceUnknownCityName => 'eine Stadt';

  @override
  String get artifactGuidanceStoredTitle => 'Artefakt gelagert';

  @override
  String artifactGuidanceStoredBody(String artifactName, String cityName) {
    return '$artifactName stärkt $cityName. Für den Kultursieg brauchst du 6 Artefakte in Städten für 5 Züge.';
  }

  @override
  String get artifactGuidanceCarriedTitle => 'Artefakt getragen';

  @override
  String artifactGuidanceCarriedBody(String artifactName) {
    return 'Die Einheit trägt $artifactName. Bringe es in eine deiner Städte mit freiem Platz und nutze die Lagern-Aktion.';
  }

  @override
  String get artifactGuidanceReachedTitle => 'Artefakt entdeckt';

  @override
  String artifactGuidanceReachedBody(String artifactName) {
    return '$artifactName liegt unter der Einheit. Nutze die Ausgrabungsaktion, um es aufzunehmen.';
  }

  @override
  String get citySelectionSpecializationLabel => 'Spezialisierung';

  @override
  String get fieldImprovementOutsideActiveCity => 'Außerhalb der aktiven Stadt';

  @override
  String get fieldImprovementYieldTitle => 'Verbesserungsbonus';

  @override
  String get fieldImprovementYieldTooltip =>
      'Zusätzlicher Ertrag durch die Feldverbesserung.';

  @override
  String get hexKindIdealCitySite => 'Idealer Stadtstandort';

  @override
  String get hexKindGoodCitySite => 'Guter Stadtstandort';

  @override
  String get hexKindFertileField => 'Fruchtbares Feld';

  @override
  String get hexKindFertilePlains => 'Fruchtbare Ebenen';

  @override
  String get hexKindRichPlain => 'Reiche Ebene';

  @override
  String get hexKindStrategicBorderland => 'Strategisches Grenzland';

  @override
  String get hexKindStrategicField => 'Strategisches Feld';

  @override
  String get hexKindDefensivePosition => 'Verteidigungsposition';

  @override
  String get hexKindFertileForest => 'Fruchtbarer Wald';

  @override
  String get hexKindForestBackline => 'Wald-Hinterland';

  @override
  String get hexKindForestForge => 'Waldschmiede';

  @override
  String get hexKindWildLand => 'Wildes Land';

  @override
  String get hexKindRichWilds => 'Reiche Wildnis';

  @override
  String get hexKindExoticBackline => 'Exotisches Hinterland';

  @override
  String get hexKindDifficultStrategicTerrain =>
      'Schwieriges strategisches Gelände';

  @override
  String get hexKindHighGround => 'Hochland';

  @override
  String get hexKindRiverHills => 'Flusshügel';

  @override
  String get hexKindIndustrialStronghold => 'Industrielle Hochburg';

  @override
  String get hexKindRichHills => 'Reiche Hügel';

  @override
  String get hexKindBarrenLand => 'Karges Land';

  @override
  String get hexKindOasis => 'Oase';

  @override
  String get hexKindTradeOasis => 'Handelsoase';

  @override
  String get hexKindDesertDeposits => 'Wüstenvorkommen';

  @override
  String get hexKindHarshLand => 'Raues Land';

  @override
  String get hexKindColdPastures => 'Kalte Weiden';

  @override
  String get hexKindResourceOutpost => 'Ressourcenaußenposten';

  @override
  String get hexKindHostileLand => 'Feindliches Land';

  @override
  String get hexKindArcticDeposits => 'Arktische Vorkommen';

  @override
  String get hexKindCoast => 'Küste';

  @override
  String get hexKindFishingCoast => 'Fischerküste';

  @override
  String get hexKindRichCoast => 'Reiche Küste';

  @override
  String get hexKindRiverPort => 'Flusshafen';

  @override
  String get hexKindRegionalPortHeart => 'Regionales Hafenzentrum';

  @override
  String get hexKindOpenSea => 'Offene See';

  @override
  String get hexKindNaturalBarrier => 'Natürliche Barriere';

  @override
  String get hexKindPromisingLand => 'Vielversprechendes Land';

  @override
  String get hexKindWeakLand => 'Schwaches Land';

  @override
  String get hexKindOrdinaryLand => 'Gewöhnliches Land';

  @override
  String get hexKindMapTile => 'Kartenfeld';

  @override
  String get hexKindIdealCitySiteDescription =>
      'Ein Siedlungsfeld von hohem Wert mit Nahrung, Wachstum und Expansionsdruck bereits in guter Lage.';

  @override
  String get hexKindGoodCitySiteDescription =>
      'Solides Gelände für ein Stadtzentrum mit genug Grundwert, um frühes Wachstum zu unterstützen.';

  @override
  String get hexKindFertileFieldDescription =>
      'Flussgespeistes Grasland, das Nahrung, Bevölkerungswachstum und Arbeiterverbesserungen begünstigt.';

  @override
  String get hexKindFertilePlainsDescription =>
      'Offene Ebenen mit Flussunterstützung, nützlich für ausgewogene Nahrung und Produktion.';

  @override
  String get hexKindRichPlainDescription =>
      'Ein wertvolles offenes Feld mit Luxus- oder Handelswert, das in die Grenzen aufgenommen werden sollte.';

  @override
  String get hexKindStrategicBorderlandDescription =>
      'Gutes Land mit strategischem Wert, nützlich für Expansion, bevor Rivalen es beanspruchen.';

  @override
  String get hexKindStrategicFieldDescription =>
      'Ein Ebenenfeld, das mit strategischen Ressourcen oder Druck an der Grenze verbunden ist.';

  @override
  String get hexKindDefensivePositionDescription =>
      'Gelände, das defensive Kontrolle verbessert und hilft, nahe Zugänge zu halten.';

  @override
  String get hexKindFertileForestDescription =>
      'Ein Wald mit Flussunterstützung, der Wachstumspotenzial mit natürlicher Deckung verbindet.';

  @override
  String get hexKindForestBacklineDescription =>
      'Ein sichereres Waldfeld, das Wachstum oder jagdorientierte Verbesserungen unterstützen kann.';

  @override
  String get hexKindForestForgeDescription =>
      'Wald mit industriellem Ressourcenwert, vielversprechend für Produktion nach Verbesserung.';

  @override
  String get hexKindWildLandDescription =>
      'Dichtes Gelände mit Reibung; nur nützlich, wenn du einen klaren Arbeiter- oder Expansionsplan hast.';

  @override
  String get hexKindRichWildsDescription =>
      'Wildes Gelände mit genug Fruchtbarkeit oder Ressourcen, um sorgfältige Entwicklung zu rechtfertigen.';

  @override
  String get hexKindExoticBacklineDescription =>
      'Ein Dschungel- oder Feuchtgebietsfeld mit Luxuswert für spätere Grenzen und Handel.';

  @override
  String get hexKindDifficultStrategicTerrainDescription =>
      'Schwieriges Gelände mit strategischem Ressourcenwert; später mächtig, früh aber umständlich.';

  @override
  String get hexKindHighGroundDescription =>
      'Hügel, die Verteidigung und Kartenkontrolle stärker begünstigen als schnelles Wachstum.';

  @override
  String get hexKindRiverHillsDescription =>
      'Hügel an einem Fluss, die Verteidigung mit besserem wirtschaftlichem Potenzial verbinden.';

  @override
  String get hexKindIndustrialStrongholdDescription =>
      'Hügel mit industriellen Ressourcen, ein starkes Produktionsziel für eine Stadt.';

  @override
  String get hexKindRichHillsDescription =>
      'Hügel mit Wohlstandsressourcen, nützlich für gold- oder produktionsorientierte Expansion.';

  @override
  String get hexKindBarrenLandDescription =>
      'Trockenes Land mit geringem unmittelbarem Wert, sofern spätere Technologie oder Grenzen den Plan nicht ändern.';

  @override
  String get hexKindOasisDescription =>
      'Durch Flusszugang gemilderte Wüste, die schwaches Land in ein nutzbares Wachstumsfeld verwandelt.';

  @override
  String get hexKindTradeOasisDescription =>
      'Eine Handelsnische in der Wüste, die mit der richtigen Verbesserung wertvoll werden kann.';

  @override
  String get hexKindDesertDepositsDescription =>
      'Schlechtes Siedlungsland mit einem strategischen Vorkommen, das in späteren Ären wichtiger wird.';

  @override
  String get hexKindHarshLandDescription =>
      'Kaltes oder raues Land mit begrenzter früher Wirtschaft und langsamer Entwicklung.';

  @override
  String get hexKindColdPasturesDescription =>
      'Kaltes Gelände mit genug Weidewert, um eine Grenzstadt zu unterstützen.';

  @override
  String get hexKindResourceOutpostDescription =>
      'Abgelegenes kaltes Land, das vor allem wegen der geschützten Ressource beansprucht werden sollte.';

  @override
  String get hexKindHostileLandDescription =>
      'Unfreundlicher Boden mit schwachem Siedlungswert und wenigen unmittelbaren Erträgen.';

  @override
  String get hexKindArcticDepositsDescription =>
      'Schneebedecktes Ressourcenland, schwer zu nutzen, aber strategisch potenziell wichtig.';

  @override
  String get hexKindCoastDescription =>
      'Küstenland, das Marinezugang und flexibles Stadtwachstum eröffnet.';

  @override
  String get hexKindFishingCoastDescription =>
      'Küste mit Nahrungswert, ein starker Grund, am Wasser zu arbeiten oder zu siedeln.';

  @override
  String get hexKindRichCoastDescription =>
      'Küstenluxus oder Handelswert, der in Stadtgrenzen aufgenommen werden sollte.';

  @override
  String get hexKindRiverPortDescription =>
      'Eine Flussmündung mit Handels- und Bewegungswert für eine Küstenstadt.';

  @override
  String get hexKindRegionalPortHeartDescription =>
      'Ein starkes Küstenzentrum, in dem Fluss- und Ressourcenwert zusammenkommen.';

  @override
  String get hexKindOpenSeaDescription =>
      'Wasser, das für Schiffe und Erkundung nützlich ist, aber nicht für Landsiedlungen.';

  @override
  String get hexKindNaturalBarrierDescription =>
      'Blockiertes Gelände, das Bewegung und Verteidigung statt Wirtschaft formt.';

  @override
  String get hexKindPromisingLandDescription =>
      'Ein allgemein nützliches Feld mit genug Wert, um es vor dem Weiterziehen zu prüfen.';

  @override
  String get hexKindWeakLandDescription =>
      'Gelände mit geringem Ertrag, das frühe Arbeiterzeit selten verdient.';

  @override
  String get hexKindOrdinaryLandDescription =>
      'Ein normales Feld ohne herausragende Stärke, nützlich, wenn es zum Stadtplan passt.';

  @override
  String get hexKindMapTileDescription =>
      'Ein einfaches Kartenfeld ohne genug Informationen für ein starkes Urteil.';

  @override
  String get hexTagCity => 'Stadtstandort';

  @override
  String get hexTagDefense => 'Verteidigungsposition';

  @override
  String get hexTagTrade => 'Handelsroute';

  @override
  String get hexTagFertile => 'Fruchtbares Feld';

  @override
  String get hexTagProduction => 'Gute Produktion';

  @override
  String get hexTagHostile => 'Feindliches Land';

  @override
  String get hexTagStrategic => 'Strategische Ressource';

  @override
  String get hexTagWater => 'Wasserpassage';

  @override
  String get hexRecommendationFoundCity => 'Guter Entwicklungsstandort';

  @override
  String get hexRecommendationDefendHere => 'Gute Verteidigungsposition';

  @override
  String get hexRecommendationExploitEconomy => 'Ausbeutung lohnt sich';

  @override
  String get hexRecommendationAvoid => 'Ohne Plan vermeiden';

  @override
  String get hexRecommendationNeutral => 'Vor Bewegung prüfen';

  @override
  String get hexRecommendationFoundCityDetail =>
      'Wenn Grenzen frei sind, erwäge hier eine Gründung oder lenke einen Siedler hierher.';

  @override
  String get hexRecommendationDefendHereDetail =>
      'Nutze es, um Einheiten zu verankern, Grenzen zu schützen oder nahe Städte abzudecken.';

  @override
  String get hexRecommendationExploitEconomyDetail =>
      'Nimm es in die Grenzen auf und weise einen Arbeiter zu, wenn die Stadt profitieren kann.';

  @override
  String get hexRecommendationAvoidDetail =>
      'Überspringe es früh, sofern Ressource, Route oder militärischer Bedarf den Wert nicht ändern.';

  @override
  String get hexRecommendationNeutralDetail =>
      'Erkunde Nachbarfelder und vergleiche Ressourcen, bevor du einen Arbeiter oder Siedler bindest.';

  @override
  String get selectionActionLockedReason =>
      'Du kannst jetzt keine Befehle erteilen.';

  @override
  String get selectionActionFoundCity => 'Stadt gründen';

  @override
  String get selectionActionCancel => 'Abbrechen';

  @override
  String get selectionActionCancelAttack => 'Angriff abbrechen';

  @override
  String get selectionActionCancelWorkerBuild => 'Verbesserung abbrechen';

  @override
  String get selectionActionCancelCityFounding => 'Stadtgründung abbrechen';

  @override
  String get selectionActionCancelAutoExplore => 'Erkundung abbrechen';

  @override
  String get selectionActionCancelArtifactExcavation =>
      'Artefaktausgrabung abbrechen';

  @override
  String get selectionActionCancelTradeRouteSelection =>
      'Handelsroutenauswahl abbrechen';

  @override
  String get selectionActionCancelMerchantMoveToCity =>
      'Weg zur Stadt abbrechen';

  @override
  String get selectionActionCancelCommanderMerge =>
      'Truppenzusammenführung abbrechen';

  @override
  String get selectionActionConfirm => 'Bestätigen';

  @override
  String selectionActionConfirmWithTurns(String turns) {
    return 'Bestätigen ($turns)';
  }

  @override
  String get selectionActionMinimize => 'Minimieren';

  @override
  String get selectionActionConfirmAttack => 'Angriff bestätigen';

  @override
  String get selectionActionCaptureCity => 'Stadt erobern';

  @override
  String get selectionActionDestroyCity => 'Stadt zerstören';

  @override
  String get selectionActionStopFortifying => 'Befestigen stoppen';

  @override
  String get selectionActionStopHealing => 'Heilung stoppen';

  @override
  String get selectionActionMove => 'Bewegen';

  @override
  String get selectionActionAttack => 'Angriff';

  @override
  String get selectionActionAutoExplore => 'Erkunden';

  @override
  String get selectionActionTradeRoute => 'Handelsroute';

  @override
  String selectionActionTradeRouteToCity(String cityName) {
    return 'Mit $cityName handeln';
  }

  @override
  String get selectionActionMerchantMoveToCity => 'Zur Stadt gehen';

  @override
  String selectionActionMerchantMoveToCityTarget(String cityName) {
    return 'Zu $cityName gehen';
  }

  @override
  String get selectionActionArmy => 'Armee';

  @override
  String get selectionArmyEmpty => 'Keine Truppen';

  @override
  String selectionTroopDetachTooltip(String troop) {
    return '$troop abtrennen';
  }

  @override
  String get selectionActionImprove => 'Verbessern';

  @override
  String get selectionActionSkip => 'Überspringen';

  @override
  String get selectionActionFortify => 'Befestigen';

  @override
  String get selectionActionHeal => 'Heilen';

  @override
  String get selectionActionCancelCityGrowth => 'Wachstum abbrechen';

  @override
  String get selectionActionCityGrowth => 'Stadtwachstum';

  @override
  String get selectionActionProduction => 'Produktion';

  @override
  String get selectionActionExcavateArtifact => 'Ausgraben';

  @override
  String get selectionActionStoreArtifact => 'Lagern';

  @override
  String get selectionActionCancelCurrentMoveFirst =>
      'Brich zuerst die aktuelle Bewegung ab.';

  @override
  String get selectionActionArtifactAlreadyCarried =>
      'Die Einheit trägt bereits ein Artefakt.';

  @override
  String get selectionActionStoreArtifactOwnCityRequired =>
      'Bewege dich in eine deiner Städte.';

  @override
  String get selectionActionStoreArtifactCityOccupied =>
      'Diese Stadt lagert bereits ein Artefakt.';

  @override
  String get selectionActionNoBuildAvailable =>
      'Auf diesem Feld ist kein Bau verfügbar.';

  @override
  String get selectionActionUnitWorking => 'Die Einheit arbeitet bereits.';

  @override
  String get selectionActionUnitFortified => 'Die Einheit ist befestigt.';

  @override
  String get selectionActionUnitHealing => 'Die Einheit heilt.';

  @override
  String get selectionActionNoMovement =>
      'In diesem Zug sind keine Bewegungspunkte mehr übrig.';

  @override
  String get selectionActionNoAttack => 'Diese Einheit hat keinen Angriff.';

  @override
  String get selectionActionNoVisibleEnemy =>
      'Kein sichtbarer Gegner in Reichweite.';

  @override
  String get selectionActionMerchantNoOriginCity =>
      'Bewege den Händler in eine deiner Städte.';

  @override
  String get selectionActionMerchantNoDestinationCity =>
      'Du brauchst eine zweite verbundene Stadt.';

  @override
  String get selectionActionMerchantNoRoute =>
      'Keine Handelsroute kann diese Stadt erreichen.';

  @override
  String get selectionActionMerchantNoCityPath =>
      'Der Händler kann diese Stadt nicht erreichen.';

  @override
  String get selectionActionCannotFoundCityHere =>
      'Hier kann keine Stadt gegründet werden.';

  @override
  String get selectionActionFoundCityNoCommander =>
      'Nur ein Siedler oder ein Kommandant mit Siedlern kann eine Stadt gründen.';

  @override
  String get selectionActionFoundCityNoSettlers =>
      'Siedler sind erforderlich, um eine Stadt zu gründen.';

  @override
  String get selectionActionFoundCityInvalidCenter =>
      'Auf diesem Feld kann keine Stadt gegründet werden.';

  @override
  String get selectionActionFoundCityCityAlreadyExists =>
      'Auf diesem Feld gibt es bereits eine Stadt.';

  @override
  String get selectionActionFoundCityCenterOccupied =>
      'Dieses Feld gehört bereits zu einer Stadt.';

  @override
  String get selectionActionFoundCityTooCloseToCity =>
      'Eine Stadt kann nicht direkt neben einer anderen Stadt gegründet werden.';

  @override
  String get selectionActionFoundCityInvalidControlledHexes =>
      'Wähle zuerst gültige Stadtfelder.';

  @override
  String get selectionActionCannotImproveCityCenter =>
      'Im Stadtzentrum können keine Verbesserungen gebaut werden.';

  @override
  String get selectionActionTileAlreadyImproved =>
      'Dieses Feld hat bereits eine Verbesserung.';

  @override
  String get selectionActionTileMustBelongToCity =>
      'Das Feld muss zu einer Stadt gehören.';

  @override
  String get selectionActionNoWorkerTile => 'Kein Feld unter dem Arbeiter.';

  @override
  String get hudFeedbackNoTurnCostDetail =>
      'Aktion hat den Zug nicht verbraucht';

  @override
  String get hudFeedbackAutoExploreNoTargetTitle => 'Keine Erkundungsroute';

  @override
  String get hudFeedbackAutoExploreNoTargetBody =>
      'Der Späher hat in diesem Zug keine Bewegung, die neue Felder aufdecken würde.';

  @override
  String get hudFeedbackArtifactGuidanceTitle => 'Weltartefakt';

  @override
  String get hudFeedbackArtifactGuidanceBody =>
      'Bringe es in eine deiner Städte und platziere es in einem leeren Artefaktplatz.';

  @override
  String get hudFeedbackActionBlockedTitle => 'Aktion nicht verfügbar';

  @override
  String get hudFeedbackActionBlockedBody =>
      'Diese Aktion ist derzeit blockiert. Wähle ein anderes Feld oder einen anderen Befehl.';

  @override
  String get hudFeedbackAttackProtectedByTreatyTitle =>
      'Vertrag blockiert Angriff';

  @override
  String get hudFeedbackAttackProtectedByTreatyBody =>
      'Du kannst keine Einheit einer Zivilisation angreifen, mit der du ein Bündnis oder einen Waffenstillstand hast. Ändere zuerst die diplomatischen Beziehungen.';

  @override
  String get hudFeedbackMovementCityOccupiedTitle => 'Stadt besetzt';

  @override
  String get hudFeedbackMovementCityOccupiedBody =>
      'Nur eine Einheit kann in einer Stadt stehen. Bewege zuerst die Garnison hinaus oder wähle ein anderes Feld.';

  @override
  String get hudFeedbackMovementEnemyOccupiedTitle => 'Gegner auf diesem Feld';

  @override
  String get hudFeedbackMovementEnemyOccupiedBody =>
      'Du kannst ein gegnerisches Feld nicht mit einer normalen Bewegung betreten. Nutze Angriff oder wähle ein angrenzendes Feld.';

  @override
  String get hudFeedbackMovementForeignCityTitle => 'Fremde Stadt';

  @override
  String get hudFeedbackMovementForeignCityBody =>
      'Du kannst eine fremde Stadt nicht mit einer normalen Bewegung betreten. Nutze Angriff oder wähle ein anderes Feld.';

  @override
  String get hudFeedbackMovementHiddenRouteTooFarTitle => 'Route zu weit';

  @override
  String get hudFeedbackMovementHiddenRouteTooFarBody =>
      'Du kannst keine so lange Route durch unentdecktes Gelände planen. Wähle ein kürzeres Segment oder nutze die automatische Erkundung des Spähers.';

  @override
  String get hudFeedbackMovementBlockedTerrainTitle =>
      'Gelände blockiert Bewegung';

  @override
  String get hudFeedbackMovementBlockedTerrainBody =>
      'Diese Einheit kann diesen Geländetyp nicht betreten. Wähle ein anderes Feld oder eine Route darum herum.';

  @override
  String get hudFeedbackMovementInsufficientUnitMovementTitle =>
      'Nicht genug Bewegung';

  @override
  String get hudFeedbackMovementInsufficientUnitMovementBody =>
      'Diese Einheit hat nicht genug Bewegung, um dieses Gebiet zu betreten. Verbessere sie oder nutze eine andere Einheit.';

  @override
  String get hudFeedbackMovementNoRouteTitle => 'Keine Route';

  @override
  String get hudFeedbackMovementNoRouteBody =>
      'Es gibt keine verfügbare Route zu diesem Feld. Versuche ein näheres Ziel oder einen anderen Ansatz.';

  @override
  String selectionCommandUnavailableDescription(String label) {
    return 'Aktion „$label“ ist für die aktuelle Auswahl nicht verfügbar.';
  }

  @override
  String selectionCommandActiveDescription(String label) {
    return 'Aktion „$label“ ist ein aktiver Modus. Wähle ein Ziel auf der Karte oder brich den Modus ab, wenn du es dir anders überlegt hast.';
  }

  @override
  String selectionCommandProminentDescription(String label) {
    return 'Aktion „$label“ ist derzeit der wichtigste Befehl für diese Auswahl.';
  }

  @override
  String selectionCommandDefaultDescription(String label) {
    return 'Führt Aktion „$label“ für die aktuell ausgewählte Einheit, Stadt oder das Feld aus.';
  }

  @override
  String get selectionInfoChipDisabledDescription =>
      'Dieser Informationsbereich ist für die aktuelle Auswahl nicht verfügbar.';

  @override
  String selectionInfoChipOpenDescription(String label) {
    return 'Öffnet Details zu „$label“ für das aktuell ausgewählte Feld, die Einheit oder Stadt.';
  }

  @override
  String turnCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Züge',
      one: '1 Zug',
      zero: '0 Züge',
    );
    return '$_temp0';
  }

  @override
  String turnPillLabel(int turn) {
    return 'Z$turn';
  }

  @override
  String get turnEtaNoProgress => 'kein Fortschritt';

  @override
  String turnEtaDetailLabel(String turnsLabel, int turn) {
    return '$turnsLabel • Zug $turn';
  }

  @override
  String turnEtaTooltipNoTurn(String turnsLabel) {
    return '$turnsLabel bis Abschluss';
  }

  @override
  String turnEtaTooltipExpectedTurn(String turnsLabel, int turn) {
    return '$turnsLabel bis Abschluss • erwarteter Zug $turn';
  }

  @override
  String get modeBannerWorkedTilesTitle => 'Bearbeitete Felder';

  @override
  String get modeBannerWorkedTilesInstruction =>
      'Tippe auf kontrollierte Felder, um Stadtarbeit umzuschalten.';

  @override
  String get modeBannerCityGrowthTitle => 'Stadtwachstum';

  @override
  String get modeBannerCityGrowthInstructionSelected =>
      'Das ausgewählte Feld wird beim nächsten Stadtwachstum beansprucht. Bestätige es oder wähle ein anderes Feld.';

  @override
  String get modeBannerCityGrowthInstructionEmpty =>
      'Tippe auf ein umrandetes Feld, um das nächste Wachstums-Hex zu wählen. Ohne Wahl nutzt die Stadt ihre Empfehlung.';

  @override
  String get modeBannerWorkerActionTitle => 'Feldverbesserung';

  @override
  String get modeBannerWorkerActionInstructionPicked =>
      'Bestätige die Verbesserung im Arbeiter-Pop-up.';

  @override
  String get modeBannerWorkerActionInstructionEmpty =>
      'Wähle im Arbeiter-Pop-up einen Verbesserungstyp.';

  @override
  String get modeBannerMerchantTradeRouteTitle => 'Handelsroute';

  @override
  String get modeBannerMerchantTradeRouteInstruction =>
      'Wähle eine deiner Städte. Der Händler reist automatisch dorthin und kehrt nach der Ankunft um.';

  @override
  String get modeBannerMerchantMoveToCityTitle => 'Zur Stadt gehen';

  @override
  String get modeBannerMerchantMoveToCityInstruction =>
      'Wähle eine deiner Städte. Der Händler plant einen Weg zu ihrem Zentrum, ohne eine Handelsroute zu erstellen.';

  @override
  String workerActionSelectedImprovement(String title) {
    return 'Ausgewählt: $title';
  }

  @override
  String get workerActionSelectImprovement => 'Verbesserung wählen';

  @override
  String get workerActionBuildDetailTitle => 'Geländeverbesserung';

  @override
  String workerActionBuildImprovement(String title) {
    return '$title bauen';
  }

  @override
  String get workerActionSelectionHint =>
      'Klicke eine Verbesserung für dieses Feld an, prüfe Erträge und bestätige den Bau.';

  @override
  String get workerActionNoYieldChange => 'keine Ertragsänderung';

  @override
  String get modeBannerResearchSelectionTitle => 'Forschung wählen';

  @override
  String get modeBannerResearchSelectionInstruction =>
      'Öffne den Technologiebaum und wähle ein Forschungsziel, um den Zug fortzusetzen.';

  @override
  String get modeBannerUnitTurnSkipTitle => 'Zug übersprungen';

  @override
  String get modeBannerUnitTurnSkipInstruction =>
      'Die Einheit wartet bis zum nächsten Zug. Ihr Zustand ist in der unteren Leiste sichtbar.';

  @override
  String get modeBannerCommanderMergeTitle => 'Truppen zusammenführen';

  @override
  String get modeBannerCommanderMergeInstruction =>
      'Wähle eine befreundete Einheit, damit der Kommandant sie der Armee hinzufügt.';

  @override
  String get modeBannerAttackTargetingTitle => 'Angriff';

  @override
  String get modeBannerAttackTargetingInstructionSelected =>
      'Prüfe die Kampfprognose im Pop-up und bestätige den Angriff.';

  @override
  String get modeBannerAttackTargetingInstructionEmpty =>
      'Wähle einen Gegner in Reichweite oder sein Hex-Feld, um die Kampfprognose zu sehen.';

  @override
  String get modeBannerAttackRetreatProgress => 'Rückzug';

  @override
  String get modeBannerActionToolbarHint =>
      'Nutze bei Bedarf die untere Werkzeugleiste für Aktionen.';

  @override
  String get combatPreviewConfirmBody =>
      'Die ausgewählte Einheit greift sofort nach der Bestätigung an.';

  @override
  String get combatPreviewOutcomeLabel => 'Ergebnis';

  @override
  String get combatPreviewTargetLabel => 'Ziel';

  @override
  String get combatPreviewRetaliationLabel => 'Gegenschlag';

  @override
  String get combatPreviewStrengthLabel => 'Stärke';

  @override
  String get combatPreviewAttackerRole => 'Angreifer';

  @override
  String get combatPreviewDefenderRole => 'Verteidiger';

  @override
  String get combatPreviewCityRole => 'Stadt';

  @override
  String combatPreviewOutcomeLine(String outcome) {
    return 'Ergebnis: $outcome';
  }

  @override
  String get combatPreviewOutcomeCityFalls => 'Stadt fällt';

  @override
  String get combatPreviewOutcomeDefenderKilled => 'Verteidiger stirbt';

  @override
  String get combatPreviewOutcomeAttackerKilled =>
      'Angreifer stirbt im Gegenschlag';

  @override
  String get combatPreviewOutcomeDefenderRetreated =>
      'Verteidiger wird sich zurückziehen';

  @override
  String get combatPreviewOutcomeCitySurvives => 'Stadt überlebt';

  @override
  String get combatPreviewOutcomeDefenderSurvives => 'Verteidiger überlebt';

  @override
  String combatPreviewTargetLine(
    int hpBefore,
    int hpAfter,
    int hpMax,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Ziel: LP $hpBefore->$hpAfter/$hpMax, Angriff $attack gegen Verteidigung $defense (-$damage)';
  }

  @override
  String combatPreviewNoRetaliationLine(int distance, int range) {
    return 'Gegenschlag: keiner (Fernangriff, Distanz $distance, Reichweite $range)';
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
    return 'Gegenschlag: Angriff $attack gegen Verteidigung $defense (-$damage), LP $hpBefore->$hpAfter/$hpMax';
  }

  @override
  String combatPreviewHpDamageValue(
    int hpBefore,
    int hpAfter,
    int hpMax,
    int damage,
  ) {
    return '$hpBefore → $hpAfter/$hpMax LP, -$damage';
  }

  @override
  String get combatPreviewForecastTitle => 'Kampfprognose';

  @override
  String get combatPreviewNoHpLoss => 'kein Schaden';

  @override
  String combatPreviewHpAfterSemantics(int hpAfter, int hpMax, int loss) {
    return '$hpAfter von $hpMax LP nach dem Kampf, $loss LP verloren';
  }

  @override
  String combatPreviewStrengthValue(int attack, int defense) {
    return '$attack Angriff gegen $defense Verteidigung';
  }

  @override
  String get combatPreviewAdvantageTitle => 'Warum diese Prognose?';

  @override
  String combatPreviewAdvantageAttacker(
    String country,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Angriffsvorteil: $country hat $attack Angriff gegen $defense Verteidigung; das Ziel verliert etwa $damage LP.';
  }

  @override
  String combatPreviewAdvantageDefender(
    String country,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Verteidigungsvorteil: $country hat $defense Verteidigung gegen $attack Angriff; der Treffer verursacht etwa $damage LP.';
  }

  @override
  String combatPreviewAdvantageEven(int attack, int defense, int damage) {
    return 'Ausgeglichener Kampf: $attack Angriff gegen $defense Verteidigung; prognostizierter Schaden beträgt etwa $damage LP.';
  }

  @override
  String combatPreviewTerrainLine(
    String attackerCountry,
    String attackerTerrain,
    String defenderCountry,
    String defenderTerrain,
  ) {
    return 'Positionen: $attackerCountry greift von $attackerTerrain an. $defenderCountry verteidigt auf $defenderTerrain.';
  }

  @override
  String combatPreviewSourcesLine(String sources) {
    return 'Der Vorteil kommt von: $sources.';
  }

  @override
  String combatPreviewPositiveSourcesLine(
    String attackerCountry,
    String sources,
  ) {
    return 'Hilft dem Angriff ($attackerCountry): $sources.';
  }

  @override
  String combatPreviewNegativeSourcesLine(
    String defenderCountry,
    String sources,
  ) {
    return 'Hilft der Verteidigung ($defenderCountry): $sources.';
  }

  @override
  String get combatPreviewNoSourcesLine =>
      'Keine Modifikatoren gelten: Basiswerte der Einheit und das Kampfergebnis entscheiden diese Prognose.';

  @override
  String combatPreviewNoRetaliationReason(int distance, int range) {
    return 'Kein Gegenschlag: Dies ist ein Fernangriff (Distanz $distance, Angriffsreichweite $range).';
  }

  @override
  String get combatPreviewNoRetaliationDefenderDefeated =>
      'Kein Gegenschlag: Das Ziel wird besiegt, bevor es antworten kann.';

  @override
  String get combatPreviewNoRetaliationDefenderRetreats =>
      'Kein Gegenschlag: Das Ziel zieht sich nach dem Treffer zurück.';

  @override
  String get combatPreviewNoRetaliationNoAttack =>
      'Kein Gegenschlag: Das Ziel hat in dieser Prognose keine Angriffsstärke.';

  @override
  String combatPreviewRetaliationRisk(
    String defenderCountry,
    String attackerCountry,
    int damage,
  ) {
    return 'Gegenschlag: $defenderCountry antwortet und $attackerCountry verliert etwa $damage LP.';
  }

  @override
  String get combatPreviewSourceAttackTerrain => 'Gelände des Angreifers';

  @override
  String get combatPreviewSourceDefenseTerrain => 'Gelände des Verteidigers';

  @override
  String get combatPreviewSourceTechnology => 'Technologie';

  @override
  String get combatPreviewSourceVeterancy => 'Erfahrung';

  @override
  String get combatPreviewSourceCityGarrison => 'Stadtgarnison';

  @override
  String get combatPreviewSourceMixedArmy => 'Einheitszusammensetzung';

  @override
  String get combatCounterSpearmanVsMountedAttack =>
      'Speerträger gegen berittene Einheiten';

  @override
  String get combatCounterSpearmanVsMountedDefense =>
      'Speerträger halten gegen berittene Einheiten';

  @override
  String get combatCounterArcherDefensiveTerrainDefense =>
      'Bogenschützen in Verteidigungsgelände';

  @override
  String get combatCounterCavalryRoughAttack =>
      'Kavallerie durch schweres Gelände gebremst';

  @override
  String get combatCounterCavalryOpenRaid =>
      'Kavallerieangriff auf offenem Gelände';

  @override
  String get combatCounterHeavyInfantryBreakthrough =>
      'schwere Infanterie bricht die Linie';

  @override
  String get terrainOcean => 'Ozean';

  @override
  String get terrainCoast => 'Küste';

  @override
  String get terrainLake => 'See';

  @override
  String get terrainPlains => 'Ebenen';

  @override
  String get terrainGrassland => 'Grasland';

  @override
  String get terrainDesert => 'Wüste';

  @override
  String get terrainTundra => 'Tundra';

  @override
  String get terrainSnow => 'Schnee';

  @override
  String get terrainMountain => 'Gebirge';

  @override
  String get terrainHills => 'Hügel';

  @override
  String get terrainWetlands => 'Feuchtgebiete';

  @override
  String get terrainJungle => 'Dschungel';

  @override
  String get terrainForest => 'Wald';

  @override
  String get terrainRiver => 'Fluss';

  @override
  String get modeBannerMoveTargetingTitle => 'Bewegungsmodus';

  @override
  String get modeBannerMoveTargetingInstruction =>
      'Das erste Tippen auf ein Hex-Feld plant die Route. Tippe dasselbe Hex-Feld erneut an, um zu ziehen; eine längere Route wird für künftige Züge eingereiht.';

  @override
  String get modeBannerMoveTargetingCancelAction => 'Bewegung verlassen';

  @override
  String get modeBannerWorkerFindTileTitle => 'Arbeiter: Feld finden';

  @override
  String modeBannerWorkerFindTileInstruction(String reason) {
    return '$reason Bewege den Arbeiter auf eines deiner Stadtfelder ohne Verbesserung oder auf Gelände, das zu einem freigeschalteten Bau passt.';
  }

  @override
  String get modeBannerWorkerFindTileDetailOwnCity => 'Eigenes Stadtfeld';

  @override
  String get modeBannerWorkerFindTileDetailNoImprovement =>
      'Keine Verbesserung';

  @override
  String get modeBannerWorkerFindTileDetailMatchingTerrain =>
      'Passendes Gelände';

  @override
  String get modeBannerWorkerImproveTileTitle => 'Arbeiter: Feld verbessern';

  @override
  String get modeBannerWorkerImproveTileInstruction =>
      'Dieses Feld kann verbessert werden. Wenn du handeln möchtest, nutze die untere Werkzeugleiste, wähle den besten Bau und bestätige ihn im unteren Bereich.';

  @override
  String get modeBannerWorkerImproveTileDetailYields => 'Erhöht Felderträge';

  @override
  String get modeBannerWorkerImproveTileDetailMovement => 'Verbraucht Bewegung';

  @override
  String get modeBannerScoutExploreTitle => 'Späher: erkunden';

  @override
  String get modeBannerScoutExploreInstruction =>
      'Aktiviere Erkundung in der unteren Werkzeugleiste, damit der Späher automatisch die nächsten unbekannten Felder entdeckt. Du kannst sie später über Einheitsaktionen abbrechen.';

  @override
  String get modeBannerScoutExploreDetailAuto => 'Automatische Erkundung';

  @override
  String get modeBannerScoutExploreDetailReveal => 'Deckt die Karte auf';

  @override
  String get modeBannerSettlerFindSiteTitle => 'Siedler: Standort finden';

  @override
  String modeBannerSettlerFindSiteInstruction(String reason) {
    return '$reason Bewege den Siedler auf ein freies Feld außerhalb von Stadtgrenzen; vermeide Wasser, Gebirge und besetzte Zentren.';
  }

  @override
  String get modeBannerSettlerFindSiteDetailFreeHex => 'Freies Hex-Feld';

  @override
  String get modeBannerSettlerFindSiteDetailOutsideBorders =>
      'Außerhalb der Grenzen';

  @override
  String get modeBannerSettlerFindSiteDetailLandOrCoast => 'Land oder Küste';

  @override
  String get modeBannerSettlerFoundCityTitle => 'Siedler: Stadt gründen';

  @override
  String get modeBannerSettlerFoundCityInstruction =>
      'Dieses Feld kann eine Stadt werden. Wenn du eine gründen möchtest, nutze die untere Werkzeugleiste und wähle dann die Startfelder der Stadt auf der Karte.';

  @override
  String get modeBannerSettlerFoundCityDetailNewCity => 'Neue Stadt';

  @override
  String get modeBannerSettlerFoundCityDetailChooseTiles =>
      'Felder nach dem Tippen wählen';

  @override
  String get modeBannerCityFoundingTitle => 'Stadtgründung';

  @override
  String get modeBannerCityFoundingInstructionReady =>
      'Bereit. Bestätige die Stadtgründung in der unteren Werkzeugleiste oder ändere die ausgewählten Felder auf der Karte.';

  @override
  String modeBannerCityFoundingInstructionPick(int count) {
    return 'Wähle $count verbundene Felder um den Siedler. Nach der Auswahl ist die Stadtgründungsaktion in der unteren Werkzeugleiste verfügbar.';
  }

  @override
  String get selectionImprovementListTitle => 'Feldverbesserungen';

  @override
  String get mapInspectionPossibleImprovementsTitle =>
      'Mögliche Verbesserungen';

  @override
  String get mapInspectionNoPossibleImprovements =>
      'Keine möglichen Verbesserungen';

  @override
  String get mapInspectionImprovementAvailableFromStart => 'von Beginn an';

  @override
  String get mapInspectionObjectiveTitle => 'Kartenziel';

  @override
  String get mapObjectiveRuins => 'Ruinen';

  @override
  String get mapObjectiveStrategicPass => 'Strategischer Pass';

  @override
  String get mapObjectiveHolySite => 'Heilige Stätte';

  @override
  String get mapObjectiveLegendaryResource => 'Legendäre Lagerstätte';

  @override
  String get mapObjectiveRuinsDescription =>
      'Ein neutraler Erkundungspunkt. Halten erhöht den Siegpunktdruck.';

  @override
  String get mapObjectiveStrategicPassDescription =>
      'Ein wichtiger Geländedurchgang. Kontrolle macht Bewegung zu Einfluss.';

  @override
  String get mapObjectiveHolySiteDescription =>
      'Eine kulturell wichtige Stätte. Kontrolle gewährt Gold und Siegpunkte.';

  @override
  String get mapObjectiveLegendaryResourceDescription =>
      'Eine seltene Lagerstätte, die Expansion oder Konflikt lohnt. Kontrolle gibt die größte Belohnung.';

  @override
  String mapObjectiveStatusNeutral(int turns) {
    return '$turns Runden halten';
  }

  @override
  String mapObjectiveStatusHolding(int held, int required) {
    return 'Halten $held/$required';
  }

  @override
  String mapObjectiveStatusCompleted(int held, int required) {
    return 'Kontrolliert $held/$required';
  }

  @override
  String get mapObjectiveStatusContested => 'Umkämpft';

  @override
  String mapObjectiveRewardVictoryPoints(int points) {
    return '+$points SP';
  }

  @override
  String mapObjectiveRewardGoldPerTurn(int gold) {
    return '+$gold Gold/Runde';
  }

  @override
  String get selectionImprovementStateBuilt => 'GEBAUT';

  @override
  String get selectionImprovementStateAvailable => 'VERFÜGBAR';

  @override
  String get selectionImprovementStateNeedsTechnology => 'TECH';

  @override
  String get selectionImprovementStateNeedsCity => 'STADT';

  @override
  String get selectionImprovementStateBlocked => 'LIMIT';

  @override
  String get selectionImprovementNoBonus => 'Kein Bonus';

  @override
  String workerImprovementYieldFood(int value) {
    return '+$value Nahrung';
  }

  @override
  String workerImprovementYieldProduction(int value) {
    return '+$value Produktion';
  }

  @override
  String workerImprovementYieldGold(int value) {
    return '+$value Gold';
  }

  @override
  String workerImprovementYieldDefense(int value) {
    return '+$value Verteidigung';
  }

  @override
  String get workerImprovementNoBonus => 'Kein zusätzlicher Bonus.';

  @override
  String get workerImprovementOnlyWorker => 'Nur ein Arbeiter kann dies bauen.';

  @override
  String get workerImprovementWorkerBusy => 'Der Arbeiter baut bereits.';

  @override
  String get workerImprovementStopQueuedMove =>
      'Stoppe zuerst die geplante Bewegung.';

  @override
  String get workerImprovementMissingTile => 'Kein Feld unter der Einheit.';

  @override
  String get workerImprovementMissingResource =>
      'Diese Verbesserung benötigt eine passende Ressource.';

  @override
  String get workerImprovementInvalidTerrain =>
      'Falsches Grundgelände für diese Verbesserung.';

  @override
  String get workerImprovementMissingRiver =>
      'Diese Verbesserung benötigt einen Fluss.';

  @override
  String get workerImprovementBlocked => 'Diese Aktion ist jetzt blockiert.';

  @override
  String unitSelectionWorkerJobTurns(String name, int turns) {
    return '$name (${turns}Z)';
  }

  @override
  String get resourceValueNoMatchingImprovement =>
      'Keine passende Verbesserung';

  @override
  String get resourceValueSelectWorkerOrCity => 'Arbeiter oder Stadt auswählen';

  @override
  String get resourceValueTileAlreadyImproved =>
      'Feld hat bereits eine Verbesserung';

  @override
  String get resourceValueCityCenter => 'Stadtzentrum';

  @override
  String resourceValueWorksForCity(String city) {
    return 'Arbeitet für: $city';
  }

  @override
  String get resourceValueOutsideCityBorders => 'Außerhalb der Stadtgrenzen';

  @override
  String get resourceValueNoLegalImprovementForTile =>
      'Keine gültige Verbesserung für dieses Feld';

  @override
  String resourceValueRequiresTechnology(String technology) {
    return 'Benötigt: $technology';
  }

  @override
  String get resourceValueAvailableForWorker => 'Für Arbeiter verfügbar';

  @override
  String get resourceDetailNoResourcesOnTile =>
      'Keine Ressourcen auf diesem Feld';

  @override
  String get resourceDetailValueSection => 'Wert';

  @override
  String get resourceDetailCurrentSection => 'Jetzt';

  @override
  String get resourceDetailAfterImprovementSection => 'Nach Verbesserung';

  @override
  String get resourceDetailYieldComparison => 'Felderträge';

  @override
  String get resourceDetailRequiresSection => 'Benötigt';

  @override
  String get resourceDetailBestMoveSection => 'Bester Zug';

  @override
  String get resourceDetailNoMatchingImprovementBody =>
      'Keine passende Verbesserung für diese Ressource.';

  @override
  String get resourceDetailRequirementNoneCanBuild =>
      'Nichts. Du kannst sofort bauen.';

  @override
  String get resourceDetailRequirementOutsideCity =>
      'Das Feld muss innerhalb der Stadtgrenzen liegen.';

  @override
  String get resourceDetailRequirementAlreadyImproved =>
      'Nichts. Das Feld ist bereits verbessert.';

  @override
  String get resourceDetailRequirementCityCenter =>
      'Kein Arbeiterbau im Stadtzentrum.';

  @override
  String get resourceDetailRequirementSelectWorkerOrCity =>
      'Eine Arbeiter- oder Stadtauswahl.';

  @override
  String get resourceDetailRequirementNoLegalImprovement =>
      'Kein verfügbarer Bau für dieses Feld.';

  @override
  String resourceDetailBestMoveRequiresTechnology(
    String technology,
    String improvement,
  ) {
    return 'Schalte zuerst $technology frei und baue dann $improvement.';
  }

  @override
  String resourceDetailBestMoveAvailable(String improvement) {
    return 'Schicke einen Arbeiter und baue $improvement.';
  }

  @override
  String get resourceDetailBestMoveOutsideCity =>
      'Erweitere Stadtgrenzen oder gründe eine Stadt näher an der Ressource.';

  @override
  String get resourceDetailBestMoveAlreadyImproved =>
      'Halte das Feld in den Grenzen und bearbeite es, wenn es zum Stadtplan passt.';

  @override
  String get resourceDetailBestMoveCityCenter =>
      'Behandle die Ressource als Stadtzentrum-Wert; Arbeiter verbessern dieses Feld nicht.';

  @override
  String get resourceDetailBestMoveSelectWorkerOrCity =>
      'Wähle einen Arbeiter oder eine Stadt, um den gültigen Bau zu prüfen.';

  @override
  String get resourceDetailBestMoveNoLegalImprovement =>
      'Behandle die Ressource als Expansionsziel; hier gibt es keinen separaten Bau.';

  @override
  String resourceValueUnlockedByTechnology(
    String technology,
    String improvement,
  ) {
    return 'Durch $technology freigeschaltet: $improvement.';
  }

  @override
  String resourceValueUnlocksFullYieldAfterTechnology(
    String technology,
    String improvement,
  ) {
    return 'Nach $technology: $improvement schaltet den vollen Feldertrag frei.';
  }

  @override
  String resourceValueResearchBoostLine(String technology, String discount) {
    return 'Forschungsboost: Kontrolle dieser Ressource beschleunigt $technology (-$discount Kosten).';
  }

  @override
  String resourceValueTechnologyControlledResourceBonus(
    String technology,
    int production,
  ) {
    return 'Nach $technology: +$production PROD für jede kontrollierte Ressource.';
  }

  @override
  String resourceValueNoBaseYieldSummary(String yield) {
    return 'Die Ressource selbst fügt keinen Grundertrag hinzu. Das ganze Hex-Feld hat jetzt $yield; der volle Wert kommt durch Verbesserungen und Freischaltungen.';
  }

  @override
  String resourceValueBaseYieldSummary(String resourceYield, String tileYield) {
    return 'Die Ressource gibt $resourceYield. Das ganze Hex-Feld hat vor Verbesserung jetzt $tileYield.';
  }

  @override
  String get resourceValueExpansionStrategic =>
      'Beanspruche sie, bevor ein Rivale es tut: Dies ist eine strategische Ressource für Produktion, Armeen oder spätere Technologien.';

  @override
  String get resourceValueExpansionFood =>
      'Ein gutes Expansionsziel für Stadtwachstum: mehr Nahrung bedeutet schnellere Bevölkerung und mehr bearbeitete Felder.';

  @override
  String get resourceValueExpansionProduction =>
      'Ein gutes Expansionsziel für Produktionstempo: Gebäude, Einheiten und Kartendruck kommen schneller.';

  @override
  String get resourceValueExpansionTrade =>
      'Ein gutes Expansionsziel für Handel: Nach Verbesserung unterstützt es Gold und weiteren Wachstumsunterhalt stark.';

  @override
  String get resourceValueExpansionEconomy =>
      'Ein gutes Expansionsziel für die Wirtschaft: Gold hilft, Armeen zu unterhalten, Reserven aufzubauen und Punkteziele zu erreichen.';

  @override
  String resourceValueYieldFood(int amount) {
    return '+$amount NAHRUNG';
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
    return '+$amount VER';
  }

  @override
  String get resourceValueZeroBaseYield => '0 Grundertrag';

  @override
  String get resourceValueCategoryBonus => 'Bonus';

  @override
  String get resourceValueCategoryLuxury => 'Luxus';

  @override
  String get resourceValueCategoryStrategic => 'Strategisch';

  @override
  String get resourceValueCategoryBonusFuture =>
      'Der Wert wirkt meist sofort: schnelleres Wachstum und ein besserer Stadtstart.';

  @override
  String get resourceValueCategoryLuxuryFuture =>
      'Der größte Wert erscheint nach Grenzbeanspruchung und passender Verbesserung.';

  @override
  String get resourceValueCategoryStrategicFuture =>
      'Dies ist eine strategische Ressource: Sichere sie für spätere Produktion und militärischen Druck.';

  @override
  String get cityYieldBreakdownTitle => 'Stadtwirtschaft';

  @override
  String cityYieldBreakdownSubtitle(String growth, String eta) {
    return 'Echter Ertrag/Zug • Wachstum $growth • $eta';
  }

  @override
  String get cityYieldBreakdownProductionSources => 'Produktionsquellen';

  @override
  String get cityYieldBreakdownScienceSources => 'Wissenschaftsquellen';

  @override
  String get cityYieldBreakdownPerTurnSuffix => '/Zug';

  @override
  String get cityYieldBreakdownNoProduction => 'Keine Produktion';

  @override
  String get cityYieldBreakdownNoScience => 'Keine Wissenschaft';

  @override
  String get cityYieldBreakdownCenter => 'Zentrum';

  @override
  String get cityYieldBreakdownPopulationFields => 'Bevölkerungsfelder';

  @override
  String get cityYieldBreakdownWorkers => 'Arbeiter';

  @override
  String get cityYieldBreakdownBuildings => 'Gebäude';

  @override
  String get cityYieldBreakdownTechnologies => 'Technologien';

  @override
  String get cityYieldBreakdownSpecialization => 'Spezialisierung';

  @override
  String get cityYieldBreakdownGoldMultiplier => 'Goldmultiplikator';

  @override
  String get cityYieldBreakdownUpkeep => 'Unterhalt';

  @override
  String get cityYieldBreakdownFieldsBucket => 'Felder';

  @override
  String get cityYieldBreakdownCenterDetail =>
      'Fester Ertrag aus dem Stadtzentrum';

  @override
  String get cityYieldBreakdownGoldMultiplierDetail =>
      'Prozentualer Bonus nach Summierung der Goldquellen';

  @override
  String get cityYieldBreakdownBaseScience => 'Stadtbasis';

  @override
  String get cityYieldBreakdownBaseScienceDetail =>
      'Feste Wissenschaft, die von jeder Stadt erzeugt wird';

  @override
  String get cityYieldBreakdownResearchProject => 'Forschungsprojekt';

  @override
  String get cityYieldBreakdownResearchProjectDetail =>
      'Aktuelle Stadtproduktion wird in Wissenschaft umgewandelt';

  @override
  String get cityYieldBreakdownScienceSpecializationDetail =>
      'Wissenschaftsprofil der Stadt';

  @override
  String get cityYieldBreakdownScienceTechnologyDetail =>
      'Wissenschaftsbonus durch freigeschaltete Technologien';

  @override
  String get cityYieldBreakdownNoWorkedPopulationFields =>
      'Keine bearbeiteten Bevölkerungsfelder';

  @override
  String get cityYieldBreakdownOneWorkedPopulationField =>
      '1 bearbeitetes Bevölkerungsfeld';

  @override
  String cityYieldBreakdownManyWorkedPopulationFields(int count) {
    return '$count bearbeitete Bevölkerungsfelder';
  }

  @override
  String get cityYieldBreakdownNoAssignedWorkers =>
      'Keine zugewiesenen Arbeiter';

  @override
  String get cityYieldBreakdownOneAssignedWorker =>
      '1 Feld durch einen Arbeiter aktiviert';

  @override
  String cityYieldBreakdownManyAssignedWorkers(int count) {
    return '$count Felder durch Arbeiter aktiviert';
  }

  @override
  String get cityYieldBreakdownNoPassiveImprovements =>
      'Keine passiven Verbesserungen';

  @override
  String get cityYieldBreakdownOnePassiveImprovement =>
      '1 unbearbeitete Verbesserung, halber Ertrag';

  @override
  String cityYieldBreakdownManyPassiveImprovements(int count) {
    return '$count unbearbeitete Verbesserungen, halber Ertrag';
  }

  @override
  String get cityYieldBreakdownNoBuildings => 'Keine Gebäude';

  @override
  String get cityYieldBreakdownBuildingsNoDirectYield =>
      'Gebäude ohne direkten Ertrag';

  @override
  String get cityYieldBreakdownOneBuildingEconomicEffect =>
      '1 Gebäude mit Wirtschaftseffekt';

  @override
  String cityYieldBreakdownManyBuildingEconomicEffects(int count) {
    return '$count Gebäude mit Wirtschaftseffekten';
  }

  @override
  String get cityYieldBreakdownNoTechnologyYield =>
      'Kein Technologie-Ertragsbonus';

  @override
  String get cityYieldBreakdownTechnologyYield =>
      'Boni aus freigeschalteten Technologien';

  @override
  String get cityYieldBreakdownNoScienceBuildings =>
      'Keine Wissenschaftsgebäude';

  @override
  String get cityYieldBreakdownOneScienceBuilding => '1 Wissenschaftsgebäude';

  @override
  String cityYieldBreakdownManyScienceBuildings(int count) {
    return '$count Wissenschaftsgebäude mit abnehmendem Ertrag';
  }

  @override
  String cityYieldBreakdownGrowthFood(int storedFood, int growthCost) {
    return '$storedFood/$growthCost Nahrung';
  }

  @override
  String get cityYieldBreakdownStagnation => 'Stagnation';

  @override
  String cityYieldBreakdownUpkeepBlocked(int population, int cost) {
    return 'Bevölkerung $population: Kosten $cost, Wachstum gestoppt';
  }

  @override
  String cityYieldBreakdownUpkeepCost(int population) {
    return 'Nahrungsunterhalt für Bevölkerung $population';
  }

  @override
  String get cityYieldBreakdownGrowthSpecializationDetail =>
      'Wachstumsprofil der Stadt';

  @override
  String get cityYieldBreakdownIndustrySpecializationDetail =>
      'Industrieprofil der Stadt';

  @override
  String get cityYieldBreakdownCommerceSpecializationDetail =>
      'Handelsprofil der Stadt';

  @override
  String get cityYieldBreakdownScienceSpecializationCityDetail =>
      'Wissenschaftsprofil der Stadt';

  @override
  String get cityYieldBreakdownMilitarySpecializationDetail =>
      'Garnisonsprofil der Stadt';

  @override
  String get cityYieldBreakdownNoSpecialization => 'Keine Spezialisierung';

  @override
  String get cityProjectWealth => 'Wohlstand';

  @override
  String get cityProjectResearch => 'Forschung';

  @override
  String get cityProductionProjectsSection => 'Stadtprojekte';

  @override
  String get cityProductionSpecializationSection => 'Stadtspezialisierung';

  @override
  String get cityProductionSortLabel => 'Sortieren';

  @override
  String cityProductionHeaderSubtitle(
    String title,
    String productionPerTurn,
    int gold,
  ) {
    return '$title • $productionPerTurn • $gold Gold';
  }

  @override
  String get cityProductionBuiltLabel => 'Gebaut';

  @override
  String get cityProductionAvailableLabel => 'Verfügbar';

  @override
  String get cityProductionAvailableUnitLabel => 'Verfügbar';

  @override
  String cityProductionUnitSupplyLimit(int used, int capacity) {
    return 'Nahrungslimit $used/$capacity';
  }

  @override
  String cityProductionUnitSupplyCost(int cost) {
    return 'Nahrung $cost';
  }

  @override
  String cityProductionUnitSupplyUsed(int used, int capacity) {
    return 'Limit $used/$capacity';
  }

  @override
  String cityProductionNextWorkerUpkeep(int upkeep) {
    return 'nächster Unterhalt: $upkeep';
  }

  @override
  String cityProductionCostShort(int production) {
    return '$production Prod.';
  }

  @override
  String cityProductionPaceShort(int production) {
    return '$production Prod./Zug';
  }

  @override
  String get cityBuildingSortRecommended => 'Empfohlen';

  @override
  String cityBuildingReplaceProgressWarning(String building) {
    return 'Die Wahl eines anderen Gebäudes ersetzt $building. Der Fortschritt bleibt erhalten.';
  }

  @override
  String get cityBuildingSortFastestImpact => 'Schnellste Wirkung';

  @override
  String get cityBuildingSortBestReturn => 'Beste Rendite';

  @override
  String get cityBuildingSortGrowth => 'Wachstum';

  @override
  String get cityBuildingSortIndustry => 'Industrie';

  @override
  String get cityBuildingSortScience => 'Wissenschaft';

  @override
  String get cityBuildingSortDefenseMilitary => 'Verteidigung / Militär';

  @override
  String get cityBuildingSortEconomy => 'Wirtschaft';

  @override
  String get cityBuildingRequiresTechnology => 'Benötigt Technologie';

  @override
  String get cityProductionContinuous => 'fortlaufend';

  @override
  String get cityProductionNoProduction => 'keine Produktion';

  @override
  String get cityProductionReady => 'bereit';

  @override
  String get cityProductionTurnOne => '1 Zug';

  @override
  String cityProductionTurns(int turns) {
    return '$turns Züge';
  }

  @override
  String cityProductionTreasuryGold(int gold) {
    return 'Schatzkammer: $gold Gold';
  }

  @override
  String cityProductionRushAction(int gold) {
    return 'Beschleunigen -$gold';
  }

  @override
  String cityProjectGoldPerTurn(int gold) {
    return '+$gold Gold / Zug';
  }

  @override
  String cityProjectSciencePerTurn(int science) {
    return '+$science Wissenschaft / Zug';
  }

  @override
  String get citySpecializationGrowth => 'Wachstum';

  @override
  String get citySpecializationIndustry => 'Industrie';

  @override
  String get citySpecializationCommerce => 'Handel';

  @override
  String get citySpecializationMilitary => 'Garnison';

  @override
  String get citySpecializationGrowthBonus => '+2 Nahrung';

  @override
  String get citySpecializationIndustryBonus => '+2 Produktion';

  @override
  String get citySpecializationCommerceBonus => '+3 Gold';

  @override
  String get citySpecializationScienceBonus => '+2 Wissenschaft';

  @override
  String get citySpecializationMilitaryProductionBonus => '+1 Produktion';

  @override
  String get citySpecializationMilitaryDefenseBonus => '+2 Verteidigung';

  @override
  String get citySpecializationMilitaryUnitProductionBonus =>
      '+1 Einheitsprod.';

  @override
  String get citySpecializationBestFit => 'Beste Eignung';

  @override
  String get eventCityFoundedTitle => 'Stadt gegründet';

  @override
  String get eventCityBuiltBuildingTitle => 'Bau abgeschlossen';

  @override
  String get eventCityProducedUnitTitle => 'Einheit ausgebildet';

  @override
  String get eventCityClaimedHexTitle => 'Stadtgrenzen';

  @override
  String eventCityClaimedHexBody(String cityName) {
    return '$cityName: neues Feld';
  }

  @override
  String get eventUnitMovedTitle => 'Einheitenbewegung';

  @override
  String get eventUnitPromotedTitle => 'Einheit befördert';

  @override
  String get eventUnitExperienceTitle => 'Erfahrung';

  @override
  String eventUnitExperienceBody(String unitName, int amount, String rank) {
    return '$unitName: +$amount EP ($rank)';
  }

  @override
  String get eventUnitAttackedTitle => 'Angriff';

  @override
  String get eventCombatTitle => 'Kampf';

  @override
  String eventCombatDamageLine(String unitName, int damage, String result) {
    return '$unitName: -$damage LP -> $result';
  }

  @override
  String eventCombatNoRetaliationLine(String unitName) {
    return '$unitName: kein Gegenschlag';
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
    return '$attackerName ($attackerCountry) griff $defenderName ($defenderCountry) an - LP $attackerHp:$defenderHp';
  }

  @override
  String get eventDiplomaticProposalAcceptedStatus => 'Angenommen';

  @override
  String get eventDiplomaticProposalRejectedStatus => 'Abgelehnt';

  @override
  String get eventDiplomaticProposalExpiredStatus => 'Abgelaufen';

  @override
  String get eventUnitKilledTitle => 'Einheit besiegt';

  @override
  String get eventUnitRetreatedTitle => 'Rückzug';

  @override
  String get eventCityCapturedTitle => 'Stadt erobert';

  @override
  String get eventCityDestroyedTitle => 'Stadt zerstört';

  @override
  String get eventTurnEndedTitle => 'Zug beendet';

  @override
  String get eventStabilityBandChangedTitle => 'Empire stability changed';

  @override
  String eventStabilityBandChangedBody(
    String playerName,
    String band,
    int net,
  ) {
    return '$playerName: $band ($net)';
  }

  @override
  String get eventWorkerCompletedJobTitle => 'Arbeit abgeschlossen';

  @override
  String get eventResearchPointsTitle => 'Wissenschaft';

  @override
  String eventResearchPointsBody(String playerName, int points) {
    return '$playerName: +$points Wissenschaft';
  }

  @override
  String get eventTechnologyResearchedTitle => 'Technologie entdeckt';

  @override
  String get eventStrategicResourceDiscoveredTitle =>
      'Strategische Ressource entdeckt';

  @override
  String eventStrategicResourceDiscoveredBody(
    String playerName,
    String resourceName,
  ) {
    return '$playerName: $resourceName';
  }

  @override
  String eventStrategicResourceControlledDetail(int count) {
    return 'Kontrolliert: $count';
  }

  @override
  String eventStrategicResourceRivalDetail(int count) {
    return 'Rivalen: $count';
  }

  @override
  String eventStrategicResourceUnclaimedDetail(int count) {
    return 'Unbeansprucht: $count';
  }

  @override
  String get eventStrategicResourcePressureSecured =>
      'Versorgung gesichert; verteidige die Quelle.';

  @override
  String get eventStrategicResourcePressureExpansionRace =>
      'Siedlungsrennen: sichere das nächste Vorkommen vor den Rivalen.';

  @override
  String get eventStrategicResourcePressureContested =>
      'Umkämpfte Versorgung: Rivalen kontrollieren ebenfalls Quellen.';

  @override
  String get eventStrategicResourcePressureRivalMonopoly =>
      'Rivalenmonopol: bereite Handel oder eine Expedition vor.';

  @override
  String eventStrategicResourceSettleHint(int col, int row) {
    return 'Vorkommen außerhalb der Grenzen bei $col:$row; gründe dort eine Stadt.';
  }

  @override
  String get eventMapObjectiveSecuredTitle => 'Kartenziel gesichert';

  @override
  String eventMapObjectiveSecuredBody(String playerName, String objectiveName) {
    return '$playerName: $objectiveName';
  }

  @override
  String eventMapObjectiveHoldDetail(int holdTurns, int requiredHoldTurns) {
    return 'Gehalten: $holdTurns/$requiredHoldTurns';
  }

  @override
  String eventMapObjectiveLocationDetail(int col, int row) {
    return 'Position: $col:$row';
  }

  @override
  String eventMapObjectiveVictoryRewardDetail(int points) {
    return '+$points Siegpunkte';
  }

  @override
  String eventMapObjectiveGoldRewardDetail(int gold) {
    return '+$gold Gold/Runde';
  }

  @override
  String get eventCivilizationMetTitle => 'Neue Zivilisation';

  @override
  String eventCivilizationMetBody(String civilizationName, String playerName) {
    return '$civilizationName ($playerName)';
  }

  @override
  String get civilizationMetPopupEyebrow => 'Zivilisation begegnet';

  @override
  String civilizationMetPopupBody(String civilizationName) {
    return 'Die Zivilisation $civilizationName ist am Horizont erschienen. Ein neuer Nachbar, Rivale oder künftiger Verbündeter ist nun Teil deiner Welt.';
  }

  @override
  String get civilizationMetPopupOk => 'OK';

  @override
  String get eventCommandRejectedTitle => 'Befehl abgelehnt';

  @override
  String get eventAllPlayersSubmittedTitle => 'Alle bereit';

  @override
  String eventAllPlayersSubmittedBody(int turn, int players) {
    return 'Zug $turn ($players)';
  }

  @override
  String get eventPlayerTimedOutTitle => 'Automatisch senden';

  @override
  String eventPlayerTimedOutBody(String playerName, int turn) {
    return '$playerName: Zeitüberschreitung in Zug $turn';
  }

  @override
  String get eventCombatDefenderKilledDetail => 'Verteidiger besiegt';

  @override
  String get eventCombatAttackerKilledDetail => 'Angreifer besiegt';

  @override
  String get eventCombatDefenderRetreatedDetail =>
      'Verteidiger zog sich zurück';

  @override
  String eventCombatAttackDamageDetail(int damage) {
    return 'Angriff: -$damage LP';
  }

  @override
  String eventCombatRetaliationDamageDetail(int damage) {
    return 'Gegenschlag: -$damage LP';
  }

  @override
  String eventCombatRollDetail(int value) {
    return 'Wurf $value';
  }

  @override
  String get eventCombatNoRetaliationDetail => 'Kein Gegenschlag';

  @override
  String get eventDominationStartedTitle => 'Dominanz begonnen';

  @override
  String get eventDominationRivalAboveTitle => 'Rivale über Schwelle';

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
    return '$held/$required Züge gehalten';
  }

  @override
  String get eventDominationReadyDetail => 'Bedingung bereit';

  @override
  String eventDominationKeepHoldingDetail(String turns) {
    return 'Noch $turns halten';
  }

  @override
  String eventDominationInterruptDetail(String turns) {
    return 'Innerhalb von $turns unterbrechen';
  }

  @override
  String eventTurnCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Züge',
      one: '1 Zug',
      zero: '0 Züge',
    );
    return '$_temp0';
  }

  @override
  String get eventCombatDefeatedResult => 'besiegt';

  @override
  String eventCombatDefenderRetreatedResult(int hp) {
    return '$hp LP, Rückzug';
  }

  @override
  String eventCombatHpResult(int hp) {
    return '$hp LP';
  }

  @override
  String eventCombatTerrainModifierLabel(Object terrain) {
    return 'Gelände $terrain';
  }

  @override
  String eventCombatTechModifierLabel(Object technology) {
    return 'Technologie $technology';
  }

  @override
  String eventCombatRankModifierLabel(Object rank) {
    return 'Rang $rank';
  }

  @override
  String get eventCombatCityGarrisonModifier => 'Stadtgarnison';

  @override
  String get eventCombatMixedArmyModifier => 'Gemischte Armee';

  @override
  String get eventCombatStatAttack => 'Angriff';

  @override
  String get eventCombatStatDefense => 'Verteidigung';

  @override
  String get eventCombatStatHp => 'LP';

  @override
  String get eventCombatStatRange => 'Reichweite';

  @override
  String get eventCombatStatMobility => 'Bewegung';

  @override
  String get closeAction => 'Schließen';
}
