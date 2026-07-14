import 'canonical_json.dart';
import 'model.dart';

/// A validated release plan. Building it never reads or changes external state.
final class ReleasePlan {
  ReleasePlan._({
    required this.input,
    required this.targetVersion,
    required this.targetBuild,
    required this.windowsArtifactSource,
    required this.linuxArtifactSource,
    required List<ReleasePlanStep> steps,
  }) : steps = List.unmodifiable(steps);

  final ReleasePlanInput input;
  final SemanticVersion targetVersion;
  final int targetBuild;
  final ArtifactSource windowsArtifactSource;
  final ArtifactSource linuxArtifactSource;
  final List<ReleasePlanStep> steps;

  String get canonicalJson => encodeCanonicalJson(toJson());

  /// Environment-neutral build intent suitable for a content-addressed
  /// manifest. Promotion environment, host, and mutable execution steps are
  /// deliberately excluded so the same artifact set can move unchanged.
  String get artifactPlanCanonicalJson =>
      encodeCanonicalJson(toArtifactPlanJson());

  String get human {
    final buffer = StringBuffer()
      ..writeln('Release plan (read-only)')
      ..writeln('Environment: ${input.environment.wireValue}')
      ..writeln('Host: ${input.host.wireValue}')
      ..writeln(
        'Version: ${input.currentVersion}+${input.currentBuild} -> '
        '$targetVersion+$targetBuild '
        '(${input.versionBump.wireValue})',
      )
      ..writeln('Channels:')
      ..writeln(
        '  Steamworks: ${_onOff(input.steamEnabled)}; '
        'Linux: ${_onOff(input.steamLinuxEnabled)}',
      )
      ..writeln(
        '  Google Play: ${_googleAction(input)}; '
        'track: ${input.googlePlayTrack.wireValue}',
      )
      ..writeln(
        '  itch.io: ${_onOff(input.itchEnabled)}; '
        'Linux: ${_onOff(input.itchLinuxEnabled)}'
        '${input.itchEnabled ? '; target: ${input.itchTarget}' : ''}',
      )
      ..writeln(
        '  Public downloads: enabled; '
        'Linux: ${_onOff(input.downloadLinuxEnabled)}',
      )
      ..writeln('iOS archive: ${input.iosMode.wireValue}')
      ..writeln('Artifact sources:')
      ..writeln(
        '  Windows: ${input.windowsArtifactSource.wireValue}'
        '${_resolution(input.windowsArtifactSource, windowsArtifactSource)}',
      )
      ..writeln(
        '  Linux: ${input.linuxArtifactSource.wireValue}'
        '${_resolution(input.linuxArtifactSource, linuxArtifactSource)}',
      )
      ..writeln('Steps:');
    for (final step in steps) {
      final number = step.order.toString().padLeft(2, '0');
      buffer.writeln(
        '  $number. [${step.enabled ? 'run' : 'skip'}] '
        '${step.description}',
      );
    }
    return buffer.toString().trimRight();
  }

  Map<String, Object?> toArtifactPlanJson() => {
    'artifactSources': _artifactSourcesJson,
    'channels': _channelsJson,
    'release': {'build': targetBuild, 'version': targetVersion.toString()},
    'schemaVersion': 1,
  };

  Map<String, Object?> toJson() => {
    'artifactSources': _artifactSourcesJson,
    'channels': _channelsJson,
    'environment': input.environment.wireValue,
    'host': input.host.wireValue,
    'release': {
      'currentBuild': input.currentBuild,
      'currentVersion': input.currentVersion.toString(),
      'newBuild': targetBuild,
      'newVersionOverride': input.newVersion?.toString(),
      'targetVersion': targetVersion.toString(),
      'versionBump': input.versionBump.wireValue,
    },
    'schemaVersion': 1,
    'steps': steps.map((step) => step.toJson()).toList(growable: false),
  };

  Map<String, Object?> get _artifactSourcesJson => {
    'linux': {
      'requested': input.linuxArtifactSource.wireValue,
      'resolved': linuxArtifactSource.wireValue,
    },
    'windows': {
      'requested': input.windowsArtifactSource.wireValue,
      'resolved': windowsArtifactSource.wireValue,
    },
  };

  Map<String, Object?> get _channelsJson => {
    'downloads': {'enabled': true, 'linux': input.downloadLinuxEnabled},
    'googlePlay': {
      'action': _googleAction(input),
      'enabled': input.googlePlayEnabled,
      'track': input.googlePlayTrack.wireValue,
    },
    'homepage': {'enabled': true},
    'ios': {'mode': input.iosMode.wireValue},
    'itch': {
      'enabled': input.itchEnabled,
      'linux': input.itchLinuxEnabled,
      'target': input.itchEnabled ? input.itchTarget : null,
    },
    'server': {'enabled': true},
    'steam': {'enabled': input.steamEnabled, 'linux': input.steamLinuxEnabled},
    'web': {'enabled': true},
  };
}

/// Resolves and validates a deterministic deployment plan without side effects.
final class ReleasePlanner {
  const ReleasePlanner();

  ReleasePlan plan(ReleasePlanInput input) {
    final targetBuild = _targetBuild(input);
    final targetVersion = _targetVersion(input);
    _validateChannels(input);
    _validateHost(input);
    final windowsSource = _resolveArtifactSource(
      requested: input.windowsArtifactSource,
      platform: ReleaseHost.windows,
      host: input.host,
      githubAvailable: input.githubCliAvailable,
      existingAvailable: input.windowsArtifactAvailable,
      required: true,
      name: 'windows-source',
    );
    final linuxRequired =
        input.steamLinuxEnabled ||
        input.itchLinuxEnabled ||
        input.downloadLinuxEnabled;
    final linuxSource = _resolveArtifactSource(
      requested: input.linuxArtifactSource,
      platform: ReleaseHost.linux,
      host: input.host,
      githubAvailable: input.githubCliAvailable,
      existingAvailable: input.linuxArtifactAvailable,
      required: linuxRequired,
      name: 'linux-source',
    );
    return ReleasePlan._(
      input: input,
      targetVersion: targetVersion,
      targetBuild: targetBuild,
      windowsArtifactSource: windowsSource,
      linuxArtifactSource: linuxSource,
      steps: _steps(
        input,
        targetVersion,
        targetBuild,
        windowsSource,
        linuxSource,
      ),
    );
  }

  int _targetBuild(ReleasePlanInput input) {
    if (input.currentBuild <= 0) {
      throw ReleasePlanException(
        'current-build must be a positive integer; got ${input.currentBuild}.',
      );
    }
    final target = input.newBuild ?? input.currentBuild + 1;
    if (target <= 0) {
      throw ReleasePlanException(
        'new-build must be a positive integer; got $target.',
      );
    }
    if (target <= input.currentBuild) {
      throw ReleasePlanException(
        'new-build ($target) must be greater than current-build '
        '(${input.currentBuild}).',
      );
    }
    return target;
  }

  SemanticVersion _targetVersion(ReleasePlanInput input) {
    final target =
        input.newVersion ??
        switch (input.versionBump) {
          VersionBump.patch => input.currentVersion.nextPatch,
          VersionBump.none => input.currentVersion,
        };
    if (target.compareTo(input.currentVersion) < 0) {
      throw ReleasePlanException(
        'new-version ($target) must not be lower than current-version '
        '(${input.currentVersion}).',
      );
    }
    return target;
  }

  void _validateChannels(ReleasePlanInput input) {
    if (input.itchEnabled && input.itchTarget.trim().isEmpty) {
      throw const ReleasePlanException(
        'itch-target is required when itch is enabled.',
      );
    }
    if (input.itchEnabled &&
        !RegExp(
          r'^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$',
        ).hasMatch(input.itchTarget)) {
      throw ReleasePlanException(
        'itch-target must use the user/game form; got "${input.itchTarget}".',
      );
    }
    if (input.googlePlayValidateOnly && !input.googlePlayEnabled) {
      throw const ReleasePlanException(
        'google-validate-only requires Google Play to be enabled.',
      );
    }
  }

  void _validateHost(ReleasePlanInput input) {
    if (input.host != ReleaseHost.macos) {
      throw ReleasePlanException(
        'deploy-all requires a macos host because the macOS artifact is built '
        'locally; got ${input.host.wireValue}.',
      );
    }
  }

  ArtifactSource _resolveArtifactSource({
    required ArtifactSource requested,
    required ReleaseHost platform,
    required ReleaseHost host,
    required bool githubAvailable,
    required bool existingAvailable,
    required bool required,
    required String name,
  }) {
    if (!required && requested == ArtifactSource.auto) {
      return ArtifactSource.auto;
    }
    final resolved = _selectArtifactSource(
      requested: requested,
      platform: platform,
      host: host,
      githubAvailable: githubAvailable,
      existingAvailable: existingAvailable,
      name: name,
    );
    _validateArtifactSource(
      resolved: resolved,
      platform: platform,
      host: host,
      githubAvailable: githubAvailable,
      existingAvailable: existingAvailable,
      name: name,
    );
    return resolved;
  }

  ArtifactSource _selectArtifactSource({
    required ArtifactSource requested,
    required ReleaseHost platform,
    required ReleaseHost host,
    required bool githubAvailable,
    required bool existingAvailable,
    required String name,
  }) => switch (requested) {
    ArtifactSource.auto when host == platform => ArtifactSource.local,
    ArtifactSource.auto when githubAvailable => ArtifactSource.github,
    ArtifactSource.auto when existingAvailable => ArtifactSource.existing,
    ArtifactSource.auto => throw ReleasePlanException(
      '$name auto cannot resolve: use the native host, install gh, or '
      'provide an existing artifact.',
    ),
    final explicit => explicit,
  };

  void _validateArtifactSource({
    required ArtifactSource resolved,
    required ReleaseHost platform,
    required ReleaseHost host,
    required bool githubAvailable,
    required bool existingAvailable,
    required String name,
  }) {
    if (resolved == ArtifactSource.local && host != platform) {
      throw ReleasePlanException(
        '$name local requires a ${platform.wireValue} host; got '
        '${host.wireValue}.',
      );
    }
    if (resolved == ArtifactSource.github && !githubAvailable) {
      throw ReleasePlanException('$name github requires the gh CLI.');
    }
    if (resolved == ArtifactSource.existing && !existingAvailable) {
      throw ReleasePlanException(
        '$name existing requires the configured release directory.',
      );
    }
  }

  List<ReleasePlanStep> _steps(
    ReleasePlanInput input,
    SemanticVersion targetVersion,
    int targetBuild,
    ArtifactSource windowsSource,
    ArtifactSource linuxSource,
  ) {
    return [
      ..._releasePreparationSteps(input, targetVersion, targetBuild),
      ..._deploymentSteps(input, windowsSource, linuxSource),
      ..._publicationSteps(input),
    ];
  }

  List<ReleasePlanStep> _releasePreparationSteps(
    ReleasePlanInput input,
    SemanticVersion targetVersion,
    int targetBuild,
  ) {
    final iosDescription = switch (input.iosMode) {
      IosMode.off => 'Skip the iOS archive by explicit policy.',
      IosMode.bestEffort =>
        'Archive iOS when the supported host and toolchain are available; '
            'a build failure remains fatal.',
      IosMode.required =>
        'Require the supported iOS host, toolchain, and a successful archive.',
    };
    return [
      const ReleasePlanStep(
        order: 1,
        id: 'validate-inputs',
        enabled: true,
        description: 'Validate the complete release contract before mutation.',
      ),
      const ReleasePlanStep(
        order: 2,
        id: 'quality-gate-current',
        enabled: true,
        description: 'Run the mandatory quality gate on the current revision.',
      ),
      ReleasePlanStep(
        order: 3,
        id: 'prepare-version',
        enabled: true,
        description:
            'Prepare version $targetVersion build $targetBuild exactly once.',
      ),
      const ReleasePlanStep(
        order: 4,
        id: 'quality-gate-release',
        enabled: true,
        description: 'Run the mandatory quality gate on the release revision.',
      ),
      ReleasePlanStep(
        order: 5,
        id: 'archive-ios',
        enabled: input.iosMode != IosMode.off,
        description: iosDescription,
      ),
      const ReleasePlanStep(
        order: 6,
        id: 'push-release',
        enabled: true,
        description: 'Push the reviewed release commit to origin/main.',
      ),
    ];
  }

  List<ReleasePlanStep> _deploymentSteps(
    ReleasePlanInput input,
    ArtifactSource windowsSource,
    ArtifactSource linuxSource,
  ) {
    final linuxRequired =
        input.steamLinuxEnabled ||
        input.itchLinuxEnabled ||
        input.downloadLinuxEnabled;
    return [
      ReleasePlanStep(
        order: 7,
        id: 'prepare-artifacts',
        enabled: true,
        description:
            'Prepare macOS, Windows '
            '(${windowsSource.wireValue}), Android, and public '
            'download artifacts${linuxRequired ? ' plus Linux (${linuxSource.wireValue})' : ''}.',
      ),
      ReleasePlanStep(
        order: 8,
        id: 'deploy-backend',
        enabled: true,
        description:
            'Deploy the compatible backend to ${input.environment.wireValue}.',
      ),
      const ReleasePlanStep(
        order: 9,
        id: 'verify-backend',
        enabled: true,
        description: 'Verify backend readiness before client publication.',
      ),
    ];
  }

  List<ReleasePlanStep> _publicationSteps(ReleasePlanInput input) {
    return [
      ReleasePlanStep(
        order: 10,
        id: 'publish-steam',
        enabled: input.steamEnabled,
        description:
            'Publish Steamworks desktop artifacts${input.steamLinuxEnabled ? ' including Linux' : ''}.',
      ),
      ReleasePlanStep(
        order: 11,
        id: 'publish-google-play',
        enabled: input.googlePlayEnabled,
        description: input.googlePlayValidateOnly
            ? 'Validate Android for Google Play track '
                  '${input.googlePlayTrack.wireValue} without publication.'
            : 'Publish Android to Google Play track '
                  '${input.googlePlayTrack.wireValue}.',
      ),
      ReleasePlanStep(
        order: 12,
        id: 'publish-itch',
        enabled: input.itchEnabled,
        description:
            'Publish itch.io artifacts${input.itchLinuxEnabled ? ' including Linux' : ''}.',
      ),
      ReleasePlanStep(
        order: 13,
        id: 'publish-downloads',
        enabled: true,
        description:
            'Publish public downloads${input.downloadLinuxEnabled ? ' including Linux' : ''}.',
      ),
      const ReleasePlanStep(
        order: 14,
        id: 'publish-static-sites',
        enabled: true,
        description: 'Promote the homepage and web client artifacts.',
      ),
      const ReleasePlanStep(
        order: 15,
        id: 'verify-release',
        enabled: true,
        description: 'Verify backend and public route health after promotion.',
      ),
    ];
  }
}

String _onOff(bool enabled) => enabled ? 'enabled' : 'disabled';

String _googleAction(ReleasePlanInput input) {
  if (!input.googlePlayEnabled) return 'disabled';
  return input.googlePlayValidateOnly ? 'validate-only' : 'publish';
}

String _resolution(ArtifactSource requested, ArtifactSource resolved) =>
    requested == resolved ? '' : ' -> ${resolved.wireValue}';
