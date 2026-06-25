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

  const FogOfWarService({this.revealCalculator = const FogRevealCalculator()});

  FogOfWarState recompute({
    required FogOfWarState current,
    required MapData mapData,
    required Iterable<String> playerIds,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
  }) {
    final updated = <PlayerFogOfWar>[];
    for (final playerId in playerIds.where((id) => id.isNotEmpty)) {
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
      updated.add(
        current.fogForPlayer(playerId).withVisibleHexes(visibleHexes),
      );
    }
    return current.updatePlayers(updated);
  }

  List<FogRevealSource> _sourcesForPlayer({
    required String playerId,
    required MapData mapData,
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
    required MapData mapData,
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
