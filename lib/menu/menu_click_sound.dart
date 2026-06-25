import 'dart:async';

import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:aonw/game/presentation/providers/game_audio_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension MenuClickSoundRef on WidgetRef {
  void playMenuClick() {
    _playMenuSound(GameSoundCue.menuClick);
  }

  void playMenuBack() {
    _playMenuSound(GameSoundCue.menuBack);
  }

  void _playMenuSound(GameSoundCue cue) {
    try {
      unawaited(read(gameAudioControllerProvider).play(cue));
    } catch (_) {}
  }

  VoidCallback withMenuClick(VoidCallback action) {
    return () {
      playMenuClick();
      action();
    };
  }

  VoidCallback withMenuBack(VoidCallback action) {
    return () {
      playMenuBack();
      action();
    };
  }

  VoidCallback withMenuBackAsync(Future<void> Function() action) {
    return () {
      playMenuBack();
      unawaited(action());
    };
  }

  VoidCallback withMenuClickAsync(Future<void> Function() action) {
    return () {
      playMenuClick();
      unawaited(action());
    };
  }

  ValueChanged<T> withMenuClickValue<T>(ValueChanged<T> action) {
    return (value) {
      playMenuClick();
      action(value);
    };
  }

  ValueChanged<T> withMenuClickValueAsync<T>(
    Future<void> Function(T value) action,
  ) {
    return (value) {
      playMenuClick();
      unawaited(action(value));
    };
  }
}
