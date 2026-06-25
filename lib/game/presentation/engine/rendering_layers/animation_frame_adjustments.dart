import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/animation_frame_adjustment_external_loader.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/animation_frame_adjustment_paths.dart';
import 'package:flutter/services.dart';

class AnimationFrameAdjustment {
  final double offsetX;
  final double offsetY;
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;
  final double scaleX;
  final double scaleY;

  const AnimationFrameAdjustment({
    this.offsetX = 0,
    this.offsetY = 0,
    this.cropLeft = 0,
    this.cropTop = 0,
    this.cropRight = 0,
    this.cropBottom = 0,
    this.scaleX = 1,
    this.scaleY = 1,
  });

  bool get isZero =>
      offsetX == 0 &&
      offsetY == 0 &&
      cropLeft == 0 &&
      cropTop == 0 &&
      cropRight == 0 &&
      cropBottom == 0 &&
      scaleX == 1 &&
      scaleY == 1;

  AnimationFrameAdjustment copyWith({
    double? offsetX,
    double? offsetY,
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
    double? scaleX,
    double? scaleY,
  }) {
    return AnimationFrameAdjustment(
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      cropLeft: cropLeft ?? this.cropLeft,
      cropTop: cropTop ?? this.cropTop,
      cropRight: cropRight ?? this.cropRight,
      cropBottom: cropBottom ?? this.cropBottom,
      scaleX: scaleX ?? this.scaleX,
      scaleY: scaleY ?? this.scaleY,
    );
  }

  AnimationFrameAdjustment nudge({double dx = 0, double dy = 0}) {
    return copyWith(offsetX: offsetX + dx, offsetY: offsetY + dy);
  }

  AnimationFrameAdjustment scaleBy({double dx = 0, double dy = 0}) {
    return copyWith(
      scaleX: _clampedScale(scaleX + dx),
      scaleY: _clampedScale(scaleY + dy),
    );
  }

  AnimationFrameAdjustment adjustCrop({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return copyWith(
      cropLeft: cropLeft + left,
      cropTop: cropTop + top,
      cropRight: cropRight + right,
      cropBottom: cropBottom + bottom,
    );
  }

  AnimationFrameAdjustment resetScale() {
    return copyWith(scaleX: 1, scaleY: 1);
  }

  ui.Rect croppedSourceFor(ui.Rect source) {
    final crop = _resolvedCropFor(source);

    return ui.Rect.fromLTRB(
      source.left + crop.left,
      source.top + crop.top,
      source.right - crop.right,
      source.bottom - crop.bottom,
    );
  }

  ui.Rect croppedDestinationFor({
    required ui.Rect baseSource,
    required ui.Rect baseDestination,
  }) {
    final scaleX = baseDestination.width / math.max(1.0, baseSource.width);
    final scaleY = baseDestination.height / math.max(1.0, baseSource.height);
    final crop = _resolvedCropFor(baseSource);
    return ui.Rect.fromLTRB(
      baseDestination.left + crop.left * scaleX,
      baseDestination.top + crop.top * scaleY,
      baseDestination.right - crop.right * scaleX,
      baseDestination.bottom - crop.bottom * scaleY,
    );
  }

  ui.Rect adjustedDestinationFor({
    required ui.Rect baseSource,
    required ui.Rect baseDestination,
  }) {
    final croppedDestination = croppedDestinationFor(
      baseSource: baseSource,
      baseDestination: baseDestination,
    );
    final sx = _clampedScale(scaleX);
    final sy = _clampedScale(scaleY);
    if (sx == 1 && sy == 1) return croppedDestination;

    return ui.Rect.fromCenter(
      center: croppedDestination.center,
      width: math.max(1.0, croppedDestination.width * sx),
      height: math.max(1.0, croppedDestination.height * sy),
    );
  }

  ({double left, double top, double right, double bottom}) _resolvedCropFor(
    ui.Rect source,
  ) {
    final maxHorizontalCrop = math.max(0.0, source.width - 1);
    final maxVerticalCrop = math.max(0.0, source.height - 1);
    final left = _finiteCrop(
      cropLeft,
    ).clamp(double.negativeInfinity, maxHorizontalCrop).toDouble();
    final top = _finiteCrop(
      cropTop,
    ).clamp(double.negativeInfinity, maxVerticalCrop).toDouble();
    final right = _finiteCrop(
      cropRight,
    ).clamp(double.negativeInfinity, maxHorizontalCrop - left).toDouble();
    final bottom = _finiteCrop(
      cropBottom,
    ).clamp(double.negativeInfinity, maxVerticalCrop - top).toDouble();
    return (left: left, top: top, right: right, bottom: bottom);
  }

  ui.Offset scaledOffset({
    required ui.Size baseSize,
    required ui.Size targetSize,
  }) {
    final scaleX = targetSize.width / math.max(1.0, baseSize.width);
    final scaleY = targetSize.height / math.max(1.0, baseSize.height);
    return ui.Offset(offsetX * scaleX, offsetY * scaleY);
  }

  static double _clampedScale(double value) {
    if (!value.isFinite) return 1;
    return value.clamp(0.25, 3.0).toDouble();
  }

  static double _finiteCrop(double value) {
    if (!value.isFinite) return 0;
    return value;
  }

  Map<String, Object> toJson() {
    return {
      if (offsetX != 0) 'offsetX': offsetX,
      if (offsetY != 0) 'offsetY': offsetY,
      if (cropLeft != 0) 'cropLeft': cropLeft,
      if (cropTop != 0) 'cropTop': cropTop,
      if (cropRight != 0) 'cropRight': cropRight,
      if (cropBottom != 0) 'cropBottom': cropBottom,
      if (scaleX != 1) 'scaleX': scaleX,
      if (scaleY != 1) 'scaleY': scaleY,
    };
  }

  factory AnimationFrameAdjustment.fromJson(Object? json) {
    if (json is! Map) return const AnimationFrameAdjustment();
    return AnimationFrameAdjustment(
      offsetX: _doubleValue(json['offsetX']),
      offsetY: _doubleValue(json['offsetY']),
      cropLeft: _doubleValue(json['cropLeft']),
      cropTop: _doubleValue(json['cropTop']),
      cropRight: _doubleValue(json['cropRight']),
      cropBottom: _doubleValue(json['cropBottom']),
      scaleX: _scaleValue(json['scaleX']),
      scaleY: _scaleValue(json['scaleY']),
    );
  }

  static double _doubleValue(Object? value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  static double _scaleValue(Object? value) {
    if (value is! num) return 1;
    return _clampedScale(value.toDouble());
  }

  @override
  bool operator ==(Object other) {
    return other is AnimationFrameAdjustment &&
        other.offsetX == offsetX &&
        other.offsetY == offsetY &&
        other.cropLeft == cropLeft &&
        other.cropTop == cropTop &&
        other.cropRight == cropRight &&
        other.cropBottom == cropBottom &&
        other.scaleX == scaleX &&
        other.scaleY == scaleY;
  }

  @override
  int get hashCode => Object.hash(
    offsetX,
    offsetY,
    cropLeft,
    cropTop,
    cropRight,
    cropBottom,
    scaleX,
    scaleY,
  );
}

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

abstract final class AnimationFrameAdjustmentCatalogCache {
  static AnimationFrameAdjustmentCatalog? _catalog;

  static Future<AnimationFrameAdjustmentCatalog> load({
    AssetBundle? bundle,
    bool forceReload = false,
  }) async {
    if (!forceReload) {
      final cached = _catalog;
      if (cached != null) return cached;
    }

    final resolvedBundle = bundle ?? rootBundle;
    final externalJson = await loadExternalAnimationFrameAdjustmentsJson();
    if (externalJson != null) {
      try {
        final decoded = jsonDecode(externalJson);
        final catalog = AnimationFrameAdjustmentCatalog.fromJson(decoded);
        _catalog = catalog;
        return catalog;
      } on Object {
        // Fall back to the bundled asset when the desktop override is invalid.
      }
    }

    try {
      final raw = await resolvedBundle.loadString(
        AnimationFrameAdjustmentCatalog.assetPath,
      );
      final decoded = jsonDecode(raw);
      final catalog = AnimationFrameAdjustmentCatalog.fromJson(decoded);
      _catalog = catalog;
      return catalog;
    } on Object {
      const empty = AnimationFrameAdjustmentCatalog.empty();
      _catalog = empty;
      return empty;
    }
  }

  static void replace(AnimationFrameAdjustmentCatalog catalog) {
    _catalog = catalog;
  }

  static void clearForTesting() {
    _catalog = null;
  }
}
