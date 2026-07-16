import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';

part 'support/world_map_combat_boundary_fixtures.dart';

const _targets = [
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/trade/'
        'persistent_resource_trade_resolver.dart',
    owner: 'PersistentResourceTradeResolver',
    boundaries: [
      _Boundary.method(
        'openGoldForResourceTrade',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'openResourceForResourceTrade',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/diplomacy/resource_trade_reducer.dart',
    owner: 'ResourceTradeReducer',
    boundaries: [
      _Boundary.method(
        'openTrade',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'openExchange',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/city/city_founding_reducer.dart',
    owner: 'CityFoundingReducer',
    boundaries: [
      _Boundary.method(
        'startCityFounding',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'toggleControlledHex',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'confirmCityFounding',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/city/city_expansion_reducer.dart',
    owner: 'CityExpansionReducer',
    boundaries: [
      _Boundary.method(
        'selectExpansionHex',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_isCandidate',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/city_selection_projector.dart',
    owner: 'CitySelectionProjector',
    boundaries: [
      _Boundary.method('project', parameter: 'mapTiles', type: 'MapTileLookup'),
    ],
  ),
  _Target(
    path:
        'lib/game/domain/reducer/game_state/'
        'game_state_reducer_taps.dart',
    owner: '_GameStateTapReducer',
    boundaries: [
      _Boundary.method(
        '_cityFoundingDraftTileTap',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_selectInspectionTileDuringResearch',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'lib/game/presentation/widgets/hud/city/'
        'hud_city_founding_availability.dart',
    owner: 'HudCityFoundingAvailability',
    boundaries: [
      _Boundary.method(
        'canStart',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'lib/game/presentation/widgets/hud/overlay/'
        'hud_overlay_frame.dart',
    owner: 'HudOverlayFrame',
    boundaries: [
      _Boundary.method(
        '_cityFoundingBlockedReason',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/worker/worker_reducer.dart',
    owner: 'WorkerReducer',
    boundaries: [
      _Boundary.method(
        'selectWorkerImprovement',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'confirmWorkerImprovement',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'cancelWorkerJob',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'assignWorkerToHex',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'cancelWorkerAssignment',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/research/research_reducer.dart',
    owner: 'ResearchReducer',
    boundaries: [
      _Boundary.method(
        'selectTechnology',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/turn/turn_reducer.dart',
    owner: 'TurnReducer',
    boundaries: [
      _Boundary.method(
        'focusNextPendingAction',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'focusTurnStartAction',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_turnStartProductionEffects',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_turnsRemainingForQueue',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_productionPerTurnForQueue',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'pendingTurnActionCount',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'pendingTurnActionTargets',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'currentPendingTurnActionIndex',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_focusUnitAction',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_focusPendingTurnAction',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_focusCityProductionAction',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_pendingTurnActions',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/turn/end_turn_reducer.dart',
    owner: 'EndTurnReducer',
    boundaries: [
      _Boundary.method(
        'advanceCitiesForPlayer',
        parameter: 'mapView',
        type: 'MapReadView',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/combat/combat_reducer.dart',
    owner: 'CombatReducer',
    boundaries: [
      _Boundary.method(
        'selectAttackTarget',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'attackHex',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_attackCity',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_recordIntent',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_clearAttackInteractionState',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_refreshSelection',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_refreshUnit',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/combat/combat_reducer_setup.dart',
    owner: '_CombatSetupFactory',
    boundaries: [
      _Boundary.method(
        'unitAttackSetup',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'cityAttackSetup',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'defenseSetup',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        '_attackerCombatSetup',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/combat/combat_reducer_fog.dart',
    owner: '_CombatFogPolicy',
    boundaries: [
      _Boundary.method(
        'recomputeAfterCombat',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/turn/turn_context.dart',
    owner: 'TurnContext',
    boundaries: [
      _Boundary.constructor(
        '',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
        requireField: false,
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/unit/unit_attachment_reducer.dart',
    owner: 'UnitAttachmentReducer',
    boundaries: [
      _Boundary.method(
        'detachTroop',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/reducer/interaction/selection_reducer.dart',
    owner: 'SelectionReducer',
    boundaries: [
      _Boundary.method(
        'selectTile',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'selectUnit',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'selectCity',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'handleTileTapped',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'handleCityTapped',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/turn/persistent_turn_combat_resolver.dart',
    owner: 'PersistentTurnCombatResolver',
    boundaries: [
      _Boundary.method(
        'resolve',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
        nullable: true,
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/combat/persistent_combat_command_resolver.dart',
    owner: 'PersistentCombatCommandResolver',
    boundaries: [
      _Boundary.method('resolve', parameter: 'mapTiles', type: 'MapTileLookup'),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/turn/persistent_turn_pipeline.dart',
    owner: 'PersistentTurnPipelineRequest',
    boundaries: [
      _Boundary.constructor(
        'simultaneousFinalize',
        parameter: 'mapView',
        type: 'MapReadView',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/turn/persistent_turn_pipeline.dart',
    owner: 'PersistentTurnPipeline',
    boundaries: [
      _Boundary.method(
        'advancePlayer',
        parameter: 'mapView',
        type: 'MapReadView',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/movement/persistent_move_unit_resolver.dart',
    owner: 'PersistentMoveUnitResolver',
    boundaries: [
      _Boundary.method(
        'resolve',
        parameter: 'mapData',
        type: 'MapTraversalView',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/movement/'
        'persistent_merchant_trade_route_resolver.dart',
    owner: 'PersistentMerchantTradeRouteResolver',
    boundaries: [
      _Boundary.method(
        'assignRoute',
        parameter: 'mapData',
        type: 'MapTraversalView',
      ),
      _Boundary.method(
        'moveToCity',
        parameter: 'mapData',
        type: 'MapTraversalView',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/movement/persistent_unit_action_resolver.dart',
    owner: 'PersistentUnitActionResolver',
    boundaries: [
      _Boundary.method(
        'autoExploreUnit',
        parameter: 'mapData',
        type: 'MapTraversalView',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/unit/persistent_unit_detachment_resolver.dart',
    owner: 'PersistentUnitDetachmentResolver',
    boundaries: [
      _Boundary.method(
        'detachTroop',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/persistent_city_founding_resolver.dart',
    owner: 'PersistentCityFoundingResolver',
    boundaries: [
      _Boundary.method(
        'foundCity',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/'
        'city_initial_territory_selector.dart',
    owner: 'CityInitialTerritorySelector',
    boundaries: [
      _Boundary.method('select', parameter: 'mapTiles', type: 'MapTileLookup'),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/persistent_city_expansion_resolver.dart',
    owner: 'PersistentCityExpansionResolver',
    boundaries: [
      _Boundary.method(
        'selectExpansionHex',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/persistent_worker_command_resolver.dart',
    owner: 'PersistentWorkerCommandResolver',
    boundaries: [
      _Boundary.method(
        'selectWorkerImprovement',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'confirmWorkerImprovement',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'assignWorkerToHex',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/persistent_city_production_resolver.dart',
    owner: 'PersistentCityProductionResolver',
    boundaries: [
      _Boundary.method(
        'startBuilding',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'startUnitProduction',
        parameter: 'mapView',
        type: 'MapReadView',
      ),
      _Boundary.method(
        'startWonder',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'rushProduction',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/technology/persistent_research_command_resolver.dart',
    owner: 'PersistentResearchCommandResolver',
    boundaries: [
      _Boundary.method(
        'selectTechnology',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
        nullable: true,
      ),
    ],
  ),
];

void main() {
  test('migrated gameplay boundaries declare canonical map APIs', () {
    final sources = productionDartSources();
    final mapDataTypeNames = mapDataBackedTypeNames(sources);
    final mapBoundaryTypeNames = typeNamesBackedBy(
      sources,
      _mapBoundaryRootTypeNames,
    );
    for (final target in _targets) {
      expect(
        _violations(
          File(target.path).readAsStringSync(),
          target,
          mapDataTypeNames: mapDataTypeNames,
          mapBoundaryTypeNames: mapBoundaryTypeNames,
        ),
        isEmpty,
        reason: target.path,
      );
    }
  });

  _registerWorldMapCombatBoundaryFixtures();
}

List<String> _violations(
  String source,
  _Target target, {
  Set<String> mapDataTypeNames = const {'MapData'},
  Set<String> mapBoundaryTypeNames = _mapBoundaryRootTypeNames,
}) {
  final unit = parseString(content: source, path: target.path).unit;
  final owner = unit.declarations.whereType<ClassDeclaration>().where(
    (declaration) => declaration.namePart.typeName.lexeme == target.owner,
  );
  final violations = <String>[];
  if (owner.length != 1) {
    return ['${target.owner} must declare exactly one class'];
  }

  for (final boundary in target.boundaries) {
    _checkBoundary(
      owner.single,
      boundary,
      violations,
      mapDataTypeNames: mapDataTypeNames,
      mapBoundaryTypeNames: mapBoundaryTypeNames,
    );
  }
  if (_namedTypes(unit).contains('MapDefinition')) {
    violations.add('must not reference MapDefinition');
  }
  final importsMapDefinition = unit.directives
      .whereType<ImportDirective>()
      .map((directive) => directive.uri.stringValue)
      .any((uri) => uri != null && uri.endsWith('map_definition.dart'));
  if (importsMapDefinition) {
    violations.add('must not import map_definition.dart');
  }
  return violations;
}

void _checkBoundary(
  ClassDeclaration owner,
  _Boundary boundary,
  List<String> violations, {
  required Set<String> mapDataTypeNames,
  required Set<String> mapBoundaryTypeNames,
}) {
  final member = _memberFor(owner, boundary);
  final boundaryName = boundary.name.isEmpty ? '<unnamed>' : boundary.name;
  final memberLabel = '${owner.namePart.typeName.lexeme}.$boundaryName';
  if (member == null) {
    violations.add('$memberLabel must declare a public ${boundary.kind.label}');
    return;
  }

  final parameters = _parametersFor(member);
  if (parameters == null) {
    violations.add('$memberLabel must declare a parameter list');
    return;
  }
  final parameter = _parameterFor(parameters, boundary.parameter);
  if (parameter == null) {
    violations.add(
      '$memberLabel must declare a ${boundary.parameter} parameter',
    );
  } else {
    final parameterType = _parameterType(parameter, owner);
    _checkBoundaryType(
      label: '$memberLabel.${boundary.parameter}',
      type: parameterType,
      expectedType: boundary.type,
      nullable: boundary.nullable,
      violations: violations,
    );
  }

  for (final parameter in parameters.parameters) {
    final normalized = _unwrap(parameter);
    final parameterName = normalized.name?.lexeme ?? '<unnamed>';
    if (_containsAnyNamedType(
      _parameterType(normalized, owner),
      mapDataTypeNames,
    )) {
      violations.add(
        '$memberLabel must not expose MapData through parameter '
        '$parameterName',
      );
    }
    if (parameterName != boundary.parameter &&
        _containsAnyNamedType(
          _parameterType(normalized, owner),
          mapBoundaryTypeNames,
        )) {
      violations.add(
        '$memberLabel must not expose an additional map dependency through '
        'parameter $parameterName',
      );
    }
  }

  if (boundary.kind == _BoundaryKind.constructor && boundary.requireField) {
    final field = _fieldFor(owner, boundary.parameter);
    final fieldLabel =
        '${owner.namePart.typeName.lexeme}.${boundary.parameter} field';
    if (field == null) {
      violations.add('$fieldLabel must be declared');
      return;
    }
    final fieldType = _fieldType(owner, boundary.parameter);
    _checkBoundaryType(
      label: fieldLabel,
      type: fieldType,
      expectedType: boundary.type,
      nullable: boundary.nullable,
      violations: violations,
    );
    if (_containsAnyNamedType(fieldType, mapDataTypeNames)) {
      violations.add('$fieldLabel must not expose MapData');
    }
  }
}

const _mapBoundaryRootTypeNames = {
  'MapData',
  'MapDefinition',
  'MapSurvey',
  'MapTileCatalog',
  'MapTileLookup',
  'MapTileSource',
  'MapTraversalView',
  'MapReadView',
  'WorldMap',
  'WorldMapReadView',
};

AstNode? _memberFor(ClassDeclaration owner, _Boundary boundary) {
  for (final member in owner.body.members) {
    if (boundary.kind == _BoundaryKind.method &&
        member is MethodDeclaration &&
        member.name.lexeme == boundary.name) {
      return member;
    }
    if (boundary.kind == _BoundaryKind.constructor &&
        member is ConstructorDeclaration &&
        (boundary.name.isEmpty
            ? member.name == null
            : member.name?.lexeme == boundary.name)) {
      return member;
    }
  }
  return null;
}

FormalParameterList? _parametersFor(AstNode member) {
  return switch (member) {
    MethodDeclaration(:final parameters) => parameters,
    ConstructorDeclaration(:final parameters) => parameters,
    _ => throw ArgumentError.value(member, 'member'),
  };
}

FormalParameter? _parameterFor(FormalParameterList parameters, String name) {
  for (final parameter in parameters.parameters) {
    final normalized = _unwrap(parameter);
    if (normalized.name?.lexeme == name) return normalized;
  }
  return null;
}

FormalParameter _unwrap(FormalParameter parameter) {
  return parameter is DefaultFormalParameter ? parameter.parameter : parameter;
}

TypeAnnotation? _parameterType(
  FormalParameter parameter,
  ClassDeclaration owner,
) {
  final normalized = _unwrap(parameter);
  return switch (normalized) {
    SimpleFormalParameter(:final type) => type,
    FieldFormalParameter(:final type, :final name) =>
      type ?? _fieldType(owner, name.lexeme),
    _ => null,
  };
}

VariableDeclaration? _fieldFor(ClassDeclaration owner, String name) {
  for (final member in owner.body.members.whereType<FieldDeclaration>()) {
    for (final field in member.fields.variables) {
      if (field.name.lexeme == name) return field;
    }
  }
  return null;
}

TypeAnnotation? _fieldType(ClassDeclaration owner, String name) {
  final field = _fieldFor(owner, name);
  final parent = field?.parent;
  return parent is VariableDeclarationList ? parent.type : null;
}

void _checkBoundaryType({
  required String label,
  required TypeAnnotation? type,
  required String expectedType,
  required bool nullable,
  required List<String> violations,
}) {
  final expected = nullable ? '$expectedType?' : expectedType;
  if (!_isExpectedType(type, expectedType, nullable)) {
    violations.add('$label must have type $expected; found ${_typeName(type)}');
  }
}

bool _isExpectedType(TypeAnnotation? type, String expectedType, bool nullable) {
  return _isNamedType(type, expectedType) &&
      (type?.question != null) == nullable;
}

bool _isNamedType(TypeAnnotation? type, String name) {
  return type is NamedType &&
      type.name.lexeme == name &&
      type.typeArguments == null;
}

bool _containsAnyNamedType(TypeAnnotation? type, Set<String> names) {
  return type != null && _namedTypes(type).any(names.contains);
}

String _typeName(TypeAnnotation? type) => type?.toSource() ?? '<inferred>';

Set<String> _namedTypes(AstNode node) {
  final types = <String>{};
  node.accept(_NamedTypeCollector(types));
  return types;
}

final class _NamedTypeCollector extends RecursiveAstVisitor<void> {
  _NamedTypeCollector(this.types);

  final Set<String> types;

  @override
  void visitNamedType(NamedType node) {
    types.add(node.name.lexeme);
    super.visitNamedType(node);
  }
}

enum _BoundaryKind {
  method('method'),
  constructor('constructor');

  const _BoundaryKind(this.label);

  final String label;
}

final class _Boundary {
  const _Boundary.method(
    this.name, {
    required this.parameter,
    required this.type,
    this.nullable = false,
  }) : kind = _BoundaryKind.method,
       requireField = false;

  const _Boundary.constructor(
    this.name, {
    required this.parameter,
    required this.type,
    this.requireField = true,
  }) : kind = _BoundaryKind.constructor,
       nullable = false;

  final _BoundaryKind kind;
  final String name;
  final String parameter;
  final String type;
  final bool nullable;
  final bool requireField;
}

final class _Target {
  const _Target({
    required this.path,
    required this.owner,
    required this.boundaries,
  });

  final String path;
  final String owner;
  final List<_Boundary> boundaries;
}
