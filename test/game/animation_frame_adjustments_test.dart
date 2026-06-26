import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:aonw/developer/asset_adjustment_file_store.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustments.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _MockPathProvider
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String documentsPath;

  _MockPathProvider(this.documentsPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;

  @override
  Future<String?> getTemporaryPath() async => documentsPath;

  @override
  Future<String?> getApplicationSupportPath() async => documentsPath;

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
  Future<String?> getApplicationCachePath() async => documentsPath;
}

void main() {
  group('AnimationFrameAdjustment', () {
    test('crops source and destination without changing frame scale', () {
      const adjustment = AnimationFrameAdjustment(
        cropLeft: 10,
        cropTop: 20,
        cropRight: 30,
        cropBottom: 40,
      );
      const source = ui.Rect.fromLTWH(10, 20, 100, 200);
      const destination = ui.Rect.fromLTWH(0, 0, 50, 100);

      expect(
        adjustment.croppedSourceFor(source),
        const ui.Rect.fromLTRB(20, 40, 80, 180),
      );
      expect(
        adjustment.croppedDestinationFor(
          baseSource: source,
          baseDestination: destination,
        ),
        const ui.Rect.fromLTRB(5, 10, 35, 80),
      );
    });

    test('scales alignment offsets from authored size to render size', () {
      const adjustment = AnimationFrameAdjustment(offsetX: 4, offsetY: -6);

      expect(
        adjustment.scaledOffset(
          baseSize: const ui.Size(80, 120),
          targetSize: const ui.Size(40, 60),
        ),
        const ui.Offset(2, -3),
      );
    });

    test('scales cropped destinations around the adjusted frame center', () {
      const adjustment = AnimationFrameAdjustment(
        cropLeft: 10,
        cropRight: 20,
        scaleX: 1.5,
        scaleY: 0.5,
      );
      const source = ui.Rect.fromLTWH(0, 0, 100, 100);
      const destination = ui.Rect.fromLTWH(0, 0, 50, 50);

      final cropped = adjustment.croppedDestinationFor(
        baseSource: source,
        baseDestination: destination,
      );
      final scaled = adjustment.adjustedDestinationFor(
        baseSource: source,
        baseDestination: destination,
      );

      expect(cropped, const ui.Rect.fromLTRB(5, 0, 40, 50));
      expect(scaled.center, cropped.center);
      expect(scaled.width, 52.5);
      expect(scaled.height, 25);
    });

    test('allows negative crop values to expand clipped frames', () {
      const adjustment = AnimationFrameAdjustment(
        cropRight: -10,
        cropBottom: -5,
      );
      const source = ui.Rect.fromLTWH(0, 0, 100, 50);
      const destination = ui.Rect.fromLTWH(0, 0, 50, 25);

      expect(
        adjustment.croppedSourceFor(source),
        const ui.Rect.fromLTRB(0, 0, 110, 55),
      );
      expect(
        adjustment.croppedDestinationFor(
          baseSource: source,
          baseDestination: destination,
        ),
        const ui.Rect.fromLTRB(0, 0, 55, 27.5),
      );
      expect(
        const AnimationFrameAdjustment().adjustCrop(right: -2).cropRight,
        -2,
      );
    });

    test('keeps crop rects valid when crop exceeds source size', () {
      const adjustment = AnimationFrameAdjustment(cropLeft: 50, cropRight: 50);
      const source = ui.Rect.fromLTWH(0, 0, 20, 20);
      const destination = ui.Rect.fromLTWH(0, 0, 40, 40);

      expect(adjustment.croppedSourceFor(source).width, 1);
      expect(
        adjustment
            .croppedDestinationFor(
              baseSource: source,
              baseDestination: destination,
            )
            .width,
        2,
      );
    });
  });

  group('AnimationFrameAdjustmentCatalog', () {
    test(
      'serializes non-zero frame adjustments by stable asset/action key',
      () {
        const adjustment = AnimationFrameAdjustment(
          offsetX: 2,
          cropLeft: 4,
          scaleX: 1.25,
        );
        final catalog = const AnimationFrameAdjustmentCatalog.empty().withFrame(
          assetPath: 'assets/sprites/units/worker.png',
          animationId: 'work',
          frameIndex: 3,
          adjustment: adjustment,
        );

        expect(
          catalog.adjustmentFor(
            assetPath: 'assets/sprites/units/worker.png',
            animationId: 'work',
            frameIndex: 3,
          ),
          adjustment,
        );

        final decoded =
            jsonDecode(catalog.toPrettyJson()) as Map<String, Object?>;
        expect(
          (decoded['frames'] as Map).containsKey(
            'assets/sprites/units/worker.png|work|3',
          ),
          isTrue,
        );
        expect(
          (decoded['frames'] as Map)['assets/sprites/units/worker.png|work|3'],
          containsPair('scaleX', 1.25),
        );
      },
    );

    test('migrates legacy civilian attack adjustments to work', () {
      final catalog = AnimationFrameAdjustmentCatalog.fromJson({
        'frames': {
          'assets/sprites/units/settler.png|attack|2': {'offsetX': 7},
          'assets/sprites/units/worker.png|attack|1': {'cropLeft': 5},
        },
      });

      expect(
        catalog.adjustmentFor(
          assetPath: 'assets/sprites/units/settler.png',
          animationId: 'work',
          frameIndex: 2,
        ),
        const AnimationFrameAdjustment(offsetX: 7),
      );
      expect(
        catalog.adjustmentFor(
          assetPath: 'assets/sprites/units/worker.png',
          animationId: 'work',
          frameIndex: 1,
        ),
        const AnimationFrameAdjustment(cropLeft: 5),
      );
      expect(
        catalog.frames.keys.where((key) => key.contains('|attack|')),
        isEmpty,
      );
    });

    test(
      'keeps explicit work adjustment over a legacy civilian attack key',
      () {
        final catalog = AnimationFrameAdjustmentCatalog.fromJson({
          'frames': {
            'assets/sprites/units/settler.png|work|2': {'offsetX': 3},
            'assets/sprites/units/settler.png|attack|2': {'offsetX': 7},
          },
        });

        expect(
          catalog.adjustmentFor(
            assetPath: 'assets/sprites/units/settler.png',
            animationId: 'work',
            frameIndex: 2,
          ),
          const AnimationFrameAdjustment(offsetX: 3),
        );
      },
    );

    test('serializes animation frame durations by asset animation key', () {
      final catalog = const AnimationFrameAdjustmentCatalog.empty()
          .withAnimationFrameDuration(
            assetPath: 'assets/sprites/units/worker.png',
            animationId: 'walk',
            frameDuration: 0.2,
            defaultFrameDuration: 0.14,
          );

      expect(
        catalog.frameDurationFor(
          assetPath: 'assets/sprites/units/worker.png',
          animationId: 'walk',
          defaultFrameDuration: 0.14,
        ),
        0.2,
      );

      final decoded =
          jsonDecode(catalog.toPrettyJson()) as Map<String, Object?>;
      expect(
        (decoded['animations'] as Map)['assets/sprites/units/worker.png|walk'],
        {'frameDuration': 0.2},
      );
    });

    test('drops animation durations matching the default frame duration', () {
      final catalog = const AnimationFrameAdjustmentCatalog.empty()
          .withAnimationFrameDuration(
            assetPath: 'assets/sprites/units/worker.png',
            animationId: 'walk',
            frameDuration: 0.14,
            defaultFrameDuration: 0.14,
          );

      expect(catalog.animationFrameDurations, isEmpty);
      expect(
        catalog.frameDurationFor(
          assetPath: 'assets/sprites/units/worker.png',
          animationId: 'walk',
          defaultFrameDuration: 0.14,
        ),
        0.14,
      );
    });

    test('parses animation frame durations and legacy civilian work keys', () {
      final catalog = AnimationFrameAdjustmentCatalog.fromJson(
        <String, Object?>{
          'animations': <String, Object?>{
            'assets/sprites/units/settler.png|attack': {'frameDuration': 0.31},
            'assets/sprites/units/worker.png|walk': 0.19,
            'assets/sprites/units/worker.png|idle': {'frameDuration': -1},
          },
        },
      );

      expect(
        catalog.frameDurationFor(
          assetPath: 'assets/sprites/units/settler.png',
          animationId: 'work',
          defaultFrameDuration: 0.22,
        ),
        0.31,
      );
      expect(
        catalog.frameDurationFor(
          assetPath: 'assets/sprites/units/worker.png',
          animationId: 'walk',
          defaultFrameDuration: 0.14,
        ),
        0.19,
      );
      expect(
        catalog.frameDurationFor(
          assetPath: 'assets/sprites/units/worker.png',
          animationId: 'idle',
          defaultFrameDuration: 0.9,
        ),
        0.9,
      );
    });

    test('bundled unit idle animations share the authored 1.82s loop', () {
      final catalog = AnimationFrameAdjustmentCatalog.fromJson(
        jsonDecode(
          File(AnimationFrameAdjustmentCatalog.assetPath).readAsStringSync(),
        ),
      );

      for (final definition in UnitSpriteCatalog.definitions.values) {
        final idle = definition.actionDefinition(UnitSpriteAction.idle);
        final frameDuration = catalog.frameDurationFor(
          assetPath: definition.assetPath,
          animationId: UnitSpriteAction.idle.name,
          defaultFrameDuration: idle.frameDuration,
        );

        expect(
          frameDuration * idle.frameCount,
          closeTo(1.82, 0.000001),
          reason: '${definition.assetPath} idle should finish in 1.82s',
        );
      }
    });
  });

  group('saveAssetAdjustmentsJson', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'animation_adjustments_test_',
      );
      PathProviderPlatform.instance = _MockPathProvider(tempDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('writes beside maps and saves in the app data root', () async {
      final result = await saveAssetAdjustmentsJson('{"frames":{}}');

      final file = File('${tempDir.path}/animation_frame_adjustments.json');
      expect(result.saved, isTrue);
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), '{"frames":{}}\n');
    });
  });
}
