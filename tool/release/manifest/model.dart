import 'dart:convert';
import 'dart:typed_data';

import '../canonical_json.dart';
import 'artifact_plan_validation.dart';
import 'digest.dart';
import 'failure.dart';
import 'validation.dart';

enum ReleaseChannel {
  downloads('downloads'),
  googlePlay('google-play'),
  homepage('homepage'),
  ios('ios'),
  itch('itch'),
  server('server'),
  steam('steam'),
  web('web');

  const ReleaseChannel(this.wireValue);

  static ReleaseChannel parse(String value) {
    for (final channel in values) {
      if (channel.wireValue == value) return channel;
    }
    throw ReleaseManifestException('Unknown release channel "$value".');
  }

  final String wireValue;
}

final class ManifestFileEntry {
  ManifestFileEntry({
    required this.path,
    required this.sha256,
    required this.bytes,
  }) {
    requireRelativePosixPath(path, 'file path');
    requireSha256(sha256, 'file sha256');
    if (bytes < 0) {
      throw const ReleaseManifestException('file bytes must not be negative.');
    }
  }

  final String path;
  final String sha256;
  final int bytes;

  Map<String, Object> toJson() => {
    'bytes': bytes,
    'path': path,
    'sha256': sha256,
  };
}

final class ManifestArtifact {
  ManifestArtifact({
    required this.id,
    required this.path,
    required this.sha256,
    required this.bytes,
    required this.mediaType,
    required Iterable<ReleaseChannel> destinations,
  }) : destinations = List.unmodifiable(destinations) {
    requireArtifactId(id);
    requireRelativePosixPath(path, 'artifact path');
    requireSha256(sha256, 'artifact sha256');
    if (bytes <= 0) {
      throw const ReleaseManifestException(
        'artifact bytes must be a positive integer.',
      );
    }
    requireMediaType(mediaType);
    requireSortedUnique(
      this.destinations.map((entry) => entry.wireValue),
      name: 'artifact destinations',
    );
  }

  final String id;
  final String path;
  final String sha256;
  final int bytes;
  final String mediaType;
  final List<ReleaseChannel> destinations;

  Map<String, Object> toJson() => {
    'bytes': bytes,
    'destinations': destinations
        .map((entry) => entry.wireValue)
        .toList(growable: false),
    'mediaType': mediaType,
    'id': id,
    'path': path,
    'sha256': sha256,
  };
}

final class ManifestFileTree {
  factory ManifestFileTree({
    required Iterable<ManifestFileEntry> files,
    String? expectedRevision,
  }) {
    final immutableFiles = List<ManifestFileEntry>.unmodifiable(files);
    requireSortedUnique(
      immutableFiles.map((entry) => entry.path),
      name: 'tree files',
    );
    final revision = computeTreeRevision(immutableFiles);
    if (expectedRevision != null) {
      requireSha256(expectedRevision, 'tree revision');
      if (revision != expectedRevision) {
        throw ReleaseManifestException(
          'Tree revision mismatch: expected $expectedRevision, computed '
          '$revision.',
        );
      }
    }
    return ManifestFileTree._(files: immutableFiles, revision: revision);
  }

  const ManifestFileTree._({required this.files, required this.revision});

  final List<ManifestFileEntry> files;
  final String revision;

  Map<String, Object> toJson() => {
    'files': files.map((entry) => entry.toJson()).toList(growable: false),
    'revision': revision,
  };

  static String computeTreeRevision(Iterable<ManifestFileEntry> files) {
    final json = files.map((entry) => entry.toJson()).toList(growable: false);
    return sha256Hex(encodeCanonicalJsonBytes(json));
  }
}

final class QualityGateEvidence {
  QualityGateEvidence.passed({required this.name, required this.sourceSha})
    : status = 'passed' {
    if (name.trim().isEmpty || name != name.trim()) {
      throw const ReleaseManifestException(
        'quality gate name must be non-empty and trimmed.',
      );
    }
    requireGitSha(sourceSha, 'quality gate sourceSha');
  }

  QualityGateEvidence.fromCanonical({
    required this.name,
    required this.sourceSha,
    required this.status,
  }) {
    if (status != 'passed') {
      throw const ReleaseManifestException(
        'quality gate status must be passed.',
      );
    }
    if (name.trim().isEmpty || name != name.trim()) {
      throw const ReleaseManifestException(
        'quality gate name must be non-empty and trimmed.',
      );
    }
    requireGitSha(sourceSha, 'quality gate sourceSha');
  }

  final String name;
  final String sourceSha;
  final String status;

  Map<String, Object> toJson() => {
    'name': name,
    'sourceSha': sourceSha,
    'status': status,
  };
}

/// Canonical, environment-neutral build and publication intent embedded in
/// the manifest so promotion never needs to reconstruct release options.
final class ArtifactPlanEvidence {
  factory ArtifactPlanEvidence.fromJson(
    Map<String, Object?> json, {
    String? expectedSha256,
  }) {
    final validated = validateArtifactPlan(json);
    final canonicalJson = encodeCanonicalJson(json);
    final sha256 = sha256Hex(utf8.encode(canonicalJson));
    if (expectedSha256 != null && expectedSha256 != sha256) {
      throw ReleaseManifestException(
        'artifactPlanSha256 mismatch: expected $expectedSha256, computed '
        '$sha256.',
      );
    }
    return ArtifactPlanEvidence._(
      canonicalJson: canonicalJson,
      sha256: sha256,
      selectedChannels: validated.selectedChannels
          .map(ReleaseChannel.parse)
          .toList(growable: false),
      requiredArtifactChannels: validated.requiredArtifactChannels
          .map(ReleaseChannel.parse)
          .toList(growable: false),
      version: validated.version,
      build: validated.build,
    );
  }

  const ArtifactPlanEvidence._({
    required this.canonicalJson,
    required this.sha256,
    required this.selectedChannels,
    required this.requiredArtifactChannels,
    required this.version,
    required this.build,
  });

  final String canonicalJson;
  final String sha256;
  final List<ReleaseChannel> selectedChannels;
  final List<ReleaseChannel> requiredArtifactChannels;
  final String version;
  final int build;

  Map<String, Object?> toJson() => Map<String, Object?>.from(
    jsonDecode(canonicalJson) as Map<String, Object?>,
  );
}

final class ReleaseManifestV1 {
  ReleaseManifestV1({
    required this.sourceSha,
    required this.version,
    required this.build,
    required this.artifactPlan,
    required this.qualityGate,
    required this.serverImage,
    required Iterable<ReleaseChannel> channels,
    required Iterable<ManifestArtifact> artifacts,
    required this.config,
    required this.migrations,
  }) : channels = List.unmodifiable(channels),
       artifacts = List.unmodifiable(artifacts) {
    requireGitSha(sourceSha, 'sourceSha');
    requireSemver(version);
    requirePositive(build, 'build');
    requireServerImage(serverImage);
    if (artifactPlan.version != version || artifactPlan.build != build) {
      throw const ReleaseManifestException(
        'artifactPlan release must match manifest version and build.',
      );
    }
    if (qualityGate.sourceSha != sourceSha) {
      throw const ReleaseManifestException(
        'quality gate must be bound to the manifest sourceSha.',
      );
    }
    requireSortedUnique(
      this.channels.map((entry) => entry.wireValue),
      name: 'channels',
    );
    if (!this.channels.contains(ReleaseChannel.server)) {
      throw const ReleaseManifestException(
        'channels must include server for the digest-pinned server image.',
      );
    }
    requireSortedUnique(
      this.artifacts.map((entry) => entry.id),
      name: 'artifact ids',
    );
    requireUnique(
      this.artifacts.map((entry) => entry.path),
      name: 'artifact paths',
    );
    final selectedChannels = this.channels.toSet();
    final selectedByPlan = artifactPlan.selectedChannels;
    if (this.channels.length != selectedByPlan.length ||
        !selectedChannels.containsAll(selectedByPlan)) {
      throw const ReleaseManifestException(
        'channels must exactly match the embedded artifactPlan.',
      );
    }
    for (final artifact in this.artifacts) {
      if (!selectedChannels.containsAll(artifact.destinations)) {
        throw ReleaseManifestException(
          'Artifact ${artifact.id} targets a channel absent from channels.',
        );
      }
    }
    for (final channel in artifactPlan.requiredArtifactChannels) {
      if (!this.artifacts.any(
        (artifact) => artifact.destinations.contains(channel),
      )) {
        throw ReleaseManifestException(
          'Selected channel ${channel.wireValue} has no manifest artifact.',
        );
      }
    }
  }

  static const schemaVersion = 1;

  final String sourceSha;
  final String version;
  final int build;
  final ArtifactPlanEvidence artifactPlan;
  final QualityGateEvidence qualityGate;
  final String serverImage;
  final List<ReleaseChannel> channels;
  final List<ManifestArtifact> artifacts;
  final ManifestFileTree config;
  final ManifestFileTree migrations;

  String get artifactPlanSha256 => artifactPlan.sha256;

  Map<String, Object> toJson() => {
    'artifactPlan': artifactPlan.toJson(),
    'artifactPlanSha256': artifactPlanSha256,
    'artifacts': artifacts
        .map((entry) => entry.toJson())
        .toList(growable: false),
    'build': build,
    'channels': channels
        .map((entry) => entry.wireValue)
        .toList(growable: false),
    'config': config.toJson(),
    'migrations': migrations.toJson(),
    'qualityGate': qualityGate.toJson(),
    'schemaVersion': schemaVersion,
    'serverImage': serverImage,
    'sourceSha': sourceSha,
    'version': version,
  };

  String get canonicalJson => encodeCanonicalJson(toJson());

  Uint8List get canonicalBytes => encodeCanonicalJsonBytes(toJson());

  String get digest => sha256Hex(canonicalBytes);

  String get fileName => '$digest.json';
}
