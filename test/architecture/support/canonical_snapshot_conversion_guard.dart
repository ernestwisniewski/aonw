part of '../canonical_turn_pipeline_boundary_test.dart';

typedef _ConversionCounts = ({int toCanonical, int toLegacy});

const _expectedSnapshotConversionCalls = <String, _ConversionCounts>{
  _saveSnapshotPath: (toCanonical: 1, toLegacy: 1),
  _losslessSnapshotDecoderPath: (toCanonical: 1, toLegacy: 0),
  _runningSnapshotCodecPath: (toCanonical: 0, toLegacy: 1),
  _performanceCallSite: (toCanonical: 1, toLegacy: 1),
};

const _expectedAdapterTypePaths = {
  _saveSnapshotPath,
  _losslessSnapshotDecoderPath,
  _runningSnapshotCodecPath,
  _performanceCallSite,
};

const _zeroConversions = (toCanonical: 0, toLegacy: 0);

Map<String, _ConversionCounts> _snapshotConversionCounts(
  Map<String, String> sources,
) {
  final result = <String, _ConversionCounts>{};
  for (final entry in sources.entries) {
    final collector = _SnapshotConversionCollector();
    parseString(content: entry.value, path: entry.key).unit.accept(collector);
    final counts = (
      toCanonical: collector.toCanonical,
      toLegacy: collector.toLegacy,
    );
    if (_total(counts) > 0) result[entry.key] = counts;
  }
  return result;
}

Set<String> _adapterTypeReferencePaths(Map<String, String> sources) {
  final adapterTypes = typeNamesBackedBy(sources, const {
    'LegacyGameSnapshotAdapter',
  });
  final paths = <String>{};
  for (final entry in sources.entries) {
    final collector = _AdapterTypeReferenceCollector(adapterTypes);
    parseString(content: entry.value, path: entry.key).unit.accept(collector);
    if (collector.hasReference) paths.add(entry.key);
  }
  return paths;
}

int _total(_ConversionCounts counts) => counts.toCanonical + counts.toLegacy;

final class _SnapshotConversionCollector extends RecursiveAstVisitor<void> {
  int toCanonical = 0;
  int toLegacy = 0;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _record(node.methodName.name);
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _record(node.identifier.name);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _record(node.propertyName.name);
    super.visitPropertyAccess(node);
  }

  void _record(String name) {
    switch (name) {
      case 'toCanonical':
        toCanonical++;
      case 'toLegacy':
        toLegacy++;
    }
  }
}

final class _AdapterTypeReferenceCollector extends RecursiveAstVisitor<void> {
  _AdapterTypeReferenceCollector(this.adapterTypes);

  final Set<String> adapterTypes;
  bool hasReference = false;

  @override
  void visitNamedType(NamedType node) {
    if (adapterTypes.contains(node.name.lexeme)) hasReference = true;
    super.visitNamedType(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (adapterTypes.contains(node.constructorName.type.name.lexeme)) {
      hasReference = true;
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Without resolved elements, an implicit-const constructor in a const
    // variable declaration is represented as a method invocation.
    if (adapterTypes.contains(node.methodName.name)) hasReference = true;
    super.visitMethodInvocation(node);
  }
}
