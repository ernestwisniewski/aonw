import 'dart:io';
import 'dart:math' as math;

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
    test('disables Darwin audio in debug builds', () {
      expect(
        isAudioPlaybackAllowedForPlatform(
          debugMode: true,
          isWeb: false,
          targetPlatform: TargetPlatform.iOS,
        ),
        isFalse,
      );
      expect(
        isAudioPlaybackAllowedForPlatform(
          debugMode: true,
          isWeb: false,
          targetPlatform: TargetPlatform.macOS,
        ),
        isFalse,
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
    test('each sound cue has a matching wav file', () {
      for (final cue in GameSoundCue.values) {
        expect(
          File('assets/sounds/${cue.assetName}.wav').existsSync(),
          isTrue,
          reason: 'Missing asset for $cue',
        );
      }
    });
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
