part of '../network_command_transport_snapshot_boundary_test.dart';

List<String> _commandTransportResultViolations(CompilationUnit unit) {
  final result = _classNamed(unit, 'CommandTransportResult');
  if (result == null) {
    return const ['CommandTransportResult must remain declared.'];
  }

  final violations = <String>[];
  final snapshotFields = <VariableDeclarationList>[];
  for (final field in result.body.members.whereType<FieldDeclaration>()) {
    if (field.fields.variables.any(
      (variable) => variable.name.lexeme == 'snapshot',
    )) {
      snapshotFields.add(field.fields);
    }
  }
  if (snapshotFields.length != 1 ||
      snapshotFields.single.type?.toSource() != 'CanonicalGameSnapshot?') {
    violations.add(
      'CommandTransportResult.snapshot must have exactly type '
      'CanonicalGameSnapshot?.',
    );
  }

  final constructors = result.body.members
      .whereType<ConstructorDeclaration>()
      .where((constructor) => constructor.name == null)
      .toList();
  final snapshotParameters = constructors
      .expand((constructor) => constructor.parameters.parameters)
      .where((parameter) => parameter.name?.lexeme == 'snapshot')
      .toList();
  if (constructors.length != 1 ||
      snapshotParameters.length != 1 ||
      !snapshotParameters.single.isRequiredNamed ||
      _normalizedParameter(snapshotParameters.single)
          is! FieldFormalParameter) {
    violations.add(
      'CommandTransportResult.snapshot must be one required named '
      'constructor field parameter.',
    );
  }

  final storedParameters = constructors
      .expand((constructor) => constructor.parameters.parameters)
      .where((parameter) => parameter.name?.lexeme == 'storedSnapshot')
      .toList();
  if (storedParameters.length != 1 ||
      !_isOptionalNamedFalse(storedParameters.single)) {
    violations.add(
      'CommandTransportResult.storedSnapshot must default to false.',
    );
  }
  return violations;
}

List<String> _networkSnapshotOwnershipViolations(CompilationUnit unit) {
  final transport = _classNamed(unit, 'NetworkCommandTransport');
  if (transport == null) {
    return const ['NetworkCommandTransport must remain declared.'];
  }

  final collector = _ForbiddenSnapshotOwnershipCollector();
  transport.accept(collector);
  return [
    if (collector.clientOnlySaveDeclarations != 0)
      'NetworkCommandTransport must not declare _clientOnlySave.',
    if (collector.gameSaveCreations != 0)
      'NetworkCommandTransport must not construct GameSave.',
    if (collector.fromGameStateCalls != 0)
      'NetworkCommandTransport must not call SaveSnapshot.fromGameState.',
  ];
}

List<String> _obsoleteNetworkSnapshotStoreViolations(
  Map<String, String> sources,
) {
  final violations = <String>[];
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final collector = _ObsoleteNetworkSnapshotStoreCollector();
    unit.accept(collector);
    for (final node in collector.references) {
      final line = unit.lineInfo.getLocation(node.offset).lineNumber;
      violations.add('${entry.key}:$line references NetworkSnapshotStore');
    }
    for (final directive in unit.directives.whereType<ImportDirective>()) {
      final uri = directive.uri.stringValue;
      if (uri == null || !uri.endsWith('network_snapshot_store.dart')) {
        continue;
      }
      final line = unit.lineInfo.getLocation(directive.offset).lineNumber;
      violations.add('${entry.key}:$line imports $uri');
    }
  }
  return violations;
}

final class _ForbiddenSnapshotOwnershipCollector
    extends RecursiveAstVisitor<void> {
  int clientOnlySaveDeclarations = 0;
  int gameSaveCreations = 0;
  int fromGameStateCalls = 0;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == '_clientOnlySave') {
      clientOnlySaveDeclarations += 1;
    }
    super.visitMethodDeclaration(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    clientOnlySaveDeclarations += node.fields.variables
        .where((variable) => variable.name.lexeme == '_clientOnlySave')
        .length;
    super.visitFieldDeclaration(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.constructorName.type.name.lexeme;
    final constructor = node.constructorName.name?.name;
    if (type == 'GameSave') gameSaveCreations += 1;
    if (type == 'CanonicalGameSnapshot' && constructor == 'fromGameState') {
      fromGameStateCalls += 1;
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'GameSave') gameSaveCreations += 1;
    if (node.target case SimpleIdentifier(
      name: 'CanonicalGameSnapshot',
    ) when node.methodName.name == 'fromGameState') {
      fromGameStateCalls += 1;
    }
    super.visitMethodInvocation(node);
  }
}

final class _ObsoleteNetworkSnapshotStoreCollector
    extends RecursiveAstVisitor<void> {
  final List<SimpleIdentifier> references = [];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == 'NetworkSnapshotStore') references.add(node);
    super.visitSimpleIdentifier(node);
  }
}
