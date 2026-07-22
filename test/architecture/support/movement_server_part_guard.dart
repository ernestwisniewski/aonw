import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'map_boundary_source_guard.dart';
import 'movement_command_boundary_guard.dart';

const _mapBoundaryTypes = {
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

List<String> movementServerPartViolations(Map<String, String> sources) {
  final rootSource = sources[movementServerReducerPath];
  final partSource = sources[movementServerCallSite];
  if (rootSource == null || partSource == null) {
    return const ['movement server reducer root and part must exist'];
  }
  final root = parseString(
    content: rootSource,
    path: movementServerReducerPath,
  ).unit;
  final part = parseString(
    content: partSource,
    path: movementServerCallSite,
  ).unit;
  final partDirectives = root.directives
      .whereType<PartDirective>()
      .where(
        (directive) =>
            directive.uri.stringValue == 'server_command_reducer_movement.dart',
      )
      .length;
  final partOfDirectives = part.directives
      .whereType<PartOfDirective>()
      .where(
        (directive) =>
            directive.uri?.stringValue == 'server_command_reducer.dart',
      )
      .length;
  final extensions = part.declarations
      .whereType<ExtensionDeclaration>()
      .where(
        (declaration) =>
            declaration.name?.lexeme == '_ServerCommandReducerMovement',
      )
      .toList();
  final extension = extensions.length == 1 ? extensions.single : null;
  final methods =
      extension?.body.members.whereType<MethodDeclaration>().toList() ??
      const <MethodDeclaration>[];
  final applyMethods = methods
      .where((method) => method.name.lexeme == '_applyMoveUnit')
      .toList();
  final apply = applyMethods.length == 1 ? applyMethods.single : null;
  final mapTypes = typeNamesBackedBy(sources, _mapBoundaryTypes);

  return [
    if (partDirectives != 1)
      'server reducer must include exactly one movement part directive',
    if (partOfDirectives != 1)
      'movement server part must point back to server_command_reducer.dart',
    if (part.directives.length != 1 || part.declarations.length != 1)
      'movement server part must contain only its part-of directive and '
          'reviewed reducer extension',
    if (extension == null ||
        extension.onClause?.extendedType.toSource() != 'ServerCommandReducer')
      'movement part must declare exactly one reducer extension',
    if (methods.length != 1 || apply == null)
      'movement server extension must expose only _applyMoveUnit',
    if (apply != null && !_hasOneExactMapParameter(apply, mapTypes))
      '_applyMoveUnit must require exactly one bounded MapTraversalView mapView',
  ];
}

bool _hasOneExactMapParameter(MethodDeclaration method, Set<String> mapTypes) {
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  final mapParameters = [
    for (final parameter in parameters)
      if (_namedTypes(parameter).intersection(mapTypes).isNotEmpty) parameter,
  ];
  if (mapParameters.length != 1 ||
      method.returnType != null &&
          _namedTypes(method.returnType!).intersection(mapTypes).isNotEmpty) {
    return false;
  }
  final parameter = mapParameters.single;
  if (parameter is! DefaultFormalParameter || !parameter.isNamed) return false;
  final normalized = parameter.parameter;
  return normalized is SimpleFormalParameter &&
      normalized.name?.lexeme == 'mapView' &&
      normalized.type?.toSource() == 'MapTraversalView' &&
      normalized.requiredKeyword != null &&
      parameter.defaultValue == null;
}

Set<String> _namedTypes(AstNode node) {
  final collector = _NamedTypeCollector()..collect(node);
  return collector.names;
}

final class _NamedTypeCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  void collect(AstNode node) => node.accept(this);

  @override
  void visitNamedType(NamedType node) {
    names.add(node.name.lexeme);
    super.visitNamedType(node);
  }
}
