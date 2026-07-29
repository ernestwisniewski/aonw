import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SaveSnapshot', () {
    test('captures persistent GameState slices', () {
      final state =
          const GameState(
            playerColors: {'p1': 0xFF4a7fc4},
            playerCountries: {'p1': PlayerCountry.canada},
            playerGold: {'p1': 7},
            activePlayerId: 'p1',
            submittedPlayerIds: {'p1'},
            dominationHoldTurnsByPlayerId: {'p1': 2},
            intendedAttacks: [
              IntendedAttack(
                attackerUnitId: 'warrior_1',
                defenderCol: 4,
                defenderRow: 5,
                declaredAtTick: 7,
                declaringPlayerId: 'p1',
              ),
            ],
          ).copyWithInteraction(
            pendingAction: const PendingCityWorkedHexSelection(
              ownerPlayerId: 'p1',
              cityId: 'city_1',
            ),
          );

      final snapshot = SaveSnapshot.fromGameState(
        save: _save(),
        state: state,
        eventLogOffset: 12,
      );

      expect(snapshot.playerColors, state.playerColors);
      expect(snapshot.playerCountries, state.playerCountries);
      expect(snapshot.playerGold, state.playerGold);
      expect(snapshot.runtimeState.pendingAction, state.pendingAction);
      expect(snapshot.runtimeState.submittedPlayerIds, {'p1'});
      expect(snapshot.runtimeState.intendedAttacks, state.intendedAttacks);
      expect(snapshot.runtimeState.dominationHoldTurnsByPlayerId, {'p1': 2});
      expect(snapshot.eventLogOffset, 12);
      expect(snapshot.persistentState.playerGold, {'p1': 7});
      expect(snapshot.persistentState.playerCountries, {
        'p1': PlayerCountry.canada,
      });
    });

    test(
      'owns raw save and persistent collections before canonical access',
      () {
        final playerStates = <String, PlayerTurnState>{
          'p1': PlayerTurnState.active,
        };
        final players = <Player>[
          const Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4),
        ];
        final playerGold = <String, int>{'p1': 1};
        final units = <GameUnit>[
          GameUnit.startingCommander(ownerPlayerId: 'p1'),
        ];
        final sourceSave = _save().copyWith(
          playerStates: playerStates,
          players: players,
        );
        final snapshot = SaveSnapshot(
          save: sourceSave,
          playerGold: playerGold,
          units: units,
        );

        playerGold['p1'] = 2;
        playerStates['p2'] = PlayerTurnState.finished;
        players.add(
          const Player(id: 'p2', name: 'Bob', colorValue: 0xFFB83A3A),
        );
        units.clear();

        expect(snapshot.playerGold, {'p1': 1});
        expect(snapshot.save.playerStates, {'p1': PlayerTurnState.active});
        expect(snapshot.save.players.map((player) => player.id), ['p1']);
        expect(snapshot.units, hasLength(1));
        expect(snapshot.canonical.domain.playerGold, {'p1': 1});
        expect(snapshot.canonical.domain.participants, hasLength(1));

        playerGold['p1'] = 3;
        players.clear();
        expect(snapshot.playerGold, {'p1': 1});
        expect(snapshot.save.players, hasLength(1));
        expect(snapshot.canonical.domain.playerGold, {'p1': 1});
      },
    );

    test('exposes immutable collections and memoizes canonical view', () {
      final snapshot = SaveSnapshot(
        save: _save(),
        playerGold: const {'p1': 1},
        units: [GameUnit.startingCommander(ownerPlayerId: 'p1')],
      );
      final canonical = snapshot.canonical;

      expect(snapshot.canonical, same(canonical));
      expect(snapshot.metadata, same(canonical.metadata));
      expect(snapshot.domain, same(canonical.domain));
      expect(snapshot.session, same(canonical.session));
      expect(snapshot.interaction, same(canonical.interaction));
      expect(
        () => snapshot.playerGold['p1'] = 2,
        throwsA(isA<UnsupportedError>()),
      );
      expect(() => snapshot.units.clear(), throwsA(isA<UnsupportedError>()));
      expect(
        () => snapshot.save.playerStates['p2'] = PlayerTurnState.active,
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => snapshot.save.players.clear(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('copyWith owns replacements and derives an independent view', () {
      final snapshot = SaveSnapshot(
        save: _save(),
        playerGold: const {'p1': 1},
        eventLogOffset: 4,
      );
      final replacement = <String, int>{'p1': 2};

      final copied = snapshot.copyWith(
        playerGold: replacement,
        eventLogOffset: 7,
      );
      replacement['p1'] = 3;

      expect(copied.playerGold, {'p1': 2});
      expect(copied.eventLogOffset, 7);
      expect(copied.canonical.domain.playerGold, {'p1': 2});
      expect(copied.canonical.eventLogOffset, 7);
      expect(copied.canonical, isNot(same(snapshot.canonical)));
    });

    test('builds snapshot from persistent state', () {
      final runtimeState = GameRuntimeState(
        submittedPlayerIds: const {'p1'},
        turnStartedAt: DateTime.utc(2026, 4, 27, 12),
      );

      final snapshot = SaveSnapshot.fromPersistentState(
        save: _save(),
        state: PersistentGameState(
          playerCountries: const {'p1': PlayerCountry.china},
          playerGold: const {'p1': 7},
          runtimeState: runtimeState,
        ),
        eventLogOffset: 9,
      );

      expect(snapshot.playerGold, {'p1': 7});
      expect(snapshot.playerCountries, {'p1': PlayerCountry.china});
      expect(snapshot.runtimeState, runtimeState);
      expect(snapshot.eventLogOffset, 9);
    });

    test(
      'restores GameState from persistent slices and caller runtime control',
      () {
        final snapshot = SaveSnapshot(
          save: _save(),
          playerColors: const {'p1': 0xFF4a7fc4},
          playerCountries: const {'p1': PlayerCountry.unitedStates},
          playerGold: const {'p1': 7},
          runtimeState: GameRuntimeState(
            pendingAction: const PendingCityWorkedHexSelection(
              ownerPlayerId: 'p1',
              cityId: 'city_1',
            ),
            submittedPlayerIds: const {'p1'},
            timeoutStreaksByPlayerId: const {'p1': 2},
            afkPlayerIds: const {'p2'},
            kickedPlayerIds: const {'p3'},
            dominationHoldTurnsByPlayerId: const {'p1': 2},
            intendedAttacks: const [
              IntendedAttack(
                attackerUnitId: 'warrior_1',
                defenderCol: 4,
                defenderRow: 5,
                declaredAtTick: 7,
                declaringPlayerId: 'p1',
              ),
            ],
            turnStartedAt: DateTime.utc(2026, 4, 27, 12),
          ),
        );

        final state = snapshot.toGameState(
          activePlayerId: 'p1',
          activePlayerCanAct: false,
        );

        expect(state.playerColors, snapshot.playerColors);
        expect(state.playerCountries, snapshot.playerCountries);
        expect(state.countryForPlayer('p1'), PlayerCountry.unitedStates);
        expect(state.playerGold, snapshot.playerGold);
        expect(state.activePlayerId, 'p1');
        expect(state.activePlayerCanAct, isFalse);
        expect(state.pendingAction, snapshot.runtimeState.pendingAction);
        expect(state.submittedPlayerIds, {'p1'});
        expect(state.timeoutStreaksByPlayerId, {'p1': 2});
        expect(state.afkPlayerIds, {'p2'});
        expect(state.kickedPlayerIds, {'p3'});
        expect(state.intendedAttacks, snapshot.runtimeState.intendedAttacks);
        expect(state.dominationHoldTurnsByPlayerId, {'p1': 2});
        expect(state.turnStartedAt, DateTime.utc(2026, 4, 27, 12));
      },
    );

    test('copyWith preserves event log offset unless replaced', () {
      final snapshot = SaveSnapshot(save: _save(), eventLogOffset: 4);

      expect(snapshot.copyWith().eventLogOffset, 4);
      expect(snapshot.copyWith(eventLogOffset: 5).eventLogOffset, 5);
    });

    test('rebuilds game state without exposing legacy envelope ownership', () {
      final snapshot = SaveSnapshot(save: _save(), eventLogOffset: 4);
      final rebuilt = snapshot.withGameState(
        const GameState(playerGold: {'p1': 9}),
        eventLogOffset: 8,
      );

      expect(rebuilt.save.toJson(), snapshot.save.toJson());
      expect(rebuilt.eventLogOffset, 8);
      expect(rebuilt.domain.playerGold, {'p1': 9});
    });

    test('updates camera without materializing sparse roster defaults', () {
      final savedAt = DateTime.utc(2026, 7, 28, 12, 30);
      final snapshot = SaveSnapshot(
        save: _save().copyWith(players: const [], savedAt: savedAt),
        playerCountries: const {'p1': PlayerCountry.canada},
        eventLogOffset: 4,
      );
      const camera = CameraState(x: 12.5, y: -8.25, zoom: 1.5);

      final updated = snapshot.withCamera(camera);

      expect(
        updated.metadata.camera,
        const GameSnapshotCamera(x: 12.5, y: -8.25, zoom: 1.5),
      );
      expect(updated.metadata.savedAtUtc, savedAt);
      expect(updated.save.players, isEmpty);
      expect(updated.rawPersistentState, snapshot.rawPersistentState);
      expect(updated.eventLogOffset, 4);
    });

    test('updates camera with the supplied savedAt normalized to UTC', () {
      final snapshot = SaveSnapshot(save: _save(), eventLogOffset: 4);
      final savedAt = DateTime.parse('2026-07-28T14:30:00+02:00');

      final updated = snapshot.withCamera(CameraState.zero, savedAt: savedAt);

      expect(updated.save.savedAt, savedAt);
      expect(updated.save.savedAt.isUtc, isTrue);
      expect(updated.metadata.savedAtUtc, DateTime.utc(2026, 7, 28, 12, 30));
      expect(updated.rawPersistentState, snapshot.rawPersistentState);
      expect(updated.eventLogOffset, 4);
    });

    test('unsubmits one player without adding a fallback turn start', () {
      final savedAt = DateTime.utc(2026, 7, 28, 12, 30);
      final snapshot = SaveSnapshot(
        save: _save().copyWith(
          gameMode: GameMode.multiplayer,
          savedAt: savedAt,
          players: const [],
        ),
        playerCountries: const {'p1': PlayerCountry.canada},
        runtimeState: const GameRuntimeState(submittedPlayerIds: {'p1', 'p2'}),
        eventLogOffset: 4,
      );

      final updated = snapshot.withPlayerUnsubmitted('p1');

      expect(updated.session.submittedPlayerIds, {'p2'});
      expect(updated.persistedTurnStartedAt, isNull);
      expect(updated.rawPersistentState.runtimeState.submittedPlayerIds, {
        'p2',
      });
      expect(updated.save.players, isEmpty);
      expect(updated.eventLogOffset, 4);
      expect(snapshot.withPlayerUnsubmitted('missing'), same(snapshot));
    });

    test('updates savedAt losslessly without changing state or offset', () {
      final snapshot = SaveSnapshot.fromGameState(
        save: _save(),
        state: const GameState(playerGold: {'p1': 9}),
        eventLogOffset: 4,
      );
      final savedAt = DateTime.parse('2026-07-28T14:30:00+02:00');
      final updated = snapshot.withSavedAt(savedAt);

      expect(updated.metadata.savedAtUtc, DateTime.utc(2026, 7, 28, 12, 30));
      expect(updated.save.savedAt, DateTime.utc(2026, 7, 28, 12, 30));
      expect(updated.eventLogOffset, 4);
      expect(updated.domain, snapshot.domain);
      expect(updated.rawPersistentState, snapshot.rawPersistentState);
    });

    test('marks one player finished without changing state or offset', () {
      final snapshot = SaveSnapshot.fromGameState(
        save: _save().copyWith(
          playerStates: const {
            'p1': PlayerTurnState.active,
            'p2': PlayerTurnState.active,
          },
        ),
        state: const GameState(playerGold: {'p1': 9}),
        eventLogOffset: 4,
      );
      final updated = snapshot.withPlayerFinished('p1');

      expect(updated.session.turnStatesByPlayerId, const {
        'p1': PlayerTurnState.finished,
        'p2': PlayerTurnState.active,
      });
      expect(updated.domain.turn, snapshot.domain.turn);
      expect(updated.metadata, snapshot.metadata);
      expect(updated.eventLogOffset, 4);
      expect(updated.rawPersistentState, snapshot.rawPersistentState);
    });

    test('prepares and finalizes a replay turn losslessly', () {
      final snapshot = SaveSnapshot.fromGameState(
        save: _save().copyWith(
          turn: 8,
          playerStates: const {
            'p1': PlayerTurnState.finished,
            'p2': PlayerTurnState.finished,
          },
          players: const [
            Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4),
            Player(id: 'p2', name: 'Bob', colorValue: 0xFFB83A3A),
          ],
        ),
        state: const GameState(playerGold: {'p1': 9}),
        eventLogOffset: 4,
      );
      final savedAt = DateTime.utc(2026, 7, 28, 12, 30, 1);

      final prepared = snapshot.withReplayPlayerTurnsReset();
      final finalized = prepared.withReplayTurnFinalized(
        state: PersistentGameState.snapshot(
          playerGold: const {'p1': 10},
          runtimeState: GameRuntimeState(turnStartedAt: savedAt),
        ),
        savedAt: savedAt,
      );

      expect(prepared.session.turnStatesByPlayerId, const {
        'p1': PlayerTurnState.active,
        'p2': PlayerTurnState.active,
      });
      expect(finalized.domain.turn, 9);
      expect(finalized.session.turnStatesByPlayerId, const {
        'p1': PlayerTurnState.active,
        'p2': PlayerTurnState.active,
      });
      expect(finalized.metadata.savedAtUtc, savedAt);
      expect(finalized.persistedTurnStartedAt, savedAt);
      expect(finalized.eventLogOffset, 4);
      expect(finalized.playerGold, {'p1': 10});
    });

    test('keeps persisted turn start distinct from canonical fallback', () {
      final savedAt = DateTime.utc(2026, 1, 1);
      final snapshot = SaveSnapshot(
        save: _save().copyWith(
          gameMode: GameMode.multiplayer,
          savedAt: savedAt,
        ),
      );

      expect(snapshot.persistedTurnStartedAt, isNull);
      expect(snapshot.session.turnStartedAt, savedAt);
    });
  });
}

GameSave _save() {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {'p1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: const [Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4)],
  );
}
