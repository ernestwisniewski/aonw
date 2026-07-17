import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:test/test.dart';

void main() {
  group('DomainState', () {
    test('owns input collections and recursively snapshots cities', () {
      final participants = <Player>[_player('p1', color: 0xFF112233)];
      final gold = <String, int>{'p1': 10};
      final units = <GameUnit>[GameUnit.startingWarrior(ownerPlayerId: 'p1')];
      final controlledHexes = <CityHex>[const CityHex(col: 2, row: 3)];
      final cities = <GameCity>[
        GameCity(
          id: 'city-1',
          ownerPlayerId: 'p1',
          name: 'Capital',
          center: const CityHex(col: 1, row: 1),
          controlledHexes: controlledHexes,
        ),
      ];

      final state = DomainState.snapshot(
        turn: 2,
        matchRules: MatchRules.standard,
        participants: participants,
        playerGold: gold,
        units: units,
        cities: cities,
      );
      participants.clear();
      gold['p1'] = 99;
      units.clear();
      cities.clear();
      controlledHexes.add(const CityHex(col: 4, row: 5));

      expect(state.participants, hasLength(1));
      expect(state.playerGold, {'p1': 10});
      expect(state.units, hasLength(1));
      expect(state.cities.single.controlledHexes, hasLength(1));
      expect(() => state.playerGold['p1'] = 20, throwsUnsupportedError);
      expect(
        () => state.cities.add(state.cities.single),
        throwsUnsupportedError,
      );
    });

    test('derives immutable player identity maps from participants', () {
      final state = DomainState.snapshot(
        turn: 1,
        matchRules: MatchRules.standard,
        participants: [
          _player('p1', color: 0xFF112233, country: PlayerCountry.poland),
          _player('p2', color: 0xFF445566, country: PlayerCountry.france),
        ],
      );

      expect(state.playerColors, {'p1': 0xFF112233, 'p2': 0xFF445566});
      expect(state.playerCountries, {
        'p1': PlayerCountry.poland,
        'p2': PlayerCountry.france,
      });
      expect(() => state.playerColors['p1'] = 0, throwsUnsupportedError);
      expect(
        () => state.playerCountries['p1'] = PlayerCountry.germany,
        throwsUnsupportedError,
      );
    });

    test('rejects empty and duplicate participant ids', () {
      expect(
        () => DomainState.snapshot(
          turn: 1,
          matchRules: MatchRules.standard,
          participants: [_player('')],
        ),
        throwsArgumentError,
      );
      expect(
        () => DomainState.snapshot(
          turn: 1,
          matchRules: MatchRules.standard,
          participants: [_player('p1'), _player('p1')],
        ),
        throwsArgumentError,
      );
    });

    test('copyWith shares unchanged branches and owns replacements', () {
      final state = DomainState.snapshot(
        turn: 1,
        matchRules: MatchRules.standard,
        participants: [_player('p1')],
        playerGold: const {'p1': 10},
        units: [GameUnit.startingWarrior(ownerPlayerId: 'p1')],
      );
      final replacementGold = <String, int>{'p1': 20};

      final next = state.copyWith(turn: 2, playerGold: replacementGold);
      replacementGold['p1'] = 30;

      expect(next.turn, 2);
      expect(next.playerGold, {'p1': 20});
      expect(identical(next.playerGold, state.playerGold), isFalse);
      expect(identical(next.participants, state.participants), isTrue);
      expect(identical(next.playerColors, state.playerColors), isTrue);
      expect(identical(next.units, state.units), isTrue);
    });

    test('uses structural equality and matching hashes', () {
      final leftPath = QueuedMovePath(
        targetCol: 1,
        targetRow: 2,
        steps: const [
          UnitMovementStep(col: 1, row: 2, enterCost: 1, cumulativeCost: 1),
        ],
      );
      final rightPath = QueuedMovePath(
        targetCol: 1,
        targetRow: 2,
        steps: const [
          UnitMovementStep(col: 1, row: 2, enterCost: 1, cumulativeCost: 1),
        ],
      );
      final leftUnit = GameUnit.startingWarrior(
        ownerPlayerId: 'p1',
      ).copyWithQueuedPath(leftPath);
      final rightUnit = GameUnit.startingWarrior(
        ownerPlayerId: 'p1',
      ).copyWithQueuedPath(rightPath);
      final left = DomainState.snapshot(
        turn: 3,
        matchRules: MatchRules.standard,
        participants: [_player('p1')],
        playerGold: const {'p1': 10},
        units: [leftUnit],
      );
      final right = DomainState.snapshot(
        turn: 3,
        matchRules: MatchRules.standard,
        participants: [_player('p1')],
        playerGold: {'p1': 10},
        units: [rightUnit],
      );

      expect(identical(leftUnit, rightUnit), isFalse);
      expect(identical(leftPath, rightPath), isFalse);
      expect(left, right);
      expect(left.hashCode, right.hashCode);
      expect(right.copyWith(turn: 4), isNot(left));
    });
  });
}

Player _player(
  String id, {
  int color = 0xFF112233,
  PlayerCountry country = PlayerCountry.poland,
}) {
  return Player(
    id: id,
    name: id.isEmpty ? 'empty' : id,
    colorValue: color,
    country: country,
  );
}
