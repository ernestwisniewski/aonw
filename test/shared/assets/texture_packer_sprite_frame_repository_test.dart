import 'dart:async';
import 'dart:convert';

import 'package:aonw/shared/assets/atlas_store.dart';
import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw/shared/assets/texture_packer_sprite_frame_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads a complete untrimmed unit grid from one shared atlas page',
    () async {
      final repository = TexturePackerSpriteFrameRepository();
      addTearDown(repository.dispose);

      final idle = await repository.load(
        const SpriteFrameId('unit.worker.idle.0'),
      );
      final workFirst = await repository.load(
        const SpriteFrameId('unit.worker.work.0'),
      );
      final workLast = await repository.load(
        const SpriteFrameId('unit.worker.work.5'),
      );

      expect(idle.originalSize, const Size(252, 380));
      expect(workFirst.originalSize, const Size(252, 380));
      expect(workFirst.trimOffset, Offset.zero);
      expect(workFirst.source.size, workFirst.originalSize);
      expect(workFirst.image, same(idle.image));
      expect(workLast.image, same(idle.image));
      expect(workFirst.statusTop, workLast.statusTop);
      expect(repository.cached(workFirst.id), same(workFirst));
    },
  );

  test('does not alias a civilian work row to a combat attack row', () async {
    final repository = TexturePackerSpriteFrameRepository();
    addTearDown(repository.dispose);

    await expectLater(
      repository.load(const SpriteFrameId('unit.worker.attack.0')),
      throwsA(isA<StateError>()),
    );
  });

  test('deduplicates concurrent manifest and frame loads', () async {
    final bundle = _DelayedManifestBundle();
    final repository = TexturePackerSpriteFrameRepository(
      store: AtlasStore(bundle: bundle),
    );
    addTearDown(repository.dispose);
    const missing = SpriteFrameId('missing.frame');

    final first = repository.load(missing);
    final second = repository.load(missing);
    expect(bundle.loadStringCalls, 1);

    bundle.complete(_emptyManifest);

    await expectLater(first, throwsA(isA<StateError>()));
    await expectLater(second, throwsA(isA<StateError>()));
    expect(bundle.loadStringCalls, 1);
  });

  test('pending load cannot repopulate a disposed repository', () async {
    final bundle = _DelayedManifestBundle();
    final repository = TexturePackerSpriteFrameRepository(
      store: AtlasStore(bundle: bundle),
    );
    const missing = SpriteFrameId('missing.frame');

    final pending = repository.load(missing);
    repository.dispose();
    bundle.complete(_emptyManifest);

    await expectLater(
      pending,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('disposed'),
        ),
      ),
    );
    expect(() => repository.cached(missing), throwsStateError);
  });

  for (final invalidPath in [
    'assets/runtime/sprites/other/dice.atlas',
    'assets/runtime/sprites/dice/../dice.atlas',
    'invalid/sprites/dice/dice.atlas',
  ]) {
    test('rejects non-canonical sprite atlas path $invalidPath', () async {
      final bundle = _DelayedManifestBundle();
      final repository = TexturePackerSpriteFrameRepository(
        store: AtlasStore(bundle: bundle),
      );
      addTearDown(repository.dispose);
      final pending = repository.load(const SpriteFrameId('missing.frame'));
      bundle.complete(
        jsonEncode({
          'version': 1,
          'atlases': {'dice': invalidPath},
          'frames': <String, Object?>{},
        }),
      );

      await expectLater(pending, throwsFormatException);
    });
  }
}

final String _emptyManifest = jsonEncode({
  'version': 1,
  'atlases': <String, String>{},
  'frames': <String, Object?>{},
});

final class _DelayedManifestBundle extends CachingAssetBundle {
  final Completer<String> _manifest = Completer<String>();
  var loadStringCalls = 0;

  void complete(String value) => _manifest.complete(value);

  @override
  Future<ByteData> load(String key) =>
      Future.error(UnsupportedError('Unexpected binary asset: $key'));

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    loadStringCalls++;
    return _manifest.future;
  }
}
