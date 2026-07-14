import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release/release.dart';

void main() {
  test('human and canonical JSON output are deterministic', () {
    final first = _plan(_cliArgs());
    final second = _plan(_cliArgs());

    expect(first.human, second.human);
    expect(first.canonicalJson, second.canonicalJson);
    expect(jsonDecode(first.canonicalJson), first.toJson());
    expect(first.canonicalJson, startsWith('{"artifactSources":'));
    expect(first.canonicalJson, isNot(contains('\n')));
    expect(
      encodeCanonicalJson({
        'z': [
          {'d': 4, 'c': 3},
        ],
        'a': {'b': 2, 'a': 1},
      }),
      '{"a":{"a":1,"b":2},"z":[{"c":3,"d":4}]}',
    );
    expect(
      first.human,
      startsWith(
        'Release plan (read-only)\n'
        'Environment: staging\n'
        'Host: macos\n'
        'Version: 1.2.3+41 -> 1.2.4+42 (patch)\n',
      ),
    );
    expect(
      first.human,
      endsWith(
        '15. [run] Verify backend and public route health after promotion.',
      ),
    );

    final humanCommand = ReleasePlanCommand.parse(_cliArgs());
    final jsonCommand = ReleasePlanCommand.parse(
      _replace(_cliArgs(), 'format', 'json'),
    );
    final artifactJsonCommand = ReleasePlanCommand.parse(
      _replace(_cliArgs(), 'format', 'artifact-json'),
    );
    expect(humanCommand.render(), first.human);
    expect(jsonCommand.render(), first.canonicalJson);
    expect(artifactJsonCommand.render(), first.artifactPlanCanonicalJson);
  });

  test('artifact plan is deterministic and environment-neutral', () {
    final staging = _plan(_cliArgs());
    final production = _plan(_replace(_cliArgs(), 'environment', 'prod'));

    expect(staging.canonicalJson, isNot(production.canonicalJson));
    expect(
      staging.artifactPlanCanonicalJson,
      production.artifactPlanCanonicalJson,
    );
    expect(
      jsonDecode(staging.artifactPlanCanonicalJson),
      staging.toArtifactPlanJson(),
    );
    final artifactPlan = staging.toArtifactPlanJson();
    expect(artifactPlan.keys.toSet(), {
      'artifactSources',
      'channels',
      'release',
      'schemaVersion',
    });
    expect(artifactPlan, isNot(contains('environment')));
    expect(artifactPlan, isNot(contains('host')));
    expect(artifactPlan, isNot(contains('steps')));
    expect(artifactPlan['release'], {'version': '1.2.4', 'build': 42});
  });
}

ReleasePlan _plan(List<String> arguments) {
  final command = ReleasePlanCommand.parse(arguments);
  return const ReleasePlanner().plan(command.input);
}

List<String> _replace(List<String> arguments, String option, String value) {
  final copy = List<String>.of(arguments);
  copy[copy.indexOf('--$option') + 1] = value;
  return copy;
}

List<String> _cliArgs() => const <String, String>{
  'environment': 'staging',
  'host': 'macos',
  'steam': '0',
  'google': '0',
  'google-validate-only': '0',
  'itch': '0',
  'itch-target': '',
  'steam-linux': '0',
  'itch-linux': '0',
  'download-linux': '0',
  'ios': 'best-effort',
  'google-track': 'closed',
  'windows-source': 'auto',
  'linux-source': 'auto',
  'github-cli-available': '1',
  'windows-artifact-available': '0',
  'linux-artifact-available': '0',
  'version-bump': 'patch',
  'current-version': '1.2.3',
  'current-build': '41',
  'new-version': '',
  'new-build': '',
  'format': 'human',
}.entries.expand((entry) => ['--${entry.key}', entry.value]).toList();
