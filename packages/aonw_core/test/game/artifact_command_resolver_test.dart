import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _playerId = 'player_1';
const _targetPlayerId = 'player_2';

void main() {
  group('ArtifactCommandResolver.startExcavation', () {
    final mapArtifact = _artifact(
      'artifact_map',
      const WorldArtifactLocation.map(col: 1, row: 1),
    );
    final poisoned = _unit(
      excavatingArtifactId: 'existing_excavation',
      carriedArtifactId: 'carried',
    );
    test('rejects in exact validation order and preserves identities', () {
      _expectStartRejected(
        const [],
        [mapArtifact],
        _targetPlayerId,
        'unit_not_found',
      );
      _expectStartRejected(
        [poisoned],
        const [],
        _targetPlayerId,
        'unit_not_controlled',
      );
      _expectStartRejected([poisoned], const [], _playerId, 'unit_unavailable');
      _expectStartRejected(
        [_unit(posture: UnitPosture.fortified)],
        [mapArtifact],
        _playerId,
        'unit_unavailable',
      );
      _expectStartRejected(
        [_unit(carriedArtifactId: 'carried')],
        const [],
        _playerId,
        'unit_already_carrying_artifact',
      );
      _expectStartRejected(
        [_unit()],
        [
          _artifact(
            'elsewhere',
            const WorldArtifactLocation.map(col: 2, row: 1),
          ),
        ],
        _playerId,
        'artifact_not_found',
      );
    });

    test('links excavation, clears movement, and owns immutable lists', () {
      final path = QueuedMovePath(
        targetCol: 2,
        targetRow: 1,
        steps: const [
          UnitMovementStep(col: 2, row: 1, enterCost: 1, cumulativeCost: 1),
        ],
      );
      final untouchedUnit = _unit(id: 'unit_2', col: 3);
      final untouchedArtifact = _artifact(
        'artifact_other',
        const WorldArtifactLocation.map(col: 3, row: 1),
      );
      final units = [_unit(movementPoints: 5, queuedPath: path), untouchedUnit];
      final artifacts = [mapArtifact, untouchedArtifact];

      final result = ArtifactCommandResolver.startExcavation(
        units: units,
        artifacts: artifacts,
        command: const StartArtifactExcavationCommand('unit_1'),
        actorPlayerId: _playerId,
      );

      expect((result.accepted, result.reason), (true, null));
      expect(identical(result.units, units), isFalse);
      expect(identical(result.artifacts, artifacts), isFalse);
      final unit = result.units.first;
      final artifact = result.artifacts.first;
      expect((unit.movementPoints, unit.queuedPath), (0, null));
      expect(unit.excavatingArtifactId, artifact.id);
      expect(artifact.location.isBeingExcavated, isTrue);
      expect(
        (
          artifact.location.unitId,
          artifact.location.col,
          artifact.location.row,
          artifact.location.remainingTurns,
        ),
        (unit.id, unit.col, unit.row, ArtifactCommandResolver.excavationTurns),
      );
      expect(identical(result.units.last, untouchedUnit), isTrue);
      expect(identical(result.artifacts.last, untouchedArtifact), isTrue);
      _expectImmutable(result.units, result.artifacts);
    });
  });

  group('ArtifactCommandResolver.storeInCity', () {
    final carried = _artifact(
      'artifact_carried',
      const WorldArtifactLocation.carried(unitId: 'unit_1'),
    );
    final carrier = _unit(carriedArtifactId: carried.id);
    final ownCity = _city('city_own', _playerId);
    final foreignCity = _city('city_foreign', _targetPlayerId);
    final distantCity = _city('city_distant', _playerId, col: 4, row: 4);
    final stored = _artifact(
      'artifact_stored',
      const WorldArtifactLocation.stored(cityId: 'city_own'),
    );
    test('rejects in exact validation order and preserves identities', () {
      _expectStoreRejected(
        const [],
        const [],
        const [],
        const StoreArtifactInCityCommand('unit_1'),
        _targetPlayerId,
        'unit_not_found',
      );
      _expectStoreRejected(
        [_unit()],
        const [],
        const [],
        const StoreArtifactInCityCommand('unit_1'),
        _targetPlayerId,
        'unit_not_controlled',
      );
      _expectStoreRejected(
        [_unit()],
        [ownCity],
        const [],
        const StoreArtifactInCityCommand('unit_1'),
        _playerId,
        'unit_not_carrying_artifact',
      );
      _expectStoreRejected(
        [_unit(carriedArtifactId: 'missing')],
        const [],
        const [],
        const StoreArtifactInCityCommand('unit_1'),
        _playerId,
        'carried_artifact_not_found',
      );
      _expectStoreRejected(
        [carrier],
        const [],
        [carried],
        const StoreArtifactInCityCommand('unit_1', cityId: 'missing'),
        _playerId,
        'city_not_found',
      );
      _expectStoreRejected(
        [carrier],
        [foreignCity],
        [carried],
        const StoreArtifactInCityCommand('unit_1'),
        _playerId,
        'city_not_controlled',
      );
      _expectStoreRejected(
        [carrier],
        [distantCity],
        [carried],
        const StoreArtifactInCityCommand('unit_1', cityId: 'city_distant'),
        _playerId,
        'unit_not_in_city',
      );
      _expectStoreRejected(
        [carrier],
        [ownCity],
        [carried, stored],
        const StoreArtifactInCityCommand('unit_1'),
        _playerId,
        'city_artifact_slot_full',
      );
    });

    test('links carried artifact to city and owns immutable lists', () {
      final untouchedUnit = _unit(id: 'unit_2', col: 3);
      final untouchedArtifact = _artifact(
        'artifact_other',
        const WorldArtifactLocation.map(col: 3, row: 1),
      );
      final units = [carrier, untouchedUnit];
      final artifacts = [carried, untouchedArtifact];
      final result = ArtifactCommandResolver.storeInCity(
        units: units,
        cities: [ownCity],
        artifacts: artifacts,
        command: const StoreArtifactInCityCommand('unit_1'),
        actorPlayerId: _playerId,
      );

      expect((result.accepted, result.reason), (true, null));
      expect(identical(result.units, units), isFalse);
      expect(identical(result.artifacts, artifacts), isFalse);
      expect(result.units.first.carriedArtifactId, isNull);
      expect(result.artifacts.first.location.isStored, isTrue);
      expect(result.artifacts.first.location.cityId, ownCity.id);
      expect(identical(result.units.last, untouchedUnit), isTrue);
      expect(identical(result.artifacts.last, untouchedArtifact), isTrue);
      _expectImmutable(result.units, result.artifacts);
    });
  });

  group('ArtifactCommandResolver.tradeArtifact', () {
    test('rejects in exact validation order and preserves identities', () {
      _expectTradeRejected(
        _tradeInput(),
        const TradeArtifactCommand(
          playerId: _playerId,
          targetPlayerId: _playerId,
          offeredArtifactId: 'offered',
          offeredGold: -1,
        ),
        _targetPlayerId,
        'invalid_artifact_trade_actor',
      );
      _expectTradeRejected(
        _tradeInput(),
        const TradeArtifactCommand(
          playerId: _playerId,
          targetPlayerId: _playerId,
          offeredArtifactId: 'offered',
          offeredGold: -1,
        ),
        _playerId,
        'invalid_artifact_trade_target',
      );
      _expectTradeRejected(
        _tradeInput(),
        const TradeArtifactCommand(
          playerId: _playerId,
          targetPlayerId: _targetPlayerId,
          offeredArtifactId: 'offered',
          offeredGold: -1,
          requestedArtifactId: 'requested',
        ),
        _playerId,
        'invalid_artifact_trade_gold',
      );
      _expectTradeRejected(
        _tradeInput(diplomacy: _warDiplomacy()),
        const TradeArtifactCommand(
          playerId: _playerId,
          targetPlayerId: _targetPlayerId,
          offeredArtifactId: 'offered',
          requestedGold: 1,
        ),
        _playerId,
        'artifact_trade_requires_acceptance',
      );
      _expectTradeRejected(
        _tradeInput(
          artifacts: const [],
          playerGold: const {_playerId: 0, _targetPlayerId: 0},
          diplomacy: _warDiplomacy(),
        ),
        _validTradeCommand(offeredGold: 3),
        _playerId,
        'artifact_trade_blocked_by_war',
      );
      _expectTradeRejected(
        _tradeInput(
          artifacts: const [],
          playerGold: const {_playerId: 2, _targetPlayerId: 5},
        ),
        _validTradeCommand(offeredGold: 3),
        _playerId,
        'artifact_trade_gold_unavailable',
      );
      _expectTradeRejected(
        _tradeInput(cities: const [], artifacts: const []),
        _validTradeCommand(),
        _playerId,
        'offered_artifact_unavailable',
      );
      _expectTradeRejected(
        _tradeInput(
          artifacts: [
            _offeredArtifact(),
            _artifact(
              'occupied',
              const WorldArtifactLocation.stored(cityId: 'target_city'),
            ),
          ],
        ),
        _validTradeCommand(),
        _playerId,
        'target_artifact_slot_unavailable',
      );
    });

    test('chooses smallest free city and transfers gold immutably', () {
      final actor = _city('actor_city', _playerId, col: 0, row: 0);
      final targetZ = _city('target_z', _targetPlayerId, col: 3, row: 0);
      final targetM = _city('target_m', _targetPlayerId, col: 2, row: 0);
      final targetA = _city('target_a', _targetPlayerId, row: 0);
      final offered = _offeredArtifact();
      final occupied = _artifact(
        'occupied',
        const WorldArtifactLocation.stored(cityId: 'target_a'),
      );
      final artifacts = [offered, occupied];
      final gold = <String, int>{_playerId: 10, _targetPlayerId: 5};
      final input = (
        cities: [targetZ, actor, targetM, targetA],
        artifacts: artifacts,
        playerGold: gold,
        diplomacy: DiplomacyState.empty,
      );

      final result = _trade(
        input,
        _validTradeCommand(offeredGold: 3),
        _playerId,
      );

      expect((result.accepted, result.reason), (true, null));
      expect(identical(result.artifacts, artifacts), isFalse);
      expect(identical(result.playerGold, gold), isFalse);
      expect(result.artifacts.first.location.cityId, targetM.id);
      expect(identical(result.artifacts.last, occupied), isTrue);
      expect(result.playerGold, {_playerId: 7, _targetPlayerId: 8});
      expect(gold, {_playerId: 10, _targetPlayerId: 5});
      expect(() => result.artifacts.clear(), throwsUnsupportedError);
      expect(() => result.playerGold[_playerId] = 0, throwsUnsupportedError);
    });
  });
}

void _expectStartRejected(
  List<GameUnit> units,
  List<WorldArtifact> artifacts,
  String actor,
  String reason,
) => _expectUnitRejected(
  ArtifactCommandResolver.startExcavation(
    units: units,
    artifacts: artifacts,
    command: const StartArtifactExcavationCommand('unit_1'),
    actorPlayerId: actor,
  ),
  units,
  artifacts,
  reason,
);

void _expectStoreRejected(
  List<GameUnit> units,
  List<GameCity> cities,
  List<WorldArtifact> artifacts,
  StoreArtifactInCityCommand command,
  String actor,
  String reason,
) => _expectUnitRejected(
  ArtifactCommandResolver.storeInCity(
    units: units,
    cities: cities,
    artifacts: artifacts,
    command: command,
    actorPlayerId: actor,
  ),
  units,
  artifacts,
  reason,
);

void _expectTradeRejected(
  _TradeInput input,
  TradeArtifactCommand command,
  String actor,
  String reason,
) {
  final result = _trade(input, command, actor);
  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(identical(result.artifacts, input.artifacts), isTrue);
  expect(identical(result.playerGold, input.playerGold), isTrue);
}

void _expectUnitRejected(
  ArtifactUnitCommandResult result,
  List<GameUnit> units,
  List<WorldArtifact> artifacts,
  String reason,
) {
  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(identical(result.units, units), isTrue);
  expect(identical(result.artifacts, artifacts), isTrue);
}

void _expectImmutable(List<GameUnit> units, List<WorldArtifact> artifacts) {
  expect(() => units.clear(), throwsUnsupportedError);
  expect(() => artifacts.clear(), throwsUnsupportedError);
}

GameUnit _unit({
  String id = 'unit_1',
  int col = 1,
  int movementPoints = 3,
  QueuedMovePath? queuedPath,
  UnitPosture posture = UnitPosture.active,
  String? carriedArtifactId,
  String? excavatingArtifactId,
}) => GameUnit(
  id: id,
  ownerPlayerId: _playerId,
  type: GameUnitType.scout,
  name: 'Scout',
  col: col,
  row: 1,
  movementPoints: movementPoints,
  queuedPath: queuedPath,
  posture: posture,
  carriedArtifactId: carriedArtifactId,
  excavatingArtifactId: excavatingArtifactId,
);

WorldArtifact _artifact(String id, WorldArtifactLocation location) =>
    WorldArtifact(
      id: id,
      type: WorldArtifactType.heroSword,
      location: location,
    );

GameCity _city(String id, String ownerPlayerId, {int col = 1, int row = 1}) =>
    GameCity(
      id: id,
      ownerPlayerId: ownerPlayerId,
      name: id,
      center: CityHex(col: col, row: row),
    );

WorldArtifact _offeredArtifact() => _artifact(
  'offered',
  const WorldArtifactLocation.stored(cityId: 'actor_city'),
);

TradeArtifactCommand _validTradeCommand({int offeredGold = 0}) =>
    TradeArtifactCommand(
      playerId: _playerId,
      targetPlayerId: _targetPlayerId,
      offeredArtifactId: 'offered',
      offeredGold: offeredGold,
    );

_TradeInput _tradeInput({
  List<GameCity>? cities,
  List<WorldArtifact>? artifacts,
  Map<String, int>? playerGold,
  DiplomacyState? diplomacy,
}) => (
  cities:
      cities ??
      [
        _city('actor_city', _playerId, col: 0, row: 0),
        _city('target_city', _targetPlayerId, row: 0),
      ],
  artifacts: artifacts ?? [_offeredArtifact()],
  playerGold: playerGold ?? const {_playerId: 10, _targetPlayerId: 5},
  diplomacy: diplomacy ?? DiplomacyState.empty,
);

ArtifactTradeCommandResult _trade(
  _TradeInput input,
  TradeArtifactCommand command,
  String actorPlayerId,
) => ArtifactCommandResolver.tradeArtifact(
  cities: input.cities,
  artifacts: input.artifacts,
  playerGold: input.playerGold,
  diplomacy: input.diplomacy,
  command: command,
  actorPlayerId: actorPlayerId,
);

DiplomacyState _warDiplomacy() {
  final relation = DiplomaticRelation.between(
    playerAId: _playerId,
    playerBId: _targetPlayerId,
    status: DiplomaticRelationStatus.war,
  );
  return DiplomacyState(relations: {relation.key: relation});
}

typedef _TradeInput = ({
  List<GameCity> cities,
  List<WorldArtifact> artifacts,
  Map<String, int> playerGold,
  DiplomacyState diplomacy,
});
