import 'failure.dart';

final RegExp _gitShaPattern = RegExp(r'^[0-9a-f]{40}$');
final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
final RegExp _semverPattern = RegExp(
  r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$',
);
final RegExp _mediaTypePattern = RegExp(
  r'^[A-Za-z0-9!#$&^_.+-]+/[A-Za-z0-9!#$&^_.+-]+$',
);
final RegExp _artifactIdPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');

void requireGitSha(String value, String name) {
  if (!_gitShaPattern.hasMatch(value)) {
    throw ReleaseManifestException('$name must be exactly 40 lowercase hex.');
  }
}

void requireSha256(String value, String name) {
  if (!_sha256Pattern.hasMatch(value)) {
    throw ReleaseManifestException('$name must be exactly 64 lowercase hex.');
  }
}

void requireSemver(String value) {
  if (!_semverPattern.hasMatch(value)) {
    throw const ReleaseManifestException(
      'version must be semantic x.y.z without leading zeroes or metadata.',
    );
  }
}

void requirePositive(int value, String name) {
  if (value <= 0) {
    throw ReleaseManifestException('$name must be a positive integer.');
  }
}

void requireMediaType(String value) {
  if (!_mediaTypePattern.hasMatch(value)) {
    throw ReleaseManifestException('Invalid artifact mediaType "$value".');
  }
}

void requireArtifactId(String value) {
  if (!_artifactIdPattern.hasMatch(value)) {
    throw ReleaseManifestException(
      'artifact id must be lowercase kebab-case; got "$value".',
    );
  }
}

void requireRelativePosixPath(String value, String name) {
  if (value.isEmpty ||
      value.startsWith('/') ||
      value.endsWith('/') ||
      value.contains(r'\') ||
      value.contains('\u0000')) {
    throw ReleaseManifestException('$name must be a relative POSIX path.');
  }
  final segments = value.split('/');
  if (segments.any(
    (segment) => segment.isEmpty || segment == '.' || segment == '..',
  )) {
    throw ReleaseManifestException(
      '$name must not contain empty, dot, or traversal segments.',
    );
  }
}

void requireSortedUnique(
  Iterable<String> values, {
  required String name,
  bool allowEmpty = false,
}) {
  final list = values.toList(growable: false);
  if (!allowEmpty && list.isEmpty) {
    throw ReleaseManifestException('$name must not be empty.');
  }
  for (var index = 1; index < list.length; index++) {
    if (list[index - 1].compareTo(list[index]) >= 0) {
      throw ReleaseManifestException(
        '$name must be strictly sorted and contain no duplicates.',
      );
    }
  }
}

void requireUnique(Iterable<String> values, {required String name}) {
  final seen = <String>{};
  for (final value in values) {
    if (!seen.add(value)) {
      throw ReleaseManifestException('$name must contain no duplicates.');
    }
  }
  if (seen.isEmpty) {
    throw ReleaseManifestException('$name must not be empty.');
  }
}

void requireServerImage(String value) {
  final separator = value.indexOf('@');
  if (separator <= 0 || separator != value.lastIndexOf('@')) {
    throw const ReleaseManifestException(
      'serverImage must use repository@sha256:<64 lowercase hex>.',
    );
  }
  final repository = value.substring(0, separator);
  final digest = value.substring(separator + 1);
  final lastComponent = repository.split('/').last;
  final validRepository =
      !repository.startsWith('/') &&
      !repository.endsWith('/') &&
      !repository.contains(RegExp(r'\s')) &&
      !repository.contains('..') &&
      !lastComponent.contains(':');
  if (!validRepository ||
      !digest.startsWith('sha256:') ||
      !_sha256Pattern.hasMatch(digest.substring('sha256:'.length))) {
    throw const ReleaseManifestException(
      'serverImage must use repository@sha256:<64 lowercase hex> without a tag.',
    );
  }
}
