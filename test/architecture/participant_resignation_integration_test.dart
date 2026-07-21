import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _resignationPath =
    'server/lib/src/multiplayer/match_lifecycle_service_resignation.dart';

void main() {
  group('participant resignation canonical integration', () {
    test('keeps the kicked no-op ahead of canonical decoding', () {
      expect(_earlyNoOpViolations(_unitAt(_resignationPath)), isEmpty);
    });

    test('converts once and calls the canonical transition once', () {
      final unit = _unitAt(_resignationPath);

      expect(_canonicalFlowViolations(unit), isEmpty);
      expect(
        staticMemberReferenceCountsByPath(
          productionDartSources(),
          'ParticipantResignationTransition',
          'apply',
        ),
        {_resignationPath: 1},
      );
    });

    test('writes only the legacy session slices owned by resignation', () {
      expect(
        _selectiveLegacyPatchViolations(_unitAt(_resignationPath)),
        isEmpty,
      );
    });

    test('leaves lifecycle overlays on the server boundary', () {
      expect(_lifecycleDecisionViolations(_unitAt(_resignationPath)), isEmpty);
    });

    test('rejects decoding before no-op and a full legacy round-trip', () {
      final violations = _allViolations(_parse(_invalidFlowFixture));

      expect(
        violations,
        contains('already-kicked return must precede save/canonical decoding'),
      );
      expect(
        violations,
        contains('resignation must canonicalize legacy state exactly once'),
      );
      expect(
        violations,
        contains('resignation must never reconstruct the full legacy snapshot'),
      );
      expect(
        violations,
        contains(
          'transition must receive canonical state and Wire human order',
        ),
      );
    });

    test('rejects broad legacy rewrites and server-side outcome rules', () {
      final violations = _allViolations(_parse(_invalidPatchFixture));

      expect(
        violations,
        contains('save patch must write only canonical turn states'),
      );
      expect(
        violations,
        contains(
          'runtime patch must write only submitted, AFK, and kicked session slices',
        ),
      );
      expect(
        violations,
        contains('server resignation must not resolve alive players directly'),
      );
    });
  });
}

List<String> _allViolations(CompilationUnit unit) => [
  ..._earlyNoOpViolations(unit),
  ..._canonicalFlowViolations(unit),
  ..._selectiveLegacyPatchViolations(unit),
  ..._lifecycleDecisionViolations(unit),
];

List<String> _earlyNoOpViolations(CompilationUnit unit) {
  final method = _runningResignationMethod(unit);
  if (method == null) {
    return const ['must declare _runningStateAfterParticipantResigned'];
  }
  final kickedReturn = _IfCollector()..collect(method.body);
  final earlyReturn = kickedReturn.nodes
      .where(
        (node) =>
            node.expression.toSource().contains('.isKicked(player.id)') &&
            node.thenStatement.toSource().contains('return state;'),
      )
      .toList();
  final saveDecode = _methodInvocations(
    method.body,
    'fromJson',
  ).where((call) => call.target?.toSource() == 'GameSave').toList();
  final conversion = _methodInvocations(method.body, 'toCanonical');
  final transition = _methodInvocations(method.body, 'apply')
      .where(
        (call) => call.target?.toSource() == 'ParticipantResignationTransition',
      )
      .toList();
  final boundaryOffsets = [
    if (saveDecode.length == 1) saveDecode.single.offset,
    if (conversion.length == 1) conversion.single.offset,
    if (transition.length == 1) transition.single.offset,
  ];
  return [
    if (earlyReturn.length != 1 ||
        boundaryOffsets.length != 3 ||
        boundaryOffsets.any((offset) => earlyReturn.single.offset >= offset))
      'already-kicked return must precede save/canonical decoding',
  ];
}

List<String> _canonicalFlowViolations(CompilationUnit unit) {
  final method = _runningResignationMethod(unit);
  if (method == null) return const [];
  final conversions = _methodInvocations(method.body, 'toCanonical');
  final conversion = conversions.length == 1 ? conversions.single : null;
  final conversionArguments = conversion == null
      ? const <String, String>{}
      : _namedArguments(conversion.argumentList);
  final transitionCalls = _methodInvocations(method.body, 'apply')
      .where(
        (call) => call.target?.toSource() == 'ParticipantResignationTransition',
      )
      .toList();
  final transitionArguments = transitionCalls.length == 1
      ? _namedArguments(transitionCalls.single.argumentList)
      : const <String, String>{};
  const orderedWireHumans =
      '[for (final matchPlayer in state.match.players) '
      'if (matchPlayer.kind == WirePlayerKind.human) matchPlayer.id]';
  return [
    if (conversion == null ||
        conversion.target?.toSource() != '_lifecycleSnapshotAdapter' ||
        !_sameStringMap(conversionArguments, const {
          'save': 'save',
          'state': 'persistentState',
          'eventLogOffset': 'state.snapshot.offset',
        }))
      'resignation must canonicalize legacy state exactly once',
    if (_methodInvocations(unit, 'toLegacy').isNotEmpty)
      'resignation must never reconstruct the full legacy snapshot',
    if (!_sameStringMap(transitionArguments, const {
      'domain': 'canonicalSnapshot.domain',
      'session': 'canonicalSnapshot.session',
      'actorPlayerId': 'player.id',
      'orderedHumanPlayerIds': orderedWireHumans,
    }))
      'transition must receive canonical state and Wire human order',
  ];
}

List<String> _selectiveLegacyPatchViolations(CompilationUnit unit) {
  final method = _runningResignationMethod(unit);
  if (method == null) return const [];
  final nextSave = _variableInitializer(method.body, 'nextSave');
  final nextSaveCall = nextSave is MethodInvocation ? nextSave : null;
  final nextPersistentState = _variableInitializer(
    method.body,
    'nextPersistentState',
  );
  final persistentCall = nextPersistentState is MethodInvocation
      ? nextPersistentState
      : null;
  final persistentArguments = persistentCall == null
      ? const <String, String>{}
      : _namedArguments(persistentCall.argumentList);
  final runtimeExpression = persistentArguments['runtimeState'];
  final runtimeCall = _methodInvocations(method.body, 'copyWith')
      .where(
        (call) =>
            call.target?.toSource() == 'persistentState.runtimeState' &&
            call.toSource() == runtimeExpression,
      )
      .toList();
  final runtimeArguments = runtimeCall.length == 1
      ? _namedArguments(runtimeCall.single.argumentList)
      : const <String, String>{};
  return [
    if (nextSaveCall?.target?.toSource() != 'save' ||
        !_sameStringMap(
          nextSaveCall == null
              ? const <String, String>{}
              : _namedArguments(nextSaveCall.argumentList),
          const {'playerStates': 'transition.session.turnStatesByPlayerId'},
        ))
      'save patch must write only canonical turn states',
    if (persistentCall?.target?.toSource() != 'persistentState' ||
        persistentArguments.keys.toSet().difference({
          'runtimeState',
        }).isNotEmpty ||
        runtimeCall.length != 1 ||
        !_sameStringMap(runtimeArguments, const {
          'submittedPlayerIds': 'transition.session.submittedPlayerIds',
          'afkPlayerIds': 'transition.session.afkPlayerIds',
          'kickedPlayerIds': 'transition.session.kickedPlayerIds',
        }))
      'runtime patch must write only submitted, AFK, and kicked session slices',
  ];
}

List<String> _lifecycleDecisionViolations(CompilationUnit unit) {
  final method =
      _methodNamed(unit, '_stateAfterResignationTransition') ??
      _runningResignationMethod(unit);
  if (method == null) return const [];
  final source = method.body.toSource();
  const cases = [
    'ParticipantResignationDisposition.unchanged',
    'ParticipantResignationDisposition.running',
    'ParticipantResignationDisposition.finished',
    'ParticipantResignationDisposition.abandoned',
  ];
  return [
    if (_methodInvocations(method.body, 'alivePlayerIds').isNotEmpty ||
        source.contains('GameOutcomeDetector') ||
        source.contains('_remainingHumanPlayers'))
      'server resignation must not resolve alive players directly',
    if (cases.any((value) => !source.contains(value)) ||
        !source.contains('_finishedStateAfterResignation') ||
        !source.contains('_stateAccess.abandonedState'))
      'server must map every typed disposition to its lifecycle overlay',
  ];
}

MethodDeclaration? _runningResignationMethod(CompilationUnit unit) {
  return _methodNamed(unit, '_runningStateAfterParticipantResigned');
}

MethodDeclaration? _methodNamed(CompilationUnit unit, String name) {
  final collector = _MethodCollector(name)..collect(unit);
  return collector.methods.length == 1 ? collector.methods.single : null;
}

List<MethodInvocation> _methodInvocations(AstNode node, String name) {
  final collector = _InvocationCollector(name)..collect(node);
  return collector.invocations;
}

Expression? _variableInitializer(AstNode node, String name) {
  final collector = _VariableCollector(name)..collect(node);
  return collector.variables.length == 1
      ? collector.variables.single.initializer
      : null;
}

Map<String, String> _namedArguments(ArgumentList arguments) => {
  for (final argument in arguments.arguments.whereType<NamedExpression>())
    argument.name.label.name: argument.expression.toSource(),
};

bool _sameStringMap(Map<String, String> left, Map<String, String> right) {
  return left.length == right.length &&
      right.entries.every((entry) => left[entry.key] == entry.value);
}

final class _MethodCollector extends RecursiveAstVisitor<void> {
  _MethodCollector(this.name);

  final String name;
  final List<MethodDeclaration> methods = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == name) methods.add(node);
    super.visitMethodDeclaration(node);
  }
}

final class _InvocationCollector extends RecursiveAstVisitor<void> {
  _InvocationCollector(this.name);

  final String name;
  final List<MethodInvocation> invocations = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == name) invocations.add(node);
    super.visitMethodInvocation(node);
  }
}

final class _VariableCollector extends RecursiveAstVisitor<void> {
  _VariableCollector(this.name);

  final String name;
  final List<VariableDeclaration> variables = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme == name) variables.add(node);
    super.visitVariableDeclaration(node);
  }
}

final class _IfCollector extends RecursiveAstVisitor<void> {
  final List<IfStatement> nodes = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitIfStatement(IfStatement node) {
    nodes.add(node);
    super.visitIfStatement(node);
  }
}

CompilationUnit _unitAt(String path) =>
    parseString(content: File(path).readAsStringSync(), path: path).unit;

CompilationUnit _parse(String source) => parseString(content: source).unit;

const _invalidFlowFixture = '''
extension Resignation on MatchLifecycleService {
  StoredMatchState _runningStateAfterParticipantResigned(
    StoredMatchState state, {
    required String userIdentifier,
    required DateTime endedAt,
  }) {
    final player = _stateAccess.requireParticipant(state, userIdentifier);
    final persistentState = PersistentGameState.fromJson(state.snapshot.state);
    final save = GameSave.fromJson(state.snapshot.save);
    final canonicalSnapshot = _lifecycleSnapshotAdapter.toCanonical(
      save: save,
      state: persistentState,
    );
    if (persistentState.runtimeState.isKicked(player.id)) return state;
    final legacy = _lifecycleSnapshotAdapter.toLegacy(canonicalSnapshot);
    ParticipantResignationTransition.apply(
      domain: canonicalSnapshot.domain,
      session: canonicalSnapshot.session,
      actorPlayerId: player.id,
      orderedHumanPlayerIds: save.players.map((player) => player.id),
    );
    throw UnimplementedError();
  }
}
''';

const _invalidPatchFixture = '''
extension Resignation on MatchLifecycleService {
  StoredMatchState _runningStateAfterParticipantResigned(
    StoredMatchState state, {
    required String userIdentifier,
    required DateTime endedAt,
  }) {
    final player = _stateAccess.requireParticipant(state, userIdentifier);
    final persistentState = PersistentGameState.fromJson(state.snapshot.state);
    if (persistentState.runtimeState.isKicked(player.id)) return state;
    final save = GameSave.fromJson(state.snapshot.save);
    final canonicalSnapshot = _lifecycleSnapshotAdapter.toCanonical(
      save: save,
      state: persistentState,
      eventLogOffset: state.snapshot.offset,
    );
    final transition = ParticipantResignationTransition.apply(
      domain: canonicalSnapshot.domain,
      session: canonicalSnapshot.session,
      actorPlayerId: player.id,
      orderedHumanPlayerIds: [
        for (final matchPlayer in state.match.players)
          if (matchPlayer.kind == WirePlayerKind.human) matchPlayer.id,
      ],
    );
    final nextSave = save.copyWith(
      players: canonicalSnapshot.domain.participants,
      playerStates: transition.session.turnStatesByPlayerId,
    );
    final nextPersistentState = persistentState.copyWith(
      runtimeState: persistentState.runtimeState.copyWith(
        submittedPlayerIds: transition.session.submittedPlayerIds,
        timeoutStreaksByPlayerId: transition.session.timeoutStreaksByPlayerId,
        afkPlayerIds: transition.session.afkPlayerIds,
        kickedPlayerIds: transition.session.kickedPlayerIds,
      ),
    );
    const GameOutcomeDetector().alivePlayerIds(
      playerIds: const [],
      state: nextPersistentState,
    );
    throw UnimplementedError();
  }
}
''';
