final class PerformanceFailure implements Exception {
  const PerformanceFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
