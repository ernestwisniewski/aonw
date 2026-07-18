import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('ResearchSelectionPendingActionPolicy', () {
    test('clears matching research selection', () {
      const pendingAction = PendingResearchSelection(ownerPlayerId: 'p1');

      final result =
          ResearchSelectionPendingActionPolicy.afterAcceptedSelection(
            pendingAction: pendingAction,
            playerId: 'p1',
          );

      expect(result, isNull);
    });

    test('preserves nonmatching actions by identity', () {
      const otherOwner = PendingResearchSelection(ownerPlayerId: 'p2');
      const otherKind = PendingCityWorkedHexSelection(
        ownerPlayerId: 'p1',
        cityId: 'city_1',
      );

      final ownerResult =
          ResearchSelectionPendingActionPolicy.afterAcceptedSelection(
            pendingAction: otherOwner,
            playerId: 'p1',
          );
      final kindResult =
          ResearchSelectionPendingActionPolicy.afterAcceptedSelection(
            pendingAction: otherKind,
            playerId: 'p1',
          );

      expect(identical(ownerResult, otherOwner), isTrue);
      expect(identical(kindResult, otherKind), isTrue);
    });

    test('preserves absent action', () {
      final result =
          ResearchSelectionPendingActionPolicy.afterAcceptedSelection(
            pendingAction: null,
            playerId: 'p1',
          );

      expect(result, isNull);
    });
  });
}
