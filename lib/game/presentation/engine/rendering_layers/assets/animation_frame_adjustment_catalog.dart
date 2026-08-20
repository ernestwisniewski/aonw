import 'dart:convert';

import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustment.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustment_paths.dart';
import 'package:aonw/shared/assets/sprite_frame_id.dart';

class AnimationFrameAdjustmentCatalog {
  static const String assetPath =
      AnimationFrameAdjustmentPaths.bundledAssetPath;

  const AnimationFrameAdjustmentCatalog({
    required this.frames,
    this.animationFrameDurations = const {},
  });

  const AnimationFrameAdjustmentCatalog.empty()
    : frames = const {},
      animationFrameDurations = const {};

  final Map<String, AnimationFrameAdjustment> frames;
  final Map<String, double> animationFrameDurations;

  AnimationFrameAdjustment adjustmentFor({
    required SpriteSequenceId sequenceId,
    required int frameIndex,
  }) {
    return frames[frameKey(sequenceId: sequenceId, frameIndex: frameIndex)] ??
        const AnimationFrameAdjustment();
  }

  AnimationFrameAdjustmentCatalog withFrame({
    required SpriteSequenceId sequenceId,
    required int frameIndex,
    required AnimationFrameAdjustment adjustment,
  }) {
    final key = frameKey(sequenceId: sequenceId, frameIndex: frameIndex);
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
    required SpriteSequenceId sequenceId,
    required double defaultFrameDuration,
  }) {
    return animationFrameDurations[animationKey(sequenceId)] ??
        defaultFrameDuration;
  }

  AnimationFrameAdjustmentCatalog withAnimationFrameDuration({
    required SpriteSequenceId sequenceId,
    required double frameDuration,
    double? defaultFrameDuration,
  }) {
    final key = animationKey(sequenceId);
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
      'version': 2,
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

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory AnimationFrameAdjustmentCatalog.fromJson(Object? json) {
    if (json is! Map || json['version'] != 2) {
      return const AnimationFrameAdjustmentCatalog.empty();
    }
    final frames = <String, AnimationFrameAdjustment>{};
    final rawFrames = json['frames'];
    if (rawFrames is Map) {
      for (final entry in rawFrames.entries) {
        if (entry.key is! String) continue;
        final adjustment = AnimationFrameAdjustment.fromJson(entry.value);
        if (!adjustment.isZero) {
          frames[entry.key as String] = adjustment;
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
    required SpriteSequenceId sequenceId,
    required int frameIndex,
  }) => '${sequenceId.value}|$frameIndex';

  static String animationKey(SpriteSequenceId sequenceId) => sequenceId.value;

  static Map<String, double> _animationFrameDurationsFromJson(Object? json) {
    if (json is! Map) return const {};
    final durations = <String, double>{};
    for (final entry in json.entries) {
      if (entry.key is! String) continue;
      final frameDuration = _frameDurationValue(entry.value);
      if (frameDuration != null) {
        durations[entry.key as String] = frameDuration;
      }
    }
    return durations;
  }

  static double? _frameDurationValue(Object? json) {
    final value = switch (json) {
      num() => json.toDouble(),
      Map() => json['frameDuration'],
      _ => null,
    };
    if (value is! num) return null;
    final duration = value.toDouble();
    return _isValidAnimationFrameDuration(duration) ? duration : null;
  }

  static bool _isValidAnimationFrameDuration(double value) =>
      value.isFinite && value > 0;

  static bool _sameDuration(double a, double b) => (a - b).abs() < 0.000001;
}
