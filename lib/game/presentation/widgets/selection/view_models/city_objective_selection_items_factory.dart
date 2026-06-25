import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_item.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

abstract final class CityObjectiveSelectionItemsFactory {
  static List<SelectionInfoItem> descriptionItems({
    required GameCity city,
    required MapData? mapData,
    required List<GameUnit> units,
    required AppLocalizations l10n,
  }) {
    if (mapData == null) return const [];
    final objectives = _controlledObjectives(city, mapData.objectives);
    final progress = MapObjectiveRules.snapshot(
      objectives: objectives,
      cities: [city],
      units: units,
    );
    return [
      for (final entry in progress.entries)
        SelectionInfoItem(
          icon: GameIcons.victory,
          label: GameDisplayNames.mapObjective(l10n, entry.definition.type),
          value: _objectiveValue(entry, l10n),
          color: _objectiveColor(entry),
        ),
    ];
  }

  static List<MapObjectiveDefinition> _controlledObjectives(
    GameCity city,
    Iterable<MapObjectiveDefinition> objectives,
  ) {
    return [
      for (final objective in objectives)
        if (_cityControlsHex(city, objective.hex)) objective,
    ];
  }

  static bool _cityControlsHex(GameCity city, CityHex hex) {
    if (city.center.col == hex.col && city.center.row == hex.row) return true;
    return city.controlledHexes.any(
      (controlled) => controlled.col == hex.col && controlled.row == hex.row,
    );
  }

  static String _objectiveValue(
    MapObjectiveProgress progress,
    AppLocalizations l10n,
  ) {
    final definition = progress.definition;
    final parts = [
      GameDisplayNames.mapObjectiveDescription(l10n, definition.type),
      _statusLabel(progress, l10n),
      if (definition.victoryPoints > 0)
        l10n.mapObjectiveRewardVictoryPoints(definition.victoryPoints),
      if (definition.goldPerTurn > 0)
        l10n.mapObjectiveRewardGoldPerTurn(definition.goldPerTurn),
    ];
    return parts.join(' • ');
  }

  static String _statusLabel(
    MapObjectiveProgress progress,
    AppLocalizations l10n,
  ) {
    if (progress.contested) return l10n.mapObjectiveStatusContested;
    if (progress.completed) {
      return l10n.mapObjectiveStatusCompleted(
        progress.holdTurns,
        progress.definition.requiredHoldTurns,
      );
    }
    if (progress.controlled) {
      return l10n.mapObjectiveStatusHolding(
        progress.holdTurns,
        progress.definition.requiredHoldTurns,
      );
    }
    return l10n.mapObjectiveStatusNeutral(
      progress.definition.requiredHoldTurns,
    );
  }

  static Color _objectiveColor(MapObjectiveProgress progress) {
    if (progress.contested) return GameUiTheme.warning;
    if (progress.completed) return GameUiTheme.success;
    if (progress.controlled) return GameUiTheme.gold;
    return GameUiTheme.textMuted;
  }
}
