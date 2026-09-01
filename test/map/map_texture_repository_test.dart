import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:aonw/map/rendering/map_texture_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../support/current_content_legacy_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the compiled map manifest and pages', () async {
    final repository = FlutterMapTextureRepository(
      bundle: _LegacyRuntimeAssetBundle(),
    );
    addTearDown(repository.dispose);

    final set = await repository.loadSet(
      'assets/runtime/maps/verdantia/map_texture_manifest.json',
    );

    expect(set.id, 'verdantia');
    expect((set.cols, set.rows), (30, 20));
    expect(set.pages, isNotEmpty);
    expect(set.averageColors, hasLength(600));
    expect(repository.cachedPage(set.pages.first), isNull);

    final image = await repository.loadPage(set.pages.first);

    expect(image.width, set.pages.first.pixelSize.width);
    expect(image.height, set.pages.first.pixelSize.height);
    expect(repository.cachedPage(set.pages.first), same(image));
  });

  test('fails fast when a bundled manifest is missing', () async {
    final repository = FlutterMapTextureRepository(
      bundle: _MissingAssetBundle(),
    );
    addTearDown(repository.dispose);

    await expectLater(
      repository.loadSet(
        'assets/runtime/maps/missing/map_texture_manifest.json',
      ),
      throwsA(isA<FlutterError>()),
    );
  });

  for (final invalidPage in [
    'assets/runtime/maps/test/page_0.webp',
    'assets/runtime/maps/test/../other/page_0.jpg',
    'assets/runtime/maps/other/page_0.jpg',
  ]) {
    test('rejects non-canonical bundled page $invalidPage', () async {
      final repository = FlutterMapTextureRepository(
        bundle: _ManifestBundle(_manifestWithPage(invalidPage)),
      );
      addTearDown(repository.dispose);

      await expectLater(
        repository.loadSet(
          'assets/runtime/maps/test/map_texture_manifest.json',
        ),
        throwsFormatException,
      );
    });
  }

  test('deduplicates a page load and rejects it after disposal', () async {
    final bundle = _DelayedBinaryBundle();
    final repository = FlutterMapTextureRepository(bundle: bundle);
    const page = MapTexturePage(
      source: BundledMapTexturePageSource(
        'assets/runtime/maps/test/page_0.jpg',
      ),
      pixelSize: ui.Size(1, 1),
      destination: ui.Rect.fromLTWH(0, 0, 1, 1),
    );

    final first = repository.loadPage(page);
    final second = repository.loadPage(page);
    expect(bundle.loadCalls, 1);

    repository.dispose();
    bundle.complete(_onePixelJpeg);

    await expectLater(first, throwsStateError);
    await expectLater(second, throwsStateError);
    expect(() => repository.cachedPage(page), throwsStateError);
  });
}

final Uint8List _onePixelJpeg = Uint8List.fromList(
  img.encodeJpg(img.Image(width: 1, height: 1)),
);

final class _MissingAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) =>
      Future.error(FlutterError('Missing bundled asset: $key'));
}

final class _LegacyRuntimeAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final data = await rootBundle.load(key);
    if (!key.endsWith('/map_texture_manifest.json')) return data;
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final fixture = currentTextureManifestAsLegacyFixture(utf8.decode(bytes));
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(fixture)));
  }
}

final class _DelayedBinaryBundle extends CachingAssetBundle {
  final Completer<ByteData> _bytes = Completer<ByteData>();
  var loadCalls = 0;

  void complete(Uint8List bytes) =>
      _bytes.complete(ByteData.sublistView(bytes));

  @override
  Future<ByteData> load(String key) {
    loadCalls++;
    return _bytes.future;
  }
}

String _manifestWithPage(String assetPath) => jsonEncode({
  'version': 1,
  'mapId': 'test',
  'cols': 1,
  'rows': 1,
  'worldWidth': 1,
  'worldHeight': 1,
  'pages': [
    {
      'asset': assetPath,
      'pixelWidth': 1,
      'pixelHeight': 1,
      'destination': [0, 0, 1, 1],
    },
  ],
  'averageColors': {'0,0': 0xFF000000},
});

final class _ManifestBundle extends CachingAssetBundle {
  _ManifestBundle(this.manifest);

  final String manifest;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(manifest)));
}
