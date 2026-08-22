import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/application/map_repository.dart';
import 'package:aonw_flutter/features/map/infrastructure/map_reference_bundle_loader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

const _manifest = 'assets/maps/aonw2_starter/map_texture_manifest.json';
const _mapHash =
    '4d5603cc00fa8963a71c23133570f89f43c734598d86579e12e1b1059da8712d';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('verifies and loads the committed starter reference page', () async {
    final scene = testMapScene(
      cols: 7,
      rows: 7,
      mapId: 'aonw2_starter',
      contentHash: _mapHash,
    );

    final bundle = await MapReferenceBundleLoader(
      _FileAssetBundle(),
    ).load(manifestAsset: _manifest, map: scene.map);

    expect(bundle.mapContentHash, _mapHash);
    expect(bundle.pages, hasLength(1));
    expect(bundle.pages.single.pixelWidth, 1324);
    expect(bundle.pages.single.pixelHeight, 1459);
    expect(bundle.pages.single.bytes, isNotEmpty);
  });

  test('rejects a bundle with another map content hash', () async {
    final scene = testMapScene(
      cols: 7,
      rows: 7,
      mapId: 'aonw2_starter',
      contentHash: 'b' * 64,
    );

    await expectLater(
      MapReferenceBundleLoader(
        _FileAssetBundle(),
      ).load(manifestAsset: _manifest, map: scene.map),
      throwsA(
        isA<MapLoadException>().having(
          (error) => error.code,
          'code',
          'invalid_map_bundle',
        ),
      ),
    );
  });
}

final class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      utf8.decode((await load(key)).buffer.asUint8List());
}
