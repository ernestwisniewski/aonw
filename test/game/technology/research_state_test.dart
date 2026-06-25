import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter_test/flutter_test.dart';

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

      expect(back, state);
      expect(back.hasUnlocked(TechnologyId.agriculture), isTrue);
      expect(back.progressFor(TechnologyId.trade), 4);
      expect(back.scienceOverflow, 3);
    });

    test('fromJson requires unlocked technologies', () {
      expect(
        () => PlayerResearchState.fromJson({
          'progressByTechnologyId': <String, dynamic>{},
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('fromJson requires progress map', () {
      expect(
        () => PlayerResearchState.fromJson({
          'unlockedTechnologyIds': <dynamic>[],
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('unlock removes active technology and its progress', () {
      final state = PlayerResearchState(
        activeTechnologyId: TechnologyId.trade,
        progressByTechnologyId: {TechnologyId.trade: 9},
      );

      final updated = state.unlock(TechnologyId.trade);

      expect(updated.hasUnlocked(TechnologyId.trade), isTrue);
      expect(updated.activeTechnologyId, isNull);
      expect(updated.progressFor(TechnologyId.trade), 0);
    });

    test('withProgress removes zero progress entries', () {
      final state = PlayerResearchState(
        progressByTechnologyId: {TechnologyId.trade: 4},
      );

      final updated = state.withProgress(TechnologyId.trade, 0);

      expect(updated.progressByTechnologyId, isEmpty);
    });

    test('withScienceOverflow clamps negative values', () {
      final updated = PlayerResearchState.empty.withScienceOverflow(-2);

      expect(updated.scienceOverflow, 0);
    });
  });

  group('ResearchState', () {
    test('returns empty player state for unknown player', () {
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

    test('fromJson requires players map', () {
      expect(() => ResearchState.fromJson({}), throwsA(isA<TypeError>()));
    });

    test('updates a single player research state immutably', () {
      final updated = ResearchState.empty.updatePlayer(
        'player_1',
        PlayerResearchState(activeTechnologyId: TechnologyId.agriculture),
      );

      expect(
        updated.forPlayer('player_1').activeTechnologyId,
        TechnologyId.agriculture,
      );
      expect(ResearchState.empty.players, isEmpty);
    });
  });
}
