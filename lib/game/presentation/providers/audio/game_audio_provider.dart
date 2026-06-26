import 'dart:async';

import 'package:aonw/game/presentation/audio/game_audio_controller.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:aonw/shared/providers/audio_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gameAudioControllerProvider = Provider<GameAudioController>((ref) {
  final controller = GameAudioController();
  unawaited(controller.applySettings(ref.read(gameAudioSettingsProvider)));
  ref.listen(gameAudioSettingsProvider, (_, next) {
    unawaited(controller.applySettings(next));
  });
  unawaited(controller.preloadAll());
  ref.onDispose(() => unawaited(controller.dispose()));
  return controller;
});

extension GameAudioControllerRef on Ref {
  void playSound(GameSoundCue cue) {
    unawaited(read(gameAudioControllerProvider).play(cue));
  }

  void playSounds(Iterable<GameSoundCue> cues) {
    read(gameAudioControllerProvider).playAll(cues);
  }
}
