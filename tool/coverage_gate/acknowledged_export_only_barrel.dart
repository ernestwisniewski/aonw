import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Whether an LCOV-absent source is a baseline-acknowledged export barrel.
///
/// Such a barrel has no executable declarations, so LCOV rightly omits it.
/// Keep the acknowledgement path-specific: an arbitrary source file must never
/// become eligible merely because it looks like a barrel.
bool isAcknowledgedExportOnlyBarrel({
  required String path,
  required Set<String> acknowledgedMissingFiles,
  required String source,
}) {
  if (!acknowledgedMissingFiles.contains(path)) return false;

  final result = parseString(content: source, path: path);
  final directives = result.unit.directives;
  return result.errors.isEmpty &&
      result.unit.declarations.isEmpty &&
      directives.any((directive) => directive is ExportDirective) &&
      directives.every(
        (directive) =>
            directive is ExportDirective || directive is LibraryDirective,
      );
}
