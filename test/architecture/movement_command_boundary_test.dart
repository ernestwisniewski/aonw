import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/movement_command_boundary_guard.dart';
import 'support/movement_instance_reference_guard.dart';
import 'support/movement_kernel_import_graph_guard.dart';
import 'support/movement_server_part_guard.dart';
import 'support/movement_visibility_boundary_guard.dart';
import 'support/static_member_reference_guard.dart';

void main() {
  _registerProductionBoundaryTests();
  _registerAdversarialGuardTests();
}

void _registerProductionBoundaryTests() {
  test('movement paths share exactly one state-neutral command kernel', () {
    final sources = movementRuntimeSources(productionDartSources());

    expect(
      movementInstanceMemberReferenceCountsByPath(
        sources,
        'MovementCommandResolver',
        'resolve',
      ),
      const {movementDomainAdapterPath: 1, movementAutoExploreKernelPath: 1},
      reason: 'Unexpected MovementCommandResolver.resolve call-sites.',
    );
    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'MovementCommandResolver',
        'resolve',
      ),
      isEmpty,
      reason: 'MovementCommandResolver.resolve must remain an instance API.',
    );
  });

  test('canonical movement adapter has one reviewed engine consumer', () {
    final sources = movementRuntimeSources(productionDartSources());

    expect(
      movementInstanceMemberReferenceCountsByPath(
        sources,
        'DomainMoveUnitResolver',
        'resolve',
      ),
      const {
        'packages/aonw_core/lib/game/application/engine/'
                'movement_engine_handler.dart':
            1,
      },
      reason: 'The domain adapter must have one GameEngine composition point.',
    );
    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'DomainMoveUnitResolver',
        'resolve',
      ),
      isEmpty,
      reason: 'DomainMoveUnitResolver must not gain a static entry point.',
    );
  });

  test('movement kernel has an exact bounded API and closed import graph', () {
    final sources = productionDartSources();
    expect(movementPublicApiViolations(sources), isEmpty);

    final forbiddenTypes = typeNamesBackedBy(
      sources,
      movementKernelForbiddenRootTypes,
    );
    final graph = movementKernelImportGraph(sources, movementKernelRootPaths);
    expect(
      movementKernelImportGraphViolations(
        graph,
        expectedPaths: movementKernelImportGraphPaths,
        forbiddenTypes: forbiddenTypes,
      ),
      isEmpty,
      reason:
          'Every reachable movement-kernel helper must remain bounded and '
          'state-container neutral.',
    );
  });

  test('movement execution owns an immutable renderer-neutral path', () {
    final sources = productionDartSources();
    expect(
      movementExecutionShapeViolations(sources[movementExecutionPath]),
      isEmpty,
    );
  });

  test('manual movement has exactly one visibility rule in core', () {
    expect(
      movementVisibilityBoundaryViolations(productionDartSources()),
      isEmpty,
    );
  });
}

void _registerAdversarialGuardTests() {
  test('kernel call-site guard catches aliases, tear-offs, and duplicates', () {
    final sources = <String, String>{
      'direct.dart': '''
void apply() => const MovementCommandResolver().resolve();
''',
      'alias.dart': '''
typedef MoveKernel = MovementCommandResolver;
final makeKernel = MoveKernel.new;
void apply() => makeKernel().resolve();
''',
      'prefixed.dart': '''
void apply() => const core.MovementCommandResolver().resolve();
''',
      'tear_off.dart': '''
final resolver = MovementCommandResolver();
final applyMove = resolver.resolve;
''',
      'duplicate.dart': '''
final resolver = MovementCommandResolver();
void applyOnce() => resolver.resolve();
final applyAgain = resolver.resolve;
''',
      'static.dart': '''
final applyMove = MovementCommandResolver.resolve;
''',
    };

    expect(
      movementInstanceMemberReferenceCountsByPath(
        sources,
        'MovementCommandResolver',
        'resolve',
      ),
      const {
        'direct.dart': 1,
        'alias.dart': 1,
        'prefixed.dart': 1,
        'tear_off.dart': 1,
        'duplicate.dart': 2,
      },
    );
    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'MovementCommandResolver',
        'resolve',
      ),
      const {'static.dart': 1},
    );
  });

  test('execution shape rejects a borrowed mutable path', () {
    final violations = movementExecutionShapeViolations('''
final class MovementCommandExecution {
  MovementCommandExecution({
    required this.unitId,
    required this.fromCol,
    required this.fromRow,
    required Iterable<UnitMovementStep> steps,
  }) : steps = steps.toList();

  final String unitId;
  final int fromCol;
  final int fromRow;
  final List<UnitMovementStep> steps;
  UnitMovementStep get destination => steps.last;
}
''');

    expect(
      violations,
      contains(
        'MovementCommandExecution must own an unmodifiable copy of steps',
      ),
    );
  });

  test('kernel graph catches an arbitrarily named stateful helper', () {
    const root = '${movementLibraryPath}fixture_resolver.dart';
    const helper = '${movementLibraryPath}stealth_rules.dart';
    final sources = <String, String>{
      root: '''
import 'package:aonw_core/game/domain/movement/stealth_rules.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/domain/world_map.dart';
WorldMap widen(WorldMap map) => map;
''',
      helper: '''
PersistentGameState leak(PersistentGameState state) => state;
''',
    };
    final graph = movementKernelImportGraph(sources, const {root});
    final violations = movementKernelImportGraphViolations(
      graph,
      expectedPaths: const {root},
      forbiddenTypes: const {'PersistentGameState', 'WorldMap'},
    );

    expect(graph.keys.toSet(), {root, helper});
    expect(
      violations.join('\n'),
      allOf(
        contains('unexpected movement-kernel graph path'),
        contains('PersistentGameState'),
        contains('WorldMap'),
        contains(
          'unapproved dependency package:aonw_core/game/domain/city.dart',
        ),
        contains(
          'unapproved dependency package:aonw_core/domain/world_map.dart',
        ),
      ),
    );
  });

  test('MapTileSource remains a pathfinder-only optimization leaf', () {
    const root = '${movementLibraryPath}fixture_resolver.dart';
    final sources = <String, String>{
      root: '''
import 'package:aonw_core/map/domain/map_tile_source.dart';
MapTileSource widen(MapTileSource source) => source;
''',
    };
    final graph = movementKernelImportGraph(sources, const {root});
    final violations = movementKernelImportGraphViolations(
      graph,
      expectedPaths: const {root},
      forbiddenTypes: const {},
    );

    expect(
      violations.join('\n'),
      allOf(
        contains('MapTileSource outside the pathfinder leaf'),
        contains(
          'unapproved dependency '
          'package:aonw_core/map/domain/map_tile_source.dart',
        ),
      ),
    );
  });

  test('visibility guard rejects a second root implementation', () {
    final violations = movementVisibilityBoundaryViolations({
      movementVisibilityPath: '''
abstract final class UnitMovementVisibilityRules {}
''',
      movementLegacyVisibilityPath: '''
abstract final class UnitMovementVisibilityRules {}
''',
      'lib/game/domain/movement.dart': '''
export 'movement/unit_movement_visibility_rules.dart';
''',
    });

    expect(
      violations.join('\n'),
      allOf(
        contains('declared exactly once in core'),
        contains('legacy root visibility rules file must be removed'),
        contains('all visibility-rule directives must resolve to the core'),
      ),
    );
  });

  test('server part guard rejects aliased and widened map contracts', () {
    expect(movementServerPartViolations(_serverFixture()), isEmpty);

    final aliased = movementServerPartViolations(
      _serverFixture(mapType: 'TraversalAlias', includeAlias: true),
    );
    expect(
      aliased,
      contains(
        '_applyMoveUnit must require exactly one bounded '
        'MapTraversalView mapView',
      ),
    );

    final widened = movementServerPartViolations(
      _serverFixture(extraMap: ', required MapReadView broadMap'),
    );
    expect(
      widened,
      contains(
        '_applyMoveUnit must require exactly one bounded '
        'MapTraversalView mapView',
      ),
    );
  });

  test('full-state bridge guard catches calls and tear-offs', () {
    const source = '''
void convert(dynamic state) {
  state.toPersistentState();
  final convertState = state.toPersistentState;
}
''';
    expect(_memberReferenceCount(source, 'toPersistentState'), 2);

    final types = typeNamesBackedBy(
      {
        'state.dart': 'class PersistentGameState {}',
        'alias.dart': 'typedef LegacyState = PersistentGameState;',
      },
      const {'PersistentGameState'},
    );
    expect(
      namedTypeReferencesInSource(
        'void bridge(LegacyState state) {}',
      ).intersection(types),
      {'LegacyState'},
    );
  });
}

Map<String, String> _serverFixture({
  String mapType = 'MapTraversalView',
  String extraMap = '',
  bool includeAlias = false,
}) => {
  movementServerReducerPath: '''
part 'server_command_reducer_movement.dart';
class ServerCommandReducer {}
''',
  movementServerCallSite:
      '''
part of 'server_command_reducer.dart';
extension _ServerCommandReducerMovement on ServerCommandReducer {
  _CommandApplication _applyMoveUnit({
    required $mapType mapView$extraMap,
  }) => throw UnimplementedError();
}
''',
  if (includeAlias)
    'aliases.dart': 'typedef TraversalAlias = MapTraversalView;',
};

int _memberReferenceCount(String source, String memberName) {
  final visitor = _NamedMemberReferenceCollector(memberName);
  parseString(content: source).unit.accept(visitor);
  return visitor.count;
}

final class _NamedMemberReferenceCollector extends RecursiveAstVisitor<void> {
  _NamedMemberReferenceCollector(this.memberName);

  final String memberName;
  int count = 0;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == memberName) count++;
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == memberName) count++;
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == memberName) count++;
    super.visitPropertyAccess(node);
  }
}
