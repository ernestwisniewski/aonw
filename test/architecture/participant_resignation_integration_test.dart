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
    test('keeps the strict canonical flow in dependency order', () {
      expect(_canonicalFlowViolations(_unitAt(_resignationPath)), isEmpty);
    });

    test('decodes, validates, transitions, and canonically encodes once', () {
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

    test('routes the resignation kick through the system engine', () {
      expect(_canonicalPatchViolations(_unitAt(_resignationPath)), isEmpty);
    });

    test('does not reach through the canonical boundary into legacy state', () {
      expect(_legacyAccessViolations(_unitAt(_resignationPath)), isEmpty);
    });

    test('leaves lifecycle overlays on the server boundary', () {
      expect(_lifecycleDecisionViolations(_unitAt(_resignationPath)), isEmpty);
    });

    test('rejects reordered flow and bypassing roster validation', () {
      final violations = _allViolations(_parse(_invalidFlowFixture));

      expect(
        violations,
        contains(
          'resignation must require the participant before snapshot access',
        ),
      );
      expect(
        violations,
        contains('resignation must decode the running snapshot exactly once'),
      );
      expect(
        violations,
        contains(
          'canonical snapshot must come from validated roster exactly once',
        ),
      );
      expect(
        violations,
        contains(
          'already-kicked return must immediately follow roster validation',
        ),
      );
      expect(
        violations,
        contains('resignation canonical flow must preserve dependency order'),
      );
    });

    test('rejects direct canonical access without roster validation', () {
      final violations = _allViolations(_parse(_invalidValidationFixture));

      expect(
        violations,
        contains(
          'canonical snapshot must come from validated roster exactly once',
        ),
      );
    });

    test('rejects a broad canonical rewrite and the wrong encode inputs', () {
      final violations = _allViolations(_parse(_invalidEncodeFixture));

      expect(
        violations,
        contains(
          'resignation kick must route through the GameEngine system command',
        ),
      );
      expect(
        violations,
        contains(
          'resignation must encode the validated canonical transition exactly '
          'once',
        ),
      );
      expect(
        violations,
        contains('running state must use the canonical codec result'),
      );
    });

    test('rejects legacy patching, conversion, and server outcome rules', () {
      final violations = _allViolations(_parse(_invalidLegacyFixture));

      expect(
        violations,
        contains('resignation must not access decoded legacy snapshot parts'),
      );
      expect(
        violations,
        contains(
          'resignation must not reference legacy snapshot state or conversion '
          'APIs',
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
