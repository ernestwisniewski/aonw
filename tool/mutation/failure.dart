final class MutationFailure implements Exception {
  const MutationFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
