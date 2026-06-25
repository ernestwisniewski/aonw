import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MapDefinition', () {
    test('parses gameplay map JSON', () {
      final map = MapDefinition.fromJsonString('''
{
  "cols": 2,
  "rows": 1,
  "mapName": "duel",
  "defaultZoom": 1.5,
  "tiles": [
    {
      "col": 0,
      "row": 0,
      "terrains": ["grassland", "forest"],
      "resources": ["deer"],
      "height": 2
    },
    {
      "col": 1,
      "row": 0,
      "terrains": ["hills"],
      "resources": [],
      "height": 3
    }
  ]
}
''');

      expect(map.cols, 2);
      expect(map.rows, 1);
      expect(map.mapName, 'duel');
      expect(map.defaultZoom, 1.5);
      expect(map.tileAt(0, 0)?.terrains, [
        TerrainType.grassland,
        TerrainType.forest,
      ]);
      expect(map.tileAt(0, 0)?.resources, [ResourceType.deer]);
      expect(map.toJson()['tiles'], hasLength(2));
    });

    test('rejects unknown terrain', () {
      expect(
        () => MapDefinition.fromJson({
          'cols': 1,
          'rows': 1,
          'tiles': [
            {
              'col': 0,
              'row': 0,
              'terrains': ['lava'],
              'resources': <String>[],
              'height': 0,
            },
          ],
        }),
        throwsArgumentError,
      );
    });

    test('rejects out-of-bounds tiles', () {
      expect(
        () => MapDefinition.fromJson({
          'cols': 1,
          'rows': 1,
          'tiles': [
            {
              'col': 2,
              'row': 0,
              'terrains': ['grassland'],
              'resources': <String>[],
              'height': 0,
            },
          ],
        }),
        throwsA(isA<MapDefinitionException>()),
      );
    });
  });
}
