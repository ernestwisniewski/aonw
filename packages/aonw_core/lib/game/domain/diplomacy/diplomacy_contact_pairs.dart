part of 'diplomacy_state.dart';

extension DiplomacyContactPairs on DiplomacyState {
  List<(String, String)> get decodedContactPairs {
    final pairs = [
      for (final key in _sortedContactKeys()) _decodedContactKey(key),
    ];
    return List.unmodifiable(pairs);
  }
}

(String, String) _decodedContactKey(String key) {
  final parts = key.split('|');
  if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
    throw ArgumentError.value(
      key,
      'DiplomacyState.contactKeys[]',
      'Expected a diplomatic contact key',
    );
  }
  return (Uri.decodeComponent(parts[0]), Uri.decodeComponent(parts[1]));
}
