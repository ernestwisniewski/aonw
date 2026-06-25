import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/objective.dart';

abstract final class EditorMapObjectiveFactory {
  static MapObjectiveDefinition build({
    required MapObjectiveType type,
    required int col,
    required int row,
  }) {
    return MapObjectiveDefinition(
      id: idFor(type: type, col: col, row: row),
      type: type,
      hex: CityHex(col: col, row: row),
      victoryPoints: defaultVictoryPoints(type),
      goldPerTurn: defaultGoldPerTurn(type),
    );
  }

  static String idFor({
    required MapObjectiveType type,
    required int col,
    required int row,
  }) {
    final typeName = switch (type) {
      MapObjectiveType.ruins => 'ruins',
      MapObjectiveType.strategicPass => 'pass',
      MapObjectiveType.holySite => 'holy',
      MapObjectiveType.legendaryResource => 'legendary',
    };
    return '${typeName}_${col}_$row';
  }

  static int defaultVictoryPoints(MapObjectiveType type) {
    return switch (type) {
      MapObjectiveType.ruins => 1,
      MapObjectiveType.strategicPass => 2,
      MapObjectiveType.holySite => 2,
      MapObjectiveType.legendaryResource => 3,
    };
  }

  static int defaultGoldPerTurn(MapObjectiveType type) {
    return switch (type) {
      MapObjectiveType.ruins => 0,
      MapObjectiveType.strategicPass => 0,
      MapObjectiveType.holySite => 1,
      MapObjectiveType.legendaryResource => 2,
    };
  }
}
