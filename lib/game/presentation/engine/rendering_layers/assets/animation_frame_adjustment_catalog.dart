import 'dart:convert';

import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustment.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustment_paths.dart';

class AnimationFrameAdjustmentCatalog {
  static const String assetPath =
      AnimationFrameAdjustmentPaths.bundledAssetPath;

  final Map<String, AnimationFrameAdjustment> frames;
  final Map<String, double> animationFrameDurations;

  const AnimationFrameAdjustmentCatalog({
    required this.frames,
    this.animationFrameDurations = const {},
  });

  const AnimationFrameAdjustmentCatalog.empty()
    : frames = const {},
      animationFrameDurations = const {};

  AnimationFrameAdjustment adjustmentFor({
    required String assetPath,
    required String animationId,
    required int frameIndex,
  }) {
    final key = frameKey(
      assetPath: assetPath,
      animationId: animationId,
      frameIndex: frameIndex,
    );
    return frames[key] ??
        frames[_legacyFrameKeyFor(
          assetPath: assetPath,
          animationId: animationId,
          frameIndex: frameIndex,
        )] ??
        const AnimationFrameAdjustment();
  }

  AnimationFrameAdjustmentCatalog withFrame({
    required String assetPath,
    required String animationId,
    required int frameIndex,
    required AnimationFrameAdjustment adjustment,
  }) {
    final key = frameKey(
      assetPath: assetPath,
      animationId: animationId,
      frameIndex: frameIndex,
    );
    final next = Map<String, AnimationFrameAdjustment>.of(frames);
    if (adjustment.isZero) {
      next.remove(key);
    } else {
      next[key] = adjustment;
    }
    return AnimationFrameAdjustmentCatalog(
      frames: Map.unmodifiable(next),
      animationFrameDurations: animationFrameDurations,
    );
  }

  double frameDurationFor({
    required String assetPath,
    required String animationId,
    required double defaultFrameDuration,
  }) {
    final key = animationKey(assetPath: assetPath, animationId: animationId);
    return animationFrameDurations[key] ??
        animationFrameDurations[_legacyAnimationKeyFor(
          assetPath: assetPath,
          animationId: animationId,
        )] ??
        defaultFrameDuration;
  }

  AnimationFrameAdjustmentCatalog withAnimationFrameDuration({
    required String assetPath,
    required String animationId,
    required double frameDuration,
    double? defaultFrameDuration,
  }) {
    final key = animationKey(assetPath: assetPath, animationId: animationId);
    final next = Map<String, double>.of(animationFrameDurations);
    if (!_isValidAnimationFrameDuration(frameDuration) ||
        (defaultFrameDuration != null &&
            _sameDuration(frameDuration, defaultFrameDuration))) {
      next.remove(key);
    } else {
      next[key] = frameDuration;
    }
    return AnimationFrameAdjustmentCatalog(
      frames: frames,
      animationFrameDurations: Map.unmodifiable(next),
    );
  }

  Map<String, Object> toJson() {
    final sortedKeys = frames.keys.toList()..sort();
    final sortedAnimationKeys = animationFrameDurations.keys.toList()..sort();
    return {
      'version': 1,
      'frames': {
        for (final key in sortedKeys)
          if (!frames[key]!.isZero) key: frames[key]!.toJson(),
      },
      if (sortedAnimationKeys.isNotEmpty)
        'animations': {
          for (final key in sortedAnimationKeys)
            key: {'frameDuration': animationFrameDurations[key]!},
        },
    };
  }

  String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  factory AnimationFrameAdjustmentCatalog.fromJson(Object? json) {
    if (json is! Map) return const AnimationFrameAdjustmentCatalog.empty();
    final rawFrames = json['frames'];
    final frames = <String, AnimationFrameAdjustment>{};
    if (rawFrames is Map) {
      for (final entry in rawFrames.entries) {
        final key = entry.key;
        if (key is! String) continue;
        final normalizedKey = _normalizedFrameKey(key);
        final adjustment = AnimationFrameAdjustment.fromJson(entry.value);
        if (!adjustment.isZero) {
          if (normalizedKey == key || !frames.containsKey(normalizedKey)) {
            frames[normalizedKey] = adjustment;
          }
        }
      }
    }
    return AnimationFrameAdjustmentCatalog(
      frames: Map.unmodifiable(frames),
      animationFrameDurations: Map.unmodifiable(
        _animationFrameDurationsFromJson(json['animations']),
      ),
    );
  }

  static String frameKey({
    required String assetPath,
    required String animationId,
    required int frameIndex,
  }) {
    return '$assetPath|$animationId|$frameIndex';
  }

  static String animationKey({
    required String assetPath,
    required String animationId,
  }) {
    return '$assetPath|$animationId';
  }

  static String _normalizedFrameKey(String key) {
    final parts = key.split('|');
    if (parts.length != 3) return key;
    final assetPath = parts[0];
    final animationId = parts[1];
    if (!_usesLegacyCivilianWorkKey(assetPath, animationId)) return key;
    final frameIndex = int.tryParse(parts[2]);
    if (frameIndex == null) return key;
    return frameKey(
      assetPath: assetPath,
      animationId: 'work',
      frameIndex: frameIndex,
    );
  }

  static String? _legacyFrameKeyFor({
    required String assetPath,
    required String animationId,
    required int frameIndex,
  }) {
    if (animationId != 'work' || !_civilianWorkAssets.contains(assetPath)) {
      return null;
    }
    return frameKey(
      assetPath: assetPath,
      animationId: 'attack',
      frameIndex: frameIndex,
    );
  }

  static String? _legacyAnimationKeyFor({
    required String assetPath,
    required String animationId,
  }) {
    if (animationId != 'work' || !_civilianWorkAssets.contains(assetPath)) {
      return null;
    }
    return animationKey(assetPath: assetPath, animationId: 'attack');
  }

  static bool _usesLegacyCivilianWorkKey(String assetPath, String animationId) {
    return animationId == 'attack' && _civilianWorkAssets.contains(assetPath);
  }

  static Map<String, double> _animationFrameDurationsFromJson(Object? json) {
    if (json is! Map) return const {};
    final durations = <String, double>{};
    for (final entry in json.entries) {
      final key = entry.key;
      if (key is! String) continue;
      final normalizedKey = _normalizedAnimationKey(key);
      final frameDuration = _frameDurationValue(entry.value);
      if (frameDuration == null) continue;
      if (normalizedKey == key || !durations.containsKey(normalizedKey)) {
        durations[normalizedKey] = frameDuration;
      }
    }
    return durations;
  }

  static String _normalizedAnimationKey(String key) {
    final parts = key.split('|');
    if (parts.length != 2) return key;
    final assetPath = parts[0];
    final animationId = parts[1];
    if (!_usesLegacyCivilianWorkKey(assetPath, animationId)) return key;
    return animationKey(assetPath: assetPath, animationId: 'work');
  }

  static double? _frameDurationValue(Object? json) {
    final value = switch (json) {
      num() => json.toDouble(),
      Map() => json['frameDuration'],
      _ => null,
    };
    if (value is! num) return null;
    final duration = value.toDouble();
    if (!_isValidAnimationFrameDuration(duration)) return null;
    return duration;
  }

  static bool _isValidAnimationFrameDuration(double value) {
    return value.isFinite && value > 0;
  }

  static bool _sameDuration(double a, double b) => (a - b).abs() < 0.000001;

  static const Set<String> _civilianWorkAssets = {
    'assets/sprites/units/merchant.png',
    'assets/sprites/units/settler.png',
    'assets/sprites/units/worker.png',
  };
}
