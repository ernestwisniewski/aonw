import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_resource_value_card.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

class SelectionResourceImprovementAssessment {
  const SelectionResourceImprovementAssessment({
    required this.improvementType,
    required this.improvementYield,
    required this.requiredTechnology,
    required this.technologyUnlocked,
    required this.improvementTitle,
    required this.statusLabel,
    required this.statusKind,
    required this.requiredTechnologyName,
  });

  final FieldImprovementType? improvementType;
  final TileYield improvementYield;
  final TechnologyDefinition? requiredTechnology;
  final bool technologyUnlocked;
  final String improvementTitle;
  final String statusLabel;
  final SelectionResourceImprovementStatusKind statusKind;
  final String? requiredTechnologyName;

  static SelectionResourceImprovementAssessment from({
    required ResourceType resource,
    required MapTileView tile,
    required GameClientState? gameState,
    required AppLocalizations l10n,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required String Function(FieldImprovementType type) improvementName,
    required String Function(TechnologyId id) technologyName,
    required String Function(GameCity city) cityName,
  }) {
    final improvementType = _preferredImprovement(
      resource: resource,
      tile: tile,
      ruleset: cityRuleset,
    );
    final requiredTechnology = improvementType == null
        ? null
        : TechnologyUnlockQuery.unlockingTechnologyForFieldImprovement(
            improvementType: improvementType,
            ruleset: technologyRuleset,
          );
    final technologyUnlocked = requiredTechnology == null
        ? true
        : _hasTechnologyUnlocked(gameState, requiredTechnology.id);
    final cityStatus = _cityStatus(
      tile: tile,
      gameState: gameState,
      l10n: l10n,
      cityName: cityName,
    );
    final status = _status(
      improvementType: improvementType,
      requiredTechnology: requiredTechnology,
      technologyUnlocked: technologyUnlocked,
      technologyName: technologyName,
      l10n: l10n,
      cityStatus: cityStatus,
    );
    return SelectionResourceImprovementAssessment(
      improvementType: improvementType,
      improvementYield: improvementType == null
          ? TileYield.zero
          : FieldImprovementRules.yieldFor(
              improvementType,
              ruleset: cityRuleset,
            ),
      requiredTechnology: requiredTechnology,
      technologyUnlocked: technologyUnlocked,
      improvementTitle: improvementType == null
          ? l10n.resourceValueNoMatchingImprovement
          : improvementName(improvementType),
      statusLabel: status.label,
      statusKind: status.kind,
      requiredTechnologyName: status.requiredTechnologyName,
    );
  }

  static FieldImprovementType? _preferredImprovement({
    required ResourceType resource,
    required MapTileView tile,
    required CityRuleset ruleset,
  }) {
    final specialistTypes = <FieldImprovementType>{
      for (final definition in ruleset.improvements.values)
        if (definition.resourceSpecialist &&
            definition.requirements.whereType<RequiresAnyResource>().any(
              (requirement) => requirement.resources.contains(resource),
            ))
          definition.type,
    };
    return FieldImprovementRules.preferredFor(
          tile,
          ruleset: ruleset,
          allowedTypes: specialistTypes,
        ) ??
        FieldImprovementRules.preferredFor(tile, ruleset: ruleset);
  }

  static _TileCityStatus _cityStatus({
    required MapTileView tile,
    required GameClientState? gameState,
    required AppLocalizations l10n,
    required String Function(GameCity city) cityName,
  }) {
    if (gameState == null) return _TileCityStatus.noSelection(l10n);
    final hex = CityHex(col: tile.col, row: tile.row);
    if (gameState.fieldImprovements.any((item) => item.hex == hex)) {
      return _TileCityStatus.alreadyImproved(l10n);
    }
    if (gameState.cities.any((city) => city.center == hex)) {
      return _TileCityStatus.cityCenter(l10n);
    }
    final city = WorkerImprovementRules.cityForImprovementHex(
      playerId: gameState.activePlayerId,
      hex: hex,
      cities: gameState.cities,
    );
    if (city != null) {
      return _TileCityStatus.available(l10n, cityName(city));
    }
    return _TileCityStatus.outsideBorders(l10n);
  }

  static bool _hasTechnologyUnlocked(
    GameClientState? gameState,
    TechnologyId technologyId,
  ) {
    if (gameState == null) return false;
    return gameState.research
        .forPlayer(gameState.activePlayerId)
        .hasUnlocked(technologyId);
  }

  static _ImprovementStatus _status({
    required FieldImprovementType? improvementType,
    required TechnologyDefinition? requiredTechnology,
    required bool technologyUnlocked,
    required String Function(TechnologyId id) technologyName,
    required AppLocalizations l10n,
    required _TileCityStatus cityStatus,
  }) {
    if (improvementType == null) return _ImprovementStatus.noLegalTile(l10n);
    if (!cityStatus.hasCityAccess) {
      return _ImprovementStatus(
        label: cityStatus.requirement,
        kind: cityStatus.kind,
      );
    }
    if (!technologyUnlocked && requiredTechnology != null) {
      final name = technologyName(requiredTechnology.id);
      return _ImprovementStatus.requiresTechnology(l10n, name);
    }
    return _ImprovementStatus.available(l10n);
  }
}

class _TileCityStatus {
  const _TileCityStatus({
    required this.requirement,
    required this.hasCityAccess,
    required this.kind,
  });

  final String requirement;
  final bool hasCityAccess;
  final SelectionResourceImprovementStatusKind kind;

  factory _TileCityStatus.noSelection(AppLocalizations l10n) => _TileCityStatus(
    requirement: l10n.resourceValueSelectWorkerOrCity,
    hasCityAccess: false,
    kind: SelectionResourceImprovementStatusKind.selectWorkerOrCity,
  );

  factory _TileCityStatus.alreadyImproved(AppLocalizations l10n) =>
      _TileCityStatus(
        requirement: l10n.resourceValueTileAlreadyImproved,
        hasCityAccess: false,
        kind: SelectionResourceImprovementStatusKind.tileAlreadyImproved,
      );

  factory _TileCityStatus.cityCenter(AppLocalizations l10n) => _TileCityStatus(
    requirement: l10n.resourceValueCityCenter,
    hasCityAccess: false,
    kind: SelectionResourceImprovementStatusKind.cityCenter,
  );

  factory _TileCityStatus.available(AppLocalizations l10n, String cityName) =>
      _TileCityStatus(
        requirement: l10n.resourceValueWorksForCity(cityName),
        hasCityAccess: true,
        kind: SelectionResourceImprovementStatusKind.availableForWorker,
      );

  factory _TileCityStatus.outsideBorders(AppLocalizations l10n) =>
      _TileCityStatus(
        requirement: l10n.resourceValueOutsideCityBorders,
        hasCityAccess: false,
        kind: SelectionResourceImprovementStatusKind.outsideCityBorders,
      );
}

class _ImprovementStatus {
  const _ImprovementStatus({
    required this.label,
    required this.kind,
    this.requiredTechnologyName,
  });

  final String label;
  final SelectionResourceImprovementStatusKind kind;
  final String? requiredTechnologyName;

  factory _ImprovementStatus.noLegalTile(AppLocalizations l10n) =>
      _ImprovementStatus(
        label: l10n.resourceValueNoLegalImprovementForTile,
        kind: SelectionResourceImprovementStatusKind.noLegalImprovementForTile,
      );

  factory _ImprovementStatus.requiresTechnology(
    AppLocalizations l10n,
    String name,
  ) => _ImprovementStatus(
    label: l10n.resourceValueRequiresTechnology(name),
    kind: SelectionResourceImprovementStatusKind.requiresTechnology,
    requiredTechnologyName: name,
  );

  factory _ImprovementStatus.available(AppLocalizations l10n) =>
      _ImprovementStatus(
        label: l10n.resourceValueAvailableForWorker,
        kind: SelectionResourceImprovementStatusKind.availableForWorker,
      );
}
