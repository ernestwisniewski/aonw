import 'dart:convert';
import 'dart:io';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/persistence/map_catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  final Map<String, String> strings;
  _FakeAssetBundle(this.strings);

  @override
  Future<ByteData> load(String key) async {
    final value = strings[key];
    if (value == null) throw StateError('Missing fake asset: $key');
    final bytes = Uint8List.fromList(utf8.encode(value));
    return ByteData.sublistView(bytes);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = strings[key];
    if (value == null) throw StateError('Missing fake asset: $key');
    return value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('map_catalog_test_');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('listAvailableMaps finds saved maps in folder structure', () async {
    final bundle = _FakeAssetBundle({
      'AssetManifest.json': json.encode({
        'assets/maps/scenario_one/map.json': <Object>[],
      }),
      'assets/maps/scenario_one/map.json': _singleTileJson(),
    });

    final userMapDir = Directory('${tempDir.path}/user_map');
    await userMapDir.create(recursive: true);
    await File('${userMapDir.path}/map.json').writeAsString(_singleTileJson());

    final maps = await MapCatalog.listAvailableMaps(
      bundle: bundle,
      savedMapsDirectory: tempDir,
    );

    expect(maps, [
      const MapSelection(name: 'user_map', source: MapSource.saved),
      const MapSelection(name: 'scenario_one', source: MapSource.asset),
    ]);
  });

  test('listAvailableMaps ignores files that are not map folders', () async {
    final bundle = _FakeAssetBundle({'AssetManifest.json': json.encode({})});

    // A plain file in the maps root — should be ignored.
    await File('${tempDir.path}/stray.json').writeAsString(_singleTileJson());

    final maps = await MapCatalog.listAvailableMaps(
      bundle: bundle,
      savedMapsDirectory: tempDir,
    );

    expect(maps, isEmpty);
  });

  test('loadMap loads bundled map from asset folder', () async {
    final bundle = _FakeAssetBundle({
      'AssetManifest.json': json.encode({
        'assets/maps/scenario_one/map.json': <Object>[],
      }),
      'assets/maps/scenario_one/map.json': _singleTileJson(),
    });

    final mapData = await MapCatalog.loadMap(
      const MapSelection(name: 'scenario_one', source: MapSource.asset),
      bundle: bundle,
      savedMapsDirectory: tempDir,
    );

    expect(mapData.mapName, 'scenario_one');
    expect(mapData.cols, 1);
    expect(mapData.rows, 1);
  });

  test('loadMap loads saved map from folder structure', () async {
    final mapDir = Directory('${tempDir.path}/user_map');
    await mapDir.create(recursive: true);
    await File('${mapDir.path}/map.json').writeAsString('''
{
  "cols": 1,
  "rows": 1,
  "mapName": "user_map",
  "tiles": [
    { "col": 0, "row": 0, "terrains": ["ocean"], "resources": [], "height": 0 }
  ]
}''');

    final mapData = await MapCatalog.loadMap(
      const MapSelection(name: 'user_map', source: MapSource.saved),
      savedMapsDirectory: tempDir,
    );

    expect(mapData.mapName, 'user_map');
    expect(mapData.cols, 1);
    expect(mapData.rows, 1);
  });
}

String _singleTileJson() => '''
{
  "cols": 1,
  "rows": 1,
  "tiles": [
    { "col": 0, "row": 0, "terrains": ["ocean"], "resources": [], "height": 0 }
  ]
}''';
