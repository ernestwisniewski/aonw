import 'dart:convert';
import 'dart:io';

import 'package:aonw/editor/services/map_exporter.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _MockPathProvider
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;

  _MockPathProvider(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;

  @override
  Future<String?> getApplicationSupportPath() async => tempPath;

  @override
  Future<String?> getLibraryPath() async => null;

  @override
  Future<String?> getExternalStoragePath() async => null;

  @override
  Future<List<String>?> getExternalCachePaths() async => null;

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => null;

  @override
  Future<String?> getDownloadsPath() async => null;

  @override
  Future<String?> getApplicationCachePath() async => tempPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('map_exporter_test_');
    PathProviderPlatform.instance = _MockPathProvider(tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('MapExporter.buildArchive', () {
    test('uses requested export name without mutating source map', () async {
      final sourceDir = Directory('${tempDir.path}/maps/original_map');
      await sourceDir.create(recursive: true);
      await File(
        '${sourceDir.path}/image.jpg',
      ).writeAsBytes([0xFF, 0xD8, 0xFF]);
      await File('${sourceDir.path}/map.json').writeAsString('stale json');

      final mapData = MapData(
        cols: 1,
        rows: 1,
        mapName: 'original_map',
        objectives: const [
          MapObjectiveDefinition(
            id: 'pass_1',
            type: MapObjectiveType.strategicPass,
            hex: CityHex(col: 0, row: 0),
            requiredHoldTurns: 2,
          ),
        ],
        tiles: const [
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.plains],
            resources: [],
            height: 0,
          ),
        ],
      );

      final result = await MapExporter.buildArchive(mapData, 'renamed map');
      final archive = ZipDecoder().decodeBytes(result.bytes);
      final names = archive.files.map((file) => file.name).toSet();
      final jsonFile = archive.files.singleWhere(
        (file) => file.name == 'renamed_map/map.json',
      );
      final decodedJson =
          json.decode(utf8.decode(jsonFile.content as List<int>))
              as Map<String, dynamic>;

      expect(result.safeName, 'renamed_map');
      expect(names, contains('renamed_map/image.jpg'));
      expect(names, contains('renamed_map/map.json'));
      expect(decodedJson['mapName'], 'renamed_map');
      final objectives = decodedJson['objectives'] as List<dynamic>;
      final objective = objectives.single as Map<String, dynamic>;
      expect(objectives, hasLength(1));
      expect(objective['id'], 'pass_1');
      expect(mapData.mapName, 'original_map');
    });
  });
}
