import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/game/domain/transport/transport_segment.dart';
import 'package:aonw_core/util/collection_equality.dart';

/// Immutable aggregate containing at most one transport segment per hex.
final class TransportNetworkState {
  factory TransportNetworkState({
    Iterable<TransportSegment> segments = const [],
  }) {
    if (segments.isEmpty) return empty;
    final byHex = <HexCoord, TransportSegment>{};
    for (final segment in segments) {
      if (segment.builtByPlayerId.isEmpty) {
        throw ArgumentError.value(
          segment.builtByPlayerId,
          'segments',
          'The builder player id must not be empty.',
        );
      }
      if (byHex.containsKey(segment.hex)) {
        throw ArgumentError.value(
          segment.hex,
          'segments',
          'Only one transport segment may occupy a hex.',
        );
      }
      byHex[segment.hex] = segment;
    }
    final immutableByHex = Map<HexCoord, TransportSegment>.unmodifiable(byHex);
    return TransportNetworkState._(
      immutableByHex,
      _routingFingerprint(immutableByHex.values),
    );
  }

  const TransportNetworkState._(this.byHex, this.routingFingerprint);

  static const empty = TransportNetworkState._({}, '');

  final Map<HexCoord, TransportSegment> byHex;

  /// Compact, deterministic identity of the routing-relevant network state.
  ///
  /// It is computed once when the immutable aggregate is created, so checking
  /// many persisted merchant routes does not repeatedly scan every road.
  final String routingFingerprint;

  bool get isEmpty => byHex.isEmpty;
  bool get isNotEmpty => byHex.isNotEmpty;
  Iterable<TransportSegment> get segments => byHex.values;

  TransportSegment? at(int col, int row) => byHex[HexCoord(col: col, row: row)];

  bool hasOperationalRoadAt(int col, int row) {
    final segment = at(col, row);
    return segment?.kind == TransportSegmentKind.road &&
        segment?.isOperational == true;
  }

  TransportNetworkState put(TransportSegment segment) {
    if (byHex[segment.hex] == segment) return this;
    return TransportNetworkState(
      segments: [
        for (final entry in byHex.entries)
          if (entry.key != segment.hex) entry.value,
        segment,
      ],
    );
  }

  TransportNetworkState removeAt(int col, int row) {
    final hex = HexCoord(col: col, row: row);
    if (!byHex.containsKey(hex)) return this;
    return TransportNetworkState(
      segments: [
        for (final entry in byHex.entries)
          if (entry.key != hex) entry.value,
      ],
    );
  }

  factory TransportNetworkState.fromJson(Object? value) {
    if (value == null) return empty;
    if (value is! List<dynamic>) {
      throw const FormatException('transportNetwork must be a JSON array.');
    }
    return TransportNetworkState(
      segments: [
        for (final entry in value)
          TransportSegment.fromJson(
            entry is Map<String, dynamic>
                ? entry
                : Map<String, dynamic>.from(entry as Map),
          ),
      ],
    );
  }

  List<Map<String, dynamic>> toJson() {
    final ordered = _orderedSegments(segments);
    return [for (final segment in ordered) segment.toJson()];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransportNetworkState && mapEquals(other.byHex, byHex);

  @override
  int get hashCode => mapHash(byHex);
}

List<TransportSegment> _orderedSegments(Iterable<TransportSegment> segments) {
  return segments.toList()..sort((left, right) {
    final col = left.hex.col.compareTo(right.hex.col);
    if (col != 0) return col;
    return left.hex.row.compareTo(right.hex.row);
  });
}

String _routingFingerprint(Iterable<TransportSegment> segments) {
  final ordered = _orderedSegments(segments);
  if (ordered.isEmpty) return '';

  var first = 0x811C9DC5;
  var second = 0x9E3779B9;
  void add(String value) {
    for (final codeUnit in value.codeUnits) {
      first = ((first ^ codeUnit) * 0x01000193) & 0xFFFFFFFF;
      second = ((second ^ codeUnit) * 0x85EBCA6B) & 0xFFFFFFFF;
    }
    first = ((first ^ 0xFF) * 0x01000193) & 0xFFFFFFFF;
    second = ((second ^ 0xFF) * 0x85EBCA6B) & 0xFFFFFFFF;
  }

  for (final segment in ordered) {
    add('${segment.hex.col}');
    add('${segment.hex.row}');
    add(segment.kind.name);
    add(segment.condition.name);
    add(segment.builtByPlayerId);
    add(segment.builtByCityId ?? '');
  }
  return '${first.toRadixString(16).padLeft(8, '0')}'
      '${second.toRadixString(16).padLeft(8, '0')}';
}
