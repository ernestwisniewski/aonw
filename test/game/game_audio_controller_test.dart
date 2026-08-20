import 'dart:io';
import 'dart:math' as math;

import 'package:aonw/game/presentation/audio/audio_asset_catalog.dart';
import 'package:aonw/game/presentation/audio/game_audio_controller.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildLoopingAudioPlaylist', () {
    test('filters and sorts mp3 assets for an asset folder', () {
      final playlist = buildLoopingAudioPlaylist(
        assetRoot: 'assets/sounds/music/',
        assetPaths: const [
          'assets/sounds/music/theme_b.mp3',
          'assets/sounds/nature/wind.mp3',
          'assets/sounds/music/readme.txt',
          'assets/sounds/music/theme_a.mp3',
          'assets/sounds/music/theme_c.MP3',
        ],
      );

      expect(playlist, const [
        'assets/sounds/music/theme_a.mp3',
        'assets/sounds/music/theme_b.mp3',
        'assets/sounds/music/theme_c.MP3',
      ]);
    });

    test('shuffles the initial playlist into a stable loop order', () {
      final playlist = buildLoopingAudioPlaylist(
        assetRoot: 'assets/sounds/music/',
        shuffle: true,
        random: _ZeroRandom(),
        assetPaths: const [
          'assets/sounds/music/theme_d.mp3',
          'assets/sounds/music/theme_b.mp3',
          'assets/sounds/music/theme_a.mp3',
          'assets/sounds/music/theme_c.mp3',
        ],
      );

      expect(playlist, const [
        'assets/sounds/music/theme_b.mp3',
        'assets/sounds/music/theme_c.mp3',
        'assets/sounds/music/theme_d.mp3',
        'assets/sounds/music/theme_a.mp3',
      ]);
    });
  });

  group('isAudioPlaybackAllowedForPlatform', () {
    test('enables Darwin audio in debug builds by default', () {
      expect(
        isAudioPlaybackAllowedForPlatform(
          debugMode: true,
          isWeb: false,
          targetPlatform: TargetPlatform.iOS,
        ),
        isTrue,
      );
      expect(
        isAudioPlaybackAllowedForPlatform(
          debugMode: true,
          isWeb: false,
          targetPlatform: TargetPlatform.macOS,
        ),
        isTrue,
      );
    });

    test('keeps release and non-Darwin audio enabled', () {
      expect(
        isAudioPlaybackAllowedForPlatform(
          debugMode: false,
          isWeb: false,
          targetPlatform: TargetPlatform.iOS,
        ),
        isTrue,
      );
      expect(
        isAudioPlaybackAllowedForPlatform(
          debugMode: true,
          isWeb: false,
          targetPlatform: TargetPlatform.android,
        ),
        isTrue,
      );
    });
  });

  group('GameSoundCue assets', () {
    test('each sound cue maps to an explicit physical asset', () {
      for (final cue in GameSoundCue.values) {
        final path = AudioAssetCatalog.effectFor(cue);
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'Missing $path for $cue',
        );
      }
    });

    test('deduplicates byte-identical semantic cues', () {
      expect(
        AudioAssetCatalog.effectFor(GameSoundCue.uiPanelClose),
        AudioAssetCatalog.effectFor(GameSoundCue.menuBack),
      );
      expect(
        AudioAssetCatalog.effectFor(GameSoundCue.movePreview),
        AudioAssetCatalog.effectFor(GameSoundCue.mapTileSelect),
      );
    });

    test('declares every looping track without scanning AssetManifest', () {
      for (final path in [
        ...AudioAssetCatalog.music,
        ...AudioAssetCatalog.nature,
      ]) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });
  });

  test('preloads sound cues sequentially', () async {
    var activeLoads = 0;
    var maximumConcurrentLoads = 0;
    final loaded = <GameSoundCue>[];
    final cues = GameSoundCue.values.take(3).toList();

    await preloadAudioCuesSequentially(cues, (cue) async {
      activeLoads++;
      maximumConcurrentLoads = math.max(maximumConcurrentLoads, activeLoads);
      await Future<void>.delayed(Duration.zero);
      loaded.add(cue);
      activeLoads--;
    });

    expect(loaded, cues);
    expect(maximumConcurrentLoads, 1);
  });
}

class _ZeroRandom implements math.Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}
