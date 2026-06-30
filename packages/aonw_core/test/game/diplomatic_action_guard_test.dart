import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('GoldAmount', () {
    test('accepts non-negative amounts', () {
      expect(GoldAmount(0).value, 0);
      expect(GoldAmount(7).value, 7);
      expect(GoldAmount(7), GoldAmount(7));
    });

    test('rejects negative amounts', () {
      expect(() => GoldAmount(-1), throwsArgumentError);
    });

    test('checks whether available gold can fund it', () {
      expect(GoldAmount(5).canFundFrom(5), isTrue);
      expect(GoldAmount(5).canFundFrom(4), isFalse);
    });
  });

  group('DiplomaticActionGuard', () {
    test('allows issue for the active player without an explicit actor', () {
      expect(
        DiplomaticActionGuard.canIssue(
          playerId: 'player_1',
          canAct: true,
          activePlayerId: 'player_1',
        ),
        isTrue,
      );
    });

    test('rejects issue when action context or actor identity is invalid', () {
      expect(
        DiplomaticActionGuard.canIssue(
          playerId: 'player_1',
          canAct: false,
          activePlayerId: 'player_1',
        ),
        isFalse,
      );
      expect(
        DiplomaticActionGuard.canIssue(
          playerId: 'player_2',
          canAct: true,
          actorPlayerId: 'player_1',
          activePlayerId: 'player_2',
        ),
        isFalse,
      );
    });

    test('allows target with an existing diplomacy contact', () {
      expect(
        DiplomaticActionGuard.canTargetDiscovered(
          playerId: 'player_1',
          targetPlayerId: 'player_2',
          knownPlayerIds: const ['player_1', 'player_2'],
          diplomacy: DiplomacyState.empty.addContact('player_1', 'player_2'),
          fogOfWar: FogOfWarState.empty,
          units: const [],
          cities: const [],
        ),
        isTrue,
      );
    });

    test('allows target discovered through remembered city visibility', () {
      expect(
        DiplomaticActionGuard.canTargetDiscovered(
          playerId: 'player_1',
          targetPlayerId: 'player_2',
          knownPlayerIds: const ['player_1', 'player_2'],
          diplomacy: DiplomacyState.empty,
          fogOfWar: FogOfWarState(
            players: {
              'player_1': PlayerFogOfWar(
                playerId: 'player_1',
                discoveredHexes: {const HexCoordinate(col: 2, row: 1)},
              ),
            },
          ),
          units: const [],
          cities: const [
            GameCity(
              id: 'city_2',
              ownerPlayerId: 'player_2',
              name: 'Known City',
              center: CityHex(col: 2, row: 1),
            ),
          ],
        ),
        isTrue,
      );
    });

    test('rejects unknown empty or self targets', () {
      bool canTarget(String targetPlayerId) {
        return DiplomaticActionGuard.canTargetDiscovered(
          playerId: 'player_1',
          targetPlayerId: targetPlayerId,
          knownPlayerIds: const ['player_1', 'player_2'],
          diplomacy: DiplomacyState.empty,
          fogOfWar: FogOfWarState.empty,
          units: const [],
          cities: const [],
        );
      }

      expect(canTarget(''), isFalse);
      expect(canTarget('player_1'), isFalse);
      expect(canTarget('player_3'), isFalse);
      expect(canTarget('player_2'), isFalse);
    });
  });
}
