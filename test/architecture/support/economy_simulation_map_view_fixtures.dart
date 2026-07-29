part of '../world_map_projection_boundary_test.dart';

void _registerEconomySimulationMapViewFixtures() {
  test('economy map-view guard rejects raw MapData reuse', () {
    final violations = _economyRunMapViewViolations('''
abstract final class EconomySimulation {
  static void run(Config config) {
    final mapData = config.mapData;
    validateMapDataTileInvariants(mapData);
    final mapView = mapData.indexedReadView();
    consume(mapData);
    consume(mapView);
  }
}
''', 'fixture.dart');

    expect(
      violations,
      contains(
        'fixture.dart EconomySimulation.run must use local mapData only for '
        'the tile-invariant pre-pass and indexed mapView',
      ),
    );
  });

  test('economy map-view guard requires tile validation before indexing', () {
    final violations = _economyRunMapViewViolations('''
abstract final class EconomySimulation {
  static void run(Config config) {
    final mapData = config.mapData;
    final mapView = mapData.indexedReadView();
    _economySimulationCommandApplierForSetup(
      config: config,
      state: state,
      mapView: mapView,
    );
  }
}
''', 'fixture.dart');

    expect(
      violations,
      contains(
        'fixture.dart EconomySimulation.run must use local mapData only for '
        'the tile-invariant pre-pass and indexed mapView',
      ),
    );
  });

  test('economy map-view guard rejects a second indexed view', () {
    final violations = _economyRunMapViewViolations('''
abstract final class EconomySimulation {
  static void run(Config config) {
    final mapData = config.mapData;
    validateMapDataTileInvariants(mapData);
    final mapView = mapData.indexedReadView();
    final duplicate = config.mapData.indexedReadView();
    _economySimulationCommandApplierForSetup(
      config: config,
      state: state,
      mapView: mapView,
    );
    consume(duplicate);
  }
}
''', 'fixture.dart');

    expect(
      violations,
      contains(
        'fixture.dart EconomySimulation.run must call indexedReadView exactly '
        'once; found 2',
      ),
    );
  });

  test('economy map-view guard rejects reading config map after indexing', () {
    final violations = _economyRunMapViewViolations('''
abstract final class EconomySimulation {
  static void run(Config config) {
    final mapData = config.mapData;
    validateMapDataTileInvariants(mapData);
    final mapView = mapData.indexedReadView();
    _economySimulationCommandApplierForSetup(
      config: config,
      state: state,
      mapView: mapView,
    );
    consume(config.mapData);
  }
}
''', 'fixture.dart');

    expect(
      violations,
      contains(
        'fixture.dart EconomySimulation.run must read config.mapData only '
        'once; found 2',
      ),
    );
  });

  test('economy map-view guard counts indexed-view tear-offs in helpers', () {
    final violations = _economyIndexedReadViewViolations({
      'economy_simulation.dart': '''
void run(MapData mapData) {
  final mapView = mapData.indexedReadView();
  consume(mapView);
}
''',
      'economy_simulation_helper.dart': '''
MapReadView helper(MapData mapData) {
  final buildView = mapData.indexedReadView;
  return buildView();
}
''',
    });

    expect(
      violations,
      contains(
        'economy simulation sources must call indexedReadView exactly once; '
        'found 2',
      ),
    );
  });

  test('economy source discovery includes future matching helpers', () {
    expect(
      _isEconomySimulationSourcePath(
        'lib/ai/simulation/economy_simulation_future_helper.dart',
      ),
      isTrue,
    );
    expect(
      _isEconomySimulationSourcePath(
        'lib/ai/simulation/unrelated_simulation.dart',
      ),
      isFalse,
    );
  });

  test('economy source discovery includes parts with unrelated names', () {
    expect(
      _libraryPartPaths(
        'lib/ai/simulation/economy_simulation.dart',
        "part 'support.dart';",
      ),
      ['lib/ai/simulation/support.dart'],
    );
  });

  test('economy map-view guard rejects canonical map state in the applier', () {
    final violations = _economyCommandApplierMapViewViolations('''
final class _EconomySimulationCommandApplier {
  const _EconomySimulationCommandApplier(this.worldMap);

  final WorldMap worldMap;
}
''', 'fixture.dart');

    expect(
      violations,
      containsAll([
        'fixture.dart command applier must declare one mapView field',
        'fixture.dart command applier must declare one engineSnapshot field',
        'fixture.dart command applier must have one constructor over mapView '
            'and engineSnapshot',
      ]),
    );
  });

  test('economy map-view guard rejects canonical and legacy dependencies', () {
    final violations = _economyMapDependencyViolations('''
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/persistence/legacy_world_map_adapter.dart';

WorldMap convert(MapData mapData) =>
    LegacyWorldMapAdapter.fromMapData(mapData);
''', 'fixture.dart');

    expect(
      violations,
      containsAll([
        'fixture.dart must not reference WorldMap',
        'fixture.dart must not reference LegacyWorldMapAdapter',
        'fixture.dart must not import package:aonw_core/domain/world_map.dart',
        'fixture.dart must not import '
            'package:aonw_core/map/persistence/legacy_world_map_adapter.dart',
      ]),
    );
  });

  test('economy map-view guard rejects an aliased canonical map', () {
    final sources = {
      'canonical_map.dart': 'typedef CanonicalMap = WorldMap;',
      'fixture.dart': 'void consume(CanonicalMap map) {}',
    };
    final violations = _economyMapDependencyViolations(
      sources['fixture.dart']!,
      'fixture.dart',
      forbiddenTypeNames: typeNamesBackedBy(sources, const {
        'WorldMap',
        'WorldMapReadView',
        'LegacyWorldMapAdapter',
      }),
    );

    expect(
      violations,
      contains('fixture.dart must not reference CanonicalMap'),
    );
  });
}
