/// The deployment environment selected for a release.
enum ReleaseEnvironment {
  staging('staging'),
  prod('prod');

  const ReleaseEnvironment(this.wireValue);

  static ReleaseEnvironment parse(String value) => switch (value) {
    'staging' => staging,
    'prod' => prod,
    _ => throw ReleasePlanException.invalidEnum(
      name: 'environment',
      value: value,
      allowed: values.map((entry) => entry.wireValue),
    ),
  };

  final String wireValue;
}

/// Host operating system used by the aggregate release flow.
enum ReleaseHost {
  macos('macos'),
  linux('linux'),
  windows('windows');

  const ReleaseHost(this.wireValue);

  static ReleaseHost parse(String value) => switch (value) {
    'macos' => macos,
    'linux' => linux,
    'windows' => windows,
    _ => throw ReleasePlanException.invalidEnum(
      name: 'host',
      value: value,
      allowed: values.map((entry) => entry.wireValue),
    ),
  };

  final String wireValue;
}

/// Policy for producing an Xcode archive during a release.
enum IosMode {
  off('off'),
  bestEffort('best-effort'),
  required('required');

  const IosMode(this.wireValue);

  static IosMode parse(String value) => switch (value) {
    'off' => off,
    'best-effort' => bestEffort,
    'required' => required,
    _ => throw ReleasePlanException.invalidEnum(
      name: 'ios',
      value: value,
      allowed: values.map((entry) => entry.wireValue),
    ),
  };

  final String wireValue;
}

/// Google Play destination selected when its upload is enabled.
enum GooglePlayTrack {
  closed('closed'),
  internal('internal'),
  alpha('alpha'),
  beta('beta'),
  production('production');

  const GooglePlayTrack(this.wireValue);

  static GooglePlayTrack parse(String value) => switch (value) {
    'closed' => closed,
    'internal' => internal,
    'alpha' => alpha,
    'beta' => beta,
    'production' => production,
    _ => throw ReleasePlanException.invalidEnum(
      name: 'google-track',
      value: value,
      allowed: values.map((entry) => entry.wireValue),
    ),
  };

  final String wireValue;
}

/// Source used to obtain a host-specific release artifact.
enum ArtifactSource {
  auto('auto'),
  local('local'),
  github('github'),
  existing('existing');

  const ArtifactSource(this.wireValue);

  static ArtifactSource parse(String value, {required String name}) =>
      switch (value) {
        'auto' => auto,
        'local' => local,
        'github' => github,
        'existing' => existing,
        _ => throw ReleasePlanException.invalidEnum(
          name: name,
          value: value,
          allowed: values.map((entry) => entry.wireValue),
        ),
      };

  final String wireValue;
}

/// Marketing-version change performed for the release.
enum VersionBump {
  patch('patch'),
  none('none');

  const VersionBump(this.wireValue);

  static VersionBump parse(String value) => switch (value) {
    'patch' => patch,
    'none' => none,
    _ => throw ReleasePlanException.invalidEnum(
      name: 'version-bump',
      value: value,
      allowed: values.map((entry) => entry.wireValue),
    ),
  };

  final String wireValue;
}

/// A strict `major.minor.patch` semantic version without prerelease metadata.
final class SemanticVersion implements Comparable<SemanticVersion> {
  const SemanticVersion._(this.major, this.minor, this.patch);

  factory SemanticVersion.parse(String value) {
    final match = _pattern.firstMatch(value);
    if (match == null) {
      throw ReleasePlanException(
        'Invalid semantic version "$value". Expected x.y.z with no leading '
        'zeroes, prerelease, or build metadata.',
      );
    }
    return SemanticVersion._(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static final RegExp _pattern = RegExp(
    r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$',
  );

  final int major;
  final int minor;
  final int patch;

  SemanticVersion get nextPatch => SemanticVersion._(major, minor, patch + 1);

  @override
  int compareTo(SemanticVersion other) {
    final majorOrder = major.compareTo(other.major);
    if (majorOrder != 0) return majorOrder;
    final minorOrder = minor.compareTo(other.minor);
    if (minorOrder != 0) return minorOrder;
    return patch.compareTo(other.patch);
  }

  @override
  bool operator ==(Object other) =>
      other is SemanticVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}

/// Complete, typed input to the side-effect-free release planner.
final class ReleasePlanInput {
  const ReleasePlanInput({
    required this.environment,
    required this.host,
    required this.steamEnabled,
    required this.googlePlayEnabled,
    required this.googlePlayValidateOnly,
    required this.itchEnabled,
    required this.itchTarget,
    required this.steamLinuxEnabled,
    required this.itchLinuxEnabled,
    required this.downloadLinuxEnabled,
    required this.iosMode,
    required this.googlePlayTrack,
    required this.windowsArtifactSource,
    required this.linuxArtifactSource,
    required this.githubCliAvailable,
    required this.windowsArtifactAvailable,
    required this.linuxArtifactAvailable,
    required this.versionBump,
    required this.currentVersion,
    required this.currentBuild,
    required this.newVersion,
    required this.newBuild,
  });

  final ReleaseEnvironment environment;
  final ReleaseHost host;
  final bool steamEnabled;
  final bool googlePlayEnabled;
  final bool googlePlayValidateOnly;
  final bool itchEnabled;
  final String itchTarget;
  final bool steamLinuxEnabled;
  final bool itchLinuxEnabled;
  final bool downloadLinuxEnabled;
  final IosMode iosMode;
  final GooglePlayTrack googlePlayTrack;
  final ArtifactSource windowsArtifactSource;
  final ArtifactSource linuxArtifactSource;
  final bool githubCliAvailable;
  final bool windowsArtifactAvailable;
  final bool linuxArtifactAvailable;
  final VersionBump versionBump;
  final SemanticVersion currentVersion;
  final int currentBuild;
  final SemanticVersion? newVersion;
  final int? newBuild;
}

/// A single deterministic decision in a release plan.
final class ReleasePlanStep {
  const ReleasePlanStep({
    required this.order,
    required this.id,
    required this.enabled,
    required this.description,
  });

  final int order;
  final String id;
  final bool enabled;
  final String description;

  Map<String, Object> toJson() => {
    'description': description,
    'enabled': enabled,
    'id': id,
    'order': order,
  };
}

/// Domain validation error suitable for both CLI and unit-test assertions.
final class ReleasePlanException implements Exception {
  const ReleasePlanException(this.message);

  factory ReleasePlanException.invalidEnum({
    required String name,
    required String value,
    required Iterable<String> allowed,
  }) => ReleasePlanException(
    'Invalid $name "$value". Expected one of: ${allowed.join(', ')}.',
  );

  final String message;

  @override
  String toString() => message;
}

bool parseStrictBoolean(String value, {required String name}) =>
    switch (value) {
      '1' => true,
      '0' => false,
      _ => throw ReleasePlanException(
        'Invalid $name "$value". Expected 0 or 1.',
      ),
    };
