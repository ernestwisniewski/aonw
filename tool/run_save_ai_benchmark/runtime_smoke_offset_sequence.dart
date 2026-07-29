/// Absolute event-log offsets assigned by the isolated runtime smoke.
///
/// The sequence starts after the persisted snapshot offset and advances once
/// for every fake dispatch, matching the production transport contract.
final class RuntimeSmokeOffsetSequence {
  RuntimeSmokeOffsetSequence({required int initialOffset})
    : _currentOffset = initialOffset;

  int _currentOffset;

  int next() {
    _currentOffset += 1;
    return _currentOffset;
  }
}
