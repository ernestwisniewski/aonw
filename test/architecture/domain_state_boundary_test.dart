import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';

const _domainStatePath =
    'packages/aonw_core/lib/game/domain/state/domain_state.dart';
const _sessionStatePath =
    'packages/aonw_core/lib/game/domain/state/match_session_state.dart';
const _metadataPath =
    'packages/aonw_core/lib/game/domain/state/game_snapshot_metadata.dart';

void main() {
  group('domain state boundaries', () {
    test('canonical state roots are exact final classes', () {
      const targets = {
        _domainStatePath: {'DomainState'},
        _sessionStatePath: {'MatchSessionState'},
        _metadataPath: {
          'GameSnapshotCamera',
          'WorldReference',
          'GameSnapshotMetadata',
        },
      };

      for (final entry in targets.entries) {
        final unit = _unitAt(entry.key);
        expect(
          _publicClassNames(unit),
          entry.value,
          reason: '${entry.key} exposes only its intended state roots',
        );
        for (final name in entry.value) {
          final declaration = _classNamed(unit, name);
          expect(declaration.finalKeyword, isNotNull, reason: '$name is final');
          expect(
            [
              declaration.abstractKeyword,
              declaration.baseKeyword,
              declaration.interfaceKeyword,
              declaration.mixinKeyword,
              declaration.sealedKeyword,
            ].whereType<Object>(),
            isEmpty,
            reason: '$name uses only the final class modifier',
          );
        }
      }
    });

    test('DomainState has the exact canonical rule-state surface', () {
      final state = _classNamed(_unitAt(_domainStatePath), 'DomainState');
      const expectedFields = {
        'turn': 'int',
        'matchRules': 'MatchRules',
        'participants': 'List<Player>',
        'playerGold': 'Map<String, int>',
        'playerWarWeariness': 'Map<String, int>',
        'playerStabilityNet': 'Map<String, int>',
        'units': 'List<GameUnit>',
        'cities': 'List<GameCity>',
        'artifacts': 'List<WorldArtifact>',
        'fieldImprovements': 'List<FieldImprovement>',
        'fogOfWar': 'FogOfWarState',
        'research': 'ResearchState',
        'wonderRegistry': 'WonderRegistry',
        'intendedAttacks': 'List<IntendedAttack>',
        'diplomacy': 'DiplomacyState',
        'resourceTradeAgreements': 'List<ResourceTradeAgreement>',
        'dominationHoldTurnsByPlayerId': 'Map<String, int>',
        'culturalVictoryHoldTurnsByPlayerId': 'Map<String, int>',
        'mapObjectiveHoldStatesByObjectiveId':
            'Map<String, MapObjectiveHoldState>',
      };
      const expectedDerivedGetters = {
        'playerColors': 'Map<String, int>',
        'playerCountries': 'Map<String, PlayerCountry>',
      };

      expect(_publicFields(state), expectedFields);
      expect(_publicDerivedGetters(state), expectedDerivedGetters);
      expect(_publicMethods(state), {'copyWith'});
    });

    test(
      'DomainState library excludes persistence, session, and interaction',
      () {
        for (final libraryUnit in _libraryUnitsAt(_domainStatePath)) {
          final forbiddenTypes = _namedTypes(
            libraryUnit.unit,
          ).where(_isForbiddenDomainType).toSet();
          final forbiddenNames = _identifierNames(
            libraryUnit.unit,
          ).where(_isForbiddenDomainName).toSet();
          final forbiddenImports = libraryUnit.unit.directives
              .whereType<ImportDirective>()
              .map((directive) => directive.uri.stringValue)
              .whereType<String>()
              .where(_isForbiddenDomainImport)
              .toSet();

          expect(
            forbiddenTypes,
            isEmpty,
            reason: '${libraryUnit.path} references forbidden state types',
          );
          expect(
            forbiddenNames,
            isEmpty,
            reason: '${libraryUnit.path} references session/interaction names',
          );
          expect(
            forbiddenImports,
            isEmpty,
            reason: '${libraryUnit.path} imports a forbidden state boundary',
          );
        }
      },
    );

    test('MatchSessionState contains only session collections', () {
      final state = _classNamed(
        _unitAt(_sessionStatePath),
        'MatchSessionState',
      );
      const expectedFields = {
        'gameMode': 'GameMode',
        'turnStatesByPlayerId': 'Map<String, PlayerTurnState>',
        'submittedPlayerIds': 'Set<String>',
        'timeoutStreaksByPlayerId': 'Map<String, int>',
        'afkPlayerIds': 'Set<String>',
        'kickedPlayerIds': 'Set<String>',
        'turnStartedAt': 'DateTime?',
      };

      expect(_publicFields(state), expectedFields);
      expect(
        _namedTypes(state).intersection(const {
          'DomainState',
          'PersistentGameState',
          'GameRuntimeState',
          'PlayerViewState',
          'MapData',
          'MatchRules',
          'GameUnit',
          'GameCity',
          'WorldArtifact',
          'FieldImprovement',
          'FogOfWarState',
          'ResearchState',
          'WonderRegistry',
          'IntendedAttack',
          'DiplomacyState',
          'ResourceTradeAgreement',
          'MapObjectiveHoldState',
        }),
        isEmpty,
      );
    });

    test('state roots reject public extensions and legacy imports', () {
      const roots = {
        'DomainState',
        'MatchSessionState',
        'GameSnapshotCamera',
        'WorldReference',
        'GameSnapshotMetadata',
      };

      expect(_productionRootExtensionViolations(roots), isEmpty);
      for (final path in const [_sessionStatePath, _metadataPath]) {
        for (final libraryUnit in _libraryUnitsAt(path)) {
          final forbiddenImports = libraryUnit.unit.directives
              .whereType<ImportDirective>()
              .map((directive) => directive.uri.stringValue)
              .whereType<String>()
              .where(_isForbiddenNeutralStateImport)
              .toSet();
          expect(
            forbiddenImports,
            isEmpty,
            reason: '${libraryUnit.path} imports a legacy state boundary',
          );
        }
      }
    });

    test('extension audit detects direct, prefixed, and aliased bypasses', () {
      final violations = _rootExtensionViolations(
        const {
          'alias.dart': 'typedef Alias = DomainState;',
          'leaks.dart': '''
extension DirectLeak on DomainState { void copyWith() {} }
extension DuplicateLeak on DomainState { void copyWith() {} }
extension PrefixedLeak on state.DomainState { int get savePayload => 1; }
extension AliasLeak on Alias { int get legacyState => 1; }
''',
        },
        const {'DomainState'},
      );

      expect(violations, hasLength(4));
      expect(violations.join('\n'), contains('DirectLeak'));
      expect(violations.join('\n'), contains('DuplicateLeak'));
      expect(violations.join('\n'), contains('PrefixedLeak'));
      expect(violations.join('\n'), contains('AliasLeak'));
    });
  });
}

CompilationUnit _unitAt(String path) {
  return parseString(content: File(path).readAsStringSync(), path: path).unit;
}

List<({String path, CompilationUnit unit})> _libraryUnitsAt(String entryPath) {
  final pending = <File>[File(entryPath).absolute];
  final visited = <String>{};
  final units = <({String path, CompilationUnit unit})>[];

  while (pending.isNotEmpty) {
    final file = pending.removeLast();
    if (!visited.add(file.path)) continue;

    final unit = _unitAt(file.path);
    units.add((path: file.path, unit: unit));
    for (final directive in unit.directives.whereType<PartDirective>()) {
      final partUri = directive.uri.stringValue;
      if (partUri == null) {
        throw StateError('Non-literal part URI in ${file.path}');
      }
      pending.add(File.fromUri(file.uri.resolve(partUri)));
    }
  }

  return units;
}

ClassDeclaration _classNamed(CompilationUnit unit, String name) {
  return unit.declarations.whereType<ClassDeclaration>().singleWhere(
    (declaration) => declaration.namePart.typeName.lexeme == name,
  );
}

Set<String> _publicClassNames(CompilationUnit unit) {
  return {
    for (final declaration in unit.declarations.whereType<ClassDeclaration>())
      if (!declaration.namePart.typeName.lexeme.startsWith('_'))
        declaration.namePart.typeName.lexeme,
  };
}

Map<String, String> _publicFields(ClassDeclaration declaration) {
  return {
    for (final field in declaration.body.members.whereType<FieldDeclaration>())
      for (final variable in field.fields.variables)
        if (!variable.name.lexeme.startsWith('_'))
          variable.name.lexeme: field.fields.type?.toSource() ?? 'dynamic',
  };
}

Map<String, String> _publicDerivedGetters(ClassDeclaration declaration) {
  return {
    for (final method
        in declaration.body.members.whereType<MethodDeclaration>())
      if (method.isGetter &&
          !method.name.lexeme.startsWith('_') &&
          method.name.lexeme != 'hashCode')
        method.name.lexeme: method.returnType?.toSource() ?? 'dynamic',
  };
}

Set<String> _publicMethods(ClassDeclaration declaration) {
  return {
    for (final method
        in declaration.body.members.whereType<MethodDeclaration>())
      if (!method.isGetter &&
          !method.isOperator &&
          !method.name.lexeme.startsWith('_'))
        method.name.lexeme,
  };
}

Set<String> _namedTypes(AstNode node) {
  final types = <String>{};
  node.accept(_NamedTypeCollector(types));
  return types;
}

Set<String> _identifierNames(AstNode node) {
  final names = <String>{};
  node.accept(_IdentifierCollector(names));
  return names;
}

List<String> _productionRootExtensionViolations(Set<String> roots) {
  return _rootExtensionViolations(productionDartSources(), roots);
}

List<String> _rootExtensionViolations(
  Map<String, String> sources,
  Set<String> roots,
) {
  final backedTypes = typeNamesBackedBy(sources, roots);
  final violations = <String>[];
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    for (final extension
        in unit.declarations.whereType<ExtensionDeclaration>()) {
      final receiver = extension.onClause?.extendedType;
      if (receiver is! NamedType ||
          !backedTypes.contains(receiver.name.lexeme)) {
        continue;
      }
      final extensionName = extension.name?.lexeme ?? '<anonymous>';
      for (final member in extension.body.members) {
        for (final memberName in _publicMemberNames(member)) {
          violations.add(
            '${entry.key}::$extensionName::$memberName::${member.toSource()}',
          );
        }
      }
    }
  }
  return violations;
}

Iterable<String> _publicMemberNames(ClassMember member) sync* {
  switch (member) {
    case MethodDeclaration(:final name):
      if (!name.lexeme.startsWith('_')) yield name.lexeme;
    case FieldDeclaration(:final fields):
      for (final variable in fields.variables) {
        if (!variable.name.lexeme.startsWith('_')) yield variable.name.lexeme;
      }
    default:
      break;
  }
}

bool _isForbiddenDomainType(String name) {
  const exactTypes = {
    'PersistentGameState',
    'GameRuntimeState',
    'PlayerViewState',
    'MapData',
    'MatchSessionState',
    'GameSave',
    'SaveSnapshot',
    'GameSnapshotMetadata',
    'CameraState',
    'GameSnapshotCamera',
    'GameMode',
    'PlayerTurnState',
    'GameInteractionState',
    'GameInteractionMode',
    'GameSelection',
    'UnitMovementPlan',
    'CityFoundingDraft',
    'PendingPlayerAction',
  };
  final normalized = name.toLowerCase();
  return exactTypes.contains(name) ||
      name.startsWith('Pending') ||
      normalized.contains('interaction') ||
      normalized.contains('session');
}

bool _isForbiddenDomainName(String name) {
  const exactNames = {
    'gameMode',
    'turnStatesByPlayerId',
    'playerStates',
    'submittedPlayerIds',
    'timeoutStreaksByPlayerId',
    'afkPlayerIds',
    'kickedPlayerIds',
    'turnStartedAt',
    'hasSubmitted',
    'isAfk',
    'isKicked',
    'cityFoundingDraft',
    'pendingAction',
    'selection',
    'movePreview',
    'moveCommandActive',
    'activePlayerId',
    'activePlayerCanAct',
  };
  final normalized = name.toLowerCase();
  return exactNames.contains(name) ||
      normalized.contains('interaction') ||
      normalized.contains('session');
}

bool _isForbiddenDomainImport(String uri) => _hasForbiddenImport(uri, const {
  ..._neutralStateImportStems,
  'game_snapshot_metadata',
  'game_mode',
});

bool _isForbiddenNeutralStateImport(String uri) =>
    _hasForbiddenImport(uri, _neutralStateImportStems);

const _neutralStateImportStems = {
  'persistent_game_state',
  'game_runtime_state',
  'player_view_state',
  'map_data',
  'match_session_state',
  'game_save',
  'save_snapshot',
  'camera_state',
};

bool _hasForbiddenImport(String uri, Set<String> forbiddenStems) {
  const boundarySegments = {
    'legacy',
    'presentation',
    'save',
    'runtime',
    'view',
  };
  final segments = Uri.parse(uri).pathSegments.map((segment) {
    final normalized = segment.toLowerCase();
    return normalized.endsWith('.dart')
        ? normalized.substring(0, normalized.length - '.dart'.length)
        : normalized;
  });
  return segments.any(
    (segment) =>
        boundarySegments.contains(segment) ||
        forbiddenStems.contains(segment) ||
        segment.contains('legacy'),
  );
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

final class _IdentifierCollector extends RecursiveAstVisitor<void> {
  _IdentifierCollector(this.names);

  final Set<String> names;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}
