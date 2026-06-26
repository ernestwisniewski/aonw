import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_entity_groups.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_view_model.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_empty_state.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class EmpireUnitsSection extends StatelessWidget {
  const EmpireUnitsSection({
    required this.groups,
    required this.l10n,
    required this.onUnitSelected,
    super.key,
  });

  final List<EmpireUnitGroup> groups;
  final AppLocalizations l10n;
  final ValueChanged<GameUnit> onUnitSelected;

  @override
  Widget build(BuildContext context) {
    final unitCount = groups.fold<int>(
      0,
      (count, group) => count + group.units.length,
    );
    return _EmpireSection(
      icon: GameIcons.army,
      title: l10n.unitsSection,
      countLabel: 'x$unitCount',
      accent: GameUiTheme.gold,
      emptyTitle: l10n.empireUnitsEmptyTitle,
      emptyBody: l10n.empireUnitsEmptyBody,
      isEmpty: groups.isEmpty,
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          EmpireUnitGroupBlock(
            group: groups[i],
            l10n: l10n,
            onUnitSelected: onUnitSelected,
          ),
        ],
      ],
    );
  }
}

class EmpireCitiesSection extends StatelessWidget {
  const EmpireCitiesSection({
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
    return _EmpireSection(
      icon: GameIcons.cityFilled,
      title: l10n.commonCities,
      countLabel: 'x${cities.length}',
      accent: GameUiTheme.resourcesAccent,
      emptyTitle: l10n.empireCitiesEmptyTitle,
      emptyBody: l10n.empireCitiesEmptyBody,
      isEmpty: cities.isEmpty,
      children: [
        if (cities.isNotEmpty)
          EmpireCityGroupBlock(
            cities: cities,
            storedArtifactsByCityId: storedArtifactsByCityId,
            l10n: l10n,
            onCitySelected: onCitySelected,
          ),
      ],
    );
  }
}

class _EmpireSection extends StatelessWidget {
  const _EmpireSection({
    required this.icon,
    required this.title,
    required this.countLabel,
    required this.accent,
    required this.isEmpty,
    required this.emptyTitle,
    required this.emptyBody,
    required this.children,
  });

  final GameIconData icon;
  final String title;
  final String countLabel;
  final Color accent;
  final bool isEmpty;
  final String emptyTitle;
  final String emptyBody;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        accent: accent,
        background: GameUiTheme.surface,
        backgroundAlpha: 74,
        border: BorderEmphasis.regular,
        borderAlpha: 108,
        borderRadius: BorderRadius.circular(8),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EmpireSectionHeader(
              icon: icon,
              title: title,
              countLabel: countLabel,
              accent: accent,
            ),
            const SizedBox(height: 10),
            if (isEmpty)
              _EmptyEmpireState(icon: icon, title: emptyTitle, body: emptyBody)
            else
              ...children,
          ],
        ),
      ),
    );
  }
}

class _EmpireSectionHeader extends StatelessWidget {
  const _EmpireSectionHeader({
    required this.icon,
    required this.title,
    required this.countLabel,
    required this.accent,
  });

  final GameIconData icon;
  final String title;
  final String countLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GameIcon(
          icon,
          key: Key('empireSectionHeader.$title.icon'),
          size: GameIconSize.small,
          color: accent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.sectionHeader.copyWith(
              color: accent,
              fontSize: 11,
            ),
          ),
        ),
        DecoratedBox(
          decoration: SurfaceElevation.flat.decoration(
            background: accent,
            backgroundAlpha: 22,
            borderColor: accent,
            border: BorderEmphasis.subtle,
            borderRadius: BorderRadius.circular(4),
            includeShadow: false,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            child: Text(
              countLabel,
              style: const TextStyle(
                color: GameUiTheme.textBright,
                fontFamily: GameUiTheme.bodyFont,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyEmpireState extends StatelessWidget {
  const _EmptyEmpireState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final GameIconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return HudPanelEmptyState(
      icon: icon,
      title: title,
      body: body,
      accent: GameUiTheme.gold,
      compact: false,
      padding: const EdgeInsets.all(14),
    );
  }
}
