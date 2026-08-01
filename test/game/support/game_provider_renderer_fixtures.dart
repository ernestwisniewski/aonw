part of '../game_providers_test.dart';

GameRenderer _makeRenderer() {
  return GameRenderer(
    mapData: _makeMap(),
    initialViewMode: MapViewMode.tile,
    onCommand: (_) async {},
  );
}

class _RecordingAudioController extends GameAudioController {
  final cues = <GameSoundCue>[];

  @override
  Future<void> play(GameSoundCue cue, {double volume = 1}) async {
    cues.add(cue);
  }

  @override
  void playAll(Iterable<GameSoundCue> cues) {
    this.cues.addAll(cues);
  }
}
