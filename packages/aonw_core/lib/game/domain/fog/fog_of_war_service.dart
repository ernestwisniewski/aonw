import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog/fog_balance.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/fog/fog_reveal_calculator.dart';
import 'package:aonw_core/game/domain/fog/fog_reveal_source.dart';
import 'package:aonw_core/game/domain/fog/player_fog_of_war.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class FogOfWarService {
  final FogRevealCalculator revealCalculator;
  final FogOfWarRecomputeCounters? counters;

  const FogOfWarService({
    this.revealCalculator = const FogRevealCalculator(),
    this.counters,
  });

  FogOfWarState recompute({
    required FogOfWarState current,
    required MapTileLookup mapData,
    required Iterable<String> playerIds,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
  }) {
    counters?.fullRecomputeCount++;
    final updated = <PlayerFogOfWar>[];
    for (final playerId in playerIds.where((id) => id.isNotEmpty)) {
      updated.add(
        _recomputedFogForPlayer(
          current: current,
          playerId: playerId,
          mapData: mapData,
          units: units,
          cities: cities,
        ),
      );
    }
    return current.updatePlayers(updated);
  }

  FogOfWarState recomputePlayer({
    required FogOfWarState current,
    required MapTileLookup mapData,
    required String playerId,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
  }) {
    if (playerId.isEmpty) return current;
    counters?.playerRecomputeCount++;
    return current.updatePlayer(
      _recomputedFogForPlayer(
        current: current,
        playerId: playerId,
        mapData: mapData,
        units: units,
        cities: cities,
      ),
    );
  }

  FogOfWarState recomputeAfterUnitMove({
    required FogOfWarState current,
    required MapTileLookup mapData,
    required GameUnit previousUnit,
    required GameUnit movedUnit,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
  }) {
    final playerId = movedUnit.ownerPlayerId;
    if (playerId.isEmpty || previousUnit.ownerPlayerId != playerId) {
      counters?.unitMoveFallbackCount++;
      return recompute(
        current: current,
        mapData: mapData,
        playerIds: {previousUnit.ownerPlayerId, movedUnit.ownerPlayerId},
        units: units,
        cities: cities,
      );
    }

    final previousVisible = revealCalculator.visibleHexesFor(
      mapData: mapData,
      sources: [
        unitRevealSource(
          playerId: playerId,
          unit: previousUnit,
          mapData: mapData,
        ),
      ],
    );
    final movedVisible = revealCalculator.visibleHexesFor(
      mapData: mapData,
      sources: [
        unitRevealSource(playerId: playerId, unit: movedUnit, mapData: mapData),
      ],
    );
    final currentPlayerFog = current.fogForPlayer(playerId);
    final potentiallyLostVisible = previousVisible.difference(movedVisible);
    for (final hex in potentiallyLostVisible) {
      if (currentPlayerFog.visibleHexes.contains(hex)) {
        counters?.unitMoveFallbackCount++;
        return recomputePlayer(
          current: current,
          mapData: mapData,
          playerId: playerId,
          units: units,
          cities: cities,
        );
      }
    }

    counters?.unitMoveIncrementalCount++;
    return current.updatePlayer(
      currentPlayerFog.withVisibleHexes({
        ...currentPlayerFog.visibleHexes,
        ...movedVisible,
      }),
    );
  }

  PlayerFogOfWar _recomputedFogForPlayer({
    required FogOfWarState current,
    required String playerId,
    required MapTileLookup mapData,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
  }) {
    final sources = _sourcesForPlayer(
      playerId: playerId,
      mapData: mapData,
      units: units,
      cities: cities,
    );
    final visibleHexes = revealCalculator.visibleHexesFor(
      mapData: mapData,
      sources: sources,
    );
    return current.fogForPlayer(playerId).withVisibleHexes(visibleHexes);
  }

  List<FogRevealSource> _sourcesForPlayer({
    required String playerId,
    required MapTileLookup mapData,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
  }) {
    return [
      for (final unit in units)
        if (unit.ownerPlayerId == playerId)
          unitRevealSource(playerId: playerId, unit: unit, mapData: mapData),
      for (final city in cities)
        if (city.ownerPlayerId == playerId) ...[
          FogRevealSource(
            playerId: playerId,
            origin: city.center.toCoordinate(),
            range: FogBalance.cityCenterVisionRange,
            observerHeight: 0,
          ),
          for (final hex in city.controlledHexes)
            FogRevealSource(
              playerId: playerId,
              origin: hex.toCoordinate(),
              range: FogBalance.controlledHexVisionRange,
              observerHeight: 0,
            ),
        ],
    ];
  }

  static FogRevealSource unitRevealSource({
    required String playerId,
    required GameUnit unit,
    required MapTileLookup mapData,
  }) {
    final tile = mapData.tileAt(unit.col, unit.row);
    final observerHeight = tile?.height ?? 0;
    final bonus = (observerHeight ~/ 2) * FogBalance.elevationBonusPerLevel;
    final effectiveRange = (FogBalance.unitVisionRange + bonus).clamp(
      0,
      FogBalance.maxVisionRange,
    );
    return FogRevealSource(
      playerId: playerId,
      origin: HexCoordinate(col: unit.col, row: unit.row),
      range: effectiveRange,
      observerHeight: observerHeight,
    );
  }
}

final class FogOfWarRecomputeCounters {
  int fullRecomputeCount = 0;
  int playerRecomputeCount = 0;
  int unitMoveIncrementalCount = 0;
  int unitMoveFallbackCount = 0;

  void reset() {
    fullRecomputeCount = 0;
    playerRecomputeCount = 0;
    unitMoveIncrementalCount = 0;
    unitMoveFallbackCount = 0;
  }
}
