import 'package:aonw_core/game/domain/technology.dart';
import 'package:test/test.dart';

void main() {
  group('PlayerResearchState', () {
    test('round-trips through JSON', () {
      final state = PlayerResearchState(
        unlockedTechnologyIds: {TechnologyId.agriculture, TechnologyId.mining},
        activeTechnologyId: TechnologyId.trade,
        progressByTechnologyId: {TechnologyId.trade: 4},
        scienceOverflow: 3,
      );

      final back = PlayerResearchState.fromJson(state.toJson());

      expect(back.hasUnlocked(TechnologyId.agriculture), isTrue);
      expect(back.progressFor(TechnologyId.trade), 4);
      expect(back.scienceOverflow, 3);
      expect(back, state);
    });

    test('unlock clears active progress', () {
      final state = PlayerResearchState(
        activeTechnologyId: TechnologyId.trade,
        progressByTechnologyId: {TechnologyId.trade: 9},
      );

      final updated = state.unlock(TechnologyId.trade);

      expect(updated.hasUnlocked(TechnologyId.trade), isTrue);
      expect(updated.activeTechnologyId, isNull);
      expect(updated.progressFor(TechnologyId.trade), 0);
    });
  });

  group('ResearchState', () {
    test('returns empty player state by default', () {
      expect(
        ResearchState.empty.forPlayer('player_1'),
        PlayerResearchState.empty,
      );
    });

    test('round-trips through JSON', () {
      final state = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.agriculture},
            activeTechnologyId: TechnologyId.mining,
            progressByTechnologyId: {TechnologyId.mining: 3},
          ),
        },
      );

      final back = ResearchState.fromJson(state.toJson());

      expect(back, state);
      expect(
        back.forPlayer('player_1').activeTechnologyId,
        TechnologyId.mining,
      );
    });
  });
}
