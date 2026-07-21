part of '../resource_trade_command_boundary_test.dart';

const _serverExtensionName = '_ServerCommandReducerResourceTrade';
const _serverExtensionMethods = {
  '_applyOpenResourceTrade',
  '_applyOpenResourceExchange',
};
const _mapBoundaryRootTypes = {
  'MapData',
  'MapDefinition',
  'MapSurvey',
  'MapTileCatalog',
  'MapTileLookup',
  'MapTileSource',
  'MapTileView',
  'MapTraversalView',
  'MapReadView',
  'WorldMap',
  'WorldMapReadView',
};

List<String> _serverExtensionMapBoundaryViolations(
  Map<String, String> sources, {
  String path = _serverCallSite,
}) {
  final source = sources[path];
  if (source == null) return ['$path must exist'];
  final unit = parseString(content: source, path: path).unit;
  final extensions = unit.declarations
      .whereType<ExtensionDeclaration>()
      .where((declaration) => declaration.name?.lexeme == _serverExtensionName)
      .toList();
  if (extensions.length != 1) {
    return ['$path must declare exactly one $_serverExtensionName extension'];
  }

  final mapTypes = typeNamesBackedBy(sources, _mapBoundaryRootTypes);
  return [
    for (final methodName in _serverExtensionMethods)
      ..._serverTradeMethodMapViolations(
        extensions.single,
        methodName,
        mapTypes,
      ),
  ];
}

List<String> _serverTradeMethodMapViolations(
  ExtensionDeclaration extension,
  String methodName,
  Set<String> mapTypes,
) {
  final methods = extension.body.members
      .whereType<MethodDeclaration>()
      .where((method) => method.name.lexeme == methodName)
      .toList();
  if (methods.length != 1) {
    return ['$methodName must be declared exactly once'];
  }
  final method = methods.single;
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  final mapTiles = _parameterNamed(parameters, 'mapTiles');
  return [
    ..._mapTilesDeclarationViolations(methodName, mapTiles),
    ..._mapDependencySetViolations(methodName, parameters, mapTypes),
    if (_tradeNamedTypes(method.returnType).intersection(mapTypes).isNotEmpty)
      '$methodName must not return a map-backed type',
  ];
}

FormalParameter? _parameterNamed(
  List<FormalParameter> parameters,
  String name,
) {
  for (final parameter in parameters) {
    if (_unwrappedTradeParameter(parameter).name?.lexeme == name) {
      return parameter;
    }
  }
  return null;
}

List<String> _mapTilesDeclarationViolations(
  String methodName,
  FormalParameter? mapTiles,
) {
  final normalized = mapTiles == null
      ? null
      : _unwrappedTradeParameter(mapTiles);
  return [
    if (_tradeParameterType(normalized)?.toSource() != 'MapTileLookup')
      '$methodName.mapTiles must be MapTileLookup',
    if (mapTiles is! DefaultFormalParameter ||
        !mapTiles.isNamed ||
        normalized?.requiredKeyword == null)
      '$methodName.mapTiles must be a required named parameter',
  ];
}

List<String> _mapDependencySetViolations(
  String methodName,
  List<FormalParameter> parameters,
  Set<String> mapTypes,
) {
  final mapParameters = [
    for (final parameter in parameters)
      if (_tradeNamedTypes(parameter).intersection(mapTypes).isNotEmpty)
        parameter,
  ];
  final exactMapTiles =
      mapParameters.length == 1 &&
      _unwrappedTradeParameter(mapParameters.single).name?.lexeme == 'mapTiles';
  return [
    if (!exactMapTiles)
      '$methodName must expose exactly one map-backed parameter: mapTiles',
  ];
}

String _serverExtensionFixture({
  String mapType = 'MapTileLookup',
  String extraParameter = '',
  String returnType = 'void',
  bool requiredNamed = true,
}) {
  final parameters = requiredNamed
      ? '{required $mapType mapTiles$extraParameter}'
      : '$mapType mapTiles';
  return '''
extension $_serverExtensionName on ServerCommandReducer {
  $returnType _applyOpenResourceTrade($parameters) {}

  $returnType _applyOpenResourceExchange($parameters) {}
}
''';
}

FormalParameter _unwrappedTradeParameter(FormalParameter parameter) {
  return parameter is DefaultFormalParameter ? parameter.parameter : parameter;
}

TypeAnnotation? _tradeParameterType(FormalParameter? parameter) {
  return switch (parameter) {
    SimpleFormalParameter(:final type) => type,
    FieldFormalParameter(:final type) => type,
    _ => null,
  };
}

Set<String> _tradeNamedTypes(AstNode? node) {
  final collector = _TradeNamedTypeCollector();
  node?.accept(collector);
  return collector.names;
}

final class _TradeNamedTypeCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitNamedType(NamedType node) {
    names.add(node.name.lexeme);
    super.visitNamedType(node);
  }
}
