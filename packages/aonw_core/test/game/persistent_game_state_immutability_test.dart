import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentGameState immutability', () {
    test('snapshot is detached from all collection sources', _sourceMutation);
    test('collection getters reject mutation', _getterMutation);
    test('nested scalar copy shares direct collections', _scalarCopySharing);
    test('collection replacements are copied', _replacementOwnership);
    test('legacy state is deeply normalized once', _legacyNormalization);
    test('fromJson returns an owned snapshot', _fromJsonOwnership);
    test('toJson exposes mutable map payloads', _mutableJsonMaps);
    test(
      'stripping interaction shares persistent collections',
      _stripInteractionSharing,
    );
  });
}

void _sourceMutation() {
  final sources = _collections('source');
  final state = _snapshot(sources);
  final originalJson = state.toJson();
  final originalHash = state.hashCode;

  _mutate(sources);

  expect(state.toJson(), originalJson);
  expect(state.hashCode, originalHash);
}

void _getterMutation() {
  final state = _snapshot(_collections('getter'));
  final mutations = <String, void Function()>{
    'playerColors': () => state.playerColors['other'] = 2,
    'playerCountries': () {
      state.playerCountries['other'] = PlayerCountry.japan;
    },
    'playerGold': () => state.playerGold['other'] = 2,
    'playerWarWeariness': () => state.playerWarWeariness['other'] = 2,
    'playerStabilityNet': () => state.playerStabilityNet['other'] = 2,
    'units': () => state.units.add(_unit('other')),
    'cities': () => state.cities.add(_city('other')),
    'artifacts': () => state.artifacts.add(_artifact('other')),
    'fieldImprovements': () {
      state.fieldImprovements.add(_improvement(9));
    },
  };

  for (final mutation in mutations.entries) {
    expect(mutation.value, throwsUnsupportedError, reason: mutation.key);
  }
}

void _scalarCopySharing() {
  final state = _snapshot(_collections('shared'));
  final copied = state.copyWith(
    runtimeState: state.runtimeState.copyWith(
      turnStartedAt: DateTime.utc(2026, 7, 18),
    ),
  );

  expect(copied.runtimeState.turnStartedAt, DateTime.utc(2026, 7, 18));
  _expectDirectCollectionsShared(copied, state);
  expect(copied.fogOfWar, same(state.fogOfWar));
  expect(copied.research, same(state.research));
  expect(copied.wonderRegistry, same(state.wonderRegistry));
}

void _replacementOwnership() {
  final initial = _snapshot(_collections('initial'));
  final replacements = _collections('replacement');
  final copied = initial.copyWith(
    playerColors: replacements.playerColors,
    playerCountries: replacements.playerCountries,
    playerGold: replacements.playerGold,
    playerWarWeariness: replacements.playerWarWeariness,
    playerStabilityNet: replacements.playerStabilityNet,
    units: replacements.units,
    cities: replacements.cities,
    artifacts: replacements.artifacts,
    fieldImprovements: replacements.fieldImprovements,
  );
  final expectedJson = copied.toJson();
  final expectedHash = copied.hashCode;

  _expectDirectCollectionsDetached(copied, replacements);
  _mutate(replacements);

  expect(copied.toJson(), expectedJson);
  expect(copied.hashCode, expectedHash);
}

void _legacyNormalization() {
  final sources = _collections('legacy');
  final controlledHexes = <CityHex>[const CityHex(col: 2, row: 1)];
  final legacyCity = GameCity(
    id: 'legacy_city',
    ownerPlayerId: 'legacy_player',
    name: 'Legacy',
    center: const CityHex(col: 1, row: 1),
    controlledHexes: controlledHexes,
  );
  final submittedPlayerIds = <String>{'legacy_player'};
  final legacyRuntime = GameRuntimeState(
    submittedPlayerIds: submittedPlayerIds,
  );
  sources.cities[0] = legacyCity;
  final legacy = PersistentGameState(
    playerColors: sources.playerColors,
    playerCountries: sources.playerCountries,
    playerGold: sources.playerGold,
    playerWarWeariness: sources.playerWarWeariness,
    playerStabilityNet: sources.playerStabilityNet,
    units: sources.units,
    cities: sources.cities,
    artifacts: sources.artifacts,
    fieldImprovements: sources.fieldImprovements,
    runtimeState: legacyRuntime,
  );

  final snapshot = legacy.immutableSnapshot();
  final expectedJson = snapshot.toJson();
  final expectedHash = snapshot.hashCode;

  expect(snapshot, isNot(same(legacy)));
  expect(snapshot.immutableSnapshot(), same(snapshot));
  expect(snapshot.cities.single, isNot(same(legacyCity)));
  expect(snapshot.runtimeState, isNot(same(legacyRuntime)));

  _mutate(sources);
  controlledHexes.clear();
  submittedPlayerIds.add('mutated');

  expect(snapshot.toJson(), expectedJson);
  expect(snapshot.hashCode, expectedHash);
  expect(snapshot.cities.single.controlledHexes, const [
    CityHex(col: 2, row: 1),
  ]);
  expect(snapshot.runtimeState.submittedPlayerIds, {'legacy_player'});
}

void _fromJsonOwnership() {
  final restored = PersistentGameState.fromJson(
    _snapshot(_collections('json')).toJson(),
  );

  expect(restored.immutableSnapshot(), same(restored));
  expect(() => restored.playerGold['other'] = 2, throwsUnsupportedError);
  expect(() => restored.units.clear(), throwsUnsupportedError);
  expect(
    () => restored.cities.single.controlledHexes.clear(),
    throwsUnsupportedError,
  );
  expect(
    () => restored.runtimeState.submittedPlayerIds.add('other'),
    throwsUnsupportedError,
  );
}

void _mutableJsonMaps() {
  final state = _snapshot(_collections('json_map'));
  final originalJson = state.toJson();
  final originalHash = state.hashCode;
  final json = state.toJson();

  (json['playerColors'] as Map<String, dynamic>)['client'] = 2;
  (json['playerCountries'] as Map<String, dynamic>)['client'] =
      PlayerCountry.japan.name;
  (json['playerGold'] as Map<String, dynamic>)['client'] = 2;
  (json['playerWarWeariness'] as Map<String, dynamic>)['client'] = 2;
  (json['playerStabilityNet'] as Map<String, dynamic>)['client'] = 2;

  expect(state.toJson(), originalJson);
  expect(state.hashCode, originalHash);
}

void _stripInteractionSharing() {
  final collections = _collections('strip');
  final state = PersistentGameState.snapshot(
    playerColors: collections.playerColors,
    playerCountries: collections.playerCountries,
    playerGold: collections.playerGold,
    playerWarWeariness: collections.playerWarWeariness,
    playerStabilityNet: collections.playerStabilityNet,
    units: collections.units,
    cities: collections.cities,
    artifacts: collections.artifacts,
    fieldImprovements: collections.fieldImprovements,
    runtimeState: GameRuntimeState.snapshot(
      cityFoundingDraft: CityFoundingDraft(
        unitId: 'strip_unit',
        ownerPlayerId: 'strip_player',
        center: const CityHex(col: 0, row: 0),
      ),
      pendingAction: const PendingResearchSelection(
        ownerPlayerId: 'strip_player',
      ),
      submittedPlayerIds: {'strip_player'},
    ),
  );

  final stripped = state.withoutClientInteractionState();

  expect(stripped.runtimeState.cityFoundingDraft, isNull);
  expect(stripped.runtimeState.pendingAction, isNull);
  _expectDirectCollectionsShared(stripped, state);
  expect(stripped.fogOfWar, same(state.fogOfWar));
  expect(stripped.research, same(state.research));
  expect(stripped.wonderRegistry, same(state.wonderRegistry));
  expect(
    stripped.runtimeState.submittedPlayerIds,
    same(state.runtimeState.submittedPlayerIds),
  );
}

_MutableCollections _collections(String prefix) => (
  playerColors: <String, int>{'${prefix}_player': 1},
  playerCountries: <String, PlayerCountry>{
    '${prefix}_player': PlayerCountry.poland,
  },
  playerGold: <String, int>{'${prefix}_player': 10},
  playerWarWeariness: <String, int>{'${prefix}_player': 2},
  playerStabilityNet: <String, int>{'${prefix}_player': -1},
  units: <GameUnit>[_unit(prefix)],
  cities: <GameCity>[_city(prefix)],
  artifacts: <WorldArtifact>[_artifact(prefix)],
  fieldImprovements: <FieldImprovement>[_improvement(1)],
);

PersistentGameState _snapshot(_MutableCollections values) {
  return PersistentGameState.snapshot(
    playerColors: values.playerColors,
    playerCountries: values.playerCountries,
    playerGold: values.playerGold,
    playerWarWeariness: values.playerWarWeariness,
    playerStabilityNet: values.playerStabilityNet,
    units: values.units,
    cities: values.cities,
    artifacts: values.artifacts,
    fieldImprovements: values.fieldImprovements,
    runtimeState: GameRuntimeState.snapshot(
      submittedPlayerIds: {'${values.playerColors.keys.single}_submitted'},
    ),
  );
}

void _mutate(_MutableCollections values) {
  values.playerColors['mutated'] = 2;
  values.playerCountries['mutated'] = PlayerCountry.japan;
  values.playerGold['mutated'] = 2;
  values.playerWarWeariness['mutated'] = 2;
  values.playerStabilityNet['mutated'] = 2;
  values.units.add(_unit('mutated'));
  values.cities.add(_city('mutated'));
  values.artifacts.add(_artifact('mutated'));
  values.fieldImprovements.add(_improvement(9));
}

void _expectDirectCollectionsShared(
  PersistentGameState actual,
  PersistentGameState source,
) {
  expect(actual.playerColors, same(source.playerColors));
  expect(actual.playerCountries, same(source.playerCountries));
  expect(actual.playerGold, same(source.playerGold));
  expect(actual.playerWarWeariness, same(source.playerWarWeariness));
  expect(actual.playerStabilityNet, same(source.playerStabilityNet));
  expect(actual.units, same(source.units));
  expect(actual.cities, same(source.cities));
  expect(actual.artifacts, same(source.artifacts));
  expect(actual.fieldImprovements, same(source.fieldImprovements));
}

void _expectDirectCollectionsDetached(
  PersistentGameState actual,
  _MutableCollections sources,
) {
  expect(actual.playerColors, isNot(same(sources.playerColors)));
  expect(actual.playerCountries, isNot(same(sources.playerCountries)));
  expect(actual.playerGold, isNot(same(sources.playerGold)));
  expect(actual.playerWarWeariness, isNot(same(sources.playerWarWeariness)));
  expect(actual.playerStabilityNet, isNot(same(sources.playerStabilityNet)));
  expect(actual.units, isNot(same(sources.units)));
  expect(actual.cities, isNot(same(sources.cities)));
  expect(actual.artifacts, isNot(same(sources.artifacts)));
  expect(actual.fieldImprovements, isNot(same(sources.fieldImprovements)));
}

GameUnit _unit(String suffix) => GameUnit.startingCommander(
  ownerPlayerId: '${suffix}_player',
  col: suffix.length,
);

GameCity _city(String suffix) => GameCity.snapshot(
  id: '${suffix}_city',
  ownerPlayerId: '${suffix}_player',
  name: suffix,
  center: CityHex(col: suffix.length, row: 0),
  controlledHexes: [CityHex(col: suffix.length + 1, row: 0)],
);

WorldArtifact _artifact(String suffix) => WorldArtifact(
  id: '${suffix}_artifact',
  type: WorldArtifactType.ancientImperialCrown,
  location: WorldArtifactLocation.map(col: suffix.length, row: 2),
);

FieldImprovement _improvement(int col) => FieldImprovement(
  hex: CityHex(col: col, row: 3),
  type: FieldImprovementType.farm,
);

typedef _MutableCollections = ({
  Map<String, int> playerColors,
  Map<String, PlayerCountry> playerCountries,
  Map<String, int> playerGold,
  Map<String, int> playerWarWeariness,
  Map<String, int> playerStabilityNet,
  List<GameUnit> units,
  List<GameCity> cities,
  List<WorldArtifact> artifacts,
  List<FieldImprovement> fieldImprovements,
});
