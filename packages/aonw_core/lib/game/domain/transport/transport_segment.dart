import 'package:aonw_core/domain/hex_coord.dart';

enum TransportSegmentKind { road }

enum TransportSegmentCondition { operational, pillaged }

/// One transport improvement occupying a map hex.
///
/// Transport is intentionally independent from economic field improvements,
/// so a road can coexist with a farm, mine, or other tile improvement.
final class TransportSegment {
  const TransportSegment({
    required this.hex,
    this.kind = TransportSegmentKind.road,
    this.condition = TransportSegmentCondition.operational,
    required this.builtByPlayerId,
    this.builtByCityId,
  });

  final HexCoord hex;
  final TransportSegmentKind kind;
  final TransportSegmentCondition condition;
  final String builtByPlayerId;
  final String? builtByCityId;

  bool get isOperational => condition == TransportSegmentCondition.operational;

  factory TransportSegment.fromJson(Map<String, dynamic> json) {
    final builtByPlayerId = json['builtByPlayerId'];
    if (builtByPlayerId is! String || builtByPlayerId.isEmpty) {
      throw const FormatException(
        'TransportSegment.builtByPlayerId must be a non-empty string.',
      );
    }
    return TransportSegment(
      hex: HexCoord(
        col: _requiredInt(json, 'col'),
        row: _requiredInt(json, 'row'),
      ),
      kind: _enumValue(
        json['kind'],
        TransportSegmentKind.values,
        'TransportSegment.kind',
      ),
      condition: _enumValue(
        json['condition'],
        TransportSegmentCondition.values,
        'TransportSegment.condition',
      ),
      builtByPlayerId: builtByPlayerId,
      builtByCityId: switch (json['builtByCityId']) {
        null => null,
        final String value when value.isNotEmpty => value,
        _ => throw const FormatException(
          'TransportSegment.builtByCityId must be a non-empty string or null.',
        ),
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'col': hex.col,
    'row': hex.row,
    'kind': kind.name,
    'condition': condition.name,
    'builtByPlayerId': builtByPlayerId,
    if (builtByCityId != null) 'builtByCityId': builtByCityId,
  };

  TransportSegment copyWith({
    TransportSegmentCondition? condition,
    String? builtByPlayerId,
    Object? builtByCityId = _unset,
  }) {
    return TransportSegment(
      hex: hex,
      kind: kind,
      condition: condition ?? this.condition,
      builtByPlayerId: builtByPlayerId ?? this.builtByPlayerId,
      builtByCityId: identical(builtByCityId, _unset)
          ? this.builtByCityId
          : builtByCityId as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransportSegment &&
          other.hex == hex &&
          other.kind == kind &&
          other.condition == condition &&
          other.builtByPlayerId == builtByPlayerId &&
          other.builtByCityId == builtByCityId;

  @override
  int get hashCode =>
      Object.hash(hex, kind, condition, builtByPlayerId, builtByCityId);
}

const Object _unset = Object();

int _requiredInt(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is num && value.toInt() == value) return value.toInt();
  throw FormatException('TransportSegment.$field must be an integer.');
}

T _enumValue<T extends Enum>(Object? value, List<T> values, String label) {
  if (value is String) {
    for (final candidate in values) {
      if (candidate.name == value) return candidate;
    }
  }
  throw FormatException('$label has an unsupported value: $value.');
}
