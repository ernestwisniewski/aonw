import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:aonw/l10n/game_text.dart';

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
