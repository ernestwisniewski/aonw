import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';

enum DiplomaticWarmongerAction { declarationOfWar, cityAttack }

final class DiplomaticWarmongerReputationResult {
  const DiplomaticWarmongerReputationResult({
    required this.diplomacy,
    required this.entries,
  });

  final DiplomacyState diplomacy;
  final List<DiplomaticScoreEntry> entries;
}

abstract final class DiplomaticWarmongerReputation {
  static const int declarationOfWarPenalty = -8;
  static const int cityAttackPenalty = -12;

  static DiplomaticWarmongerReputationResult apply({
    required DiplomacyState diplomacy,
    required String aggressorPlayerId,
    required String victimPlayerId,
    required DiplomaticWarmongerAction action,
    int? turn,
    String? sourceId,
  }) {
    if (aggressorPlayerId.isEmpty ||
        victimPlayerId.isEmpty ||
        aggressorPlayerId == victimPlayerId) {
      return DiplomaticWarmongerReputationResult(
        diplomacy: diplomacy,
        entries: const [],
      );
    }

    var next = diplomacy;
    final entries = <DiplomaticScoreEntry>[];
    for (final observerId in _knownObservers(
      diplomacy,
      aggressorPlayerId,
      victimPlayerId,
    )) {
      final adjustment = next.adjustRelationScoreWithEntry(
        observerId,
        aggressorPlayerId,
        _penaltyFor(action),
        turn: turn,
        reason: DiplomaticScoreChangeReason.warmongerPenalty,
        sourceId:
            sourceId ??
            _sourceId(
              turn: turn,
              action: action,
              aggressorPlayerId: aggressorPlayerId,
              victimPlayerId: victimPlayerId,
            ),
      );
      next = adjustment.state;
      if (adjustment.entry != null) entries.add(adjustment.entry!);
    }

    return DiplomaticWarmongerReputationResult(
      diplomacy: next,
      entries: List.unmodifiable(entries),
    );
  }

  static int _penaltyFor(DiplomaticWarmongerAction action) {
    return switch (action) {
      DiplomaticWarmongerAction.declarationOfWar => declarationOfWarPenalty,
      DiplomaticWarmongerAction.cityAttack => cityAttackPenalty,
    };
  }

  static List<String> _knownObservers(
    DiplomacyState diplomacy,
    String aggressorPlayerId,
    String victimPlayerId,
  ) {
    final observers = <String>{};
    for (final key in diplomacy.contactKeys) {
      final pair = _decodeContactKey(key);
      if (pair == null) continue;
      final other = switch (pair) {
        (final a, final b) when a == aggressorPlayerId => b,
        (final a, final b) when b == aggressorPlayerId => a,
        _ => null,
      };
      if (other == null ||
          other == victimPlayerId ||
          other == aggressorPlayerId ||
          !diplomacy.hasContact(other, victimPlayerId)) {
        continue;
      }
      observers.add(other);
    }
    return observers.toList()..sort();
  }

  static (String, String)? _decodeContactKey(String key) {
    final parts = key.split('|');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      return null;
    }
    return (Uri.decodeComponent(parts[0]), Uri.decodeComponent(parts[1]));
  }

  static String _sourceId({
    required int? turn,
    required DiplomaticWarmongerAction action,
    required String aggressorPlayerId,
    required String victimPlayerId,
  }) {
    return 'warmonger.${turn ?? 0}.${action.name}.'
        '$aggressorPlayerId.$victimPlayerId';
  }
}
