import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

part 'support/running_match_snapshot_codec_fixtures.dart';
part 'support/running_match_snapshot_codec_ast.dart';
part 'support/running_match_snapshot_codec_guard.dart';

const _codecPath =
    'server/lib/src/multiplayer/running_match_snapshot_codec.dart';

void main() {
  group('running match snapshot codec boundary', () {
    test('declares final nominal types and the exact boundary API', () {
      expect(_codecShapeViolations(_unitAt(_codecPath)), isEmpty);
    });

    test('rejects lifecycle before decoding without phase heuristics', () {
      expect(_decodeFlowViolations(_unitAt(_codecPath)), isEmpty);
    });

    test('encodes only by patching the retained raw snapshot', () {
      expect(_encodeFlowViolations(_unitAt(_codecPath)), isEmpty);
    });

    test('guard rejects open types and widened method contracts', () {
      final violations = _codecBoundaryViolations(
        _parse(_invalidCodecShapeFixture),
      );

      expect(
        violations,
        containsAll([
          'RunningMatchSnapshotCodec must be final',
          'DecodedRunningMatchSnapshot must be final',
          'decode must require exactly named WireMatch and WireSnapshot',
          'encode must require one positional source and optional legacy parts',
        ]),
      );
    });

    test('guard rejects late lifecycle checks and phase heuristics', () {
      final violations = _decodeFlowViolations(
        _parse(_invalidDecodeFlowFixture),
      );

      expect(
        violations,
        containsAll([
          'decode must reject a non-running match as its first statement',
          'decode must not infer lifecycle from snapshot phase',
          'legacy save and state parsing must remain lazy on the decoded wrapper',
          'lifecycle rejection must precede legacy parsing and construction',
        ]),
      );
    });

    test('guard rejects eager parsing after a valid lifecycle check', () {
      final violations = _decodeFlowViolations(
        _parse(_invalidEagerDecodeFixture),
      );

      expect(
        violations,
        contains('decode must construct only the lazy raw-wire wrapper'),
      );
      expect(
        violations,
        isNot(
          contains(
            'decode must reject a non-running match as its first statement',
          ),
        ),
      );
    });

    test('guard rejects helper work between lifecycle and construction', () {
      final violations = _decodeFlowViolations(
        _parse(_invalidHelperDecodeFixture),
      );

      expect(
        violations,
        contains('decode must construct only the lazy raw-wire wrapper'),
      );
    });

    test('guard rejects rebuilt, legacy, and canonical encoding', () {
      final violations = _encodeFlowViolations(
        _parse(_invalidEncodeFlowFixture),
      );

      expect(
        violations,
        containsAll([
          'encode must return source.wire.copyWith directly',
          'encode must not construct a WireSnapshot',
          'encode must not use legacy or canonical conversion',
        ]),
      );
    });
  });
}

CompilationUnit _unitAt(String path) {
  return parseString(content: File(path).readAsStringSync(), path: path).unit;
}

CompilationUnit _parse(String source) {
  return parseString(content: source, path: 'fixture.dart').unit;
}
