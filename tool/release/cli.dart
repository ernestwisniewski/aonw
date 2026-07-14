import 'model.dart';
import 'planner.dart';

enum PlanOutputFormat {
  human('human'),
  json('json'),
  artifactJson('artifact-json');

  const PlanOutputFormat(this.wireValue);

  static PlanOutputFormat parse(String value) => switch (value) {
    'human' => human,
    'json' => json,
    'artifact-json' => artifactJson,
    _ => throw ReleasePlanException.invalidEnum(
      name: 'format',
      value: value,
      allowed: values.map((entry) => entry.wireValue),
    ),
  };

  final String wireValue;
}

/// Parsed CLI request. It can be exercised without invoking a process.
final class ReleasePlanCommand {
  const ReleasePlanCommand({required this.input, required this.format});

  factory ReleasePlanCommand.parse(List<String> arguments) {
    final values = _parsePairs(arguments);
    final missing = _requiredKeys.where((key) => !values.containsKey(key));
    if (missing.isNotEmpty) {
      throw ReleasePlanException(
        'Missing required options: ${missing.map((key) => '--$key').join(', ')}.',
      );
    }
    final currentBuild = _parseInteger(
      values['current-build']!,
      name: 'current-build',
    );
    final newBuild = _parseOptionalInteger(
      values['new-build']!,
      name: 'new-build',
    );
    final newVersion = values['new-version']!.isEmpty
        ? null
        : SemanticVersion.parse(values['new-version']!);
    return ReleasePlanCommand(
      input: ReleasePlanInput(
        environment: ReleaseEnvironment.parse(values['environment']!),
        host: ReleaseHost.parse(values['host']!),
        steamEnabled: parseStrictBoolean(values['steam']!, name: 'steam'),
        googlePlayEnabled: parseStrictBoolean(
          values['google']!,
          name: 'google',
        ),
        googlePlayValidateOnly: parseStrictBoolean(
          values['google-validate-only']!,
          name: 'google-validate-only',
        ),
        itchEnabled: parseStrictBoolean(values['itch']!, name: 'itch'),
        itchTarget: values['itch-target']!,
        steamLinuxEnabled: parseStrictBoolean(
          values['steam-linux']!,
          name: 'steam-linux',
        ),
        itchLinuxEnabled: parseStrictBoolean(
          values['itch-linux']!,
          name: 'itch-linux',
        ),
        downloadLinuxEnabled: parseStrictBoolean(
          values['download-linux']!,
          name: 'download-linux',
        ),
        iosMode: IosMode.parse(values['ios']!),
        googlePlayTrack: GooglePlayTrack.parse(values['google-track']!),
        windowsArtifactSource: ArtifactSource.parse(
          values['windows-source']!,
          name: 'windows-source',
        ),
        linuxArtifactSource: ArtifactSource.parse(
          values['linux-source']!,
          name: 'linux-source',
        ),
        githubCliAvailable: parseStrictBoolean(
          values['github-cli-available']!,
          name: 'github-cli-available',
        ),
        windowsArtifactAvailable: parseStrictBoolean(
          values['windows-artifact-available']!,
          name: 'windows-artifact-available',
        ),
        linuxArtifactAvailable: parseStrictBoolean(
          values['linux-artifact-available']!,
          name: 'linux-artifact-available',
        ),
        versionBump: VersionBump.parse(values['version-bump']!),
        currentVersion: SemanticVersion.parse(values['current-version']!),
        currentBuild: currentBuild,
        newVersion: newVersion,
        newBuild: newBuild,
      ),
      format: PlanOutputFormat.parse(values['format']!),
    );
  }

  final ReleasePlanInput input;
  final PlanOutputFormat format;

  String render([ReleasePlanner planner = const ReleasePlanner()]) {
    final plan = planner.plan(input);
    return switch (format) {
      PlanOutputFormat.human => plan.human,
      PlanOutputFormat.json => plan.canonicalJson,
      PlanOutputFormat.artifactJson => plan.artifactPlanCanonicalJson,
    };
  }
}

const releasePlanUsage = '''
Usage: dart tool/release/deploy_all_plan.dart
  --environment staging|prod
  --host macos|linux|windows
  --steam 0|1
  --google 0|1
  --google-validate-only 0|1
  --itch 0|1
  --itch-target user/game|""
  --steam-linux 0|1
  --itch-linux 0|1
  --download-linux 0|1
  --ios off|best-effort|required
  --google-track closed|internal|alpha|beta|production
  --windows-source auto|local|github|existing
  --linux-source auto|local|github|existing
  --github-cli-available 0|1
  --windows-artifact-available 0|1
  --linux-artifact-available 0|1
  --version-bump patch|none
  --current-version x.y.z
  --current-build N
  --new-version x.y.z|""
  --new-build N|""
  --format human|json|artifact-json

Every option is required and must use the explicit `--key value` form.
The command only validates and prints a plan; it performs no release actions.
''';

const _requiredKeys = <String>[
  'environment',
  'host',
  'steam',
  'google',
  'google-validate-only',
  'itch',
  'itch-target',
  'steam-linux',
  'itch-linux',
  'download-linux',
  'ios',
  'google-track',
  'windows-source',
  'linux-source',
  'github-cli-available',
  'windows-artifact-available',
  'linux-artifact-available',
  'version-bump',
  'current-version',
  'current-build',
  'new-version',
  'new-build',
  'format',
];

Map<String, String> _parsePairs(List<String> arguments) {
  final values = <String, String>{};
  for (var index = 0; index < arguments.length; index += 2) {
    final option = arguments[index];
    if (!option.startsWith('--') ||
        option.length == 2 ||
        option.contains('=')) {
      throw ReleasePlanException(
        'Invalid option "$option". Use the explicit --key value form.',
      );
    }
    if (index + 1 >= arguments.length) {
      throw ReleasePlanException('Missing value for $option.');
    }
    final key = option.substring(2);
    if (!_requiredKeys.contains(key)) {
      throw ReleasePlanException('Unknown option "$option".');
    }
    final value = arguments[index + 1];
    if (value.startsWith('--')) {
      throw ReleasePlanException('Missing value for $option.');
    }
    if (values.containsKey(key)) {
      throw ReleasePlanException('Duplicate option "$option".');
    }
    values[key] = value;
  }
  return values;
}

int _parseInteger(String value, {required String name}) {
  if (!RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(value)) {
    throw ReleasePlanException(
      '$name must be a positive integer; got "$value".',
    );
  }
  final parsed = int.tryParse(value);
  if (parsed == null) {
    throw ReleasePlanException('$name is outside the supported integer range.');
  }
  return parsed;
}

int? _parseOptionalInteger(String value, {required String name}) =>
    value.isEmpty ? null : _parseInteger(value, name: name);
