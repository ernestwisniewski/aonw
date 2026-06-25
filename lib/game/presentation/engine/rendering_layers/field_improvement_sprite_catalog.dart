import 'dart:ui' as ui;

import 'package:aonw/shared/assets/sprite_atlas_geometry.dart';
import 'package:aonw_core/game/domain/city.dart';

abstract final class FieldImprovementSpriteCatalog {
  static const String assetPath = 'assets/sprites/improvements1.jpg';
  static const List<String> assetPaths = [
    'assets/sprites/improvements1.jpg',
    'assets/sprites/improvements2.jpg',
    'assets/sprites/improvements3.jpg',
    'assets/sprites/improvements4.jpg',
  ];
  static const int columns = 4;
  static const int rows = 19;
  static const int sheetColumns = 6;
  static const int sheetRows = 4;
  static const int sourceImageWidth = 1768;
  static const int sourceImageHeight = 890;
  static const double sourceCellWidth = sourceImageWidth / sheetColumns;
  static const double sourceCellHeight = sourceImageHeight / sheetRows;
  static const double sourceInset = 0;
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

  static String assetPathFor(FieldImprovementType type) {
    return _spriteCells[type]?.assetPath ?? assetPath;
  }

  static int sheetColumnForType(FieldImprovementType type) {
    return _spriteCells[type]?.column ?? 0;
  }

  static int rowForType(FieldImprovementType type) {
    final row = typesInAtlasOrder.indexOf(type);
    assert(row != -1, 'Missing field improvement atlas row for ${type.name}');
    return row == -1 ? 0 : row;
  }

  static String adjustmentIdFor(FieldImprovementType type) =>
      adjustmentIdForVariant(type: type, eraColumn: 0);

  static String adjustmentIdForVariant({
    required FieldImprovementType type,
    required int eraColumn,
  }) {
    final column = eraColumn.clamp(0, columns - 1).toInt();
    return 'field-improvement.${type.name}.era-$column';
  }

  static String labelForEraColumn(int column) {
    return switch (column.clamp(0, columns - 1).toInt()) {
      0 => 'Early',
      1 => 'Developed',
      2 => 'Industrial',
      _ => 'Modern',
    };
  }

  static ui.Rect sourceRectFor({
    required int imageWidth,
    required int imageHeight,
    required FieldImprovementType type,
    required int eraColumn,
  }) {
    final eraRow = eraColumn.clamp(0, columns - 1).toInt();
    return SpriteAtlasGeometry.sourceRectFor(
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      columns: sheetColumns,
      rows: sheetRows,
      column: sheetColumnForType(type),
      row: eraRow,
      sourceInset: sourceInset,
    );
  }

  static const Map<FieldImprovementType, _FieldImprovementSpriteCell>
  _spriteCells = {
    FieldImprovementType.farm: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements1.jpg',
      column: 0,
    ),
    FieldImprovementType.riverFarm: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements1.jpg',
      column: 1,
    ),
    FieldImprovementType.orchard: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements1.jpg',
      column: 2,
    ),
    FieldImprovementType.pasture: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements1.jpg',
      column: 3,
    ),
    FieldImprovementType.camp: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements1.jpg',
      column: 4,
    ),
    FieldImprovementType.fishingBoats: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements2.jpg',
      column: 0,
    ),
    FieldImprovementType.pearlDivers: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements2.jpg',
      column: 1,
    ),
    FieldImprovementType.lumberMill: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements2.jpg',
      column: 2,
    ),
    FieldImprovementType.quarry: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements2.jpg',
      column: 3,
    ),
    FieldImprovementType.mine: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements2.jpg',
      column: 4,
    ),
    FieldImprovementType.plantation: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements3.jpg',
      column: 0,
    ),
    FieldImprovementType.vineyard: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements3.jpg',
      column: 1,
    ),
    FieldImprovementType.tradingPost: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements3.jpg',
      column: 2,
    ),
    FieldImprovementType.prospectorCamp: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements3.jpg',
      column: 3,
    ),
    FieldImprovementType.horseRanch: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements3.jpg',
      column: 4,
    ),
    FieldImprovementType.coalShaft: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements4.jpg',
      column: 0,
    ),
    FieldImprovementType.oilWell: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements4.jpg',
      column: 1,
    ),
    FieldImprovementType.bauxiteMine: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements4.jpg',
      column: 2,
    ),
    FieldImprovementType.uraniumMine: _FieldImprovementSpriteCell(
      assetPath: 'assets/sprites/improvements4.jpg',
      column: 3,
    ),
  };
}

class _FieldImprovementSpriteCell {
  final String assetPath;
  final int column;

  const _FieldImprovementSpriteCell({
    required this.assetPath,
    required this.column,
  });
}
