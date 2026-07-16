part of '../world_map_combat_boundary_test.dart';

void _registerWorldMapCombatBoundaryFixtures() {
  test(
    'guard rejects MapData at a method boundary despite an unrelated WorldMap',
    () {
      const target = _Target(
        path: 'lib/persistent_combat_command_resolver.dart',
        owner: 'PersistentCombatCommandResolver',
        boundaries: [
          _Boundary.method(
            'resolve',
            parameter: 'mapTiles',
            type: 'MapTileLookup',
          ),
        ],
      );

      final violations = _violations('''
class PersistentCombatCommandResolver {
  final WorldMap cachedWorldMap;

  void resolve({required MapData mapTiles}) {}
}
''', target);

      expect(
        violations,
        containsAll([
          'PersistentCombatCommandResolver.resolve.mapTiles must have type '
              'MapTileLookup; found MapData',
          'PersistentCombatCommandResolver.resolve must not expose MapData '
              'through parameter mapTiles',
        ]),
      );
    },
  );

  test('guard rejects MapData in a public request field', () {
    const target = _Target(
      path: 'lib/persistent_turn_pipeline.dart',
      owner: 'PersistentTurnPipelineRequest',
      boundaries: [
        _Boundary.constructor(
          'simultaneousFinalize',
          parameter: 'mapView',
          type: 'MapReadView',
        ),
      ],
    );

    final violations = _violations('''
final class PersistentTurnPipelineRequest {
  PersistentTurnPipelineRequest.simultaneousFinalize({
    required this.mapView,
  });

  final MapData mapView;
  final WorldMap cachedWorldMap;
}
''', target);

    expect(
      violations,
      containsAll([
        'PersistentTurnPipelineRequest.simultaneousFinalize.mapView must '
            'have type MapReadView; found MapData',
        'PersistentTurnPipelineRequest.mapView field must have type '
            'MapReadView; found MapData',
        'PersistentTurnPipelineRequest.mapView field must not expose MapData',
      ]),
    );
  });

  test('guard rejects a legacy MapDefinition signature', () {
    const target = _Target(
      path: 'lib/persistent_turn_combat_resolver.dart',
      owner: 'PersistentTurnCombatResolver',
      boundaries: [
        _Boundary.method(
          'resolve',
          parameter: 'mapTiles',
          type: 'MapTileLookup',
          nullable: true,
        ),
      ],
    );
    final violations = _violations('''
import 'package:aonw_core/domain/map_definition.dart';

abstract final class PersistentTurnCombatResolver {
  static void resolve({required MapDefinition mapDefinition}) {}
}
''', target);

    expect(
      violations,
      containsAll([
        'PersistentTurnCombatResolver.resolve must declare a mapTiles '
            'parameter',
        'must not reference MapDefinition',
        'must not import map_definition.dart',
      ]),
    );
  });

  test('guard rejects MapData nested inside boundary parameter types', () {
    const target = _Target(
      path: 'lib/persistent_combat_command_resolver.dart',
      owner: 'PersistentCombatCommandResolver',
      boundaries: [
        _Boundary.method(
          'resolve',
          parameter: 'mapTiles',
          type: 'MapTileLookup',
        ),
      ],
    );

    final violations = _violations('''
class PersistentCombatCommandResolver {
  void resolve({
    required MapTileLookup mapTiles,
    required List<MapData> snapshots,
    required Map<String, MapData?> archivedById,
  }) {}
}
''', target);

    expect(
      violations,
      containsAll([
        'PersistentCombatCommandResolver.resolve must not expose MapData '
            'through parameter snapshots',
        'PersistentCombatCommandResolver.resolve must not expose MapData '
            'through parameter archivedById',
      ]),
    );
  });

  test('guard rejects MapData nested inside a boundary request field', () {
    const target = _Target(
      path: 'lib/persistent_turn_pipeline.dart',
      owner: 'PersistentTurnPipelineRequest',
      boundaries: [
        _Boundary.constructor(
          'simultaneousFinalize',
          parameter: 'mapView',
          type: 'MapReadView',
        ),
      ],
    );

    final violations = _violations('''
final class PersistentTurnPipelineRequest {
  PersistentTurnPipelineRequest.simultaneousFinalize({
    required this.mapView,
  });

  final List<MapData> mapView;
}
''', target);

    expect(
      violations,
      containsAll([
        'PersistentTurnPipelineRequest.simultaneousFinalize must not expose '
            'MapData through parameter mapView',
        'PersistentTurnPipelineRequest.mapView field must not expose MapData',
      ]),
    );
  });

  test('guard rejects MapData imported through a typedef alias', () {
    const target = _Target(
      path: 'lib/persistent_combat_command_resolver.dart',
      owner: 'PersistentCombatCommandResolver',
      boundaries: [
        _Boundary.method(
          'resolve',
          parameter: 'mapTiles',
          type: 'MapTileLookup',
        ),
      ],
    );
    final sources = <String, String>{
      'lib/legacy_payload.dart': '''
typedef LegacyPayload = List<MapData>;
''',
      target.path: '''
import 'legacy_payload.dart';

class PersistentCombatCommandResolver {
  void resolve({
    required MapTileLookup mapTiles,
    required LegacyPayload payload,
  }) {}
}
''',
    };

    final violations = _violations(
      sources[target.path]!,
      target,
      mapDataTypeNames: mapDataBackedTypeNames(sources),
    );

    expect(
      violations,
      contains(
        'PersistentCombatCommandResolver.resolve must not expose MapData '
        'through parameter payload',
      ),
    );
  });

  test('guard rejects a wider WorldMap at a bounded lookup boundary', () {
    const target = _Target(
      path: 'lib/persistent_unit_detachment_resolver.dart',
      owner: 'PersistentUnitDetachmentResolver',
      boundaries: [
        _Boundary.method(
          'detachTroop',
          parameter: 'mapTiles',
          type: 'MapTileLookup',
        ),
      ],
    );

    final violations = _violations('''
class PersistentUnitDetachmentResolver {
  void detachTroop({required WorldMap mapTiles}) {}
}
''', target);

    expect(
      violations,
      contains(
        'PersistentUnitDetachmentResolver.detachTroop.mapTiles must have '
        'type MapTileLookup; found WorldMap',
      ),
    );
  });

  test('guard rejects a second map dependency beside a bounded lookup', () {
    const target = _Target(
      path: 'lib/persistent_unit_detachment_resolver.dart',
      owner: 'PersistentUnitDetachmentResolver',
      boundaries: [
        _Boundary.method(
          'detachTroop',
          parameter: 'mapTiles',
          type: 'MapTileLookup',
        ),
      ],
    );

    final violations = _violations('''
class PersistentUnitDetachmentResolver {
  void detachTroop({
    required MapTileLookup mapTiles,
    required WorldMap worldMap,
    required MapSurvey survey,
  }) {}
}
''', target);

    expect(
      violations,
      containsAll([
        'PersistentUnitDetachmentResolver.detachTroop must not expose an '
            'additional map dependency through parameter worldMap',
        'PersistentUnitDetachmentResolver.detachTroop must not expose an '
            'additional map dependency through parameter survey',
      ]),
    );
  });

  test('guard rejects an aliased second map dependency', () {
    const target = _Target(
      path: 'lib/persistent_unit_detachment_resolver.dart',
      owner: 'PersistentUnitDetachmentResolver',
      boundaries: [
        _Boundary.method(
          'detachTroop',
          parameter: 'mapTiles',
          type: 'MapTileLookup',
        ),
      ],
    );
    final sources = <String, String>{
      'lib/canonical_map.dart': 'typedef CanonicalMap = WorldMap;',
      target.path: '''
class PersistentUnitDetachmentResolver {
  void detachTroop({
    required MapTileLookup mapTiles,
    required CanonicalMap worldMap,
  }) {}
}
''',
    };

    final violations = _violations(
      sources[target.path]!,
      target,
      mapBoundaryTypeNames: typeNamesBackedBy(
        sources,
        _mapBoundaryRootTypeNames,
      ),
    );

    expect(
      violations,
      contains(
        'PersistentUnitDetachmentResolver.detachTroop must not expose an '
        'additional map dependency through parameter worldMap',
      ),
    );
  });

  test(
    'guard checks an unnamed redirecting factory without generated fields',
    () {
      const target = _Target(
        path: 'lib/turn_context.dart',
        owner: 'TurnContext',
        boundaries: [
          _Boundary.constructor(
            '',
            parameter: 'mapTiles',
            type: 'MapTileLookup',
            requireField: false,
          ),
        ],
      );

      final violations = _violations('''
abstract class TurnContext {
  const factory TurnContext({required MapReadView mapTiles}) = _TurnContext;
}
''', target);

      expect(
        violations,
        contains(
          'TurnContext.<unnamed>.mapTiles must have type MapTileLookup; '
          'found MapReadView',
        ),
      );
    },
  );
}
