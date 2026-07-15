import 'package:aonw_core/game/domain/city/city_production_target.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/wonder/wonder_registry.dart';
import 'package:aonw_core/game/domain/wonder/wonder_requirement.dart';
import 'package:aonw_core/game/domain/wonder/wonder_requirement_rules.dart';
import 'package:aonw_core/game/domain/wonder/wonder_ruleset.dart';
import 'package:aonw_core/game/domain/wonder/wonder_type.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

enum WonderAvailabilityStatus {
  available,
  completed,
  technologyLocked,
  requirementsMissing,
  playerAlreadyBuildingWonder,
  cityAlreadyBuildingWonder,
}

class WonderAvailability {
  const WonderAvailability({
    required this.status,
    this.completedBy,
    this.missingRequirements = const [],
  });

  final WonderAvailabilityStatus status;
  final String? completedBy;
  final List<WonderRequirement> missingRequirements;

  bool get isAvailable => status == WonderAvailabilityStatus.available;
}

abstract final class WonderAvailabilityPolicy {
  static WonderAvailability availabilityFor({
    required GameCity city,
    required WonderType wonderType,
    required Iterable<GameCity> cities,
    required WonderRegistry registry,
    required ResearchState research,
    required MapTileLookup mapTiles,
    WonderRuleset ruleset = WonderRuleset.standard,
  }) {
    final completedBy = registry.ownerOf(wonderType);
    if (completedBy != null) {
      return WonderAvailability(
        status: WonderAvailabilityStatus.completed,
        completedBy: completedBy,
      );
    }

    final definition = ruleset.definitionFor(wonderType);
    if (!research
        .forPlayer(city.ownerPlayerId)
        .hasUnlocked(definition.unlockTech)) {
      return const WonderAvailability(
        status: WonderAvailabilityStatus.technologyLocked,
      );
    }

    final missingRequirements = WonderRequirementRules.missingRequirements(
      city: city,
      wonderType: wonderType,
      mapTiles: mapTiles,
      ruleset: ruleset,
      research: research,
    );
    if (missingRequirements.isNotEmpty) {
      return WonderAvailability(
        status: WonderAvailabilityStatus.requirementsMissing,
        missingRequirements: missingRequirements,
      );
    }

    final activeWonder = switch (city.productionQueue?.target) {
      WonderProductionTarget() => true,
      _ => false,
    };
    if (activeWonder) {
      return const WonderAvailability(
        status: WonderAvailabilityStatus.cityAlreadyBuildingWonder,
      );
    }

    for (final otherCity in cities) {
      if (otherCity.ownerPlayerId != city.ownerPlayerId) continue;
      if (otherCity.id == city.id) continue;
      if (otherCity.productionQueue?.target case WonderProductionTarget()) {
        return const WonderAvailability(
          status: WonderAvailabilityStatus.playerAlreadyBuildingWonder,
        );
      }
    }

    return const WonderAvailability(status: WonderAvailabilityStatus.available);
  }
}
