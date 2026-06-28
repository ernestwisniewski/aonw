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
    return 'Joueur $index';
  }

  @override
  String defaultCityName(int index) {
    return 'Ville $index';
  }

  @override
  String get newGameTitle => 'NOUVEAU JEU';

  @override
  String get gameModeSinglePlayerMenuLabel => 'Joueur unique';

  @override
  String get gameModeMultiplayerMenuLabel => 'Multijoueur';

  @override
  String get gameModeHotSeatMenuLabel => 'Hot Seat';

  @override
  String get gameModeSinglePlayerSummaryLabel => 'Joueur unique';

  @override
  String get gameModeMultiplayerSummaryLabel => 'Multijoueur';

  @override
  String get gameModeHotSeatSummaryLabel => 'Hot Seat';

  @override
  String get gameModeSinglePlayerMapTitle =>
      'Choisissez une carte pour jouer en solo';

  @override
  String get gameModeMultiplayerMapTitle =>
      'Choisissez une carte pour jouer en ligne';

  @override
  String get gameModeHotSeatMapTitle =>
      'Choisissez une carte pour jouer au Hot Seat';

  @override
  String get gameModeSinglePlayerMapSubtitle =>
      'Une partie locale contre l\'IA.';

  @override
  String get gameModeMultiplayerMapSubtitle =>
      'Scénario de départ et carte du monde pour un partie en ligne.';

  @override
  String get gameModeHotSeatMapSubtitle =>
      'Scénario de départ et carte du monde pour un seul appareil de jeu de Hot Seat.';

  @override
  String get newGameIntroTitle => 'Préparez l\'expédition';

  @override
  String get newGameIntroSubtitle =>
      'Choisissez d\'abord le style de jeu, puis la carte, puis raffinez les joueurs et allumez le rythme.';

  @override
  String get newGameStepPlan => 'Plan de jeu';

  @override
  String get newGameStepMap => 'Carte';

  @override
  String get newGameStepReview => 'Révision';

  @override
  String get newGamePlanTitle => 'Quelle histoire voulez-vous commencer ?';

  @override
  String get newGamePremiseTitle => 'De la colonisation à l\'empire';

  @override
  String get newGamePremiseBody =>
      'Chaque partie commence par quelques choix décisifs: où trouver la première ville, comment façonner la recherche, quand risquer l\'expansion, et comment garder le contrôle de la carte.';

  @override
  String get newGameCountryTitle => 'Choisir la civilisation';

  @override
  String get newGameCountrySubtitle =>
      'Votre nom de chef suit la civilisation que vous choisissez.';

  @override
  String get newGameSinglePlayerSettingsTitle => 'Paramètres de partie';

  @override
  String get newGameGameLengthLabel => 'Longueur du jeu';

  @override
  String get newGameLeaderLabel => 'LEADER';

  @override
  String get newGamePillarCities => 'Villes';

  @override
  String get newGamePillarUnits => 'Unités';

  @override
  String get newGamePillarResearch => 'Recherche';

  @override
  String get newGameVictoryTypesTitle => 'Chemins de la victoire';

  @override
  String get newGameVictoryDominationTitle => 'Domination';

  @override
  String newGameVictoryDominationBody(String controlPercent, int holdTurns) {
    return 'Contrôlez $controlPercent% de la carte et conservez ce seuil pendant $holdTurns tours. La conquête peut encore mettre fin à la partie en éliminant les rivaux.';
  }

  @override
  String get newGameVictoryArtifactsTitle => 'Artefacts';

  @override
  String newGameVictoryArtifactsBody(int artifactCount, int holdTurns) {
    return 'Placez des artefacts uniques du monde $artifactCount dans vos villes et conservez la collection complète pour les tours $holdTurns.';
  }

  @override
  String get newGameModeSinglePlayerDescription =>
      'Un partie calme contre l\'IA. Meilleur pour les systèmes d\'apprentissage, les mises à l\'essai et l\'expérimentation de la croissance.';

  @override
  String get newGameModeMultiplayerDescription =>
      'Un partie en ligne avec lobby réseau, préparation du joueur, et une entrée partagée sur la carte.';

  @override
  String get newGameModeMultiplayerAlphaDisabled =>
      'Indisponible dans la version alpha.';

  @override
  String get newGameModeHotSeatDescription =>
      'Le Hot Seat joue sur un seul appareil. Les joueurs passent le tour, tandis que l\'écran guide chaque sortie.';

  @override
  String get newGameMapTitle => 'Choisir le monde';

  @override
  String get newGameMapSubtitle =>
      'La carte définit le rythme du premier contact, les ressources disponibles, l\'espace urbain et la forme du conflit.';

  @override
  String get newGameReviewTitle => 'Confirmer l\'expédition';

  @override
  String get newGameReviewSubtitle =>
      'Après confirmation, vous entrez dans le lobby pour définir le nom du jeu, la longueur du partie, et les joueurs.';

  @override
  String newGameReviewSinglePlayerSubtitle(int aiCount) {
    return 'Un seul joueur commence immédiatement avec vous et $aiCount IA.';
  }

  @override
  String get newGameReviewMissingMap =>
      'Choisissez une carte avant de configurer les joueurs.';

  @override
  String get newGameExpeditionReady => 'Expédition prête';

  @override
  String get newGameSelectedMapLabel => 'Carte';

  @override
  String get newGameMapPickLabel => 'Choix de la carte';

  @override
  String get newGameMapPickRandom => 'Par défaut aléatoire';

  @override
  String get newGameMapPickManual => 'Sélection manuelle';

  @override
  String get newGameWorldSourceLabel => 'Source';

  @override
  String newGameSinglePlayerAiSummary(int aiCount) {
    return 'Vous + $aiCount IA';
  }

  @override
  String get newGameChangeMapAction => 'Modifier la carte';

  @override
  String get newGameStartSetupAction => 'Allez dans le hall';

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
  String get manualTitle => 'Manuel des commandes';

  @override
  String get manualSubtitle =>
      'Une référence rapide pour le mouvement de carte, la sélection, les commandes, les panneaux, et le flux de tour sur le bureau et mobile.';

  @override
  String get manualMetaDesktop => 'Bureau';

  @override
  String get manualMetaMobile => 'Mobile';

  @override
  String get manualMetaAlpha => 'Un seul joueur alpha';

  @override
  String get manualCommandLoopTitle => 'Boucle de commande de base';

  @override
  String get manualCommandLoopSelectTitle => 'Sélectionner';

  @override
  String get manualCommandLoopSelectBody =>
      'Choisissez une unité, une ville, un artefact ou une carte pour révéler les actions qui comptent maintenant.';

  @override
  String get manualCommandLoopPreviewTitle => 'Aperçu';

  @override
  String get manualCommandLoopPreviewBody =>
      'Plongez ou tapez une fois pour inspecter les cibles, les couleurs d\'intention, les itinéraires et les actions bloquées.';

  @override
  String get manualCommandLoopConfirmTitle => 'Confirmer';

  @override
  String get manualCommandLoopConfirmBody =>
      'Utilisez une puce d\'action ou choisissez à nouveau la cible surlignée pour lancer l\'ordre.';

  @override
  String get manualCommandLoopAdvanceTitle => 'Avances';

  @override
  String get manualCommandLoopAdvanceBody =>
      'Utilisez le bouton d\'action en bas pour passer à la prochaine décision ou terminer le tour.';

  @override
  String get manualDesktopTitle => 'Commandes de bureau';

  @override
  String get manualDesktopSubtitle =>
      'Mouse-premier jeu avec inspection rapide de la carte, ciblage précis, et panneaux persistants.';

  @override
  String get manualMobileTitle => 'Commandes mobiles';

  @override
  String get manualMobileSubtitle =>
      'Touch-premier jeu accordé pour des panneaux lisibles, des ordres délibérés, et un flux de tour rapide.';

  @override
  String get manualMapCameraGroup => 'Carte & appareil photo';

  @override
  String get manualOrdersGroup => 'Sélection & commandes';

  @override
  String get manualPanelsGroup => 'Panneaux & aide';

  @override
  String get manualTurnFlowGroup => 'Courroie';

  @override
  String get manualDesktopLeftClickAction => 'Cliquez à gauche';

  @override
  String get manualDesktopLeftClickBody =>
      'Sélectionnez les unités, les villes, les artefacts et les tuiles; avec un ordre actif, choisissez la cible.';

  @override
  String get manualDesktopDragAction => 'Faites glisser la carte';

  @override
  String get manualDesktopDragBody =>
      'Panifiez la caméra sans changer le mode de sélection ou de commande actuel.';

  @override
  String get manualDesktopZoomAction => 'Roue de la souris / piste';

  @override
  String get manualDesktopZoomBody =>
      'Zoom entre aperçu stratégique et détails tactiques sur la carte.';

  @override
  String get manualDesktopHoverAction => 'Coucher';

  @override
  String get manualDesktopHoverBody =>
      'Prévisualiser les bouts d\'outils, les conseils de la cible et les raisons de l\'ordre bloqué avant de commettre.';

  @override
  String get manualDesktopActionChipsAction => 'puces d\'action';

  @override
  String get manualDesktopActionChipsBody =>
      'Déplacer, attaquer, améliorer, trouver une ville, sauter, fortifier ou annuler le mode actuel.';

  @override
  String get manualDesktopSecondClickAction => 'Même cible deux fois';

  @override
  String get manualDesktopSecondClickBody =>
      'Pour le mouvement, le premier clic prévisualise l\'itinéraire; le second clic l\'exécute ou le file d\'attente.';

  @override
  String get manualDesktopHoldAction => 'Cliquez et maintenez';

  @override
  String get manualDesktopHoldBody =>
      'Ouvrez des explications de commande détaillées pour les actions, les options désactivées et les puces contextuelles.';

  @override
  String get manualDesktopRailAction => 'Rail gauche';

  @override
  String get manualDesktopRailBody =>
      'Ouvrir les options de carte, l\'aide, les objectifs, le journal des activités, la recherche et les panneaux empire.';

  @override
  String get manualDesktopTopPillsAction => 'Ressources principales';

  @override
  String get manualDesktopTopPillsBody =>
      'Inspecter l\'économie, la science, les ressources et la victoire.';

  @override
  String get manualDesktopCloseAction => 'Cliquez à l\'extérieur';

  @override
  String get manualDesktopCloseBody =>
      'Fermez les popups, les panneaux d\'option et les cartes d\'aide, puis retournez le focus sur la carte.';

  @override
  String get manualDesktopHelpAction => '?';

  @override
  String get manualDesktopHelpBody =>
      'Ouvrez chaque conseil minimisé et chaque carte de tutoriel à tout moment, indépendamment de la sélection.';

  @override
  String get manualDesktopTurnAction => 'Décision suivante';

  @override
  String get manualDesktopTurnBody =>
      'Concentrez-vous sur la prochaine unité, la recherche ou le choix de la ville; terminez le tour quand rien ne bloque les progrès.';

  @override
  String get manualMobileTapAction => 'Appuyez sur';

  @override
  String get manualMobileTapBody =>
      'Sélectionnez les unités, les villes, les artefacts et les tuiles; avec un ordre actif, choisissez la cible.';

  @override
  String get manualMobileDragAction => 'Traîne à un doigt';

  @override
  String get manualMobileDragBody =>
      'Panifiez la caméra tout en maintenant l\'unité ou le panneau sélectionné intact.';

  @override
  String get manualMobilePinchAction => 'Pince';

  @override
  String get manualMobilePinchBody =>
      'Zoomez la carte pour le scoutisme, le travail urbain, la planification des mouvements ou le ciblage de la bataille.';

  @override
  String get manualMobileSecondTapAction => 'Même cible deux fois';

  @override
  String get manualMobileSecondTapBody =>
      'Prévisualisez un itinéraire de mouvement d\'abord, puis tapez de nouveau sur le même hexagone pour l\'exécuter ou la file d\'attente.';

  @override
  String get manualMobileActionChipsAction => 'puces d\'action';

  @override
  String get manualMobileActionChipsBody =>
      'Utilisez la ligne de commande inférieure pour les commandes d\'unité, les choix de ville, les travailleurs et annuler les actions.';

  @override
  String get manualMobileHoldAction => 'Presser et tenir';

  @override
  String get manualMobileHoldBody =>
      'Ouvrez des explications pour les commandes, les options désactivées, les ressources et l\'interface utilisateur contextuelle.';

  @override
  String get manualMobileScrollAction => 'Panneaux de défilement';

  @override
  String get manualMobileScrollBody =>
      'Parcourez la longue ville, la recherche, le journal, la diplomatie et les listes d\'aide sans perdre l\'état de carte.';

  @override
  String get manualMobileRailAction => 'Rail gauche';

  @override
  String get manualMobileRailBody =>
      'Appuyez sur pour ouvrir les options de cartes, l\'aide, les objectifs, le journal des activités, la recherche et les panneaux empire.';

  @override
  String get manualMobileHelpAction => '?';

  @override
  String get manualMobileHelpBody =>
      'Passez en revue chaque conseil minimisé et chaque carte de tutoriel chaque fois que vous avez besoin d\'un rafraîchissement.';

  @override
  String get manualMobileTurnAction => 'Action de fond';

  @override
  String get manualMobileTurnBody =>
      'Aller à la prochaine décision requise ou terminer le tour une fois que tous les points d\'action sont dépensés.';

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
  String get gameNameLabel => 'NOM DU JEU';

  @override
  String get playersLabel => 'JEUNES';

  @override
  String get countryLabel => 'PAYS';

  @override
  String get countryPoland => 'Pologne';

  @override
  String get countryUkraine => 'Ukraine';

  @override
  String get countryGermany => 'Allemagne';

  @override
  String get countryFrance => 'France';

  @override
  String get countryUnitedKingdom => 'Royaume-Uni';

  @override
  String get countryItaly => 'Italie';

  @override
  String get countrySpain => 'Espagne';

  @override
  String get countryNetherlands => 'Belgique';

  @override
  String get countrySweden => 'Suède';

  @override
  String get countryRussia => 'Russie';

  @override
  String get countryUnitedStates => 'États-Unis';

  @override
  String get countryCanada => 'Canada';

  @override
  String get countryChina => 'Chine';

  @override
  String get countryKorea => 'Corée';

  @override
  String get countryJapan => 'Japon';

  @override
  String get countryPortugal => 'Portugal';

  @override
  String get countryLeaderPoland => 'Casimir III le Grand';

  @override
  String get countryLeaderUkraine => 'Yaroslav le Sage';

  @override
  String get countryLeaderGermany => 'Otto von Bismarck';

  @override
  String get countryLeaderFrance => 'Napoléon Bonaparte';

  @override
  String get countryLeaderUnitedKingdom => 'Reine Victoria';

  @override
  String get countryLeaderItaly => 'Jules César';

  @override
  String get countryLeaderSpain => 'Isabella I';

  @override
  String get countryLeaderNetherlands => 'Guillaume d\'Orange';

  @override
  String get countryLeaderSweden => 'Gustavus Adolphe';

  @override
  String get countryLeaderRussia => 'Catherine la Grande';

  @override
  String get countryLeaderUnitedStates => 'Abraham Lincoln';

  @override
  String get countryLeaderCanada => 'Wilfrid Laurier';

  @override
  String get countryLeaderChina => 'Qin Shi Huang';

  @override
  String get countryLeaderKorea => 'Sejong le Grand';

  @override
  String get countryLeaderJapan => 'Tokugawa Ieyasu';

  @override
  String get countryLeaderPortugal => 'Henry le navigateur';

  @override
  String get addPlayerAction => '+ AJOUTER';

  @override
  String get startGameAction => 'DÉPÔT';

  @override
  String get removePlayerTooltip => 'Supprimer le joueur';

  @override
  String get multiplayerSearchTitle => 'RECHERCHE DES SERVEURS';

  @override
  String get multiplayerSearchBody =>
      'La liste des jeux en ligne apparaîtra ici.';

  @override
  String get multiplayerPlayersTitle => 'Joueurs';

  @override
  String get multiplayerStatusTooltip => 'État du joueur';

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
  String get multiplayerStatusActive => 'jouer maintenant';

  @override
  String get multiplayerStatusSubmitted => 'tour envoyé';

  @override
  String get multiplayerStatusThinking => 'penser';

  @override
  String get multiplayerStatusWaiting => 'attendre';

  @override
  String get multiplayerStatusTimeout => 'temps mort';

  @override
  String get diplomacyRelationFriendly => 'amical';

  @override
  String get diplomacyRelationNeutral => 'neutre';

  @override
  String get diplomacyRelationHostile => 'hostile';

  @override
  String get diplomacyRelationTruce => 'trêve';

  @override
  String get diplomacyRelationWar => 'guerre';

  @override
  String get diplomacyRelationFriendlyShort => 'fr.';

  @override
  String get diplomacyRelationNeutralShort => 'Neut. Je ne sais pas.';

  @override
  String get diplomacyRelationHostileShort => 'hôte.';

  @override
  String get diplomacyRelationTruceShort => 'trêve';

  @override
  String get diplomacyRelationWarShort => 'guerre';

  @override
  String get commonDiplomacy => 'Diplomatie';

  @override
  String get diplomacyScoreLabel => 'Relations';

  @override
  String get diplomacyScoreDriversTitle => 'Ce qui change les relations';

  @override
  String get diplomacyScoreReasonManual => 'Changement manuel';

  @override
  String get diplomacyScoreReasonUnitAttack => 'Attaque d\'unité';

  @override
  String get diplomacyScoreReasonCityAttack => 'Attaque de la ville';

  @override
  String get diplomacyScoreReasonDeclarationOfWar => 'Déclaration de guerre';

  @override
  String get diplomacyScoreReasonProposalAccepted => 'Proposition acceptée';

  @override
  String get diplomacyScoreReasonProposalRejected => 'Proposition rejetée';

  @override
  String get diplomacyScoreReasonMessageResponse => 'Réponse d \' expédition';

  @override
  String get diplomacyScoreReasonPromiseBroken => 'La promesse brisée';

  @override
  String get diplomacyStatsTitle => 'Statistiques';

  @override
  String get diplomacyHistoryTitle => 'Historique';

  @override
  String get diplomacyMessagesTitle => 'Expéditions';

  @override
  String get diplomacyIncomingMessageTitle => 'Nouvelle expédition';

  @override
  String diplomacyIncomingMessageFrom(String playerName) {
    return 'De: $playerName';
  }

  @override
  String get diplomacyIncomingProposalTitle => 'Nouvelle proposition';

  @override
  String diplomacyIncomingProposalFrom(String playerName) {
    return 'De: $playerName';
  }

  @override
  String get diplomacyIncomingMessageLater => 'Plus tard';

  @override
  String get diplomacyActionsTitle => 'Actions';

  @override
  String get diplomacyProposalsTitle => 'Propositions';

  @override
  String get diplomacyNoHistory => 'Aucun incident enregistré.';

  @override
  String get diplomacyNoMessages => 'Pas de dépêches.';

  @override
  String get diplomacyMilitaryStat => 'Militaire';

  @override
  String get diplomacyCitiesStat => 'Villes';

  @override
  String get diplomacyExpansionStat => 'Expansion';

  @override
  String get diplomacyArtifactsStat => 'Artefacts';

  @override
  String get diplomacyLastAggressionStat => 'Dernière agression';

  @override
  String get diplomacyOwnArtifactsLabel => 'Vos artefacts';

  @override
  String get diplomacyTargetArtifactsLabel => 'Artefacts rivaux';

  @override
  String diplomacyTurnsRemaining(int turns) {
    return 'Tours restants: $turns';
  }

  @override
  String get diplomacyProposalFriendship => 'Proposition d\'amitié';

  @override
  String get diplomacyProposalTruce => 'Proposition de trêve';

  @override
  String get diplomacySendFriendship => 'Proposer l\'amitié';

  @override
  String get diplomacySendTruce => 'Proposition de trêve';

  @override
  String get diplomacyDeclareWar => 'Déclarer la guerre';

  @override
  String get diplomacyAccept => 'Accepter';

  @override
  String get diplomacyDecline => 'Baisse';

  @override
  String get diplomacyMessageTroopsNearCities =>
      'Trop de troupes sont placées près de mes villes.';

  @override
  String get diplomacyMessageCitiesTooClose =>
      'Vous êtes des villes fondatrices trop proches de mes frontières.';

  @override
  String get diplomacyMessageBlockedRoutes => 'Vos unités bloquent mes routes.';

  @override
  String get diplomacyMessageWithdrawScouts =>
      'Retirez vos éclaireurs de mon territoire.';

  @override
  String get diplomacyMessageAvoidEscalation =>
      'Nos civilisations devraient éviter une nouvelle escalade.';

  @override
  String get diplomacyMessageCommonEnemy =>
      'Un ennemi commun nous menace tous les deux.';

  @override
  String get diplomacyMessageExpansionProvocation =>
      'Votre expansion est perçue comme une provocation.';

  @override
  String get diplomacyMessagePeacefulPraise =>
      'Nous apprécions les relations pacifiques entre nos peuples.';

  @override
  String get diplomacyResponseConciliatory => 'Conciliation';

  @override
  String get diplomacyResponseNeutral => 'Neutre';

  @override
  String get diplomacyResponseEvasive => 'Évasive';

  @override
  String get diplomacyResponseAggressive => 'Agressifs';

  @override
  String get diplomacyStrategicResourcesTitle => 'Ressources stratégiques';

  @override
  String get diplomacyResourceTradeBlockedByWar =>
      'Le commerce des ressources est bloqué par la guerre.';

  @override
  String get diplomacyResourceTradeNoAvailableResources =>
      'Aucune ressource stratégique de rechange n\'est disponible pour le commerce.';

  @override
  String diplomacyResourceTradeImportOffer(int goldPerTurn, int durationTurns) {
    return 'Offre d\'importation: $goldPerTurn or/tour pour $durationTurns tours.';
  }

  @override
  String diplomacyResourceTradeImportAction(String resourceName) {
    return 'Importer $resourceName';
  }

  @override
  String diplomacyResourceTradeExchangeOffer(int durationTurns) {
    return 'Échange de troc: ressource pour les tours $durationTurns.';
  }

  @override
  String diplomacyResourceTradeExchangeAction(
    String offeredResource,
    String requestedResource,
  ) {
    return 'Échangez $offeredResource contre $requestedResource';
  }

  @override
  String get diplomacyResourceTradeNoActiveAgreements =>
      'Pas d\'accord sur les ressources actives.';

  @override
  String get diplomacyResourceTradeImportDirection => 'Importation';

  @override
  String get diplomacyResourceTradeExportDirection => 'Exportations';

  @override
  String get diplomacyResourceTradeBarterPrice => 'troc';

  @override
  String diplomacyResourceTradeGoldPerTurnPrice(int goldPerTurn) {
    return '$goldPerTurn or/tour';
  }

  @override
  String diplomacyResourceTradeAgreementLabel(
    String direction,
    String resourceName,
    String price,
    int remainingTurns,
  ) {
    return '$direction $resourceName · $price · $remainingTurns tourne';
  }

  @override
  String get notFoundScreenTitle => 'Écran introuvable';

  @override
  String get notFoundBackToMenuAction => 'MENU';

  @override
  String get loadGameTitle => 'JEU DE PRÊT';

  @override
  String get loadGameHeaderTitle => 'Jeux enregistrés';

  @override
  String get loadGameHeaderEmptySubtitle => 'Aucun jeu n\'a encore été lancé.';

  @override
  String get loadGameHeaderSavesSubtitle =>
      'Retourner aux parties récents et continuer du tour enregistré.';

  @override
  String loadGameSavesCount(int count) {
    return 'Enregistrer: $count';
  }

  @override
  String get loadGameCorruptedStatus => 'Sauvetage corrompu';

  @override
  String get loadGameCorruptedAction => 'Indisponible';

  @override
  String get loadGameCorruptedBody =>
      'Cette sauvegarde ne peut pas être lue. Vous pouvez le supprimer de la liste.';

  @override
  String get replayTitle => 'REMPLACEMENT';

  @override
  String get replayAction => 'REMPLACEMENT';

  @override
  String get replayUnavailableAction => 'PAS DE REPLAY';

  @override
  String get replayErrorTitle => 'Rejouer indisponible';

  @override
  String replayErrorBody(String error) {
    return 'Le replay ne peut pas être ouvert: $error';
  }

  @override
  String get replayMissingInitialSnapshotBody =>
      'Ce save ne contient pas d\'instantané replay de graines. Démarrer un nouveau jeu pour enregistrer des données de replay complètes.';

  @override
  String get replayCorruptLogBody =>
      'Le journal de commande replay est incomplet ou ne peut pas être lu.';

  @override
  String replayStepCounter(int step, int total) {
    return 'Étape $step/$total';
  }

  @override
  String endTurnButtonTurnLabel(int turn) {
    return 'TURN $turn';
  }

  @override
  String replayTurnLabel(int turn) {
    return 'Tourner $turn';
  }

  @override
  String replayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count événements',
      one: '1 événement',
      zero: '0 événement',
    );
    return '$_temp0';
  }

  @override
  String get replayInitialStateLabel => 'État initial';

  @override
  String get replayPreviousAction => 'Étape précédente';

  @override
  String get replayNextAction => 'Prochaine étape';

  @override
  String get replayPlayAction => 'Lecture de replay';

  @override
  String get replayPauseAction => 'Pause rejouer';

  @override
  String get replaySpeedLabel => 'Vitesse';

  @override
  String get replayPerspectiveLabel => 'Aperçu';

  @override
  String get replayAllPlayers => 'Tous les joueurs';

  @override
  String get replayShowTurnsLabel => 'Afficher les tours';

  @override
  String get replayFreeCameraLabel => 'Caméra gratuite';

  @override
  String mapsLoadError(String error) {
    return 'Impossible de charger les cartes: $error';
  }

  @override
  String get editorMapPickerTitle => 'Cartes de l\'éditeur';

  @override
  String get editorMapPickerSubtitle =>
      'Créer de nouveaux mondes ou affiner les cartes existantes.';

  @override
  String get editorMapPickerEmptyTitle => 'Pas de cartes enregistrées';

  @override
  String get editorMapPickerEmptyMessage =>
      'Créez une nouvelle carte depuis l\'en-tête de l\'écran.';

  @override
  String get editorNewMapAction => 'Nouvelle carte';

  @override
  String get editorDeleteMapTooltip => 'Supprimer la carte';

  @override
  String get editorDeleteMapTitle => 'Supprimer la carte ?';

  @override
  String editorDeleteMapMessage(String name) {
    return 'Cela supprimera définitivement -$name-- et tous les fichiers map.';
  }

  @override
  String get editorOpenMapErrorTitle => 'Impossible d\'ouvrir la carte';

  @override
  String get editorCollapseToolbarTooltip => 'Effacer le panneau d\'éditeur';

  @override
  String get editorExpandToolbarTooltip => 'Élargir le panneau de l\'éditeur';

  @override
  String officialMapsCount(int count) {
    return 'Officiel: $count';
  }

  @override
  String yourMapsCount(int count) {
    return 'Le vôtre: $count';
  }

  @override
  String get officialMapsSection => 'Fonctionnaires';

  @override
  String get yourMapsSection => 'Vos cartes';

  @override
  String get playAction => 'Jouer';

  @override
  String get editAction => 'Modifier';

  @override
  String get noMapsTitle => 'Pas de cartes';

  @override
  String get noMapsMessage =>
      'Aucune carte n\'a été trouvée pour lancer un jeu.';

  @override
  String get gameLengthLabel => 'Longueur du jeu';

  @override
  String get gameLengthPresetHint => 'Préréglage du jeu';

  @override
  String get gameLengthPresetUnlimited => 'Illimité';

  @override
  String get gameLengthPresetShort60 => 'Court';

  @override
  String get gameLengthPresetNormal90 => 'Normal';

  @override
  String get gameLengthPresetStandard60 => 'Standard 60 min';

  @override
  String get gameLengthPresetLong120 => 'Longue';

  @override
  String get gameLengthPresetVeryLong => 'Très longue';

  @override
  String get gameLengthUnlimitedSummary =>
      'Pas de limite de tour - rythme de jeu actuel';

  @override
  String gameLengthTimedSummary(int minutes, int turns) {
    return 'Cible $minutes min - limite de tour $turns';
  }

  @override
  String get gameLengthScoreFallbackOn => 'avec recul de score';

  @override
  String get gameLengthScoreFallbackOff => 'sans retour de score';

  @override
  String get aiDifficultyLabel => 'Problèmes d\'IA';

  @override
  String get aiDifficultyEasy => 'Facile';

  @override
  String get aiDifficultyNormal => 'Normal';

  @override
  String get aiDifficultyHard => 'Dur';

  @override
  String get aiDifficultyVeryHard => 'Très dur';

  @override
  String gameLengthVictoryRules(
    String controlPercent,
    int holdTurns,
    String fallback,
  ) {
    return 'Conquête + domination Tours $controlPercent%/$holdTurns - $fallback';
  }

  @override
  String get mapValidationErrorTitle => 'Correction des besoins de la carte';

  @override
  String get mapValidationLoadingTitle => 'Vérification de la carte';

  @override
  String get mapValidationWarningTitle =>
      'La carte peut être trop lente pour ce préréglage';

  @override
  String mapValidationLoadError(String error) {
    return 'Impossible de vérifier la carte: $error';
  }

  @override
  String get mapValidationLoadingMessage =>
      'Valider les départs, les ressources et le premier contact.';

  @override
  String get mapValidationIssueSlowFirstContact =>
      'Les positions de départ sont éloignées; 60 min peuvent retarder le premier contact trop.';

  @override
  String get mapValidationIssueLargeMap =>
      'La carte a de nombreuses tuiles par joueur; ajoutez des joueurs ou choisissez un jeu plus long.';

  @override
  String get mapValidationIssueInvalidPlayerCount =>
      'Le nombre de joueurs ne correspond pas à la plage prise en charge par cette carte.';

  @override
  String get mapValidationIssueNoTiles => 'La carte n\'a pas de carreaux.';

  @override
  String get mapValidationIssueLowPassableTileRatio =>
      'La carte a trop peu de tuiles passables par les unités terrestres.';

  @override
  String get mapValidationIssueLowFoodResourceDensity =>
      'La carte a trop peu de ressources alimentaires pour ce joueur compte.';

  @override
  String get mapValidationIssueLowStrategicResourceDensity =>
      'La carte a trop peu de ressources stratégiques.';

  @override
  String get mapValidationIssueLowLuxuryResourceDensity =>
      'La carte a trop peu de ressources de luxe.';

  @override
  String get mapValidationIssueStartSiteNotFoundable =>
      'Le colon débutant ne peut pas trouver une ville sur sa tuile.';

  @override
  String get mapValidationIssueStartSiteLowLandRing =>
      'Le départ a trop peu de tuiles passables dans la première bague.';

  @override
  String get mapValidationIssueStartSiteLowFood =>
      'Le départ n\'a aucune ressource alimentaire visible à proximité.';

  @override
  String get mapValidationIssueStartSiteLowCityControl =>
      'Le départ a trop peu de tuiles légales pour le contrôle initial de la ville.';

  @override
  String get mapValidationIssueStartSitesTooClose =>
      'Les départs des joueurs sont trop proches les uns des autres.';

  @override
  String lobbyMapPlayersSummary(String mapName, int playerCount) {
    return '$mapName - joueurs $playerCount';
  }

  @override
  String get lobbyHeaderTitle => 'Préparer le tableau';

  @override
  String get lobbyHeaderSubtitle =>
      'Confirmer la civilisation d\'abord, puis régler le partie et les sièges avant le premier tour.';

  @override
  String get lobbyCivilizationTitle => 'Choisir la civilisation';

  @override
  String get lobbyCivilizationSubtitle =>
      'C\'est l\'identité du joueur pour le tour d\'ouverture.';

  @override
  String get lobbyStepCivilization => 'Civilisation';

  @override
  String get lobbyStepSetup => 'Configuration';

  @override
  String get lobbyStepOnline => 'En ligne';

  @override
  String get lobbyStepPlayers => 'Joueurs';

  @override
  String get lobbySetupTitle => 'Configuration de la partie';

  @override
  String get lobbySetupSubtitle =>
      'Nommez le jeu, choisissez le rythme et vérifiez si la carte correspond au nombre de joueurs sélectionné.';

  @override
  String get lobbyPlayersSetupTitle => 'Les joueurs à la table';

  @override
  String get lobbyPlayersSetupSubtitle =>
      'Le premier joueur prend le tour d\'ouverture. Des sièges supplémentaires peuvent être des personnes sur cet appareil ou IA.';

  @override
  String get lobbyPlayerYou => 'Toi';

  @override
  String get lobbyPlayerHost => 'Hôte';

  @override
  String get lobbyPlayerReady => 'Prêt';

  @override
  String get lobbyPlayerConnected => 'connecté';

  @override
  String get lobbyPlayerConnecting => 'connexion';

  @override
  String get lobbyPlayerReconnecting => 'reconnexion';

  @override
  String get lobbyPlayerOffline => 'hors ligne';

  @override
  String lobbyPlayerOpenSlot(int slotNumber) {
    return 'Siège ouvert $slotNumber';
  }

  @override
  String get lobbyPlayerRequiredSlot => 'Besoin de commencer';

  @override
  String get lobbyPlayerOptionalSlot => 'Peut se joindre avant le début';

  @override
  String get playerKindHuman => 'Humain';

  @override
  String get playerKindAi => 'IA';

  @override
  String get multiplayerServerTitle => 'Serveur de jeu en ligne';

  @override
  String get connectAction => 'Connexion';

  @override
  String get refreshAction => 'Actualiser';

  @override
  String get createMatchAction => 'Créer une partie';

  @override
  String get noOpenMatches => 'Pas de partie ouvert';

  @override
  String get matchStatusRunning => 'Prêt';

  @override
  String get matchStatusFinished => 'Terminé';

  @override
  String get matchStatusAbandoned => 'Abandonné';

  @override
  String matchPlayersCount(int players, int maxPlayers) {
    return 'joueurs $players/$maxPlayers';
  }

  @override
  String matchReadyCount(int readyPlayers, int players) {
    return '$readyPlayers/$players prêt';
  }

  @override
  String matchTurnInfo(String mapName, String status, int turn) {
    return '$mapName - $status - tourner $turn';
  }

  @override
  String openMatchInfo(String mapName, int players, int maxPlayers, int turn) {
    return '$mapName - $players/$maxPlayers - tourner $turn';
  }

  @override
  String get enterMatchAction => 'Entrez';

  @override
  String get hideMatchAction => 'Masquer';

  @override
  String get joinMatchAction => 'Rejoignez';

  @override
  String get cancelAction => 'ANNULATION';

  @override
  String get copyAction => 'Copier';

  @override
  String get shareAction => 'Partager';

  @override
  String get multiplayerHomeSubtitle =>
      'Choisissez une file d\'attente rapide ou un code privé pour les amis.';

  @override
  String get multiplayerProfileTitle => 'Votre profil';

  @override
  String get multiplayerProfileSubtitle =>
      'Définissez le nom et la civilisation que vous utiliserez dans les parties en ligne.';

  @override
  String get multiplayerProfileOptionsSubtitle =>
      'Votre surnom est utilisé dans les parties multijoueurs et doit être unique.';

  @override
  String get multiplayerProfileSaveAction => 'Enregistrer le pseudonyme';

  @override
  String get multiplayerProfileSaved => 'Pseudo sauvegardé.';

  @override
  String get multiplayerLobbyHeaderTitle => 'Lobby en ligne';

  @override
  String get multiplayerLobbyHeaderSubtitle =>
      'Choisissez la civilisation d\'abord, puis entrez le jeu rapide ou créez une table privée. La carte est sélectionnée automatiquement.';

  @override
  String get multiplayerCountryPickTitle => 'Choisir la civilisation';

  @override
  String get multiplayerCountryPickSubtitle =>
      'C\'est le choix clé avant d\'entrer dans la file d\'attente. Les cartes multijoueur sont sélectionnées au hasard.';

  @override
  String get multiplayerRandomMapLabel => 'Carte aléatoire';

  @override
  String get multiplayerNicknameLabel => 'Pseudo';

  @override
  String get multiplayerQuickplayTitle => 'Jeu rapide';

  @override
  String get multiplayerQuickplaySubtitle =>
      'Trouvez les joueurs automatiquement et démarrez à partir de 2 joueurs.';

  @override
  String get multiplayerCreatePrivateTitle => 'Créer un code';

  @override
  String get multiplayerCreatePrivateSubtitle =>
      'Partie privé sans limite de temps, seulement pour les amis.';

  @override
  String get multiplayerJoinPrivateTitle => 'Rejoignez le code';

  @override
  String get multiplayerJoinPrivateSubtitle =>
      'Entrez le code d\'un ami et attendez l\'hôte.';

  @override
  String get multiplayerQueueReadyTitle => 'C\'est prêt';

  @override
  String get multiplayerQueueSearchingTitle => 'Recherche de joueurs';

  @override
  String get multiplayerQueueCountdownTitle => 'À partir de bientôt';

  @override
  String get multiplayerQueueConnectingSubtitle =>
      'Se connecter au serveur et chercher une file d\'attente.';

  @override
  String multiplayerQueueWaitingForPlayers(int minPlayers) {
    return 'Attendre au moins les joueurs $minPlayers.';
  }

  @override
  String get multiplayerQueuePreparingStart =>
      'Les joueurs ont trouvé. Préparation du début du partie.';

  @override
  String get multiplayerQueueStartingNow => 'Début du partie...';

  @override
  String multiplayerQueueStartingIn(int seconds) {
    return 'À partir de $seconds. D\'autres joueurs peuvent encore se joindre.';
  }

  @override
  String get multiplayerPrivateTitle => 'Les amis correspondent';

  @override
  String get multiplayerPrivateHostReady =>
      'Tu peux commencer le partie maintenant.';

  @override
  String get multiplayerPrivateWaitingForHost =>
      'Attendre que l\'hôte démarre le partie.';

  @override
  String get multiplayerJoinCodeHelp =>
      'Entrez le code que vous avez reçu d\'un ami.';

  @override
  String get multiplayerInviteCodeHint => 'Code correspondant';

  @override
  String get multiplayerInviteCodeLabel => 'Code correspondant';

  @override
  String get multiplayerInviteCopied => 'Code de partie copié.';

  @override
  String multiplayerInviteShareText(String inviteCode) {
    return 'Rejoignez mon partie AONW. Code: $inviteCode';
  }

  @override
  String get multiplayerInviteCodeRequired => 'Saisissez un code de partie.';

  @override
  String get multiplayerMapNotReady =>
      'Cette carte n\'est pas prête pour multijoueur.';

  @override
  String multiplayerRequestRejected(int statusCode) {
    return 'Le serveur a rejeté la requête ($statusCode).';
  }

  @override
  String multiplayerRequestRejectedWithReason(int statusCode, String reason) {
    return 'Le serveur a rejeté la requête ($statusCode: $reason).';
  }

  @override
  String multiplayerConnectionError(String host) {
    return 'Impossible de se connecter à $host. Vérifiez votre connexion Internet et essayez à nouveau.';
  }

  @override
  String get multiplayerSignInRequired =>
      'Connectez-vous ou créez un compte pour jouer au multijoueur.';

  @override
  String get multiplayerSessionExpired =>
      'Votre session multijoueur a expiré. Connectez-vous encore et réessayez.';

  @override
  String get multiplayerAccountTitle => 'Compte multijoueur';

  @override
  String get multiplayerAccountSubtitle =>
      'Connectez-vous ou créez un compte pour continuer.';

  @override
  String get multiplayerAccountEmailLabel => 'Courriel';

  @override
  String get multiplayerAccountPasswordLabel => 'Mot de passe';

  @override
  String get multiplayerAccountSignInTab => 'Connexion';

  @override
  String get multiplayerAccountCreateTab => 'Créer un compte';

  @override
  String get multiplayerAccountSignInAction => 'Connexion';

  @override
  String get multiplayerAccountCreateAction => 'Créer un compte';

  @override
  String get multiplayerAccountSignOutAction => 'Déconnexion';

  @override
  String get multiplayerAccountSignedOut => 'Signée en multijoueur.';

  @override
  String get multiplayerAccountInvalidEmail =>
      'Saisissez une adresse email valide.';

  @override
  String get multiplayerAccountInvalidCredentials =>
      'Courriel ou mot de passe incorrect.';

  @override
  String get multiplayerAccountExists =>
      'Un compte avec ce courriel existe déjà.';

  @override
  String get multiplayerAccountWeakPassword =>
      'Le mot de passe doit être d\'au moins 8 caractères.';

  @override
  String get multiplayerAccountInvalidNickname =>
      'Utilisez 3-24 lettres, chiffres, espaces,   ou -.';

  @override
  String get multiplayerAccountNicknameTaken => 'Ce surnom est déjà pris.';

  @override
  String get multiplayerAccountGenericError =>
      'Je ne pouvais pas authentifier. Essaie encore.';

  @override
  String get multiplayerMatchUnavailable => 'Ce partie n\'est plus disponible.';

  @override
  String get multiplayerMatchFull => 'Ce partie est plein.';

  @override
  String get multiplayerCountryUnavailable =>
      'Plusieurs joueurs ont choisi votre civilisation. Essaie un autre.';

  @override
  String get multiplayerMatchNotReady => 'Le partie n\'est pas encore prêt.';

  @override
  String get multiplayerMatchAccessDenied =>
      'Vous n\'êtes pas un joueur dans ce partie.';

  @override
  String get multiplayerQueueGenericError =>
      'Impossible d\'entrer la file multijoueur. Essaie encore.';

  @override
  String get multiplayerResumeAction => 'Reprendre le jeu';

  @override
  String get multiplayerResumeSublabel =>
      'Retour à la dernière session multijoueur';

  @override
  String get multiplayerResumeLoading => 'Connexion pour correspondre...';

  @override
  String get multiplayerResumeFailed =>
      'Impossible de reprendre la dernière session multijoueur.';

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
  String get mapViewModeTooltip => 'Modifier le mode de vue de la carte';

  @override
  String get mapViewGraphicUnavailableTooltip =>
      'Le mode graphique est indisponible pour cette carte';

  @override
  String get mapViewModeGraphic => 'Graphique';

  @override
  String get mapViewModeTiles => 'Carreaux';

  @override
  String get gameOptionTerrain => 'Terrain';

  @override
  String get gameOptionResources => 'Ressources';

  @override
  String get gameOptionHeight => 'Hauteur';

  @override
  String get gameOptionCitySites => 'Sites urbains';

  @override
  String get gameOptionCityGrowth => 'Croissance des villes';

  @override
  String get gameOptionShowHexes => 'Afficher les hexagones';

  @override
  String get gameOptionShowHeight => 'Afficher la hauteur';

  @override
  String get gameOptionDiceTest => 'Essai de dés';

  @override
  String get gameOptionAutoActionFlow => 'Achèvement de l\'action automatique';

  @override
  String get gameOptionAutoTurnFlow => 'Exécution automatique';

  @override
  String get helpPopupsTitle => 'Conseils';

  @override
  String get autoTurnHintTitle => 'Exécution automatique';

  @override
  String get autoTurnHintBody =>
      'L\'achèvement automatique du tour soumet le tour quand il ne reste pas d\'actions importantes. L\'achèvement de l\'action automatique peut être contrôlé séparément dans les options de carte.';

  @override
  String get autoTurnHintEnableAction => 'Activer';

  @override
  String get autoTurnHintDisableAction => 'Désactiver';

  @override
  String get autoTurnHintStatusOn => 'Activé';

  @override
  String get autoTurnHintStatusOff => 'Handicapé';

  @override
  String get autoTurnHintMinimizedSubtitle =>
      'Toggle rapide pour le flux de tour automatique.';

  @override
  String visibilityShowAction(String label) {
    return 'Afficher $label';
  }

  @override
  String visibilityHideAction(String label) {
    return 'Masquer $label';
  }

  @override
  String get resignAction => 'Démissionner';

  @override
  String get resignMatchTitle => 'Démissionner du partie ?';

  @override
  String get resignMatchMessage => 'Le partie sera terminé.';

  @override
  String get resignMatchError => 'Je ne pouvais pas démissionner du partie.';

  @override
  String get creditsTitle => 'Crédits';

  @override
  String creditsCreatedBy(String name) {
    return 'Créé par $name';
  }

  @override
  String get deleteGameTitle => 'Supprimer le jeu';

  @override
  String deleteGameMessage(String name) {
    return 'Supprimer \"$name\" ? Cela ne peut pas être annulé.';
  }

  @override
  String get deleteAction => 'DELETE';

  @override
  String get retryAction => 'RETRAITE';

  @override
  String get noSavedGames => 'Pas de jeux enregistrés.';

  @override
  String get resumeAction => 'RÉSUME';

  @override
  String get newGameAction => 'NOUVELLE PARTIE';

  @override
  String get turnActionButtonLabel => 'Décision';

  @override
  String get endTurnButtonLabel => 'Fin du tour';

  @override
  String get waitingTurnButtonLabel => 'Attendre';

  @override
  String get waitingForPlayersTooltip => 'Attendre d\'autres joueurs';

  @override
  String submitTurnTooltip(int turn) {
    return 'Soumettre l\'état de préparation au tour $turn';
  }

  @override
  String endTurnTooltip(int turn) {
    return 'Fin du tour $turn';
  }

  @override
  String get nextActionTooltip => 'Aller à la prochaine action';

  @override
  String nextActionWithCountTooltip(int count) {
    return 'Aller à l\'action suivante ($count à gauche)';
  }

  @override
  String get turnActionListTooltip => 'Choisissez une action dans la liste';

  @override
  String get hudActionDeckCollapseTooltip =>
      'Réduire la barre d\'outils inférieure';

  @override
  String get hudActionDeckExpandTooltip =>
      'Élargir la barre d\'outils inférieure';

  @override
  String get turnActionUnitKind => 'Unité';

  @override
  String get turnActionCityProductionKind => 'Ville';

  @override
  String get turnActionResearchKind => 'Recherche';

  @override
  String turnActionCityProductionLabel(String cityName) {
    return 'Production $cityName';
  }

  @override
  String get turnActionResearchLabel => 'Choisir la recherche';

  @override
  String turnLabel(int turn) {
    return 'TURN $turn';
  }

  @override
  String loadGameError(String error) {
    return 'Erreur de chargement: $error';
  }

  @override
  String get backAction => 'Précédent';

  @override
  String get continueAction => 'Continuer';

  @override
  String get gameLoadingTitle => 'Chargement du monde';

  @override
  String get gameLoadingMessage =>
      'Préparer la carte, les unités et l\'interface. Le jeu apparaîtra une fois les actifs prêts.';

  @override
  String get firstTurnTutorialPopupTitle => 'Tutoriel';

  @override
  String get firstTurnTutorialPopupSubtitle => 'Guide du premier tour';

  @override
  String firstTurnTutorialSemantics(String title) {
    return 'Premier tour: $title';
  }

  @override
  String firstTurnCoachmarkProgressLabel(int current, int total) {
    return 'Étape $current/$total';
  }

  @override
  String get firstTurnCoachmarkMinimizeTooltip => 'Minimiser';

  @override
  String get firstTurnCoachmarkSkipAction => 'Sauter';

  @override
  String get firstTurnCoachmarkNextAction => 'Suivant';

  @override
  String get firstTurnCoachmarkDoneAction => 'Fait';

  @override
  String get firstTurnCoachmarkSelectionTitle => 'Étape 1: lire la sélection';

  @override
  String get firstTurnCoachmarkSelectionBody =>
      'Le jeu commence par sélectionner automatiquement votre première unité. Le panneau inférieur vous indique ce que vous commandez, combien d\'actions restent, et quels ordres vous pouvez donner maintenant.';

  @override
  String get firstTurnCoachmarkSelectionBodyUnit =>
      'La barre d\'outils inférieure décrit l\'unité sélectionnée: type, mouvement, file d\'attente d\'action et commandes disponibles. Utilisez-le pour entrer en mode Déplacer et l\'annuler lorsque vous voulez des touches hexagonales pour revenir à l\'inspection.';

  @override
  String get firstTurnCoachmarkSelectionBodyCity =>
      'Vous avez une ville sélectionnée. Le panneau inférieur montre sa production, sa population, ses bâtiments et ses décisions économiques. C\'est un contexte différent des commandes unitaires, donc le tutoriel parlera de la ville.';

  @override
  String get firstTurnCoachmarkSelectionBodyNone =>
      'Lorsque rien n\'est sélectionné, le panneau inférieur affiche l\'état général du tour. Appuyez sur l\'une de vos unités ou villes pour voir les commandes et les informations concrètes.';

  @override
  String get firstTurnCoachmarkResourcesTitle =>
      'Étape 2: Vérifiez votre empire';

  @override
  String get firstTurnCoachmarkResourcesBody =>
      'La barre supérieure montre le tour, l\'or, la science et les ressources. L\'or soutient l\'économie, la science stimule la recherche, et les ressources suggèrent ce qui vaut la peine de construire.';

  @override
  String get firstTurnCoachmarkMenuTitle =>
      'Étape 3: apprendre le menu de gauche';

  @override
  String get firstTurnCoachmarkMenuBody =>
      'Le menu de gauche rassemble des vues que vous revisitez à chaque tour: options de carte, réponses popup minimisées, objectifs, journal, recherche et empire. Appuyez longuement sur le bouton du menu pour faire tomber le rail, puis appuyez sur le bouton unique pour l\'ouvrir à nouveau.';

  @override
  String get firstTurnCoachmarkActionTitle => 'Étape 4: donner le bon ordre';

  @override
  String get firstTurnCoachmarkActionBodyActive =>
      'Si le colon se tient sur une bonne tuile, utilisez l\'action de la ville trouvée. Si l\'emplacement est faible, déplacer l\'unité et révéler le terrain. Le mouvement et les actions spéciales passent le tour de cette unité.';

  @override
  String get firstTurnCoachmarkActionBodyWaiting =>
      'Quand une unité a un ordre, il apparaît ici. Dans les premiers tours, passer à travers les unités et les villes un par un jusqu\'à ce qu\'aucune décision importante ne soit laissée derrière.';

  @override
  String get firstTurnCoachmarkActionBodySettler =>
      'Le colon décide du début de votre empire. Si la tuile offre de la croissance, la production, et la possibilité de se développer, trouvé une ville. Si le terrain est faible, déplacer le colon et inspecter les terres avoisinantes d\'abord.';

  @override
  String get firstTurnCoachmarkActionBodyWorker =>
      'Un travailleur n\'a pas trouvé de villes. Son travail est d\'améliorer les tuiles à l\'intérieur des frontières de la ville: les fermes contribuent à la croissance, les mines stimulent la production et les ressources renforcent l\'économie.';

  @override
  String get firstTurnCoachmarkActionBodyUnit =>
      'Pour les unités de combat et de scoutisme, le mouvement, la vision et la sécurité comptent le plus. Reveal terrain, protéger les frontières de la ville, et l\'attaque seulement lorsque le résultat prévu est favorable.';

  @override
  String get firstTurnCoachmarkActionBodyCity =>
      'Avec une ville sélectionnée, cette zone mène à la production et à la gestion. Choisissez une cible de construction, vérifiez la croissance de la ville, et empêchez la ville de rester inactif.';

  @override
  String get firstTurnCoachmarkResearchTitle => 'Étape 5: Choisir la recherche';

  @override
  String get firstTurnCoachmarkResearchBody =>
      'Ouvrir la recherche avant de terminer le tour. L\'agriculture soutient la croissance, l\'exploitation minière stimule la production, et la chasse améliore le scoutisme et la défense. Plus important encore, la science ne devrait pas courir sans cible.';

  @override
  String get firstTurnCoachmarkResearchBodyAvailable =>
      'La recherche est prête à choisir. Ouvrir la recherche avant de terminer le tour: l\'agriculture soutient la croissance, l\'exploitation minière stimule la production et la chasse améliore le scoutisme et la défense.';

  @override
  String get firstTurnCoachmarkCityTitle => 'Étape 6: mettre en place la ville';

  @override
  String get firstTurnCoachmarkCityBody =>
      'Après avoir fondé la capitale, choisissez la production. Un travailleur développe des tuiles, un guerrier sécurise la zone et les bâtiments renforcent l\'économie. La ville devrait toujours construire quelque chose.';

  @override
  String get firstTurnCoachmarkCityBodySelected =>
      'Voici le panneau de la ville. Vérifier la production, la croissance, les bâtiments et les projets disponibles. La règle principale pour les nouveaux tours: chaque ville devrait avoir une cible de production.';

  @override
  String get firstTurnCoachmarkCityBodyNeedsProduction =>
      'Une de vos villes attend la production. Utilisez le bouton d\'action ou sélectionnez la ville, choisissez une unité, un bâtiment ou un projet, puis terminez le tour.';

  @override
  String get firstTurnCoachmarkCityBodyExisting =>
      'Vos villes ont déjà une production assignée. Plus tard, retournez ici pour observer la croissance, les bâtiments, la spécialisation et les besoins de défense.';

  @override
  String get firstTurnCoachmarkCityBodyFuture =>
      'Après avoir trouvé la première ville, vous retournerez ici pour choisir la production. Un travailleur développe des tuiles, un guerrier sécurise la zone et les bâtiments renforcent l\'économie.';

  @override
  String get firstTurnCoachmarkActionFlowTitle =>
      'Étape 7: effacer la file d\'attente d\'action';

  @override
  String get firstTurnCoachmarkActionFlowBodyReady =>
      'Toutes les décisions clés pour ce tour sont prêtes. Avant de terminer le tour, confirmez rapidement que la recherche et la production urbaine ont toutes deux une cible.';

  @override
  String get firstTurnCoachmarkActionFlowBodyPending =>
      'Le bouton action mène à l\'unité suivante, la ville, ou le choix manquant. Continuez à appuyer jusqu\'à ce que le jeu montre qu\'il est sûr de terminer le tour.';

  @override
  String get firstTurnCoachmarkEndTurnTitle =>
      'Étape 8: terminer le tour et répéter';

  @override
  String get firstTurnCoachmarkEndTurnBody =>
      'Quand rien n\'a besoin de votre réponse, finissez le tour. Le rythme des tours suivants est le même: ressources, unités, ville, recherche, puis fin tour.';

  @override
  String get firstTurnCoachmarkVictoryBody =>
      'Vous pouvez gagner par domination ou par artefacts: placer 6 artefacts uniques dans vos villes et tenir la collection pour 5 tours.';

  @override
  String get firstTurnCoachmarkHexTapBody =>
      'Cliquez ou tapez plusieurs fois sur le même hexagone pour faire cycler ses informations: sélection des tuiles, artefact, objectif de la carte et description de l\'hexagone.';

  @override
  String get gameLoadMapErrorTitle => 'Impossible de charger la carte';

  @override
  String gameLoadMapErrorMessage(String mapName, String error) {
    return 'Impossible de charger la carte \"$mapName\": $error';
  }

  @override
  String get gameOutcomeVictoryTitle => 'Victoire';

  @override
  String get gameOutcomeDefeatTitle => 'Défaut';

  @override
  String get gameOutcomeDrawTitle => 'Dessiner';

  @override
  String get gameOutcomeCompleteTitle => 'Jeu terminé';

  @override
  String get gameOutcomeConditionConquest => 'Conquête';

  @override
  String get gameOutcomeConditionScore => 'Score';

  @override
  String get gameOutcomeConditionScoreDraw => 'Tirage des points';

  @override
  String get gameOutcomeConditionDomination => 'Domination';

  @override
  String get gameOutcomeConquestNoWinner => 'Un empire reste sur la carte.';

  @override
  String gameOutcomeConquestWinner(String winner) {
    return '$winner est le dernier empire sur la carte.';
  }

  @override
  String get gameOutcomeScoreNoWinner =>
      'La limite de tour a décidé le résultat.';

  @override
  String gameOutcomeScoreWinner(String winner) {
    return '$winner gagne après la limite de tour.';
  }

  @override
  String get gameOutcomeScoreDrawSubtitle =>
      'Limite de tour atteinte. Le score le plus élevé est égal.';

  @override
  String get gameOutcomeDominationNoWinner =>
      'Le contrôle des cartes a été maintenu.';

  @override
  String gameOutcomeDominationWinner(String winner) {
    return '$winner détient la domination territoriale.';
  }

  @override
  String get gameOutcomeWinnerMetric => 'Gagnant';

  @override
  String get gameOutcomeConditionMetric => 'État';

  @override
  String get gameOutcomeEliminationMetric => 'Élimination';

  @override
  String get gameOutcomeMapControlMetric => 'Contrôle des cartes';

  @override
  String get gameOutcomeHoldMetric => 'Attendez';

  @override
  String get gameOutcomeThresholdMetric => 'Seuil';

  @override
  String gameOutcomeTurnsValue(int held, int required) {
    return 'Tours $held/$required';
  }

  @override
  String get victoryConquestPrimary => 'Conquête';

  @override
  String get victoryGoalCompact => 'Objectif';

  @override
  String get victoryNoLimit => 'Aucune limite';

  @override
  String get victoryConquestTooltip =>
      'Objectif: éliminer les rivaux. Pas de limite de tour.';

  @override
  String get victoryLimitLabel => 'Limite';

  @override
  String get victoryNoneValue => 'Aucune';

  @override
  String get victoryScoreCapPrimary => 'La PAC SCORE';

  @override
  String victoryScoreRemainingPrimary(int turns) {
    return 'SCORE ${turns}T';
  }

  @override
  String get victoryScoreCapCompact => 'Politique agricole';

  @override
  String victoryTurnsCompact(int turns) {
    return '${turns}T';
  }

  @override
  String victoryTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tours',
      one: '1 tour',
    );
    return '$_temp0';
  }

  @override
  String get victoryRemainingLabel => 'Reste';

  @override
  String get victoryScoreLeaderLabel => 'Leader du score';

  @override
  String victoryScoreDrawLabel(int score) {
    return 'VÉHICULE $score';
  }

  @override
  String victoryScoreLimitReachedTooltip(int turnLimit) {
    return 'Limite de tour $turnLimit atteint. Le score décide du résultat.';
  }

  @override
  String victoryScoreFallbackTooltip(int remainingTurns, int turnLimit) {
    return 'Recul des scores dans les tours $remainingTurns. Limite: $turnLimit.';
  }

  @override
  String victoryLeaderTooltip(String leader) {
    return 'Chef: $leader.';
  }

  @override
  String victoryDominationTooltip(
    String leader,
    String control,
    String required,
    String hold,
  ) {
    return 'Domination: $leader contrôle $control% de la carte. Seuil: $required%, tenir: $hold.';
  }

  @override
  String get victoryLeaderLabel => 'Chef';

  @override
  String get victoryControlLabel => 'Contrôle';

  @override
  String get victoryHoldLabel => 'Attendez';

  @override
  String get victoryYouLabel => 'Toi';

  @override
  String get victoryPressureLabel => 'Pression';

  @override
  String get victoryFallbackLabel => 'Retour';

  @override
  String victoryYourGoalGainControl(int points) {
    return 'Votre objectif: gagner $points pp plus de contrôle de carte.';
  }

  @override
  String get victoryYourGoalReady =>
      'Votre but: la condition de domination est prête à être résolue.';

  @override
  String victoryYourGoalHold(String turns) {
    return 'Votre objectif: maintenez le seuil pour $turns plus.';
  }

  @override
  String victoryLeaderAboveThreshold(String leader) {
    return '$leader est au-dessus du seuil; briser ce contrôle avant que le but soit maintenu.';
  }

  @override
  String victoryYourProgress(String control, String required) {
    return 'Vos progrès: $control% / $required%.';
  }

  @override
  String victoryPressureReachThreshold(int points) {
    return 'Atteindre le seuil: manquant $points pp';
  }

  @override
  String get victoryConditionReady => 'État prêt';

  @override
  String victoryPressureHold(String turns) {
    return 'Tenez pour $turns';
  }

  @override
  String victoryPressureLeaderHolding(String leader, String turns) {
    return '$leader au-dessus du seuil: $turns';
  }

  @override
  String victoryPressureYourGap(int points) {
    return 'Votre objectif: manquant $points pp';
  }

  @override
  String victoryPressureLeaderGap(String leader, int points) {
    return '$leader conduits: manquant $points pp';
  }

  @override
  String victoryThreatApproaching(
    String player,
    String control,
    String required,
    int points,
  ) {
    return 'Rival approche la domination: $player contrôle $control% au seuil $required%; il manque $points pp.';
  }

  @override
  String victoryThreatHolding(String player, String hold) {
    return 'Rival détient le seuil de domination: $player $hold.';
  }

  @override
  String victoryThreatImminent(String player, String hold) {
    return 'Rival est proche de la domination: $player $hold.';
  }

  @override
  String victoryThreatPressureApproaching(String player, int points) {
    return '$player près du seuil: manquant $points pp';
  }

  @override
  String victoryThreatPressureBreak(String player, String turns) {
    return 'Break $player: $turns';
  }

  @override
  String get victoryBelowThreshold => 'au-dessous du seuil';

  @override
  String victoryHoldProgress(int held, int required) {
    return 'Tours $held/$required';
  }

  @override
  String victoryHoldCompact(int held, int required) {
    return '$held/${required}T';
  }

  @override
  String get victoryReady => 'Prêt';

  @override
  String victoryRemainingTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tours restants',
      one: '1 tour restant',
    );
    return '$_temp0';
  }

  @override
  String get returnToMenuAction => 'Retour au menu';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'hier';

  @override
  String get objectivesPanelTitle => 'OBJECTIFS';

  @override
  String get objectivesCloseTooltip => 'Objectifs étroits';

  @override
  String get objectivesMenuClosePrefix => 'Objectifs étroits';

  @override
  String get objectivesMenuOpenPrefix => 'Objectifs';

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
      other: '$count objectifs',
      one: '1 objectif',
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
  String get objectivesMenuDescriptorDominationThreat => 'menace de domination';

  @override
  String get objectivesMenuDescriptorScoreLead => 'défense principale';

  @override
  String get objectivesMenuDescriptorScorePressure => 'pression nominale';

  @override
  String get objectivesMenuDescriptorActiveObjective => 'objectif actif';

  @override
  String get objectiveMicroTooltipLabel => 'Pourquoi';

  @override
  String get objectiveOverviewGuidanceLabel => 'OBJECTIF ACTIF';

  @override
  String get objectiveOverviewStrategicLabel => 'URGENT';

  @override
  String get objectiveOverviewScoreCatchUpLabel => 'PRESSION SCORE';

  @override
  String get objectiveOverviewScoreProtectLabel => 'DÉFENSE';

  @override
  String get objectiveOverviewDominationHoldLabel => 'DOMAINE';

  @override
  String get objectiveOverviewDominationThreatLabel =>
      'PROTECTION DE L\'INTÉRIEUR';

  @override
  String objectiveOverviewTitleLabel(String title) {
    return 'Priorité absolue: $title';
  }

  @override
  String objectiveOverviewProgressLabel(String progress) {
    return 'Progrès $progress';
  }

  @override
  String get objectivePhaseFoundation => 'Fondation';

  @override
  String get objectivePhaseExpansion => 'Expansion';

  @override
  String get objectivePhasePressure => 'Pression';

  @override
  String get objectivePhaseEndgame => 'Fin du jeu';

  @override
  String get objectiveChooseResearchTitle => 'Choisir la recherche';

  @override
  String get objectiveChooseResearchHint =>
      'Réglez votre direction de développement avant la fin du premier tour.';

  @override
  String get objectiveChooseResearchReward => '+ tempo scientifique';

  @override
  String get objectiveChooseResearchTooltip =>
      'La recherche tourne chaque tour suivant vers une voie de développement spécifique.';

  @override
  String get objectiveFoundCapitalTitle => 'Trouvé ta première ville';

  @override
  String get objectiveFoundCapitalHint =>
      'Votre colon devrait rapidement transformer un bon terrain en capitale.';

  @override
  String get objectiveFoundCapitalReward => '+ base de production';

  @override
  String get objectiveFoundCapitalTooltip =>
      'La capitale libère la production, la croissance et la portée territoriale.';

  @override
  String get objectiveExploreNearbyTitle => 'Explorez les terres voisines';

  @override
  String get objectiveExploreNearbyHint =>
      'Votre guerrier devrait révéler les ressources et les sites de la ville.';

  @override
  String get objectiveExploreNearbyReward => '+ meilleures décisions';

  @override
  String get objectiveExploreNearbyTooltip =>
      'Le dépistage précoce aide à choisir les sites de la ville et à éviter les déplacements aveugles.';

  @override
  String get objectiveQueueWorkerTitle => 'Demander un travailleur';

  @override
  String get objectiveQueueWorkerHint =>
      'Un travailleur transforme la nourriture et la production sur la carte en un véritable avantage.';

  @override
  String get objectiveQueueWorkerReward => '+ développement sur le terrain';

  @override
  String get objectiveQueueWorkerTooltip =>
      'Un travailleur transforme de bonnes tuiles en croissance régulière des ressources.';

  @override
  String get objectiveImproveFirstHexTitle => 'Améliorez votre première tuile';

  @override
  String get objectiveImproveFirstHexHint =>
      'La première amélioration devrait soutenir la nourriture, la production ou l\'or.';

  @override
  String get objectiveImproveFirstHexReward => '+ une économie plus forte';

  @override
  String get objectiveImproveFirstHexTooltip =>
      'La première amélioration montre quelle partie de l\'économie de la ville devrait connaître la croissance la plus rapide.';

  @override
  String get objectiveFoundSecondCityTitle => 'Trouvé une deuxième ville';

  @override
  String get objectiveFoundSecondCityHint =>
      'Une seconde colonie ouvre l\'expansion sans inonder la carte avec des unités.';

  @override
  String get objectiveFoundSecondCityReward => '+ échelle de l\'empire';

  @override
  String get objectiveFoundSecondCityTooltip =>
      'Une deuxième ville augmente le rythme de production sans attendre une capitale.';

  @override
  String get objectiveBuildFirstBuildingTitle =>
      'Construisez votre premier bâtiment';

  @override
  String get objectiveBuildFirstBuildingHint =>
      'Le premier bâtiment devrait renforcer la nourriture, la production ou l\'or.';

  @override
  String get objectiveBuildFirstBuildingReward => '+ avantage urbain durable';

  @override
  String get objectiveBuildFirstBuildingTooltip =>
      'Les bâtiments restent dans la ville et s\'étendent sur de nombreux tours.';

  @override
  String get objectiveImproveThreeHexesTitle => 'Améliorer trois tuiles';

  @override
  String get objectiveImproveThreeHexesHint =>
      'Plusieurs améliorations transforment un camp de départ en économie.';

  @override
  String get objectiveImproveThreeHexesReward => '+ revenu stable';

  @override
  String get objectiveImproveThreeHexesTooltip =>
      'Trois améliorations créent une base stable pour les armées, la recherche ou l\'expansion.';

  @override
  String get objectiveFoundThirdCityTitle => 'Trouvé une troisième ville';

  @override
  String get objectiveFoundThirdCityHint =>
      'Une troisième colonie crée un véritable empire et une deuxième direction d\'expansion.';

  @override
  String get objectiveFoundThirdCityReward => '+ échelle de carte';

  @override
  String get objectiveFoundThirdCityTooltip =>
      'Une troisième ville vous donne un deuxième front de développement et plus de décisions à chaque tour.';

  @override
  String get objectiveExploreRegionTitle => 'Explorer la région';

  @override
  String get objectiveExploreRegionHint =>
      'Une carte plus large révèle les ressources, les rivaux et les lieux à défendre.';

  @override
  String get objectiveExploreRegionReward => '+ plan stratégique';

  @override
  String get objectiveExploreRegionTooltip =>
      'Une carte plus large révèle des rivaux, des ressources stratégiques et des frontières sûres.';

  @override
  String get objectiveBuildCombatForceTitle => 'Construire une force défensive';

  @override
  String get objectiveBuildCombatForceHint =>
      'Plusieurs soldats vous permettent de protéger les rivaux d\'expansion et de pression.';

  @override
  String get objectiveBuildCombatForceReward => '+ sécurité aux frontières';

  @override
  String get objectiveBuildCombatForceTooltip =>
      'Un écran permanent protège les colons, les travailleurs et les villes développées.';

  @override
  String get objectiveHoldDominationTitle => 'Maintenez la domination';

  @override
  String get objectiveHoldDominationHint =>
      'Vous êtes au-dessus du seuil de la carte. Gardez le contrôle jusqu\'à la fin du compte à rebours.';

  @override
  String get objectiveHoldDominationReward => '+ victoire de carte';

  @override
  String get objectiveHoldDominationTooltip =>
      'La domination termine le jeu avant le plafond de score si vous maintenez le pourcentage de carte requis pour des tours consécutifs.';

  @override
  String get objectiveBreakDominationHoldTitle =>
      'Briser la domination d\'un rival';

  @override
  String get objectiveBreakDominationHoldHint =>
      'Un rival est au-dessus du seuil de la carte. Prenez le territoire avant qu\'ils ne tiennent l\'objectif.';

  @override
  String get objectiveBreakDominationHoldReward => '+ compte à rebours arrêté';

  @override
  String get objectiveBreakDominationHoldTooltip =>
      'Si un rival tombe au-dessous du seuil de contrôle, ses tours de maintien sont remis à zéro.';

  @override
  String get objectiveHoldScoreLeadTitle => 'Tenez la tête';

  @override
  String get objectiveHoldScoreLeadHint =>
      'La limite de tour est proche. Protégez votre score et évitez de perdre votre avantage lors des derniers tours.';

  @override
  String get objectiveHoldScoreLeadReward => '+ gain de bonnet de score';

  @override
  String get objectiveHoldScoreLeadTooltip =>
      'La limite de score détermine le partie lorsque la limite de tour passe, de sorte que le point d\'avance doit durer jusqu\'à la fin.';

  @override
  String get objectiveOvertakeScoreLeaderTitle => 'Attrapez le leader du score';

  @override
  String get objectiveOvertakeScoreLeaderHint =>
      'La limite de tour est proche. Il faut une croissance rapide des scores ou un leader plus faible.';

  @override
  String get objectiveOvertakeScoreLeaderReward => '+ une chance de succès';

  @override
  String get objectiveOvertakeScoreLeaderTooltip =>
      'Construire des villes, de la population, des technologies, des unités et des améliorations; si les scores sont égaux, le plafond se termine par un tirage au sort.';

  @override
  String get objectiveSecureMapObjectiveTitle =>
      'Sécuriser l\'objectif de la carte';

  @override
  String get objectiveSecureMapObjectiveHint =>
      'Garder une unité ou une ville d\'influence sur l\'objectif jusqu\'à ce que la cale soit terminée.';

  @override
  String get objectiveSecureMapObjectiveReward => '+ récompenses objectives';

  @override
  String get objectiveSecureMapObjectiveTooltip =>
      'Les objectifs de la carte utilisent des marqueurs triangulaires et n\'accordent leurs points de victoire ou d\'or qu\'après un contrôle consécutif.';

  @override
  String get objectiveBreakMapObjectiveHoldTitle => 'Briser l\'objectif rival';

  @override
  String get objectiveBreakMapObjectiveHoldHint =>
      'Un rival tient un objectif de carte. Concourser le marqueur triangle avant la tenue complète.';

  @override
  String get objectiveBreakMapObjectiveHoldReward => '+ Objectif refusé';

  @override
  String get objectiveBreakMapObjectiveHoldTooltip =>
      'En passant à l\'objectif avec votre propre force conteste le contrôle et réinitialise le progrès du rival.';

  @override
  String get objectiveAdviceFoundCity =>
      'Plus grand écart: une ville nouvelle ou capturée.';

  @override
  String get objectiveAdviceGrowPopulation =>
      'Écart le plus important: croissance démographique.';

  @override
  String get objectiveAdviceClaimTerritory =>
      'Plus grand écart: tuiles plus contrôlées.';

  @override
  String get objectiveAdviceConstructBuilding =>
      'Plus grand écart: un immeuble urbain.';

  @override
  String get objectiveAdviceTrainUnit => 'Plus grand écart: une unité rapide.';

  @override
  String get objectiveAdviceUnlockTechnology =>
      'Plus grand écart: compléter une technologie.';

  @override
  String get objectiveAdviceImproveField =>
      'Plus grand écart: une amélioration de la tuile.';

  @override
  String get objectiveAdviceCollectGold =>
      'Plus grand écart: l\'or pour la partition.';

  @override
  String get objectiveAdviceProtectLead =>
      'Priorité: ne pas abandonner les villes et obtenir le prochain gain de score.';

  @override
  String objectiveScoreBreakdownCatchUpHeader(int delta) {
    return 'Écart de score: $delta pts';
  }

  @override
  String objectiveScoreBreakdownProtectHeader(int delta) {
    return 'Niveau supérieur: $delta pts';
  }

  @override
  String objectiveScoreBreakdownCatchUpTotals(
    int playerScore,
    int comparisonScore,
  ) {
    return 'Vous $playerScore / leader $comparisonScore';
  }

  @override
  String objectiveScoreBreakdownProtectTotals(
    int playerScore,
    int comparisonScore,
  ) {
    return 'Vous $playerScore / rival $comparisonScore';
  }

  @override
  String objectiveScoreBreakdownCatchUpDelta(int delta) {
    return 'courte par $delta';
  }

  @override
  String objectiveScoreBreakdownProtectDelta(int delta) {
    return '+$delta';
  }

  @override
  String get objectiveScoreCategoryCity => 'Villes';

  @override
  String get objectiveScoreCategoryPopulation => 'Population';

  @override
  String get objectiveScoreCategoryTerritory => 'Territoire';

  @override
  String get objectiveScoreCategoryBuilding => 'Bâtiments';

  @override
  String get objectiveScoreCategoryUnit => 'Unités';

  @override
  String get objectiveScoreCategoryTechnology => 'Technologies';

  @override
  String get objectiveScoreCategoryImprovement => 'Améliorations';

  @override
  String get objectiveScoreCategoryGold => 'Or';

  @override
  String get cityBuildingGranary => 'Granary';

  @override
  String get cityBuildingWaterMill => 'Usine d\'eau';

  @override
  String get cityBuildingWorkshop => 'Atelier';

  @override
  String get cityBuildingStorehouse => 'Magasin';

  @override
  String get cityBuildingHousing => 'Logement';

  @override
  String get cityBuildingMerchantHall => 'Salle des marchands';

  @override
  String get cityBuildingStonemason => 'Maçon';

  @override
  String get cityBuildingBarracks => 'Barres';

  @override
  String get cityBuildingMarketplace => 'Marché';

  @override
  String get cityBuildingPort => 'Port';

  @override
  String get cityBuildingAqueduct => 'Aqueduc';

  @override
  String get cityBuildingForge => 'Forge';

  @override
  String get cityBuildingStable => 'Stable';

  @override
  String get cityBuildingBank => 'Banque';

  @override
  String get cityBuildingBuildersGuild => 'Guilde des constructeurs';

  @override
  String get cityBuildingFactory => 'Usine';

  @override
  String get cityBuildingLighthouse => 'Phare';

  @override
  String get cityBuildingTrainingGrounds => 'Terrains de formation';

  @override
  String get cityBuildingTownHall => 'Mairie';

  @override
  String get cityBuildingMonument => 'Monument';

  @override
  String get cityBuildingArchive => 'Archive';

  @override
  String get cityBuildingAcademy => 'Académie';

  @override
  String get cityBuildingUniversity => 'Université';

  @override
  String get cityBuildingObservatory => 'Observatoire';

  @override
  String get cityBuildingLaboratory => 'Laboratoire';

  @override
  String get cityBuildingReactor => 'Réacteur';

  @override
  String get cityBuildingCourthouse => 'Palais de justice';

  @override
  String get cityBuildingCourt => 'Cour';

  @override
  String get cityBuildingGovernorsOffice => 'Bureau du Gouverneur';

  @override
  String get cityBuildingSurveyorsOffice => 'Bureau d\'arpenteur';

  @override
  String get cityBuildingPlanningOffice => 'Bureau de la planification';

  @override
  String get cityBuildingApothecary => 'Apothécaire';

  @override
  String get cityBuildingPublicBaths => 'Bains publics';

  @override
  String get cityBuildingHospital => 'Hôpital';

  @override
  String get cityBuildingMinistries => 'Ministères';

  @override
  String get cityBuildingWalls => 'Murs';

  @override
  String get cityBuildingArmory => 'Armoire';

  @override
  String get cityBuildingSiegeWorkshop => 'Atelier de siège';

  @override
  String get cityBuildingCitadel => 'Citadelle';

  @override
  String get cityBuildingWarCollege => 'Collège de guerre';

  @override
  String get cityBuildingConscriptionOffice => 'Bureau de conscription';

  @override
  String get cityBuildingBorderFort => 'Fort frontalier';

  @override
  String get cityBuildingAirfield => 'Terrain d\'aviation';

  @override
  String get cityBuildingArtisansGuild => 'Guilde des artisans';

  @override
  String get cityBuildingMasterWorkshop => 'Atelier principal';

  @override
  String get cityBuildingSteelworks => 'Aciéries';

  @override
  String get cityBuildingRailDepot => 'Dépôt ferroviaire';

  @override
  String get cityBuildingPowerPlant => 'Centrale électrique';

  @override
  String get cityBuildingAssemblyPlant => 'Usine de montage';

  @override
  String get cityBuildingRefinery => 'Raffinerie';

  @override
  String get cityBuildingMapRoom => 'Salle de carte';

  @override
  String get cityBuildingShipyard => 'Chantier naval';

  @override
  String get cityBuildingDryDock => 'Dock sec';

  @override
  String get cityBuildingNavalAcademy => 'Académie navale';

  @override
  String get cityBuildingHarborCustoms => 'Douanes portuaires';

  @override
  String get cityBuildingMuseum => 'Musée';

  @override
  String get cityBuildingParliament => 'Parlement européen';

  @override
  String get cityBuildingBroadcastTower => 'Tour de diffusion';

  @override
  String get cityBuildingWorldFairGrounds =>
      'Des terrains d\'exposition mondiale';

  @override
  String get cityBuildingGranaryDescription =>
      'Un bâtiment alimentaire précoce qui stabilise la croissance de la ville.';

  @override
  String get cityBuildingWaterMillDescription =>
      'Utilise des tuiles de rivière contrôlées pour augmenter la nourriture de la ville.';

  @override
  String get cityBuildingWorkshopDescription =>
      'Un centre d\'artisanat de base qui élève la production urbaine.';

  @override
  String get cityBuildingStorehouseDescription =>
      'Améliore l\'entreposage des récoltes et augmente les aliments entreposés.';

  @override
  String get cityBuildingHousingDescription =>
      'Élargit l\'espace vital et permet à la ville de contrôler plus de tuiles.';

  @override
  String get cityBuildingMerchantHallDescription =>
      'Organise le commerce local et augmente le revenu de la ville.';

  @override
  String get cityBuildingStonemasonDescription =>
      'Renforce la construction de la ville et la base défensive.';

  @override
  String get cityBuildingBarracksDescription =>
      'Fournit une infrastructure militaire et une défense supplémentaire.';

  @override
  String get cityBuildingMarketplaceDescription =>
      'Développe le commerce urbain et augmente considérablement le revenu de l\'or.';

  @override
  String get cityBuildingPortDescription =>
      'Ouvre la ville au commerce maritime et à la nourriture côtière.';

  @override
  String get cityBuildingAqueductDescription =>
      'Offre de l\'eau, favorisant la croissance et l\'expansion de la ville.';

  @override
  String get cityBuildingForgeDescription =>
      'Concentre le travail des métaux et augmente considérablement la production.';

  @override
  String get cityBuildingStableDescription =>
      'Soutient l\'élevage et la logistique, ajoutant nourriture et production.';

  @override
  String get cityBuildingBankDescription =>
      'Centralise les finances et augmente considérablement les revenus des villes.';

  @override
  String get cityBuildingBuildersGuildDescription =>
      'Rassemble des spécialistes de la construction, accélère la production et la croissance territoriale.';

  @override
  String get cityBuildingFactoryDescription =>
      'Un bâtiment industriel plus tard-jeu qui accorde un grand bonus de production.';

  @override
  String get cityBuildingLighthouseDescription =>
      'Renforcer l\'économie côtière par la navigation et le commerce.';

  @override
  String get cityBuildingTrainingGroundsDescription =>
      'Développer l\'entraînement militaire et améliorer la défense de la ville.';

  @override
  String get cityBuildingTownHallDescription =>
      'Le centre administratif de la ville, renforçant l\'économie et le contrôle territorial.';

  @override
  String get cityBuildingMonumentDescription =>
      'Symbole du prestige de la ville, fournissant l\'or et la défense.';

  @override
  String get cityBuildingArchiveDescription =>
      'La première acquisition de connaissances, l\'organisation de documents et l\'appui à la recherche.';

  @override
  String get cityBuildingAcademyDescription =>
      'Renforcer les villes scientifiques et préparer le chemin vers l\'enseignement supérieur.';

  @override
  String get cityBuildingUniversityDescription =>
      'Un bâtiment scientifique ultérieur pour de grandes villes développées.';

  @override
  String get cityBuildingObservatoryDescription =>
      'Établir des liens entre la géographie et la science et appuyer la recherche avancée.';

  @override
  String get cityBuildingLaboratoryDescription =>
      'Soutien aux projets technologiques tardifs et aux sciences modernes.';

  @override
  String get cityBuildingReactorDescription =>
      'Un puissant bâtiment de jeu nécessitant de l\'uranium et une infrastructure solide.';

  @override
  String get cityBuildingCourthouseDescription =>
      'Stabilise les grandes villes ou les villes capturées par l\'administration légale.';

  @override
  String get cityBuildingCourtDescription =>
      'Développer le droit, les politiques municipales et le contrôle civil.';

  @override
  String get cityBuildingGovernorsOfficeDescription =>
      'Renforcer la spécialisation urbaine et la gestion territoriale.';

  @override
  String get cityBuildingSurveyorsOfficeDescription =>
      'Facilite la planification des frontières et augmente la portée du contrôle urbain.';

  @override
  String get cityBuildingPlanningOfficeDescription =>
      'Développe la ville par la planification, la production et le contrôle territorial.';

  @override
  String get cityBuildingApothecaryDescription =>
      'La santé des premières villes contribue à maintenir une croissance régulière.';

  @override
  String get cityBuildingPublicBathsDescription =>
      'Améliorer la stabilité et la croissance dans les grandes villes.';

  @override
  String get cityBuildingHospitalDescription =>
      'Infrastructure démographique tardive pour le développement à long terme.';

  @override
  String get cityBuildingMinistriesDescription =>
      'Un empire limité qui renforce l\'administration et l\'or.';

  @override
  String get cityBuildingWallsDescription =>
      'Défense de la ville contre les premières attaques.';

  @override
  String get cityBuildingArmoryDescription =>
      'Un meilleur centre de recrutement et d\'équipement pour les troupes.';

  @override
  String get cityBuildingSiegeWorkshopDescription =>
      'Produit et maintient la base de soutien des moteurs de siège.';

  @override
  String get cityBuildingCitadelDescription =>
      'Défense stratégique tardive pour les villes aux frontières importantes.';

  @override
  String get cityBuildingWarCollegeDescription =>
      'Une académie militaire qui renforce l\'armée et la coordination générale.';

  @override
  String get cityBuildingConscriptionOfficeDescription =>
      'Mobilise l\'armée et accélère la préparation des nouvelles troupes.';

  @override
  String get cityBuildingBorderFortDescription =>
      'Renforce la défense et la visibilité aux frontières de l\'empire.';

  @override
  String get cityBuildingAirfieldDescription =>
      'Un aérodrome militaire pour l\'aviation, la reconnaissance et la projection des forces modernes.';

  @override
  String get cityBuildingArtisansGuildDescription =>
      'Une étape de production avant l\'usine, basée sur l\'artisanat et les ateliers.';

  @override
  String get cityBuildingMasterWorkshopDescription =>
      'Un atelier spécialisé pour les villes axées sur la production.';

  @override
  String get cityBuildingSteelworksDescription =>
      'Industrie lourde basée sur le fer ou le charbon.';

  @override
  String get cityBuildingRailDepotDescription =>
      'Un dépôt ferroviaire améliorant la logistique et la mobilité entre les villes.';

  @override
  String get cityBuildingPowerPlantDescription =>
      'Infrastructure énergétique tardive pour une production industrielle forte.';

  @override
  String get cityBuildingAssemblyPlantDescription =>
      'Un bâtiment industriel pour la production de masse.';

  @override
  String get cityBuildingRefineryDescription =>
      'Procéde au pétrole pour les armées modernes et les projets tardifs.';

  @override
  String get cityBuildingMapRoomDescription =>
      'Soutient l\'exploration, la visibilité et la planification des expéditions.';

  @override
  String get cityBuildingShipyardDescription =>
      'Développer les flottes et la production dans les villes portuaires.';

  @override
  String get cityBuildingDryDockDescription =>
      'Un port naval tardif pour les plus grands navires de guerre.';

  @override
  String get cityBuildingNavalAcademyDescription =>
      'Une académie militaire navale pour les ports spécialisés.';

  @override
  String get cityBuildingHarborCustomsDescription =>
      'Un bureau portuaire qui renforce le commerce et le contrôle côtier.';

  @override
  String get cityBuildingMuseumDescription =>
      'Un bâtiment prestigieux qui renforce l\'influence de la ville.';

  @override
  String get cityBuildingParliamentDescription =>
      'Un bâtiment civique limité pour un état mature.';

  @override
  String get cityBuildingBroadcastTowerDescription =>
      'Renforce l\'influence de l\'empire, la visibilité et la communication.';

  @override
  String get cityBuildingWorldFairGroundsDescription =>
      'Un projet de prestige paisible pour une ville riche et développée.';

  @override
  String get unitCommander => 'Généralités';

  @override
  String get unitWarrior => 'Guerrier';

  @override
  String get unitArcher => 'Archer';

  @override
  String get unitSettler => 'Settler';

  @override
  String get unitWorker => 'Travailleur';

  @override
  String get unitMerchant => 'Marchand';

  @override
  String get unitScout => 'Scout';

  @override
  String get unitSpearman => 'Spearman';

  @override
  String get unitCavalry => 'Cavalerie';

  @override
  String get unitCatapult => 'Catapulte';

  @override
  String get unitHeavyInfantry => 'Infanterie lourde';

  @override
  String get unitFieldCannon => 'Cannon de champ';

  @override
  String get unitRifleman => 'Rifleman';

  @override
  String get unitTank => 'Réservoir';

  @override
  String get unitScoutShip => 'Navire scout';

  @override
  String get unitWarship => 'Bateau de guerre';

  @override
  String get unitReconPlane => 'Plan de reconnaissance';

  @override
  String get unitCommanderDescription =>
      'Un général commande une armée, dirige la reconnaissance et peut agir plus rapidement que les troupes régulières.';

  @override
  String get unitWarriorDescription =>
      'Une unité de combat de base pour la défense de la ville et les combats de mêlée.';

  @override
  String get unitArcherDescription =>
      'Une unité variée qui attaque de plus loin mais se défend mal en mêlée.';

  @override
  String get unitSettlerDescription =>
      'Fonde de nouvelles villes et étend l\'empire, mais a besoin de protection sur la route.';

  @override
  String get unitWorkerDescription =>
      'Améliore les carreaux autour des villes, augmentant la nourriture, la production et l\'or.';

  @override
  String get unitMerchantDescription =>
      'Voyage automatiquement entre vos villes le long d\'une route commerciale et peut entrer dans les centres-villes accueillants occupés.';

  @override
  String get unitScoutDescription =>
      'Une unité de reconnaissance rapide pour explorer la carte et détecter les menaces.';

  @override
  String get unitSpearmanDescription =>
      'Fantassin défensif, bon pour couvrir les villes et arrêter les charges.';

  @override
  String get unitCavalryDescription =>
      'Une unité de frappe mobile qui réagit rapidement aux points faibles sur le front.';

  @override
  String get unitCatapultDescription =>
      'Un moteur de siège à plus longue portée, efficace contre les fortifications.';

  @override
  String get unitHeavyInfantryDescription =>
      'Fantassin en première ligne durable avec haute défense et attaque solide.';

  @override
  String get unitFieldCannonDescription =>
      'L\'artillerie de campagne moderne pour les bombardements.';

  @override
  String get unitRiflemanDescription =>
      'Un soldat moderne, stable dans l\'attaque et la défense.';

  @override
  String get unitTankDescription =>
      'Une unité blindée lourde avec une grande résistance et une grande mobilité.';

  @override
  String get unitScoutShipDescription =>
      'Un navire léger pour la reconnaissance côtière et la protection des routes maritimes précoces.';

  @override
  String get unitWarshipDescription =>
      'Un fort navire de combat pour le contrôle maritime et le bombardement.';

  @override
  String get unitReconPlaneDescription =>
      'Un avion de reconnaissance à longue portée et à très haute mobilité.';

  @override
  String get unitRankRecruit => 'Recrutement';

  @override
  String get unitRankSeasoned => 'Assaisonnement';

  @override
  String get unitRankVeteran => 'Vétéran';

  @override
  String get unitRankElite => 'Elite';

  @override
  String get troopWarrior => 'Guerriers';

  @override
  String get troopArcher => 'Archers';

  @override
  String get troopSettler => 'Les colons';

  @override
  String get fieldImprovementFarm => 'Exploitation agricole';

  @override
  String get fieldImprovementRiverFarm => 'Ferme fluviale';

  @override
  String get fieldImprovementMine => 'La mienne';

  @override
  String get fieldImprovementLumberMill => 'Usine de bois';

  @override
  String get fieldImprovementPasture => 'Pâturages';

  @override
  String get fieldImprovementCamp => 'Camp';

  @override
  String get fieldImprovementQuarry => 'Carrière';

  @override
  String get fieldImprovementFishingBoats => 'Bateaux de pêche';

  @override
  String get fieldImprovementOrchard => 'verger';

  @override
  String get fieldImprovementPlantation => 'Plantation';

  @override
  String get fieldImprovementVineyard => 'Vignoble';

  @override
  String get fieldImprovementTradingPost => 'Poste de négociation';

  @override
  String get fieldImprovementProspectorCamp => 'Camp de prospecteurs';

  @override
  String get fieldImprovementHorseRanch => 'Ranche de chevaux';

  @override
  String get fieldImprovementPearlDivers => 'Perles plongeuses';

  @override
  String get fieldImprovementCoalShaft => 'Arbres de charbon';

  @override
  String get fieldImprovementOilWell => 'Biens pétroliers';

  @override
  String get fieldImprovementBauxiteMine => 'Mine de bauxite';

  @override
  String get fieldImprovementUraniumMine => 'Mine d\'uranium';

  @override
  String get resourceWheat => 'blé';

  @override
  String get resourceFish => 'poissons';

  @override
  String get resourceDeer => 'Cerveau';

  @override
  String get resourceSheep => 'ovins';

  @override
  String get resourceRice => 'riz';

  @override
  String get resourceCow => 'bovins';

  @override
  String get resourceApple => 'Pommes';

  @override
  String get resourceBanana => 'bananes';

  @override
  String get resourceCitrus => 'agrumes';

  @override
  String get resourceGold => 'or';

  @override
  String get resourceSilver => 'argent';

  @override
  String get resourceGems => 'gemmes';

  @override
  String get resourceSilk => 'soie';

  @override
  String get resourceSpices => 'épices';

  @override
  String get resourceCotton => 'coton';

  @override
  String get resourceGrapes => 'raisins';

  @override
  String get resourceIvory => 'ivoire';

  @override
  String get resourcePearls => 'perles';

  @override
  String get resourceCoffee => 'café';

  @override
  String get resourceCocoa => 'cacao';

  @override
  String get resourceTobacco => 'tabac';

  @override
  String get resourceSugar => 'sucre';

  @override
  String get resourceIron => 'fer';

  @override
  String get resourceCoal => 'charbon';

  @override
  String get resourceOil => 'huile';

  @override
  String get resourceAluminium => 'aluminium';

  @override
  String get resourceUranium => 'uranium';

  @override
  String get resourceHorses => 'chevaux';

  @override
  String get resourceMarble => 'marbre';

  @override
  String get technologyAgriculture => 'Agriculture';

  @override
  String get technologyWoodworking => 'Travail du bois';

  @override
  String get technologyMining => 'Exploitation minière';

  @override
  String get technologyAnimalHusbandry => 'Maris d\'animaux';

  @override
  String get technologyHunting => 'Chasse';

  @override
  String get technologyFishing => 'Pêche';

  @override
  String get technologyCraftsmanship => 'Artisanat';

  @override
  String get technologyTrade => 'Commerce';

  @override
  String get technologyStorage => 'Stockage';

  @override
  String get technologyWaterEngineering => 'Génie de l\'eau';

  @override
  String get technologyStoneworking => 'Ouvrage de pierres';

  @override
  String get technologyMilitaryOrganization => 'Organisation militaire';

  @override
  String get technologyAdvancedTrade => 'Commerce avancé';

  @override
  String get technologyConstruction => 'Bâtiment';

  @override
  String get technologyNavigation => 'Navigation';

  @override
  String get technologyIrrigation => 'Irrigation';

  @override
  String get technologyBanking => 'Banques';

  @override
  String get technologyEngineering => 'Génie';

  @override
  String get technologyMetallurgy => 'Métallurgie';

  @override
  String get technologyHorsebackRiding => 'Équitation';

  @override
  String get technologyIronWorking => 'Travail du fer';

  @override
  String get technologyCoalMining => 'Houilles';

  @override
  String get technologyMachinery => 'Machines';

  @override
  String get technologyAdministration => 'Administration';

  @override
  String get technologyLogistics => 'Logistique';

  @override
  String get technologyShipbuilding => 'Construction navale';

  @override
  String get technologyTactics => 'Tactiques';

  @override
  String get technologyEconomy => 'Économie';

  @override
  String get technologyUrbanization => 'Urbanisation';

  @override
  String get technologyFortifications => 'Fortifications';

  @override
  String get technologyStrategy => 'Stratégie';

  @override
  String get technologySpecialization => 'Spécialisation';

  @override
  String get technologyWriting => 'Rédaction';

  @override
  String get technologyMathematics => 'Mathématiques';

  @override
  String get technologyMedicine => 'Médecine';

  @override
  String get technologyCivilService => 'Fonction publique';

  @override
  String get technologySiegecraft => 'Sièges';

  @override
  String get technologyCartography => 'Cartographie';

  @override
  String get technologyGuilds => 'Guildes';

  @override
  String get technologyLaw => 'Droit';

  @override
  String get technologyEducation => 'Éducation';

  @override
  String get technologyUrbanPlanning => 'Planification urbaine';

  @override
  String get technologyNavalDoctrine => 'Doctrine navale';

  @override
  String get technologySteel => 'Acier';

  @override
  String get technologyBureaucracy => 'Bureaucratie';

  @override
  String get technologyNationalism => 'Nationalisme';

  @override
  String get technologyScientificMethod => 'Méthode scientifique';

  @override
  String get technologySteamPower => 'Puissance de vapeur';

  @override
  String get technologyElectricity => 'Électricité';

  @override
  String get technologyCombustion => 'Combustion';

  @override
  String get technologyFlight => 'Vol';

  @override
  String get technologyMassProduction => 'Production de masse';

  @override
  String get technologyRadio => 'Radio';

  @override
  String get technologyNuclearPhysics => 'Physique nucléaire';

  @override
  String get technologyAgricultureDescription =>
      'Ouvre la voie de croissance de base. Les fermes et les fermes fluviales permettent à la population de croître plus rapidement et de stabiliser la première ville.';

  @override
  String get technologyWoodworkingDescription =>
      'Développe le côté production de l\'exploitation minière. Les moulins à bois transforment les forêts en production sans aller profondément dans la métallurgie.';

  @override
  String get technologyMiningDescription =>
      'Ouvre la voie de l\'industrie et de l\'infrastructure. Les mines constituent le premier saut majeur dans la production urbaine.';

  @override
  String get technologyAnimalHusbandryDescription =>
      'Renforce la croissance grâce aux ressources animales. Les pâturages construisent une économie alimentaire et préparent le chemin à l\'équitation.';

  @override
  String get technologyHuntingDescription =>
      'Ouvre la branche militaire et d\'exploration. Fournit des camps et la première unité de production urbaine.';

  @override
  String get technologyFishingDescription =>
      'Développe des villes près de l\'eau. Les bateaux de pêche aident les villes côtières à croître plus rapidement et à se préparer au port.';

  @override
  String get technologyCraftsmanshipDescription =>
      'Première amélioration de la production urbaine. L\'atelier empêche les bâtiments et les unités de bloquer la file d\'attente trop longtemps.';

  @override
  String get technologyTradeDescription =>
      'La première étape de l\'économie de l\'or. La salle des marchands donne à une ville un avantage financier simple après avoir choisi une branche de croissance.';

  @override
  String get technologyStorageDescription =>
      'Stabilise la croissance de la ville. Le stockage aide à maintenir le rythme des aliments et réduit le risque de décrochage.';

  @override
  String get technologyWaterEngineeringDescription =>
      'Élargit le chemin de croissance de l\'eau. Le moulin à eau récompense les villes qui contrôlent les rivières.';

  @override
  String get technologyStoneworkingDescription =>
      'Combine production et défense. Les carrières et le maçon de pierre renforcent les villes de la branche infrastructure.';

  @override
  String get technologyMilitaryOrganizationDescription =>
      'Construit le premier noyau militaire d\'une ville. Les casernes renforcent la production et la défense avant que des bonus militaires plus tard apparaissent.';

  @override
  String get technologyAdvancedTradeDescription =>
      'Développe l\'économie après le commerce. Le marché est un bâtiment aurifère plus fort et prépare la voie à la banque.';

  @override
  String get technologyConstructionDescription =>
      'Élargit le territoire et la maturité de la ville. Le logement augmente le contrôle des tuiles et conduit à l\'administration et à l\'ingénierie.';

  @override
  String get technologyNavigationDescription =>
      'Ouvre une ville pour la côte. Le port a besoin d\'un accès côtier/océanique et récompense les villes riveraines avec de la nourriture et de l\'or.';

  @override
  String get technologyIrrigationDescription =>
      'Spécialise la croissance à base d\'eau. L\'aqueduc accorde une forte prime alimentaire et un contrôle territorial supplémentaire.';

  @override
  String get technologyBankingDescription =>
      'Spécialisé dans le commerce. La banque transforme les marchés antérieurs en revenus urbains solides et libère l\'économie plus large.';

  @override
  String get technologyEngineeringDescription =>
      'Spécialisation de la construction. La guilde des constructeurs accélère la production et augmente la limite des tuiles contrôlées.';

  @override
  String get technologyMetallurgyDescription =>
      'Une forte rentabilité industrielle après la pierre. La forge augmente la production et prépare le chemin vers le fer et le charbon.';

  @override
  String get technologyHorsebackRidingDescription =>
      'Une technologie qui relie croissance et guerre. L\'écurie soutient les villes qui ont investi plus tôt dans les animaux et la chasse.';

  @override
  String get technologyIronWorkingDescription =>
      'Un effet ressources industrielles. Chaque ressource de fer contrôlée augmente la production de la ville.';

  @override
  String get technologyCoalMiningDescription =>
      'Un effet sur les ressources industrielles. Le charbon contrôlé augmente la production urbaine et soutient le chemin de l\'usine.';

  @override
  String get technologyMachineryDescription =>
      'Une récupération tardive de l\'infrastructure. L\'usine donne une forte augmentation de la production aux villes qui sont entrées dans l\'ingénierie.';

  @override
  String get technologyAdministrationDescription =>
      'Liens entre l\'infrastructure et l\'économie. Les mairies et les monuments renforcent les villes matures et mènent à l\'urbanisation.';

  @override
  String get technologyLogisticsDescription =>
      'Vitesse de production unitaire. C\'est la principale technologie pour les joueurs qui veulent faire campagne les armées des villes plus souvent.';

  @override
  String get technologyShipbuildingDescription =>
      'Développe la sous-branche côtière/exploration. Le phare nécessite un accès à la côte et renforce les villes riveraines.';

  @override
  String get technologyTacticsDescription =>
      'Spécialisation des villes militaires. Les terrains d\'entraînement ajoutent la défense et la production pour les centres militaires.';

  @override
  String get technologyEconomyDescription =>
      'Une compensation systémique pour la banque. Augmente l\'or généré par les économies urbaines.';

  @override
  String get technologyUrbanizationDescription =>
      'La dernière orientation pour la croissance des grandes villes. Augmente la limite de population une fois que le système de population commence à utiliser des plafonds durs.';

  @override
  String get technologyFortificationsDescription =>
      'Renforce la défense de la ville. Accorde un bonus défensif à l\'économie de la ville, avec son plein sens croissant après le combat et l\'expansion du siège.';

  @override
  String get technologyStrategyDescription =>
      'La dernière direction militaire. Renforce l\'efficacité de l\'armée en tant que compensation tardive après la logistique.';

  @override
  String get technologySpecializationDescription =>
      'La dernière compensation civique/économie. Débloque les spécialisations de la ville, ajoute les sciences de la ville, et aide à terminer les technologies tardives dans des parties plus longs.';

  @override
  String get technologyWritingDescription =>
      'Le premier pas vers la science, le droit et l\'administration. Les archives donnent à une ville une base de recherche permanente.';

  @override
  String get technologyMathematicsDescription =>
      'Relier la science à l\'aménagement du territoire. Le bureau d\'arpentage aide les villes à mieux contrôler les frontières.';

  @override
  String get technologyMedicineDescription =>
      'Développer la santé et la croissance à long terme dans les grandes villes grâce aux apothicaires, aux bains et aux hôpitaux.';

  @override
  String get technologyCivilServiceDescription =>
      'Améliore la gestion d\'un grand empire et débloque les tribunaux qui stabilisent les villes.';

  @override
  String get technologySiegecraftDescription =>
      'Ouvre la guerre de siège. Catapultes et ateliers de siège brisent les villes forteresses.';

  @override
  String get technologyCartographyDescription =>
      'Développer l\'exploration, les cartes et la côte. Accorde la salle des cartes et les premiers vaisseaux éclaireurs.';

  @override
  String get technologyGuildsDescription =>
      'Donne aux villes de production une étape entre l\'atelier et l\'industrie.';

  @override
  String get technologyLawDescription =>
      'Introduit l\'ordre, les politiques et la gouvernance civile par les tribunaux.';

  @override
  String get technologyEducationDescription =>
      'Construire la voie scientifique complète pour les villes à travers les académies et les universités.';

  @override
  String get technologyUrbanPlanningDescription =>
      'Développer les grandes villes et le contrôle territorial par l\'aménagement du territoire.';

  @override
  String get technologyNavalDoctrineDescription =>
      'Transforme les ports en centres de flottes, de chantiers navals et de projection de force en mer.';

  @override
  String get technologySteelDescription =>
      'Introduit l\'industrie lourde et l\'infanterie lourde pour le front ultérieur.';

  @override
  String get technologyBureaucracyDescription =>
      'Fournit un objectif civique majeur après l\'administration: bureaux, ministères, musées et parlement.';

  @override
  String get technologyNationalismDescription =>
      'Combine la défense frontalière, la mobilisation et l\'identité de l\'empire.';

  @override
  String get technologyScientificMethodDescription =>
      'Préparer des projets scientifiques, des laboratoires, des observatoires et des technologies.';

  @override
  String get technologySteamPowerDescription =>
      'Ouvre le rail, la logistique plus lourde et l\'industrie de la vapeur.';

  @override
  String get technologyElectricityDescription =>
      'Introduit la puissance, l\'infrastructure et la portée de l\'information.';

  @override
  String get technologyCombustionDescription =>
      'Donne de l\'importance à l\'huile et déverrouille les unités de première ligne modernes.';

  @override
  String get technologyFlightDescription =>
      'Introduit l\'aviation, la reconnaissance et la projection de force sur le front.';

  @override
  String get technologyMassProductionDescription =>
      'Développer la production industrielle finale, les réservoirs et les usines de montage.';

  @override
  String get technologyRadioDescription =>
      'Renforce la communication, la visibilité et l\'influence de l\'empire à travers les tours de diffusion.';

  @override
  String get technologyNuclearPhysicsDescription =>
      'Ouvre le réacteur, l\'uranium et les projets de fin de jeu.';

  @override
  String get technologyEraFoundation => 'Fondation';

  @override
  String get technologyEraSettlement => 'Règlement';

  @override
  String get technologyEraExpansion => 'Expansion';

  @override
  String get technologyEraSpecialization => 'Spécialisation';

  @override
  String get technologyEraIndustry => 'Industrie';

  @override
  String get technologyEraStrategy => 'Stratégie';

  @override
  String get technologyUnlockEffect => 'Effet';

  @override
  String get technologyPrerequisitesNone => 'Aucune';

  @override
  String get technologyStateCompleted => 'Achevé';

  @override
  String get technologyStateInProgress => 'En cours';

  @override
  String get technologyStateAvailable => 'Disponible';

  @override
  String get technologyButtonResearched => 'RECHERCHES';

  @override
  String get technologyButtonActive => 'ACTIF';

  @override
  String get technologyButtonResearch => 'RECHERCHE';

  @override
  String get technologyButtonLocked => 'LOCÉ';

  @override
  String get technologyTreeTitle => 'TECHNOLOGIE';

  @override
  String get technologyTreeEmptyTitle => 'Aucune technologie à afficher';

  @override
  String get technologyTreeEmptyBody =>
      'L\'arbre de recherche apparaîtra ici lorsque le jeu de règles fournira des technologies pour cette ère.';

  @override
  String technologyResearchPointsShort(int points) {
    return '$points pts';
  }

  @override
  String get technologyDetailsTooltip => 'Détails technologiques';

  @override
  String get technologyDetailsStatus => 'État';

  @override
  String get technologyDetailsCost => 'Coût';

  @override
  String get technologyDetailsProgress => 'Progrès accomplis';

  @override
  String get technologyDetailsPrerequisites => 'Exigences';

  @override
  String get technologyDetailsUnlocks => 'Déverrouillage';

  @override
  String get technologyDetailsEffects => 'Effets';

  @override
  String get technologyDetailsBoosts => 'Boosts';

  @override
  String get technologyDetailsUnlockStatus => 'Déverrouillage';

  @override
  String get technologyDetailsNoEffects => 'Aucun effet passif';

  @override
  String get technologyDetailsNoBoosts => 'Pas de coup de pouce';

  @override
  String get technologyUnlocksNone => 'Aucun déverrouillage direct';

  @override
  String get technologyBoostActiveBadge => 'Coup de pouce';

  @override
  String get technologyBoostActiveBest =>
      'Le meilleur boost disponible est actif.';

  @override
  String technologyBoostLine(String condition, String discount) {
    return '$condition (coût $discount)';
  }

  @override
  String get technologyUnlockFieldImprovementCategory =>
      'Amélioration sur le terrain';

  @override
  String technologyEffectStrategicResourceProductionBonus(
    int production,
    String resource,
  ) {
    return 'Production +$production pour chaque ressource contrôlée: $resource';
  }

  @override
  String technologyEffectGlobalGoldMultiplier(String percent) {
    return '+$percent or dans l\'économie urbaine';
  }

  @override
  String technologyEffectCityDefenseBonus(int amount) {
    return '+$amount défense de la ville';
  }

  @override
  String technologyEffectArmyProductionMultiplier(String percent) {
    return '+$percent production unitaire dans les villes';
  }

  @override
  String technologyEffectArmyStrengthMultiplier(String percent) {
    return 'Force armée +$percent';
  }

  @override
  String technologyEffectMaxCityPopulationBonus(int amount) {
    return '+$amount population urbaine maximale';
  }

  @override
  String technologyEffectMaxControlledHexesBonus(int amount) {
    return '+$amount territoire ville max';
  }

  @override
  String technologyEffectCityScienceBonus(int amount) {
    return '+$amount science par ville';
  }

  @override
  String technologyBoostConditionImprovementCount(
    int count,
    String improvement,
  ) {
    return 'Avoir ${count}x $improvement';
  }

  @override
  String technologyBoostConditionHasImprovement(String improvement) {
    return 'Avoir $improvement';
  }

  @override
  String technologyBoostConditionControlsResource(String resource) {
    return 'Contrôle $resource';
  }

  @override
  String technologyBoostConditionControlsAnyResource(String resources) {
    return 'Contrôle: $resources';
  }

  @override
  String technologyEffectAttackBonus(String value) {
    return 'Attaque $value';
  }

  @override
  String technologyEffectDefenseBonus(String value) {
    return 'Défense $value';
  }

  @override
  String get technologyEffectNoArmyStatsBonus =>
      'Pas de bonus de statistiques de l\'armée';

  @override
  String technologyEffectArmyStatsBonus(String parts) {
    return '$parts pour les armées';
  }

  @override
  String commonListOr(String first, String last) {
    return '$first ou $last';
  }

  @override
  String get buildingDetailsTooltip => 'Détails du bâtiment';

  @override
  String get buildingDetailsNoRequirements => 'Aucune';

  @override
  String get buildingDetailsYieldImpact => 'Impact sur la ville';

  @override
  String buildingDetailsRequirementTechnology(String technology) {
    return 'Technologie: $technology';
  }

  @override
  String get buildingDetailsRequirementCoastalAccess => 'Accès côtier';

  @override
  String buildingDetailsRequirementResources(String resources) {
    return 'Ressources: $resources';
  }

  @override
  String buildingDetailsFlatYieldEffect(String yield) {
    return '$yield à rendement urbain';
  }

  @override
  String buildingDetailsRiverHexYieldEffect(String yield) {
    return '$yield par tuile de rivière contrôlée';
  }

  @override
  String buildingDetailsRiverHexYieldEffectWithMax(
    String yield,
    int maxApplications,
  ) {
    return '$yield par dalle de rivière contrôlée (maximum $maxApplications)';
  }

  @override
  String buildingDetailsMaxControlledHexesEffect(int amount) {
    return '+$amount ville limite de tuile contrôlée';
  }

  @override
  String buildingDetailsFoodDepositMultiplierEffect(int percent) {
    return '+$percent% aliments stockés après le tour';
  }

  @override
  String buildingDetailsYieldFood(String value) {
    return '$value aliment';
  }

  @override
  String buildingDetailsYieldProduction(String value) {
    return 'Production $value';
  }

  @override
  String buildingDetailsYieldGold(String value) {
    return 'Or $value';
  }

  @override
  String buildingDetailsYieldDefense(String value) {
    return 'Défense $value';
  }

  @override
  String buildingDetailsYieldScience(String value) {
    return 'Sciences $value';
  }

  @override
  String get buildingDetailsNoYieldChange => 'Pas de changement de ressources';

  @override
  String get unitDetailsTooltip => 'Détails de l\'unité';

  @override
  String get unitDetailsMovement => 'Mouvement';

  @override
  String get unitDetailsCombat => 'Lutte';

  @override
  String unitDetailsMovementPerTurn(int movement) {
    return 'Tuiles $movement/tour';
  }

  @override
  String get unitDetailsPace => 'Pace';

  @override
  String unitDetailsRequirementTechnology(String technology) {
    return 'Technologie: $technology';
  }

  @override
  String unitDetailsAttackLine(int value) {
    return 'Attaque: $value';
  }

  @override
  String unitDetailsDefenseLine(int value) {
    return 'Défense: $value';
  }

  @override
  String unitDetailsHpLine(int value) {
    return 'HP: $value';
  }

  @override
  String unitDetailsRangeLine(int value) {
    return 'Portée: $value';
  }

  @override
  String sciencePerTurn(int science) {
    return '$science science/tour';
  }

  @override
  String get activeResearchLabel => 'RECHERCHE';

  @override
  String get requirementTechnology => 'Nécessite une technologie';

  @override
  String requirementTechnologyName(String technology) {
    return 'Nécessite: $technology';
  }

  @override
  String requirementResourcesName(String resources) {
    return 'Nécessite: $resources';
  }

  @override
  String technologyBlockedBy(String technology) {
    return 'Bloqué par: $technology';
  }

  @override
  String get requirementCoastalAccess => 'Nécessite: accès côtier';

  @override
  String get productionCategoryBuilding => 'Bâtiment';

  @override
  String get productionCategoryUnit => 'Unité';

  @override
  String get productionTitle => 'PRODUIT';

  @override
  String get productionInProgressLabel => 'En cours';

  @override
  String productionPerTurn(int production) {
    return 'Production/tour $production';
  }

  @override
  String get productionNoProduction => 'pas de production';

  @override
  String get productionButtonProduce => 'PRODUIT';

  @override
  String get productionButtonLocked => 'LOCÉ';

  @override
  String get productionEmptyState =>
      'Aucune production n\'est actuellement disponible.';

  @override
  String get buildingsSection => 'Bâtiments';

  @override
  String get unitsSection => 'Unités';

  @override
  String futureBuildingsSection(int count) {
    return 'Bâtiments futurs ($count)';
  }

  @override
  String get futureBuildingsSubtitle => 'Débloqué par les technologies';

  @override
  String workerPanelTitle(String unitName) {
    return 'Travailleur - $unitName';
  }

  @override
  String get commonOpenAction => 'Ouvrir';

  @override
  String get commonShowDetailsAction => 'Afficher les détails';

  @override
  String get commonExecuteAction => 'Exécuter';

  @override
  String colorPickerChangeTooltip(String label) {
    return 'Modifier la couleur: $label';
  }

  @override
  String colorPickerColorSelected(String hex) {
    return '#$hex sélectionné';
  }

  @override
  String colorPickerSelectColor(String hex) {
    return 'Sélectionner #$hex';
  }

  @override
  String get commonDescription => 'Désignation des marchandises';

  @override
  String get commonSummary => 'Résumé';

  @override
  String get commonStatus => 'État';

  @override
  String get commonTerrain => 'Terrain';

  @override
  String get commonResources => 'Ressources';

  @override
  String get commonImprovements => 'Améliorations';

  @override
  String get commonCities => 'Villes';

  @override
  String get commonBuildings => 'Bâtiments';

  @override
  String get commonGold => 'Or';

  @override
  String get commonScience => 'Science';

  @override
  String get commonProduction => 'Production';

  @override
  String get commonResearch => 'Recherche';

  @override
  String get commonEmpire => 'Empire';

  @override
  String get commonTurn => 'Tourner';

  @override
  String get commonProjects => 'Projets';

  @override
  String get commonPopulation => 'Population';

  @override
  String get commonTechnologies => 'Technologies';

  @override
  String get commonFields => 'Champs';

  @override
  String get commonMultipliers => 'Multiplicateurs';

  @override
  String get commonOther => 'Autres';

  @override
  String get commonReady => 'Prêt';

  @override
  String get commonDone => 'Fait';

  @override
  String get commonDefault => 'Par défaut';

  @override
  String get commonAvailable => 'Disponible';

  @override
  String get commonBlocked => 'Bloqué';

  @override
  String get commonSelectAction => 'Sélectionner';

  @override
  String get commonSelectedAction => 'Sélectionné';

  @override
  String get commonOk => 'Très bien.';

  @override
  String get commonDoNotShowAgain => 'Ne plus afficher';

  @override
  String get commonNoneLower => 'aucune';

  @override
  String get visualCurrentLabel => 'Tout de suite';

  @override
  String get visualAfterLabel => 'Après changement';

  @override
  String get terrainDetailEmpty => 'Aucune information sur le terrain';

  @override
  String get yieldFoodShort => 'ALIMENTAIRES';

  @override
  String get yieldProductionShort => 'PROD';

  @override
  String get yieldGoldShort => 'OR';

  @override
  String get yieldDefenseShort => 'DEF';

  @override
  String selectionChipBadgeSuffix(String badge) {
    return 'Compteur visible: $badge.';
  }

  @override
  String selectionChipDisabledDescription(String badge) {
    return 'Ce raccourci n\'est pas disponible pour la sélection actuelle. $badge';
  }

  @override
  String selectionChipOpenDescription(String label, String badge) {
    return 'Ouvre les détails de « $label » pour le contexte actuel de la carte.$badge';
  }

  @override
  String get gameGoalTitle => 'Objectif du jeu';

  @override
  String get globalHudCloseResearch => 'Recherche étroite';

  @override
  String globalHudResearchActive(String technologyName) {
    return 'Recherche: $technologyName';
  }

  @override
  String globalHudResearchActiveWithEta(String technologyName, String eta) {
    return 'Recherche: $technologyName · $eta';
  }

  @override
  String get globalHudChooseResearch => 'Choisir la recherche';

  @override
  String get globalHudCloseEmpire => 'Fermez l\'empire';

  @override
  String get globalHudCloseActivityLog => 'Fermer le journal des activités';

  @override
  String get bottomToolbarWaiting => 'Attendre';

  @override
  String get bottomToolbarPlan => 'Plan';

  @override
  String get bottomToolbarMove => 'Déplacer';

  @override
  String get bottomToolbarResolvingTurn => 'Résolution du tour';

  @override
  String bottomToolbarWaitingFor(String players) {
    return 'En attente: $players';
  }

  @override
  String turnHintNextUnit(String unit) {
    return 'Prochaine étape: $unit';
  }

  @override
  String turnHintNextCityProduction(String city) {
    return 'Prochaine étape: production en $city';
  }

  @override
  String get turnHintChooseResearch => 'Prochaine étape: choisir la recherche';

  @override
  String get turnHintCheckAction => 'Prochaine étape: vérifier l\'action';

  @override
  String turnHintObjective(String objective) {
    return 'Objectif: $objective';
  }

  @override
  String turnHintObjectiveWithAdvice(String objective, String advice) {
    return 'Objectif: $objective · $advice';
  }

  @override
  String get turnHintImproveFieldWithWorker =>
      'Objectif: améliorer une tuile avec un travailleur';

  @override
  String get turnHintFoundCityWithSettler =>
      'Objectif: trouvé une ville avec un colon';

  @override
  String get turnHintClaimTerritoryWithSettler =>
      'Objectif: territoire de revendication avec un colon';

  @override
  String turnHintTrainUnit(String unit) {
    return 'Objectif: unité définie: $unit';
  }

  @override
  String turnHintProtectLeadUnit(String unit) {
    return 'Objectif: sécuriser la tête: $unit';
  }

  @override
  String turnHintConstructBuildingInCity(String city) {
    return 'Objectif: faire la file d\'attente d\'un bâtiment à $city';
  }

  @override
  String turnHintTrainUnitInCity(String city) {
    return 'Objectif: file d\'attente une unité dans $city';
  }

  @override
  String turnHintPrepareSettlerInCity(String city) {
    return 'Objectif: préparer un colon en $city';
  }

  @override
  String turnHintGrowPopulationInCity(String city) {
    return 'Objectif: fixer la croissance de $city';
  }

  @override
  String turnHintPrepareWorkerInCity(String city) {
    return 'Objectif: préparer un travailleur à $city';
  }

  @override
  String turnHintCollectGoldInCity(String city) {
    return 'Objectif: fermer l\'or en $city';
  }

  @override
  String turnHintProtectLeadProductionInCity(String city) {
    return 'Objectif: une production sûre en $city';
  }

  @override
  String get turnHintUnlockTechnologyForScore =>
      'Objectif: choisir une technologie de notation';

  @override
  String get turnHintProtectLeadResearch =>
      'Objectif: terminer la recherche en toute sécurité';

  @override
  String topResourceTurnShortLabel(int turn) {
    return 'T$turn';
  }

  @override
  String topResourceTurnTooltip(int turn) {
    return 'Tourner $turn';
  }

  @override
  String topResourceScienceTooltip(String scienceTurnLabel) {
    return 'Science: $scienceTurnLabel / tour';
  }

  @override
  String topResourceResourcesTooltip(int resourceTotal, int resourceTypes) {
    return 'Ressources: Dépôts $resourceTotal • Types contrôlés $resourceTypes';
  }

  @override
  String topResourceGoldTooltip(
    int gold,
    int goldIncome,
    int unitUpkeep,
    String net,
  ) {
    return 'Or: $gold • revenu +$goldIncome • entretien -$unitUpkeep • net $net / tour';
  }

  @override
  String topResourceGoldTooltipNegativeTreasury(String base) {
    return '$base • trésorerie inférieure à zéro';
  }

  @override
  String topResourceGoldTooltipBankruptcy(String base) {
    return '$base • risque de faillite dans les 3 tours';
  }

  @override
  String get resourceBreakdownTreasury => 'Trésorerie';

  @override
  String get resourceBreakdownCityIncome => 'Revenus des villes';

  @override
  String get resourceBreakdownUpkeep => 'Entretien';

  @override
  String get resourceBreakdownNetPerTurn => 'Net / tour';

  @override
  String get resourceBreakdownNoCityIncome => 'Pas de revenus urbains';

  @override
  String get resourceBreakdownFreeLimit => 'Limite libre';

  @override
  String get resourceBreakdownNextWorkerUpkeep =>
      'Prochain entretien des travailleurs';

  @override
  String resourceBreakdownNextWorkerUpkeepValue(int upkeep) {
    return '-$upkeep or/tour';
  }

  @override
  String get resourceBreakdownInsideFreeLimit => 'Limite intérieure libre';

  @override
  String get resourceBreakdownNoActiveTechnology =>
      'Aucune technologie sélectionnée';

  @override
  String get resourceBreakdownScienceTitle => 'Science et recherche';

  @override
  String get resourceBreakdownSciencePerTurn => 'Science / tour';

  @override
  String get resourceBreakdownActiveResearch => 'Recherche active';

  @override
  String get resourceBreakdownTurnsToComplete => 'À compléter';

  @override
  String get resourceBreakdownNoScienceSources => 'Aucune source scientifique';

  @override
  String resourceBreakdownCityResearchProject(String cityName) {
    return '$cityName: Recherche';
  }

  @override
  String get resourceBreakdownNoControlledResources =>
      'Aucune ressource contrôlée';

  @override
  String get resourceBreakdownGrowCitiesWithFood =>
      'Culturer des villes avec de la nourriture';

  @override
  String get resourceBreakdownControlledDeposits => 'Dépôts contrôlés';

  @override
  String get resourceBreakdownResourceTypes => 'Types de ressources';

  @override
  String get resourceBreakdownTypesSection => 'Types';

  @override
  String get resourceBreakdownSourcesSection => 'Sources';

  @override
  String get technologyRecommendationsTitle => 'Recherche recommandée';

  @override
  String get technologyShowTreeAction => 'Afficher l\'arbre';

  @override
  String technologyShowTreeCountAction(int count) {
    return 'Afficher l\'arbre ($count)';
  }

  @override
  String get technologyRecommendationUnlocks => 'Déverrouillage';

  @override
  String get technologyRecommendationReasonBoost =>
      'Une stimulation active réduit le coût de la recherche.';

  @override
  String get technologyRecommendationReasonSection => 'Pourquoi maintenant';

  @override
  String get technologyRecommendationReasonImprovements =>
      'De nouvelles améliorations de tuiles transforment rapidement les ressources en rendement.';

  @override
  String get technologyRecommendationReasonBuilding =>
      'Un nouveau bâtiment urbain ouvre une autre direction de développement.';

  @override
  String get technologyRecommendationReasonUnit =>
      'Une nouvelle unité renforce la sécurité et le contrôle des cartes.';

  @override
  String get technologyRecommendationReasonEffect =>
      'Une prime permanente s\'applique à l\'ensemble de l\'économie.';

  @override
  String get technologyRecommendationReasonFast =>
      'Recherche rapide sans exigences supplémentaires.';

  @override
  String get technologyRecommendationReasonDefault =>
      'La recherche disponible qui ferme soigneusement la prochaine étape.';

  @override
  String get technologyNoRecommendations =>
      'Aucune nouvelle recherche n\'est actuellement disponible.';

  @override
  String get technologyFullTreeTitle => 'Arbre pleine technologie';

  @override
  String get technologyRecommendationsBackAction => 'Recommandations';

  @override
  String get empireUnitsEmptyTitle => 'Pas d\'unités';

  @override
  String get empireUnitsEmptyBody =>
      'De nouvelles unités apparaîtront ici après la production urbaine ou le recrutement d\'événements.';

  @override
  String get empireCitiesEmptyTitle => 'Pas de villes';

  @override
  String get empireCitiesEmptyBody =>
      'Trouvé votre première ville avec un colon pour débloquer la production, la science, et les frontières de l\'empire.';

  @override
  String get empireCityCenters => 'Centres urbains';

  @override
  String get empireShowFirstUnitTooltip =>
      'Afficher la première unité sur la carte';

  @override
  String get empireShowUnitTooltip => 'Afficher l\'unité sur la carte';

  @override
  String get empireShowFirstCityTooltip =>
      'Afficher la première ville sur la carte';

  @override
  String get empireShowCityTooltip => 'Montrer la ville sur la carte';

  @override
  String empireUnitCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unités',
      one: '1 unité',
    );
    return '$_temp0';
  }

  @override
  String empireCityCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count villes',
      one: '1 ville',
    );
    return '$_temp0';
  }

  @override
  String empireUnitMovement(int movement) {
    return 'Mouvement $movement';
  }

  @override
  String get empireUnitBuilding => 'Bâtiment';

  @override
  String get empireUnitWorking => 'Travail';

  @override
  String get empireUnitFortifying => 'Fortifiant';

  @override
  String get empireUnitHealing => 'Guérison';

  @override
  String get empireUnitEnRoute => 'En route';

  @override
  String get empireUnitNoMovement => 'Pas de mouvement';

  @override
  String empireUnitsWithMovement(int count) {
    return '$count avec mouvement';
  }

  @override
  String empireCitySubtitle(
    int population,
    int hexes,
    int buildings,
    String production,
  ) {
    return 'Population $population - Tuiles $hexes - Bldg $buildings - produisant: $production';
  }

  @override
  String empireCityStoredArtifact(String artifactName) {
    return 'Artéfact: $artifactName';
  }

  @override
  String empireCityGroupSubtitle(String cityLabel, int population) {
    return '$cityLabel - population $population';
  }

  @override
  String get empireStatsTitle => 'Statut Empire';

  @override
  String get empireStatsSubtitle =>
      'Une lecture rapide de la préparation, de la composition et de la croissance de la ville';

  @override
  String get empireStatsReadinessTitle => 'Préparation de l\'unité';

  @override
  String get empireStatsUnitCompositionTitle => 'Composition de l\'unité';

  @override
  String get empireStatsCityDevelopmentTitle => 'Développement urbain';

  @override
  String get empireStatsCityComparisonTitle => 'Comparaison des villes';

  @override
  String get empireStatsOrders => 'Avec des ordres';

  @override
  String get empireStatsNoMovement => 'Pas de mouvement';

  @override
  String get empireStatsAveragePopulation => '- Oui.';

  @override
  String get empireStatsTotalBuildings => 'Bâtiments';

  @override
  String get empireStatsStoredArtifacts => 'Artefacts';

  @override
  String get empireStatsTerritory => 'Territoire';

  @override
  String get empireStatsCitiesProducing => 'Production';

  @override
  String get empireStatsOther => 'Autres';

  @override
  String get empireStatsEmptyUnits => 'Aucune unité à analyser';

  @override
  String get empireStatsEmptyCities => 'Aucune ville à analyser';

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
    return 'Pop. $population • Prod. $production • Alimentation $food • Or $gold';
  }

  @override
  String get empireStatsMetricPopulation => 'Père.';

  @override
  String get empireStatsMetricProduction => 'Produit.';

  @override
  String get empireStatsMetricFood => 'Produits alimentaires';

  @override
  String get empireStatsMetricGold => 'Or';

  @override
  String get activityLogTitle => 'Registre des activités';

  @override
  String get activityLogShowAllAction => 'Afficher tout';

  @override
  String activityLogShowMoreAction(int visible, int total) {
    return 'Afficher plus ($visible/$total)';
  }

  @override
  String get activityLogLoadingHistory =>
      'Chargement de l\'historique complet...';

  @override
  String get activityLogHistoryErrorTitle =>
      'Impossible de charger l\'historique';

  @override
  String activityLogHistoryErrorBody(String error) {
    return 'Le journal événement n\'est pas disponible: $error';
  }

  @override
  String get activityLogFilterAll => 'Tous';

  @override
  String get activityLogFilterAllShort => 'Tous';

  @override
  String get activityLogFilterCombat => 'Lutte';

  @override
  String get activityLogFilterCities => 'Villes';

  @override
  String get activityLogFilterDiplomacy => 'Diplomatie';

  @override
  String get activityLogFilterDiplomacyShort => 'Diplo';

  @override
  String get activityLogFilterTechnology => 'Science';

  @override
  String get activityLogEmptyAllTitle => 'Aucun événement enregistré';

  @override
  String get activityLogEmptyCombatTitle => 'Aucune bataille enregistrée';

  @override
  String get activityLogEmptyCityTitle => 'Aucun événement urbain enregistré';

  @override
  String get activityLogEmptyDiplomacyTitle => 'Pas de diplomatie enregistrée';

  @override
  String get activityLogEmptyTechnologyTitle => 'Aucune découverte enregistrée';

  @override
  String get activityLogEmptyAllBody =>
      'Les premières découvertes, batailles et constructions apparaîtront ici après avoir joué.';

  @override
  String get activityLogEmptyCombatBody =>
      'Les batailles sont enregistrées après des attaques ou des défenses visibles pour le joueur.';

  @override
  String get activityLogEmptyCityBody =>
      'Des villes fondées, des constructions et des tuiles revendiquées créeront ici la chronologie de l\'empire.';

  @override
  String get activityLogEmptyDiplomacyBody =>
      'Les dépêches, les propositions, les réponses et les changements de relation apparaîtront ici après les actions diplomatiques.';

  @override
  String get activityLogEmptyTechnologyBody =>
      'Les technologies découvertes apparaîtront ici après la fin de la recherche.';

  @override
  String get turnTimelineTitle => 'Tourner la chronologie';

  @override
  String turnTimelineSubtitle(int turn, int count) {
    return 'Tourner $turn • événements: $count';
  }

  @override
  String get turnTimelineChartTitle => 'Événements à travers les tours';

  @override
  String get turnTimelineMetricEvents => 'Événements';

  @override
  String get turnTimelineMetricActiveTurns => 'Tours actifs';

  @override
  String get turnTimelineMetricCurrentTurn => 'Tour actuel';

  @override
  String get technologyDiscoveryEyebrow => 'Technologie découverte';

  @override
  String unitSelectionMovementSubtitle(int current, int max) {
    return 'Déplacer $current/$max';
  }

  @override
  String unitSelectionMovementHpSubtitle(
    int current,
    int max,
    int hp,
    int maxHp,
  ) {
    return 'Déplacer $current/$max • HP $hp/$maxHp';
  }

  @override
  String get unitSelectionAttackLabel => 'Attaque';

  @override
  String get unitSelectionDefenseLabel => 'Défense';

  @override
  String get unitSelectionHpLabel => 'HP';

  @override
  String get unitSelectionRangeLabel => 'Portée';

  @override
  String get unitSelectionConstructionLabel => 'Bâtiment';

  @override
  String get unitSelectionWorkLabel => 'Travail';

  @override
  String get unitSelectionFieldBonusValue => 'Prime de champ';

  @override
  String get tileSelectionYieldTitle => 'Potentiel de carreaux';

  @override
  String get tileSelectionYieldTooltip =>
      'Estimation d\'inspection pour cette tuile, pas le rendement réel de la ville.';

  @override
  String get tileSelectionBonusLabel => 'Bonus';

  @override
  String get tileSelectionDefenseBonusValue => '+ défense';

  @override
  String get tileSelectionRiverBonusValue => '+rivière';

  @override
  String get citySelectionYieldTitle => 'Revenus des villes';

  @override
  String get citySelectionYieldTooltip =>
      'Rendement réel de la ville par tour de l\'économie de la ville.';

  @override
  String citySelectionSubtitle(
    int population,
    int territoryHexCount,
    int maxHexes,
    String production,
  ) {
    return 'Population $population • Champs $territoryHexCount/$maxHexes • Production: $production';
  }

  @override
  String get citySelectionTerritoryLabel => 'Territoire';

  @override
  String get citySelectionFoodLabel => 'Produits alimentaires';

  @override
  String get citySelectionNetFoodLabel => 'Produits alimentaires nets';

  @override
  String get citySelectionBuildingsLabel => 'Bâtiments';

  @override
  String get citySelectionArtifactLabel => 'Artéfact';

  @override
  String get worldArtifactBonusTitle => 'Bonus';

  @override
  String get worldArtifactHeritageTitle => 'Patrimoine';

  @override
  String get worldArtifactHeritageBody =>
      'Recueillir et placer 6 artefacts uniques dans vos villes, puis tenir la collection pour 5 tours.';

  @override
  String get worldArtifactAncientImperialCrown => 'Ancienne couronne impériale';

  @override
  String get worldArtifactAstronomersTablets => 'Comprimés d\'astronomes';

  @override
  String get worldArtifactProphetMask => 'Masque du Prophète';

  @override
  String get worldArtifactHeroSword => 'Épée du héros';

  @override
  String get worldArtifactMerchantsSeal => 'Le sceau du marchand';

  @override
  String get worldArtifactFirstPeoplesChronicle =>
      'Chronique des Premières nations';

  @override
  String get worldArtifactTempleReliquary => 'Reliquaire du Temple';

  @override
  String get worldArtifactQueensMirror => 'Miroir de la Reine';

  @override
  String get worldArtifactAncientImperialCrownShortBonus => '+1 défense';

  @override
  String get worldArtifactAstronomersTabletsShortBonus => '+1 science';

  @override
  String get worldArtifactProphetMaskShortBonus => '+1 or, diplomatie';

  @override
  String get worldArtifactHeroSwordShortBonus =>
      '+2 XP pour les unités produites';

  @override
  String get worldArtifactMerchantsSealShortBonus => '+2 or';

  @override
  String get worldArtifactFirstPeoplesChronicleShortBonus => '+1 aliments';

  @override
  String get worldArtifactTempleReliquaryShortBonus =>
      '+1 nourriture, +1 défense';

  @override
  String get worldArtifactQueensMirrorShortBonus => '+1 or, diplomatie';

  @override
  String get worldArtifactAncientImperialCrownDescription =>
      'Un symbole de l\'ancienne règle. Une fois stocké dans une ville, il renforce la défense et le prestige de la collection.';

  @override
  String get worldArtifactAstronomersTabletsDescription =>
      'Tablettes en pierre avec des cartes anciennes du ciel. Dans une ville, ils soutiennent la science.';

  @override
  String get worldArtifactProphetMaskDescription =>
      'Un masque rituel de grand poids politique. Dans une ville, elle accorde de l\'or et de la valeur diplomatique.';

  @override
  String get worldArtifactHeroSwordDescription =>
      'L\'arme d\'un commandant légendaire. Les unités produites dans cette ville acquièrent une expérience supplémentaire.';

  @override
  String get worldArtifactMerchantsSealDescription =>
      'La marque des premières corporations marchandes. Dans une ville, il renforce les revenus d\'or.';

  @override
  String get worldArtifactFirstPeoplesChronicleDescription =>
      'Une trace des plus anciennes lignées et frontières. Dans une ville, elle soutient la croissance.';

  @override
  String get worldArtifactTempleReliquaryDescription =>
      'Un reliquaire sacré qui donne à la ville stabilité, nourriture et défense.';

  @override
  String get worldArtifactQueensMirrorDescription =>
      'Un trésor de cour qui rejoint le commerce avec la diplomatie. Dans une ville, il accorde l\'or et le prestige.';

  @override
  String get worldArtifactLocationMap => 'Artéfact sur la carte';

  @override
  String get worldArtifactLocationExcavation => 'Excavation en cours';

  @override
  String get worldArtifactLocationCarried => 'Porté par une unité';

  @override
  String get worldArtifactLocationStored => 'Stocké dans une ville';

  @override
  String get worldArtifactStepExcavate => 'Excavation';

  @override
  String get worldArtifactStepMove => 'Déplacer';

  @override
  String get worldArtifactStepStore => 'A conserver';

  @override
  String get artifactGuidanceUnknownCityName => 'une ville';

  @override
  String get artifactGuidanceStoredTitle => 'Artefact stocké';

  @override
  String artifactGuidanceStoredBody(String artifactName, String cityName) {
    return '$artifactName renforce $cityName. La victoire culturelle nécessite 6 artefacts dans les villes pour 5 tours.';
  }

  @override
  String get artifactGuidanceCarriedTitle => 'Objet transporté';

  @override
  String artifactGuidanceCarriedBody(String artifactName) {
    return 'L\'unité porte $artifactName. Apportez-le dans une de vos villes avec une fente gratuite et utilisez l\'action magasin.';
  }

  @override
  String get artifactGuidanceReachedTitle => 'Artéfact découvert';

  @override
  String artifactGuidanceReachedBody(String artifactName) {
    return '$artifactName est sous l\'unité. Utilisez l\'action Excavation pour le récupérer.';
  }

  @override
  String get citySelectionSpecializationLabel => 'Spécialisation';

  @override
  String get fieldImprovementOutsideActiveCity =>
      'En dehors de la ville active';

  @override
  String get fieldImprovementYieldTitle => 'Prime d\'amélioration';

  @override
  String get fieldImprovementYieldTooltip =>
      'Rendement supplémentaire de l\'amélioration sur le terrain.';

  @override
  String get hexKindIdealCitySite => 'Site idéal de la ville';

  @override
  String get hexKindGoodCitySite => 'Bon site de ville';

  @override
  String get hexKindFertileField => 'Champ fertile';

  @override
  String get hexKindFertilePlains => 'Plaines fertiles';

  @override
  String get hexKindRichPlain => 'Riche plaine';

  @override
  String get hexKindStrategicBorderland => 'Frontière stratégique';

  @override
  String get hexKindStrategicField => 'Domaine stratégique';

  @override
  String get hexKindDefensivePosition => 'Position défensive';

  @override
  String get hexKindFertileForest => 'Forêts fertiles';

  @override
  String get hexKindForestBackline => 'Couverture forestière';

  @override
  String get hexKindForestForge => 'Faux forestiers';

  @override
  String get hexKindWildLand => 'Terres sauvages';

  @override
  String get hexKindRichWilds => 'Des sauvages riches';

  @override
  String get hexKindExoticBackline => 'Ligne arrière exotique';

  @override
  String get hexKindDifficultStrategicTerrain =>
      'Terrain stratégique difficile';

  @override
  String get hexKindHighGround => 'Terrain élevé';

  @override
  String get hexKindRiverHills => 'Collines fluviales';

  @override
  String get hexKindIndustrialStronghold => 'Bastion industriel';

  @override
  String get hexKindRichHills => 'Des collines riches';

  @override
  String get hexKindBarrenLand => 'Terrains';

  @override
  String get hexKindOasis => 'Oasis';

  @override
  String get hexKindTradeOasis => 'Oasis commerciale';

  @override
  String get hexKindDesertDeposits => 'Dépôts des déserts';

  @override
  String get hexKindHarshLand => 'Terres sauvages';

  @override
  String get hexKindColdPastures => 'Pâturages froids';

  @override
  String get hexKindResourceOutpost => 'Ressources poste';

  @override
  String get hexKindHostileLand => 'Terres hostiles';

  @override
  String get hexKindArcticDeposits => 'Dépôts arctiques';

  @override
  String get hexKindCoast => 'Côte';

  @override
  String get hexKindFishingCoast => 'Côte de pêche';

  @override
  String get hexKindRichCoast => 'Côte riche';

  @override
  String get hexKindRiverPort => 'Port fluvial';

  @override
  String get hexKindRegionalPortHeart => 'Hub portuaire régional';

  @override
  String get hexKindOpenSea => 'Mer ouverte';

  @override
  String get hexKindNaturalBarrier => 'Barrière naturelle';

  @override
  String get hexKindPromisingLand => 'Terrains prometteurs';

  @override
  String get hexKindWeakLand => 'Pays faibles';

  @override
  String get hexKindOrdinaryLand => 'Terres ordinaires';

  @override
  String get hexKindMapTile => 'Carrelage de carte';

  @override
  String get hexKindIdealCitySiteDescription =>
      'Une tuile de peuplement de haute valeur avec la nourriture, la croissance et la pression d\'expansion déjà alignée.';

  @override
  String get hexKindGoodCitySiteDescription =>
      'Terrain solide pour un centre-ville avec une valeur de base suffisante pour soutenir la croissance précoce.';

  @override
  String get hexKindFertileFieldDescription =>
      'Les prairies alimentées par les rivières favorisent la nourriture, la croissance de la population et l\'amélioration des travailleurs.';

  @override
  String get hexKindFertilePlainsDescription =>
      'Plaines ouvertes avec support fluvial, utiles pour une alimentation et une production équilibrées.';

  @override
  String get hexKindRichPlainDescription =>
      'Une précieuse tuile ouverte avec luxe ou valeur commerciale vaut la peine d\'apporter à l\'intérieur des frontières.';

  @override
  String get hexKindStrategicBorderlandDescription =>
      'Une bonne terre à valeur stratégique, utile pour l\'expansion avant que les rivaux ne la revendiquent.';

  @override
  String get hexKindStrategicFieldDescription =>
      'Une tuile des plaines liée aux ressources stratégiques ou à la pression sur la frontière.';

  @override
  String get hexKindDefensivePositionDescription =>
      'Terrain qui améliore le contrôle défensif et aide à maintenir des approches proches.';

  @override
  String get hexKindFertileForestDescription =>
      'Une forêt avec un support fluvial, mélangeant le potentiel de croissance et le couvert naturel.';

  @override
  String get hexKindForestBacklineDescription =>
      'Une tuile forestière plus sûre qui peut soutenir la croissance ou des améliorations axées sur la chasse.';

  @override
  String get hexKindForestForgeDescription =>
      'Forêt à valeur industrielle, prometteuse pour la production une fois améliorée.';

  @override
  String get hexKindWildLandDescription =>
      'Terrain dense avec friction; utile seulement lorsque vous avez un travailleur clair ou un plan d\'expansion.';

  @override
  String get hexKindRichWildsDescription =>
      'Terrain sauvage avec suffisamment de fertilité ou de ressources pour justifier un développement attentif.';

  @override
  String get hexKindExoticBacklineDescription =>
      'Une jungle ou des tuiles de zones humides ayant une valeur de luxe pour les frontières et le commerce ultérieurs.';

  @override
  String get hexKindDifficultStrategicTerrainDescription =>
      'Terrain dur avec une valeur stratégique des ressources; puissant plus tard, maladroit tôt.';

  @override
  String get hexKindHighGroundDescription =>
      'Hills qui favorisent la défense et le contrôle de la carte plus que la croissance rapide.';

  @override
  String get hexKindRiverHillsDescription =>
      'Collines au bord d\'une rivière, combinant défense et meilleur potentiel économique.';

  @override
  String get hexKindIndustrialStrongholdDescription =>
      'Des collines avec des ressources industrielles, un objectif de production fort pour une ville.';

  @override
  String get hexKindRichHillsDescription =>
      'Collines riches, utiles pour l\'or ou l\'expansion axée sur la production.';

  @override
  String get hexKindBarrenLandDescription =>
      'Terres sèches avec peu de valeur immédiate à moins que la technologie ou les frontières plus tard changent le plan.';

  @override
  String get hexKindOasisDescription =>
      'Désert adouci par l\'accès à la rivière, transformant des terres faibles en une tuile de croissance utilisable.';

  @override
  String get hexKindTradeOasisDescription =>
      'Une poche commerciale du désert qui peut devenir utile avec la bonne amélioration.';

  @override
  String get hexKindDesertDepositsDescription =>
      'Les terres de peuplement pauvres avec un dépôt stratégique qui importe plus dans les époques ultérieures.';

  @override
  String get hexKindHarshLandDescription =>
      'Terres froides ou accidentées avec une économie précoce limitée et un développement lent.';

  @override
  String get hexKindColdPasturesDescription =>
      'Terrain froid avec une valeur de pâturage suffisante pour soutenir une ville frontalière.';

  @override
  String get hexKindResourceOutpostDescription =>
      'Terres froides éloignées qui méritent d\'être revendiquées principalement pour la ressource qu\'elle protège.';

  @override
  String get hexKindHostileLandDescription =>
      'Un terrain hostile avec une faible valeur d\'établissement et peu de retours immédiats.';

  @override
  String get hexKindArcticDepositsDescription =>
      'Des terres enneigées qui sont difficiles à utiliser, mais qui peuvent avoir une importance stratégique.';

  @override
  String get hexKindCoastDescription =>
      'Terrain côtier qui ouvre l\'accès à la marine et la croissance flexible de la ville.';

  @override
  String get hexKindFishingCoastDescription =>
      'Côte à valeur alimentaire, une forte raison de travailler ou de s\'installer près de l\'eau.';

  @override
  String get hexKindRichCoastDescription =>
      'Le luxe côtier ou la valeur commerciale vaut la peine de se replier dans les frontières de la ville.';

  @override
  String get hexKindRiverPortDescription =>
      'Une embouchure fluviale avec valeur commerciale et de déplacement pour une ville côtière.';

  @override
  String get hexKindRegionalPortHeartDescription =>
      'Un centre côtier fort où la valeur de la rivière et des ressources s\'accumulent ensemble.';

  @override
  String get hexKindOpenSeaDescription =>
      'L\'eau qui est utile pour les navires et le scoutisme, mais pas pour le peuplement terrestre.';

  @override
  String get hexKindNaturalBarrierDescription =>
      'Terrain bloqué qui forme le mouvement et la défense plutôt que l\'économie.';

  @override
  String get hexKindPromisingLandDescription =>
      'Une tuile généralement utile avec une valeur suffisante pour l\'inspection avant de passer.';

  @override
  String get hexKindWeakLandDescription =>
      'Terrain à faible rendement qui mérite rarement un temps de travail précoce.';

  @override
  String get hexKindOrdinaryLandDescription =>
      'Une tuile normale sans résistance, utile quand elle correspond au plan de la ville.';

  @override
  String get hexKindMapTileDescription =>
      'Une carrure de carte simple sans suffisamment d\'informations pour faire un jugement fort.';

  @override
  String get hexTagCity => 'Site urbain';

  @override
  String get hexTagDefense => 'Position défensive';

  @override
  String get hexTagTrade => 'Voie commerciale';

  @override
  String get hexTagFertile => 'Champ fertile';

  @override
  String get hexTagProduction => 'Bonne production';

  @override
  String get hexTagHostile => 'Terres hostiles';

  @override
  String get hexTagStrategic => 'Ressources stratégiques';

  @override
  String get hexTagWater => 'Passage d\'eau';

  @override
  String get hexRecommendationFoundCity => 'Bon site de développement';

  @override
  String get hexRecommendationDefendHere => 'Bonne position défensive';

  @override
  String get hexRecommendationExploitEconomy => 'Une bonne exploitation';

  @override
  String get hexRecommendationAvoid => 'Éviter sans plan';

  @override
  String get hexRecommendationNeutral => 'Inspecter avant de se déplacer';

  @override
  String get hexRecommendationFoundCityDetail =>
      'Si les frontières sont libres, envisagez de fonder ou de diriger un colon ici.';

  @override
  String get hexRecommendationDefendHereDetail =>
      'Utilisez-le pour ancrer les unités, protéger les frontières ou couvrir les villes voisines.';

  @override
  String get hexRecommendationExploitEconomyDetail =>
      'Apportez-le à l\'intérieur des frontières et assignez un travailleur lorsque la ville peut en bénéficier.';

  @override
  String get hexRecommendationAvoidDetail =>
      'Passer tôt à moins qu\'une ressource, un itinéraire ou un besoin militaire ne change la valeur.';

  @override
  String get hexRecommendationNeutralDetail =>
      'Scout voisin carreaux et comparer les ressources avant de commettre un travailleur ou un colon.';

  @override
  String get selectionActionLockedReason =>
      'Vous ne pouvez pas donner d\'ordres maintenant.';

  @override
  String get selectionActionFoundCity => 'Ville trouvée';

  @override
  String get selectionActionCancel => 'Annuler';

  @override
  String get selectionActionCancelAttack => 'Annuler l\'attaque';

  @override
  String get selectionActionCancelWorkerBuild =>
      'Annuler la construction d\'amélioration';

  @override
  String get selectionActionCancelCityFounding =>
      'Annuler la fondation de la ville';

  @override
  String get selectionActionCancelAutoExplore => 'Annuler l\'exploration';

  @override
  String get selectionActionCancelArtifactExcavation =>
      'Annuler l\'excavation des artefacts';

  @override
  String get selectionActionCancelTradeRouteSelection =>
      'Annuler la sélection de l\'itinéraire commercial';

  @override
  String get selectionActionCancelMerchantMoveToCity =>
      'Annuler le voyage en ville';

  @override
  String get selectionActionCancelCommanderMerge =>
      'Annuler la fusion des troupes';

  @override
  String get selectionActionConfirm => 'Confirmer';

  @override
  String selectionActionConfirmWithTurns(String turns) {
    return 'Confirmer ($turns)';
  }

  @override
  String get selectionActionMinimize => 'Minimiser';

  @override
  String get selectionActionConfirmAttack => 'Confirmer l\'attaque';

  @override
  String get selectionActionCaptureCity => 'Ville de capture';

  @override
  String get selectionActionDestroyCity => 'Détruire la ville';

  @override
  String get selectionActionStopFortifying => 'Arrête de fortifier';

  @override
  String get selectionActionStopHealing => 'Arrête de guérir';

  @override
  String get selectionActionMove => 'Déplacer';

  @override
  String get selectionActionAttack => 'Attaque';

  @override
  String get selectionActionAutoExplore => 'Explorer';

  @override
  String get selectionActionTradeRoute => 'Voie commerciale';

  @override
  String selectionActionTradeRouteToCity(String cityName) {
    return 'Échanges avec $cityName';
  }

  @override
  String get selectionActionMerchantMoveToCity => 'Allez en ville';

  @override
  String selectionActionMerchantMoveToCityTarget(String cityName) {
    return 'Aller à $cityName';
  }

  @override
  String get selectionActionArmy => 'Armée';

  @override
  String get selectionArmyEmpty => 'Pas de troupes';

  @override
  String selectionTroopDetachTooltip(String troop) {
    return 'Détachement $troop';
  }

  @override
  String get selectionActionImprove => 'Améliorer';

  @override
  String get selectionActionSkip => 'Sauter';

  @override
  String get selectionActionFortify => 'Fortifier';

  @override
  String get selectionActionHeal => 'Guérison';

  @override
  String get selectionActionCancelCityGrowth => 'Annuler la croissance';

  @override
  String get selectionActionCityGrowth => 'Croissance des villes';

  @override
  String get selectionActionProduction => 'Production';

  @override
  String get selectionActionExcavateArtifact => 'Excavation';

  @override
  String get selectionActionStoreArtifact => 'A conserver';

  @override
  String get selectionActionCancelCurrentMoveFirst =>
      'Annule d\'abord le mouvement actuel.';

  @override
  String get selectionActionArtifactAlreadyCarried =>
      'L\'unité porte déjà un artefact.';

  @override
  String get selectionActionStoreArtifactOwnCityRequired =>
      'Déménagez dans une de vos villes.';

  @override
  String get selectionActionStoreArtifactCityOccupied =>
      'Cette ville conserve déjà un artefact.';

  @override
  String get selectionActionNoBuildAvailable =>
      'Aucune construction n\'est disponible sur cette tuile.';

  @override
  String get selectionActionUnitWorking => 'L\'unité fonctionne déjà.';

  @override
  String get selectionActionUnitFortified => 'L\'unité est fortifiée.';

  @override
  String get selectionActionUnitHealing => 'L\'unité guérit.';

  @override
  String get selectionActionNoMovement =>
      'Aucun point de mouvement n\'a quitté ce tour.';

  @override
  String get selectionActionNoAttack => 'Cette unité n\'a pas d\'attaque.';

  @override
  String get selectionActionNoVisibleEnemy => 'Aucun ennemi visible à portée.';

  @override
  String get selectionActionMerchantNoOriginCity =>
      'Déplacez le marchand dans une de vos villes.';

  @override
  String get selectionActionMerchantNoDestinationCity =>
      'Vous avez besoin d\'une autre ville connectée.';

  @override
  String get selectionActionMerchantNoRoute =>
      'Aucune route commerciale ne peut atteindre cette ville.';

  @override
  String get selectionActionMerchantNoCityPath =>
      'Le marchand ne peut pas atteindre cette ville.';

  @override
  String get selectionActionCannotFoundCityHere =>
      'Je n\'ai pas trouvé de ville ici.';

  @override
  String get selectionActionFoundCityNoCommander =>
      'Seul un colon ou un commandant avec des colons peut trouver une ville.';

  @override
  String get selectionActionFoundCityNoSettlers =>
      'Les colons sont tenus de trouver une ville.';

  @override
  String get selectionActionFoundCityInvalidCenter =>
      'Une ville ne peut être fondée sur cette tuile.';

  @override
  String get selectionActionFoundCityCityAlreadyExists =>
      'Il y a déjà une ville sur cette tuile.';

  @override
  String get selectionActionFoundCityCenterOccupied =>
      'Cette tuile appartient déjà à une ville.';

  @override
  String get selectionActionFoundCityTooCloseToCity =>
      'Une ville ne peut être adjacente à une autre ville.';

  @override
  String get selectionActionFoundCityInvalidControlledHexes =>
      'Choisissez d\'abord les tuiles de ville valides.';

  @override
  String get selectionActionCannotImproveCityCenter =>
      'Impossible de construire des améliorations sur le centre-ville.';

  @override
  String get selectionActionTileAlreadyImproved =>
      'Cette tuile a déjà une amélioration.';

  @override
  String get selectionActionTileMustBelongToCity =>
      'La tuile doit appartenir à une ville.';

  @override
  String get selectionActionNoWorkerTile => 'Pas de tuile sous l\'ouvrier.';

  @override
  String get hudFeedbackNoTurnCostDetail =>
      'L\'action n\'a pas consommé le tour';

  @override
  String get hudFeedbackAutoExploreNoTargetTitle =>
      'Aucune route d\'exploration';

  @override
  String get hudFeedbackAutoExploreNoTargetBody =>
      'Le scout n\'a aucun mouvement qui révélerait de nouvelles tuiles ce tour.';

  @override
  String get hudFeedbackArtifactGuidanceTitle => 'Artefact mondial';

  @override
  String get hudFeedbackArtifactGuidanceBody =>
      'Livrez-le à l\'une de vos villes et placez-le dans une fente vide.';

  @override
  String get hudFeedbackActionBlockedTitle => 'Action non disponible';

  @override
  String get hudFeedbackActionBlockedBody =>
      'Cette action est bloquée en ce moment. Choisissez une autre tuile ou une autre commande.';

  @override
  String get hudFeedbackAttackProtectedByTreatyTitle =>
      'Le traité bloque l\'attaque';

  @override
  String get hudFeedbackAttackProtectedByTreatyBody =>
      'Vous ne pouvez pas attaquer une unité d\'une civilisation qui a une alliance ou une trêve avec vous. Changer d\'abord les relations diplomatiques.';

  @override
  String get hudFeedbackMovementCityOccupiedTitle => 'Ville occupée';

  @override
  String get hudFeedbackMovementCityOccupiedBody =>
      'Une seule unité peut se tenir dans une ville. Déplacez la garnison d\'abord ou choisissez une autre tuile.';

  @override
  String get hudFeedbackMovementEnemyOccupiedTitle => 'Ennemi sur cette tuile';

  @override
  String get hudFeedbackMovementEnemyOccupiedBody =>
      'Vous ne pouvez pas entrer dans une tuile ennemie avec un mouvement normal. Utilisez Attaquer ou choisissez une tuile adjacente.';

  @override
  String get hudFeedbackMovementForeignCityTitle => 'Ville étrangère';

  @override
  String get hudFeedbackMovementForeignCityBody =>
      'Vous ne pouvez pas entrer dans une ville étrangère avec un mouvement normal. Utilisez Attaquer ou choisissez une autre tuile.';

  @override
  String get hudFeedbackMovementHiddenRouteTooFarTitle => 'Route trop loin';

  @override
  String get hudFeedbackMovementHiddenRouteTooFarBody =>
      'Vous ne pouvez pas tracer une route aussi longue à travers un terrain inconnu. Choisissez un segment plus court ou utilisez l\'auto-exploration scout.';

  @override
  String get hudFeedbackMovementBlockedTerrainTitle =>
      'Mouvement des blocs de terrain';

  @override
  String get hudFeedbackMovementBlockedTerrainBody =>
      'Cette unité ne peut pas entrer ce type de terrain. Choisissez une autre tuile ou un itinéraire autour.';

  @override
  String get hudFeedbackMovementInsufficientUnitMovementTitle =>
      'Pas assez de mouvement';

  @override
  String get hudFeedbackMovementInsufficientUnitMovementBody =>
      'Cette unité n\'a pas assez de mouvement pour entrer dans cette zone. Mettez-le à niveau ou utilisez une autre unité.';

  @override
  String get hudFeedbackMovementNoRouteTitle => 'Aucune route';

  @override
  String get hudFeedbackMovementNoRouteBody =>
      'Il n\'y a pas de route disponible pour cette tuile. Essayez une cible plus proche ou une autre approche.';

  @override
  String selectionCommandUnavailableDescription(String label) {
    return 'L\'action \"$label\" n\'est pas disponible pour la sélection actuelle.';
  }

  @override
  String selectionCommandActiveDescription(String label) {
    return 'L\'action \"$label\" est un mode actif. Choisissez une cible sur la carte ou annulez le mode si vous avez changé d\'avis.';
  }

  @override
  String selectionCommandProminentDescription(String label) {
    return 'L\'action \"$label\" est actuellement la commande la plus importante pour cette sélection.';
  }

  @override
  String selectionCommandDefaultDescription(String label) {
    return 'Exécute l\'action \"$label\" pour l\'unité, la ville ou la tuile actuellement sélectionnée.';
  }

  @override
  String get selectionInfoChipDisabledDescription =>
      'Ce panneau d\'information n\'est pas disponible pour la sélection actuelle.';

  @override
  String selectionInfoChipOpenDescription(String label) {
    return 'Ouvre les détails \"$label\" pour la tuile, l\'unité ou la ville actuellement sélectionnée.';
  }

  @override
  String turnCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tours',
      one: '1 tour',
      zero: '0 tour',
    );
    return '$_temp0';
  }

  @override
  String turnPillLabel(int turn) {
    return 'T$turn';
  }

  @override
  String get turnEtaNoProgress => 'Pas de progrès';

  @override
  String turnEtaDetailLabel(String turnsLabel, int turn) {
    return '$turnsLabel • tourner $turn';
  }

  @override
  String turnEtaTooltipNoTurn(String turnsLabel) {
    return '$turnsLabel à compléter';
  }

  @override
  String turnEtaTooltipExpectedTurn(String turnsLabel, int turn) {
    return '$turnsLabel à compléter • tour prévu $turn';
  }

  @override
  String get modeBannerWorkedTilesTitle => 'Tuiles travaillées';

  @override
  String get modeBannerWorkedTilesInstruction =>
      'Tapez les tuiles contrôlées pour basculer le travail de la ville.';

  @override
  String get modeBannerCityGrowthTitle => 'Croissance des villes';

  @override
  String get modeBannerCityGrowthInstructionSelected =>
      'La tuile sélectionnée sera revendiquée lors de la prochaine croissance de la ville. Confirmez-le ou choisissez une autre tuile.';

  @override
  String get modeBannerCityGrowthInstructionEmpty =>
      'Appuyez sur une tuile tracée pour choisir le prochain hexagone de croissance. Sans choix, la ville utilisera sa recommandation.';

  @override
  String get modeBannerWorkerActionTitle => 'Amélioration des carreaux';

  @override
  String get modeBannerWorkerActionInstructionPicked =>
      'Confirmer l\'amélioration du popup ouvrier.';

  @override
  String get modeBannerWorkerActionInstructionEmpty =>
      'Choisissez un type d\'amélioration dans le popup ouvrier.';

  @override
  String get modeBannerMerchantTradeRouteTitle => 'Voie commerciale';

  @override
  String get modeBannerMerchantTradeRouteInstruction =>
      'Choisissez une de vos villes. Le marchand y voyage automatiquement et se retourne après l\'arrivée.';

  @override
  String get modeBannerMerchantMoveToCityTitle => 'Allez en ville';

  @override
  String get modeBannerMerchantMoveToCityInstruction =>
      'Choisissez une de vos villes. Le marchand tracera un chemin vers son centre sans créer de route commerciale.';

  @override
  String workerActionSelectedImprovement(String title) {
    return 'Sélectionné: $title';
  }

  @override
  String get workerActionSelectImprovement => 'Choisir l\'amélioration';

  @override
  String get workerActionBuildDetailTitle => 'Amélioration des carreaux';

  @override
  String workerActionBuildImprovement(String title) {
    return 'Construire $title';
  }

  @override
  String get workerActionSelectionHint =>
      'Cliquez sur une amélioration pour cette tuile, inspectez les rendements et confirmez la construction.';

  @override
  String get workerActionNoYieldChange => 'Aucun changement de rendement';

  @override
  String get modeBannerResearchSelectionTitle => 'Choisir la recherche';

  @override
  String get modeBannerResearchSelectionInstruction =>
      'Ouvrez l\'arbre technologique et choisissez une cible de recherche pour poursuivre le tour.';

  @override
  String get modeBannerUnitTurnSkipTitle => 'Tourné en panne';

  @override
  String get modeBannerUnitTurnSkipInstruction =>
      'L\'unité attend le prochain tour. Son état est visible dans la barre inférieure.';

  @override
  String get modeBannerCommanderMergeTitle => 'Fusionner les troupes';

  @override
  String get modeBannerCommanderMergeInstruction =>
      'Sélectionnez une unité amicale pour le commandant à ajouter à l\'armée.';

  @override
  String get modeBannerAttackTargetingTitle => 'Attaque';

  @override
  String get modeBannerAttackTargetingInstructionSelected =>
      'Vérifiez les prévisions de combat dans le popup et confirmez l\'attaque.';

  @override
  String get modeBannerAttackTargetingInstructionEmpty =>
      'Sélectionnez un ennemi à portée ou son hexagone pour voir les prévisions de combat.';

  @override
  String get modeBannerAttackRetreatProgress => 'Retraite';

  @override
  String get modeBannerActionToolbarHint =>
      'Utilisez la barre d\'outils inférieure pour les actions lorsque vous en avez besoin.';

  @override
  String get combatPreviewConfirmBody =>
      'L\'unité sélectionnée attaquera immédiatement après confirmation.';

  @override
  String get combatPreviewOutcomeLabel => 'Résultat';

  @override
  String get combatPreviewTargetLabel => 'Objectif';

  @override
  String get combatPreviewRetaliationLabel => 'Rétorsion';

  @override
  String get combatPreviewStrengthLabel => 'Résistance';

  @override
  String get combatPreviewAttackerRole => 'Attaque';

  @override
  String get combatPreviewDefenderRole => 'Défenseur';

  @override
  String get combatPreviewCityRole => 'Ville';

  @override
  String combatPreviewOutcomeLine(String outcome) {
    return 'Résultat: $outcome';
  }

  @override
  String get combatPreviewOutcomeCityFalls => 'chutes de ville';

  @override
  String get combatPreviewOutcomeDefenderKilled => 'le défenseur meurt';

  @override
  String get combatPreviewOutcomeAttackerKilled =>
      'l\'agresseur meurt en représailles';

  @override
  String get combatPreviewOutcomeDefenderRetreated =>
      'le défenseur va se retirer';

  @override
  String get combatPreviewOutcomeCitySurvives => 'la ville survit';

  @override
  String get combatPreviewOutcomeDefenderSurvives => 'le défenseur survit';

  @override
  String combatPreviewTargetLine(
    int hpBefore,
    int hpAfter,
    int hpMax,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Cible: HP $hpBefore->$hpAfter/$hpMax, Attaque $attack contre Défense $defense (-$damage)';
  }

  @override
  String combatPreviewNoRetaliationLine(int distance, int range) {
    return 'Rétorsion: aucune (attaque à distance, distance $distance, plage $range)';
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
    return 'Rétorsion: Attaque $attack vs Défense $defense (-$damage), HP $hpBefore->$hpAfter/$hpMax';
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
  String get combatPreviewForecastTitle => 'Prévisions de combat';

  @override
  String get combatPreviewNoHpLoss => 'aucun dommage';

  @override
  String combatPreviewHpAfterSemantics(int hpAfter, int hpMax, int loss) {
    return '$hpAfter de $hpMax HP après le combat, $loss HP perdu';
  }

  @override
  String combatPreviewStrengthValue(int attack, int defense) {
    return '$attack attaque contre la défense $defense';
  }

  @override
  String get combatPreviewAdvantageTitle => 'Pourquoi cette prévision?';

  @override
  String combatPreviewAdvantageAttacker(
    String country,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Avantage d\'attaque: $country a une attaque $attack contre la défense $defense; la cible perd sur $damage HP.';
  }

  @override
  String combatPreviewAdvantageDefender(
    String country,
    int attack,
    int defense,
    int damage,
  ) {
    return 'Avantage de la défense: $country a la défense $defense contre l\'attaque $attack; le succès traite de $damage HP.';
  }

  @override
  String combatPreviewAdvantageEven(int attack, int defense, int damage) {
    return 'Même combat: attaque $attack contre la défense $defense; les dommages prévus concernent $damage HP.';
  }

  @override
  String combatPreviewTerrainLine(
    String attackerCountry,
    String attackerTerrain,
    String defenderCountry,
    String defenderTerrain,
  ) {
    return 'Positions: attaques $attackerCountry depuis $attackerTerrain. $defenderCountry défend sur $defenderTerrain.';
  }

  @override
  String combatPreviewSourcesLine(String sources) {
    return 'Le bord provient de: $sources.';
  }

  @override
  String combatPreviewPositiveSourcesLine(
    String attackerCountry,
    String sources,
  ) {
    return 'Aide l\'attaque ($attackerCountry): $sources.';
  }

  @override
  String combatPreviewNegativeSourcesLine(
    String defenderCountry,
    String sources,
  ) {
    return 'Aide la défense ($defenderCountry): $sources.';
  }

  @override
  String get combatPreviewNoSourcesLine =>
      'Aucune modification ne s\'applique: les statistiques des unités de base et le résultat du combat décident de cette prévision.';

  @override
  String combatPreviewNoRetaliationReason(int distance, int range) {
    return 'Pas de représailles: il s\'agit d\'une attaque variée (distance $distance, portée d\'attaque $range).';
  }

  @override
  String get combatPreviewNoRetaliationDefenderDefeated =>
      'Pas de représailles: la cible est vaincue avant de pouvoir répondre.';

  @override
  String get combatPreviewNoRetaliationDefenderRetreats =>
      'Pas de représailles: la cible recule après le coup.';

  @override
  String get combatPreviewNoRetaliationNoAttack =>
      'Pas de représailles: la cible n\'a pas de force d\'attaque dans cette prévision.';

  @override
  String combatPreviewRetaliationRisk(
    String defenderCountry,
    String attackerCountry,
    int damage,
  ) {
    return 'Rétorsion: $defenderCountry répond et $attackerCountry perd sur $damage HP.';
  }

  @override
  String get combatPreviewSourceAttackTerrain => 'terrain d\'attaque';

  @override
  String get combatPreviewSourceDefenseTerrain => 'terrain du défenseur';

  @override
  String get combatPreviewSourceTechnology => 'technologie';

  @override
  String get combatPreviewSourceVeterancy => 'expérience';

  @override
  String get combatPreviewSourceCityGarrison => 'garnison de la ville';

  @override
  String get combatPreviewSourceMixedArmy => 'composition de l\'unité';

  @override
  String get combatCounterSpearmanVsMountedAttack =>
      'Lanceurs contre les unités montées';

  @override
  String get combatCounterSpearmanVsMountedDefense =>
      'hommes de lance tenant contre les unités montées';

  @override
  String get combatCounterArcherDefensiveTerrainDefense =>
      'archers en terrain défensif';

  @override
  String get combatCounterCavalryRoughAttack =>
      'cavalerie ralentie par un terrain accidenté';

  @override
  String get combatCounterCavalryOpenRaid =>
      'raid de cavalerie sur terrain ouvert';

  @override
  String get combatCounterHeavyInfantryBreakthrough =>
      'infanterie lourde brisant la ligne';

  @override
  String get terrainOcean => 'océan';

  @override
  String get terrainCoast => 'côte';

  @override
  String get terrainLake => 'lac';

  @override
  String get terrainPlains => 'des plaines';

  @override
  String get terrainGrassland => 'prairies';

  @override
  String get terrainDesert => 'désert';

  @override
  String get terrainTundra => 'toundra';

  @override
  String get terrainSnow => 'neige';

  @override
  String get terrainMountain => 'montagnes';

  @override
  String get terrainHills => 'collines';

  @override
  String get terrainWetlands => 'zones humides';

  @override
  String get terrainJungle => 'jungle';

  @override
  String get terrainForest => 'forêt';

  @override
  String get terrainRiver => 'rivière';

  @override
  String get modeBannerMoveTargetingTitle => 'Mode mouvement';

  @override
  String get modeBannerMoveTargetingInstruction =>
      'Le premier robinet sur un hexagone trace l\'itinéraire. Appuyez de nouveau sur le même hexagone pour bouger; un itinéraire plus long est en attente pour les tours futurs.';

  @override
  String get modeBannerMoveTargetingCancelAction => 'Mouvement de sortie';

  @override
  String get modeBannerWorkerFindTileTitle => 'Travailleur: trouver une tuile';

  @override
  String modeBannerWorkerFindTileInstruction(String reason) {
    return '$reason Déplacez le travailleur dans une des tuiles de votre ville sans amélioration, ou sur un terrain qui correspond à une construction déverrouillée.';
  }

  @override
  String get modeBannerWorkerFindTileDetailOwnCity => 'Carrelage de la ville';

  @override
  String get modeBannerWorkerFindTileDetailNoImprovement =>
      'Aucune amélioration';

  @override
  String get modeBannerWorkerFindTileDetailMatchingTerrain =>
      'Terrains correspondants';

  @override
  String get modeBannerWorkerImproveTileTitle => 'Worker: améliorer la tuile';

  @override
  String get modeBannerWorkerImproveTileInstruction =>
      'Cette tuile peut être améliorée. Si vous voulez agir, utilisez la barre d\'outils inférieure, choisissez la meilleure compilation et validez-la dans le panneau inférieur.';

  @override
  String get modeBannerWorkerImproveTileDetailYields =>
      'Augmente les rendements en tuiles';

  @override
  String get modeBannerWorkerImproveTileDetailMovement =>
      'Utilisation des mouvements';

  @override
  String get modeBannerScoutExploreTitle => 'Scout: explorer';

  @override
  String get modeBannerScoutExploreInstruction =>
      'Activer l\'exploration à partir de la barre d\'outils inférieure afin que le scout découvre automatiquement les tuiles inconnues les plus proches. Vous pouvez l\'annuler plus tard des actions de l\'unité.';

  @override
  String get modeBannerScoutExploreDetailAuto => 'Exploration automatique';

  @override
  String get modeBannerScoutExploreDetailReveal => 'Révèle la carte';

  @override
  String get modeBannerSettlerFindSiteTitle => 'Settler: trouver un site';

  @override
  String modeBannerSettlerFindSiteInstruction(String reason) {
    return '$reason Déplacez le colon vers une tuile libre en dehors des frontières de la ville; évitez l\'eau, les montagnes et les centres occupés.';
  }

  @override
  String get modeBannerSettlerFindSiteDetailFreeHex => 'Hex libre';

  @override
  String get modeBannerSettlerFindSiteDetailOutsideBorders => 'Hors frontières';

  @override
  String get modeBannerSettlerFindSiteDetailLandOrCoast => 'Terrain ou côte';

  @override
  String get modeBannerSettlerFoundCityTitle => 'Settler: ville trouvée';

  @override
  String get modeBannerSettlerFoundCityInstruction =>
      'Cette tuile peut devenir une ville. Si vous voulez en trouver un, utilisez la barre d\'outils inférieure, puis choisissez les tuiles de départ de la ville sur la carte.';

  @override
  String get modeBannerSettlerFoundCityDetailNewCity => 'Nouvelle ville';

  @override
  String get modeBannerSettlerFoundCityDetailChooseTiles =>
      'Choisir les carreaux après avoir tapoté';

  @override
  String get modeBannerCityFoundingTitle => 'Trouvé une ville';

  @override
  String get modeBannerCityFoundingInstructionReady =>
      'Prêt. Confirmer la fondation de la ville dans la barre d\'outils inférieure ou modifier les carreaux sélectionnés sur la carte.';

  @override
  String modeBannerCityFoundingInstructionPick(int count) {
    return 'Choisissez les tuiles connectées $count autour du colon. Après les avoir choisies, l\'action de la ville trouvée sera disponible dans la barre d\'outils inférieure.';
  }

  @override
  String get selectionImprovementListTitle => 'Amélioration des carreaux';

  @override
  String get mapInspectionPossibleImprovementsTitle =>
      'Améliorations possibles';

  @override
  String get mapInspectionNoPossibleImprovements =>
      'Aucune amélioration possible';

  @override
  String get mapInspectionImprovementAvailableFromStart => 'dès le début';

  @override
  String get mapInspectionObjectiveTitle => 'Objectif cartographique';

  @override
  String get mapObjectiveRuins => 'Ruines';

  @override
  String get mapObjectiveStrategicPass => 'Pass stratégique';

  @override
  String get mapObjectiveHolySite => 'Site sacré';

  @override
  String get mapObjectiveLegendaryResource => 'Dépôt légendaire';

  @override
  String get mapObjectiveRuinsDescription =>
      'Un point d\'exploration neutre. La maintenir ajoute une pression de victoire.';

  @override
  String get mapObjectiveStrategicPassDescription =>
      'Un passage clé à travers le terrain. Le contrôle transforme le mouvement en levier.';

  @override
  String get mapObjectiveHolySiteDescription =>
      'Un site culturel important. Le contrôle accorde l\'or et les points de victoire.';

  @override
  String get mapObjectiveLegendaryResourceDescription =>
      'Un dépôt rare qui mérite une expansion ou un conflit. Le contrôle offre la plus grande récompense.';

  @override
  String mapObjectiveStatusNeutral(int turns) {
    return 'Maintenez les tours $turns';
  }

  @override
  String mapObjectiveStatusHolding(int held, int required) {
    return 'Exploitation de $held/$required';
  }

  @override
  String mapObjectiveStatusCompleted(int held, int required) {
    return 'Commande $held/$required';
  }

  @override
  String get mapObjectiveStatusContested => 'Concours';

  @override
  String mapObjectiveRewardVictoryPoints(int points) {
    return '+$points VP';
  }

  @override
  String mapObjectiveRewardGoldPerTurn(int gold) {
    return '+$gold or/tour';
  }

  @override
  String get selectionImprovementStateBuilt => 'BÂTIMENT';

  @override
  String get selectionImprovementStateAvailable => 'DISPONIBLE';

  @override
  String get selectionImprovementStateNeedsTechnology => 'TECH';

  @override
  String get selectionImprovementStateNeedsCity => 'VILLE';

  @override
  String get selectionImprovementStateBlocked => 'LIMITÉE';

  @override
  String get selectionImprovementNoBonus => 'Pas de bonus';

  @override
  String workerImprovementYieldFood(int value) {
    return '+$value aliments';
  }

  @override
  String workerImprovementYieldProduction(int value) {
    return 'Production +$value';
  }

  @override
  String workerImprovementYieldGold(int value) {
    return '+$value or';
  }

  @override
  String workerImprovementYieldDefense(int value) {
    return 'Défense +$value';
  }

  @override
  String get workerImprovementNoBonus => 'Pas de bonus.';

  @override
  String get workerImprovementOnlyWorker =>
      'Seul un ouvrier peut construire ça.';

  @override
  String get workerImprovementWorkerBusy =>
      'Le travailleur est déjà en construction.';

  @override
  String get workerImprovementStopQueuedMove =>
      'Arrêtez d\'abord le mouvement prévu.';

  @override
  String get workerImprovementMissingTile => 'Pas de tuile sous l\'unité.';

  @override
  String get workerImprovementMissingResource =>
      'Cette amélioration nécessite une ressource équivalente.';

  @override
  String get workerImprovementInvalidTerrain =>
      'Mauvais terrain de base pour cette amélioration.';

  @override
  String get workerImprovementMissingRiver =>
      'Cette amélioration nécessite une rivière.';

  @override
  String get workerImprovementBlocked => 'Cette action est bloquée maintenant.';

  @override
  String unitSelectionWorkerJobTurns(String name, int turns) {
    return '$name (${turns}T)';
  }

  @override
  String get resourceValueNoMatchingImprovement =>
      'Aucune amélioration correspondante';

  @override
  String get resourceValueSelectWorkerOrCity =>
      'Sélectionner un travailleur ou une ville';

  @override
  String get resourceValueTileAlreadyImproved => 'Tile a déjà une amélioration';

  @override
  String get resourceValueCityCenter => 'Centre-ville';

  @override
  String resourceValueWorksForCity(String city) {
    return 'Fonctionne pour: $city';
  }

  @override
  String get resourceValueOutsideCityBorders =>
      'En dehors des frontières de la ville';

  @override
  String get resourceValueNoLegalImprovementForTile =>
      'Aucune amélioration juridique pour cette tuile';

  @override
  String resourceValueRequiresTechnology(String technology) {
    return 'Nécessite: $technology';
  }

  @override
  String get resourceValueAvailableForWorker =>
      'Disponible pour les travailleurs';

  @override
  String get resourceDetailNoResourcesOnTile =>
      'Aucune ressource sur cette tuile';

  @override
  String get resourceDetailValueSection => 'Valeur';

  @override
  String get resourceDetailCurrentSection => 'Tout de suite';

  @override
  String get resourceDetailAfterImprovementSection => 'Après amélioration';

  @override
  String get resourceDetailYieldComparison => 'Rendement des carreaux';

  @override
  String get resourceDetailRequiresSection => 'Nécessaire';

  @override
  String get resourceDetailBestMoveSection => 'Meilleur mouvement';

  @override
  String get resourceDetailNoMatchingImprovementBody =>
      'Aucune amélioration correspondante pour cette ressource.';

  @override
  String get resourceDetailRequirementNoneCanBuild =>
      'Rien. Vous pouvez construire immédiatement.';

  @override
  String get resourceDetailRequirementOutsideCity =>
      'La tuile doit être à l\'intérieur des frontières de la ville.';

  @override
  String get resourceDetailRequirementAlreadyImproved =>
      'Rien. La tuile est déjà améliorée.';

  @override
  String get resourceDetailRequirementCityCenter =>
      'Aucun ouvrier ne construit dans le centre-ville.';

  @override
  String get resourceDetailRequirementSelectWorkerOrCity =>
      'Une sélection d\'ouvriers ou de villes.';

  @override
  String get resourceDetailRequirementNoLegalImprovement =>
      'Pas de construction disponible pour cette tuile.';

  @override
  String resourceDetailBestMoveRequiresTechnology(
    String technology,
    String improvement,
  ) {
    return 'Déverrouillez d\'abord $technology, puis créez $improvement.';
  }

  @override
  String resourceDetailBestMoveAvailable(String improvement) {
    return 'Envoyez un travailleur et construisez $improvement.';
  }

  @override
  String get resourceDetailBestMoveOutsideCity =>
      'Étendre les frontières de la ville ou trouver une ville plus proche de la ressource.';

  @override
  String get resourceDetailBestMoveAlreadyImproved =>
      'Gardez la tuile dans les frontières et travaillez-la quand elle correspond au plan de la ville.';

  @override
  String get resourceDetailBestMoveCityCenter =>
      'Traiter la ressource comme un centre-ville; les travailleurs n\'améliorent pas cette tuile.';

  @override
  String get resourceDetailBestMoveSelectWorkerOrCity =>
      'Sélectionnez un travailleur ou une ville pour vérifier la construction légale.';

  @override
  String get resourceDetailBestMoveNoLegalImprovement =>
      'Traiter la ressource comme une cible d\'expansion; il n\'y a pas de construction séparée ici.';

  @override
  String resourceValueUnlockedByTechnology(
    String technology,
    String improvement,
  ) {
    return 'Débloqué par $technology: $improvement.';
  }

  @override
  String resourceValueUnlocksFullYieldAfterTechnology(
    String technology,
    String improvement,
  ) {
    return 'Après $technology: $improvement déverrouille le rendement complet de la tuile.';
  }

  @override
  String resourceValueResearchBoostLine(String technology, String discount) {
    return 'Davantage de recherche: le contrôle de cette ressource accélère $technology (-$discount coût).';
  }

  @override
  String resourceValueTechnologyControlledResourceBonus(
    String technology,
    int production,
  ) {
    return 'Après $technology: +$production PROD pour chaque ressource contrôlée.';
  }

  @override
  String resourceValueNoBaseYieldSummary(String yield) {
    return 'La ressource elle-même n\'ajoute aucun rendement de base. L\'hexagone entier a maintenant $yield; la pleine valeur provient des améliorations et des déverrouillages.';
  }

  @override
  String resourceValueBaseYieldSummary(String resourceYield, String tileYield) {
    return 'La ressource donne $resourceYield. L\'hexagone entier a maintenant $tileYield avant l\'amélioration.';
  }

  @override
  String get resourceValueExpansionStrategic =>
      'C\'est une ressource stratégique pour la production, les armées ou les technologies ultérieures.';

  @override
  String get resourceValueExpansionFood =>
      'Une bonne cible d\'expansion pour la croissance de la ville: plus de nourriture signifie une population plus rapide et des tuiles plus travaillées.';

  @override
  String get resourceValueExpansionProduction =>
      'Une bonne cible d\'expansion pour le rythme de production: les bâtiments, les unités et la pression de la carte arrivent plus rapidement.';

  @override
  String get resourceValueExpansionTrade =>
      'Un bon objectif d\'expansion pour le commerce: après l\'amélioration, il soutient fortement l\'or et l\'entretien continu de la croissance.';

  @override
  String get resourceValueExpansionEconomy =>
      'Une bonne cible d\'expansion pour l\'économie: l\'or aide à maintenir les armées, à créer des réserves et à atteindre des buts de score serrés.';

  @override
  String resourceValueYieldFood(int amount) {
    return '+$amount ALIMENTS';
  }

  @override
  String resourceValueYieldProduction(int amount) {
    return '+$amount PROD';
  }

  @override
  String resourceValueYieldGold(int amount) {
    return '+$amount OR';
  }

  @override
  String resourceValueYieldDefense(int amount) {
    return '+$amount DEF';
  }

  @override
  String get resourceValueZeroBaseYield => '0 rendement de base';

  @override
  String get resourceValueCategoryBonus => 'Bonus';

  @override
  String get resourceValueCategoryLuxury => 'Luxe';

  @override
  String get resourceValueCategoryStrategic => 'Stratégie';

  @override
  String get resourceValueCategoryBonusFuture =>
      'La valeur fonctionne surtout tout de suite: une croissance plus rapide et un meilleur départ de la ville.';

  @override
  String get resourceValueCategoryLuxuryFuture =>
      'La valeur la plus élevée apparaît après la revendication à la frontière et l\'amélioration appropriée.';

  @override
  String get resourceValueCategoryStrategicFuture =>
      'Il s\'agit d\'une ressource stratégique: la sécuriser pour la production ultérieure et la pression militaire.';

  @override
  String get cityYieldBreakdownTitle => 'Économie urbaine';

  @override
  String cityYieldBreakdownSubtitle(String growth, String eta) {
    return 'Rendement/tour réel • croissance $growth • $eta';
  }

  @override
  String get cityYieldBreakdownProductionSources => 'Sources de production';

  @override
  String get cityYieldBreakdownScienceSources => 'Sources scientifiques';

  @override
  String get cityYieldBreakdownPerTurnSuffix => '/tourner';

  @override
  String get cityYieldBreakdownNoProduction => 'Pas de production';

  @override
  String get cityYieldBreakdownNoScience => 'Pas de science';

  @override
  String get cityYieldBreakdownCenter => 'Centre';

  @override
  String get cityYieldBreakdownPopulationFields => 'Champs de population';

  @override
  String get cityYieldBreakdownWorkers => 'Travailleurs';

  @override
  String get cityYieldBreakdownBuildings => 'Bâtiments';

  @override
  String get cityYieldBreakdownTechnologies => 'Technologies';

  @override
  String get cityYieldBreakdownSpecialization => 'Spécialisation';

  @override
  String get cityYieldBreakdownGoldMultiplier => 'multiplicateur d\'or';

  @override
  String get cityYieldBreakdownUpkeep => 'Entretien';

  @override
  String get cityYieldBreakdownFieldsBucket => 'Champs';

  @override
  String get cityYieldBreakdownCenterDetail => 'Rendement fixe du centre-ville';

  @override
  String get cityYieldBreakdownGoldMultiplierDetail =>
      'Pourcentage de bonus après la somme des sources d\'or';

  @override
  String get cityYieldBreakdownBaseScience => 'Ville';

  @override
  String get cityYieldBreakdownBaseScienceDetail =>
      'Science fixe générée par chaque ville';

  @override
  String get cityYieldBreakdownResearchProject => 'Projet de recherche';

  @override
  String get cityYieldBreakdownResearchProjectDetail =>
      'Production urbaine actuelle convertie en science';

  @override
  String get cityYieldBreakdownScienceSpecializationDetail =>
      'Profil scientifique de la ville';

  @override
  String get cityYieldBreakdownScienceTechnologyDetail =>
      'Bonus scientifique des technologies débloquées';

  @override
  String get cityYieldBreakdownNoWorkedPopulationFields =>
      'Pas de zones de population occupées';

  @override
  String get cityYieldBreakdownOneWorkedPopulationField =>
      '1 domaine de la population active';

  @override
  String cityYieldBreakdownManyWorkedPopulationFields(int count) {
    return '$count zones de population occupées';
  }

  @override
  String get cityYieldBreakdownNoAssignedWorkers =>
      'Pas de travailleurs affectés';

  @override
  String get cityYieldBreakdownOneAssignedWorker =>
      '1 champ activé par un travailleur';

  @override
  String cityYieldBreakdownManyAssignedWorkers(int count) {
    return 'Champs $count activés par les travailleurs';
  }

  @override
  String get cityYieldBreakdownNoPassiveImprovements =>
      'Aucune amélioration passive';

  @override
  String get cityYieldBreakdownOnePassiveImprovement =>
      '1 amélioration non travaillée, demi rendement';

  @override
  String cityYieldBreakdownManyPassiveImprovements(int count) {
    return '$count améliorations non travaillées, demi rendement';
  }

  @override
  String get cityYieldBreakdownNoBuildings => 'Pas de bâtiments';

  @override
  String get cityYieldBreakdownBuildingsNoDirectYield =>
      'Bâtiments sans rendement direct';

  @override
  String get cityYieldBreakdownOneBuildingEconomicEffect =>
      '1 bâtiment à effet économique';

  @override
  String cityYieldBreakdownManyBuildingEconomicEffects(int count) {
    return 'Bâtiments $count ayant des effets économiques';
  }

  @override
  String get cityYieldBreakdownNoTechnologyYield =>
      'Pas de bonus de rendement technologique';

  @override
  String get cityYieldBreakdownTechnologyYield =>
      'Bonus des technologies déverrouillées';

  @override
  String get cityYieldBreakdownNoScienceBuildings =>
      'Pas de bâtiments scientifiques';

  @override
  String get cityYieldBreakdownOneScienceBuilding => '1 bâtiment scientifique';

  @override
  String cityYieldBreakdownManyScienceBuildings(int count) {
    return '$count bâtiments scientifiques avec des rendements décroissants';
  }

  @override
  String cityYieldBreakdownGrowthFood(int storedFood, int growthCost) {
    return '$storedFood/$growthCost aliment';
  }

  @override
  String get cityYieldBreakdownStagnation => 'stagnation';

  @override
  String cityYieldBreakdownUpkeepBlocked(int population, int cost) {
    return 'Population $population: coût $cost, arrêt de la croissance';
  }

  @override
  String cityYieldBreakdownUpkeepCost(int population) {
    return 'Entretien des aliments pour la population $population';
  }

  @override
  String get cityYieldBreakdownGrowthSpecializationDetail =>
      'Profil de croissance de la ville';

  @override
  String get cityYieldBreakdownIndustrySpecializationDetail =>
      'Profil de l\'industrie urbaine';

  @override
  String get cityYieldBreakdownCommerceSpecializationDetail =>
      'Profil commercial de la ville';

  @override
  String get cityYieldBreakdownScienceSpecializationCityDetail =>
      'Profil scientifique de la ville';

  @override
  String get cityYieldBreakdownMilitarySpecializationDetail =>
      'Profil de la garnison';

  @override
  String get cityYieldBreakdownNoSpecialization => 'Pas de spécialisation';

  @override
  String get cityProjectWealth => 'Richesse';

  @override
  String get cityProjectResearch => 'Recherche';

  @override
  String get cityProductionProjectsSection => 'Projets urbains';

  @override
  String get cityProductionSpecializationSection => 'Spécialisation urbaine';

  @override
  String get cityProductionSortLabel => 'Tri';

  @override
  String cityProductionHeaderSubtitle(
    String title,
    String productionPerTurn,
    int gold,
  ) {
    return '$title • $productionPerTurn • Or $gold';
  }

  @override
  String get cityProductionBuiltLabel => 'Construit';

  @override
  String get cityProductionAvailableLabel => 'Disponible';

  @override
  String get cityProductionAvailableUnitLabel => 'Disponible';

  @override
  String cityProductionUnitSupplyLimit(int used, int capacity) {
    return 'Limite alimentaire $used/$capacity';
  }

  @override
  String cityProductionUnitSupplyCost(int cost) {
    return 'aliments $cost';
  }

  @override
  String cityProductionUnitSupplyUsed(int used, int capacity) {
    return 'limite $used/$capacity';
  }

  @override
  String cityProductionNextWorkerUpkeep(int upkeep) {
    return 'prochain entretien: $upkeep';
  }

  @override
  String cityProductionCostShort(int production) {
    return '$production prod.';
  }

  @override
  String cityProductionPaceShort(int production) {
    return '$production prod./tour';
  }

  @override
  String get cityBuildingSortRecommended => 'Recommandation';

  @override
  String cityBuildingReplaceProgressWarning(String building) {
    return 'Choisir un autre bâtiment remplacera $building. Les progrès seront préservés.';
  }

  @override
  String get cityBuildingSortFastestImpact => 'Impact le plus rapide';

  @override
  String get cityBuildingSortBestReturn => 'Meilleur retour';

  @override
  String get cityBuildingSortGrowth => 'Croissance';

  @override
  String get cityBuildingSortIndustry => 'Industrie';

  @override
  String get cityBuildingSortScience => 'Science';

  @override
  String get cityBuildingSortDefenseMilitary => 'Défense / militaire';

  @override
  String get cityBuildingSortEconomy => 'Économie';

  @override
  String get cityBuildingRequiresTechnology => 'Nécessite une technologie';

  @override
  String get cityProductionContinuous => 'continu';

  @override
  String get cityProductionNoProduction => 'pas de production';

  @override
  String get cityProductionReady => 'Prêt';

  @override
  String get cityProductionTurnOne => '1 tour';

  @override
  String cityProductionTurns(int turns) {
    return 'Tours $turns';
  }

  @override
  String cityProductionTreasuryGold(int gold) {
    return 'Trésorerie: or $gold';
  }

  @override
  String cityProductionRushAction(int gold) {
    return 'Rush -$gold';
  }

  @override
  String cityProjectGoldPerTurn(int gold) {
    return '+$gold or / tour';
  }

  @override
  String cityProjectSciencePerTurn(int science) {
    return '+$science science / tour';
  }

  @override
  String get citySpecializationGrowth => 'Croissance';

  @override
  String get citySpecializationIndustry => 'Industrie';

  @override
  String get citySpecializationCommerce => 'Commerce';

  @override
  String get citySpecializationMilitary => 'Garrison';

  @override
  String get citySpecializationGrowthBonus => '+2 aliments';

  @override
  String get citySpecializationIndustryBonus => '+2 production';

  @override
  String get citySpecializationCommerceBonus => '+3 or';

  @override
  String get citySpecializationScienceBonus => '+2 sciences';

  @override
  String get citySpecializationMilitaryProductionBonus => '+1 production';

  @override
  String get citySpecializationMilitaryDefenseBonus => '+2 défense';

  @override
  String get citySpecializationMilitaryUnitProductionBonus => '+1 unité prod.';

  @override
  String get citySpecializationBestFit => 'Meilleur ajustement';

  @override
  String get eventCityFoundedTitle => 'Ville fondée';

  @override
  String get eventCityBuiltBuildingTitle => 'Construction terminée';

  @override
  String get eventCityProducedUnitTitle => 'Unité formée';

  @override
  String get eventCityClaimedHexTitle => 'Frontières de la ville';

  @override
  String eventCityClaimedHexBody(String cityName) {
    return '$cityName: nouvelle tuile';
  }

  @override
  String get eventUnitMovedTitle => 'Mouvement unitaire';

  @override
  String get eventUnitPromotedTitle => 'Unité promue';

  @override
  String get eventUnitExperienceTitle => 'Expérience';

  @override
  String eventUnitExperienceBody(String unitName, int amount, String rank) {
    return '$unitName: +$amount XP ($rank)';
  }

  @override
  String get eventUnitAttackedTitle => 'Attaque';

  @override
  String get eventCombatTitle => 'Lutte';

  @override
  String eventCombatDamageLine(String unitName, int damage, String result) {
    return '$unitName: -$damage HP -> $result';
  }

  @override
  String eventCombatNoRetaliationLine(String unitName) {
    return '$unitName: pas de représailles';
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
    return '$attackerName ($attackerCountry) a attaqué $defenderName ($defenderCountry) - HP $attackerHp:$defenderHp';
  }

  @override
  String get eventDiplomaticProposalAcceptedStatus => 'Acceptée';

  @override
  String get eventDiplomaticProposalRejectedStatus => 'Décliné';

  @override
  String get eventDiplomaticProposalExpiredStatus => 'Expiré';

  @override
  String get eventUnitKilledTitle => 'Unité vaincue';

  @override
  String get eventUnitRetreatedTitle => 'Retraite';

  @override
  String get eventCityCapturedTitle => 'Ville capturée';

  @override
  String get eventCityDestroyedTitle => 'Ville détruite';

  @override
  String get eventTurnEndedTitle => 'Fin du tour';

  @override
  String get eventWorkerCompletedJobTitle => 'Travaux terminés';

  @override
  String get eventResearchPointsTitle => 'Science';

  @override
  String eventResearchPointsBody(String playerName, int points) {
    return '$playerName: +$points science';
  }

  @override
  String get eventTechnologyResearchedTitle => 'Technologie découverte';

  @override
  String get eventStrategicResourceDiscoveredTitle =>
      'Ressources stratégiques découvertes';

  @override
  String eventStrategicResourceDiscoveredBody(
    String playerName,
    String resourceName,
  ) {
    return '$playerName: $resourceName';
  }

  @override
  String eventStrategicResourceControlledDetail(int count) {
    return 'Contrôle: $count';
  }

  @override
  String eventStrategicResourceRivalDetail(int count) {
    return 'Rivales: $count';
  }

  @override
  String eventStrategicResourceUnclaimedDetail(int count) {
    return 'Non réclamé: $count';
  }

  @override
  String get eventStrategicResourcePressureSecured =>
      'Approvisionnement sécurisé; défendre la source.';

  @override
  String get eventStrategicResourcePressureExpansionRace =>
      'Course de règlement: demander le dépôt le plus proche devant les rivaux.';

  @override
  String get eventStrategicResourcePressureContested =>
      'Approvisionnement contesté: les rivaux contrôlent également les sources.';

  @override
  String get eventStrategicResourcePressureRivalMonopoly =>
      'Monopole rival: préparer le commerce ou une expédition.';

  @override
  String eventStrategicResourceSettleHint(int col, int row) {
    return 'Dépôt en dehors des frontières à $col:$row; envisager de fonder une ville.';
  }

  @override
  String get eventMapObjectiveSecuredTitle => 'Objectif de la carte';

  @override
  String eventMapObjectiveSecuredBody(String playerName, String objectiveName) {
    return '$playerName: $objectiveName';
  }

  @override
  String eventMapObjectiveHoldDetail(int holdTurns, int requiredHoldTurns) {
    return 'Arrêt: $holdTurns/$requiredHoldTurns';
  }

  @override
  String eventMapObjectiveLocationDetail(int col, int row) {
    return 'Fonction: $col:$row';
  }

  @override
  String eventMapObjectiveVictoryRewardDetail(int points) {
    return 'Points de victoire +$points';
  }

  @override
  String eventMapObjectiveGoldRewardDetail(int gold) {
    return '+$gold or/tour';
  }

  @override
  String get eventCivilizationMetTitle => 'Nouvelle civilisation';

  @override
  String eventCivilizationMetBody(String civilizationName, String playerName) {
    return '$civilizationName ($playerName)';
  }

  @override
  String get civilizationMetPopupEyebrow => 'Civilisation rencontrée';

  @override
  String civilizationMetPopupBody(String civilizationName) {
    return 'La civilisation de $civilizationName est apparue à l\'horizon. Un nouveau voisin, rival ou futur allié fait maintenant partie de votre monde.';
  }

  @override
  String get civilizationMetPopupOk => 'Très bien.';

  @override
  String get eventCommandRejectedTitle => 'Commande rejetée';

  @override
  String get eventAllPlayersSubmittedTitle => 'Tout le monde est prêt';

  @override
  String eventAllPlayersSubmittedBody(int turn, int players) {
    return 'Tourner $turn ($players)';
  }

  @override
  String get eventPlayerTimedOutTitle => 'Soumettre automatiquement';

  @override
  String eventPlayerTimedOutBody(String playerName, int turn) {
    return '$playerName: désactivé au tour $turn';
  }

  @override
  String get eventCombatDefenderKilledDetail => 'Défendeur vaincu';

  @override
  String get eventCombatAttackerKilledDetail => 'Attaque vaincu';

  @override
  String get eventCombatDefenderRetreatedDetail => 'Le défenseur a reculé';

  @override
  String eventCombatAttackDamageDetail(int damage) {
    return 'Attaque: -$damage HP';
  }

  @override
  String eventCombatRetaliationDamageDetail(int damage) {
    return 'Rétorsion: -$damage HP';
  }

  @override
  String eventCombatRollDetail(int value) {
    return 'Rouleaux $value';
  }

  @override
  String get eventCombatNoRetaliationDetail => 'Pas de représailles';

  @override
  String get eventDominationStartedTitle => 'La domination a commencé';

  @override
  String get eventDominationRivalAboveTitle => 'Rival au-dessus du seuil';

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
    return 'Tourne $held/$required';
  }

  @override
  String get eventDominationReadyDetail => 'État prêt';

  @override
  String eventDominationKeepHoldingDetail(String turns) {
    return 'Tenez pour $turns plus';
  }

  @override
  String eventDominationInterruptDetail(String turns) {
    return 'Interruption dans $turns';
  }

  @override
  String eventTurnCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tours',
      one: '1 tour',
      zero: '0 tour',
    );
    return '$_temp0';
  }

  @override
  String get eventCombatDefeatedResult => 'défaite';

  @override
  String eventCombatDefenderRetreatedResult(int hp) {
    return '$hp HP, retraite';
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
    return 'Technologie $technology';
  }

  @override
  String eventCombatRankModifierLabel(Object rank) {
    return 'Classement $rank';
  }

  @override
  String get eventCombatCityGarrisonModifier => 'Garçon de ville';

  @override
  String get eventCombatMixedArmyModifier => 'Armée mixte';

  @override
  String get eventCombatStatAttack => 'attaque';

  @override
  String get eventCombatStatDefense => 'défense';

  @override
  String get eventCombatStatHp => 'HP';

  @override
  String get eventCombatStatRange => 'plage';

  @override
  String get eventCombatStatMobility => 'mouvement';

  @override
  String get closeAction => 'Fermer';
}
