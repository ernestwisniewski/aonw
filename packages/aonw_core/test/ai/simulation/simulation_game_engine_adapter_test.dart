import 'package:aonw_core/ai/simulation/simulation_game_engine_adapter.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('simulation projection carries every authoritative state slice', () {
    final state = DomainState.snapshot(
      playerColors: const {'player_1': 99},
      playerCountries: const {'player_1': PlayerCountry.japan},
      playerGold: const {'player_1': 17},
      playerWarWeariness: const {'player_1': 4},
      playerStabilityNet: const {'player_1': -2},
      fieldImprovements: const [
        FieldImprovement(
          hex: CityHex(col: 2, row: 3),
          type: FieldImprovementType.farm,
        ),
      ],

      dominationHoldTurnsByPlayerId: const {'player_1': 2},
      culturalVictoryHoldTurnsByPlayerId: const {'player_1': 3},
      mapObjectiveHoldStatesByObjectiveId: const {
        'pass_1': MapObjectiveHoldState(
          objectiveId: 'pass_1',
          playerId: 'player_1',
          holdTurns: 4,
        ),
      },
    );

    final projected = const SimulationGameEngineAdapter().projectSnapshot(
      snapshot: _snapshotFor(state),
      state: state,
    );

    expect(projected.domain.playerColors, state.playerColors);
    expect(projected.domain.playerCountries, state.playerCountries);
    expect(projected.domain.playerGold, state.playerGold);
    expect(projected.domain.playerWarWeariness, state.playerWarWeariness);
    expect(projected.domain.playerStabilityNet, state.playerStabilityNet);
    expect(projected.domain.fieldImprovements, state.fieldImprovements);
    expect(
      projected.domain.dominationHoldTurnsByPlayerId,
      state.dominationHoldTurnsByPlayerId,
    );
    expect(
      projected.domain.culturalVictoryHoldTurnsByPlayerId,
      state.culturalVictoryHoldTurnsByPlayerId,
    );
    expect(
      projected.domain.mapObjectiveHoldStatesByObjectiveId,
      state.mapObjectiveHoldStatesByObjectiveId,
    );
  });

  test(
    'simulation adapter applies migrated unit actions through GameEngine',
    () {
      final state = DomainState.snapshot(
        playerColors: const {'player_1': 1},
        playerCountries: const {'player_1': PlayerCountry.poland},
        playerGold: const {'player_1': 17},
        playerWarWeariness: const {'player_1': 4},
        playerStabilityNet: const {'player_1': -2},
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
        artifacts: const [
          WorldArtifact(
            id: 'artifact_1',
            type: WorldArtifactType.heroSword,
            location: WorldArtifactLocation.map(col: 1, row: 1),
          ),
        ],
        wonderRegistry: WonderRegistry(
          completedBy: const {WonderType.greatLibrary: 'player_1'},
        ),

        pendingAction: const PendingResearchSelection(
          ownerPlayerId: 'player_1',
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
        result.state.actions.pendingAction,
        const PendingUnitTurnSkip(
          ownerPlayerId: 'player_1',
          unitId: 'unit_1',
          restoreMovementPoints: 3,
        ),
      );
      expect(result.state.playerGold, same(state.playerGold));
      expect(
        result.snapshot.domain.playerWarWeariness,
        state.playerWarWeariness,
      );
      expect(
        result.snapshot.domain.playerStabilityNet,
        state.playerStabilityNet,
      );
      expect(result.snapshot.domain.artifacts, state.artifacts);
      expect(result.snapshot.domain.wonderRegistry, state.wonderRegistry);
    },
  );

  test('simulation adapter preserves rejected state identity', () {
    final state = DomainState.snapshot(
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
    final state = DomainState.snapshot(
      gameMode: GameMode.multiplayer,
      participants: const [
        Player(id: 'player_1', name: 'Actor', colorValue: 1),
        Player(id: 'session_only', name: 'Submitted', colorValue: 2),
        Player(id: 'timeout_only', name: 'Timeout', colorValue: 3),
        Player(id: 'afk_only', name: 'AFK', colorValue: 4),
        Player(id: 'kicked_only', name: 'Kicked', colorValue: 5),
      ],
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

      submittedPlayerIds: const {'session_only'},
      timeoutStreaksByPlayerId: const {'timeout_only': 2},
      afkPlayerIds: const {'afk_only'},
      kickedPlayerIds: const {'kicked_only'},
    );
    final snapshot = CanonicalGameSnapshot.snapshot(
      domain: state.copyWith(turn: 7),

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
    expect(
      result.snapshot.domain.turnStatesByPlayerId,
      same(snapshot.domain.turnStatesByPlayerId),
    );
    expect(result.snapshot.metadata, same(snapshot.metadata));
    expect(result.snapshot.eventLogOffset, 73);
    expect(result.snapshot.domain.units.single.movementPoints, 0);
    expect(result.state.submittedPlayerIds, {'session_only'});
    expect(result.state.timeoutStreaksByPlayerId, {'timeout_only': 2});
    expect(result.state.afkPlayerIds, {'afk_only'});
    expect(result.state.kickedPlayerIds, {'kicked_only'});
  });
}

CanonicalGameSnapshot _snapshotFor(DomainState state) {
  return CanonicalGameSnapshot.snapshot(
    domain:
        ((DomainState.snapshot(
          turn: 7,
          matchRules: MatchRules.standard,
          participants: const [
            Player(id: 'player_1', name: 'Actor', colorValue: 1),
          ],
          units: state.units,
          artifacts: state.artifacts,
        )).copyWith(gameMode: GameMode.hotSeat)).copyWith(
          actions: DomainActionState(
            cityFoundingDraft: state.actions.cityFoundingDraft,
            pendingAction: state.actions.pendingAction,
          ),
        ),

    metadata: GameSnapshotMetadata(
      id: 'simulation_test',
      schemaVersion: 3,
      name: 'Simulation test',
      world: const WorldReference(name: 'verdantia', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 29),
      camera: GameSnapshotCamera.zero,
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
