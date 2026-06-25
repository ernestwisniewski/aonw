import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/map/domain/map_data.dart';

TileData selectedTileData(SelectedTile tile) {
  return TileData(
    col: tile.col,
    row: tile.row,
    terrains: tile.terrains,
    resources: tile.resources,
    height: tile.height,
  );
}

String enumLabelList(Iterable<Enum> values, {required String empty}) {
  if (values.isEmpty) return empty;
  return values.map((value) => humanEnumName(value.name)).join(' + ');
}

String humanEnumName(String name) {
  final words = name.replaceAll('_', ' ').split(' ');
  return words
      .map((word) => word.isEmpty ? word : GameText.capitalize(word))
      .join(' ');
}
