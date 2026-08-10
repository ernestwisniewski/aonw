import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/shared/math/scale_clamp.dart';

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
    return clampFiniteScale(value, min: 0.25, max: 3.0);
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
