/// Recipient-specific game state that is safe to serialize at a player edge.
///
/// The projected JSON tree deliberately remains private. Consumers can carry
/// this nominal proof or encode it for the wire, but cannot feed the redacted
/// view back into canonical game-state processing.
final class PlayerViewState {
  PlayerViewState({
    required Map<String, dynamic> projectedState,
    required this.recipientPlayerId,
  }) : _projectedState = _ownedJsonMap(projectedState);

  final String recipientPlayerId;
  final Map<String, dynamic> _projectedState;
}

/// The only wire serializer for [PlayerViewState].
final class PlayerViewStateWireCodec {
  const PlayerViewStateWireCodec();

  Map<String, dynamic> encode(PlayerViewState state) {
    return _mutableJsonMap(state._projectedState);
  }
}

Map<String, dynamic> _ownedJsonMap(Map<String, dynamic> source) {
  return Map<String, dynamic>.unmodifiable({
    for (final entry in source.entries) entry.key: _ownedJsonValue(entry.value),
  });
}

Object? _ownedJsonValue(Object? value) {
  return switch (value) {
    final Map<String, dynamic> map => _ownedJsonMap(map),
    final Map<Object?, Object?> map => _ownedJsonMap(
      Map<String, dynamic>.from(map),
    ),
    final Iterable<Object?> values => List<Object?>.unmodifiable(
      values.map(_ownedJsonValue),
    ),
    _ => value,
  };
}

Map<String, dynamic> _mutableJsonMap(Map<String, dynamic> source) {
  return {
    for (final entry in source.entries)
      entry.key: _mutableJsonValue(entry.value),
  };
}

Object? _mutableJsonValue(Object? value) {
  return switch (value) {
    final Map<String, dynamic> map => _mutableJsonMap(map),
    final List<Object?> values => values.map(_mutableJsonValue).toList(),
    _ => value,
  };
}
