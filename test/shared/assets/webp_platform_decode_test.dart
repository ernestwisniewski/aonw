import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:aonw/shared/assets/atlas_store.dart';
import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw/shared/assets/texture_packer_sprite_frame_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'platform codec and texture packer decode bundled WebP',
    () async {
      final manifest =
          jsonDecode(
                await rootBundle.loadString(
                  TexturePackerSpriteFrameRepository.manifestPath,
                ),
              )
              as Map<String, dynamic>;
      final atlases = (manifest['atlases'] as Map<String, dynamic>).keys
          .toSet();
      final frameEntries = manifest['frames'] as Map<String, dynamic>;
      final representatives = <String, SpriteFrameId>{};
      for (final entry in frameEntries.entries) {
        final atlasId =
            (entry.value as Map<String, dynamic>)['atlas'] as String;
        representatives.putIfAbsent(atlasId, () => SpriteFrameId(entry.key));
      }
      final repository = TexturePackerSpriteFrameRepository(
        store: AtlasStore(bundle: rootBundle),
      );
      addTearDown(repository.dispose);

      expect(representatives.keys, unorderedEquals(atlases));
      // Browser coverage proves WebP codec and TexturePacker integration on a
      // real generated atlas. Native tests retain exhaustive per-atlas
      // coverage; decoding every 2048 px page under DDC is prohibitively slow.
      final atlasesUnderTest = kIsWeb ? const {'dice'} : atlases;
      expect(atlases, containsAll(atlasesUnderTest));
      for (final atlasId in atlasesUnderTest) {
        final id = representatives[atlasId]!;
        final frame = await repository
            .load(id)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException(
                'Timed out decoding WebP atlas $atlasId',
              ),
            );
        expect(frame.source.isEmpty, isFalse, reason: id.value);
        repository.disposeAtlas(atlasId);
      }

      final logoData = await rootBundle.load('assets/runtime/ui/logo.webp');
      final logoCodec = await ui.instantiateImageCodec(
        logoData.buffer.asUint8List(
          logoData.offsetInBytes,
          logoData.lengthInBytes,
        ),
      );
      try {
        final logo = (await logoCodec.getNextFrame()).image;
        try {
          expect((logo.width, logo.height), (768, 512));
        } finally {
          logo.dispose();
        }
      } finally {
        logoCodec.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
