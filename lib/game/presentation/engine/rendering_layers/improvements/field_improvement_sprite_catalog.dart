import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw_core/game/domain/city.dart';

abstract final class FieldImprovementSpriteCatalog {
  static const int columns = 4;
  static const List<FieldImprovementType> typesInAtlasOrder = [
    FieldImprovementType.farm,
    FieldImprovementType.riverFarm,
    FieldImprovementType.orchard,
    FieldImprovementType.mine,
    FieldImprovementType.prospectorCamp,
    FieldImprovementType.lumberMill,
    FieldImprovementType.pasture,
    FieldImprovementType.camp,
    FieldImprovementType.fishingBoats,
    FieldImprovementType.vineyard,
    FieldImprovementType.tradingPost,
    FieldImprovementType.quarry,
    FieldImprovementType.plantation,
    FieldImprovementType.pearlDivers,
    FieldImprovementType.horseRanch,
    FieldImprovementType.coalShaft,
    FieldImprovementType.oilWell,
    FieldImprovementType.bauxiteMine,
    FieldImprovementType.uraniumMine,
  ];

  static Iterable<FieldImprovementType> get improvementTypes =>
      typesInAtlasOrder;

  static Iterable<int> get eraColumns => Iterable<int>.generate(columns);

  static int rowForType(FieldImprovementType type) {
    final row = typesInAtlasOrder.indexOf(type);
    assert(row != -1, 'Missing field improvement sprite for ${type.name}');
    return row == -1 ? 0 : row;
  }

  static SpriteFrameId frameIdFor({
    required FieldImprovementType type,
    required int eraColumn,
  }) {
    final era = eraColumn.clamp(0, columns - 1).toInt();
    return SpriteFrameId('improvement.${type.name}.$era');
  }

  static SpriteSequenceId sequenceIdFor({
    required FieldImprovementType type,
    required int eraColumn,
  }) {
    return SpriteSequenceId(frameIdFor(type: type, eraColumn: eraColumn).value);
  }

  static String labelForEraColumn(int column) {
    return switch (column.clamp(0, columns - 1).toInt()) {
      0 => 'Early',
      1 => 'Developed',
      2 => 'Industrial',
      _ => 'Modern',
    };
  }
}
