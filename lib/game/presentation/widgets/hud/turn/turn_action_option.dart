part of 'turn_action_hint.dart';

class HudTurnActionOption {
  const HudTurnActionOption({
    required this.index,
    required this.label,
    required this.kindLabel,
    this.thumbnail,
  });

  final int index;
  final String label;
  final String kindLabel;
  final HudTurnActionThumbnail? thumbnail;

  factory HudTurnActionOption.fromTarget({
    required int index,
    required TurnActionTarget target,
    required AppLocalizations l10n,
    required TechnologyPanelViewModel technologyViewModel,
  }) {
    return switch (target) {
      UnitTurnActionTarget(:final unit) => HudTurnActionOption(
        index: index,
        label: GameDisplayNames.unitWithType(l10n, unit),
        kindLabel: l10n.turnActionUnitKind,
        thumbnail: HudTurnActionThumbnail.unit(unit.type),
      ),
      CityProductionTurnActionTarget(:final city) => HudTurnActionOption(
        index: index,
        label: l10n.turnActionCityProductionLabel(
          GameDisplayNames.city(l10n, city),
        ),
        kindLabel: l10n.turnActionCityProductionKind,
        thumbnail: HudTurnActionThumbnail.city(
          cityVisualLevel: _cityActionVisualLevel(city),
        ),
      ),
      ResearchTurnActionTarget() => HudTurnActionOption(
        index: index,
        label: l10n.turnActionResearchLabel,
        kindLabel: l10n.turnActionResearchKind,
        thumbnail: HudTurnActionThumbnail.research(
          technologyViewModel.recommendedTechnologies.firstOrNull?.id,
        ),
      ),
    };
  }
}

enum HudTurnActionThumbnailKind { unit, city, research }

class HudTurnActionThumbnail {
  const HudTurnActionThumbnail.unit(GameUnitType type)
    : kind = HudTurnActionThumbnailKind.unit,
      unitType = type,
      cityVisualLevel = null,
      cityTechnologyProfileIndex = null,
      technologyId = null;

  const HudTurnActionThumbnail.city({
    this.cityVisualLevel = 0,
    this.cityTechnologyProfileIndex = 0,
  }) : kind = HudTurnActionThumbnailKind.city,
       unitType = null,
       technologyId = null;

  const HudTurnActionThumbnail.research([this.technologyId])
    : kind = HudTurnActionThumbnailKind.research,
      unitType = null,
      cityVisualLevel = null,
      cityTechnologyProfileIndex = null;

  final HudTurnActionThumbnailKind kind;
  final GameUnitType? unitType;
  final int? cityVisualLevel;
  final int? cityTechnologyProfileIndex;
  final TechnologyId? technologyId;
}

int _cityActionVisualLevel(GameCity city) {
  if (city.population >= 10) return 3;
  if (city.population >= 6) return 2;
  if (city.population >= 4) return 1;
  return 0;
}
