import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

final class BasicStrategyResourceTradePlanner {
  const BasicStrategyResourceTradePlanner({
    this.goldPerTurn = 2,
    this.durationTurns = 8,
  });

  final int goldPerTurn;
  final int durationTurns;

  List<GameCommand> plan(GameView view) {
    if (view.rememberedEnemyCities.isEmpty) {
      return const [];
    }

    final missingResources = _missingStrategicResources(view);
    if (missingResources.isEmpty) return const [];

    final exporterCitiesByPlayer = _exporterCitiesByPlayer(view);
    final ownSurplusResources = _surplusResourcesFor(
      view: view,
      playerId: view.forPlayerId,
      cities: view.ownCities,
    );
    for (final resource in missingResources) {
      if (_hasActiveImport(view, resource)) continue;

      final exporter = _exporterFor(
        view: view,
        resource: resource,
        exporterCitiesByPlayer: exporterCitiesByPlayer,
      );
      if (exporter == null) continue;

      final offeredResource = _exchangeOfferFor(
        view: view,
        exporter: exporter,
        requestedResource: resource,
        ownSurplusResources: ownSurplusResources,
      );
      if (offeredResource != null) {
        return [
          OpenResourceExchangeCommand(
            playerId: view.forPlayerId,
            targetPlayerId: exporter.playerId,
            offeredResource: offeredResource,
            requestedResource: resource,
            durationTurns: durationTurns,
          ),
        ];
      }

      if (view.ownGold < goldPerTurn) continue;

      return [
        OpenResourceTradeCommand(
          playerId: view.forPlayerId,
          targetPlayerId: exporter.playerId,
          resource: resource,
          goldPerTurn: goldPerTurn,
          durationTurns: durationTurns,
        ),
      ];
    }
    return const [];
  }

  List<ResourceType> _missingStrategicResources(GameView view) {
    final missing = <ResourceType>{};
    for (final unitType in GameUnitType.values) {
      if (!unitType.canBeProducedByCities) continue;
      if (!TechnologyUnlockQuery.hasUnitUnlocked(
        playerId: view.forPlayerId,
        unitType: unitType,
        research: view.research,
        ruleset: view.ruleset.technology,
      )) {
        continue;
      }

      missing.addAll(
        UnitProductionRequirementRules.missingResourceChoices(
          playerId: view.forPlayerId,
          unitType: unitType,
          cities: view.ownCities,
          mapData: view.mapData,
          ruleset: view.ruleset.city,
          research: view.research,
          resourceTradeAgreements: view.resourceTradeAgreements,
        ),
      );
    }

    return [
      for (final resource in ResourceType.values)
        if (missing.contains(resource)) resource,
    ];
  }

  Map<String, List<GameCity>> _exporterCitiesByPlayer(GameView view) {
    final result = <String, List<GameCity>>{};
    for (final city in view.rememberedEnemyCities) {
      final exporterId = city.ownerPlayerId;
      if (exporterId.isEmpty || exporterId == view.forPlayerId) continue;
      if (!view.hasDiplomaticContactWith(exporterId)) continue;
      if (view.relationStatusFor(exporterId) == DiplomaticRelationStatus.war) {
        continue;
      }
      result.putIfAbsent(exporterId, () => []).add(city);
    }
    return result;
  }

  _ResourceExporter? _exporterFor({
    required GameView view,
    required ResourceType resource,
    required Map<String, List<GameCity>> exporterCitiesByPlayer,
  }) {
    final exporterIds = exporterCitiesByPlayer.keys.toList()..sort();
    for (final exporterId in exporterIds) {
      final cities = exporterCitiesByPlayer[exporterId]!;
      final availableExports = _availableExportCount(
        view: view,
        playerId: exporterId,
        cities: cities,
        resource: resource,
      );
      if (availableExports > 0) {
        return _ResourceExporter(playerId: exporterId, cities: cities);
      }
    }
    return null;
  }

  ResourceType? _exchangeOfferFor({
    required GameView view,
    required _ResourceExporter exporter,
    required ResourceType requestedResource,
    required List<ResourceType> ownSurplusResources,
  }) {
    for (final offeredResource in ownSurplusResources) {
      if (offeredResource == requestedResource) continue;
      if (_controlsOrImportsResource(
        view: view,
        playerId: exporter.playerId,
        cities: exporter.cities,
        resource: offeredResource,
      )) {
        continue;
      }
      return offeredResource;
    }
    return null;
  }

  List<ResourceType> _surplusResourcesFor({
    required GameView view,
    required String playerId,
    required Iterable<GameCity> cities,
  }) {
    return [
      for (final resource in ResourceType.values)
        if (_availableExportCount(
              view: view,
              playerId: playerId,
              cities: cities,
              resource: resource,
            ) >
            0)
          resource,
    ];
  }

  bool _controlsOrImportsResource({
    required GameView view,
    required String playerId,
    required Iterable<GameCity> cities,
    required ResourceType resource,
  }) {
    if (_hasActiveImportFor(view, playerId, resource)) return true;
    final inventory = CityResourceInventoryRules.forPlayer(
      playerId: playerId,
      cities: cities,
      mapData: view.mapData,
      research: view.research,
    );
    return inventory.controls(resource);
  }

  int _availableExportCount({
    required GameView view,
    required String playerId,
    required Iterable<GameCity> cities,
    required ResourceType resource,
  }) {
    final inventory = CityResourceInventoryRules.forPlayer(
      playerId: playerId,
      cities: cities,
      mapData: view.mapData,
      research: view.research,
    );
    return inventory.countFor(resource) -
        _activeExportCount(view, playerId, resource) -
        _strategicReserveFor(
          view: view,
          playerId: playerId,
          resource: resource,
        );
  }

  int _strategicReserveFor({
    required GameView view,
    required String playerId,
    required ResourceType resource,
  }) {
    for (final unitType in GameUnitType.values) {
      if (!unitType.canBeProducedByCities) continue;
      if (!TechnologyUnlockQuery.hasUnitUnlocked(
        playerId: playerId,
        unitType: unitType,
        research: view.research,
        ruleset: view.ruleset.technology,
      )) {
        continue;
      }
      final definition = view.ruleset.city.unitDefinitionFor(unitType);
      for (final requirement in definition.requirements) {
        switch (requirement) {
          case UnitResourceRequirement(:final resources):
            if (resources.contains(resource)) return 1;
        }
      }
    }
    return 0;
  }

  bool _hasActiveImport(GameView view, ResourceType resource) {
    return _hasActiveImportFor(view, view.forPlayerId, resource);
  }

  bool _hasActiveImportFor(
    GameView view,
    String playerId,
    ResourceType resource,
  ) {
    for (final agreement in view.resourceTradeAgreements) {
      if (agreement.importerPlayerId == playerId &&
          agreement.resource == resource &&
          agreement.isActive) {
        return true;
      }
    }
    return false;
  }

  int _activeExportCount(
    GameView view,
    String exporterPlayerId,
    ResourceType resource,
  ) {
    var count = 0;
    for (final agreement in view.resourceTradeAgreements) {
      if (agreement.exporterPlayerId == exporterPlayerId &&
          agreement.resource == resource &&
          agreement.isActive) {
        count += 1;
      }
    }
    return count;
  }
}

final class _ResourceExporter {
  const _ResourceExporter({required this.playerId, required this.cities});

  final String playerId;
  final List<GameCity> cities;
}
