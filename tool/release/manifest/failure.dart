final class ReleaseManifestException implements Exception {
  const ReleaseManifestException(this.message);

  final String message;

  @override
  String toString() => message;
}
