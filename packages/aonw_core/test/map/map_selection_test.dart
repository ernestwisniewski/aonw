import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:test/test.dart';

void main() {
  group('MapSelection', () {
    test('formats names and exposes source routing values', () {
      const builtIn = MapSelection(
        name: 'verdantia__opening',
        source: MapSource.asset,
      );
      const saved = MapSelection(name: 'my_map', source: MapSource.saved);

      expect(builtIn.displayName, 'Verdantia Opening');
      expect(builtIn.sourceLabel, 'Built-in');
      expect(saved.sourceLabel, 'Saved');
      expect(builtIn.sourceQueryValue, 'asset');
      expect(saved.sourceQueryValue, 'saved');
      expect(MapSelection.sourceFromQuery('saved'), MapSource.saved);
      expect(MapSelection.sourceFromQuery(null), MapSource.asset);
      expect(MapSelection.sourceFromQuery('unknown'), MapSource.asset);
    });

    test('uses name and source as its value identity', () {
      const selection = MapSelection(
        name: 'verdantia',
        source: MapSource.asset,
      );

      expect(
        selection,
        const MapSelection(name: 'verdantia', source: MapSource.asset),
      );
      expect(selection.hashCode, selection.hashCode);
      expect(
        selection,
        isNot(const MapSelection(name: 'verdantia', source: MapSource.saved)),
      );
    });
  });

  group('MapViewMode', () {
    test('keeps graphic and tile rendering flags complementary', () {
      expect(MapViewMode.graphic.showsImage, isTrue);
      expect(MapViewMode.graphic.usesOutlineHexes, isTrue);
      expect(MapViewMode.graphic.showsExtrusion, isFalse);
      expect(MapViewMode.graphic.showsIcons, isFalse);

      expect(MapViewMode.tile.showsImage, isFalse);
      expect(MapViewMode.tile.usesOutlineHexes, isFalse);
      expect(MapViewMode.tile.showsExtrusion, isTrue);
      expect(MapViewMode.tile.showsIcons, isTrue);
    });
  });
}
