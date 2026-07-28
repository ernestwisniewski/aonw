part of '../initial_multiplayer_snapshot_boundary_test.dart';

const _legacyInitialFactoryFixture = '''
class InitialMultiplayerSnapshotFactory {
  Future<WireSnapshot> create({required WireMatch match}) async {
    final save = GameSave();
    return WireSnapshot(save: save.toJson());
  }
}
''';

const _directInitialConversionFixture = '''
final class RunningMatchSnapshotCodec {
  WireSnapshot encodeInitial({
    required WireMatch match,
    required CanonicalGameSnapshot snapshot,
  }) {
    final legacy = adapter.toLegacy(snapshot);
    return WireSnapshot(
      matchId: snapshot.metadata.id,
      offset: snapshot.eventLogOffset,
      save: legacy.save.toJson(),
      state: legacy.state.toJson(),
    );
  }
}
''';

List<String> _initialFactoryViolations(CompilationUnit unit) {
  final factory = _classNamed(unit, 'InitialMultiplayerSnapshotFactory');
  final create = _methodNamed(factory, 'create');
  return [
    ..._initialFactoryShapeViolations(factory, create),
    ..._initialFactoryLegacyViolations(unit),
  ];
}

List<String> _initialFactoryShapeViolations(
  ClassDeclaration? factory,
  MethodDeclaration? create,
) {
  return [
    if (factory == null || factory.finalKeyword == null)
      'InitialMultiplayerSnapshotFactory must be final',
    if (!_hasExactInitialFactoryContract(create))
      'create must expose the exact canonical initial contract',
    if (create == null ||
        _staticInvocationCount(
              create.body,
              target: 'CanonicalGameSnapshot',
              member: 'snapshot',
            ) !=
            1)
      'create must construct exactly one CanonicalGameSnapshot',
    if (create == null ||
        _staticInvocationCount(
              create.body,
              target: 'DomainState',
              member: 'snapshot',
            ) !=
            1)
      'create must construct exactly one DomainState',
    if (create == null ||
        _staticInvocationCount(
              create.body,
              target: 'MatchSessionState',
              member: 'snapshot',
            ) !=
            1)
      'create must construct exactly one MatchSessionState',
    if (create == null ||
        _constructionCount(create.body, 'GameSnapshotMetadata') != 1)
      'create must construct exactly one GameSnapshotMetadata',
  ];
}

List<String> _initialFactoryLegacyViolations(CompilationUnit unit) {
  const forbiddenSymbols = {
    'WireSnapshot',
    'WireMatch',
    'WirePlayer',
    'GameSave',
    'PersistentGameState',
    'GameRuntimeState',
    'LegacyGameSnapshotAdapter',
  };
  return [
    for (final symbol in forbiddenSymbols)
      if (_identifierCount(unit, symbol) > 0)
        'factory must not reference $symbol',
    if (_identifierCount(unit, 'toLegacy') > 0 ||
        _identifierCount(unit, 'toCanonical') > 0)
      'factory must not perform compatibility conversion',
  ];
}

bool _hasExactInitialFactoryContract(MethodDeclaration? method) {
  if (method?.returnType?.toSource() != 'Future<CanonicalGameSnapshot>') {
    return false;
  }
  return _sameStringMap(_parameterTypes(method), const {
    'matchId': 'String',
    'matchName': 'String',
    'mapName': 'String',
    'participants': 'List<Player>',
    'startedAt': 'DateTime',
  });
}

Map<String, int> _domainPlayerMapperReferenceCounts(
  Map<String, String> sources,
) {
  final result = <String, int>{};
  for (final entry in sources.entries) {
    if (entry.key == _wirePlayerMapperPath) continue;
    final count = _identifierCount(
      parseString(content: entry.value, path: entry.key).unit,
      'domainPlayerFromWire',
    );
    if (count > 0) result[entry.key] = count;
  }
  return result;
}

List<String> _wirePlayerMapperViolations(CompilationUnit unit) {
  final functions = unit.declarations
      .whereType<FunctionDeclaration>()
      .where((function) => function.name.lexeme == 'domainPlayerFromWire')
      .toList();
  if (functions.length != 1) {
    return const ['must declare exactly one domainPlayerFromWire'];
  }
  final function = functions.single;
  final parameters =
      function.functionExpression.parameters?.parameters ??
      const <FormalParameter>[];
  return [
    if (function.returnType?.toSource() != 'Player' ||
        parameters.length != 1 ||
        _normalizedParameter(parameters.single).toSource() !=
            'WirePlayer player')
      'domainPlayerFromWire must map exactly one WirePlayer to Player',
    if (_constructionCount(function.functionExpression.body, 'Player') != 1)
      'domainPlayerFromWire must construct exactly one Player',
    if (_identifierCount(function.functionExpression.body, 'userId') > 0 ||
        _identifierCount(function.functionExpression.body, 'ready') > 0 ||
        _identifierCount(function.functionExpression.body, 'connectionState') >
            0)
      'domainPlayerFromWire must not copy transport-only identity or presence',
  ];
}

List<String> _initialLifecycleFlowViolations(CompilationUnit unit) {
  final lifecycle = _classNamed(unit, 'MatchLifecycleService');
  final start = _methodNamed(lifecycle, '_startOpenMatch');
  if (start == null) return const ['must declare _startOpenMatch'];
  final mapperOffsets = _identifierOffsets(start.body, 'domainPlayerFromWire');
  final createCalls = _methodCalls(
    start.body,
    'create',
  ).where((call) => call.target?.toSource() == 'snapshotFactory').toList();
  final encodeCalls = _methodCalls(start.body, 'encodeInitial')
      .where((call) => call.target?.toSource() == '_runningMatchSnapshotCodec')
      .toList();
  final ordered =
      mapperOffsets.length == 1 &&
      createCalls.length == 1 &&
      encodeCalls.length == 1 &&
      mapperOffsets.single < createCalls.single.offset &&
      createCalls.single.offset < encodeCalls.single.offset;
  return [
    if (!ordered)
      '_startOpenMatch must map, build, and encode exactly once in order',
    if (createCalls.length != 1 ||
        !_sameStringMap(_namedArguments(createCalls.single), const {
          'matchId': 'runningMatch.id',
          'matchName': 'runningMatch.name',
          'mapName': 'runningMatch.mapName',
          'participants': 'participants',
          'startedAt': 'now',
        }))
      'initial factory call must receive exact canonical roster metadata',
    if (encodeCalls.length != 1 ||
        !_sameStringMap(_namedArguments(encodeCalls.single), const {
          'match': 'runningMatch',
          'snapshot': 'canonicalSnapshot',
        }))
      'initial encoder call must receive the running match and canonical state',
  ];
}

List<String> _initialEncodeFlowViolations(CompilationUnit unit) {
  final codec = _classNamed(unit, 'RunningMatchSnapshotCodec');
  final method = _methodNamed(codec, 'encodeInitial');
  if (method == null) return const ['must declare encodeInitial'];
  final body = method.body;
  final statements = body is BlockFunctionBody
      ? body.block.statements
      : const <Statement>[];
  final guardConditions = statements
      .take(4)
      .whereType<IfStatement>()
      .map((statement) => statement.expression.toSource())
      .toList();
  final returned = statements.whereType<ReturnStatement>().toList();
  final returnedSource = returned.length == 1
      ? returned.single.expression?.toSource()
      : null;
  return [
    if (guardConditions.join('|') !=
        "match.state != 'running'|match.id != snapshot.metadata.id|"
            'snapshot.eventLogOffset != 0|'
            'snapshot.session.turnStartedAt != snapshot.metadata.savedAtUtc')
      'encodeInitial must perform exact lifecycle, id, offset, and implicit '
          'turn-start guards',
    ..._initialRosterConversionViolations(method, body),
    if (_methodCalls(body, '_withoutInitialTurnStartedAt').length != 1 ||
        _localInitializer(method, 'state') !=
            '_withoutInitialTurnStartedAt(legacy.state)')
      'encodeInitial must apply the initial turn-start wire policy once',
    if (returnedSource !=
        'WireSnapshot(matchId: snapshot.metadata.id, '
            'offset: snapshot.eventLogOffset, save: legacy.save.toJson(), '
            'state: state.toJson())')
      'encodeInitial must construct the exact initial wire envelope',
    if (_identifierCount(body, 'toLegacy') > 0 ||
        _identifierCount(body, 'toCanonical') > 0 ||
        _identifierCount(body, 'LegacyGameSnapshotAdapter') > 0)
      'encodeInitial must not convert snapshots directly',
  ];
}

List<String> _initialRosterConversionViolations(
  MethodDeclaration method,
  FunctionBody body,
) {
  final rosterGuards = _methodCalls(body, '_requireMatchingRoster');
  final conversions = _methodCalls(
    body,
    'encodeCanonical',
  ).where((call) => call.target?.toSource() == '_losslessMatchSnapshotCodec');
  final validatesBeforeConversion =
      rosterGuards.length == 1 &&
      conversions.length == 1 &&
      rosterGuards.single.offset < conversions.single.offset;
  final usesSharedCodec =
      conversions.length == 1 &&
      _localInitializer(method, 'legacy') ==
          '_losslessMatchSnapshotCodec.encodeCanonical(snapshot)';
  return [
    if (!validatesBeforeConversion)
      'encodeInitial must validate the authoritative roster before conversion',
    if (!usesSharedCodec)
      'encodeInitial must use the shared lossless codec once',
  ];
}

ClassDeclaration? _classNamed(CompilationUnit unit, String name) {
  final matches = unit.declarations
      .whereType<ClassDeclaration>()
      .where((declaration) => declaration.namePart.typeName.lexeme == name)
      .toList();
  return matches.length == 1 ? matches.single : null;
}

MethodDeclaration? _methodNamed(ClassDeclaration? declaration, String name) {
  if (declaration == null) return null;
  final matches = declaration.body.members
      .whereType<MethodDeclaration>()
      .where((method) => method.name.lexeme == name)
      .toList();
  return matches.length == 1 ? matches.single : null;
}

Map<String, String> _parameterTypes(MethodDeclaration? method) {
  if (method == null) return const {};
  final result = <String, String>{};
  for (final parameter
      in method.parameters?.parameters ?? const <FormalParameter>[]) {
    if (parameter is! DefaultFormalParameter || !parameter.isNamed) {
      return const {};
    }
    final normalized = _normalizedParameter(parameter);
    if (normalized is! SimpleFormalParameter ||
        normalized.requiredKeyword == null ||
        parameter.defaultValue != null) {
      return const {};
    }
    result[normalized.name?.lexeme ?? ''] = normalized.type?.toSource() ?? '';
  }
  return result;
}

FormalParameter _normalizedParameter(FormalParameter parameter) {
  return parameter is DefaultFormalParameter ? parameter.parameter : parameter;
}

int _staticInvocationCount(
  AstNode node, {
  required String target,
  required String member,
}) {
  return _methodCalls(
    node,
    member,
  ).where((call) => call.target?.toSource() == target).length;
}

int _constructionCount(AstNode node, String type) {
  final collector = _ConstructionCollector(type);
  node.accept(collector);
  return collector.count;
}

int _identifierCount(AstNode node, String name) {
  return _identifierOffsets(node, name).length;
}

List<int> _identifierOffsets(AstNode node, String name) {
  final collector = _IdentifierOffsetCollector(name);
  node.accept(collector);
  return collector.offsets;
}

List<MethodInvocation> _methodCalls(AstNode node, String name) {
  final collector = _MethodInvocationCollector(name);
  node.accept(collector);
  return collector.calls;
}

Map<String, String> _namedArguments(MethodInvocation call) {
  return {
    for (final argument in call.argumentList.arguments)
      if (argument is NamedExpression)
        argument.name.label.name: argument.expression.toSource(),
  };
}

bool _sameStringMap(Map<String, String> actual, Map<String, String> expected) {
  if (actual.length != expected.length) return false;
  for (final entry in expected.entries) {
    if (actual[entry.key] != entry.value) return false;
  }
  return true;
}

String? _localInitializer(MethodDeclaration method, String name) {
  final body = method.body;
  if (body is! BlockFunctionBody) return null;
  for (final statement in body.block.statements) {
    if (statement is! VariableDeclarationStatement) continue;
    for (final variable in statement.variables.variables) {
      if (variable.name.lexeme == name) {
        return variable.initializer?.toSource();
      }
    }
  }
  return null;
}

bool _importsUri(CompilationUnit unit, String suffix) {
  return unit.directives.whereType<ImportDirective>().any(
    (directive) => directive.uri.stringValue?.endsWith(suffix) ?? false,
  );
}

bool _exportsUri(CompilationUnit unit, String suffix) {
  return unit.directives.whereType<ExportDirective>().any(
    (directive) => directive.uri.stringValue?.endsWith(suffix) ?? false,
  );
}

final class _ConstructionCollector extends RecursiveAstVisitor<void> {
  _ConstructionCollector(this.type);

  final String type;
  int count = 0;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme == type) count += 1;
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null && node.methodName.name == type) count += 1;
    super.visitMethodInvocation(node);
  }
}

final class _IdentifierOffsetCollector extends RecursiveAstVisitor<void> {
  _IdentifierOffsetCollector(this.name);

  final String name;
  final List<int> offsets = [];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name) offsets.add(node.offset);
    super.visitSimpleIdentifier(node);
  }
}

final class _MethodInvocationCollector extends RecursiveAstVisitor<void> {
  _MethodInvocationCollector(this.name);

  final String name;
  final List<MethodInvocation> calls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == name) calls.add(node);
    super.visitMethodInvocation(node);
  }
}
