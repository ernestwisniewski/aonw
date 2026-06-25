import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_sections.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_statistics.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_view_model.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class EmpireOverviewContent extends StatelessWidget {
  const EmpireOverviewContent({
    required this.viewModel,
    required this.l10n,
    required this.compact,
    required this.onUnitSelected,
    required this.onCitySelected,
    super.key,
  });

  final EmpireOverviewViewModel viewModel;
  final AppLocalizations l10n;
  final bool compact;
  final ValueChanged<GameUnit> onUnitSelected;
  final ValueChanged<GameCity> onCitySelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 14,
        14,
        compact ? 10 : 14,
        14,
      ),
      child: compact
          ? Column(
              children: [
                EmpireStatisticsPanel(
                  viewModel: viewModel,
                  l10n: l10n,
                  compact: compact,
                ),
                const SizedBox(height: 16),
                EmpireUnitsSection(
                  groups: viewModel.unitGroups,
                  l10n: l10n,
                  onUnitSelected: onUnitSelected,
                ),
                const SizedBox(height: 16),
                EmpireCitiesSection(
                  cities: viewModel.cities,
                  storedArtifactsByCityId: viewModel.storedArtifactsByCityId,
                  l10n: l10n,
                  onCitySelected: onCitySelected,
                ),
              ],
            )
          : Column(
              children: [
                EmpireStatisticsPanel(
                  viewModel: viewModel,
                  l10n: l10n,
                  compact: compact,
                ),
                const SizedBox(height: 16),
                EmpireUnitsSection(
                  groups: viewModel.unitGroups,
                  l10n: l10n,
                  onUnitSelected: onUnitSelected,
                ),
                const SizedBox(height: 16),
                EmpireCitiesSection(
                  cities: viewModel.cities,
                  storedArtifactsByCityId: viewModel.storedArtifactsByCityId,
                  l10n: l10n,
                  onCitySelected: onCitySelected,
                ),
              ],
            ),
    );
  }
}
