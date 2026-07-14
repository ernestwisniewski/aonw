import 'failure.dart';
import 'validation.dart';

final class ValidatedArtifactPlan {
  const ValidatedArtifactPlan({
    required this.version,
    required this.build,
    required this.selectedChannels,
    required this.requiredArtifactChannels,
  });

  final String version;
  final int build;
  final List<String> selectedChannels;
  final List<String> requiredArtifactChannels;
}

ValidatedArtifactPlan validateArtifactPlan(Map<String, Object?> plan) {
  _requireKeys(plan, 'artifactPlan', const {
    'artifactSources',
    'channels',
    'release',
    'schemaVersion',
  });
  final schemaVersion = plan['schemaVersion'];
  if (schemaVersion is! int || schemaVersion != 1) {
    throw const ReleaseManifestException(
      'artifactPlan schemaVersion must be 1.',
    );
  }
  final channels = _object(plan['channels'], 'artifactPlan.channels');
  final selectedChannels = _validateChannels(channels);
  final linuxRequired = const ['downloads', 'itch', 'steam'].any((key) {
    final channel = channels[key]! as Map<String, Object?>;
    return channel['linux'] == true;
  });
  _validateArtifactSources(
    _object(plan['artifactSources'], 'artifactPlan.artifactSources'),
    linuxRequired: linuxRequired,
  );
  final ios = _object(channels['ios'], 'artifactPlan.channels.ios');
  final iosIsBestEffort = ios['mode'] == 'best-effort';
  final requiredArtifactChannels = selectedChannels
      .where(
        (channel) =>
            channel != 'server' && !(channel == 'ios' && iosIsBestEffort),
      )
      .toList(growable: false);
  final release = _object(plan['release'], 'artifactPlan.release');
  _requireKeys(release, 'artifactPlan.release', const {'build', 'version'});
  final version = _string(release['version'], 'artifactPlan.release.version');
  final build = _integer(release['build'], 'artifactPlan.release.build');
  requireSemver(version);
  requirePositive(build, 'artifactPlan.release.build');
  return ValidatedArtifactPlan(
    version: version,
    build: build,
    selectedChannels: List.unmodifiable(selectedChannels),
    requiredArtifactChannels: List.unmodifiable(requiredArtifactChannels),
  );
}

void _validateArtifactSources(
  Map<String, Object?> sources, {
  required bool linuxRequired,
}) {
  _requireKeys(sources, 'artifactPlan.artifactSources', const {
    'linux',
    'windows',
  });
  for (final platform in const ['linux', 'windows']) {
    final name = 'artifactPlan.artifactSources.$platform';
    final source = _object(sources[platform], name);
    _requireKeys(source, name, const {'requested', 'resolved'});
    final requested = _string(source['requested'], '$name.requested');
    final resolved = _string(source['resolved'], '$name.resolved');
    const allowed = {'auto', 'existing', 'github', 'local'};
    if (!allowed.contains(requested) || !allowed.contains(resolved)) {
      throw ReleaseManifestException(
        '$name must use auto, existing, github, or local.',
      );
    }
    if (requested != 'auto' && requested != resolved) {
      throw ReleaseManifestException(
        '$name.resolved must equal an explicit requested source.',
      );
    }
    if (resolved == 'auto' && (platform == 'windows' || linuxRequired)) {
      throw ReleaseManifestException(
        '$name.resolved must be concrete when the artifact is required.',
      );
    }
  }
}

List<String> _validateChannels(Map<String, Object?> channels) {
  _requireKeys(channels, 'artifactPlan.channels', const {
    'downloads',
    'googlePlay',
    'homepage',
    'ios',
    'itch',
    'server',
    'steam',
    'web',
  });
  final selected = <String>[];
  _validateRequiredChannel(channels, 'downloads', selected);
  _validateGooglePlay(channels, selected);
  _validateRequiredChannel(channels, 'homepage', selected, linux: false);
  _validateIos(channels, selected);
  _validateOptionalChannel(
    channels,
    key: 'itch',
    wireValue: 'itch',
    expectedKeys: const {'enabled', 'linux', 'target'},
    selected: selected,
  );
  _validateRequiredChannel(channels, 'server', selected, linux: false);
  _validateOptionalChannel(
    channels,
    key: 'steam',
    wireValue: 'steam',
    expectedKeys: const {'enabled', 'linux'},
    selected: selected,
  );
  _validateRequiredChannel(channels, 'web', selected, linux: false);
  selected.sort();
  return selected;
}

void _validateRequiredChannel(
  Map<String, Object?> channels,
  String key,
  List<String> selected, {
  bool linux = true,
}) {
  final name = 'artifactPlan.channels.$key';
  final channel = _object(channels[key], name);
  _requireKeys(
    channel,
    name,
    linux ? const {'enabled', 'linux'} : const {'enabled'},
  );
  if (_boolean(channel['enabled'], '$name.enabled') != true) {
    throw ReleaseManifestException('$name.enabled must be true.');
  }
  if (linux) _boolean(channel['linux'], '$name.linux');
  selected.add(key);
}

void _validateOptionalChannel(
  Map<String, Object?> channels, {
  required String key,
  required String wireValue,
  required Set<String> expectedKeys,
  required List<String> selected,
}) {
  final name = 'artifactPlan.channels.$key';
  final channel = _object(channels[key], name);
  _requireKeys(channel, name, expectedKeys);
  final enabled = _boolean(channel['enabled'], '$name.enabled');
  _boolean(channel['linux'], '$name.linux');
  if (key == 'itch') {
    final target = channel['target'];
    if (enabled) {
      final value = _string(target, '$name.target');
      if (!RegExp(r'^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$').hasMatch(value)) {
        throw const ReleaseManifestException(
          'artifactPlan.channels.itch.target must use user/game.',
        );
      }
    } else if (target != null) {
      throw const ReleaseManifestException(
        'artifactPlan.channels.itch.target must be null when disabled.',
      );
    }
  }
  if (enabled) selected.add(wireValue);
}

void _validateGooglePlay(Map<String, Object?> channels, List<String> selected) {
  const name = 'artifactPlan.channels.googlePlay';
  final channel = _object(channels['googlePlay'], name);
  _requireKeys(channel, name, const {'action', 'enabled', 'track'});
  final enabled = _boolean(channel['enabled'], '$name.enabled');
  final action = _string(channel['action'], '$name.action');
  final track = _string(channel['track'], '$name.track');
  if (!const {'disabled', 'publish', 'validate-only'}.contains(action)) {
    throw const ReleaseManifestException(
      'artifactPlan.channels.googlePlay.action is invalid.',
    );
  }
  if (!const {
    'alpha',
    'beta',
    'closed',
    'internal',
    'production',
  }.contains(track)) {
    throw const ReleaseManifestException(
      'artifactPlan.channels.googlePlay.track is invalid.',
    );
  }
  if ((enabled && action == 'disabled') || (!enabled && action != 'disabled')) {
    throw const ReleaseManifestException(
      'artifactPlan.channels.googlePlay action and enabled must agree.',
    );
  }
  if (enabled) selected.add('google-play');
}

void _validateIos(Map<String, Object?> channels, List<String> selected) {
  const name = 'artifactPlan.channels.ios';
  final channel = _object(channels['ios'], name);
  _requireKeys(channel, name, const {'mode'});
  final mode = _string(channel['mode'], '$name.mode');
  if (!const {'best-effort', 'off', 'required'}.contains(mode)) {
    throw const ReleaseManifestException(
      'artifactPlan.channels.ios.mode is invalid.',
    );
  }
  if (mode != 'off') selected.add('ios');
}

Map<String, Object?> _object(Object? value, String name) {
  if (value is! Map<String, Object?>) {
    throw ReleaseManifestException('$name must be a JSON object.');
  }
  return value;
}

String _string(Object? value, String name) {
  if (value is! String) {
    throw ReleaseManifestException('$name must be a JSON string.');
  }
  return value;
}

int _integer(Object? value, String name) {
  if (value is! int) {
    throw ReleaseManifestException('$name must be a JSON integer.');
  }
  return value;
}

bool _boolean(Object? value, String name) {
  if (value is! bool) {
    throw ReleaseManifestException('$name must be a JSON boolean.');
  }
  return value;
}

void _requireKeys(
  Map<String, Object?> object,
  String name,
  Set<String> expected,
) {
  final actual = object.keys.toSet();
  final missing = expected.difference(actual).toList()..sort();
  final unknown = actual.difference(expected).toList()..sort();
  if (missing.isEmpty && unknown.isEmpty) return;
  final details = <String>[
    if (missing.isNotEmpty) 'missing: ${missing.join(', ')}',
    if (unknown.isNotEmpty) 'unknown: ${unknown.join(', ')}',
  ];
  throw ReleaseManifestException(
    '$name has invalid fields (${details.join('; ')}).',
  );
}
