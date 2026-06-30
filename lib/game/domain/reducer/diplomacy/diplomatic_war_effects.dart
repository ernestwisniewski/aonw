import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/trade.dart';

abstract final class DiplomaticWarEffects {
  static List<ResourceTradeAgreement> removeResourceTradeAgreementsBetween(
    Iterable<ResourceTradeAgreement> agreements,
    String playerAId,
    String playerBId,
  ) {
    final key = DiplomacyState.relationKey(playerAId, playerBId);
    return [
      for (final agreement in agreements)
        if (DiplomacyState.relationKey(
              agreement.exporterPlayerId,
              agreement.importerPlayerId,
            ) !=
            key)
          agreement,
    ];
  }

  static List<DiplomaticScoreChangedEvent> warmongerScoreEvents(
    Iterable<DiplomaticScoreEntry> entries,
  ) {
    return [
      for (final entry in entries)
        DiplomaticScoreChangedEvent(
          playerAId: entry.playerAId,
          playerBId: entry.playerBId,
          delta: entry.delta,
          scoreAfter: entry.scoreAfter,
          reason: entry.reason,
          sourceId: entry.sourceId,
        ),
    ];
  }
}
