// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Tijdperk van Nieuwe Werelden';

  @override
  String defaultPlayerName(int index) {
    return 'Speler $index';
  }

  @override
  String defaultCityName(int index) {
    return 'Plaats $index';
  }

  @override
  String get newGameTitle => 'NIEUW SPEL';

  @override
  String get gameModeSinglePlayerMenuLabel => 'Singleplayer';

  @override
  String get gameModeMultiplayerMenuLabel => 'Multiplayer';

  @override
  String get gameModeHotSeatMenuLabel => 'Hete stoel';

  @override
  String get gameModeSinglePlayerSummaryLabel => 'Singleplayer';

  @override
  String get gameModeMultiplayerSummaryLabel => 'Multiplayer';

  @override
  String get gameModeHotSeatSummaryLabel => 'Hete stoel';

  @override
  String get gameModeSinglePlayerMapTitle => 'Kies een kaart om solo te spelen';

  @override
  String get gameModeMultiplayerMapTitle =>
      'Kies een kaart om online te spelen';

  @override
  String get gameModeHotSeatMapTitle => 'Kies een kaart voor hot-seat-spel';

  @override
  String get gameModeSinglePlayerMapSubtitle =>
      'Een lokale wedstrijd tegen AI.';

  @override
  String get gameModeMultiplayerMapSubtitle =>
      'Startscenario en wereldkaart voor een online wedstrijd.';

  @override
  String get gameModeHotSeatMapSubtitle =>
      'Startscenario en wereldkaart voor hot-seat-play op één apparaat.';

  @override
  String get newGameIntroTitle => 'Bereid de expeditie voor';

  @override
  String get newGameIntroSubtitle =>
      'Kies eerst de speelstijl, daarna de kaart en verfijn vervolgens de spelers en het wedstrijdtempo.';

  @override
  String get newGameStepPlan => 'Spelplan';

  @override
  String get newGameStepMap => 'Kaart';

  @override
  String get newGameStepReview => 'Beoordeling';

  @override
  String get newGamePlanTitle => 'Welk verhaal wil je beginnen?';

  @override
  String get newGamePremiseTitle => 'Van nederzetting tot imperium';

  @override
  String get newGamePremiseBody =>
      'Elke wedstrijd begint met een paar beslissende keuzes: waar we de eerste stad kunnen stichten, hoe we het onderzoek vorm moeten geven, wanneer we het risico moeten nemen om uit te breiden en hoe we de controle over de kaart kunnen behouden.';

  @override
  String get newGameCountryTitle => 'Kies beschaving';

  @override
  String get newGameCountrySubtitle =>
      'De naam van je heerser volgt de beschaving die je kiest.';

  @override
  String get newGameSinglePlayerSettingsTitle => 'Match-instellingen';

  @override
  String get newGameGameLengthLabel => 'Spellengte';

  @override
  String get newGameLeaderLabel => 'LEIDER';

  @override
  String get newGamePillarCities => 'Steden';

  @override
  String get newGamePillarUnits => 'Eenheden';

  @override
  String get newGamePillarResearch => 'Onderzoek';

  @override
  String get newGameVictoryTypesTitle => 'Overwinningspaden';

  @override
  String get newGameVictoryDominationTitle => 'Overheersing';

  @override
  String newGameVictoryDominationBody(String controlPercent, int holdTurns) {
    return 'Beheers $controlPercent% van de kaart en houd deze vast voor $holdTurns-beurten. Verovering kan de wedstrijd nog steeds beëindigen door rivalen uit te schakelen.';
  }

  @override
  String get newGameVictoryArtifactsTitle => 'Artefacten';

  @override
  String newGameVictoryArtifactsBody(int artifactCount, int holdTurns) {
    return 'Plaats unieke wereldartefacten van $artifactCount in uw steden en bewaar de volledige collectie voor $holdTurns-beurten.';
  }

  @override
  String get newGameModeSinglePlayerDescription =>
      'Een rustige wedstrijd tegen AI. Het beste voor leersystemen, testen, en experimenteren met groei.';

  @override
  String get newGameModeMultiplayerDescription =>
      'Een online match met netwerklobby, spelerbereidheid en een gedeelde toegang tot de kaart.';

  @override
  String get newGameModeMultiplayerAlphaDisabled =>
      'Niet beschikbaar in de alfaversie.';

  @override
  String get newGameModeHotSeatDescription =>
      'Hotseat spelen op één apparaat. Spelers passeren de beurt, terwijl het scherm elke overdracht begeleidt.';

  @override
  String get newGameMapTitle => 'Kies de wereld';

  @override
  String get newGameMapSubtitle =>
      'De kaart definieert het tempo van het eerste contact, de beschikbare middelen, de stadsruimte en de vorm van het conflict.';

  @override
  String get newGameReviewTitle => 'Bevestig de expeditie';

  @override
  String get newGameReviewSubtitle =>
      'Nadat je hebt bevestigd, ga je naar de lobby om de spelnaam, wedstrijdduur en spelers in te stellen.';

  @override
  String newGameReviewSinglePlayerSubtitle(int aiCount) {
    return 'Singleplayer begint onmiddellijk met jou en $aiCount AI-spelers.';
  }

  @override
  String get newGameReviewMissingMap =>
      'Kies een kaart voordat je spelers configureert.';

  @override
  String get newGameExpeditionReady => 'Expeditie klaar';

  @override
  String get newGameSelectedMapLabel => 'Kaart';

  @override
  String get newGameMapPickLabel => 'Kaartkeuze';

  @override
  String get newGameMapPickRandom => 'Willekeurige standaard';

  @override
  String get newGameMapPickManual => 'Handmatig gekozen';

  @override
  String get newGameWorldSourceLabel => 'Bron';

  @override
  String newGameSinglePlayerAiSummary(int aiCount) {
    return 'Jij + $aiCount AI';
  }

  @override
  String get newGameChangeMapAction => 'Wijzig kaart';

  @override
  String get newGameStartSetupAction => 'Ga naar de lobby';

  @override
  String get mainMenuLoadGame => 'Spel laden';

  @override
  String get mainMenuDeveloper => 'Hulpmiddelen';

  @override
  String get mainMenuSettings => 'Instellingen';

  @override
  String get mainMenuSettingsSublabel => 'Tekst en audio';

  @override
  String get mainMenuExit => 'Uitgang';

  @override
  String get mainMenuAiSublabel => 'AI';

  @override
  String get mainMenuOnlineSublabel => 'Netwerk';

  @override
  String get mainMenuLocalSublabel => 'Lokaal';

  @override
  String get mainMenuToolsSublabel => 'Redacteuren';

  @override
  String get mainMenuToolsTitle => 'Hulpmiddelen';

  @override
  String get mainMenuMapEditor => 'Kaarteditor';

  @override
  String get mainMenuAssetsEditor => 'Activa-editor';

  @override
  String get mainMenuTextSize => 'Tekstgrootte';

  @override
  String get mainMenuTextSample => 'Voorbeeld speltekst';

  @override
  String get mainMenuManual => 'Handmatig';

  @override
  String get mainMenuCredits => 'Kredieten';

  @override
  String get mainMenuFeedback => 'Feedback';

  @override
  String get manualTitle => 'Bedieningshandleiding';

  @override
  String get manualSubtitle =>
      'Een snelle referentie voor kaartbeweging, selectie, bestellingen, panelen en turnflow op desktop en mobiel.';

  @override
  String get manualMetaDesktop => 'Bureaublad';

  @override
  String get manualMetaMobile => 'Mobiel';

  @override
  String get manualMetaAlpha => 'Alfa voor één speler';

  @override
  String get manualCommandLoopTitle => 'Kernopdrachtlus';

  @override
  String get manualCommandLoopSelectTitle => 'Selecteer';

  @override
  String get manualCommandLoopSelectBody =>
      'Kies een eenheid, stad, artefact of kaarttegel om de acties te onthullen die er nu toe doen.';

  @override
  String get manualCommandLoopPreviewTitle => 'Voorbeeld';

  @override
  String get manualCommandLoopPreviewBody =>
      'Beweeg of tik één keer om doelen, intentiekleuren, routes en geblokkeerde acties te inspecteren.';

  @override
  String get manualCommandLoopConfirmTitle => 'Bevestigen';

  @override
  String get manualCommandLoopConfirmBody =>
      'Gebruik een actiechip of kies opnieuw het gemarkeerde doelwit om de bestelling uit te voeren.';

  @override
  String get manualCommandLoopAdvanceTitle => 'Voorschot';

  @override
  String get manualCommandLoopAdvanceBody =>
      'Gebruik de onderste actieknop om naar de volgende beslissing te gaan of de beurt te voltooien.';

  @override
  String get manualDesktopTitle => 'Bureaubladbediening';

  @override
  String get manualDesktopSubtitle =>
      'Speel met de muis eerst met snelle kaartinspectie, nauwkeurige targeting en permanente panelen.';

  @override
  String get manualMobileTitle => 'Mobiele bediening';

  @override
  String get manualMobileSubtitle =>
      'Touch-first play afgestemd op leesbare panelen, weloverwogen opdrachten en een snelle beurtstroom.';

  @override
  String get manualMapCameraGroup => 'Kaart en camera';

  @override
  String get manualOrdersGroup => 'Selectie & bestellingen';

  @override
  String get manualPanelsGroup => 'Panelen en hulp';

  @override
  String get manualTurnFlowGroup => 'Draai stroom';

  @override
  String get manualDesktopLeftClickAction => 'Klik met de linkermuisknop';

  @override
  String get manualDesktopLeftClickBody =>
      'Selecteer eenheden, steden, artefacten en tegels; bij een actieve bestelling kiest u het doel.';

  @override
  String get manualDesktopDragAction => 'Sleep de kaart';

  @override
  String get manualDesktopDragBody =>
      'Pan de camera zonder de huidige selectie of opdrachtmodus te wijzigen.';

  @override
  String get manualDesktopZoomAction => 'Muiswiel / trackpad';

  @override
  String get manualDesktopZoomBody =>
      'Zoom tussen strategisch overzicht en tactische details op de kaart.';

  @override
  String get manualDesktopHoverAction => 'Zweven';

  @override
  String get manualDesktopHoverBody =>
      'Bekijk een voorbeeld van tooltips, doelhints en redenen voor geblokkeerde volgorde voordat u een commit maakt.';

  @override
  String get manualDesktopActionChipsAction => 'Actiechips';

  @override
  String get manualDesktopActionChipsBody =>
      'Verplaats, val aan, verbeter, vind een stad, sla over, versterk of annuleer de huidige modus.';

  @override
  String get manualDesktopSecondClickAction => 'Twee keer hetzelfde doel';

  @override
  String get manualDesktopSecondClickBody =>
      'Voor beweging geeft de eerste klik een voorbeeld van de route weer; de tweede klik wordt uitgevoerd of in de wachtrij geplaatst.';

  @override
  String get manualDesktopHoldAction => 'Klik en houd vast';

  @override
  String get manualDesktopHoldBody =>
      'Open gedetailleerde opdrachtuitleg voor acties, uitgeschakelde opties en contextchips.';

  @override
  String get manualDesktopRailAction => 'Linker rail';

  @override
  String get manualDesktopRailBody =>
      'Open kaartopties, hulp, doelstellingen, activiteitenlogboek, onderzoek en imperiumpanelen.';

  @override
  String get manualDesktopTopPillsAction => 'Topbronnen';

  @override
  String get manualDesktopTopPillsBody =>
      'Inspecteer de mislukkingen van de economie, de wetenschap, de hulpbronnen en de overwinningsdruk.';

  @override
  String get manualDesktopCloseAction => 'Klik naar buiten';

  @override
  String get manualDesktopCloseBody =>
      'Sluit pop-ups, optiepanelen en helpkaarten en breng de focus terug naar de kaart.';

  @override
  String get manualDesktopHelpAction => '?';

  @override
  String get manualDesktopHelpBody =>
      'Open elke geminimaliseerde hint- en instructiekaart op elk gewenst moment, ongeacht de selectie.';

  @override
  String get manualDesktopTurnAction => 'Volgende beslissing';

  @override
  String get manualDesktopTurnBody =>
      'Focus op de volgende eenheid, onderzoek of stadskeuze; beëindig de beurt wanneer niets de voortgang blokkeert.';

  @override
  String get manualMobileTapAction => 'Kraan';

  @override
  String get manualMobileTapBody =>
      'Selecteer eenheden, steden, artefacten en tegels; bij een actieve bestelling kiest u het doel.';

  @override
  String get manualMobileDragAction => 'Met één vinger slepen';

  @override
  String get manualMobileDragBody =>
      'Pan de camera terwijl de geselecteerde eenheid of paneelstatus intact blijft.';

  @override
  String get manualMobilePinchAction => 'Kneep';

  @override
  String get manualMobilePinchBody =>
      'Zoom in op de kaart voor scouting, stadswerk, bewegingsplanning of gevechtstargeting.';

  @override
  String get manualMobileSecondTapAction => 'Twee keer hetzelfde doel';

  @override
  String get manualMobileSecondTapBody =>
      'Bekijk eerst een voorbeeld van een verplaatsingsroute en tik vervolgens opnieuw op hetzelfde vak om deze uit te voeren of in de wachtrij te plaatsen.';

  @override
  String get manualMobileActionChipsAction => 'Actiechips';

  @override
  String get manualMobileActionChipsBody =>
      'Gebruik de onderste commandorij voor eenheidsorders, stadskeuzes, arbeiders en annuleringsacties.';

  @override
  String get manualMobileHoldAction => 'Houd ingedrukt';

  @override
  String get manualMobileHoldBody =>
      'Open uitleg voor opdrachten, uitgeschakelde opties, bronnen en contextuele gebruikersinterface.';

  @override
  String get manualMobileScrollAction => 'Schuifpanelen';

  @override
  String get manualMobileScrollBody =>
      'Blader door lange stads-, onderzoeks-, log-, diplomatie- en hulplijsten zonder de kaartstatus te verliezen.';

  @override
  String get manualMobileRailAction => 'Linker rail';

  @override
  String get manualMobileRailBody =>
      'Tik om kaartopties, hulp, doelstellingen, activiteitenlogboek, onderzoek en imperiumpanelen te openen.';

  @override
  String get manualMobileHelpAction => '?';

  @override
  String get manualMobileHelpBody =>
      'Bekijk elke geminimaliseerde hint en instructiekaart wanneer u een opfriscursus nodig heeft.';

  @override
  String get manualMobileTurnAction => 'Onderste actie';

  @override
  String get manualMobileTurnBody =>
      'Spring naar de volgende vereiste beslissing of beëindig de beurt zodra alle actiepunten zijn opgebruikt.';

  @override
  String get mainMenuWhatsNew => 'Wat is er nieuw';

  @override
  String get mainMenuWhatsNewBody =>
      'Welkom in het tijdperk van de nieuwe werelden. Bouw steden, leid commandanten, ontdek nieuwe landen en schrijf de geschiedenis van je beschaving.';

  @override
  String get mainMenuUpdateSoonTitle => 'Update onderweg';

  @override
  String get mainMenuUpdateSoonBody =>
      'Een nieuwere versie staat klaar en verschijnt binnenkort op dit platform. Controleer je store of launcher straks opnieuw.';

  @override
  String get gameModeLabel => 'MODUS';

  @override
  String get gameNameLabel => 'SPELNAAM';

  @override
  String get playersLabel => 'SPELERS';

  @override
  String get countryLabel => 'LAND';

  @override
  String get countryPoland => 'Polen';

  @override
  String get countryUkraine => 'Oekraïne';

  @override
  String get countryGermany => 'Duitsland';

  @override
  String get countryFrance => 'Frankrijk';

  @override
  String get countryUnitedKingdom => 'Verenigd Koninkrijk';

  @override
  String get countryItaly => 'Italië';

  @override
  String get countrySpain => 'Spanje';

  @override
  String get countryNetherlands => 'Nederland';

  @override
  String get countrySweden => 'Zweden';

  @override
  String get countryRussia => 'Rusland';

  @override
  String get countryUnitedStates => 'Verenigde Staten';

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
  String get countryLeaderPoland => 'Casimir III de Grote';

  @override
  String get countryLeaderUkraine => 'Jaroslav de Wijze';

  @override
  String get countryLeaderGermany => 'Otto von Bismarck';

  @override
  String get countryLeaderFrance => 'Napoleon Bonaparte';

  @override
  String get countryLeaderUnitedKingdom => 'Koningin Victoria';

  @override
  String get countryLeaderItaly => 'Julius Caesar';

  @override
  String get countryLeaderSpain => 'Isabella I';

  @override
  String get countryLeaderNetherlands => 'Willem van Oranje';

  @override
  String get countryLeaderSweden => 'Gustaaf Adolf';

  @override
  String get countryLeaderRussia => 'Catharina de Grote';

  @override
  String get countryLeaderUnitedStates => 'Abraham Lincoln';

  @override
  String get countryLeaderCanada => 'Wilfrid Laurier';

  @override
  String get countryLeaderChina => 'Qin Shi Huang';

  @override
  String get countryLeaderKorea => 'Sejong de Grote';

  @override
  String get countryLeaderJapan => 'Tokugawa Ieyasu';

  @override
  String get countryLeaderPortugal => 'Hendrik de Zeevaarder';

  @override
  String get addPlayerAction => '+ SPELER TOEVOEGEN';

  @override
  String get startGameAction => 'BEGIN';

  @override
  String get removePlayerTooltip => 'Speler verwijderen';

  @override
  String get multiplayerSearchTitle => 'SERVER ZOEKEN';

  @override
  String get multiplayerSearchBody =>
      'De lijst met online games verschijnt hier.';

  @override
  String get multiplayerPlayersTitle => 'Spelers';

  @override
  String get multiplayerStatusTooltip => 'Spelerstatus';

  @override
  String multiplayerAvatarTooltip(String playerName, String status) {
    return '$playerName $status';
  }

  @override
  String multiplayerAvatarTooltipWithRelation(
    String playerName,
    String status,
    String relation,
  ) {
    return '$playerName $status\nRelaties: $relation';
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
    return '$playerName\n$defaultName\nRelaties: $relation';
  }

  @override
  String get multiplayerStatusActive => 'speelt nu';

  @override
  String get multiplayerStatusSubmitted => 'beurt verzonden';

  @override
  String get multiplayerStatusThinking => 'denken';

  @override
  String get multiplayerStatusWaiting => 'wachten';

  @override
  String get multiplayerStatusTimeout => 'time-out';

  @override
  String get diplomacyRelationFriendly => 'vriendelijk';

  @override
  String get diplomacyRelationNeutral => 'neutrale';

  @override
  String get diplomacyRelationHostile => 'gewelddadig';

  @override
  String get diplomacyRelationTruce => 'bestand';

  @override
  String get diplomacyRelationWar => 'oorlog';

  @override
  String get diplomacyRelationFriendlyShort => 'fr.';

  @override
  String get diplomacyRelationNeutralShort => 'neut.';

  @override
  String get diplomacyRelationHostileShort => 'gastheer.';

  @override
  String get diplomacyRelationTruceShort => 'bestand';

  @override
  String get diplomacyRelationWarShort => 'oorlog';

  @override
  String get commonDiplomacy => 'Diplomatie';

  @override
  String get diplomacyScoreLabel => 'Betrekkingen';

  @override
  String get diplomacyScoreDriversTitle => 'Wat relaties verandert';

  @override
  String get diplomacyScoreReasonManual => 'Handmatige wijziging';

  @override
  String get diplomacyScoreReasonUnitAttack => 'Aanval op eenheid';

  @override
  String get diplomacyScoreReasonCityAttack => 'Aanval op stad';

  @override
  String get diplomacyScoreReasonDeclarationOfWar => 'Oorlogsverklaring';

  @override
  String get diplomacyScoreReasonWarmongerPenalty => 'Straf voor oorlogszucht';

  @override
  String get diplomacyScoreReasonProposalAccepted => 'Voorstel geaccepteerd';

  @override
  String get diplomacyScoreReasonProposalRejected => 'Voorstel afgewezen';

  @override
  String get diplomacyScoreReasonMessageResponse => 'Reactie op bericht';

  @override
  String get diplomacyScoreReasonPromiseBroken => 'Belofte gebroken';

  @override
  String get diplomacyStatsTitle => 'Statistieken';

  @override
  String get diplomacyHistoryTitle => 'Geschiedenis';

  @override
  String get diplomacyMessagesTitle => 'Verzendingen';

  @override
  String get diplomacyIncomingMessageTitle => 'Nieuw bericht';

  @override
  String diplomacyIncomingMessageFrom(String playerName) {
    return 'Van: $playerName';
  }

  @override
  String get diplomacyIncomingProposalTitle => 'Nieuw voorstel';

  @override
  String diplomacyIncomingProposalFrom(String playerName) {
    return 'Van: $playerName';
  }

  @override
  String get diplomacyIncomingMessageLater => 'Later';

  @override
  String get diplomacyActionsTitle => 'Acties';

  @override
  String get diplomacyProposalsTitle => 'Voorstellen';

  @override
  String get diplomacyNoHistory => 'Geen geregistreerde incidenten.';

  @override
  String get diplomacyNoMessages => 'Geen verzendingen.';

  @override
  String get diplomacyMilitaryStat => 'Militair';

  @override
  String get diplomacyCitiesStat => 'Steden';

  @override
  String get diplomacyExpansionStat => 'Uitbreiding';

  @override
  String get diplomacyArtifactsStat => 'Artefacten';

  @override
  String get diplomacyLastAggressionStat => 'Laatste agressie';

  @override
  String get diplomacyOwnArtifactsLabel => 'Jouw artefacten';

  @override
  String get diplomacyTargetArtifactsLabel => 'Rivaliserende artefacten';

  @override
  String diplomacyTurnsRemaining(int turns) {
    return 'Draait naar links: $turns';
  }

  @override
  String get diplomacyProposalFriendship => 'Vriendschapsvoorstel';

  @override
  String get diplomacyProposalTruce => 'Wapenstilstandsvoorstel';

  @override
  String diplomacyProposalForecastLine(
    String proposal,
    String outcome,
    String reasons,
  ) {
    return '$proposal: $outcome · $reasons';
  }

  @override
  String get diplomacyProposalForecastAccepted => 'waarschijnlijk geaccepteerd';

  @override
  String get diplomacyProposalForecastRejected => 'waarschijnlijk afgewezen';

  @override
  String get diplomacyProposalForecastReasonAcceptableRelations =>
      'relaties zijn werkbaar';

  @override
  String get diplomacyProposalForecastReasonActiveWar => 'actieve oorlog';

  @override
  String get diplomacyProposalForecastReasonAtWar =>
      'vriendschap geblokkeerd door oorlog';

  @override
  String get diplomacyProposalForecastReasonLowRelations => 'relaties te laag';

  @override
  String get diplomacyProposalForecastReasonMilitaryPressure =>
      'militaire druk';

  @override
  String get diplomacyProposalForecastReasonRecentHostility =>
      'recente vijandigheid';

  @override
  String get diplomacySendFriendship => 'Stel vriendschap voor';

  @override
  String get diplomacySendTruce => 'Stel een wapenstilstand voor';

  @override
  String get diplomacyDeclareWar => 'Verklaar de oorlog';

  @override
  String get diplomacyAccept => 'Accepteren';

  @override
  String get diplomacyDecline => 'Afwijzen';

  @override
  String get diplomacyMessageTroopsNearCities =>
      'Er zijn te veel troepen in de buurt van mijn steden geplaatst.';

  @override
  String get diplomacyMessageCitiesTooClose =>
      'Jullie stichten steden te dicht bij mijn grenzen.';

  @override
  String get diplomacyMessageBlockedRoutes =>
      'Jouw eenheden blokkeren mijn routes.';

  @override
  String get diplomacyMessageWithdrawScouts =>
      'Trek alstublieft uw verkenners terug uit mijn territorium.';

  @override
  String get diplomacyMessageAvoidEscalation =>
      'Onze beschavingen moeten verdere escalatie vermijden.';

  @override
  String get diplomacyMessageCommonEnemy =>
      'Een gemeenschappelijke vijand bedreigt ons allebei.';

  @override
  String get diplomacyMessageExpansionProvocation =>
      'Uw expansie wordt gezien als een provocatie.';

  @override
  String get diplomacyMessagePeacefulPraise =>
      'Wij waarderen de vreedzame betrekkingen tussen onze volkeren.';

  @override
  String get diplomacyResponseConciliatory => 'Verzoenend';

  @override
  String get diplomacyResponseNeutral => 'Neutrale';

  @override
  String get diplomacyResponseEvasive => 'Ontwijkend';

  @override
  String get diplomacyResponseAggressive => 'Agressief';

  @override
  String get diplomacyStrategicResourcesTitle => 'Strategische grondstoffen';

  @override
  String get diplomacyResourceTradeBlockedByWar =>
      'Grondstoffenhandel is geblokkeerd door oorlog.';

  @override
  String get diplomacyResourceTradeNoAvailableResources =>
      'Er zijn geen vrije strategische grondstoffen beschikbaar voor handel.';

  @override
  String diplomacyResourceTradeImportOffer(int goldPerTurn, int durationTurns) {
    return 'Importaanbod: $goldPerTurn goud/beurt gedurende $durationTurns beurten.';
  }

  @override
  String diplomacyResourceTradeImportAction(String resourceName) {
    return '$resourceName importeren';
  }

  @override
  String diplomacyResourceTradeExchangeOffer(int durationTurns) {
    return 'Ruilhandel: grondstof voor grondstof gedurende $durationTurns beurten.';
  }

  @override
  String diplomacyResourceTradeExchangeAction(
    String offeredResource,
    String requestedResource,
  ) {
    return '$offeredResource ruilen voor $requestedResource';
  }

  @override
  String get diplomacyResourceTradeNoActiveAgreements =>
      'Geen actieve grondstoffenakkoorden.';

  @override
  String get diplomacyResourceTradeImportDirection => 'Importeert';

  @override
  String get diplomacyResourceTradeExportDirection => 'Exporteert';

  @override
  String get diplomacyResourceTradeBarterPrice => 'ruil';

  @override
  String diplomacyResourceTradeGoldPerTurnPrice(int goldPerTurn) {
    return '$goldPerTurn goud/beurt';
  }

  @override
  String diplomacyResourceTradeAgreementLabel(
    String direction,
    String resourceName,
    String price,
    int remainingTurns,
  ) {
    return '$direction $resourceName · $price · $remainingTurns beurten';
  }

  @override
  String get notFoundScreenTitle => 'Scherm niet gevonden';

  @override
  String get notFoundBackToMenuAction => 'MENU';

  @override
  String get loadGameTitle => 'LAAD SPEL';

  @override
  String get loadGameHeaderTitle => 'Opgeslagen spellen';

  @override
  String get loadGameHeaderEmptySubtitle => 'Er is nog geen spel gestart.';

  @override
  String get loadGameHeaderSavesSubtitle =>
      'Keer terug naar recente wedstrijden en ga verder vanaf de opgeslagen beurt.';

  @override
  String loadGameSavesCount(int count) {
    return 'Opgeslagen: $count';
  }

  @override
  String get loadGameCorruptedStatus => 'Beschadigde save';

  @override
  String get loadGameCorruptedAction => 'Niet beschikbaar';

  @override
  String get loadGameCorruptedBody =>
      'Deze save kan niet worden gelezen. U kunt deze uit de lijst verwijderen.';

  @override
  String get replayTitle => 'HERHAAL';

  @override
  String get replayAction => 'HERHAAL';

  @override
  String get replayUnavailableAction => 'GEEN HERHAAL';

  @override
  String get replayErrorTitle => 'Herhaling niet beschikbaar';

  @override
  String replayErrorBody(String error) {
    return 'Herhaling kan niet worden geopend: $error';
  }

  @override
  String get replayMissingInitialSnapshotBody =>
      'Deze opslag bevat geen momentopname van het herhalingszaad. Start een nieuw spel om de volledige herhalingsgegevens van de wedstrijd vast te leggen.';

  @override
  String get replayCorruptLogBody =>
      'Het replay-opdrachtlogboek is onvolledig of kan niet worden gelezen.';

  @override
  String replayStepCounter(int step, int total) {
    return 'Stap $step/$total';
  }

  @override
  String endTurnButtonTurnLabel(int turn) {
    return 'BEURT $turn';
  }

  @override
  String replayTurnLabel(int turn) {
    return 'Draai $turn';
  }

  @override
  String replayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gebeurtenissen',
      one: '1 gebeurtenis',
      zero: '0 gebeurtenissen',
    );
    return '$_temp0';
  }

  @override
  String get replayInitialStateLabel => 'Initiële staat';

  @override
  String get replayPreviousAction => 'Vorige stap';

  @override
  String get replayNextAction => 'Volgende stap';

  @override
  String get replayPlayAction => 'Speel herhaling';

  @override
  String get replayPauseAction => 'Pauzeer het opnieuw afspelen';

  @override
  String get replaySpeedLabel => 'Snelheid';

  @override
  String get replayPerspectiveLabel => 'Perspectief';

  @override
  String get replayAllPlayers => 'Alle spelers';

  @override
  String get replayShowTurnsLabel => 'Beurten tonen';

  @override
  String get replayFreeCameraLabel => 'Vrije camera';

  @override
  String mapsLoadError(String error) {
    return 'Kan kaarten niet laden: $error';
  }

  @override
  String get editorMapPickerTitle => 'Editor kaarten';

  @override
  String get editorMapPickerSubtitle =>
      'Creëer nieuwe werelden of verfijn bestaande kaarten.';

  @override
  String get editorMapPickerEmptyTitle => 'Geen opgeslagen kaarten';

  @override
  String get editorMapPickerEmptyMessage =>
      'Maak een nieuwe kaart vanuit de schermkop.';

  @override
  String get editorNewMapAction => 'Nieuwe kaart';

  @override
  String get editorDeleteMapTooltip => 'Kaart verwijderen';

  @override
  String get editorDeleteMapTitle => 'Kaart verwijderen?';

  @override
  String editorDeleteMapMessage(String name) {
    return 'Hierdoor worden “$name” en alle kaartbestanden permanent verwijderd.';
  }

  @override
  String get editorOpenMapErrorTitle => 'Kon de kaart niet openen';

  @override
  String get editorCollapseToolbarTooltip => 'Editorvenster samenvouwen';

  @override
  String get editorExpandToolbarTooltip => 'Vouw het editorpaneel uit';

  @override
  String officialMapsCount(int count) {
    return 'Officieel: $count';
  }

  @override
  String yourMapsCount(int count) {
    return 'Van jou: $count';
  }

  @override
  String get officialMapsSection => 'Officieel';

  @override
  String get yourMapsSection => 'Jouw kaarten';

  @override
  String get playAction => 'Toneelstuk';

  @override
  String get editAction => 'Bewerking';

  @override
  String get noMapsTitle => 'Geen kaarten';

  @override
  String get noMapsMessage =>
      'Er zijn geen kaarten gevonden om een ​​spel te starten.';

  @override
  String get gameLengthLabel => 'Spellengte';

  @override
  String get gameLengthPresetHint => 'Spelvoorinstelling';

  @override
  String get gameLengthPresetUnlimited => 'Onbeperkt';

  @override
  String get gameLengthPresetShort60 => 'Kort';

  @override
  String get gameLengthPresetNormal90 => 'Normaal';

  @override
  String get gameLengthPresetStandard60 => 'Standaard 60 min';

  @override
  String get gameLengthPresetLong120 => 'Lang';

  @override
  String get gameLengthPresetVeryLong => 'Heel lang';

  @override
  String get gameLengthUnlimitedSummary =>
      'Geen beurtlimiet - huidig ​​speltempo';

  @override
  String gameLengthTimedSummary(int minutes, int turns) {
    return '$minutes min doel - $turns beurtlimiet';
  }

  @override
  String get gameLengthScoreFallbackOn => 'met scoreterugval';

  @override
  String get gameLengthScoreFallbackOff => 'zonder scoreterugval';

  @override
  String get aiDifficultyLabel => 'AI-moeilijkheid';

  @override
  String get aiDifficultyEasy => 'Eenvoudig';

  @override
  String get aiDifficultyNormal => 'Normaal';

  @override
  String get aiDifficultyHard => 'Moeilijk';

  @override
  String get aiDifficultyVeryHard => 'Heel moeilijk';

  @override
  String gameLengthVictoryRules(
    String controlPercent,
    int holdTurns,
    String fallback,
  ) {
    return 'Verovering + overheersing $controlPercent%/$holdTurns beurten - $fallback';
  }

  @override
  String get mapValidationErrorTitle => 'Kaart heeft reparaties nodig';

  @override
  String get mapValidationLoadingTitle => 'Kaart controleren';

  @override
  String get mapValidationWarningTitle =>
      'De kaart is mogelijk te langzaam voor deze voorinstelling';

  @override
  String mapValidationLoadError(String error) {
    return 'Kan kaart niet controleren: $error';
  }

  @override
  String get mapValidationLoadingMessage =>
      'Validatie van starts, bronnen en tempo bij het eerste contact.';

  @override
  String get mapValidationIssueSlowFirstContact =>
      'De startposities liggen ver uit elkaar; 60 minuten kunnen het eerste contact te veel vertragen.';

  @override
  String get mapValidationIssueLargeMap =>
      'De kaart heeft veel tegels per speler; voeg spelers toe of kies een langer spel.';

  @override
  String get mapValidationIssueInvalidPlayerCount =>
      'Het aantal spelers komt niet overeen met het bereik dat door deze kaart wordt ondersteund.';

  @override
  String get mapValidationIssueNoTiles => 'De kaart heeft geen tegels.';

  @override
  String get mapValidationIssueLowPassableTileRatio =>
      'De kaart heeft te weinig tegels die door landeenheden kunnen worden begaanbaar.';

  @override
  String get mapValidationIssueLowFoodResourceDensity =>
      'De kaart heeft te weinig voedselbronnen voor dit spelersaantal.';

  @override
  String get mapValidationIssueLowStrategicResourceDensity =>
      'De kaart heeft te weinig strategische middelen.';

  @override
  String get mapValidationIssueLowLuxuryResourceDensity =>
      'De kaart heeft te weinig luxe middelen.';

  @override
  String get mapValidationIssueStartSiteNotFoundable =>
      'De startende kolonist kan geen stad op zijn tegel vinden.';

  @override
  String get mapValidationIssueStartSiteLowLandRing =>
      'De start heeft te weinig begaanbare tegels in de eerste ring.';

  @override
  String get mapValidationIssueStartSiteLowFood =>
      'De start heeft geen zichtbare voedselbron in de buurt.';

  @override
  String get mapValidationIssueStartSiteLowCityControl =>
      'De start heeft te weinig legale tegels voor initiële stadscontrole.';

  @override
  String get mapValidationIssueStartSitesTooClose =>
      'De spelersstarts zijn te dicht bij elkaar.';

  @override
  String lobbyMapPlayersSummary(String mapName, int playerCount) {
    return '$mapName $playerCount-spelers';
  }

  @override
  String get lobbyHeaderTitle => 'Bereid de tafel voor';

  @override
  String get lobbyHeaderSubtitle =>
      'Bevestig eerst de beschaving en stem vervolgens de wedstrijd en stoelen af ​​vóór de eerste beurt.';

  @override
  String get lobbyCivilizationTitle => 'Kies beschaving';

  @override
  String get lobbyCivilizationSubtitle =>
      'Dit is de identiteit van de speler voor de openingsbeurt.';

  @override
  String get lobbyStepCivilization => 'Beschaving';

  @override
  String get lobbyStepSetup => 'Installatie';

  @override
  String get lobbyStepOnline => 'Online';

  @override
  String get lobbyStepPlayers => 'Spelers';

  @override
  String get lobbySetupTitle => 'Wedstrijdopstelling';

  @override
  String get lobbySetupSubtitle =>
      'Geef het spel een naam, kies het tempo en controleer of de kaart past bij het geselecteerde spelersaantal.';

  @override
  String get lobbyPlayersSetupTitle => 'Spelers aan tafel';

  @override
  String get lobbyPlayersSetupSubtitle =>
      'De startspeler neemt de openingsbeurt. Extra zitplaatsen kunnen mensen op dit apparaat of AI zijn.';

  @override
  String get lobbyPlayerYou => 'Jij';

  @override
  String get lobbyPlayerHost => 'Gastheer';

  @override
  String get lobbyPlayerReady => 'klaar';

  @override
  String get lobbyPlayerConnected => 'aangesloten';

  @override
  String get lobbyPlayerConnecting => 'verbinden';

  @override
  String get lobbyPlayerReconnecting => 'opnieuw verbinden';

  @override
  String get lobbyPlayerOffline => 'offline';

  @override
  String lobbyPlayerOpenSlot(int slotNumber) {
    return 'Open stoel $slotNumber';
  }

  @override
  String get lobbyPlayerRequiredSlot => 'Nodig om te beginnen';

  @override
  String get lobbyPlayerOptionalSlot => 'Kan vóór aanvang meedoen';

  @override
  String get playerKindHuman => 'Menselijk';

  @override
  String get playerKindAi => 'AI';

  @override
  String get multiplayerServerTitle => 'Online gameserver';

  @override
  String get connectAction => 'Verbinden';

  @override
  String get refreshAction => 'Vernieuwen';

  @override
  String get createMatchAction => 'Match creëren';

  @override
  String get noOpenMatches => 'Geen open wedstrijden';

  @override
  String get matchStatusRunning => 'Klaar';

  @override
  String get matchStatusFinished => 'Afgerond';

  @override
  String get matchStatusAbandoned => 'Verlaten';

  @override
  String matchPlayersCount(int players, int maxPlayers) {
    return '$players/$maxPlayers-spelers';
  }

  @override
  String matchReadyCount(int readyPlayers, int players) {
    return '$readyPlayers/$players gereed';
  }

  @override
  String matchTurnInfo(String mapName, String status, int turn) {
    return '$mapName $status draai $turn';
  }

  @override
  String openMatchInfo(String mapName, int players, int maxPlayers, int turn) {
    return '$mapName $players/$maxPlayers draai $turn';
  }

  @override
  String get enterMatchAction => 'Binnenkomen';

  @override
  String get hideMatchAction => 'Verbergen';

  @override
  String get joinMatchAction => 'Meedoen';

  @override
  String get cancelAction => 'ANNULEREN';

  @override
  String get copyAction => 'Kopiëren';

  @override
  String get shareAction => 'Deel';

  @override
  String get multiplayerHomeSubtitle =>
      'Kies een snelle wachtrij of een privécodematch voor vrienden.';

  @override
  String get multiplayerProfileTitle => 'Jouw profiel';

  @override
  String get multiplayerProfileSubtitle =>
      'Stel de naam en beschaving in die je in online wedstrijden gaat gebruiken.';

  @override
  String get multiplayerProfileOptionsSubtitle =>
      'Je bijnaam wordt gebruikt in multiplayerwedstrijden en moet uniek zijn.';

  @override
  String get multiplayerProfileSaveAction => 'Bijnaam opslaan';

  @override
  String get multiplayerProfileSaved => 'Bijnaam opgeslagen.';

  @override
  String get multiplayerLobbyHeaderTitle => 'Onlinelobby';

  @override
  String get multiplayerLobbyHeaderSubtitle =>
      'Kies eerst de beschaving en voer vervolgens quickplay in of maak een privétafel aan. De kaart wordt automatisch geselecteerd.';

  @override
  String get multiplayerCountryPickTitle => 'Kies beschaving';

  @override
  String get multiplayerCountryPickSubtitle =>
      'Dit is de belangrijkste keuze voordat u in de wachtrij gaat. Multiplayer-kaarten worden willekeurig geselecteerd.';

  @override
  String get multiplayerRandomMapLabel => 'Willekeurige kaart';

  @override
  String get multiplayerNicknameLabel => 'Bijnaam';

  @override
  String get multiplayerQuickplayTitle => 'Snel spel';

  @override
  String get multiplayerQuickplaySubtitle =>
      'Vindt spelers automatisch en begint vanaf 2 spelers.';

  @override
  String get multiplayerCreatePrivateTitle => 'Code maken';

  @override
  String get multiplayerCreatePrivateSubtitle =>
      'Privéwedstrijd zonder tijdslimiet, alleen voor vrienden.';

  @override
  String get multiplayerJoinPrivateTitle => 'Doe mee met code';

  @override
  String get multiplayerJoinPrivateSubtitle =>
      'Voer de code van een vriend in en wacht op de host.';

  @override
  String get multiplayerQueueReadyTitle => 'Wedstrijd klaar';

  @override
  String get multiplayerQueueSearchingTitle => 'Spelers zoeken';

  @override
  String get multiplayerQueueCountdownTitle => 'Binnenkort van start';

  @override
  String get multiplayerQueueConnectingSubtitle =>
      'Verbinding maken met de server en zoeken naar een wachtrij.';

  @override
  String multiplayerQueueWaitingForPlayers(int minPlayers) {
    return 'Wachten op minimaal $minPlayers-spelers.';
  }

  @override
  String get multiplayerQueuePreparingStart =>
      'Spelers gevonden. Wedstrijdstart voorbereiden.';

  @override
  String get multiplayerQueueStartingNow => 'Startwedstrijd...';

  @override
  String multiplayerQueueStartingIn(int seconds) {
    return 'Beginnend met ${seconds}s. Er kunnen nog steeds meer spelers meedoen.';
  }

  @override
  String get multiplayerPrivateTitle => 'Vrienden komen overeen';

  @override
  String get multiplayerPrivateHostReady => 'Je kunt de wedstrijd nu beginnen.';

  @override
  String get multiplayerPrivateWaitingForHost =>
      'Wachten tot de gastheer de wedstrijd begint.';

  @override
  String get multiplayerJoinCodeHelp =>
      'Voer de code in die je van een vriend hebt ontvangen.';

  @override
  String get multiplayerInviteCodeHint => 'Matchcode';

  @override
  String get multiplayerInviteCodeLabel => 'Matchcode';

  @override
  String get multiplayerInviteCopied => 'Matchcode gekopieerd.';

  @override
  String multiplayerInviteShareText(String inviteCode) {
    return 'Doe mee met mijn AONW-wedstrijd. Code: $inviteCode';
  }

  @override
  String get multiplayerInviteCodeRequired => 'Voer een wedstrijdcode in.';

  @override
  String get multiplayerMapNotReady =>
      'Deze kaart is niet klaar voor multiplayer.';

  @override
  String multiplayerRequestRejected(int statusCode) {
    return 'De server heeft het verzoek afgewezen ($statusCode).';
  }

  @override
  String multiplayerRequestRejectedWithReason(int statusCode, String reason) {
    return 'De server heeft het verzoek afgewezen ($statusCode: $reason).';
  }

  @override
  String multiplayerConnectionError(String host) {
    return 'Kan geen verbinding maken met $host. Controleer uw internetverbinding en probeer het opnieuw.';
  }

  @override
  String get multiplayerSignInRequired =>
      'Meld je aan of maak een account aan om multiplayer te spelen.';

  @override
  String get multiplayerSessionExpired =>
      'Je multiplayersessie is verlopen. Meld u opnieuw aan en probeer het opnieuw.';

  @override
  String get multiplayerAccountTitle => 'Multiplayeraccount';

  @override
  String get multiplayerAccountSubtitle =>
      'Meld je aan of maak een account aan om door te gaan.';

  @override
  String get multiplayerAccountEmailLabel => 'Email';

  @override
  String get multiplayerAccountPasswordLabel => 'Wachtwoord';

  @override
  String get multiplayerAccountSignInTab => 'Aanmelden';

  @override
  String get multiplayerAccountCreateTab => 'Account maken';

  @override
  String get multiplayerAccountSignInAction => 'Aanmelden';

  @override
  String get multiplayerAccountCreateAction => 'Account maken';

  @override
  String get multiplayerAccountSignOutAction => 'Afmelden';

  @override
  String get multiplayerAccountSignedOut => 'Afgemeld bij multiplayer.';

  @override
  String get multiplayerAccountInvalidEmail => 'Voer een geldig emailadres in.';

  @override
  String get multiplayerAccountInvalidCredentials =>
      'Email of wachtwoord is ongeldig.';

  @override
  String get multiplayerAccountExists =>
      'Er bestaat al een account met deze email.';

  @override
  String get multiplayerAccountWeakPassword =>
      'Het wachtwoord moet minimaal 8 tekens lang zijn.';

  @override
  String get multiplayerAccountInvalidNickname =>
      'Gebruik 3-24 letters, cijfers, spaties, _ of -.';

  @override
  String get multiplayerAccountNicknameTaken =>
      'Deze bijnaam is al in gebruik.';

  @override
  String get multiplayerAccountGenericError =>
      'Authenticatie is mislukt. Probeer het opnieuw.';

  @override
  String get multiplayerMatchUnavailable =>
      'Deze wedstrijd is niet langer beschikbaar.';

  @override
  String get multiplayerMatchFull => 'Deze wedstrijd is vol.';

  @override
  String get multiplayerCountryUnavailable =>
      'Meerdere spelers hebben jouw beschaving gekozen. Probeer een andere.';

  @override
  String get multiplayerMatchNotReady =>
      'De wedstrijd is nog niet klaar om te beginnen.';

  @override
  String get multiplayerMatchAccessDenied =>
      'Je bent geen speler in deze wedstrijd.';

  @override
  String get multiplayerQueueGenericError =>
      'Kon niet in de multiplayer-wachtrij komen. Probeer het opnieuw.';

  @override
  String get multiplayerResumeAction => 'Hervat het spel';

  @override
  String get multiplayerResumeSublabel =>
      'Keer terug naar de laatste multiplayersessie';

  @override
  String get multiplayerResumeLoading => 'Verbinden met match...';

  @override
  String get multiplayerResumeFailed =>
      'Kan de laatste multiplayersessie niet hervatten.';

  @override
  String get optionsTooltip => 'Opties';

  @override
  String get optionsOpenMenuTooltip => 'Menu openen';

  @override
  String optionsTooltipWithCollapseHint(String tooltip) {
    return '$tooltip. Houd ingedrukt om het menu samen te vouwen.';
  }

  @override
  String get optionsTitle => 'Opties';

  @override
  String get optionsSubtitle => 'Tekst, taal, audio en uitvoering';

  @override
  String get languageSectionTitle => 'Taal';

  @override
  String get languagePolish => 'Pools';

  @override
  String get languageEnglish => 'Engels';

  @override
  String get languageFrench => 'Frans';

  @override
  String get languageGerman => 'Duits';

  @override
  String get languageSpanish => 'Spaans';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get textScaleStandard => 'Standaard';

  @override
  String get textScaleLarge => 'Groot';

  @override
  String get textScaleExtraLarge => 'Extra groot';

  @override
  String textScaleSemanticLabel(String label) {
    return 'Tekstgrootte $label';
  }

  @override
  String textScaleTooltip(String label) {
    return 'Tekstgrootte: $label';
  }

  @override
  String languageSemanticLabel(String label) {
    return 'Taal $label';
  }

  @override
  String languageTooltip(String label) {
    return 'Taal: $label';
  }

  @override
  String get audioSectionTitle => 'Audio';

  @override
  String get gameSoundsLabel => 'Spelgeluiden';

  @override
  String get soundVolumeLabel => 'Geluidsvolume';

  @override
  String get gameMusicLabel => 'Spelmuziek';

  @override
  String get musicVolumeLabel => 'Muziekvolume';

  @override
  String get natureSoundsLabel => 'Natuur klinkt';

  @override
  String get natureVolumeLabel => 'Natuurvolume';

  @override
  String get aiSectionTitle => 'AI';

  @override
  String get aiBatterySaverLabel => 'AI-batterijbesparing';

  @override
  String get gameplaySectionTitle => 'Gameplay';

  @override
  String get followUnitMovementCameraLabel =>
      'Volg eenheidsbeweging met de camera';

  @override
  String get followEnemyUnitCameraLabel =>
      'Volg vijandelijke eenheden met de camera';

  @override
  String get cinematicCameraLabel => 'Filmische camera';

  @override
  String get performanceSectionTitle => 'Prestatie';

  @override
  String get showFpsLabel => 'FPS tonen';

  @override
  String get showMapZoomLabel => 'Toon kaartzoom';

  @override
  String get mapViewModeTooltip => 'Wijzig de kaartweergavemodus';

  @override
  String get mapViewGraphicUnavailableTooltip =>
      'De grafische modus is niet beschikbaar voor deze kaart';

  @override
  String get mapViewModeGraphic => 'Grafisch';

  @override
  String get mapViewModeTiles => 'Tegels';

  @override
  String get gameOptionTerrain => 'Terrein';

  @override
  String get gameOptionResources => 'Bronnen';

  @override
  String get gameOptionHeight => 'Hoogte';

  @override
  String get gameOptionCitySites => 'Stadssites';

  @override
  String get gameOptionCityGrowth => 'Groei van de stad';

  @override
  String get gameOptionShowHexes => 'Hexen tonen';

  @override
  String get gameOptionShowHeight => 'Hoogte tonen';

  @override
  String get gameOptionDiceTest => 'Dobbelstenen test';

  @override
  String get gameOptionAutoActionFlow => 'Acties automatisch afronden';

  @override
  String get gameOptionAutoTurnFlow => 'Beurten automatisch beëindigen';

  @override
  String get helpPopupsTitle => 'Hints';

  @override
  String get autoTurnHintTitle => 'Beurten automatisch beëindigen';

  @override
  String get autoTurnHintBody =>
      'Automatisch beurten beëindigen verstuurt de beurt wanneer er geen belangrijke acties meer over zijn. Automatisch acties afronden kun je apart regelen in de kaartopties.';

  @override
  String get autoTurnHintEnableAction => 'Inschakelen';

  @override
  String get autoTurnHintDisableAction => 'Uitzetten';

  @override
  String get autoTurnHintStatusOn => 'Ingeschakeld';

  @override
  String get autoTurnHintStatusOff => 'Gehandicapt';

  @override
  String get autoTurnHintMinimizedSubtitle =>
      'Snelle schakelaar voor automatische draaistroom.';

  @override
  String visibilityShowAction(String label) {
    return 'Toon $label';
  }

  @override
  String visibilityHideAction(String label) {
    return '$label verbergen';
  }

  @override
  String get resignAction => 'Ontslag nemen';

  @override
  String get resignMatchTitle => 'Opzeggen van de wedstrijd?';

  @override
  String get resignMatchMessage => 'De wedstrijd zal worden beëindigd.';

  @override
  String get resignMatchError => 'Kon de wedstrijd niet opgeven.';

  @override
  String get creditsTitle => 'Kredieten';

  @override
  String creditsCreatedBy(String name) {
    return 'Gemaakt door $name';
  }

  @override
  String get deleteGameTitle => 'Spel verwijderen';

  @override
  String deleteGameMessage(String name) {
    return '\'$name\' verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get deleteAction => 'VERWIJDEREN';

  @override
  String get retryAction => 'OPNIEUW PROBEREN';

  @override
  String get noSavedGames => 'Geen opgeslagen spellen.';

  @override
  String get resumeAction => 'CV';

  @override
  String get newGameAction => 'NIEUW SPEL';

  @override
  String get turnActionButtonLabel => 'Actie';

  @override
  String get endTurnButtonLabel => 'Einde beurt';

  @override
  String get waitingTurnButtonLabel => 'Wachten';

  @override
  String get waitingForPlayersTooltip => 'Wachten op andere spelers';

  @override
  String submitTurnTooltip(int turn) {
    return 'Gereedheid indienen bij beurt $turn';
  }

  @override
  String endTurnTooltip(int turn) {
    return 'Einde beurt $turn';
  }

  @override
  String get nextActionTooltip => 'Ga naar de volgende actie';

  @override
  String nextActionWithCountTooltip(int count) {
    return 'Ga naar de volgende actie ($count links)';
  }

  @override
  String get turnActionListTooltip => 'Kies een actie uit de lijst';

  @override
  String get hudActionDeckCollapseTooltip => 'Onderste werkbalk samenvouwen';

  @override
  String get hudActionDeckExpandTooltip => 'Vouw de onderste werkbalk uit';

  @override
  String get turnActionUnitKind => 'Eenheid';

  @override
  String get turnActionCityProductionKind => 'Stad';

  @override
  String get turnActionResearchKind => 'Onderzoek';

  @override
  String turnActionCityProductionLabel(String cityName) {
    return '$cityName-productie';
  }

  @override
  String get turnActionResearchLabel => 'Kies voor onderzoek';

  @override
  String turnLabel(int turn) {
    return 'DRAAI $turn';
  }

  @override
  String loadGameError(String error) {
    return 'Laadfout: $error';
  }

  @override
  String get backAction => 'Rug';

  @override
  String get continueAction => 'Doorgaan';

  @override
  String get gameLoadingTitle => 'Wereld laden';

  @override
  String get gameLoadingMessage =>
      'De kaart, eenheden en interface voorbereiden. Het spel verschijnt zodra de middelen gereed zijn.';

  @override
  String get firstTurnTutorialPopupTitle => 'Handleiding';

  @override
  String get firstTurnTutorialPopupSubtitle => 'Gids voor de eerste beurt';

  @override
  String firstTurnTutorialSemantics(String title) {
    return 'Eerste beurt: $title';
  }

  @override
  String firstTurnCoachmarkProgressLabel(int current, int total) {
    return 'Stap $current/$total';
  }

  @override
  String get firstTurnCoachmarkMinimizeTooltip => 'Minimaliseer';

  @override
  String get firstTurnCoachmarkSkipAction => 'Overslaan';

  @override
  String get firstTurnCoachmarkNextAction => 'Volgende';

  @override
  String get firstTurnCoachmarkDoneAction => 'Klaar';

  @override
  String get firstTurnCoachmarkSelectionTitle => 'Stap 1: lees de selectie';

  @override
  String get firstTurnCoachmarkSelectionBody =>
      'Het spel begint met het automatisch selecteren van je eerste eenheid. Het onderste paneel vertelt je wat je beveelt, hoeveel acties er nog over zijn en welke orders je nu kunt geven.';

  @override
  String get firstTurnCoachmarkSelectionBodyUnit =>
      'De onderste werkbalk beschrijft de geselecteerde eenheid: type, beweging, actiewachtrij en beschikbare orders. Gebruik het om naar de Verplaatsmodus te gaan en annuleer het als je wilt dat zeskantige tikken terugkeren naar inspectie.';

  @override
  String get firstTurnCoachmarkSelectionBodyCity =>
      'Je hebt een stad geselecteerd. Het onderste paneel toont de productie, bevolking, gebouwen en economische beslissingen. Dat is een andere context dan eenheidsbestellingen, dus de tutorial zal over de stad gaan.';

  @override
  String get firstTurnCoachmarkSelectionBodyNone =>
      'Als er niets is geselecteerd, toont het onderste paneel de algemene beurtstatus. Tik op een van je eenheden of steden om concrete orders en informatie te zien.';

  @override
  String get firstTurnCoachmarkResourcesTitle =>
      'Stap 2: controleer je imperium';

  @override
  String get firstTurnCoachmarkResourcesBody =>
      'De bovenste balk toont de beurt, het goud, de wetenschap en de grondstoffen. Goud ondersteunt de economie, wetenschap stimuleert onderzoek en hulpbronnen geven aan wat de moeite waard is om te bouwen.';

  @override
  String get firstTurnCoachmarkMenuTitle => 'Stap 3: leer het linkermenu';

  @override
  String get firstTurnCoachmarkMenuBody =>
      'Het linkermenu bevat weergaven die je elke beurt opnieuw bezoekt: kaartopties, geminimaliseerde pop-upantwoorden, doelstellingen, logboek, onderzoek en imperium. Druk lang op de menuknop om de rail in te klappen en tik vervolgens op de enkele knop om deze weer te openen.';

  @override
  String get firstTurnCoachmarkActionTitle => 'Stap 4: geef de juiste volgorde';

  @override
  String get firstTurnCoachmarkActionBodyActive =>
      'Als de kolonist op een goede tegel staat, gebruik dan de actie Stad gevonden. Als de locatie zwak is, verplaats je de eenheid en maak je terrein zichtbaar. Beweging en speciale acties duren de beurt van die eenheid.';

  @override
  String get firstTurnCoachmarkActionBodyWaiting =>
      'Als een eenheid een opdracht heeft, wordt deze hier weergegeven. In de eerste beurten beweeg je één voor één door eenheden en steden totdat er geen belangrijke beslissing meer overblijft.';

  @override
  String get firstTurnCoachmarkActionBodySettler =>
      'De kolonist bepaalt de start van je rijk. Als de tegel groei, productie en ruimte biedt om uit te breiden, zoek dan een stad. Als het terrein zwak is, verplaats dan de kolonist en inspecteer eerst het nabijgelegen land.';

  @override
  String get firstTurnCoachmarkActionBodyWorker =>
      'Een arbeider vindt geen steden. Het is zijn taak om tegels binnen de stadsgrenzen te verbeteren: boerderijen helpen de groei, mijnen stimuleren de productie en verbeteringen van hulpbronnen versterken de economie.';

  @override
  String get firstTurnCoachmarkActionBodyUnit =>
      'Voor gevechts- en verkenningseenheden zijn beweging, zicht en veiligheid het belangrijkst. Onthul terrein, bescherm stadsgrenzen en val alleen aan als het voorspelde resultaat gunstig is.';

  @override
  String get firstTurnCoachmarkActionBodyCity =>
      'Wanneer een stad wordt geselecteerd, leidt dit gebied tot productie en beheer. Kies een bouwdoel, controleer de groei van de stad en zorg ervoor dat de stad niet stilstaat.';

  @override
  String get firstTurnCoachmarkResearchTitle => 'Stap 5: kies voor onderzoek';

  @override
  String get firstTurnCoachmarkResearchBody =>
      'Open Onderzoek voordat je de beurt beëindigt. Landbouw ondersteunt de groei, mijnbouw stimuleert de productie en jacht verbetert de verkenning en verdediging. Het allerbelangrijkste is dat de wetenschap niet zonder doel mag opereren.';

  @override
  String get firstTurnCoachmarkResearchBodyAvailable =>
      'Onderzoek is klaar om te kiezen. Open onderzoek voordat de beurt eindigt: landbouw ondersteunt de groei, mijnbouw verhoogt de productie en jacht verbetert de verkenning en verdediging.';

  @override
  String get firstTurnCoachmarkCityTitle => 'Stap 6: richt de stad in';

  @override
  String get firstTurnCoachmarkCityBody =>
      'Kies na de oprichting van de hoofdstad voor productie. Een arbeider ontwikkelt tegels, een krijger beveiligt het gebied en gebouwen versterken de economie. De stad moet altijd iets bouwen.';

  @override
  String get firstTurnCoachmarkCityBodySelected =>
      'Dit is het stadspaneel. Controleer productie, groei, gebouwen en beschikbare projecten. De hoofdregel voor nieuwe beurten: elke stad moet een productiedoel hebben.';

  @override
  String get firstTurnCoachmarkCityBodyNeedsProduction =>
      'Een van je steden wacht op productie. Gebruik de actieknop of selecteer de stad, kies een eenheid, gebouw of project en beëindig dan pas de beurt.';

  @override
  String get firstTurnCoachmarkCityBodyExisting =>
      'Aan jouw steden is al productie toegewezen. In latere beurten kom je hier terug om groei, gebouwen, specialisatie en defensiebehoeften te bekijken.';

  @override
  String get firstTurnCoachmarkCityBodyFuture =>
      'Nadat je de eerste stad hebt gevonden, keer je hier terug om de productie te kiezen. Een arbeider ontwikkelt tegels, een krijger beveiligt het gebied en gebouwen versterken de economie.';

  @override
  String get firstTurnCoachmarkActionFlowTitle =>
      'Stap 7: maak de actiewachtrij leeg';

  @override
  String get firstTurnCoachmarkActionFlowBodyReady =>
      'Alle belangrijke beslissingen voor deze beurt zijn klaar. Voordat je de beurt beëindigt, bevestig je snel dat onderzoek en stadsproductie beide een doelwit hebben.';

  @override
  String get firstTurnCoachmarkActionFlowBodyPending =>
      'De actieknop leidt naar de volgende eenheid, stad of ontbrekende keuze. Blijf erop drukken totdat het spel laat zien dat het veilig is om de beurt te beëindigen.';

  @override
  String get firstTurnCoachmarkEndTurnTitle =>
      'Stap 8: beëindig de beurt en herhaal';

  @override
  String get firstTurnCoachmarkEndTurnBody =>
      'Als niets jouw reactie nodig heeft, beëindig je de beurt. Het ritme van de volgende beurten is hetzelfde: grondstoffen, eenheden, stad, onderzoek en dan de eindbeurt.';

  @override
  String get firstTurnCoachmarkVictoryBody =>
      'Je kunt winnen door dominantie of artefacten: plaats 6 unieke artefacten in je steden en houd de collectie 5 beurten vast.';

  @override
  String get firstTurnCoachmarkHexTapBody =>
      'Klik of tik meerdere keren op dezelfde hex om de informatie te wisselen: tegelkeuze, artefact, kaartdoel en hexbeschrijving.';

  @override
  String get gameLoadMapErrorTitle => 'Kan kaart niet laden';

  @override
  String gameLoadMapErrorMessage(String mapName, String error) {
    return 'Kan kaart \"$mapName\" niet laden: $error';
  }

  @override
  String get gameOutcomeVictoryTitle => 'Overwinning';

  @override
  String get gameOutcomeDefeatTitle => 'Verlies';

  @override
  String get gameOutcomeDrawTitle => 'Tekenen';

  @override
  String get gameOutcomeCompleteTitle => 'Spel voorbij';

  @override
  String get gameOutcomeConditionConquest => 'Verovering';

  @override
  String get gameOutcomeConditionScore => 'Scoren';

  @override
  String get gameOutcomeConditionScoreDraw => 'Score gelijkspel';

  @override
  String get gameOutcomeConditionDomination => 'Overheersing';

  @override
  String get gameOutcomeConquestNoWinner =>
      'Eén imperium blijft op de kaart staan.';

  @override
  String gameOutcomeConquestWinner(String winner) {
    return '$winner is het laatste imperium op de kaart.';
  }

  @override
  String get gameOutcomeScoreNoWinner =>
      'De beurtlimiet bepaalde het resultaat.';

  @override
  String gameOutcomeScoreWinner(String winner) {
    return '$winner wint na de beurtlimiet.';
  }

  @override
  String get gameOutcomeScoreDrawSubtitle =>
      'Draailimiet bereikt. De hoogste score is gelijk.';

  @override
  String get gameOutcomeDominationNoWinner => 'Kaartcontrole werd gehouden.';

  @override
  String gameOutcomeDominationWinner(String winner) {
    return '$winner heeft territoriale overheersing.';
  }

  @override
  String get gameOutcomeWinnerMetric => 'Winnaar';

  @override
  String get gameOutcomeConditionMetric => 'Voorwaarde';

  @override
  String get gameOutcomeEliminationMetric => 'Eliminatie';

  @override
  String get gameOutcomeMapControlMetric => 'Kaartcontrole';

  @override
  String get gameOutcomeHoldMetric => 'Uitstel';

  @override
  String get gameOutcomeThresholdMetric => 'Drempelwaarde';

  @override
  String gameOutcomeTurnsValue(int held, int required) {
    return '$held/$required bochten';
  }

  @override
  String get victoryConquestPrimary => 'Verovering';

  @override
  String get victoryGoalCompact => 'Doel';

  @override
  String get victoryNoLimit => 'Geen limiet';

  @override
  String get victoryConquestTooltip =>
      'Doel: rivalen elimineren. Geen draailimiet.';

  @override
  String get victoryLimitLabel => 'Beperken';

  @override
  String get victoryNoneValue => 'Geen';

  @override
  String get victoryScoreCapPrimary => 'SCORE CAP';

  @override
  String victoryScoreRemainingPrimary(int turns) {
    return 'SCORE ${turns}T';
  }

  @override
  String get victoryScoreCapCompact => 'GLB';

  @override
  String victoryTurnsCompact(int turns) {
    return '${turns}T';
  }

  @override
  String victoryTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beurten',
      one: '1 beurt',
    );
    return '$_temp0';
  }

  @override
  String get victoryRemainingLabel => 'Overig';

  @override
  String get victoryScoreLeaderLabel => 'Score leider';

  @override
  String victoryScoreDrawLabel(int score) {
    return 'TEKEN $score';
  }

  @override
  String victoryScoreLimitReachedTooltip(int turnLimit) {
    return 'Beurlimiet $turnLimit bereikt. Score bepaalt het resultaat.';
  }

  @override
  String victoryScoreFallbackTooltip(int remainingTurns, int turnLimit) {
    return 'Scoor terugval in $remainingTurns-beurten. Limiet: $turnLimit.';
  }

  @override
  String victoryLeaderTooltip(String leader) {
    return 'Leider: $leader.';
  }

  @override
  String victoryDominationTooltip(
    String leader,
    String control,
    String required,
    String hold,
  ) {
    return 'Dominantie: $leader beheert $control% van de kaart. Drempel: $required%, vasthouden: $hold.';
  }

  @override
  String get victoryLeaderLabel => 'Leider';

  @override
  String get victoryControlLabel => 'Controle';

  @override
  String get victoryHoldLabel => 'Uitstel';

  @override
  String get victoryYouLabel => 'Jij';

  @override
  String get victoryPressureLabel => 'Druk';

  @override
  String get victoryFallbackLabel => 'Terugval';

  @override
  String victoryYourGoalGainControl(int points) {
    return 'Jouw doel: $points pp meer kaartcontrole krijgen.';
  }

  @override
  String get victoryYourGoalReady =>
      'Jouw doel: de overheersingstoestand is klaar om te worden opgelost.';

  @override
  String victoryYourGoalHold(String turns) {
    return 'Jouw doel: de drempel voor $turns meer vasthouden.';
  }

  @override
  String victoryLeaderAboveThreshold(String leader) {
    return '$leader ligt boven de drempel; verbreek die controle voordat het doel wordt vastgehouden.';
  }

  @override
  String victoryYourProgress(String control, String required) {
    return 'Je voortgang: $control% / $required%.';
  }

  @override
  String victoryPressureReachThreshold(int points) {
    return 'Bereik de drempel: ontbrekende $points pp';
  }

  @override
  String get victoryConditionReady => 'Conditie gereed';

  @override
  String victoryPressureHold(String turns) {
    return 'Houd vast voor $turns';
  }

  @override
  String victoryPressureLeaderHolding(String leader, String turns) {
    return '$leader boven drempelwaarde: $turns';
  }

  @override
  String victoryPressureYourGap(int points) {
    return 'Jouw doel: ontbrekende $points pp';
  }

  @override
  String victoryPressureLeaderGap(String leader, int points) {
    return '$leader-leads: ontbrekende $points-pp';
  }

  @override
  String victoryThreatApproaching(
    String player,
    String control,
    String required,
    int points,
  ) {
    return 'Rival nadert dominantie: $player controleert $control% op de $required%-drempel; ontbrekende $points pag.';
  }

  @override
  String victoryThreatHolding(String player, String hold) {
    return 'Rival houdt de dominantiedrempel vast: $player $hold.';
  }

  @override
  String victoryThreatImminent(String player, String hold) {
    return 'Rival is bijna dominant: $player $hold.';
  }

  @override
  String victoryThreatPressureApproaching(String player, int points) {
    return '$player nabij drempel: ontbrekende $points pp';
  }

  @override
  String victoryThreatPressureBreak(String player, String turns) {
    return 'Onderbreek $player: $turns';
  }

  @override
  String get victoryBelowThreshold => 'onder de drempel';

  @override
  String victoryHoldProgress(int held, int required) {
    return '$held/$required bochten';
  }

  @override
  String victoryHoldCompact(int held, int required) {
    return '$held/${required}T';
  }

  @override
  String get victoryReady => 'klaar';

  @override
  String victoryRemainingTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beurten resterend',
      one: '1 beurt resterend',
    );
    return '$_temp0';
  }

  @override
  String get returnToMenuAction => 'Terug naar menu';

  @override
  String get today => 'Vandaag';

  @override
  String get yesterday => 'gisteren';

  @override
  String get objectivesPanelTitle => 'DOELSTELLINGEN';

  @override
  String get objectivesCloseTooltip => 'Doelstellingen sluiten';

  @override
  String get objectivesMenuClosePrefix => 'Doelstellingen sluiten';

  @override
  String get objectivesMenuOpenPrefix => 'Doelstellingen';

  @override
  String objectivesMenuTooltip(
    String prefix,
    String descriptor,
    String title,
    String progress,
    String count,
  ) {
    return '$prefix: $descriptor $title ($progress, $count)';
  }

  @override
  String objectivesMenuCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doelen',
      one: '1 doel',
    );
    return '$_temp0';
  }

  @override
  String get objectivesMenuBadgeScore => 'PTS';

  @override
  String get objectivesMenuBadgeDomination => 'DOM';

  @override
  String get objectivesMenuDescriptorDomination => 'overheersing';

  @override
  String get objectivesMenuDescriptorDominationThreat =>
      'overheersingsdreiging';

  @override
  String get objectivesMenuDescriptorScoreLead => 'verdediging leiden';

  @override
  String get objectivesMenuDescriptorScorePressure => 'druk scoren';

  @override
  String get objectivesMenuDescriptorActiveObjective => 'actieve doelstelling';

  @override
  String get objectiveMicroTooltipLabel => 'Waarom';

  @override
  String get objectiveOverviewGuidanceLabel => 'ACTIEF DOEL';

  @override
  String get objectiveOverviewStrategicLabel => 'DRINGEND';

  @override
  String get objectiveOverviewScoreCatchUpLabel => 'SCOREDRUK';

  @override
  String get objectiveOverviewScoreProtectLabel => 'VERDEDIG LEID';

  @override
  String get objectiveOverviewDominationHoldLabel => 'OVERHEERSING';

  @override
  String get objectiveOverviewDominationThreatLabel => 'DOMINATIE BEDREIGING';

  @override
  String objectiveOverviewTitleLabel(String title) {
    return 'Topprioriteit: $title';
  }

  @override
  String objectiveOverviewProgressLabel(String progress) {
    return 'Voortgang $progress';
  }

  @override
  String get objectivePhaseFoundation => 'Fundering';

  @override
  String get objectivePhaseExpansion => 'Uitbreiding';

  @override
  String get objectivePhasePressure => 'Druk';

  @override
  String get objectivePhaseEndgame => 'Eindspel';

  @override
  String get objectiveChooseResearchTitle => 'Kies voor onderzoek';

  @override
  String get objectiveChooseResearchHint =>
      'Bepaal uw ontwikkelingsrichting voordat de eerste beurt eindigt.';

  @override
  String get objectiveChooseResearchReward => '+ wetenschappelijk tempo';

  @override
  String get objectiveChooseResearchTooltip =>
      'Onderzoek leidt elke volgende wending in de richting van een specifiek ontwikkelingspad.';

  @override
  String get objectiveFoundCapitalTitle => 'Je eerste stad gevonden';

  @override
  String get objectiveFoundCapitalHint =>
      'Je kolonist moet goed terrein snel in een hoofdstad veranderen.';

  @override
  String get objectiveFoundCapitalReward => '+ productiebasis';

  @override
  String get objectiveFoundCapitalTooltip =>
      'Het kapitaal ontsluit productie, groei en territoriaal bereik.';

  @override
  String get objectiveExploreNearbyTitle => 'Verken nabijgelegen land';

  @override
  String get objectiveExploreNearbyHint =>
      'Je krijger moet nabijgelegen hulpbronnen en stadslocaties onthullen.';

  @override
  String get objectiveExploreNearbyReward => '+ betere beslissingen';

  @override
  String get objectiveExploreNearbyTooltip =>
      'Vroegtijdig scouten helpt bij het kiezen van locaties in de stad en het vermijden van blinde bewegingen.';

  @override
  String get objectiveQueueWorkerTitle => 'Zet een medewerker in de wachtrij';

  @override
  String get objectiveQueueWorkerHint =>
      'Een arbeider verandert voedsel en productie op de kaart in een echt voordeel.';

  @override
  String get objectiveQueueWorkerReward => '+ veldontwikkeling';

  @override
  String get objectiveQueueWorkerTooltip =>
      'Een arbeider verandert goede tegels in een gestage groei van grondstoffen.';

  @override
  String get objectiveImproveFirstHexTitle => 'Verbeter je eerste tegel';

  @override
  String get objectiveImproveFirstHexHint =>
      'De eerste verbetering zou voedsel, productie of goud moeten ondersteunen.';

  @override
  String get objectiveImproveFirstHexReward => '+ sterkere economie';

  @override
  String get objectiveImproveFirstHexTooltip =>
      'De eerste verbetering laat zien welk deel van de stadseconomie het snelst zou moeten groeien.';

  @override
  String get objectiveFoundSecondCityTitle => 'Ik heb een tweede stad gevonden';

  @override
  String get objectiveFoundSecondCityHint =>
      'Een tweede nederzetting opent uitbreiding zonder de kaart te overspoelen met eenheden.';

  @override
  String get objectiveFoundSecondCityReward => '+ imperiumschaal';

  @override
  String get objectiveFoundSecondCityTooltip =>
      'Een tweede stad verhoogt het productietempo zonder op één hoofdstad te wachten.';

  @override
  String get objectiveBuildFirstBuildingTitle => 'Bouw je eerste gebouw';

  @override
  String get objectiveBuildFirstBuildingHint =>
      'Het eerste gebouw moet voedsel, productie of goud versterken.';

  @override
  String get objectiveBuildFirstBuildingReward => '+ blijvend stadsvoordeel';

  @override
  String get objectiveBuildFirstBuildingTooltip =>
      'Gebouwen blijven in de stad en schalen over vele beurten heen.';

  @override
  String get objectiveImproveThreeHexesTitle => 'Verbeter drie tegels';

  @override
  String get objectiveImproveThreeHexesHint =>
      'Verschillende verbeteringen maken van een startkamp een economie.';

  @override
  String get objectiveImproveThreeHexesReward => '+ stabiel inkomen';

  @override
  String get objectiveImproveThreeHexesTooltip =>
      'Drie verbeteringen creëren een stabiele basis voor legers, onderzoek of uitbreiding.';

  @override
  String get objectiveFoundThirdCityTitle => 'Ik heb een derde stad gevonden';

  @override
  String get objectiveFoundThirdCityHint =>
      'Een derde nederzetting creëert een echt imperium en een tweede uitbreidingsrichting.';

  @override
  String get objectiveFoundThirdCityReward => '+ kaartschaal';

  @override
  String get objectiveFoundThirdCityTooltip =>
      'Een derde stad geeft je een tweede ontwikkelingsfront en elke beurt meer beslissingen.';

  @override
  String get objectiveExploreRegionTitle => 'Verken de regio';

  @override
  String get objectiveExploreRegionHint =>
      'Een bredere kaart onthult hulpbronnen, rivalen en plaatsen die de moeite waard zijn om te verdedigen.';

  @override
  String get objectiveExploreRegionReward => '+ strategisch plan';

  @override
  String get objectiveExploreRegionTooltip =>
      'Een bredere kaart onthult rivalen, strategische hulpbronnen en veilige grenzen.';

  @override
  String get objectiveBuildCombatForceTitle => 'Bouw een verdedigingsmacht';

  @override
  String get objectiveBuildCombatForceHint =>
      'Met verschillende troepen kun je expansie- en drukrivalen beschermen.';

  @override
  String get objectiveBuildCombatForceReward => '+ grensbeveiliging';

  @override
  String get objectiveBuildCombatForceTooltip =>
      'Een stabiel scherm beschermt kolonisten, arbeiders en ontwikkelde steden.';

  @override
  String get objectiveHoldDominationTitle => 'Houd de dominantie vast';

  @override
  String get objectiveHoldDominationHint =>
      'U bevindt zich boven de kaartdrempel. Houd de controle totdat het aftellen eindigt.';

  @override
  String get objectiveHoldDominationReward => '+ kaartoverwinning';

  @override
  String get objectiveHoldDominationTooltip =>
      'Dominantie beëindigt het spel vóór de scorelimiet als je het vereiste kaartpercentage gedurende opeenvolgende beurten vasthoudt.';

  @override
  String get objectiveBreakDominationHoldTitle =>
      'Doorbreek de dominantie van een rivaal';

  @override
  String get objectiveBreakDominationHoldHint =>
      'Een rivaal bevindt zich boven de kaartdrempel. Verover territorium voordat ze het doel in handen hebben.';

  @override
  String get objectiveBreakDominationHoldReward => '+ aftellen gestopt';

  @override
  String get objectiveBreakDominationHoldTooltip =>
      'Als een rivaal onder de controledrempel valt, wordt zijn hold-beurt teruggezet naar nul.';

  @override
  String get objectiveHoldScoreLeadTitle => 'Houd de leiding vast';

  @override
  String get objectiveHoldScoreLeadHint =>
      'De beurtlimiet is dichtbij. Bescherm je score en voorkom dat je je voorsprong verliest in de laatste beurten.';

  @override
  String get objectiveHoldScoreLeadReward => '+ scorelimiet-overwinning';

  @override
  String get objectiveHoldScoreLeadTooltip =>
      'De scorelimiet beslist de wedstrijd wanneer de beurtlimiet verstreken is, dus de puntenvoorsprong moet tot het einde duren.';

  @override
  String get objectiveOvertakeScoreLeaderTitle => 'Vang de scoreleider';

  @override
  String get objectiveOvertakeScoreLeaderHint =>
      'De beurtlimiet is dichtbij. Je hebt een snelle scoregroei of een zwakkere leider nodig.';

  @override
  String get objectiveOvertakeScoreLeaderReward => '+ scorelimietkans';

  @override
  String get objectiveOvertakeScoreLeaderTooltip =>
      'Bouw steden, bevolking, technologieën, eenheden en verbeteringen; als de scores gelijk zijn, eindigt de scorelimiet in een gelijkspel.';

  @override
  String get objectiveSecureMapObjectiveTitle => 'Stel het kaartdoel veilig';

  @override
  String get objectiveSecureMapObjectiveHint =>
      'Houd een eenheid of stadsinvloed op het doel totdat de hold voltooid is.';

  @override
  String get objectiveSecureMapObjectiveReward => '+ doelbeloningen';

  @override
  String get objectiveSecureMapObjectiveTooltip =>
      'Kaartdoelen gebruiken driehoekige markers en geven overwinningspunten of goud pas na opeenvolgende controle.';

  @override
  String get objectiveBreakMapObjectiveHoldTitle =>
      'Breek het doel van de rivaal';

  @override
  String get objectiveBreakMapObjectiveHoldHint =>
      'Een rivaal houdt een kaartdoel vast. Betwist de driehoekige marker voordat de hold voltooid is.';

  @override
  String get objectiveBreakMapObjectiveHoldReward => '+ doel ontzegd';

  @override
  String get objectiveBreakMapObjectiveHoldTooltip =>
      'Een eigen eenheid op het doel betwist de controle en reset de voortgang van de rivaal.';

  @override
  String get objectiveAdviceFoundCity =>
      'Grootste gat: een nieuwe of veroverde stad.';

  @override
  String get objectiveAdviceGrowPopulation =>
      'Grootste kloof: bevolkingsgroei.';

  @override
  String get objectiveAdviceClaimTerritory =>
      'Grootste kloof: meer gecontroleerde tegels.';

  @override
  String get objectiveAdviceConstructBuilding =>
      'Grootste gat: een stadsgebouw.';

  @override
  String get objectiveAdviceTrainUnit => 'Grootste gat: een snelle eenheid.';

  @override
  String get objectiveAdviceUnlockTechnology =>
      'Grootste kloof: het voltooien van een technologie.';

  @override
  String get objectiveAdviceImproveField =>
      'Grootste gat: een tegelverbetering.';

  @override
  String get objectiveAdviceCollectGold => 'Grootste gat: goud voor score.';

  @override
  String get objectiveAdviceProtectLead =>
      'Prioriteit: geef geen steden op en stel de volgende scorewinst veilig.';

  @override
  String objectiveScoreBreakdownCatchUpHeader(int delta) {
    return 'Scoreverschil: $delta punten';
  }

  @override
  String objectiveScoreBreakdownProtectHeader(int delta) {
    return 'Score voorsprong: $delta punten';
  }

  @override
  String objectiveScoreBreakdownCatchUpTotals(
    int playerScore,
    int comparisonScore,
  ) {
    return 'Jij $playerScore / leider $comparisonScore';
  }

  @override
  String objectiveScoreBreakdownProtectTotals(
    int playerScore,
    int comparisonScore,
  ) {
    return 'Jij $playerScore / rivaal $comparisonScore';
  }

  @override
  String objectiveScoreBreakdownCatchUpDelta(int delta) {
    return 'kort door $delta';
  }

  @override
  String objectiveScoreBreakdownProtectDelta(int delta) {
    return '+$delta';
  }

  @override
  String get objectiveScoreCategoryCity => 'Steden';

  @override
  String get objectiveScoreCategoryPopulation => 'Bevolking';

  @override
  String get objectiveScoreCategoryTerritory => 'Grondgebied';

  @override
  String get objectiveScoreCategoryBuilding => 'Gebouwen';

  @override
  String get objectiveScoreCategoryUnit => 'Eenheden';

  @override
  String get objectiveScoreCategoryTechnology => 'Technologieën';

  @override
  String get objectiveScoreCategoryImprovement => 'Verbeteringen';

  @override
  String get objectiveScoreCategoryGold => 'Goud';

  @override
  String get cityBuildingGranary => 'Graanschuur';

  @override
  String get cityBuildingWaterMill => 'Watermolen';

  @override
  String get cityBuildingWorkshop => 'Werkplaats';

  @override
  String get cityBuildingStorehouse => 'Pakhuis';

  @override
  String get cityBuildingHousing => 'Huisvesting';

  @override
  String get cityBuildingMerchantHall => 'Koopmanszaal';

  @override
  String get cityBuildingStonemason => 'Steenhouwer';

  @override
  String get cityBuildingBarracks => 'Kazerne';

  @override
  String get cityBuildingMarketplace => 'Marktplaats';

  @override
  String get cityBuildingPort => 'Haven';

  @override
  String get cityBuildingAqueduct => 'Aquaduct';

  @override
  String get cityBuildingForge => 'Smederij';

  @override
  String get cityBuildingStable => 'Stabiel';

  @override
  String get cityBuildingBank => 'Bank';

  @override
  String get cityBuildingBuildersGuild => 'Bouwersgilde';

  @override
  String get cityBuildingFactory => 'Fabriek';

  @override
  String get cityBuildingLighthouse => 'Vuurtoren';

  @override
  String get cityBuildingTrainingGrounds => 'Oefenterreinen';

  @override
  String get cityBuildingTownHall => 'Stadhuis';

  @override
  String get cityBuildingMonument => 'Monument';

  @override
  String get cityBuildingArchive => 'Archief';

  @override
  String get cityBuildingAcademy => 'Academie';

  @override
  String get cityBuildingUniversity => 'Universiteit';

  @override
  String get cityBuildingObservatory => 'Observatorium';

  @override
  String get cityBuildingLaboratory => 'Laboratorium';

  @override
  String get cityBuildingReactor => 'Reactor';

  @override
  String get cityBuildingCourthouse => 'Gerechtsgebouw';

  @override
  String get cityBuildingCourt => 'Rechtbank';

  @override
  String get cityBuildingGovernorsOffice => 'Gouverneurskantoor';

  @override
  String get cityBuildingSurveyorsOffice => 'Landmeter kantoor';

  @override
  String get cityBuildingPlanningOffice => 'Planbureau';

  @override
  String get cityBuildingApothecary => 'Apotheker';

  @override
  String get cityBuildingPublicBaths => 'Openbare baden';

  @override
  String get cityBuildingHospital => 'Ziekenhuis';

  @override
  String get cityBuildingMinistries => 'Ministeries';

  @override
  String get cityBuildingWalls => 'Muren';

  @override
  String get cityBuildingArmory => 'Arsenaal';

  @override
  String get cityBuildingSiegeWorkshop => 'Belegeringswerkplaats';

  @override
  String get cityBuildingCitadel => 'Citadel';

  @override
  String get cityBuildingWarCollege => 'Oorlogscollege';

  @override
  String get cityBuildingConscriptionOffice => 'Dienstplichtbureau';

  @override
  String get cityBuildingBorderFort => 'Grensfort';

  @override
  String get cityBuildingAirfield => 'Vliegveld';

  @override
  String get cityBuildingArtisansGuild => 'Ambachtsliedengilde';

  @override
  String get cityBuildingMasterWorkshop => 'Meester Workshop';

  @override
  String get cityBuildingSteelworks => 'Staalfabrieken';

  @override
  String get cityBuildingRailDepot => 'Spoorwegdepot';

  @override
  String get cityBuildingPowerPlant => 'Elektriciteitscentrale';

  @override
  String get cityBuildingAssemblyPlant => 'Assemblagefabriek';

  @override
  String get cityBuildingRefinery => 'Raffinaderij';

  @override
  String get cityBuildingMapRoom => 'Kaart Kamer';

  @override
  String get cityBuildingShipyard => 'Scheepswerf';

  @override
  String get cityBuildingDryDock => 'Droogdok';

  @override
  String get cityBuildingNavalAcademy => 'Marine Academie';

  @override
  String get cityBuildingHarborCustoms => 'Haven douane';

  @override
  String get cityBuildingMuseum => 'Museum';

  @override
  String get cityBuildingParliament => 'Parlement';

  @override
  String get cityBuildingBroadcastTower => 'Omroeptoren';

  @override
  String get cityBuildingWorldFairGrounds =>
      'Terrein van de Wereldtentoonstelling';

  @override
  String get cityBuildingGranaryDescription =>
      'Een vroeg voedselgebouw dat de groei van de stad stabiliseert.';

  @override
  String get cityBuildingWaterMillDescription =>
      'Gebruikt gecontroleerde riviertegels om het stadsvoedsel te verhogen.';

  @override
  String get cityBuildingWorkshopDescription =>
      'Een fundamenteel ambachtscentrum dat de stadsproductie verhoogt.';

  @override
  String get cityBuildingStorehouseDescription =>
      'Verbetert de oogstopslag en verhoogt het opgeslagen voedsel.';

  @override
  String get cityBuildingHousingDescription =>
      'Breidt de leefruimte uit en geeft de stad controle over meer tegels.';

  @override
  String get cityBuildingMerchantHallDescription =>
      'Organiseert de lokale handel en verhoogt de stadsinkomsten.';

  @override
  String get cityBuildingStonemasonDescription =>
      'Versterkt de stadsconstructie en defensieve basis.';

  @override
  String get cityBuildingBarracksDescription =>
      'Biedt militaire infrastructuur en extra verdediging.';

  @override
  String get cityBuildingMarketplaceDescription =>
      'Ontwikkelt stedelijke handel en verhoogt de goudinkomsten aanzienlijk.';

  @override
  String get cityBuildingPortDescription =>
      'Opent de stad voor zeehandel en kustvoedsel.';

  @override
  String get cityBuildingAqueductDescription =>
      'Levert water, ondersteunt groei en verdere stadsuitbreiding.';

  @override
  String get cityBuildingForgeDescription =>
      'Concentreert de metaalbewerking en verhoogt de productie aanzienlijk.';

  @override
  String get cityBuildingStableDescription =>
      'Ondersteunt de fokkerij en logistiek, door voedsel en productie toe te voegen.';

  @override
  String get cityBuildingBankDescription =>
      'Centraliseert de financiën en verhoogt de stadsinkomsten aanzienlijk.';

  @override
  String get cityBuildingBuildersGuildDescription =>
      'Verzamelt bouwspecialisten, waardoor de productie en territoriale groei worden versneld.';

  @override
  String get cityBuildingFactoryDescription =>
      'Een industrieel gebouw uit de latere game dat een grote productiebonus toekent.';

  @override
  String get cityBuildingLighthouseDescription =>
      'Versterkt de kusteconomie door navigatie en handel.';

  @override
  String get cityBuildingTrainingGroundsDescription =>
      'Ontwikkelt militaire training en verbetert de stadsverdediging.';

  @override
  String get cityBuildingTownHallDescription =>
      'Het stadsbestuurcentrum, dat de economie en territoriale controle versterkt.';

  @override
  String get cityBuildingMonumentDescription =>
      'Een symbool van het prestige van de stad, dat goud en verdediging biedt.';

  @override
  String get cityBuildingArchiveDescription =>
      'De eerste kennisopbouw, het organiseren van dossiers en het ondersteunen van onderzoek.';

  @override
  String get cityBuildingAcademyDescription =>
      'Versterkt wetenschapssteden en bereidt de weg naar het hoger onderwijs voor.';

  @override
  String get cityBuildingUniversityDescription =>
      'Een later wetenschappelijk gebouw voor grote, ontwikkelde steden.';

  @override
  String get cityBuildingObservatoryDescription =>
      'Verbindt geografie met wetenschap en ondersteunt geavanceerd onderzoek.';

  @override
  String get cityBuildingLaboratoryDescription =>
      'Ondersteuning voor late technologieprojecten en moderne wetenschap.';

  @override
  String get cityBuildingReactorDescription =>
      'Een krachtig eindspelgebouw waarvoor uranium en een sterke infrastructuur nodig zijn.';

  @override
  String get cityBuildingCourthouseDescription =>
      'Stabiliseert grote of veroverde steden door middel van juridisch bestuur.';

  @override
  String get cityBuildingCourtDescription =>
      'Ontwikkelt wetten, stadsbeleid en civiele controle.';

  @override
  String get cityBuildingGovernorsOfficeDescription =>
      'Versterkt stadsspecialisatie en territoriaal beheer.';

  @override
  String get cityBuildingSurveyorsOfficeDescription =>
      'Vereenvoudigt de grensplanning en vergroot het bereik van de stadscontrole.';

  @override
  String get cityBuildingPlanningOfficeDescription =>
      'Ontwikkelt de stad door middel van planning, productie en territoriale controle.';

  @override
  String get cityBuildingApothecaryDescription =>
      'Vroege stadsgezondheid die helpt bij het handhaven van een gestage groei.';

  @override
  String get cityBuildingPublicBathsDescription =>
      'Verbeter de stabiliteit en groei in grotere steden.';

  @override
  String get cityBuildingHospitalDescription =>
      'Late bevolkingsinfrastructuur voor ontwikkeling op lange termijn.';

  @override
  String get cityBuildingMinistriesDescription =>
      'Een beperkt rijksgebouw dat het bestuur en het goud versterkt.';

  @override
  String get cityBuildingWallsDescription =>
      'Vroege stadsverdediging tegen de eerste aanvallen.';

  @override
  String get cityBuildingArmoryDescription =>
      'Een beter rekruterings- en uitrustingscentrum voor troepen.';

  @override
  String get cityBuildingSiegeWorkshopDescription =>
      'Produceert en onderhoudt de ondersteuningsbasis voor belegeringsmotoren.';

  @override
  String get cityBuildingCitadelDescription =>
      'Late strategische verdediging voor steden aan belangrijke grenzen.';

  @override
  String get cityBuildingWarCollegeDescription =>
      'Een militaire academie die de leger- en algemene coördinatie versterkt.';

  @override
  String get cityBuildingConscriptionOfficeDescription =>
      'Mobiliseert het leger en versnelt de voorbereiding van nieuwe troepen.';

  @override
  String get cityBuildingBorderFortDescription =>
      'Versterkt de verdediging en zichtbaarheid aan de grenzen van het imperium.';

  @override
  String get cityBuildingAirfieldDescription =>
      'Een militair vliegveld voor luchtvaart, verkenning en moderne krachtprojectie.';

  @override
  String get cityBuildingArtisansGuildDescription =>
      'Een productiefase vóór de fabriek, gebaseerd op ambachten en workshops.';

  @override
  String get cityBuildingMasterWorkshopDescription =>
      'Een gespecialiseerde werkplaats voor productiegerichte steden.';

  @override
  String get cityBuildingSteelworksDescription =>
      'Zware industrie op basis van ijzer of steenkool.';

  @override
  String get cityBuildingRailDepotDescription =>
      'Een spoordepot dat de logistiek en mobiliteit tussen steden verbetert.';

  @override
  String get cityBuildingPowerPlantDescription =>
      'Late energie-infrastructuur voor sterke industriële productie.';

  @override
  String get cityBuildingAssemblyPlantDescription =>
      'Een eindspel industrieel gebouw voor massaproductie.';

  @override
  String get cityBuildingRefineryDescription =>
      'Verwerkt olie voor moderne legers en late projecten.';

  @override
  String get cityBuildingMapRoomDescription =>
      'Ondersteunt verkenning, zichtbaarheid en expeditieplanning.';

  @override
  String get cityBuildingShipyardDescription =>
      'Ontwikkelt vloten en productie in havensteden.';

  @override
  String get cityBuildingDryDockDescription =>
      'Een late marinehaven voor grotere oorlogsschepen.';

  @override
  String get cityBuildingNavalAcademyDescription =>
      'Een marine-militaire academie voor gespecialiseerde havens.';

  @override
  String get cityBuildingHarborCustomsDescription =>
      'Een havenkantoor dat de handel en kustcontrole versterkt.';

  @override
  String get cityBuildingMuseumDescription =>
      'Een prestigieus imperiumgebouw dat de invloed van de stad versterkt.';

  @override
  String get cityBuildingParliamentDescription =>
      'Een beperkt burgergebouw voor een volwassen staat.';

  @override
  String get cityBuildingBroadcastTowerDescription =>
      'Versterkt de invloed, zichtbaarheid en communicatie van het imperium.';

  @override
  String get cityBuildingWorldFairGroundsDescription =>
      'Een vreedzaam prestigeproject voor een rijke, ontwikkelde stad.';

  @override
  String get unitCommander => 'Algemeen';

  @override
  String get unitWarrior => 'Strijder';

  @override
  String get unitArcher => 'Boogschutter';

  @override
  String get unitSettler => 'Kolonist';

  @override
  String get unitWorker => 'Werknemer';

  @override
  String get unitMerchant => 'Handelaar';

  @override
  String get unitScout => 'Verkenner';

  @override
  String get unitSpearman => 'Speerman';

  @override
  String get unitCavalry => 'Cavalerie';

  @override
  String get unitCatapult => 'Katapult';

  @override
  String get unitHeavyInfantry => 'Zware infanterie';

  @override
  String get unitFieldCannon => 'Veldkanon';

  @override
  String get unitRifleman => 'Schutter';

  @override
  String get unitTank => 'Tank';

  @override
  String get unitScoutShip => 'Verkenningsschip';

  @override
  String get unitWarship => 'Oorlogsschip';

  @override
  String get unitReconPlane => 'Verkenningsvliegtuig';

  @override
  String get unitCommanderDescription =>
      'Een generaal voert het bevel over een leger, leidt verkenningen en kan sneller handelen dan reguliere troepen.';

  @override
  String get unitWarriorDescription =>
      'Een basisgevechtseenheid voor stadsverdediging en melee-gevechten.';

  @override
  String get unitArcherDescription =>
      'Een afstandseenheid die van verder weg aanvalt, maar slecht verdedigt in gevechten.';

  @override
  String get unitSettlerDescription =>
      'Sticht nieuwe steden en breidt het rijk uit, maar heeft onderweg bescherming nodig.';

  @override
  String get unitWorkerDescription =>
      'Verbetert tegels rond steden, waardoor voedsel, productie en goud toenemen.';

  @override
  String get unitMerchantDescription =>
      'Reist automatisch tussen je steden via een handelsroute en kan bezette bevriende stadscentra betreden.';

  @override
  String get unitScoutDescription =>
      'Een snelle verkenningseenheid voor het verkennen van de kaart en het detecteren van bedreigingen.';

  @override
  String get unitSpearmanDescription =>
      'Vroege defensieve infanterie, goed voor het dekken van steden en het tegenhouden van aanvallen.';

  @override
  String get unitCavalryDescription =>
      'Een mobiele aanvalseenheid die snel reageert op zwakke punten aan het front.';

  @override
  String get unitCatapultDescription =>
      'Een belegeringsmotor met een groter bereik, effectief tegen vestingwerken.';

  @override
  String get unitHeavyInfantryDescription =>
      'Duurzame frontlinie-infanterie met hoge verdediging en solide aanval.';

  @override
  String get unitFieldCannonDescription =>
      'Moderne veldartillerie voor afstandsbombardementen.';

  @override
  String get unitRiflemanDescription =>
      'Een moderne afstandssoldaat, stabiel in aanval en verdediging.';

  @override
  String get unitTankDescription =>
      'Een zware gepantserde eenheid met hoge sterkte en hoge mobiliteit.';

  @override
  String get unitScoutShipDescription =>
      'Een licht schip voor kustverkenning en het beschermen van vroege zeeroutes.';

  @override
  String get unitWarshipDescription =>
      'Een sterk gevechtsschip voor zeecontrole en afstandsbombardementen.';

  @override
  String get unitReconPlaneDescription =>
      'Een verkenningsvliegtuig met groot zichtbereik en zeer hoge mobiliteit.';

  @override
  String get unitRankRecruit => 'Werven';

  @override
  String get unitRankSeasoned => 'Gekruid';

  @override
  String get unitRankVeteran => 'Veteraan';

  @override
  String get unitRankElite => 'Elite';

  @override
  String get troopWarrior => 'Strijders';

  @override
  String get troopArcher => 'Boogschutters';

  @override
  String get troopSettler => 'Kolonisten';

  @override
  String get fieldImprovementFarm => 'Boerderij';

  @override
  String get fieldImprovementRiverFarm => 'Rivier boerderij';

  @override
  String get fieldImprovementMine => 'De mijne';

  @override
  String get fieldImprovementLumberMill => 'Houtzagerij';

  @override
  String get fieldImprovementPasture => 'Weiland';

  @override
  String get fieldImprovementCamp => 'Kamp';

  @override
  String get fieldImprovementQuarry => 'Groeve';

  @override
  String get fieldImprovementFishingBoats => 'Vissersboten';

  @override
  String get fieldImprovementOrchard => 'Boomgaard';

  @override
  String get fieldImprovementPlantation => 'Plantage';

  @override
  String get fieldImprovementVineyard => 'Wijngaard';

  @override
  String get fieldImprovementTradingPost => 'Handelspost';

  @override
  String get fieldImprovementProspectorCamp => 'Goudzoeker kamp';

  @override
  String get fieldImprovementHorseRanch => 'Paardenranch';

  @override
  String get fieldImprovementPearlDivers => 'Parel duikers';

  @override
  String get fieldImprovementCoalShaft => 'Kolenschacht';

  @override
  String get fieldImprovementOilWell => 'Oliebron';

  @override
  String get fieldImprovementBauxiteMine => 'Bauxietmijn';

  @override
  String get fieldImprovementUraniumMine => 'Uraniummijn';

  @override
  String get resourceWheat => 'tarwe';

  @override
  String get resourceFish => 'vis';

  @override
  String get resourceDeer => 'hert';

  @override
  String get resourceSheep => 'schaap';

  @override
  String get resourceRice => 'rijst';

  @override
  String get resourceCow => 'vee';

  @override
  String get resourceApple => 'appels';

  @override
  String get resourceBanana => 'bananen';

  @override
  String get resourceCitrus => 'citrus';

  @override
  String get resourceGold => 'goud';

  @override
  String get resourceSilver => 'zilver';

  @override
  String get resourceGems => 'edelstenen';

  @override
  String get resourceSilk => 'zijde';

  @override
  String get resourceSpices => 'specerijen';

  @override
  String get resourceCotton => 'katoen';

  @override
  String get resourceGrapes => 'druiven';

  @override
  String get resourceIvory => 'ivoor';

  @override
  String get resourcePearls => 'parels';

  @override
  String get resourceCoffee => 'koffie';

  @override
  String get resourceCocoa => 'cacao';

  @override
  String get resourceTobacco => 'tabak';

  @override
  String get resourceSugar => 'suiker';

  @override
  String get resourceIron => 'ijzer';

  @override
  String get resourceCoal => 'kolen';

  @override
  String get resourceOil => 'olie';

  @override
  String get resourceAluminium => 'aluminium';

  @override
  String get resourceUranium => 'uranium';

  @override
  String get resourceHorses => 'paarden';

  @override
  String get resourceMarble => 'marmer';

  @override
  String get technologyAgriculture => 'Landbouw';

  @override
  String get technologyWoodworking => 'Houtbewerking';

  @override
  String get technologyMining => 'Mijnbouw';

  @override
  String get technologyAnimalHusbandry => 'Veehouderij';

  @override
  String get technologyHunting => 'Jacht';

  @override
  String get technologyFishing => 'Vissen';

  @override
  String get technologyCraftsmanship => 'Vakmanschap';

  @override
  String get technologyTrade => 'Handel';

  @override
  String get technologyStorage => 'Opslag';

  @override
  String get technologyWaterEngineering => 'Watertechniek';

  @override
  String get technologyStoneworking => 'Steenbewerking';

  @override
  String get technologyMilitaryOrganization => 'Militaire organisatie';

  @override
  String get technologyAdvancedTrade => 'Geavanceerde handel';

  @override
  String get technologyConstruction => 'Bouw';

  @override
  String get technologyNavigation => 'Navigatie';

  @override
  String get technologyIrrigation => 'Irrigatie';

  @override
  String get technologyBanking => 'Bankieren';

  @override
  String get technologyEngineering => 'Engineering';

  @override
  String get technologyMetallurgy => 'Metallurgie';

  @override
  String get technologyHorsebackRiding => 'Paardrijden';

  @override
  String get technologyIronWorking => 'Ijzer werken';

  @override
  String get technologyCoalMining => 'Kolenwinning';

  @override
  String get technologyMachinery => 'Machines';

  @override
  String get technologyAdministration => 'Administratie';

  @override
  String get technologyLogistics => 'Logistiek';

  @override
  String get technologyShipbuilding => 'Scheepsbouw';

  @override
  String get technologyTactics => 'Tactiek';

  @override
  String get technologyEconomy => 'Economie';

  @override
  String get technologyUrbanization => 'Verstedelijking';

  @override
  String get technologyFortifications => 'Vestingwerken';

  @override
  String get technologyStrategy => 'Strategie';

  @override
  String get technologySpecialization => 'Specialisatie';

  @override
  String get technologyWriting => 'Schrijven';

  @override
  String get technologyMathematics => 'Wiskunde';

  @override
  String get technologyMedicine => 'Geneesmiddel';

  @override
  String get technologyCivilService => 'Ambtenarenzaken';

  @override
  String get technologySiegecraft => 'Belegering';

  @override
  String get technologyCartography => 'Cartografie';

  @override
  String get technologyGuilds => 'Gilden';

  @override
  String get technologyLaw => 'Wet';

  @override
  String get technologyEducation => 'Onderwijs';

  @override
  String get technologyUrbanPlanning => 'Stedelijke planning';

  @override
  String get technologyNavalDoctrine => 'Marinedoctrine';

  @override
  String get technologySteel => 'Staal';

  @override
  String get technologyBureaucracy => 'Bureaucratie';

  @override
  String get technologyNationalism => 'Nationalisme';

  @override
  String get technologyScientificMethod => 'Wetenschappelijke methode';

  @override
  String get technologySteamPower => 'Stoomkracht';

  @override
  String get technologyElectricity => 'Elektriciteit';

  @override
  String get technologyCombustion => 'Verbranding';

  @override
  String get technologyFlight => 'Vlucht';

  @override
  String get technologyMassProduction => 'Massaproductie';

  @override
  String get technologyRadio => 'Radio';

  @override
  String get technologyNuclearPhysics => 'Kernfysica';

  @override
  String get technologyAgricultureDescription =>
      'Opent het basisgroeipad. Boerderijen en rivierboerderijen laten de bevolking sneller groeien en stabiliseren de eerste stad.';

  @override
  String get technologyWoodworkingDescription =>
      'Ontwikkelt de productiekant van de mijnbouw. Houtzagerijen zetten bossen om in productie zonder diep in de metallurgie te duiken.';

  @override
  String get technologyMiningDescription =>
      'Opent het pad van industrie en infrastructuur. Mijnen zijn de eerste grote sprong voorwaarts in de stadsproductie.';

  @override
  String get technologyAnimalHusbandryDescription =>
      'Versterkt de groei via dierlijke hulpbronnen. Weilanden bouwen een voedseleconomie op en bereiden de weg voor paardrijden voor.';

  @override
  String get technologyHuntingDescription =>
      'Opent de militaire en verkenningsafdeling. Biedt kampen en de eerste afstandseenheid voor stadsproductie.';

  @override
  String get technologyFishingDescription =>
      'Ontwikkelt steden aan het water. Vissersboten helpen kuststeden sneller te groeien en de weg naar de haven voor te bereiden.';

  @override
  String get technologyCraftsmanshipDescription =>
      'De eerste upgrade van de stadsproductie. De werkplaats zorgt ervoor dat latere gebouwen en eenheden de wachtrij niet te lang blokkeren.';

  @override
  String get technologyTradeDescription =>
      'De eerste stap in de goudeconomie. De koopmanszaal geeft een stad een eenvoudige financiële beloning na het kiezen van een groeitak.';

  @override
  String get technologyStorageDescription =>
      'Stabiliseert de groei van de stad. Opslag helpt het voedseltempo op peil te houden en vermindert het risico dat de ontwikkeling stagneert.';

  @override
  String get technologyWaterEngineeringDescription =>
      'Vergroot het watergroeipad. De watermolen beloont steden die rivieren beheersen.';

  @override
  String get technologyStoneworkingDescription =>
      'Combineert productie en verdediging. Steengroeven en steenhouwers versterken steden in de infrastructuursector.';

  @override
  String get technologyMilitaryOrganizationDescription =>
      'Bouwt de eerste militaire kern van een stad. Kazernes versterken de productie en verdediging voordat latere legerbonussen verschijnen.';

  @override
  String get technologyAdvancedTradeDescription =>
      'Ontwikkelt de economie na de handel. De markt is een sterker goudgebouw en bereidt de weg naar het bankwezen voor.';

  @override
  String get technologyConstructionDescription =>
      'Vergroot de volwassenheid van het territorium en de stad. Huisvesting vergroot de tegelcontrole en leidt tot administratie en engineering.';

  @override
  String get technologyNavigationDescription =>
      'Opent een stadsuitbetaling voor de kust. De haven heeft toegang tot de kust/oceaan nodig en beloont steden aan het water met voedsel en goud.';

  @override
  String get technologyIrrigationDescription =>
      'Gespecialiseerd in kweken op waterbasis. Het aquaduct biedt een sterke voedselbonus en extra territoriale controle.';

  @override
  String get technologyBankingDescription =>
      'Gespecialiseerd in de handelsbranche. De bank verandert eerdere markten in sterke stadsinkomsten en ontsluit de bredere economie.';

  @override
  String get technologyEngineeringDescription =>
      'Specialisatie bouw. Het bouwersgilde versnelt de productie en verhoogt de gecontroleerde tegellimiet.';

  @override
  String get technologyMetallurgyDescription =>
      'Een sterke industriële uitbetaling na steenbewerking. De smederij verhoogt de productie en bereidt de weg voor naar ijzer en steenkool.';

  @override
  String get technologyHorsebackRidingDescription =>
      'Een technologie die groei en oorlog met elkaar verbindt. De stal ondersteunt steden die eerder investeerden in dieren en jacht.';

  @override
  String get technologyIronWorkingDescription =>
      'Een industrieel hulpbronneneffect. Elke gecontroleerde ijzerbron verhoogt de stadsproductie.';

  @override
  String get technologyCoalMiningDescription =>
      'Een later industrieel hulpbronneneffect. Gecontroleerde steenkool verhoogt de stadsproductie en ondersteunt het fabriekspad.';

  @override
  String get technologyMachineryDescription =>
      'Een late uitbetaling van de infrastructuur. De fabriek geeft een grote productieverhoging aan steden die de techniek zijn ingegaan.';

  @override
  String get technologyAdministrationDescription =>
      'Verbindt infrastructuur met economie. Stadhuizen en monumenten versterken volwassen steden en leiden tot verstedelijking.';

  @override
  String get technologyLogisticsDescription =>
      'Versnelt de productie van eenheden. Dit is de belangrijkste technologie voor spelers die vaker legers uit steden willen inzetten.';

  @override
  String get technologyShipbuildingDescription =>
      'Ontwikkelt de deeltak kust/exploratie. De vuurtoren vereist toegang tot de kust en versterkt steden aan het water.';

  @override
  String get technologyTacticsDescription =>
      'Specialisatie militaire stad. Oefenterreinen voegen defensie en productie voor militaire centra toe.';

  @override
  String get technologyEconomyDescription =>
      'Een systemische uitbetaling voor het bankwezen. Verhoogt het goud gegenereerd door stadseconomieën.';

  @override
  String get technologyUrbanizationDescription =>
      'De definitieve richting voor de groei van grote steden. Verhoogt de bevolkingslimiet zodra het bevolkingssysteem harde limieten gaat gebruiken.';

  @override
  String get technologyFortificationsDescription =>
      'Versterkt de stadsverdediging. Geeft een defensieve bonus aan de stadseconomie, waarvan de volle betekenis toeneemt na uitbreiding van gevechten en belegeringen.';

  @override
  String get technologyStrategyDescription =>
      'De laatste militaire richting. Versterkt de effectiviteit van het leger als uitbetaling in de late game na logistiek.';

  @override
  String get technologySpecializationDescription =>
      'De uiteindelijke maatschappelijke/economische uitbetaling. Ontgrendelt stadsspecialisaties, voegt stadswetenschap toe en helpt bij het voltooien van late technologieën in langere wedstrijden.';

  @override
  String get technologyWritingDescription =>
      'De eerste stap richting wetenschap, recht en bestuur. Het archief geeft een stad een permanente onderzoeksbasis.';

  @override
  String get technologyMathematicsDescription =>
      'Verbindt wetenschap met territoriale planning. Het landmeterkantoor helpt steden hun grenzen effectiever te controleren.';

  @override
  String get technologyMedicineDescription =>
      'Ontwikkelt de gezondheidszorg en groei op lange termijn in grote steden via apotheken, baden en ziekenhuizen.';

  @override
  String get technologyCivilServiceDescription =>
      'Verbetert het beheer van een groot imperium en ontgrendelt rechtbanken die steden stabiliseren.';

  @override
  String get technologySiegecraftDescription =>
      'Opent een belegeringsoorlog. Katapulten en belegeringswerkplaatsen breken vestingsteden.';

  @override
  String get technologyCartographyDescription =>
      'Ontwikkelt verkenning, kaarten en de kust. Geeft de kaartenkamer en de eerste verkenningsschepen.';

  @override
  String get technologyGuildsDescription =>
      'Geeft productiesteden een podium tussen werkplaats en industrie.';

  @override
  String get technologyLawDescription =>
      'Introduceert orde, beleid en civiel bestuur via rechtbanken.';

  @override
  String get technologyEducationDescription =>
      'Bouwt het volledige wetenschapspad voor steden via academies en universiteiten.';

  @override
  String get technologyUrbanPlanningDescription =>
      'Ontwikkelt grote steden en territoriale controle door middel van ruimtelijke planning.';

  @override
  String get technologyNavalDoctrineDescription =>
      'Verandert havens in centra van vloten, scheepswerven en krachtprojectie op zee.';

  @override
  String get technologySteelDescription =>
      'Introduceert zware industrie en zware infanterie voor het latere front.';

  @override
  String get technologyBureaucracyDescription =>
      'Biedt na de regering een belangrijk maatschappelijk doel: kantoren, ministeries, musea en parlement.';

  @override
  String get technologyNationalismDescription =>
      'Combineert grensverdediging, mobilisatie en imperiumidentiteit.';

  @override
  String get technologyScientificMethodDescription =>
      'Bereidt late wetenschappelijke, laboratoria, observatoria en technologieprojecten voor.';

  @override
  String get technologySteamPowerDescription =>
      'Opent spoor-, zwaardere logistiek- en stoomindustrie.';

  @override
  String get technologyElectricityDescription =>
      'Introduceert stroom, infrastructuur en informatiebereik.';

  @override
  String get technologyCombustionDescription =>
      'Geeft olie belang en ontgrendelt moderne frontlinie-eenheden.';

  @override
  String get technologyFlightDescription =>
      'Introduceert luchtvaart, verkenning en krachtprojectie over het front.';

  @override
  String get technologyMassProductionDescription =>
      'Ontwikkelt de uiteindelijke industriële productie, tanks en assemblagefabrieken.';

  @override
  String get technologyRadioDescription =>
      'Versterkt de communicatie, zichtbaarheid en invloed van het imperium via zendmasten.';

  @override
  String get technologyNuclearPhysicsDescription =>
      'Opent de reactor-, uranium- en late eindspelprojecten.';

  @override
  String get technologyEraFoundation => 'Fundering';

  @override
  String get technologyEraSettlement => 'Schikking';

  @override
  String get technologyEraExpansion => 'Uitbreiding';

  @override
  String get technologyEraSpecialization => 'Specialisatie';

  @override
  String get technologyEraIndustry => 'Industrie';

  @override
  String get technologyEraStrategy => 'Strategie';

  @override
  String get technologyUnlockEffect => 'Effect';

  @override
  String get technologyPrerequisitesNone => 'Geen';

  @override
  String get technologyStateCompleted => 'Voltooid';

  @override
  String get technologyStateInProgress => 'In uitvoering';

  @override
  String get technologyStateAvailable => 'Beschikbaar';

  @override
  String get technologyButtonResearched => 'ONDERZOEKEN';

  @override
  String get technologyButtonActive => 'ACTIEF';

  @override
  String get technologyButtonResearch => 'ONDERZOEK';

  @override
  String get technologyButtonLocked => 'GESLOTEN';

  @override
  String get technologyTreeTitle => 'TECHNOLOGIE BOOM';

  @override
  String get technologyTreeEmptyTitle =>
      'Er zijn geen technologieën om weer te geven';

  @override
  String get technologyTreeEmptyBody =>
      'De onderzoeksboom zal hier verschijnen wanneer de regelset technologieën voor dit tijdperk biedt.';

  @override
  String technologyResearchPointsShort(int points) {
    return '$points punten';
  }

  @override
  String get technologyDetailsTooltip => 'Technologiedetails';

  @override
  String get technologyDetailsStatus => 'Status';

  @override
  String get technologyDetailsCost => 'Kosten';

  @override
  String get technologyDetailsProgress => 'Voortgang';

  @override
  String get technologyDetailsPrerequisites => 'Vereisten';

  @override
  String get technologyDetailsUnlocks => 'Ontgrendelt';

  @override
  String get technologyDetailsEffects => 'Effecten';

  @override
  String get technologyDetailsBoosts => 'Verhoogt';

  @override
  String get technologyDetailsUnlockStatus => 'Ontgrendelen';

  @override
  String get technologyDetailsNoEffects => 'Geen passieve effecten';

  @override
  String get technologyDetailsNoBoosts => 'Geen boosts';

  @override
  String get technologyUnlocksNone => 'Geen directe ontgrendelingen';

  @override
  String get technologyBoostActiveBadge => 'Boost';

  @override
  String get technologyBoostActiveBest =>
      'De best beschikbare boost is actief.';

  @override
  String technologyBoostLine(String condition, String discount) {
    return '$condition (-$discount kosten)';
  }

  @override
  String get technologyUnlockFieldImprovementCategory => 'Veldverbetering';

  @override
  String technologyEffectStrategicResourceProductionBonus(
    int production,
    String resource,
  ) {
    return '+$production-productie voor elke gecontroleerde hulpbron: $resource';
  }

  @override
  String technologyEffectGlobalGoldMultiplier(String percent) {
    return '+$percent goud in de stadseconomie';
  }

  @override
  String technologyEffectCityDefenseBonus(int amount) {
    return '+$amount stadsverdediging';
  }

  @override
  String technologyEffectArmyProductionMultiplier(String percent) {
    return '+$percent eenheidsproductie in steden';
  }

  @override
  String technologyEffectArmyStrengthMultiplier(String percent) {
    return '+$percent legersterkte';
  }

  @override
  String technologyEffectMaxCityPopulationBonus(int amount) {
    return '+$amount maximale stadsbevolking';
  }

  @override
  String technologyEffectMaxControlledHexesBonus(int amount) {
    return '+$amount max. stadsgebied';
  }

  @override
  String technologyEffectCityScienceBonus(int amount) {
    return '+$amount wetenschap per stad';
  }

  @override
  String technologyBoostConditionImprovementCount(
    int count,
    String improvement,
  ) {
    return 'Heb ${count}x $improvement';
  }

  @override
  String technologyBoostConditionHasImprovement(String improvement) {
    return 'Heb $improvement';
  }

  @override
  String technologyBoostConditionControlsResource(String resource) {
    return 'Controle $resource';
  }

  @override
  String technologyBoostConditionControlsAnyResource(String resources) {
    return 'Controle: $resources';
  }

  @override
  String technologyEffectAttackBonus(String value) {
    return '$value-aanval';
  }

  @override
  String technologyEffectDefenseBonus(String value) {
    return '$value-verdediging';
  }

  @override
  String get technologyEffectNoArmyStatsBonus => 'Geen legerstatistiekenbonus';

  @override
  String technologyEffectArmyStatsBonus(String parts) {
    return '$parts voor legers';
  }

  @override
  String commonListOr(String first, String last) {
    return '$first of $last';
  }

  @override
  String get buildingDetailsTooltip => 'Details van het gebouw';

  @override
  String get buildingDetailsNoRequirements => 'Geen';

  @override
  String get buildingDetailsYieldImpact => 'Impact van de stad';

  @override
  String buildingDetailsRequirementTechnology(String technology) {
    return 'Technologie: $technology';
  }

  @override
  String get buildingDetailsRequirementCoastalAccess => 'Toegang tot de kust';

  @override
  String buildingDetailsRequirementResources(String resources) {
    return 'Bron: $resources';
  }

  @override
  String buildingDetailsFlatYieldEffect(String yield) {
    return '$yield naar stadsrendement';
  }

  @override
  String buildingDetailsRiverHexYieldEffect(String yield) {
    return '$yield per gecontroleerde riviertegel';
  }

  @override
  String buildingDetailsRiverHexYieldEffectWithMax(
    String yield,
    int maxApplications,
  ) {
    return '$yield per gecontroleerde riviertegel (max $maxApplications)';
  }

  @override
  String buildingDetailsMaxControlledHexesEffect(int amount) {
    return '+$amount door de stad gecontroleerde tegellimiet';
  }

  @override
  String buildingDetailsFoodDepositMultiplierEffect(int percent) {
    return '+$percent% voedsel dat na de beurt wordt bewaard';
  }

  @override
  String buildingDetailsYieldFood(String value) {
    return '$value eten';
  }

  @override
  String buildingDetailsYieldProduction(String value) {
    return '$value-productie';
  }

  @override
  String buildingDetailsYieldGold(String value) {
    return '$value goud';
  }

  @override
  String buildingDetailsYieldDefense(String value) {
    return '$value-verdediging';
  }

  @override
  String buildingDetailsYieldScience(String value) {
    return '$value wetenschap';
  }

  @override
  String get buildingDetailsNoYieldChange => 'Geen wijziging van de middelen';

  @override
  String get unitDetailsTooltip => 'Eenheidsdetails';

  @override
  String get unitDetailsMovement => 'Beweging';

  @override
  String get unitDetailsCombat => 'Gevecht';

  @override
  String unitDetailsMovementPerTurn(int movement) {
    return '$movement tegels/beurt';
  }

  @override
  String get unitDetailsPace => 'Tempo';

  @override
  String unitDetailsRequirementTechnology(String technology) {
    return 'Technologie: $technology';
  }

  @override
  String unitDetailsAttackLine(int value) {
    return 'Aanval: $value';
  }

  @override
  String unitDetailsDefenseLine(int value) {
    return 'Verdediging: $value';
  }

  @override
  String unitDetailsHpLine(int value) {
    return 'PK: $value';
  }

  @override
  String unitDetailsRangeLine(int value) {
    return 'Bereik: $value';
  }

  @override
  String sciencePerTurn(int science) {
    return '$science wetenschap/beurt';
  }

  @override
  String get activeResearchLabel => 'ONDERZOEK';

  @override
  String get requirementTechnology => 'Vereist technologie';

  @override
  String requirementTechnologyName(String technology) {
    return 'Vereist: $technology';
  }

  @override
  String requirementResourceAnyOf(String leading, String last) {
    return '$leading of $last';
  }

  @override
  String requirementResourcesName(String resources) {
    return 'Vereist: $resources';
  }

  @override
  String technologyBlockedBy(String technology) {
    return 'Geblokkeerd door: $technology';
  }

  @override
  String get requirementCoastalAccess => 'Vereist: toegang tot de kust';

  @override
  String get productionCategoryBuilding => 'Gebouw';

  @override
  String get productionCategoryUnit => 'Eenheid';

  @override
  String get productionTitle => 'PRODUCTIE';

  @override
  String get productionInProgressLabel => 'IN UITVOERING';

  @override
  String productionPerTurn(int production) {
    return '$production productie/beurt';
  }

  @override
  String get productionNoProduction => 'geen productie';

  @override
  String get productionButtonProduce => 'PRODUCEREN';

  @override
  String get productionButtonLocked => 'GESLOTEN';

  @override
  String get productionEmptyState =>
      'Er is momenteel geen productie beschikbaar.';

  @override
  String get buildingsSection => 'Gebouwen';

  @override
  String get unitsSection => 'Eenheden';

  @override
  String futureBuildingsSection(int count) {
    return 'Toekomstige gebouwen ($count)';
  }

  @override
  String get futureBuildingsSubtitle => 'Ontgrendeld door technologieën';

  @override
  String workerPanelTitle(String unitName) {
    return 'Werknemer - $unitName';
  }

  @override
  String get commonOpenAction => 'Open';

  @override
  String get commonShowDetailsAction => 'Details weergeven';

  @override
  String get commonExecuteAction => 'Uitvoeren';

  @override
  String colorPickerChangeTooltip(String label) {
    return 'Kleur wijzigen: $label';
  }

  @override
  String colorPickerColorSelected(String hex) {
    return '#$hex geselecteerd';
  }

  @override
  String colorPickerSelectColor(String hex) {
    return 'Selecteer #$hex';
  }

  @override
  String get commonDescription => 'Beschrijving';

  @override
  String get commonSummary => 'Samenvatting';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonTerrain => 'Terrein';

  @override
  String get commonResources => 'Bronnen';

  @override
  String get commonImprovements => 'Verbeteringen';

  @override
  String get commonCities => 'Steden';

  @override
  String get commonBuildings => 'Gebouwen';

  @override
  String get commonGold => 'Goud';

  @override
  String get commonScience => 'Wetenschap';

  @override
  String get commonProduction => 'Productie';

  @override
  String get commonResearch => 'Onderzoek';

  @override
  String get commonEmpire => 'Empire';

  @override
  String get commonTurn => 'Draai';

  @override
  String get commonProjects => 'Projecten';

  @override
  String get commonPopulation => 'Bevolking';

  @override
  String get commonTechnologies => 'Technologieën';

  @override
  String get commonFields => 'Velden';

  @override
  String get commonMultipliers => 'Vermenigvuldigers';

  @override
  String get commonOther => 'Ander';

  @override
  String get commonReady => 'Klaar';

  @override
  String get commonDone => 'Klaar';

  @override
  String get commonDefault => 'Standaard';

  @override
  String get commonAvailable => 'Beschikbaar';

  @override
  String get commonBlocked => 'Geblokkeerd';

  @override
  String get commonSelectAction => 'Selecteer';

  @override
  String get commonSelectedAction => 'Gekozen';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDoNotShowAgain => 'Niet meer tonen';

  @override
  String get commonNoneLower => 'geen';

  @override
  String get visualCurrentLabel => 'Nu';

  @override
  String get visualAfterLabel => 'Na verandering';

  @override
  String get terrainDetailEmpty => 'Geen terreininformatie';

  @override
  String get yieldFoodShort => 'VOEDSEL';

  @override
  String get yieldProductionShort => 'ART';

  @override
  String get yieldGoldShort => 'GOUD';

  @override
  String get yieldDefenseShort => 'DEF';

  @override
  String selectionChipBadgeSuffix(String badge) {
    return 'Zichtbare teller: $badge.';
  }

  @override
  String selectionChipDisabledDescription(String badge) {
    return 'Deze informatiesnelkoppeling is niet beschikbaar voor de huidige selectie.$badge';
  }

  @override
  String selectionChipOpenDescription(String label, String badge) {
    return 'Opent “$label”-details voor de huidige kaartcontext.$badge';
  }

  @override
  String get gameGoalTitle => 'Doel van het spel';

  @override
  String get globalHudCloseResearch => 'Sluit onderzoek';

  @override
  String globalHudResearchActive(String technologyName) {
    return 'Onderzoek: $technologyName';
  }

  @override
  String globalHudResearchActiveWithEta(String technologyName, String eta) {
    return 'Onderzoek: $technologyName · $eta';
  }

  @override
  String get globalHudChooseResearch => 'Kies voor onderzoek';

  @override
  String get globalHudCloseEmpire => 'Sluit imperium';

  @override
  String get globalHudCloseActivityLog => 'Sluit het activiteitenlogboek';

  @override
  String get bottomToolbarWaiting => 'Wachten';

  @override
  String get bottomToolbarPlan => 'Plan';

  @override
  String get bottomToolbarMove => 'Beweging';

  @override
  String get bottomToolbarResolvingTurn => 'De beurt oplossen';

  @override
  String bottomToolbarWaitingFor(String players) {
    return 'Wachten: $players';
  }

  @override
  String turnHintNextUnit(String unit) {
    return 'Volgende stap: $unit';
  }

  @override
  String turnHintNextCityProduction(String city) {
    return 'Volgende stap: productie in $city';
  }

  @override
  String get turnHintChooseResearch => 'Volgende stap: kies voor onderzoek';

  @override
  String get turnHintCheckAction => 'Volgende stap: actie controleren';

  @override
  String turnHintObjective(String objective) {
    return 'Doelstelling: $objective';
  }

  @override
  String turnHintObjectiveWithAdvice(String objective, String advice) {
    return 'Doelstelling: $objective · $advice';
  }

  @override
  String get turnHintImproveFieldWithWorker =>
      'Doel: een tegel verbeteren met een arbeider';

  @override
  String get turnHintFoundCityWithSettler =>
      'Doel: een stad vinden met een kolonist';

  @override
  String get turnHintClaimTerritoryWithSettler =>
      'Doel: gebied claimen met een kolonist';

  @override
  String turnHintTrainUnit(String unit) {
    return 'Doel: eenheid instellen: $unit';
  }

  @override
  String turnHintProtectLeadUnit(String unit) {
    return 'Doel: de voorsprong veiligstellen: $unit';
  }

  @override
  String turnHintConstructBuildingInCity(String city) {
    return 'Doel: een gebouw in $city in de wachtrij plaatsen';
  }

  @override
  String turnHintTrainUnitInCity(String city) {
    return 'Doel: een eenheid in $city in de wachtrij plaatsen';
  }

  @override
  String turnHintPrepareSettlerInCity(String city) {
    return 'Doel: bereid een kolonist voor in $city';
  }

  @override
  String turnHintGrowPopulationInCity(String city) {
    return 'Doelstelling: groei realiseren in $city';
  }

  @override
  String turnHintPrepareWorkerInCity(String city) {
    return 'Doel: een werknemer voorbereiden in $city';
  }

  @override
  String turnHintCollectGoldInCity(String city) {
    return 'Doelstelling: goud sluiten in $city';
  }

  @override
  String turnHintProtectLeadProductionInCity(String city) {
    return 'Doel: veilige productie in $city';
  }

  @override
  String get turnHintUnlockTechnologyForScore =>
      'Doel: kies een scoretechnologie';

  @override
  String get turnHintProtectLeadResearch => 'Doel: veilig onderzoek afronden';

  @override
  String topResourceTurnShortLabel(int turn) {
    return 'T$turn';
  }

  @override
  String topResourceTurnTooltip(int turn) {
    return 'Draai $turn';
  }

  @override
  String topResourceScienceTooltip(String scienceTurnLabel) {
    return 'Wetenschap: $scienceTurnLabel / beurt';
  }

  @override
  String topResourceResourcesTooltip(int resourceTotal, int resourceTypes) {
    return 'Grondstoffen: $resourceTotal-stortingen • $resourceTypes-gecontroleerde typen';
  }

  @override
  String topResourceGoldTooltip(
    int gold,
    int goldIncome,
    int unitUpkeep,
    String net,
  ) {
    return 'Goud: $gold • inkomen +$goldIncome • onderhoud -$unitUpkeep • netto $net / beurt';
  }

  @override
  String topResourceGoldTooltipNegativeTreasury(String base) {
    return '$base • schatkist onder nul';
  }

  @override
  String topResourceGoldTooltipBankruptcy(String base) {
    return '$base • faillissementsrisico binnen 3 beurten';
  }

  @override
  String get resourceBreakdownTreasury => 'Schatkist';

  @override
  String get resourceBreakdownCityIncome => 'Inkomen van de stad';

  @override
  String get resourceBreakdownUpkeep => 'Onderhoud';

  @override
  String get resourceBreakdownNetPerTurn => 'Netto / beurt';

  @override
  String get resourceBreakdownNoCityIncome => 'Geen stadsinkomsten';

  @override
  String get resourceBreakdownFreeLimit => 'Gratis limiet';

  @override
  String get resourceBreakdownNextWorkerUpkeep =>
      'Onderhoud van de volgende werknemer';

  @override
  String resourceBreakdownNextWorkerUpkeepValue(int upkeep) {
    return '-$upkeep goud/draai';
  }

  @override
  String get resourceBreakdownInsideFreeLimit => 'Binnen de vrije limiet';

  @override
  String get resourceBreakdownNoActiveTechnology =>
      'Geen technologie geselecteerd';

  @override
  String get resourceBreakdownScienceTitle => 'Wetenschap en onderzoek';

  @override
  String get resourceBreakdownSciencePerTurn => 'Wetenschap / beurt';

  @override
  String get resourceBreakdownActiveResearch => 'Actief onderzoek';

  @override
  String get resourceBreakdownTurnsToComplete => 'Om te voltooien';

  @override
  String get resourceBreakdownNoScienceSources =>
      'Geen wetenschappelijke bronnen';

  @override
  String resourceBreakdownCityResearchProject(String cityName) {
    return '$cityName: Onderzoek';
  }

  @override
  String get resourceBreakdownNoControlledResources =>
      'Geen gecontroleerde middelen';

  @override
  String get resourceBreakdownGrowCitiesWithFood =>
      'Laat steden groeien met voedsel';

  @override
  String get resourceBreakdownControlledDeposits => 'Gecontroleerde stortingen';

  @override
  String get resourceBreakdownResourceTypes => 'Resourcetypen';

  @override
  String get resourceBreakdownTypesSection => 'Soorten';

  @override
  String get resourceBreakdownSourcesSection => 'Bronnen';

  @override
  String get technologyRecommendationsTitle => 'Aanbevolen onderzoek';

  @override
  String get technologyShowTreeAction => 'Boom laten zien';

  @override
  String technologyShowTreeCountAction(int count) {
    return 'Boom weergeven ($count)';
  }

  @override
  String get technologyRecommendationUnlocks => 'Ontgrendelt';

  @override
  String get technologyRecommendationReasonBoost =>
      'Actieve boost verlaagt de onderzoekskosten.';

  @override
  String get technologyRecommendationReasonSection => 'Waarom nu';

  @override
  String get technologyRecommendationReasonImprovements =>
      'Nieuwe tegelverbeteringen zetten grondstoffen snel om in opbrengst.';

  @override
  String get technologyRecommendationReasonBuilding =>
      'Een nieuw stadsgebouw opent een nieuwe ontwikkelingsrichting.';

  @override
  String get technologyRecommendationReasonUnit =>
      'Een nieuwe eenheid versterkt de veiligheid en kaartcontrole.';

  @override
  String get technologyRecommendationReasonEffect =>
      'Een permanente bonus geldt voor de hele economie.';

  @override
  String get technologyRecommendationReasonFast =>
      'Snel onderzoek zonder extra eisen.';

  @override
  String get technologyRecommendationReasonDefault =>
      'Beschikbaar onderzoek dat de volgende stap netjes afsluit.';

  @override
  String get technologyNoRecommendations =>
      'Er is momenteel geen nieuw onderzoek beschikbaar.';

  @override
  String get technologyFullTreeTitle => 'Volledige technologieboom';

  @override
  String get technologyRecommendationsBackAction => 'Aanbevelingen';

  @override
  String get empireUnitsEmptyTitle => 'Geen eenheden';

  @override
  String get empireUnitsEmptyBody =>
      'Nieuwe eenheden zullen hier verschijnen na stadsproductie of evenementenrekrutering.';

  @override
  String get empireCitiesEmptyTitle => 'Geen steden';

  @override
  String get empireCitiesEmptyBody =>
      'Vind je eerste stad met een kolonist om productie-, wetenschaps- en imperiumgrenzen te ontgrendelen.';

  @override
  String get empireCityCenters => 'Stadscentra';

  @override
  String get empireShowFirstUnitTooltip => 'Toon de eerste eenheid op de kaart';

  @override
  String get empireShowUnitTooltip => 'Toon eenheid op de kaart';

  @override
  String get empireShowFirstCityTooltip => 'Toon de eerste stad op de kaart';

  @override
  String get empireShowCityTooltip => 'Toon stad op de kaart';

  @override
  String empireUnitCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eenheden',
      one: '1 eenheid',
    );
    return '$_temp0';
  }

  @override
  String empireCityCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steden',
      one: '1 stad',
    );
    return '$_temp0';
  }

  @override
  String empireUnitMovement(int movement) {
    return 'Beweging $movement';
  }

  @override
  String get empireUnitBuilding => 'Gebouw';

  @override
  String get empireUnitWorking => 'Werken';

  @override
  String get empireUnitFortifying => 'Versterkend';

  @override
  String get empireUnitHealing => 'Genezing';

  @override
  String get empireUnitEnRoute => 'Onderweg';

  @override
  String get empireUnitNoMovement => 'geen beweging';

  @override
  String empireUnitsWithMovement(int count) {
    return '$count met beweging';
  }

  @override
  String empireCitySubtitle(
    int population,
    int hexes,
    int buildings,
    String production,
  ) {
    return 'Bevolking $population $hexes tegels - $buildings gebouw. - produceren: $production';
  }

  @override
  String empireCityStoredArtifact(String artifactName) {
    return 'Artefact: $artifactName';
  }

  @override
  String empireCityGroupSubtitle(String cityLabel, int population) {
    return '$cityLabel populatie $population';
  }

  @override
  String get empireStatsTitle => 'Empire-status';

  @override
  String get empireStatsSubtitle =>
      'Een snelle lezing van paraatheid, compositie en stadsgroei';

  @override
  String get empireStatsReadinessTitle => 'Eenheid gereed';

  @override
  String get empireStatsUnitCompositionTitle => 'Samenstelling van de eenheid';

  @override
  String get empireStatsCityDevelopmentTitle => 'Ontwikkeling van de stad';

  @override
  String get empireStatsCityComparisonTitle => 'Vergelijking van steden';

  @override
  String get empireStatsOrders => 'Met bestellingen';

  @override
  String get empireStatsNoMovement => 'Geen beweging';

  @override
  String get empireStatsAveragePopulation => 'Gem. knal.';

  @override
  String get empireStatsTotalBuildings => 'Gebouwen';

  @override
  String get empireStatsStoredArtifacts => 'Artefacten';

  @override
  String get empireStatsTerritory => 'Grondgebied';

  @override
  String get empireStatsCitiesProducing => 'Productie';

  @override
  String get empireStatsOther => 'Ander';

  @override
  String get empireStatsEmptyUnits => 'Geen eenheden om te analyseren';

  @override
  String get empireStatsEmptyCities => 'Geen steden om te analyseren';

  @override
  String empireStatsCityBarDetail(int population, int buildings) {
    return 'Knal. $population • gebouw. $buildings';
  }

  @override
  String empireStatsCityComparisonDetail(
    int population,
    int production,
    int food,
    int gold,
  ) {
    return 'Knal. $population • Prod. $production • Voedsel $food • Goud $gold';
  }

  @override
  String get empireStatsMetricPopulation => 'Knal.';

  @override
  String get empireStatsMetricProduction => 'Prod.';

  @override
  String get empireStatsMetricFood => 'Voedsel';

  @override
  String get empireStatsMetricGold => 'Goud';

  @override
  String get activityLogTitle => 'Activiteitenlogboek';

  @override
  String get activityLogShowAllAction => 'Toon alles';

  @override
  String activityLogShowMoreAction(int visible, int total) {
    return 'Meer weergeven ($visible/$total)';
  }

  @override
  String get activityLogLoadingHistory => 'Volledige geschiedenis laden...';

  @override
  String get activityLogHistoryErrorTitle => 'Kan de geschiedenis niet laden';

  @override
  String activityLogHistoryErrorBody(String error) {
    return 'Het gebeurtenisjournaal is niet beschikbaar: $error';
  }

  @override
  String get activityLogFilterAll => 'Alle';

  @override
  String get activityLogFilterAllShort => 'Alle';

  @override
  String get activityLogFilterCombat => 'Gevecht';

  @override
  String get activityLogFilterCities => 'Steden';

  @override
  String get activityLogFilterDiplomacy => 'Diplomatie';

  @override
  String get activityLogFilterDiplomacyShort => 'Dipl.';

  @override
  String get activityLogFilterTechnology => 'Wetenschap';

  @override
  String get activityLogEmptyAllTitle => 'Geen geregistreerde gebeurtenissen';

  @override
  String get activityLogEmptyCombatTitle => 'Geen geregistreerde gevechten';

  @override
  String get activityLogEmptyCityTitle =>
      'Geen geregistreerde stadsevenementen';

  @override
  String get activityLogEmptyDiplomacyTitle => 'Geen geregistreerde diplomatie';

  @override
  String get activityLogEmptyTechnologyTitle =>
      'Geen geregistreerde ontdekkingen';

  @override
  String get activityLogEmptyAllBody =>
      'De eerste ontdekkingen, gevechten en builds verschijnen hier nadat je acties hebt gespeeld.';

  @override
  String get activityLogEmptyCombatBody =>
      'Gevechten worden opgenomen na aanvallen of verdedigingen die zichtbaar zijn voor de speler.';

  @override
  String get activityLogEmptyCityBody =>
      'Gestichte steden, gebouwen en geclaimde tegels vormen hier de tijdlijn van het rijk.';

  @override
  String get activityLogEmptyDiplomacyBody =>
      'Berichten, voorstellen, antwoorden en relatieveranderingen verschijnen hier na diplomatieke acties.';

  @override
  String get activityLogEmptyTechnologyBody =>
      'Ontdekte technologieën zullen hier verschijnen nadat het onderzoek is voltooid.';

  @override
  String get turnTimelineTitle => 'Draai de tijdlijn';

  @override
  String turnTimelineSubtitle(int turn, int count) {
    return 'Zet $turn • gebeurtenissen: $count';
  }

  @override
  String get turnTimelineChartTitle => 'Gebeurtenissen over beurten';

  @override
  String get turnTimelineMetricEvents => 'Evenementen';

  @override
  String get turnTimelineMetricActiveTurns => 'Actieve bochten';

  @override
  String get turnTimelineMetricCurrentTurn => 'Huidige beurt';

  @override
  String get technologyDiscoveryEyebrow => 'Technologie ontdekt';

  @override
  String unitSelectionMovementSubtitle(int current, int max) {
    return 'Verplaats $current/$max';
  }

  @override
  String unitSelectionMovementHpSubtitle(
    int current,
    int max,
    int hp,
    int maxHp,
  ) {
    return '$current/$max verplaatsen • HP $hp/$maxHp';
  }

  @override
  String get unitSelectionAttackLabel => 'Aanval';

  @override
  String get unitSelectionDefenseLabel => 'Verdediging';

  @override
  String get unitSelectionHpLabel => 'PK';

  @override
  String get unitSelectionRangeLabel => 'Bereik';

  @override
  String get unitSelectionConstructionLabel => 'Bouw';

  @override
  String get unitSelectionWorkLabel => 'Werk';

  @override
  String get unitSelectionFieldBonusValue => 'Veldbonus';

  @override
  String get tileSelectionYieldTitle => 'Tegelpotentieel';

  @override
  String get tileSelectionYieldTooltip =>
      'Inspectieschatting voor deze tegel, niet de werkelijke stadsopbrengst.';

  @override
  String get tileSelectionBonusLabel => 'Bonus';

  @override
  String get tileSelectionDefenseBonusValue => '+verdediging';

  @override
  String get tileSelectionRiverBonusValue => '+rivier';

  @override
  String get citySelectionYieldTitle => 'Inkomen van de stad';

  @override
  String get citySelectionYieldTooltip =>
      'Werkelijke stadsopbrengst per beurt uit de stadseconomie.';

  @override
  String citySelectionSubtitle(
    int population,
    int territoryHexCount,
    int maxHexes,
    String production,
  ) {
    return 'Bevolking $population • $territoryHexCount/$maxHexes-velden • Productie: $production';
  }

  @override
  String get citySelectionTerritoryLabel => 'Grondgebied';

  @override
  String get citySelectionFoodLabel => 'Voedsel';

  @override
  String get citySelectionNetFoodLabel => 'Netto eten';

  @override
  String get citySelectionBuildingsLabel => 'Gebouwen';

  @override
  String get citySelectionArtifactLabel => 'Artefact';

  @override
  String get worldArtifactBonusTitle => 'Bonus';

  @override
  String get worldArtifactHeritageTitle => 'Erfenis';

  @override
  String get worldArtifactHeritageBody =>
      'Verzamel en plaats 6 unieke artefacten in je steden, en houd de collectie vervolgens 5 beurten vast.';

  @override
  String get worldArtifactAncientImperialCrown => 'Oude keizerlijke kroon';

  @override
  String get worldArtifactAstronomersTablets => 'Tabletten van astronomen';

  @override
  String get worldArtifactProphetMask => 'Masker van de Profeet';

  @override
  String get worldArtifactHeroSword => 'Heldenzwaard';

  @override
  String get worldArtifactMerchantsSeal => 'Koopmanszegel';

  @override
  String get worldArtifactFirstPeoplesChronicle => 'Eerste Volkskroniek';

  @override
  String get worldArtifactTempleReliquary => 'Tempelreliekschrijn';

  @override
  String get worldArtifactQueensMirror => 'Koninginnespiegel';

  @override
  String get worldArtifactAncientImperialCrownShortBonus => '+1 verdediging';

  @override
  String get worldArtifactAstronomersTabletsShortBonus => '+1 wetenschap';

  @override
  String get worldArtifactProphetMaskShortBonus => '+1 goud, diplomatie';

  @override
  String get worldArtifactHeroSwordShortBonus =>
      '+2 XP voor geproduceerde eenheden';

  @override
  String get worldArtifactMerchantsSealShortBonus => '+2 goud';

  @override
  String get worldArtifactFirstPeoplesChronicleShortBonus => '+1 eten';

  @override
  String get worldArtifactTempleReliquaryShortBonus =>
      '+1 eten, +1 verdediging';

  @override
  String get worldArtifactQueensMirrorShortBonus => '+1 goud, diplomatie';

  @override
  String get worldArtifactAncientImperialCrownDescription =>
      'Een symbool van oude heerschappij. Eenmaal opgeslagen in een stad versterkt het de verdediging en het prestige van de collectie.';

  @override
  String get worldArtifactAstronomersTabletsDescription =>
      'Stenen tabletten met oude kaarten van de hemel. In een stad ondersteunen ze de wetenschap.';

  @override
  String get worldArtifactProphetMaskDescription =>
      'Een ritueel masker van groot politiek gewicht. In een stad verleent het goud en diplomatieke waarde.';

  @override
  String get worldArtifactHeroSwordDescription =>
      'Het wapen van een legendarische commandant. Eenheden die in deze stad worden geproduceerd, krijgen extra ervaring.';

  @override
  String get worldArtifactMerchantsSealDescription =>
      'Het kenmerk van de eerste koopmansgilden. In een stad versterkt het de goudinkomsten.';

  @override
  String get worldArtifactFirstPeoplesChronicleDescription =>
      'Een verslag van de oudste geslachten en grenzen. In een stad ondersteunt het de groei.';

  @override
  String get worldArtifactTempleReliquaryDescription =>
      'Een heilig reliekschrijn dat de stad stabiliteit, voedsel en verdediging geeft.';

  @override
  String get worldArtifactQueensMirrorDescription =>
      'Een hofschat die handel met diplomatie verbindt. In een stad schenkt het goud en prestige.';

  @override
  String get worldArtifactLocationMap => 'Artefact op de kaart';

  @override
  String get worldArtifactLocationExcavation => 'Opgraving bezig';

  @override
  String get worldArtifactLocationCarried => 'Gedragen door een eenheid';

  @override
  String get worldArtifactLocationStored => 'Opgeslagen in een stad';

  @override
  String get worldArtifactStepExcavate => 'Opgraven';

  @override
  String get worldArtifactStepMove => 'Beweging';

  @override
  String get worldArtifactStepStore => 'Winkel';

  @override
  String get artifactGuidanceUnknownCityName => 'een stad';

  @override
  String get artifactGuidanceStoredTitle => 'Artefact opgeslagen';

  @override
  String artifactGuidanceStoredBody(String artifactName, String cityName) {
    return '$artifactName versterkt $cityName. Voor een culturele overwinning zijn 6 artefacten in steden nodig gedurende 5 beurten.';
  }

  @override
  String get artifactGuidanceCarriedTitle => 'Artefact gedragen';

  @override
  String artifactGuidanceCarriedBody(String artifactName) {
    return 'Het apparaat is voorzien van $artifactName. Breng het naar een van je steden met een gratis slot en gebruik de winkelactie.';
  }

  @override
  String get artifactGuidanceReachedTitle => 'Artefact ontdekt';

  @override
  String artifactGuidanceReachedBody(String artifactName) {
    return '$artifactName bevindt zich onder de unit. Gebruik de actie Opgraven om het op te rapen.';
  }

  @override
  String get citySelectionSpecializationLabel => 'Specialisatie';

  @override
  String get fieldImprovementOutsideActiveCity => 'Buiten actieve stad';

  @override
  String get fieldImprovementYieldTitle => 'Verbeteringsbonus';

  @override
  String get fieldImprovementYieldTooltip =>
      'Extra opbrengst door de veldverbetering.';

  @override
  String get hexKindIdealCitySite => 'Ideale stadscamping';

  @override
  String get hexKindGoodCitySite => 'Goede stadssite';

  @override
  String get hexKindFertileField => 'Vruchtbaar veld';

  @override
  String get hexKindFertilePlains => 'Vruchtbare vlaktes';

  @override
  String get hexKindRichPlain => 'Rijke vlakte';

  @override
  String get hexKindStrategicBorderland => 'Strategisch grensgebied';

  @override
  String get hexKindStrategicField => 'Strategisch veld';

  @override
  String get hexKindDefensivePosition => 'Defensieve positie';

  @override
  String get hexKindFertileForest => 'Vruchtbaar bos';

  @override
  String get hexKindForestBackline => 'Bos achterlijn';

  @override
  String get hexKindForestForge => 'Bos smederij';

  @override
  String get hexKindWildLand => 'Wild land';

  @override
  String get hexKindRichWilds => 'Rijke wildernis';

  @override
  String get hexKindExoticBackline => 'Exotische ruglijn';

  @override
  String get hexKindDifficultStrategicTerrain => 'Moeilijk strategisch terrein';

  @override
  String get hexKindHighGround => 'Hoge grond';

  @override
  String get hexKindRiverHills => 'Rivier heuvels';

  @override
  String get hexKindIndustrialStronghold => 'Industrieel bolwerk';

  @override
  String get hexKindRichHills => 'Rijke heuvels';

  @override
  String get hexKindBarrenLand => 'Onvruchtbaar land';

  @override
  String get hexKindOasis => 'Oase';

  @override
  String get hexKindTradeOasis => 'Handel oase';

  @override
  String get hexKindDesertDeposits => 'Woestijnafzettingen';

  @override
  String get hexKindHarshLand => 'Ruw land';

  @override
  String get hexKindColdPastures => 'Koude weilanden';

  @override
  String get hexKindResourceOutpost => 'Hulpbron buitenpost';

  @override
  String get hexKindHostileLand => 'Vijandig land';

  @override
  String get hexKindArcticDeposits => 'Arctische afzettingen';

  @override
  String get hexKindCoast => 'Kust';

  @override
  String get hexKindFishingCoast => 'Visserijkust';

  @override
  String get hexKindRichCoast => 'Rijke kust';

  @override
  String get hexKindRiverPort => 'Rivierhaven';

  @override
  String get hexKindRegionalPortHeart => 'Regionaal havenknooppunt';

  @override
  String get hexKindOpenSea => 'Open zee';

  @override
  String get hexKindNaturalBarrier => 'Natuurlijke barrière';

  @override
  String get hexKindPromisingLand => 'Veelbelovend land';

  @override
  String get hexKindWeakLand => 'Zwak land';

  @override
  String get hexKindOrdinaryLand => 'Gewone grond';

  @override
  String get hexKindMapTile => 'Kaart tegel';

  @override
  String get hexKindIdealCitySiteDescription =>
      'Een waardevolle nederzettingstegel waarop voedsel, groei en expansiedruk al op een rij staan.';

  @override
  String get hexKindGoodCitySiteDescription =>
      'Solide terrein voor een stadscentrum met voldoende basiswaarde om vroege groei te ondersteunen.';

  @override
  String get hexKindFertileFieldDescription =>
      'Door rivieren gevoed grasland dat voedsel, bevolkingsgroei en verbetering van de werknemers bevordert.';

  @override
  String get hexKindFertilePlainsDescription =>
      'Open vlaktes met rivierondersteuning, nuttig voor evenwichtige voeding en productie.';

  @override
  String get hexKindRichPlainDescription =>
      'Een waardevolle open tegel met luxe- of handelswaarde die de moeite waard is om binnen de grenzen te brengen.';

  @override
  String get hexKindStrategicBorderlandDescription =>
      'Goed land met strategische waarde, nuttig voor uitbreiding voordat rivalen het claimen.';

  @override
  String get hexKindStrategicFieldDescription =>
      'Een vlaktegel die is gekoppeld aan strategische hulpbronnen of druk op de grens.';

  @override
  String get hexKindDefensivePositionDescription =>
      'Terrein dat de defensieve controle verbetert en helpt bij het vasthouden van naderingen in de buurt.';

  @override
  String get hexKindFertileForestDescription =>
      'Een bos met rivierondersteuning, dat groeipotentieel combineert met natuurlijke dekking.';

  @override
  String get hexKindForestBacklineDescription =>
      'Een veiliger bostegel die groei of jachtgerichte verbeteringen kan ondersteunen.';

  @override
  String get hexKindForestForgeDescription =>
      'Bos met industriële waarde, veelbelovend voor productie zodra het is verbeterd.';

  @override
  String get hexKindWildLandDescription =>
      'Dicht terrein met wrijving; alleen nuttig als u een duidelijk werknemers- of uitbreidingsplan heeft.';

  @override
  String get hexKindRichWildsDescription =>
      'Wild terrein met voldoende vruchtbaarheid of hulpbronnen om een ​​zorgvuldige ontwikkeling te rechtvaardigen.';

  @override
  String get hexKindExoticBacklineDescription =>
      'Een jungle- of moerastegel met luxewaarde voor latere grenzen en handel.';

  @override
  String get hexKindDifficultStrategicTerrainDescription =>
      'Hard terrein met strategische hulpbronnenwaarde; krachtig later, onhandig vroeg.';

  @override
  String get hexKindHighGroundDescription =>
      'Heuvels die meer de voorkeur geven aan verdediging en kaartcontrole dan aan snelle groei.';

  @override
  String get hexKindRiverHillsDescription =>
      'Heuvels naast een rivier, die verdediging combineren met een beter economisch potentieel.';

  @override
  String get hexKindIndustrialStrongholdDescription =>
      'Heuvels met industriële hulpbronnen, een sterk productiedoel voor een stad.';

  @override
  String get hexKindRichHillsDescription =>
      'Heuvels met rijkdommen, nuttig voor goud of productiegerichte expansie.';

  @override
  String get hexKindBarrenLandDescription =>
      'Droog land met weinig directe waarde, tenzij technologie of grenzen het plan later veranderen.';

  @override
  String get hexKindOasisDescription =>
      'Woestijn verzacht door toegang tot de rivier, waardoor zwak land een bruikbare groeitegel wordt.';

  @override
  String get hexKindTradeOasisDescription =>
      'Een woestijnhandelszak die waardevol kan worden met de juiste verbetering.';

  @override
  String get hexKindDesertDepositsDescription =>
      'Arme nederzettingsgrond met een strategische afzetting die er in latere tijdperken meer toe doet.';

  @override
  String get hexKindHarshLandDescription =>
      'Koud of ruig land met beperkte vroege economie en trage ontwikkeling.';

  @override
  String get hexKindColdPasturesDescription =>
      'Koud terrein met voldoende weidewaarde om een ​​grensstad te ondersteunen.';

  @override
  String get hexKindResourceOutpostDescription =>
      'Afgelegen, koud land dat vooral de moeite waard is om te claimen vanwege de hulpbron die het beschermt.';

  @override
  String get hexKindHostileLandDescription =>
      'Onvriendelijk terrein met een zwakke schikkingswaarde en weinig directe opbrengsten.';

  @override
  String get hexKindArcticDepositsDescription =>
      'Besneeuwd land dat moeilijk te gebruiken is, maar van strategisch belang kan zijn.';

  @override
  String get hexKindCoastDescription =>
      'Kustgebied dat maritieme toegang en flexibele stadsgroei mogelijk maakt.';

  @override
  String get hexKindFishingCoastDescription =>
      'Kust met voedselwaarde, een sterke reden om aan het water te werken of te vestigen.';

  @override
  String get hexKindRichCoastDescription =>
      'Kustluxe of handelswaarde die de moeite waard is om binnen de stadsgrenzen te vouwen.';

  @override
  String get hexKindRiverPortDescription =>
      'Een riviermonding met handels- en bewegingswaarde voor een kuststad.';

  @override
  String get hexKindRegionalPortHeartDescription =>
      'Een sterk kustcentrum waar de waarde van rivieren en hulpbronnen samenkomt.';

  @override
  String get hexKindOpenSeaDescription =>
      'Water dat nuttig is voor schepen en verkenning, maar niet voor landbezetting.';

  @override
  String get hexKindNaturalBarrierDescription =>
      'Geblokkeerd terrein dat beweging en verdediging vormgeeft in plaats van economie.';

  @override
  String get hexKindPromisingLandDescription =>
      'Een over het algemeen bruikbare tegel met voldoende waarde om te inspecteren voordat je verder gaat.';

  @override
  String get hexKindWeakLandDescription =>
      'Terrein met een laag rendement dat zelden vroege werktijd verdient.';

  @override
  String get hexKindOrdinaryLandDescription =>
      'Een normale tegel zonder opvallende sterkte, handig als deze in het stadsplan past.';

  @override
  String get hexKindMapTileDescription =>
      'Een eenvoudige kaarttegel zonder voldoende informatie om een ​​sterk oordeel te vellen.';

  @override
  String get hexTagCity => 'Stadssite';

  @override
  String get hexTagDefense => 'Defensieve positie';

  @override
  String get hexTagTrade => 'Handelsroute';

  @override
  String get hexTagFertile => 'Vruchtbaar veld';

  @override
  String get hexTagProduction => 'Goede productie';

  @override
  String get hexTagHostile => 'Vijandig land';

  @override
  String get hexTagStrategic => 'Strategische hulpbron';

  @override
  String get hexTagWater => 'Waterdoorgang';

  @override
  String get hexRecommendationFoundCity => 'Goede ontwikkelsite';

  @override
  String get hexRecommendationDefendHere => 'Goede defensieve positie';

  @override
  String get hexRecommendationExploitEconomy =>
      'De moeite waard om te exploiteren';

  @override
  String get hexRecommendationAvoid => 'Vermijd zonder plan';

  @override
  String get hexRecommendationNeutral => 'Inspecteer voordat u verhuist';

  @override
  String get hexRecommendationFoundCityDetail =>
      'Als de grenzen vrij zijn, overweeg dan om hier een kolonist op te richten of aan te sturen.';

  @override
  String get hexRecommendationDefendHereDetail =>
      'Gebruik het om eenheden te verankeren, grenzen te beschermen of nabijgelegen steden te bedekken.';

  @override
  String get hexRecommendationExploitEconomyDetail =>
      'Breng het binnen de grenzen en wijs een arbeider toe als de stad hiervan kan profiteren.';

  @override
  String get hexRecommendationAvoidDetail =>
      'Sla het vroegtijdig over, tenzij een hulpbron, route of militaire behoefte de waarde verandert.';

  @override
  String get hexRecommendationNeutralDetail =>
      'Verken aangrenzende tegels en vergelijk grondstoffen voordat je een arbeider of kolonist inzet.';

  @override
  String get selectionActionLockedReason =>
      'U kunt nu geen bestellingen plaatsen.';

  @override
  String get selectionActionFoundCity => 'Stad gevonden';

  @override
  String get selectionActionCancel => 'Annuleren';

  @override
  String get selectionActionCancelAttack => 'Aanval annuleren';

  @override
  String get selectionActionCancelWorkerBuild => 'Verbetering annuleren';

  @override
  String get selectionActionCancelCityFounding => 'Stadsstichting annuleren';

  @override
  String get selectionActionCancelAutoExplore => 'Verkenning annuleren';

  @override
  String get selectionActionCancelArtifactExcavation =>
      'Artefactopgraving annuleren';

  @override
  String get selectionActionCancelTradeRouteSelection =>
      'Handelsrouteselectie annuleren';

  @override
  String get selectionActionCancelMerchantMoveToCity => 'Stadsreis annuleren';

  @override
  String get selectionActionCancelCommanderMerge =>
      'Troepen samenvoegen annuleren';

  @override
  String get selectionActionConfirm => 'Bevestigen';

  @override
  String selectionActionConfirmWithTurns(String turns) {
    return 'Bevestigen ($turns)';
  }

  @override
  String get selectionActionMinimize => 'Minimaliseer';

  @override
  String get selectionActionConfirmAttack => 'Bevestig aanval';

  @override
  String get selectionActionCaptureCity => 'Stad veroveren';

  @override
  String get selectionActionDestroyCity => 'Vernietig de stad';

  @override
  String get selectionActionStopFortifying => 'Stop met versterken';

  @override
  String get selectionActionStopHealing => 'Stop met genezen';

  @override
  String get selectionActionMove => 'Beweging';

  @override
  String get selectionActionAttack => 'Aanval';

  @override
  String get selectionActionAutoExplore => 'Ontdekken';

  @override
  String get selectionActionTradeRoute => 'Handelsroute';

  @override
  String selectionActionTradeRouteToCity(String cityName) {
    return 'Handel met $cityName';
  }

  @override
  String get selectionActionMerchantMoveToCity => 'Ga naar stad';

  @override
  String selectionActionMerchantMoveToCityTarget(String cityName) {
    return 'Ga naar $cityName';
  }

  @override
  String get selectionActionArmy => 'Leger';

  @override
  String get selectionArmyEmpty => 'Geen troepen';

  @override
  String selectionTroopDetachTooltip(String troop) {
    return 'Maak $troop los';
  }

  @override
  String get selectionActionImprove => 'Verbeteren';

  @override
  String get selectionActionSkip => 'Overslaan';

  @override
  String get selectionActionFortify => 'Versterken';

  @override
  String get selectionActionHeal => 'Genezen';

  @override
  String get selectionActionCancelCityGrowth => 'Annuleer de groei';

  @override
  String get selectionActionCityGrowth => 'Groei van de stad';

  @override
  String get selectionActionProduction => 'Productie';

  @override
  String get selectionActionExcavateArtifact => 'Opgraven';

  @override
  String get selectionActionStoreArtifact => 'Winkel';

  @override
  String get selectionActionCancelCurrentMoveFirst =>
      'Annuleer eerst de huidige zet.';

  @override
  String get selectionActionArtifactAlreadyCarried =>
      'De eenheid heeft al een artefact bij zich.';

  @override
  String get selectionActionStoreArtifactOwnCityRequired =>
      'Verhuis naar een van je steden.';

  @override
  String get selectionActionStoreArtifactCityOccupied =>
      'Deze stad heeft al een artefact opgeslagen.';

  @override
  String get selectionActionNoBuildAvailable =>
      'Er is geen bebouwing beschikbaar op deze tegel.';

  @override
  String get selectionActionUnitWorking => 'Het apparaat werkt al.';

  @override
  String get selectionActionUnitFortified => 'De eenheid is versterkt.';

  @override
  String get selectionActionUnitHealing => 'De eenheid is aan het genezen.';

  @override
  String get selectionActionNoMovement =>
      'Er zijn geen bewegingspunten meer over deze beurt.';

  @override
  String get selectionActionNoAttack => 'Deze eenheid heeft geen aanval.';

  @override
  String get selectionActionNoVisibleEnemy =>
      'Geen zichtbare vijand binnen bereik.';

  @override
  String get selectionActionMerchantNoOriginCity =>
      'Verplaats de handelaar naar een van je steden.';

  @override
  String get selectionActionMerchantNoDestinationCity =>
      'Je hebt een tweede verbonden stad nodig.';

  @override
  String get selectionActionMerchantNoRoute =>
      'Geen handelsroute kan deze stad bereiken.';

  @override
  String get selectionActionMerchantNoCityPath =>
      'De handelaar kan deze stad niet bereiken.';

  @override
  String get selectionActionCannotFoundCityHere => 'Kan hier geen stad vinden.';

  @override
  String get selectionActionFoundCityNoCommander =>
      'Alleen een kolonist of een commandant met kolonisten kan een stad stichten.';

  @override
  String get selectionActionFoundCityNoSettlers =>
      'Kolonisten zijn verplicht een stad te stichten.';

  @override
  String get selectionActionFoundCityInvalidCenter =>
      'Op deze tegel kan geen stad worden gesticht.';

  @override
  String get selectionActionFoundCityCityAlreadyExists =>
      'Er staat al een stad op deze tegel.';

  @override
  String get selectionActionFoundCityCenterOccupied =>
      'Deze tegel hoort al bij een stad.';

  @override
  String get selectionActionFoundCityTooCloseToCity =>
      'Een stad kan niet aangrenzend zijn aan een andere stad.';

  @override
  String get selectionActionFoundCityInvalidControlledHexes =>
      'Kies eerst geldige stadstegels.';

  @override
  String get selectionActionCannotImproveCityCenter =>
      'Er kunnen geen verbeteringen in het stadscentrum worden gebouwd.';

  @override
  String get selectionActionTileAlreadyImproved =>
      'Deze tegel heeft al een verbetering.';

  @override
  String get selectionActionTileMustBelongToCity =>
      'De tegel moet bij een stad horen.';

  @override
  String get selectionActionNoWorkerTile => 'Geen tegel onder de arbeider.';

  @override
  String get hudFeedbackNoTurnCostDetail =>
      'Actie heeft de beurt niet verbruikt';

  @override
  String get hudFeedbackAutoExploreNoTargetTitle => 'Geen verkenningsroute';

  @override
  String get hudFeedbackAutoExploreNoTargetBody =>
      'De verkenner heeft deze beurt geen zet die nieuwe tegels zou onthullen.';

  @override
  String get hudFeedbackArtifactGuidanceTitle => 'Wereld artefact';

  @override
  String get hudFeedbackArtifactGuidanceBody =>
      'Lever het af in een van je steden en plaats het in een leeg artefactvak.';

  @override
  String get hudFeedbackActionBlockedTitle => 'Actie niet beschikbaar';

  @override
  String get hudFeedbackActionBlockedBody =>
      'Deze actie is momenteel geblokkeerd. Kies een andere tegel of een ander commando.';

  @override
  String get hudFeedbackAttackProtectedByTreatyTitle =>
      'Verdrag blokkeert aanval';

  @override
  String get hudFeedbackAttackProtectedByTreatyBody =>
      'Je kunt geen eenheid aanvallen van een beschaving waarmee je een alliantie of wapenstilstand hebt. Verander eerst de diplomatieke relaties.';

  @override
  String get hudFeedbackMovementCityOccupiedTitle => 'Stad bezet';

  @override
  String get hudFeedbackMovementCityOccupiedBody =>
      'Er kan slechts één eenheid in een stad staan. Verplaats eerst het garnizoen of kies een andere tegel.';

  @override
  String get hudFeedbackMovementEnemyOccupiedTitle => 'Vijand op deze tegel';

  @override
  String get hudFeedbackMovementEnemyOccupiedBody =>
      'Je kunt een vijandelijke tegel niet betreden met een normale beweging. Gebruik Aanval of kies een aangrenzende tegel.';

  @override
  String get hudFeedbackMovementForeignCityTitle => 'Buitenlandse stad';

  @override
  String get hudFeedbackMovementForeignCityBody =>
      'Je kunt een vreemde stad niet betreden met een normale beweging. Gebruik Aanval of kies een andere tegel.';

  @override
  String get hudFeedbackMovementHiddenRouteTooFarTitle => 'Route te ver';

  @override
  String get hudFeedbackMovementHiddenRouteTooFarBody =>
      'Je kunt zo\'n lange route door onontdekt terrein niet uitstippelen. Kies een korter segment of gebruik automatische verkenning van scout.';

  @override
  String get hudFeedbackMovementBlockedTerrainTitle =>
      'Terrein blokkeert beweging';

  @override
  String get hudFeedbackMovementBlockedTerrainBody =>
      'Deze eenheid kan dat terreintype niet betreden. Kies een andere tegel of een route eromheen.';

  @override
  String get hudFeedbackMovementInsufficientUnitMovementTitle =>
      'Niet genoeg beweging';

  @override
  String get hudFeedbackMovementInsufficientUnitMovementBody =>
      'Deze eenheid heeft niet genoeg beweging om dat gebied te betreden. Verbeter haar of gebruik een andere eenheid.';

  @override
  String get hudFeedbackMovementNoRouteTitle => 'Geen traject';

  @override
  String get hudFeedbackMovementNoRouteBody =>
      'Er is geen beschikbare route naar die tegel. Probeer een dichterbij gelegen doelwit of een andere benadering.';

  @override
  String selectionCommandUnavailableDescription(String label) {
    return 'Actie \"$label\" is niet beschikbaar voor de huidige selectie.';
  }

  @override
  String selectionCommandActiveDescription(String label) {
    return 'Actie \"$label\" is een actieve modus. Kies een doel op de kaart of annuleer de modus als je van gedachten bent veranderd.';
  }

  @override
  String selectionCommandProminentDescription(String label) {
    return 'Actie \"$label\" is momenteel het belangrijkste commando voor deze selectie.';
  }

  @override
  String selectionCommandDefaultDescription(String label) {
    return 'Voert actie \"$label\" uit voor de momenteel geselecteerde eenheid, stad of tegel.';
  }

  @override
  String get selectionInfoChipDisabledDescription =>
      'Dit informatiepaneel is niet beschikbaar voor de huidige selectie.';

  @override
  String selectionInfoChipOpenDescription(String label) {
    return 'Opent \"$label\"-details voor de momenteel geselecteerde tegel, eenheid of stad.';
  }

  @override
  String turnCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beurten',
      one: '1 beurt',
      zero: '0 beurten',
    );
    return '$_temp0';
  }

  @override
  String turnPillLabel(int turn) {
    return 'T$turn';
  }

  @override
  String get turnEtaNoProgress => 'geen vooruitgang';

  @override
  String turnEtaDetailLabel(String turnsLabel, int turn) {
    return '$turnsLabel • draai $turn';
  }

  @override
  String turnEtaTooltipNoTurn(String turnsLabel) {
    return '$turnsLabel om te voltooien';
  }

  @override
  String turnEtaTooltipExpectedTurn(String turnsLabel, int turn) {
    return '$turnsLabel voltooid • verwachte beurt $turn';
  }

  @override
  String get modeBannerWorkedTilesTitle => 'Bewerkte tegels';

  @override
  String get modeBannerWorkedTilesInstruction =>
      'Tik op gecontroleerde tegels om stadswerk in of uit te schakelen.';

  @override
  String get modeBannerCityGrowthTitle => 'Groei van de stad';

  @override
  String get modeBannerCityGrowthInstructionSelected =>
      'De geselecteerde tegel wordt geclaimd bij de volgende stadsgroei. Bevestig het of kies een andere tegel.';

  @override
  String get modeBannerCityGrowthInstructionEmpty =>
      'Tik op een omlijnde tegel om het volgende groeiveld te kiezen. Zonder keuze zal de stad gebruik maken van haar aanbeveling.';

  @override
  String get modeBannerWorkerActionTitle => 'Verbetering van tegels';

  @override
  String get modeBannerWorkerActionInstructionPicked =>
      'Bevestig de verbetering in de werknemerspop-up.';

  @override
  String get modeBannerWorkerActionInstructionEmpty =>
      'Kies een verbeteringstype in de werknemerspop-up.';

  @override
  String get modeBannerMerchantTradeRouteTitle => 'Handelsroute';

  @override
  String get modeBannerMerchantTradeRouteInstruction =>
      'Kies een van je steden. De handelaar reist er automatisch heen en keert terug na aankomst.';

  @override
  String get modeBannerMerchantMoveToCityTitle => 'Ga naar stad';

  @override
  String get modeBannerMerchantMoveToCityInstruction =>
      'Kies een van je steden. De handelaar plant een pad naar het centrum zonder een handelsroute te maken.';

  @override
  String workerActionSelectedImprovement(String title) {
    return 'Geselecteerd: $title';
  }

  @override
  String get workerActionSelectImprovement => 'Kies voor verbetering';

  @override
  String get workerActionBuildDetailTitle => 'Tegelverbetering';

  @override
  String workerActionBuildImprovement(String title) {
    return 'Bouw $title';
  }

  @override
  String get workerActionSelectionHint =>
      'Klik op een verbetering voor deze tegel, inspecteer de opbrengsten en bevestig de build.';

  @override
  String get workerActionNoYieldChange => 'geen opbrengstverandering';

  @override
  String get modeBannerResearchSelectionTitle => 'Kies voor onderzoek';

  @override
  String get modeBannerResearchSelectionInstruction =>
      'Open de technologieboom en kies een onderzoeksdoel om de beurt voort te zetten.';

  @override
  String get modeBannerUnitTurnSkipTitle => 'Beurt overgeslagen';

  @override
  String get modeBannerUnitTurnSkipInstruction =>
      'De eenheid wacht tot de volgende beurt. De staat ervan is zichtbaar in de onderste balk.';

  @override
  String get modeBannerCommanderMergeTitle => 'Troepen samenvoegen';

  @override
  String get modeBannerCommanderMergeInstruction =>
      'Selecteer een bevriende eenheid die de commandant aan het leger kan toevoegen.';

  @override
  String get modeBannerAttackTargetingTitle => 'Aanval';

  @override
  String get modeBannerAttackTargetingInstructionSelected =>
      'Controleer de gevechtsvoorspelling in de pop-up en bevestig de aanval.';

  @override
  String get modeBannerAttackTargetingInstructionEmpty =>
      'Selecteer een vijand binnen bereik of zijn vakje om de gevechtsvoorspelling te zien.';

  @override
  String get modeBannerAttackRetreatProgress => 'Toevluchtsoord';

  @override
  String get modeBannerActionToolbarHint =>
      'Gebruik de onderste werkbalk voor acties wanneer je ze nodig hebt.';

  @override
  String get combatPreviewConfirmBody =>
      'De geselecteerde eenheid zal na bevestiging onmiddellijk aanvallen.';

  @override
  String get combatPreviewOutcomeLabel => 'Resultaat';

  @override
  String get combatPreviewTargetLabel => 'Doel';

  @override
  String get combatPreviewRetaliationLabel => 'Wraak';

  @override
  String get combatPreviewStrengthLabel => 'Kracht';

  @override
  String get combatPreviewAttackerRole => 'Aanvaller';

  @override
  String get combatPreviewDefenderRole => 'Verdediger';

  @override
  String get combatPreviewCityRole => 'Stad';

  @override
  String combatPreviewOutcomeLine(String outcome) {
    return 'Resultaat: $outcome';
  }

  @override
  String get combatPreviewOutcomeCityFalls => 'stad valt';

  @override
  String get combatPreviewOutcomeDefenderKilled => 'verdediger sterft';

  @override
  String get combatPreviewOutcomeAttackerKilled =>
      'aanvaller sterft als vergelding';

  @override
  String get combatPreviewOutcomeDefenderRetreated =>
      'verdediger zal zich terugtrekken';

  @override
  String get combatPreviewOutcomeCitySurvives => 'stad overleeft';

  @override
  String get combatPreviewOutcomeDefenderSurvives => 'verdediger overleeft';

  @override
  String combatPreviewTargetLine(
    int hpBefore,
    int hpAfter,
    int hpMax,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Doel: HP $hpBefore->$hpAfter/$hpMax, aanval $attack versus verdediging $defense (-$damage)';
  }

  @override
  String combatPreviewNoRetaliationLine(int distance, int range) {
    return 'Vergelding: geen (afstandsaanval, afstand $distance, bereik $range)';
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
    return 'Vergelding: aanval $attack versus verdediging $defense (-$damage), HP $hpBefore->$hpAfter/$hpMax';
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
  String get combatPreviewForecastTitle => 'Gevechtsvoorspelling';

  @override
  String get combatPreviewNoHpLoss => 'geen schade';

  @override
  String combatPreviewHpAfterSemantics(int hpAfter, int hpMax, int loss) {
    return '$hpAfter van $hpMax HP na gevecht verloor $loss HP';
  }

  @override
  String combatPreviewStrengthValue(int attack, int defense) {
    return '$attack-aanval versus $defense-verdediging';
  }

  @override
  String get combatPreviewAdvantageTitle => 'Waarom deze voorspelling?';

  @override
  String combatPreviewAdvantageAttacker(
    String country,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Aanvalsvoordeel: $country heeft $attack-aanval tegen $defense-verdediging; het doelwit verliest ongeveer $damage HP.';
  }

  @override
  String combatPreviewAdvantageDefender(
    String country,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Verdedigingsvoordeel: $country heeft $defense-verdediging tegen $attack-aanvallen; de hit gaat over $damage HP.';
  }

  @override
  String combatPreviewAdvantageEven(int attack, int defense, int damage) {
    return 'Gelijkmatig vechten: $attack-aanval tegen $defense-verdediging; de voorspelde schade bedraagt ​​ongeveer $damage HP.';
  }

  @override
  String combatPreviewTerrainLine(
    String attackerCountry,
    String attackerTerrain,
    String defenderCountry,
    String defenderTerrain,
  ) {
    return 'Posities: $attackerCountry-aanvallen vanuit $attackerTerrain. $defenderCountry verdedigt op $defenderTerrain.';
  }

  @override
  String combatPreviewSourcesLine(String sources) {
    return 'De rand komt van: $sources.';
  }

  @override
  String combatPreviewPositiveSourcesLine(
    String attackerCountry,
    String sources,
  ) {
    return 'Helpt de aanval ($attackerCountry): $sources.';
  }

  @override
  String combatPreviewNegativeSourcesLine(
    String defenderCountry,
    String sources,
  ) {
    return 'Helpt de verdediging ($defenderCountry): $sources.';
  }

  @override
  String get combatPreviewNoSourcesLine =>
      'Er zijn geen aanpassingen van toepassing: de statistieken van de basiseenheid en het gevechtsresultaat bepalen deze voorspelling.';

  @override
  String combatPreviewNoRetaliationReason(int distance, int range) {
    return 'Geen vergelding: dit is een afstandsaanval (afstand $distance, aanvalsbereik $range).';
  }

  @override
  String get combatPreviewNoRetaliationDefenderDefeated =>
      'Geen vergelding: het doelwit wordt verslagen voordat het kan antwoorden.';

  @override
  String get combatPreviewNoRetaliationDefenderRetreats =>
      'Geen vergelding: het doelwit trekt zich terug na de treffer.';

  @override
  String get combatPreviewNoRetaliationNoAttack =>
      'Geen vergelding: het doelwit heeft in deze voorspelling geen aanvalskracht.';

  @override
  String combatPreviewRetaliationRisk(
    String defenderCountry,
    String attackerCountry,
    int damage,
  ) {
    return 'Vergelding: $defenderCountry antwoordt en $attackerCountry verliest ongeveer $damage HP.';
  }

  @override
  String get combatPreviewSourceAttackTerrain => 'aanvaller terrein';

  @override
  String get combatPreviewSourceDefenseTerrain => 'verdediger terrein';

  @override
  String get combatPreviewSourceTechnology => 'technologie';

  @override
  String get combatPreviewSourceVeterancy => 'ervaring';

  @override
  String get combatPreviewSourceCityGarrison => 'stadsgarnizoen';

  @override
  String get combatPreviewSourceMixedArmy => 'samenstelling van de eenheid';

  @override
  String get combatCounterSpearmanVsMountedAttack =>
      'speerdragers tegen bereden eenheden';

  @override
  String get combatCounterSpearmanVsMountedDefense =>
      'speerdragers houden stand tegen bereden eenheden';

  @override
  String get combatCounterArcherDefensiveTerrainDefense =>
      'boogschutters in verdedigend terrein';

  @override
  String get combatCounterCavalryRoughAttack =>
      'cavalerie vertraagd door ruw terrein';

  @override
  String get combatCounterCavalryOpenRaid => 'cavalerieaanval op open terrein';

  @override
  String get combatCounterHeavyInfantryBreakthrough =>
      'zware infanterie breekt de linie';

  @override
  String get terrainOcean => 'oceaan';

  @override
  String get terrainCoast => 'kust';

  @override
  String get terrainLake => 'meer';

  @override
  String get terrainPlains => 'vlaktes';

  @override
  String get terrainGrassland => 'grasland';

  @override
  String get terrainDesert => 'woestijn';

  @override
  String get terrainTundra => 'toendra';

  @override
  String get terrainSnow => 'sneeuw';

  @override
  String get terrainMountain => 'bergen';

  @override
  String get terrainHills => 'heuvels';

  @override
  String get terrainWetlands => 'wetlands';

  @override
  String get terrainJungle => 'oerwoud';

  @override
  String get terrainForest => 'woud';

  @override
  String get terrainRiver => 'rivier';

  @override
  String get modeBannerMoveTargetingTitle => 'Bewegingsmodus';

  @override
  String get modeBannerMoveTargetingInstruction =>
      'De eerste tik op een vakje stippelt de route uit. Tik nogmaals op hetzelfde vakje om te bewegen; een langere route staat in de wachtrij voor toekomstige afslagen.';

  @override
  String get modeBannerMoveTargetingCancelAction => 'Exit beweging';

  @override
  String get modeBannerWorkerFindTileTitle => 'Werker: zoek een tegel';

  @override
  String modeBannerWorkerFindTileInstruction(String reason) {
    return '$reason Verplaats de arbeider naar een van je stadstegels zonder verbetering, of naar terrein dat overeenkomt met een ontgrendeld bouwwerk.';
  }

  @override
  String get modeBannerWorkerFindTileDetailOwnCity => 'Eigen stadstegel';

  @override
  String get modeBannerWorkerFindTileDetailNoImprovement => 'Geen verbetering';

  @override
  String get modeBannerWorkerFindTileDetailMatchingTerrain =>
      'Bijpassend terrein';

  @override
  String get modeBannerWorkerImproveTileTitle => 'Werker: verbeter de tegel';

  @override
  String get modeBannerWorkerImproveTileInstruction =>
      'Deze tegel kan worden verbeterd. Als je wilt handelen, gebruik dan de onderste werkbalk, kies de beste build en bevestig deze in het onderste paneel.';

  @override
  String get modeBannerWorkerImproveTileDetailYields =>
      'Verhoogt de tegelopbrengst';

  @override
  String get modeBannerWorkerImproveTileDetailMovement =>
      'Maakt gebruik van beweging';

  @override
  String get modeBannerScoutExploreTitle => 'Verkennen: verkennen';

  @override
  String get modeBannerScoutExploreInstruction =>
      'Schakel verkenning in via de onderste werkbalk zodat de verkenner automatisch de dichtstbijzijnde onbekende tegels ontdekt. Je kunt het later annuleren via eenheidsacties.';

  @override
  String get modeBannerScoutExploreDetailAuto => 'Automatische verkenning';

  @override
  String get modeBannerScoutExploreDetailReveal => 'Onthult de kaart';

  @override
  String get modeBannerSettlerFindSiteTitle => 'Settler: zoek een site';

  @override
  String modeBannerSettlerFindSiteInstruction(String reason) {
    return '$reason Verplaats de kolonist naar een vrije tegel buiten de stadsgrenzen; vermijd water, bergen en bezette centra.';
  }

  @override
  String get modeBannerSettlerFindSiteDetailFreeHex => 'Gratis zeshoek';

  @override
  String get modeBannerSettlerFindSiteDetailOutsideBorders => 'Buiten grenzen';

  @override
  String get modeBannerSettlerFindSiteDetailLandOrCoast => 'Land of kust';

  @override
  String get modeBannerSettlerFoundCityTitle => 'Kolonist: gevonden stad';

  @override
  String get modeBannerSettlerFoundCityInstruction =>
      'Deze tegel kan een stad worden. Als je er een wilt stichten, gebruik dan de onderste werkbalk en kies vervolgens de starttegels van de stad op de kaart.';

  @override
  String get modeBannerSettlerFoundCityDetailNewCity => 'Nieuwe stad';

  @override
  String get modeBannerSettlerFoundCityDetailChooseTiles =>
      'Kies tegels na het tikken';

  @override
  String get modeBannerCityFoundingTitle => 'Een stad stichten';

  @override
  String get modeBannerCityFoundingInstructionReady =>
      'Klaar. Bevestig de oprichting van de stad in de onderste werkbalk of wijzig de geselecteerde tegels op de kaart.';

  @override
  String modeBannerCityFoundingInstructionPick(int count) {
    return 'Kies $count verbonden tegels rond de kolonist. Nadat je ze hebt gekozen, is de stadsstichtingsactie beschikbaar in de onderste werkbalk.';
  }

  @override
  String get selectionImprovementListTitle => 'Tegelverbeteringen';

  @override
  String get mapInspectionPossibleImprovementsTitle =>
      'Mogelijke verbeteringen';

  @override
  String get mapInspectionNoPossibleImprovements =>
      'Geen mogelijke verbeteringen';

  @override
  String get mapInspectionImprovementAvailableFromStart => 'vanaf het begin';

  @override
  String get mapInspectionObjectiveTitle => 'Kaartdoel';

  @override
  String get mapObjectiveRuins => 'Ruïnes';

  @override
  String get mapObjectiveStrategicPass => 'Strategische pas';

  @override
  String get mapObjectiveHolySite => 'Heilige plaats';

  @override
  String get mapObjectiveLegendaryResource => 'Legendarische afzetting';

  @override
  String get mapObjectiveRuinsDescription =>
      'Een neutraal verkenningspunt. Vasthouden verhoogt de overwinningsdruk.';

  @override
  String get mapObjectiveStrategicPassDescription =>
      'Een belangrijke doorgang door het terrein. Controle maakt beweging tot voordeel.';

  @override
  String get mapObjectiveHolySiteDescription =>
      'Een cultureel belangrijke plek. Controle geeft goud en overwinningspunten.';

  @override
  String get mapObjectiveLegendaryResourceDescription =>
      'Een zeldzame afzetting die uitbreiding of conflict waard is. Controle geeft de grootste beloning.';

  @override
  String mapObjectiveStatusNeutral(int turns) {
    return 'Houd $turns beurten vast';
  }

  @override
  String mapObjectiveStatusHolding(int held, int required) {
    return 'Vasthouden $held/$required';
  }

  @override
  String mapObjectiveStatusCompleted(int held, int required) {
    return 'Gecontroleerd $held/$required';
  }

  @override
  String get mapObjectiveStatusContested => 'Betwist';

  @override
  String mapObjectiveRewardVictoryPoints(int points) {
    return '+$points OP';
  }

  @override
  String mapObjectiveRewardGoldPerTurn(int gold) {
    return '+$gold goud/beurt';
  }

  @override
  String get selectionImprovementStateBuilt => 'GEBOUWD';

  @override
  String get selectionImprovementStateAvailable => 'BESCHIKBAAR';

  @override
  String get selectionImprovementStateNeedsTechnology => 'TECH';

  @override
  String get selectionImprovementStateNeedsCity => 'STAD';

  @override
  String get selectionImprovementStateBlocked => 'BEPERKEN';

  @override
  String get selectionImprovementNoBonus => 'Geen bonus';

  @override
  String workerImprovementYieldFood(int value) {
    return '+$value eten';
  }

  @override
  String workerImprovementYieldProduction(int value) {
    return '+$value productie';
  }

  @override
  String workerImprovementYieldGold(int value) {
    return '+$value goud';
  }

  @override
  String workerImprovementYieldDefense(int value) {
    return '+$value verdediging';
  }

  @override
  String get workerImprovementNoBonus => 'Geen extra bonus.';

  @override
  String get workerImprovementOnlyWorker =>
      'Alleen een arbeider kan dit bouwen.';

  @override
  String get workerImprovementWorkerBusy => 'De arbeider is al aan het bouwen.';

  @override
  String get workerImprovementStopQueuedMove =>
      'Stop eerst de geplande beweging.';

  @override
  String get workerImprovementMissingTile => 'Geen tegel onder de unit.';

  @override
  String get workerImprovementMissingResource =>
      'Deze verbetering vereist een bijpassende hulpbron.';

  @override
  String get workerImprovementInvalidTerrain =>
      'Verkeerd basisterrein voor deze verbetering.';

  @override
  String get workerImprovementMissingRiver =>
      'Voor deze verbetering is een rivier nodig.';

  @override
  String get workerImprovementBlocked => 'Deze actie is nu geblokkeerd.';

  @override
  String unitSelectionWorkerJobTurns(String name, int turns) {
    return '$name (${turns}T)';
  }

  @override
  String get resourceValueNoMatchingImprovement =>
      'Geen overeenkomstige verbetering';

  @override
  String get resourceValueSelectWorkerOrCity => 'Selecteer werknemer of stad';

  @override
  String get resourceValueTileAlreadyImproved =>
      'Tile heeft al een verbetering';

  @override
  String get resourceValueCityCenter => 'Stadscentrum';

  @override
  String resourceValueWorksForCity(String city) {
    return 'Werkt voor: $city';
  }

  @override
  String get resourceValueOutsideCityBorders => 'Buiten de stadsgrenzen';

  @override
  String get resourceValueNoLegalImprovementForTile =>
      'Geen juridische verbetering voor deze tegel';

  @override
  String resourceValueRequiresTechnology(String technology) {
    return 'Vereist: $technology';
  }

  @override
  String get resourceValueAvailableForWorker => 'Beschikbaar voor werknemer';

  @override
  String get resourceDetailNoResourcesOnTile =>
      'Geen grondstoffen op deze tegel';

  @override
  String get resourceDetailValueSection => 'Waarde';

  @override
  String get resourceDetailCurrentSection => 'Nu';

  @override
  String get resourceDetailAfterImprovementSection => 'Na verbetering';

  @override
  String get resourceDetailYieldComparison => 'Tegelopbrengsten';

  @override
  String get resourceDetailRequiresSection => 'Vereist';

  @override
  String get resourceDetailBestMoveSection => 'Beste zet';

  @override
  String get resourceDetailNoMatchingImprovementBody =>
      'Geen overeenkomende verbetering voor deze bron.';

  @override
  String get resourceDetailRequirementNoneCanBuild =>
      'Niets. Je kunt meteen bouwen.';

  @override
  String get resourceDetailRequirementOutsideCity =>
      'De tegel moet binnen de stadsgrenzen liggen.';

  @override
  String get resourceDetailRequirementAlreadyImproved =>
      'Niets. De tegel is al verbeterd.';

  @override
  String get resourceDetailRequirementCityCenter =>
      'Er wordt geen arbeider gebouwd in het stadscentrum.';

  @override
  String get resourceDetailRequirementSelectWorkerOrCity =>
      'Een arbeiders- of stadsselectie.';

  @override
  String get resourceDetailRequirementNoLegalImprovement =>
      'Geen beschikbare build voor deze tegel.';

  @override
  String resourceDetailBestMoveRequiresTechnology(
    String technology,
    String improvement,
  ) {
    return 'Ontgrendel eerst $technology en bouw vervolgens $improvement.';
  }

  @override
  String resourceDetailBestMoveAvailable(String improvement) {
    return 'Stuur een arbeider en bouw $improvement.';
  }

  @override
  String get resourceDetailBestMoveOutsideCity =>
      'Breid de stadsgrenzen uit of zoek een stad dichter bij de bron.';

  @override
  String get resourceDetailBestMoveAlreadyImproved =>
      'Bewaar de tegel binnen de grenzen en bewerk hem wanneer dit in het stadsplan past.';

  @override
  String get resourceDetailBestMoveCityCenter =>
      'Behandel de hulpbron als waarde in het stadscentrum; werknemers verbeteren deze tegel niet.';

  @override
  String get resourceDetailBestMoveSelectWorkerOrCity =>
      'Selecteer een arbeider of stad om de legale constructie te controleren.';

  @override
  String get resourceDetailBestMoveNoLegalImprovement =>
      'Behandel de hulpbron als een uitbreidingsdoel; er is hier geen aparte constructie.';

  @override
  String resourceValueUnlockedByTechnology(
    String technology,
    String improvement,
  ) {
    return 'Ontgrendeld door $technology: $improvement.';
  }

  @override
  String resourceValueUnlocksFullYieldAfterTechnology(
    String technology,
    String improvement,
  ) {
    return 'Na $technology: $improvement ontgrendelt de volledige tegelopbrengst.';
  }

  @override
  String resourceValueResearchBoostLine(String technology, String discount) {
    return 'Onderzoeksboost: het beheersen van deze hulpbron versnelt $technology (kosten -$discount).';
  }

  @override
  String resourceValueTechnologyControlledResourceBonus(
    String technology,
    int production,
  ) {
    return 'Na $technology: +$production PROD voor elke gecontroleerde bron.';
  }

  @override
  String resourceValueNoBaseYieldSummary(String yield) {
    return 'De hulpbron zelf voegt geen basisopbrengst toe. De hele hex heeft nu $yield; de volledige waarde komt van verbeteringen en ontgrendelingen.';
  }

  @override
  String resourceValueBaseYieldSummary(String resourceYield, String tileYield) {
    return 'De bron geeft $resourceYield. De hele hex heeft nu $tileYield vóór verbetering.';
  }

  @override
  String get resourceValueExpansionStrategic =>
      'Claim het voordat een rivaal dat doet: dit is een strategische hulpbron voor productie, legers of latere technologieën.';

  @override
  String get resourceValueExpansionFood =>
      'Een goed uitbreidingsdoel voor de groei van de stad: meer voedsel betekent een snellere bevolking en meer bewerkte tegels.';

  @override
  String get resourceValueExpansionProduction =>
      'Een goed uitbreidingsdoel voor het productietempo: gebouwen, eenheden en kaartdruk komen sneller aan.';

  @override
  String get resourceValueExpansionTrade =>
      'Een goede expansiedoelstelling voor de handel: na verbetering ondersteunt het goud en het voortzetten van de groei sterk.';

  @override
  String get resourceValueExpansionEconomy =>
      'Een goed expansiedoel voor de economie: goud helpt legers in stand te houden, reserves op te bouwen en doelpunten te dichten.';

  @override
  String resourceValueYieldFood(int amount) {
    return '+$amount VOEDSEL';
  }

  @override
  String resourceValueYieldProduction(int amount) {
    return '+$amount ART';
  }

  @override
  String resourceValueYieldGold(int amount) {
    return '+$amount GOUD';
  }

  @override
  String resourceValueYieldDefense(int amount) {
    return '+$amount DEF';
  }

  @override
  String get resourceValueZeroBaseYield => '0 basisopbrengst';

  @override
  String get resourceValueCategoryBonus => 'Bonus';

  @override
  String get resourceValueCategoryLuxury => 'Luxe';

  @override
  String get resourceValueCategoryStrategic => 'Strategisch';

  @override
  String get resourceValueCategoryBonusFuture =>
      'Waarde werkt meestal meteen: snellere groei en een betere start van de stad.';

  @override
  String get resourceValueCategoryLuxuryFuture =>
      'De grootste waarde verschijnt na grensclaim en de juiste verbetering.';

  @override
  String get resourceValueCategoryStrategicFuture =>
      'Dit is een strategische hulpbron: stel deze veilig voor latere productie en militaire druk.';

  @override
  String get cityYieldBreakdownTitle => 'Stedelijke economie';

  @override
  String cityYieldBreakdownSubtitle(String growth, String eta) {
    return 'Reëel rendement/omzet • groei $growth • $eta';
  }

  @override
  String get cityYieldBreakdownProductionSources => 'Productiebronnen';

  @override
  String get cityYieldBreakdownScienceSources => 'Wetenschappelijke bronnen';

  @override
  String get cityYieldBreakdownPerTurnSuffix => '/draai';

  @override
  String get cityYieldBreakdownNoProduction => 'Geen productie';

  @override
  String get cityYieldBreakdownNoScience => 'Geen wetenschap';

  @override
  String get cityYieldBreakdownCenter => 'Centrum';

  @override
  String get cityYieldBreakdownPopulationFields => 'Bevolkingsvelden';

  @override
  String get cityYieldBreakdownWorkers => 'Werknemers';

  @override
  String get cityYieldBreakdownBuildings => 'Gebouwen';

  @override
  String get cityYieldBreakdownTechnologies => 'Technologieën';

  @override
  String get cityYieldBreakdownSpecialization => 'Specialisatie';

  @override
  String get cityYieldBreakdownGoldMultiplier => 'Gouden vermenigvuldiger';

  @override
  String get cityYieldBreakdownUpkeep => 'Onderhoud';

  @override
  String get cityYieldBreakdownFieldsBucket => 'Velden';

  @override
  String get cityYieldBreakdownCenterDetail =>
      'Vast rendement vanuit het centrum';

  @override
  String get cityYieldBreakdownGoldMultiplierDetail =>
      'Percentage bonus na optelling van goudbronnen';

  @override
  String get cityYieldBreakdownBaseScience => 'Basis van de stad';

  @override
  String get cityYieldBreakdownBaseScienceDetail =>
      'Vaste wetenschap gegenereerd door elke stad';

  @override
  String get cityYieldBreakdownResearchProject => 'Onderzoeksproject';

  @override
  String get cityYieldBreakdownResearchProjectDetail =>
      'Huidige stadsproductie omgezet in wetenschap';

  @override
  String get cityYieldBreakdownScienceSpecializationDetail =>
      'Stadswetenschappelijk profiel';

  @override
  String get cityYieldBreakdownScienceTechnologyDetail =>
      'Wetenschapsbonus van ontgrendelde technologieën';

  @override
  String get cityYieldBreakdownNoWorkedPopulationFields =>
      'Geen bewerkte populatievelden';

  @override
  String get cityYieldBreakdownOneWorkedPopulationField =>
      '1 bewerkt bevolkingsveld';

  @override
  String cityYieldBreakdownManyWorkedPopulationFields(int count) {
    return '$count bewerkte populatievelden';
  }

  @override
  String get cityYieldBreakdownNoAssignedWorkers =>
      'Geen toegewezen werknemers';

  @override
  String get cityYieldBreakdownOneAssignedWorker =>
      '1 veld geactiveerd door een arbeider';

  @override
  String cityYieldBreakdownManyAssignedWorkers(int count) {
    return '$count-velden geactiveerd door werknemers';
  }

  @override
  String get cityYieldBreakdownNoPassiveImprovements =>
      'Geen passieve verbeteringen';

  @override
  String get cityYieldBreakdownOnePassiveImprovement =>
      '1 onbewerkte verbetering, halve opbrengst';

  @override
  String cityYieldBreakdownManyPassiveImprovements(int count) {
    return '$count onbewerkte verbeteringen, halve opbrengst';
  }

  @override
  String get cityYieldBreakdownNoBuildings => 'Geen gebouwen';

  @override
  String get cityYieldBreakdownBuildingsNoDirectYield =>
      'Gebouwen zonder direct rendement';

  @override
  String get cityYieldBreakdownOneBuildingEconomicEffect =>
      '1 gebouw met een economisch effect';

  @override
  String cityYieldBreakdownManyBuildingEconomicEffects(int count) {
    return '$count gebouwen met economische effecten';
  }

  @override
  String get cityYieldBreakdownNoTechnologyYield =>
      'Geen technologie-opbrengstbonus';

  @override
  String get cityYieldBreakdownTechnologyYield =>
      'Bonussen van ontgrendelde technologieën';

  @override
  String get cityYieldBreakdownNoScienceBuildings => 'Geen wetenschapsgebouwen';

  @override
  String get cityYieldBreakdownOneScienceBuilding => '1 wetenschapsgebouw';

  @override
  String cityYieldBreakdownManyScienceBuildings(int count) {
    return '$count wetenschappelijke gebouwen met afnemende opbrengsten';
  }

  @override
  String cityYieldBreakdownGrowthFood(int storedFood, int growthCost) {
    return '$storedFood/$growthCost voedsel';
  }

  @override
  String get cityYieldBreakdownStagnation => 'stagnatie';

  @override
  String cityYieldBreakdownUpkeepBlocked(int population, int cost) {
    return 'Bevolking $population: kosten $cost, groei gestopt';
  }

  @override
  String cityYieldBreakdownUpkeepCost(int population) {
    return 'Voedselonderhoud voor bevolking $population';
  }

  @override
  String get cityYieldBreakdownGrowthSpecializationDetail =>
      'Groeiprofiel van de stad';

  @override
  String get cityYieldBreakdownIndustrySpecializationDetail =>
      'Profiel van de stadsindustrie';

  @override
  String get cityYieldBreakdownCommerceSpecializationDetail =>
      'Stadshandelsprofiel';

  @override
  String get cityYieldBreakdownScienceSpecializationCityDetail =>
      'Stadswetenschappelijk profiel';

  @override
  String get cityYieldBreakdownMilitarySpecializationDetail =>
      'Profiel van het stadsgarnizoen';

  @override
  String get cityYieldBreakdownNoSpecialization => 'Geen specialisatie';

  @override
  String get cityProjectWealth => 'Rijkdom';

  @override
  String get cityProjectResearch => 'Onderzoek';

  @override
  String get cityProductionProjectsSection => 'Stadsprojecten';

  @override
  String get cityProductionSpecializationSection => 'Specialisatie van de stad';

  @override
  String get cityProductionSortLabel => 'Soort';

  @override
  String cityProductionHeaderSubtitle(
    String title,
    String productionPerTurn,
    int gold,
  ) {
    return '$title • $productionPerTurn • $gold goud';
  }

  @override
  String get cityProductionBuiltLabel => 'Gebouwd';

  @override
  String get cityProductionAvailableLabel => 'Beschikbaar';

  @override
  String get cityProductionAvailableUnitLabel => 'Beschikbaar';

  @override
  String cityProductionUnitSupplyLimit(int used, int capacity) {
    return 'Voedsellimiet $used/$capacity';
  }

  @override
  String cityProductionUnitSupplyCost(int cost) {
    return 'voedsel $cost';
  }

  @override
  String cityProductionUnitSupplyUsed(int used, int capacity) {
    return 'limiet $used/$capacity';
  }

  @override
  String cityProductionNextWorkerUpkeep(int upkeep) {
    return 'volgende onderhoud: $upkeep';
  }

  @override
  String cityProductionCostShort(int production) {
    return '$production-artikelnr.';
  }

  @override
  String cityProductionPaceShort(int production) {
    return '$production prod./beurt';
  }

  @override
  String get cityBuildingSortRecommended => 'Aanbevolen';

  @override
  String cityBuildingReplaceProgressWarning(String building) {
    return 'Als u een ander gebouw kiest, wordt $building vervangen. De vooruitgang zal behouden blijven.';
  }

  @override
  String get cityBuildingSortFastestImpact => 'Snelste impact';

  @override
  String get cityBuildingSortBestReturn => 'Beste rendement';

  @override
  String get cityBuildingSortGrowth => 'Groei';

  @override
  String get cityBuildingSortIndustry => 'Industrie';

  @override
  String get cityBuildingSortScience => 'Wetenschap';

  @override
  String get cityBuildingSortDefenseMilitary => 'Defensie/militair';

  @override
  String get cityBuildingSortEconomy => 'Economie';

  @override
  String get cityBuildingRequiresTechnology => 'Vereist technologie';

  @override
  String get cityProductionContinuous => 'continu';

  @override
  String get cityProductionNoProduction => 'geen productie';

  @override
  String get cityProductionReady => 'klaar';

  @override
  String get cityProductionTurnOne => '1 beurt';

  @override
  String cityProductionTurns(int turns) {
    return '$turns bochten';
  }

  @override
  String cityProductionTreasuryGold(int gold) {
    return 'Schatkist: $gold goud';
  }

  @override
  String cityProductionRushAction(int gold) {
    return 'Spoed -$gold';
  }

  @override
  String cityProjectGoldPerTurn(int gold) {
    return '+$gold goud / beurt';
  }

  @override
  String cityProjectSciencePerTurn(int science) {
    return '+$science wetenschap / beurt';
  }

  @override
  String get citySpecializationGrowth => 'Groei';

  @override
  String get citySpecializationIndustry => 'Industrie';

  @override
  String get citySpecializationCommerce => 'Handel';

  @override
  String get citySpecializationMilitary => 'Garnizoen';

  @override
  String get citySpecializationGrowthBonus => '+2 eten';

  @override
  String get citySpecializationIndustryBonus => '+2 productie';

  @override
  String get citySpecializationCommerceBonus => '+3 goud';

  @override
  String get citySpecializationScienceBonus => '+2 wetenschap';

  @override
  String get citySpecializationMilitaryProductionBonus => '+1 productie';

  @override
  String get citySpecializationMilitaryDefenseBonus => '+2 verdediging';

  @override
  String get citySpecializationMilitaryUnitProductionBonus =>
      '+1 eenheidsprod.';

  @override
  String get citySpecializationBestFit => 'Beste match';

  @override
  String get eventCityFoundedTitle => 'Stad gesticht';

  @override
  String get eventCityBuiltBuildingTitle => 'Bouw voltooid';

  @override
  String get eventCityProducedUnitTitle => 'Eenheid getraind';

  @override
  String get eventCityClaimedHexTitle => 'Stadsgrenzen';

  @override
  String eventCityClaimedHexBody(String cityName) {
    return '$cityName: nieuwe tegel';
  }

  @override
  String get eventUnitMovedTitle => 'Eenheid beweging';

  @override
  String get eventUnitPromotedTitle => 'Eenheid gepromoveerd';

  @override
  String get eventUnitExperienceTitle => 'Ervaring';

  @override
  String eventUnitExperienceBody(String unitName, int amount, String rank) {
    return '$unitName: +$amount XP ($rank)';
  }

  @override
  String get eventUnitAttackedTitle => 'Aanval';

  @override
  String get eventCombatTitle => 'Gevecht';

  @override
  String eventCombatDamageLine(String unitName, int damage, String result) {
    return '$unitName: -$damage PK -> $result';
  }

  @override
  String eventCombatNoRetaliationLine(String unitName) {
    return '$unitName: geen vergelding';
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
    return '$attackerName ($attackerCountry) viel $defenderName ($defenderCountry) aan - HP $attackerHp:$defenderHp';
  }

  @override
  String get eventDiplomaticProposalAcceptedStatus => 'Geaccepteerd';

  @override
  String get eventDiplomaticProposalRejectedStatus => 'Afgewezen';

  @override
  String get eventDiplomaticProposalExpiredStatus => 'Verlopen';

  @override
  String get eventUnitKilledTitle => 'Eenheid verslagen';

  @override
  String get eventUnitRetreatedTitle => 'Toevluchtsoord';

  @override
  String get eventCityCapturedTitle => 'Stad veroverd';

  @override
  String get eventCityDestroyedTitle => 'Stad vernietigd';

  @override
  String get eventTurnEndedTitle => 'De beurt is geëindigd';

  @override
  String get eventWorkerCompletedJobTitle => 'Werk voltooid';

  @override
  String get eventResearchPointsTitle => 'Wetenschap';

  @override
  String eventResearchPointsBody(String playerName, int points) {
    return '$playerName: +$points wetenschap';
  }

  @override
  String get eventTechnologyResearchedTitle => 'Technologie ontdekt';

  @override
  String get eventStrategicResourceDiscoveredTitle =>
      'Strategische grondstof ontdekt';

  @override
  String eventStrategicResourceDiscoveredBody(
    String playerName,
    String resourceName,
  ) {
    return '$playerName: $resourceName';
  }

  @override
  String eventStrategicResourceControlledDetail(int count) {
    return 'Onder controle: $count';
  }

  @override
  String eventStrategicResourceRivalDetail(int count) {
    return 'Rivalen: $count';
  }

  @override
  String eventStrategicResourceUnclaimedDetail(int count) {
    return 'Niet opgeëist: $count';
  }

  @override
  String get eventStrategicResourcePressureSecured =>
      'Voorraad veiliggesteld; verdedig de bron.';

  @override
  String get eventStrategicResourcePressureExpansionRace =>
      'Kolonisatierace: claim de dichtstbijzijnde afzetting voor je rivalen.';

  @override
  String get eventStrategicResourcePressureContested =>
      'Betwiste voorraad: rivalen beheersen ook bronnen.';

  @override
  String get eventStrategicResourcePressureRivalMonopoly =>
      'Rivaal monopolie: bereid handel of een expeditie voor.';

  @override
  String eventStrategicResourceSettleHint(int col, int row) {
    return 'Afzetting buiten grenzen op $col:$row; overweeg daar een stad te stichten.';
  }

  @override
  String get eventMapObjectiveSecuredTitle => 'Kaartdoel veiliggesteld';

  @override
  String eventMapObjectiveSecuredBody(String playerName, String objectiveName) {
    return '$playerName: $objectiveName';
  }

  @override
  String eventMapObjectiveHoldDetail(int holdTurns, int requiredHoldTurns) {
    return 'Vastgehouden: $holdTurns/$requiredHoldTurns';
  }

  @override
  String eventMapObjectiveLocationDetail(int col, int row) {
    return 'Positie: $col:$row';
  }

  @override
  String eventMapObjectiveVictoryRewardDetail(int points) {
    return '+$points overwinningspunten';
  }

  @override
  String eventMapObjectiveGoldRewardDetail(int gold) {
    return '+$gold goud/beurt';
  }

  @override
  String get eventCivilizationMetTitle => 'Nieuwe beschaving';

  @override
  String eventCivilizationMetBody(String civilizationName, String playerName) {
    return '$civilizationName ($playerName)';
  }

  @override
  String get civilizationMetPopupEyebrow => 'Beschaving tegengekomen';

  @override
  String civilizationMetPopupBody(String civilizationName) {
    return 'De beschaving van $civilizationName is aan de horizon verschenen. Een nieuwe buur, rivaal of toekomstige bondgenoot maakt nu deel uit van jouw wereld.';
  }

  @override
  String get civilizationMetPopupOk => 'OK';

  @override
  String get eventCommandRejectedTitle => 'Commando afgewezen';

  @override
  String get eventAllPlayersSubmittedTitle => 'Iedereen klaar';

  @override
  String eventAllPlayersSubmittedBody(int turn, int players) {
    return 'Draai $turn ($players)';
  }

  @override
  String get eventPlayerTimedOutTitle => 'Automatisch indienen';

  @override
  String eventPlayerTimedOutBody(String playerName, int turn) {
    return '$playerName: time-out tijdens beurt $turn';
  }

  @override
  String get eventCombatDefenderKilledDetail => 'Verdediger verslagen';

  @override
  String get eventCombatAttackerKilledDetail => 'Aanvaller verslagen';

  @override
  String get eventCombatDefenderRetreatedDetail => 'Verdediger trok zich terug';

  @override
  String eventCombatAttackDamageDetail(int damage) {
    return 'Aanval: -$damage HP';
  }

  @override
  String eventCombatRetaliationDamageDetail(int damage) {
    return 'Vergelding: -$damage HP';
  }

  @override
  String eventCombatRollDetail(int value) {
    return 'Rol $value';
  }

  @override
  String get eventCombatNoRetaliationDetail => 'Geen vergelding';

  @override
  String get eventDominationStartedTitle => 'De overheersing begon';

  @override
  String get eventDominationRivalAboveTitle => 'Rival boven de drempel';

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
    return '$held/$required-beurten vastgehouden';
  }

  @override
  String get eventDominationReadyDetail => 'Conditie gereed';

  @override
  String eventDominationKeepHoldingDetail(String turns) {
    return 'Houd langer vast voor $turns';
  }

  @override
  String eventDominationInterruptDetail(String turns) {
    return 'Onderbreken binnen $turns';
  }

  @override
  String eventTurnCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beurten',
      one: '1 beurt',
      zero: '0 beurten',
    );
    return '$_temp0';
  }

  @override
  String get eventCombatDefeatedResult => 'verslagen';

  @override
  String eventCombatDefenderRetreatedResult(int hp) {
    return '$hp HP, terugtrekken';
  }

  @override
  String eventCombatHpResult(int hp) {
    return '$hp PK';
  }

  @override
  String eventCombatTerrainModifierLabel(Object terrain) {
    return 'Terrein $terrain';
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
  String get eventCombatCityGarrisonModifier => 'Stad garnizoen';

  @override
  String get eventCombatMixedArmyModifier => 'Gemengd leger';

  @override
  String get eventCombatStatAttack => 'aanval';

  @override
  String get eventCombatStatDefense => 'verdediging';

  @override
  String get eventCombatStatHp => 'PK';

  @override
  String get eventCombatStatRange => 'bereik';

  @override
  String get eventCombatStatMobility => 'beweging';

  @override
  String get closeAction => 'Dichtbij';
}
