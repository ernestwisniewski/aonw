import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:aonw/shared/providers/audio_settings_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const int _playerPoolSize = 6;
const int _preloadedPlayersPerSound = 2;
const String _musicAssetRoot = 'assets/sounds/music/';
const String _natureAssetRoot = 'assets/sounds/nature/';
const bool _enableDarwinDebugAudio = bool.fromEnvironment(
  'AONW_ENABLE_DARWIN_DEBUG_AUDIO',
);

class GameAudioController {
  GameAudioController({AssetBundle? bundle, math.Random? musicRandom})
    : _bundle = bundle ?? rootBundle {
    _musicLoop = _LoopingAssetFolderPlayer(
      bundle: _bundle,
      assetRoot: _musicAssetRoot,
      shufflePlaylist: true,
      random: musicRandom,
    );
    _natureLoop = _LoopingAssetFolderPlayer(
      bundle: _bundle,
      assetRoot: _natureAssetRoot,
    );
  }

  final AssetBundle _bundle;
  final Map<GameSoundCue, Future<AudioPool>> _poolFutures = {};
  late final _LoopingAssetFolderPlayer _musicLoop;
  late final _LoopingAssetFolderPlayer _natureLoop;
  GameAudioSettings _settings = const GameAudioSettings();
  AudioContext? _audioContext;
  bool _musicLoopActive = false;
  bool _natureLoopActive = false;
  bool _disposed = false;

  Future<void> applySettings(GameAudioSettings settings) async {
    if (_disposed) return;
    final nextContext = _audioContextFor(settings);
    final contextChanged = _audioContext != nextContext;
    _settings = settings;
    if (contextChanged) {
      _audioContext = nextContext;
      _discardAllPools();
      if (_playbackAllowed) {
        try {
          await AudioPlayer.global.setAudioContext(nextContext);
        } catch (_) {}
      }
    }
    await _syncMusicLoop();
    await _syncNatureLoop();
  }

  Future<void> play(GameSoundCue cue, {double volume = 1}) async {
    if (_disposed || !_playbackAllowed || !_settings.soundsEnabled) return;
    try {
      final pool = await _poolFor(cue);
      if (_disposed || !_playbackAllowed || !_settings.soundsEnabled) return;
      await pool.start(
        volume: (volume * _settings.soundVolume).clamp(0, 1).toDouble(),
      );
    } catch (_) {
      _discardPool(cue);
    }
  }

  void playAll(Iterable<GameSoundCue> cues) {
    for (final cue in cues) {
      unawaited(play(cue));
    }
  }

  Future<void> preloadAll() async {
    if (_disposed || !_playbackAllowed) return;
    await Future.wait([
      for (final cue in GameSoundCue.values)
        () async {
          if (_disposed || !_playbackAllowed) return;
          try {
            await _poolFor(cue);
          } catch (_) {
            _discardPool(cue);
          }
        }(),
    ]);
  }

  Future<void> startMusicLoop() async {
    if (_disposed) return;
    _musicLoopActive = true;
    await _syncMusicLoop();
  }

  Future<void> stopMusicLoop() async {
    _musicLoopActive = false;
    await _musicLoop.stop();
  }

  Future<void> startNatureLoop() async {
    if (_disposed) return;
    _natureLoopActive = true;
    await _syncNatureLoop();
  }

  Future<void> stopNatureLoop() async {
    _natureLoopActive = false;
    await _natureLoop.stop();
  }

  Future<void> _syncMusicLoop() async {
    if (_disposed || !_musicLoopActive || !_playbackAllowed) return;
    final context = _audioContext ?? _audioContextFor(_settings);
    await _musicLoop.update(
      enabled: _settings.musicEnabled,
      volume: _settings.musicVolume,
      audioContext: context,
    );
  }

  Future<void> _syncNatureLoop() async {
    if (_disposed || !_natureLoopActive || !_playbackAllowed) return;
    final context = _audioContext ?? _audioContextFor(_settings);
    await _natureLoop.update(
      enabled: _settings.natureEnabled,
      volume: _settings.natureVolume,
      audioContext: context,
    );
  }

  Future<AudioPool> _poolFor(GameSoundCue cue) {
    return _poolFutures[cue] ??= AudioPool.create(
      source: AssetSource('sounds/${cue.assetName}.wav'),
      minPlayers: _preloadedPlayersPerSound,
      maxPlayers: _playerPoolSize,
      audioContext: _audioContext ?? _audioContextFor(_settings),
    );
  }

  void _discardPool(GameSoundCue cue) {
    final poolFuture = _poolFutures.remove(cue);
    if (poolFuture == null) return;
    unawaited(_disposePoolFuture(poolFuture));
  }

  void _discardAllPools() {
    final poolFutures = _poolFutures.values.toList();
    _poolFutures.clear();
    for (final poolFuture in poolFutures) {
      unawaited(_disposePoolFuture(poolFuture));
    }
  }

  Future<void> _disposePoolFuture(Future<AudioPool> poolFuture) async {
    try {
      final pool = await poolFuture;
      await pool.dispose();
    } catch (_) {}
  }

  bool get _playbackAllowed {
    var allowed = true;
    assert(() {
      final bindingType = BindingBase.debugBindingType()?.toString();
      allowed = bindingType != null && !bindingType.contains('Test');
      return true;
    }());
    return allowed &&
        isAudioPlaybackAllowedForPlatform(
          debugMode: kDebugMode,
          isWeb: kIsWeb,
          targetPlatform: defaultTargetPlatform,
        );
  }

  AudioContext _audioContextFor(GameAudioSettings settings) {
    return AudioContextConfig(
      focus: settings.gameMusicAudible
          ? AudioContextConfigFocus.gain
          : AudioContextConfigFocus.mixWithOthers,
    ).build();
  }

  Future<void> dispose() async {
    _disposed = true;
    await Future.wait([_musicLoop.dispose(), _natureLoop.dispose()]);
    final poolFutures = _poolFutures.values.toList();
    _poolFutures.clear();
    for (final poolFuture in poolFutures) {
      try {
        final pool = await poolFuture;
        await pool.dispose();
      } catch (_) {}
    }
  }
}

@visibleForTesting
bool isAudioPlaybackAllowedForPlatform({
  required bool debugMode,
  required bool isWeb,
  required TargetPlatform targetPlatform,
}) {
  if (isWeb || !debugMode || _enableDarwinDebugAudio) return true;
  return switch (targetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => false,
    _ => true,
  };
}

@visibleForTesting
List<String> buildLoopingAudioPlaylist({
  required Iterable<String> assetPaths,
  required String assetRoot,
  bool shuffle = false,
  math.Random? random,
}) {
  final playlist =
      assetPaths
          .where(
            (path) =>
                path.startsWith(assetRoot) &&
                path.toLowerCase().endsWith('.mp3'),
          )
          .toList()
        ..sort();
  if (shuffle && playlist.length > 1) {
    _shufflePlaylist(playlist, random ?? math.Random());
  }
  return playlist;
}

void _shufflePlaylist(List<String> playlist, math.Random random) {
  for (var index = playlist.length - 1; index > 0; index--) {
    final swapIndex = random.nextInt(index + 1);
    final current = playlist[index];
    playlist[index] = playlist[swapIndex];
    playlist[swapIndex] = current;
  }
}

class _LoopingAssetFolderPlayer {
  _LoopingAssetFolderPlayer({
    required AssetBundle bundle,
    required String assetRoot,
    bool shufflePlaylist = false,
    math.Random? random,
  }) : _bundle = bundle,
       _assetRoot = assetRoot,
       _shufflePlaylist = shufflePlaylist,
       _random = random;

  final AssetBundle _bundle;
  final String _assetRoot;
  final bool _shufflePlaylist;
  final math.Random? _random;
  AudioPlayer? _player;
  StreamSubscription<void>? _completionSub;
  Future<List<String>>? _assetPathsFuture;
  AudioContext? _audioContext;
  bool _running = false;
  bool _disposed = false;
  double _volume = 1;
  int _index = 0;

  Future<void> update({
    required bool enabled,
    required double volume,
    required AudioContext audioContext,
  }) async {
    if (_disposed) return;
    _volume = volume.clamp(0.0, 1.0).toDouble();
    if (!enabled || _volume <= 0) {
      await stop();
      return;
    }

    final player = _ensurePlayer();
    if (_audioContext != audioContext) {
      _audioContext = audioContext;
      await player.setAudioContext(audioContext);
    }
    await player.setVolume(_volume);
    if (_running) return;

    _running = true;
    _completionSub ??= player.onPlayerComplete.listen((_) {
      if (!_running || _disposed) return;
      _index++;
      unawaited(_playCurrent());
    });
    await _playCurrent();
  }

  Future<void> stop() async {
    _running = false;
    await _player?.stop();
  }

  Future<void> _playCurrent() async {
    final paths = await _assetPaths();
    if (!_running || _disposed) return;
    if (paths.isEmpty) {
      _running = false;
      return;
    }
    if (_index >= paths.length) _index = 0;
    final player = _ensurePlayer();
    await player.play(AssetSource(_assetSourcePath(paths[_index])));
    await player.setVolume(_volume);
  }

  Future<List<String>> _assetPaths() {
    return _assetPathsFuture ??= AssetManifest.loadFromAssetBundle(_bundle)
        .then((manifest) {
          return buildLoopingAudioPlaylist(
            assetPaths: manifest.listAssets(),
            assetRoot: _assetRoot,
            shuffle: _shufflePlaylist,
            random: _random,
          );
        });
  }

  String _assetSourcePath(String assetPath) {
    const prefix = 'assets/';
    return assetPath.startsWith(prefix)
        ? assetPath.substring(prefix.length)
        : assetPath;
  }

  AudioPlayer _ensurePlayer() {
    return _player ??= AudioPlayer();
  }

  Future<void> dispose() async {
    _disposed = true;
    _running = false;
    await _completionSub?.cancel();
    await _player?.dispose();
  }
}
