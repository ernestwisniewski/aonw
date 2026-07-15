/// A recoverable coverage-gate failure with a human-readable [message].
final class CoverageFailure implements Exception {
  const CoverageFailure(this.message);

  final String message;
}
