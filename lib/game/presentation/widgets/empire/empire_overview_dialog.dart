import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_content.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_header.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_view_model.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class EmpireOverviewDialog extends StatelessWidget {
  final GameState state;
  final String activePlayerId;
  final MapData? mapData;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final PaceBalance paceBalance;
  final ValueChanged<GameUnit> onUnitSelected;
  final ValueChanged<GameCity> onCitySelected;

  const EmpireOverviewDialog({
    required this.state,
    required this.activePlayerId,
    this.mapData,
    this.cityRuleset = CityRulesets.standard,
    this.technologyRuleset = TechnologyRulesets.standard,
    this.paceBalance = PaceBalance.unlimited,
    required this.onUnitSelected,
    required this.onCitySelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return EmpireOverviewPanel(
      state: state,
      activePlayerId: activePlayerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
      maxHeight: size.height * .82,
      onUnitSelected: onUnitSelected,
      onCitySelected: onCitySelected,
      onClose: () => Navigator.of(context).maybePop(),
    );
  }
}

class EmpireOverviewPanel extends StatelessWidget {
  final GameState state;
  final String activePlayerId;
  final MapData? mapData;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final PaceBalance paceBalance;
  final double? maxHeight;
  final ValueChanged<GameUnit> onUnitSelected;
  final ValueChanged<GameCity> onCitySelected;
  final VoidCallback onClose;

  const EmpireOverviewPanel({
    required this.state,
    required this.activePlayerId,
    this.mapData,
    this.cityRuleset = CityRulesets.standard,
    this.technologyRuleset = TechnologyRulesets.standard,
    this.paceBalance = PaceBalance.unlimited,
    this.maxHeight,
    required this.onUnitSelected,
    required this.onCitySelected,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 620;
    final viewModel = EmpireOverviewViewModel.fromState(
      state,
      activePlayerId: activePlayerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 860,
        maxHeight: maxHeight ?? size.height * .82,
      ),
      child: GameModalScaffold(
        surfaceKey: const Key('empireOverviewPanel.surface'),
        size: GameModalSize.wide,
        showCornerDiamonds: false,
        contentPadding: EdgeInsets.zero,
        centerInAvailableSpace: false,
        scrollable: false,
        content: Column(
          children: [
            EmpireOverviewHeader(
              subtitle: viewModel.subtitle(l10n),
              onClose: onClose,
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: SurfaceElevation.flat.strokeColor(
                color: GameUiTheme.copper,
                alpha: 90,
              ),
            ),
            Expanded(
              child: EmpireOverviewContent(
                viewModel: viewModel,
                l10n: l10n,
                compact: compact,
                onUnitSelected: onUnitSelected,
                onCitySelected: onCitySelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
