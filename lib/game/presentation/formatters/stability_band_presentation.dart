import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:flutter/material.dart';

/// Single source of the [StabilityBand] presentation shared by the HUD pill,
/// the resource breakdown popup and event notifications.
abstract final class StabilityBandPresentation {
  static String label(AppLocalizations l10n, StabilityBand band) {
    return switch (band) {
      StabilityBand.content => l10n.stabilityBandContent,
      StabilityBand.stable => l10n.stabilityBandStable,
      StabilityBand.strained => l10n.stabilityBandStrained,
      StabilityBand.unrest => l10n.stabilityBandUnrest,
    };
  }

  static Color color(StabilityBand band) {
    return switch (band) {
      StabilityBand.content => GameUiTheme.success,
      StabilityBand.stable => GameUiTheme.gold,
      StabilityBand.strained => GameUiTheme.warning,
      StabilityBand.unrest => GameUiTheme.danger,
    };
  }
}
