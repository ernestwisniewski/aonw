import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/ai_domain_state_fingerprint.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiDomainStateFingerprint', () {
    test('preserves the legacy cache invalidation partition', () {
      final base = _snapshot();
      final variants = <({String label, SaveSnapshot snapshot})>[
        (label: 'gold', snapshot: _snapshot(gold: 11)),
        (label: 'unit', snapshot: _snapshot(unitCol: 1)),
        (
          label: 'session',
          snapshot: _snapshot(
            runtimeState: const GameRuntimeState(
              submittedPlayerIds: {'player-1'},
            ),
          ),
        ),
        (
          label: 'attack',
          snapshot: _snapshot(
            runtimeState: const GameRuntimeState(intendedAttacks: [_attack]),
          ),
        ),
        (
          label: 'victory progress',
          snapshot: _snapshot(
            runtimeState: const GameRuntimeState(
              dominationHoldTurnsByPlayerId: {'player-1': 2},
            ),
          ),
        ),
      ];

      for (final includeAttacks in const [false, true]) {
        final legacyBase = _legacyFingerprint(
          base,
          includeIntendedAttacks: includeAttacks,
        );
        final canonicalBase = AiDomainStateFingerprint.hash(
          base.canonical.domain,
          includeIntendedAttacks: includeAttacks,
        );

        for (final variant in variants) {
          final legacyEqual =
              _legacyFingerprint(
                variant.snapshot,
                includeIntendedAttacks: includeAttacks,
              ) ==
              legacyBase;
          final canonicalEqual =
              AiDomainStateFingerprint.hash(
                variant.snapshot.canonical.domain,
                includeIntendedAttacks: includeAttacks,
              ) ==
              canonicalBase;

          expect(
            canonicalEqual,
            legacyEqual,
            reason: '${variant.label}, includeIntendedAttacks=$includeAttacks',
          );
        }
      }
    });

    test('ignores domain fields owned by other cache triggers', () {
      final domain = _snapshot().canonical.domain;
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
      final domain = _snapshot(includeRawRoster: false).canonical.domain;
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

int _legacyFingerprint(
  SaveSnapshot snapshot, {
  required bool includeIntendedAttacks,
}) {
  final runtime = GameRuntimeState.snapshot(
    intendedAttacks: includeIntendedAttacks
        ? snapshot.runtimeState.intendedAttacks
        : const [],
  );
  return snapshot.persistentState.copyWith(runtimeState: runtime).hashCode;
}

SaveSnapshot _snapshot({
  int gold = 10,
  int unitCol = 0,
  GameRuntimeState runtimeState = GameRuntimeState.empty,
  bool includeRawRoster = true,
}) {
  return SaveSnapshot(
    save: _save(),
    playerColors: includeRawRoster ? const {'player-1': 0xFF2563EB} : const {},
    playerCountries: includeRawRoster
        ? const {'player-1': PlayerCountry.poland}
        : const {},
    playerGold: {'player-1': gold},
    units: [
      GameUnit.startingCommander(ownerPlayerId: 'player-1', col: unitCol),
    ],
    runtimeState: runtimeState,
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
