import 'package:aonw/game/application/services/game_event_descriptor.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:flutter/material.dart';

enum ActivityLogFilter { all, combat, city, diplomacy, technology }

extension ActivityLogFilterPresentation on ActivityLogFilter {
  String label(AppLocalizations l10n) {
    return switch (this) {
      ActivityLogFilter.all => l10n.activityLogFilterAll,
      ActivityLogFilter.combat => l10n.activityLogFilterCombat,
      ActivityLogFilter.city => l10n.activityLogFilterCities,
      ActivityLogFilter.diplomacy => l10n.activityLogFilterDiplomacy,
      ActivityLogFilter.technology => l10n.activityLogFilterTechnology,
    };
  }

  String shortLabel(AppLocalizations l10n) {
    return switch (this) {
      ActivityLogFilter.all => l10n.activityLogFilterAllShort,
      ActivityLogFilter.combat => l10n.activityLogFilterCombat,
      ActivityLogFilter.city => l10n.activityLogFilterCities,
      ActivityLogFilter.diplomacy => l10n.activityLogFilterDiplomacyShort,
      ActivityLogFilter.technology => l10n.activityLogFilterTechnology,
    };
  }

  String emptyLabel(AppLocalizations l10n) {
    return switch (this) {
      ActivityLogFilter.all => l10n.activityLogEmptyAllTitle,
      ActivityLogFilter.combat => l10n.activityLogEmptyCombatTitle,
      ActivityLogFilter.city => l10n.activityLogEmptyCityTitle,
      ActivityLogFilter.diplomacy => l10n.activityLogEmptyDiplomacyTitle,
      ActivityLogFilter.technology => l10n.activityLogEmptyTechnologyTitle,
    };
  }

  String emptyBody(AppLocalizations l10n) {
    return switch (this) {
      ActivityLogFilter.all => l10n.activityLogEmptyAllBody,
      ActivityLogFilter.combat => l10n.activityLogEmptyCombatBody,
      ActivityLogFilter.city => l10n.activityLogEmptyCityBody,
      ActivityLogFilter.diplomacy => l10n.activityLogEmptyDiplomacyBody,
      ActivityLogFilter.technology => l10n.activityLogEmptyTechnologyBody,
    };
  }

  GameIconData get emptyIcon => switch (this) {
    ActivityLogFilter.all => GameIcons.activityLog,
    ActivityLogFilter.combat => GameIcons.attack,
    ActivityLogFilter.city => GameIcons.cityFilled,
    ActivityLogFilter.diplomacy => GameIcons.diplomacy,
    ActivityLogFilter.technology => GameIcons.science,
  };

  Color get emptyAccent => switch (this) {
    ActivityLogFilter.all => GameUiTheme.gold,
    ActivityLogFilter.combat => GameUiTheme.danger,
    ActivityLogFilter.city => GameUiTheme.resourcesAccent,
    ActivityLogFilter.diplomacy => GameUiTheme.info,
    ActivityLogFilter.technology => GameUiTheme.scienceAccent,
  };

  bool matches(GameEvent event) {
    final categories = GameEventDescriptor.forEvent(event).activityCategories;
    return switch (this) {
      ActivityLogFilter.all => true,
      ActivityLogFilter.combat => categories.contains(
        GameEventActivityCategory.combat,
      ),
      ActivityLogFilter.city => categories.contains(
        GameEventActivityCategory.city,
      ),
      ActivityLogFilter.diplomacy => categories.contains(
        GameEventActivityCategory.diplomacy,
      ),
      ActivityLogFilter.technology => categories.contains(
        GameEventActivityCategory.technology,
      ),
    };
  }
}
