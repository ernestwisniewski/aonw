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

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;
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
