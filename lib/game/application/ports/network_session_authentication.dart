sealed class NetworkSessionAuthenticationException implements Exception {
  const NetworkSessionAuthenticationException();
}

final class NetworkSessionUnavailableException
    extends NetworkSessionAuthenticationException {
  const NetworkSessionUnavailableException();

  @override
  String toString() => 'NetworkSessionUnavailableException';
}

final class NetworkSessionRefreshFailedException
    extends NetworkSessionAuthenticationException {
  final Object cause;
  final bool rejected;

  const NetworkSessionRefreshFailedException(
    this.cause, {
    this.rejected = false,
  });

  @override
  String toString() => 'NetworkSessionRefreshFailedException($cause)';
}
