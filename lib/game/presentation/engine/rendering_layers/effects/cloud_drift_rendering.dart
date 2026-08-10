part of 'cloud_drift_layer.dart';

extension _CloudDriftRendering on CloudDriftLayer {
  void _renderCloud(Canvas canvas, _Cloudlet cloud) {
    final progress = (cloud.elapsed / cloud.duration).clamp(0.0, 1.0);
    final opacity = math.sin(progress * math.pi) * cloud.opacity;
    if (opacity <= 0) return;

    final center = cloud.start + (cloud.end - cloud.start) * progress;
    final shadowAlpha = (opacity * 16).round().clamp(0, 255);
    final hazeAlpha = (opacity * 44).round().clamp(0, 255);
    final coreAlpha = (opacity * 34).round().clamp(0, 255);

    _shadowPaint.color = Color.fromARGB(shadowAlpha, 84, 91, 102);
    _hazePaint.color = Color.fromARGB(hazeAlpha, 235, 242, 247);
    _corePaint.color = Color.fromARGB(coreAlpha, 255, 255, 255);

    canvas
      ..save()
      ..translate(center.x, center.y)
      ..rotate(cloud.angle);

    for (final puff in cloud.puffs) {
      final rect = Rect.fromCenter(
        center: Offset(puff.x, puff.y),
        width: puff.width,
        height: puff.height,
      );
      canvas
        ..drawOval(rect.shift(const Offset(18, 22)), _shadowPaint)
        ..drawOval(rect, _hazePaint)
        ..drawOval(rect.deflate(puff.coreInset), _corePaint);
    }

    canvas.restore();
  }
}
