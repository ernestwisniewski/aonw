import 'dart:async';

import 'package:aonw/game/presentation/audio/game_audio_controller.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:aonw/shared/providers/audio_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gameAudioControllerProvider = Provider<GameAudioController>((ref) {
  final controller = GameAudioController();
  unawaited(_initializeAudio(controller, ref.read(gameAudioSettingsProvider)));
  ref
    ..listen(gameAudioSettingsProvider, (_, next) {
      unawaited(controller.applySettings(next));
    })
    ..onDispose(() => unawaited(controller.dispose()));
  return controller;
});

Future<void> _initializeAudio(
  GameAudioController controller,
  GameAudioSettings settings,
) async {
  await controller.applySettings(settings);
  await controller.preloadAll();
}

extension GameAudioControllerRef on Ref {
  void playSound(GameSoundCue cue) {
    unawaited(read(gameAudioControllerProvider).play(cue));
  }

  void playSounds(Iterable<GameSoundCue> cues) {
    read(gameAudioControllerProvider).playAll(cues);
  }
}
