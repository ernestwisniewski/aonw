import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

const _runningCodecPath =
    'server/lib/src/multiplayer/running_match_snapshot_codec.dart';
const _losslessCodecPath =
    'server/lib/src/multiplayer/lossless_match_snapshot_codec.dart';

void main() {
  group('current running snapshot codec boundary', () {
    test('contains no removed state or conversion API', () {
      for (final path in const [_runningCodecPath, _losslessCodecPath]) {
        final identifiers = _identifiers(_unitAt(path));
        expect(
          identifiers.intersection(const {
            'PersistentGameState',
            'GameRuntimeState',
            'MatchSessionState',
            'LegacyGameSnapshotAdapter',
            'toCanonical',
            'toLegacy',
          }),
          isEmpty,
          reason: path,
        );
      }
    });

    test('decodes and encodes one canonical snapshot representation', () {
      final lossless = File(_losslessCodecPath).readAsStringSync();
      final running = File(_runningCodecPath).readAsStringSync();

      expect(lossless, contains('final WireSnapshot wire;'));
      expect(lossless, contains('late final CanonicalGameSnapshot canonical'));
      expect(
        RegExp(r'CanonicalGameSnapshotCodec\.decode\(').allMatches(lossless),
        hasLength(2),
      );
      expect(
        RegExp(r'CanonicalGameSnapshotCodec\.encode\(').allMatches(lossless),
        hasLength(1),
      );
      expect(running, contains('canonicalWithValidatedRoster('));
      expect(running, contains('_requireMatchingRoster('));
    });
  });
}

CompilationUnit _unitAt(String path) =>
    parseString(content: File(path).readAsStringSync(), path: path).unit;

Set<String> _identifiers(AstNode node) {
  final collector = _IdentifierCollector();
  node.accept(collector);
  return collector.names;
}

final class _IdentifierCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}
