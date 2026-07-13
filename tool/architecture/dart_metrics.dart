import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import 'baseline.dart';
import 'failure.dart';
import 'git_repository.dart';
import 'policy.dart';
import 'source_census.dart';
import 'strict_json.dart';

final class ArchitectureMeasurer {
  ArchitectureMeasurer({
    required this.repository,
    required this.policy,
    required this.census,
  });

  final GitRepository repository;
  final ArchitecturePolicy policy;
  final SourceCensus census;

  ArchitectureBaseline measure() {
    census.validateRepositoryCoverage();
    final scopes = <String, ScopeBaseline>{};
    for (final entry in policy.scopes.entries) {
      scopes[entry.key] = _measureScope(entry.key, entry.value);
    }
    return ArchitectureBaseline(scopes: scopes);
  }

  ScopeBaseline _measureScope(String scopeName, ScopePolicy scope) {
    final fileDebt = <String, int>{};
    final declarationDebt = <String, int>{};
    for (final path in census.handwrittenFiles(scopeName)) {
      final contents = File(repository.resolve(path)).readAsStringSync();
      final sourceMetrics = measureDartSource(path, contents);
      final fileLines = sourceMetrics.fileLines;
      final profile = scope.profileFor(path);
      if (fileLines > profile.lineTarget) fileDebt[path] = fileLines;
      for (final declaration in sourceMetrics.declarations) {
        if (declaration.lines <= scope.declarationLineTarget) continue;
        if (declarationDebt.containsKey(declaration.key)) {
          throw ArchitectureFailure(
            '$path contains duplicate declaration debt key: '
            '${declaration.key}',
          );
        }
        declarationDebt[declaration.key] = declaration.lines;
      }
    }
    return ScopeBaseline(
      files: Map.unmodifiable(sortedMap(fileDebt)),
      declarations: Map.unmodifiable(sortedMap(declarationDebt)),
    );
  }
}

DartSourceMetrics measureDartSource(String path, String contents) {
  final result = parseString(
    content: contents,
    path: path,
    throwIfDiagnostics: false,
  );
  if (result.errors.isNotEmpty) {
    final details = result.errors
        .map((diagnostic) => diagnostic.toString())
        .join('\n');
    throw ArchitectureFailure('$path has parser diagnostics:\n$details');
  }
  final visitor = _DeclarationVisitor(
    path: path,
    lineInfo: LineInfo.fromContent(contents),
  );
  result.unit.accept(visitor);
  return DartSourceMetrics(
    fileLines: const LineSplitter().convert(contents).length,
    declarations: List.unmodifiable(visitor.metrics),
  );
}

final class DartSourceMetrics {
  const DartSourceMetrics({
    required this.fileLines,
    required this.declarations,
  });

  final int fileLines;
  final List<DeclarationMetric> declarations;
}

final class DeclarationMetric {
  const DeclarationMetric({
    required this.key,
    required this.startLine,
    required this.lines,
  });

  final String key;
  final int startLine;
  final int lines;
}

final class _DeclarationVisitor extends RecursiveAstVisitor<void> {
  _DeclarationVisitor({required this.path, required this.lineInfo});

  final String path;
  final LineInfo lineInfo;
  final List<DeclarationMetric> metrics = [];
  var _anonymousExtensionCount = 0;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _record(node, 'class', node.namePart.typeName.lexeme);
    super.visitClassDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _record(node, 'enum', node.namePart.typeName.lexeme);
    super.visitEnumDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _record(node, 'mixin', node.name.lexeme);
    super.visitMixinDeclaration(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    final name =
        node.name?.lexeme ?? '<anonymous#${++_anonymousExtensionCount}>';
    _record(node, 'extension', name);
    super.visitExtensionDeclaration(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _record(node, 'extension_type', node.primaryConstructor.typeName.lexeme);
    super.visitExtensionTypeDeclaration(node);
  }

  void _record(AnnotatedNode node, String kind, String name) {
    final startOffset = node.metadata.isEmpty
        ? node.firstTokenAfterCommentAndMetadata.offset
        : node.metadata.first.offset;
    final endOffset = node.end > startOffset ? node.end - 1 : startOffset;
    final startLine = lineInfo.getLocation(startOffset).lineNumber;
    final endLine = lineInfo.getLocation(endOffset).lineNumber;
    metrics.add(
      DeclarationMetric(
        key: '$path::$kind:$name',
        startLine: startLine,
        lines: endLine - startLine + 1,
      ),
    );
  }
}
