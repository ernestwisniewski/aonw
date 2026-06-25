/// Structured score value used by AI evaluators.
///
/// [total] is the value used for ranking. [components] exposes named inputs
/// for tests, telemetry, debug overlays, and future explainable-AI output.
class ScoreBreakdown {
  final double total;
  final Map<String, double> components;

  ScoreBreakdown({
    required this.total,
    Map<String, double> components = const {},
  }) : components = Map<String, double>.unmodifiable(components);

  factory ScoreBreakdown.fromComponents(Map<String, double> components) {
    final frozen = Map<String, double>.unmodifiable(components);
    return ScoreBreakdown(
      total: frozen.values.fold(0, (sum, value) => sum + value),
      components: frozen,
    );
  }

  ScoreBreakdown scale(double weight) {
    return ScoreBreakdown(
      total: total * weight,
      components: {
        for (final entry in components.entries) entry.key: entry.value * weight,
      },
    );
  }
}

abstract interface class Scorer<TCandidate, TContext> {
  ScoreBreakdown score(TCandidate candidate, TContext context);
}

typedef WeightedScorer<TCandidate, TContext> = ({
  Scorer<TCandidate, TContext> scorer,
  double weight,
  String label,
});

final class CompositeScorer<TCandidate, TContext>
    implements Scorer<TCandidate, TContext> {
  final List<WeightedScorer<TCandidate, TContext>> children;

  CompositeScorer({
    Iterable<WeightedScorer<TCandidate, TContext>> children = const [],
  }) : children = List.unmodifiable(children);

  @override
  ScoreBreakdown score(TCandidate candidate, TContext context) {
    final components = <String, double>{};
    var total = 0.0;

    for (final child in children) {
      final weighted = child.scorer
          .score(candidate, context)
          .scale(child.weight);
      total += weighted.total;
      components[child.label] = (components[child.label] ?? 0) + weighted.total;
      for (final entry in weighted.components.entries) {
        components['${child.label}.${entry.key}'] =
            (components['${child.label}.${entry.key}'] ?? 0) + entry.value;
      }
    }

    return ScoreBreakdown(total: total, components: components);
  }
}
