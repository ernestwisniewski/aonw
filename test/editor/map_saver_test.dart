import 'dart:io';
import 'dart:ui' as ui;
import 'package:aonw/editor/services/map_saver.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:flutter/material.dart';
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
    tempDir = await Directory.systemTemp.createTemp('map_saver_test_');
    PathProviderPlatform.instance = _MockPathProvider(tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('MapSaver.sanitizeMapName', () {
    test('replaces unsafe path characters with a safe stem', () {
      expect(MapSaver.sanitizeMapName('../my map?.png'), 'my_map_png');
    });

    test('avoids reserved Windows device names', () {
      expect(MapSaver.sanitizeMapName('CON'), 'CON_map');
    });
  });

  group('MapSaver.save', () {
    test('writes JSON using a sanitized filename stem', () async {
      final mapData = MapData(
        cols: 1,
        rows: 1,
        tiles: [
          const TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.ocean],
            resources: [],
            height: 0,
          ),
        ],
        mapName: '../bad map',
      );

      await MapSaver.save(mapData);

      // New structure: maps/<name>/map.json
      final file = File('${tempDir.path}/maps/bad_map/map.json');
      expect(await file.exists(), isTrue);
      expect(mapData.mapName, 'bad_map');
      expect(await file.readAsString(), contains('"mapName": "bad_map"'));
    });
  });

  group('MapSaver.saveImageCopy', () {
    test('re-encodes source as JPEG under the sanitized stem', () async {
      final source = File('${tempDir.path}/picked image.png');
      await _writePng(source, color: Colors.red);

      final savedPath = await MapSaver.saveImageCopy(
        sourcePath: source.path,
        mapName: '../bad map',
      );

      final savedFile = File(savedPath);
      expect(savedPath, endsWith('/maps/bad_map/image.jpg'));
      expect(_isJpeg(await savedFile.readAsBytes()), isTrue);
    });

    test('removes stale sliced image files', () async {
      final mapDir = Directory('${tempDir.path}/maps/mymap');
      await mapDir.create(recursive: true);
      final staleSlice = File('${mapDir.path}/1x1.jpg');
      await staleSlice.writeAsBytes([9, 9, 9]);
      final source = File('${tempDir.path}/picked image.png');
      await _writePng(source, color: Colors.red);

      await MapSaver.saveImageCopy(sourcePath: source.path, mapName: 'mymap');

      expect(await staleSlice.exists(), isFalse);
      expect(
        _isJpeg(await File('${mapDir.path}/image.jpg').readAsBytes()),
        isTrue,
      );
    });
  });

  group('MapSaver.saveImageSlices', () {
    test('replaces old slices and removes single image', () async {
      final source = File('${tempDir.path}/picked image.png');
      await _writePng(source, color: Colors.red);
      final mapDir = Directory('${tempDir.path}/maps/mymap');
      await mapDir.create(recursive: true);
      final staleSlice = File('${mapDir.path}/1x1.jpg');
      await staleSlice.writeAsBytes([9, 9, 9]);
      final staleExtraSlice = File('${mapDir.path}/9x9.jpg');
      await staleExtraSlice.writeAsBytes([8, 8, 8]);
      final staleSingleImage = File('${mapDir.path}/image.jpg');
      await staleSingleImage.writeAsBytes([7, 7, 7]);

      final savedPath = await MapSaver.saveImageSlices(
        sourcePath: source.path,
        mapName: 'mymap',
        cols: 1,
        rows: 1,
        config: MapConfig.defaultConfig,
      );

      final savedSlice = File(savedPath);
      expect(savedPath, endsWith('/maps/mymap/1x1.jpg'));
      expect(await savedSlice.exists(), isTrue);
      expect(_isJpeg(await savedSlice.readAsBytes()), isTrue);
      expect(await staleExtraSlice.exists(), isFalse);
      expect(await staleSingleImage.exists(), isFalse);
    });
  });

  group('MapSaver.resolveImagePath', () {
    test('returns documents path when file exists', () async {
      final mapDir = Directory('${tempDir.path}/maps/mymap');
      await mapDir.create(recursive: true);
      final imageFile = File('${mapDir.path}/image.jpg');
      await imageFile.writeAsBytes([0, 1, 2, 3]);

      expect(await MapSaver.resolveImagePath('mymap'), imageFile.path);
    });

    test(
      'returns null when neither documents nor bundled image exists',
      () async {
        expect(await MapSaver.resolveImagePath('missing-map'), isNull);
      },
    );
  });
}

bool _isJpeg(List<int> bytes) =>
    bytes.length >= 3 &&
    bytes[0] == 0xFF &&
    bytes[1] == 0xD8 &&
    bytes[2] == 0xFF;

Future<void> _writePng(File file, {required Color color}) async {
  final recorder = ui.PictureRecorder();
  Canvas(
    recorder,
  ).drawRect(const Rect.fromLTWH(0, 0, 32, 32), Paint()..color = color);
  final image = await recorder.endRecording().toImage(32, 32);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}
