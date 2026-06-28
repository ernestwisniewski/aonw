import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

abstract final class AiCityFoundingSafety {
  static bool hasKnownCenterExclusionZone({
    required GameView view,
    required CityHex center,
  }) {
    return unknownCenterExclusionTiles(view: view, center: center).isEmpty;
  }

  static List<TileData> unknownCenterExclusionTiles({
    required GameView view,
    required CityHex center,
  }) {
    if (view.ownCities.isEmpty) return const [];

    final origin = HexCoordinate(col: center.col, row: center.row);
    final unknown = <TileData>[];
    for (final tile in view.mapData.tiles) {
      final hex = HexCoordinate.fromTile(tile);
      if (HexDistance.between(origin, hex) >=
          CityFoundingRules.minimumCenterDistance) {
        continue;
      }
      if (!view.visibility.canRememberStaticAt(tile.col, tile.row)) {
        unknown.add(tile);
      }
    }
    return List.unmodifiable(unknown);
  }

  static int revealableUnknownCenterExclusionTileCount({
    required GameView view,
    required CityHex center,
    required GameUnit observer,
  }) {
    final unknown = unknownCenterExclusionTiles(view: view, center: center);
    if (unknown.isEmpty) return 0;

    final visibleFromObserver = const FogRevealCalculator().visibleHexesFor(
      mapData: view.mapData,
      sources: [
        FogOfWarService.unitRevealSource(
          playerId: view.forPlayerId,
          unit: observer,
          mapData: view.mapData,
        ),
      ],
    );
    return unknown.where((tile) {
      return visibleFromObserver.contains(HexCoordinate.fromTile(tile));
    }).length;
  }

  static bool isKnownEnemyCityHex({
    required GameView view,
    required HexCoordinate hex,
  }) {
    for (final city in view.rememberedEnemyCities) {
      if (city.occupiesCenter(hex.col, hex.row)) {
        return true;
      }
      for (final controlled in city.controlledHexes) {
        if (controlled.col == hex.col && controlled.row == hex.row) {
          return true;
        }
      }
    }
    return false;
  }

  static int? nearestRememberedEnemyCityDistance({
    required GameView view,
    required HexCoordinate hex,
  }) {
    int? nearest;
    for (final city in view.rememberedEnemyCities) {
      final distance = HexDistance.between(hex, city.center.toCoordinate());
      if (nearest == null || distance < nearest) nearest = distance;
    }
    return nearest;
  }
}
