import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/save_snapshot_serialization_guard.dart';
import 'support/target_method_invocation_count.dart';

const _snapshotPath = 'lib/game/application/ports/save_snapshot.dart';
const _persistenceCodecPath =
    'lib/game/infrastructure/persistence/save_snapshot_codec.dart';
const _protocolCodecPath = 'lib/api/protocol/codecs.dart';
const _localResolverPath =
    'lib/game/application/services/local_command_resolver.dart';
const _localTransportPath =
    'lib/game/infrastructure/transport/local_command_transport.dart';
const _aiTurnPreparationBuilderPath =
    'lib/game/application/services/ai_turn_preparation_builder.dart';
const _bootstrapGameStatePath =
    'lib/game/application/use_cases/bootstrap_game_state_use_case.dart';
const _replayServicePath = 'lib/game/application/services/replay_service.dart';
const _replayControlSelectorsPath =
    'lib/game/presentation/screens/replay/replay_control_selectors.dart';
const _replayControlsPath =
    'lib/game/presentation/screens/replay/replay_controls.dart';
const _replayRendererHostPath =
    'lib/game/presentation/screens/replay/replay_renderer_host.dart';
const _replayRendererLifecyclePath =
    'lib/game/presentation/screens/replay/replay_renderer_host_lifecycle.dart';
const _canonicalSessionConsumerPaths = [
  _localResolverPath,
  'lib/api/transport/network_command_transport.dart',
  'lib/game/application/services/ai_plan_precompute_cache.dart',
  'lib/game/application/services/ai_strategic_plan_provider.dart',
  'lib/game/application/services/ai_recent_hostility_tracker.dart',
];

void main() {
  group('SaveSnapshot boundary', () {
    test('snapshot is final with one lazy canonical compatibility seam', () {
      final unit = _unitAt(_snapshotPath);
      final snapshot = unit.declarations
          .whereType<ClassDeclaration>()
          .singleWhere(
            (declaration) =>
                declaration.namePart.typeName.lexeme == 'SaveSnapshot',
          );
      final canonicalFields = snapshot.body.members
          .whereType<FieldDeclaration>()
          .where(
            (field) => field.fields.variables.any(
              (variable) => variable.name.lexeme == 'canonical',
            ),
          );
      final rawGetters = snapshot.body.members
          .whereType<MethodDeclaration>()
          .where(
            (method) =>
                method.isGetter && method.name.lexeme == 'rawPersistentState',
          );
      final fromCanonical = snapshot.body.members
          .whereType<ConstructorDeclaration>()
          .where(
            (constructor) =>
                constructor.factoryKeyword != null &&
                constructor.name?.lexeme == 'fromCanonical',
          );

      expect(snapshot.finalKeyword, isNotNull);
      expect(canonicalFields, hasLength(1));
      expect(canonicalFields.single.fields.isLate, isTrue);
      expect(rawGetters, hasLength(1));
      expect(fromCanonical, hasLength(1));
      expect(
        _namesIn(snapshot),
        containsAll(const {'metadata', 'domain', 'session', 'interaction'}),
      );
    });

    test('persistence and protocol codecs serialize only raw views', () {
      final violations = saveSnapshotSerializationBoundaryViolations(
        persistenceSource: File(_persistenceCodecPath).readAsStringSync(),
        protocolSource: File(_protocolCodecPath).readAsStringSync(),
      );

      expect(violations, isEmpty);
    });

    test('local resolver depends on snapshot boundary, not compatibility', () {
      final unit = _unitAt(_localResolverPath);
      final names = _namesIn(unit);
      final imports = unit.directives
          .whereType<UriBasedDirective>()
          .map((directive) => directive.uri.stringValue)
          .whereType<String>();

      expect(
        imports.where(
          (uri) =>
              uri.contains('/compatibility/') ||
              uri.endsWith('/compatibility.dart'),
        ),
        isEmpty,
      );
      expect(
        names.intersection(const {
          'LegacyGameSnapshotAdapter',
          'toCanonical',
          'toLegacy',
        }),
        isEmpty,
      );
      expect(names, containsAll(const {'SaveSnapshot', 'canonical'}));

      final resolution = unit.declarations
          .whereType<ClassDeclaration>()
          .singleWhere(
            (declaration) =>
                declaration.namePart.typeName.lexeme ==
                'LocalCommandResolution',
          );
      final resolutionFields = resolution.body.members
          .whereType<FieldDeclaration>()
          .expand((field) => field.fields.variables)
          .map((variable) => variable.name.lexeme);
      final resolutionSaveGetters = resolution.body.members
          .whereType<MethodDeclaration>()
          .where((method) => method.isGetter && method.name.lexeme == 'save');
      expect(resolutionFields, contains('snapshot'));
      expect(resolutionFields, isNot(contains('save')));
      expect(resolutionSaveGetters, isEmpty);
      expect(_targetPropertyReadCount(unit, 'baseSnapshot', 'save'), 0);
      expect(_targetPropertyReadCount(unit, 'baseSnapshot', 'domain'), 1);
      expect(_targetPropertyReadCount(unit, 'baseSnapshot', 'session'), 0);
      expect(
        targetMethodInvocationCount(unit, 'baseSnapshot', 'withSavedAt'),
        2,
      );
      expect(
        targetMethodInvocationCount(unit, 'baseSnapshot', 'withPlayerFinished'),
        0,
      );
      expect(
        _namesIn(unit),
        containsAll(const {'GameEngine', 'fromCanonical'}),
      );
    });

    test('local transport logs turns from the canonical snapshot', () {
      final unit = _unitAt(_localTransportPath);

      expect(_targetPropertyReadCount(unit, 'baseSnapshot', 'save'), 0);
      expect(_targetPropertyReadCount(unit, 'baseSnapshot', 'domain'), 1);
    });

    test('migrated consumers query canonical snapshot boundaries', () {
      for (final path in _canonicalSessionConsumerPaths) {
        final unit = _unitAt(path);
        if (path == _localResolverPath) {
          expect(
            _targetPropertyReadCount(unit, 'snapshot', 'runtimeState'),
            0,
            reason: path,
          );
          continue;
        }
        final names = _namesIn(unit);
        expect(names, isNot(contains('runtimeState')), reason: path);
      }
    });

    test('AI builder uses canonical and lossless snapshot APIs only', () {
      final unit = _unitAt(_aiTurnPreparationBuilderPath);
      expect(_propertyReadCount(unit, 'save'), 0);
      expect(_propertyReadCount(unit, 'runtimeState'), 0);
      expect(_propertyReadCount(unit, 'withGameState'), 1);
      expect(_propertyReadCount(unit, 'persistedTurnStartedAt'), 1);
      expect(_propertyReadCount(unit, 'metadata'), 2);
      expect(_propertyReadCount(unit, 'session'), 1);
      expect(_propertyReadCount(unit, 'domain'), 3);
    });

    test('bootstrap uses canonical player control inputs', () {
      final unit = _unitAt(_bootstrapGameStatePath);
      expect(_propertyReadCount(unit, 'save'), 0);
      expect(_propertyReadCount(unit, 'session'), 3);
      expect(_propertyReadCount(unit, 'domain'), 1);
    });

    test('replay read model ratchets initial snapshot legacy access', () {
      final unit = _unitAt(_replayServicePath);
      expect(_targetPropertyReadCount(unit, 'initialSnapshot', 'save'), 0);
      expect(_targetPropertyReadCount(unit, 'initialSnapshot', 'metadata'), 1);
      expect(_targetPropertyReadCount(unit, 'initialSnapshot', 'session'), 1);
      expect(_targetPropertyReadCount(unit, 'initialSnapshot', 'domain'), 2);
      expect(_namesIn(unit), isNot(contains('currentSave')));

      final replayStep = unit.declarations
          .whereType<ClassDeclaration>()
          .singleWhere(
            (declaration) =>
                declaration.namePart.typeName.lexeme == 'ReplayStep',
          );
      final replayStepFields = replayStep.body.members
          .whereType<FieldDeclaration>()
          .expand((field) => field.fields.variables)
          .map((variable) => variable.name.lexeme);
      final replayStepSaveGetters = replayStep.body.members
          .whereType<MethodDeclaration>()
          .where((method) => method.isGetter && method.name.lexeme == 'save');
      expect(replayStepFields, contains('snapshot'));
      expect(replayStepFields, isNot(contains('save')));
      expect(replayStepSaveGetters, isEmpty);

      final timeline = unit.declarations
          .whereType<ClassDeclaration>()
          .singleWhere(
            (declaration) =>
                declaration.namePart.typeName.lexeme == 'ReplayTimeline',
          );
      final lastTurn = timeline.body.members
          .whereType<MethodDeclaration>()
          .singleWhere((method) => method.name.lexeme == 'lastTurn');
      expect(_namesIn(lastTurn), contains('domain'));
      expect(_namesIn(lastTurn), isNot(contains('save')));
    });

    test('replay name and roster presentation use canonical read model', () {
      final selectors = _namesIn(_unitAt(_replayControlSelectorsPath));
      final controls = _unitAt(_replayControlsPath);
      final renderer = _namesIn(_unitAt(_replayRendererHostPath));
      final rendererLifecycle = _unitAt(_replayRendererLifecyclePath);
      expect(selectors, contains('participants'));
      expect(selectors, isNot(contains('save')));
      expect(_propertyReadCount(controls, 'save'), 0);
      expect(_propertyReadCount(controls, 'participants'), 2);
      expect(_namesIn(controls), contains('fromPlayers'));
      expect(renderer, contains('metadata'));
      expect(renderer, isNot(contains('save')));
      expect(_propertyReadCount(rendererLifecycle, 'save'), 0);
      expect(_propertyReadCount(rendererLifecycle, 'initialCamera'), 3);
    });
  });
}

CompilationUnit _unitAt(String path) {
  return parseString(content: File(path).readAsStringSync(), path: path).unit;
}

Set<String> _namesIn(AstNode node) {
  final collector = _NameCollector();
  node.accept(collector);
  return collector.names;
}

int _propertyReadCount(AstNode node, String propertyName) {
  final collector = _PropertyReadCollector(propertyName);
  node.accept(collector);
  return collector.count;
}

int _targetPropertyReadCount(
  AstNode node,
  String targetName,
  String propertyName,
) {
  final collector = _TargetPropertyReadCollector(targetName, propertyName);
  node.accept(collector);
  return collector.count;
}

final class _NameCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}

final class _PropertyReadCollector extends RecursiveAstVisitor<void> {
  _PropertyReadCollector(this.propertyName);

  final String propertyName;
  int count = 0;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == propertyName) count += 1;
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == propertyName) count += 1;
    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == propertyName) count += 1;
    super.visitMethodInvocation(node);
  }
}

final class _TargetPropertyReadCollector extends RecursiveAstVisitor<void> {
  _TargetPropertyReadCollector(this.targetName, this.propertyName);

  final String targetName;
  final String propertyName;
  int count = 0;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == targetName &&
        node.identifier.name == propertyName) {
      count += 1;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.realTarget;
    if (target is SimpleIdentifier &&
        target.name == targetName &&
        node.propertyName.name == propertyName) {
      count += 1;
    }
    super.visitPropertyAccess(node);
  }
}
