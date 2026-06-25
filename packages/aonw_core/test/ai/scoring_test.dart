import 'package:aonw_core/ai.dart';
import 'package:test/test.dart';

void main() {
  group('ScoreBreakdown', () {
    test('freezes components and sums totals from components', () {
      final source = {'a': 2.0, 'b': -0.5};
      final breakdown = ScoreBreakdown.fromComponents(source);

      source['a'] = 10;

      expect(breakdown.total, 1.5);
      expect(breakdown.components, {'a': 2.0, 'b': -0.5});
      expect(() => breakdown.components['c'] = 1, throwsUnsupportedError);
    });
  });

  group('CompositeScorer', () {
    test('weights child totals and namespaces component breakdowns', () {
      final scorer = CompositeScorer<String, Object?>(
        children: [
          (label: 'base', weight: 2, scorer: _FixedScorer(3, {'x': 1})),
          (label: 'bonus', weight: 0.5, scorer: _FixedScorer(4, {'y': 2})),
        ],
      );

      final score = scorer.score('candidate', null);

      expect(score.total, 8);
      expect(score.components, {
        'base': 6.0,
        'base.x': 2.0,
        'bonus': 2.0,
        'bonus.y': 1.0,
      });
    });
  });
}

final class _FixedScorer implements Scorer<String, Object?> {
  final double total;
  final Map<String, double> components;

  _FixedScorer(this.total, this.components);

  @override
  ScoreBreakdown score(String candidate, Object? context) {
    return ScoreBreakdown(total: total, components: components);
  }
}
