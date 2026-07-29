import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';

const _commandLibraryPath =
    'packages/aonw_core/lib/game/domain/command/game_command.dart';
const _serializerPath =
    'packages/aonw_core/lib/game/domain/command/game_command_serialization.dart';

const _rolePolicy = <String, _CommandRole>{
  'AssignMerchantTradeRouteCommand': _CommandRole.domain,
  'AssignWorkerToHexCommand': _CommandRole.domain,
  'AttackHexCommand': _CommandRole.domain,
  'AutoExploreUnitCommand': _CommandRole.domain,
  'CancelAttackTargetingCommand': _CommandRole.intent,
  'CancelCityExpansionSelectionCommand': _CommandRole.intent,
  'CancelCityFoundingCommand': _CommandRole.intent,
  'CancelCityWorkedHexSelectionCommand': _CommandRole.intent,
  'CancelCommanderMergeSelectionCommand': _CommandRole.intent,
  'CancelMerchantMoveToCitySelectionCommand': _CommandRole.intent,
  'CancelMerchantTradeRouteSelectionCommand': _CommandRole.intent,
  'CancelResearchSelectionCommand': _CommandRole.intent,
  'CancelUnitActionCommand': _CommandRole.domain,
  'CancelWorkerActionSelectionCommand': _CommandRole.intent,
  'CancelWorkerAssignmentCommand': _CommandRole.domain,
  'CancelWorkerJobCommand': _CommandRole.domain,
  'CityTappedCommand': _CommandRole.intent,
  'ConfirmWorkerImprovementCommand': _CommandRole.domain,
  'DeclareWarCommand': _CommandRole.domain,
  'DetachTroopCommand': _CommandRole.domain,
  'EndTurnCommand': _CommandRole.domain,
  'FocusNextPendingActionCommand': _CommandRole.intent,
  'FocusTurnStartActionCommand': _CommandRole.intent,
  'FortifyUnitCommand': _CommandRole.domain,
  'FoundCityCommand': _CommandRole.domain,
  'MoveMerchantToCityCommand': _CommandRole.domain,
  'MoveUnitCommand': _CommandRole.domain,
  'OpenResourceExchangeCommand': _CommandRole.domain,
  'OpenResourceTradeCommand': _CommandRole.domain,
  'ResetUnitMovementCommand': _CommandRole.system,
  'RespondDiplomaticMessageCommand': _CommandRole.domain,
  'RespondDiplomaticProposalCommand': _CommandRole.domain,
  'RushProductionCommand': _CommandRole.domain,
  'SelectCityCommand': _CommandRole.intent,
  'SelectCityExpansionHexCommand': _CommandRole.domain,
  'SelectTechnologyCommand': _CommandRole.domain,
  'SelectTileCommand': _CommandRole.intent,
  'SelectUnitCommand': _CommandRole.intent,
  'SelectWorkerImprovementCommand': _CommandRole.domain,
  'SendDiplomaticMessageCommand': _CommandRole.domain,
  'SendDiplomaticProposalCommand': _CommandRole.domain,
  'SendGoldGiftCommand': _CommandRole.domain,
  'SetActivePlayerCommand': _CommandRole.system,
  'SetCitySpecializationCommand': _CommandRole.domain,
  'SkipUnitTurnCommand': _CommandRole.domain,
  'StartArtifactExcavationCommand': _CommandRole.domain,
  'StartAttackTargetingCommand': _CommandRole.intent,
  'StartBuildingCommand': _CommandRole.domain,
  'StartCityExpansionSelectionCommand': _CommandRole.intent,
  'StartCityFoundingCommand': _CommandRole.intent,
  'StartCityProjectCommand': _CommandRole.domain,
  'StartCityWorkedHexSelectionCommand': _CommandRole.intent,
  'StartCommanderMergeSelectionCommand': _CommandRole.intent,
  'StartMerchantMoveToCitySelectionCommand': _CommandRole.intent,
  'StartMerchantTradeRouteSelectionCommand': _CommandRole.intent,
  'StartUnitProductionCommand': _CommandRole.domain,
  'StartWonderCommand': _CommandRole.domain,
  'StartWorkerActionSelectionCommand': _CommandRole.intent,
  'StoreArtifactInCityCommand': _CommandRole.domain,
  'SubmitTurnCommand': _CommandRole.domain,
  'TileTappedCommand': _CommandRole.intent,
  'ToggleMoveTargetingCommand': _CommandRole.intent,
  'ToggleWorkedHexCommand': _CommandRole.domain,
  'TradeArtifactCommand': _CommandRole.domain,
};

void main() {
  test('every concrete game command has one explicit boundary role', () {
    final inventory = _GameCommandInventory.build(
      rolePolicy: _rolePolicy,
      sources: productionDartSources(),
    );

    expect(
      inventory.unclassifiedCommands,
      isEmpty,
      reason: 'Every GameCommand must be intent, domain, or system.',
    );
    expect(
      inventory.unknownPolicyCommands,
      isEmpty,
      reason: 'The role policy may only classify concrete GameCommand types.',
    );
    expect(inventory.commandsOutsideTypedRoot, isEmpty);
    expect(inventory.serializedIntents, isEmpty);
    expect(inventory.serializedSystemCommands, isEmpty);
  });

  test('inventory includes concrete indirect command subclasses', () {
    const rolePolicy = {'IndirectCommand': _CommandRole.domain};
    final inventory = _GameCommandInventory.build(
      rolePolicy: rolePolicy,
      sources: _indirectCommandFixtureSources,
    );

    expect(inventory.entries.map((entry) => entry.className), [
      'IndirectCommand',
    ]);
    expect(inventory.unclassifiedCommands, isEmpty);
    expect(inventory.unknownPolicyCommands, isEmpty);
  });

  test('inventory records semantic command dispatch paths', () {
    final inventory = _GameCommandInventory.build(
      rolePolicy: _rolePolicy,
      sources: productionDartSources(),
    );
    final submitTurn = inventory.entries.singleWhere(
      (entry) => entry.className == 'SubmitTurnCommand',
    );
    final moveUnit = inventory.entries.singleWhere(
      (entry) => entry.className == 'MoveUnitCommand',
    );

    expect(submitTurn.localHandlers, [
      'lib/game/domain/reducer/game_state/game_state_reducer.dart',
    ]);
    expect(submitTurn.serverHandlers, [
      'server/lib/src/multiplayer/server_command_reducer.dart',
    ]);
    expect(
      submitTurn.serverHandlers,
      isNot(
        contains('server/lib/src/multiplayer/match_command_service_event.dart'),
      ),
    );
    expect(
      moveUnit.aiConsumers,
      contains('packages/aonw_core/lib/ai/mcts/mcts_simulated_state.dart'),
    );
  });
}

const _indirectCommandFixtureSources = <String, String>{
  _commandLibraryPath: '''
part 'intermediate_command.dart';

sealed class GameCommand {
  const GameCommand();
}
''',
  'packages/aonw_core/lib/game/domain/command/intermediate_command.dart': '''
part of 'game_command.dart';

abstract class IntermediateCommand extends GameCommand {
  const IntermediateCommand();
}

final class IndirectCommand extends IntermediateCommand {
  const IndirectCommand();
}
''',
  _serializerPath: '',
};

enum _CommandRole { intent, domain, system }

final class _GameCommandInventory {
  const _GameCommandInventory({
    required this.entries,
    required this.rolePolicy,
  });

  factory _GameCommandInventory.build({
    required Map<String, _CommandRole> rolePolicy,
    required Map<String, String> sources,
  }) {
    final commandPaths = _commandLibraryPaths(sources[_commandLibraryPath]!);
    final declarations = _commandDeclarations(sources, commandPaths);
    final commandNames = _concreteGameCommandNames(declarations);
    final serializerNames = _identifiersIn(sources[_serializerPath]!);

    return _GameCommandInventory(
      entries: [
        for (final className in commandNames)
          _GameCommandInventoryEntry(
            className: className,
            role: rolePolicy[className],
            typedRoot: _typedRoot(className, declarations),
            serialized: serializerNames.contains(className),
            localHandlers: _semanticCommandPaths(
              sources,
              _commandHierarchyNames(className, declarations),
              pathPrefix: 'lib/game/domain/reducer/',
            ),
            serverHandlers: _semanticCommandPaths(
              sources,
              _commandHierarchyNames(className, declarations),
              pathPrefix: 'server/lib/src/multiplayer/',
            ),
            aiConsumers: _semanticCommandPaths(
              sources,
              _commandHierarchyNames(className, declarations),
              pathPrefix: 'packages/aonw_core/lib/ai/',
            ),
          ),
      ],
      rolePolicy: rolePolicy,
    );
  }

  final List<_GameCommandInventoryEntry> entries;
  final Map<String, _CommandRole> rolePolicy;

  List<String> get unclassifiedCommands => [
    for (final entry in entries)
      if (entry.role == null) entry.className,
  ];

  List<String> get unknownPolicyCommands => [
    for (final className in rolePolicy.keys)
      if (!entries.any((entry) => entry.className == className)) className,
  ]..sort();

  List<String> get serializedIntents => [
    for (final entry in entries)
      if (entry.role == _CommandRole.intent && entry.serialized)
        entry.className,
  ];

  List<String> get serializedSystemCommands => [
    for (final entry in entries)
      if (entry.role == _CommandRole.system && entry.serialized)
        entry.className,
  ];

  List<String> get commandsOutsideTypedRoot => [
    for (final entry in entries)
      if (entry.role != null && entry.typedRoot != entry.role!.typedRoot)
        '${entry.className}: ${entry.typedRoot ?? 'untyped'}',
  ];
}

final class _GameCommandInventoryEntry {
  const _GameCommandInventoryEntry({
    required this.className,
    required this.role,
    required this.typedRoot,
    required this.serialized,
    required this.localHandlers,
    required this.serverHandlers,
    required this.aiConsumers,
  });

  final String className;
  final _CommandRole? role;
  final String? typedRoot;
  final bool serialized;

  /// Reducer paths with an AST command pattern or `is` guard.
  final List<String> localHandlers;

  /// Multiplayer reducer paths with an AST command pattern or `is` guard.
  final List<String> serverHandlers;

  /// Core AI paths with an AST command pattern or `is` guard.
  final List<String> aiConsumers;
}

extension on _CommandRole {
  String get typedRoot => switch (this) {
    _CommandRole.intent => 'GameIntent',
    _CommandRole.domain => 'DomainCommand',
    _CommandRole.system => 'ServerSystemCommand',
  };
}

List<String> _commandLibraryPaths(String source) {
  final unit = parseString(content: source, path: _commandLibraryPath).unit;
  return [
    _commandLibraryPath,
    for (final directive in unit.directives.whereType<PartDirective>())
      'packages/aonw_core/lib/game/domain/command/${directive.uri.stringValue}',
  ];
}

Map<String, _CommandDeclaration> _commandDeclarations(
  Map<String, String> sources,
  List<String> commandPaths,
) {
  final declarations = <String, _CommandDeclaration>{};
  for (final path in commandPaths) {
    final unit = parseString(content: sources[path]!, path: path).unit;
    for (final declaration in unit.declarations.whereType<ClassDeclaration>()) {
      final name = declaration.namePart.typeName.lexeme;
      declarations[name] = _CommandDeclaration(
        name: name,
        parentName: declaration.extendsClause?.superclass.name.lexeme,
        isAbstract:
            declaration.abstractKeyword != null ||
            declaration.sealedKeyword != null,
      );
    }
  }
  return declarations;
}

List<String> _concreteGameCommandNames(
  Map<String, _CommandDeclaration> declarations,
) {
  final names = [
    for (final declaration in declarations.values)
      if (!declaration.isAbstract &&
          declaration.name != 'GameCommand' &&
          _isGameCommandSubclass(declaration.name, declarations, <String>{}))
        declaration.name,
  ]..sort();
  return names;
}

bool _isGameCommandSubclass(
  String className,
  Map<String, _CommandDeclaration> declarations,
  Set<String> visited,
) {
  if (!visited.add(className)) return false;
  final parentName = declarations[className]?.parentName;
  if (parentName == 'GameCommand') return true;
  if (parentName == null || !declarations.containsKey(parentName)) return false;
  return _isGameCommandSubclass(parentName, declarations, visited);
}

Set<String> _commandHierarchyNames(
  String className,
  Map<String, _CommandDeclaration> declarations,
) {
  final names = <String>{};
  String? currentName = className;
  while (currentName != null && names.add(currentName)) {
    currentName = declarations[currentName]?.parentName;
  }
  return names;
}

String? _typedRoot(
  String className,
  Map<String, _CommandDeclaration> declarations,
) {
  final hierarchy = _commandHierarchyNames(className, declarations);
  for (final root in const [
    'GameIntent',
    'DomainCommand',
    'ServerSystemCommand',
  ]) {
    if (hierarchy.contains(root)) return root;
  }
  return null;
}

List<String> _semanticCommandPaths(
  Map<String, String> sources,
  Set<String> commandTypeNames, {
  required String pathPrefix,
}) {
  final paths = <String>[];
  for (final entry in sources.entries) {
    if (entry.key.startsWith(pathPrefix) &&
        _dispatchTypeNamesIn(entry.value).any(commandTypeNames.contains)) {
      paths.add(entry.key);
    }
  }
  paths.sort();
  return paths;
}

final class _CommandDeclaration {
  const _CommandDeclaration({
    required this.name,
    required this.parentName,
    required this.isAbstract,
  });

  final String name;
  final String? parentName;
  final bool isAbstract;
}

Set<String> _identifiersIn(String source) {
  final identifiers = <String>{};
  parseString(content: source).unit.accept(_IdentifierCollector(identifiers));
  return identifiers;
}

Set<String> _dispatchTypeNamesIn(String source) {
  final typeNames = <String>{};
  parseString(
    content: source,
  ).unit.accept(_DispatchTypeNameCollector(typeNames));
  return typeNames;
}

final class _IdentifierCollector extends RecursiveAstVisitor<void> {
  _IdentifierCollector(this.identifiers);

  final Set<String> identifiers;

  @override
  void visitNamedType(NamedType node) {
    identifiers.add(node.name.lexeme);
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    identifiers.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}

/// Collects command types that influence a branch, not lexical references.
final class _DispatchTypeNameCollector extends RecursiveAstVisitor<void> {
  _DispatchTypeNameCollector(this.typeNames);

  final Set<String> typeNames;

  @override
  void visitObjectPattern(ObjectPattern node) {
    typeNames.add(node.type.name.lexeme);
    super.visitObjectPattern(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    if (node.type case NamedType(:final name)) typeNames.add(name.lexeme);
    super.visitIsExpression(node);
  }
}
