import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/util/wire_json.dart';

/// Internal event-log codec for authoritative player commands.
abstract final class RecordedDomainCommandCodec {
  static Map<String, dynamic> toJson(DomainCommand command) =>
      DomainCommandCodec.toJson(command);

  static DomainCommand? fromJson(Map<String, dynamic> json) {
    final type = requiredStringField(json, 'RecordedDomainCommand', 'type');
    if (_nonDomainHistoricalTypes.contains(type)) return null;
    return DomainCommandCodec.fromJson(json);
  }

  /// Compatibility read path. Historical UI intents and obsolete lifecycle
  /// messages are intentionally ignored instead of being reintroduced into
  /// the authoritative command type.
  static const _nonDomainHistoricalTypes = {
    'ResetUnitMovement',
    'SetActivePlayer',
    'TileTapped',
    'CityTapped',
    'StartMerchantTradeRouteSelection',
    'CancelMerchantTradeRouteSelection',
    'StartMerchantMoveToCitySelection',
    'CancelMerchantMoveToCitySelection',
    'CancelResearchSelection',
    'ToggleMoveTargeting',
    'StartCityFounding',
    'CancelCityFounding',
    'StartCityWorkedHexSelection',
    'CancelCityWorkedHexSelection',
    'StartCityExpansionSelection',
    'CancelCityExpansionSelection',
    'StartWorkerActionSelection',
    'CancelWorkerActionSelection',
    'StartAttackTargeting',
    'CancelAttackTargeting',
    'StartCommanderMergeSelection',
    'CancelCommanderMergeSelection',
    'SelectTile',
    'SelectUnit',
    'SelectCity',
    'SelectFieldImprovement',
    'FocusNextPendingAction',
    'FocusTurnStartAction',
  };
}
