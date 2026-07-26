part of 'authoritative_turn_movement_transport_guard.dart';

Set<String> _candidatePaths(
  Map<String, String> sources,
  Iterable<String> overridePaths,
) {
  final routingNames = <String>{
    'MovementCommandExecution',
    'TurnMovementDelta',
    ..._expectedReferences.keys.map((key) => key.split('.').first),
    ..._forbiddenTransportTypes,
  };
  var changed = true;
  while (changed) {
    changed = false;
    for (final source in sources.values) {
      if (!routingNames.any(source.contains)) continue;
      final unit = _parseForRouting(source);
      for (final alias in unit.declarations.whereType<GenericTypeAlias>()) {
        if (!routingNames.any(alias.type.toSource().contains)) continue;
        if (routingNames.add(alias.name.lexeme)) changed = true;
      }
    }
  }

  return {
    ..._transportGraphRootPaths.where(sources.containsKey),
    ...overridePaths,
    for (final entry in sources.entries)
      if (routingNames.any(entry.value.contains)) entry.key,
  };
}

Future<_ResolvedTransportGraph> _resolveTransportGraph({
  required ResolvedDartWorkspace workspace,
  required Map<String, String> sources,
  required Set<String> candidatePaths,
}) async {
  final sourcePaths = sources.keys.toSet();
  final transportGraphPaths = {
    ..._transportGraphRootPaths.where(sourcePaths.contains),
  };
  final units = <String, ResolvedUnitResult>{};
  var pending = transportGraphPaths.toSet();

  while (pending.isNotEmpty) {
    final resolved = await workspace.resolveAll(pending);
    units.addAll(resolved);
    pending = {};
    for (final entry in resolved.entries) {
      final dependencies = _carrierDependencySourcePaths(entry.value.unit);
      for (final dependency in dependencies) {
        final path = _firstPartyDisplayPath(workspace, dependency, sourcePaths);
        if (path == null || _transportGraphStopPaths.contains(path)) continue;
        final fileName = path.split('/').last;
        if (_forbiddenTransportLibraryNames.contains(fileName)) continue;
        if (transportGraphPaths.add(path)) pending.add(path);
      }
    }
  }

  units.addAll(await workspace.resolveAll(candidatePaths));
  return _ResolvedTransportGraph(
    units: Map.unmodifiable(units),
    transportGraphPaths: Set.unmodifiable(transportGraphPaths),
  );
}

String? _firstPartyDisplayPath(
  ResolvedDartWorkspace workspace,
  String? absolutePath,
  Set<String> sourcePaths,
) {
  if (absolutePath == null) return null;
  try {
    final displayPath = workspace.displayPath(absolutePath);
    if (displayPath.startsWith('server/lib/src/generated/') ||
        displayPath.startsWith(
          'packages/aonw_server_client/lib/src/protocol/',
        )) {
      return null;
    }
    return sourcePaths.contains(displayPath) ? displayPath : null;
  } on ArgumentError {
    return null;
  }
}

final class _ResolvedTransportGraph {
  const _ResolvedTransportGraph({
    required this.units,
    required this.transportGraphPaths,
  });

  final Map<String, ResolvedUnitResult> units;
  final Set<String> transportGraphPaths;
}

CompilationUnit _parseForRouting(String source) {
  return parseString(content: source, throwIfDiagnostics: false).unit;
}
