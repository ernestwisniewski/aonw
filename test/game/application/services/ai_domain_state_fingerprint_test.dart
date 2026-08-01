import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/ai_domain_state_fingerprint.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiDomainStateFingerprint', () {
    test('tracks only inputs owned by the AI world-state cache', () {
      final base = _snapshot();
      final baseHash = AiDomainStateFingerprint.hash(base.domain);

      expect(
        AiDomainStateFingerprint.hash(_snapshot(gold: 11).domain),
        isNot(baseHash),
      );
      expect(
        AiDomainStateFingerprint.hash(_snapshot(unitCol: 1).domain),
        isNot(baseHash),
      );
      expect(
        AiDomainStateFingerprint.hash(
          _snapshot(submittedPlayerIds: {'player-1'}).domain,
        ),
        baseHash,
      );
      expect(
        AiDomainStateFingerprint.hash(
          _snapshot(dominationHoldTurnsByPlayerId: {'player-1': 2}).domain,
        ),
        baseHash,
      );
      final attackState = _snapshot(intendedAttacks: [_attack]).domain;
      expect(AiDomainStateFingerprint.hash(attackState), baseHash);
      expect(
        AiDomainStateFingerprint.hash(
          attackState,
          includeIntendedAttacks: true,
        ),
        isNot(
          AiDomainStateFingerprint.hash(
            base.domain,
            includeIntendedAttacks: true,
          ),
        ),
      );
    });

    test('ignores domain fields owned by other cache triggers', () {
      final domain = _snapshot().domain;
      final changed = domain.copyWith(
        turn: domain.turn + 1,
        dominationHoldTurnsByPlayerId: const {'player-1': 3},
        culturalVictoryHoldTurnsByPlayerId: const {'player-1': 4},
      );

      expect(
        AiDomainStateFingerprint.hash(changed),
        AiDomainStateFingerprint.hash(domain),
      );
      expect(
        AiDomainStateFingerprint.hash(changed, includeIntendedAttacks: true),
        AiDomainStateFingerprint.hash(domain, includeIntendedAttacks: true),
      );
    });

    test('uses canonical participant colors but not presentation names', () {
      final domain = _snapshot(includeRawRoster: false).domain;
      final renamed = domain.copyWith(
        participants: [
          domain.participants.single.copyWith(name: 'Renamed player'),
        ],
      );
      final recolored = domain.copyWith(
        participants: [
          domain.participants.single.copyWith(colorValue: 0xFFDC2626),
        ],
      );

      expect(
        AiDomainStateFingerprint.hash(renamed),
        AiDomainStateFingerprint.hash(domain),
      );
      expect(
        AiDomainStateFingerprint.hash(recolored),
        isNot(AiDomainStateFingerprint.hash(domain)),
      );
    });
  });
}

CanonicalGameSnapshot _snapshot({
  int gold = 10,
  int unitCol = 0,
  Set<String> submittedPlayerIds = const {},
  List<IntendedAttack> intendedAttacks = const [],
  Map<String, int> dominationHoldTurnsByPlayerId = const {},
  bool includeRawRoster = true,
}) {
  return GameSnapshotFactory.create(
    save: _save(),
    playerColors: includeRawRoster ? const {'player-1': 0xFF2563EB} : const {},
    playerCountries: includeRawRoster
        ? const {'player-1': PlayerCountry.poland}
        : const {},
    playerGold: {'player-1': gold},
    units: [
      GameUnit.startingCommander(ownerPlayerId: 'player-1', col: unitCol),
    ],
    submittedPlayerIds: submittedPlayerIds,
    intendedAttacks: intendedAttacks,
    dominationHoldTurnsByPlayerId: dominationHoldTurnsByPlayerId,
  );
}

GameSave _save() {
  return GameSave(
    id: 'fingerprint-save',
    name: 'Fingerprint test',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 7,
    playerStates: const {'player-1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 7, 28, 12),
    camera: CameraState.zero,
    players: const [
      Player(
        id: 'player-1',
        name: 'Player',
        colorValue: 0xFF2563EB,
        country: PlayerCountry.poland,
      ),
    ],
    gameMode: GameMode.hotSeat,
  );
}

const _attack = IntendedAttack(
  attackerUnitId: 'commander_player-1',
  defenderCol: 1,
  defenderRow: 0,
  declaredAtTick: 3,
  declaringPlayerId: 'player-1',
);
