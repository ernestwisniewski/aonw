import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

const _timeoutServicePath =
    'server/lib/src/multiplayer/match_command_service_timeout.dart';
const _commandServicePath =
    'server/lib/src/multiplayer/match_command_service.dart';
const _reducerPath = 'server/lib/src/multiplayer/server_command_reducer.dart';
const _retiredReducerSnapshotPath =
    'server/lib/src/multiplayer/server_command_reducer_snapshot.dart';

void main() {
  group('timeout actor canonical integration', () {
    test('service owns the single wire decode/canonical/encode flow', () {
      expect(
        _timeoutFlowViolations(
          timeout: _unitAt(_timeoutServicePath),
          service: _unitAt(_commandServicePath),
        ),
        isEmpty,
      );
    });

    test('selector uses ordered wire roster and canonical session', () {
      expect(
        _timeoutSelectionViolations(_unitAt(_timeoutServicePath)),
        isEmpty,
      );
    });

    test('reducer has no decoded wrapper or compatibility alias', () {
      expect(File(_retiredReducerSnapshotPath).existsSync(), isFalse);
      final reducer = _unitAt(_reducerPath);
      final names = _IdentifierCollector()..collect(reducer);
      expect(names.count('DecodedMatchSnapshot'), 0);
      expect(names.count('DecodedRunningMatchSnapshot'), 0);
      expect(names.count('decodeSnapshot'), 0);
      expect(names.count('RunningMatchSnapshotCodec'), 0);
      expect(names.count('PersistentGameState'), 0);
      expect(names.count('GameSave'), 0);
    });

    test('flow guard rejects duplicate decode and stale canonical input', () {
      final violations = _timeoutFlowViolations(
        timeout: _parse('''
extension TimeoutFlow on Object {
void advanceTimedOutTurn() {
  final decodedSnapshot = _runningMatchSnapshotCodec.decode(
    match: state.match,
    snapshot: state.snapshot,
  );
  _runningMatchSnapshotCodec.decode(
    match: state.match,
    snapshot: state.snapshot,
  );
  final canonicalSnapshot = decodedSnapshot.canonical;
  _commandReducer.hasTurnTimedOut(snapshot: staleSnapshot, now: now);
  _commandReducer.reduceTimedOutTurn(
    match: state.match,
    snapshot: canonicalSnapshot,
    actorPlayerId: actor,
    now: now,
  );
}
}
'''),
        service: _unitAt(_commandServicePath),
      );

      expect(
        violations,
        containsAll([
          'advanceTimedOutTurn must decode the retained wire snapshot once',
          'hasTurnTimedOut must receive canonicalSnapshot',
          'accepted timeout flow must encode its canonical result once',
        ]),
      );
    });

    test('selection guard rejects legacy save/runtime reads and sorting', () {
      final violations = _timeoutSelectionViolations(
        _parse('''
extension TimeoutSelection on Object {
String? _selectTimeoutActorPlayerId({
  required WireMatch match,
  required GameSave save,
  required PersistentGameState state,
}) {
  final ids = save.players.map((player) => player.id).toList()..sort();
  return TimeoutActorSelector.select(
    orderedParticipantPlayerIds: ids,
    submittedPlayerIds: state.runtimeState.submittedPlayerIds,
    kickedPlayerIds: state.runtimeState.kickedPlayerIds,
  );
}
}
'''),
      );

      expect(
        violations,
        containsAll([
          '_selectTimeoutActorPlayerId must require match and canonical snapshot',
          'timeout selection must use canonical domain participants',
          'timeout selection must use canonical submitted players',
          'timeout selection must use canonical kicked players',
          'timeout selection must preserve Wire player order without sort',
        ]),
      );
    });
  });
}

List<String> _timeoutFlowViolations({
  required CompilationUnit timeout,
  required CompilationUnit service,
}) {
  final advance = _singleMethod(timeout, 'advanceTimedOutTurn');
  if (advance == null) return const ['must declare advanceTimedOutTurn'];
  final reduction = _singleMethod(timeout, '_reduceTimedOutTurnIfNeeded');
  return [
    ..._timeoutAdvanceViolations(advance),
    ..._timeoutIoHelperViolations(service),
    ..._timeoutReductionViolations(reduction),
  ];
}

List<String> _timeoutAdvanceViolations(MethodDeclaration method) {
  final body = method.body.toSource();
  final identifiers = _IdentifierCollector()..collect(method.body);
  final decodeCount = _methodCalls(method.body, '_decodeRunningSnapshot');
  final encodeCount = _methodCalls(method.body, '_encodeReductionSnapshot');
  return [
    if (decodeCount != 1 ||
        !body.contains(
          'final decodedSnapshot = _decodeRunningSnapshot(state);',
        ))
      'advanceTimedOutTurn must decode the retained wire snapshot once',
    if (identifiers.count('canonical') != 1 ||
        !body.contains('final canonicalSnapshot = decodedSnapshot.canonical;'))
      'advanceTimedOutTurn must read one memoized canonical snapshot',
    if (_singleNamedArgument(
          method.body,
          methodName: '_reduceTimedOutTurnIfNeeded',
          argumentName: 'snapshot',
        ) !=
        'canonicalSnapshot')
      'timeout reduction helper must receive canonicalSnapshot',
    if (encodeCount != 1)
      'accepted timeout flow must encode its canonical result once',
    if (!body.contains('previousSnapshot: canonicalSnapshot'))
      'timeout event audience must receive the same previous snapshot',
    if (identifiers.count('DecodedMatchSnapshot') != 0)
      'timeout flow must not use the retired decoded alias',
  ];
}

List<String> _timeoutIoHelperViolations(CompilationUnit service) {
  final decodeHelper = _singleMethod(service, '_decodeRunningSnapshot');
  final encodeHelper = _singleMethod(service, '_encodeReductionSnapshot');
  return [
    if (decodeHelper == null ||
        _methodCalls(decodeHelper.body, 'decode') != 1 ||
        !decodeHelper.body.toSource().contains('match: state.match') ||
        !decodeHelper.body.toSource().contains('snapshot: state.snapshot'))
      '_decodeRunningSnapshot must own the exact wire decode',
    if (encodeHelper == null ||
        _methodCalls(encodeHelper.body, 'encodeCanonical') != 1 ||
        !encodeHelper.body.toSource().contains(
          '.encodeCanonical(decoded, reduction.nextSnapshot!)',
        ))
      '_encodeReductionSnapshot must own the exact canonical encode',
  ];
}

List<String> _timeoutReductionViolations(MethodDeclaration? method) {
  if (method == null) {
    return const [
      'hasTurnTimedOut must receive canonicalSnapshot',
      'reduceTimedOutTurn must receive canonicalSnapshot',
    ];
  }
  return [
    if (_singleNamedArgument(
          method.body,
          methodName: 'hasTurnTimedOut',
          argumentName: 'snapshot',
        ) !=
        'snapshot')
      'hasTurnTimedOut must receive canonicalSnapshot',
    if (_singleNamedArgument(
          method.body,
          methodName: 'reduceTimedOutTurn',
          argumentName: 'snapshot',
        ) !=
        'snapshot')
      'reduceTimedOutTurn must receive canonicalSnapshot',
  ];
}

List<String> _timeoutSelectionViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, '_selectTimeoutActorPlayerId');
  if (method == null) return const ['must declare _selectTimeoutActorPlayerId'];
  final parameters = _namedParameterTypes(method);
  final body = method.body.toSource();
  return [
    if (!_sameMap(parameters, const {
      'match': 'WireMatch',
      'snapshot': 'CanonicalGameSnapshot',
    }))
      '_selectTimeoutActorPlayerId must require match and canonical snapshot',
    if (!body.contains('snapshot.domain.participants'))
      'timeout selection must use canonical domain participants',
    if (!body.contains('snapshot.session.turnStatesByPlayerId.keys'))
      'timeout selection must include canonical turn-state players',
    if (!body.contains('snapshot.session.submittedPlayerIds'))
      'timeout selection must use canonical submitted players',
    if (!body.contains('snapshot.session.kickedPlayerIds'))
      'timeout selection must use canonical kicked players',
    if (!body.contains('for (final player in match.players)'))
      'timeout selection must preserve the filtered Wire roster',
    if (body.contains('.sort('))
      'timeout selection must preserve Wire player order without sort',
    if (body.contains('lifecycle') || body.contains('GameSave'))
      'timeout selection must not read legacy save or runtime state',
  ];
}

Map<String, String> _namedParameterTypes(MethodDeclaration method) {
  return {
    for (final parameter
        in method.parameters?.parameters ?? const <FormalParameter>[])
      if (parameter is DefaultFormalParameter &&
          parameter.isNamed &&
          parameter.parameter is SimpleFormalParameter)
        (parameter.parameter as SimpleFormalParameter).name!.lexeme:
            (parameter.parameter as SimpleFormalParameter).type!.toSource(),
  };
}

MethodDeclaration? _singleMethod(CompilationUnit unit, String name) {
  final collector = _MethodCollector(name)..collect(unit);
  return collector.methods.length == 1 ? collector.methods.single : null;
}

int _methodCalls(AstNode node, String name) {
  final collector = _InvocationCollector(name)..collect(node);
  return collector.invocations.length;
}

String? _singleNamedArgument(
  AstNode node, {
  required String methodName,
  required String argumentName,
}) {
  final collector = _InvocationCollector(methodName)..collect(node);
  if (collector.invocations.length != 1) return null;
  final arguments = collector.invocations.single.argumentList.arguments
      .whereType<NamedExpression>()
      .where((argument) => argument.name.label.name == argumentName);
  return arguments.length == 1 ? arguments.single.expression.toSource() : null;
}

CompilationUnit _unitAt(String path) =>
    parseString(content: File(path).readAsStringSync(), path: path).unit;

CompilationUnit _parse(String source) => parseString(content: source).unit;

bool _sameMap(Map<String, String> left, Map<String, String> right) =>
    left.length == right.length &&
    right.entries.every((entry) => left[entry.key] == entry.value);

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

final class _IdentifierCollector extends RecursiveAstVisitor<void> {
  final List<String> names = [];

  void collect(AstNode node) => node.accept(this);

  int count(String name) =>
      names.where((candidate) => candidate == name).length;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
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
