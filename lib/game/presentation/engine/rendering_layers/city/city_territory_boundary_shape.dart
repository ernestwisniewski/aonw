import 'dart:ui';

Path cityTerritoryBoundaryShapePath(
  List<Offset> points, {
  required bool closed,
}) {
  final path = Path();
  if (points.isEmpty) return path;

  final baseLoopPoints = closed ? points.sublist(0, points.length - 1) : points;
  final loopPoints = closed
      ? _organicBoundaryPoints(baseLoopPoints)
      : baseLoopPoints;
  if (!closed || loopPoints.length < 3) {
    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  final smoothedPoints = _smoothBoundaryPoints(loopPoints);
  return _curvedLoopPath(smoothedPoints);
}

Path _curvedLoopPath(List<Offset> points) {
  final path = Path();
  if (points.length < 3) return path;

  final start = _midpoint(points.last, points.first);
  path.moveTo(start.dx, start.dy);
  for (var i = 0; i < points.length; i++) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    final end = _midpoint(current, next);
    path.quadraticBezierTo(current.dx, current.dy, end.dx, end.dy);
  }
  return path..close();
}

List<Offset> _smoothBoundaryPoints(List<Offset> points) {
  var smoothed = points;
  for (var pass = 0; pass < _boundarySmoothingPasses; pass++) {
    final nextPoints = <Offset>[];
    for (var i = 0; i < smoothed.length; i++) {
      final current = smoothed[i];
      final next = smoothed[(i + 1) % smoothed.length];
      final delta = next - current;
      nextPoints
        ..add(current + delta * _boundaryCornerCut)
        ..add(current + delta * (1 - _boundaryCornerCut));
    }
    smoothed = nextPoints;
  }
  return smoothed;
}

List<Offset> _organicBoundaryPoints(List<Offset> points) {
  if (points.length < 2) return points;

  final organic = <Offset>[];
  for (var i = 0; i < points.length; i++) {
    final start = points[i];
    final end = points[(i + 1) % points.length];
    organic.add(start);

    final delta = end - start;
    final length = delta.distance;
    if (length <= _organicMinSegmentLength) continue;

    final canonical = _canonicalBoundaryEdge(start, end);
    final canonicalDelta = canonical.end - canonical.start;
    final canonicalLength = canonicalDelta.distance;
    if (canonicalLength == 0) continue;
    final canonicalNormal = Offset(
      -canonicalDelta.dy / canonicalLength,
      canonicalDelta.dx / canonicalLength,
    );
    final steps = (length / _organicPointSpacing)
        .floor()
        .clamp(_organicMinSegmentSteps, _organicMaxSegmentSteps)
        .toInt();
    for (var step = 1; step <= steps; step++) {
      final t = step / (steps + 1);
      final base = Offset(start.dx + delta.dx * t, start.dy + delta.dy * t);
      final canonicalT = canonical.reversed ? 1 - t : t;
      final jitter = _fractalBoundaryJitter(
        start: canonical.start,
        end: canonical.end,
        t: canonicalT,
      );
      organic.add(base + canonicalNormal * jitter);
    }
  }
  return organic;
}

({Offset start, Offset end, bool reversed}) _canonicalBoundaryEdge(
  Offset start,
  Offset end,
) {
  if (_isBoundaryPointBefore(start, end)) {
    return (start: start, end: end, reversed: false);
  }
  return (start: end, end: start, reversed: true);
}

bool _isBoundaryPointBefore(Offset a, Offset b) {
  final ax = (a.dx * 1000).round();
  final bx = (b.dx * 1000).round();
  if (ax != bx) return ax < bx;
  return (a.dy * 1000).round() <= (b.dy * 1000).round();
}

double _fractalBoundaryJitter({
  required Offset start,
  required Offset end,
  required double t,
}) {
  var jitter = 0.0;
  var amplitude = _organicBoundaryJitter;
  for (var octave = 0; octave < _organicBoundaryOctaves; octave++) {
    final frequency = 1 << octave;
    final scaledT = t * frequency;
    final sample = scaledT.floor();
    final localT = scaledT - sample;
    final easedT = localT * localT * (3 - 2 * localT);
    final a = _boundaryNoise(
      start: start,
      end: end,
      octave: octave,
      sample: sample,
    );
    final b = _boundaryNoise(
      start: start,
      end: end,
      octave: octave,
      sample: sample + 1,
    );
    jitter += lerpDouble(a, b, easedT)! * amplitude;
    amplitude *= _organicBoundaryAmplitudeFalloff;
  }
  return jitter;
}

double _boundaryNoise({
  required Offset start,
  required Offset end,
  required int octave,
  required int sample,
}) {
  var hash = 17;
  hash = _hashBoundaryValue(hash, start.dx);
  hash = _hashBoundaryValue(hash, start.dy);
  hash = _hashBoundaryValue(hash, end.dx);
  hash = _hashBoundaryValue(hash, end.dy);
  hash = 37 * hash + octave * 65537;
  hash = 37 * hash + sample * 104729;
  final value = hash.abs() % 2001;
  return value / 1000.0 - 1.0;
}

int _hashBoundaryValue(int hash, double value) {
  return 37 * hash + (value * 1000).round();
}

Offset _midpoint(Offset a, Offset b) =>
    Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

const double _organicPointSpacing = 9.0;
const int _organicMinSegmentSteps = 3;
const int _organicMaxSegmentSteps = 7;
const int _organicBoundaryOctaves = 4;
const double _organicBoundaryJitter = 4.8;
const double _organicBoundaryAmplitudeFalloff = 0.52;
const double _organicMinSegmentLength = 18.0;
const int _boundarySmoothingPasses = 1;
const double _boundaryCornerCut = 0.16;
