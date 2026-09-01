import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'aonw_localizations_en.dart';
import 'aonw_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AonwLocalizations
/// returned by `AonwLocalizations.of(context)`.
///
/// Applications need to include `AonwLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/aonw_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AonwLocalizations.localizationsDelegates,
///   supportedLocales: AonwLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AonwLocalizations.supportedLocales
/// property.
abstract class AonwLocalizations {
  AonwLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AonwLocalizations of(BuildContext context) {
    return Localizations.of<AonwLocalizations>(context, AonwLocalizations)!;
  }

  static const LocalizationsDelegate<AonwLocalizations> delegate =
      _AonwLocalizationsDelegate();

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
    Locale('en'),
    Locale('pl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Age of New Worlds'**
  String get appTitle;

  /// No description provided for @unknownRouteLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown route'**
  String get unknownRouteLabel;

  /// No description provided for @pageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Page unavailable'**
  String get pageUnavailable;

  /// No description provided for @unknownRouteMessage.
  ///
  /// In en, this message translates to:
  /// **'Unknown route: {location}'**
  String unknownRouteMessage(String location);

  /// No description provided for @missingRouteLocation.
  ///
  /// In en, this message translates to:
  /// **'(missing)'**
  String get missingRouteLocation;

  /// No description provided for @mapSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Map {mapId}, {cols} by {rows} hexes'**
  String mapSemanticsLabel(String mapId, int cols, int rows);

  /// No description provided for @mapInputHint.
  ///
  /// In en, this message translates to:
  /// **'Use the arrow keys or D-pad to move the map cursor and Enter or A to select.'**
  String get mapInputHint;

  /// No description provided for @noHexSelected.
  ///
  /// In en, this message translates to:
  /// **'No hex selected'**
  String get noHexSelected;

  /// No description provided for @selectedHex.
  ///
  /// In en, this message translates to:
  /// **'Selected hex {col}, {row}'**
  String selectedHex(int col, int row);

  /// No description provided for @hideReferenceLayer.
  ///
  /// In en, this message translates to:
  /// **'Hide reference layer'**
  String get hideReferenceLayer;

  /// No description provided for @showReferenceLayer.
  ///
  /// In en, this message translates to:
  /// **'Show reference layer'**
  String get showReferenceLayer;

  /// No description provided for @hexLabel.
  ///
  /// In en, this message translates to:
  /// **'Hex {col}, {row}'**
  String hexLabel(int col, int row);

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit {unitId}'**
  String unitLabel(String unitId);

  /// No description provided for @routeSummary.
  ///
  /// In en, this message translates to:
  /// **'Route: {totalCost} movement units · {remaining} remaining'**
  String routeSummary(int totalCost, int remaining);

  /// No description provided for @confirmMove.
  ///
  /// In en, this message translates to:
  /// **'Confirm move'**
  String get confirmMove;

  /// No description provided for @chooseHighlightedDestination.
  ///
  /// In en, this message translates to:
  /// **'Choose a highlighted destination.'**
  String get chooseHighlightedDestination;

  /// No description provided for @movingUnit.
  ///
  /// In en, this message translates to:
  /// **'Moving unit'**
  String get movingUnit;

  /// No description provided for @turnLabel.
  ///
  /// In en, this message translates to:
  /// **'TURN {turn}'**
  String turnLabel(int turn);

  /// No description provided for @loadingMap.
  ///
  /// In en, this message translates to:
  /// **'Loading map'**
  String get loadingMap;

  /// No description provided for @mapLoadingFailed.
  ///
  /// In en, this message translates to:
  /// **'Map loading failed'**
  String get mapLoadingFailed;

  /// No description provided for @mapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Map unavailable'**
  String get mapUnavailable;

  /// No description provided for @mapAdapterUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The native game adapter is unavailable on this platform.'**
  String get mapAdapterUnavailable;

  /// No description provided for @mapClientIncompatible.
  ///
  /// In en, this message translates to:
  /// **'The native game adapter is incompatible with this client.'**
  String get mapClientIncompatible;

  /// No description provided for @mapLoadSuperseded.
  ///
  /// In en, this message translates to:
  /// **'A newer map request replaced this one.'**
  String get mapLoadSuperseded;

  /// No description provided for @mapLoadFailure.
  ///
  /// In en, this message translates to:
  /// **'The map could not be loaded.'**
  String get mapLoadFailure;

  /// No description provided for @movementRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'The movement request could not be completed.'**
  String get movementRequestFailed;

  /// No description provided for @movementResponseIncompatible.
  ///
  /// In en, this message translates to:
  /// **'The movement response is incompatible with this client.'**
  String get movementResponseIncompatible;

  /// No description provided for @movementSessionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The local game session is unavailable.'**
  String get movementSessionUnavailable;

  /// No description provided for @moveRejectedStale.
  ///
  /// In en, this message translates to:
  /// **'The game state changed. Review the latest position and try again.'**
  String get moveRejectedStale;

  /// No description provided for @moveRejectedUnitUnavailable.
  ///
  /// In en, this message translates to:
  /// **'That unit is no longer available to move.'**
  String get moveRejectedUnitUnavailable;

  /// No description provided for @moveRejectedUnitBusy.
  ///
  /// In en, this message translates to:
  /// **'That unit is busy and cannot move now.'**
  String get moveRejectedUnitBusy;

  /// No description provided for @moveRejectedTargetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'That destination is not available.'**
  String get moveRejectedTargetUnavailable;

  /// No description provided for @moveRejectedMovementInsufficient.
  ///
  /// In en, this message translates to:
  /// **'The unit does not have enough movement remaining.'**
  String get moveRejectedMovementInsufficient;

  /// No description provided for @moveRejectedPathUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No valid route to that destination is available.'**
  String get moveRejectedPathUnavailable;

  /// No description provided for @moveRejectedInternal.
  ///
  /// In en, this message translates to:
  /// **'The move could not be applied. Try again.'**
  String get moveRejectedInternal;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @audioSettings.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audioSettings;

  /// No description provided for @masterVolume.
  ///
  /// In en, this message translates to:
  /// **'Master volume'**
  String get masterVolume;

  /// No description provided for @cameraSettings.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraSettings;

  /// No description provided for @cameraSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Zoom sensitivity'**
  String get cameraSensitivity;

  /// No description provided for @accessibilitySettings.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibilitySettings;

  /// No description provided for @reducedMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reducedMotion;

  /// No description provided for @reducedMotionDescription.
  ///
  /// In en, this message translates to:
  /// **'Avoid nonessential animations and transitions.'**
  String get reducedMotionDescription;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrast;

  /// No description provided for @highContrastDescription.
  ///
  /// In en, this message translates to:
  /// **'Increase contrast in the application interface.'**
  String get highContrastDescription;

  /// No description provided for @resetSettings.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults'**
  String get resetSettings;
}

class _AonwLocalizationsDelegate
    extends LocalizationsDelegate<AonwLocalizations> {
  const _AonwLocalizationsDelegate();

  @override
  Future<AonwLocalizations> load(Locale locale) {
    return SynchronousFuture<AonwLocalizations>(
      lookupAonwLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AonwLocalizationsDelegate old) => false;
}

AonwLocalizations lookupAonwLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AonwLocalizationsEn();
    case 'pl':
      return AonwLocalizationsPl();
  }

  throw FlutterError(
    'AonwLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
