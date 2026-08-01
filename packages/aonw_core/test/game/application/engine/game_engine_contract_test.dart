import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('context carries deterministic engine inputs', () {
    final mapView = WorldMap(cols: 1, rows: 1, tiles: []);
    final context = GameEngineContext(
      actorPlayerId: 'player-1',
      mapView: mapView,
      ruleset: GameRuleset.defaults,
      commandTick: 7,
    );

    expect(context.actorPlayerId, 'player-1');
    expect(context.mapView, same(mapView));
    expect(context.ruleset, same(GameRuleset.defaults));
    expect(context.commandTick, 7);
  });

  test('accepted result preserves ordered immutable domain events', () {
    final sourceEvents = <DomainEvent>[
      const TurnEndedEvent(playerId: 'player-1'),
      const UnitMovedEvent(
        unitId: 'unit-1',
        fromCol: 0,
        fromRow: 0,
        toCol: 1,
        toRow: 0,
      ),
    ];

    final result = GameEngineResult.accepted(
      snapshot: _snapshot(),
      events: sourceEvents,
    );
    sourceEvents.clear();

    expect(result, isA<GameEngineAccepted>());
    expect(result.events.map((event) => event.runtimeType), [
      TurnEndedEvent,
      UnitMovedEvent,
    ]);
    expect(() => result.events.clear(), throwsUnsupportedError);
  });

  test('complete dispatcher accepts turn commands', () {
    final result = const GameEngine().apply(
      snapshot: _snapshot(),
      command: const EndTurnCommand('player-1'),
      context: const GameEngineContext(
        actorPlayerId: 'player-1',
        mapView: _EmptyMapReadView(),
        ruleset: GameRuleset.defaults,
        commandTick: 7,
      ),
    );

    expect(result, isA<GameEngineAccepted>());
    expect(result.events, isNotEmpty);
  });

  test('dispatcher classifies authoritative command families', () {
    expect(
      GameEngine.commandFamily(const MoveUnitCommand('unit-1', 1, 0)),
      GameEngineCommandFamily.movement,
    );
    expect(
      GameEngine.commandFamily(const SkipUnitTurnCommand('unit-1')),
      GameEngineCommandFamily.unitAction,
    );
    expect(
      GameEngine.commandFamily(const FortifyUnitCommand('unit-1')),
      GameEngineCommandFamily.unitAction,
    );
    expect(
      GameEngine.commandFamily(const EndTurnCommand('player-1')),
      GameEngineCommandFamily.turn,
    );
  });

  test('system diagnostics remain outside authoritative domain events', () {
    const GameEvent diagnostic = CommandRejectedEvent(reason: 'denied');

    expect(diagnostic, isNot(isA<DomainEvent>()));
  });
}

CanonicalGameSnapshot _snapshot() {
  return CanonicalGameSnapshot.snapshot(
    domain: (DomainState.snapshot(
      turn: 1,
      matchRules: MatchRules.standard,
      participants: const [
        Player(id: 'player-1', name: 'Player', colorValue: 0xFF000001),
      ],
    )).copyWith(gameMode: GameMode.multiplayer),

    metadata: GameSnapshotMetadata(
      id: 'save-1',
      schemaVersion: 3,
      name: 'Campaign',
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
