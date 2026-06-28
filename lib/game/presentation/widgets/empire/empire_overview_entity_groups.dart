import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_view_model.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_type_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

part 'empire_overview_group_shell.dart';

class EmpireUnitGroupBlock extends StatelessWidget {
  const EmpireUnitGroupBlock({
    required this.group,
    required this.l10n,
    required this.onUnitSelected,
    super.key,
  });

  final EmpireUnitGroup group;
  final AppLocalizations l10n;
  final ValueChanged<GameUnit> onUnitSelected;

  @override
  Widget build(BuildContext context) {
    final label = GameDisplayNames.unitType(l10n, group.type);
    final first = group.units.first;
    return _GroupShell(
      icon: gameIconForUnitType(group.type),
      title: label,
      subtitle: empireUnitGroupSubtitle(l10n, group),
      focusTooltip: l10n.empireShowFirstUnitTooltip,
      onTap: () => onUnitSelected(first),
      children: [
        for (final unit in group.units)
          _EmpireEntityRow(
            key: Key('empire.unit.${unit.id}'),
            icon: gameIconForUnitType(unit.type),
            title: GameDisplayNames.unit(l10n, unit),
            subtitle: empireUnitSubtitle(l10n, unit),
            focusTooltip: l10n.empireShowUnitTooltip,
            onTap: () => onUnitSelected(unit),
          ),
      ],
    );
  }
}

class EmpireCityGroupBlock extends StatelessWidget {
  const EmpireCityGroupBlock({
    required this.cities,
    required this.storedArtifactsByCityId,
    required this.l10n,
    required this.onCitySelected,
    super.key,
  });

  final List<GameCity> cities;
  final Map<String, WorldArtifact> storedArtifactsByCityId;
  final AppLocalizations l10n;
  final ValueChanged<GameCity> onCitySelected;

  @override
  Widget build(BuildContext context) {
    final first = cities.first;
    return _GroupShell(
      icon: GameIcons.cityFilled,
      title: l10n.empireCityCenters,
      subtitle: empireCityGroupSubtitle(l10n, cities),
      focusTooltip: l10n.empireShowFirstCityTooltip,
      onTap: () => onCitySelected(first),
      children: [
        for (final city in cities)
          _EmpireEntityRow(
            key: Key('empire.city.${city.id}'),
            icon: GameIcons.city,
            title: GameDisplayNames.city(l10n, city),
            subtitle: empireCitySubtitle(
              l10n,
              city,
              storedArtifact: storedArtifactsByCityId[city.id],
            ),
            badgeIcon: storedArtifactsByCityId.containsKey(city.id)
                ? GameIcons.artifact
                : null,
            badgeTooltip: storedArtifactsByCityId[city.id] == null
                ? null
                : l10n.empireCityStoredArtifact(
                    GameDisplayNames.worldArtifact(
                      l10n,
                      storedArtifactsByCityId[city.id]!.type,
                    ),
                  ),
            focusTooltip: l10n.empireShowCityTooltip,
            onTap: () => onCitySelected(city),
          ),
      ],
    );
  }
}
