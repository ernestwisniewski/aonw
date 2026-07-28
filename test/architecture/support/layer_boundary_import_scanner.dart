import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

typedef ParsedNamespaceUri = ({String uri, int line});

/// Reads semantic import/export directives without matching fixture strings.
List<ParsedNamespaceUri> parseNamespaceDirectiveUris(
  String source, {
  required String path,
}) {
  final unit = parseString(content: source, path: path).unit;
  final result = <ParsedNamespaceUri>[];
  for (final directive in unit.directives.whereType<NamespaceDirective>()) {
    _addUri(result, unit, directive.uri);
    for (final configuration in directive.configurations) {
      _addUri(result, unit, configuration.uri);
    }
  }
  return result;
}

void _addUri(
  List<ParsedNamespaceUri> result,
  CompilationUnit unit,
  StringLiteral literal,
) {
  final uri = literal.stringValue;
  if (uri == null) return;
  result.add((
    uri: uri,
    line: unit.lineInfo.getLocation(literal.offset).lineNumber,
  ));
}
