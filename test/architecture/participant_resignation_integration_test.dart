import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

part 'support/participant_resignation_integration_ast.dart';
part 'support/participant_resignation_integration_codec_guard.dart';
part 'support/participant_resignation_integration_fixtures.dart';
part 'support/participant_resignation_integration_flow_guard.dart';
part 'support/participant_resignation_integration_patch_guard.dart';

const _resignationPath =
    'server/lib/src/multiplayer/match_lifecycle_service_resignation.dart';

void main() {
  group('participant resignation canonical integration', () {
    test('keeps the kicked no-op at the lazy decode boundary', () {
      expect(_earlyNoOpViolations(_unitAt(_resignationPath)), isEmpty);
    });

    test('decodes, transitions, and losslessly encodes once', () {
      final unit = _unitAt(_resignationPath);

      expect(_codecFlowViolations(unit), isEmpty);
      expect(
        staticMemberReferenceCountsByPath(
          productionDartSources(),
          'ParticipantResignationTransition',
          'apply',
        ),
        {_resignationPath: 1},
      );
    });

    test('writes only the session slices owned by resignation', () {
      expect(
        _selectiveSnapshotPatchViolations(_unitAt(_resignationPath)),
        isEmpty,
      );
    });

    test('leaves lifecycle overlays on the server boundary', () {
      expect(_lifecycleDecisionViolations(_unitAt(_resignationPath)), isEmpty);
    });

    test('rejects eager access and bypassing the lossless codec', () {
      final violations = _allViolations(_parse(_invalidFlowFixture));

      expect(
        violations,
        contains(
          'already-kicked return must immediately follow state access and '
          'precede save/canonical access',
        ),
      );
      expect(
        violations,
        contains('resignation must decode the running snapshot exactly once'),
      );
      expect(
        violations,
        contains(
          'resignation must source state, save, and canonical data from '
          'decodedSnapshot',
        ),
      );
      expect(
        violations,
        contains('running resignation must not bypass the snapshot codec'),
      );
      expect(
        violations,
        contains(
          'resignation must encode the same decoded snapshot exactly once',
        ),
      );
      expect(
        violations,
        contains('running state must use the codec-encoded snapshot'),
      );
      expect(
        violations,
        contains(
          'transition must receive canonical state and Wire human order',
        ),
      );
    });

    test(
      'rejects encoding a different decoded snapshot or a partial patch',
      () {
        final violations = _allViolations(_parse(_invalidEncodeFixture));

        expect(
          violations,
          contains(
            'resignation must encode the same decoded snapshot exactly once',
          ),
        );
        expect(
          violations,
          contains('running state must use the codec-encoded snapshot'),
        );
      },
    );

    test('rejects broad snapshot rewrites and server-side outcome rules', () {
      final violations = _allViolations(_parse(_invalidPatchFixture));

      expect(
        violations,
        contains('save patch must write only canonical turn states'),
      );
      expect(
        violations,
        contains(
          'runtime patch must write only submitted, AFK, and kicked session slices',
        ),
      );
      expect(
        violations,
        contains('server resignation must not resolve alive players directly'),
      );
    });
  });
}

CompilationUnit _unitAt(String path) =>
    parseString(content: File(path).readAsStringSync(), path: path).unit;

CompilationUnit _parse(String source) => parseString(content: source).unit;
