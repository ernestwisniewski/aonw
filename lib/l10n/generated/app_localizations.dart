import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('nl'),
    Locale('pl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Age of New Worlds'**
  String get appTitle;

  /// No description provided for @defaultPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Player {index}'**
  String defaultPlayerName(int index);

  /// No description provided for @defaultCityName.
  ///
  /// In en, this message translates to:
  /// **'City {index}'**
  String defaultCityName(int index);

  /// No description provided for @newGameTitle.
  ///
  /// In en, this message translates to:
  /// **'NEW GAME'**
  String get newGameTitle;

  /// No description provided for @gameModeSinglePlayerMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Singleplayer'**
  String get gameModeSinglePlayerMenuLabel;

  /// No description provided for @gameModeMultiplayerMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Multiplayer'**
  String get gameModeMultiplayerMenuLabel;

  /// No description provided for @gameModeHotSeatMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Hot Seat'**
  String get gameModeHotSeatMenuLabel;

  /// No description provided for @gameModeSinglePlayerSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Singleplayer'**
  String get gameModeSinglePlayerSummaryLabel;

  /// No description provided for @gameModeMultiplayerSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Multiplayer'**
  String get gameModeMultiplayerSummaryLabel;

  /// No description provided for @gameModeHotSeatSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Hot Seat'**
  String get gameModeHotSeatSummaryLabel;

  /// No description provided for @gameModeSinglePlayerMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a map for solo play'**
  String get gameModeSinglePlayerMapTitle;

  /// No description provided for @gameModeMultiplayerMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a map for online play'**
  String get gameModeMultiplayerMapTitle;

  /// No description provided for @gameModeHotSeatMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a map for hot seat play'**
  String get gameModeHotSeatMapTitle;

  /// No description provided for @gameModeSinglePlayerMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A local match against AI.'**
  String get gameModeSinglePlayerMapSubtitle;

  /// No description provided for @gameModeMultiplayerMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Starting scenario and world map for an online match.'**
  String get gameModeMultiplayerMapSubtitle;

  /// No description provided for @gameModeHotSeatMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Starting scenario and world map for one-device hot seat play.'**
  String get gameModeHotSeatMapSubtitle;

  /// No description provided for @newGameIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare the expedition'**
  String get newGameIntroTitle;

  /// No description provided for @newGameIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the play style first, then the map, then refine players and match pace.'**
  String get newGameIntroSubtitle;

  /// No description provided for @newGameStepPlan.
  ///
  /// In en, this message translates to:
  /// **'Game plan'**
  String get newGameStepPlan;

  /// No description provided for @newGameStepMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get newGameStepMap;

  /// No description provided for @newGameStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get newGameStepReview;

  /// No description provided for @newGamePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'What story do you want to begin?'**
  String get newGamePlanTitle;

  /// No description provided for @newGamePremiseTitle.
  ///
  /// In en, this message translates to:
  /// **'From settlement to empire'**
  String get newGamePremiseTitle;

  /// No description provided for @newGamePremiseBody.
  ///
  /// In en, this message translates to:
  /// **'Every match starts with a few decisive choices: where to found the first city, how to shape research, when to risk expansion, and how to hold map control.'**
  String get newGamePremiseBody;

  /// No description provided for @newGameCountryTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose civilization'**
  String get newGameCountryTitle;

  /// No description provided for @newGameCountrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your ruler name follows the civilization you choose.'**
  String get newGameCountrySubtitle;

  /// No description provided for @newGameSinglePlayerSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Match settings'**
  String get newGameSinglePlayerSettingsTitle;

  /// No description provided for @newGameGameLengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Game length'**
  String get newGameGameLengthLabel;

  /// No description provided for @newGameLeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'LEADER'**
  String get newGameLeaderLabel;

  /// No description provided for @newGamePillarCities.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get newGamePillarCities;

  /// No description provided for @newGamePillarUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get newGamePillarUnits;

  /// No description provided for @newGamePillarResearch.
  ///
  /// In en, this message translates to:
  /// **'Research'**
  String get newGamePillarResearch;

  /// No description provided for @newGameVictoryTypesTitle.
  ///
  /// In en, this message translates to:
  /// **'Victory paths'**
  String get newGameVictoryTypesTitle;

  /// No description provided for @newGameVictoryDominationTitle.
  ///
  /// In en, this message translates to:
  /// **'Domination'**
  String get newGameVictoryDominationTitle;

  /// No description provided for @newGameVictoryDominationBody.
  ///
  /// In en, this message translates to:
  /// **'Control {controlPercent}% of the map and hold it for {holdTurns} turns. Conquest can still end the match by eliminating rivals.'**
  String newGameVictoryDominationBody(String controlPercent, int holdTurns);

  /// No description provided for @newGameVictoryArtifactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Artifacts'**
  String get newGameVictoryArtifactsTitle;

  /// No description provided for @newGameVictoryArtifactsBody.
  ///
  /// In en, this message translates to:
  /// **'Place {artifactCount} unique world artifacts in your cities and keep the full collection for {holdTurns} turns.'**
  String newGameVictoryArtifactsBody(int artifactCount, int holdTurns);

  /// No description provided for @newGameModeSinglePlayerDescription.
  ///
  /// In en, this message translates to:
  /// **'A calm match against AI. Best for learning systems, testing starts, and experimenting with growth.'**
  String get newGameModeSinglePlayerDescription;

  /// No description provided for @newGameModeMultiplayerDescription.
  ///
  /// In en, this message translates to:
  /// **'An online match with network lobby, player readiness, and a shared entry onto the map.'**
  String get newGameModeMultiplayerDescription;

  /// No description provided for @newGameModeMultiplayerAlphaDisabled.
  ///
  /// In en, this message translates to:
  /// **'Unavailable in the alpha release.'**
  String get newGameModeMultiplayerAlphaDisabled;

  /// No description provided for @newGameModeHotSeatDescription.
  ///
  /// In en, this message translates to:
  /// **'Hot seat play on one device. Players pass the turn, while the screen guides each handoff.'**
  String get newGameModeHotSeatDescription;

  /// No description provided for @newGameMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the world'**
  String get newGameMapTitle;

  /// No description provided for @newGameMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The map defines first-contact pace, available resources, city space, and the shape of conflict.'**
  String get newGameMapSubtitle;

  /// No description provided for @newGameReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm the expedition'**
  String get newGameReviewTitle;

  /// No description provided for @newGameReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'After confirming, you will enter the lobby to set game name, match length, and players.'**
  String get newGameReviewSubtitle;

  /// No description provided for @newGameReviewSinglePlayerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Singleplayer starts immediately with you and {aiCount} AI players.'**
  String newGameReviewSinglePlayerSubtitle(int aiCount);

  /// No description provided for @newGameReviewMissingMap.
  ///
  /// In en, this message translates to:
  /// **'Choose a map before configuring players.'**
  String get newGameReviewMissingMap;

  /// No description provided for @newGameExpeditionReady.
  ///
  /// In en, this message translates to:
  /// **'Expedition ready'**
  String get newGameExpeditionReady;

  /// No description provided for @newGameSelectedMapLabel.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get newGameSelectedMapLabel;

  /// No description provided for @newGameMapPickLabel.
  ///
  /// In en, this message translates to:
  /// **'Map pick'**
  String get newGameMapPickLabel;

  /// No description provided for @newGameMapPickRandom.
  ///
  /// In en, this message translates to:
  /// **'Random default'**
  String get newGameMapPickRandom;

  /// No description provided for @newGameMapPickManual.
  ///
  /// In en, this message translates to:
  /// **'Chosen manually'**
  String get newGameMapPickManual;

  /// No description provided for @newGameWorldSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get newGameWorldSourceLabel;

  /// No description provided for @newGameSinglePlayerAiSummary.
  ///
  /// In en, this message translates to:
  /// **'You + {aiCount} AI'**
  String newGameSinglePlayerAiSummary(int aiCount);

  /// No description provided for @newGameChangeMapAction.
  ///
  /// In en, this message translates to:
  /// **'Change map'**
  String get newGameChangeMapAction;

  /// No description provided for @newGameStartSetupAction.
  ///
  /// In en, this message translates to:
  /// **'Go to lobby'**
  String get newGameStartSetupAction;

  /// No description provided for @mainMenuLoadGame.
  ///
  /// In en, this message translates to:
  /// **'Load game'**
  String get mainMenuLoadGame;

  /// No description provided for @mainMenuDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get mainMenuDeveloper;

  /// No description provided for @mainMenuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get mainMenuSettings;

  /// No description provided for @mainMenuSettingsSublabel.
  ///
  /// In en, this message translates to:
  /// **'Text and audio'**
  String get mainMenuSettingsSublabel;

  /// No description provided for @mainMenuExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get mainMenuExit;

  /// No description provided for @mainMenuAiSublabel.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get mainMenuAiSublabel;

  /// No description provided for @mainMenuOnlineSublabel.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get mainMenuOnlineSublabel;

  /// No description provided for @mainMenuLocalSublabel.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get mainMenuLocalSublabel;

  /// No description provided for @mainMenuToolsSublabel.
  ///
  /// In en, this message translates to:
  /// **'Editors'**
  String get mainMenuToolsSublabel;

  /// No description provided for @mainMenuToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get mainMenuToolsTitle;

  /// No description provided for @mainMenuMapEditor.
  ///
  /// In en, this message translates to:
  /// **'Map editor'**
  String get mainMenuMapEditor;

  /// No description provided for @mainMenuAssetsEditor.
  ///
  /// In en, this message translates to:
  /// **'Asset editor'**
  String get mainMenuAssetsEditor;

  /// No description provided for @mainMenuTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get mainMenuTextSize;

  /// No description provided for @mainMenuTextSample.
  ///
  /// In en, this message translates to:
  /// **'Sample game text'**
  String get mainMenuTextSample;

  /// No description provided for @mainMenuManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get mainMenuManual;

  /// No description provided for @mainMenuCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get mainMenuCredits;

  /// No description provided for @mainMenuFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get mainMenuFeedback;

  /// No description provided for @manualTitle.
  ///
  /// In en, this message translates to:
  /// **'Controls manual'**
  String get manualTitle;

  /// No description provided for @manualSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A quick reference for map movement, selection, orders, panels, and turn flow across desktop and mobile.'**
  String get manualSubtitle;

  /// No description provided for @manualMetaDesktop.
  ///
  /// In en, this message translates to:
  /// **'Desktop'**
  String get manualMetaDesktop;

  /// No description provided for @manualMetaMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get manualMetaMobile;

  /// No description provided for @manualMetaAlpha.
  ///
  /// In en, this message translates to:
  /// **'Single-player alpha'**
  String get manualMetaAlpha;

  /// No description provided for @manualCommandLoopTitle.
  ///
  /// In en, this message translates to:
  /// **'Core command loop'**
  String get manualCommandLoopTitle;

  /// No description provided for @manualCommandLoopSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get manualCommandLoopSelectTitle;

  /// No description provided for @manualCommandLoopSelectBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a unit, city, artifact, or map tile to reveal the actions that matter now.'**
  String get manualCommandLoopSelectBody;

  /// No description provided for @manualCommandLoopPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get manualCommandLoopPreviewTitle;

  /// No description provided for @manualCommandLoopPreviewBody.
  ///
  /// In en, this message translates to:
  /// **'Hover or tap once to inspect targets, intent colors, routes, and blocked actions.'**
  String get manualCommandLoopPreviewBody;

  /// No description provided for @manualCommandLoopConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get manualCommandLoopConfirmTitle;

  /// No description provided for @manualCommandLoopConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Use an action chip or choose the highlighted target again to commit the order.'**
  String get manualCommandLoopConfirmBody;

  /// No description provided for @manualCommandLoopAdvanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get manualCommandLoopAdvanceTitle;

  /// No description provided for @manualCommandLoopAdvanceBody.
  ///
  /// In en, this message translates to:
  /// **'Use the bottom action button to jump to the next decision or finish the turn.'**
  String get manualCommandLoopAdvanceBody;

  /// No description provided for @manualDesktopTitle.
  ///
  /// In en, this message translates to:
  /// **'Desktop controls'**
  String get manualDesktopTitle;

  /// No description provided for @manualDesktopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mouse-first play with fast map inspection, precise targeting, and persistent panels.'**
  String get manualDesktopSubtitle;

  /// No description provided for @manualMobileTitle.
  ///
  /// In en, this message translates to:
  /// **'Mobile controls'**
  String get manualMobileTitle;

  /// No description provided for @manualMobileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Touch-first play tuned for readable panels, deliberate orders, and quick turn flow.'**
  String get manualMobileSubtitle;

  /// No description provided for @manualMapCameraGroup.
  ///
  /// In en, this message translates to:
  /// **'Map & camera'**
  String get manualMapCameraGroup;

  /// No description provided for @manualOrdersGroup.
  ///
  /// In en, this message translates to:
  /// **'Selection & orders'**
  String get manualOrdersGroup;

  /// No description provided for @manualPanelsGroup.
  ///
  /// In en, this message translates to:
  /// **'Panels & help'**
  String get manualPanelsGroup;

  /// No description provided for @manualTurnFlowGroup.
  ///
  /// In en, this message translates to:
  /// **'Turn flow'**
  String get manualTurnFlowGroup;

  /// No description provided for @manualDesktopLeftClickAction.
  ///
  /// In en, this message translates to:
  /// **'Left click'**
  String get manualDesktopLeftClickAction;

  /// No description provided for @manualDesktopLeftClickBody.
  ///
  /// In en, this message translates to:
  /// **'Select units, cities, artifacts, and tiles; with an active order, choose the target.'**
  String get manualDesktopLeftClickBody;

  /// No description provided for @manualDesktopDragAction.
  ///
  /// In en, this message translates to:
  /// **'Drag the map'**
  String get manualDesktopDragAction;

  /// No description provided for @manualDesktopDragBody.
  ///
  /// In en, this message translates to:
  /// **'Pan the camera without changing the current selection or command mode.'**
  String get manualDesktopDragBody;

  /// No description provided for @manualDesktopZoomAction.
  ///
  /// In en, this message translates to:
  /// **'Mouse wheel / trackpad'**
  String get manualDesktopZoomAction;

  /// No description provided for @manualDesktopZoomBody.
  ///
  /// In en, this message translates to:
  /// **'Zoom between strategic overview and tactical detail on the map.'**
  String get manualDesktopZoomBody;

  /// No description provided for @manualDesktopHoverAction.
  ///
  /// In en, this message translates to:
  /// **'Hover'**
  String get manualDesktopHoverAction;

  /// No description provided for @manualDesktopHoverBody.
  ///
  /// In en, this message translates to:
  /// **'Preview tooltips, target hints, and blocked-order reasons before committing.'**
  String get manualDesktopHoverBody;

  /// No description provided for @manualDesktopActionChipsAction.
  ///
  /// In en, this message translates to:
  /// **'Action chips'**
  String get manualDesktopActionChipsAction;

  /// No description provided for @manualDesktopActionChipsBody.
  ///
  /// In en, this message translates to:
  /// **'Move, attack, improve, found a city, skip, fortify, or cancel the current mode.'**
  String get manualDesktopActionChipsBody;

  /// No description provided for @manualDesktopSecondClickAction.
  ///
  /// In en, this message translates to:
  /// **'Same target twice'**
  String get manualDesktopSecondClickAction;

  /// No description provided for @manualDesktopSecondClickBody.
  ///
  /// In en, this message translates to:
  /// **'For movement, the first click previews the route; the second click executes or queues it.'**
  String get manualDesktopSecondClickBody;

  /// No description provided for @manualDesktopHoldAction.
  ///
  /// In en, this message translates to:
  /// **'Click and hold'**
  String get manualDesktopHoldAction;

  /// No description provided for @manualDesktopHoldBody.
  ///
  /// In en, this message translates to:
  /// **'Open detailed command explanations for actions, disabled options, and context chips.'**
  String get manualDesktopHoldBody;

  /// No description provided for @manualDesktopRailAction.
  ///
  /// In en, this message translates to:
  /// **'Left rail'**
  String get manualDesktopRailAction;

  /// No description provided for @manualDesktopRailBody.
  ///
  /// In en, this message translates to:
  /// **'Open map options, help, objectives, activity log, research, and empire panels.'**
  String get manualDesktopRailBody;

  /// No description provided for @manualDesktopTopPillsAction.
  ///
  /// In en, this message translates to:
  /// **'Top resources'**
  String get manualDesktopTopPillsAction;

  /// No description provided for @manualDesktopTopPillsBody.
  ///
  /// In en, this message translates to:
  /// **'Inspect economy, science, resources, and victory pressure breakdowns.'**
  String get manualDesktopTopPillsBody;

  /// No description provided for @manualDesktopCloseAction.
  ///
  /// In en, this message translates to:
  /// **'Click outside'**
  String get manualDesktopCloseAction;

  /// No description provided for @manualDesktopCloseBody.
  ///
  /// In en, this message translates to:
  /// **'Close popups, option panels, and help cards, then return focus to the map.'**
  String get manualDesktopCloseBody;

  /// No description provided for @manualDesktopHelpAction.
  ///
  /// In en, this message translates to:
  /// **'?'**
  String get manualDesktopHelpAction;

  /// No description provided for @manualDesktopHelpBody.
  ///
  /// In en, this message translates to:
  /// **'Open every minimized hint and tutorial card at any time, regardless of selection.'**
  String get manualDesktopHelpBody;

  /// No description provided for @manualDesktopTurnAction.
  ///
  /// In en, this message translates to:
  /// **'Next decision'**
  String get manualDesktopTurnAction;

  /// No description provided for @manualDesktopTurnBody.
  ///
  /// In en, this message translates to:
  /// **'Focus the next unit, research, or city choice; end the turn when nothing blocks progress.'**
  String get manualDesktopTurnBody;

  /// No description provided for @manualMobileTapAction.
  ///
  /// In en, this message translates to:
  /// **'Tap'**
  String get manualMobileTapAction;

  /// No description provided for @manualMobileTapBody.
  ///
  /// In en, this message translates to:
  /// **'Select units, cities, artifacts, and tiles; with an active order, choose the target.'**
  String get manualMobileTapBody;

  /// No description provided for @manualMobileDragAction.
  ///
  /// In en, this message translates to:
  /// **'One-finger drag'**
  String get manualMobileDragAction;

  /// No description provided for @manualMobileDragBody.
  ///
  /// In en, this message translates to:
  /// **'Pan the camera while keeping the selected unit or panel state intact.'**
  String get manualMobileDragBody;

  /// No description provided for @manualMobilePinchAction.
  ///
  /// In en, this message translates to:
  /// **'Pinch'**
  String get manualMobilePinchAction;

  /// No description provided for @manualMobilePinchBody.
  ///
  /// In en, this message translates to:
  /// **'Zoom the map for scouting, city work, movement planning, or battle targeting.'**
  String get manualMobilePinchBody;

  /// No description provided for @manualMobileSecondTapAction.
  ///
  /// In en, this message translates to:
  /// **'Same target twice'**
  String get manualMobileSecondTapAction;

  /// No description provided for @manualMobileSecondTapBody.
  ///
  /// In en, this message translates to:
  /// **'Preview a movement route first, then tap the same hex again to execute or queue it.'**
  String get manualMobileSecondTapBody;

  /// No description provided for @manualMobileActionChipsAction.
  ///
  /// In en, this message translates to:
  /// **'Action chips'**
  String get manualMobileActionChipsAction;

  /// No description provided for @manualMobileActionChipsBody.
  ///
  /// In en, this message translates to:
  /// **'Use the bottom command row for unit orders, city choices, workers, and cancel actions.'**
  String get manualMobileActionChipsBody;

  /// No description provided for @manualMobileHoldAction.
  ///
  /// In en, this message translates to:
  /// **'Press and hold'**
  String get manualMobileHoldAction;

  /// No description provided for @manualMobileHoldBody.
  ///
  /// In en, this message translates to:
  /// **'Open explanations for commands, disabled options, resources, and contextual UI.'**
  String get manualMobileHoldBody;

  /// No description provided for @manualMobileScrollAction.
  ///
  /// In en, this message translates to:
  /// **'Scroll panels'**
  String get manualMobileScrollAction;

  /// No description provided for @manualMobileScrollBody.
  ///
  /// In en, this message translates to:
  /// **'Browse long city, research, log, diplomacy, and help lists without losing map state.'**
  String get manualMobileScrollBody;

  /// No description provided for @manualMobileRailAction.
  ///
  /// In en, this message translates to:
  /// **'Left rail'**
  String get manualMobileRailAction;

  /// No description provided for @manualMobileRailBody.
  ///
  /// In en, this message translates to:
  /// **'Tap to open map options, help, objectives, activity log, research, and empire panels.'**
  String get manualMobileRailBody;

  /// No description provided for @manualMobileHelpAction.
  ///
  /// In en, this message translates to:
  /// **'?'**
  String get manualMobileHelpAction;

  /// No description provided for @manualMobileHelpBody.
  ///
  /// In en, this message translates to:
  /// **'Review every minimized hint and tutorial card whenever you need a refresher.'**
  String get manualMobileHelpBody;

  /// No description provided for @manualMobileTurnAction.
  ///
  /// In en, this message translates to:
  /// **'Bottom action'**
  String get manualMobileTurnAction;

  /// No description provided for @manualMobileTurnBody.
  ///
  /// In en, this message translates to:
  /// **'Jump to the next required decision or end the turn once all action points are spent.'**
  String get manualMobileTurnBody;

  /// No description provided for @mainMenuWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get mainMenuWhatsNew;

  /// No description provided for @mainMenuWhatsNewBody.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Age of New Worlds. Build cities, lead commanders, discover new lands, and write the history of your civilization.'**
  String get mainMenuWhatsNewBody;

  /// No description provided for @mainMenuUpdateSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Update incoming'**
  String get mainMenuUpdateSoonTitle;

  /// No description provided for @mainMenuUpdateSoonBody.
  ///
  /// In en, this message translates to:
  /// **'A newer version is ready and will appear on this platform soon. Check your store or launcher again shortly.'**
  String get mainMenuUpdateSoonBody;

  /// No description provided for @gameModeLabel.
  ///
  /// In en, this message translates to:
  /// **'MODE'**
  String get gameModeLabel;

  /// No description provided for @gameNameLabel.
  ///
  /// In en, this message translates to:
  /// **'GAME NAME'**
  String get gameNameLabel;

  /// No description provided for @playersLabel.
  ///
  /// In en, this message translates to:
  /// **'PLAYERS'**
  String get playersLabel;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'COUNTRY'**
  String get countryLabel;

  /// No description provided for @countryPoland.
  ///
  /// In en, this message translates to:
  /// **'Poland'**
  String get countryPoland;

  /// No description provided for @countryUkraine.
  ///
  /// In en, this message translates to:
  /// **'Ukraine'**
  String get countryUkraine;

  /// No description provided for @countryGermany.
  ///
  /// In en, this message translates to:
  /// **'Germany'**
  String get countryGermany;

  /// No description provided for @countryFrance.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get countryFrance;

  /// No description provided for @countryUnitedKingdom.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get countryUnitedKingdom;

  /// No description provided for @countryItaly.
  ///
  /// In en, this message translates to:
  /// **'Italy'**
  String get countryItaly;

  /// No description provided for @countrySpain.
  ///
  /// In en, this message translates to:
  /// **'Spain'**
  String get countrySpain;

  /// No description provided for @countryNetherlands.
  ///
  /// In en, this message translates to:
  /// **'Netherlands'**
  String get countryNetherlands;

  /// No description provided for @countrySweden.
  ///
  /// In en, this message translates to:
  /// **'Sweden'**
  String get countrySweden;

  /// No description provided for @countryRussia.
  ///
  /// In en, this message translates to:
  /// **'Russia'**
  String get countryRussia;

  /// No description provided for @countryUnitedStates.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get countryUnitedStates;

  /// No description provided for @countryCanada.
  ///
  /// In en, this message translates to:
  /// **'Canada'**
  String get countryCanada;

  /// No description provided for @countryChina.
  ///
  /// In en, this message translates to:
  /// **'China'**
  String get countryChina;

  /// No description provided for @countryKorea.
  ///
  /// In en, this message translates to:
  /// **'Korea'**
  String get countryKorea;

  /// No description provided for @countryJapan.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get countryJapan;

  /// No description provided for @countryPortugal.
  ///
  /// In en, this message translates to:
  /// **'Portugal'**
  String get countryPortugal;

  /// No description provided for @countryLeaderPoland.
  ///
  /// In en, this message translates to:
  /// **'Casimir III the Great'**
  String get countryLeaderPoland;

  /// No description provided for @countryLeaderUkraine.
  ///
  /// In en, this message translates to:
  /// **'Yaroslav the Wise'**
  String get countryLeaderUkraine;

  /// No description provided for @countryLeaderGermany.
  ///
  /// In en, this message translates to:
  /// **'Otto von Bismarck'**
  String get countryLeaderGermany;

  /// No description provided for @countryLeaderFrance.
  ///
  /// In en, this message translates to:
  /// **'Napoleon Bonaparte'**
  String get countryLeaderFrance;

  /// No description provided for @countryLeaderUnitedKingdom.
  ///
  /// In en, this message translates to:
  /// **'Queen Victoria'**
  String get countryLeaderUnitedKingdom;

  /// No description provided for @countryLeaderItaly.
  ///
  /// In en, this message translates to:
  /// **'Julius Caesar'**
  String get countryLeaderItaly;

  /// No description provided for @countryLeaderSpain.
  ///
  /// In en, this message translates to:
  /// **'Isabella I'**
  String get countryLeaderSpain;

  /// No description provided for @countryLeaderNetherlands.
  ///
  /// In en, this message translates to:
  /// **'William of Orange'**
  String get countryLeaderNetherlands;

  /// No description provided for @countryLeaderSweden.
  ///
  /// In en, this message translates to:
  /// **'Gustavus Adolphus'**
  String get countryLeaderSweden;

  /// No description provided for @countryLeaderRussia.
  ///
  /// In en, this message translates to:
  /// **'Catherine the Great'**
  String get countryLeaderRussia;

  /// No description provided for @countryLeaderUnitedStates.
  ///
  /// In en, this message translates to:
  /// **'Abraham Lincoln'**
  String get countryLeaderUnitedStates;

  /// No description provided for @countryLeaderCanada.
  ///
  /// In en, this message translates to:
  /// **'Wilfrid Laurier'**
  String get countryLeaderCanada;

  /// No description provided for @countryLeaderChina.
  ///
  /// In en, this message translates to:
  /// **'Qin Shi Huang'**
  String get countryLeaderChina;

  /// No description provided for @countryLeaderKorea.
  ///
  /// In en, this message translates to:
  /// **'Sejong the Great'**
  String get countryLeaderKorea;

  /// No description provided for @countryLeaderJapan.
  ///
  /// In en, this message translates to:
  /// **'Tokugawa Ieyasu'**
  String get countryLeaderJapan;

  /// No description provided for @countryLeaderPortugal.
  ///
  /// In en, this message translates to:
  /// **'Henry the Navigator'**
  String get countryLeaderPortugal;

  /// No description provided for @addPlayerAction.
  ///
  /// In en, this message translates to:
  /// **'+ ADD PLAYER'**
  String get addPlayerAction;

  /// No description provided for @startGameAction.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get startGameAction;

  /// No description provided for @removePlayerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove player'**
  String get removePlayerTooltip;

  /// No description provided for @multiplayerSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'SERVER SEARCH'**
  String get multiplayerSearchTitle;

  /// No description provided for @multiplayerSearchBody.
  ///
  /// In en, this message translates to:
  /// **'The list of online games will appear here.'**
  String get multiplayerSearchBody;

  /// No description provided for @multiplayerPlayersTitle.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get multiplayerPlayersTitle;

  /// No description provided for @multiplayerStatusTooltip.
  ///
  /// In en, this message translates to:
  /// **'Player status'**
  String get multiplayerStatusTooltip;

  /// No description provided for @multiplayerAvatarTooltip.
  ///
  /// In en, this message translates to:
  /// **'{playerName} - {status}'**
  String multiplayerAvatarTooltip(String playerName, String status);

  /// No description provided for @multiplayerAvatarTooltipWithRelation.
  ///
  /// In en, this message translates to:
  /// **'{playerName} - {status}\nRelations: {relation}'**
  String multiplayerAvatarTooltipWithRelation(
    String playerName,
    String status,
    String relation,
  );

  /// No description provided for @multiplayerPlayerTooltip.
  ///
  /// In en, this message translates to:
  /// **'{playerName}\n{defaultName}'**
  String multiplayerPlayerTooltip(String playerName, String defaultName);

  /// No description provided for @multiplayerPlayerTooltipWithRelation.
  ///
  /// In en, this message translates to:
  /// **'{playerName}\n{defaultName}\nRelations: {relation}'**
  String multiplayerPlayerTooltipWithRelation(
    String playerName,
    String defaultName,
    String relation,
  );

  /// No description provided for @multiplayerStatusActive.
  ///
  /// In en, this message translates to:
  /// **'playing now'**
  String get multiplayerStatusActive;

  /// No description provided for @multiplayerStatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'turn sent'**
  String get multiplayerStatusSubmitted;

  /// No description provided for @multiplayerStatusThinking.
  ///
  /// In en, this message translates to:
  /// **'thinking'**
  String get multiplayerStatusThinking;

  /// No description provided for @multiplayerStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'waiting'**
  String get multiplayerStatusWaiting;

  /// No description provided for @multiplayerStatusTimeout.
  ///
  /// In en, this message translates to:
  /// **'timeout'**
  String get multiplayerStatusTimeout;

  /// No description provided for @diplomacyRelationFriendly.
  ///
  /// In en, this message translates to:
  /// **'friendly'**
  String get diplomacyRelationFriendly;

  /// No description provided for @diplomacyRelationNeutral.
  ///
  /// In en, this message translates to:
  /// **'neutral'**
  String get diplomacyRelationNeutral;

  /// No description provided for @diplomacyRelationHostile.
  ///
  /// In en, this message translates to:
  /// **'hostile'**
  String get diplomacyRelationHostile;

  /// No description provided for @diplomacyRelationTruce.
  ///
  /// In en, this message translates to:
  /// **'truce'**
  String get diplomacyRelationTruce;

  /// No description provided for @diplomacyRelationWar.
  ///
  /// In en, this message translates to:
  /// **'war'**
  String get diplomacyRelationWar;

  /// No description provided for @diplomacyRelationFriendlyShort.
  ///
  /// In en, this message translates to:
  /// **'fr.'**
  String get diplomacyRelationFriendlyShort;

  /// No description provided for @diplomacyRelationNeutralShort.
  ///
  /// In en, this message translates to:
  /// **'neut.'**
  String get diplomacyRelationNeutralShort;

  /// No description provided for @diplomacyRelationHostileShort.
  ///
  /// In en, this message translates to:
  /// **'host.'**
  String get diplomacyRelationHostileShort;

  /// No description provided for @diplomacyRelationTruceShort.
  ///
  /// In en, this message translates to:
  /// **'truce'**
  String get diplomacyRelationTruceShort;

  /// No description provided for @diplomacyRelationWarShort.
  ///
  /// In en, this message translates to:
  /// **'war'**
  String get diplomacyRelationWarShort;

  /// No description provided for @commonDiplomacy.
  ///
  /// In en, this message translates to:
  /// **'Diplomacy'**
  String get commonDiplomacy;

  /// No description provided for @diplomacyScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Relations'**
  String get diplomacyScoreLabel;

  /// No description provided for @diplomacyTreatyLabel.
  ///
  /// In en, this message translates to:
  /// **'Treaty'**
  String get diplomacyTreatyLabel;

  /// No description provided for @diplomacyAttitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Attitude'**
  String get diplomacyAttitudeLabel;

  /// No description provided for @diplomacyTreatyBenefitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Treaty benefits'**
  String get diplomacyTreatyBenefitsLabel;

  /// No description provided for @diplomacyFriendlyBenefits.
  ///
  /// In en, this message translates to:
  /// **'+1 gold from resource trades · right of passage'**
  String get diplomacyFriendlyBenefits;

  /// No description provided for @diplomacyNoTreatyBenefits.
  ///
  /// In en, this message translates to:
  /// **'No treaty benefits'**
  String get diplomacyNoTreatyBenefits;

  /// No description provided for @diplomacyScoreDriversTitle.
  ///
  /// In en, this message translates to:
  /// **'What changes relations'**
  String get diplomacyScoreDriversTitle;

  /// No description provided for @diplomacyScoreReasonManual.
  ///
  /// In en, this message translates to:
  /// **'Manual change'**
  String get diplomacyScoreReasonManual;

  /// No description provided for @diplomacyScoreReasonUnitAttack.
  ///
  /// In en, this message translates to:
  /// **'Unit attack'**
  String get diplomacyScoreReasonUnitAttack;

  /// No description provided for @diplomacyScoreReasonCityAttack.
  ///
  /// In en, this message translates to:
  /// **'City attack'**
  String get diplomacyScoreReasonCityAttack;

  /// No description provided for @diplomacyScoreReasonDeclarationOfWar.
  ///
  /// In en, this message translates to:
  /// **'Declaration of war'**
  String get diplomacyScoreReasonDeclarationOfWar;

  /// No description provided for @diplomacyScoreReasonWarmongerPenalty.
  ///
  /// In en, this message translates to:
  /// **'Warmonger penalty'**
  String get diplomacyScoreReasonWarmongerPenalty;

  /// No description provided for @diplomacyScoreReasonProposalAccepted.
  ///
  /// In en, this message translates to:
  /// **'Proposal accepted'**
  String get diplomacyScoreReasonProposalAccepted;

  /// No description provided for @diplomacyScoreReasonProposalRejected.
  ///
  /// In en, this message translates to:
  /// **'Proposal rejected'**
  String get diplomacyScoreReasonProposalRejected;

  /// No description provided for @diplomacyScoreReasonMessageResponse.
  ///
  /// In en, this message translates to:
  /// **'Dispatch response'**
  String get diplomacyScoreReasonMessageResponse;

  /// No description provided for @diplomacyScoreReasonCommonEnemyCooperation.
  ///
  /// In en, this message translates to:
  /// **'Common enemy cooperation'**
  String get diplomacyScoreReasonCommonEnemyCooperation;

  /// No description provided for @diplomacyScoreReasonGoldGift.
  ///
  /// In en, this message translates to:
  /// **'Gold gift'**
  String get diplomacyScoreReasonGoldGift;

  /// No description provided for @diplomacyScoreReasonPromiseBroken.
  ///
  /// In en, this message translates to:
  /// **'Promise broken'**
  String get diplomacyScoreReasonPromiseBroken;

  /// No description provided for @diplomacyStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get diplomacyStatsTitle;

  /// No description provided for @diplomacyHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get diplomacyHistoryTitle;

  /// No description provided for @diplomacyMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispatches'**
  String get diplomacyMessagesTitle;

  /// No description provided for @diplomacyIncomingMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'New dispatch'**
  String get diplomacyIncomingMessageTitle;

  /// No description provided for @diplomacyIncomingMessageFrom.
  ///
  /// In en, this message translates to:
  /// **'From: {playerName}'**
  String diplomacyIncomingMessageFrom(String playerName);

  /// No description provided for @diplomacyIncomingProposalTitle.
  ///
  /// In en, this message translates to:
  /// **'New proposal'**
  String get diplomacyIncomingProposalTitle;

  /// No description provided for @diplomacyIncomingProposalFrom.
  ///
  /// In en, this message translates to:
  /// **'From: {playerName}'**
  String diplomacyIncomingProposalFrom(String playerName);

  /// No description provided for @diplomacyIncomingMessageLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get diplomacyIncomingMessageLater;

  /// No description provided for @diplomacyActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get diplomacyActionsTitle;

  /// No description provided for @diplomacyProposalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Proposals'**
  String get diplomacyProposalsTitle;

  /// No description provided for @diplomacyNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No recorded incidents.'**
  String get diplomacyNoHistory;

  /// No description provided for @diplomacyNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No dispatches.'**
  String get diplomacyNoMessages;

  /// No description provided for @diplomacyMilitaryStat.
  ///
  /// In en, this message translates to:
  /// **'Military'**
  String get diplomacyMilitaryStat;

  /// No description provided for @diplomacyCitiesStat.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get diplomacyCitiesStat;

  /// No description provided for @diplomacyExpansionStat.
  ///
  /// In en, this message translates to:
  /// **'Expansion'**
  String get diplomacyExpansionStat;

  /// No description provided for @diplomacyArtifactsStat.
  ///
  /// In en, this message translates to:
  /// **'Artifacts'**
  String get diplomacyArtifactsStat;

  /// No description provided for @diplomacyLastAggressionStat.
  ///
  /// In en, this message translates to:
  /// **'Last aggression'**
  String get diplomacyLastAggressionStat;

  /// No description provided for @diplomacyOwnArtifactsLabel.
  ///
  /// In en, this message translates to:
  /// **'Your artifacts'**
  String get diplomacyOwnArtifactsLabel;

  /// No description provided for @diplomacyTargetArtifactsLabel.
  ///
  /// In en, this message translates to:
  /// **'Rival artifacts'**
  String get diplomacyTargetArtifactsLabel;

  /// No description provided for @diplomacyTurnsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Turns left: {turns}'**
  String diplomacyTurnsRemaining(int turns);

  /// No description provided for @diplomacyProposalFriendship.
  ///
  /// In en, this message translates to:
  /// **'Friendship proposal'**
  String get diplomacyProposalFriendship;

  /// No description provided for @diplomacyProposalTruce.
  ///
  /// In en, this message translates to:
  /// **'Truce proposal'**
  String get diplomacyProposalTruce;

  /// No description provided for @diplomacyProposalForecastLine.
  ///
  /// In en, this message translates to:
  /// **'{proposal}: {outcome} · {reasons}'**
  String diplomacyProposalForecastLine(
    String proposal,
    String outcome,
    String reasons,
  );

  /// No description provided for @diplomacyProposalForecastAccepted.
  ///
  /// In en, this message translates to:
  /// **'likely accepted'**
  String get diplomacyProposalForecastAccepted;

  /// No description provided for @diplomacyProposalForecastRejected.
  ///
  /// In en, this message translates to:
  /// **'likely rejected'**
  String get diplomacyProposalForecastRejected;

  /// No description provided for @diplomacyProposalForecastReasonAcceptableRelations.
  ///
  /// In en, this message translates to:
  /// **'relations are workable'**
  String get diplomacyProposalForecastReasonAcceptableRelations;

  /// No description provided for @diplomacyProposalForecastReasonActiveWar.
  ///
  /// In en, this message translates to:
  /// **'active war'**
  String get diplomacyProposalForecastReasonActiveWar;

  /// No description provided for @diplomacyProposalForecastReasonAtWar.
  ///
  /// In en, this message translates to:
  /// **'friendship blocked by war'**
  String get diplomacyProposalForecastReasonAtWar;

  /// No description provided for @diplomacyProposalForecastReasonGoldPayment.
  ///
  /// In en, this message translates to:
  /// **'peace payment'**
  String get diplomacyProposalForecastReasonGoldPayment;

  /// No description provided for @diplomacyProposalForecastReasonLowRelations.
  ///
  /// In en, this message translates to:
  /// **'relations too low'**
  String get diplomacyProposalForecastReasonLowRelations;

  /// No description provided for @diplomacyProposalForecastReasonMilitaryPressure.
  ///
  /// In en, this message translates to:
  /// **'military pressure'**
  String get diplomacyProposalForecastReasonMilitaryPressure;

  /// No description provided for @diplomacyProposalForecastReasonRecentHostility.
  ///
  /// In en, this message translates to:
  /// **'recent hostility'**
  String get diplomacyProposalForecastReasonRecentHostility;

  /// No description provided for @diplomacyTruceGoldPayment.
  ///
  /// In en, this message translates to:
  /// **'Peace terms: {gold} gold'**
  String diplomacyTruceGoldPayment(int gold);

  /// No description provided for @diplomacyGoldGiftAmount.
  ///
  /// In en, this message translates to:
  /// **'Gold gift: {gold} gold'**
  String diplomacyGoldGiftAmount(int gold);

  /// No description provided for @diplomacySendFriendship.
  ///
  /// In en, this message translates to:
  /// **'Propose friendship'**
  String get diplomacySendFriendship;

  /// No description provided for @diplomacySendTruce.
  ///
  /// In en, this message translates to:
  /// **'Propose truce'**
  String get diplomacySendTruce;

  /// No description provided for @diplomacySendGoldGift.
  ///
  /// In en, this message translates to:
  /// **'Send gold gift'**
  String get diplomacySendGoldGift;

  /// No description provided for @diplomacyDeclareWar.
  ///
  /// In en, this message translates to:
  /// **'Declare war'**
  String get diplomacyDeclareWar;

  /// No description provided for @diplomacyAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get diplomacyAccept;

  /// No description provided for @diplomacyDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get diplomacyDecline;

  /// No description provided for @diplomacyMessageTroopsNearCities.
  ///
  /// In en, this message translates to:
  /// **'Too many troops are positioned near my cities.'**
  String get diplomacyMessageTroopsNearCities;

  /// No description provided for @diplomacyMessageCitiesTooClose.
  ///
  /// In en, this message translates to:
  /// **'You are founding cities too close to my borders.'**
  String get diplomacyMessageCitiesTooClose;

  /// No description provided for @diplomacyMessageBlockedRoutes.
  ///
  /// In en, this message translates to:
  /// **'Your units are blocking my routes.'**
  String get diplomacyMessageBlockedRoutes;

  /// No description provided for @diplomacyMessageWithdrawScouts.
  ///
  /// In en, this message translates to:
  /// **'Please withdraw your scouts from my territory.'**
  String get diplomacyMessageWithdrawScouts;

  /// No description provided for @diplomacyMessageAvoidEscalation.
  ///
  /// In en, this message translates to:
  /// **'Our civilizations should avoid further escalation.'**
  String get diplomacyMessageAvoidEscalation;

  /// No description provided for @diplomacyMessageCommonEnemy.
  ///
  /// In en, this message translates to:
  /// **'A common enemy threatens us both.'**
  String get diplomacyMessageCommonEnemy;

  /// No description provided for @diplomacyMessageExpansionProvocation.
  ///
  /// In en, this message translates to:
  /// **'Your expansion is seen as a provocation.'**
  String get diplomacyMessageExpansionProvocation;

  /// No description provided for @diplomacyMessagePeacefulPraise.
  ///
  /// In en, this message translates to:
  /// **'We value the peaceful relations between our peoples.'**
  String get diplomacyMessagePeacefulPraise;

  /// No description provided for @diplomacyResponseConciliatory.
  ///
  /// In en, this message translates to:
  /// **'Conciliatory'**
  String get diplomacyResponseConciliatory;

  /// No description provided for @diplomacyResponseNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get diplomacyResponseNeutral;

  /// No description provided for @diplomacyResponseEvasive.
  ///
  /// In en, this message translates to:
  /// **'Evasive'**
  String get diplomacyResponseEvasive;

  /// No description provided for @diplomacyResponseAggressive.
  ///
  /// In en, this message translates to:
  /// **'Aggressive'**
  String get diplomacyResponseAggressive;

  /// No description provided for @diplomacyStrategicResourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Strategic resources'**
  String get diplomacyStrategicResourcesTitle;

  /// No description provided for @diplomacyResourceTradeBlockedByWar.
  ///
  /// In en, this message translates to:
  /// **'Resource trade is blocked by war.'**
  String get diplomacyResourceTradeBlockedByWar;

  /// No description provided for @diplomacyResourceTradeNoAvailableResources.
  ///
  /// In en, this message translates to:
  /// **'No spare strategic resources are available for trade.'**
  String get diplomacyResourceTradeNoAvailableResources;

  /// No description provided for @diplomacyResourceTradeImportOffer.
  ///
  /// In en, this message translates to:
  /// **'Import offer: {goldPerTurn} gold/turn for {durationTurns} turns.'**
  String diplomacyResourceTradeImportOffer(int goldPerTurn, int durationTurns);

  /// No description provided for @diplomacyResourceTradeImportAction.
  ///
  /// In en, this message translates to:
  /// **'Import {resourceName}'**
  String diplomacyResourceTradeImportAction(String resourceName);

  /// No description provided for @diplomacyResourceTradeExchangeOffer.
  ///
  /// In en, this message translates to:
  /// **'Barter exchange: resource for resource for {durationTurns} turns.'**
  String diplomacyResourceTradeExchangeOffer(int durationTurns);

  /// No description provided for @diplomacyResourceTradeExchangeAction.
  ///
  /// In en, this message translates to:
  /// **'Trade {offeredResource} for {requestedResource}'**
  String diplomacyResourceTradeExchangeAction(
    String offeredResource,
    String requestedResource,
  );

  /// No description provided for @diplomacyResourceTradeNoActiveAgreements.
  ///
  /// In en, this message translates to:
  /// **'No active resource agreements.'**
  String get diplomacyResourceTradeNoActiveAgreements;

  /// No description provided for @diplomacyResourceTradeImportDirection.
  ///
  /// In en, this message translates to:
  /// **'Importing'**
  String get diplomacyResourceTradeImportDirection;

  /// No description provided for @diplomacyResourceTradeExportDirection.
  ///
  /// In en, this message translates to:
  /// **'Exporting'**
  String get diplomacyResourceTradeExportDirection;

  /// No description provided for @diplomacyResourceTradeBarterPrice.
  ///
  /// In en, this message translates to:
  /// **'barter'**
  String get diplomacyResourceTradeBarterPrice;

  /// No description provided for @diplomacyResourceTradeGoldPerTurnPrice.
  ///
  /// In en, this message translates to:
  /// **'{goldPerTurn} gold/turn'**
  String diplomacyResourceTradeGoldPerTurnPrice(int goldPerTurn);

  /// No description provided for @diplomacyResourceTradeAgreementLabel.
  ///
  /// In en, this message translates to:
  /// **'{direction} {resourceName} · {price} · {remainingTurns} turns'**
  String diplomacyResourceTradeAgreementLabel(
    String direction,
    String resourceName,
    String price,
    int remainingTurns,
  );

  /// No description provided for @notFoundScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Screen not found'**
  String get notFoundScreenTitle;

  /// No description provided for @notFoundBackToMenuAction.
  ///
  /// In en, this message translates to:
  /// **'MENU'**
  String get notFoundBackToMenuAction;

  /// No description provided for @loadGameTitle.
  ///
  /// In en, this message translates to:
  /// **'LOAD GAME'**
  String get loadGameTitle;

  /// No description provided for @loadGameHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved games'**
  String get loadGameHeaderTitle;

  /// No description provided for @loadGameHeaderEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No game has been started yet.'**
  String get loadGameHeaderEmptySubtitle;

  /// No description provided for @loadGameHeaderSavesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Return to recent matches and continue from the saved turn.'**
  String get loadGameHeaderSavesSubtitle;

  /// No description provided for @loadGameSavesCount.
  ///
  /// In en, this message translates to:
  /// **'Saves: {count}'**
  String loadGameSavesCount(int count);

  /// No description provided for @loadGameCorruptedStatus.
  ///
  /// In en, this message translates to:
  /// **'Corrupted save'**
  String get loadGameCorruptedStatus;

  /// No description provided for @loadGameCorruptedAction.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get loadGameCorruptedAction;

  /// No description provided for @loadGameCorruptedBody.
  ///
  /// In en, this message translates to:
  /// **'This save cannot be read. You can remove it from the list.'**
  String get loadGameCorruptedBody;

  /// No description provided for @replayTitle.
  ///
  /// In en, this message translates to:
  /// **'REPLAY'**
  String get replayTitle;

  /// No description provided for @replayAction.
  ///
  /// In en, this message translates to:
  /// **'REPLAY'**
  String get replayAction;

  /// No description provided for @replayUnavailableAction.
  ///
  /// In en, this message translates to:
  /// **'NO REPLAY'**
  String get replayUnavailableAction;

  /// No description provided for @replayErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Replay unavailable'**
  String get replayErrorTitle;

  /// No description provided for @replayErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Replay cannot be opened: {error}'**
  String replayErrorBody(String error);

  /// No description provided for @replayMissingInitialSnapshotBody.
  ///
  /// In en, this message translates to:
  /// **'This save does not contain a replay seed snapshot. Start a new game to record full-match replay data.'**
  String get replayMissingInitialSnapshotBody;

  /// No description provided for @replayCorruptLogBody.
  ///
  /// In en, this message translates to:
  /// **'The replay command log is incomplete or cannot be read.'**
  String get replayCorruptLogBody;

  /// No description provided for @replayStepCounter.
  ///
  /// In en, this message translates to:
  /// **'Step {step}/{total}'**
  String replayStepCounter(int step, int total);

  /// No description provided for @endTurnButtonTurnLabel.
  ///
  /// In en, this message translates to:
  /// **'TURN {turn}'**
  String endTurnButtonTurnLabel(int turn);

  /// No description provided for @replayTurnLabel.
  ///
  /// In en, this message translates to:
  /// **'Turn {turn}'**
  String replayTurnLabel(int turn);

  /// No description provided for @replayEventCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 events} =1{1 event} other{{count} events}}'**
  String replayEventCount(int count);

  /// No description provided for @replayInitialStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Initial state'**
  String get replayInitialStateLabel;

  /// No description provided for @replayPreviousAction.
  ///
  /// In en, this message translates to:
  /// **'Previous step'**
  String get replayPreviousAction;

  /// No description provided for @replayNextAction.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get replayNextAction;

  /// No description provided for @replayPlayAction.
  ///
  /// In en, this message translates to:
  /// **'Play replay'**
  String get replayPlayAction;

  /// No description provided for @replayPauseAction.
  ///
  /// In en, this message translates to:
  /// **'Pause replay'**
  String get replayPauseAction;

  /// No description provided for @replaySpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get replaySpeedLabel;

  /// No description provided for @replayPerspectiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Perspective'**
  String get replayPerspectiveLabel;

  /// No description provided for @replayAllPlayers.
  ///
  /// In en, this message translates to:
  /// **'All players'**
  String get replayAllPlayers;

  /// No description provided for @replayShowTurnsLabel.
  ///
  /// In en, this message translates to:
  /// **'Show turns'**
  String get replayShowTurnsLabel;

  /// No description provided for @replayFreeCameraLabel.
  ///
  /// In en, this message translates to:
  /// **'Free camera'**
  String get replayFreeCameraLabel;

  /// No description provided for @mapsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load maps: {error}'**
  String mapsLoadError(String error);

  /// No description provided for @editorMapPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Editor maps'**
  String get editorMapPickerTitle;

  /// No description provided for @editorMapPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create new worlds or refine existing maps.'**
  String get editorMapPickerSubtitle;

  /// No description provided for @editorMapPickerEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved maps'**
  String get editorMapPickerEmptyTitle;

  /// No description provided for @editorMapPickerEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a new map from the screen header.'**
  String get editorMapPickerEmptyMessage;

  /// No description provided for @editorNewMapAction.
  ///
  /// In en, this message translates to:
  /// **'New map'**
  String get editorNewMapAction;

  /// No description provided for @editorDeleteMapTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete map'**
  String get editorDeleteMapTooltip;

  /// No description provided for @editorDeleteMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete map?'**
  String get editorDeleteMapTitle;

  /// No description provided for @editorDeleteMapMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete “{name}” and all map files.'**
  String editorDeleteMapMessage(String name);

  /// No description provided for @editorOpenMapErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not open map'**
  String get editorOpenMapErrorTitle;

  /// No description provided for @editorCollapseToolbarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Collapse editor panel'**
  String get editorCollapseToolbarTooltip;

  /// No description provided for @editorExpandToolbarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Expand editor panel'**
  String get editorExpandToolbarTooltip;

  /// No description provided for @officialMapsCount.
  ///
  /// In en, this message translates to:
  /// **'Official: {count}'**
  String officialMapsCount(int count);

  /// No description provided for @yourMapsCount.
  ///
  /// In en, this message translates to:
  /// **'Yours: {count}'**
  String yourMapsCount(int count);

  /// No description provided for @officialMapsSection.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get officialMapsSection;

  /// No description provided for @yourMapsSection.
  ///
  /// In en, this message translates to:
  /// **'Your maps'**
  String get yourMapsSection;

  /// No description provided for @playAction.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playAction;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @noMapsTitle.
  ///
  /// In en, this message translates to:
  /// **'No maps'**
  String get noMapsTitle;

  /// No description provided for @noMapsMessage.
  ///
  /// In en, this message translates to:
  /// **'No maps were found to start a game.'**
  String get noMapsMessage;

  /// No description provided for @gameLengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Game length'**
  String get gameLengthLabel;

  /// No description provided for @gameLengthPresetHint.
  ///
  /// In en, this message translates to:
  /// **'Game preset'**
  String get gameLengthPresetHint;

  /// No description provided for @gameLengthPresetUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get gameLengthPresetUnlimited;

  /// No description provided for @gameLengthPresetShort60.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get gameLengthPresetShort60;

  /// No description provided for @gameLengthPresetNormal90.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get gameLengthPresetNormal90;

  /// No description provided for @gameLengthPresetStandard60.
  ///
  /// In en, this message translates to:
  /// **'Standard 60 min'**
  String get gameLengthPresetStandard60;

  /// No description provided for @gameLengthPresetLong120.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get gameLengthPresetLong120;

  /// No description provided for @gameLengthPresetVeryLong.
  ///
  /// In en, this message translates to:
  /// **'Very long'**
  String get gameLengthPresetVeryLong;

  /// No description provided for @gameLengthUnlimitedSummary.
  ///
  /// In en, this message translates to:
  /// **'No turn limit - current game pace'**
  String get gameLengthUnlimitedSummary;

  /// No description provided for @gameLengthTimedSummary.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min target - {turns} turn limit'**
  String gameLengthTimedSummary(int minutes, int turns);

  /// No description provided for @gameLengthScoreFallbackOn.
  ///
  /// In en, this message translates to:
  /// **'with score fallback'**
  String get gameLengthScoreFallbackOn;

  /// No description provided for @gameLengthScoreFallbackOff.
  ///
  /// In en, this message translates to:
  /// **'without score fallback'**
  String get gameLengthScoreFallbackOff;

  /// No description provided for @aiDifficultyLabel.
  ///
  /// In en, this message translates to:
  /// **'AI difficulty'**
  String get aiDifficultyLabel;

  /// No description provided for @aiDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get aiDifficultyEasy;

  /// No description provided for @aiDifficultyNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get aiDifficultyNormal;

  /// No description provided for @aiDifficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get aiDifficultyHard;

  /// No description provided for @aiDifficultyVeryHard.
  ///
  /// In en, this message translates to:
  /// **'Very hard'**
  String get aiDifficultyVeryHard;

  /// No description provided for @gameLengthVictoryRules.
  ///
  /// In en, this message translates to:
  /// **'Conquest + domination {controlPercent}%/{holdTurns} turns - {fallback}'**
  String gameLengthVictoryRules(
    String controlPercent,
    int holdTurns,
    String fallback,
  );

  /// No description provided for @mapValidationErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Map needs fixes'**
  String get mapValidationErrorTitle;

  /// No description provided for @mapValidationLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Checking map'**
  String get mapValidationLoadingTitle;

  /// No description provided for @mapValidationWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Map may be too slow for this preset'**
  String get mapValidationWarningTitle;

  /// No description provided for @mapValidationLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not check map: {error}'**
  String mapValidationLoadError(String error);

  /// No description provided for @mapValidationLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Validating starts, resources, and first-contact pacing.'**
  String get mapValidationLoadingMessage;

  /// No description provided for @mapValidationIssueSlowFirstContact.
  ///
  /// In en, this message translates to:
  /// **'Starting positions are far apart; 60 min may delay first contact too much.'**
  String get mapValidationIssueSlowFirstContact;

  /// No description provided for @mapValidationIssueLargeMap.
  ///
  /// In en, this message translates to:
  /// **'The map has many tiles per player; add players or choose a longer game.'**
  String get mapValidationIssueLargeMap;

  /// No description provided for @mapValidationIssueInvalidPlayerCount.
  ///
  /// In en, this message translates to:
  /// **'Player count does not match the range supported by this map.'**
  String get mapValidationIssueInvalidPlayerCount;

  /// No description provided for @mapValidationIssueNoTiles.
  ///
  /// In en, this message translates to:
  /// **'The map has no tiles.'**
  String get mapValidationIssueNoTiles;

  /// No description provided for @mapValidationIssueLowPassableTileRatio.
  ///
  /// In en, this message translates to:
  /// **'The map has too few tiles passable by land units.'**
  String get mapValidationIssueLowPassableTileRatio;

  /// No description provided for @mapValidationIssueLowFoodResourceDensity.
  ///
  /// In en, this message translates to:
  /// **'The map has too few food resources for this player count.'**
  String get mapValidationIssueLowFoodResourceDensity;

  /// No description provided for @mapValidationIssueLowStrategicResourceDensity.
  ///
  /// In en, this message translates to:
  /// **'The map has too few strategic resources.'**
  String get mapValidationIssueLowStrategicResourceDensity;

  /// No description provided for @mapValidationIssueLowLuxuryResourceDensity.
  ///
  /// In en, this message translates to:
  /// **'The map has too few luxury resources.'**
  String get mapValidationIssueLowLuxuryResourceDensity;

  /// No description provided for @mapValidationIssueStartSiteNotFoundable.
  ///
  /// In en, this message translates to:
  /// **'The starting settler cannot found a city on its tile.'**
  String get mapValidationIssueStartSiteNotFoundable;

  /// No description provided for @mapValidationIssueStartSiteLowLandRing.
  ///
  /// In en, this message translates to:
  /// **'The start has too few passable tiles in the first ring.'**
  String get mapValidationIssueStartSiteLowLandRing;

  /// No description provided for @mapValidationIssueStartSiteLowFood.
  ///
  /// In en, this message translates to:
  /// **'The start has no visible food resource nearby.'**
  String get mapValidationIssueStartSiteLowFood;

  /// No description provided for @mapValidationIssueStartSiteLowCityControl.
  ///
  /// In en, this message translates to:
  /// **'The start has too few legal tiles for initial city control.'**
  String get mapValidationIssueStartSiteLowCityControl;

  /// No description provided for @mapValidationIssueStartSitesTooClose.
  ///
  /// In en, this message translates to:
  /// **'Player starts are too close to each other.'**
  String get mapValidationIssueStartSitesTooClose;

  /// No description provided for @lobbyMapPlayersSummary.
  ///
  /// In en, this message translates to:
  /// **'{mapName} - {playerCount} players'**
  String lobbyMapPlayersSummary(String mapName, int playerCount);

  /// No description provided for @lobbyHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare the table'**
  String get lobbyHeaderTitle;

  /// No description provided for @lobbyHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm civilization first, then tune the match and seats before the first turn.'**
  String get lobbyHeaderSubtitle;

  /// No description provided for @lobbyCivilizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose civilization'**
  String get lobbyCivilizationTitle;

  /// No description provided for @lobbyCivilizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is player one\'s identity for the opening turn.'**
  String get lobbyCivilizationSubtitle;

  /// No description provided for @lobbyStepCivilization.
  ///
  /// In en, this message translates to:
  /// **'Civilization'**
  String get lobbyStepCivilization;

  /// No description provided for @lobbyStepSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get lobbyStepSetup;

  /// No description provided for @lobbyStepOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get lobbyStepOnline;

  /// No description provided for @lobbyStepPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get lobbyStepPlayers;

  /// No description provided for @lobbySetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Match setup'**
  String get lobbySetupTitle;

  /// No description provided for @lobbySetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name the game, choose the pace, and check whether the map fits the selected player count.'**
  String get lobbySetupSubtitle;

  /// No description provided for @lobbyPlayersSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Players at the table'**
  String get lobbyPlayersSetupTitle;

  /// No description provided for @lobbyPlayersSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The first player takes the opening turn. Extra seats can be people on this device or AI.'**
  String get lobbyPlayersSetupSubtitle;

  /// No description provided for @lobbyPlayerYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get lobbyPlayerYou;

  /// No description provided for @lobbyPlayerHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get lobbyPlayerHost;

  /// No description provided for @lobbyPlayerReady.
  ///
  /// In en, this message translates to:
  /// **'ready'**
  String get lobbyPlayerReady;

  /// No description provided for @lobbyPlayerConnected.
  ///
  /// In en, this message translates to:
  /// **'connected'**
  String get lobbyPlayerConnected;

  /// No description provided for @lobbyPlayerConnecting.
  ///
  /// In en, this message translates to:
  /// **'connecting'**
  String get lobbyPlayerConnecting;

  /// No description provided for @lobbyPlayerReconnecting.
  ///
  /// In en, this message translates to:
  /// **'reconnecting'**
  String get lobbyPlayerReconnecting;

  /// No description provided for @lobbyPlayerOffline.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get lobbyPlayerOffline;

  /// No description provided for @lobbyPlayerOpenSlot.
  ///
  /// In en, this message translates to:
  /// **'Open seat {slotNumber}'**
  String lobbyPlayerOpenSlot(int slotNumber);

  /// No description provided for @lobbyPlayerRequiredSlot.
  ///
  /// In en, this message translates to:
  /// **'Needed to start'**
  String get lobbyPlayerRequiredSlot;

  /// No description provided for @lobbyPlayerOptionalSlot.
  ///
  /// In en, this message translates to:
  /// **'Can join before start'**
  String get lobbyPlayerOptionalSlot;

  /// No description provided for @playerKindHuman.
  ///
  /// In en, this message translates to:
  /// **'Human'**
  String get playerKindHuman;

  /// No description provided for @playerKindAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get playerKindAi;

  /// No description provided for @multiplayerServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Online game server'**
  String get multiplayerServerTitle;

  /// No description provided for @connectAction.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectAction;

  /// No description provided for @refreshAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshAction;

  /// No description provided for @createMatchAction.
  ///
  /// In en, this message translates to:
  /// **'Create match'**
  String get createMatchAction;

  /// No description provided for @noOpenMatches.
  ///
  /// In en, this message translates to:
  /// **'No open matches'**
  String get noOpenMatches;

  /// No description provided for @matchStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get matchStatusRunning;

  /// No description provided for @matchStatusFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get matchStatusFinished;

  /// No description provided for @matchStatusAbandoned.
  ///
  /// In en, this message translates to:
  /// **'Abandoned'**
  String get matchStatusAbandoned;

  /// No description provided for @matchPlayersCount.
  ///
  /// In en, this message translates to:
  /// **'{players}/{maxPlayers} players'**
  String matchPlayersCount(int players, int maxPlayers);

  /// No description provided for @matchReadyCount.
  ///
  /// In en, this message translates to:
  /// **'{readyPlayers}/{players} ready'**
  String matchReadyCount(int readyPlayers, int players);

  /// No description provided for @matchTurnInfo.
  ///
  /// In en, this message translates to:
  /// **'{mapName} - {status} - turn {turn}'**
  String matchTurnInfo(String mapName, String status, int turn);

  /// No description provided for @openMatchInfo.
  ///
  /// In en, this message translates to:
  /// **'{mapName} - {players}/{maxPlayers} - turn {turn}'**
  String openMatchInfo(String mapName, int players, int maxPlayers, int turn);

  /// No description provided for @enterMatchAction.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enterMatchAction;

  /// No description provided for @hideMatchAction.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideMatchAction;

  /// No description provided for @joinMatchAction.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinMatchAction;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelAction;

  /// No description provided for @copyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyAction;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @multiplayerHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a quick queue or a private code match for friends.'**
  String get multiplayerHomeSubtitle;

  /// No description provided for @multiplayerProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get multiplayerProfileTitle;

  /// No description provided for @multiplayerProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the name and civilization you will use in online matches.'**
  String get multiplayerProfileSubtitle;

  /// No description provided for @multiplayerProfileOptionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your nickname is used in multiplayer matches and must be unique.'**
  String get multiplayerProfileOptionsSubtitle;

  /// No description provided for @multiplayerProfileSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save nickname'**
  String get multiplayerProfileSaveAction;

  /// No description provided for @multiplayerProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Nickname saved.'**
  String get multiplayerProfileSaved;

  /// No description provided for @multiplayerLobbyHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Online lobby'**
  String get multiplayerLobbyHeaderTitle;

  /// No description provided for @multiplayerLobbyHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose civilization first, then enter quickplay or create a private table. The map is selected automatically.'**
  String get multiplayerLobbyHeaderSubtitle;

  /// No description provided for @multiplayerCountryPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose civilization'**
  String get multiplayerCountryPickTitle;

  /// No description provided for @multiplayerCountryPickSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is the key choice before entering the queue. Multiplayer maps are selected at random.'**
  String get multiplayerCountryPickSubtitle;

  /// No description provided for @multiplayerRandomMapLabel.
  ///
  /// In en, this message translates to:
  /// **'Random map'**
  String get multiplayerRandomMapLabel;

  /// No description provided for @multiplayerNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get multiplayerNicknameLabel;

  /// No description provided for @multiplayerQuickplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick game'**
  String get multiplayerQuickplayTitle;

  /// No description provided for @multiplayerQuickplaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Finds players automatically and starts from 2 players.'**
  String get multiplayerQuickplaySubtitle;

  /// No description provided for @multiplayerCreatePrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create code'**
  String get multiplayerCreatePrivateTitle;

  /// No description provided for @multiplayerCreatePrivateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Private match with no time limit, only for friends.'**
  String get multiplayerCreatePrivateSubtitle;

  /// No description provided for @multiplayerJoinPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Join with code'**
  String get multiplayerJoinPrivateTitle;

  /// No description provided for @multiplayerJoinPrivateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a friend\'s code and wait for the host.'**
  String get multiplayerJoinPrivateSubtitle;

  /// No description provided for @multiplayerQueueReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Match ready'**
  String get multiplayerQueueReadyTitle;

  /// No description provided for @multiplayerQueueSearchingTitle.
  ///
  /// In en, this message translates to:
  /// **'Searching for players'**
  String get multiplayerQueueSearchingTitle;

  /// No description provided for @multiplayerQueueCountdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Starting soon'**
  String get multiplayerQueueCountdownTitle;

  /// No description provided for @multiplayerQueueConnectingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connecting to the server and looking for a queue.'**
  String get multiplayerQueueConnectingSubtitle;

  /// No description provided for @multiplayerQueueWaitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for at least {minPlayers} players.'**
  String multiplayerQueueWaitingForPlayers(int minPlayers);

  /// No description provided for @multiplayerQueuePreparingStart.
  ///
  /// In en, this message translates to:
  /// **'Players found. Preparing match start.'**
  String get multiplayerQueuePreparingStart;

  /// No description provided for @multiplayerQueueStartingNow.
  ///
  /// In en, this message translates to:
  /// **'Starting match...'**
  String get multiplayerQueueStartingNow;

  /// No description provided for @multiplayerQueueStartingIn.
  ///
  /// In en, this message translates to:
  /// **'Starting in {seconds}s. More players can still join.'**
  String multiplayerQueueStartingIn(int seconds);

  /// No description provided for @multiplayerPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends match'**
  String get multiplayerPrivateTitle;

  /// No description provided for @multiplayerPrivateHostReady.
  ///
  /// In en, this message translates to:
  /// **'You can start the match now.'**
  String get multiplayerPrivateHostReady;

  /// No description provided for @multiplayerPrivateWaitingForHost.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the host to start the match.'**
  String get multiplayerPrivateWaitingForHost;

  /// No description provided for @multiplayerJoinCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter the code you received from a friend.'**
  String get multiplayerJoinCodeHelp;

  /// No description provided for @multiplayerInviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Match code'**
  String get multiplayerInviteCodeHint;

  /// No description provided for @multiplayerInviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Match code'**
  String get multiplayerInviteCodeLabel;

  /// No description provided for @multiplayerInviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Match code copied.'**
  String get multiplayerInviteCopied;

  /// No description provided for @multiplayerInviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Join my AONW match. Code: {inviteCode}'**
  String multiplayerInviteShareText(String inviteCode);

  /// No description provided for @multiplayerInviteCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a match code.'**
  String get multiplayerInviteCodeRequired;

  /// No description provided for @multiplayerMapNotReady.
  ///
  /// In en, this message translates to:
  /// **'This map is not ready for multiplayer.'**
  String get multiplayerMapNotReady;

  /// No description provided for @multiplayerRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'The server rejected the request ({statusCode}).'**
  String multiplayerRequestRejected(int statusCode);

  /// No description provided for @multiplayerRequestRejectedWithReason.
  ///
  /// In en, this message translates to:
  /// **'The server rejected the request ({statusCode}: {reason}).'**
  String multiplayerRequestRejectedWithReason(int statusCode, String reason);

  /// No description provided for @multiplayerConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to {host}. Check your internet connection and try again.'**
  String multiplayerConnectionError(String host);

  /// No description provided for @multiplayerSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to play multiplayer.'**
  String get multiplayerSignInRequired;

  /// No description provided for @multiplayerSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your multiplayer session expired. Sign in again and retry.'**
  String get multiplayerSessionExpired;

  /// No description provided for @multiplayerAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Multiplayer account'**
  String get multiplayerAccountTitle;

  /// No description provided for @multiplayerAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to continue.'**
  String get multiplayerAccountSubtitle;

  /// No description provided for @multiplayerAccountEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get multiplayerAccountEmailLabel;

  /// No description provided for @multiplayerAccountPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get multiplayerAccountPasswordLabel;

  /// No description provided for @multiplayerAccountSignInTab.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get multiplayerAccountSignInTab;

  /// No description provided for @multiplayerAccountCreateTab.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get multiplayerAccountCreateTab;

  /// No description provided for @multiplayerAccountSignInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get multiplayerAccountSignInAction;

  /// No description provided for @multiplayerAccountCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get multiplayerAccountCreateAction;

  /// No description provided for @multiplayerAccountSignOutAction.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get multiplayerAccountSignOutAction;

  /// No description provided for @multiplayerAccountSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out of multiplayer.'**
  String get multiplayerAccountSignedOut;

  /// No description provided for @multiplayerAccountInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get multiplayerAccountInvalidEmail;

  /// No description provided for @multiplayerAccountInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get multiplayerAccountInvalidCredentials;

  /// No description provided for @multiplayerAccountExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get multiplayerAccountExists;

  /// No description provided for @multiplayerAccountWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long.'**
  String get multiplayerAccountWeakPassword;

  /// No description provided for @multiplayerAccountInvalidNickname.
  ///
  /// In en, this message translates to:
  /// **'Use 3-24 letters, numbers, spaces, _ or -.'**
  String get multiplayerAccountInvalidNickname;

  /// No description provided for @multiplayerAccountNicknameTaken.
  ///
  /// In en, this message translates to:
  /// **'This nickname is already taken.'**
  String get multiplayerAccountNicknameTaken;

  /// No description provided for @multiplayerAccountGenericError.
  ///
  /// In en, this message translates to:
  /// **'Could not authenticate. Try again.'**
  String get multiplayerAccountGenericError;

  /// No description provided for @multiplayerMatchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This match is no longer available.'**
  String get multiplayerMatchUnavailable;

  /// No description provided for @multiplayerMatchFull.
  ///
  /// In en, this message translates to:
  /// **'This match is full.'**
  String get multiplayerMatchFull;

  /// No description provided for @multiplayerCountryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Multiple players picked your civilization. Try another one.'**
  String get multiplayerCountryUnavailable;

  /// No description provided for @multiplayerMatchNotReady.
  ///
  /// In en, this message translates to:
  /// **'The match is not ready to start yet.'**
  String get multiplayerMatchNotReady;

  /// No description provided for @multiplayerMatchAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'You are not a player in this match.'**
  String get multiplayerMatchAccessDenied;

  /// No description provided for @multiplayerQueueGenericError.
  ///
  /// In en, this message translates to:
  /// **'Could not enter the multiplayer queue. Try again.'**
  String get multiplayerQueueGenericError;

  /// No description provided for @multiplayerResumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume game'**
  String get multiplayerResumeAction;

  /// No description provided for @multiplayerResumeSublabel.
  ///
  /// In en, this message translates to:
  /// **'Return to the last multiplayer session'**
  String get multiplayerResumeSublabel;

  /// No description provided for @multiplayerResumeLoading.
  ///
  /// In en, this message translates to:
  /// **'Connecting to match...'**
  String get multiplayerResumeLoading;

  /// No description provided for @multiplayerResumeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not resume the last multiplayer session.'**
  String get multiplayerResumeFailed;

  /// No description provided for @optionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get optionsTooltip;

  /// No description provided for @optionsOpenMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get optionsOpenMenuTooltip;

  /// No description provided for @optionsTooltipWithCollapseHint.
  ///
  /// In en, this message translates to:
  /// **'{tooltip}. Hold to collapse the menu.'**
  String optionsTooltipWithCollapseHint(String tooltip);

  /// No description provided for @optionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get optionsTitle;

  /// No description provided for @optionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Text, language, audio, and performance'**
  String get optionsSubtitle;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// No description provided for @languagePolish.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get languagePolish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageGerman;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @languageDutch.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get languageDutch;

  /// No description provided for @textScaleStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get textScaleStandard;

  /// No description provided for @textScaleLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textScaleLarge;

  /// No description provided for @textScaleExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get textScaleExtraLarge;

  /// No description provided for @textScaleSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Text size {label}'**
  String textScaleSemanticLabel(String label);

  /// No description provided for @textScaleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Text size: {label}'**
  String textScaleTooltip(String label);

  /// No description provided for @languageSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Language {label}'**
  String languageSemanticLabel(String label);

  /// No description provided for @languageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language: {label}'**
  String languageTooltip(String label);

  /// No description provided for @audioSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audioSectionTitle;

  /// No description provided for @gameSoundsLabel.
  ///
  /// In en, this message translates to:
  /// **'Game sounds'**
  String get gameSoundsLabel;

  /// No description provided for @soundVolumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Sound volume'**
  String get soundVolumeLabel;

  /// No description provided for @gameMusicLabel.
  ///
  /// In en, this message translates to:
  /// **'Game music'**
  String get gameMusicLabel;

  /// No description provided for @musicVolumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Music volume'**
  String get musicVolumeLabel;

  /// No description provided for @natureSoundsLabel.
  ///
  /// In en, this message translates to:
  /// **'Nature sounds'**
  String get natureSoundsLabel;

  /// No description provided for @natureVolumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Nature volume'**
  String get natureVolumeLabel;

  /// No description provided for @aiSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get aiSectionTitle;

  /// No description provided for @aiBatterySaverLabel.
  ///
  /// In en, this message translates to:
  /// **'AI battery saver'**
  String get aiBatterySaverLabel;

  /// No description provided for @gameplaySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Gameplay'**
  String get gameplaySectionTitle;

  /// No description provided for @followUnitMovementCameraLabel.
  ///
  /// In en, this message translates to:
  /// **'Follow unit movement with camera'**
  String get followUnitMovementCameraLabel;

  /// No description provided for @followEnemyUnitCameraLabel.
  ///
  /// In en, this message translates to:
  /// **'Follow enemy units with camera'**
  String get followEnemyUnitCameraLabel;

  /// No description provided for @cinematicCameraLabel.
  ///
  /// In en, this message translates to:
  /// **'Cinematic camera'**
  String get cinematicCameraLabel;

  /// No description provided for @performanceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performanceSectionTitle;

  /// No description provided for @showFpsLabel.
  ///
  /// In en, this message translates to:
  /// **'Show FPS'**
  String get showFpsLabel;

  /// No description provided for @showMapZoomLabel.
  ///
  /// In en, this message translates to:
  /// **'Show map zoom'**
  String get showMapZoomLabel;

  /// No description provided for @mapViewModeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change map view mode'**
  String get mapViewModeTooltip;

  /// No description provided for @mapViewGraphicUnavailableTooltip.
  ///
  /// In en, this message translates to:
  /// **'Graphic mode is unavailable for this map'**
  String get mapViewGraphicUnavailableTooltip;

  /// No description provided for @mapViewModeGraphic.
  ///
  /// In en, this message translates to:
  /// **'Graphic'**
  String get mapViewModeGraphic;

  /// No description provided for @mapViewModeTiles.
  ///
  /// In en, this message translates to:
  /// **'Tiles'**
  String get mapViewModeTiles;

  /// No description provided for @gameOptionTerrain.
  ///
  /// In en, this message translates to:
  /// **'Terrain'**
  String get gameOptionTerrain;

  /// No description provided for @gameOptionResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get gameOptionResources;

  /// No description provided for @gameOptionHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get gameOptionHeight;

  /// No description provided for @gameOptionCitySites.
  ///
  /// In en, this message translates to:
  /// **'City sites'**
  String get gameOptionCitySites;

  /// No description provided for @gameOptionCityGrowth.
  ///
  /// In en, this message translates to:
  /// **'City growth'**
  String get gameOptionCityGrowth;

  /// No description provided for @gameOptionShowHexes.
  ///
  /// In en, this message translates to:
  /// **'Show hexes'**
  String get gameOptionShowHexes;

  /// No description provided for @gameOptionShowHeight.
  ///
  /// In en, this message translates to:
  /// **'Show height'**
  String get gameOptionShowHeight;

  /// No description provided for @gameOptionDiceTest.
  ///
  /// In en, this message translates to:
  /// **'Dice test'**
  String get gameOptionDiceTest;

  /// No description provided for @gameOptionAutoActionFlow.
  ///
  /// In en, this message translates to:
  /// **'Auto action completion'**
  String get gameOptionAutoActionFlow;

  /// No description provided for @gameOptionAutoTurnFlow.
  ///
  /// In en, this message translates to:
  /// **'Auto turn completion'**
  String get gameOptionAutoTurnFlow;

  /// No description provided for @helpPopupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hints'**
  String get helpPopupsTitle;

  /// No description provided for @autoTurnHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto turn completion'**
  String get autoTurnHintTitle;

  /// No description provided for @autoTurnHintBody.
  ///
  /// In en, this message translates to:
  /// **'Auto turn completion submits the turn when no important actions remain. Auto action completion can be controlled separately in map options.'**
  String get autoTurnHintBody;

  /// No description provided for @autoTurnHintEnableAction.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get autoTurnHintEnableAction;

  /// No description provided for @autoTurnHintDisableAction.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get autoTurnHintDisableAction;

  /// No description provided for @autoTurnHintStatusOn.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get autoTurnHintStatusOn;

  /// No description provided for @autoTurnHintStatusOff.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get autoTurnHintStatusOff;

  /// No description provided for @autoTurnHintMinimizedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick toggle for automatic turn flow.'**
  String get autoTurnHintMinimizedSubtitle;

  /// No description provided for @visibilityShowAction.
  ///
  /// In en, this message translates to:
  /// **'Show {label}'**
  String visibilityShowAction(String label);

  /// No description provided for @visibilityHideAction.
  ///
  /// In en, this message translates to:
  /// **'Hide {label}'**
  String visibilityHideAction(String label);

  /// No description provided for @resignAction.
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get resignAction;

  /// No description provided for @resignMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Resign from match?'**
  String get resignMatchTitle;

  /// No description provided for @resignMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'The match will be ended.'**
  String get resignMatchMessage;

  /// No description provided for @resignMatchError.
  ///
  /// In en, this message translates to:
  /// **'Could not resign from the match.'**
  String get resignMatchError;

  /// No description provided for @creditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get creditsTitle;

  /// No description provided for @creditsCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created by {name}'**
  String creditsCreatedBy(String name);

  /// No description provided for @deleteGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete game'**
  String get deleteGameTitle;

  /// No description provided for @deleteGameMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String deleteGameMessage(String name);

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteAction;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get retryAction;

  /// No description provided for @noSavedGames.
  ///
  /// In en, this message translates to:
  /// **'No saved games.'**
  String get noSavedGames;

  /// No description provided for @resumeAction.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get resumeAction;

  /// No description provided for @newGameAction.
  ///
  /// In en, this message translates to:
  /// **'NEW GAME'**
  String get newGameAction;

  /// No description provided for @turnActionButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get turnActionButtonLabel;

  /// No description provided for @endTurnButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'End turn'**
  String get endTurnButtonLabel;

  /// No description provided for @waitingTurnButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waitingTurnButtonLabel;

  /// No description provided for @waitingForPlayersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Waiting for other players'**
  String get waitingForPlayersTooltip;

  /// No description provided for @submitTurnTooltip.
  ///
  /// In en, this message translates to:
  /// **'Submit readiness on turn {turn}'**
  String submitTurnTooltip(int turn);

  /// No description provided for @endTurnTooltip.
  ///
  /// In en, this message translates to:
  /// **'End turn {turn}'**
  String endTurnTooltip(int turn);

  /// No description provided for @nextActionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Go to the next action'**
  String get nextActionTooltip;

  /// No description provided for @nextActionWithCountTooltip.
  ///
  /// In en, this message translates to:
  /// **'Go to the next action ({count} left)'**
  String nextActionWithCountTooltip(int count);

  /// No description provided for @turnActionListTooltip.
  ///
  /// In en, this message translates to:
  /// **'Choose an action from the list'**
  String get turnActionListTooltip;

  /// No description provided for @hudActionDeckCollapseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Collapse bottom toolbar'**
  String get hudActionDeckCollapseTooltip;

  /// No description provided for @hudActionDeckExpandTooltip.
  ///
  /// In en, this message translates to:
  /// **'Expand bottom toolbar'**
  String get hudActionDeckExpandTooltip;

  /// No description provided for @turnActionUnitKind.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get turnActionUnitKind;

  /// No description provided for @turnActionCityProductionKind.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get turnActionCityProductionKind;

  /// No description provided for @turnActionResearchKind.
  ///
  /// In en, this message translates to:
  /// **'Research'**
  String get turnActionResearchKind;

  /// No description provided for @turnActionCityProductionLabel.
  ///
  /// In en, this message translates to:
  /// **'{cityName} production'**
  String turnActionCityProductionLabel(String cityName);

  /// No description provided for @turnActionResearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose research'**
  String get turnActionResearchLabel;

  /// No description provided for @turnLabel.
  ///
  /// In en, this message translates to:
  /// **'TURN {turn}'**
  String turnLabel(int turn);

  /// No description provided for @loadGameError.
  ///
  /// In en, this message translates to:
  /// **'Load error: {error}'**
  String loadGameError(String error);

  /// No description provided for @backAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backAction;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @gameLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading world'**
  String get gameLoadingTitle;

  /// No description provided for @gameLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Preparing the map, units, and interface. The game will appear once the assets are ready.'**
  String get gameLoadingMessage;

  /// No description provided for @firstTurnTutorialPopupTitle.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get firstTurnTutorialPopupTitle;

  /// No description provided for @firstTurnTutorialPopupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'First-turn guide'**
  String get firstTurnTutorialPopupSubtitle;

  /// No description provided for @firstTurnTutorialSemantics.
  ///
  /// In en, this message translates to:
  /// **'First turn: {title}'**
  String firstTurnTutorialSemantics(String title);

  /// No description provided for @firstTurnCoachmarkProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {current}/{total}'**
  String firstTurnCoachmarkProgressLabel(int current, int total);

  /// No description provided for @firstTurnCoachmarkMinimizeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get firstTurnCoachmarkMinimizeTooltip;

  /// No description provided for @firstTurnCoachmarkSkipAction.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get firstTurnCoachmarkSkipAction;

  /// No description provided for @firstTurnCoachmarkNextAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get firstTurnCoachmarkNextAction;

  /// No description provided for @firstTurnCoachmarkDoneAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get firstTurnCoachmarkDoneAction;

  /// No description provided for @firstTurnCoachmarkSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 1: read the selection'**
  String get firstTurnCoachmarkSelectionTitle;

  /// No description provided for @firstTurnCoachmarkSelectionBody.
  ///
  /// In en, this message translates to:
  /// **'The game begins by selecting your first unit automatically. The bottom panel tells you what you command, how many actions remain, and which orders you can give now.'**
  String get firstTurnCoachmarkSelectionBody;

  /// No description provided for @firstTurnCoachmarkSelectionBodyUnit.
  ///
  /// In en, this message translates to:
  /// **'The bottom toolbar describes the selected unit: type, movement, action queue, and available orders. Use it to enter Move mode and cancel it when you want hex taps to return to inspection.'**
  String get firstTurnCoachmarkSelectionBodyUnit;

  /// No description provided for @firstTurnCoachmarkSelectionBodyCity.
  ///
  /// In en, this message translates to:
  /// **'You have a city selected. The bottom panel shows its production, population, buildings, and economic decisions. That is a different context than unit orders, so the tutorial will talk about the city.'**
  String get firstTurnCoachmarkSelectionBodyCity;

  /// No description provided for @firstTurnCoachmarkSelectionBodyNone.
  ///
  /// In en, this message translates to:
  /// **'When nothing is selected, the bottom panel shows the general turn state. Tap one of your units or cities to see concrete orders and information.'**
  String get firstTurnCoachmarkSelectionBodyNone;

  /// No description provided for @firstTurnCoachmarkResourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 2: check your empire'**
  String get firstTurnCoachmarkResourcesTitle;

  /// No description provided for @firstTurnCoachmarkResourcesBody.
  ///
  /// In en, this message translates to:
  /// **'The top bar shows the turn, gold, science, and resources. Gold sustains the economy, science drives research, and resources hint at what is worth building.'**
  String get firstTurnCoachmarkResourcesBody;

  /// No description provided for @firstTurnCoachmarkMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 3: learn the left menu'**
  String get firstTurnCoachmarkMenuTitle;

  /// No description provided for @firstTurnCoachmarkMenuBody.
  ///
  /// In en, this message translates to:
  /// **'The left menu gathers views you revisit every turn: map options, minimized popup replies, objectives, log, research, and empire. Long-press the menu button to collapse the rail, then tap the single button to open it again.'**
  String get firstTurnCoachmarkMenuBody;

  /// No description provided for @firstTurnCoachmarkActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 4: give the right order'**
  String get firstTurnCoachmarkActionTitle;

  /// No description provided for @firstTurnCoachmarkActionBodyActive.
  ///
  /// In en, this message translates to:
  /// **'If the settler stands on a good tile, use the found-city action. If the location is weak, move the unit and reveal terrain. Movement and special actions spend that unit\'s turn.'**
  String get firstTurnCoachmarkActionBodyActive;

  /// No description provided for @firstTurnCoachmarkActionBodyWaiting.
  ///
  /// In en, this message translates to:
  /// **'When a unit has an order, it appears here. In the first turns, move through units and cities one by one until no important decision is left behind.'**
  String get firstTurnCoachmarkActionBodyWaiting;

  /// No description provided for @firstTurnCoachmarkActionBodySettler.
  ///
  /// In en, this message translates to:
  /// **'The settler decides the start of your empire. If the tile offers growth, production, and room to expand, found a city. If the terrain is weak, move the settler and inspect nearby land first.'**
  String get firstTurnCoachmarkActionBodySettler;

  /// No description provided for @firstTurnCoachmarkActionBodyWorker.
  ///
  /// In en, this message translates to:
  /// **'A worker does not found cities. Its job is to improve tiles inside city borders: farms help growth, mines boost production, and resource improvements strengthen the economy.'**
  String get firstTurnCoachmarkActionBodyWorker;

  /// No description provided for @firstTurnCoachmarkActionBodyUnit.
  ///
  /// In en, this message translates to:
  /// **'For combat and scouting units, movement, vision, and safety matter most. Reveal terrain, protect city borders, and attack only when the predicted result is favorable.'**
  String get firstTurnCoachmarkActionBodyUnit;

  /// No description provided for @firstTurnCoachmarkActionBodyCity.
  ///
  /// In en, this message translates to:
  /// **'With a city selected, this area leads to production and management. Choose a build target, check city growth, and keep the city from sitting idle.'**
  String get firstTurnCoachmarkActionBodyCity;

  /// No description provided for @firstTurnCoachmarkResearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 5: choose research'**
  String get firstTurnCoachmarkResearchTitle;

  /// No description provided for @firstTurnCoachmarkResearchBody.
  ///
  /// In en, this message translates to:
  /// **'Open Research before ending the turn. Agriculture supports growth, Mining boosts production, and Hunting improves scouting and defense. Most importantly, science should not run without a target.'**
  String get firstTurnCoachmarkResearchBody;

  /// No description provided for @firstTurnCoachmarkResearchBodyAvailable.
  ///
  /// In en, this message translates to:
  /// **'Research is ready to choose. Open Research before ending the turn: Agriculture supports growth, Mining boosts production, and Hunting improves scouting and defense.'**
  String get firstTurnCoachmarkResearchBodyAvailable;

  /// No description provided for @firstTurnCoachmarkCityTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 6: set up the city'**
  String get firstTurnCoachmarkCityTitle;

  /// No description provided for @firstTurnCoachmarkCityBody.
  ///
  /// In en, this message translates to:
  /// **'After founding the capital, choose production. A worker develops tiles, a warrior secures the area, and buildings strengthen the economy. The city should always be building something.'**
  String get firstTurnCoachmarkCityBody;

  /// No description provided for @firstTurnCoachmarkCityBodySelected.
  ///
  /// In en, this message translates to:
  /// **'This is the city panel. Check production, growth, buildings, and available projects. The main rule for new turns: every city should have a production target.'**
  String get firstTurnCoachmarkCityBodySelected;

  /// No description provided for @firstTurnCoachmarkCityBodyNeedsProduction.
  ///
  /// In en, this message translates to:
  /// **'One of your cities is waiting for production. Use the action button or select the city, choose a unit, building, or project, and only then end the turn.'**
  String get firstTurnCoachmarkCityBodyNeedsProduction;

  /// No description provided for @firstTurnCoachmarkCityBodyExisting.
  ///
  /// In en, this message translates to:
  /// **'Your cities already have production assigned. In later turns, return here to watch growth, buildings, specialization, and defense needs.'**
  String get firstTurnCoachmarkCityBodyExisting;

  /// No description provided for @firstTurnCoachmarkCityBodyFuture.
  ///
  /// In en, this message translates to:
  /// **'After you found the first city, you will return here to choose production. A worker develops tiles, a warrior secures the area, and buildings strengthen the economy.'**
  String get firstTurnCoachmarkCityBodyFuture;

  /// No description provided for @firstTurnCoachmarkActionFlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 7: clear the action queue'**
  String get firstTurnCoachmarkActionFlowTitle;

  /// No description provided for @firstTurnCoachmarkActionFlowBodyReady.
  ///
  /// In en, this message translates to:
  /// **'All key decisions for this turn are ready. Before ending the turn, quickly confirm that research and city production both have a target.'**
  String get firstTurnCoachmarkActionFlowBodyReady;

  /// No description provided for @firstTurnCoachmarkActionFlowBodyPending.
  ///
  /// In en, this message translates to:
  /// **'The action button leads to the next unit, city, or missing choice. Keep pressing it until the game shows that it is safe to end the turn.'**
  String get firstTurnCoachmarkActionFlowBodyPending;

  /// No description provided for @firstTurnCoachmarkEndTurnTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 8: end the turn and repeat'**
  String get firstTurnCoachmarkEndTurnTitle;

  /// No description provided for @firstTurnCoachmarkEndTurnBody.
  ///
  /// In en, this message translates to:
  /// **'When nothing needs your response, end the turn. The rhythm of the next turns is the same: resources, units, city, research, then end turn.'**
  String get firstTurnCoachmarkEndTurnBody;

  /// No description provided for @firstTurnCoachmarkVictoryBody.
  ///
  /// In en, this message translates to:
  /// **'You can win by domination or by artifacts: place 6 unique artifacts in your cities and hold the collection for 5 turns.'**
  String get firstTurnCoachmarkVictoryBody;

  /// No description provided for @firstTurnCoachmarkHexTapBody.
  ///
  /// In en, this message translates to:
  /// **'Click or tap the same hex several times to cycle its information: tile selection, artifact, map objective, and hex description.'**
  String get firstTurnCoachmarkHexTapBody;

  /// No description provided for @gameLoadMapErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load map'**
  String get gameLoadMapErrorTitle;

  /// No description provided for @gameLoadMapErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not load map \"{mapName}\": {error}'**
  String gameLoadMapErrorMessage(String mapName, String error);

  /// No description provided for @gameOutcomeVictoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Victory'**
  String get gameOutcomeVictoryTitle;

  /// No description provided for @gameOutcomeDefeatTitle.
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get gameOutcomeDefeatTitle;

  /// No description provided for @gameOutcomeDrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get gameOutcomeDrawTitle;

  /// No description provided for @gameOutcomeCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Game over'**
  String get gameOutcomeCompleteTitle;

  /// No description provided for @gameOutcomeConditionConquest.
  ///
  /// In en, this message translates to:
  /// **'Conquest'**
  String get gameOutcomeConditionConquest;

  /// No description provided for @gameOutcomeConditionScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get gameOutcomeConditionScore;

  /// No description provided for @gameOutcomeConditionScoreDraw.
  ///
  /// In en, this message translates to:
  /// **'Score draw'**
  String get gameOutcomeConditionScoreDraw;

  /// No description provided for @gameOutcomeConditionDomination.
  ///
  /// In en, this message translates to:
  /// **'Domination'**
  String get gameOutcomeConditionDomination;

  /// No description provided for @gameOutcomeConquestNoWinner.
  ///
  /// In en, this message translates to:
  /// **'One empire remains on the map.'**
  String get gameOutcomeConquestNoWinner;

  /// No description provided for @gameOutcomeConquestWinner.
  ///
  /// In en, this message translates to:
  /// **'{winner} is the last empire on the map.'**
  String gameOutcomeConquestWinner(String winner);

  /// No description provided for @gameOutcomeScoreNoWinner.
  ///
  /// In en, this message translates to:
  /// **'The turn limit decided the result.'**
  String get gameOutcomeScoreNoWinner;

  /// No description provided for @gameOutcomeScoreWinner.
  ///
  /// In en, this message translates to:
  /// **'{winner} wins after the turn limit.'**
  String gameOutcomeScoreWinner(String winner);

  /// No description provided for @gameOutcomeScoreDrawSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn limit reached. The highest score is tied.'**
  String get gameOutcomeScoreDrawSubtitle;

  /// No description provided for @gameOutcomeDominationNoWinner.
  ///
  /// In en, this message translates to:
  /// **'Map control was held.'**
  String get gameOutcomeDominationNoWinner;

  /// No description provided for @gameOutcomeDominationWinner.
  ///
  /// In en, this message translates to:
  /// **'{winner} holds territorial domination.'**
  String gameOutcomeDominationWinner(String winner);

  /// No description provided for @gameOutcomeWinnerMetric.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get gameOutcomeWinnerMetric;

  /// No description provided for @gameOutcomeConditionMetric.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get gameOutcomeConditionMetric;

  /// No description provided for @gameOutcomeEliminationMetric.
  ///
  /// In en, this message translates to:
  /// **'Elimination'**
  String get gameOutcomeEliminationMetric;

  /// No description provided for @gameOutcomeMapControlMetric.
  ///
  /// In en, this message translates to:
  /// **'Map control'**
  String get gameOutcomeMapControlMetric;

  /// No description provided for @gameOutcomeHoldMetric.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get gameOutcomeHoldMetric;

  /// No description provided for @gameOutcomeThresholdMetric.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get gameOutcomeThresholdMetric;

  /// No description provided for @gameOutcomeTurnsValue.
  ///
  /// In en, this message translates to:
  /// **'{held}/{required} turns'**
  String gameOutcomeTurnsValue(int held, int required);

  /// No description provided for @victoryConquestPrimary.
  ///
  /// In en, this message translates to:
  /// **'Conquest'**
  String get victoryConquestPrimary;

  /// No description provided for @victoryGoalCompact.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get victoryGoalCompact;

  /// No description provided for @victoryNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get victoryNoLimit;

  /// No description provided for @victoryConquestTooltip.
  ///
  /// In en, this message translates to:
  /// **'Goal: eliminate rivals. No turn limit.'**
  String get victoryConquestTooltip;

  /// No description provided for @victoryLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get victoryLimitLabel;

  /// No description provided for @victoryNoneValue.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get victoryNoneValue;

  /// No description provided for @victoryScoreCapPrimary.
  ///
  /// In en, this message translates to:
  /// **'SCORE CAP'**
  String get victoryScoreCapPrimary;

  /// No description provided for @victoryScoreRemainingPrimary.
  ///
  /// In en, this message translates to:
  /// **'SCORE {turns}T'**
  String victoryScoreRemainingPrimary(int turns);

  /// No description provided for @victoryScoreCapCompact.
  ///
  /// In en, this message translates to:
  /// **'CAP'**
  String get victoryScoreCapCompact;

  /// No description provided for @victoryTurnsCompact.
  ///
  /// In en, this message translates to:
  /// **'{turns}T'**
  String victoryTurnsCompact(int turns);

  /// No description provided for @victoryTurns.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 turn} other{{count} turns}}'**
  String victoryTurns(int count);

  /// No description provided for @victoryRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get victoryRemainingLabel;

  /// No description provided for @victoryScoreLeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'Score leader'**
  String get victoryScoreLeaderLabel;

  /// No description provided for @victoryScoreDrawLabel.
  ///
  /// In en, this message translates to:
  /// **'DRAW {score}'**
  String victoryScoreDrawLabel(int score);

  /// No description provided for @victoryScoreLimitReachedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Turn limit {turnLimit} reached. Score decides the result.'**
  String victoryScoreLimitReachedTooltip(int turnLimit);

  /// No description provided for @victoryScoreFallbackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Score fallback in {remainingTurns} turns. Limit: {turnLimit}.'**
  String victoryScoreFallbackTooltip(int remainingTurns, int turnLimit);

  /// No description provided for @victoryLeaderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Leader: {leader}.'**
  String victoryLeaderTooltip(String leader);

  /// No description provided for @victoryDominationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Domination: {leader} controls {control}% of the map. Threshold: {required}%, hold: {hold}.'**
  String victoryDominationTooltip(
    String leader,
    String control,
    String required,
    String hold,
  );

  /// No description provided for @victoryLeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get victoryLeaderLabel;

  /// No description provided for @victoryControlLabel.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get victoryControlLabel;

  /// No description provided for @victoryHoldLabel.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get victoryHoldLabel;

  /// No description provided for @victoryYouLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get victoryYouLabel;

  /// No description provided for @victoryPressureLabel.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get victoryPressureLabel;

  /// No description provided for @victoryFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Fallback'**
  String get victoryFallbackLabel;

  /// No description provided for @victoryYourGoalGainControl.
  ///
  /// In en, this message translates to:
  /// **'Your goal: gain {points} pp more map control.'**
  String victoryYourGoalGainControl(int points);

  /// No description provided for @victoryYourGoalReady.
  ///
  /// In en, this message translates to:
  /// **'Your goal: the domination condition is ready to resolve.'**
  String get victoryYourGoalReady;

  /// No description provided for @victoryYourGoalHold.
  ///
  /// In en, this message translates to:
  /// **'Your goal: hold the threshold for {turns} more.'**
  String victoryYourGoalHold(String turns);

  /// No description provided for @victoryLeaderAboveThreshold.
  ///
  /// In en, this message translates to:
  /// **'{leader} is above the threshold; break that control before the goal is held.'**
  String victoryLeaderAboveThreshold(String leader);

  /// No description provided for @victoryYourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your progress: {control}% / {required}%.'**
  String victoryYourProgress(String control, String required);

  /// No description provided for @victoryPressureReachThreshold.
  ///
  /// In en, this message translates to:
  /// **'Reach the threshold: missing {points} pp'**
  String victoryPressureReachThreshold(int points);

  /// No description provided for @victoryConditionReady.
  ///
  /// In en, this message translates to:
  /// **'Condition ready'**
  String get victoryConditionReady;

  /// No description provided for @victoryPressureHold.
  ///
  /// In en, this message translates to:
  /// **'Hold for {turns}'**
  String victoryPressureHold(String turns);

  /// No description provided for @victoryPressureLeaderHolding.
  ///
  /// In en, this message translates to:
  /// **'{leader} above threshold: {turns}'**
  String victoryPressureLeaderHolding(String leader, String turns);

  /// No description provided for @victoryPressureYourGap.
  ///
  /// In en, this message translates to:
  /// **'Your goal: missing {points} pp'**
  String victoryPressureYourGap(int points);

  /// No description provided for @victoryPressureLeaderGap.
  ///
  /// In en, this message translates to:
  /// **'{leader} leads: missing {points} pp'**
  String victoryPressureLeaderGap(String leader, int points);

  /// No description provided for @victoryThreatApproaching.
  ///
  /// In en, this message translates to:
  /// **'Rival approaches domination: {player} controls {control}% at the {required}% threshold; missing {points} pp.'**
  String victoryThreatApproaching(
    String player,
    String control,
    String required,
    int points,
  );

  /// No description provided for @victoryThreatHolding.
  ///
  /// In en, this message translates to:
  /// **'Rival is holding the domination threshold: {player} {hold}.'**
  String victoryThreatHolding(String player, String hold);

  /// No description provided for @victoryThreatImminent.
  ///
  /// In en, this message translates to:
  /// **'Rival is close to domination: {player} {hold}.'**
  String victoryThreatImminent(String player, String hold);

  /// No description provided for @victoryThreatPressureApproaching.
  ///
  /// In en, this message translates to:
  /// **'{player} near threshold: missing {points} pp'**
  String victoryThreatPressureApproaching(String player, int points);

  /// No description provided for @victoryThreatPressureBreak.
  ///
  /// In en, this message translates to:
  /// **'Break {player}: {turns}'**
  String victoryThreatPressureBreak(String player, String turns);

  /// No description provided for @victoryBelowThreshold.
  ///
  /// In en, this message translates to:
  /// **'below threshold'**
  String get victoryBelowThreshold;

  /// No description provided for @victoryHoldProgress.
  ///
  /// In en, this message translates to:
  /// **'{held}/{required} turns'**
  String victoryHoldProgress(int held, int required);

  /// No description provided for @victoryHoldCompact.
  ///
  /// In en, this message translates to:
  /// **'{held}/{required}T'**
  String victoryHoldCompact(int held, int required);

  /// No description provided for @victoryReady.
  ///
  /// In en, this message translates to:
  /// **'ready'**
  String get victoryReady;

  /// No description provided for @victoryRemainingTurns.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 turn left} other{{count} turns left}}'**
  String victoryRemainingTurns(int count);

  /// No description provided for @returnToMenuAction.
  ///
  /// In en, this message translates to:
  /// **'Return to menu'**
  String get returnToMenuAction;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get yesterday;

  /// No description provided for @objectivesPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'OBJECTIVES'**
  String get objectivesPanelTitle;

  /// No description provided for @objectivesCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close objectives'**
  String get objectivesCloseTooltip;

  /// No description provided for @objectivesMenuClosePrefix.
  ///
  /// In en, this message translates to:
  /// **'Close objectives'**
  String get objectivesMenuClosePrefix;

  /// No description provided for @objectivesMenuOpenPrefix.
  ///
  /// In en, this message translates to:
  /// **'Objectives'**
  String get objectivesMenuOpenPrefix;

  /// No description provided for @objectivesMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'{prefix}: {descriptor} - {title} ({progress}, {count})'**
  String objectivesMenuTooltip(
    String prefix,
    String descriptor,
    String title,
    String progress,
    String count,
  );

  /// No description provided for @objectivesMenuCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 objective} other{{count} objectives}}'**
  String objectivesMenuCount(int count);

  /// No description provided for @objectivesMenuBadgeScore.
  ///
  /// In en, this message translates to:
  /// **'PTS'**
  String get objectivesMenuBadgeScore;

  /// No description provided for @objectivesMenuBadgeDomination.
  ///
  /// In en, this message translates to:
  /// **'DOM'**
  String get objectivesMenuBadgeDomination;

  /// No description provided for @objectivesMenuDescriptorDomination.
  ///
  /// In en, this message translates to:
  /// **'domination'**
  String get objectivesMenuDescriptorDomination;

  /// No description provided for @objectivesMenuDescriptorDominationThreat.
  ///
  /// In en, this message translates to:
  /// **'domination threat'**
  String get objectivesMenuDescriptorDominationThreat;

  /// No description provided for @objectivesMenuDescriptorScoreLead.
  ///
  /// In en, this message translates to:
  /// **'lead defense'**
  String get objectivesMenuDescriptorScoreLead;

  /// No description provided for @objectivesMenuDescriptorScorePressure.
  ///
  /// In en, this message translates to:
  /// **'score pressure'**
  String get objectivesMenuDescriptorScorePressure;

  /// No description provided for @objectivesMenuDescriptorActiveObjective.
  ///
  /// In en, this message translates to:
  /// **'active objective'**
  String get objectivesMenuDescriptorActiveObjective;

  /// No description provided for @objectiveMicroTooltipLabel.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get objectiveMicroTooltipLabel;

  /// No description provided for @objectiveOverviewGuidanceLabel.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE OBJECTIVE'**
  String get objectiveOverviewGuidanceLabel;

  /// No description provided for @objectiveOverviewStrategicLabel.
  ///
  /// In en, this message translates to:
  /// **'URGENT'**
  String get objectiveOverviewStrategicLabel;

  /// No description provided for @objectiveOverviewScoreCatchUpLabel.
  ///
  /// In en, this message translates to:
  /// **'SCORE PRESSURE'**
  String get objectiveOverviewScoreCatchUpLabel;

  /// No description provided for @objectiveOverviewScoreProtectLabel.
  ///
  /// In en, this message translates to:
  /// **'DEFEND LEAD'**
  String get objectiveOverviewScoreProtectLabel;

  /// No description provided for @objectiveOverviewDominationHoldLabel.
  ///
  /// In en, this message translates to:
  /// **'DOMINATION'**
  String get objectiveOverviewDominationHoldLabel;

  /// No description provided for @objectiveOverviewDominationThreatLabel.
  ///
  /// In en, this message translates to:
  /// **'DOMINATION THREAT'**
  String get objectiveOverviewDominationThreatLabel;

  /// No description provided for @objectiveOverviewTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Top priority: {title}'**
  String objectiveOverviewTitleLabel(String title);

  /// No description provided for @objectiveOverviewProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress {progress}'**
  String objectiveOverviewProgressLabel(String progress);

  /// No description provided for @objectivePhaseFoundation.
  ///
  /// In en, this message translates to:
  /// **'Foundation'**
  String get objectivePhaseFoundation;

  /// No description provided for @objectivePhaseExpansion.
  ///
  /// In en, this message translates to:
  /// **'Expansion'**
  String get objectivePhaseExpansion;

  /// No description provided for @objectivePhasePressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get objectivePhasePressure;

  /// No description provided for @objectivePhaseEndgame.
  ///
  /// In en, this message translates to:
  /// **'Endgame'**
  String get objectivePhaseEndgame;

  /// No description provided for @objectiveChooseResearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose research'**
  String get objectiveChooseResearchTitle;

  /// No description provided for @objectiveChooseResearchHint.
  ///
  /// In en, this message translates to:
  /// **'Set your development direction before the first turn ends.'**
  String get objectiveChooseResearchHint;

  /// No description provided for @objectiveChooseResearchReward.
  ///
  /// In en, this message translates to:
  /// **'+ science tempo'**
  String get objectiveChooseResearchReward;

  /// No description provided for @objectiveChooseResearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Research turns every following turn toward a specific development path.'**
  String get objectiveChooseResearchTooltip;

  /// No description provided for @objectiveFoundCapitalTitle.
  ///
  /// In en, this message translates to:
  /// **'Found your first city'**
  String get objectiveFoundCapitalTitle;

  /// No description provided for @objectiveFoundCapitalHint.
  ///
  /// In en, this message translates to:
  /// **'Your settler should quickly turn good terrain into a capital.'**
  String get objectiveFoundCapitalHint;

  /// No description provided for @objectiveFoundCapitalReward.
  ///
  /// In en, this message translates to:
  /// **'+ production base'**
  String get objectiveFoundCapitalReward;

  /// No description provided for @objectiveFoundCapitalTooltip.
  ///
  /// In en, this message translates to:
  /// **'The capital unlocks production, growth, and territorial reach.'**
  String get objectiveFoundCapitalTooltip;

  /// No description provided for @objectiveExploreNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore nearby land'**
  String get objectiveExploreNearbyTitle;

  /// No description provided for @objectiveExploreNearbyHint.
  ///
  /// In en, this message translates to:
  /// **'Your warrior should reveal nearby resources and city sites.'**
  String get objectiveExploreNearbyHint;

  /// No description provided for @objectiveExploreNearbyReward.
  ///
  /// In en, this message translates to:
  /// **'+ better decisions'**
  String get objectiveExploreNearbyReward;

  /// No description provided for @objectiveExploreNearbyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Early scouting helps choose city sites and avoid blind moves.'**
  String get objectiveExploreNearbyTooltip;

  /// No description provided for @objectiveQueueWorkerTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue a worker'**
  String get objectiveQueueWorkerTitle;

  /// No description provided for @objectiveQueueWorkerHint.
  ///
  /// In en, this message translates to:
  /// **'A worker turns food and production on the map into a real advantage.'**
  String get objectiveQueueWorkerHint;

  /// No description provided for @objectiveQueueWorkerReward.
  ///
  /// In en, this message translates to:
  /// **'+ field development'**
  String get objectiveQueueWorkerReward;

  /// No description provided for @objectiveQueueWorkerTooltip.
  ///
  /// In en, this message translates to:
  /// **'A worker turns good tiles into steady resource growth.'**
  String get objectiveQueueWorkerTooltip;

  /// No description provided for @objectiveImproveFirstHexTitle.
  ///
  /// In en, this message translates to:
  /// **'Improve your first tile'**
  String get objectiveImproveFirstHexTitle;

  /// No description provided for @objectiveImproveFirstHexHint.
  ///
  /// In en, this message translates to:
  /// **'The first improvement should support food, production, or gold.'**
  String get objectiveImproveFirstHexHint;

  /// No description provided for @objectiveImproveFirstHexReward.
  ///
  /// In en, this message translates to:
  /// **'+ stronger economy'**
  String get objectiveImproveFirstHexReward;

  /// No description provided for @objectiveImproveFirstHexTooltip.
  ///
  /// In en, this message translates to:
  /// **'The first improvement shows which part of the city economy should grow fastest.'**
  String get objectiveImproveFirstHexTooltip;

  /// No description provided for @objectiveFoundSecondCityTitle.
  ///
  /// In en, this message translates to:
  /// **'Found a second city'**
  String get objectiveFoundSecondCityTitle;

  /// No description provided for @objectiveFoundSecondCityHint.
  ///
  /// In en, this message translates to:
  /// **'A second settlement opens expansion without flooding the map with units.'**
  String get objectiveFoundSecondCityHint;

  /// No description provided for @objectiveFoundSecondCityReward.
  ///
  /// In en, this message translates to:
  /// **'+ empire scale'**
  String get objectiveFoundSecondCityReward;

  /// No description provided for @objectiveFoundSecondCityTooltip.
  ///
  /// In en, this message translates to:
  /// **'A second city increases production pace without waiting on one capital.'**
  String get objectiveFoundSecondCityTooltip;

  /// No description provided for @objectiveBuildFirstBuildingTitle.
  ///
  /// In en, this message translates to:
  /// **'Build your first building'**
  String get objectiveBuildFirstBuildingTitle;

  /// No description provided for @objectiveBuildFirstBuildingHint.
  ///
  /// In en, this message translates to:
  /// **'The first building should strengthen food, production, or gold.'**
  String get objectiveBuildFirstBuildingHint;

  /// No description provided for @objectiveBuildFirstBuildingReward.
  ///
  /// In en, this message translates to:
  /// **'+ lasting city advantage'**
  String get objectiveBuildFirstBuildingReward;

  /// No description provided for @objectiveBuildFirstBuildingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Buildings stay in the city and scale across many turns.'**
  String get objectiveBuildFirstBuildingTooltip;

  /// No description provided for @objectiveImproveThreeHexesTitle.
  ///
  /// In en, this message translates to:
  /// **'Improve three tiles'**
  String get objectiveImproveThreeHexesTitle;

  /// No description provided for @objectiveImproveThreeHexesHint.
  ///
  /// In en, this message translates to:
  /// **'Several improvements turn a starting camp into an economy.'**
  String get objectiveImproveThreeHexesHint;

  /// No description provided for @objectiveImproveThreeHexesReward.
  ///
  /// In en, this message translates to:
  /// **'+ stable income'**
  String get objectiveImproveThreeHexesReward;

  /// No description provided for @objectiveImproveThreeHexesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Three improvements create a stable base for armies, research, or expansion.'**
  String get objectiveImproveThreeHexesTooltip;

  /// No description provided for @objectiveFoundThirdCityTitle.
  ///
  /// In en, this message translates to:
  /// **'Found a third city'**
  String get objectiveFoundThirdCityTitle;

  /// No description provided for @objectiveFoundThirdCityHint.
  ///
  /// In en, this message translates to:
  /// **'A third settlement creates a true empire and a second expansion direction.'**
  String get objectiveFoundThirdCityHint;

  /// No description provided for @objectiveFoundThirdCityReward.
  ///
  /// In en, this message translates to:
  /// **'+ map scale'**
  String get objectiveFoundThirdCityReward;

  /// No description provided for @objectiveFoundThirdCityTooltip.
  ///
  /// In en, this message translates to:
  /// **'A third city gives you a second development front and more decisions every turn.'**
  String get objectiveFoundThirdCityTooltip;

  /// No description provided for @objectiveExploreRegionTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore the region'**
  String get objectiveExploreRegionTitle;

  /// No description provided for @objectiveExploreRegionHint.
  ///
  /// In en, this message translates to:
  /// **'A wider map reveals resources, rivals, and places worth defending.'**
  String get objectiveExploreRegionHint;

  /// No description provided for @objectiveExploreRegionReward.
  ///
  /// In en, this message translates to:
  /// **'+ strategic plan'**
  String get objectiveExploreRegionReward;

  /// No description provided for @objectiveExploreRegionTooltip.
  ///
  /// In en, this message translates to:
  /// **'A wider map reveals rivals, strategic resources, and safe borders.'**
  String get objectiveExploreRegionTooltip;

  /// No description provided for @objectiveBuildCombatForceTitle.
  ///
  /// In en, this message translates to:
  /// **'Build a defensive force'**
  String get objectiveBuildCombatForceTitle;

  /// No description provided for @objectiveBuildCombatForceHint.
  ///
  /// In en, this message translates to:
  /// **'Several troops let you protect expansion and pressure rivals.'**
  String get objectiveBuildCombatForceHint;

  /// No description provided for @objectiveBuildCombatForceReward.
  ///
  /// In en, this message translates to:
  /// **'+ border security'**
  String get objectiveBuildCombatForceReward;

  /// No description provided for @objectiveBuildCombatForceTooltip.
  ///
  /// In en, this message translates to:
  /// **'A steady screen protects settlers, workers, and developed cities.'**
  String get objectiveBuildCombatForceTooltip;

  /// No description provided for @objectiveHoldDominationTitle.
  ///
  /// In en, this message translates to:
  /// **'Hold domination'**
  String get objectiveHoldDominationTitle;

  /// No description provided for @objectiveHoldDominationHint.
  ///
  /// In en, this message translates to:
  /// **'You are above the map threshold. Keep control until the countdown ends.'**
  String get objectiveHoldDominationHint;

  /// No description provided for @objectiveHoldDominationReward.
  ///
  /// In en, this message translates to:
  /// **'+ map victory'**
  String get objectiveHoldDominationReward;

  /// No description provided for @objectiveHoldDominationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Domination ends the game before the score cap if you hold the required map percentage for consecutive turns.'**
  String get objectiveHoldDominationTooltip;

  /// No description provided for @objectiveBreakDominationHoldTitle.
  ///
  /// In en, this message translates to:
  /// **'Break a rival\'s domination'**
  String get objectiveBreakDominationHoldTitle;

  /// No description provided for @objectiveBreakDominationHoldHint.
  ///
  /// In en, this message translates to:
  /// **'A rival is above the map threshold. Take territory before they hold the objective.'**
  String get objectiveBreakDominationHoldHint;

  /// No description provided for @objectiveBreakDominationHoldReward.
  ///
  /// In en, this message translates to:
  /// **'+ countdown stopped'**
  String get objectiveBreakDominationHoldReward;

  /// No description provided for @objectiveBreakDominationHoldTooltip.
  ///
  /// In en, this message translates to:
  /// **'If a rival falls below the control threshold, their hold turns reset to zero.'**
  String get objectiveBreakDominationHoldTooltip;

  /// No description provided for @objectiveHoldScoreLeadTitle.
  ///
  /// In en, this message translates to:
  /// **'Hold the lead'**
  String get objectiveHoldScoreLeadTitle;

  /// No description provided for @objectiveHoldScoreLeadHint.
  ///
  /// In en, this message translates to:
  /// **'The turn limit is close. Protect your score and avoid losing your edge in the final turns.'**
  String get objectiveHoldScoreLeadHint;

  /// No description provided for @objectiveHoldScoreLeadReward.
  ///
  /// In en, this message translates to:
  /// **'+ score-cap win'**
  String get objectiveHoldScoreLeadReward;

  /// No description provided for @objectiveHoldScoreLeadTooltip.
  ///
  /// In en, this message translates to:
  /// **'The score cap decides the match when the turn limit passes, so the point lead must last to the end.'**
  String get objectiveHoldScoreLeadTooltip;

  /// No description provided for @objectiveOvertakeScoreLeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Catch the score leader'**
  String get objectiveOvertakeScoreLeaderTitle;

  /// No description provided for @objectiveOvertakeScoreLeaderHint.
  ///
  /// In en, this message translates to:
  /// **'The turn limit is close. You need fast score growth or a weaker leader.'**
  String get objectiveOvertakeScoreLeaderHint;

  /// No description provided for @objectiveOvertakeScoreLeaderReward.
  ///
  /// In en, this message translates to:
  /// **'+ score-cap chance'**
  String get objectiveOvertakeScoreLeaderReward;

  /// No description provided for @objectiveOvertakeScoreLeaderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Build cities, population, technologies, units, and improvements; if scores tie, the score cap ends in a draw.'**
  String get objectiveOvertakeScoreLeaderTooltip;

  /// No description provided for @objectiveSecureMapObjectiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure the map objective'**
  String get objectiveSecureMapObjectiveTitle;

  /// No description provided for @objectiveSecureMapObjectiveHint.
  ///
  /// In en, this message translates to:
  /// **'Keep a unit or city influence on the objective until the hold completes.'**
  String get objectiveSecureMapObjectiveHint;

  /// No description provided for @objectiveSecureMapObjectiveReward.
  ///
  /// In en, this message translates to:
  /// **'+ objective rewards'**
  String get objectiveSecureMapObjectiveReward;

  /// No description provided for @objectiveSecureMapObjectiveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Map objectives use triangle markers and grant their victory points or gold only after consecutive control.'**
  String get objectiveSecureMapObjectiveTooltip;

  /// No description provided for @objectiveBreakMapObjectiveHoldTitle.
  ///
  /// In en, this message translates to:
  /// **'Break the rival objective'**
  String get objectiveBreakMapObjectiveHoldTitle;

  /// No description provided for @objectiveBreakMapObjectiveHoldHint.
  ///
  /// In en, this message translates to:
  /// **'A rival is holding a map objective. Contest the triangle marker before the hold completes.'**
  String get objectiveBreakMapObjectiveHoldHint;

  /// No description provided for @objectiveBreakMapObjectiveHoldReward.
  ///
  /// In en, this message translates to:
  /// **'+ denied objective'**
  String get objectiveBreakMapObjectiveHoldReward;

  /// No description provided for @objectiveBreakMapObjectiveHoldTooltip.
  ///
  /// In en, this message translates to:
  /// **'Moving onto the objective with your own force contests control and resets the rival\'s progress.'**
  String get objectiveBreakMapObjectiveHoldTooltip;

  /// No description provided for @objectiveAdviceFoundCity.
  ///
  /// In en, this message translates to:
  /// **'Biggest gap: a new or captured city.'**
  String get objectiveAdviceFoundCity;

  /// No description provided for @objectiveAdviceGrowPopulation.
  ///
  /// In en, this message translates to:
  /// **'Biggest gap: population growth.'**
  String get objectiveAdviceGrowPopulation;

  /// No description provided for @objectiveAdviceClaimTerritory.
  ///
  /// In en, this message translates to:
  /// **'Biggest gap: more controlled tiles.'**
  String get objectiveAdviceClaimTerritory;

  /// No description provided for @objectiveAdviceConstructBuilding.
  ///
  /// In en, this message translates to:
  /// **'Biggest gap: a city building.'**
  String get objectiveAdviceConstructBuilding;

  /// No description provided for @objectiveAdviceTrainUnit.
  ///
  /// In en, this message translates to:
  /// **'Biggest gap: a quick unit.'**
  String get objectiveAdviceTrainUnit;

  /// No description provided for @objectiveAdviceUnlockTechnology.
  ///
  /// In en, this message translates to:
  /// **'Biggest gap: completing a technology.'**
  String get objectiveAdviceUnlockTechnology;

  /// No description provided for @objectiveAdviceImproveField.
  ///
  /// In en, this message translates to:
  /// **'Biggest gap: a tile improvement.'**
  String get objectiveAdviceImproveField;

  /// No description provided for @objectiveAdviceCollectGold.
  ///
  /// In en, this message translates to:
  /// **'Biggest gap: gold for score.'**
  String get objectiveAdviceCollectGold;

  /// No description provided for @objectiveAdviceProtectLead.
  ///
  /// In en, this message translates to:
  /// **'Priority: do not give up cities, and secure the next score gain.'**
  String get objectiveAdviceProtectLead;

  /// No description provided for @objectiveScoreBreakdownCatchUpHeader.
  ///
  /// In en, this message translates to:
  /// **'Score gap: {delta} pts'**
  String objectiveScoreBreakdownCatchUpHeader(int delta);

  /// No description provided for @objectiveScoreBreakdownProtectHeader.
  ///
  /// In en, this message translates to:
  /// **'Score lead: {delta} pts'**
  String objectiveScoreBreakdownProtectHeader(int delta);

  /// No description provided for @objectiveScoreBreakdownCatchUpTotals.
  ///
  /// In en, this message translates to:
  /// **'You {playerScore} / leader {comparisonScore}'**
  String objectiveScoreBreakdownCatchUpTotals(
    int playerScore,
    int comparisonScore,
  );

  /// No description provided for @objectiveScoreBreakdownProtectTotals.
  ///
  /// In en, this message translates to:
  /// **'You {playerScore} / rival {comparisonScore}'**
  String objectiveScoreBreakdownProtectTotals(
    int playerScore,
    int comparisonScore,
  );

  /// No description provided for @objectiveScoreBreakdownCatchUpDelta.
  ///
  /// In en, this message translates to:
  /// **'short by {delta}'**
  String objectiveScoreBreakdownCatchUpDelta(int delta);

  /// No description provided for @objectiveScoreBreakdownProtectDelta.
  ///
  /// In en, this message translates to:
  /// **'+{delta}'**
  String objectiveScoreBreakdownProtectDelta(int delta);

  /// No description provided for @objectiveScoreCategoryCity.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get objectiveScoreCategoryCity;

  /// No description provided for @objectiveScoreCategoryPopulation.
  ///
  /// In en, this message translates to:
  /// **'Population'**
  String get objectiveScoreCategoryPopulation;

  /// No description provided for @objectiveScoreCategoryTerritory.
  ///
  /// In en, this message translates to:
  /// **'Territory'**
  String get objectiveScoreCategoryTerritory;

  /// No description provided for @objectiveScoreCategoryBuilding.
  ///
  /// In en, this message translates to:
  /// **'Buildings'**
  String get objectiveScoreCategoryBuilding;

  /// No description provided for @objectiveScoreCategoryUnit.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get objectiveScoreCategoryUnit;

  /// No description provided for @objectiveScoreCategoryTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technologies'**
  String get objectiveScoreCategoryTechnology;

  /// No description provided for @objectiveScoreCategoryImprovement.
  ///
  /// In en, this message translates to:
  /// **'Improvements'**
  String get objectiveScoreCategoryImprovement;

  /// No description provided for @objectiveScoreCategoryGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get objectiveScoreCategoryGold;

  /// No description provided for @cityBuildingGranary.
  ///
  /// In en, this message translates to:
  /// **'Granary'**
  String get cityBuildingGranary;

  /// No description provided for @cityBuildingWaterMill.
  ///
  /// In en, this message translates to:
  /// **'Water Mill'**
  String get cityBuildingWaterMill;

  /// No description provided for @cityBuildingWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop'**
  String get cityBuildingWorkshop;

  /// No description provided for @cityBuildingStorehouse.
  ///
  /// In en, this message translates to:
  /// **'Storehouse'**
  String get cityBuildingStorehouse;

  /// No description provided for @cityBuildingHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get cityBuildingHousing;

  /// No description provided for @cityBuildingMerchantHall.
  ///
  /// In en, this message translates to:
  /// **'Merchant Hall'**
  String get cityBuildingMerchantHall;

  /// No description provided for @cityBuildingStonemason.
  ///
  /// In en, this message translates to:
  /// **'Stonemason'**
  String get cityBuildingStonemason;

  /// No description provided for @cityBuildingBarracks.
  ///
  /// In en, this message translates to:
  /// **'Barracks'**
  String get cityBuildingBarracks;

  /// No description provided for @cityBuildingMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get cityBuildingMarketplace;

  /// No description provided for @cityBuildingPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get cityBuildingPort;

  /// No description provided for @cityBuildingAqueduct.
  ///
  /// In en, this message translates to:
  /// **'Aqueduct'**
  String get cityBuildingAqueduct;

  /// No description provided for @cityBuildingForge.
  ///
  /// In en, this message translates to:
  /// **'Forge'**
  String get cityBuildingForge;

  /// No description provided for @cityBuildingStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get cityBuildingStable;

  /// No description provided for @cityBuildingBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get cityBuildingBank;

  /// No description provided for @cityBuildingBuildersGuild.
  ///
  /// In en, this message translates to:
  /// **'Builders\' Guild'**
  String get cityBuildingBuildersGuild;

  /// No description provided for @cityBuildingFactory.
  ///
  /// In en, this message translates to:
  /// **'Factory'**
  String get cityBuildingFactory;

  /// No description provided for @cityBuildingLighthouse.
  ///
  /// In en, this message translates to:
  /// **'Lighthouse'**
  String get cityBuildingLighthouse;

  /// No description provided for @cityBuildingTrainingGrounds.
  ///
  /// In en, this message translates to:
  /// **'Training Grounds'**
  String get cityBuildingTrainingGrounds;

  /// No description provided for @cityBuildingTownHall.
  ///
  /// In en, this message translates to:
  /// **'Town Hall'**
  String get cityBuildingTownHall;

  /// No description provided for @cityBuildingMonument.
  ///
  /// In en, this message translates to:
  /// **'Monument'**
  String get cityBuildingMonument;

  /// No description provided for @cityBuildingArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get cityBuildingArchive;

  /// No description provided for @cityBuildingAcademy.
  ///
  /// In en, this message translates to:
  /// **'Academy'**
  String get cityBuildingAcademy;

  /// No description provided for @cityBuildingUniversity.
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get cityBuildingUniversity;

  /// No description provided for @cityBuildingObservatory.
  ///
  /// In en, this message translates to:
  /// **'Observatory'**
  String get cityBuildingObservatory;

  /// No description provided for @cityBuildingLaboratory.
  ///
  /// In en, this message translates to:
  /// **'Laboratory'**
  String get cityBuildingLaboratory;

  /// No description provided for @cityBuildingReactor.
  ///
  /// In en, this message translates to:
  /// **'Reactor'**
  String get cityBuildingReactor;

  /// No description provided for @cityBuildingCourthouse.
  ///
  /// In en, this message translates to:
  /// **'Courthouse'**
  String get cityBuildingCourthouse;

  /// No description provided for @cityBuildingCourt.
  ///
  /// In en, this message translates to:
  /// **'Court'**
  String get cityBuildingCourt;

  /// No description provided for @cityBuildingGovernorsOffice.
  ///
  /// In en, this message translates to:
  /// **'Governor\'s Office'**
  String get cityBuildingGovernorsOffice;

  /// No description provided for @cityBuildingSurveyorsOffice.
  ///
  /// In en, this message translates to:
  /// **'Surveyor\'s Office'**
  String get cityBuildingSurveyorsOffice;

  /// No description provided for @cityBuildingPlanningOffice.
  ///
  /// In en, this message translates to:
  /// **'Planning Office'**
  String get cityBuildingPlanningOffice;

  /// No description provided for @cityBuildingApothecary.
  ///
  /// In en, this message translates to:
  /// **'Apothecary'**
  String get cityBuildingApothecary;

  /// No description provided for @cityBuildingPublicBaths.
  ///
  /// In en, this message translates to:
  /// **'Public Baths'**
  String get cityBuildingPublicBaths;

  /// No description provided for @cityBuildingHospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get cityBuildingHospital;

  /// No description provided for @cityBuildingMinistries.
  ///
  /// In en, this message translates to:
  /// **'Ministries'**
  String get cityBuildingMinistries;

  /// No description provided for @cityBuildingWalls.
  ///
  /// In en, this message translates to:
  /// **'Walls'**
  String get cityBuildingWalls;

  /// No description provided for @cityBuildingArmory.
  ///
  /// In en, this message translates to:
  /// **'Armory'**
  String get cityBuildingArmory;

  /// No description provided for @cityBuildingSiegeWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Siege Workshop'**
  String get cityBuildingSiegeWorkshop;

  /// No description provided for @cityBuildingCitadel.
  ///
  /// In en, this message translates to:
  /// **'Citadel'**
  String get cityBuildingCitadel;

  /// No description provided for @cityBuildingWarCollege.
  ///
  /// In en, this message translates to:
  /// **'War College'**
  String get cityBuildingWarCollege;

  /// No description provided for @cityBuildingConscriptionOffice.
  ///
  /// In en, this message translates to:
  /// **'Conscription Office'**
  String get cityBuildingConscriptionOffice;

  /// No description provided for @cityBuildingBorderFort.
  ///
  /// In en, this message translates to:
  /// **'Border Fort'**
  String get cityBuildingBorderFort;

  /// No description provided for @cityBuildingAirfield.
  ///
  /// In en, this message translates to:
  /// **'Airfield'**
  String get cityBuildingAirfield;

  /// No description provided for @cityBuildingArtisansGuild.
  ///
  /// In en, this message translates to:
  /// **'Artisans\' Guild'**
  String get cityBuildingArtisansGuild;

  /// No description provided for @cityBuildingMasterWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Master Workshop'**
  String get cityBuildingMasterWorkshop;

  /// No description provided for @cityBuildingSteelworks.
  ///
  /// In en, this message translates to:
  /// **'Steelworks'**
  String get cityBuildingSteelworks;

  /// No description provided for @cityBuildingRailDepot.
  ///
  /// In en, this message translates to:
  /// **'Rail Depot'**
  String get cityBuildingRailDepot;

  /// No description provided for @cityBuildingPowerPlant.
  ///
  /// In en, this message translates to:
  /// **'Power Plant'**
  String get cityBuildingPowerPlant;

  /// No description provided for @cityBuildingAssemblyPlant.
  ///
  /// In en, this message translates to:
  /// **'Assembly Plant'**
  String get cityBuildingAssemblyPlant;

  /// No description provided for @cityBuildingRefinery.
  ///
  /// In en, this message translates to:
  /// **'Refinery'**
  String get cityBuildingRefinery;

  /// No description provided for @cityBuildingMapRoom.
  ///
  /// In en, this message translates to:
  /// **'Map Room'**
  String get cityBuildingMapRoom;

  /// No description provided for @cityBuildingShipyard.
  ///
  /// In en, this message translates to:
  /// **'Shipyard'**
  String get cityBuildingShipyard;

  /// No description provided for @cityBuildingDryDock.
  ///
  /// In en, this message translates to:
  /// **'Dry Dock'**
  String get cityBuildingDryDock;

  /// No description provided for @cityBuildingNavalAcademy.
  ///
  /// In en, this message translates to:
  /// **'Naval Academy'**
  String get cityBuildingNavalAcademy;

  /// No description provided for @cityBuildingHarborCustoms.
  ///
  /// In en, this message translates to:
  /// **'Harbor Customs'**
  String get cityBuildingHarborCustoms;

  /// No description provided for @cityBuildingMuseum.
  ///
  /// In en, this message translates to:
  /// **'Museum'**
  String get cityBuildingMuseum;

  /// No description provided for @cityBuildingParliament.
  ///
  /// In en, this message translates to:
  /// **'Parliament'**
  String get cityBuildingParliament;

  /// No description provided for @cityBuildingBroadcastTower.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Tower'**
  String get cityBuildingBroadcastTower;

  /// No description provided for @cityBuildingWorldFairGrounds.
  ///
  /// In en, this message translates to:
  /// **'World Fair Grounds'**
  String get cityBuildingWorldFairGrounds;

  /// No description provided for @cityBuildingGranaryDescription.
  ///
  /// In en, this message translates to:
  /// **'An early food building that stabilizes city growth.'**
  String get cityBuildingGranaryDescription;

  /// No description provided for @cityBuildingWaterMillDescription.
  ///
  /// In en, this message translates to:
  /// **'Uses controlled river tiles to increase city food.'**
  String get cityBuildingWaterMillDescription;

  /// No description provided for @cityBuildingWorkshopDescription.
  ///
  /// In en, this message translates to:
  /// **'A basic craft center that raises city production.'**
  String get cityBuildingWorkshopDescription;

  /// No description provided for @cityBuildingStorehouseDescription.
  ///
  /// In en, this message translates to:
  /// **'Improves harvest storage and increases stored food.'**
  String get cityBuildingStorehouseDescription;

  /// No description provided for @cityBuildingHousingDescription.
  ///
  /// In en, this message translates to:
  /// **'Expands living space and lets the city control more tiles.'**
  String get cityBuildingHousingDescription;

  /// No description provided for @cityBuildingMerchantHallDescription.
  ///
  /// In en, this message translates to:
  /// **'Organizes local trade and increases city income.'**
  String get cityBuildingMerchantHallDescription;

  /// No description provided for @cityBuildingStonemasonDescription.
  ///
  /// In en, this message translates to:
  /// **'Strengthens the city construction and defensive base.'**
  String get cityBuildingStonemasonDescription;

  /// No description provided for @cityBuildingBarracksDescription.
  ///
  /// In en, this message translates to:
  /// **'Provides military infrastructure and additional defense.'**
  String get cityBuildingBarracksDescription;

  /// No description provided for @cityBuildingMarketplaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Develops urban trade and greatly increases gold income.'**
  String get cityBuildingMarketplaceDescription;

  /// No description provided for @cityBuildingPortDescription.
  ///
  /// In en, this message translates to:
  /// **'Opens the city to sea trade and coastal food.'**
  String get cityBuildingPortDescription;

  /// No description provided for @cityBuildingAqueductDescription.
  ///
  /// In en, this message translates to:
  /// **'Delivers water, supporting growth and further city expansion.'**
  String get cityBuildingAqueductDescription;

  /// No description provided for @cityBuildingForgeDescription.
  ///
  /// In en, this message translates to:
  /// **'Concentrates metalworking and greatly increases production.'**
  String get cityBuildingForgeDescription;

  /// No description provided for @cityBuildingStableDescription.
  ///
  /// In en, this message translates to:
  /// **'Supports breeding and logistics, adding food and production.'**
  String get cityBuildingStableDescription;

  /// No description provided for @cityBuildingBankDescription.
  ///
  /// In en, this message translates to:
  /// **'Centralizes finance and significantly increases city income.'**
  String get cityBuildingBankDescription;

  /// No description provided for @cityBuildingBuildersGuildDescription.
  ///
  /// In en, this message translates to:
  /// **'Gathers construction specialists, accelerating production and territorial growth.'**
  String get cityBuildingBuildersGuildDescription;

  /// No description provided for @cityBuildingFactoryDescription.
  ///
  /// In en, this message translates to:
  /// **'A later-game industrial building that grants a large production bonus.'**
  String get cityBuildingFactoryDescription;

  /// No description provided for @cityBuildingLighthouseDescription.
  ///
  /// In en, this message translates to:
  /// **'Strengthens the coastal economy through navigation and trade.'**
  String get cityBuildingLighthouseDescription;

  /// No description provided for @cityBuildingTrainingGroundsDescription.
  ///
  /// In en, this message translates to:
  /// **'Develops military training and improves city defense.'**
  String get cityBuildingTrainingGroundsDescription;

  /// No description provided for @cityBuildingTownHallDescription.
  ///
  /// In en, this message translates to:
  /// **'The city administration center, strengthening economy and territorial control.'**
  String get cityBuildingTownHallDescription;

  /// No description provided for @cityBuildingMonumentDescription.
  ///
  /// In en, this message translates to:
  /// **'A symbol of city prestige, providing gold and defense.'**
  String get cityBuildingMonumentDescription;

  /// No description provided for @cityBuildingArchiveDescription.
  ///
  /// In en, this message translates to:
  /// **'The first knowledge building, organizing records and supporting research.'**
  String get cityBuildingArchiveDescription;

  /// No description provided for @cityBuildingAcademyDescription.
  ///
  /// In en, this message translates to:
  /// **'Strengthens science cities and prepares the path to higher education.'**
  String get cityBuildingAcademyDescription;

  /// No description provided for @cityBuildingUniversityDescription.
  ///
  /// In en, this message translates to:
  /// **'A later science building for large, developed cities.'**
  String get cityBuildingUniversityDescription;

  /// No description provided for @cityBuildingObservatoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Links geography with science and supports advanced research.'**
  String get cityBuildingObservatoryDescription;

  /// No description provided for @cityBuildingLaboratoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Support for late technology projects and modern science.'**
  String get cityBuildingLaboratoryDescription;

  /// No description provided for @cityBuildingReactorDescription.
  ///
  /// In en, this message translates to:
  /// **'A powerful endgame building requiring uranium and strong infrastructure.'**
  String get cityBuildingReactorDescription;

  /// No description provided for @cityBuildingCourthouseDescription.
  ///
  /// In en, this message translates to:
  /// **'Stabilizes large or captured cities through legal administration.'**
  String get cityBuildingCourthouseDescription;

  /// No description provided for @cityBuildingCourtDescription.
  ///
  /// In en, this message translates to:
  /// **'Develops law, city policies, and civilian control.'**
  String get cityBuildingCourtDescription;

  /// No description provided for @cityBuildingGovernorsOfficeDescription.
  ///
  /// In en, this message translates to:
  /// **'Strengthens city specialization and territorial management.'**
  String get cityBuildingGovernorsOfficeDescription;

  /// No description provided for @cityBuildingSurveyorsOfficeDescription.
  ///
  /// In en, this message translates to:
  /// **'Eases border planning and increases city control range.'**
  String get cityBuildingSurveyorsOfficeDescription;

  /// No description provided for @cityBuildingPlanningOfficeDescription.
  ///
  /// In en, this message translates to:
  /// **'Develops the city through planning, production, and territorial control.'**
  String get cityBuildingPlanningOfficeDescription;

  /// No description provided for @cityBuildingApothecaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Early city health that helps maintain steady growth.'**
  String get cityBuildingApothecaryDescription;

  /// No description provided for @cityBuildingPublicBathsDescription.
  ///
  /// In en, this message translates to:
  /// **'Improve stability and growth in larger cities.'**
  String get cityBuildingPublicBathsDescription;

  /// No description provided for @cityBuildingHospitalDescription.
  ///
  /// In en, this message translates to:
  /// **'Late population infrastructure for long-term development.'**
  String get cityBuildingHospitalDescription;

  /// No description provided for @cityBuildingMinistriesDescription.
  ///
  /// In en, this message translates to:
  /// **'A limited empire building that strengthens administration and gold.'**
  String get cityBuildingMinistriesDescription;

  /// No description provided for @cityBuildingWallsDescription.
  ///
  /// In en, this message translates to:
  /// **'Early city defense against the first attacks.'**
  String get cityBuildingWallsDescription;

  /// No description provided for @cityBuildingArmoryDescription.
  ///
  /// In en, this message translates to:
  /// **'A better recruitment and equipment center for troops.'**
  String get cityBuildingArmoryDescription;

  /// No description provided for @cityBuildingSiegeWorkshopDescription.
  ///
  /// In en, this message translates to:
  /// **'Produces and maintains the support base for siege engines.'**
  String get cityBuildingSiegeWorkshopDescription;

  /// No description provided for @cityBuildingCitadelDescription.
  ///
  /// In en, this message translates to:
  /// **'Late strategic defense for cities on important borders.'**
  String get cityBuildingCitadelDescription;

  /// No description provided for @cityBuildingWarCollegeDescription.
  ///
  /// In en, this message translates to:
  /// **'A military academy that strengthens army and general coordination.'**
  String get cityBuildingWarCollegeDescription;

  /// No description provided for @cityBuildingConscriptionOfficeDescription.
  ///
  /// In en, this message translates to:
  /// **'Mobilizes the army and speeds preparation of new troops.'**
  String get cityBuildingConscriptionOfficeDescription;

  /// No description provided for @cityBuildingBorderFortDescription.
  ///
  /// In en, this message translates to:
  /// **'Strengthens defense and visibility on empire borders.'**
  String get cityBuildingBorderFortDescription;

  /// No description provided for @cityBuildingAirfieldDescription.
  ///
  /// In en, this message translates to:
  /// **'A military airfield for aviation, reconnaissance, and modern force projection.'**
  String get cityBuildingAirfieldDescription;

  /// No description provided for @cityBuildingArtisansGuildDescription.
  ///
  /// In en, this message translates to:
  /// **'A production stage before the factory, based on crafts and workshops.'**
  String get cityBuildingArtisansGuildDescription;

  /// No description provided for @cityBuildingMasterWorkshopDescription.
  ///
  /// In en, this message translates to:
  /// **'A specialized workshop for production-focused cities.'**
  String get cityBuildingMasterWorkshopDescription;

  /// No description provided for @cityBuildingSteelworksDescription.
  ///
  /// In en, this message translates to:
  /// **'Heavy industry based on iron or coal.'**
  String get cityBuildingSteelworksDescription;

  /// No description provided for @cityBuildingRailDepotDescription.
  ///
  /// In en, this message translates to:
  /// **'A rail depot improving logistics and mobility between cities.'**
  String get cityBuildingRailDepotDescription;

  /// No description provided for @cityBuildingPowerPlantDescription.
  ///
  /// In en, this message translates to:
  /// **'Late energy infrastructure for strong industrial production.'**
  String get cityBuildingPowerPlantDescription;

  /// No description provided for @cityBuildingAssemblyPlantDescription.
  ///
  /// In en, this message translates to:
  /// **'An endgame industrial building for mass production.'**
  String get cityBuildingAssemblyPlantDescription;

  /// No description provided for @cityBuildingRefineryDescription.
  ///
  /// In en, this message translates to:
  /// **'Processes oil for modern armies and late projects.'**
  String get cityBuildingRefineryDescription;

  /// No description provided for @cityBuildingMapRoomDescription.
  ///
  /// In en, this message translates to:
  /// **'Supports exploration, visibility, and expedition planning.'**
  String get cityBuildingMapRoomDescription;

  /// No description provided for @cityBuildingShipyardDescription.
  ///
  /// In en, this message translates to:
  /// **'Develops fleets and production in port cities.'**
  String get cityBuildingShipyardDescription;

  /// No description provided for @cityBuildingDryDockDescription.
  ///
  /// In en, this message translates to:
  /// **'A late naval port for larger warships.'**
  String get cityBuildingDryDockDescription;

  /// No description provided for @cityBuildingNavalAcademyDescription.
  ///
  /// In en, this message translates to:
  /// **'A naval military academy for specialized ports.'**
  String get cityBuildingNavalAcademyDescription;

  /// No description provided for @cityBuildingHarborCustomsDescription.
  ///
  /// In en, this message translates to:
  /// **'A port office strengthening trade and coastal control.'**
  String get cityBuildingHarborCustomsDescription;

  /// No description provided for @cityBuildingMuseumDescription.
  ///
  /// In en, this message translates to:
  /// **'A prestigious empire building that strengthens city influence.'**
  String get cityBuildingMuseumDescription;

  /// No description provided for @cityBuildingParliamentDescription.
  ///
  /// In en, this message translates to:
  /// **'A limited civic building for a mature state.'**
  String get cityBuildingParliamentDescription;

  /// No description provided for @cityBuildingBroadcastTowerDescription.
  ///
  /// In en, this message translates to:
  /// **'Strengthens empire influence, visibility, and communication.'**
  String get cityBuildingBroadcastTowerDescription;

  /// No description provided for @cityBuildingWorldFairGroundsDescription.
  ///
  /// In en, this message translates to:
  /// **'A peaceful prestige project for a rich, developed city.'**
  String get cityBuildingWorldFairGroundsDescription;

  /// No description provided for @unitCommander.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get unitCommander;

  /// No description provided for @unitWarrior.
  ///
  /// In en, this message translates to:
  /// **'Warrior'**
  String get unitWarrior;

  /// No description provided for @unitArcher.
  ///
  /// In en, this message translates to:
  /// **'Archer'**
  String get unitArcher;

  /// No description provided for @unitSettler.
  ///
  /// In en, this message translates to:
  /// **'Settler'**
  String get unitSettler;

  /// No description provided for @unitWorker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get unitWorker;

  /// No description provided for @unitMerchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get unitMerchant;

  /// No description provided for @unitScout.
  ///
  /// In en, this message translates to:
  /// **'Scout'**
  String get unitScout;

  /// No description provided for @unitSpearman.
  ///
  /// In en, this message translates to:
  /// **'Spearman'**
  String get unitSpearman;

  /// No description provided for @unitCavalry.
  ///
  /// In en, this message translates to:
  /// **'Cavalry'**
  String get unitCavalry;

  /// No description provided for @unitCatapult.
  ///
  /// In en, this message translates to:
  /// **'Catapult'**
  String get unitCatapult;

  /// No description provided for @unitHeavyInfantry.
  ///
  /// In en, this message translates to:
  /// **'Heavy Infantry'**
  String get unitHeavyInfantry;

  /// No description provided for @unitFieldCannon.
  ///
  /// In en, this message translates to:
  /// **'Field Cannon'**
  String get unitFieldCannon;

  /// No description provided for @unitRifleman.
  ///
  /// In en, this message translates to:
  /// **'Rifleman'**
  String get unitRifleman;

  /// No description provided for @unitTank.
  ///
  /// In en, this message translates to:
  /// **'Tank'**
  String get unitTank;

  /// No description provided for @unitScoutShip.
  ///
  /// In en, this message translates to:
  /// **'Scout Ship'**
  String get unitScoutShip;

  /// No description provided for @unitWarship.
  ///
  /// In en, this message translates to:
  /// **'Warship'**
  String get unitWarship;

  /// No description provided for @unitReconPlane.
  ///
  /// In en, this message translates to:
  /// **'Recon Plane'**
  String get unitReconPlane;

  /// No description provided for @unitCommanderDescription.
  ///
  /// In en, this message translates to:
  /// **'A general commands an army, leads reconnaissance, and can act faster than regular troops.'**
  String get unitCommanderDescription;

  /// No description provided for @unitWarriorDescription.
  ///
  /// In en, this message translates to:
  /// **'A basic combat unit for city defense and melee fighting.'**
  String get unitWarriorDescription;

  /// No description provided for @unitArcherDescription.
  ///
  /// In en, this message translates to:
  /// **'A ranged unit that attacks from farther away but defends poorly in melee.'**
  String get unitArcherDescription;

  /// No description provided for @unitSettlerDescription.
  ///
  /// In en, this message translates to:
  /// **'Founds new cities and expands the empire, but needs protection on the road.'**
  String get unitSettlerDescription;

  /// No description provided for @unitWorkerDescription.
  ///
  /// In en, this message translates to:
  /// **'Improves tiles around cities, increasing food, production, and gold.'**
  String get unitWorkerDescription;

  /// No description provided for @unitMerchantDescription.
  ///
  /// In en, this message translates to:
  /// **'Travels automatically between your cities along a trade route and can enter occupied friendly city centers.'**
  String get unitMerchantDescription;

  /// No description provided for @unitScoutDescription.
  ///
  /// In en, this message translates to:
  /// **'A fast reconnaissance unit for exploring the map and detecting threats.'**
  String get unitScoutDescription;

  /// No description provided for @unitSpearmanDescription.
  ///
  /// In en, this message translates to:
  /// **'Early defensive infantry, good for covering cities and stopping charges.'**
  String get unitSpearmanDescription;

  /// No description provided for @unitCavalryDescription.
  ///
  /// In en, this message translates to:
  /// **'A mobile strike unit that quickly responds to weak points on the front.'**
  String get unitCavalryDescription;

  /// No description provided for @unitCatapultDescription.
  ///
  /// In en, this message translates to:
  /// **'A siege engine with longer range, effective against fortifications.'**
  String get unitCatapultDescription;

  /// No description provided for @unitHeavyInfantryDescription.
  ///
  /// In en, this message translates to:
  /// **'Durable frontline infantry with high defense and solid attack.'**
  String get unitHeavyInfantryDescription;

  /// No description provided for @unitFieldCannonDescription.
  ///
  /// In en, this message translates to:
  /// **'Modern field artillery for ranged bombardment.'**
  String get unitFieldCannonDescription;

  /// No description provided for @unitRiflemanDescription.
  ///
  /// In en, this message translates to:
  /// **'A modern ranged soldier, steady in attack and defense.'**
  String get unitRiflemanDescription;

  /// No description provided for @unitTankDescription.
  ///
  /// In en, this message translates to:
  /// **'A heavy armored unit with high strength and high mobility.'**
  String get unitTankDescription;

  /// No description provided for @unitScoutShipDescription.
  ///
  /// In en, this message translates to:
  /// **'A light ship for coastal reconnaissance and protecting early sea routes.'**
  String get unitScoutShipDescription;

  /// No description provided for @unitWarshipDescription.
  ///
  /// In en, this message translates to:
  /// **'A strong combat ship for sea control and ranged bombardment.'**
  String get unitWarshipDescription;

  /// No description provided for @unitReconPlaneDescription.
  ///
  /// In en, this message translates to:
  /// **'A reconnaissance aircraft with long vision range and very high mobility.'**
  String get unitReconPlaneDescription;

  /// No description provided for @unitRankRecruit.
  ///
  /// In en, this message translates to:
  /// **'Recruit'**
  String get unitRankRecruit;

  /// No description provided for @unitRankSeasoned.
  ///
  /// In en, this message translates to:
  /// **'Seasoned'**
  String get unitRankSeasoned;

  /// No description provided for @unitRankVeteran.
  ///
  /// In en, this message translates to:
  /// **'Veteran'**
  String get unitRankVeteran;

  /// No description provided for @unitRankElite.
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get unitRankElite;

  /// No description provided for @troopWarrior.
  ///
  /// In en, this message translates to:
  /// **'Warriors'**
  String get troopWarrior;

  /// No description provided for @troopArcher.
  ///
  /// In en, this message translates to:
  /// **'Archers'**
  String get troopArcher;

  /// No description provided for @troopSettler.
  ///
  /// In en, this message translates to:
  /// **'Settlers'**
  String get troopSettler;

  /// No description provided for @fieldImprovementFarm.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get fieldImprovementFarm;

  /// No description provided for @fieldImprovementRiverFarm.
  ///
  /// In en, this message translates to:
  /// **'River Farm'**
  String get fieldImprovementRiverFarm;

  /// No description provided for @fieldImprovementMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get fieldImprovementMine;

  /// No description provided for @fieldImprovementLumberMill.
  ///
  /// In en, this message translates to:
  /// **'Lumber Mill'**
  String get fieldImprovementLumberMill;

  /// No description provided for @fieldImprovementPasture.
  ///
  /// In en, this message translates to:
  /// **'Pasture'**
  String get fieldImprovementPasture;

  /// No description provided for @fieldImprovementCamp.
  ///
  /// In en, this message translates to:
  /// **'Camp'**
  String get fieldImprovementCamp;

  /// No description provided for @fieldImprovementQuarry.
  ///
  /// In en, this message translates to:
  /// **'Quarry'**
  String get fieldImprovementQuarry;

  /// No description provided for @fieldImprovementFishingBoats.
  ///
  /// In en, this message translates to:
  /// **'Fishing Boats'**
  String get fieldImprovementFishingBoats;

  /// No description provided for @fieldImprovementOrchard.
  ///
  /// In en, this message translates to:
  /// **'Orchard'**
  String get fieldImprovementOrchard;

  /// No description provided for @fieldImprovementPlantation.
  ///
  /// In en, this message translates to:
  /// **'Plantation'**
  String get fieldImprovementPlantation;

  /// No description provided for @fieldImprovementVineyard.
  ///
  /// In en, this message translates to:
  /// **'Vineyard'**
  String get fieldImprovementVineyard;

  /// No description provided for @fieldImprovementTradingPost.
  ///
  /// In en, this message translates to:
  /// **'Trading Post'**
  String get fieldImprovementTradingPost;

  /// No description provided for @fieldImprovementProspectorCamp.
  ///
  /// In en, this message translates to:
  /// **'Prospector Camp'**
  String get fieldImprovementProspectorCamp;

  /// No description provided for @fieldImprovementHorseRanch.
  ///
  /// In en, this message translates to:
  /// **'Horse Ranch'**
  String get fieldImprovementHorseRanch;

  /// No description provided for @fieldImprovementPearlDivers.
  ///
  /// In en, this message translates to:
  /// **'Pearl Divers'**
  String get fieldImprovementPearlDivers;

  /// No description provided for @fieldImprovementCoalShaft.
  ///
  /// In en, this message translates to:
  /// **'Coal Shaft'**
  String get fieldImprovementCoalShaft;

  /// No description provided for @fieldImprovementOilWell.
  ///
  /// In en, this message translates to:
  /// **'Oil Well'**
  String get fieldImprovementOilWell;

  /// No description provided for @fieldImprovementBauxiteMine.
  ///
  /// In en, this message translates to:
  /// **'Bauxite Mine'**
  String get fieldImprovementBauxiteMine;

  /// No description provided for @fieldImprovementUraniumMine.
  ///
  /// In en, this message translates to:
  /// **'Uranium Mine'**
  String get fieldImprovementUraniumMine;

  /// No description provided for @resourceWheat.
  ///
  /// In en, this message translates to:
  /// **'wheat'**
  String get resourceWheat;

  /// No description provided for @resourceFish.
  ///
  /// In en, this message translates to:
  /// **'fish'**
  String get resourceFish;

  /// No description provided for @resourceDeer.
  ///
  /// In en, this message translates to:
  /// **'deer'**
  String get resourceDeer;

  /// No description provided for @resourceSheep.
  ///
  /// In en, this message translates to:
  /// **'sheep'**
  String get resourceSheep;

  /// No description provided for @resourceRice.
  ///
  /// In en, this message translates to:
  /// **'rice'**
  String get resourceRice;

  /// No description provided for @resourceCow.
  ///
  /// In en, this message translates to:
  /// **'cattle'**
  String get resourceCow;

  /// No description provided for @resourceApple.
  ///
  /// In en, this message translates to:
  /// **'apples'**
  String get resourceApple;

  /// No description provided for @resourceBanana.
  ///
  /// In en, this message translates to:
  /// **'bananas'**
  String get resourceBanana;

  /// No description provided for @resourceCitrus.
  ///
  /// In en, this message translates to:
  /// **'citrus'**
  String get resourceCitrus;

  /// No description provided for @resourceGold.
  ///
  /// In en, this message translates to:
  /// **'gold'**
  String get resourceGold;

  /// No description provided for @resourceSilver.
  ///
  /// In en, this message translates to:
  /// **'silver'**
  String get resourceSilver;

  /// No description provided for @resourceGems.
  ///
  /// In en, this message translates to:
  /// **'gems'**
  String get resourceGems;

  /// No description provided for @resourceSilk.
  ///
  /// In en, this message translates to:
  /// **'silk'**
  String get resourceSilk;

  /// No description provided for @resourceSpices.
  ///
  /// In en, this message translates to:
  /// **'spices'**
  String get resourceSpices;

  /// No description provided for @resourceCotton.
  ///
  /// In en, this message translates to:
  /// **'cotton'**
  String get resourceCotton;

  /// No description provided for @resourceGrapes.
  ///
  /// In en, this message translates to:
  /// **'grapes'**
  String get resourceGrapes;

  /// No description provided for @resourceIvory.
  ///
  /// In en, this message translates to:
  /// **'ivory'**
  String get resourceIvory;

  /// No description provided for @resourcePearls.
  ///
  /// In en, this message translates to:
  /// **'pearls'**
  String get resourcePearls;

  /// No description provided for @resourceCoffee.
  ///
  /// In en, this message translates to:
  /// **'coffee'**
  String get resourceCoffee;

  /// No description provided for @resourceCocoa.
  ///
  /// In en, this message translates to:
  /// **'cocoa'**
  String get resourceCocoa;

  /// No description provided for @resourceTobacco.
  ///
  /// In en, this message translates to:
  /// **'tobacco'**
  String get resourceTobacco;

  /// No description provided for @resourceSugar.
  ///
  /// In en, this message translates to:
  /// **'sugar'**
  String get resourceSugar;

  /// No description provided for @resourceIron.
  ///
  /// In en, this message translates to:
  /// **'iron'**
  String get resourceIron;

  /// No description provided for @resourceCoal.
  ///
  /// In en, this message translates to:
  /// **'coal'**
  String get resourceCoal;

  /// No description provided for @resourceOil.
  ///
  /// In en, this message translates to:
  /// **'oil'**
  String get resourceOil;

  /// No description provided for @resourceAluminium.
  ///
  /// In en, this message translates to:
  /// **'aluminum'**
  String get resourceAluminium;

  /// No description provided for @resourceUranium.
  ///
  /// In en, this message translates to:
  /// **'uranium'**
  String get resourceUranium;

  /// No description provided for @resourceHorses.
  ///
  /// In en, this message translates to:
  /// **'horses'**
  String get resourceHorses;

  /// No description provided for @resourceMarble.
  ///
  /// In en, this message translates to:
  /// **'marble'**
  String get resourceMarble;

  /// No description provided for @technologyAgriculture.
  ///
  /// In en, this message translates to:
  /// **'Agriculture'**
  String get technologyAgriculture;

  /// No description provided for @technologyWoodworking.
  ///
  /// In en, this message translates to:
  /// **'Woodworking'**
  String get technologyWoodworking;

  /// No description provided for @technologyMining.
  ///
  /// In en, this message translates to:
  /// **'Mining'**
  String get technologyMining;

  /// No description provided for @technologyAnimalHusbandry.
  ///
  /// In en, this message translates to:
  /// **'Animal Husbandry'**
  String get technologyAnimalHusbandry;

  /// No description provided for @technologyHunting.
  ///
  /// In en, this message translates to:
  /// **'Hunting'**
  String get technologyHunting;

  /// No description provided for @technologyFishing.
  ///
  /// In en, this message translates to:
  /// **'Fishing'**
  String get technologyFishing;

  /// No description provided for @technologyCraftsmanship.
  ///
  /// In en, this message translates to:
  /// **'Craftsmanship'**
  String get technologyCraftsmanship;

  /// No description provided for @technologyTrade.
  ///
  /// In en, this message translates to:
  /// **'Trade'**
  String get technologyTrade;

  /// No description provided for @technologyStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get technologyStorage;

  /// No description provided for @technologyWaterEngineering.
  ///
  /// In en, this message translates to:
  /// **'Water Engineering'**
  String get technologyWaterEngineering;

  /// No description provided for @technologyStoneworking.
  ///
  /// In en, this message translates to:
  /// **'Stoneworking'**
  String get technologyStoneworking;

  /// No description provided for @technologyMilitaryOrganization.
  ///
  /// In en, this message translates to:
  /// **'Military Organization'**
  String get technologyMilitaryOrganization;

  /// No description provided for @technologyAdvancedTrade.
  ///
  /// In en, this message translates to:
  /// **'Advanced Trade'**
  String get technologyAdvancedTrade;

  /// No description provided for @technologyConstruction.
  ///
  /// In en, this message translates to:
  /// **'Construction'**
  String get technologyConstruction;

  /// No description provided for @technologyNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get technologyNavigation;

  /// No description provided for @technologyIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Irrigation'**
  String get technologyIrrigation;

  /// No description provided for @technologyBanking.
  ///
  /// In en, this message translates to:
  /// **'Banking'**
  String get technologyBanking;

  /// No description provided for @technologyEngineering.
  ///
  /// In en, this message translates to:
  /// **'Engineering'**
  String get technologyEngineering;

  /// No description provided for @technologyMetallurgy.
  ///
  /// In en, this message translates to:
  /// **'Metallurgy'**
  String get technologyMetallurgy;

  /// No description provided for @technologyHorsebackRiding.
  ///
  /// In en, this message translates to:
  /// **'Horseback Riding'**
  String get technologyHorsebackRiding;

  /// No description provided for @technologyIronWorking.
  ///
  /// In en, this message translates to:
  /// **'Iron Working'**
  String get technologyIronWorking;

  /// No description provided for @technologyCoalMining.
  ///
  /// In en, this message translates to:
  /// **'Coal Mining'**
  String get technologyCoalMining;

  /// No description provided for @technologyMachinery.
  ///
  /// In en, this message translates to:
  /// **'Machinery'**
  String get technologyMachinery;

  /// No description provided for @technologyAdministration.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get technologyAdministration;

  /// No description provided for @technologyLogistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get technologyLogistics;

  /// No description provided for @technologyShipbuilding.
  ///
  /// In en, this message translates to:
  /// **'Shipbuilding'**
  String get technologyShipbuilding;

  /// No description provided for @technologyTactics.
  ///
  /// In en, this message translates to:
  /// **'Tactics'**
  String get technologyTactics;

  /// No description provided for @technologyEconomy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get technologyEconomy;

  /// No description provided for @technologyUrbanization.
  ///
  /// In en, this message translates to:
  /// **'Urbanization'**
  String get technologyUrbanization;

  /// No description provided for @technologyFortifications.
  ///
  /// In en, this message translates to:
  /// **'Fortifications'**
  String get technologyFortifications;

  /// No description provided for @technologyStrategy.
  ///
  /// In en, this message translates to:
  /// **'Strategy'**
  String get technologyStrategy;

  /// No description provided for @technologySpecialization.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get technologySpecialization;

  /// No description provided for @technologyWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get technologyWriting;

  /// No description provided for @technologyMathematics.
  ///
  /// In en, this message translates to:
  /// **'Mathematics'**
  String get technologyMathematics;

  /// No description provided for @technologyMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get technologyMedicine;

  /// No description provided for @technologyCivilService.
  ///
  /// In en, this message translates to:
  /// **'Civil Service'**
  String get technologyCivilService;

  /// No description provided for @technologySiegecraft.
  ///
  /// In en, this message translates to:
  /// **'Siegecraft'**
  String get technologySiegecraft;

  /// No description provided for @technologyCartography.
  ///
  /// In en, this message translates to:
  /// **'Cartography'**
  String get technologyCartography;

  /// No description provided for @technologyGuilds.
  ///
  /// In en, this message translates to:
  /// **'Guilds'**
  String get technologyGuilds;

  /// No description provided for @technologyLaw.
  ///
  /// In en, this message translates to:
  /// **'Law'**
  String get technologyLaw;

  /// No description provided for @technologyEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get technologyEducation;

  /// No description provided for @technologyUrbanPlanning.
  ///
  /// In en, this message translates to:
  /// **'Urban Planning'**
  String get technologyUrbanPlanning;

  /// No description provided for @technologyNavalDoctrine.
  ///
  /// In en, this message translates to:
  /// **'Naval Doctrine'**
  String get technologyNavalDoctrine;

  /// No description provided for @technologySteel.
  ///
  /// In en, this message translates to:
  /// **'Steel'**
  String get technologySteel;

  /// No description provided for @technologyBureaucracy.
  ///
  /// In en, this message translates to:
  /// **'Bureaucracy'**
  String get technologyBureaucracy;

  /// No description provided for @technologyNationalism.
  ///
  /// In en, this message translates to:
  /// **'Nationalism'**
  String get technologyNationalism;

  /// No description provided for @technologyScientificMethod.
  ///
  /// In en, this message translates to:
  /// **'Scientific Method'**
  String get technologyScientificMethod;

  /// No description provided for @technologySteamPower.
  ///
  /// In en, this message translates to:
  /// **'Steam Power'**
  String get technologySteamPower;

  /// No description provided for @technologyElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get technologyElectricity;

  /// No description provided for @technologyCombustion.
  ///
  /// In en, this message translates to:
  /// **'Combustion'**
  String get technologyCombustion;

  /// No description provided for @technologyFlight.
  ///
  /// In en, this message translates to:
  /// **'Flight'**
  String get technologyFlight;

  /// No description provided for @technologyMassProduction.
  ///
  /// In en, this message translates to:
  /// **'Mass Production'**
  String get technologyMassProduction;

  /// No description provided for @technologyRadio.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get technologyRadio;

  /// No description provided for @technologyNuclearPhysics.
  ///
  /// In en, this message translates to:
  /// **'Nuclear Physics'**
  String get technologyNuclearPhysics;

  /// No description provided for @technologyAgricultureDescription.
  ///
  /// In en, this message translates to:
  /// **'Opens the basic growth path. Farms and river farms let population grow faster and stabilize the first city.'**
  String get technologyAgricultureDescription;

  /// No description provided for @technologyWoodworkingDescription.
  ///
  /// In en, this message translates to:
  /// **'Develops the production side of mining. Lumber mills turn forests into production without going deep into metallurgy.'**
  String get technologyWoodworkingDescription;

  /// No description provided for @technologyMiningDescription.
  ///
  /// In en, this message translates to:
  /// **'Opens the path of industry and infrastructure. Mines are the first major jump in city production.'**
  String get technologyMiningDescription;

  /// No description provided for @technologyAnimalHusbandryDescription.
  ///
  /// In en, this message translates to:
  /// **'Strengthens growth through animal resources. Pastures build a food economy and prepare the way to horseback riding.'**
  String get technologyAnimalHusbandryDescription;

  /// No description provided for @technologyHuntingDescription.
  ///
  /// In en, this message translates to:
  /// **'Opens the military and exploration branch. Provides camps and the first ranged unit for city production.'**
  String get technologyHuntingDescription;

  /// No description provided for @technologyFishingDescription.
  ///
  /// In en, this message translates to:
  /// **'Develops cities near water. Fishing boats help coastal cities grow faster and prepare the way to the port.'**
  String get technologyFishingDescription;

  /// No description provided for @technologyCraftsmanshipDescription.
  ///
  /// In en, this message translates to:
  /// **'The first city production upgrade. The workshop keeps later buildings and units from blocking the queue too long.'**
  String get technologyCraftsmanshipDescription;

  /// No description provided for @technologyTradeDescription.
  ///
  /// In en, this message translates to:
  /// **'The first step in the gold economy. The merchant hall gives a city a simple financial payoff after choosing a growth branch.'**
  String get technologyTradeDescription;

  /// No description provided for @technologyStorageDescription.
  ///
  /// In en, this message translates to:
  /// **'Stabilizes city growth. Storage helps maintain food pace and reduces the risk of development stalls.'**
  String get technologyStorageDescription;

  /// No description provided for @technologyWaterEngineeringDescription.
  ///
  /// In en, this message translates to:
  /// **'Expands the water growth path. The water mill rewards cities that control rivers.'**
  String get technologyWaterEngineeringDescription;

  /// No description provided for @technologyStoneworkingDescription.
  ///
  /// In en, this message translates to:
  /// **'Combines production and defense. Quarries and the stonemason strengthen cities in the infrastructure branch.'**
  String get technologyStoneworkingDescription;

  /// No description provided for @technologyMilitaryOrganizationDescription.
  ///
  /// In en, this message translates to:
  /// **'Builds the first military core of a city. Barracks strengthen production and defense before later army bonuses appear.'**
  String get technologyMilitaryOrganizationDescription;

  /// No description provided for @technologyAdvancedTradeDescription.
  ///
  /// In en, this message translates to:
  /// **'Develops the economy after trade. The marketplace is a stronger gold building and prepares the path to banking.'**
  String get technologyAdvancedTradeDescription;

  /// No description provided for @technologyConstructionDescription.
  ///
  /// In en, this message translates to:
  /// **'Expands territory and city maturity. Housing increases tile control and leads to administration and engineering.'**
  String get technologyConstructionDescription;

  /// No description provided for @technologyNavigationDescription.
  ///
  /// In en, this message translates to:
  /// **'Opens a city payoff for the coast. The port requires coast/ocean access and rewards waterfront cities with food and gold.'**
  String get technologyNavigationDescription;

  /// No description provided for @technologyIrrigationDescription.
  ///
  /// In en, this message translates to:
  /// **'Specializes water-based growth. The aqueduct grants a strong food bonus and additional territorial control.'**
  String get technologyIrrigationDescription;

  /// No description provided for @technologyBankingDescription.
  ///
  /// In en, this message translates to:
  /// **'Specializes the trade branch. The bank turns earlier markets into strong city income and unlocks the wider economy.'**
  String get technologyBankingDescription;

  /// No description provided for @technologyEngineeringDescription.
  ///
  /// In en, this message translates to:
  /// **'Construction specialization. The builders guild speeds production and increases the controlled tile limit.'**
  String get technologyEngineeringDescription;

  /// No description provided for @technologyMetallurgyDescription.
  ///
  /// In en, this message translates to:
  /// **'A strong industrial payoff after stoneworking. The forge raises production and prepares the path to iron and coal.'**
  String get technologyMetallurgyDescription;

  /// No description provided for @technologyHorsebackRidingDescription.
  ///
  /// In en, this message translates to:
  /// **'A technology linking growth and war. The stable supports cities that invested earlier in animals and hunting.'**
  String get technologyHorsebackRidingDescription;

  /// No description provided for @technologyIronWorkingDescription.
  ///
  /// In en, this message translates to:
  /// **'An industrial resource effect. Each controlled iron resource increases city production.'**
  String get technologyIronWorkingDescription;

  /// No description provided for @technologyCoalMiningDescription.
  ///
  /// In en, this message translates to:
  /// **'A later industrial resource effect. Controlled coal increases city production and supports the factory path.'**
  String get technologyCoalMiningDescription;

  /// No description provided for @technologyMachineryDescription.
  ///
  /// In en, this message translates to:
  /// **'A late infrastructure payoff. The factory gives a large production increase to cities that entered engineering.'**
  String get technologyMachineryDescription;

  /// No description provided for @technologyAdministrationDescription.
  ///
  /// In en, this message translates to:
  /// **'Links infrastructure with economy. Town halls and monuments strengthen mature cities and lead to urbanization.'**
  String get technologyAdministrationDescription;

  /// No description provided for @technologyLogisticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Speeds unit production. This is the main technology for players who want to field armies from cities more often.'**
  String get technologyLogisticsDescription;

  /// No description provided for @technologyShipbuildingDescription.
  ///
  /// In en, this message translates to:
  /// **'Develops the coastal/exploration subbranch. The lighthouse requires coast access and strengthens waterfront cities.'**
  String get technologyShipbuildingDescription;

  /// No description provided for @technologyTacticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Military city specialization. Training grounds add defense and production for military centers.'**
  String get technologyTacticsDescription;

  /// No description provided for @technologyEconomyDescription.
  ///
  /// In en, this message translates to:
  /// **'A systemic payoff for banking. Increases gold generated by city economies.'**
  String get technologyEconomyDescription;

  /// No description provided for @technologyUrbanizationDescription.
  ///
  /// In en, this message translates to:
  /// **'The final direction for large-city growth. Increases the population limit once the population system starts using hard caps.'**
  String get technologyUrbanizationDescription;

  /// No description provided for @technologyFortificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Strengthens city defense. Grants a defensive bonus to the city economy, with its full meaning growing after combat and siege expansion.'**
  String get technologyFortificationsDescription;

  /// No description provided for @technologyStrategyDescription.
  ///
  /// In en, this message translates to:
  /// **'The final military direction. Strengthens army effectiveness as a late-game payoff after logistics.'**
  String get technologyStrategyDescription;

  /// No description provided for @technologySpecializationDescription.
  ///
  /// In en, this message translates to:
  /// **'The final civic/economy payoff. Unlocks city specializations, adds city science, and helps finish late technologies in longer matches.'**
  String get technologySpecializationDescription;

  /// No description provided for @technologyWritingDescription.
  ///
  /// In en, this message translates to:
  /// **'The first step toward science, law, and administration. The archive gives a city a permanent research base.'**
  String get technologyWritingDescription;

  /// No description provided for @technologyMathematicsDescription.
  ///
  /// In en, this message translates to:
  /// **'Connects science with territorial planning. The surveyor office helps cities control borders more effectively.'**
  String get technologyMathematicsDescription;

  /// No description provided for @technologyMedicineDescription.
  ///
  /// In en, this message translates to:
  /// **'Develops health and long-term growth in large cities through apothecaries, baths, and hospitals.'**
  String get technologyMedicineDescription;

  /// No description provided for @technologyCivilServiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Improves management of a large empire and unlocks courts that stabilize cities.'**
  String get technologyCivilServiceDescription;

  /// No description provided for @technologySiegecraftDescription.
  ///
  /// In en, this message translates to:
  /// **'Opens siege warfare. Catapults and siege workshops break fortress cities.'**
  String get technologySiegecraftDescription;

  /// No description provided for @technologyCartographyDescription.
  ///
  /// In en, this message translates to:
  /// **'Develops exploration, maps, and the coast. Grants the map room and the first scout ships.'**
  String get technologyCartographyDescription;

  /// No description provided for @technologyGuildsDescription.
  ///
  /// In en, this message translates to:
  /// **'Gives production cities a stage between the workshop and industry.'**
  String get technologyGuildsDescription;

  /// No description provided for @technologyLawDescription.
  ///
  /// In en, this message translates to:
  /// **'Introduces order, policies, and civilian governance through courts.'**
  String get technologyLawDescription;

  /// No description provided for @technologyEducationDescription.
  ///
  /// In en, this message translates to:
  /// **'Builds the full science path for cities through academies and universities.'**
  String get technologyEducationDescription;

  /// No description provided for @technologyUrbanPlanningDescription.
  ///
  /// In en, this message translates to:
  /// **'Develops great cities and territorial control through spatial planning.'**
  String get technologyUrbanPlanningDescription;

  /// No description provided for @technologyNavalDoctrineDescription.
  ///
  /// In en, this message translates to:
  /// **'Turns ports into centers of fleets, shipyards, and force projection at sea.'**
  String get technologyNavalDoctrineDescription;

  /// No description provided for @technologySteelDescription.
  ///
  /// In en, this message translates to:
  /// **'Introduces heavy industry and heavy infantry for the later front.'**
  String get technologySteelDescription;

  /// No description provided for @technologyBureaucracyDescription.
  ///
  /// In en, this message translates to:
  /// **'Provides a major civic goal after administration: offices, ministries, museums, and parliament.'**
  String get technologyBureaucracyDescription;

  /// No description provided for @technologyNationalismDescription.
  ///
  /// In en, this message translates to:
  /// **'Combines border defense, mobilization, and empire identity.'**
  String get technologyNationalismDescription;

  /// No description provided for @technologyScientificMethodDescription.
  ///
  /// In en, this message translates to:
  /// **'Prepares late science, laboratories, observatories, and technology projects.'**
  String get technologyScientificMethodDescription;

  /// No description provided for @technologySteamPowerDescription.
  ///
  /// In en, this message translates to:
  /// **'Opens rail, heavier logistics, and steam industry.'**
  String get technologySteamPowerDescription;

  /// No description provided for @technologyElectricityDescription.
  ///
  /// In en, this message translates to:
  /// **'Introduces power, infrastructure, and information reach.'**
  String get technologyElectricityDescription;

  /// No description provided for @technologyCombustionDescription.
  ///
  /// In en, this message translates to:
  /// **'Gives oil importance and unlocks modern frontline units.'**
  String get technologyCombustionDescription;

  /// No description provided for @technologyFlightDescription.
  ///
  /// In en, this message translates to:
  /// **'Introduces aviation, reconnaissance, and force projection over the front.'**
  String get technologyFlightDescription;

  /// No description provided for @technologyMassProductionDescription.
  ///
  /// In en, this message translates to:
  /// **'Develops final industrial production, tanks, and assembly plants.'**
  String get technologyMassProductionDescription;

  /// No description provided for @technologyRadioDescription.
  ///
  /// In en, this message translates to:
  /// **'Strengthens empire communication, visibility, and influence through broadcast towers.'**
  String get technologyRadioDescription;

  /// No description provided for @technologyNuclearPhysicsDescription.
  ///
  /// In en, this message translates to:
  /// **'Opens the reactor, uranium, and late endgame projects.'**
  String get technologyNuclearPhysicsDescription;

  /// No description provided for @technologyEraFoundation.
  ///
  /// In en, this message translates to:
  /// **'Foundation'**
  String get technologyEraFoundation;

  /// No description provided for @technologyEraSettlement.
  ///
  /// In en, this message translates to:
  /// **'Settlement'**
  String get technologyEraSettlement;

  /// No description provided for @technologyEraExpansion.
  ///
  /// In en, this message translates to:
  /// **'Expansion'**
  String get technologyEraExpansion;

  /// No description provided for @technologyEraSpecialization.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get technologyEraSpecialization;

  /// No description provided for @technologyEraIndustry.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get technologyEraIndustry;

  /// No description provided for @technologyEraStrategy.
  ///
  /// In en, this message translates to:
  /// **'Strategy'**
  String get technologyEraStrategy;

  /// No description provided for @technologyUnlockEffect.
  ///
  /// In en, this message translates to:
  /// **'Effect'**
  String get technologyUnlockEffect;

  /// No description provided for @technologyPrerequisitesNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get technologyPrerequisitesNone;

  /// No description provided for @technologyStateCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get technologyStateCompleted;

  /// No description provided for @technologyStateInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get technologyStateInProgress;

  /// No description provided for @technologyStateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get technologyStateAvailable;

  /// No description provided for @technologyButtonResearched.
  ///
  /// In en, this message translates to:
  /// **'RESEARCHED'**
  String get technologyButtonResearched;

  /// No description provided for @technologyButtonActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get technologyButtonActive;

  /// No description provided for @technologyButtonResearch.
  ///
  /// In en, this message translates to:
  /// **'RESEARCH'**
  String get technologyButtonResearch;

  /// No description provided for @technologyButtonLocked.
  ///
  /// In en, this message translates to:
  /// **'LOCKED'**
  String get technologyButtonLocked;

  /// No description provided for @technologyTreeTitle.
  ///
  /// In en, this message translates to:
  /// **'TECHNOLOGY TREE'**
  String get technologyTreeTitle;

  /// No description provided for @technologyTreeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No technologies to display'**
  String get technologyTreeEmptyTitle;

  /// No description provided for @technologyTreeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'The research tree will appear here when the ruleset provides technologies for this era.'**
  String get technologyTreeEmptyBody;

  /// No description provided for @technologyResearchPointsShort.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String technologyResearchPointsShort(int points);

  /// No description provided for @technologyDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Technology details'**
  String get technologyDetailsTooltip;

  /// No description provided for @technologyDetailsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get technologyDetailsStatus;

  /// No description provided for @technologyDetailsCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get technologyDetailsCost;

  /// No description provided for @technologyDetailsProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get technologyDetailsProgress;

  /// No description provided for @technologyDetailsPrerequisites.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get technologyDetailsPrerequisites;

  /// No description provided for @technologyDetailsUnlocks.
  ///
  /// In en, this message translates to:
  /// **'Unlocks'**
  String get technologyDetailsUnlocks;

  /// No description provided for @technologyDetailsEffects.
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get technologyDetailsEffects;

  /// No description provided for @technologyDetailsBoosts.
  ///
  /// In en, this message translates to:
  /// **'Boosts'**
  String get technologyDetailsBoosts;

  /// No description provided for @technologyDetailsUnlockStatus.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get technologyDetailsUnlockStatus;

  /// No description provided for @technologyDetailsNoEffects.
  ///
  /// In en, this message translates to:
  /// **'No passive effects'**
  String get technologyDetailsNoEffects;

  /// No description provided for @technologyDetailsNoBoosts.
  ///
  /// In en, this message translates to:
  /// **'No boosts'**
  String get technologyDetailsNoBoosts;

  /// No description provided for @technologyUnlocksNone.
  ///
  /// In en, this message translates to:
  /// **'No direct unlocks'**
  String get technologyUnlocksNone;

  /// No description provided for @technologyBoostActiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get technologyBoostActiveBadge;

  /// No description provided for @technologyBoostActiveBest.
  ///
  /// In en, this message translates to:
  /// **'The best available boost is active.'**
  String get technologyBoostActiveBest;

  /// No description provided for @technologyBoostLine.
  ///
  /// In en, this message translates to:
  /// **'{condition} (-{discount} cost)'**
  String technologyBoostLine(String condition, String discount);

  /// No description provided for @technologyUnlockFieldImprovementCategory.
  ///
  /// In en, this message translates to:
  /// **'Field improvement'**
  String get technologyUnlockFieldImprovementCategory;

  /// No description provided for @technologyEffectStrategicResourceProductionBonus.
  ///
  /// In en, this message translates to:
  /// **'+{production} production for each controlled resource: {resource}'**
  String technologyEffectStrategicResourceProductionBonus(
    int production,
    String resource,
  );

  /// No description provided for @technologyEffectGlobalGoldMultiplier.
  ///
  /// In en, this message translates to:
  /// **'+{percent} gold in city economy'**
  String technologyEffectGlobalGoldMultiplier(String percent);

  /// No description provided for @technologyEffectCityDefenseBonus.
  ///
  /// In en, this message translates to:
  /// **'+{amount} city defense'**
  String technologyEffectCityDefenseBonus(int amount);

  /// No description provided for @technologyEffectArmyProductionMultiplier.
  ///
  /// In en, this message translates to:
  /// **'+{percent} unit production in cities'**
  String technologyEffectArmyProductionMultiplier(String percent);

  /// No description provided for @technologyEffectArmyStrengthMultiplier.
  ///
  /// In en, this message translates to:
  /// **'+{percent} army strength'**
  String technologyEffectArmyStrengthMultiplier(String percent);

  /// No description provided for @technologyEffectMaxCityPopulationBonus.
  ///
  /// In en, this message translates to:
  /// **'+{amount} max city population'**
  String technologyEffectMaxCityPopulationBonus(int amount);

  /// No description provided for @technologyEffectMaxControlledHexesBonus.
  ///
  /// In en, this message translates to:
  /// **'+{amount} max city territory'**
  String technologyEffectMaxControlledHexesBonus(int amount);

  /// No description provided for @technologyEffectCityScienceBonus.
  ///
  /// In en, this message translates to:
  /// **'+{amount} science per city'**
  String technologyEffectCityScienceBonus(int amount);

  /// No description provided for @technologyBoostConditionImprovementCount.
  ///
  /// In en, this message translates to:
  /// **'Have {count}x {improvement}'**
  String technologyBoostConditionImprovementCount(
    int count,
    String improvement,
  );

  /// No description provided for @technologyBoostConditionHasImprovement.
  ///
  /// In en, this message translates to:
  /// **'Have {improvement}'**
  String technologyBoostConditionHasImprovement(String improvement);

  /// No description provided for @technologyBoostConditionControlsResource.
  ///
  /// In en, this message translates to:
  /// **'Control {resource}'**
  String technologyBoostConditionControlsResource(String resource);

  /// No description provided for @technologyBoostConditionControlsAnyResource.
  ///
  /// In en, this message translates to:
  /// **'Control: {resources}'**
  String technologyBoostConditionControlsAnyResource(String resources);

  /// No description provided for @technologyEffectAttackBonus.
  ///
  /// In en, this message translates to:
  /// **'{value} attack'**
  String technologyEffectAttackBonus(String value);

  /// No description provided for @technologyEffectDefenseBonus.
  ///
  /// In en, this message translates to:
  /// **'{value} defense'**
  String technologyEffectDefenseBonus(String value);

  /// No description provided for @technologyEffectNoArmyStatsBonus.
  ///
  /// In en, this message translates to:
  /// **'No army stat bonus'**
  String get technologyEffectNoArmyStatsBonus;

  /// No description provided for @technologyEffectArmyStatsBonus.
  ///
  /// In en, this message translates to:
  /// **'{parts} for armies'**
  String technologyEffectArmyStatsBonus(String parts);

  /// No description provided for @commonListOr.
  ///
  /// In en, this message translates to:
  /// **'{first} or {last}'**
  String commonListOr(String first, String last);

  /// No description provided for @buildingDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Building details'**
  String get buildingDetailsTooltip;

  /// No description provided for @buildingDetailsNoRequirements.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get buildingDetailsNoRequirements;

  /// No description provided for @buildingDetailsYieldImpact.
  ///
  /// In en, this message translates to:
  /// **'City impact'**
  String get buildingDetailsYieldImpact;

  /// No description provided for @buildingDetailsRequirementTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology: {technology}'**
  String buildingDetailsRequirementTechnology(String technology);

  /// No description provided for @buildingDetailsRequirementCoastalAccess.
  ///
  /// In en, this message translates to:
  /// **'Coastal access'**
  String get buildingDetailsRequirementCoastalAccess;

  /// No description provided for @buildingDetailsRequirementResources.
  ///
  /// In en, this message translates to:
  /// **'Resource: {resources}'**
  String buildingDetailsRequirementResources(String resources);

  /// No description provided for @buildingDetailsFlatYieldEffect.
  ///
  /// In en, this message translates to:
  /// **'{yield} to city yield'**
  String buildingDetailsFlatYieldEffect(String yield);

  /// No description provided for @buildingDetailsRiverHexYieldEffect.
  ///
  /// In en, this message translates to:
  /// **'{yield} per controlled river tile'**
  String buildingDetailsRiverHexYieldEffect(String yield);

  /// No description provided for @buildingDetailsRiverHexYieldEffectWithMax.
  ///
  /// In en, this message translates to:
  /// **'{yield} per controlled river tile (max {maxApplications})'**
  String buildingDetailsRiverHexYieldEffectWithMax(
    String yield,
    int maxApplications,
  );

  /// No description provided for @buildingDetailsMaxControlledHexesEffect.
  ///
  /// In en, this message translates to:
  /// **'+{amount} city controlled tile limit'**
  String buildingDetailsMaxControlledHexesEffect(int amount);

  /// No description provided for @buildingDetailsFoodDepositMultiplierEffect.
  ///
  /// In en, this message translates to:
  /// **'+{percent}% food stored after turn'**
  String buildingDetailsFoodDepositMultiplierEffect(int percent);

  /// No description provided for @buildingDetailsYieldFood.
  ///
  /// In en, this message translates to:
  /// **'{value} food'**
  String buildingDetailsYieldFood(String value);

  /// No description provided for @buildingDetailsYieldProduction.
  ///
  /// In en, this message translates to:
  /// **'{value} production'**
  String buildingDetailsYieldProduction(String value);

  /// No description provided for @buildingDetailsYieldGold.
  ///
  /// In en, this message translates to:
  /// **'{value} gold'**
  String buildingDetailsYieldGold(String value);

  /// No description provided for @buildingDetailsYieldDefense.
  ///
  /// In en, this message translates to:
  /// **'{value} defense'**
  String buildingDetailsYieldDefense(String value);

  /// No description provided for @buildingDetailsYieldScience.
  ///
  /// In en, this message translates to:
  /// **'{value} science'**
  String buildingDetailsYieldScience(String value);

  /// No description provided for @buildingDetailsNoYieldChange.
  ///
  /// In en, this message translates to:
  /// **'No resource change'**
  String get buildingDetailsNoYieldChange;

  /// No description provided for @unitDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unit details'**
  String get unitDetailsTooltip;

  /// No description provided for @unitDetailsMovement.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get unitDetailsMovement;

  /// No description provided for @unitDetailsCombat.
  ///
  /// In en, this message translates to:
  /// **'Combat'**
  String get unitDetailsCombat;

  /// No description provided for @unitDetailsMovementPerTurn.
  ///
  /// In en, this message translates to:
  /// **'{movement} tiles/turn'**
  String unitDetailsMovementPerTurn(int movement);

  /// No description provided for @unitDetailsPace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get unitDetailsPace;

  /// No description provided for @unitDetailsRequirementTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology: {technology}'**
  String unitDetailsRequirementTechnology(String technology);

  /// No description provided for @unitDetailsAttackLine.
  ///
  /// In en, this message translates to:
  /// **'Attack: {value}'**
  String unitDetailsAttackLine(int value);

  /// No description provided for @unitDetailsDefenseLine.
  ///
  /// In en, this message translates to:
  /// **'Defense: {value}'**
  String unitDetailsDefenseLine(int value);

  /// No description provided for @unitDetailsHpLine.
  ///
  /// In en, this message translates to:
  /// **'HP: {value}'**
  String unitDetailsHpLine(int value);

  /// No description provided for @unitDetailsRangeLine.
  ///
  /// In en, this message translates to:
  /// **'Range: {value}'**
  String unitDetailsRangeLine(int value);

  /// No description provided for @sciencePerTurn.
  ///
  /// In en, this message translates to:
  /// **'{science} science/turn'**
  String sciencePerTurn(int science);

  /// No description provided for @activeResearchLabel.
  ///
  /// In en, this message translates to:
  /// **'RESEARCHING'**
  String get activeResearchLabel;

  /// No description provided for @requirementTechnology.
  ///
  /// In en, this message translates to:
  /// **'Requires technology'**
  String get requirementTechnology;

  /// No description provided for @requirementTechnologyName.
  ///
  /// In en, this message translates to:
  /// **'Requires: {technology}'**
  String requirementTechnologyName(String technology);

  /// Joins alternative resource requirements into a list, e.g. 'wheat, fish or gold'.
  ///
  /// In en, this message translates to:
  /// **'{leading} or {last}'**
  String requirementResourceAnyOf(String leading, String last);

  /// No description provided for @requirementResourcesName.
  ///
  /// In en, this message translates to:
  /// **'Requires: {resources}'**
  String requirementResourcesName(String resources);

  /// No description provided for @technologyBlockedBy.
  ///
  /// In en, this message translates to:
  /// **'Blocked by: {technology}'**
  String technologyBlockedBy(String technology);

  /// No description provided for @requirementCoastalAccess.
  ///
  /// In en, this message translates to:
  /// **'Requires: coastal access'**
  String get requirementCoastalAccess;

  /// No description provided for @productionCategoryBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get productionCategoryBuilding;

  /// No description provided for @productionCategoryUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get productionCategoryUnit;

  /// No description provided for @productionTitle.
  ///
  /// In en, this message translates to:
  /// **'PRODUCTION'**
  String get productionTitle;

  /// No description provided for @productionInProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get productionInProgressLabel;

  /// No description provided for @productionPerTurn.
  ///
  /// In en, this message translates to:
  /// **'{production} production/turn'**
  String productionPerTurn(int production);

  /// No description provided for @productionNoProduction.
  ///
  /// In en, this message translates to:
  /// **'no production'**
  String get productionNoProduction;

  /// No description provided for @productionButtonProduce.
  ///
  /// In en, this message translates to:
  /// **'PRODUCE'**
  String get productionButtonProduce;

  /// No description provided for @productionButtonLocked.
  ///
  /// In en, this message translates to:
  /// **'LOCKED'**
  String get productionButtonLocked;

  /// No description provided for @productionEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No production is currently available.'**
  String get productionEmptyState;

  /// No description provided for @buildingsSection.
  ///
  /// In en, this message translates to:
  /// **'Buildings'**
  String get buildingsSection;

  /// No description provided for @unitsSection.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get unitsSection;

  /// No description provided for @futureBuildingsSection.
  ///
  /// In en, this message translates to:
  /// **'Future buildings ({count})'**
  String futureBuildingsSection(int count);

  /// No description provided for @futureBuildingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlocked by technologies'**
  String get futureBuildingsSubtitle;

  /// No description provided for @workerPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Worker - {unitName}'**
  String workerPanelTitle(String unitName);

  /// No description provided for @commonOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpenAction;

  /// No description provided for @commonShowDetailsAction.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get commonShowDetailsAction;

  /// No description provided for @commonExecuteAction.
  ///
  /// In en, this message translates to:
  /// **'Execute'**
  String get commonExecuteAction;

  /// No description provided for @colorPickerChangeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change color: {label}'**
  String colorPickerChangeTooltip(String label);

  /// No description provided for @colorPickerColorSelected.
  ///
  /// In en, this message translates to:
  /// **'#{hex} selected'**
  String colorPickerColorSelected(String hex);

  /// No description provided for @colorPickerSelectColor.
  ///
  /// In en, this message translates to:
  /// **'Select #{hex}'**
  String colorPickerSelectColor(String hex);

  /// No description provided for @commonDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get commonDescription;

  /// No description provided for @commonSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get commonSummary;

  /// No description provided for @commonStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get commonStatus;

  /// No description provided for @commonTerrain.
  ///
  /// In en, this message translates to:
  /// **'Terrain'**
  String get commonTerrain;

  /// No description provided for @commonResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get commonResources;

  /// No description provided for @commonImprovements.
  ///
  /// In en, this message translates to:
  /// **'Improvements'**
  String get commonImprovements;

  /// No description provided for @commonCities.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get commonCities;

  /// No description provided for @commonBuildings.
  ///
  /// In en, this message translates to:
  /// **'Buildings'**
  String get commonBuildings;

  /// No description provided for @commonGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get commonGold;

  /// No description provided for @commonScience.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get commonScience;

  /// No description provided for @commonStability.
  ///
  /// In en, this message translates to:
  /// **'Stability'**
  String get commonStability;

  /// No description provided for @commonProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get commonProduction;

  /// No description provided for @commonResearch.
  ///
  /// In en, this message translates to:
  /// **'Research'**
  String get commonResearch;

  /// No description provided for @commonEmpire.
  ///
  /// In en, this message translates to:
  /// **'Empire'**
  String get commonEmpire;

  /// No description provided for @commonTurn.
  ///
  /// In en, this message translates to:
  /// **'Turn'**
  String get commonTurn;

  /// No description provided for @commonProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get commonProjects;

  /// No description provided for @commonPopulation.
  ///
  /// In en, this message translates to:
  /// **'Population'**
  String get commonPopulation;

  /// No description provided for @commonTechnologies.
  ///
  /// In en, this message translates to:
  /// **'Technologies'**
  String get commonTechnologies;

  /// No description provided for @commonFields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get commonFields;

  /// No description provided for @commonMultipliers.
  ///
  /// In en, this message translates to:
  /// **'Multipliers'**
  String get commonMultipliers;

  /// No description provided for @commonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get commonOther;

  /// No description provided for @commonReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get commonReady;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get commonDefault;

  /// No description provided for @commonAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get commonAvailable;

  /// No description provided for @commonBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get commonBlocked;

  /// No description provided for @commonSelectAction.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get commonSelectAction;

  /// No description provided for @commonSelectedAction.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get commonSelectedAction;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonDoNotShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Do not show again'**
  String get commonDoNotShowAgain;

  /// No description provided for @commonNoneLower.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get commonNoneLower;

  /// No description provided for @visualCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get visualCurrentLabel;

  /// No description provided for @visualAfterLabel.
  ///
  /// In en, this message translates to:
  /// **'After change'**
  String get visualAfterLabel;

  /// No description provided for @terrainDetailEmpty.
  ///
  /// In en, this message translates to:
  /// **'No terrain information'**
  String get terrainDetailEmpty;

  /// No description provided for @yieldFoodShort.
  ///
  /// In en, this message translates to:
  /// **'FOOD'**
  String get yieldFoodShort;

  /// No description provided for @yieldProductionShort.
  ///
  /// In en, this message translates to:
  /// **'PROD'**
  String get yieldProductionShort;

  /// No description provided for @yieldGoldShort.
  ///
  /// In en, this message translates to:
  /// **'GOLD'**
  String get yieldGoldShort;

  /// No description provided for @yieldDefenseShort.
  ///
  /// In en, this message translates to:
  /// **'DEF'**
  String get yieldDefenseShort;

  /// No description provided for @selectionChipBadgeSuffix.
  ///
  /// In en, this message translates to:
  /// **' Visible counter: {badge}.'**
  String selectionChipBadgeSuffix(String badge);

  /// No description provided for @selectionChipDisabledDescription.
  ///
  /// In en, this message translates to:
  /// **'This information shortcut is not available for the current selection.{badge}'**
  String selectionChipDisabledDescription(String badge);

  /// No description provided for @selectionChipOpenDescription.
  ///
  /// In en, this message translates to:
  /// **'Opens “{label}” details for the current map context.{badge}'**
  String selectionChipOpenDescription(String label, String badge);

  /// No description provided for @gameGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Game goal'**
  String get gameGoalTitle;

  /// No description provided for @globalHudCloseResearch.
  ///
  /// In en, this message translates to:
  /// **'Close research'**
  String get globalHudCloseResearch;

  /// No description provided for @globalHudResearchActive.
  ///
  /// In en, this message translates to:
  /// **'Research: {technologyName}'**
  String globalHudResearchActive(String technologyName);

  /// No description provided for @globalHudResearchActiveWithEta.
  ///
  /// In en, this message translates to:
  /// **'Research: {technologyName} · {eta}'**
  String globalHudResearchActiveWithEta(String technologyName, String eta);

  /// No description provided for @globalHudChooseResearch.
  ///
  /// In en, this message translates to:
  /// **'Choose research'**
  String get globalHudChooseResearch;

  /// No description provided for @globalHudCloseEmpire.
  ///
  /// In en, this message translates to:
  /// **'Close empire'**
  String get globalHudCloseEmpire;

  /// No description provided for @globalHudCloseActivityLog.
  ///
  /// In en, this message translates to:
  /// **'Close activity log'**
  String get globalHudCloseActivityLog;

  /// No description provided for @bottomToolbarWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get bottomToolbarWaiting;

  /// No description provided for @bottomToolbarPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get bottomToolbarPlan;

  /// No description provided for @bottomToolbarMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get bottomToolbarMove;

  /// No description provided for @bottomToolbarResolvingTurn.
  ///
  /// In en, this message translates to:
  /// **'Resolving turn'**
  String get bottomToolbarResolvingTurn;

  /// No description provided for @bottomToolbarWaitingFor.
  ///
  /// In en, this message translates to:
  /// **'Waiting: {players}'**
  String bottomToolbarWaitingFor(String players);

  /// No description provided for @turnHintNextUnit.
  ///
  /// In en, this message translates to:
  /// **'Next step: {unit}'**
  String turnHintNextUnit(String unit);

  /// No description provided for @turnHintNextCityProduction.
  ///
  /// In en, this message translates to:
  /// **'Next step: production in {city}'**
  String turnHintNextCityProduction(String city);

  /// No description provided for @turnHintChooseResearch.
  ///
  /// In en, this message translates to:
  /// **'Next step: choose research'**
  String get turnHintChooseResearch;

  /// No description provided for @turnHintCheckAction.
  ///
  /// In en, this message translates to:
  /// **'Next step: check action'**
  String get turnHintCheckAction;

  /// No description provided for @turnHintObjective.
  ///
  /// In en, this message translates to:
  /// **'Objective: {objective}'**
  String turnHintObjective(String objective);

  /// No description provided for @turnHintObjectiveWithAdvice.
  ///
  /// In en, this message translates to:
  /// **'Objective: {objective} · {advice}'**
  String turnHintObjectiveWithAdvice(String objective, String advice);

  /// No description provided for @turnHintImproveFieldWithWorker.
  ///
  /// In en, this message translates to:
  /// **'Objective: improve a tile with a worker'**
  String get turnHintImproveFieldWithWorker;

  /// No description provided for @turnHintFoundCityWithSettler.
  ///
  /// In en, this message translates to:
  /// **'Objective: found a city with a settler'**
  String get turnHintFoundCityWithSettler;

  /// No description provided for @turnHintClaimTerritoryWithSettler.
  ///
  /// In en, this message translates to:
  /// **'Objective: claim territory with a settler'**
  String get turnHintClaimTerritoryWithSettler;

  /// No description provided for @turnHintTrainUnit.
  ///
  /// In en, this message translates to:
  /// **'Objective: set unit: {unit}'**
  String turnHintTrainUnit(String unit);

  /// No description provided for @turnHintProtectLeadUnit.
  ///
  /// In en, this message translates to:
  /// **'Objective: secure the lead: {unit}'**
  String turnHintProtectLeadUnit(String unit);

  /// No description provided for @turnHintConstructBuildingInCity.
  ///
  /// In en, this message translates to:
  /// **'Objective: queue a building in {city}'**
  String turnHintConstructBuildingInCity(String city);

  /// No description provided for @turnHintTrainUnitInCity.
  ///
  /// In en, this message translates to:
  /// **'Objective: queue a unit in {city}'**
  String turnHintTrainUnitInCity(String city);

  /// No description provided for @turnHintPrepareSettlerInCity.
  ///
  /// In en, this message translates to:
  /// **'Objective: prepare a settler in {city}'**
  String turnHintPrepareSettlerInCity(String city);

  /// No description provided for @turnHintGrowPopulationInCity.
  ///
  /// In en, this message translates to:
  /// **'Objective: set growth in {city}'**
  String turnHintGrowPopulationInCity(String city);

  /// No description provided for @turnHintPrepareWorkerInCity.
  ///
  /// In en, this message translates to:
  /// **'Objective: prepare a worker in {city}'**
  String turnHintPrepareWorkerInCity(String city);

  /// No description provided for @turnHintCollectGoldInCity.
  ///
  /// In en, this message translates to:
  /// **'Objective: close gold in {city}'**
  String turnHintCollectGoldInCity(String city);

  /// No description provided for @turnHintProtectLeadProductionInCity.
  ///
  /// In en, this message translates to:
  /// **'Objective: secure production in {city}'**
  String turnHintProtectLeadProductionInCity(String city);

  /// No description provided for @turnHintUnlockTechnologyForScore.
  ///
  /// In en, this message translates to:
  /// **'Objective: choose a scoring technology'**
  String get turnHintUnlockTechnologyForScore;

  /// No description provided for @turnHintProtectLeadResearch.
  ///
  /// In en, this message translates to:
  /// **'Objective: finish safe research'**
  String get turnHintProtectLeadResearch;

  /// No description provided for @topResourceTurnShortLabel.
  ///
  /// In en, this message translates to:
  /// **'T{turn}'**
  String topResourceTurnShortLabel(int turn);

  /// No description provided for @topResourceTurnTooltip.
  ///
  /// In en, this message translates to:
  /// **'Turn {turn}'**
  String topResourceTurnTooltip(int turn);

  /// No description provided for @topResourceScienceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Science: {scienceTurnLabel} / turn'**
  String topResourceScienceTooltip(String scienceTurnLabel);

  /// No description provided for @topResourceStabilityTooltip.
  ///
  /// In en, this message translates to:
  /// **'Empire stability: {net}'**
  String topResourceStabilityTooltip(int net);

  /// No description provided for @topResourceResourcesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Resources: {resourceTotal} deposits • {resourceTypes} controlled types'**
  String topResourceResourcesTooltip(int resourceTotal, int resourceTypes);

  /// No description provided for @topResourceGoldTooltip.
  ///
  /// In en, this message translates to:
  /// **'Gold: {gold} • income +{goldIncome} • upkeep -{unitUpkeep} • net {net} / turn'**
  String topResourceGoldTooltip(
    int gold,
    int goldIncome,
    int unitUpkeep,
    String net,
  );

  /// No description provided for @topResourceGoldTooltipNegativeTreasury.
  ///
  /// In en, this message translates to:
  /// **'{base} • treasury below zero'**
  String topResourceGoldTooltipNegativeTreasury(String base);

  /// No description provided for @topResourceGoldTooltipBankruptcy.
  ///
  /// In en, this message translates to:
  /// **'{base} • bankruptcy risk within 3 turns'**
  String topResourceGoldTooltipBankruptcy(String base);

  /// No description provided for @resourceBreakdownTreasury.
  ///
  /// In en, this message translates to:
  /// **'Treasury'**
  String get resourceBreakdownTreasury;

  /// No description provided for @resourceBreakdownCityIncome.
  ///
  /// In en, this message translates to:
  /// **'City income'**
  String get resourceBreakdownCityIncome;

  /// No description provided for @resourceBreakdownUpkeep.
  ///
  /// In en, this message translates to:
  /// **'Upkeep'**
  String get resourceBreakdownUpkeep;

  /// No description provided for @resourceBreakdownNetPerTurn.
  ///
  /// In en, this message translates to:
  /// **'Net / turn'**
  String get resourceBreakdownNetPerTurn;

  /// No description provided for @resourceBreakdownNoCityIncome.
  ///
  /// In en, this message translates to:
  /// **'No city income'**
  String get resourceBreakdownNoCityIncome;

  /// No description provided for @resourceBreakdownFreeLimit.
  ///
  /// In en, this message translates to:
  /// **'Free limit'**
  String get resourceBreakdownFreeLimit;

  /// No description provided for @resourceBreakdownNextWorkerUpkeep.
  ///
  /// In en, this message translates to:
  /// **'Next worker upkeep'**
  String get resourceBreakdownNextWorkerUpkeep;

  /// No description provided for @resourceBreakdownNextWorkerUpkeepValue.
  ///
  /// In en, this message translates to:
  /// **'-{upkeep} gold/turn'**
  String resourceBreakdownNextWorkerUpkeepValue(int upkeep);

  /// No description provided for @resourceBreakdownInsideFreeLimit.
  ///
  /// In en, this message translates to:
  /// **'Inside free limit'**
  String get resourceBreakdownInsideFreeLimit;

  /// No description provided for @resourceBreakdownNoActiveTechnology.
  ///
  /// In en, this message translates to:
  /// **'No technology selected'**
  String get resourceBreakdownNoActiveTechnology;

  /// No description provided for @resourceBreakdownScienceTitle.
  ///
  /// In en, this message translates to:
  /// **'Science and research'**
  String get resourceBreakdownScienceTitle;

  /// No description provided for @resourceBreakdownSciencePerTurn.
  ///
  /// In en, this message translates to:
  /// **'Science / turn'**
  String get resourceBreakdownSciencePerTurn;

  /// No description provided for @resourceBreakdownActiveResearch.
  ///
  /// In en, this message translates to:
  /// **'Active research'**
  String get resourceBreakdownActiveResearch;

  /// No description provided for @resourceBreakdownTurnsToComplete.
  ///
  /// In en, this message translates to:
  /// **'To complete'**
  String get resourceBreakdownTurnsToComplete;

  /// No description provided for @resourceBreakdownNoScienceSources.
  ///
  /// In en, this message translates to:
  /// **'No science sources'**
  String get resourceBreakdownNoScienceSources;

  /// No description provided for @resourceBreakdownCityResearchProject.
  ///
  /// In en, this message translates to:
  /// **'{cityName}: Research'**
  String resourceBreakdownCityResearchProject(String cityName);

  /// No description provided for @resourceBreakdownNoControlledResources.
  ///
  /// In en, this message translates to:
  /// **'No controlled resources'**
  String get resourceBreakdownNoControlledResources;

  /// No description provided for @resourceBreakdownGrowCitiesWithFood.
  ///
  /// In en, this message translates to:
  /// **'Grow cities with food'**
  String get resourceBreakdownGrowCitiesWithFood;

  /// No description provided for @resourceBreakdownControlledDeposits.
  ///
  /// In en, this message translates to:
  /// **'Controlled deposits'**
  String get resourceBreakdownControlledDeposits;

  /// No description provided for @resourceBreakdownResourceTypes.
  ///
  /// In en, this message translates to:
  /// **'Resource types'**
  String get resourceBreakdownResourceTypes;

  /// No description provided for @resourceBreakdownTypesSection.
  ///
  /// In en, this message translates to:
  /// **'Types'**
  String get resourceBreakdownTypesSection;

  /// No description provided for @resourceBreakdownSourcesSection.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get resourceBreakdownSourcesSection;

  /// No description provided for @technologyRecommendationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended research'**
  String get technologyRecommendationsTitle;

  /// No description provided for @technologyShowTreeAction.
  ///
  /// In en, this message translates to:
  /// **'Show tree'**
  String get technologyShowTreeAction;

  /// No description provided for @technologyShowTreeCountAction.
  ///
  /// In en, this message translates to:
  /// **'Show tree ({count})'**
  String technologyShowTreeCountAction(int count);

  /// No description provided for @technologyRecommendationUnlocks.
  ///
  /// In en, this message translates to:
  /// **'Unlocks'**
  String get technologyRecommendationUnlocks;

  /// No description provided for @technologyRecommendationReasonBoost.
  ///
  /// In en, this message translates to:
  /// **'Active boost lowers the research cost.'**
  String get technologyRecommendationReasonBoost;

  /// No description provided for @technologyRecommendationReasonSection.
  ///
  /// In en, this message translates to:
  /// **'Why now'**
  String get technologyRecommendationReasonSection;

  /// No description provided for @technologyRecommendationReasonImprovements.
  ///
  /// In en, this message translates to:
  /// **'New tile improvements quickly turn resources into yield.'**
  String get technologyRecommendationReasonImprovements;

  /// No description provided for @technologyRecommendationReasonBuilding.
  ///
  /// In en, this message translates to:
  /// **'A new city building opens another development direction.'**
  String get technologyRecommendationReasonBuilding;

  /// No description provided for @technologyRecommendationReasonUnit.
  ///
  /// In en, this message translates to:
  /// **'A new unit strengthens safety and map control.'**
  String get technologyRecommendationReasonUnit;

  /// No description provided for @technologyRecommendationReasonEffect.
  ///
  /// In en, this message translates to:
  /// **'A permanent bonus applies to the whole economy.'**
  String get technologyRecommendationReasonEffect;

  /// No description provided for @technologyRecommendationReasonFast.
  ///
  /// In en, this message translates to:
  /// **'Fast research with no extra requirements.'**
  String get technologyRecommendationReasonFast;

  /// No description provided for @technologyRecommendationReasonDefault.
  ///
  /// In en, this message translates to:
  /// **'Available research that neatly closes the next step.'**
  String get technologyRecommendationReasonDefault;

  /// No description provided for @technologyNoRecommendations.
  ///
  /// In en, this message translates to:
  /// **'No new research is currently available.'**
  String get technologyNoRecommendations;

  /// No description provided for @technologyFullTreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Full technology tree'**
  String get technologyFullTreeTitle;

  /// No description provided for @technologyRecommendationsBackAction.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get technologyRecommendationsBackAction;

  /// No description provided for @empireUnitsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No units'**
  String get empireUnitsEmptyTitle;

  /// No description provided for @empireUnitsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'New units will appear here after city production or event recruitment.'**
  String get empireUnitsEmptyBody;

  /// No description provided for @empireCitiesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No cities'**
  String get empireCitiesEmptyTitle;

  /// No description provided for @empireCitiesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Found your first city with a settler to unlock production, science, and empire borders.'**
  String get empireCitiesEmptyBody;

  /// No description provided for @empireCityCenters.
  ///
  /// In en, this message translates to:
  /// **'City centers'**
  String get empireCityCenters;

  /// No description provided for @empireShowFirstUnitTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show the first unit on the map'**
  String get empireShowFirstUnitTooltip;

  /// No description provided for @empireShowUnitTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show unit on the map'**
  String get empireShowUnitTooltip;

  /// No description provided for @empireShowFirstCityTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show the first city on the map'**
  String get empireShowFirstCityTooltip;

  /// No description provided for @empireShowCityTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show city on the map'**
  String get empireShowCityTooltip;

  /// No description provided for @empireUnitCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unit} other{{count} units}}'**
  String empireUnitCountLabel(int count);

  /// No description provided for @empireCityCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 city} other{{count} cities}}'**
  String empireCityCountLabel(int count);

  /// No description provided for @empireUnitMovement.
  ///
  /// In en, this message translates to:
  /// **'Movement {movement}'**
  String empireUnitMovement(int movement);

  /// No description provided for @empireUnitBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get empireUnitBuilding;

  /// No description provided for @empireUnitWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get empireUnitWorking;

  /// No description provided for @empireUnitFortifying.
  ///
  /// In en, this message translates to:
  /// **'Fortifying'**
  String get empireUnitFortifying;

  /// No description provided for @empireUnitHealing.
  ///
  /// In en, this message translates to:
  /// **'Healing'**
  String get empireUnitHealing;

  /// No description provided for @empireUnitEnRoute.
  ///
  /// In en, this message translates to:
  /// **'En route'**
  String get empireUnitEnRoute;

  /// No description provided for @empireUnitNoMovement.
  ///
  /// In en, this message translates to:
  /// **'no movement'**
  String get empireUnitNoMovement;

  /// No description provided for @empireUnitsWithMovement.
  ///
  /// In en, this message translates to:
  /// **'{count} with movement'**
  String empireUnitsWithMovement(int count);

  /// No description provided for @empireCitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Population {population} - {hexes} tiles - {buildings} bldg. - producing: {production}'**
  String empireCitySubtitle(
    int population,
    int hexes,
    int buildings,
    String production,
  );

  /// No description provided for @empireCityStoredArtifact.
  ///
  /// In en, this message translates to:
  /// **'Artifact: {artifactName}'**
  String empireCityStoredArtifact(String artifactName);

  /// No description provided for @empireCityGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{cityLabel} - population {population}'**
  String empireCityGroupSubtitle(String cityLabel, int population);

  /// No description provided for @empireStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Empire status'**
  String get empireStatsTitle;

  /// No description provided for @empireStatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A quick read of readiness, composition, and city growth'**
  String get empireStatsSubtitle;

  /// No description provided for @empireStatsReadinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Unit readiness'**
  String get empireStatsReadinessTitle;

  /// No description provided for @empireStatsUnitCompositionTitle.
  ///
  /// In en, this message translates to:
  /// **'Unit composition'**
  String get empireStatsUnitCompositionTitle;

  /// No description provided for @empireStatsCityDevelopmentTitle.
  ///
  /// In en, this message translates to:
  /// **'City development'**
  String get empireStatsCityDevelopmentTitle;

  /// No description provided for @empireStatsCityComparisonTitle.
  ///
  /// In en, this message translates to:
  /// **'City comparison'**
  String get empireStatsCityComparisonTitle;

  /// No description provided for @empireStatsOrders.
  ///
  /// In en, this message translates to:
  /// **'With orders'**
  String get empireStatsOrders;

  /// No description provided for @empireStatsNoMovement.
  ///
  /// In en, this message translates to:
  /// **'No movement'**
  String get empireStatsNoMovement;

  /// No description provided for @empireStatsAveragePopulation.
  ///
  /// In en, this message translates to:
  /// **'Avg. pop.'**
  String get empireStatsAveragePopulation;

  /// No description provided for @empireStatsTotalBuildings.
  ///
  /// In en, this message translates to:
  /// **'Buildings'**
  String get empireStatsTotalBuildings;

  /// No description provided for @empireStatsStoredArtifacts.
  ///
  /// In en, this message translates to:
  /// **'Artifacts'**
  String get empireStatsStoredArtifacts;

  /// No description provided for @empireStatsTerritory.
  ///
  /// In en, this message translates to:
  /// **'Territory'**
  String get empireStatsTerritory;

  /// No description provided for @empireStatsCitiesProducing.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get empireStatsCitiesProducing;

  /// No description provided for @empireStatsOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get empireStatsOther;

  /// No description provided for @empireStatsEmptyUnits.
  ///
  /// In en, this message translates to:
  /// **'No units to analyze'**
  String get empireStatsEmptyUnits;

  /// No description provided for @empireStatsEmptyCities.
  ///
  /// In en, this message translates to:
  /// **'No cities to analyze'**
  String get empireStatsEmptyCities;

  /// No description provided for @empireStatsCityBarDetail.
  ///
  /// In en, this message translates to:
  /// **'Pop. {population} • bldg. {buildings}'**
  String empireStatsCityBarDetail(int population, int buildings);

  /// No description provided for @empireStatsCityComparisonDetail.
  ///
  /// In en, this message translates to:
  /// **'Pop. {population} • Prod. {production} • Food {food} • Gold {gold}'**
  String empireStatsCityComparisonDetail(
    int population,
    int production,
    int food,
    int gold,
  );

  /// No description provided for @empireStatsMetricPopulation.
  ///
  /// In en, this message translates to:
  /// **'Pop.'**
  String get empireStatsMetricPopulation;

  /// No description provided for @empireStatsMetricProduction.
  ///
  /// In en, this message translates to:
  /// **'Prod.'**
  String get empireStatsMetricProduction;

  /// No description provided for @empireStatsMetricFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get empireStatsMetricFood;

  /// No description provided for @empireStatsMetricGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get empireStatsMetricGold;

  /// No description provided for @activityLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get activityLogTitle;

  /// No description provided for @activityLogShowAllAction.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get activityLogShowAllAction;

  /// No description provided for @activityLogShowMoreAction.
  ///
  /// In en, this message translates to:
  /// **'Show more ({visible}/{total})'**
  String activityLogShowMoreAction(int visible, int total);

  /// No description provided for @activityLogLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading full history...'**
  String get activityLogLoadingHistory;

  /// No description provided for @activityLogHistoryErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load history'**
  String get activityLogHistoryErrorTitle;

  /// No description provided for @activityLogHistoryErrorBody.
  ///
  /// In en, this message translates to:
  /// **'The event journal is unavailable: {error}'**
  String activityLogHistoryErrorBody(String error);

  /// No description provided for @activityLogFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get activityLogFilterAll;

  /// No description provided for @activityLogFilterAllShort.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get activityLogFilterAllShort;

  /// No description provided for @activityLogFilterCombat.
  ///
  /// In en, this message translates to:
  /// **'Combat'**
  String get activityLogFilterCombat;

  /// No description provided for @activityLogFilterCities.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get activityLogFilterCities;

  /// No description provided for @activityLogFilterDiplomacy.
  ///
  /// In en, this message translates to:
  /// **'Diplomacy'**
  String get activityLogFilterDiplomacy;

  /// No description provided for @activityLogFilterDiplomacyShort.
  ///
  /// In en, this message translates to:
  /// **'Diplo'**
  String get activityLogFilterDiplomacyShort;

  /// No description provided for @activityLogFilterTechnology.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get activityLogFilterTechnology;

  /// No description provided for @activityLogEmptyAllTitle.
  ///
  /// In en, this message translates to:
  /// **'No recorded events'**
  String get activityLogEmptyAllTitle;

  /// No description provided for @activityLogEmptyCombatTitle.
  ///
  /// In en, this message translates to:
  /// **'No recorded battles'**
  String get activityLogEmptyCombatTitle;

  /// No description provided for @activityLogEmptyCityTitle.
  ///
  /// In en, this message translates to:
  /// **'No recorded city events'**
  String get activityLogEmptyCityTitle;

  /// No description provided for @activityLogEmptyDiplomacyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recorded diplomacy'**
  String get activityLogEmptyDiplomacyTitle;

  /// No description provided for @activityLogEmptyTechnologyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recorded discoveries'**
  String get activityLogEmptyTechnologyTitle;

  /// No description provided for @activityLogEmptyAllBody.
  ///
  /// In en, this message translates to:
  /// **'First discoveries, battles, and builds will appear here after you play actions.'**
  String get activityLogEmptyAllBody;

  /// No description provided for @activityLogEmptyCombatBody.
  ///
  /// In en, this message translates to:
  /// **'Battles are recorded after attacks or defenses visible to the player.'**
  String get activityLogEmptyCombatBody;

  /// No description provided for @activityLogEmptyCityBody.
  ///
  /// In en, this message translates to:
  /// **'Founded cities, builds, and claimed tiles will create the empire timeline here.'**
  String get activityLogEmptyCityBody;

  /// No description provided for @activityLogEmptyDiplomacyBody.
  ///
  /// In en, this message translates to:
  /// **'Dispatches, proposals, replies, and relation changes will appear here after diplomatic actions.'**
  String get activityLogEmptyDiplomacyBody;

  /// No description provided for @activityLogEmptyTechnologyBody.
  ///
  /// In en, this message translates to:
  /// **'Discovered technologies will appear here after research completes.'**
  String get activityLogEmptyTechnologyBody;

  /// No description provided for @turnTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn timeline'**
  String get turnTimelineTitle;

  /// No description provided for @turnTimelineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn {turn} • events: {count}'**
  String turnTimelineSubtitle(int turn, int count);

  /// No description provided for @turnTimelineChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Events across turns'**
  String get turnTimelineChartTitle;

  /// No description provided for @turnTimelineMetricEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get turnTimelineMetricEvents;

  /// No description provided for @turnTimelineMetricActiveTurns.
  ///
  /// In en, this message translates to:
  /// **'Active turns'**
  String get turnTimelineMetricActiveTurns;

  /// No description provided for @turnTimelineMetricCurrentTurn.
  ///
  /// In en, this message translates to:
  /// **'Current turn'**
  String get turnTimelineMetricCurrentTurn;

  /// No description provided for @technologyDiscoveryEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Technology discovered'**
  String get technologyDiscoveryEyebrow;

  /// No description provided for @unitSelectionMovementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Move {current}/{max}'**
  String unitSelectionMovementSubtitle(int current, int max);

  /// No description provided for @unitSelectionMovementHpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Move {current}/{max} • HP {hp}/{maxHp}'**
  String unitSelectionMovementHpSubtitle(
    int current,
    int max,
    int hp,
    int maxHp,
  );

  /// No description provided for @unitSelectionAttackLabel.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get unitSelectionAttackLabel;

  /// No description provided for @unitSelectionDefenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Defense'**
  String get unitSelectionDefenseLabel;

  /// No description provided for @unitSelectionHpLabel.
  ///
  /// In en, this message translates to:
  /// **'HP'**
  String get unitSelectionHpLabel;

  /// No description provided for @unitSelectionRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get unitSelectionRangeLabel;

  /// No description provided for @unitSelectionConstructionLabel.
  ///
  /// In en, this message translates to:
  /// **'Construction'**
  String get unitSelectionConstructionLabel;

  /// No description provided for @unitSelectionWorkLabel.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get unitSelectionWorkLabel;

  /// No description provided for @unitSelectionFieldBonusValue.
  ///
  /// In en, this message translates to:
  /// **'Field bonus'**
  String get unitSelectionFieldBonusValue;

  /// No description provided for @tileSelectionYieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Tile potential'**
  String get tileSelectionYieldTitle;

  /// No description provided for @tileSelectionYieldTooltip.
  ///
  /// In en, this message translates to:
  /// **'Inspection estimate for this tile, not actual city yield.'**
  String get tileSelectionYieldTooltip;

  /// No description provided for @tileSelectionBonusLabel.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get tileSelectionBonusLabel;

  /// No description provided for @tileSelectionDefenseBonusValue.
  ///
  /// In en, this message translates to:
  /// **'+defense'**
  String get tileSelectionDefenseBonusValue;

  /// No description provided for @tileSelectionRiverBonusValue.
  ///
  /// In en, this message translates to:
  /// **'+river'**
  String get tileSelectionRiverBonusValue;

  /// No description provided for @citySelectionYieldTitle.
  ///
  /// In en, this message translates to:
  /// **'City income'**
  String get citySelectionYieldTitle;

  /// No description provided for @citySelectionYieldTooltip.
  ///
  /// In en, this message translates to:
  /// **'Actual city yield per turn from the city economy.'**
  String get citySelectionYieldTooltip;

  /// No description provided for @citySelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Population {population} • {territoryHexCount}/{maxHexes} fields • Production: {production}'**
  String citySelectionSubtitle(
    int population,
    int territoryHexCount,
    int maxHexes,
    String production,
  );

  /// No description provided for @citySelectionTerritoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Territory'**
  String get citySelectionTerritoryLabel;

  /// No description provided for @citySelectionFoodLabel.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get citySelectionFoodLabel;

  /// No description provided for @citySelectionNetFoodLabel.
  ///
  /// In en, this message translates to:
  /// **'Net food'**
  String get citySelectionNetFoodLabel;

  /// No description provided for @citySelectionBuildingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Buildings'**
  String get citySelectionBuildingsLabel;

  /// No description provided for @citySelectionArtifactLabel.
  ///
  /// In en, this message translates to:
  /// **'Artifact'**
  String get citySelectionArtifactLabel;

  /// No description provided for @worldArtifactBonusTitle.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get worldArtifactBonusTitle;

  /// No description provided for @worldArtifactHeritageTitle.
  ///
  /// In en, this message translates to:
  /// **'Heritage'**
  String get worldArtifactHeritageTitle;

  /// No description provided for @worldArtifactHeritageBody.
  ///
  /// In en, this message translates to:
  /// **'Collect and place 6 unique artifacts in your cities, then hold the collection for 5 turns.'**
  String get worldArtifactHeritageBody;

  /// No description provided for @worldArtifactAncientImperialCrown.
  ///
  /// In en, this message translates to:
  /// **'Ancient Imperial Crown'**
  String get worldArtifactAncientImperialCrown;

  /// No description provided for @worldArtifactAstronomersTablets.
  ///
  /// In en, this message translates to:
  /// **'Astronomers\' Tablets'**
  String get worldArtifactAstronomersTablets;

  /// No description provided for @worldArtifactProphetMask.
  ///
  /// In en, this message translates to:
  /// **'Prophet\'s Mask'**
  String get worldArtifactProphetMask;

  /// No description provided for @worldArtifactHeroSword.
  ///
  /// In en, this message translates to:
  /// **'Hero\'s Sword'**
  String get worldArtifactHeroSword;

  /// No description provided for @worldArtifactMerchantsSeal.
  ///
  /// In en, this message translates to:
  /// **'Merchant\'s Seal'**
  String get worldArtifactMerchantsSeal;

  /// No description provided for @worldArtifactFirstPeoplesChronicle.
  ///
  /// In en, this message translates to:
  /// **'First Peoples\' Chronicle'**
  String get worldArtifactFirstPeoplesChronicle;

  /// No description provided for @worldArtifactTempleReliquary.
  ///
  /// In en, this message translates to:
  /// **'Temple Reliquary'**
  String get worldArtifactTempleReliquary;

  /// No description provided for @worldArtifactQueensMirror.
  ///
  /// In en, this message translates to:
  /// **'Queen\'s Mirror'**
  String get worldArtifactQueensMirror;

  /// No description provided for @worldArtifactAncientImperialCrownShortBonus.
  ///
  /// In en, this message translates to:
  /// **'+1 defense'**
  String get worldArtifactAncientImperialCrownShortBonus;

  /// No description provided for @worldArtifactAstronomersTabletsShortBonus.
  ///
  /// In en, this message translates to:
  /// **'+1 science'**
  String get worldArtifactAstronomersTabletsShortBonus;

  /// No description provided for @worldArtifactProphetMaskShortBonus.
  ///
  /// In en, this message translates to:
  /// **'+1 gold, diplomacy'**
  String get worldArtifactProphetMaskShortBonus;

  /// No description provided for @worldArtifactHeroSwordShortBonus.
  ///
  /// In en, this message translates to:
  /// **'+2 XP for produced units'**
  String get worldArtifactHeroSwordShortBonus;

  /// No description provided for @worldArtifactMerchantsSealShortBonus.
  ///
  /// In en, this message translates to:
  /// **'+2 gold'**
  String get worldArtifactMerchantsSealShortBonus;

  /// No description provided for @worldArtifactFirstPeoplesChronicleShortBonus.
  ///
  /// In en, this message translates to:
  /// **'+1 food'**
  String get worldArtifactFirstPeoplesChronicleShortBonus;

  /// No description provided for @worldArtifactTempleReliquaryShortBonus.
  ///
  /// In en, this message translates to:
  /// **'+1 food, +1 defense'**
  String get worldArtifactTempleReliquaryShortBonus;

  /// No description provided for @worldArtifactQueensMirrorShortBonus.
  ///
  /// In en, this message translates to:
  /// **'+1 gold, diplomacy'**
  String get worldArtifactQueensMirrorShortBonus;

  /// No description provided for @worldArtifactAncientImperialCrownDescription.
  ///
  /// In en, this message translates to:
  /// **'A symbol of old rule. Once stored in a city, it strengthens defense and the prestige of the collection.'**
  String get worldArtifactAncientImperialCrownDescription;

  /// No description provided for @worldArtifactAstronomersTabletsDescription.
  ///
  /// In en, this message translates to:
  /// **'Stone tablets with ancient maps of the sky. In a city, they support science.'**
  String get worldArtifactAstronomersTabletsDescription;

  /// No description provided for @worldArtifactProphetMaskDescription.
  ///
  /// In en, this message translates to:
  /// **'A ritual mask of great political weight. In a city, it grants gold and diplomatic value.'**
  String get worldArtifactProphetMaskDescription;

  /// No description provided for @worldArtifactHeroSwordDescription.
  ///
  /// In en, this message translates to:
  /// **'The weapon of a legendary commander. Units produced in this city gain extra experience.'**
  String get worldArtifactHeroSwordDescription;

  /// No description provided for @worldArtifactMerchantsSealDescription.
  ///
  /// In en, this message translates to:
  /// **'The mark of the first merchant guilds. In a city, it strengthens gold income.'**
  String get worldArtifactMerchantsSealDescription;

  /// No description provided for @worldArtifactFirstPeoplesChronicleDescription.
  ///
  /// In en, this message translates to:
  /// **'A record of the oldest lineages and borders. In a city, it supports growth.'**
  String get worldArtifactFirstPeoplesChronicleDescription;

  /// No description provided for @worldArtifactTempleReliquaryDescription.
  ///
  /// In en, this message translates to:
  /// **'A sacred reliquary that gives the city stability, food, and defense.'**
  String get worldArtifactTempleReliquaryDescription;

  /// No description provided for @worldArtifactQueensMirrorDescription.
  ///
  /// In en, this message translates to:
  /// **'A court treasure joining trade with diplomacy. In a city, it grants gold and prestige.'**
  String get worldArtifactQueensMirrorDescription;

  /// No description provided for @worldArtifactLocationMap.
  ///
  /// In en, this message translates to:
  /// **'Artifact on the map'**
  String get worldArtifactLocationMap;

  /// No description provided for @worldArtifactLocationExcavation.
  ///
  /// In en, this message translates to:
  /// **'Excavation in progress'**
  String get worldArtifactLocationExcavation;

  /// No description provided for @worldArtifactLocationCarried.
  ///
  /// In en, this message translates to:
  /// **'Carried by a unit'**
  String get worldArtifactLocationCarried;

  /// No description provided for @worldArtifactLocationStored.
  ///
  /// In en, this message translates to:
  /// **'Stored in a city'**
  String get worldArtifactLocationStored;

  /// No description provided for @worldArtifactStepExcavate.
  ///
  /// In en, this message translates to:
  /// **'Excavate'**
  String get worldArtifactStepExcavate;

  /// No description provided for @worldArtifactStepMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get worldArtifactStepMove;

  /// No description provided for @worldArtifactStepStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get worldArtifactStepStore;

  /// No description provided for @artifactGuidanceUnknownCityName.
  ///
  /// In en, this message translates to:
  /// **'a city'**
  String get artifactGuidanceUnknownCityName;

  /// No description provided for @artifactGuidanceStoredTitle.
  ///
  /// In en, this message translates to:
  /// **'Artifact stored'**
  String get artifactGuidanceStoredTitle;

  /// No description provided for @artifactGuidanceStoredBody.
  ///
  /// In en, this message translates to:
  /// **'{artifactName} strengthens {cityName}. Cultural victory needs 6 artifacts in cities for 5 turns.'**
  String artifactGuidanceStoredBody(String artifactName, String cityName);

  /// No description provided for @artifactGuidanceCarriedTitle.
  ///
  /// In en, this message translates to:
  /// **'Artifact carried'**
  String get artifactGuidanceCarriedTitle;

  /// No description provided for @artifactGuidanceCarriedBody.
  ///
  /// In en, this message translates to:
  /// **'The unit carries {artifactName}. Bring it to one of your cities with a free slot and use the store action.'**
  String artifactGuidanceCarriedBody(String artifactName);

  /// No description provided for @artifactGuidanceReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Artifact discovered'**
  String get artifactGuidanceReachedTitle;

  /// No description provided for @artifactGuidanceReachedBody.
  ///
  /// In en, this message translates to:
  /// **'{artifactName} is under the unit. Use the Excavation action to pick it up.'**
  String artifactGuidanceReachedBody(String artifactName);

  /// No description provided for @citySelectionSpecializationLabel.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get citySelectionSpecializationLabel;

  /// No description provided for @fieldImprovementOutsideActiveCity.
  ///
  /// In en, this message translates to:
  /// **'Outside active city'**
  String get fieldImprovementOutsideActiveCity;

  /// No description provided for @fieldImprovementYieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Improvement bonus'**
  String get fieldImprovementYieldTitle;

  /// No description provided for @fieldImprovementYieldTooltip.
  ///
  /// In en, this message translates to:
  /// **'Additional yield from the field improvement.'**
  String get fieldImprovementYieldTooltip;

  /// No description provided for @hexKindIdealCitySite.
  ///
  /// In en, this message translates to:
  /// **'Ideal city site'**
  String get hexKindIdealCitySite;

  /// No description provided for @hexKindGoodCitySite.
  ///
  /// In en, this message translates to:
  /// **'Good city site'**
  String get hexKindGoodCitySite;

  /// No description provided for @hexKindFertileField.
  ///
  /// In en, this message translates to:
  /// **'Fertile field'**
  String get hexKindFertileField;

  /// No description provided for @hexKindFertilePlains.
  ///
  /// In en, this message translates to:
  /// **'Fertile plains'**
  String get hexKindFertilePlains;

  /// No description provided for @hexKindRichPlain.
  ///
  /// In en, this message translates to:
  /// **'Rich plain'**
  String get hexKindRichPlain;

  /// No description provided for @hexKindStrategicBorderland.
  ///
  /// In en, this message translates to:
  /// **'Strategic borderland'**
  String get hexKindStrategicBorderland;

  /// No description provided for @hexKindStrategicField.
  ///
  /// In en, this message translates to:
  /// **'Strategic field'**
  String get hexKindStrategicField;

  /// No description provided for @hexKindDefensivePosition.
  ///
  /// In en, this message translates to:
  /// **'Defensive position'**
  String get hexKindDefensivePosition;

  /// No description provided for @hexKindFertileForest.
  ///
  /// In en, this message translates to:
  /// **'Fertile forest'**
  String get hexKindFertileForest;

  /// No description provided for @hexKindForestBackline.
  ///
  /// In en, this message translates to:
  /// **'Forest backline'**
  String get hexKindForestBackline;

  /// No description provided for @hexKindForestForge.
  ///
  /// In en, this message translates to:
  /// **'Forest forge'**
  String get hexKindForestForge;

  /// No description provided for @hexKindWildLand.
  ///
  /// In en, this message translates to:
  /// **'Wild land'**
  String get hexKindWildLand;

  /// No description provided for @hexKindRichWilds.
  ///
  /// In en, this message translates to:
  /// **'Rich wilds'**
  String get hexKindRichWilds;

  /// No description provided for @hexKindExoticBackline.
  ///
  /// In en, this message translates to:
  /// **'Exotic backline'**
  String get hexKindExoticBackline;

  /// No description provided for @hexKindDifficultStrategicTerrain.
  ///
  /// In en, this message translates to:
  /// **'Difficult strategic terrain'**
  String get hexKindDifficultStrategicTerrain;

  /// No description provided for @hexKindHighGround.
  ///
  /// In en, this message translates to:
  /// **'High ground'**
  String get hexKindHighGround;

  /// No description provided for @hexKindRiverHills.
  ///
  /// In en, this message translates to:
  /// **'River hills'**
  String get hexKindRiverHills;

  /// No description provided for @hexKindIndustrialStronghold.
  ///
  /// In en, this message translates to:
  /// **'Industrial stronghold'**
  String get hexKindIndustrialStronghold;

  /// No description provided for @hexKindRichHills.
  ///
  /// In en, this message translates to:
  /// **'Rich hills'**
  String get hexKindRichHills;

  /// No description provided for @hexKindBarrenLand.
  ///
  /// In en, this message translates to:
  /// **'Barren land'**
  String get hexKindBarrenLand;

  /// No description provided for @hexKindOasis.
  ///
  /// In en, this message translates to:
  /// **'Oasis'**
  String get hexKindOasis;

  /// No description provided for @hexKindTradeOasis.
  ///
  /// In en, this message translates to:
  /// **'Trade oasis'**
  String get hexKindTradeOasis;

  /// No description provided for @hexKindDesertDeposits.
  ///
  /// In en, this message translates to:
  /// **'Desert deposits'**
  String get hexKindDesertDeposits;

  /// No description provided for @hexKindHarshLand.
  ///
  /// In en, this message translates to:
  /// **'Harsh land'**
  String get hexKindHarshLand;

  /// No description provided for @hexKindColdPastures.
  ///
  /// In en, this message translates to:
  /// **'Cold pastures'**
  String get hexKindColdPastures;

  /// No description provided for @hexKindResourceOutpost.
  ///
  /// In en, this message translates to:
  /// **'Resource outpost'**
  String get hexKindResourceOutpost;

  /// No description provided for @hexKindHostileLand.
  ///
  /// In en, this message translates to:
  /// **'Hostile land'**
  String get hexKindHostileLand;

  /// No description provided for @hexKindArcticDeposits.
  ///
  /// In en, this message translates to:
  /// **'Arctic deposits'**
  String get hexKindArcticDeposits;

  /// No description provided for @hexKindCoast.
  ///
  /// In en, this message translates to:
  /// **'Coast'**
  String get hexKindCoast;

  /// No description provided for @hexKindFishingCoast.
  ///
  /// In en, this message translates to:
  /// **'Fishing coast'**
  String get hexKindFishingCoast;

  /// No description provided for @hexKindRichCoast.
  ///
  /// In en, this message translates to:
  /// **'Rich coast'**
  String get hexKindRichCoast;

  /// No description provided for @hexKindRiverPort.
  ///
  /// In en, this message translates to:
  /// **'River port'**
  String get hexKindRiverPort;

  /// No description provided for @hexKindRegionalPortHeart.
  ///
  /// In en, this message translates to:
  /// **'Regional port hub'**
  String get hexKindRegionalPortHeart;

  /// No description provided for @hexKindOpenSea.
  ///
  /// In en, this message translates to:
  /// **'Open sea'**
  String get hexKindOpenSea;

  /// No description provided for @hexKindNaturalBarrier.
  ///
  /// In en, this message translates to:
  /// **'Natural barrier'**
  String get hexKindNaturalBarrier;

  /// No description provided for @hexKindPromisingLand.
  ///
  /// In en, this message translates to:
  /// **'Promising land'**
  String get hexKindPromisingLand;

  /// No description provided for @hexKindWeakLand.
  ///
  /// In en, this message translates to:
  /// **'Weak land'**
  String get hexKindWeakLand;

  /// No description provided for @hexKindOrdinaryLand.
  ///
  /// In en, this message translates to:
  /// **'Ordinary land'**
  String get hexKindOrdinaryLand;

  /// No description provided for @hexKindMapTile.
  ///
  /// In en, this message translates to:
  /// **'Map tile'**
  String get hexKindMapTile;

  /// No description provided for @hexKindIdealCitySiteDescription.
  ///
  /// In en, this message translates to:
  /// **'A high-value settlement tile with food, growth, and expansion pressure already lined up.'**
  String get hexKindIdealCitySiteDescription;

  /// No description provided for @hexKindGoodCitySiteDescription.
  ///
  /// In en, this message translates to:
  /// **'Solid terrain for a city center with enough baseline value to support early growth.'**
  String get hexKindGoodCitySiteDescription;

  /// No description provided for @hexKindFertileFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'River-fed grassland that favors food, population growth, and worker improvements.'**
  String get hexKindFertileFieldDescription;

  /// No description provided for @hexKindFertilePlainsDescription.
  ///
  /// In en, this message translates to:
  /// **'Open plains with river support, useful for balanced food and production.'**
  String get hexKindFertilePlainsDescription;

  /// No description provided for @hexKindRichPlainDescription.
  ///
  /// In en, this message translates to:
  /// **'A valuable open tile with luxury or trade value worth bringing inside borders.'**
  String get hexKindRichPlainDescription;

  /// No description provided for @hexKindStrategicBorderlandDescription.
  ///
  /// In en, this message translates to:
  /// **'Good land with strategic value, useful for expansion before rivals claim it.'**
  String get hexKindStrategicBorderlandDescription;

  /// No description provided for @hexKindStrategicFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'A plains tile tied to strategic resources or pressure on the frontier.'**
  String get hexKindStrategicFieldDescription;

  /// No description provided for @hexKindDefensivePositionDescription.
  ///
  /// In en, this message translates to:
  /// **'Terrain that improves defensive control and helps hold nearby approaches.'**
  String get hexKindDefensivePositionDescription;

  /// No description provided for @hexKindFertileForestDescription.
  ///
  /// In en, this message translates to:
  /// **'A forest with river support, mixing growth potential with natural cover.'**
  String get hexKindFertileForestDescription;

  /// No description provided for @hexKindForestBacklineDescription.
  ///
  /// In en, this message translates to:
  /// **'A safer forest tile that can support growth or hunting-oriented improvements.'**
  String get hexKindForestBacklineDescription;

  /// No description provided for @hexKindForestForgeDescription.
  ///
  /// In en, this message translates to:
  /// **'Forest with industrial resource value, promising for production once improved.'**
  String get hexKindForestForgeDescription;

  /// No description provided for @hexKindWildLandDescription.
  ///
  /// In en, this message translates to:
  /// **'Dense terrain with friction; useful only when you have a clear worker or expansion plan.'**
  String get hexKindWildLandDescription;

  /// No description provided for @hexKindRichWildsDescription.
  ///
  /// In en, this message translates to:
  /// **'Wild terrain with enough fertility or resources to justify careful development.'**
  String get hexKindRichWildsDescription;

  /// No description provided for @hexKindExoticBacklineDescription.
  ///
  /// In en, this message translates to:
  /// **'A jungle or wetland tile carrying luxury value for later borders and trade.'**
  String get hexKindExoticBacklineDescription;

  /// No description provided for @hexKindDifficultStrategicTerrainDescription.
  ///
  /// In en, this message translates to:
  /// **'Hard terrain with strategic resource value; powerful later, awkward early.'**
  String get hexKindDifficultStrategicTerrainDescription;

  /// No description provided for @hexKindHighGroundDescription.
  ///
  /// In en, this message translates to:
  /// **'Hills that favor defense and map control more than fast growth.'**
  String get hexKindHighGroundDescription;

  /// No description provided for @hexKindRiverHillsDescription.
  ///
  /// In en, this message translates to:
  /// **'Hills beside a river, combining defense with better economic potential.'**
  String get hexKindRiverHillsDescription;

  /// No description provided for @hexKindIndustrialStrongholdDescription.
  ///
  /// In en, this message translates to:
  /// **'Hills with industrial resources, a strong production target for a city.'**
  String get hexKindIndustrialStrongholdDescription;

  /// No description provided for @hexKindRichHillsDescription.
  ///
  /// In en, this message translates to:
  /// **'Hills with wealth resources, useful for gold or production-focused expansion.'**
  String get hexKindRichHillsDescription;

  /// No description provided for @hexKindBarrenLandDescription.
  ///
  /// In en, this message translates to:
  /// **'Dry land with little immediate value unless later tech or borders change the plan.'**
  String get hexKindBarrenLandDescription;

  /// No description provided for @hexKindOasisDescription.
  ///
  /// In en, this message translates to:
  /// **'Desert softened by river access, turning weak land into a usable growth tile.'**
  String get hexKindOasisDescription;

  /// No description provided for @hexKindTradeOasisDescription.
  ///
  /// In en, this message translates to:
  /// **'A desert trade pocket that can become valuable with the right improvement.'**
  String get hexKindTradeOasisDescription;

  /// No description provided for @hexKindDesertDepositsDescription.
  ///
  /// In en, this message translates to:
  /// **'Poor settlement land with a strategic deposit that matters more in later eras.'**
  String get hexKindDesertDepositsDescription;

  /// No description provided for @hexKindHarshLandDescription.
  ///
  /// In en, this message translates to:
  /// **'Cold or rough land with limited early economy and slow development.'**
  String get hexKindHarshLandDescription;

  /// No description provided for @hexKindColdPasturesDescription.
  ///
  /// In en, this message translates to:
  /// **'Cold terrain with enough pasture value to support a border city.'**
  String get hexKindColdPasturesDescription;

  /// No description provided for @hexKindResourceOutpostDescription.
  ///
  /// In en, this message translates to:
  /// **'Remote cold land worth claiming mainly for the resource it protects.'**
  String get hexKindResourceOutpostDescription;

  /// No description provided for @hexKindHostileLandDescription.
  ///
  /// In en, this message translates to:
  /// **'Unfriendly ground with weak settlement value and few immediate returns.'**
  String get hexKindHostileLandDescription;

  /// No description provided for @hexKindArcticDepositsDescription.
  ///
  /// In en, this message translates to:
  /// **'Snowy resource land that is hard to use but can matter strategically.'**
  String get hexKindArcticDepositsDescription;

  /// No description provided for @hexKindCoastDescription.
  ///
  /// In en, this message translates to:
  /// **'Coastal land that opens naval access and flexible city growth.'**
  String get hexKindCoastDescription;

  /// No description provided for @hexKindFishingCoastDescription.
  ///
  /// In en, this message translates to:
  /// **'Coast with food value, a strong reason to work or settle near the water.'**
  String get hexKindFishingCoastDescription;

  /// No description provided for @hexKindRichCoastDescription.
  ///
  /// In en, this message translates to:
  /// **'Coastal luxury or trade value worth folding into city borders.'**
  String get hexKindRichCoastDescription;

  /// No description provided for @hexKindRiverPortDescription.
  ///
  /// In en, this message translates to:
  /// **'A river mouth with trade and movement value for a coastal city.'**
  String get hexKindRiverPortDescription;

  /// No description provided for @hexKindRegionalPortHeartDescription.
  ///
  /// In en, this message translates to:
  /// **'A strong coastal center where river and resource value stack together.'**
  String get hexKindRegionalPortHeartDescription;

  /// No description provided for @hexKindOpenSeaDescription.
  ///
  /// In en, this message translates to:
  /// **'Water that is useful for ships and scouting, but not for land settlement.'**
  String get hexKindOpenSeaDescription;

  /// No description provided for @hexKindNaturalBarrierDescription.
  ///
  /// In en, this message translates to:
  /// **'Blocked terrain that shapes movement and defense rather than economy.'**
  String get hexKindNaturalBarrierDescription;

  /// No description provided for @hexKindPromisingLandDescription.
  ///
  /// In en, this message translates to:
  /// **'A generally useful tile with enough value to inspect before moving on.'**
  String get hexKindPromisingLandDescription;

  /// No description provided for @hexKindWeakLandDescription.
  ///
  /// In en, this message translates to:
  /// **'Low-return terrain that rarely deserves early worker time.'**
  String get hexKindWeakLandDescription;

  /// No description provided for @hexKindOrdinaryLandDescription.
  ///
  /// In en, this message translates to:
  /// **'A normal tile with no standout strength, useful when it fits the city plan.'**
  String get hexKindOrdinaryLandDescription;

  /// No description provided for @hexKindMapTileDescription.
  ///
  /// In en, this message translates to:
  /// **'A plain map tile without enough information to make a strong judgment.'**
  String get hexKindMapTileDescription;

  /// No description provided for @hexTagCity.
  ///
  /// In en, this message translates to:
  /// **'City site'**
  String get hexTagCity;

  /// No description provided for @hexTagDefense.
  ///
  /// In en, this message translates to:
  /// **'Defensive position'**
  String get hexTagDefense;

  /// No description provided for @hexTagTrade.
  ///
  /// In en, this message translates to:
  /// **'Trade route'**
  String get hexTagTrade;

  /// No description provided for @hexTagFertile.
  ///
  /// In en, this message translates to:
  /// **'Fertile field'**
  String get hexTagFertile;

  /// No description provided for @hexTagProduction.
  ///
  /// In en, this message translates to:
  /// **'Good production'**
  String get hexTagProduction;

  /// No description provided for @hexTagHostile.
  ///
  /// In en, this message translates to:
  /// **'Hostile land'**
  String get hexTagHostile;

  /// No description provided for @hexTagStrategic.
  ///
  /// In en, this message translates to:
  /// **'Strategic resource'**
  String get hexTagStrategic;

  /// No description provided for @hexTagWater.
  ///
  /// In en, this message translates to:
  /// **'Water passage'**
  String get hexTagWater;

  /// No description provided for @hexRecommendationFoundCity.
  ///
  /// In en, this message translates to:
  /// **'Good development site'**
  String get hexRecommendationFoundCity;

  /// No description provided for @hexRecommendationDefendHere.
  ///
  /// In en, this message translates to:
  /// **'Good defensive position'**
  String get hexRecommendationDefendHere;

  /// No description provided for @hexRecommendationExploitEconomy.
  ///
  /// In en, this message translates to:
  /// **'Worth exploiting'**
  String get hexRecommendationExploitEconomy;

  /// No description provided for @hexRecommendationAvoid.
  ///
  /// In en, this message translates to:
  /// **'Avoid without a plan'**
  String get hexRecommendationAvoid;

  /// No description provided for @hexRecommendationNeutral.
  ///
  /// In en, this message translates to:
  /// **'Inspect before moving'**
  String get hexRecommendationNeutral;

  /// No description provided for @hexRecommendationFoundCityDetail.
  ///
  /// In en, this message translates to:
  /// **'If borders are free, consider founding or steering a settler here.'**
  String get hexRecommendationFoundCityDetail;

  /// No description provided for @hexRecommendationDefendHereDetail.
  ///
  /// In en, this message translates to:
  /// **'Use it to anchor units, protect borders, or cover nearby cities.'**
  String get hexRecommendationDefendHereDetail;

  /// No description provided for @hexRecommendationExploitEconomyDetail.
  ///
  /// In en, this message translates to:
  /// **'Bring it inside borders and assign a worker when the city can benefit.'**
  String get hexRecommendationExploitEconomyDetail;

  /// No description provided for @hexRecommendationAvoidDetail.
  ///
  /// In en, this message translates to:
  /// **'Skip it early unless a resource, route, or military need changes the value.'**
  String get hexRecommendationAvoidDetail;

  /// No description provided for @hexRecommendationNeutralDetail.
  ///
  /// In en, this message translates to:
  /// **'Scout neighboring tiles and compare resources before committing a worker or settler.'**
  String get hexRecommendationNeutralDetail;

  /// No description provided for @selectionActionLockedReason.
  ///
  /// In en, this message translates to:
  /// **'You cannot issue orders now.'**
  String get selectionActionLockedReason;

  /// No description provided for @selectionActionFoundCity.
  ///
  /// In en, this message translates to:
  /// **'Found city'**
  String get selectionActionFoundCity;

  /// No description provided for @selectionActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get selectionActionCancel;

  /// No description provided for @selectionActionCancelAttack.
  ///
  /// In en, this message translates to:
  /// **'Cancel attack'**
  String get selectionActionCancelAttack;

  /// No description provided for @selectionActionCancelWorkerBuild.
  ///
  /// In en, this message translates to:
  /// **'Cancel improvement build'**
  String get selectionActionCancelWorkerBuild;

  /// No description provided for @selectionActionCancelCityFounding.
  ///
  /// In en, this message translates to:
  /// **'Cancel city founding'**
  String get selectionActionCancelCityFounding;

  /// No description provided for @selectionActionCancelAutoExplore.
  ///
  /// In en, this message translates to:
  /// **'Cancel exploration'**
  String get selectionActionCancelAutoExplore;

  /// No description provided for @selectionActionCancelArtifactExcavation.
  ///
  /// In en, this message translates to:
  /// **'Cancel artifact excavation'**
  String get selectionActionCancelArtifactExcavation;

  /// No description provided for @selectionActionCancelTradeRouteSelection.
  ///
  /// In en, this message translates to:
  /// **'Cancel trade route selection'**
  String get selectionActionCancelTradeRouteSelection;

  /// No description provided for @selectionActionCancelMerchantMoveToCity.
  ///
  /// In en, this message translates to:
  /// **'Cancel city travel'**
  String get selectionActionCancelMerchantMoveToCity;

  /// No description provided for @selectionActionCancelCommanderMerge.
  ///
  /// In en, this message translates to:
  /// **'Cancel troop merge'**
  String get selectionActionCancelCommanderMerge;

  /// No description provided for @selectionActionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get selectionActionConfirm;

  /// No description provided for @selectionActionConfirmWithTurns.
  ///
  /// In en, this message translates to:
  /// **'Confirm ({turns})'**
  String selectionActionConfirmWithTurns(String turns);

  /// No description provided for @selectionActionMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get selectionActionMinimize;

  /// No description provided for @selectionActionConfirmAttack.
  ///
  /// In en, this message translates to:
  /// **'Confirm attack'**
  String get selectionActionConfirmAttack;

  /// No description provided for @selectionActionCaptureCity.
  ///
  /// In en, this message translates to:
  /// **'Capture city'**
  String get selectionActionCaptureCity;

  /// No description provided for @selectionActionDestroyCity.
  ///
  /// In en, this message translates to:
  /// **'Destroy city'**
  String get selectionActionDestroyCity;

  /// No description provided for @selectionActionStopFortifying.
  ///
  /// In en, this message translates to:
  /// **'Stop fortifying'**
  String get selectionActionStopFortifying;

  /// No description provided for @selectionActionStopHealing.
  ///
  /// In en, this message translates to:
  /// **'Stop healing'**
  String get selectionActionStopHealing;

  /// No description provided for @selectionActionMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get selectionActionMove;

  /// No description provided for @selectionActionAttack.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get selectionActionAttack;

  /// No description provided for @selectionActionAutoExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get selectionActionAutoExplore;

  /// No description provided for @selectionActionTradeRoute.
  ///
  /// In en, this message translates to:
  /// **'Trade route'**
  String get selectionActionTradeRoute;

  /// No description provided for @selectionActionTradeRouteToCity.
  ///
  /// In en, this message translates to:
  /// **'Trade with {cityName}'**
  String selectionActionTradeRouteToCity(String cityName);

  /// No description provided for @selectionActionMerchantMoveToCity.
  ///
  /// In en, this message translates to:
  /// **'Go to city'**
  String get selectionActionMerchantMoveToCity;

  /// No description provided for @selectionActionMerchantMoveToCityTarget.
  ///
  /// In en, this message translates to:
  /// **'Go to {cityName}'**
  String selectionActionMerchantMoveToCityTarget(String cityName);

  /// No description provided for @selectionActionArmy.
  ///
  /// In en, this message translates to:
  /// **'Army'**
  String get selectionActionArmy;

  /// No description provided for @selectionArmyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No troops'**
  String get selectionArmyEmpty;

  /// No description provided for @selectionTroopDetachTooltip.
  ///
  /// In en, this message translates to:
  /// **'Detach {troop}'**
  String selectionTroopDetachTooltip(String troop);

  /// No description provided for @selectionActionImprove.
  ///
  /// In en, this message translates to:
  /// **'Improve'**
  String get selectionActionImprove;

  /// No description provided for @selectionActionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get selectionActionSkip;

  /// No description provided for @selectionActionFortify.
  ///
  /// In en, this message translates to:
  /// **'Fortify'**
  String get selectionActionFortify;

  /// No description provided for @selectionActionHeal.
  ///
  /// In en, this message translates to:
  /// **'Heal'**
  String get selectionActionHeal;

  /// No description provided for @selectionActionCancelCityGrowth.
  ///
  /// In en, this message translates to:
  /// **'Cancel growth'**
  String get selectionActionCancelCityGrowth;

  /// No description provided for @selectionActionCityGrowth.
  ///
  /// In en, this message translates to:
  /// **'City growth'**
  String get selectionActionCityGrowth;

  /// No description provided for @selectionActionProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get selectionActionProduction;

  /// No description provided for @selectionActionExcavateArtifact.
  ///
  /// In en, this message translates to:
  /// **'Excavate'**
  String get selectionActionExcavateArtifact;

  /// No description provided for @selectionActionStoreArtifact.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get selectionActionStoreArtifact;

  /// No description provided for @selectionActionCancelCurrentMoveFirst.
  ///
  /// In en, this message translates to:
  /// **'Cancel the current move first.'**
  String get selectionActionCancelCurrentMoveFirst;

  /// No description provided for @selectionActionArtifactAlreadyCarried.
  ///
  /// In en, this message translates to:
  /// **'The unit already carries an artifact.'**
  String get selectionActionArtifactAlreadyCarried;

  /// No description provided for @selectionActionStoreArtifactOwnCityRequired.
  ///
  /// In en, this message translates to:
  /// **'Move to one of your cities.'**
  String get selectionActionStoreArtifactOwnCityRequired;

  /// No description provided for @selectionActionStoreArtifactCityOccupied.
  ///
  /// In en, this message translates to:
  /// **'This city already stores an artifact.'**
  String get selectionActionStoreArtifactCityOccupied;

  /// No description provided for @selectionActionNoBuildAvailable.
  ///
  /// In en, this message translates to:
  /// **'No build is available on this tile.'**
  String get selectionActionNoBuildAvailable;

  /// No description provided for @selectionActionUnitWorking.
  ///
  /// In en, this message translates to:
  /// **'The unit is already working.'**
  String get selectionActionUnitWorking;

  /// No description provided for @selectionActionUnitFortified.
  ///
  /// In en, this message translates to:
  /// **'The unit is fortified.'**
  String get selectionActionUnitFortified;

  /// No description provided for @selectionActionUnitHealing.
  ///
  /// In en, this message translates to:
  /// **'The unit is healing.'**
  String get selectionActionUnitHealing;

  /// No description provided for @selectionActionNoMovement.
  ///
  /// In en, this message translates to:
  /// **'No movement points left this turn.'**
  String get selectionActionNoMovement;

  /// No description provided for @selectionActionNoAttack.
  ///
  /// In en, this message translates to:
  /// **'This unit has no attack.'**
  String get selectionActionNoAttack;

  /// No description provided for @selectionActionNoVisibleEnemy.
  ///
  /// In en, this message translates to:
  /// **'No visible enemy in range.'**
  String get selectionActionNoVisibleEnemy;

  /// No description provided for @selectionActionMerchantNoOriginCity.
  ///
  /// In en, this message translates to:
  /// **'Move the merchant into one of your cities.'**
  String get selectionActionMerchantNoOriginCity;

  /// No description provided for @selectionActionMerchantNoDestinationCity.
  ///
  /// In en, this message translates to:
  /// **'You need another connected city.'**
  String get selectionActionMerchantNoDestinationCity;

  /// No description provided for @selectionActionMerchantNoRoute.
  ///
  /// In en, this message translates to:
  /// **'No trade route can reach this city.'**
  String get selectionActionMerchantNoRoute;

  /// No description provided for @selectionActionMerchantNoCityPath.
  ///
  /// In en, this message translates to:
  /// **'The merchant cannot reach this city.'**
  String get selectionActionMerchantNoCityPath;

  /// No description provided for @selectionActionCannotFoundCityHere.
  ///
  /// In en, this message translates to:
  /// **'Cannot found a city here.'**
  String get selectionActionCannotFoundCityHere;

  /// No description provided for @selectionActionFoundCityNoCommander.
  ///
  /// In en, this message translates to:
  /// **'Only a settler or a commander with settlers can found a city.'**
  String get selectionActionFoundCityNoCommander;

  /// No description provided for @selectionActionFoundCityNoSettlers.
  ///
  /// In en, this message translates to:
  /// **'Settlers are required to found a city.'**
  String get selectionActionFoundCityNoSettlers;

  /// No description provided for @selectionActionFoundCityInvalidCenter.
  ///
  /// In en, this message translates to:
  /// **'A city cannot be founded on this tile.'**
  String get selectionActionFoundCityInvalidCenter;

  /// No description provided for @selectionActionFoundCityCityAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'There is already a city on this tile.'**
  String get selectionActionFoundCityCityAlreadyExists;

  /// No description provided for @selectionActionFoundCityCenterOccupied.
  ///
  /// In en, this message translates to:
  /// **'This tile already belongs to a city.'**
  String get selectionActionFoundCityCenterOccupied;

  /// No description provided for @selectionActionFoundCityTooCloseToCity.
  ///
  /// In en, this message translates to:
  /// **'A city cannot be adjacent to another city.'**
  String get selectionActionFoundCityTooCloseToCity;

  /// No description provided for @selectionActionFoundCityInvalidControlledHexes.
  ///
  /// In en, this message translates to:
  /// **'Choose valid city tiles first.'**
  String get selectionActionFoundCityInvalidControlledHexes;

  /// No description provided for @selectionActionCannotImproveCityCenter.
  ///
  /// In en, this message translates to:
  /// **'Cannot build improvements on the city center.'**
  String get selectionActionCannotImproveCityCenter;

  /// No description provided for @selectionActionTileAlreadyImproved.
  ///
  /// In en, this message translates to:
  /// **'This tile already has an improvement.'**
  String get selectionActionTileAlreadyImproved;

  /// No description provided for @selectionActionTileMustBelongToCity.
  ///
  /// In en, this message translates to:
  /// **'The tile must belong to a city.'**
  String get selectionActionTileMustBelongToCity;

  /// No description provided for @selectionActionNoWorkerTile.
  ///
  /// In en, this message translates to:
  /// **'No tile under the worker.'**
  String get selectionActionNoWorkerTile;

  /// No description provided for @hudFeedbackNoTurnCostDetail.
  ///
  /// In en, this message translates to:
  /// **'Action did not consume the turn'**
  String get hudFeedbackNoTurnCostDetail;

  /// No description provided for @hudFeedbackAutoExploreNoTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'No exploration route'**
  String get hudFeedbackAutoExploreNoTargetTitle;

  /// No description provided for @hudFeedbackAutoExploreNoTargetBody.
  ///
  /// In en, this message translates to:
  /// **'The scout has no move that would reveal new tiles this turn.'**
  String get hudFeedbackAutoExploreNoTargetBody;

  /// No description provided for @hudFeedbackArtifactGuidanceTitle.
  ///
  /// In en, this message translates to:
  /// **'World artifact'**
  String get hudFeedbackArtifactGuidanceTitle;

  /// No description provided for @hudFeedbackArtifactGuidanceBody.
  ///
  /// In en, this message translates to:
  /// **'Deliver it to one of your cities and place it in an empty artifact slot.'**
  String get hudFeedbackArtifactGuidanceBody;

  /// No description provided for @hudFeedbackActionBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Action unavailable'**
  String get hudFeedbackActionBlockedTitle;

  /// No description provided for @hudFeedbackActionBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'This action is blocked right now. Choose another tile or another command.'**
  String get hudFeedbackActionBlockedBody;

  /// No description provided for @hudFeedbackAttackProtectedByTreatyTitle.
  ///
  /// In en, this message translates to:
  /// **'Treaty blocks attack'**
  String get hudFeedbackAttackProtectedByTreatyTitle;

  /// No description provided for @hudFeedbackAttackProtectedByTreatyBody.
  ///
  /// In en, this message translates to:
  /// **'You cannot attack a unit from a civilization that has an alliance or a truce with you. Change diplomatic relations first.'**
  String get hudFeedbackAttackProtectedByTreatyBody;

  /// No description provided for @hudFeedbackMovementCityOccupiedTitle.
  ///
  /// In en, this message translates to:
  /// **'City occupied'**
  String get hudFeedbackMovementCityOccupiedTitle;

  /// No description provided for @hudFeedbackMovementCityOccupiedBody.
  ///
  /// In en, this message translates to:
  /// **'Only one unit can stand in a city. Move the garrison out first or choose another tile.'**
  String get hudFeedbackMovementCityOccupiedBody;

  /// No description provided for @hudFeedbackMovementEnemyOccupiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Enemy on this tile'**
  String get hudFeedbackMovementEnemyOccupiedTitle;

  /// No description provided for @hudFeedbackMovementEnemyOccupiedBody.
  ///
  /// In en, this message translates to:
  /// **'You cannot enter an enemy tile with a normal move. Use Attack or choose an adjacent tile.'**
  String get hudFeedbackMovementEnemyOccupiedBody;

  /// No description provided for @hudFeedbackMovementForeignCityTitle.
  ///
  /// In en, this message translates to:
  /// **'Foreign city'**
  String get hudFeedbackMovementForeignCityTitle;

  /// No description provided for @hudFeedbackMovementForeignCityBody.
  ///
  /// In en, this message translates to:
  /// **'You cannot enter a foreign city with a normal move. Use Attack or choose another tile.'**
  String get hudFeedbackMovementForeignCityBody;

  /// No description provided for @hudFeedbackMovementHiddenRouteTooFarTitle.
  ///
  /// In en, this message translates to:
  /// **'Route too far'**
  String get hudFeedbackMovementHiddenRouteTooFarTitle;

  /// No description provided for @hudFeedbackMovementHiddenRouteTooFarBody.
  ///
  /// In en, this message translates to:
  /// **'You cannot plot such a long route through undiscovered terrain. Pick a shorter segment or use scout auto-exploration.'**
  String get hudFeedbackMovementHiddenRouteTooFarBody;

  /// No description provided for @hudFeedbackMovementBlockedTerrainTitle.
  ///
  /// In en, this message translates to:
  /// **'Terrain blocks movement'**
  String get hudFeedbackMovementBlockedTerrainTitle;

  /// No description provided for @hudFeedbackMovementBlockedTerrainBody.
  ///
  /// In en, this message translates to:
  /// **'This unit cannot enter that terrain type. Choose another tile or a route around it.'**
  String get hudFeedbackMovementBlockedTerrainBody;

  /// No description provided for @hudFeedbackMovementInsufficientUnitMovementTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough movement'**
  String get hudFeedbackMovementInsufficientUnitMovementTitle;

  /// No description provided for @hudFeedbackMovementInsufficientUnitMovementBody.
  ///
  /// In en, this message translates to:
  /// **'This unit does not have enough movement to enter that area. Upgrade it or use another unit.'**
  String get hudFeedbackMovementInsufficientUnitMovementBody;

  /// No description provided for @hudFeedbackMovementNoRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'No route'**
  String get hudFeedbackMovementNoRouteTitle;

  /// No description provided for @hudFeedbackMovementNoRouteBody.
  ///
  /// In en, this message translates to:
  /// **'There is no available route to that tile. Try a closer target or another approach.'**
  String get hudFeedbackMovementNoRouteBody;

  /// No description provided for @selectionCommandUnavailableDescription.
  ///
  /// In en, this message translates to:
  /// **'Action \"{label}\" is unavailable for the current selection.'**
  String selectionCommandUnavailableDescription(String label);

  /// No description provided for @selectionCommandActiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Action \"{label}\" is an active mode. Choose a target on the map or cancel the mode if you changed your mind.'**
  String selectionCommandActiveDescription(String label);

  /// No description provided for @selectionCommandProminentDescription.
  ///
  /// In en, this message translates to:
  /// **'Action \"{label}\" is currently the most important command for this selection.'**
  String selectionCommandProminentDescription(String label);

  /// No description provided for @selectionCommandDefaultDescription.
  ///
  /// In en, this message translates to:
  /// **'Runs action \"{label}\" for the currently selected unit, city, or tile.'**
  String selectionCommandDefaultDescription(String label);

  /// No description provided for @selectionInfoChipDisabledDescription.
  ///
  /// In en, this message translates to:
  /// **'This information panel is not available for the current selection.'**
  String get selectionInfoChipDisabledDescription;

  /// No description provided for @selectionInfoChipOpenDescription.
  ///
  /// In en, this message translates to:
  /// **'Opens \"{label}\" details for the currently selected tile, unit, or city.'**
  String selectionInfoChipOpenDescription(String label);

  /// No description provided for @turnCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 turns} =1{1 turn} other{{count} turns}}'**
  String turnCountLabel(int count);

  /// No description provided for @turnPillLabel.
  ///
  /// In en, this message translates to:
  /// **'T{turn}'**
  String turnPillLabel(int turn);

  /// No description provided for @turnEtaNoProgress.
  ///
  /// In en, this message translates to:
  /// **'no progress'**
  String get turnEtaNoProgress;

  /// No description provided for @turnEtaDetailLabel.
  ///
  /// In en, this message translates to:
  /// **'{turnsLabel} • turn {turn}'**
  String turnEtaDetailLabel(String turnsLabel, int turn);

  /// No description provided for @turnEtaTooltipNoTurn.
  ///
  /// In en, this message translates to:
  /// **'{turnsLabel} to complete'**
  String turnEtaTooltipNoTurn(String turnsLabel);

  /// No description provided for @turnEtaTooltipExpectedTurn.
  ///
  /// In en, this message translates to:
  /// **'{turnsLabel} to complete • expected turn {turn}'**
  String turnEtaTooltipExpectedTurn(String turnsLabel, int turn);

  /// No description provided for @modeBannerWorkedTilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Worked tiles'**
  String get modeBannerWorkedTilesTitle;

  /// No description provided for @modeBannerWorkedTilesInstruction.
  ///
  /// In en, this message translates to:
  /// **'Tap controlled tiles to toggle city work.'**
  String get modeBannerWorkedTilesInstruction;

  /// No description provided for @modeBannerCityGrowthTitle.
  ///
  /// In en, this message translates to:
  /// **'City growth'**
  String get modeBannerCityGrowthTitle;

  /// No description provided for @modeBannerCityGrowthInstructionSelected.
  ///
  /// In en, this message translates to:
  /// **'The selected tile will be claimed on the next city growth. Confirm it or choose another tile.'**
  String get modeBannerCityGrowthInstructionSelected;

  /// No description provided for @modeBannerCityGrowthInstructionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tap an outlined tile to choose the next growth hex. Without a choice, the city will use its recommendation.'**
  String get modeBannerCityGrowthInstructionEmpty;

  /// No description provided for @modeBannerWorkerActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Tile improvement'**
  String get modeBannerWorkerActionTitle;

  /// No description provided for @modeBannerWorkerActionInstructionPicked.
  ///
  /// In en, this message translates to:
  /// **'Confirm the improvement in the worker popup.'**
  String get modeBannerWorkerActionInstructionPicked;

  /// No description provided for @modeBannerWorkerActionInstructionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Choose an improvement type in the worker popup.'**
  String get modeBannerWorkerActionInstructionEmpty;

  /// No description provided for @modeBannerMerchantTradeRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Trade route'**
  String get modeBannerMerchantTradeRouteTitle;

  /// No description provided for @modeBannerMerchantTradeRouteInstruction.
  ///
  /// In en, this message translates to:
  /// **'Choose one of your cities. The merchant will travel there automatically and turn back after arrival.'**
  String get modeBannerMerchantTradeRouteInstruction;

  /// No description provided for @modeBannerMerchantMoveToCityTitle.
  ///
  /// In en, this message translates to:
  /// **'Go to city'**
  String get modeBannerMerchantMoveToCityTitle;

  /// No description provided for @modeBannerMerchantMoveToCityInstruction.
  ///
  /// In en, this message translates to:
  /// **'Choose one of your cities. The merchant will plot a path to its center without creating a trade route.'**
  String get modeBannerMerchantMoveToCityInstruction;

  /// No description provided for @workerActionSelectedImprovement.
  ///
  /// In en, this message translates to:
  /// **'Selected: {title}'**
  String workerActionSelectedImprovement(String title);

  /// No description provided for @workerActionSelectImprovement.
  ///
  /// In en, this message translates to:
  /// **'Choose improvement'**
  String get workerActionSelectImprovement;

  /// No description provided for @workerActionBuildDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Tile improvement'**
  String get workerActionBuildDetailTitle;

  /// No description provided for @workerActionBuildImprovement.
  ///
  /// In en, this message translates to:
  /// **'Build {title}'**
  String workerActionBuildImprovement(String title);

  /// No description provided for @workerActionSelectionHint.
  ///
  /// In en, this message translates to:
  /// **'Click an improvement for this tile, inspect yields, and confirm the build.'**
  String get workerActionSelectionHint;

  /// No description provided for @workerActionNoYieldChange.
  ///
  /// In en, this message translates to:
  /// **'no yield change'**
  String get workerActionNoYieldChange;

  /// No description provided for @modeBannerResearchSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose research'**
  String get modeBannerResearchSelectionTitle;

  /// No description provided for @modeBannerResearchSelectionInstruction.
  ///
  /// In en, this message translates to:
  /// **'Open the technology tree and choose a research target to continue the turn.'**
  String get modeBannerResearchSelectionInstruction;

  /// No description provided for @modeBannerUnitTurnSkipTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn skipped'**
  String get modeBannerUnitTurnSkipTitle;

  /// No description provided for @modeBannerUnitTurnSkipInstruction.
  ///
  /// In en, this message translates to:
  /// **'The unit waits until the next turn. Its state is visible in the bottom bar.'**
  String get modeBannerUnitTurnSkipInstruction;

  /// No description provided for @modeBannerCommanderMergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge troops'**
  String get modeBannerCommanderMergeTitle;

  /// No description provided for @modeBannerCommanderMergeInstruction.
  ///
  /// In en, this message translates to:
  /// **'Select a friendly unit for the commander to add to the army.'**
  String get modeBannerCommanderMergeInstruction;

  /// No description provided for @modeBannerAttackTargetingTitle.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get modeBannerAttackTargetingTitle;

  /// No description provided for @modeBannerAttackTargetingInstructionSelected.
  ///
  /// In en, this message translates to:
  /// **'Check the combat forecast in the popup and confirm the attack.'**
  String get modeBannerAttackTargetingInstructionSelected;

  /// No description provided for @modeBannerAttackTargetingInstructionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Select an enemy in range or its hex to see the combat forecast.'**
  String get modeBannerAttackTargetingInstructionEmpty;

  /// No description provided for @modeBannerAttackRetreatProgress.
  ///
  /// In en, this message translates to:
  /// **'Retreat'**
  String get modeBannerAttackRetreatProgress;

  /// No description provided for @modeBannerActionToolbarHint.
  ///
  /// In en, this message translates to:
  /// **'Use the bottom toolbar for actions when you need them.'**
  String get modeBannerActionToolbarHint;

  /// No description provided for @combatPreviewConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The selected unit will attack immediately after confirmation.'**
  String get combatPreviewConfirmBody;

  /// No description provided for @combatPreviewOutcomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get combatPreviewOutcomeLabel;

  /// No description provided for @combatPreviewTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get combatPreviewTargetLabel;

  /// No description provided for @combatPreviewRetaliationLabel.
  ///
  /// In en, this message translates to:
  /// **'Retaliation'**
  String get combatPreviewRetaliationLabel;

  /// No description provided for @combatPreviewStrengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get combatPreviewStrengthLabel;

  /// No description provided for @combatPreviewAttackerRole.
  ///
  /// In en, this message translates to:
  /// **'Attacker'**
  String get combatPreviewAttackerRole;

  /// No description provided for @combatPreviewDefenderRole.
  ///
  /// In en, this message translates to:
  /// **'Defender'**
  String get combatPreviewDefenderRole;

  /// No description provided for @combatPreviewCityRole.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get combatPreviewCityRole;

  /// No description provided for @combatPreviewOutcomeLine.
  ///
  /// In en, this message translates to:
  /// **'Outcome: {outcome}'**
  String combatPreviewOutcomeLine(String outcome);

  /// No description provided for @combatPreviewOutcomeCityFalls.
  ///
  /// In en, this message translates to:
  /// **'city falls'**
  String get combatPreviewOutcomeCityFalls;

  /// No description provided for @combatPreviewOutcomeDefenderKilled.
  ///
  /// In en, this message translates to:
  /// **'defender dies'**
  String get combatPreviewOutcomeDefenderKilled;

  /// No description provided for @combatPreviewOutcomeAttackerKilled.
  ///
  /// In en, this message translates to:
  /// **'attacker dies in retaliation'**
  String get combatPreviewOutcomeAttackerKilled;

  /// No description provided for @combatPreviewOutcomeDefenderRetreated.
  ///
  /// In en, this message translates to:
  /// **'defender will retreat'**
  String get combatPreviewOutcomeDefenderRetreated;

  /// No description provided for @combatPreviewOutcomeCitySurvives.
  ///
  /// In en, this message translates to:
  /// **'city survives'**
  String get combatPreviewOutcomeCitySurvives;

  /// No description provided for @combatPreviewOutcomeDefenderSurvives.
  ///
  /// In en, this message translates to:
  /// **'defender survives'**
  String get combatPreviewOutcomeDefenderSurvives;

  /// No description provided for @combatPreviewTargetLine.
  ///
  /// In en, this message translates to:
  /// **'Target: HP {hpBefore}->{hpAfter}/{hpMax}, Attack {attack} vs Defense {defense} (-{damage})'**
  String combatPreviewTargetLine(
    int hpBefore,
    int hpAfter,
    int hpMax,
    int attack,
    int defense,
    int damage,
  );

  /// No description provided for @combatPreviewNoRetaliationLine.
  ///
  /// In en, this message translates to:
  /// **'Retaliation: none (ranged attack, distance {distance}, range {range})'**
  String combatPreviewNoRetaliationLine(int distance, int range);

  /// No description provided for @combatPreviewRetaliationLine.
  ///
  /// In en, this message translates to:
  /// **'Retaliation: Attack {attack} vs Defense {defense} (-{damage}), HP {hpBefore}->{hpAfter}/{hpMax}'**
  String combatPreviewRetaliationLine(
    int attack,
    int defense,
    int damage,
    int hpBefore,
    int hpAfter,
    int hpMax,
  );

  /// No description provided for @combatPreviewHpDamageValue.
  ///
  /// In en, this message translates to:
  /// **'{hpBefore} → {hpAfter}/{hpMax} HP, -{damage}'**
  String combatPreviewHpDamageValue(
    int hpBefore,
    int hpAfter,
    int hpMax,
    int damage,
  );

  /// No description provided for @combatPreviewForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Combat forecast'**
  String get combatPreviewForecastTitle;

  /// No description provided for @combatPreviewNoHpLoss.
  ///
  /// In en, this message translates to:
  /// **'no damage'**
  String get combatPreviewNoHpLoss;

  /// No description provided for @combatPreviewHpAfterSemantics.
  ///
  /// In en, this message translates to:
  /// **'{hpAfter} of {hpMax} HP after combat, {loss} HP lost'**
  String combatPreviewHpAfterSemantics(int hpAfter, int hpMax, int loss);

  /// No description provided for @combatPreviewStrengthValue.
  ///
  /// In en, this message translates to:
  /// **'{attack} attack vs {defense} defense'**
  String combatPreviewStrengthValue(int attack, int defense);

  /// No description provided for @combatPreviewAdvantageTitle.
  ///
  /// In en, this message translates to:
  /// **'Why this forecast?'**
  String get combatPreviewAdvantageTitle;

  /// No description provided for @combatPreviewAdvantageAttacker.
  ///
  /// In en, this message translates to:
  /// **'Attack advantage: {country} has {attack} attack against {defense} defense; the target loses about {damage} HP.'**
  String combatPreviewAdvantageAttacker(
    String country,
    int attack,
    int defense,
    int damage,
  );

  /// No description provided for @combatPreviewAdvantageDefender.
  ///
  /// In en, this message translates to:
  /// **'Defense advantage: {country} has {defense} defense against {attack} attack; the hit deals about {damage} HP.'**
  String combatPreviewAdvantageDefender(
    String country,
    int attack,
    int defense,
    int damage,
  );

  /// No description provided for @combatPreviewAdvantageEven.
  ///
  /// In en, this message translates to:
  /// **'Even fight: {attack} attack against {defense} defense; forecast damage is about {damage} HP.'**
  String combatPreviewAdvantageEven(int attack, int defense, int damage);

  /// No description provided for @combatPreviewTerrainLine.
  ///
  /// In en, this message translates to:
  /// **'Positions: {attackerCountry} attacks from {attackerTerrain}. {defenderCountry} defends on {defenderTerrain}.'**
  String combatPreviewTerrainLine(
    String attackerCountry,
    String attackerTerrain,
    String defenderCountry,
    String defenderTerrain,
  );

  /// No description provided for @combatPreviewSourcesLine.
  ///
  /// In en, this message translates to:
  /// **'The edge comes from: {sources}.'**
  String combatPreviewSourcesLine(String sources);

  /// No description provided for @combatPreviewPositiveSourcesLine.
  ///
  /// In en, this message translates to:
  /// **'Helps the attack ({attackerCountry}): {sources}.'**
  String combatPreviewPositiveSourcesLine(
    String attackerCountry,
    String sources,
  );

  /// No description provided for @combatPreviewNegativeSourcesLine.
  ///
  /// In en, this message translates to:
  /// **'Helps the defense ({defenderCountry}): {sources}.'**
  String combatPreviewNegativeSourcesLine(
    String defenderCountry,
    String sources,
  );

  /// No description provided for @combatPreviewNoSourcesLine.
  ///
  /// In en, this message translates to:
  /// **'No modifiers apply: base unit stats and the combat result decide this forecast.'**
  String get combatPreviewNoSourcesLine;

  /// No description provided for @combatPreviewNoRetaliationReason.
  ///
  /// In en, this message translates to:
  /// **'No retaliation: this is a ranged attack (distance {distance}, attack range {range}).'**
  String combatPreviewNoRetaliationReason(int distance, int range);

  /// No description provided for @combatPreviewNoRetaliationDefenderDefeated.
  ///
  /// In en, this message translates to:
  /// **'No retaliation: the target is defeated before it can answer.'**
  String get combatPreviewNoRetaliationDefenderDefeated;

  /// No description provided for @combatPreviewNoRetaliationDefenderRetreats.
  ///
  /// In en, this message translates to:
  /// **'No retaliation: the target retreats after the hit.'**
  String get combatPreviewNoRetaliationDefenderRetreats;

  /// No description provided for @combatPreviewNoRetaliationNoAttack.
  ///
  /// In en, this message translates to:
  /// **'No retaliation: the target has no attack strength in this forecast.'**
  String get combatPreviewNoRetaliationNoAttack;

  /// No description provided for @combatPreviewRetaliationRisk.
  ///
  /// In en, this message translates to:
  /// **'Retaliation: {defenderCountry} answers and {attackerCountry} loses about {damage} HP.'**
  String combatPreviewRetaliationRisk(
    String defenderCountry,
    String attackerCountry,
    int damage,
  );

  /// No description provided for @combatPreviewSourceAttackTerrain.
  ///
  /// In en, this message translates to:
  /// **'attacker terrain'**
  String get combatPreviewSourceAttackTerrain;

  /// No description provided for @combatPreviewSourceDefenseTerrain.
  ///
  /// In en, this message translates to:
  /// **'defender terrain'**
  String get combatPreviewSourceDefenseTerrain;

  /// No description provided for @combatPreviewSourceTechnology.
  ///
  /// In en, this message translates to:
  /// **'technology'**
  String get combatPreviewSourceTechnology;

  /// No description provided for @combatPreviewSourceVeterancy.
  ///
  /// In en, this message translates to:
  /// **'experience'**
  String get combatPreviewSourceVeterancy;

  /// No description provided for @combatPreviewSourceCityGarrison.
  ///
  /// In en, this message translates to:
  /// **'city garrison'**
  String get combatPreviewSourceCityGarrison;

  /// No description provided for @combatPreviewSourceMixedArmy.
  ///
  /// In en, this message translates to:
  /// **'unit composition'**
  String get combatPreviewSourceMixedArmy;

  /// No description provided for @combatCounterSpearmanVsMountedAttack.
  ///
  /// In en, this message translates to:
  /// **'spearmen against mounted units'**
  String get combatCounterSpearmanVsMountedAttack;

  /// No description provided for @combatCounterSpearmanVsMountedDefense.
  ///
  /// In en, this message translates to:
  /// **'spearmen holding against mounted units'**
  String get combatCounterSpearmanVsMountedDefense;

  /// No description provided for @combatCounterArcherDefensiveTerrainDefense.
  ///
  /// In en, this message translates to:
  /// **'archers in defensive terrain'**
  String get combatCounterArcherDefensiveTerrainDefense;

  /// No description provided for @combatCounterCavalryRoughAttack.
  ///
  /// In en, this message translates to:
  /// **'cavalry slowed by rough terrain'**
  String get combatCounterCavalryRoughAttack;

  /// No description provided for @combatCounterCavalryOpenRaid.
  ///
  /// In en, this message translates to:
  /// **'cavalry raid on open terrain'**
  String get combatCounterCavalryOpenRaid;

  /// No description provided for @combatCounterHeavyInfantryBreakthrough.
  ///
  /// In en, this message translates to:
  /// **'heavy infantry breaking the line'**
  String get combatCounterHeavyInfantryBreakthrough;

  /// No description provided for @terrainOcean.
  ///
  /// In en, this message translates to:
  /// **'ocean'**
  String get terrainOcean;

  /// No description provided for @terrainCoast.
  ///
  /// In en, this message translates to:
  /// **'coast'**
  String get terrainCoast;

  /// No description provided for @terrainLake.
  ///
  /// In en, this message translates to:
  /// **'lake'**
  String get terrainLake;

  /// No description provided for @terrainPlains.
  ///
  /// In en, this message translates to:
  /// **'plains'**
  String get terrainPlains;

  /// No description provided for @terrainGrassland.
  ///
  /// In en, this message translates to:
  /// **'grassland'**
  String get terrainGrassland;

  /// No description provided for @terrainDesert.
  ///
  /// In en, this message translates to:
  /// **'desert'**
  String get terrainDesert;

  /// No description provided for @terrainTundra.
  ///
  /// In en, this message translates to:
  /// **'tundra'**
  String get terrainTundra;

  /// No description provided for @terrainSnow.
  ///
  /// In en, this message translates to:
  /// **'snow'**
  String get terrainSnow;

  /// No description provided for @terrainMountain.
  ///
  /// In en, this message translates to:
  /// **'mountains'**
  String get terrainMountain;

  /// No description provided for @terrainHills.
  ///
  /// In en, this message translates to:
  /// **'hills'**
  String get terrainHills;

  /// No description provided for @terrainWetlands.
  ///
  /// In en, this message translates to:
  /// **'wetlands'**
  String get terrainWetlands;

  /// No description provided for @terrainJungle.
  ///
  /// In en, this message translates to:
  /// **'jungle'**
  String get terrainJungle;

  /// No description provided for @terrainForest.
  ///
  /// In en, this message translates to:
  /// **'forest'**
  String get terrainForest;

  /// No description provided for @terrainRiver.
  ///
  /// In en, this message translates to:
  /// **'river'**
  String get terrainRiver;

  /// No description provided for @modeBannerMoveTargetingTitle.
  ///
  /// In en, this message translates to:
  /// **'Movement mode'**
  String get modeBannerMoveTargetingTitle;

  /// No description provided for @modeBannerMoveTargetingInstruction.
  ///
  /// In en, this message translates to:
  /// **'The first tap on a hex plots the route. Tap the same hex again to move; a longer route is queued for future turns.'**
  String get modeBannerMoveTargetingInstruction;

  /// No description provided for @modeBannerMoveTargetingCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Exit movement'**
  String get modeBannerMoveTargetingCancelAction;

  /// No description provided for @modeBannerWorkerFindTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Worker: find a tile'**
  String get modeBannerWorkerFindTileTitle;

  /// No description provided for @modeBannerWorkerFindTileInstruction.
  ///
  /// In en, this message translates to:
  /// **'{reason} Move the worker to one of your city tiles without an improvement, or to terrain that matches an unlocked build.'**
  String modeBannerWorkerFindTileInstruction(String reason);

  /// No description provided for @modeBannerWorkerFindTileDetailOwnCity.
  ///
  /// In en, this message translates to:
  /// **'Own city tile'**
  String get modeBannerWorkerFindTileDetailOwnCity;

  /// No description provided for @modeBannerWorkerFindTileDetailNoImprovement.
  ///
  /// In en, this message translates to:
  /// **'No improvement'**
  String get modeBannerWorkerFindTileDetailNoImprovement;

  /// No description provided for @modeBannerWorkerFindTileDetailMatchingTerrain.
  ///
  /// In en, this message translates to:
  /// **'Matching terrain'**
  String get modeBannerWorkerFindTileDetailMatchingTerrain;

  /// No description provided for @modeBannerWorkerImproveTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Worker: improve tile'**
  String get modeBannerWorkerImproveTileTitle;

  /// No description provided for @modeBannerWorkerImproveTileInstruction.
  ///
  /// In en, this message translates to:
  /// **'This tile can be improved. If you want to act, use the bottom toolbar, choose the best build, and confirm it in the bottom panel.'**
  String get modeBannerWorkerImproveTileInstruction;

  /// No description provided for @modeBannerWorkerImproveTileDetailYields.
  ///
  /// In en, this message translates to:
  /// **'Increases tile yields'**
  String get modeBannerWorkerImproveTileDetailYields;

  /// No description provided for @modeBannerWorkerImproveTileDetailMovement.
  ///
  /// In en, this message translates to:
  /// **'Uses movement'**
  String get modeBannerWorkerImproveTileDetailMovement;

  /// No description provided for @modeBannerScoutExploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Scout: explore'**
  String get modeBannerScoutExploreTitle;

  /// No description provided for @modeBannerScoutExploreInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enable exploration from the bottom toolbar so the scout discovers the nearest unknown tiles automatically. You can cancel it later from unit actions.'**
  String get modeBannerScoutExploreInstruction;

  /// No description provided for @modeBannerScoutExploreDetailAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto exploration'**
  String get modeBannerScoutExploreDetailAuto;

  /// No description provided for @modeBannerScoutExploreDetailReveal.
  ///
  /// In en, this message translates to:
  /// **'Reveals the map'**
  String get modeBannerScoutExploreDetailReveal;

  /// No description provided for @modeBannerSettlerFindSiteTitle.
  ///
  /// In en, this message translates to:
  /// **'Settler: find a site'**
  String get modeBannerSettlerFindSiteTitle;

  /// No description provided for @modeBannerSettlerFindSiteInstruction.
  ///
  /// In en, this message translates to:
  /// **'{reason} Move the settler to a free tile outside city borders; avoid water, mountains, and occupied centers.'**
  String modeBannerSettlerFindSiteInstruction(String reason);

  /// No description provided for @modeBannerSettlerFindSiteDetailFreeHex.
  ///
  /// In en, this message translates to:
  /// **'Free hex'**
  String get modeBannerSettlerFindSiteDetailFreeHex;

  /// No description provided for @modeBannerSettlerFindSiteDetailOutsideBorders.
  ///
  /// In en, this message translates to:
  /// **'Outside borders'**
  String get modeBannerSettlerFindSiteDetailOutsideBorders;

  /// No description provided for @modeBannerSettlerFindSiteDetailLandOrCoast.
  ///
  /// In en, this message translates to:
  /// **'Land or coast'**
  String get modeBannerSettlerFindSiteDetailLandOrCoast;

  /// No description provided for @modeBannerSettlerFoundCityTitle.
  ///
  /// In en, this message translates to:
  /// **'Settler: found city'**
  String get modeBannerSettlerFoundCityTitle;

  /// No description provided for @modeBannerSettlerFoundCityInstruction.
  ///
  /// In en, this message translates to:
  /// **'This tile can become a city. If you want to found one, use the bottom toolbar, then choose the city\'s starting tiles on the map.'**
  String get modeBannerSettlerFoundCityInstruction;

  /// No description provided for @modeBannerSettlerFoundCityDetailNewCity.
  ///
  /// In en, this message translates to:
  /// **'New city'**
  String get modeBannerSettlerFoundCityDetailNewCity;

  /// No description provided for @modeBannerSettlerFoundCityDetailChooseTiles.
  ///
  /// In en, this message translates to:
  /// **'Choose tiles after tapping'**
  String get modeBannerSettlerFoundCityDetailChooseTiles;

  /// No description provided for @modeBannerCityFoundingTitle.
  ///
  /// In en, this message translates to:
  /// **'Founding a city'**
  String get modeBannerCityFoundingTitle;

  /// No description provided for @modeBannerCityFoundingInstructionReady.
  ///
  /// In en, this message translates to:
  /// **'Ready. Confirm founding the city in the bottom toolbar or change the selected tiles on the map.'**
  String get modeBannerCityFoundingInstructionReady;

  /// No description provided for @modeBannerCityFoundingInstructionPick.
  ///
  /// In en, this message translates to:
  /// **'Choose {count} connected tiles around the settler. After choosing them, the found-city action will be available in the bottom toolbar.'**
  String modeBannerCityFoundingInstructionPick(int count);

  /// No description provided for @selectionImprovementListTitle.
  ///
  /// In en, this message translates to:
  /// **'Tile improvements'**
  String get selectionImprovementListTitle;

  /// No description provided for @mapInspectionPossibleImprovementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Possible improvements'**
  String get mapInspectionPossibleImprovementsTitle;

  /// No description provided for @mapInspectionNoPossibleImprovements.
  ///
  /// In en, this message translates to:
  /// **'No possible improvements'**
  String get mapInspectionNoPossibleImprovements;

  /// No description provided for @mapInspectionImprovementAvailableFromStart.
  ///
  /// In en, this message translates to:
  /// **'from start'**
  String get mapInspectionImprovementAvailableFromStart;

  /// No description provided for @mapInspectionObjectiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Map objective'**
  String get mapInspectionObjectiveTitle;

  /// No description provided for @mapObjectiveRuins.
  ///
  /// In en, this message translates to:
  /// **'Ruins'**
  String get mapObjectiveRuins;

  /// No description provided for @mapObjectiveStrategicPass.
  ///
  /// In en, this message translates to:
  /// **'Strategic pass'**
  String get mapObjectiveStrategicPass;

  /// No description provided for @mapObjectiveHolySite.
  ///
  /// In en, this message translates to:
  /// **'Holy site'**
  String get mapObjectiveHolySite;

  /// No description provided for @mapObjectiveLegendaryResource.
  ///
  /// In en, this message translates to:
  /// **'Legendary deposit'**
  String get mapObjectiveLegendaryResource;

  /// No description provided for @mapObjectiveRuinsDescription.
  ///
  /// In en, this message translates to:
  /// **'A neutral exploration point. Holding it adds victory pressure.'**
  String get mapObjectiveRuinsDescription;

  /// No description provided for @mapObjectiveStrategicPassDescription.
  ///
  /// In en, this message translates to:
  /// **'A key passage through the terrain. Control turns movement into leverage.'**
  String get mapObjectiveStrategicPassDescription;

  /// No description provided for @mapObjectiveHolySiteDescription.
  ///
  /// In en, this message translates to:
  /// **'A culturally important site. Control grants gold and victory points.'**
  String get mapObjectiveHolySiteDescription;

  /// No description provided for @mapObjectiveLegendaryResourceDescription.
  ///
  /// In en, this message translates to:
  /// **'A rare deposit worth expansion or conflict. Control grants the largest reward.'**
  String get mapObjectiveLegendaryResourceDescription;

  /// No description provided for @mapObjectiveStatusNeutral.
  ///
  /// In en, this message translates to:
  /// **'Hold {turns} turns'**
  String mapObjectiveStatusNeutral(int turns);

  /// No description provided for @mapObjectiveStatusHolding.
  ///
  /// In en, this message translates to:
  /// **'Holding {held}/{required}'**
  String mapObjectiveStatusHolding(int held, int required);

  /// No description provided for @mapObjectiveStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Controlled {held}/{required}'**
  String mapObjectiveStatusCompleted(int held, int required);

  /// No description provided for @mapObjectiveStatusContested.
  ///
  /// In en, this message translates to:
  /// **'Contested'**
  String get mapObjectiveStatusContested;

  /// No description provided for @mapObjectiveRewardVictoryPoints.
  ///
  /// In en, this message translates to:
  /// **'+{points} VP'**
  String mapObjectiveRewardVictoryPoints(int points);

  /// No description provided for @mapObjectiveRewardGoldPerTurn.
  ///
  /// In en, this message translates to:
  /// **'+{gold} gold/turn'**
  String mapObjectiveRewardGoldPerTurn(int gold);

  /// No description provided for @selectionImprovementStateBuilt.
  ///
  /// In en, this message translates to:
  /// **'BUILT'**
  String get selectionImprovementStateBuilt;

  /// No description provided for @selectionImprovementStateAvailable.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE'**
  String get selectionImprovementStateAvailable;

  /// No description provided for @selectionImprovementStateNeedsTechnology.
  ///
  /// In en, this message translates to:
  /// **'TECH'**
  String get selectionImprovementStateNeedsTechnology;

  /// No description provided for @selectionImprovementStateNeedsCity.
  ///
  /// In en, this message translates to:
  /// **'CITY'**
  String get selectionImprovementStateNeedsCity;

  /// No description provided for @selectionImprovementStateBlocked.
  ///
  /// In en, this message translates to:
  /// **'LIMIT'**
  String get selectionImprovementStateBlocked;

  /// No description provided for @selectionImprovementNoBonus.
  ///
  /// In en, this message translates to:
  /// **'No bonus'**
  String get selectionImprovementNoBonus;

  /// No description provided for @workerImprovementYieldFood.
  ///
  /// In en, this message translates to:
  /// **'+{value} food'**
  String workerImprovementYieldFood(int value);

  /// No description provided for @workerImprovementYieldProduction.
  ///
  /// In en, this message translates to:
  /// **'+{value} production'**
  String workerImprovementYieldProduction(int value);

  /// No description provided for @workerImprovementYieldGold.
  ///
  /// In en, this message translates to:
  /// **'+{value} gold'**
  String workerImprovementYieldGold(int value);

  /// No description provided for @workerImprovementYieldDefense.
  ///
  /// In en, this message translates to:
  /// **'+{value} defense'**
  String workerImprovementYieldDefense(int value);

  /// No description provided for @workerImprovementNoBonus.
  ///
  /// In en, this message translates to:
  /// **'No extra bonus.'**
  String get workerImprovementNoBonus;

  /// No description provided for @workerImprovementOnlyWorker.
  ///
  /// In en, this message translates to:
  /// **'Only a worker can build this.'**
  String get workerImprovementOnlyWorker;

  /// No description provided for @workerImprovementWorkerBusy.
  ///
  /// In en, this message translates to:
  /// **'The worker is already building.'**
  String get workerImprovementWorkerBusy;

  /// No description provided for @workerImprovementStopQueuedMove.
  ///
  /// In en, this message translates to:
  /// **'Stop the planned movement first.'**
  String get workerImprovementStopQueuedMove;

  /// No description provided for @workerImprovementMissingTile.
  ///
  /// In en, this message translates to:
  /// **'No tile under the unit.'**
  String get workerImprovementMissingTile;

  /// No description provided for @workerImprovementMissingResource.
  ///
  /// In en, this message translates to:
  /// **'This improvement requires a matching resource.'**
  String get workerImprovementMissingResource;

  /// No description provided for @workerImprovementInvalidTerrain.
  ///
  /// In en, this message translates to:
  /// **'Wrong base terrain for this improvement.'**
  String get workerImprovementInvalidTerrain;

  /// No description provided for @workerImprovementMissingRiver.
  ///
  /// In en, this message translates to:
  /// **'This improvement requires a river.'**
  String get workerImprovementMissingRiver;

  /// No description provided for @workerImprovementBlocked.
  ///
  /// In en, this message translates to:
  /// **'This action is blocked now.'**
  String get workerImprovementBlocked;

  /// No description provided for @unitSelectionWorkerJobTurns.
  ///
  /// In en, this message translates to:
  /// **'{name} ({turns}T)'**
  String unitSelectionWorkerJobTurns(String name, int turns);

  /// No description provided for @resourceValueNoMatchingImprovement.
  ///
  /// In en, this message translates to:
  /// **'No matching improvement'**
  String get resourceValueNoMatchingImprovement;

  /// No description provided for @resourceValueSelectWorkerOrCity.
  ///
  /// In en, this message translates to:
  /// **'Select worker or city'**
  String get resourceValueSelectWorkerOrCity;

  /// No description provided for @resourceValueTileAlreadyImproved.
  ///
  /// In en, this message translates to:
  /// **'Tile already has an improvement'**
  String get resourceValueTileAlreadyImproved;

  /// No description provided for @resourceValueCityCenter.
  ///
  /// In en, this message translates to:
  /// **'City center'**
  String get resourceValueCityCenter;

  /// No description provided for @resourceValueWorksForCity.
  ///
  /// In en, this message translates to:
  /// **'Works for: {city}'**
  String resourceValueWorksForCity(String city);

  /// No description provided for @resourceValueOutsideCityBorders.
  ///
  /// In en, this message translates to:
  /// **'Outside city borders'**
  String get resourceValueOutsideCityBorders;

  /// No description provided for @resourceValueNoLegalImprovementForTile.
  ///
  /// In en, this message translates to:
  /// **'No legal improvement for this tile'**
  String get resourceValueNoLegalImprovementForTile;

  /// No description provided for @resourceValueRequiresTechnology.
  ///
  /// In en, this message translates to:
  /// **'Requires: {technology}'**
  String resourceValueRequiresTechnology(String technology);

  /// No description provided for @resourceValueAvailableForWorker.
  ///
  /// In en, this message translates to:
  /// **'Available for worker'**
  String get resourceValueAvailableForWorker;

  /// No description provided for @resourceDetailNoResourcesOnTile.
  ///
  /// In en, this message translates to:
  /// **'No resources on this tile'**
  String get resourceDetailNoResourcesOnTile;

  /// No description provided for @resourceDetailValueSection.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get resourceDetailValueSection;

  /// No description provided for @resourceDetailCurrentSection.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get resourceDetailCurrentSection;

  /// No description provided for @resourceDetailAfterImprovementSection.
  ///
  /// In en, this message translates to:
  /// **'After improvement'**
  String get resourceDetailAfterImprovementSection;

  /// No description provided for @resourceDetailYieldComparison.
  ///
  /// In en, this message translates to:
  /// **'Tile yields'**
  String get resourceDetailYieldComparison;

  /// No description provided for @resourceDetailRequiresSection.
  ///
  /// In en, this message translates to:
  /// **'Requires'**
  String get resourceDetailRequiresSection;

  /// No description provided for @resourceDetailBestMoveSection.
  ///
  /// In en, this message translates to:
  /// **'Best move'**
  String get resourceDetailBestMoveSection;

  /// No description provided for @resourceDetailNoMatchingImprovementBody.
  ///
  /// In en, this message translates to:
  /// **'No matching improvement for this resource.'**
  String get resourceDetailNoMatchingImprovementBody;

  /// No description provided for @resourceDetailRequirementNoneCanBuild.
  ///
  /// In en, this message translates to:
  /// **'Nothing. You can build immediately.'**
  String get resourceDetailRequirementNoneCanBuild;

  /// No description provided for @resourceDetailRequirementOutsideCity.
  ///
  /// In en, this message translates to:
  /// **'The tile must be inside city borders.'**
  String get resourceDetailRequirementOutsideCity;

  /// No description provided for @resourceDetailRequirementAlreadyImproved.
  ///
  /// In en, this message translates to:
  /// **'Nothing. The tile is already improved.'**
  String get resourceDetailRequirementAlreadyImproved;

  /// No description provided for @resourceDetailRequirementCityCenter.
  ///
  /// In en, this message translates to:
  /// **'No worker build in the city center.'**
  String get resourceDetailRequirementCityCenter;

  /// No description provided for @resourceDetailRequirementSelectWorkerOrCity.
  ///
  /// In en, this message translates to:
  /// **'A worker or city selection.'**
  String get resourceDetailRequirementSelectWorkerOrCity;

  /// No description provided for @resourceDetailRequirementNoLegalImprovement.
  ///
  /// In en, this message translates to:
  /// **'No available build for this tile.'**
  String get resourceDetailRequirementNoLegalImprovement;

  /// No description provided for @resourceDetailBestMoveRequiresTechnology.
  ///
  /// In en, this message translates to:
  /// **'Unlock {technology} first, then build {improvement}.'**
  String resourceDetailBestMoveRequiresTechnology(
    String technology,
    String improvement,
  );

  /// No description provided for @resourceDetailBestMoveAvailable.
  ///
  /// In en, this message translates to:
  /// **'Send a worker and build {improvement}.'**
  String resourceDetailBestMoveAvailable(String improvement);

  /// No description provided for @resourceDetailBestMoveOutsideCity.
  ///
  /// In en, this message translates to:
  /// **'Expand city borders or found a city closer to the resource.'**
  String get resourceDetailBestMoveOutsideCity;

  /// No description provided for @resourceDetailBestMoveAlreadyImproved.
  ///
  /// In en, this message translates to:
  /// **'Keep the tile in borders and work it when it fits the city plan.'**
  String get resourceDetailBestMoveAlreadyImproved;

  /// No description provided for @resourceDetailBestMoveCityCenter.
  ///
  /// In en, this message translates to:
  /// **'Treat the resource as city-center value; workers do not improve this tile.'**
  String get resourceDetailBestMoveCityCenter;

  /// No description provided for @resourceDetailBestMoveSelectWorkerOrCity.
  ///
  /// In en, this message translates to:
  /// **'Select a worker or city to check the legal build.'**
  String get resourceDetailBestMoveSelectWorkerOrCity;

  /// No description provided for @resourceDetailBestMoveNoLegalImprovement.
  ///
  /// In en, this message translates to:
  /// **'Treat the resource as an expansion target; there is no separate build here.'**
  String get resourceDetailBestMoveNoLegalImprovement;

  /// No description provided for @resourceValueUnlockedByTechnology.
  ///
  /// In en, this message translates to:
  /// **'Unlocked by {technology}: {improvement}.'**
  String resourceValueUnlockedByTechnology(
    String technology,
    String improvement,
  );

  /// No description provided for @resourceValueUnlocksFullYieldAfterTechnology.
  ///
  /// In en, this message translates to:
  /// **'After {technology}: {improvement} unlocks the full tile yield.'**
  String resourceValueUnlocksFullYieldAfterTechnology(
    String technology,
    String improvement,
  );

  /// No description provided for @resourceValueResearchBoostLine.
  ///
  /// In en, this message translates to:
  /// **'Research boost: controlling this resource accelerates {technology} (-{discount} cost).'**
  String resourceValueResearchBoostLine(String technology, String discount);

  /// No description provided for @resourceValueTechnologyControlledResourceBonus.
  ///
  /// In en, this message translates to:
  /// **'After {technology}: +{production} PROD for each controlled resource.'**
  String resourceValueTechnologyControlledResourceBonus(
    String technology,
    int production,
  );

  /// No description provided for @resourceValueNoBaseYieldSummary.
  ///
  /// In en, this message translates to:
  /// **'The resource itself adds no base yield. The whole hex now has {yield}; full value comes from improvements and unlocks.'**
  String resourceValueNoBaseYieldSummary(String yield);

  /// No description provided for @resourceValueBaseYieldSummary.
  ///
  /// In en, this message translates to:
  /// **'The resource gives {resourceYield}. The whole hex now has {tileYield} before improvement.'**
  String resourceValueBaseYieldSummary(String resourceYield, String tileYield);

  /// No description provided for @resourceValueExpansionStrategic.
  ///
  /// In en, this message translates to:
  /// **'Claim it before a rival does: this is a strategic resource for production, armies, or later technologies.'**
  String get resourceValueExpansionStrategic;

  /// No description provided for @resourceValueExpansionFood.
  ///
  /// In en, this message translates to:
  /// **'A good expansion target for city growth: more food means faster population and more worked tiles.'**
  String get resourceValueExpansionFood;

  /// No description provided for @resourceValueExpansionProduction.
  ///
  /// In en, this message translates to:
  /// **'A good expansion target for production tempo: buildings, units, and map pressure arrive faster.'**
  String get resourceValueExpansionProduction;

  /// No description provided for @resourceValueExpansionTrade.
  ///
  /// In en, this message translates to:
  /// **'A good expansion target for trade: after improvement it strongly supports gold and continued growth upkeep.'**
  String get resourceValueExpansionTrade;

  /// No description provided for @resourceValueExpansionEconomy.
  ///
  /// In en, this message translates to:
  /// **'A good expansion target for the economy: gold helps maintain armies, build reserves, and close score goals.'**
  String get resourceValueExpansionEconomy;

  /// No description provided for @resourceValueYieldFood.
  ///
  /// In en, this message translates to:
  /// **'+{amount} FOOD'**
  String resourceValueYieldFood(int amount);

  /// No description provided for @resourceValueYieldProduction.
  ///
  /// In en, this message translates to:
  /// **'+{amount} PROD'**
  String resourceValueYieldProduction(int amount);

  /// No description provided for @resourceValueYieldGold.
  ///
  /// In en, this message translates to:
  /// **'+{amount} GOLD'**
  String resourceValueYieldGold(int amount);

  /// No description provided for @resourceValueYieldDefense.
  ///
  /// In en, this message translates to:
  /// **'+{amount} DEF'**
  String resourceValueYieldDefense(int amount);

  /// No description provided for @resourceValueZeroBaseYield.
  ///
  /// In en, this message translates to:
  /// **'0 base yield'**
  String get resourceValueZeroBaseYield;

  /// No description provided for @resourceValueCategoryBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get resourceValueCategoryBonus;

  /// No description provided for @resourceValueCategoryLuxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get resourceValueCategoryLuxury;

  /// No description provided for @resourceValueCategoryStrategic.
  ///
  /// In en, this message translates to:
  /// **'Strategic'**
  String get resourceValueCategoryStrategic;

  /// No description provided for @resourceValueCategoryBonusFuture.
  ///
  /// In en, this message translates to:
  /// **'Value works mostly right away: faster growth and a better city start.'**
  String get resourceValueCategoryBonusFuture;

  /// No description provided for @resourceValueCategoryLuxuryFuture.
  ///
  /// In en, this message translates to:
  /// **'The largest value appears after border claim and the proper improvement.'**
  String get resourceValueCategoryLuxuryFuture;

  /// No description provided for @resourceValueCategoryStrategicFuture.
  ///
  /// In en, this message translates to:
  /// **'This is a strategic resource: secure it for later production and military pressure.'**
  String get resourceValueCategoryStrategicFuture;

  /// No description provided for @cityYieldBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'City economy'**
  String get cityYieldBreakdownTitle;

  /// No description provided for @cityYieldBreakdownSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real yield/turn • growth {growth} • {eta}'**
  String cityYieldBreakdownSubtitle(String growth, String eta);

  /// No description provided for @cityYieldBreakdownProductionSources.
  ///
  /// In en, this message translates to:
  /// **'Production sources'**
  String get cityYieldBreakdownProductionSources;

  /// No description provided for @cityYieldBreakdownScienceSources.
  ///
  /// In en, this message translates to:
  /// **'Science sources'**
  String get cityYieldBreakdownScienceSources;

  /// No description provided for @cityYieldBreakdownPerTurnSuffix.
  ///
  /// In en, this message translates to:
  /// **'/turn'**
  String get cityYieldBreakdownPerTurnSuffix;

  /// No description provided for @cityYieldBreakdownNoProduction.
  ///
  /// In en, this message translates to:
  /// **'No production'**
  String get cityYieldBreakdownNoProduction;

  /// No description provided for @cityYieldBreakdownNoScience.
  ///
  /// In en, this message translates to:
  /// **'No science'**
  String get cityYieldBreakdownNoScience;

  /// No description provided for @cityYieldBreakdownCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get cityYieldBreakdownCenter;

  /// No description provided for @cityYieldBreakdownPopulationFields.
  ///
  /// In en, this message translates to:
  /// **'Population fields'**
  String get cityYieldBreakdownPopulationFields;

  /// No description provided for @cityYieldBreakdownWorkers.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get cityYieldBreakdownWorkers;

  /// No description provided for @cityYieldBreakdownBuildings.
  ///
  /// In en, this message translates to:
  /// **'Buildings'**
  String get cityYieldBreakdownBuildings;

  /// No description provided for @cityYieldBreakdownTechnologies.
  ///
  /// In en, this message translates to:
  /// **'Technologies'**
  String get cityYieldBreakdownTechnologies;

  /// No description provided for @cityYieldBreakdownSpecialization.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get cityYieldBreakdownSpecialization;

  /// No description provided for @cityYieldBreakdownGoldMultiplier.
  ///
  /// In en, this message translates to:
  /// **'Gold multiplier'**
  String get cityYieldBreakdownGoldMultiplier;

  /// No description provided for @cityYieldBreakdownUpkeep.
  ///
  /// In en, this message translates to:
  /// **'Upkeep'**
  String get cityYieldBreakdownUpkeep;

  /// No description provided for @cityYieldBreakdownFieldsBucket.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get cityYieldBreakdownFieldsBucket;

  /// No description provided for @cityYieldBreakdownCenterDetail.
  ///
  /// In en, this message translates to:
  /// **'Fixed yield from the city center'**
  String get cityYieldBreakdownCenterDetail;

  /// No description provided for @cityYieldBreakdownGoldMultiplierDetail.
  ///
  /// In en, this message translates to:
  /// **'Percentage bonus after summing gold sources'**
  String get cityYieldBreakdownGoldMultiplierDetail;

  /// No description provided for @cityYieldBreakdownBaseScience.
  ///
  /// In en, this message translates to:
  /// **'City base'**
  String get cityYieldBreakdownBaseScience;

  /// No description provided for @cityYieldBreakdownBaseScienceDetail.
  ///
  /// In en, this message translates to:
  /// **'Fixed science generated by each city'**
  String get cityYieldBreakdownBaseScienceDetail;

  /// No description provided for @cityYieldBreakdownResearchProject.
  ///
  /// In en, this message translates to:
  /// **'Research project'**
  String get cityYieldBreakdownResearchProject;

  /// No description provided for @cityYieldBreakdownResearchProjectDetail.
  ///
  /// In en, this message translates to:
  /// **'Current city production converted into science'**
  String get cityYieldBreakdownResearchProjectDetail;

  /// No description provided for @cityYieldBreakdownScienceSpecializationDetail.
  ///
  /// In en, this message translates to:
  /// **'City science profile'**
  String get cityYieldBreakdownScienceSpecializationDetail;

  /// No description provided for @cityYieldBreakdownScienceTechnologyDetail.
  ///
  /// In en, this message translates to:
  /// **'Science bonus from unlocked technologies'**
  String get cityYieldBreakdownScienceTechnologyDetail;

  /// No description provided for @cityYieldBreakdownNoWorkedPopulationFields.
  ///
  /// In en, this message translates to:
  /// **'No worked population fields'**
  String get cityYieldBreakdownNoWorkedPopulationFields;

  /// No description provided for @cityYieldBreakdownOneWorkedPopulationField.
  ///
  /// In en, this message translates to:
  /// **'1 worked population field'**
  String get cityYieldBreakdownOneWorkedPopulationField;

  /// No description provided for @cityYieldBreakdownManyWorkedPopulationFields.
  ///
  /// In en, this message translates to:
  /// **'{count} worked population fields'**
  String cityYieldBreakdownManyWorkedPopulationFields(int count);

  /// No description provided for @cityYieldBreakdownNoAssignedWorkers.
  ///
  /// In en, this message translates to:
  /// **'No assigned workers'**
  String get cityYieldBreakdownNoAssignedWorkers;

  /// No description provided for @cityYieldBreakdownOneAssignedWorker.
  ///
  /// In en, this message translates to:
  /// **'1 field activated by a worker'**
  String get cityYieldBreakdownOneAssignedWorker;

  /// No description provided for @cityYieldBreakdownManyAssignedWorkers.
  ///
  /// In en, this message translates to:
  /// **'{count} fields activated by workers'**
  String cityYieldBreakdownManyAssignedWorkers(int count);

  /// No description provided for @cityYieldBreakdownNoPassiveImprovements.
  ///
  /// In en, this message translates to:
  /// **'No passive improvements'**
  String get cityYieldBreakdownNoPassiveImprovements;

  /// No description provided for @cityYieldBreakdownOnePassiveImprovement.
  ///
  /// In en, this message translates to:
  /// **'1 unworked improvement, half yield'**
  String get cityYieldBreakdownOnePassiveImprovement;

  /// No description provided for @cityYieldBreakdownManyPassiveImprovements.
  ///
  /// In en, this message translates to:
  /// **'{count} unworked improvements, half yield'**
  String cityYieldBreakdownManyPassiveImprovements(int count);

  /// No description provided for @cityYieldBreakdownNoBuildings.
  ///
  /// In en, this message translates to:
  /// **'No buildings'**
  String get cityYieldBreakdownNoBuildings;

  /// No description provided for @cityYieldBreakdownBuildingsNoDirectYield.
  ///
  /// In en, this message translates to:
  /// **'Buildings without direct yield'**
  String get cityYieldBreakdownBuildingsNoDirectYield;

  /// No description provided for @cityYieldBreakdownOneBuildingEconomicEffect.
  ///
  /// In en, this message translates to:
  /// **'1 building with an economy effect'**
  String get cityYieldBreakdownOneBuildingEconomicEffect;

  /// No description provided for @cityYieldBreakdownManyBuildingEconomicEffects.
  ///
  /// In en, this message translates to:
  /// **'{count} buildings with economy effects'**
  String cityYieldBreakdownManyBuildingEconomicEffects(int count);

  /// No description provided for @cityYieldBreakdownNoTechnologyYield.
  ///
  /// In en, this message translates to:
  /// **'No technology yield bonus'**
  String get cityYieldBreakdownNoTechnologyYield;

  /// No description provided for @cityYieldBreakdownTechnologyYield.
  ///
  /// In en, this message translates to:
  /// **'Bonuses from unlocked technologies'**
  String get cityYieldBreakdownTechnologyYield;

  /// No description provided for @cityYieldBreakdownNoScienceBuildings.
  ///
  /// In en, this message translates to:
  /// **'No science buildings'**
  String get cityYieldBreakdownNoScienceBuildings;

  /// No description provided for @cityYieldBreakdownOneScienceBuilding.
  ///
  /// In en, this message translates to:
  /// **'1 science building'**
  String get cityYieldBreakdownOneScienceBuilding;

  /// No description provided for @cityYieldBreakdownManyScienceBuildings.
  ///
  /// In en, this message translates to:
  /// **'{count} science buildings with diminishing returns'**
  String cityYieldBreakdownManyScienceBuildings(int count);

  /// No description provided for @cityYieldBreakdownGrowthFood.
  ///
  /// In en, this message translates to:
  /// **'{storedFood}/{growthCost} food'**
  String cityYieldBreakdownGrowthFood(int storedFood, int growthCost);

  /// No description provided for @cityYieldBreakdownStagnation.
  ///
  /// In en, this message translates to:
  /// **'stagnation'**
  String get cityYieldBreakdownStagnation;

  /// No description provided for @cityYieldBreakdownUpkeepBlocked.
  ///
  /// In en, this message translates to:
  /// **'Population {population}: cost {cost}, growth halted'**
  String cityYieldBreakdownUpkeepBlocked(int population, int cost);

  /// No description provided for @cityYieldBreakdownUpkeepCost.
  ///
  /// In en, this message translates to:
  /// **'Food upkeep for population {population}'**
  String cityYieldBreakdownUpkeepCost(int population);

  /// No description provided for @cityYieldBreakdownGrowthSpecializationDetail.
  ///
  /// In en, this message translates to:
  /// **'City growth profile'**
  String get cityYieldBreakdownGrowthSpecializationDetail;

  /// No description provided for @cityYieldBreakdownIndustrySpecializationDetail.
  ///
  /// In en, this message translates to:
  /// **'City industry profile'**
  String get cityYieldBreakdownIndustrySpecializationDetail;

  /// No description provided for @cityYieldBreakdownCommerceSpecializationDetail.
  ///
  /// In en, this message translates to:
  /// **'City trade profile'**
  String get cityYieldBreakdownCommerceSpecializationDetail;

  /// No description provided for @cityYieldBreakdownScienceSpecializationCityDetail.
  ///
  /// In en, this message translates to:
  /// **'City science profile'**
  String get cityYieldBreakdownScienceSpecializationCityDetail;

  /// No description provided for @cityYieldBreakdownMilitarySpecializationDetail.
  ///
  /// In en, this message translates to:
  /// **'City garrison profile'**
  String get cityYieldBreakdownMilitarySpecializationDetail;

  /// No description provided for @cityYieldBreakdownNoSpecialization.
  ///
  /// In en, this message translates to:
  /// **'No specialization'**
  String get cityYieldBreakdownNoSpecialization;

  /// No description provided for @cityProjectWealth.
  ///
  /// In en, this message translates to:
  /// **'Wealth'**
  String get cityProjectWealth;

  /// No description provided for @cityProjectResearch.
  ///
  /// In en, this message translates to:
  /// **'Research'**
  String get cityProjectResearch;

  /// No description provided for @cityProductionProjectsSection.
  ///
  /// In en, this message translates to:
  /// **'City projects'**
  String get cityProductionProjectsSection;

  /// No description provided for @cityProductionSpecializationSection.
  ///
  /// In en, this message translates to:
  /// **'City specialization'**
  String get cityProductionSpecializationSection;

  /// No description provided for @cityProductionSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get cityProductionSortLabel;

  /// No description provided for @cityProductionHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{title} • {productionPerTurn} • {gold} gold'**
  String cityProductionHeaderSubtitle(
    String title,
    String productionPerTurn,
    int gold,
  );

  /// No description provided for @cityProductionBuiltLabel.
  ///
  /// In en, this message translates to:
  /// **'Built'**
  String get cityProductionBuiltLabel;

  /// No description provided for @cityProductionAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get cityProductionAvailableLabel;

  /// No description provided for @cityProductionAvailableUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get cityProductionAvailableUnitLabel;

  /// No description provided for @cityProductionUnitSupplyLimit.
  ///
  /// In en, this message translates to:
  /// **'Food limit {used}/{capacity}'**
  String cityProductionUnitSupplyLimit(int used, int capacity);

  /// No description provided for @cityProductionUnitSupplyCost.
  ///
  /// In en, this message translates to:
  /// **'food {cost}'**
  String cityProductionUnitSupplyCost(int cost);

  /// No description provided for @cityProductionUnitSupplyUsed.
  ///
  /// In en, this message translates to:
  /// **'limit {used}/{capacity}'**
  String cityProductionUnitSupplyUsed(int used, int capacity);

  /// No description provided for @cityProductionNextWorkerUpkeep.
  ///
  /// In en, this message translates to:
  /// **'next upkeep: {upkeep}'**
  String cityProductionNextWorkerUpkeep(int upkeep);

  /// No description provided for @cityProductionCostShort.
  ///
  /// In en, this message translates to:
  /// **'{production} prod.'**
  String cityProductionCostShort(int production);

  /// No description provided for @cityProductionPaceShort.
  ///
  /// In en, this message translates to:
  /// **'{production} prod./turn'**
  String cityProductionPaceShort(int production);

  /// No description provided for @cityBuildingSortRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get cityBuildingSortRecommended;

  /// No description provided for @cityBuildingReplaceProgressWarning.
  ///
  /// In en, this message translates to:
  /// **'Choosing another building will replace {building}. Progress will be preserved.'**
  String cityBuildingReplaceProgressWarning(String building);

  /// No description provided for @cityBuildingSortFastestImpact.
  ///
  /// In en, this message translates to:
  /// **'Fastest impact'**
  String get cityBuildingSortFastestImpact;

  /// No description provided for @cityBuildingSortBestReturn.
  ///
  /// In en, this message translates to:
  /// **'Best return'**
  String get cityBuildingSortBestReturn;

  /// No description provided for @cityBuildingSortGrowth.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get cityBuildingSortGrowth;

  /// No description provided for @cityBuildingSortIndustry.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get cityBuildingSortIndustry;

  /// No description provided for @cityBuildingSortScience.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get cityBuildingSortScience;

  /// No description provided for @cityBuildingSortDefenseMilitary.
  ///
  /// In en, this message translates to:
  /// **'Defense / military'**
  String get cityBuildingSortDefenseMilitary;

  /// No description provided for @cityBuildingSortEconomy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get cityBuildingSortEconomy;

  /// No description provided for @cityBuildingRequiresTechnology.
  ///
  /// In en, this message translates to:
  /// **'Requires technology'**
  String get cityBuildingRequiresTechnology;

  /// No description provided for @cityProductionContinuous.
  ///
  /// In en, this message translates to:
  /// **'continuous'**
  String get cityProductionContinuous;

  /// No description provided for @cityProductionNoProduction.
  ///
  /// In en, this message translates to:
  /// **'no production'**
  String get cityProductionNoProduction;

  /// No description provided for @cityProductionReady.
  ///
  /// In en, this message translates to:
  /// **'ready'**
  String get cityProductionReady;

  /// No description provided for @cityProductionTurnOne.
  ///
  /// In en, this message translates to:
  /// **'1 turn'**
  String get cityProductionTurnOne;

  /// No description provided for @cityProductionTurns.
  ///
  /// In en, this message translates to:
  /// **'{turns} turns'**
  String cityProductionTurns(int turns);

  /// No description provided for @cityProductionTreasuryGold.
  ///
  /// In en, this message translates to:
  /// **'Treasury: {gold} gold'**
  String cityProductionTreasuryGold(int gold);

  /// No description provided for @cityProductionRushAction.
  ///
  /// In en, this message translates to:
  /// **'Rush -{gold}'**
  String cityProductionRushAction(int gold);

  /// No description provided for @cityProjectGoldPerTurn.
  ///
  /// In en, this message translates to:
  /// **'+{gold} gold / turn'**
  String cityProjectGoldPerTurn(int gold);

  /// No description provided for @cityProjectSciencePerTurn.
  ///
  /// In en, this message translates to:
  /// **'+{science} science / turn'**
  String cityProjectSciencePerTurn(int science);

  /// No description provided for @citySpecializationGrowth.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get citySpecializationGrowth;

  /// No description provided for @citySpecializationIndustry.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get citySpecializationIndustry;

  /// No description provided for @citySpecializationCommerce.
  ///
  /// In en, this message translates to:
  /// **'Commerce'**
  String get citySpecializationCommerce;

  /// No description provided for @citySpecializationMilitary.
  ///
  /// In en, this message translates to:
  /// **'Garrison'**
  String get citySpecializationMilitary;

  /// No description provided for @citySpecializationGrowthBonus.
  ///
  /// In en, this message translates to:
  /// **'+2 food'**
  String get citySpecializationGrowthBonus;

  /// No description provided for @citySpecializationIndustryBonus.
  ///
  /// In en, this message translates to:
  /// **'+2 production'**
  String get citySpecializationIndustryBonus;

  /// No description provided for @citySpecializationCommerceBonus.
  ///
  /// In en, this message translates to:
  /// **'+3 gold'**
  String get citySpecializationCommerceBonus;

  /// No description provided for @citySpecializationScienceBonus.
  ///
  /// In en, this message translates to:
  /// **'+2 science'**
  String get citySpecializationScienceBonus;

  /// No description provided for @citySpecializationMilitaryProductionBonus.
  ///
  /// In en, this message translates to:
  /// **'+1 production'**
  String get citySpecializationMilitaryProductionBonus;

  /// No description provided for @citySpecializationMilitaryDefenseBonus.
  ///
  /// In en, this message translates to:
  /// **'+2 defense'**
  String get citySpecializationMilitaryDefenseBonus;

  /// No description provided for @citySpecializationMilitaryUnitProductionBonus.
  ///
  /// In en, this message translates to:
  /// **'+1 unit prod.'**
  String get citySpecializationMilitaryUnitProductionBonus;

  /// No description provided for @citySpecializationBestFit.
  ///
  /// In en, this message translates to:
  /// **'Best fit'**
  String get citySpecializationBestFit;

  /// No description provided for @eventCityFoundedTitle.
  ///
  /// In en, this message translates to:
  /// **'City founded'**
  String get eventCityFoundedTitle;

  /// No description provided for @eventCityBuiltBuildingTitle.
  ///
  /// In en, this message translates to:
  /// **'Construction complete'**
  String get eventCityBuiltBuildingTitle;

  /// No description provided for @eventCityProducedUnitTitle.
  ///
  /// In en, this message translates to:
  /// **'Unit trained'**
  String get eventCityProducedUnitTitle;

  /// No description provided for @eventCityClaimedHexTitle.
  ///
  /// In en, this message translates to:
  /// **'City borders'**
  String get eventCityClaimedHexTitle;

  /// No description provided for @eventCityClaimedHexBody.
  ///
  /// In en, this message translates to:
  /// **'{cityName}: new tile'**
  String eventCityClaimedHexBody(String cityName);

  /// No description provided for @eventUnitMovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unit movement'**
  String get eventUnitMovedTitle;

  /// No description provided for @eventUnitPromotedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unit promoted'**
  String get eventUnitPromotedTitle;

  /// No description provided for @eventUnitExperienceTitle.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get eventUnitExperienceTitle;

  /// No description provided for @eventUnitExperienceBody.
  ///
  /// In en, this message translates to:
  /// **'{unitName}: +{amount} XP ({rank})'**
  String eventUnitExperienceBody(String unitName, int amount, String rank);

  /// No description provided for @eventUnitAttackedTitle.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get eventUnitAttackedTitle;

  /// No description provided for @eventCombatTitle.
  ///
  /// In en, this message translates to:
  /// **'Combat'**
  String get eventCombatTitle;

  /// No description provided for @eventCombatDamageLine.
  ///
  /// In en, this message translates to:
  /// **'{unitName}: -{damage} HP -> {result}'**
  String eventCombatDamageLine(String unitName, int damage, String result);

  /// No description provided for @eventCombatNoRetaliationLine.
  ///
  /// In en, this message translates to:
  /// **'{unitName}: no retaliation'**
  String eventCombatNoRetaliationLine(String unitName);

  /// No description provided for @eventCombatSimpleBody.
  ///
  /// In en, this message translates to:
  /// **'{attackerName} ({attackerCountry}) attacked {defenderName} ({defenderCountry}) - HP {attackerHp}:{defenderHp}'**
  String eventCombatSimpleBody(
    String attackerCountry,
    String attackerName,
    String defenderCountry,
    String defenderName,
    int attackerHp,
    int defenderHp,
  );

  /// No description provided for @eventDiplomaticProposalAcceptedStatus.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get eventDiplomaticProposalAcceptedStatus;

  /// No description provided for @eventDiplomaticProposalRejectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get eventDiplomaticProposalRejectedStatus;

  /// No description provided for @eventDiplomaticProposalExpiredStatus.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get eventDiplomaticProposalExpiredStatus;

  /// No description provided for @eventUnitKilledTitle.
  ///
  /// In en, this message translates to:
  /// **'Unit defeated'**
  String get eventUnitKilledTitle;

  /// No description provided for @eventUnitRetreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Retreat'**
  String get eventUnitRetreatedTitle;

  /// No description provided for @eventCityCapturedTitle.
  ///
  /// In en, this message translates to:
  /// **'City captured'**
  String get eventCityCapturedTitle;

  /// No description provided for @eventCityDestroyedTitle.
  ///
  /// In en, this message translates to:
  /// **'City destroyed'**
  String get eventCityDestroyedTitle;

  /// No description provided for @eventTurnEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn ended'**
  String get eventTurnEndedTitle;

  /// No description provided for @eventWorkerCompletedJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Work complete'**
  String get eventWorkerCompletedJobTitle;

  /// No description provided for @eventResearchPointsTitle.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get eventResearchPointsTitle;

  /// No description provided for @eventResearchPointsBody.
  ///
  /// In en, this message translates to:
  /// **'{playerName}: +{points} science'**
  String eventResearchPointsBody(String playerName, int points);

  /// No description provided for @eventTechnologyResearchedTitle.
  ///
  /// In en, this message translates to:
  /// **'Technology discovered'**
  String get eventTechnologyResearchedTitle;

  /// No description provided for @eventStrategicResourceDiscoveredTitle.
  ///
  /// In en, this message translates to:
  /// **'Strategic resource discovered'**
  String get eventStrategicResourceDiscoveredTitle;

  /// No description provided for @eventStrategicResourceDiscoveredBody.
  ///
  /// In en, this message translates to:
  /// **'{playerName}: {resourceName}'**
  String eventStrategicResourceDiscoveredBody(
    String playerName,
    String resourceName,
  );

  /// No description provided for @eventStrategicResourceControlledDetail.
  ///
  /// In en, this message translates to:
  /// **'Controlled: {count}'**
  String eventStrategicResourceControlledDetail(int count);

  /// No description provided for @eventStrategicResourceRivalDetail.
  ///
  /// In en, this message translates to:
  /// **'Rivals: {count}'**
  String eventStrategicResourceRivalDetail(int count);

  /// No description provided for @eventStrategicResourceUnclaimedDetail.
  ///
  /// In en, this message translates to:
  /// **'Unclaimed: {count}'**
  String eventStrategicResourceUnclaimedDetail(int count);

  /// No description provided for @eventStrategicResourcePressureSecured.
  ///
  /// In en, this message translates to:
  /// **'Supply secured; defend the source.'**
  String get eventStrategicResourcePressureSecured;

  /// No description provided for @eventStrategicResourcePressureExpansionRace.
  ///
  /// In en, this message translates to:
  /// **'Settlement race: claim the nearest deposit before rivals.'**
  String get eventStrategicResourcePressureExpansionRace;

  /// No description provided for @eventStrategicResourcePressureContested.
  ///
  /// In en, this message translates to:
  /// **'Contested supply: rivals also control sources.'**
  String get eventStrategicResourcePressureContested;

  /// No description provided for @eventStrategicResourcePressureRivalMonopoly.
  ///
  /// In en, this message translates to:
  /// **'Rival monopoly: prepare trade or an expedition.'**
  String get eventStrategicResourcePressureRivalMonopoly;

  /// No description provided for @eventStrategicResourceSettleHint.
  ///
  /// In en, this message translates to:
  /// **'Deposit outside borders at {col}:{row}; consider founding a city.'**
  String eventStrategicResourceSettleHint(int col, int row);

  /// No description provided for @eventMapObjectiveSecuredTitle.
  ///
  /// In en, this message translates to:
  /// **'Map objective secured'**
  String get eventMapObjectiveSecuredTitle;

  /// No description provided for @eventMapObjectiveSecuredBody.
  ///
  /// In en, this message translates to:
  /// **'{playerName}: {objectiveName}'**
  String eventMapObjectiveSecuredBody(String playerName, String objectiveName);

  /// No description provided for @eventMapObjectiveHoldDetail.
  ///
  /// In en, this message translates to:
  /// **'Held: {holdTurns}/{requiredHoldTurns}'**
  String eventMapObjectiveHoldDetail(int holdTurns, int requiredHoldTurns);

  /// No description provided for @eventMapObjectiveLocationDetail.
  ///
  /// In en, this message translates to:
  /// **'Position: {col}:{row}'**
  String eventMapObjectiveLocationDetail(int col, int row);

  /// No description provided for @eventMapObjectiveVictoryRewardDetail.
  ///
  /// In en, this message translates to:
  /// **'+{points} victory points'**
  String eventMapObjectiveVictoryRewardDetail(int points);

  /// No description provided for @eventMapObjectiveGoldRewardDetail.
  ///
  /// In en, this message translates to:
  /// **'+{gold} gold/turn'**
  String eventMapObjectiveGoldRewardDetail(int gold);

  /// No description provided for @eventCivilizationMetTitle.
  ///
  /// In en, this message translates to:
  /// **'New civilization'**
  String get eventCivilizationMetTitle;

  /// No description provided for @eventCivilizationMetBody.
  ///
  /// In en, this message translates to:
  /// **'{civilizationName} ({playerName})'**
  String eventCivilizationMetBody(String civilizationName, String playerName);

  /// No description provided for @civilizationMetPopupEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Civilization encountered'**
  String get civilizationMetPopupEyebrow;

  /// No description provided for @civilizationMetPopupBody.
  ///
  /// In en, this message translates to:
  /// **'The civilization of {civilizationName} has appeared on the horizon. A new neighbor, rival, or future ally is now part of your world.'**
  String civilizationMetPopupBody(String civilizationName);

  /// No description provided for @civilizationMetPopupOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get civilizationMetPopupOk;

  /// No description provided for @eventCommandRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Command rejected'**
  String get eventCommandRejectedTitle;

  /// No description provided for @eventAllPlayersSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Everyone ready'**
  String get eventAllPlayersSubmittedTitle;

  /// No description provided for @eventAllPlayersSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'Turn {turn} ({players})'**
  String eventAllPlayersSubmittedBody(int turn, int players);

  /// No description provided for @eventPlayerTimedOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-submit'**
  String get eventPlayerTimedOutTitle;

  /// No description provided for @eventPlayerTimedOutBody.
  ///
  /// In en, this message translates to:
  /// **'{playerName}: timed out on turn {turn}'**
  String eventPlayerTimedOutBody(String playerName, int turn);

  /// No description provided for @eventCombatDefenderKilledDetail.
  ///
  /// In en, this message translates to:
  /// **'Defender defeated'**
  String get eventCombatDefenderKilledDetail;

  /// No description provided for @eventCombatAttackerKilledDetail.
  ///
  /// In en, this message translates to:
  /// **'Attacker defeated'**
  String get eventCombatAttackerKilledDetail;

  /// No description provided for @eventCombatDefenderRetreatedDetail.
  ///
  /// In en, this message translates to:
  /// **'Defender retreated'**
  String get eventCombatDefenderRetreatedDetail;

  /// No description provided for @eventCombatAttackDamageDetail.
  ///
  /// In en, this message translates to:
  /// **'Attack: -{damage} HP'**
  String eventCombatAttackDamageDetail(int damage);

  /// No description provided for @eventCombatRetaliationDamageDetail.
  ///
  /// In en, this message translates to:
  /// **'Retaliation: -{damage} HP'**
  String eventCombatRetaliationDamageDetail(int damage);

  /// No description provided for @eventCombatRollDetail.
  ///
  /// In en, this message translates to:
  /// **'Roll {value}'**
  String eventCombatRollDetail(int value);

  /// No description provided for @eventCombatNoRetaliationDetail.
  ///
  /// In en, this message translates to:
  /// **'No retaliation'**
  String get eventCombatNoRetaliationDetail;

  /// No description provided for @eventDominationStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Domination started'**
  String get eventDominationStartedTitle;

  /// No description provided for @eventDominationRivalAboveTitle.
  ///
  /// In en, this message translates to:
  /// **'Rival above threshold'**
  String get eventDominationRivalAboveTitle;

  /// No description provided for @eventDominationBody.
  ///
  /// In en, this message translates to:
  /// **'{playerName}: {control}% / {required}%'**
  String eventDominationBody(
    String playerName,
    String control,
    String required,
  );

  /// No description provided for @eventDominationHoldProgressDetail.
  ///
  /// In en, this message translates to:
  /// **'Held {held}/{required} turns'**
  String eventDominationHoldProgressDetail(int held, int required);

  /// No description provided for @eventDominationReadyDetail.
  ///
  /// In en, this message translates to:
  /// **'Condition ready'**
  String get eventDominationReadyDetail;

  /// No description provided for @eventDominationKeepHoldingDetail.
  ///
  /// In en, this message translates to:
  /// **'Hold for {turns} more'**
  String eventDominationKeepHoldingDetail(String turns);

  /// No description provided for @eventDominationInterruptDetail.
  ///
  /// In en, this message translates to:
  /// **'Interrupt within {turns}'**
  String eventDominationInterruptDetail(String turns);

  /// No description provided for @eventTurnCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 turns} =1{1 turn} other{{count} turns}}'**
  String eventTurnCountLabel(int count);

  /// No description provided for @eventCombatDefeatedResult.
  ///
  /// In en, this message translates to:
  /// **'defeated'**
  String get eventCombatDefeatedResult;

  /// No description provided for @eventCombatDefenderRetreatedResult.
  ///
  /// In en, this message translates to:
  /// **'{hp} HP, retreat'**
  String eventCombatDefenderRetreatedResult(int hp);

  /// No description provided for @eventCombatHpResult.
  ///
  /// In en, this message translates to:
  /// **'{hp} HP'**
  String eventCombatHpResult(int hp);

  /// No description provided for @eventCombatTerrainModifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Terrain {terrain}'**
  String eventCombatTerrainModifierLabel(Object terrain);

  /// No description provided for @eventCombatTechModifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Technology {technology}'**
  String eventCombatTechModifierLabel(Object technology);

  /// No description provided for @eventCombatRankModifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank}'**
  String eventCombatRankModifierLabel(Object rank);

  /// No description provided for @eventCombatCityGarrisonModifier.
  ///
  /// In en, this message translates to:
  /// **'City garrison'**
  String get eventCombatCityGarrisonModifier;

  /// No description provided for @eventCombatMixedArmyModifier.
  ///
  /// In en, this message translates to:
  /// **'Mixed army'**
  String get eventCombatMixedArmyModifier;

  /// No description provided for @eventCombatStatAttack.
  ///
  /// In en, this message translates to:
  /// **'attack'**
  String get eventCombatStatAttack;

  /// No description provided for @eventCombatStatDefense.
  ///
  /// In en, this message translates to:
  /// **'defense'**
  String get eventCombatStatDefense;

  /// No description provided for @eventCombatStatHp.
  ///
  /// In en, this message translates to:
  /// **'HP'**
  String get eventCombatStatHp;

  /// No description provided for @eventCombatStatRange.
  ///
  /// In en, this message translates to:
  /// **'range'**
  String get eventCombatStatRange;

  /// No description provided for @eventCombatStatMobility.
  ///
  /// In en, this message translates to:
  /// **'movement'**
  String get eventCombatStatMobility;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'nl',
    'pl',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
