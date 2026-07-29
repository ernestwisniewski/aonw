import 'package:aonw_core/game/application/engine/combat_animation_fact.dart';

/// Stable renderer-neutral JSON carried beside a combat domain event.
///
/// The enclosing event position is authoritative for [eventIndex], so the
/// serialized payload contains geometry and entity identity only.
abstract final class CombatAnimationFactCodec {
  static const eventPayloadKey = 'combatAnimation';

  static Map<String, dynamic> toJson(CombatAnimationFact fact) => {
    'attackerUnitId': fact.attackerUnitId,
    'defenderId': fact.defenderId,
    'attackerFromCol': fact.attackerFromCol,
    'attackerFromRow': fact.attackerFromRow,
    'attackerToCol': fact.attackerToCol,
    'attackerToRow': fact.attackerToRow,
  };

  static CombatAnimationFact fromJson(Object? raw, {required int eventIndex}) {
    if (raw is! Map<Object?, Object?>) {
      throw const FormatException(
        'Combat animation fact must be a JSON object.',
      );
    }
    return CombatAnimationFact(
      eventIndex: eventIndex,
      attackerUnitId: _string(raw, 'attackerUnitId'),
      defenderId: _string(raw, 'defenderId'),
      attackerFromCol: _int(raw, 'attackerFromCol'),
      attackerFromRow: _int(raw, 'attackerFromRow'),
      attackerToCol: _int(raw, 'attackerToCol'),
      attackerToRow: _int(raw, 'attackerToRow'),
    );
  }

  static List<CombatAnimationFact> fromEventPayloads(
    Iterable<Map<String, dynamic>> payloads,
  ) {
    final facts = <CombatAnimationFact>[];
    var eventIndex = 0;
    for (final payload in payloads) {
      final raw = payload[eventPayloadKey];
      if (raw != null) {
        facts.add(fromJson(raw, eventIndex: eventIndex));
      }
      eventIndex += 1;
    }
    return List.unmodifiable(facts);
  }

  static String _string(Map<Object?, Object?> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Combat animation fact.$key must be a string.');
  }

  static int _int(Map<Object?, Object?> json, String key) {
    final value = json[key];
    if (value is int) return value;
    throw FormatException('Combat animation fact.$key must be an integer.');
  }
}
