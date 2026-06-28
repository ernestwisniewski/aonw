import 'dart:math' as math;

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_type_icon.dart';
import 'package:aonw/game/presentation/widgets/unit/unit_details_panel.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_layout.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class TechnologyInlineTechnologyDetailsLayer extends StatelessWidget {
  const TechnologyInlineTechnologyDetailsLayer({
    required this.card,
    required this.l10n,
    required this.cityRuleset,
    required this.technologyRuleset,
    required this.compact,
    required this.onClose,
    super.key,
  });

  final TechnologyCardViewModel card;
  final AppLocalizations l10n;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final bool compact;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return _TechnologyInlineDetailsLayer(
      compact: compact,
      childBuilder: (maxWidth, maxHeight) => TechnologyDetailsPanel(
        card: card,
        l10n: l10n,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        onClose: onClose,
      ),
    );
  }
}

class TechnologyInlineCityBuildingDetailsLayer extends StatelessWidget {
  const TechnologyInlineCityBuildingDetailsLayer({
    required this.buildingType,
    required this.l10n,
    required this.cityRuleset,
    required this.technologyRuleset,
    required this.compact,
    required this.onClose,
    super.key,
  });

  final CityBuildingType buildingType;
  final AppLocalizations l10n;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final bool compact;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final definition = cityRuleset.buildingDefinitionFor(buildingType);
    return _TechnologyInlineDetailsLayer(
      compact: compact,
      childBuilder: (maxWidth, maxHeight) {
        return CityBuildingDetailsPanel(
          buildingType: buildingType,
          definition: definition,
          unlockingTechnology:
              TechnologyUnlockQuery.unlockingTechnologyForBuilding(
                buildingType: buildingType,
                ruleset: technologyRuleset,
              ),
          l10n: l10n,
          title: GameDisplayNames.cityBuilding(l10n, buildingType),
          emoji: CityBuildingsPanelViewModelFactory.emojiFor(buildingType),
          statusLabel: l10n.technologyDetailsUnlockStatus,
          costLabel: l10n.cityProductionCostShort(definition.productionCost),
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          onClose: onClose,
        );
      },
    );
  }
}

class TechnologyInlineUnitDetailsLayer extends StatelessWidget {
  const TechnologyInlineUnitDetailsLayer({
    required this.unitType,
    required this.l10n,
    required this.cityRuleset,
    required this.technologyRuleset,
    required this.compact,
    required this.onClose,
    super.key,
  });

  final GameUnitType unitType;
  final AppLocalizations l10n;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final bool compact;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final definition = _unitDefinitionFor(unitType);
    return _TechnologyInlineDetailsLayer(
      compact: compact,
      childBuilder: (maxWidth, maxHeight) {
        return UnitDetailsPanel(
          unitType: unitType,
          unlockingTechnology: TechnologyUnlockQuery.unlockingTechnologyForUnit(
            unitType: unitType,
            ruleset: technologyRuleset,
          ),
          l10n: l10n,
          title: GameDisplayNames.unitType(l10n, unitType),
          icon: gameIconForUnitType(unitType),
          statusLabel: l10n.technologyDetailsUnlockStatus,
          costLabel: definition == null
              ? null
              : l10n.cityProductionCostShort(definition.productionCost),
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          onClose: onClose,
        );
      },
    );
  }

  UnitProductionDefinition? _unitDefinitionFor(GameUnitType unitType) {
    try {
      return cityRuleset.unitDefinitionFor(unitType);
    } on ArgumentError {
      return null;
    }
  }
}

class _TechnologyInlineDetailsLayer extends StatelessWidget {
  const _TechnologyInlineDetailsLayer({
    required this.compact,
    required this.childBuilder,
  });

  final bool compact;
  final Widget Function(double maxWidth, double maxHeight) childBuilder;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SurfaceElevation.flat.fill(background: GameUiTheme.bg, alpha: 188),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = compact ? 8.0 : 14.0;
          final maxWidth = compact
              ? math.max(260.0, constraints.maxWidth - padding * 2)
              : 560.0;
          final maxHeight = GameModalLayout.inlineDetailsMaxHeight(
            availableHeight: constraints.maxHeight,
            padding: padding,
            compact: compact,
          );

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Align(
              alignment: Alignment.topCenter,
              child: childBuilder(maxWidth, maxHeight),
            ),
          );
        },
      ),
    );
  }
}
