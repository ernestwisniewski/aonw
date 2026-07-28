import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

part 'support/running_match_snapshot_codec_fixtures.dart';
part 'support/running_match_snapshot_codec_ast.dart';
part 'support/running_match_snapshot_codec_guard.dart';
part 'support/running_match_snapshot_codec_shape_guard.dart';
part 'support/running_match_snapshot_codec_flow_guard.dart';
part 'support/running_match_snapshot_codec_guard_helpers.dart';

const _codecPath =
    'server/lib/src/multiplayer/running_match_snapshot_codec.dart';
const _losslessDecoderPath =
    'server/lib/src/multiplayer/lossless_match_snapshot_decoder.dart';

void main() {
  group('running match snapshot codec boundary', () {
    test('declares final nominal types and the exact boundary API', () {
      expect(
        _codecShapeViolations(
          _unitAt(_codecPath),
          _unitAt(_losslessDecoderPath),
        ),
        isEmpty,
      );
    });

    test('rejects lifecycle before decoding without phase heuristics', () {
      expect(_runningDecodeFlowViolations(_unitAt(_codecPath)), isEmpty);
    });

    test('lossless decoder constructs only the lazy raw-wire wrapper', () {
      expect(
        _losslessDecodeFlowViolations(_unitAt(_losslessDecoderPath)),
        isEmpty,
      );
    });

    test('encodes only by patching the retained raw snapshot', () {
      expect(_encodeFlowViolations(_unitAt(_codecPath)), isEmpty);
    });

    test('guard rejects open types and widened method contracts', () {
      final unit = _parse(_invalidCodecShapeFixture);
      final violations = _codecBoundaryViolations(unit, unit);

      expect(
        violations,
        containsAll([
          'RunningMatchSnapshotCodec must be final',
          'must declare exactly one LosslessMatchSnapshotDecoder',
          'DecodedRunningMatchSnapshot must be final',
          'decode must require exactly named WireMatch and WireSnapshot',
          'lossless decode must require exactly one WireSnapshot',
          'canonicalWithValidatedRoster must require one decoded source and '
              'named WireMatch',
          'encode must require one positional source and optional legacy parts',
          'encodeInitial must require exactly named WireMatch and canonical '
              'snapshot',
          'encodeCanonical must require decoded source and canonical successor',
        ]),
      );
    });

    test('guard rejects late lifecycle checks and phase heuristics', () {
      final violations = _runningDecodeFlowViolations(
        _parse(_invalidDecodeFlowFixture),
      );

      expect(
        violations,
        containsAll([
          'decode must reject a non-running match as its first statement',
          'decode must not infer lifecycle from snapshot phase',
          'running decode must delegate directly to the lossless decoder after '
              'lifecycle rejection',
        ]),
      );
    });

    test('guard rejects eager parsing after a valid lifecycle check', () {
      final violations = _runningDecodeFlowViolations(
        _parse(_invalidEagerDecodeFixture),
      );

      expect(
        violations,
        contains(
          'running decode must delegate directly to the lossless decoder after '
          'lifecycle rejection',
        ),
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

    test('guard rejects helper work between lifecycle and delegation', () {
      final violations = _runningDecodeFlowViolations(
        _parse(_invalidHelperDecodeFixture),
      );

      expect(
        violations,
        contains(
          'running decode must delegate directly to the lossless decoder after '
          'lifecycle rejection',
        ),
      );
    });

    test('guard rejects helper work in the lossless decoder', () {
      expect(
        _losslessDecodeFlowViolations(_parse(_invalidLosslessHelperFixture)),
        contains(
          'lossless decode must directly construct the lazy raw-wire wrapper',
        ),
      );
    });

    test('guard rejects a lossless constructor tear-off', () {
      expect(
        _losslessDecodeFlowViolations(_parse(_invalidLosslessTearOffFixture)),
        contains(
          'lossless decode must directly construct the lazy raw-wire wrapper',
        ),
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
