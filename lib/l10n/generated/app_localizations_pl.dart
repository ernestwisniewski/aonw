// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Era Nowych Światów';

  @override
  String defaultPlayerName(int index) {
    return 'Gracz $index';
  }

  @override
  String defaultCityName(int index) {
    return 'Miasto $index';
  }

  @override
  String get newGameTitle => 'NOWA GRA';

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
  String get gameModeSinglePlayerMapTitle => 'Wybierz mapę do gry solo';

  @override
  String get gameModeMultiplayerMapTitle => 'Wybierz mapę do gry online';

  @override
  String get gameModeHotSeatMapTitle => 'Wybierz mapę do trybu hot seat';

  @override
  String get gameModeSinglePlayerMapSubtitle => 'Lokalna partia przeciw AI.';

  @override
  String get gameModeMultiplayerMapSubtitle =>
      'Scenariusz startowy i mapa świata dla meczu online.';

  @override
  String get gameModeHotSeatMapSubtitle =>
      'Scenariusz startowy i mapa świata dla trybu hot seat na jednym urządzeniu.';

  @override
  String get newGameIntroTitle => 'Przygotuj wyprawę';

  @override
  String get newGameIntroSubtitle =>
      'Najpierw wybierz styl rozgrywki, potem mapę, a na końcu dopracuj graczy i tempo partii.';

  @override
  String get newGameStepPlan => 'Plan gry';

  @override
  String get newGameStepMap => 'Mapa';

  @override
  String get newGameStepReview => 'Przegląd';

  @override
  String get newGamePlanTitle => 'Jaką historię chcesz rozpocząć?';

  @override
  String get newGamePremiseTitle => 'Od osady do imperium';

  @override
  String get newGamePremiseBody =>
      'Każda partia zaczyna się od kilku kluczowych decyzji: gdzie postawić pierwsze miasto, jak rozwinąć badania, kiedy zaryzykować ekspansję i jak utrzymać przewagę na mapie.';

  @override
  String get newGameCountryTitle => 'Wybierz cywilizację';

  @override
  String get newGameCountrySubtitle =>
      'Nazwa władcy dopasuje się do wybranej cywilizacji.';

  @override
  String get newGameSinglePlayerSettingsTitle => 'Ustawienia rozgrywki';

  @override
  String get newGameGameLengthLabel => 'Długość rozgrywki';

  @override
  String get newGameLeaderLabel => 'PRZYWÓDCA';

  @override
  String get newGamePillarCities => 'Miasta';

  @override
  String get newGamePillarUnits => 'Jednostki';

  @override
  String get newGamePillarResearch => 'Badania';

  @override
  String get newGameVictoryTypesTitle => 'Drogi do zwycięstwa';

  @override
  String get newGameVictoryDominationTitle => 'Dominacja';

  @override
  String newGameVictoryDominationBody(String controlPercent, int holdTurns) {
    return 'Kontroluj $controlPercent% mapy i utrzymaj przewagę przez $holdTurns tur. Podbój nadal może zakończyć partię po wyeliminowaniu rywali.';
  }

  @override
  String get newGameVictoryArtifactsTitle => 'Artefakty';

  @override
  String newGameVictoryArtifactsBody(int artifactCount, int holdTurns) {
    return 'Umieść $artifactCount unikalnych artefaktów świata w swoich miastach i utrzymaj pełną kolekcję przez $holdTurns tur.';
  }

  @override
  String get newGameModeSinglePlayerDescription =>
      'Spokojna partia przeciw AI. Dobre miejsce na naukę systemów, testowanie startów i eksperymenty z rozwojem.';

  @override
  String get newGameModeMultiplayerDescription =>
      'Mecz online z lobby sieciowym, gotowością graczy i wspólnym wejściem na mapę.';

  @override
  String get newGameModeMultiplayerAlphaDisabled =>
      'Niedostępny w wydaniu alfa.';

  @override
  String get newGameModeHotSeatDescription =>
      'Tryb hot seat na jednym urządzeniu. Gracze przekazują sobie turę, a ekran prowadzi przez przekazanie kontroli.';

  @override
  String get newGameMapTitle => 'Wybierz świat';

  @override
  String get newGameMapSubtitle =>
      'Mapa definiuje tempo pierwszego kontaktu, dostępne zasoby, przestrzeń na miasta i charakter konfliktów.';

  @override
  String get newGameReviewTitle => 'Potwierdź wyprawę';

  @override
  String get newGameReviewSubtitle =>
      'Po potwierdzeniu przejdziesz do lobby, gdzie ustawisz nazwę gry, długość partii oraz graczy.';

  @override
  String newGameReviewSinglePlayerSubtitle(int aiCount) {
    return 'Singleplayer uruchomi się od razu z Tobą i $aiCount graczami AI.';
  }

  @override
  String get newGameReviewMissingMap =>
      'Wybierz mapę, zanim przejdziesz do konfiguracji graczy.';

  @override
  String get newGameExpeditionReady => 'Wyprawa gotowa';

  @override
  String get newGameSelectedMapLabel => 'Mapa';

  @override
  String get newGameMapPickLabel => 'Dobór mapy';

  @override
  String get newGameMapPickRandom => 'Losowy domyślny';

  @override
  String get newGameMapPickManual => 'Wybrana ręcznie';

  @override
  String get newGameWorldSourceLabel => 'Źródło';

  @override
  String newGameSinglePlayerAiSummary(int aiCount) {
    return 'Ty + $aiCount AI';
  }

  @override
  String get newGameChangeMapAction => 'Zmień mapę';

  @override
  String get newGameStartSetupAction => 'Przejdź do lobby';

  @override
  String get mainMenuLoadGame => 'Wczytaj grę';

  @override
  String get mainMenuDeveloper => 'Narzędzia';

  @override
  String get mainMenuSettings => 'Ustawienia';

  @override
  String get mainMenuSettingsSublabel => 'Tekst i audio';

  @override
  String get mainMenuExit => 'Wyjdź';

  @override
  String get mainMenuAiSublabel => 'AI';

  @override
  String get mainMenuOnlineSublabel => 'Sieć';

  @override
  String get mainMenuLocalSublabel => 'Lokalnie';

  @override
  String get mainMenuToolsSublabel => 'Edytory';

  @override
  String get mainMenuToolsTitle => 'Narzędzia';

  @override
  String get mainMenuMapEditor => 'Edytor map';

  @override
  String get mainMenuAssetsEditor => 'Edytor zasobów';

  @override
  String get mainMenuTextSize => 'Rozmiar tekstu';

  @override
  String get mainMenuTextSample => 'Przykładowy tekst gry';

  @override
  String get mainMenuManual => 'Instrukcja';

  @override
  String get mainMenuCredits => 'Autorzy';

  @override
  String get mainMenuFeedback => 'Opinie';

  @override
  String get manualTitle => 'Instrukcja sterowania';

  @override
  String get manualSubtitle =>
      'Szybka karta ruchu mapy, zaznaczania, rozkazów, paneli i przebiegu tury na desktopie oraz mobile.';

  @override
  String get manualMetaDesktop => 'Desktop';

  @override
  String get manualMetaMobile => 'Mobile';

  @override
  String get manualMetaAlpha => 'Alpha singleplayer';

  @override
  String get manualCommandLoopTitle => 'Główna pętla komend';

  @override
  String get manualCommandLoopSelectTitle => 'Wybierz';

  @override
  String get manualCommandLoopSelectBody =>
      'Wybierz jednostkę, miasto, artefakt albo pole mapy, żeby zobaczyć ważne w danym momencie akcje.';

  @override
  String get manualCommandLoopPreviewTitle => 'Podejrzyj';

  @override
  String get manualCommandLoopPreviewBody =>
      'Najedź albo stuknij raz, żeby sprawdzić cele, kolory intencji, trasy i zablokowane akcje.';

  @override
  String get manualCommandLoopConfirmTitle => 'Potwierdź';

  @override
  String get manualCommandLoopConfirmBody =>
      'Użyj chipa akcji albo wybierz podświetlony cel ponownie, żeby wykonać rozkaz.';

  @override
  String get manualCommandLoopAdvanceTitle => 'Przejdź dalej';

  @override
  String get manualCommandLoopAdvanceBody =>
      'Użyj dolnego przycisku akcji, żeby skoczyć do kolejnej decyzji albo zakończyć turę.';

  @override
  String get manualDesktopTitle => 'Sterowanie desktop';

  @override
  String get manualDesktopSubtitle =>
      'Gra myszką z szybkim podglądem mapy, precyzyjnym celowaniem i stałymi panelami.';

  @override
  String get manualMobileTitle => 'Sterowanie mobile';

  @override
  String get manualMobileSubtitle =>
      'Gra dotykiem ustawiona pod czytelne panele, świadome rozkazy i szybki przebieg tury.';

  @override
  String get manualMapCameraGroup => 'Mapa i kamera';

  @override
  String get manualOrdersGroup => 'Zaznaczanie i rozkazy';

  @override
  String get manualPanelsGroup => 'Panele i pomoc';

  @override
  String get manualTurnFlowGroup => 'Przebieg tury';

  @override
  String get manualDesktopLeftClickAction => 'Lewy klik';

  @override
  String get manualDesktopLeftClickBody =>
      'Zaznacza jednostki, miasta, artefakty i pola; przy aktywnym rozkazie wybiera cel.';

  @override
  String get manualDesktopDragAction => 'Przeciągnij mapę';

  @override
  String get manualDesktopDragBody =>
      'Przesuwa kamerę bez zmiany aktualnego zaznaczenia ani trybu komendy.';

  @override
  String get manualDesktopZoomAction => 'Kółko myszy / trackpad';

  @override
  String get manualDesktopZoomBody =>
      'Przybliża i oddala mapę między widokiem strategicznym a taktycznym detalem.';

  @override
  String get manualDesktopHoverAction => 'Najedź kursorem';

  @override
  String get manualDesktopHoverBody =>
      'Pokazuje tooltipy, podpowiedzi celu i powody zablokowanych rozkazów przed potwierdzeniem.';

  @override
  String get manualDesktopActionChipsAction => 'Chipy akcji';

  @override
  String get manualDesktopActionChipsBody =>
      'Ruch, atak, ulepszenia, założenie miasta, pominięcie, fortyfikacja albo anulowanie trybu.';

  @override
  String get manualDesktopSecondClickAction => 'Ten sam cel dwa razy';

  @override
  String get manualDesktopSecondClickBody =>
      'Przy ruchu pierwszy klik pokazuje trasę, a drugi wykonuje ją albo dodaje do kolejki.';

  @override
  String get manualDesktopHoldAction => 'Kliknij i przytrzymaj';

  @override
  String get manualDesktopHoldBody =>
      'Otwiera szczegółowe opisy komend, zablokowanych opcji i chipów kontekstowych.';

  @override
  String get manualDesktopRailAction => 'Lewy pasek';

  @override
  String get manualDesktopRailBody =>
      'Otwiera opcje mapy, pomoc, cele, dziennik aktywności, badania i panel imperium.';

  @override
  String get manualDesktopTopPillsAction => 'Górne zasoby';

  @override
  String get manualDesktopTopPillsBody =>
      'Pokazuje rozbicie ekonomii, nauki, zasobów i presji zwycięstwa.';

  @override
  String get manualDesktopCloseAction => 'Klik poza panelem';

  @override
  String get manualDesktopCloseBody =>
      'Zamyka popupy, panele opcji i karty pomocy, a potem oddaje fokus mapie.';

  @override
  String get manualDesktopHelpAction => '?';

  @override
  String get manualDesktopHelpBody =>
      'Otwiera wszystkie zminimalizowane podpowiedzi i tutorial w dowolnym momencie, niezależnie od zaznaczenia.';

  @override
  String get manualDesktopTurnAction => 'Kolejna decyzja';

  @override
  String get manualDesktopTurnBody =>
      'Przenosi do kolejnej jednostki, badania albo wyboru miasta; kończy turę, gdy nic nie blokuje postępu.';

  @override
  String get manualMobileTapAction => 'Stuknij';

  @override
  String get manualMobileTapBody =>
      'Zaznacza jednostki, miasta, artefakty i pola; przy aktywnym rozkazie wybiera cel.';

  @override
  String get manualMobileDragAction => 'Przeciągnij palcem';

  @override
  String get manualMobileDragBody =>
      'Przesuwa kamerę bez utraty zaznaczonej jednostki albo stanu panelu.';

  @override
  String get manualMobilePinchAction => 'Uszczypnij';

  @override
  String get manualMobilePinchBody =>
      'Przybliża i oddala mapę do zwiadu, pracy miasta, planowania ruchu albo celowania.';

  @override
  String get manualMobileSecondTapAction => 'Ten sam cel dwa razy';

  @override
  String get manualMobileSecondTapBody =>
      'Najpierw pokazuje trasę ruchu, a potem po drugim stuknięciu wykonuje ją albo kolejkuje.';

  @override
  String get manualMobileActionChipsAction => 'Chipy akcji';

  @override
  String get manualMobileActionChipsBody =>
      'Dolny rząd komend obsługuje rozkazy jednostek, decyzje miast, robotników i anulowanie akcji.';

  @override
  String get manualMobileHoldAction => 'Przytrzymaj';

  @override
  String get manualMobileHoldBody =>
      'Otwiera opisy komend, zablokowanych opcji, zasobów i kontekstowych elementów UI.';

  @override
  String get manualMobileScrollAction => 'Przewijaj panele';

  @override
  String get manualMobileScrollBody =>
      'Pozwala czytać długie listy miast, badań, dziennika, dyplomacji i pomocy bez utraty stanu mapy.';

  @override
  String get manualMobileRailAction => 'Lewy pasek';

  @override
  String get manualMobileRailBody =>
      'Stuknij, żeby otworzyć opcje mapy, pomoc, cele, dziennik aktywności, badania i imperium.';

  @override
  String get manualMobileHelpAction => '?';

  @override
  String get manualMobileHelpBody =>
      'Pokazuje wszystkie zminimalizowane podpowiedzi i tutorial, kiedy chcesz wrócić do wskazówek.';

  @override
  String get manualMobileTurnAction => 'Dolna akcja';

  @override
  String get manualMobileTurnBody =>
      'Przeskakuje do kolejnej wymaganej decyzji albo kończy turę, gdy punkty akcji są zużyte.';

  @override
  String get mainMenuWhatsNew => 'Co nowego';

  @override
  String get mainMenuWhatsNewBody =>
      'Witaj w Erze Nowych Światów. Buduj miasta, prowadź dowódców, odkrywaj nowe krainy i zapisuj historię swojej cywilizacji.';

  @override
  String get mainMenuUpdateSoonTitle => 'Aktualizacja w drodze';

  @override
  String get mainMenuUpdateSoonBody =>
      'Nowsza wersja gry jest już gotowa i pojawi się na tej platformie wkrótce. Sprawdź sklep albo launcher za chwilę.';

  @override
  String get gameModeLabel => 'TRYB';

  @override
  String get gameNameLabel => 'NAZWA GRY';

  @override
  String get playersLabel => 'GRACZE';

  @override
  String get countryLabel => 'KRAJ';

  @override
  String get countryPoland => 'Polska';

  @override
  String get countryUkraine => 'Ukraina';

  @override
  String get countryGermany => 'Niemcy';

  @override
  String get countryFrance => 'Francja';

  @override
  String get countryUnitedKingdom => 'Wielka Brytania';

  @override
  String get countryItaly => 'Włochy';

  @override
  String get countrySpain => 'Hiszpania';

  @override
  String get countryNetherlands => 'Holandia';

  @override
  String get countrySweden => 'Szwecja';

  @override
  String get countryRussia => 'Rosja';

  @override
  String get countryUnitedStates => 'Stany Zjednoczone';

  @override
  String get countryCanada => 'Kanada';

  @override
  String get countryChina => 'Chiny';

  @override
  String get countryKorea => 'Korea';

  @override
  String get countryJapan => 'Japonia';

  @override
  String get countryPortugal => 'Portugalia';

  @override
  String get countryLeaderPoland => 'Kazimierz Wielki';

  @override
  String get countryLeaderUkraine => 'Jarosław Mądry';

  @override
  String get countryLeaderGermany => 'Otto von Bismarck';

  @override
  String get countryLeaderFrance => 'Napoleon Bonaparte';

  @override
  String get countryLeaderUnitedKingdom => 'Królowa Wiktoria';

  @override
  String get countryLeaderItaly => 'Juliusz Cezar';

  @override
  String get countryLeaderSpain => 'Izabela I';

  @override
  String get countryLeaderNetherlands => 'Wilhelm Orański';

  @override
  String get countryLeaderSweden => 'Gustaw Adolf';

  @override
  String get countryLeaderRussia => 'Katarzyna Wielka';

  @override
  String get countryLeaderUnitedStates => 'Abraham Lincoln';

  @override
  String get countryLeaderCanada => 'Wilfrid Laurier';

  @override
  String get countryLeaderChina => 'Qin Shi Huang';

  @override
  String get countryLeaderKorea => 'Sejong Wielki';

  @override
  String get countryLeaderJapan => 'Tokugawa Ieyasu';

  @override
  String get countryLeaderPortugal => 'Henryk Żeglarz';

  @override
  String get addPlayerAction => '+ DODAJ GRACZA';

  @override
  String get startGameAction => 'ROZPOCZNIJ';

  @override
  String get removePlayerTooltip => 'Usuń gracza';

  @override
  String get multiplayerSearchTitle => 'WYSZUKIWANIE SERWERÓW';

  @override
  String get multiplayerSearchBody => 'Lista gier online pojawi się tutaj.';

  @override
  String get multiplayerPlayersTitle => 'Gracze';

  @override
  String get multiplayerStatusTooltip => 'Status graczy';

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
    return '$playerName - $status\nRelacje: $relation';
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
    return '$playerName\n$defaultName\nRelacje: $relation';
  }

  @override
  String get multiplayerStatusActive => 'gra teraz';

  @override
  String get multiplayerStatusSubmitted => 'wysłał turę';

  @override
  String get multiplayerStatusThinking => 'myśli';

  @override
  String get multiplayerStatusWaiting => 'czeka';

  @override
  String get multiplayerStatusTimeout => 'timeout';

  @override
  String get diplomacyRelationFriendly => 'przyjazne';

  @override
  String get diplomacyRelationNeutral => 'neutralne';

  @override
  String get diplomacyRelationHostile => 'wrogie';

  @override
  String get diplomacyRelationTruce => 'rozejm';

  @override
  String get diplomacyRelationWar => 'wojna';

  @override
  String get diplomacyRelationFriendlyShort => 'przyj.';

  @override
  String get diplomacyRelationNeutralShort => 'neutr.';

  @override
  String get diplomacyRelationHostileShort => 'wrogi';

  @override
  String get diplomacyRelationTruceShort => 'rozejm';

  @override
  String get diplomacyRelationWarShort => 'wojna';

  @override
  String get commonDiplomacy => 'Dyplomacja';

  @override
  String get diplomacyScoreLabel => 'Relacje';

  @override
  String get diplomacyTreatyLabel => 'Traktat';

  @override
  String get diplomacyAttitudeLabel => 'Nastawienie';

  @override
  String get diplomacyTreatyBenefitsLabel => 'Korzyści traktatu';

  @override
  String get diplomacyFriendlyBenefits =>
      '+1 złota z handlu surowcami · prawo przemarszu';

  @override
  String get diplomacyNoTreatyBenefits => 'Brak korzyści traktatu';

  @override
  String get diplomacyScoreDriversTitle => 'Co wpływa na relacje';

  @override
  String get diplomacyScoreReasonManual => 'Ręczna zmiana';

  @override
  String get diplomacyScoreReasonUnitAttack => 'Atak na jednostkę';

  @override
  String get diplomacyScoreReasonCityAttack => 'Atak na miasto';

  @override
  String get diplomacyScoreReasonDeclarationOfWar => 'Wypowiedzenie wojny';

  @override
  String get diplomacyScoreReasonWarmongerPenalty => 'Kara za agresję';

  @override
  String get diplomacyScoreReasonProposalAccepted => 'Akceptacja propozycji';

  @override
  String get diplomacyScoreReasonProposalRejected => 'Odrzucenie propozycji';

  @override
  String get diplomacyScoreReasonMessageResponse => 'Odpowiedź na depeszę';

  @override
  String get diplomacyScoreReasonCommonEnemyCooperation =>
      'Współpraca przeciw wspólnemu wrogowi';

  @override
  String get diplomacyScoreReasonPromiseBroken => 'Złamana obietnica';

  @override
  String get diplomacyStatsTitle => 'Statystyki';

  @override
  String get diplomacyHistoryTitle => 'Historia';

  @override
  String get diplomacyMessagesTitle => 'Depesze';

  @override
  String get diplomacyIncomingMessageTitle => 'Nowa depesza';

  @override
  String diplomacyIncomingMessageFrom(String playerName) {
    return 'Od: $playerName';
  }

  @override
  String get diplomacyIncomingProposalTitle => 'Nowa propozycja';

  @override
  String diplomacyIncomingProposalFrom(String playerName) {
    return 'Od: $playerName';
  }

  @override
  String get diplomacyIncomingMessageLater => 'Później';

  @override
  String get diplomacyActionsTitle => 'Akcje';

  @override
  String get diplomacyProposalsTitle => 'Propozycje';

  @override
  String get diplomacyNoHistory => 'Brak zapisanych incydentów.';

  @override
  String get diplomacyNoMessages => 'Brak depesz.';

  @override
  String get diplomacyMilitaryStat => 'Wojsko';

  @override
  String get diplomacyCitiesStat => 'Miasta';

  @override
  String get diplomacyExpansionStat => 'Ekspansja';

  @override
  String get diplomacyArtifactsStat => 'Artefakty';

  @override
  String get diplomacyLastAggressionStat => 'Ostatnia agresja';

  @override
  String get diplomacyOwnArtifactsLabel => 'Twoje artefakty';

  @override
  String get diplomacyTargetArtifactsLabel => 'Artefakty rywala';

  @override
  String diplomacyTurnsRemaining(int turns) {
    return 'Pozostało tur: $turns';
  }

  @override
  String get diplomacyProposalFriendship => 'Propozycja przyjaźni';

  @override
  String get diplomacyProposalTruce => 'Propozycja rozejmu';

  @override
  String diplomacyProposalForecastLine(
    String proposal,
    String outcome,
    String reasons,
  ) {
    return '$proposal: $outcome · $reasons';
  }

  @override
  String get diplomacyProposalForecastAccepted => 'raczej zaakceptują';

  @override
  String get diplomacyProposalForecastRejected => 'raczej odrzucą';

  @override
  String get diplomacyProposalForecastReasonAcceptableRelations =>
      'relacje są wystarczające';

  @override
  String get diplomacyProposalForecastReasonActiveWar => 'trwa wojna';

  @override
  String get diplomacyProposalForecastReasonAtWar => 'wojna blokuje przyjaźń';

  @override
  String get diplomacyProposalForecastReasonGoldPayment => 'zapłata za pokój';

  @override
  String get diplomacyProposalForecastReasonLowRelations =>
      'relacje są zbyt niskie';

  @override
  String get diplomacyProposalForecastReasonMilitaryPressure =>
      'presja militarna';

  @override
  String get diplomacyProposalForecastReasonRecentHostility =>
      'niedawna wrogość';

  @override
  String get diplomacySendFriendship => 'Zaproponuj przyjaźń';

  @override
  String get diplomacySendTruce => 'Zaproponuj rozejm';

  @override
  String get diplomacyDeclareWar => 'Wypowiedz wojnę';

  @override
  String get diplomacyAccept => 'Akceptuj';

  @override
  String get diplomacyDecline => 'Odrzuć';

  @override
  String get diplomacyMessageTroopsNearCities =>
      'Za dużo wojsk rozmieszczonych jest pod moimi miastami.';

  @override
  String get diplomacyMessageCitiesTooClose =>
      'Zakładasz miasta zbyt blisko moich granic.';

  @override
  String get diplomacyMessageBlockedRoutes =>
      'Twoje oddziały blokują moje szlaki.';

  @override
  String get diplomacyMessageWithdrawScouts =>
      'Proszę o wycofanie zwiadowców z mojego terytorium.';

  @override
  String get diplomacyMessageAvoidEscalation =>
      'Nasze cywilizacje powinny unikać dalszej eskalacji.';

  @override
  String get diplomacyMessageCommonEnemy => 'Wspólny wróg zagraża nam obu.';

  @override
  String get diplomacyMessageExpansionProvocation =>
      'Twoja ekspansja jest odbierana jako prowokacja.';

  @override
  String get diplomacyMessagePeacefulPraise =>
      'Doceniamy pokojowe relacje między naszymi ludami.';

  @override
  String get diplomacyResponseConciliatory => 'Ugodowo';

  @override
  String get diplomacyResponseNeutral => 'Neutralnie';

  @override
  String get diplomacyResponseEvasive => 'Wymijająco';

  @override
  String get diplomacyResponseAggressive => 'Agresywnie';

  @override
  String get diplomacyStrategicResourcesTitle => 'Zasoby strategiczne';

  @override
  String get diplomacyResourceTradeBlockedByWar =>
      'Handel zasobami jest zablokowany przez wojnę.';

  @override
  String get diplomacyResourceTradeNoAvailableResources =>
      'Brak wolnych zasobów strategicznych do wymiany.';

  @override
  String diplomacyResourceTradeImportOffer(int goldPerTurn, int durationTurns) {
    return 'Oferta importu: $goldPerTurn złota/turę przez $durationTurns tur.';
  }

  @override
  String diplomacyResourceTradeImportAction(String resourceName) {
    return 'Importuj $resourceName';
  }

  @override
  String diplomacyResourceTradeExchangeOffer(int durationTurns) {
    return 'Wymiana barterowa: zasób za zasób przez $durationTurns tur.';
  }

  @override
  String diplomacyResourceTradeExchangeAction(
    String offeredResource,
    String requestedResource,
  ) {
    return 'Wymień $offeredResource za $requestedResource';
  }

  @override
  String get diplomacyResourceTradeNoActiveAgreements =>
      'Brak aktywnych umów zasobowych.';

  @override
  String get diplomacyResourceTradeImportDirection => 'Importujesz';

  @override
  String get diplomacyResourceTradeExportDirection => 'Eksportujesz';

  @override
  String get diplomacyResourceTradeBarterPrice => 'wymiana';

  @override
  String diplomacyResourceTradeGoldPerTurnPrice(int goldPerTurn) {
    return '$goldPerTurn złota/turę';
  }

  @override
  String diplomacyResourceTradeAgreementLabel(
    String direction,
    String resourceName,
    String price,
    int remainingTurns,
  ) {
    return '$direction $resourceName · $price · $remainingTurns tur';
  }

  @override
  String get notFoundScreenTitle => 'Nie znaleziono ekranu';

  @override
  String get notFoundBackToMenuAction => 'MENU';

  @override
  String get loadGameTitle => 'WCZYTAJ GRĘ';

  @override
  String get loadGameHeaderTitle => 'Zapisane gry';

  @override
  String get loadGameHeaderEmptySubtitle =>
      'Nie ma jeszcze żadnej rozpoczętej partii.';

  @override
  String get loadGameHeaderSavesSubtitle =>
      'Wróć do ostatnich partii i kontynuuj od zapisanej tury.';

  @override
  String loadGameSavesCount(int count) {
    return 'Zapisy: $count';
  }

  @override
  String get loadGameCorruptedStatus => 'Uszkodzony zapis';

  @override
  String get loadGameCorruptedAction => 'Niedostępny';

  @override
  String get loadGameCorruptedBody =>
      'Nie można odczytać tego zapisu. Możesz go usunąć z listy.';

  @override
  String get replayTitle => 'REPLAY';

  @override
  String get replayAction => 'REPLAY';

  @override
  String get replayUnavailableAction => 'BRAK REPLAY';

  @override
  String get replayErrorTitle => 'Replay niedostępny';

  @override
  String replayErrorBody(String error) {
    return 'Nie można otworzyć replay: $error';
  }

  @override
  String get replayMissingInitialSnapshotBody =>
      'Ten zapis nie zawiera startowego snapshotu replay. Rozpocznij nową grę, aby nagrywać pełną powtórkę partii.';

  @override
  String get replayCorruptLogBody =>
      'Log komend replay jest niekompletny albo nie można go odczytać.';

  @override
  String replayStepCounter(int step, int total) {
    return 'Krok $step/$total';
  }

  @override
  String endTurnButtonTurnLabel(int turn) {
    return 'TURA $turn';
  }

  @override
  String replayTurnLabel(int turn) {
    return 'Tura $turn';
  }

  @override
  String replayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zdarzenia',
      many: '$count zdarzeń',
      few: '$count zdarzenia',
      one: '1 zdarzenie',
      zero: '0 zdarzeń',
    );
    return '$_temp0';
  }

  @override
  String get replayInitialStateLabel => 'Stan początkowy';

  @override
  String get replayPreviousAction => 'Poprzedni krok';

  @override
  String get replayNextAction => 'Następny krok';

  @override
  String get replayPlayAction => 'Odtwórz replay';

  @override
  String get replayPauseAction => 'Pauza replay';

  @override
  String get replaySpeedLabel => 'Prędkość';

  @override
  String get replayPerspectiveLabel => 'Perspektywa';

  @override
  String get replayAllPlayers => 'Wszyscy gracze';

  @override
  String get replayShowTurnsLabel => 'Pokazuj tury';

  @override
  String get replayFreeCameraLabel => 'Wolna kamera';

  @override
  String mapsLoadError(String error) {
    return 'Nie udało się wczytać map: $error';
  }

  @override
  String get editorMapPickerTitle => 'Mapy edytora';

  @override
  String get editorMapPickerSubtitle =>
      'Twórz nowe światy albo poprawiaj istniejące mapy.';

  @override
  String get editorMapPickerEmptyTitle => 'Brak zapisanych map';

  @override
  String get editorMapPickerEmptyMessage =>
      'Nową mapę możesz utworzyć z nagłówka ekranu.';

  @override
  String get editorNewMapAction => 'Nowa mapa';

  @override
  String get editorDeleteMapTooltip => 'Usuń mapę';

  @override
  String get editorDeleteMapTitle => 'Usunąć mapę?';

  @override
  String editorDeleteMapMessage(String name) {
    return 'To trwale usunie „$name” i wszystkie pliki mapy.';
  }

  @override
  String get editorOpenMapErrorTitle => 'Nie udało się otworzyć mapy';

  @override
  String get editorCollapseToolbarTooltip => 'Zwiń panel edytora';

  @override
  String get editorExpandToolbarTooltip => 'Rozwiń panel edytora';

  @override
  String officialMapsCount(int count) {
    return 'Oficjalne: $count';
  }

  @override
  String yourMapsCount(int count) {
    return 'Twoje: $count';
  }

  @override
  String get officialMapsSection => 'Oficjalne';

  @override
  String get yourMapsSection => 'Twoje mapy';

  @override
  String get playAction => 'Graj';

  @override
  String get editAction => 'Edytuj';

  @override
  String get noMapsTitle => 'Brak map';

  @override
  String get noMapsMessage => 'Nie znaleziono map do rozpoczęcia gry.';

  @override
  String get gameLengthLabel => 'Długość gry';

  @override
  String get gameLengthPresetHint => 'Preset gry';

  @override
  String get gameLengthPresetUnlimited => 'Bez limitu';

  @override
  String get gameLengthPresetShort60 => 'Krótka';

  @override
  String get gameLengthPresetNormal90 => 'Normalna';

  @override
  String get gameLengthPresetStandard60 => 'Standard 60m';

  @override
  String get gameLengthPresetLong120 => 'Długa';

  @override
  String get gameLengthPresetVeryLong => 'Bardzo długa';

  @override
  String get gameLengthUnlimitedSummary => 'Bez limitu tur - obecne tempo gry';

  @override
  String gameLengthTimedSummary(int minutes, int turns) {
    return 'Cel $minutes min - limit $turns tur';
  }

  @override
  String get gameLengthScoreFallbackOn => 'z punktacją awaryjną';

  @override
  String get gameLengthScoreFallbackOff => 'bez punktacji awaryjnej';

  @override
  String get aiDifficultyLabel => 'Poziom trudności';

  @override
  String get aiDifficultyEasy => 'Łatwy';

  @override
  String get aiDifficultyNormal => 'Normalny';

  @override
  String get aiDifficultyHard => 'Trudny';

  @override
  String get aiDifficultyVeryHard => 'Bardzo trudny';

  @override
  String gameLengthVictoryRules(
    String controlPercent,
    int holdTurns,
    String fallback,
  ) {
    return 'Podbój + dominacja $controlPercent%/${holdTurns}T - $fallback';
  }

  @override
  String get mapValidationErrorTitle => 'Mapa wymaga poprawy';

  @override
  String get mapValidationLoadingTitle => 'Sprawdzanie mapy';

  @override
  String get mapValidationWarningTitle =>
      'Mapa może być za wolna dla tego presetu';

  @override
  String mapValidationLoadError(String error) {
    return 'Nie można sprawdzić mapy: $error';
  }

  @override
  String get mapValidationLoadingMessage =>
      'Waliduję starty, zasoby i tempo pierwszego kontaktu.';

  @override
  String get mapValidationIssueSlowFirstContact =>
      'Starty są daleko od siebie; 60m może mieć zbyt późny pierwszy kontakt.';

  @override
  String get mapValidationIssueLargeMap =>
      'Mapa ma dużo pól na gracza; dodaj graczy albo wybierz dłuższą grę.';

  @override
  String get mapValidationIssueInvalidPlayerCount =>
      'Liczba graczy nie pasuje do zakresu obsługiwanego przez mapę.';

  @override
  String get mapValidationIssueNoTiles => 'Mapa nie ma żadnych pól.';

  @override
  String get mapValidationIssueLowPassableTileRatio =>
      'Mapa ma zbyt mało pól dostępnych dla jednostek lądowych.';

  @override
  String get mapValidationIssueLowFoodResourceDensity =>
      'Mapa ma za mało zasobów żywności dla tej liczby graczy.';

  @override
  String get mapValidationIssueLowStrategicResourceDensity =>
      'Mapa ma za mało zasobów strategicznych.';

  @override
  String get mapValidationIssueLowLuxuryResourceDensity =>
      'Mapa ma za mało zasobów luksusowych.';

  @override
  String get mapValidationIssueStartSiteNotFoundable =>
      'Początkowy osadnik nie może założyć miasta na swoim polu.';

  @override
  String get mapValidationIssueStartSiteLowLandRing =>
      'Start ma za mało przechodnich pól w pierwszym ringu.';

  @override
  String get mapValidationIssueStartSiteLowFood =>
      'Start nie ma widocznego zasobu żywności w pobliżu.';

  @override
  String get mapValidationIssueStartSiteLowCityControl =>
      'Start ma za mało legalnych pól do pierwszej kontroli miasta.';

  @override
  String get mapValidationIssueStartSitesTooClose =>
      'Starty graczy są zbyt blisko siebie.';

  @override
  String lobbyMapPlayersSummary(String mapName, int playerCount) {
    return '$mapName - $playerCount graczy';
  }

  @override
  String get lobbyHeaderTitle => 'Przygotuj stół';

  @override
  String get lobbyHeaderSubtitle =>
      'Najpierw potwierdź cywilizację, potem dopracuj ustawienia partii i miejsca graczy.';

  @override
  String get lobbyCivilizationTitle => 'Wybierz cywilizację';

  @override
  String get lobbyCivilizationSubtitle =>
      'Tożsamość pierwszego gracza przed rozpoczęciem partii.';

  @override
  String get lobbyStepCivilization => 'Cywilizacja';

  @override
  String get lobbyStepSetup => 'Ustawienia';

  @override
  String get lobbyStepOnline => 'Online';

  @override
  String get lobbyStepPlayers => 'Gracze';

  @override
  String get lobbySetupTitle => 'Ustawienia partii';

  @override
  String get lobbySetupSubtitle =>
      'Nazwij grę, wybierz tempo i sprawdź, czy mapa pasuje do wybranej liczby graczy.';

  @override
  String get lobbyPlayersSetupTitle => 'Gracze przy stole';

  @override
  String get lobbyPlayersSetupSubtitle =>
      'Pierwszy gracz przejmuje start. Kolejne miejsca mogą być ludźmi przy tym urządzeniu albo AI.';

  @override
  String get lobbyPlayerYou => 'Ty';

  @override
  String get lobbyPlayerHost => 'Host';

  @override
  String get lobbyPlayerReady => 'gotowy';

  @override
  String get lobbyPlayerConnected => 'połączony';

  @override
  String get lobbyPlayerConnecting => 'łączy się';

  @override
  String get lobbyPlayerReconnecting => 'wraca';

  @override
  String get lobbyPlayerOffline => 'offline';

  @override
  String lobbyPlayerOpenSlot(int slotNumber) {
    return 'Wolne miejsce $slotNumber';
  }

  @override
  String get lobbyPlayerRequiredSlot => 'Potrzebne do startu';

  @override
  String get lobbyPlayerOptionalSlot => 'Może dołączyć przed startem';

  @override
  String get playerKindHuman => 'Człowiek';

  @override
  String get playerKindAi => 'AI';

  @override
  String get multiplayerServerTitle => 'Serwer gry online';

  @override
  String get connectAction => 'Połącz';

  @override
  String get refreshAction => 'Odśwież';

  @override
  String get createMatchAction => 'Utwórz mecz';

  @override
  String get noOpenMatches => 'Brak otwartych meczów';

  @override
  String get matchStatusRunning => 'Gotowy';

  @override
  String get matchStatusFinished => 'Zakończony';

  @override
  String get matchStatusAbandoned => 'Porzucony';

  @override
  String matchPlayersCount(int players, int maxPlayers) {
    return '$players/$maxPlayers graczy';
  }

  @override
  String matchReadyCount(int readyPlayers, int players) {
    return '$readyPlayers/$players gotowych';
  }

  @override
  String matchTurnInfo(String mapName, String status, int turn) {
    return '$mapName · $status · tura $turn';
  }

  @override
  String openMatchInfo(String mapName, int players, int maxPlayers, int turn) {
    return '$mapName · $players/$maxPlayers · tura $turn';
  }

  @override
  String get enterMatchAction => 'Wejdź';

  @override
  String get hideMatchAction => 'Ukryj';

  @override
  String get joinMatchAction => 'Dołącz';

  @override
  String get cancelAction => 'ANULUJ';

  @override
  String get copyAction => 'Kopiuj';

  @override
  String get shareAction => 'Udostępnij';

  @override
  String get multiplayerHomeSubtitle =>
      'Wybierz szybką kolejkę albo prywatny mecz z kodem dla znajomych.';

  @override
  String get multiplayerProfileTitle => 'Twój profil';

  @override
  String get multiplayerProfileSubtitle =>
      'Ustaw nazwę i cywilizację, którymi zagrasz w meczach online.';

  @override
  String get multiplayerProfileOptionsSubtitle =>
      'Nickname jest używany w meczach online i musi być unikalny.';

  @override
  String get multiplayerProfileSaveAction => 'Zapisz nickname';

  @override
  String get multiplayerProfileSaved => 'Zapisano nickname.';

  @override
  String get multiplayerLobbyHeaderTitle => 'Lobby online';

  @override
  String get multiplayerLobbyHeaderSubtitle =>
      'Najpierw wybierz cywilizację, potem wejdź do szybkiej gry albo utwórz prywatny stół. Mapa zostanie dobrana automatycznie.';

  @override
  String get multiplayerCountryPickTitle => 'Wybierz cywilizację';

  @override
  String get multiplayerCountryPickSubtitle =>
      'To najważniejsza decyzja przed wejściem do kolejki. Mapa w multiplayerze zostanie dobrana losowo.';

  @override
  String get multiplayerRandomMapLabel => 'Losowa mapa';

  @override
  String get multiplayerNicknameLabel => 'Nickname';

  @override
  String get multiplayerQuickplayTitle => 'Szybka gra';

  @override
  String get multiplayerQuickplaySubtitle =>
      'Automatycznie znajdzie graczy i wystartuje od 2 osób.';

  @override
  String get multiplayerCreatePrivateTitle => 'Utwórz kod';

  @override
  String get multiplayerCreatePrivateSubtitle =>
      'Prywatny mecz bez limitu czasu, tylko dla znajomych.';

  @override
  String get multiplayerJoinPrivateTitle => 'Dołącz kodem';

  @override
  String get multiplayerJoinPrivateSubtitle =>
      'Wpisz kod od znajomego i czekaj na hosta.';

  @override
  String get multiplayerQueueReadyTitle => 'Mecz gotowy';

  @override
  String get multiplayerQueueSearchingTitle => 'Szukam graczy';

  @override
  String get multiplayerQueueCountdownTitle => 'Start za chwilę';

  @override
  String get multiplayerQueueConnectingSubtitle =>
      'Łączę z serwerem i szukam wolnej kolejki.';

  @override
  String multiplayerQueueWaitingForPlayers(int minPlayers) {
    return 'Czekam na minimum $minPlayers graczy.';
  }

  @override
  String get multiplayerQueuePreparingStart =>
      'Znaleziono graczy. Przygotowuję start meczu.';

  @override
  String get multiplayerQueueStartingNow => 'Startuję mecz...';

  @override
  String multiplayerQueueStartingIn(int seconds) {
    return 'Start za $seconds s. Kolejni gracze mogą jeszcze dołączyć.';
  }

  @override
  String get multiplayerPrivateTitle => 'Mecz dla znajomych';

  @override
  String get multiplayerPrivateHostReady => 'Możesz wystartować mecz.';

  @override
  String get multiplayerPrivateWaitingForHost =>
      'Czekam, aż host wystartuje mecz.';

  @override
  String get multiplayerJoinCodeHelp =>
      'Wpisz kod, który dostałeś od znajomego.';

  @override
  String get multiplayerInviteCodeHint => 'Kod meczu';

  @override
  String get multiplayerInviteCodeLabel => 'Kod meczu';

  @override
  String get multiplayerInviteCopied => 'Kod meczu skopiowany.';

  @override
  String multiplayerInviteShareText(String inviteCode) {
    return 'Dołącz do mojego meczu AONW. Kod: $inviteCode';
  }

  @override
  String get multiplayerInviteCodeRequired => 'Podaj kod meczu.';

  @override
  String get multiplayerMapNotReady => 'Mapa nie jest gotowa do multiplayer.';

  @override
  String multiplayerRequestRejected(int statusCode) {
    return 'Serwer odrzucił żądanie ($statusCode).';
  }

  @override
  String multiplayerRequestRejectedWithReason(int statusCode, String reason) {
    return 'Serwer odrzucił żądanie ($statusCode: $reason).';
  }

  @override
  String multiplayerConnectionError(String host) {
    return 'Nie mogę połączyć się z $host. Sprawdź internet i spróbuj ponownie.';
  }

  @override
  String get multiplayerSignInRequired =>
      'Zaloguj się lub załóż konto, aby zagrać w multiplayer.';

  @override
  String get multiplayerSessionExpired =>
      'Sesja multiplayer wygasła. Zaloguj się ponownie i spróbuj jeszcze raz.';

  @override
  String get multiplayerAccountTitle => 'Konto multiplayer';

  @override
  String get multiplayerAccountSubtitle =>
      'Zaloguj się albo załóż konto, aby kontynuować.';

  @override
  String get multiplayerAccountEmailLabel => 'Email';

  @override
  String get multiplayerAccountPasswordLabel => 'Hasło';

  @override
  String get multiplayerAccountSignInTab => 'Logowanie';

  @override
  String get multiplayerAccountCreateTab => 'Nowe konto';

  @override
  String get multiplayerAccountSignInAction => 'Zaloguj';

  @override
  String get multiplayerAccountCreateAction => 'Załóż konto';

  @override
  String get multiplayerAccountSignOutAction => 'Wyloguj konto';

  @override
  String get multiplayerAccountSignedOut => 'Wylogowano z multiplayera.';

  @override
  String get multiplayerAccountInvalidEmail => 'Podaj poprawny adres email.';

  @override
  String get multiplayerAccountInvalidCredentials =>
      'Nieprawidłowy email lub hasło.';

  @override
  String get multiplayerAccountExists =>
      'Konto z tym adresem email już istnieje.';

  @override
  String get multiplayerAccountWeakPassword =>
      'Hasło musi mieć co najmniej 8 znaków.';

  @override
  String get multiplayerAccountInvalidNickname =>
      'Użyj 3-24 liter, cyfr, spacji, _ albo -.';

  @override
  String get multiplayerAccountNicknameTaken => 'Ten nickname jest już zajęty.';

  @override
  String get multiplayerAccountGenericError =>
      'Nie udało się uwierzytelnić. Spróbuj ponownie.';

  @override
  String get multiplayerMatchUnavailable => 'Ten mecz nie jest już dostępny.';

  @override
  String get multiplayerMatchFull => 'Ten mecz jest pełny.';

  @override
  String get multiplayerCountryUnavailable =>
      'Wielu graczy wybiera twój kraj. Spróbuj inny.';

  @override
  String get multiplayerMatchNotReady =>
      'Mecz nie jest jeszcze gotowy do startu.';

  @override
  String get multiplayerMatchAccessDenied => 'Nie jesteś graczem w tym meczu.';

  @override
  String get multiplayerQueueGenericError =>
      'Nie udało się wejść do kolejki multiplayer. Spróbuj ponownie.';

  @override
  String get multiplayerResumeAction => 'Wznów grę';

  @override
  String get multiplayerResumeSublabel => 'Wróć do ostatniej sesji multiplayer';

  @override
  String get multiplayerResumeLoading => 'Łączę z meczem...';

  @override
  String get multiplayerResumeFailed =>
      'Nie udało się wznowić ostatniej sesji multiplayer.';

  @override
  String get optionsTooltip => 'Opcje';

  @override
  String get optionsOpenMenuTooltip => 'Otwórz menu';

  @override
  String optionsTooltipWithCollapseHint(String tooltip) {
    return '$tooltip. Przytrzymaj, aby zwinąć menu.';
  }

  @override
  String get optionsTitle => 'Opcje';

  @override
  String get optionsSubtitle => 'Tekst, język, audio i wydajność';

  @override
  String get languageSectionTitle => 'Język';

  @override
  String get languagePolish => 'Polski';

  @override
  String get languageEnglish => 'Angielski';

  @override
  String get languageFrench => 'Francuski';

  @override
  String get languageGerman => 'Niemiecki';

  @override
  String get languageSpanish => 'Hiszpański';

  @override
  String get languageDutch => 'Niderlandzki';

  @override
  String get textScaleStandard => 'Standard';

  @override
  String get textScaleLarge => 'Duży';

  @override
  String get textScaleExtraLarge => 'Bardzo duży';

  @override
  String textScaleSemanticLabel(String label) {
    return 'Rozmiar tekstu $label';
  }

  @override
  String textScaleTooltip(String label) {
    return 'Rozmiar tekstu: $label';
  }

  @override
  String languageSemanticLabel(String label) {
    return 'Język $label';
  }

  @override
  String languageTooltip(String label) {
    return 'Język: $label';
  }

  @override
  String get audioSectionTitle => 'Audio';

  @override
  String get gameSoundsLabel => 'Dźwięki gry';

  @override
  String get soundVolumeLabel => 'Głośność dźwięków';

  @override
  String get gameMusicLabel => 'Muzyka w grze';

  @override
  String get musicVolumeLabel => 'Głośność muzyki';

  @override
  String get natureSoundsLabel => 'Odgłosy natury';

  @override
  String get natureVolumeLabel => 'Głośność natury';

  @override
  String get aiSectionTitle => 'AI';

  @override
  String get aiBatterySaverLabel => 'Oszczędzanie baterii AI';

  @override
  String get gameplaySectionTitle => 'Rozgrywka';

  @override
  String get followUnitMovementCameraLabel => 'Śledź ruch jednostki kamerą';

  @override
  String get followEnemyUnitCameraLabel => 'Śledź kamerą jednostki wroga';

  @override
  String get cinematicCameraLabel => 'Filmowa kamera';

  @override
  String get performanceSectionTitle => 'Wydajność';

  @override
  String get showFpsLabel => 'Pokaż FPS';

  @override
  String get showMapZoomLabel => 'Pokaż zbliżenie mapy';

  @override
  String get mapViewModeTooltip => 'Zmień tryb widoku mapy';

  @override
  String get mapViewGraphicUnavailableTooltip =>
      'Tryb graficzny jest niedostępny dla tej mapy';

  @override
  String get mapViewModeGraphic => 'Graficzny';

  @override
  String get mapViewModeTiles => 'Kafelki';

  @override
  String get gameOptionTerrain => 'Teren';

  @override
  String get gameOptionResources => 'Zasoby';

  @override
  String get gameOptionHeight => 'Wysokość';

  @override
  String get gameOptionCitySites => 'Miejsca pod miasta';

  @override
  String get gameOptionCityGrowth => 'Rozwój miast';

  @override
  String get gameOptionShowHexes => 'Pokaż hexy';

  @override
  String get gameOptionShowHeight => 'Pokaż wysokość';

  @override
  String get gameOptionDiceTest => 'Test kości';

  @override
  String get gameOptionAutoActionFlow => 'Automatyczne kończenie akcji';

  @override
  String get gameOptionAutoTurnFlow => 'Automatyczne kończenie tur';

  @override
  String get helpPopupsTitle => 'Podpowiedzi';

  @override
  String get autoTurnHintTitle => 'Automatyczne kończenie tur';

  @override
  String get autoTurnHintBody =>
      'Automatyczne kończenie tur wysyła turę, gdy nie ma już ważnych akcji. Automatyczne kończenie akcji możesz kontrolować osobno w opcjach mapy.';

  @override
  String get autoTurnHintEnableAction => 'Włącz';

  @override
  String get autoTurnHintDisableAction => 'Wyłącz';

  @override
  String get autoTurnHintStatusOn => 'Włączone';

  @override
  String get autoTurnHintStatusOff => 'Wyłączone';

  @override
  String get autoTurnHintMinimizedSubtitle =>
      'Szybki przełącznik automatycznego prowadzenia tury.';

  @override
  String visibilityShowAction(String label) {
    return 'Pokaż $label';
  }

  @override
  String visibilityHideAction(String label) {
    return 'Ukryj $label';
  }

  @override
  String get resignAction => 'Rezygnuj';

  @override
  String get resignMatchTitle => 'Zrezygnować z meczu?';

  @override
  String get resignMatchMessage => 'Mecz zostanie zakończony.';

  @override
  String get resignMatchError => 'Nie udało się zrezygnować z meczu.';

  @override
  String get creditsTitle => 'Autorzy';

  @override
  String creditsCreatedBy(String name) {
    return 'Autor: $name';
  }

  @override
  String get deleteGameTitle => 'Usuń grę';

  @override
  String deleteGameMessage(String name) {
    return 'Usunąć \"$name\"? Tego nie można cofnąć.';
  }

  @override
  String get deleteAction => 'USUŃ';

  @override
  String get retryAction => 'PONÓW';

  @override
  String get noSavedGames => 'Brak zapisanych gier.';

  @override
  String get resumeAction => 'WZNÓW';

  @override
  String get newGameAction => 'NOWA GRA';

  @override
  String get turnActionButtonLabel => 'Akcja';

  @override
  String get endTurnButtonLabel => 'Koniec tury';

  @override
  String get waitingTurnButtonLabel => 'Czeka';

  @override
  String get waitingForPlayersTooltip => 'Czeka na innych graczy';

  @override
  String submitTurnTooltip(int turn) {
    return 'Zgłoś gotowość w turze $turn';
  }

  @override
  String endTurnTooltip(int turn) {
    return 'Koniec tury $turn';
  }

  @override
  String get nextActionTooltip => 'Przejdź do następnej akcji';

  @override
  String nextActionWithCountTooltip(int count) {
    return 'Przejdź do następnej akcji ($count pozostało)';
  }

  @override
  String get turnActionListTooltip => 'Wybierz akcję z listy';

  @override
  String get hudActionDeckCollapseTooltip => 'Zwiń dolny pasek';

  @override
  String get hudActionDeckExpandTooltip => 'Rozwiń dolny pasek';

  @override
  String get turnActionUnitKind => 'Jednostka';

  @override
  String get turnActionCityProductionKind => 'Miasto';

  @override
  String get turnActionResearchKind => 'Badania';

  @override
  String turnActionCityProductionLabel(String cityName) {
    return '$cityName produkcja';
  }

  @override
  String get turnActionResearchLabel => 'Wybierz badanie';

  @override
  String turnLabel(int turn) {
    return 'TURA $turn';
  }

  @override
  String loadGameError(String error) {
    return 'Błąd wczytywania: $error';
  }

  @override
  String get backAction => 'Wróć';

  @override
  String get continueAction => 'Dalej';

  @override
  String get gameLoadingTitle => 'Wczytywanie świata';

  @override
  String get gameLoadingMessage =>
      'Przygotowujemy mapę, jednostki i interfejs. Gra pokaże się dopiero, gdy assety będą gotowe.';

  @override
  String get firstTurnTutorialPopupTitle => 'Samouczek';

  @override
  String get firstTurnTutorialPopupSubtitle =>
      'Przewodnik po pierwszych turach';

  @override
  String firstTurnTutorialSemantics(String title) {
    return 'Pierwsza tura: $title';
  }

  @override
  String firstTurnCoachmarkProgressLabel(int current, int total) {
    return 'Krok $current/$total';
  }

  @override
  String get firstTurnCoachmarkMinimizeTooltip => 'Minimalizuj';

  @override
  String get firstTurnCoachmarkSkipAction => 'Pomiń';

  @override
  String get firstTurnCoachmarkNextAction => 'Dalej';

  @override
  String get firstTurnCoachmarkDoneAction => 'Gotowe';

  @override
  String get firstTurnCoachmarkSelectionTitle => 'Krok 1: sprawdź zaznaczenie';

  @override
  String get firstTurnCoachmarkSelectionBody =>
      'Gra zaczyna od automatycznego zaznaczenia pierwszej jednostki. Dolny panel mówi, kim dowodzisz, ile zostało akcji i jakie rozkazy możesz wykonać teraz.';

  @override
  String get firstTurnCoachmarkSelectionBodyUnit =>
      'Dolny toolbar opisuje zaznaczoną jednostkę: typ, ruch, kolejkę akcji i dostępne rozkazy. To tam włączasz Ruch i możesz go anulować, gdy chcesz wrócić do zwykłego sprawdzania heksów.';

  @override
  String get firstTurnCoachmarkSelectionBodyCity =>
      'Masz zaznaczone miasto. Dolny panel pokazuje jego produkcję, populację, budynki i decyzje gospodarcze. To inny kontekst niż rozkazy jednostki, więc tutorial będzie mówił o mieście.';

  @override
  String get firstTurnCoachmarkSelectionBodyNone =>
      'Gdy nic nie jest zaznaczone, dolny panel pokaże ogólny stan tury. Dotknij własnej jednostki albo miasta, aby zobaczyć konkretne rozkazy i informacje.';

  @override
  String get firstTurnCoachmarkResourcesTitle =>
      'Krok 2: oceń sytuację państwa';

  @override
  String get firstTurnCoachmarkResourcesBody =>
      'Górny pasek pokazuje turę, złoto, naukę i zasoby. Złoto utrzymuje gospodarkę, nauka pcha badania, a zasoby podpowiadają, co warto budować.';

  @override
  String get firstTurnCoachmarkMenuTitle => 'Krok 3: poznaj lewe menu';

  @override
  String get firstTurnCoachmarkMenuBody =>
      'Lewe menu zbiera widoki, do których wracasz co turę: opcje mapy, odpowiedzi zminimalizowanych popupów, cele, dziennik, badania i imperium. Przytrzymanie przycisku menu zwija pasek, a pojedynczy przycisk otwiera go ponownie.';

  @override
  String get firstTurnCoachmarkActionTitle => 'Krok 4: wydaj właściwy rozkaz';

  @override
  String get firstTurnCoachmarkActionBodyActive =>
      'Jeśli osadnik stoi na dobrym polu, użyj akcji założenia miasta. Jeśli miejsce jest słabe, przesuń jednostkę i odsłoń teren. Ruch i akcje specjalne zużywają turę jednostki.';

  @override
  String get firstTurnCoachmarkActionBodyWaiting =>
      'Gdy jednostka ma rozkaz, pojawi się tutaj. W pierwszych turach przechodzisz kolejno przez jednostki i miasta, aż żadna ważna decyzja nie zostanie pominięta.';

  @override
  String get firstTurnCoachmarkActionBodySettler =>
      'Osadnik decyduje o starcie państwa. Jeśli pole daje dobry wzrost, produkcję i miejsce na rozwój, załóż miasto. Jeśli teren jest słaby, przesuń osadnika i sprawdź okolicę przed decyzją.';

  @override
  String get firstTurnCoachmarkActionBodyWorker =>
      'Robotnik nie zakłada miasta. Jego zadaniem jest rozwijać pola w granicach miasta: farmy pomagają rosnąć, kopalnie zwiększają produkcję, a ulepszenia zasobów wzmacniają gospodarkę.';

  @override
  String get firstTurnCoachmarkActionBodyUnit =>
      'Dla jednostek bojowych i zwiadowczych najważniejsze są ruch, rozpoznanie i bezpieczeństwo. Odsłaniaj teren, pilnuj granic miasta i atakuj tylko wtedy, gdy przewidywany wynik jest korzystny.';

  @override
  String get firstTurnCoachmarkActionBodyCity =>
      'Przy zaznaczonym mieście ten obszar prowadzi do produkcji i zarządzania. Wybierz cel budowy, sprawdź rozwój miasta i pilnuj, żeby miasto nie stało bez zadania.';

  @override
  String get firstTurnCoachmarkResearchTitle => 'Krok 5: wybierz badania';

  @override
  String get firstTurnCoachmarkResearchBody =>
      'Otwórz Badania przed końcem tury. Rolnictwo wzmacnia wzrost, Górnictwo produkcję, a Łowiectwo rozpoznanie i obronę. Najważniejsze: nauka nie powinna iść bez celu.';

  @override
  String get firstTurnCoachmarkResearchBodyAvailable =>
      'Masz badania gotowe do wyboru. Otwórz Badania przed końcem tury: Rolnictwo wzmacnia wzrost, Górnictwo produkcję, a Łowiectwo rozpoznanie i obronę.';

  @override
  String get firstTurnCoachmarkCityTitle => 'Krok 6: ustaw miasto';

  @override
  String get firstTurnCoachmarkCityBody =>
      'Po założeniu stolicy wybierz produkcję. Robotnik rozwija pola, wojownik zabezpiecza teren, a budynki wzmacniają ekonomię. Miasto powinno zawsze coś budować.';

  @override
  String get firstTurnCoachmarkCityBodySelected =>
      'To jest panel miasta. Sprawdź produkcję, wzrost, budynki i dostępne projekty. Najważniejsza zasada nowych tur: każde miasto powinno mieć wybrany cel produkcji.';

  @override
  String get firstTurnCoachmarkCityBodyNeedsProduction =>
      'Jedno z twoich miast czeka na produkcję. Użyj przycisku akcji albo zaznacz miasto, wybierz jednostkę, budynek albo projekt i dopiero wtedy kończ turę.';

  @override
  String get firstTurnCoachmarkCityBodyExisting =>
      'Twoje miasta pracują już nad produkcją. W kolejnych turach wracaj tu, aby kontrolować wzrost, budynki, specjalizację i potrzeby obronne.';

  @override
  String get firstTurnCoachmarkCityBodyFuture =>
      'Gdy założysz pierwsze miasto, wrócisz tu po wybór produkcji. Robotnik rozwija pola, wojownik zabezpiecza teren, a budynki wzmacniają ekonomię.';

  @override
  String get firstTurnCoachmarkActionFlowTitle => 'Krok 7: przejdź po akcjach';

  @override
  String get firstTurnCoachmarkActionFlowBodyReady =>
      'Wszystkie kluczowe decyzje tej tury są gotowe. Przed zakończeniem tury sprawdź jeszcze, czy badania i produkcja miasta mają wybrany cel.';

  @override
  String get firstTurnCoachmarkActionFlowBodyPending =>
      'Przycisk akcji prowadzi do następnej jednostki, miasta albo brakującego wyboru. Klikaj go, dopóki gra nie pokaże, że można bezpiecznie zakończyć turę.';

  @override
  String get firstTurnCoachmarkEndTurnTitle =>
      'Krok 8: zakończ turę i powtarzaj';

  @override
  String get firstTurnCoachmarkEndTurnBody =>
      'Kiedy nic nie wymaga reakcji, zakończ turę. W kolejnych turach rytm jest ten sam: zasoby, jednostki, miasto, badania, a dopiero potem koniec tury.';

  @override
  String get firstTurnCoachmarkVictoryBody =>
      'Wygrać możesz przez dominację albo przez artefakty: umieść 6 unikalnych artefaktów w swoich miastach i utrzymaj kolekcję przez 5 tur.';

  @override
  String get firstTurnCoachmarkHexTapBody =>
      'Kliknij albo tapnij kilka razy ten sam heks, aby przełączać informacje: zaznaczenie pola, artefakt, cel mapowy i opis heksa.';

  @override
  String get gameLoadMapErrorTitle => 'Nie udało się wczytać mapy';

  @override
  String gameLoadMapErrorMessage(String mapName, String error) {
    return 'Nie udało się wczytać mapy \"$mapName\": $error';
  }

  @override
  String get gameOutcomeVictoryTitle => 'Zwycięstwo';

  @override
  String get gameOutcomeDefeatTitle => 'Porażka';

  @override
  String get gameOutcomeDrawTitle => 'Remis';

  @override
  String get gameOutcomeCompleteTitle => 'Koniec gry';

  @override
  String get gameOutcomeConditionConquest => 'Podbój';

  @override
  String get gameOutcomeConditionScore => 'Punkty';

  @override
  String get gameOutcomeConditionScoreDraw => 'Remis punktowy';

  @override
  String get gameOutcomeConditionDomination => 'Dominacja';

  @override
  String get gameOutcomeConquestNoWinner => 'Na mapie zostało jedno imperium.';

  @override
  String gameOutcomeConquestWinner(String winner) {
    return '$winner zostaje ostatnim imperium na mapie.';
  }

  @override
  String get gameOutcomeScoreNoWinner => 'Limit tur rozstrzygnął wynik.';

  @override
  String gameOutcomeScoreWinner(String winner) {
    return '$winner wygrywa po limicie tur.';
  }

  @override
  String get gameOutcomeScoreDrawSubtitle =>
      'Limit tur osiągnięty. Najwyższy wynik punktowy jest remisowy.';

  @override
  String get gameOutcomeDominationNoWinner =>
      'Kontrola mapy została utrzymana.';

  @override
  String gameOutcomeDominationWinner(String winner) {
    return '$winner utrzymuje dominację terytorialną.';
  }

  @override
  String get gameOutcomeWinnerMetric => 'Zwycięzca';

  @override
  String get gameOutcomeConditionMetric => 'Warunek';

  @override
  String get gameOutcomeEliminationMetric => 'Eliminacja';

  @override
  String get gameOutcomeMapControlMetric => 'Kontrola mapy';

  @override
  String get gameOutcomeHoldMetric => 'Utrzymanie';

  @override
  String get gameOutcomeThresholdMetric => 'Próg';

  @override
  String gameOutcomeTurnsValue(int held, int required) {
    return '$held/$required tur';
  }

  @override
  String get victoryConquestPrimary => 'Podbój';

  @override
  String get victoryGoalCompact => 'Cel';

  @override
  String get victoryNoLimit => 'Bez limitu';

  @override
  String get victoryConquestTooltip =>
      'Cel: wyeliminuj rywali. Brak limitu tur.';

  @override
  String get victoryLimitLabel => 'Limit';

  @override
  String get victoryNoneValue => 'Brak';

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
      other: '$count tur',
      few: '$count tury',
      one: '1 tura',
    );
    return '$_temp0';
  }

  @override
  String get victoryRemainingLabel => 'Pozostało';

  @override
  String get victoryScoreLeaderLabel => 'Lider score';

  @override
  String victoryScoreDrawLabel(int score) {
    return 'REMIS $score';
  }

  @override
  String victoryScoreLimitReachedTooltip(int turnLimit) {
    return 'Limit $turnLimit tur osiągnięty. Wynik rozstrzyga score.';
  }

  @override
  String victoryScoreFallbackTooltip(int remainingTurns, int turnLimit) {
    return 'Score fallback za $remainingTurns tur. Limit: $turnLimit.';
  }

  @override
  String victoryLeaderTooltip(String leader) {
    return 'Lider: $leader.';
  }

  @override
  String victoryDominationTooltip(
    String leader,
    String control,
    String required,
    String hold,
  ) {
    return 'Dominacja: $leader kontroluje $control% mapy. Próg: $required%, utrzymanie: $hold.';
  }

  @override
  String get victoryLeaderLabel => 'Lider';

  @override
  String get victoryControlLabel => 'Kontrola';

  @override
  String get victoryHoldLabel => 'Utrzymanie';

  @override
  String get victoryYouLabel => 'Ty';

  @override
  String get victoryPressureLabel => 'Presja';

  @override
  String get victoryFallbackLabel => 'Fallback';

  @override
  String victoryYourGoalGainControl(int points) {
    return 'Twój cel: zdobądź jeszcze $points pp kontroli mapy.';
  }

  @override
  String get victoryYourGoalReady =>
      'Twój cel: warunek dominacji jest gotowy do rozstrzygnięcia.';

  @override
  String victoryYourGoalHold(String turns) {
    return 'Twój cel: utrzymaj próg jeszcze $turns.';
  }

  @override
  String victoryLeaderAboveThreshold(String leader) {
    return '$leader jest nad progiem; przerwij jego kontrolę zanim utrzyma cel.';
  }

  @override
  String victoryYourProgress(String control, String required) {
    return 'Twój postęp: $control% / $required%.';
  }

  @override
  String victoryPressureReachThreshold(int points) {
    return 'Dobij do progu: brakuje $points pp';
  }

  @override
  String get victoryConditionReady => 'Warunek gotowy';

  @override
  String victoryPressureHold(String turns) {
    return 'Utrzymaj jeszcze $turns';
  }

  @override
  String victoryPressureLeaderHolding(String leader, String turns) {
    return '$leader nad progiem: $turns';
  }

  @override
  String victoryPressureYourGap(int points) {
    return 'Twój cel: brakuje $points pp';
  }

  @override
  String victoryPressureLeaderGap(String leader, int points) {
    return '$leader prowadzi: brakuje $points pp';
  }

  @override
  String victoryThreatApproaching(
    String player,
    String control,
    String required,
    int points,
  ) {
    return 'Rywal zbliża się do dominacji: $player kontroluje $control% przy progu $required%; brakuje mu $points pp.';
  }

  @override
  String victoryThreatHolding(String player, String hold) {
    return 'Rywal utrzymuje próg dominacji: $player $hold.';
  }

  @override
  String victoryThreatImminent(String player, String hold) {
    return 'Rywal blisko dominacji: $player $hold.';
  }

  @override
  String victoryThreatPressureApproaching(String player, int points) {
    return '$player blisko progu: brakuje $points pp';
  }

  @override
  String victoryThreatPressureBreak(String player, String turns) {
    return 'Przerwij $player: $turns';
  }

  @override
  String get victoryBelowThreshold => 'poniżej progu';

  @override
  String victoryHoldProgress(int held, int required) {
    return '$held/$required tur';
  }

  @override
  String victoryHoldCompact(int held, int required) {
    return '$held/${required}T';
  }

  @override
  String get victoryReady => 'gotowe';

  @override
  String victoryRemainingTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'zostało $count tur',
      few: 'zostały $count tury',
      one: 'została 1 tura',
    );
    return '$_temp0';
  }

  @override
  String get returnToMenuAction => 'Wróć do menu';

  @override
  String get today => 'dzisiaj';

  @override
  String get yesterday => 'wczoraj';

  @override
  String get objectivesPanelTitle => 'CELE';

  @override
  String get objectivesCloseTooltip => 'Zamknij zadania';

  @override
  String get objectivesMenuClosePrefix => 'Zamknij cele';

  @override
  String get objectivesMenuOpenPrefix => 'Cele';

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
      other: '$count celów',
      few: '$count cele',
      one: '1 cel',
    );
    return '$_temp0';
  }

  @override
  String get objectivesMenuBadgeScore => 'PKT';

  @override
  String get objectivesMenuBadgeDomination => 'DOM';

  @override
  String get objectivesMenuDescriptorDomination => 'dominacja';

  @override
  String get objectivesMenuDescriptorDominationThreat => 'zagrożenie dominacją';

  @override
  String get objectivesMenuDescriptorScoreLead => 'obrona prowadzenia';

  @override
  String get objectivesMenuDescriptorScorePressure => 'presja punktów';

  @override
  String get objectivesMenuDescriptorActiveObjective => 'aktywny cel';

  @override
  String get objectiveMicroTooltipLabel => 'Dlaczego';

  @override
  String get objectiveOverviewGuidanceLabel => 'AKTYWNY CEL';

  @override
  String get objectiveOverviewStrategicLabel => 'PILNE';

  @override
  String get objectiveOverviewScoreCatchUpLabel => 'PRESJA PUNKTÓW';

  @override
  String get objectiveOverviewScoreProtectLabel => 'OBRONA PROWADZENIA';

  @override
  String get objectiveOverviewDominationHoldLabel => 'DOMINACJA';

  @override
  String get objectiveOverviewDominationThreatLabel => 'ZAGROŻENIE DOMINACJĄ';

  @override
  String objectiveOverviewTitleLabel(String title) {
    return 'Najważniejsze: $title';
  }

  @override
  String objectiveOverviewProgressLabel(String progress) {
    return 'Postęp $progress';
  }

  @override
  String get objectivePhaseFoundation => 'Fundament';

  @override
  String get objectivePhaseExpansion => 'Ekspansja';

  @override
  String get objectivePhasePressure => 'Presja';

  @override
  String get objectivePhaseEndgame => 'Finał';

  @override
  String get objectiveChooseResearchTitle => 'Wybierz badania';

  @override
  String get objectiveChooseResearchHint =>
      'Nadaj kierunek rozwoju, zanim minie pierwsza tura.';

  @override
  String get objectiveChooseResearchReward => '+ tempo nauki';

  @override
  String get objectiveChooseResearchTooltip =>
      'Badania zmieniają każdą kolejną turę w konkretny kierunek rozwoju.';

  @override
  String get objectiveFoundCapitalTitle => 'Załóż pierwsze miasto';

  @override
  String get objectiveFoundCapitalHint =>
      'Osadnik powinien szybko zamienić dobry teren w stolicę.';

  @override
  String get objectiveFoundCapitalReward => '+ baza produkcji';

  @override
  String get objectiveFoundCapitalTooltip =>
      'Stolica uruchamia produkcję, wzrost i zasięg terytorium.';

  @override
  String get objectiveExploreNearbyTitle => 'Odkryj okolicę';

  @override
  String get objectiveExploreNearbyHint =>
      'Wojownik powinien odsłonić pobliskie zasoby i miejsca pod miasta.';

  @override
  String get objectiveExploreNearbyReward => '+ lepsze decyzje';

  @override
  String get objectiveExploreNearbyTooltip =>
      'Wczesne rozpoznanie pomaga wybrać miejsca pod miasta i uniknąć ślepych ruchów.';

  @override
  String get objectiveQueueWorkerTitle => 'Zleć robotnika';

  @override
  String get objectiveQueueWorkerHint =>
      'Robotnik zamienia żywność i produkcję z mapy w realną przewagę.';

  @override
  String get objectiveQueueWorkerReward => '+ rozwój pól';

  @override
  String get objectiveQueueWorkerTooltip =>
      'Robotnik zamienia dobre pola w stały przyrost zasobów.';

  @override
  String get objectiveImproveFirstHexTitle => 'Ulepsz pierwsze pole';

  @override
  String get objectiveImproveFirstHexHint =>
      'Pierwsze ulepszenie powinno wesprzeć żywność, produkcję albo złoto.';

  @override
  String get objectiveImproveFirstHexReward => '+ mocniejsza ekonomia';

  @override
  String get objectiveImproveFirstHexTooltip =>
      'Pierwsze ulepszenie pokazuje, która ekonomia miasta ma rosnąć najszybciej.';

  @override
  String get objectiveFoundSecondCityTitle => 'Załóż drugie miasto';

  @override
  String get objectiveFoundSecondCityHint =>
      'Druga osada otwiera ekspansję bez zalewania mapy jednostkami.';

  @override
  String get objectiveFoundSecondCityReward => '+ skala imperium';

  @override
  String get objectiveFoundSecondCityTooltip =>
      'Drugie miasto zwiększa tempo produkcji bez czekania na jedną stolicę.';

  @override
  String get objectiveBuildFirstBuildingTitle => 'Zbuduj pierwszy budynek';

  @override
  String get objectiveBuildFirstBuildingHint =>
      'Pierwszy budynek powinien wzmacniać jedzenie, produkcję albo złoto.';

  @override
  String get objectiveBuildFirstBuildingReward => '+ trwała przewaga miasta';

  @override
  String get objectiveBuildFirstBuildingTooltip =>
      'Budynki zostają w mieście i skalują się przez wiele tur.';

  @override
  String get objectiveImproveThreeHexesTitle => 'Ulepsz trzy pola';

  @override
  String get objectiveImproveThreeHexesHint =>
      'Kilka ulepszeń zmienia miasto z obozu startowego w gospodarkę.';

  @override
  String get objectiveImproveThreeHexesReward => '+ stabilny przychód';

  @override
  String get objectiveImproveThreeHexesTooltip =>
      'Trzy ulepszenia tworzą stabilną bazę pod wojsko, badania lub ekspansję.';

  @override
  String get objectiveFoundThirdCityTitle => 'Załóż trzecie miasto';

  @override
  String get objectiveFoundThirdCityHint =>
      'Trzecia osada tworzy prawdziwe imperium i drugi kierunek ekspansji.';

  @override
  String get objectiveFoundThirdCityReward => '+ skala mapowa';

  @override
  String get objectiveFoundThirdCityTooltip =>
      'Trzecie miasto daje drugi front rozwoju i więcej decyzji co turę.';

  @override
  String get objectiveExploreRegionTitle => 'Odkryj region';

  @override
  String get objectiveExploreRegionHint =>
      'Szeroka mapa ujawnia zasoby, rywali i miejsca warte obrony.';

  @override
  String get objectiveExploreRegionReward => '+ plan strategiczny';

  @override
  String get objectiveExploreRegionTooltip =>
      'Szersza mapa odsłania rywali, zasoby strategiczne i bezpieczne granice.';

  @override
  String get objectiveBuildCombatForceTitle => 'Zbuduj siłę obronną';

  @override
  String get objectiveBuildCombatForceHint =>
      'Kilka oddziałów pozwala chronić ekspansję i naciskać rywali.';

  @override
  String get objectiveBuildCombatForceReward => '+ bezpieczeństwo granic';

  @override
  String get objectiveBuildCombatForceTooltip =>
      'Stała osłona chroni osadników, robotników i rozwinięte miasta.';

  @override
  String get objectiveHoldDominationTitle => 'Utrzymaj dominację';

  @override
  String get objectiveHoldDominationHint =>
      'Jesteś nad progiem mapy. Utrzymaj kontrolę, aż odliczanie dobiegnie końca.';

  @override
  String get objectiveHoldDominationReward => '+ zwycięstwo mapowe';

  @override
  String get objectiveHoldDominationTooltip =>
      'Domination kończy grę przed score capem, jeżeli utrzymasz wymagany procent mapy przez kolejne tury.';

  @override
  String get objectiveBreakDominationHoldTitle => 'Przerwij dominację rywala';

  @override
  String get objectiveBreakDominationHoldHint =>
      'Rywal jest nad progiem mapy. Odbierz mu terytorium, zanim utrzyma cel.';

  @override
  String get objectiveBreakDominationHoldReward => '+ zatrzymany countdown';

  @override
  String get objectiveBreakDominationHoldTooltip =>
      'Jeżeli rywal spadnie poniżej progu kontroli, jego hold turns resetują się do zera.';

  @override
  String get objectiveHoldScoreLeadTitle => 'Utrzymaj prowadzenie';

  @override
  String get objectiveHoldScoreLeadHint =>
      'Limit tur jest blisko. Pilnuj wyniku i nie oddawaj przewagi w ostatnich turach.';

  @override
  String get objectiveHoldScoreLeadReward => '+ wygrana na score capie';

  @override
  String get objectiveHoldScoreLeadTooltip =>
      'Score cap rozstrzyga partię, gdy minie limit tur, więc prowadzenie punktowe trzeba utrzymać do końca.';

  @override
  String get objectiveOvertakeScoreLeaderTitle => 'Dogoń lidera punktów';

  @override
  String get objectiveOvertakeScoreLeaderHint =>
      'Limit tur jest blisko. Potrzebujesz szybkiego przyrostu score albo osłabienia lidera.';

  @override
  String get objectiveOvertakeScoreLeaderReward => '+ szansa na score cap';

  @override
  String get objectiveOvertakeScoreLeaderTooltip =>
      'Buduj miasta, populację, technologie, jednostki i ulepszenia; przy remisie score cap kończy się remisem.';

  @override
  String get objectiveSecureMapObjectiveTitle => 'Zabezpiecz cel mapowy';

  @override
  String get objectiveSecureMapObjectiveHint =>
      'Utrzymaj jednostkę albo wpływ miasta na celu, aż hold dobiegnie końca.';

  @override
  String get objectiveSecureMapObjectiveReward => '+ nagrody celu';

  @override
  String get objectiveSecureMapObjectiveTooltip =>
      'Cele mapowe mają trójkątne znaczniki i dają punkty zwycięstwa albo złoto dopiero po kolejnych turach kontroli.';

  @override
  String get objectiveBreakMapObjectiveHoldTitle => 'Przerwij cel rywala';

  @override
  String get objectiveBreakMapObjectiveHoldHint =>
      'Rywal utrzymuje cel mapowy. Wejdź na trójkątny znacznik, zanim domknie hold.';

  @override
  String get objectiveBreakMapObjectiveHoldReward => '+ zablokowany cel';

  @override
  String get objectiveBreakMapObjectiveHoldTooltip =>
      'Własna jednostka na celu kontestuje kontrolę i resetuje postęp rywala.';

  @override
  String get objectiveAdviceFoundCity =>
      'Największa luka: nowe albo przejęte miasto.';

  @override
  String get objectiveAdviceGrowPopulation =>
      'Największa luka: wzrost populacji.';

  @override
  String get objectiveAdviceClaimTerritory =>
      'Największa luka: więcej kontrolowanych pól.';

  @override
  String get objectiveAdviceConstructBuilding =>
      'Największa luka: budynek w mieście.';

  @override
  String get objectiveAdviceTrainUnit => 'Największa luka: szybka jednostka.';

  @override
  String get objectiveAdviceUnlockTechnology =>
      'Największa luka: ukończenie technologii.';

  @override
  String get objectiveAdviceImproveField => 'Największa luka: ulepszenie pola.';

  @override
  String get objectiveAdviceCollectGold => 'Największa luka: złoto do punktów.';

  @override
  String get objectiveAdviceProtectLead =>
      'Priorytet: nie oddawaj miast i domknij najbliższy przyrost score.';

  @override
  String objectiveScoreBreakdownCatchUpHeader(int delta) {
    return 'Luka score: $delta pkt';
  }

  @override
  String objectiveScoreBreakdownProtectHeader(int delta) {
    return 'Przewaga score: $delta pkt';
  }

  @override
  String objectiveScoreBreakdownCatchUpTotals(
    int playerScore,
    int comparisonScore,
  ) {
    return 'Ty $playerScore / lider $comparisonScore';
  }

  @override
  String objectiveScoreBreakdownProtectTotals(
    int playerScore,
    int comparisonScore,
  ) {
    return 'Ty $playerScore / rywal $comparisonScore';
  }

  @override
  String objectiveScoreBreakdownCatchUpDelta(int delta) {
    return 'brakuje $delta';
  }

  @override
  String objectiveScoreBreakdownProtectDelta(int delta) {
    return '+$delta';
  }

  @override
  String get objectiveScoreCategoryCity => 'Miasta';

  @override
  String get objectiveScoreCategoryPopulation => 'Populacja';

  @override
  String get objectiveScoreCategoryTerritory => 'Teren';

  @override
  String get objectiveScoreCategoryBuilding => 'Budynki';

  @override
  String get objectiveScoreCategoryUnit => 'Jednostki';

  @override
  String get objectiveScoreCategoryTechnology => 'Technologie';

  @override
  String get objectiveScoreCategoryImprovement => 'Ulepszenia';

  @override
  String get objectiveScoreCategoryGold => 'Złoto';

  @override
  String get cityBuildingGranary => 'Spichlerz';

  @override
  String get cityBuildingWaterMill => 'Młyn wodny';

  @override
  String get cityBuildingWorkshop => 'Warsztat';

  @override
  String get cityBuildingStorehouse => 'Magazyn';

  @override
  String get cityBuildingHousing => 'Mieszkania';

  @override
  String get cityBuildingMerchantHall => 'Hala kupiecka';

  @override
  String get cityBuildingStonemason => 'Kamieniarz';

  @override
  String get cityBuildingBarracks => 'Koszary';

  @override
  String get cityBuildingMarketplace => 'Targowisko';

  @override
  String get cityBuildingPort => 'Port';

  @override
  String get cityBuildingAqueduct => 'Akwedukt';

  @override
  String get cityBuildingForge => 'Kuźnia';

  @override
  String get cityBuildingStable => 'Stajnia';

  @override
  String get cityBuildingBank => 'Bank';

  @override
  String get cityBuildingBuildersGuild => 'Gildia budowniczych';

  @override
  String get cityBuildingFactory => 'Fabryka';

  @override
  String get cityBuildingLighthouse => 'Latarnia morska';

  @override
  String get cityBuildingTrainingGrounds => 'Plac ćwiczeń';

  @override
  String get cityBuildingTownHall => 'Ratusz';

  @override
  String get cityBuildingMonument => 'Pomnik';

  @override
  String get cityBuildingArchive => 'Archiwum';

  @override
  String get cityBuildingAcademy => 'Akademia';

  @override
  String get cityBuildingUniversity => 'Uniwersytet';

  @override
  String get cityBuildingObservatory => 'Obserwatorium';

  @override
  String get cityBuildingLaboratory => 'Laboratorium';

  @override
  String get cityBuildingReactor => 'Reaktor';

  @override
  String get cityBuildingCourthouse => 'Sąd';

  @override
  String get cityBuildingCourt => 'Trybunał';

  @override
  String get cityBuildingGovernorsOffice => 'Urząd gubernatora';

  @override
  String get cityBuildingSurveyorsOffice => 'Urząd mierniczy';

  @override
  String get cityBuildingPlanningOffice => 'Biuro urbanistyczne';

  @override
  String get cityBuildingApothecary => 'Apteka';

  @override
  String get cityBuildingPublicBaths => 'Łaźnie publiczne';

  @override
  String get cityBuildingHospital => 'Szpital';

  @override
  String get cityBuildingMinistries => 'Ministerstwa';

  @override
  String get cityBuildingWalls => 'Mury';

  @override
  String get cityBuildingArmory => 'Zbrojownia';

  @override
  String get cityBuildingSiegeWorkshop => 'Warsztat oblężniczy';

  @override
  String get cityBuildingCitadel => 'Cytadela';

  @override
  String get cityBuildingWarCollege => 'Akademia wojskowa';

  @override
  String get cityBuildingConscriptionOffice => 'Urząd poborowy';

  @override
  String get cityBuildingBorderFort => 'Fort graniczny';

  @override
  String get cityBuildingAirfield => 'Lotnisko wojskowe';

  @override
  String get cityBuildingArtisansGuild => 'Gildia rzemieślników';

  @override
  String get cityBuildingMasterWorkshop => 'Warsztat mistrzów';

  @override
  String get cityBuildingSteelworks => 'Huta stali';

  @override
  String get cityBuildingRailDepot => 'Dworzec kolejowy';

  @override
  String get cityBuildingPowerPlant => 'Elektrownia';

  @override
  String get cityBuildingAssemblyPlant => 'Zakład montażowy';

  @override
  String get cityBuildingRefinery => 'Rafineria';

  @override
  String get cityBuildingMapRoom => 'Sala map';

  @override
  String get cityBuildingShipyard => 'Stocznia';

  @override
  String get cityBuildingDryDock => 'Suchy dok';

  @override
  String get cityBuildingNavalAcademy => 'Akademia morska';

  @override
  String get cityBuildingHarborCustoms => 'Urząd portowy';

  @override
  String get cityBuildingMuseum => 'Muzeum';

  @override
  String get cityBuildingParliament => 'Parlament';

  @override
  String get cityBuildingBroadcastTower => 'Wieża nadawcza';

  @override
  String get cityBuildingWorldFairGrounds => 'Teren wystawy światowej';

  @override
  String get cityBuildingGranaryDescription =>
      'Wczesny budynek żywnościowy, który stabilizuje wzrost miasta.';

  @override
  String get cityBuildingWaterMillDescription =>
      'Wykorzystuje kontrolowane pola rzeczne, zwiększając żywność z miasta.';

  @override
  String get cityBuildingWorkshopDescription =>
      'Podstawowe centrum rzemiosła, które podnosi produkcję miasta.';

  @override
  String get cityBuildingStorehouseDescription =>
      'Usprawnia magazynowanie plonów i zwiększa odkładaną żywność.';

  @override
  String get cityBuildingHousingDescription =>
      'Rozbudowuje przestrzeń mieszkalną i pozwala miastu kontrolować więcej pól.';

  @override
  String get cityBuildingMerchantHallDescription =>
      'Organizuje handel lokalny i zwiększa dochód miasta.';

  @override
  String get cityBuildingStonemasonDescription =>
      'Wzmacnia zaplecze budowlane i defensywne miasta.';

  @override
  String get cityBuildingBarracksDescription =>
      'Zapewnia wojskową infrastrukturę oraz dodatkową obronę.';

  @override
  String get cityBuildingMarketplaceDescription =>
      'Rozwija handel miejski i mocno zwiększa przychód w złocie.';

  @override
  String get cityBuildingPortDescription =>
      'Otwiera miasto na handel morski i żywność z wybrzeża.';

  @override
  String get cityBuildingAqueductDescription =>
      'Dostarcza wodę, wspierając wzrost oraz dalszą ekspansję miasta.';

  @override
  String get cityBuildingForgeDescription =>
      'Koncentruje obróbkę metalu i mocno zwiększa produkcję.';

  @override
  String get cityBuildingStableDescription =>
      'Wspiera hodowlę i logistykę, dając żywność oraz produkcję.';

  @override
  String get cityBuildingBankDescription =>
      'Centralizuje finanse i znacząco zwiększa dochód miasta.';

  @override
  String get cityBuildingBuildersGuildDescription =>
      'Skupia fachowców budowlanych, przyspieszając produkcję i rozwój terytorium.';

  @override
  String get cityBuildingFactoryDescription =>
      'Przemysłowy budynek późniejszej gry, który daje dużą premię produkcyjną.';

  @override
  String get cityBuildingLighthouseDescription =>
      'Wzmacnia nadmorską gospodarkę miasta dzięki żegludze i handlowi.';

  @override
  String get cityBuildingTrainingGroundsDescription =>
      'Rozwija wojskowe szkolenie i poprawia obronność miasta.';

  @override
  String get cityBuildingTownHallDescription =>
      'Administracyjne centrum miasta, wzmacniające gospodarkę i kontrolę terenu.';

  @override
  String get cityBuildingMonumentDescription =>
      'Symbol prestiżu miasta, zapewniający złoto oraz obronę.';

  @override
  String get cityBuildingArchiveDescription =>
      'Pierwszy budynek wiedzy, który porządkuje zapisy i wspiera badania.';

  @override
  String get cityBuildingAcademyDescription =>
      'Wzmacnia miasta naukowe i przygotowuje drogę do wyższej edukacji.';

  @override
  String get cityBuildingUniversityDescription =>
      'Późniejszy budynek naukowy dla dużych, rozwiniętych miast.';

  @override
  String get cityBuildingObservatoryDescription =>
      'Łączy geografię z nauką i wspiera zaawansowane badania.';

  @override
  String get cityBuildingLaboratoryDescription =>
      'Zaplecze późnych projektów technologicznych i nowoczesnej nauki.';

  @override
  String get cityBuildingReactorDescription =>
      'Potężny budynek końcowy wymagający uranu i silnej infrastruktury.';

  @override
  String get cityBuildingCourthouseDescription =>
      'Stabilizuje duże lub zdobyte miasta przez administrację prawa.';

  @override
  String get cityBuildingCourtDescription =>
      'Rozwija prawo, polityki miasta i cywilną kontrolę.';

  @override
  String get cityBuildingGovernorsOfficeDescription =>
      'Wzmacnia specjalizację miasta oraz zarządzanie terytorium.';

  @override
  String get cityBuildingSurveyorsOfficeDescription =>
      'Ułatwia planowanie granic i zwiększa zasięg kontroli miasta.';

  @override
  String get cityBuildingPlanningOfficeDescription =>
      'Rozwija miasto przez urbanistykę, produkcję i kontrolę terenu.';

  @override
  String get cityBuildingApothecaryDescription =>
      'Wczesne zdrowie miasta, które pomaga utrzymać stabilny wzrost.';

  @override
  String get cityBuildingPublicBathsDescription =>
      'Poprawiają stabilność i wzrost większych miast.';

  @override
  String get cityBuildingHospitalDescription =>
      'Późna infrastruktura populacji dla długoterminowego rozwoju.';

  @override
  String get cityBuildingMinistriesDescription =>
      'Limitowany budynek imperium wzmacniający administrację i złoto.';

  @override
  String get cityBuildingWallsDescription =>
      'Wczesna obrona miasta przeciw pierwszym atakom.';

  @override
  String get cityBuildingArmoryDescription =>
      'Lepsze centrum rekrutacji i wyposażenia oddziałów.';

  @override
  String get cityBuildingSiegeWorkshopDescription =>
      'Produkuje i utrzymuje zaplecze machin oblężniczych.';

  @override
  String get cityBuildingCitadelDescription =>
      'Późna obrona strategiczna dla miast przy ważnych granicach.';

  @override
  String get cityBuildingWarCollegeDescription =>
      'Akademia wojskowa, która wzmacnia koordynację armii i generałów.';

  @override
  String get cityBuildingConscriptionOfficeDescription =>
      'Mobilizuje armię i przyspiesza przygotowanie nowych oddziałów.';

  @override
  String get cityBuildingBorderFortDescription =>
      'Wzmacnia obronę i widoczność na granicach imperium.';

  @override
  String get cityBuildingAirfieldDescription =>
      'Lotnisko wojskowe dla lotnictwa, zwiadu i nowoczesnej projekcji siły.';

  @override
  String get cityBuildingArtisansGuildDescription =>
      'Etap produkcji przed fabryką, oparty na rzemiośle i warsztatach.';

  @override
  String get cityBuildingMasterWorkshopDescription =>
      'Specjalistyczny warsztat dla miast nastawionych na produkcję.';

  @override
  String get cityBuildingSteelworksDescription =>
      'Ciężki przemysł oparty na żelazie lub węglu.';

  @override
  String get cityBuildingRailDepotDescription =>
      'Dworzec kolejowy usprawniający logistykę i mobilność między miastami.';

  @override
  String get cityBuildingPowerPlantDescription =>
      'Późna infrastruktura energii dla mocnej produkcji przemysłowej.';

  @override
  String get cityBuildingAssemblyPlantDescription =>
      'Końcowy budynek przemysłowy dla masowej produkcji.';

  @override
  String get cityBuildingRefineryDescription =>
      'Przetwarza ropę dla nowoczesnej armii i późnych projektów.';

  @override
  String get cityBuildingMapRoomDescription =>
      'Wspiera eksplorację, widoczność i planowanie wypraw.';

  @override
  String get cityBuildingShipyardDescription =>
      'Rozwija flotę i produkcję w miastach portowych.';

  @override
  String get cityBuildingDryDockDescription =>
      'Późny port wojenny dla większych okrętów.';

  @override
  String get cityBuildingNavalAcademyDescription =>
      'Militarna akademia morska dla wyspecjalizowanych portów.';

  @override
  String get cityBuildingHarborCustomsDescription =>
      'Urząd portowy wzmacniający handel i kontrolę wybrzeża.';

  @override
  String get cityBuildingMuseumDescription =>
      'Prestiżowy budynek imperium wzmacniający wpływ miasta.';

  @override
  String get cityBuildingParliamentDescription =>
      'Limitowany budynek cywilny dla dojrzałego państwa.';

  @override
  String get cityBuildingBroadcastTowerDescription =>
      'Wzmacnia wpływ, widoczność i komunikację imperium.';

  @override
  String get cityBuildingWorldFairGroundsDescription =>
      'Pokojowy projekt prestiżu dla bogatego, rozwiniętego miasta.';

  @override
  String get unitCommander => 'Generał';

  @override
  String get unitWarrior => 'Wojownik';

  @override
  String get unitArcher => 'Łucznik';

  @override
  String get unitSettler => 'Osadnik';

  @override
  String get unitWorker => 'Robotnik';

  @override
  String get unitMerchant => 'Kupiec';

  @override
  String get unitScout => 'Zwiadowca';

  @override
  String get unitSpearman => 'Włócznik';

  @override
  String get unitCavalry => 'Kawaleria';

  @override
  String get unitCatapult => 'Katapulta';

  @override
  String get unitHeavyInfantry => 'Ciężka piechota';

  @override
  String get unitFieldCannon => 'Działo polowe';

  @override
  String get unitRifleman => 'Strzelec';

  @override
  String get unitTank => 'Czołg';

  @override
  String get unitScoutShip => 'Okręt zwiadowczy';

  @override
  String get unitWarship => 'Okręt wojenny';

  @override
  String get unitReconPlane => 'Samolot rozpoznawczy';

  @override
  String get unitCommanderDescription =>
      'Generał dowodzi armią, prowadzi rozpoznanie i może działać szybciej niż zwykłe oddziały.';

  @override
  String get unitWarriorDescription =>
      'Podstawowa jednostka bojowa do obrony miasta oraz walki w zwarciu.';

  @override
  String get unitArcherDescription =>
      'Jednostka dystansowa, która atakuje z większego zasięgu, ale słabiej broni się w zwarciu.';

  @override
  String get unitSettlerDescription =>
      'Zakłada nowe miasta i rozszerza imperium, lecz potrzebuje ochrony w drodze.';

  @override
  String get unitWorkerDescription =>
      'Ulepsza pola wokół miast, zwiększając żywność, produkcję i złoto.';

  @override
  String get unitMerchantDescription =>
      'Porusza się automatycznie między własnymi miastami po trasie handlowej i może wejść do zajętego centrum przyjaznego miasta.';

  @override
  String get unitScoutDescription =>
      'Szybka jednostka rozpoznawcza do odkrywania mapy i wykrywania zagrożeń.';

  @override
  String get unitSpearmanDescription =>
      'Wczesna piechota defensywna, dobra do osłony miast i powstrzymywania szarż.';

  @override
  String get unitCavalryDescription =>
      'Mobilna jednostka uderzeniowa, która szybko reaguje na słabe punkty frontu.';

  @override
  String get unitCatapultDescription =>
      'Machina oblężnicza o większym zasięgu, skuteczna przeciw umocnieniom.';

  @override
  String get unitHeavyInfantryDescription =>
      'Wytrzymała piechota frontowa z wysoką obroną i solidnym atakiem.';

  @override
  String get unitFieldCannonDescription =>
      'Nowoczesna artyleria polowa do ostrzału z dystansu.';

  @override
  String get unitRiflemanDescription =>
      'Nowoczesny żołnierz dystansowy, stabilny w ataku i obronie.';

  @override
  String get unitTankDescription =>
      'Ciężka jednostka pancerna o wysokiej sile i dużej mobilności.';

  @override
  String get unitScoutShipDescription =>
      'Lekki okręt do rozpoznania wybrzeży i ochrony pierwszych tras morskich.';

  @override
  String get unitWarshipDescription =>
      'Silny okręt bojowy do kontroli morza i ostrzału z dystansu.';

  @override
  String get unitReconPlaneDescription =>
      'Samolot zwiadowczy o dużym zasięgu widzenia i bardzo wysokiej mobilności.';

  @override
  String get unitRankRecruit => 'Rekrut';

  @override
  String get unitRankSeasoned => 'Zaprawiony';

  @override
  String get unitRankVeteran => 'Weteran';

  @override
  String get unitRankElite => 'Elita';

  @override
  String get troopWarrior => 'Wojownicy';

  @override
  String get troopArcher => 'Łucznicy';

  @override
  String get troopSettler => 'Osadnicy';

  @override
  String get fieldImprovementFarm => 'Farma';

  @override
  String get fieldImprovementRiverFarm => 'Farma rzeczna';

  @override
  String get fieldImprovementMine => 'Kopalnia';

  @override
  String get fieldImprovementLumberMill => 'Tartak';

  @override
  String get fieldImprovementPasture => 'Pastwisko';

  @override
  String get fieldImprovementCamp => 'Obóz';

  @override
  String get fieldImprovementQuarry => 'Kamieniołom';

  @override
  String get fieldImprovementFishingBoats => 'Łodzie rybackie';

  @override
  String get fieldImprovementOrchard => 'Sad';

  @override
  String get fieldImprovementPlantation => 'Plantacja';

  @override
  String get fieldImprovementVineyard => 'Winnica';

  @override
  String get fieldImprovementTradingPost => 'Faktoria';

  @override
  String get fieldImprovementProspectorCamp => 'Obóz poszukiwaczy';

  @override
  String get fieldImprovementHorseRanch => 'Stadnina';

  @override
  String get fieldImprovementPearlDivers => 'Poławiacze pereł';

  @override
  String get fieldImprovementCoalShaft => 'Szyb węglowy';

  @override
  String get fieldImprovementOilWell => 'Szyb naftowy';

  @override
  String get fieldImprovementBauxiteMine => 'Kopalnia boksytu';

  @override
  String get fieldImprovementUraniumMine => 'Kopalnia uranu';

  @override
  String get resourceWheat => 'pszenicę';

  @override
  String get resourceFish => 'ryby';

  @override
  String get resourceDeer => 'zwierzynę';

  @override
  String get resourceSheep => 'owce';

  @override
  String get resourceRice => 'ryż';

  @override
  String get resourceCow => 'bydło';

  @override
  String get resourceApple => 'jabłka';

  @override
  String get resourceBanana => 'banany';

  @override
  String get resourceCitrus => 'cytrusy';

  @override
  String get resourceGold => 'złoto';

  @override
  String get resourceSilver => 'srebro';

  @override
  String get resourceGems => 'klejnoty';

  @override
  String get resourceSilk => 'jedwab';

  @override
  String get resourceSpices => 'przyprawy';

  @override
  String get resourceCotton => 'bawełnę';

  @override
  String get resourceGrapes => 'winogrona';

  @override
  String get resourceIvory => 'kość słoniową';

  @override
  String get resourcePearls => 'perły';

  @override
  String get resourceCoffee => 'kawę';

  @override
  String get resourceCocoa => 'kakao';

  @override
  String get resourceTobacco => 'tytoń';

  @override
  String get resourceSugar => 'cukier';

  @override
  String get resourceIron => 'żelazo';

  @override
  String get resourceCoal => 'węgiel';

  @override
  String get resourceOil => 'ropę';

  @override
  String get resourceAluminium => 'aluminium';

  @override
  String get resourceUranium => 'uran';

  @override
  String get resourceHorses => 'konie';

  @override
  String get resourceMarble => 'marmur';

  @override
  String get technologyAgriculture => 'Rolnictwo';

  @override
  String get technologyWoodworking => 'Obróbka drewna';

  @override
  String get technologyMining => 'Górnictwo';

  @override
  String get technologyAnimalHusbandry => 'Hodowla zwierząt';

  @override
  String get technologyHunting => 'Łowiectwo';

  @override
  String get technologyFishing => 'Rybołówstwo';

  @override
  String get technologyCraftsmanship => 'Rzemiosło';

  @override
  String get technologyTrade => 'Handel';

  @override
  String get technologyStorage => 'Magazynowanie';

  @override
  String get technologyWaterEngineering => 'Inżynieria wodna';

  @override
  String get technologyStoneworking => 'Kamieniarstwo';

  @override
  String get technologyMilitaryOrganization => 'Organizacja wojskowa';

  @override
  String get technologyAdvancedTrade => 'Zaawansowany handel';

  @override
  String get technologyConstruction => 'Budownictwo';

  @override
  String get technologyNavigation => 'Nawigacja';

  @override
  String get technologyIrrigation => 'Irygacja';

  @override
  String get technologyBanking => 'Bankowość';

  @override
  String get technologyEngineering => 'Inżynieria';

  @override
  String get technologyMetallurgy => 'Metalurgia';

  @override
  String get technologyHorsebackRiding => 'Jazda konna';

  @override
  String get technologyIronWorking => 'Obróbka żelaza';

  @override
  String get technologyCoalMining => 'Wydobycie węgla';

  @override
  String get technologyMachinery => 'Mechanizacja';

  @override
  String get technologyAdministration => 'Administracja';

  @override
  String get technologyLogistics => 'Logistyka';

  @override
  String get technologyShipbuilding => 'Budowa okrętów';

  @override
  String get technologyTactics => 'Taktyka';

  @override
  String get technologyEconomy => 'Gospodarka';

  @override
  String get technologyUrbanization => 'Urbanizacja';

  @override
  String get technologyFortifications => 'Fortyfikacje';

  @override
  String get technologyStrategy => 'Strategia';

  @override
  String get technologySpecialization => 'Specjalizacja';

  @override
  String get technologyWriting => 'Pismo';

  @override
  String get technologyMathematics => 'Matematyka';

  @override
  String get technologyMedicine => 'Medycyna';

  @override
  String get technologyCivilService => 'Służba cywilna';

  @override
  String get technologySiegecraft => 'Sztuka oblężnicza';

  @override
  String get technologyCartography => 'Kartografia';

  @override
  String get technologyGuilds => 'Gildie';

  @override
  String get technologyLaw => 'Prawo';

  @override
  String get technologyEducation => 'Edukacja';

  @override
  String get technologyUrbanPlanning => 'Planowanie urbanistyczne';

  @override
  String get technologyNavalDoctrine => 'Doktryna morska';

  @override
  String get technologySteel => 'Stal';

  @override
  String get technologyBureaucracy => 'Biurokracja';

  @override
  String get technologyNationalism => 'Nacjonalizm';

  @override
  String get technologyScientificMethod => 'Metoda naukowa';

  @override
  String get technologySteamPower => 'Silnik parowy';

  @override
  String get technologyElectricity => 'Elektryczność';

  @override
  String get technologyCombustion => 'Silnik spalinowy';

  @override
  String get technologyFlight => 'Lotnictwo';

  @override
  String get technologyMassProduction => 'Produkcja masowa';

  @override
  String get technologyRadio => 'Radio';

  @override
  String get technologyNuclearPhysics => 'Fizyka jądrowa';

  @override
  String get technologyAgricultureDescription =>
      'Otwiera podstawową ścieżkę wzrostu. Farmy i farmy rzeczne pozwalają szybciej zwiększać populację oraz stabilizują pierwsze miasto.';

  @override
  String get technologyWoodworkingDescription =>
      'Rozwija produkcyjną stronę górnictwa. Tartaki zmieniają lasy w źródło produkcji bez wchodzenia głęboko w metalurgię.';

  @override
  String get technologyMiningDescription =>
      'Otwiera ścieżkę przemysłu i infrastruktury. Kopalnie są pierwszym dużym skokiem produkcji miasta.';

  @override
  String get technologyAnimalHusbandryDescription =>
      'Wzmacnia rozwój przez zasoby zwierzęce. Pastwiska budują gospodarkę żywnościową i przygotowują drogę do jazdy konnej.';

  @override
  String get technologyHuntingDescription =>
      'Otwiera militarną i eksploracyjną gałąź. Daje obozy oraz pierwszą jednostkę dystansową do produkcji w mieście.';

  @override
  String get technologyFishingDescription =>
      'Rozwija miasta przy wodzie. Łodzie rybackie pomagają coastal city szybciej rosnąć i przygotowują drogę do portu.';

  @override
  String get technologyCraftsmanshipDescription =>
      'Pierwszy miejski upgrade produkcji. Warsztat sprawia, że kolejne budynki i jednostki nie blokują kolejki na zbyt długo.';

  @override
  String get technologyTradeDescription =>
      'Pierwszy krok w ekonomii złota. Hala kupiecka daje miastu prosty payoff finansowy po wyborze gałęzi wzrostu.';

  @override
  String get technologyStorageDescription =>
      'Stabilizuje wzrost miasta. Magazynowanie pomaga utrzymać tempo żywności i zmniejsza ryzyko przestojów rozwoju.';

  @override
  String get technologyWaterEngineeringDescription =>
      'Rozbudowuje wodną ścieżkę wzrostu. Młyn wodny nagradza miasta kontrolujące rzeki.';

  @override
  String get technologyStoneworkingDescription =>
      'Łączy produkcję i obronę. Kamieniołomy oraz kamieniarz wzmacniają miasta w gałęzi infrastruktury.';

  @override
  String get technologyMilitaryOrganizationDescription =>
      'Buduje pierwszy militarny rdzeń miasta. Koszary wzmacniają produkcję i obronę, zanim pojawią się późniejsze premie armii.';

  @override
  String get technologyAdvancedTradeDescription =>
      'Rozwija ekonomię po handlu. Targowisko jest mocniejszym budynkiem złota i przygotowuje ścieżkę do bankowości.';

  @override
  String get technologyConstructionDescription =>
      'Poszerza terytorium i dojrzewanie miasta. Mieszkania zwiększają kontrolę pól i prowadzą do administracji oraz inżynierii.';

  @override
  String get technologyNavigationDescription =>
      'Otwiera miejski payoff dla wybrzeża. Port wymaga dostępu do coast/ocean i nagradza miasta nad wodą żywnością oraz złotem.';

  @override
  String get technologyIrrigationDescription =>
      'Specjalizacja wodnego wzrostu. Akwedukt daje mocny food bonus i dodatkową kontrolę terytorium.';

  @override
  String get technologyBankingDescription =>
      'Specjalizacja gałęzi handlu. Bank zamienia wcześniejsze targi w silny przychód miasta i odblokowuje dalszą gospodarkę.';

  @override
  String get technologyEngineeringDescription =>
      'Specjalizacja budowlana. Gildia budowniczych przyspiesza produkcję i zwiększa limit kontrolowanych pól.';

  @override
  String get technologyMetallurgyDescription =>
      'Mocny payoff przemysłowy po kamieniarstwie. Kuźnia podnosi produkcję i przygotowuje ścieżkę do żelaza oraz węgla.';

  @override
  String get technologyHorsebackRidingDescription =>
      'Technologia łącząca wzrost i wojsko. Stajnia wspiera miasta, które wcześniej inwestowały w zwierzęta i łowiectwo.';

  @override
  String get technologyIronWorkingDescription =>
      'Przemysłowy efekt zasobów. Każde kontrolowane żelazo zwiększa produkcję miasta.';

  @override
  String get technologyCoalMiningDescription =>
      'Późniejszy efekt zasobów przemysłowych. Kontrolowany węgiel zwiększa produkcję miasta i wspiera ścieżkę fabryki.';

  @override
  String get technologyMachineryDescription =>
      'Późny payoff infrastruktury. Fabryka daje duży wzrost produkcji dla miast, które weszły w inżynierię.';

  @override
  String get technologyAdministrationDescription =>
      'Łączy infrastrukturę z ekonomią. Ratusz i pomnik wzmacniają dojrzałe miasta oraz prowadzą do urbanizacji.';

  @override
  String get technologyLogisticsDescription =>
      'Przyspiesza produkcję jednostek. To główna technologia dla gracza, który chce częściej wystawiać armię z miast.';

  @override
  String get technologyShipbuildingDescription =>
      'Rozwija coastal/exploration subbranch. Latarnia morska wymaga dostępu do wybrzeża i wzmacnia miasta nad wodą.';

  @override
  String get technologyTacticsDescription =>
      'Militarna specjalizacja miasta. Plac ćwiczeń dodaje obronę i produkcję dla ośrodków wojskowych.';

  @override
  String get technologyEconomyDescription =>
      'Systemowy payoff za bankowość. Zwiększa złoto generowane przez ekonomię miast.';

  @override
  String get technologyUrbanizationDescription =>
      'Końcowy kierunek rozwoju dużych miast. Zwiększa limit populacji, gdy system populacji zacznie używać twardych limitów.';

  @override
  String get technologyFortificationsDescription =>
      'Wzmacnia obronę miast. Daje defensywny bonus gospodarce miasta, a pełne znaczenie wzrośnie po rozbudowie walki i oblężeń.';

  @override
  String get technologyStrategyDescription =>
      'Końcowy kierunek wojskowy. Wzmacnia skuteczność armii jako late-game payoff po logistyce.';

  @override
  String get technologySpecializationDescription =>
      'Końcowy payoff civic/economy. Odblokowuje specjalizacje miast, dodaje naukę miastom i pomaga domykać późne technologie w dłuższej partii.';

  @override
  String get technologyWritingDescription =>
      'Pierwszy krok do nauki, prawa i administracji. Archiwum daje miastu trwałą podstawę badań.';

  @override
  String get technologyMathematicsDescription =>
      'Łączy naukę z planowaniem terytorium. Urząd mierniczy pomaga miastom lepiej kontrolować granice.';

  @override
  String get technologyMedicineDescription =>
      'Rozwija zdrowie i długoterminowy wzrost dużych miast przez apteki, łaźnie i szpitale.';

  @override
  String get technologyCivilServiceDescription =>
      'Usprawnia zarządzanie dużym imperium i odblokowuje sądy stabilizujące miasta.';

  @override
  String get technologySiegecraftDescription =>
      'Otwiera oblężenia. Katapulty i warsztaty oblężnicze przełamują miasta-fortece.';

  @override
  String get technologyCartographyDescription =>
      'Rozwija eksplorację, mapy i wybrzeże. Daje salę map oraz pierwsze okręty zwiadowcze.';

  @override
  String get technologyGuildsDescription =>
      'Daje miastom produkcyjnym etap między warsztatem a przemysłem.';

  @override
  String get technologyLawDescription =>
      'Wprowadza porządek, polityki i cywilne zarządzanie przez trybunały.';

  @override
  String get technologyEducationDescription =>
      'Buduje pełną ścieżkę naukową dla miast przez akademie i uniwersytety.';

  @override
  String get technologyUrbanPlanningDescription =>
      'Rozwija wielkie miasta i kontrolę terytorium przez planowanie przestrzenne.';

  @override
  String get technologyNavalDoctrineDescription =>
      'Zamienia porty w centra floty, stoczni i projekcji siły na morzu.';

  @override
  String get technologySteelDescription =>
      'Wprowadza ciężki przemysł oraz ciężką piechotę dla późniejszego frontu.';

  @override
  String get technologyBureaucracyDescription =>
      'Daje duży cywilny cel po administracji: urzędy, ministerstwa, muzea i parlament.';

  @override
  String get technologyNationalismDescription =>
      'Łączy obronę granic, mobilizację i tożsamość imperium.';

  @override
  String get technologyScientificMethodDescription =>
      'Przygotowuje późną naukę, laboratoria, obserwatoria i projekty technologiczne.';

  @override
  String get technologySteamPowerDescription =>
      'Otwiera kolej, cięższą logistykę i przemysł parowy.';

  @override
  String get technologyElectricityDescription =>
      'Wprowadza energię, infrastrukturę i zasięg informacyjny.';

  @override
  String get technologyCombustionDescription =>
      'Nadaje ropie znaczenie i odblokowuje nowoczesne jednostki frontowe.';

  @override
  String get technologyFlightDescription =>
      'Wprowadza lotnictwo, zwiad i projekcję siły ponad frontem.';

  @override
  String get technologyMassProductionDescription =>
      'Rozwija końcową produkcję przemysłową, czołgi i zakłady montażowe.';

  @override
  String get technologyRadioDescription =>
      'Wzmacnia komunikację, widoczność i wpływ imperium przez wieże nadawcze.';

  @override
  String get technologyNuclearPhysicsDescription =>
      'Otwiera reaktor, uran i późne projekty końcowe.';

  @override
  String get technologyEraFoundation => 'Podstawy';

  @override
  String get technologyEraSettlement => 'Osadnictwo';

  @override
  String get technologyEraExpansion => 'Ekspansja';

  @override
  String get technologyEraSpecialization => 'Specjalizacja';

  @override
  String get technologyEraIndustry => 'Przemysł';

  @override
  String get technologyEraStrategy => 'Strategia';

  @override
  String get technologyUnlockEffect => 'Efekt';

  @override
  String get technologyPrerequisitesNone => 'Brak';

  @override
  String get technologyStateCompleted => 'Ukończone';

  @override
  String get technologyStateInProgress => 'W toku';

  @override
  String get technologyStateAvailable => 'Dostępne';

  @override
  String get technologyButtonResearched => 'ZBADANE';

  @override
  String get technologyButtonActive => 'AKTYWNE';

  @override
  String get technologyButtonResearch => 'BADAJ';

  @override
  String get technologyButtonLocked => 'NIEDOSTĘPNE';

  @override
  String get technologyTreeTitle => 'DRZEWO TECHNOLOGII';

  @override
  String get technologyTreeEmptyTitle => 'Brak technologii do wyświetlenia';

  @override
  String get technologyTreeEmptyBody =>
      'Drzewko badań pojawi się tutaj, gdy ruleset udostępni technologie dla tej epoki.';

  @override
  String technologyResearchPointsShort(int points) {
    return '$points pkt';
  }

  @override
  String get technologyDetailsTooltip => 'Szczegóły technologii';

  @override
  String get technologyDetailsStatus => 'Status';

  @override
  String get technologyDetailsCost => 'Koszt';

  @override
  String get technologyDetailsProgress => 'Postęp';

  @override
  String get technologyDetailsPrerequisites => 'Wymagania';

  @override
  String get technologyDetailsUnlocks => 'Odblokowuje';

  @override
  String get technologyDetailsEffects => 'Efekty';

  @override
  String get technologyDetailsBoosts => 'Boosty';

  @override
  String get technologyDetailsUnlockStatus => 'Odblokowanie';

  @override
  String get technologyDetailsNoEffects => 'Brak efektów pasywnych';

  @override
  String get technologyDetailsNoBoosts => 'Brak boostów';

  @override
  String get technologyUnlocksNone => 'Brak bezpośrednich odblokowań';

  @override
  String get technologyBoostActiveBadge => 'Boost';

  @override
  String get technologyBoostActiveBest =>
      'Aktualnie działa najlepszy dostępny boost.';

  @override
  String technologyBoostLine(String condition, String discount) {
    return '$condition (-$discount kosztu)';
  }

  @override
  String get technologyUnlockFieldImprovementCategory => 'Ulepszenie pola';

  @override
  String technologyEffectStrategicResourceProductionBonus(
    int production,
    String resource,
  ) {
    return '+$production produkcji za każdy kontrolowany zasób: $resource';
  }

  @override
  String technologyEffectGlobalGoldMultiplier(String percent) {
    return '+$percent złota w ekonomii miast';
  }

  @override
  String technologyEffectCityDefenseBonus(int amount) {
    return '+$amount obrony miasta';
  }

  @override
  String technologyEffectArmyProductionMultiplier(String percent) {
    return '+$percent produkcji jednostek w miastach';
  }

  @override
  String technologyEffectArmyStrengthMultiplier(String percent) {
    return '+$percent siły armii';
  }

  @override
  String technologyEffectMaxCityPopulationBonus(int amount) {
    return '+$amount maksymalnej populacji miasta';
  }

  @override
  String technologyEffectMaxControlledHexesBonus(int amount) {
    return '+$amount maksymalnego terytorium miasta';
  }

  @override
  String technologyEffectCityScienceBonus(int amount) {
    return '+$amount nauki na miasto';
  }

  @override
  String technologyBoostConditionImprovementCount(
    int count,
    String improvement,
  ) {
    return 'Miej ${count}x $improvement';
  }

  @override
  String technologyBoostConditionHasImprovement(String improvement) {
    return 'Miej $improvement';
  }

  @override
  String technologyBoostConditionControlsResource(String resource) {
    return 'Kontroluj $resource';
  }

  @override
  String technologyBoostConditionControlsAnyResource(String resources) {
    return 'Kontroluj: $resources';
  }

  @override
  String technologyEffectAttackBonus(String value) {
    return '$value ataku';
  }

  @override
  String technologyEffectDefenseBonus(String value) {
    return '$value obrony';
  }

  @override
  String get technologyEffectNoArmyStatsBonus => 'Brak bonusu statystyk armii';

  @override
  String technologyEffectArmyStatsBonus(String parts) {
    return '$parts dla armii';
  }

  @override
  String commonListOr(String first, String last) {
    return '$first lub $last';
  }

  @override
  String get buildingDetailsTooltip => 'Szczegóły budynku';

  @override
  String get buildingDetailsNoRequirements => 'Brak';

  @override
  String get buildingDetailsYieldImpact => 'Wpływ na miasto';

  @override
  String buildingDetailsRequirementTechnology(String technology) {
    return 'Technologia: $technology';
  }

  @override
  String get buildingDetailsRequirementCoastalAccess => 'Dostęp do wybrzeża';

  @override
  String buildingDetailsRequirementResources(String resources) {
    return 'Zasób: $resources';
  }

  @override
  String buildingDetailsFlatYieldEffect(String yield) {
    return '$yield do wyniku miasta';
  }

  @override
  String buildingDetailsRiverHexYieldEffect(String yield) {
    return '$yield za kontrolowane pole z rzeką';
  }

  @override
  String buildingDetailsRiverHexYieldEffectWithMax(
    String yield,
    int maxApplications,
  ) {
    return '$yield za kontrolowane pole z rzeką (maks. $maxApplications)';
  }

  @override
  String buildingDetailsMaxControlledHexesEffect(int amount) {
    return '+$amount limitu kontrolowanych pól miasta';
  }

  @override
  String buildingDetailsFoodDepositMultiplierEffect(int percent) {
    return '+$percent% odkładanej żywności po turze';
  }

  @override
  String buildingDetailsYieldFood(String value) {
    return '$value żywności';
  }

  @override
  String buildingDetailsYieldProduction(String value) {
    return '$value produkcji';
  }

  @override
  String buildingDetailsYieldGold(String value) {
    return '$value złota';
  }

  @override
  String buildingDetailsYieldDefense(String value) {
    return '$value obrony';
  }

  @override
  String buildingDetailsYieldScience(String value) {
    return '$value nauki';
  }

  @override
  String get buildingDetailsNoYieldChange => 'Brak zmiany zasobów';

  @override
  String get unitDetailsTooltip => 'Szczegóły jednostki';

  @override
  String get unitDetailsMovement => 'Ruch';

  @override
  String get unitDetailsCombat => 'Walka';

  @override
  String unitDetailsMovementPerTurn(int movement) {
    return '$movement pola/turę';
  }

  @override
  String get unitDetailsPace => 'Tempo';

  @override
  String unitDetailsRequirementTechnology(String technology) {
    return 'Technologia: $technology';
  }

  @override
  String unitDetailsAttackLine(int value) {
    return 'Atak: $value';
  }

  @override
  String unitDetailsDefenseLine(int value) {
    return 'Obrona: $value';
  }

  @override
  String unitDetailsHpLine(int value) {
    return 'PŻ: $value';
  }

  @override
  String unitDetailsRangeLine(int value) {
    return 'Zasięg: $value';
  }

  @override
  String sciencePerTurn(int science) {
    return '$science nauki/turę';
  }

  @override
  String get activeResearchLabel => 'BADANE';

  @override
  String get requirementTechnology => 'Wymaga technologii';

  @override
  String requirementTechnologyName(String technology) {
    return 'Wymaga: $technology';
  }

  @override
  String requirementResourceAnyOf(String leading, String last) {
    return '$leading lub $last';
  }

  @override
  String requirementResourcesName(String resources) {
    return 'Wymaga: $resources';
  }

  @override
  String technologyBlockedBy(String technology) {
    return 'Blokowane przez: $technology';
  }

  @override
  String get requirementCoastalAccess => 'Wymaga: dostęp do wybrzeża';

  @override
  String get productionCategoryBuilding => 'Budynek';

  @override
  String get productionCategoryUnit => 'Jednostka';

  @override
  String get productionTitle => 'PRODUKCJA';

  @override
  String get productionInProgressLabel => 'W TRAKCIE';

  @override
  String productionPerTurn(int production) {
    return '$production produkcji/turę';
  }

  @override
  String get productionNoProduction => 'brak produkcji';

  @override
  String get productionButtonProduce => 'PRODUKUJ';

  @override
  String get productionButtonLocked => 'NIEDOSTĘPNE';

  @override
  String get productionEmptyState => 'Brak aktualnie dostępnej produkcji.';

  @override
  String get buildingsSection => 'Budynki';

  @override
  String get unitsSection => 'Jednostki';

  @override
  String futureBuildingsSection(int count) {
    return 'Przyszłe budynki ($count)';
  }

  @override
  String get futureBuildingsSubtitle => 'Odblokowywane przez technologie';

  @override
  String workerPanelTitle(String unitName) {
    return 'Robotnik - $unitName';
  }

  @override
  String get commonOpenAction => 'Otwórz';

  @override
  String get commonShowDetailsAction => 'Pokaż szczegóły';

  @override
  String get commonExecuteAction => 'Wykonaj';

  @override
  String colorPickerChangeTooltip(String label) {
    return 'Zmień kolor: $label';
  }

  @override
  String colorPickerColorSelected(String hex) {
    return '#$hex wybrany';
  }

  @override
  String colorPickerSelectColor(String hex) {
    return 'Wybierz #$hex';
  }

  @override
  String get commonDescription => 'Opis';

  @override
  String get commonSummary => 'Podsumowanie';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonTerrain => 'Teren';

  @override
  String get commonResources => 'Zasoby';

  @override
  String get commonImprovements => 'Ulepszenia';

  @override
  String get commonCities => 'Miasta';

  @override
  String get commonBuildings => 'Budynki';

  @override
  String get commonGold => 'Złoto';

  @override
  String get commonScience => 'Nauka';

  @override
  String get commonProduction => 'Produkcja';

  @override
  String get commonResearch => 'Badania';

  @override
  String get commonEmpire => 'Imperium';

  @override
  String get commonTurn => 'Tura';

  @override
  String get commonProjects => 'Projekty';

  @override
  String get commonPopulation => 'Populacja';

  @override
  String get commonTechnologies => 'Technologie';

  @override
  String get commonFields => 'Pola';

  @override
  String get commonMultipliers => 'Mnożniki';

  @override
  String get commonOther => 'Inne';

  @override
  String get commonReady => 'Gotowe';

  @override
  String get commonDone => 'Gotowe';

  @override
  String get commonDefault => 'Domyślne';

  @override
  String get commonAvailable => 'Dostępne';

  @override
  String get commonBlocked => 'Zablokowane';

  @override
  String get commonSelectAction => 'Wybierz';

  @override
  String get commonSelectedAction => 'Wybrana';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDoNotShowAgain => 'Nie pokazuj więcej';

  @override
  String get commonNoneLower => 'brak';

  @override
  String get visualCurrentLabel => 'Teraz';

  @override
  String get visualAfterLabel => 'Po zmianie';

  @override
  String get terrainDetailEmpty => 'Brak informacji o terenie';

  @override
  String get yieldFoodShort => 'ŻYW';

  @override
  String get yieldProductionShort => 'PROD';

  @override
  String get yieldGoldShort => 'ZŁ';

  @override
  String get yieldDefenseShort => 'DEF';

  @override
  String selectionChipBadgeSuffix(String badge) {
    return ' Widoczny licznik: $badge.';
  }

  @override
  String selectionChipDisabledDescription(String badge) {
    return 'Ten skrót informacji nie jest teraz dostępny dla aktualnego zaznaczenia.$badge';
  }

  @override
  String selectionChipOpenDescription(String label, String badge) {
    return 'Otwiera szczegóły „$label” dla aktualnego kontekstu mapy.$badge';
  }

  @override
  String get gameGoalTitle => 'Cel gry';

  @override
  String get globalHudCloseResearch => 'Zamknij badania';

  @override
  String globalHudResearchActive(String technologyName) {
    return 'Badanie: $technologyName';
  }

  @override
  String globalHudResearchActiveWithEta(String technologyName, String eta) {
    return 'Badanie: $technologyName · $eta';
  }

  @override
  String get globalHudChooseResearch => 'Wybierz badanie';

  @override
  String get globalHudCloseEmpire => 'Zamknij imperium';

  @override
  String get globalHudCloseActivityLog => 'Zamknij dziennik aktywności';

  @override
  String get bottomToolbarWaiting => 'Czeka';

  @override
  String get bottomToolbarPlan => 'Plan';

  @override
  String get bottomToolbarMove => 'Ruch';

  @override
  String get bottomToolbarResolvingTurn => 'Rozliczanie tury';

  @override
  String bottomToolbarWaitingFor(String players) {
    return 'Czeka: $players';
  }

  @override
  String turnHintNextUnit(String unit) {
    return 'Następny krok: $unit';
  }

  @override
  String turnHintNextCityProduction(String city) {
    return 'Następny krok: produkcja w $city';
  }

  @override
  String get turnHintChooseResearch => 'Następny krok: wybierz badanie';

  @override
  String get turnHintCheckAction => 'Następny krok: sprawdź akcję';

  @override
  String turnHintObjective(String objective) {
    return 'Cel: $objective';
  }

  @override
  String turnHintObjectiveWithAdvice(String objective, String advice) {
    return 'Cel: $objective · $advice';
  }

  @override
  String get turnHintImproveFieldWithWorker => 'Cel: ulepsz pole robotnikiem';

  @override
  String get turnHintFoundCityWithSettler => 'Cel: załóż miasto osadnikiem';

  @override
  String get turnHintClaimTerritoryWithSettler =>
      'Cel: zajmij teren osadnikiem';

  @override
  String turnHintTrainUnit(String unit) {
    return 'Cel: ustaw jednostkę: $unit';
  }

  @override
  String turnHintProtectLeadUnit(String unit) {
    return 'Cel: zabezpiecz prowadzenie: $unit';
  }

  @override
  String turnHintConstructBuildingInCity(String city) {
    return 'Cel: zleć budynek w $city';
  }

  @override
  String turnHintTrainUnitInCity(String city) {
    return 'Cel: zleć jednostkę w $city';
  }

  @override
  String turnHintPrepareSettlerInCity(String city) {
    return 'Cel: przygotuj osadnika w $city';
  }

  @override
  String turnHintGrowPopulationInCity(String city) {
    return 'Cel: ustaw wzrost w $city';
  }

  @override
  String turnHintPrepareWorkerInCity(String city) {
    return 'Cel: przygotuj robotnika w $city';
  }

  @override
  String turnHintCollectGoldInCity(String city) {
    return 'Cel: domknij złoto w $city';
  }

  @override
  String turnHintProtectLeadProductionInCity(String city) {
    return 'Cel: domknij produkcję w $city';
  }

  @override
  String get turnHintUnlockTechnologyForScore =>
      'Cel: wybierz technologię do punktów';

  @override
  String get turnHintProtectLeadResearch => 'Cel: domknij bezpieczne badanie';

  @override
  String topResourceTurnShortLabel(int turn) {
    return 'T$turn';
  }

  @override
  String topResourceTurnTooltip(int turn) {
    return 'Tura $turn';
  }

  @override
  String topResourceScienceTooltip(String scienceTurnLabel) {
    return 'Nauka: $scienceTurnLabel / turę';
  }

  @override
  String topResourceResourcesTooltip(int resourceTotal, int resourceTypes) {
    return 'Zasoby: $resourceTotal złóż • $resourceTypes typów kontrolowanych';
  }

  @override
  String topResourceGoldTooltip(
    int gold,
    int goldIncome,
    int unitUpkeep,
    String net,
  ) {
    return 'Złoto: $gold • dochód +$goldIncome • utrzymanie -$unitUpkeep • netto $net / turę';
  }

  @override
  String topResourceGoldTooltipNegativeTreasury(String base) {
    return '$base • skarbiec poniżej zera';
  }

  @override
  String topResourceGoldTooltipBankruptcy(String base) {
    return '$base • ryzyko bankructwa w ciągu 3 tur';
  }

  @override
  String get resourceBreakdownTreasury => 'Skarbiec';

  @override
  String get resourceBreakdownCityIncome => 'Dochód miast';

  @override
  String get resourceBreakdownUpkeep => 'Utrzymanie';

  @override
  String get resourceBreakdownNetPerTurn => 'Netto / turę';

  @override
  String get resourceBreakdownNoCityIncome => 'Brak dochodu z miast';

  @override
  String get resourceBreakdownFreeLimit => 'Darmowy limit';

  @override
  String get resourceBreakdownNextWorkerUpkeep =>
      'Utrzymanie następnego robotnika';

  @override
  String resourceBreakdownNextWorkerUpkeepValue(int upkeep) {
    return '-$upkeep złota/turę';
  }

  @override
  String get resourceBreakdownInsideFreeLimit => 'W limicie darmowym';

  @override
  String get resourceBreakdownNoActiveTechnology => 'Brak wybranej technologii';

  @override
  String get resourceBreakdownScienceTitle => 'Nauka i badania';

  @override
  String get resourceBreakdownSciencePerTurn => 'Nauka / turę';

  @override
  String get resourceBreakdownActiveResearch => 'Aktywne badanie';

  @override
  String get resourceBreakdownTurnsToComplete => 'Do ukończenia';

  @override
  String get resourceBreakdownNoScienceSources => 'Brak źródeł nauki';

  @override
  String resourceBreakdownCityResearchProject(String cityName) {
    return '$cityName: Badania';
  }

  @override
  String get resourceBreakdownNoControlledResources =>
      'Brak kontrolowanych zasobów';

  @override
  String get resourceBreakdownGrowCitiesWithFood => 'Rozwijaj miasta żywnością';

  @override
  String get resourceBreakdownControlledDeposits => 'Kontrolowane złoża';

  @override
  String get resourceBreakdownResourceTypes => 'Typy zasobów';

  @override
  String get resourceBreakdownTypesSection => 'Typy';

  @override
  String get resourceBreakdownSourcesSection => 'Źródła';

  @override
  String get technologyRecommendationsTitle => 'Rekomendowane badania';

  @override
  String get technologyShowTreeAction => 'Pokaż drzewo';

  @override
  String technologyShowTreeCountAction(int count) {
    return 'Pokaż drzewo ($count)';
  }

  @override
  String get technologyRecommendationUnlocks => 'Odblokuje';

  @override
  String get technologyRecommendationReasonBoost =>
      'Aktywny boost skraca koszt badania.';

  @override
  String get technologyRecommendationReasonSection => 'Warto teraz';

  @override
  String get technologyRecommendationReasonImprovements =>
      'Nowe ulepszenia pól szybko zmieniają zasoby w yield.';

  @override
  String get technologyRecommendationReasonBuilding =>
      'Nowy budynek miasta otwiera kolejny kierunek rozwoju.';

  @override
  String get technologyRecommendationReasonUnit =>
      'Nowa jednostka wzmacnia bezpieczeństwo i kontrolę mapy.';

  @override
  String get technologyRecommendationReasonEffect =>
      'Stały bonus działa na całą gospodarkę.';

  @override
  String get technologyRecommendationReasonFast =>
      'Szybkie badanie bez dodatkowych wymagań.';

  @override
  String get technologyRecommendationReasonDefault =>
      'Dostępne badanie, które dobrze domyka następny krok.';

  @override
  String get technologyNoRecommendations => 'Brak dostępnych nowych badań.';

  @override
  String get technologyFullTreeTitle => 'Pełne drzewo technologii';

  @override
  String get technologyRecommendationsBackAction => 'Rekomendacje';

  @override
  String get empireUnitsEmptyTitle => 'Brak jednostek';

  @override
  String get empireUnitsEmptyBody =>
      'Nowe jednostki pojawią się tutaj po produkcji w mieście albo rekrutacji z wydarzeń.';

  @override
  String get empireCitiesEmptyTitle => 'Brak miast';

  @override
  String get empireCitiesEmptyBody =>
      'Załóż pierwsze miasto osadnikiem, aby odblokować produkcję, naukę i granice imperium.';

  @override
  String get empireCityCenters => 'Centra miast';

  @override
  String get empireShowFirstUnitTooltip => 'Pokaż pierwszą jednostkę na mapie';

  @override
  String get empireShowUnitTooltip => 'Pokaż jednostkę na mapie';

  @override
  String get empireShowFirstCityTooltip => 'Pokaż pierwsze miasto na mapie';

  @override
  String get empireShowCityTooltip => 'Pokaż miasto na mapie';

  @override
  String empireUnitCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jednostek',
      few: '$count jednostki',
      one: '1 jednostka',
    );
    return '$_temp0';
  }

  @override
  String empireCityCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miast',
      few: '$count miasta',
      one: '1 miasto',
    );
    return '$_temp0';
  }

  @override
  String empireUnitMovement(int movement) {
    return 'Ruch $movement';
  }

  @override
  String get empireUnitBuilding => 'Buduje';

  @override
  String get empireUnitWorking => 'Pracuje';

  @override
  String get empireUnitFortifying => 'Fortyfikuje się';

  @override
  String get empireUnitHealing => 'Leczy się';

  @override
  String get empireUnitEnRoute => 'W drodze';

  @override
  String get empireUnitNoMovement => 'bez ruchu';

  @override
  String empireUnitsWithMovement(int count) {
    return '$count z ruchem';
  }

  @override
  String empireCitySubtitle(
    int population,
    int hexes,
    int buildings,
    String production,
  ) {
    return 'Populacja $population - $hexes pól - $buildings bud. - produkuje: $production';
  }

  @override
  String empireCityStoredArtifact(String artifactName) {
    return 'Artefakt: $artifactName';
  }

  @override
  String empireCityGroupSubtitle(String cityLabel, int population) {
    return '$cityLabel - populacja $population';
  }

  @override
  String get empireStatsTitle => 'Stan imperium';

  @override
  String get empireStatsSubtitle =>
      'Szybki obraz gotowości, składu i rozwoju miast';

  @override
  String get empireStatsReadinessTitle => 'Gotowość jednostek';

  @override
  String get empireStatsUnitCompositionTitle => 'Skład jednostek';

  @override
  String get empireStatsCityDevelopmentTitle => 'Rozwój miast';

  @override
  String get empireStatsCityComparisonTitle => 'Porównanie miast';

  @override
  String get empireStatsOrders => 'Z rozkazami';

  @override
  String get empireStatsNoMovement => 'Bez ruchu';

  @override
  String get empireStatsAveragePopulation => 'Śr. pop.';

  @override
  String get empireStatsTotalBuildings => 'Budynki';

  @override
  String get empireStatsStoredArtifacts => 'Artefakty';

  @override
  String get empireStatsTerritory => 'Terytorium';

  @override
  String get empireStatsCitiesProducing => 'Produkcja';

  @override
  String get empireStatsOther => 'Inne';

  @override
  String get empireStatsEmptyUnits => 'Brak jednostek do analizy';

  @override
  String get empireStatsEmptyCities => 'Brak miast do analizy';

  @override
  String empireStatsCityBarDetail(int population, int buildings) {
    return 'Pop. $population • bud. $buildings';
  }

  @override
  String empireStatsCityComparisonDetail(
    int population,
    int production,
    int food,
    int gold,
  ) {
    return 'Pop. $population • Prod. $production • Żyw. $food • Złoto $gold';
  }

  @override
  String get empireStatsMetricPopulation => 'Pop.';

  @override
  String get empireStatsMetricProduction => 'Prod.';

  @override
  String get empireStatsMetricFood => 'Żyw.';

  @override
  String get empireStatsMetricGold => 'Złoto';

  @override
  String get activityLogTitle => 'Dziennik aktywności';

  @override
  String get activityLogShowAllAction => 'Pokaż wszystko';

  @override
  String activityLogShowMoreAction(int visible, int total) {
    return 'Pokaż więcej ($visible/$total)';
  }

  @override
  String get activityLogLoadingHistory => 'Wczytywanie pełnej historii...';

  @override
  String get activityLogHistoryErrorTitle => 'Nie można wczytać historii';

  @override
  String activityLogHistoryErrorBody(String error) {
    return 'Dziennik zdarzeń jest niedostępny: $error';
  }

  @override
  String get activityLogFilterAll => 'Wszystko';

  @override
  String get activityLogFilterAllShort => 'Wszyst.';

  @override
  String get activityLogFilterCombat => 'Walka';

  @override
  String get activityLogFilterCities => 'Miasta';

  @override
  String get activityLogFilterDiplomacy => 'Dyplomacja';

  @override
  String get activityLogFilterDiplomacyShort => 'Dypl.';

  @override
  String get activityLogFilterTechnology => 'Nauka';

  @override
  String get activityLogEmptyAllTitle => 'Brak zapisanych zdarzeń';

  @override
  String get activityLogEmptyCombatTitle => 'Brak zapisanych walk';

  @override
  String get activityLogEmptyCityTitle => 'Brak zapisanych zdarzeń miast';

  @override
  String get activityLogEmptyDiplomacyTitle => 'Brak zapisanej dyplomacji';

  @override
  String get activityLogEmptyTechnologyTitle => 'Brak zapisanych odkryć';

  @override
  String get activityLogEmptyAllBody =>
      'Pierwsze odkrycia, walki i budowy pojawią się tutaj po rozegraniu akcji.';

  @override
  String get activityLogEmptyCombatBody =>
      'Starcia zostaną zapisane po ataku lub obronie widocznej dla gracza.';

  @override
  String get activityLogEmptyCityBody =>
      'Założone miasta, budowy i przejęcia pól utworzą tutaj linię czasu imperium.';

  @override
  String get activityLogEmptyDiplomacyBody =>
      'Depesze, propozycje, odpowiedzi i zmiany relacji pojawią się tutaj po działaniach dyplomatycznych.';

  @override
  String get activityLogEmptyTechnologyBody =>
      'Odkryte technologie trafią tu po zakończeniu badań.';

  @override
  String get turnTimelineTitle => 'Przebieg tur';

  @override
  String turnTimelineSubtitle(int turn, int count) {
    return 'Tura $turn • zdarzeń: $count';
  }

  @override
  String get turnTimelineChartTitle => 'Zdarzenia na przestrzeni tur';

  @override
  String get turnTimelineMetricEvents => 'Zdarzenia';

  @override
  String get turnTimelineMetricActiveTurns => 'Aktywne tury';

  @override
  String get turnTimelineMetricCurrentTurn => 'Bieżąca tura';

  @override
  String get technologyDiscoveryEyebrow => 'Odkryto technologię';

  @override
  String unitSelectionMovementSubtitle(int current, int max) {
    return 'Ruch $current/$max';
  }

  @override
  String unitSelectionMovementHpSubtitle(
    int current,
    int max,
    int hp,
    int maxHp,
  ) {
    return 'Ruch $current/$max • HP $hp/$maxHp';
  }

  @override
  String get unitSelectionAttackLabel => 'Atak';

  @override
  String get unitSelectionDefenseLabel => 'Obrona';

  @override
  String get unitSelectionHpLabel => 'HP';

  @override
  String get unitSelectionRangeLabel => 'Zasięg';

  @override
  String get unitSelectionConstructionLabel => 'Budowa';

  @override
  String get unitSelectionWorkLabel => 'Praca';

  @override
  String get unitSelectionFieldBonusValue => 'Bonus z pola';

  @override
  String get tileSelectionYieldTitle => 'Potencjał pola';

  @override
  String get tileSelectionYieldTooltip =>
      'Ocena inspekcyjna pola, nie realny yield miasta.';

  @override
  String get tileSelectionBonusLabel => 'Bonus';

  @override
  String get tileSelectionDefenseBonusValue => '+obrona';

  @override
  String get tileSelectionRiverBonusValue => '+rzeka';

  @override
  String get citySelectionYieldTitle => 'Przychód miasta';

  @override
  String get citySelectionYieldTooltip =>
      'Realny yield miasta na turę z ekonomii miasta.';

  @override
  String citySelectionSubtitle(
    int population,
    int territoryHexCount,
    int maxHexes,
    String production,
  ) {
    return 'Populacja $population • $territoryHexCount/$maxHexes pól • Produkcja: $production';
  }

  @override
  String get citySelectionTerritoryLabel => 'Terytorium';

  @override
  String get citySelectionFoodLabel => 'Żywność';

  @override
  String get citySelectionNetFoodLabel => 'Net food';

  @override
  String get citySelectionBuildingsLabel => 'Budynki';

  @override
  String get citySelectionArtifactLabel => 'Artefakt';

  @override
  String get worldArtifactBonusTitle => 'Bonus';

  @override
  String get worldArtifactHeritageTitle => 'Dziedzictwo';

  @override
  String get worldArtifactHeritageBody =>
      'Zbierz i umieść 6 unikalnych artefaktów w swoich miastach, a potem utrzymaj kolekcję przez 5 tur.';

  @override
  String get worldArtifactAncientImperialCrown => 'Korona Dawnego Imperium';

  @override
  String get worldArtifactAstronomersTablets => 'Tablice Astronomów';

  @override
  String get worldArtifactProphetMask => 'Maska Proroka';

  @override
  String get worldArtifactHeroSword => 'Miecz Bohatera';

  @override
  String get worldArtifactMerchantsSeal => 'Pieczęć Kupców';

  @override
  String get worldArtifactFirstPeoplesChronicle => 'Kronika Pierwszych Ludów';

  @override
  String get worldArtifactTempleReliquary => 'Relikwiarz Świątynny';

  @override
  String get worldArtifactQueensMirror => 'Zwierciadło Królowej';

  @override
  String get worldArtifactAncientImperialCrownShortBonus => '+1 obrona';

  @override
  String get worldArtifactAstronomersTabletsShortBonus => '+1 nauka';

  @override
  String get worldArtifactProphetMaskShortBonus => '+1 złoto, dyplomacja';

  @override
  String get worldArtifactHeroSwordShortBonus =>
      '+2 PD dla produkowanych jednostek';

  @override
  String get worldArtifactMerchantsSealShortBonus => '+2 złoto';

  @override
  String get worldArtifactFirstPeoplesChronicleShortBonus => '+1 żywność';

  @override
  String get worldArtifactTempleReliquaryShortBonus => '+1 żywność, +1 obrona';

  @override
  String get worldArtifactQueensMirrorShortBonus => '+1 złoto, dyplomacja';

  @override
  String get worldArtifactAncientImperialCrownDescription =>
      'Symbol dawnego panowania. Po złożeniu w mieście wzmacnia obronę i prestiż kolekcji.';

  @override
  String get worldArtifactAstronomersTabletsDescription =>
      'Kamienne tablice z dawnymi mapami nieba. W mieście wspierają naukę.';

  @override
  String get worldArtifactProphetMaskDescription =>
      'Rytualna maska o wielkiej wadze politycznej. W mieście daje złoto i wartość dyplomatyczną.';

  @override
  String get worldArtifactHeroSwordDescription =>
      'Broń legendarnego wodza. Jednostki tworzone w mieście zyskują dodatkowe doświadczenie.';

  @override
  String get worldArtifactMerchantsSealDescription =>
      'Znak pierwszych gildii kupieckich. W mieście wzmacnia dochód ze złota.';

  @override
  String get worldArtifactFirstPeoplesChronicleDescription =>
      'Zapis najstarszych rodów i granic. W mieście wspiera wzrost.';

  @override
  String get worldArtifactTempleReliquaryDescription =>
      'Święty relikwiarz dający miastu stabilność, żywność i obronę.';

  @override
  String get worldArtifactQueensMirrorDescription =>
      'Dworski skarb łączący handel z dyplomacją. W mieście daje złoto i prestiż.';

  @override
  String get worldArtifactLocationMap => 'Artefakt na mapie';

  @override
  String get worldArtifactLocationExcavation => 'Wykopaliska w toku';

  @override
  String get worldArtifactLocationCarried => 'Przenoszony przez jednostkę';

  @override
  String get worldArtifactLocationStored => 'Złożony w mieście';

  @override
  String get worldArtifactStepExcavate => 'Wykop';

  @override
  String get worldArtifactStepMove => 'Przenieś';

  @override
  String get worldArtifactStepStore => 'Złóż';

  @override
  String get artifactGuidanceUnknownCityName => 'miasto';

  @override
  String get artifactGuidanceStoredTitle => 'Artefakt w mieście';

  @override
  String artifactGuidanceStoredBody(String artifactName, String cityName) {
    return '$artifactName wzmacnia $cityName. Do zwycięstwa kulturowego potrzeba 6 artefaktów w miastach przez 5 tur.';
  }

  @override
  String get artifactGuidanceCarriedTitle => 'Artefakt przenoszony';

  @override
  String artifactGuidanceCarriedBody(String artifactName) {
    return 'Jednostka niesie $artifactName. Odprowadź ją do własnego miasta z wolnym slotem i użyj akcji złożenia.';
  }

  @override
  String get artifactGuidanceReachedTitle => 'Artefakt odkryty';

  @override
  String artifactGuidanceReachedBody(String artifactName) {
    return '$artifactName jest pod jednostką. Użyj akcji Wykopaliska, aby go podnieść.';
  }

  @override
  String get citySelectionSpecializationLabel => 'Specjalizacja';

  @override
  String get fieldImprovementOutsideActiveCity => 'Poza aktywnym miastem';

  @override
  String get fieldImprovementYieldTitle => 'Premia ulepszenia';

  @override
  String get fieldImprovementYieldTooltip =>
      'Dodatkowy yield z ulepszenia pola.';

  @override
  String get hexKindIdealCitySite => 'Idealne pod miasto';

  @override
  String get hexKindGoodCitySite => 'Dobre pod miasto';

  @override
  String get hexKindFertileField => 'Żyzne pole';

  @override
  String get hexKindFertilePlains => 'Żyzna równina';

  @override
  String get hexKindRichPlain => 'Bogata równina';

  @override
  String get hexKindStrategicBorderland => 'Strategiczne pogranicze';

  @override
  String get hexKindStrategicField => 'Pole strategiczne';

  @override
  String get hexKindDefensivePosition => 'Pozycja obronna';

  @override
  String get hexKindFertileForest => 'Żyzny las';

  @override
  String get hexKindForestBackline => 'Leśne zaplecze';

  @override
  String get hexKindForestForge => 'Leśna kuźnia';

  @override
  String get hexKindWildLand => 'Dziki teren';

  @override
  String get hexKindRichWilds => 'Bogata dzicz';

  @override
  String get hexKindExoticBackline => 'Egzotyczne zaplecze';

  @override
  String get hexKindDifficultStrategicTerrain => 'Trudny teren strategiczny';

  @override
  String get hexKindHighGround => 'Wysoka pozycja';

  @override
  String get hexKindRiverHills => 'Wzgórza nad rzeką';

  @override
  String get hexKindIndustrialStronghold => 'Twierdza przemysłowa';

  @override
  String get hexKindRichHills => 'Bogate wzgórza';

  @override
  String get hexKindBarrenLand => 'Jałowy teren';

  @override
  String get hexKindOasis => 'Oaza';

  @override
  String get hexKindTradeOasis => 'Oaza handlowa';

  @override
  String get hexKindDesertDeposits => 'Pustynne złoża';

  @override
  String get hexKindHarshLand => 'Surowy teren';

  @override
  String get hexKindColdPastures => 'Zimne pastwiska';

  @override
  String get hexKindResourceOutpost => 'Surowcowa placówka';

  @override
  String get hexKindHostileLand => 'Nieprzyjazny teren';

  @override
  String get hexKindArcticDeposits => 'Arktyczne złoża';

  @override
  String get hexKindCoast => 'Wybrzeże';

  @override
  String get hexKindFishingCoast => 'Rybackie wybrzeże';

  @override
  String get hexKindRichCoast => 'Bogate wybrzeże';

  @override
  String get hexKindRiverPort => 'Portowe ujście';

  @override
  String get hexKindRegionalPortHeart => 'Portowe serce regionu';

  @override
  String get hexKindOpenSea => 'Otwarte morze';

  @override
  String get hexKindNaturalBarrier => 'Naturalna bariera';

  @override
  String get hexKindPromisingLand => 'Obiecujący teren';

  @override
  String get hexKindWeakLand => 'Słaby teren';

  @override
  String get hexKindOrdinaryLand => 'Zwykły teren';

  @override
  String get hexKindMapTile => 'Pole mapy';

  @override
  String get hexKindIdealCitySiteDescription =>
      'Bardzo mocne miejsce pod osadę: żywność, wzrost i przestrzeń rozwoju są już w jednym pakiecie.';

  @override
  String get hexKindGoodCitySiteDescription =>
      'Solidny teren pod centrum miasta, z dość dobrą bazą pod wczesny rozwój.';

  @override
  String get hexKindFertileFieldDescription =>
      'Trawiaste pole nad rzeką, dobre pod żywność, populację i pracę robotnika.';

  @override
  String get hexKindFertilePlainsDescription =>
      'Otwarte równiny z rzeką, przydatne do zbalansowania żywności i produkcji.';

  @override
  String get hexKindRichPlainDescription =>
      'Wartościowe otwarte pole z luksusem albo handlem, warte objęcia granicami.';

  @override
  String get hexKindStrategicBorderlandDescription =>
      'Dobry teren o znaczeniu strategicznym, przydatny zanim zajmie go rywal.';

  @override
  String get hexKindStrategicFieldDescription =>
      'Równinne pole powiązane z zasobem strategicznym lub presją na granicy.';

  @override
  String get hexKindDefensivePositionDescription =>
      'Teren wzmacniający kontrolę obronną i utrzymanie pobliskich podejść.';

  @override
  String get hexKindFertileForestDescription =>
      'Las z dostępem do rzeki, łączący potencjał wzrostu z naturalną osłoną.';

  @override
  String get hexKindForestBacklineDescription =>
      'Bezpieczniejszy leśny heks, dobry pod zaplecze lub ulepszenia łowieckie.';

  @override
  String get hexKindForestForgeDescription =>
      'Las z zasobem przemysłowym, obiecujący pod produkcję po ulepszeniu.';

  @override
  String get hexKindWildLandDescription =>
      'Gęsty i trudniejszy teren; opłaca się dopiero z jasnym planem robotnika lub ekspansji.';

  @override
  String get hexKindRichWildsDescription =>
      'Dziki teren z dość dobrą żyznością albo zasobami, wart ostrożnego rozwoju.';

  @override
  String get hexKindExoticBacklineDescription =>
      'Dżungla lub mokradła z wartością luksusową dla późniejszych granic i handlu.';

  @override
  String get hexKindDifficultStrategicTerrainDescription =>
      'Trudny teren z zasobem strategicznym; mocny później, niewygodny na starcie.';

  @override
  String get hexKindHighGroundDescription =>
      'Wzgórza lepsze do obrony i kontroli mapy niż do szybkiego wzrostu.';

  @override
  String get hexKindRiverHillsDescription =>
      'Wzgórza nad rzeką, łączące obronę z lepszym potencjałem ekonomicznym.';

  @override
  String get hexKindIndustrialStrongholdDescription =>
      'Wzgórza z zasobami przemysłowymi, mocny cel produkcyjny dla miasta.';

  @override
  String get hexKindRichHillsDescription =>
      'Bogate wzgórza przydatne pod złoto albo ekspansję nastawioną na produkcję.';

  @override
  String get hexKindBarrenLandDescription =>
      'Suchy teren o małej wartości natychmiastowej, chyba że plan zmienią technologie lub granice.';

  @override
  String get hexKindOasisDescription =>
      'Pustynia złagodzona rzeką, zmieniająca słabe pole w użyteczny heks wzrostu.';

  @override
  String get hexKindTradeOasisDescription =>
      'Pustynna kieszeń handlowa, która może zyskać wartość po właściwym ulepszeniu.';

  @override
  String get hexKindDesertDepositsDescription =>
      'Słaby teren osadniczy ze złożem strategicznym ważniejszym w późniejszych erach.';

  @override
  String get hexKindHarshLandDescription =>
      'Zimny albo surowy teren z ograniczoną ekonomią i wolnym rozwojem na starcie.';

  @override
  String get hexKindColdPasturesDescription =>
      'Zimny teren z pastwiskową wartością wystarczającą dla miasta granicznego.';

  @override
  String get hexKindResourceOutpostDescription =>
      'Odległy zimny teren wart zajęcia głównie przez chroniony zasób.';

  @override
  String get hexKindHostileLandDescription =>
      'Nieprzyjazny teren o słabej wartości osadniczej i małym zwrocie na starcie.';

  @override
  String get hexKindArcticDepositsDescription =>
      'Śnieżne złoża trudne w użyciu, ale ważne strategicznie.';

  @override
  String get hexKindCoastDescription =>
      'Wybrzeże otwierające dostęp morski i elastyczny rozwój miasta.';

  @override
  String get hexKindFishingCoastDescription =>
      'Wybrzeże z żywnością, dobry powód do pracy pola albo osady przy wodzie.';

  @override
  String get hexKindRichCoastDescription =>
      'Wybrzeże z luksusem lub handlem, warte włączenia do granic miasta.';

  @override
  String get hexKindRiverPortDescription =>
      'Ujście rzeki z wartością handlową i ruchową dla miasta nad wodą.';

  @override
  String get hexKindRegionalPortHeartDescription =>
      'Mocne centrum portowe, gdzie rzeka i zasoby nakładają się na siebie.';

  @override
  String get hexKindOpenSeaDescription =>
      'Woda przydatna dla statków i zwiadu, ale nie dla osadnictwa lądowego.';

  @override
  String get hexKindNaturalBarrierDescription =>
      'Blokujący teren, który kształtuje ruch i obronę bardziej niż ekonomię.';

  @override
  String get hexKindPromisingLandDescription =>
      'Ogólnie użyteczne pole z wartością, którą warto sprawdzić przed ruchem dalej.';

  @override
  String get hexKindWeakLandDescription =>
      'Nisko opłacalny teren, który rzadko zasługuje na wczesny czas robotnika.';

  @override
  String get hexKindOrdinaryLandDescription =>
      'Zwykłe pole bez wyraźnej przewagi, użyteczne gdy pasuje do planu miasta.';

  @override
  String get hexKindMapTileDescription =>
      'Zwykłe pole mapy bez dość mocnych danych do jednoznacznej oceny.';

  @override
  String get hexTagCity => 'Pod miasto';

  @override
  String get hexTagDefense => 'Pozycja obronna';

  @override
  String get hexTagTrade => 'Szlak handlowy';

  @override
  String get hexTagFertile => 'Żyzne pole';

  @override
  String get hexTagProduction => 'Dobra produkcja';

  @override
  String get hexTagHostile => 'Nieprzyjazny teren';

  @override
  String get hexTagStrategic => 'Zasób strategiczny';

  @override
  String get hexTagWater => 'Wodne przejście';

  @override
  String get hexRecommendationFoundCity => 'Dobra lokacja pod rozwój';

  @override
  String get hexRecommendationDefendHere => 'Dobra pozycja obronna';

  @override
  String get hexRecommendationExploitEconomy => 'Warto eksploatować';

  @override
  String get hexRecommendationAvoid => 'Lepiej ominąć bez planu';

  @override
  String get hexRecommendationNeutral => 'Sprawdź przed ruchem';

  @override
  String get hexRecommendationFoundCityDetail =>
      'Jeśli granice są wolne, rozważ założenie miasta albo skierowanie tu osadnika.';

  @override
  String get hexRecommendationDefendHereDetail =>
      'Użyj jako punktu oparcia dla jednostek, granic lub obrony pobliskiego miasta.';

  @override
  String get hexRecommendationExploitEconomyDetail =>
      'Warto objąć granicami i wysłać robotnika, gdy miasto może skorzystać z yieldu.';

  @override
  String get hexRecommendationAvoidDetail =>
      'Na początku pomiń, chyba że zasób, trasa albo potrzeba militarna zmienia ocenę.';

  @override
  String get hexRecommendationNeutralDetail =>
      'Odkryj sąsiednie pola i porównaj zasoby, zanim poświęcisz ruch lub robotnika.';

  @override
  String get selectionActionLockedReason =>
      'Nie możesz teraz wydawać rozkazów.';

  @override
  String get selectionActionFoundCity => 'Załóż miasto';

  @override
  String get selectionActionCancel => 'Anuluj';

  @override
  String get selectionActionCancelAttack => 'Przerwij atak';

  @override
  String get selectionActionCancelWorkerBuild => 'Przerwij budowę ulepszenia';

  @override
  String get selectionActionCancelCityFounding => 'Przerwij zakładanie miasta';

  @override
  String get selectionActionCancelAutoExplore => 'Przerwij eksplorację';

  @override
  String get selectionActionCancelArtifactExcavation =>
      'Przerwij wykopywanie artefaktu';

  @override
  String get selectionActionCancelTradeRouteSelection =>
      'Przerwij wybór trasy handlowej';

  @override
  String get selectionActionCancelMerchantMoveToCity =>
      'Przerwij przejście do miasta';

  @override
  String get selectionActionCancelCommanderMerge =>
      'Przerwij dołączanie oddziałów';

  @override
  String get selectionActionConfirm => 'Potwierdź';

  @override
  String selectionActionConfirmWithTurns(String turns) {
    return 'Potwierdź ($turns)';
  }

  @override
  String get selectionActionMinimize => 'Minimalizuj';

  @override
  String get selectionActionConfirmAttack => 'Potwierdź atak';

  @override
  String get selectionActionCaptureCity => 'Przejmij miasto';

  @override
  String get selectionActionDestroyCity => 'Zniszcz miasto';

  @override
  String get selectionActionStopFortifying => 'Przerwij fortyfikację';

  @override
  String get selectionActionStopHealing => 'Przerwij leczenie';

  @override
  String get selectionActionMove => 'Przesuń';

  @override
  String get selectionActionAttack => 'Atak';

  @override
  String get selectionActionAutoExplore => 'Eksploruj';

  @override
  String get selectionActionTradeRoute => 'Trasa handlowa';

  @override
  String selectionActionTradeRouteToCity(String cityName) {
    return 'Handluj z $cityName';
  }

  @override
  String get selectionActionMerchantMoveToCity => 'Przejdź do miasta';

  @override
  String selectionActionMerchantMoveToCityTarget(String cityName) {
    return 'Przejdź do $cityName';
  }

  @override
  String get selectionActionArmy => 'Armia';

  @override
  String get selectionArmyEmpty => 'Brak oddziałów';

  @override
  String selectionTroopDetachTooltip(String troop) {
    return 'Odłącz $troop';
  }

  @override
  String get selectionActionImprove => 'Ulepsz';

  @override
  String get selectionActionSkip => 'Pomiń';

  @override
  String get selectionActionFortify => 'Fortyfikuj';

  @override
  String get selectionActionHeal => 'Lecz';

  @override
  String get selectionActionCancelCityGrowth => 'Anuluj rozwój';

  @override
  String get selectionActionCityGrowth => 'Rozwój miasta';

  @override
  String get selectionActionProduction => 'Produkcja';

  @override
  String get selectionActionExcavateArtifact => 'Wykop';

  @override
  String get selectionActionStoreArtifact => 'Złóż';

  @override
  String get selectionActionCancelCurrentMoveFirst =>
      'Najpierw anuluj obecny ruch.';

  @override
  String get selectionActionArtifactAlreadyCarried =>
      'Jednostka niesie już artefakt.';

  @override
  String get selectionActionStoreArtifactOwnCityRequired =>
      'Przejdź do jednego ze swoich miast.';

  @override
  String get selectionActionStoreArtifactCityOccupied =>
      'To miasto przechowuje już artefakt.';

  @override
  String get selectionActionNoBuildAvailable =>
      'Brak dostępnej budowy na tym polu.';

  @override
  String get selectionActionUnitWorking => 'Jednostka wykonuje już zadanie.';

  @override
  String get selectionActionUnitFortified => 'Jednostka jest ufortyfikowana.';

  @override
  String get selectionActionUnitHealing => 'Jednostka się leczy.';

  @override
  String get selectionActionNoMovement => 'Brak punktów ruchu w tej turze.';

  @override
  String get selectionActionNoAttack => 'Ta jednostka nie ma ataku.';

  @override
  String get selectionActionNoVisibleEnemy =>
      'Brak widocznego wroga w zasięgu.';

  @override
  String get selectionActionMerchantNoOriginCity =>
      'Przesuń kupca do jednego ze swoich miast.';

  @override
  String get selectionActionMerchantNoDestinationCity =>
      'Potrzebujesz drugiego połączonego miasta.';

  @override
  String get selectionActionMerchantNoRoute =>
      'Nie da się wyznaczyć trasy handlowej do tego miasta.';

  @override
  String get selectionActionMerchantNoCityPath =>
      'Nie da się dojść kupcem do tego miasta.';

  @override
  String get selectionActionCannotFoundCityHere =>
      'Nie można tu założyć miasta.';

  @override
  String get selectionActionFoundCityNoCommander =>
      'Tylko osadnik albo dowódca z osadnikami może założyć miasto.';

  @override
  String get selectionActionFoundCityNoSettlers =>
      'Do założenia miasta potrzebni są osadnicy.';

  @override
  String get selectionActionFoundCityInvalidCenter =>
      'Na tym polu nie można założyć miasta.';

  @override
  String get selectionActionFoundCityCityAlreadyExists =>
      'Na tym polu jest już miasto.';

  @override
  String get selectionActionFoundCityCenterOccupied =>
      'To pole należy już do miasta.';

  @override
  String get selectionActionFoundCityTooCloseToCity =>
      'Miasto nie może sąsiadować z innym miastem.';

  @override
  String get selectionActionFoundCityInvalidControlledHexes =>
      'Najpierw wybierz poprawne pola miasta.';

  @override
  String get selectionActionCannotImproveCityCenter =>
      'Na centrum miasta nie budujemy ulepszeń.';

  @override
  String get selectionActionTileAlreadyImproved =>
      'Na tym polu jest już ulepszenie.';

  @override
  String get selectionActionTileMustBelongToCity =>
      'Pole musi należeć do miasta.';

  @override
  String get selectionActionNoWorkerTile => 'Brak pola pod robotnikiem.';

  @override
  String get hudFeedbackNoTurnCostDetail => 'Akcja nie zużyła tury';

  @override
  String get hudFeedbackAutoExploreNoTargetTitle => 'Brak trasy eksploracji';

  @override
  String get hudFeedbackAutoExploreNoTargetBody =>
      'Scout nie ma ruchu, który odkryje nowe pola w tej turze.';

  @override
  String get hudFeedbackArtifactGuidanceTitle => 'Artefakt świata';

  @override
  String get hudFeedbackArtifactGuidanceBody =>
      'Dostarcz go do własnego miasta i złóż w pustym slocie artefaktu.';

  @override
  String get hudFeedbackActionBlockedTitle => 'Akcja niedostępna';

  @override
  String get hudFeedbackActionBlockedBody =>
      'Ta akcja jest teraz zablokowana. Wybierz inne pole albo inną komendę.';

  @override
  String get hudFeedbackAttackProtectedByTreatyTitle => 'Traktat blokuje atak';

  @override
  String get hudFeedbackAttackProtectedByTreatyBody =>
      'Nie możesz zaatakować jednostki cywilizacji, z którą masz sojusz albo rozejm. Najpierw zmień relacje dyplomatyczne.';

  @override
  String get hudFeedbackMovementCityOccupiedTitle => 'Miasto zajęte';

  @override
  String get hudFeedbackMovementCityOccupiedBody =>
      'W mieście może stać tylko jedna jednostka. Najpierw wyprowadź garnizon albo wybierz inne pole.';

  @override
  String get hudFeedbackMovementEnemyOccupiedTitle => 'Pole zajęte przez wroga';

  @override
  String get hudFeedbackMovementEnemyOccupiedBody =>
      'Nie można wejść na wroga zwykłym ruchem. Włącz atak albo wybierz sąsiednie pole.';

  @override
  String get hudFeedbackMovementForeignCityTitle => 'Obce miasto';

  @override
  String get hudFeedbackMovementForeignCityBody =>
      'Nie można wejść do obcego miasta zwykłym ruchem. Użyj ataku albo wybierz inne pole.';

  @override
  String get hudFeedbackMovementHiddenRouteTooFarTitle => 'Trasa za daleko';

  @override
  String get hudFeedbackMovementHiddenRouteTooFarBody =>
      'Nie można wyznaczyć tak dalekiej trasy przez nieodkryty teren. Wyznacz krótszy odcinek albo użyj autoeksploracji zwiadowcy.';

  @override
  String get hudFeedbackMovementBlockedTerrainTitle => 'Teren blokuje ruch';

  @override
  String get hudFeedbackMovementBlockedTerrainBody =>
      'Ta jednostka nie może wejść na ten typ terenu. Wybierz inne pole lub obejście.';

  @override
  String get hudFeedbackMovementInsufficientUnitMovementTitle =>
      'Za mało ruchu';

  @override
  String get hudFeedbackMovementInsufficientUnitMovementBody =>
      'Ta jednostka ma za mało punktów ruchu, aby wejść na ten obszar. Awansuj jednostkę albo użyj innej.';

  @override
  String get hudFeedbackMovementNoRouteTitle => 'Brak trasy';

  @override
  String get hudFeedbackMovementNoRouteBody =>
      'Nie ma dostępnej trasy do tego pola. Spróbuj wybrać bliższy cel albo inne podejście.';

  @override
  String selectionCommandUnavailableDescription(String label) {
    return 'Akcja „$label” jest teraz niedostępna dla aktualnego zaznaczenia.';
  }

  @override
  String selectionCommandActiveDescription(String label) {
    return 'Akcja „$label” jest aktywnym trybem. Wybierz cel na mapie albo anuluj tryb, jeśli zmieniasz decyzję.';
  }

  @override
  String selectionCommandProminentDescription(String label) {
    return 'Akcja „$label” jest obecnie najważniejszą komendą dla tego zaznaczenia.';
  }

  @override
  String selectionCommandDefaultDescription(String label) {
    return 'Wykonuje akcję „$label” dla aktualnie zaznaczonej jednostki, miasta albo pola.';
  }

  @override
  String get selectionInfoChipDisabledDescription =>
      'Ten panel informacji nie jest teraz dostępny dla aktualnego zaznaczenia.';

  @override
  String selectionInfoChipOpenDescription(String label) {
    return 'Otwiera szczegóły „$label” dla aktualnie zaznaczonego pola, jednostki albo miasta.';
  }

  @override
  String turnCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tur',
      few: '$count tury',
      one: '1 tura',
      zero: '0 tur',
    );
    return '$_temp0';
  }

  @override
  String turnPillLabel(int turn) {
    return 'T$turn';
  }

  @override
  String get turnEtaNoProgress => 'brak postępu';

  @override
  String turnEtaDetailLabel(String turnsLabel, int turn) {
    return '$turnsLabel • tura $turn';
  }

  @override
  String turnEtaTooltipNoTurn(String turnsLabel) {
    return '$turnsLabel do ukończenia';
  }

  @override
  String turnEtaTooltipExpectedTurn(String turnsLabel, int turn) {
    return '$turnsLabel do ukończenia • oczekiwana tura $turn';
  }

  @override
  String get modeBannerWorkedTilesTitle => 'Wybór pól pracujących';

  @override
  String get modeBannerWorkedTilesInstruction =>
      'Klikaj kontrolowane pola, aby przełączać pracę miasta.';

  @override
  String get modeBannerCityGrowthTitle => 'Rozwój miasta';

  @override
  String get modeBannerCityGrowthInstructionSelected =>
      'Wybrane pole zostanie dołączone przy następnym rozwoju miasta. Potwierdź wybór albo wskaż inne pole.';

  @override
  String get modeBannerCityGrowthInstructionEmpty =>
      'Kliknij obrysowane pole, aby wybrać następny hex rozwoju. Bez wyboru miasto użyje rekomendacji.';

  @override
  String get modeBannerWorkerActionTitle => 'Ulepszenie pola';

  @override
  String get modeBannerWorkerActionInstructionPicked =>
      'Potwierdź ulepszenie z dolnego toolbaru robotnika.';

  @override
  String get modeBannerWorkerActionInstructionEmpty =>
      'Wybierz typ ulepszenia w dolnym toolbarze robotnika.';

  @override
  String get modeBannerMerchantTradeRouteTitle => 'Trasa handlowa';

  @override
  String get modeBannerMerchantTradeRouteInstruction =>
      'Wybierz jedno ze swoich miast. Kupiec pojedzie tam automatycznie i zawróci po dotarciu.';

  @override
  String get modeBannerMerchantMoveToCityTitle => 'Przejdź do miasta';

  @override
  String get modeBannerMerchantMoveToCityInstruction =>
      'Wybierz jedno ze swoich miast. Kupiec wyznaczy drogę do centrum miasta bez tworzenia trasy handlowej.';

  @override
  String workerActionSelectedImprovement(String title) {
    return 'Wybrane: $title';
  }

  @override
  String get workerActionSelectImprovement => 'Wybierz ulepszenie';

  @override
  String get workerActionBuildDetailTitle => 'Budowa ulepszenia';

  @override
  String workerActionBuildImprovement(String title) {
    return 'Zbuduj $title';
  }

  @override
  String get workerActionSelectionHint =>
      'Kliknij ulepszenie dla tego pola, sprawdź plony i zatwierdź budowę.';

  @override
  String get workerActionNoYieldChange => 'bez zmiany plonów';

  @override
  String get modeBannerResearchSelectionTitle => 'Wybór badań';

  @override
  String get modeBannerResearchSelectionInstruction =>
      'Otwórz drzewko technologii i wskaż badanie, aby kontynuować turę.';

  @override
  String get modeBannerUnitTurnSkipTitle => 'Pominięta tura';

  @override
  String get modeBannerUnitTurnSkipInstruction =>
      'Jednostka czeka do następnej tury. Jej stan jest widoczny w dolnym pasku.';

  @override
  String get modeBannerCommanderMergeTitle => 'Dołączanie oddziałów';

  @override
  String get modeBannerCommanderMergeInstruction =>
      'Wskaż własną jednostkę, którą dowódca ma włączyć do armii.';

  @override
  String get modeBannerAttackTargetingTitle => 'Atak';

  @override
  String get modeBannerAttackTargetingInstructionSelected =>
      'Sprawdź prognozę walki w popupie i potwierdź atak.';

  @override
  String get modeBannerAttackTargetingInstructionEmpty =>
      'Wskaż wroga w zasięgu albo jego heks, aby zobaczyć prognozę walki.';

  @override
  String get modeBannerAttackRetreatProgress => 'Odwrót';

  @override
  String get modeBannerActionToolbarHint =>
      'Akcje wykonasz w dolnym toolbarze, jeśli są potrzebne.';

  @override
  String get combatPreviewConfirmBody =>
      'Atak wybranej jednostki zostanie wykonany natychmiast po potwierdzeniu.';

  @override
  String get combatPreviewOutcomeLabel => 'Wynik';

  @override
  String get combatPreviewTargetLabel => 'Cel';

  @override
  String get combatPreviewRetaliationLabel => 'Kontratak';

  @override
  String get combatPreviewStrengthLabel => 'Siła';

  @override
  String get combatPreviewAttackerRole => 'Atakujący';

  @override
  String get combatPreviewDefenderRole => 'Obrońca';

  @override
  String get combatPreviewCityRole => 'Miasto';

  @override
  String combatPreviewOutcomeLine(String outcome) {
    return 'Wynik: $outcome';
  }

  @override
  String get combatPreviewOutcomeCityFalls => 'miasto upada';

  @override
  String get combatPreviewOutcomeDefenderKilled => 'obrońca ginie';

  @override
  String get combatPreviewOutcomeAttackerKilled =>
      'atakujący ginie w kontrataku';

  @override
  String get combatPreviewOutcomeDefenderRetreated => 'obrońca wycofa się';

  @override
  String get combatPreviewOutcomeCitySurvives => 'miasto przetrwa';

  @override
  String get combatPreviewOutcomeDefenderSurvives => 'obrońca przeżyje';

  @override
  String combatPreviewTargetLine(
    int hpBefore,
    int hpAfter,
    int hpMax,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Cel: HP $hpBefore->$hpAfter/$hpMax, Atak $attack vs Obrona $defense (-$damage)';
  }

  @override
  String combatPreviewNoRetaliationLine(int distance, int range) {
    return 'Kontratak: brak (atak dystansowy, dystans $distance, zasięg $range)';
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
    return 'Kontratak: Atak $attack vs Obrona $defense (-$damage), HP $hpBefore->$hpAfter/$hpMax';
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
  String get combatPreviewForecastTitle => 'Prognoza starcia';

  @override
  String get combatPreviewNoHpLoss => 'bez strat';

  @override
  String combatPreviewHpAfterSemantics(int hpAfter, int hpMax, int loss) {
    return '$hpAfter z $hpMax HP po starciu, strata $loss HP';
  }

  @override
  String combatPreviewStrengthValue(int attack, int defense) {
    return '$attack ataku vs $defense obrony';
  }

  @override
  String get combatPreviewAdvantageTitle => 'Dlaczego tak?';

  @override
  String combatPreviewAdvantageAttacker(
    String country,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Przewaga ataku: $country ma atak $attack przeciw obronie $defense; cel straci około $damage HP.';
  }

  @override
  String combatPreviewAdvantageDefender(
    String country,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Przewaga obrony: $country ma obronę $defense przeciw atakowi $attack; atak zada około $damage HP.';
  }

  @override
  String combatPreviewAdvantageEven(int attack, int defense, int damage) {
    return 'Wyrównane starcie: atak $attack przeciw obronie $defense; prognoza obrażeń to około $damage HP.';
  }

  @override
  String combatPreviewTerrainLine(
    String attackerCountry,
    String attackerTerrain,
    String defenderCountry,
    String defenderTerrain,
  ) {
    return 'Pozycje: $attackerCountry atakuje z terenu: $attackerTerrain. $defenderCountry broni się na terenie: $defenderTerrain.';
  }

  @override
  String combatPreviewSourcesLine(String sources) {
    return 'Na przewagę wpływa: $sources.';
  }

  @override
  String combatPreviewPositiveSourcesLine(
    String attackerCountry,
    String sources,
  ) {
    return 'Na korzyść ataku ($attackerCountry): $sources.';
  }

  @override
  String combatPreviewNegativeSourcesLine(
    String defenderCountry,
    String sources,
  ) {
    return 'Na korzyść obrony ($defenderCountry): $sources.';
  }

  @override
  String get combatPreviewNoSourcesLine =>
      'Brak modyfikatorów: decydują bazowe statystyki jednostek i wynik walki.';

  @override
  String combatPreviewNoRetaliationReason(int distance, int range) {
    return 'Bez kontrataku: atak jest dystansowy (dystans $distance, zasięg ataku $range).';
  }

  @override
  String get combatPreviewNoRetaliationDefenderDefeated =>
      'Bez kontrataku: cel zostanie pokonany przed odpowiedzią.';

  @override
  String get combatPreviewNoRetaliationDefenderRetreats =>
      'Bez kontrataku: cel wycofa się po uderzeniu.';

  @override
  String get combatPreviewNoRetaliationNoAttack =>
      'Bez kontrataku: cel nie ma siły ataku w tej prognozie.';

  @override
  String combatPreviewRetaliationRisk(
    String defenderCountry,
    String attackerCountry,
    int damage,
  ) {
    return 'Kontratak: $defenderCountry odpowie i $attackerCountry straci około $damage HP.';
  }

  @override
  String get combatPreviewSourceAttackTerrain => 'teren atakującego';

  @override
  String get combatPreviewSourceDefenseTerrain => 'teren obrońcy';

  @override
  String get combatPreviewSourceTechnology => 'technologie';

  @override
  String get combatPreviewSourceVeterancy => 'doświadczenie';

  @override
  String get combatPreviewSourceCityGarrison => 'garnizon miasta';

  @override
  String get combatPreviewSourceMixedArmy => 'skład oddziału';

  @override
  String get combatCounterSpearmanVsMountedAttack =>
      'włócznicy przeciw jeździe';

  @override
  String get combatCounterSpearmanVsMountedDefense =>
      'włócznicy bronią przed jazdą';

  @override
  String get combatCounterArcherDefensiveTerrainDefense =>
      'łucznicy w terenie obronnym';

  @override
  String get combatCounterCavalryRoughAttack =>
      'kawaleria spowolniona w trudnym terenie';

  @override
  String get combatCounterCavalryOpenRaid =>
      'rajd kawalerii w otwartym terenie';

  @override
  String get combatCounterHeavyInfantryBreakthrough =>
      'ciężka piechota przełamuje linię';

  @override
  String get terrainOcean => 'ocean';

  @override
  String get terrainCoast => 'wybrzeże';

  @override
  String get terrainLake => 'jezioro';

  @override
  String get terrainPlains => 'równiny';

  @override
  String get terrainGrassland => 'trawy';

  @override
  String get terrainDesert => 'pustynia';

  @override
  String get terrainTundra => 'tundra';

  @override
  String get terrainSnow => 'śnieg';

  @override
  String get terrainMountain => 'góry';

  @override
  String get terrainHills => 'wzgórza';

  @override
  String get terrainWetlands => 'mokradła';

  @override
  String get terrainJungle => 'dżungla';

  @override
  String get terrainForest => 'las';

  @override
  String get terrainRiver => 'rzeka';

  @override
  String get modeBannerMoveTargetingTitle => 'Tryb ruchu';

  @override
  String get modeBannerMoveTargetingInstruction =>
      'Pierwsze kliknięcie w heks wyznacza trasę. Drugie kliknięcie w ten sam heks wykonuje ruch; dłuższa trasa trafi do kolejki na kolejne tury.';

  @override
  String get modeBannerMoveTargetingCancelAction => 'Wyjdź z ruchu';

  @override
  String get modeBannerWorkerFindTileTitle => 'Robotnik: znajdź pole';

  @override
  String modeBannerWorkerFindTileInstruction(String reason) {
    return '$reason Przesuń robotnika na własne pole miasta bez gotowego ulepszenia albo na teren pasujący do odblokowanej budowy.';
  }

  @override
  String get modeBannerWorkerFindTileDetailOwnCity => 'Własne pole miasta';

  @override
  String get modeBannerWorkerFindTileDetailNoImprovement => 'Bez ulepszenia';

  @override
  String get modeBannerWorkerFindTileDetailMatchingTerrain => 'Pasujący teren';

  @override
  String get modeBannerWorkerImproveTileTitle => 'Robotnik: ulepsz pole';

  @override
  String get modeBannerWorkerImproveTileInstruction =>
      'Na tym polu możesz rozpocząć ulepszenie. Jeśli chcesz je wykonać, użyj akcji w dolnym toolbarze, wybierz budowę i zatwierdź w dolnym panelu.';

  @override
  String get modeBannerWorkerImproveTileDetailYields => 'Zwiększa plony pola';

  @override
  String get modeBannerWorkerImproveTileDetailMovement => 'Zużywa ruch';

  @override
  String get modeBannerScoutExploreTitle => 'Zwiadowca: eksploruj';

  @override
  String get modeBannerScoutExploreInstruction =>
      'Autoeksplorację włączysz z dolnego toolbaru, żeby zwiadowca sam odkrywał najbliższe nieznane pola. Możesz ją później anulować z akcji jednostki.';

  @override
  String get modeBannerScoutExploreDetailAuto => 'Autoeksploracja';

  @override
  String get modeBannerScoutExploreDetailReveal => 'Odkrywa mapę';

  @override
  String get modeBannerSettlerFindSiteTitle => 'Osadnik: znajdź miejsce';

  @override
  String modeBannerSettlerFindSiteInstruction(String reason) {
    return '$reason Przesuń osadnika na wolne pole poza granicami miasta; unikaj wody, gór i zajętych centrów.';
  }

  @override
  String get modeBannerSettlerFindSiteDetailFreeHex => 'Wolny heks';

  @override
  String get modeBannerSettlerFindSiteDetailOutsideBorders => 'Poza granicami';

  @override
  String get modeBannerSettlerFindSiteDetailLandOrCoast => 'Ląd lub wybrzeże';

  @override
  String get modeBannerSettlerFoundCityTitle => 'Osadnik: załóż miasto';

  @override
  String get modeBannerSettlerFoundCityInstruction =>
      'To pole nadaje się na miasto. Jeśli chcesz założyć miasto, użyj akcji w dolnym toolbarze, a potem wybierz pola startowe miasta na mapie.';

  @override
  String get modeBannerSettlerFoundCityDetailNewCity => 'Nowe miasto';

  @override
  String get modeBannerSettlerFoundCityDetailChooseTiles =>
      'Wybór pól po kliknięciu';

  @override
  String get modeBannerCityFoundingTitle => 'Zakładanie miasta';

  @override
  String get modeBannerCityFoundingInstructionReady =>
      'Gotowe. Zatwierdź założenie miasta w dolnym toolbarze albo zmień wybrane pola na mapie.';

  @override
  String modeBannerCityFoundingInstructionPick(int count) {
    return 'Wybierz $count połączone pola wokół osadnika. Po wybraniu pól akcja założenia miasta będzie dostępna w dolnym toolbarze.';
  }

  @override
  String get selectionImprovementListTitle => 'Ulepszenia pola';

  @override
  String get mapInspectionPossibleImprovementsTitle => 'Możliwe ulepszenia';

  @override
  String get mapInspectionNoPossibleImprovements => 'Brak możliwych ulepszeń';

  @override
  String get mapInspectionImprovementAvailableFromStart => 'od początku';

  @override
  String get mapInspectionObjectiveTitle => 'Cel mapowy';

  @override
  String get mapObjectiveRuins => 'Ruiny';

  @override
  String get mapObjectiveStrategicPass => 'Strategiczna przełęcz';

  @override
  String get mapObjectiveHolySite => 'Święte miejsce';

  @override
  String get mapObjectiveLegendaryResource => 'Legendarne złoże';

  @override
  String get mapObjectiveRuinsDescription =>
      'Neutralny punkt eksploracji. Utrzymanie go daje przewagę punktową.';

  @override
  String get mapObjectiveStrategicPassDescription =>
      'Kluczowe przejście przez teren. Kontrola wzmacnia presję strategiczną.';

  @override
  String get mapObjectiveHolySiteDescription =>
      'Miejsce o znaczeniu kulturowym. Kontrola zapewnia złoto i punkty.';

  @override
  String get mapObjectiveLegendaryResourceDescription =>
      'Rzadkie złoże warte ekspansji lub konfliktu. Kontrola daje największą nagrodę.';

  @override
  String mapObjectiveStatusNeutral(int turns) {
    return 'Utrzymaj $turns tur';
  }

  @override
  String mapObjectiveStatusHolding(int held, int required) {
    return 'Utrzymanie $held/$required';
  }

  @override
  String mapObjectiveStatusCompleted(int held, int required) {
    return 'Kontrolowane $held/$required';
  }

  @override
  String get mapObjectiveStatusContested => 'Sporne';

  @override
  String mapObjectiveRewardVictoryPoints(int points) {
    return '+$points pkt';
  }

  @override
  String mapObjectiveRewardGoldPerTurn(int gold) {
    return '+$gold złota/turę';
  }

  @override
  String get selectionImprovementStateBuilt => 'ZBUDOWANE';

  @override
  String get selectionImprovementStateAvailable => 'DOSTĘPNE';

  @override
  String get selectionImprovementStateNeedsTechnology => 'TECH';

  @override
  String get selectionImprovementStateNeedsCity => 'MIASTO';

  @override
  String get selectionImprovementStateBlocked => 'LIMIT';

  @override
  String get selectionImprovementNoBonus => 'Bez premii';

  @override
  String workerImprovementYieldFood(int value) {
    return '+$value żywność';
  }

  @override
  String workerImprovementYieldProduction(int value) {
    return '+$value prod.';
  }

  @override
  String workerImprovementYieldGold(int value) {
    return '+$value złoto';
  }

  @override
  String workerImprovementYieldDefense(int value) {
    return '+$value obrona';
  }

  @override
  String get workerImprovementNoBonus => 'Bez dodatkowego bonusu.';

  @override
  String get workerImprovementOnlyWorker => 'Tylko robotnik może to zbudować.';

  @override
  String get workerImprovementWorkerBusy => 'Robotnik jest już zajęty budową.';

  @override
  String get workerImprovementStopQueuedMove =>
      'Najpierw zatrzymaj zaplanowany ruch.';

  @override
  String get workerImprovementMissingTile => 'Brak pola pod jednostką.';

  @override
  String get workerImprovementMissingResource =>
      'To ulepszenie wymaga pasującego surowca.';

  @override
  String get workerImprovementInvalidTerrain =>
      'Zły teren bazowy dla tego ulepszenia.';

  @override
  String get workerImprovementMissingRiver => 'To ulepszenie wymaga rzeki.';

  @override
  String get workerImprovementBlocked => 'Ta akcja jest teraz zablokowana.';

  @override
  String unitSelectionWorkerJobTurns(String name, int turns) {
    return '$name ($turns t.)';
  }

  @override
  String get resourceValueNoMatchingImprovement => 'Brak pasującego ulepszenia';

  @override
  String get resourceValueSelectWorkerOrCity => 'Wybierz robotnika lub miasto';

  @override
  String get resourceValueTileAlreadyImproved => 'Pole ma już ulepszenie';

  @override
  String get resourceValueCityCenter => 'Centrum miasta';

  @override
  String resourceValueWorksForCity(String city) {
    return 'Działa dla: $city';
  }

  @override
  String get resourceValueOutsideCityBorders => 'Poza granicami miasta';

  @override
  String get resourceValueNoLegalImprovementForTile =>
      'Brak legalnego ulepszenia dla pola';

  @override
  String resourceValueRequiresTechnology(String technology) {
    return 'Wymaga: $technology';
  }

  @override
  String get resourceValueAvailableForWorker => 'Dostępne dla robotnika';

  @override
  String get resourceDetailNoResourcesOnTile => 'Brak zasobów na polu';

  @override
  String get resourceDetailValueSection => 'Wartość';

  @override
  String get resourceDetailCurrentSection => 'Teraz';

  @override
  String get resourceDetailAfterImprovementSection => 'Po ulepszeniu';

  @override
  String get resourceDetailYieldComparison => 'Plony pola';

  @override
  String get resourceDetailRequiresSection => 'Wymaga';

  @override
  String get resourceDetailBestMoveSection => 'Najlepszy ruch';

  @override
  String get resourceDetailNoMatchingImprovementBody =>
      'Brak pasującego ulepszenia dla tego zasobu.';

  @override
  String get resourceDetailRequirementNoneCanBuild =>
      'Nic. Możesz budować od razu.';

  @override
  String get resourceDetailRequirementOutsideCity =>
      'Pole musi być w granicach miasta.';

  @override
  String get resourceDetailRequirementAlreadyImproved =>
      'Nic. Pole jest już ulepszone.';

  @override
  String get resourceDetailRequirementCityCenter =>
      'Brak budowy robotnikiem w centrum miasta.';

  @override
  String get resourceDetailRequirementSelectWorkerOrCity =>
      'Zaznaczenia robotnika albo miasta.';

  @override
  String get resourceDetailRequirementNoLegalImprovement =>
      'Brak dostępnej budowy dla tego pola.';

  @override
  String resourceDetailBestMoveRequiresTechnology(
    String technology,
    String improvement,
  ) {
    return 'Najpierw odblokuj $technology, potem zbuduj $improvement.';
  }

  @override
  String resourceDetailBestMoveAvailable(String improvement) {
    return 'Wyślij robotnika i zbuduj $improvement.';
  }

  @override
  String get resourceDetailBestMoveOutsideCity =>
      'Rozszerz granice miasta albo załóż miasto bliżej zasobu.';

  @override
  String get resourceDetailBestMoveAlreadyImproved =>
      'Utrzymaj pole w granicach i pracuj je, gdy pasuje do planu miasta.';

  @override
  String get resourceDetailBestMoveCityCenter =>
      'Traktuj zasób jako wartość centrum miasta; robotnik nie ulepsza tego pola.';

  @override
  String get resourceDetailBestMoveSelectWorkerOrCity =>
      'Zaznacz robotnika albo miasto, żeby sprawdzić legalną budowę.';

  @override
  String get resourceDetailBestMoveNoLegalImprovement =>
      'Traktuj zasób jako cel ekspansji; nie ma tu osobnej budowy.';

  @override
  String resourceValueUnlockedByTechnology(
    String technology,
    String improvement,
  ) {
    return 'Odblokowano przez $technology: $improvement.';
  }

  @override
  String resourceValueUnlocksFullYieldAfterTechnology(
    String technology,
    String improvement,
  ) {
    return 'Po $technology: $improvement odblokuje pełny yield pola.';
  }

  @override
  String resourceValueResearchBoostLine(String technology, String discount) {
    return 'Boost badań: kontrola zasobu przyspiesza $technology (-$discount kosztu).';
  }

  @override
  String resourceValueTechnologyControlledResourceBonus(
    String technology,
    int production,
  ) {
    return 'Po $technology: +$production PROD za każdy kontrolowany zasób.';
  }

  @override
  String resourceValueNoBaseYieldSummary(String yield) {
    return 'Sam zasób nie dodaje bazowego yieldu. Cały heks teraz ma $yield; pełna wartość przychodzi z ulepszeń i odblokowań.';
  }

  @override
  String resourceValueBaseYieldSummary(String resourceYield, String tileYield) {
    return 'Zasób daje $resourceYield. Cały heks teraz ma $tileYield przed ulepszeniem.';
  }

  @override
  String get resourceValueExpansionStrategic =>
      'Warto objąć granicami, zanim zrobi to rywal: to zasób strategiczny dla produkcji, armii albo późnych technologii.';

  @override
  String get resourceValueExpansionFood =>
      'Dobry cel ekspansji pod wzrost miasta: więcej żywności oznacza szybszą populację i więcej pracowanych pól.';

  @override
  String get resourceValueExpansionProduction =>
      'Dobry cel ekspansji pod tempo produkcji: szybciej powstają budynki, jednostki i presja mapowa.';

  @override
  String get resourceValueExpansionTrade =>
      'Dobry cel ekspansji pod handel: po ulepszeniu mocno wzmacnia złoto i utrzymanie dalszego rozwoju.';

  @override
  String get resourceValueExpansionEconomy =>
      'Dobry cel ekspansji pod ekonomię: złoto pomaga utrzymać armię, budować rezerwę i domykać cele punktowe.';

  @override
  String resourceValueYieldFood(int amount) {
    return '+$amount ŻYW';
  }

  @override
  String resourceValueYieldProduction(int amount) {
    return '+$amount PROD';
  }

  @override
  String resourceValueYieldGold(int amount) {
    return '+$amount ZŁ';
  }

  @override
  String resourceValueYieldDefense(int amount) {
    return '+$amount DEF';
  }

  @override
  String get resourceValueZeroBaseYield => '0 bazowego yieldu';

  @override
  String get resourceValueCategoryBonus => 'Bonus';

  @override
  String get resourceValueCategoryLuxury => 'Luksus';

  @override
  String get resourceValueCategoryStrategic => 'Strategiczny';

  @override
  String get resourceValueCategoryBonusFuture =>
      'Wartość działa głównie od razu: szybszy wzrost i lepszy start miasta.';

  @override
  String get resourceValueCategoryLuxuryFuture =>
      'Największa wartość pojawia się po objęciu granicami i właściwym ulepszeniu.';

  @override
  String get resourceValueCategoryStrategicFuture =>
      'To zasób strategiczny: warto go zabezpieczyć przed późną produkcją i presją militarną.';

  @override
  String get cityYieldBreakdownTitle => 'Ekonomia miasta';

  @override
  String cityYieldBreakdownSubtitle(String growth, String eta) {
    return 'Realny yield/turę • wzrost $growth • $eta';
  }

  @override
  String get cityYieldBreakdownProductionSources => 'Źródła produkcji';

  @override
  String get cityYieldBreakdownScienceSources => 'Źródła nauki';

  @override
  String get cityYieldBreakdownPerTurnSuffix => '/turę';

  @override
  String get cityYieldBreakdownNoProduction => 'Brak produkcji';

  @override
  String get cityYieldBreakdownNoScience => 'Brak nauki';

  @override
  String get cityYieldBreakdownCenter => 'Centrum';

  @override
  String get cityYieldBreakdownPopulationFields => 'Pola populacji';

  @override
  String get cityYieldBreakdownWorkers => 'Workerzy';

  @override
  String get cityYieldBreakdownBuildings => 'Budynki';

  @override
  String get cityYieldBreakdownTechnologies => 'Technologie';

  @override
  String get cityYieldBreakdownSpecialization => 'Specjalizacja';

  @override
  String get cityYieldBreakdownGoldMultiplier => 'Mnożnik złota';

  @override
  String get cityYieldBreakdownUpkeep => 'Utrzymanie';

  @override
  String get cityYieldBreakdownFieldsBucket => 'Pola';

  @override
  String get cityYieldBreakdownCenterDetail => 'Stały yield centrum miasta';

  @override
  String get cityYieldBreakdownGoldMultiplierDetail =>
      'Bonus procentowy po zsumowaniu źródeł złota';

  @override
  String get cityYieldBreakdownBaseScience => 'Podstawa miasta';

  @override
  String get cityYieldBreakdownBaseScienceDetail =>
      'Stała nauka generowana przez każde miasto';

  @override
  String get cityYieldBreakdownResearchProject => 'Projekt badawczy';

  @override
  String get cityYieldBreakdownResearchProjectDetail =>
      'Bieżąca produkcja miasta zamieniana na naukę';

  @override
  String get cityYieldBreakdownScienceSpecializationDetail =>
      'Profil naukowy miasta';

  @override
  String get cityYieldBreakdownScienceTechnologyDetail =>
      'Bonus nauki z odblokowanych technologii';

  @override
  String get cityYieldBreakdownNoWorkedPopulationFields =>
      'Brak pracowanych pól z populacji';

  @override
  String get cityYieldBreakdownOneWorkedPopulationField =>
      '1 pracowane pole z populacji';

  @override
  String cityYieldBreakdownManyWorkedPopulationFields(int count) {
    return '$count pracowane pola z populacji';
  }

  @override
  String get cityYieldBreakdownNoAssignedWorkers =>
      'Brak przypisanych workerów';

  @override
  String get cityYieldBreakdownOneAssignedWorker =>
      '1 pole aktywowane przez workera';

  @override
  String cityYieldBreakdownManyAssignedWorkers(int count) {
    return '$count pola aktywowane przez workerów';
  }

  @override
  String get cityYieldBreakdownNoPassiveImprovements =>
      'Brak pasywnych ulepszeń';

  @override
  String get cityYieldBreakdownOnePassiveImprovement =>
      '1 niepracowane ulepszenie, połowa yield';

  @override
  String cityYieldBreakdownManyPassiveImprovements(int count) {
    return '$count niepracowane ulepszenia, połowa yield';
  }

  @override
  String get cityYieldBreakdownNoBuildings => 'Brak budynków';

  @override
  String get cityYieldBreakdownBuildingsNoDirectYield =>
      'Budynki bez bezpośredniego yield';

  @override
  String get cityYieldBreakdownOneBuildingEconomicEffect =>
      '1 budynek z efektem ekonomii';

  @override
  String cityYieldBreakdownManyBuildingEconomicEffects(int count) {
    return '$count budynki z efektami ekonomii';
  }

  @override
  String get cityYieldBreakdownNoTechnologyYield =>
      'Brak bonusu yield z technologii';

  @override
  String get cityYieldBreakdownTechnologyYield =>
      'Bonusy od odblokowanych technologii';

  @override
  String get cityYieldBreakdownNoScienceBuildings => 'Brak budynków naukowych';

  @override
  String get cityYieldBreakdownOneScienceBuilding => '1 budynek naukowy';

  @override
  String cityYieldBreakdownManyScienceBuildings(int count) {
    return '$count budynki naukowe z malejącym zwrotem';
  }

  @override
  String cityYieldBreakdownGrowthFood(int storedFood, int growthCost) {
    return '$storedFood/$growthCost żywności';
  }

  @override
  String get cityYieldBreakdownStagnation => 'stagnacja';

  @override
  String cityYieldBreakdownUpkeepBlocked(int population, int cost) {
    return 'Populacja $population: koszt $cost, wzrost zatrzymany';
  }

  @override
  String cityYieldBreakdownUpkeepCost(int population) {
    return 'Koszt żywności populacji $population';
  }

  @override
  String get cityYieldBreakdownGrowthSpecializationDetail =>
      'Profil wzrostu miasta';

  @override
  String get cityYieldBreakdownIndustrySpecializationDetail =>
      'Profil przemysłu miasta';

  @override
  String get cityYieldBreakdownCommerceSpecializationDetail =>
      'Profil handlu miasta';

  @override
  String get cityYieldBreakdownScienceSpecializationCityDetail =>
      'Profil nauki miasta';

  @override
  String get cityYieldBreakdownMilitarySpecializationDetail =>
      'Profil garnizonu miasta';

  @override
  String get cityYieldBreakdownNoSpecialization => 'Brak specjalizacji';

  @override
  String get cityProjectWealth => 'Bogactwo';

  @override
  String get cityProjectResearch => 'Badania';

  @override
  String get cityProductionProjectsSection => 'Projekty miasta';

  @override
  String get cityProductionSpecializationSection => 'Specjalizacja miasta';

  @override
  String get cityProductionSortLabel => 'Sortuj';

  @override
  String cityProductionHeaderSubtitle(
    String title,
    String productionPerTurn,
    int gold,
  ) {
    return '$title • $productionPerTurn • $gold złota';
  }

  @override
  String get cityProductionBuiltLabel => 'Zbudowany';

  @override
  String get cityProductionAvailableLabel => 'Dostępny';

  @override
  String get cityProductionAvailableUnitLabel => 'Dostępna';

  @override
  String cityProductionUnitSupplyLimit(int used, int capacity) {
    return 'Limit żywności $used/$capacity';
  }

  @override
  String cityProductionUnitSupplyCost(int cost) {
    return 'żywność $cost';
  }

  @override
  String cityProductionUnitSupplyUsed(int used, int capacity) {
    return 'limit $used/$capacity';
  }

  @override
  String cityProductionNextWorkerUpkeep(int upkeep) {
    return 'utrzymanie kolejnego: $upkeep';
  }

  @override
  String cityProductionCostShort(int production) {
    return '$production prod.';
  }

  @override
  String cityProductionPaceShort(int production) {
    return '$production prod./turę';
  }

  @override
  String get cityBuildingSortRecommended => 'Polecane';

  @override
  String cityBuildingReplaceProgressWarning(String building) {
    return 'Wybór innego budynku zastąpi $building. Postęp zostanie zachowany.';
  }

  @override
  String get cityBuildingSortFastestImpact => 'Najszybszy efekt';

  @override
  String get cityBuildingSortBestReturn => 'Najlepszy zwrot';

  @override
  String get cityBuildingSortGrowth => 'Rozwój';

  @override
  String get cityBuildingSortIndustry => 'Przemysł';

  @override
  String get cityBuildingSortScience => 'Nauka';

  @override
  String get cityBuildingSortDefenseMilitary => 'Obrona / wojsko';

  @override
  String get cityBuildingSortEconomy => 'Ekonomia';

  @override
  String get cityBuildingRequiresTechnology => 'Wymaga technologii';

  @override
  String get cityProductionContinuous => 'ciągły';

  @override
  String get cityProductionNoProduction => 'brak produkcji';

  @override
  String get cityProductionReady => 'gotowe';

  @override
  String get cityProductionTurnOne => '1 tura';

  @override
  String cityProductionTurns(int turns) {
    return '$turns tur';
  }

  @override
  String cityProductionTreasuryGold(int gold) {
    return 'Skarbiec: $gold złota';
  }

  @override
  String cityProductionRushAction(int gold) {
    return 'Przyspiesz -$gold';
  }

  @override
  String cityProjectGoldPerTurn(int gold) {
    return '+$gold złota / turę';
  }

  @override
  String cityProjectSciencePerTurn(int science) {
    return '+$science nauki / turę';
  }

  @override
  String get citySpecializationGrowth => 'Wzrost';

  @override
  String get citySpecializationIndustry => 'Przemysł';

  @override
  String get citySpecializationCommerce => 'Handel';

  @override
  String get citySpecializationMilitary => 'Garnizon';

  @override
  String get citySpecializationGrowthBonus => '+2 żywności';

  @override
  String get citySpecializationIndustryBonus => '+2 produkcji';

  @override
  String get citySpecializationCommerceBonus => '+3 złota';

  @override
  String get citySpecializationScienceBonus => '+2 nauki';

  @override
  String get citySpecializationMilitaryProductionBonus => '+1 produkcji';

  @override
  String get citySpecializationMilitaryDefenseBonus => '+2 obrony';

  @override
  String get citySpecializationMilitaryUnitProductionBonus =>
      '+1 prod. jednostek';

  @override
  String get citySpecializationBestFit => 'Najlepsze dopasowanie';

  @override
  String get eventCityFoundedTitle => 'Miasto założone';

  @override
  String get eventCityBuiltBuildingTitle => 'Budowa ukończona';

  @override
  String get eventCityProducedUnitTitle => 'Jednostka wyszkolona';

  @override
  String get eventCityClaimedHexTitle => 'Granice miasta';

  @override
  String eventCityClaimedHexBody(String cityName) {
    return '$cityName: nowe pole';
  }

  @override
  String get eventUnitMovedTitle => 'Ruch jednostki';

  @override
  String get eventUnitPromotedTitle => 'Awans jednostki';

  @override
  String get eventUnitExperienceTitle => 'Doświadczenie';

  @override
  String eventUnitExperienceBody(String unitName, int amount, String rank) {
    return '$unitName: +$amount XP ($rank)';
  }

  @override
  String get eventUnitAttackedTitle => 'Atak';

  @override
  String get eventCombatTitle => 'Walka';

  @override
  String eventCombatDamageLine(String unitName, int damage, String result) {
    return '$unitName: -$damage HP -> $result';
  }

  @override
  String eventCombatNoRetaliationLine(String unitName) {
    return '$unitName: brak kontrataku';
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
    return '$attackerName ($attackerCountry) zaatakował $defenderName ($defenderCountry) - HP $attackerHp:$defenderHp';
  }

  @override
  String get eventDiplomaticProposalAcceptedStatus => 'Zaakceptowano';

  @override
  String get eventDiplomaticProposalRejectedStatus => 'Odrzucono';

  @override
  String get eventDiplomaticProposalExpiredStatus => 'Wygasło';

  @override
  String get eventUnitKilledTitle => 'Jednostka pokonana';

  @override
  String get eventUnitRetreatedTitle => 'Odwrót';

  @override
  String get eventCityCapturedTitle => 'Miasto zdobyte';

  @override
  String get eventCityDestroyedTitle => 'Miasto zniszczone';

  @override
  String get eventTurnEndedTitle => 'Tura zakończona';

  @override
  String get eventWorkerCompletedJobTitle => 'Praca zakończona';

  @override
  String get eventResearchPointsTitle => 'Nauka';

  @override
  String eventResearchPointsBody(String playerName, int points) {
    return '$playerName: +$points nauki';
  }

  @override
  String get eventTechnologyResearchedTitle => 'Technologia odkryta';

  @override
  String get eventStrategicResourceDiscoveredTitle =>
      'Odkryto zasób strategiczny';

  @override
  String eventStrategicResourceDiscoveredBody(
    String playerName,
    String resourceName,
  ) {
    return '$playerName: $resourceName';
  }

  @override
  String eventStrategicResourceControlledDetail(int count) {
    return 'Kontrolowane: $count';
  }

  @override
  String eventStrategicResourceRivalDetail(int count) {
    return 'U rywali: $count';
  }

  @override
  String eventStrategicResourceUnclaimedDetail(int count) {
    return 'Nieprzejęte: $count';
  }

  @override
  String get eventStrategicResourcePressureSecured =>
      'Zaopatrzenie zabezpieczone; broń źródła.';

  @override
  String get eventStrategicResourcePressureExpansionRace =>
      'Wyścig osadniczy: przejmij najbliższe złoże przed rywalami.';

  @override
  String get eventStrategicResourcePressureContested =>
      'Sporny zasób: rywale też mają źródła.';

  @override
  String get eventStrategicResourcePressureRivalMonopoly =>
      'Monopol rywali: przygotuj handel albo ekspedycję.';

  @override
  String eventStrategicResourceSettleHint(int col, int row) {
    return 'Złoże poza granicami przy $col:$row; warto wysłać osadnika.';
  }

  @override
  String get eventMapObjectiveSecuredTitle => 'Cel mapowy zabezpieczony';

  @override
  String eventMapObjectiveSecuredBody(String playerName, String objectiveName) {
    return '$playerName: $objectiveName';
  }

  @override
  String eventMapObjectiveHoldDetail(int holdTurns, int requiredHoldTurns) {
    return 'Utrzymanie: $holdTurns/$requiredHoldTurns';
  }

  @override
  String eventMapObjectiveLocationDetail(int col, int row) {
    return 'Pozycja: $col:$row';
  }

  @override
  String eventMapObjectiveVictoryRewardDetail(int points) {
    return '+$points punktów zwycięstwa';
  }

  @override
  String eventMapObjectiveGoldRewardDetail(int gold) {
    return '+$gold złota/turę';
  }

  @override
  String get eventCivilizationMetTitle => 'Nowa cywilizacja';

  @override
  String eventCivilizationMetBody(String civilizationName, String playerName) {
    return '$civilizationName ($playerName)';
  }

  @override
  String get civilizationMetPopupEyebrow => 'Spotkano cywilizację';

  @override
  String civilizationMetPopupBody(String civilizationName) {
    return 'Na horyzoncie pojawiła się cywilizacja $civilizationName. To nowy sąsiad, rywal albo przyszły sojusznik.';
  }

  @override
  String get civilizationMetPopupOk => 'OK';

  @override
  String get eventCommandRejectedTitle => 'Komenda odrzucona';

  @override
  String get eventAllPlayersSubmittedTitle => 'Wszyscy gotowi';

  @override
  String eventAllPlayersSubmittedBody(int turn, int players) {
    return 'Tura $turn ($players)';
  }

  @override
  String get eventPlayerTimedOutTitle => 'Auto-submit';

  @override
  String eventPlayerTimedOutBody(String playerName, int turn) {
    return '$playerName: timeout w turze $turn';
  }

  @override
  String get eventCombatDefenderKilledDetail => 'Obrońca pokonany';

  @override
  String get eventCombatAttackerKilledDetail => 'Atakujący pokonany';

  @override
  String get eventCombatDefenderRetreatedDetail => 'Obrońca wycofany';

  @override
  String eventCombatAttackDamageDetail(int damage) {
    return 'Atak: -$damage HP';
  }

  @override
  String eventCombatRetaliationDamageDetail(int damage) {
    return 'Kontratak: -$damage HP';
  }

  @override
  String eventCombatRollDetail(int value) {
    return 'Rzut $value';
  }

  @override
  String get eventCombatNoRetaliationDetail => 'Brak kontrataku';

  @override
  String get eventDominationStartedTitle => 'Dominacja rozpoczęta';

  @override
  String get eventDominationRivalAboveTitle => 'Rywal nad progiem';

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
    return 'Utrzymanie $held/$required tur';
  }

  @override
  String get eventDominationReadyDetail => 'Warunek gotowy';

  @override
  String eventDominationKeepHoldingDetail(String turns) {
    return 'Utrzymaj jeszcze $turns';
  }

  @override
  String eventDominationInterruptDetail(String turns) {
    return 'Przerwij w ciągu $turns';
  }

  @override
  String eventTurnCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tur',
      few: '$count tury',
      one: '1 turę',
      zero: '0 tur',
    );
    return '$_temp0';
  }

  @override
  String get eventCombatDefeatedResult => 'pokonany';

  @override
  String eventCombatDefenderRetreatedResult(int hp) {
    return '$hp HP, odwrót';
  }

  @override
  String eventCombatHpResult(int hp) {
    return '$hp HP';
  }

  @override
  String eventCombatTerrainModifierLabel(Object terrain) {
    return 'Teren $terrain';
  }

  @override
  String eventCombatTechModifierLabel(Object technology) {
    return 'Technologia $technology';
  }

  @override
  String eventCombatRankModifierLabel(Object rank) {
    return 'Ranga $rank';
  }

  @override
  String get eventCombatCityGarrisonModifier => 'Garnizon miasta';

  @override
  String get eventCombatMixedArmyModifier => 'Mieszana armia';

  @override
  String get eventCombatStatAttack => 'atak';

  @override
  String get eventCombatStatDefense => 'obrona';

  @override
  String get eventCombatStatHp => 'HP';

  @override
  String get eventCombatStatRange => 'zasięg';

  @override
  String get eventCombatStatMobility => 'ruch';

  @override
  String get closeAction => 'Zamknij';
}
