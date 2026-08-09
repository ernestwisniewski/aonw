import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('WorkerImprovementRecommendation.bestTypeForScores', () {
    test('returns null when there are no scored improvements', () {
      expect(
        WorkerImprovementRecommendation.bestTypeForScores(const {}),
        isNull,
      );
    });

    test('selects the highest score', () {
      expect(
        WorkerImprovementRecommendation.bestTypeForScores(const {
          FieldImprovementType.farm: 2,
          FieldImprovementType.mine: 7,
        }),
        FieldImprovementType.mine,
      );
    });

    test('breaks score ties by stable domain order', () {
      final later = FieldImprovementType.values.last;
      final earlier = FieldImprovementType.values.first;

      expect(
        WorkerImprovementRecommendation.bestTypeForScores({
          later: 5,
          earlier: 5,
        }),
        earlier,
      );
    });
  });
}
