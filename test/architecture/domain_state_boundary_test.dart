import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

const _domainStatePath =
    'packages/aonw_core/lib/game/domain/state/domain_state.dart';
const _canonicalSnapshotPath =
    'packages/aonw_core/lib/game/domain/state/canonical_game_snapshot.dart';
const _clientStatePath = 'lib/game/domain/game_state.dart';

void main() {
  group('one canonical state boundary', () {
    test('removed aggregate and session state models cannot return', () {
      for (final path in const [
        'packages/aonw_core/lib/game/domain/state/persistent_game_state.dart',
        'packages/aonw_core/lib/game/domain/state/match_session_state.dart',
        'packages/aonw_core/lib/game/domain/runtime/game_runtime_state.dart',
        'packages/aonw_core/lib/game/compatibility/legacy_game_snapshot_adapter.dart',
        'lib/game/domain/game_state_conversions.dart',
      ]) {
        expect(File(path).existsSync(), isFalse, reason: path);
      }

      expect(_legacyStateReferences(), isEmpty);
    });

    test('DomainState owns all authoritative rule and lifecycle fields', () {
      final unit = _unitAt(_domainStatePath);
      final state = _classNamed(unit, 'DomainState');
      final actionState = _classNamed(unit, 'DomainActionState');

      expect(state.finalKeyword, isNotNull);
      expect(actionState.finalKeyword, isNotNull);
      expect(_publicFields(state), {
        'turn': 'int',
        'matchRules': 'MatchRules',
        'participants': 'List<Player>',
        'gameMode': 'GameMode',
        'turnStatesByPlayerId': 'Map<String, PlayerTurnState>',
        'submittedPlayerIds': 'Set<String>',
        'timeoutStreaksByPlayerId': 'Map<String, int>',
        'afkPlayerIds': 'Set<String>',
        'kickedPlayerIds': 'Set<String>',
        'turnStartedAt': 'DateTime?',
        'actions': 'DomainActionState',
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
      });
      expect(_publicFields(actionState), {
        'cityFoundingDraft': 'CityFoundingDraft?',
        'pendingAction': 'PendingPlayerAction?',
      });
      for (final field in [
        ...state.body.members.whereType<FieldDeclaration>(),
        ...actionState.body.members.whereType<FieldDeclaration>(),
      ]) {
        if (field.isStatic) continue;
        expect(field.fields.isFinal, isTrue, reason: field.toSource());
      }
    });

    test('CanonicalGameSnapshot has exactly one domain and one offset', () {
      final snapshot = _classNamed(
        _unitAt(_canonicalSnapshotPath),
        'CanonicalGameSnapshot',
      );

      expect(snapshot.finalKeyword, isNotNull);
      expect(_publicFields(snapshot), {
        'domain': 'DomainState',
        'metadata': 'GameSnapshotMetadata',
        'eventLogOffset': 'int',
      });
      expect(
        _identifierNames(snapshot).intersection(const {
          'session',
          'interaction',
          'runtimeState',
          'persistentState',
        }),
        isEmpty,
      );
    });

    test('client state composes DomainState and InteractionState only', () {
      final unit = _unitAt(_clientStatePath);
      final client = _classNamed(unit, 'GameClientState');
      final interaction = _classNamed(unit, 'InteractionState');

      expect(client.finalKeyword, isNotNull);
      expect(_publicFields(client), containsPair('domain', 'DomainState'));
      expect(
        _publicFields(client),
        containsPair('interaction', 'InteractionState'),
      );
      expect(
        _publicFields(client).values.toSet().intersection(const {
          'List<GameUnit>',
          'List<GameCity>',
          'FogOfWarState',
          'ResearchState',
          'DiplomacyState',
        }),
        isEmpty,
      );
      expect(interaction.finalKeyword, isNotNull);
    });

    test('recipient projections cannot enter the engine', () {
      final violations = <String>[];
      for (final entry in _dartSourcesUnder(
        'packages/aonw_core/lib/game/application/engine',
      ).entries) {
        final names = _namedTypes(_unit(entry.key, entry.value));
        if (names.contains('RecipientSnapshot')) violations.add(entry.key);
      }
      expect(violations, isEmpty);
    });
  });
}

List<String> _legacyStateReferences() {
  const forbidden = {
    'PersistentGameState',
    'GameRuntimeState',
    'MatchSessionState',
    'LegacyGameSnapshotAdapter',
    'GameState',
  };
  final violations = <String>[];
  for (final root in const [
    'lib',
    'packages/aonw_core/lib',
    'packages/aonw_core/tool',
    'server/lib',
    'tool',
  ]) {
    for (final entry in _dartSourcesUnder(root).entries) {
      final unit = _unit(entry.key, entry.value);
      final names = {
        ..._namedTypes(unit),
        for (final declaration
            in unit.declarations.whereType<ClassDeclaration>())
          declaration.namePart.typeName.lexeme,
      };
      final found = names.intersection(forbidden);
      if (found.isNotEmpty) violations.add('${entry.key}: $found');
    }
  }
  return violations;
}

Map<String, String> _dartSourcesUnder(String root) {
  final directory = Directory(root);
  if (!directory.existsSync()) return const {};
  return {
    for (final entity in directory.listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        entity.path: entity.readAsStringSync(),
  };
}

CompilationUnit _unitAt(String path) =>
    _unit(path, File(path).readAsStringSync());

CompilationUnit _unit(String path, String source) =>
    parseString(content: source, path: path).unit;

ClassDeclaration _classNamed(CompilationUnit unit, String name) => unit
    .declarations
    .whereType<ClassDeclaration>()
    .singleWhere((declaration) => declaration.namePart.typeName.lexeme == name);

Map<String, String> _publicFields(ClassDeclaration declaration) => {
  for (final field in declaration.body.members.whereType<FieldDeclaration>())
    if (!field.isStatic)
      for (final variable in field.fields.variables)
        if (!variable.name.lexeme.startsWith('_'))
          variable.name.lexeme: field.fields.type?.toSource() ?? 'dynamic',
};

Set<String> _namedTypes(AstNode node) {
  final names = <String>{};
  node.accept(_NamedTypeCollector(names));
  return names;
}

Set<String> _identifierNames(AstNode node) {
  final names = <String>{};
  node.accept(_IdentifierCollector(names));
  return names;
}

final class _NamedTypeCollector extends RecursiveAstVisitor<void> {
  _NamedTypeCollector(this.names);

  final Set<String> names;

  @override
  void visitNamedType(NamedType node) {
    names.add(node.name.lexeme);
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
