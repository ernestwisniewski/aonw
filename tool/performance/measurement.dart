import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../release/canonical_json.dart';

/// The deterministic and diagnostic parts of one performance workload.
///
/// Values in [stable] must describe work or output only. Wall-clock samples
/// belong in [observations], so portable checks never depend on runner speed.
class PerformanceCaseResult {
  PerformanceCaseResult(
    this.name,
    Map<String, Object?> stable,
    Map<String, Object?> observations,
  ) : stable = Map.unmodifiable(stable),
      observations = Map.unmodifiable(observations);

  final String name;
  final Map<String, Object?> stable;
  final Map<String, Object?> observations;

  Map<String, Object?> toJson() => {
    'name': name,
    'stable': stable,
    'observations': observations,
  };
}

String stableDigest(Object? value) =>
    sha256.convert(utf8.encode(encodeCanonicalJson(value))).toString();

class Measured<T> {
  const Measured(this.value, this.elapsed);

  final T value;
  final Duration elapsed;
}

Measured<T> measureSync<T>(T Function() action) {
  final stopwatch = Stopwatch()..start();
  final value = action();
  stopwatch.stop();
  return Measured(value, stopwatch.elapsed);
}

Future<Measured<T>> measureAsync<T>(Future<T> Function() action) async {
  final stopwatch = Stopwatch()..start();
  final value = await action();
  stopwatch.stop();
  return Measured(value, stopwatch.elapsed);
}

double median(Iterable<num> samples) {
  final sorted = _sortedSamples(samples);
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[middle];
  return (sorted[middle - 1] + sorted[middle]) / 2;
}

double p95(Iterable<num> samples) {
  final sorted = _sortedSamples(samples);
  final index = ((sorted.length - 1) * 0.95).ceil();
  return sorted[index];
}

Map<String, Object?> timingObservation(Iterable<Duration> samples) {
  final micros = samples.map((sample) => sample.inMicroseconds).toList();
  if (micros.isEmpty) {
    throw ArgumentError.value(samples, 'samples', 'Must not be empty.');
  }
  return {
    'samples': micros.length,
    'medianMicros': median(micros),
    'p95Micros': p95(micros),
    'minMicros': micros.reduce((left, right) => left < right ? left : right),
    'maxMicros': micros.reduce((left, right) => left > right ? left : right),
  };
}

List<double> _sortedSamples(Iterable<num> samples) {
  final sorted = samples.map((sample) => sample.toDouble()).toList()..sort();
  if (sorted.isEmpty) {
    throw ArgumentError.value(samples, 'samples', 'Must not be empty.');
  }
  return sorted;
}
