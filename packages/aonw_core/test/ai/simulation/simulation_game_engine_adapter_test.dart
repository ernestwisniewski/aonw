import 'package:aonw_core/ai/simulation/simulation_game_engine_adapter.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'simulation adapter applies migrated unit actions through GameEngine',
    () {
      final state = PersistentGameState.snapshot(
        playerColors: const {'player_1': 1},
        playerCountries: const {'player_1': PlayerCountry.poland},
        playerGold: const {'player_1': 17},
        units: [
          GameUnit(
            id: 'unit_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            name: GameUnitType.warrior.defaultNameToken,
            col: 0,
            row: 0,
            movementPoints: 3,
          ),
        ],
        runtimeState: GameRuntimeState.snapshot(
          pendingAction: const PendingResearchSelection(
            ownerPlayerId: 'player_1',
          ),
        ),
      );

      final result = const SimulationGameEngineAdapter().apply(
        snapshot: _snapshotFor(state),
        state: state,
        command: const SkipUnitTurnCommand('unit_1'),
        actorPlayerId: 'player_1',
        commandTick: 3,
        mapView: const _EmptyMapReadView(),
        ruleset: GameRuleset.defaults,
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(result.state.units.single.movementPoints, 0);
      expect(
        result.state.runtimeState.pendingAction,
        const PendingUnitTurnSkip(
          ownerPlayerId: 'player_1',
          unitId: 'unit_1',
          restoreMovementPoints: 3,
        ),
      );
      expect(result.state.playerGold, same(state.playerGold));
    },
  );

  test('simulation adapter preserves rejected state identity', () {
    final state = PersistentGameState.snapshot(
      playerColors: const {'player_1': 1},
      playerCountries: const {'player_1': PlayerCountry.poland},
    );

    final result = const SimulationGameEngineAdapter().apply(
      snapshot: _snapshotFor(state),
      state: state,
      command: const FortifyUnitCommand('missing'),
      actorPlayerId: 'player_1',
      commandTick: 3,
      mapView: const _EmptyMapReadView(),
      ruleset: GameRuleset.defaults,
    );

    expect(result.accepted, isFalse);
    expect(result.reason, 'unit_not_found');
    expect(result.state, same(state));
  });

  test('simulation adapter uses the supplied lossless canonical envelope', () {
    final state = PersistentGameState.snapshot(
      units: [
        GameUnit(
          id: 'unit_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: GameUnitType.warrior.defaultNameToken,
          col: 0,
          row: 0,
          movementPoints: 3,
        ),
      ],
      runtimeState: GameRuntimeState.snapshot(
        submittedPlayerIds: const {'session_only'},
        timeoutStreaksByPlayerId: const {'timeout_only': 2},
        afkPlayerIds: const {'afk_only'},
        kickedPlayerIds: const {'kicked_only'},
      ),
    );
    final snapshot = CanonicalGameSnapshot.snapshot(
      domain: DomainState.snapshot(
        turn: 7,
        matchRules: MatchRules.standard,
        participants: const [
          Player(id: 'player_1', name: 'Actor', colorValue: 1),
          Player(id: 'session_only', name: 'Submitted', colorValue: 2),
          Player(id: 'timeout_only', name: 'Timeout', colorValue: 3),
          Player(id: 'afk_only', name: 'AFK', colorValue: 4),
          Player(id: 'kicked_only', name: 'Kicked', colorValue: 5),
        ],
        units: state.units,
      ),
      session: MatchSessionState.snapshot(
        gameMode: GameMode.multiplayer,
        submittedPlayerIds: state.runtimeState.submittedPlayerIds,
        timeoutStreaksByPlayerId: state.runtimeState.timeoutStreaksByPlayerId,
        afkPlayerIds: state.runtimeState.afkPlayerIds,
        kickedPlayerIds: state.runtimeState.kickedPlayerIds,
      ),
      metadata: GameSnapshotMetadata(
        id: 'faithful_snapshot',
        schemaVersion: 3,
        name: 'Faithful AI boundary',
        world: const WorldReference(name: 'verdantia', source: MapSource.asset),
        savedAtUtc: DateTime.utc(2026, 7, 29),
        camera: GameSnapshotCamera.zero,
      ),
      eventLogOffset: 73,
    );

    final result = const SimulationGameEngineAdapter().apply(
      snapshot: snapshot,
      state: state,
      command: const SkipUnitTurnCommand('unit_1'),
      actorPlayerId: 'player_1',
      commandTick: 3,
      mapView: const _EmptyMapReadView(),
      ruleset: GameRuleset.defaults,
    );

    expect(result.accepted, isTrue);
    expect(result.snapshot.session, same(snapshot.session));
    expect(result.snapshot.metadata, same(snapshot.metadata));
    expect(result.snapshot.eventLogOffset, 73);
    expect(result.snapshot.domain.units.single.movementPoints, 0);
    expect(result.state.runtimeState.submittedPlayerIds, {'session_only'});
    expect(result.state.runtimeState.timeoutStreaksByPlayerId, {
      'timeout_only': 2,
    });
    expect(result.state.runtimeState.afkPlayerIds, {'afk_only'});
    expect(result.state.runtimeState.kickedPlayerIds, {'kicked_only'});
  });
}

CanonicalGameSnapshot _snapshotFor(PersistentGameState state) {
  return CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: 7,
      matchRules: MatchRules.standard,
      participants: const [
        Player(id: 'player_1', name: 'Actor', colorValue: 1),
      ],
      units: state.units,
      artifacts: state.artifacts,
    ),
    session: MatchSessionState.snapshot(gameMode: GameMode.hotSeat),
    metadata: GameSnapshotMetadata(
      id: 'simulation_test',
      schemaVersion: 3,
      name: 'Simulation test',
      world: const WorldReference(name: 'verdantia', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 29),
      camera: GameSnapshotCamera.zero,
    ),
    interaction: PersistedInteractionState(
      cityFoundingDraft: state.runtimeState.cityFoundingDraft,
      pendingAction: state.runtimeState.pendingAction,
    ),
  );
}

final class _EmptyMapReadView implements MapReadView {
  const _EmptyMapReadView();

  @override
  int get cols => 0;

  @override
  int get rows => 0;

  @override
  MapTileLookup get mapTiles => this;

  @override
  String? get mapName => null;

  @override
  Iterable<MapObjectiveDefinition> get objectives => const [];

  @override
  int get tileCount => 0;

  @override
  Iterable<Iterable<TerrainType>> get tileTerrains => const [];

  @override
  Iterable<MapTileView> get tileViews => const [];

  @override
  MapTileView? tileAt(int col, int row) => null;
}
