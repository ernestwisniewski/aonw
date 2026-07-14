import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release/release.dart';

void main() {
  group('channel matrix', () {
    for (var mask = 0; mask < 8; mask++) {
      final steam = mask & 1 != 0;
      final google = mask & 2 != 0;
      final itch = mask & 4 != 0;

      test('enables only selected publish channels for mask $mask', () {
        final plan = _plan(
          _input(
            steamEnabled: steam,
            googlePlayEnabled: google,
            itchEnabled: itch,
            itchTarget: itch ? 'studio/game' : '',
          ),
        );
        final enabledPublishSteps = plan.steps
            .where((step) => step.enabled && step.id.startsWith('publish-'))
            .map((step) => step.id)
            .toList();

        expect(enabledPublishSteps, [
          if (steam) 'publish-steam',
          if (google) 'publish-google-play',
          if (itch) 'publish-itch',
          'publish-downloads',
          'publish-static-sites',
        ]);
      });
    }
  });

  group('Linux matrix', () {
    for (var mask = 0; mask < 8; mask++) {
      final steamLinux = mask & 1 != 0;
      final itchLinux = mask & 2 != 0;
      final downloadLinux = mask & 4 != 0;
      final linuxRequired = mask != 0;

      test('prepares artifacts once for Linux mask $mask', () {
        final plan = _plan(
          _input(
            steamEnabled: true,
            itchEnabled: true,
            itchTarget: 'studio/game',
            steamLinuxEnabled: steamLinux,
            itchLinuxEnabled: itchLinux,
            downloadLinuxEnabled: downloadLinux,
          ),
        );
        final prepare = plan.steps
            .where((step) => step.id == 'prepare-artifacts')
            .toList();

        expect(prepare, hasLength(1));
        expect(prepare.single.enabled, isTrue);
        expect(
          prepare.single.description.contains('plus Linux (github)'),
          linuxRequired,
        );
        expect(
          _step(plan, 'publish-steam').description.contains('including Linux'),
          steamLinux,
        );
        expect(
          _step(plan, 'publish-itch').description.contains('including Linux'),
          itchLinux,
        );
        expect(
          _step(
            plan,
            'publish-downloads',
          ).description.contains('including Linux'),
          downloadLinux,
        );
      });
    }
  });

  group('Google Play', () {
    for (final track in GooglePlayTrack.values) {
      test('supports ${track.wireValue} track', () {
        final parsed = GooglePlayTrack.parse(track.wireValue);
        final plan = _plan(
          _input(googlePlayEnabled: true, googlePlayTrack: parsed),
        );

        expect(parsed, track);
        expect(
          _step(plan, 'publish-google-play').description,
          'Publish Android to Google Play track ${track.wireValue}.',
        );
        expect(plan.canonicalJson, contains('"track":"${track.wireValue}"'));
      });
    }

    test('rejects an unknown track', () {
      expect(
        () => GooglePlayTrack.parse('open'),
        _throwsMessage(
          'Invalid google-track "open". Expected one of: '
          'closed, internal, alpha, beta, production.',
        ),
      );
    });

    test('validate-only requires Google Play and never publishes', () {
      expect(
        () => _plan(_input(googlePlayValidateOnly: true)),
        _throwsMessage(
          'google-validate-only requires Google Play to be enabled.',
        ),
      );

      final plan = _plan(
        _input(
          googlePlayEnabled: true,
          googlePlayValidateOnly: true,
          googlePlayTrack: GooglePlayTrack.internal,
        ),
      );
      expect(
        _step(plan, 'publish-google-play').description,
        'Validate Android for Google Play track internal without publication.',
      );
      expect(
        plan.human,
        contains('Google Play: validate-only; track: internal'),
      );
      expect(plan.canonicalJson, contains('"action":"validate-only"'));
    });
  });

  group('strict CLI contract', () {
    const booleanOptions = [
      'steam',
      'google',
      'google-validate-only',
      'itch',
      'steam-linux',
      'itch-linux',
      'download-linux',
      'github-cli-available',
      'windows-artifact-available',
      'linux-artifact-available',
    ];

    test('accepts only explicit zero and one for every boolean option', () {
      for (final option in booleanOptions) {
        expect(
          () => ReleasePlanCommand.parse(_replace(_cliArgs(), option, '0')),
          returnsNormally,
        );
        final args = _replace(_cliArgs(), option, '1');
        if (option == 'itch') {
          args[_valueIndex(args, 'itch-target')] = 'studio/game';
        }
        if (option == 'google-validate-only') {
          args[_valueIndex(args, 'google')] = '1';
        }
        expect(() => ReleasePlanCommand.parse(args), returnsNormally);
      }
    });

    for (final invalid in ['true', 'yes', '2', '-1', '']) {
      test('rejects boolean spelling "$invalid"', () {
        expect(
          () =>
              ReleasePlanCommand.parse(_replace(_cliArgs(), 'steam', invalid)),
          _throwsMessage('Invalid steam "$invalid". Expected 0 or 1.'),
        );
      });
    }

    test('requires key-value form, known unique keys, and all options', () {
      expect(
        () => ReleasePlanCommand.parse(['--steam=1']),
        _throwsMessage(contains('explicit --key value form')),
      );
      expect(
        () => ReleasePlanCommand.parse([..._cliArgs(), '--other', 'value']),
        _throwsMessage('Unknown option "--other".'),
      );
      expect(
        () => ReleasePlanCommand.parse([..._cliArgs(), '--steam', '1']),
        _throwsMessage('Duplicate option "--steam".'),
      );
      expect(
        () => ReleasePlanCommand.parse(_cliArgs().sublist(2)),
        _throwsMessage('Missing required options: --environment.'),
      );
    });
  });

  group('version and build resolution', () {
    test('defaults to one patch and one build increment', () {
      final plan = _plan(_input());

      expect(plan.targetVersion, SemanticVersion.parse('1.2.4'));
      expect(plan.targetBuild, 42);
      expect(
        _step(plan, 'prepare-version').description,
        'Prepare version 1.2.4 build 42 exactly once.',
      );
    });

    test('supports no bump and explicit version/build overrides', () {
      final unchanged = _plan(_input(versionBump: VersionBump.none));
      final overridden = _plan(
        _input(newVersion: SemanticVersion.parse('2.0.0'), newBuild: 100),
      );

      expect(unchanged.targetVersion, SemanticVersion.parse('1.2.3'));
      expect(unchanged.targetBuild, 42);
      expect(overridden.targetVersion, SemanticVersion.parse('2.0.0'));
      expect(overridden.targetBuild, 100);
    });

    test('rejects non-monotonic versions and builds', () {
      expect(
        () => _plan(_input(newVersion: SemanticVersion.parse('1.2.2'))),
        _throwsMessage(
          'new-version (1.2.2) must not be lower than current-version (1.2.3).',
        ),
      );
      for (final build in [40, 41]) {
        expect(
          () => _plan(_input(newBuild: build)),
          _throwsMessage(
            'new-build ($build) must be greater than current-build (41).',
          ),
        );
      }
      expect(
        () => _plan(_input(currentBuild: 0)),
        _throwsMessage('current-build must be a positive integer; got 0.'),
      );
      expect(
        () => _plan(_input(newBuild: -1)),
        _throwsMessage('new-build must be a positive integer; got -1.'),
      );
    });

    test('rejects malformed semantic versions and CLI build values', () {
      for (final version in ['1.2', '01.2.3', '1.2.3-beta', '1.2.3+4']) {
        expect(
          () => SemanticVersion.parse(version),
          _throwsMessage(startsWith('Invalid semantic version "$version".')),
        );
      }
      for (final build in ['-1', '1.0', 'abc']) {
        expect(
          () => ReleasePlanCommand.parse(
            _replace(_cliArgs(), 'current-build', build),
          ),
          _throwsMessage(
            'current-build must be a positive integer; got "$build".',
          ),
        );
      }
    });
  });

  group('channel and host validation', () {
    test('requires a well-formed itch target only when itch is enabled', () {
      final disabled = _plan(_input(itchTarget: 'not/a/target'));
      expect(disabled.canonicalJson, contains('"target":null'));

      final enabled = _plan(
        _input(itchEnabled: true, itchTarget: 'owner.name/game-name_1'),
      );
      expect(enabled.human, contains('target: owner.name/game-name_1'));

      for (final target in ['', '  ', 'owner', 'owner/game/extra']) {
        expect(
          () => _plan(_input(itchEnabled: true, itchTarget: target)),
          throwsA(isA<ReleasePlanException>()),
        );
      }
    });

    test('parses every host, artifact source, and iOS mode', () {
      for (final host in ReleaseHost.values) {
        expect(ReleaseHost.parse(host.wireValue), host);
      }
      for (final source in ArtifactSource.values) {
        expect(
          ArtifactSource.parse(source.wireValue, name: 'windows-source'),
          source,
        );
      }
      for (final mode in IosMode.values) {
        expect(IosMode.parse(mode.wireValue), mode);
        final archive = _step(_plan(_input(iosMode: mode)), 'archive-ios');
        expect(archive.enabled, mode != IosMode.off);
      }
      expect(
        () => ReleaseHost.parse('bsd'),
        throwsA(isA<ReleasePlanException>()),
      );
      expect(
        () => ArtifactSource.parse('remote', name: 'linux-source'),
        throwsA(isA<ReleasePlanException>()),
      );
      expect(
        () => IosMode.parse('optional'),
        throwsA(isA<ReleasePlanException>()),
      );
    });

    test('enforces the macOS aggregate-release source constraints', () {
      for (final host in [ReleaseHost.linux, ReleaseHost.windows]) {
        expect(
          () => _plan(_input(host: host)),
          _throwsMessage(contains('deploy-all requires a macos host')),
        );
      }
      expect(
        () => _plan(_input(windowsArtifactSource: ArtifactSource.local)),
        _throwsMessage(
          contains('windows-source local requires a windows host'),
        ),
      );
      expect(
        () => _plan(_input(linuxArtifactSource: ArtifactSource.local)),
        _throwsMessage(contains('linux-source local requires a linux host')),
      );
      expect(_plan(_input()).windowsArtifactSource, ArtifactSource.github);
      expect(
        _plan(
          _input(githubCliAvailable: false, windowsArtifactAvailable: true),
        ).windowsArtifactSource,
        ArtifactSource.existing,
      );
      expect(
        () => _plan(_input(githubCliAvailable: false)),
        _throwsMessage(contains('windows-source auto cannot resolve')),
      );
      expect(
        () => _plan(
          _input(
            windowsArtifactSource: ArtifactSource.existing,
            windowsArtifactAvailable: false,
          ),
        ),
        _throwsMessage(contains('requires the configured release directory')),
      );
    });
  });

  test('human and canonical JSON output are deterministic', () {
    final first = _plan(_input());
    final second = _plan(_input());

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
    expect(humanCommand.render(), first.human);
    expect(jsonCommand.render(), first.canonicalJson);
  });
}

ReleasePlan _plan(ReleasePlanInput input) => const ReleasePlanner().plan(input);

ReleasePlanInput _input({
  ReleaseEnvironment environment = ReleaseEnvironment.staging,
  ReleaseHost host = ReleaseHost.macos,
  bool steamEnabled = false,
  bool googlePlayEnabled = false,
  bool googlePlayValidateOnly = false,
  bool itchEnabled = false,
  String itchTarget = '',
  bool steamLinuxEnabled = false,
  bool itchLinuxEnabled = false,
  bool downloadLinuxEnabled = false,
  IosMode iosMode = IosMode.bestEffort,
  GooglePlayTrack googlePlayTrack = GooglePlayTrack.closed,
  ArtifactSource windowsArtifactSource = ArtifactSource.auto,
  ArtifactSource linuxArtifactSource = ArtifactSource.auto,
  bool githubCliAvailable = true,
  bool windowsArtifactAvailable = false,
  bool linuxArtifactAvailable = false,
  VersionBump versionBump = VersionBump.patch,
  SemanticVersion? currentVersion,
  int currentBuild = 41,
  SemanticVersion? newVersion,
  int? newBuild,
}) => ReleasePlanInput(
  environment: environment,
  host: host,
  steamEnabled: steamEnabled,
  googlePlayEnabled: googlePlayEnabled,
  googlePlayValidateOnly: googlePlayValidateOnly,
  itchEnabled: itchEnabled,
  itchTarget: itchTarget,
  steamLinuxEnabled: steamLinuxEnabled,
  itchLinuxEnabled: itchLinuxEnabled,
  downloadLinuxEnabled: downloadLinuxEnabled,
  iosMode: iosMode,
  googlePlayTrack: googlePlayTrack,
  windowsArtifactSource: windowsArtifactSource,
  linuxArtifactSource: linuxArtifactSource,
  githubCliAvailable: githubCliAvailable,
  windowsArtifactAvailable: windowsArtifactAvailable,
  linuxArtifactAvailable: linuxArtifactAvailable,
  versionBump: versionBump,
  currentVersion: currentVersion ?? SemanticVersion.parse('1.2.3'),
  currentBuild: currentBuild,
  newVersion: newVersion,
  newBuild: newBuild,
);

ReleasePlanStep _step(ReleasePlan plan, String id) =>
    plan.steps.singleWhere((step) => step.id == id);

Matcher _throwsMessage(Object matcher) => throwsA(
  isA<ReleasePlanException>().having(
    (error) => error.message,
    'message',
    matcher,
  ),
);

List<String> _replace(List<String> arguments, String option, String value) {
  final copy = List<String>.of(arguments);
  copy[_valueIndex(copy, option)] = value;
  return copy;
}

int _valueIndex(List<String> arguments, String option) =>
    arguments.indexOf('--$option') + 1;

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
