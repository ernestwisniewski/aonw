import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/util/wire_json.dart';

typedef _CommandDecoder =
    GameCommand Function(Map<String, dynamic> json, String type);

/// Internal event-log codec for authoritative commands and historical reads.
///
/// New presentation intents are rejected. Intent decoding exists only so old
/// local logs remain readable at this explicit compatibility boundary.
abstract final class LoggedGameCommandCodec {
  static Map<String, dynamic> toJson(GameCommand command) {
    return switch (command) {
      DomainCommand() => GameCommandSerializer.toJson(command),
      GameIntent() => throw UnsupportedError(
        'Presentation intents cannot be written to the authoritative log.',
      ),
    };
  }

  static GameCommand? fromJson(Map<String, dynamic> json) {
    final type = requiredStringField(json, 'LoggedGameCommand', 'type');
    if (_unsupportedLifecycleTypes.contains(type)) return null;
    final decoder = _historicalDecoders[type];
    if (decoder != null) return decoder(json, type);
    return GameCommandSerializer.fromJson(json);
  }

  static const _unsupportedLifecycleTypes = {
    'ResetUnitMovement',
    'SetActivePlayer',
  };

  static final _historicalDecoders = <String, _CommandDecoder>{
    'TileTapped': (json, type) => TileTappedCommand(
      requiredIntField(json, type, 'col'),
      requiredIntField(json, type, 'row'),
    ),
    'CityTapped': (json, type) =>
        CityTappedCommand(requiredStringField(json, type, 'cityId')),
    'StartMerchantTradeRouteSelection': (json, type) =>
        StartMerchantTradeRouteSelectionCommand(
          requiredStringField(json, type, 'unitId'),
        ),
    'CancelMerchantTradeRouteSelection': (json, type) =>
        CancelMerchantTradeRouteSelectionCommand(
          requiredStringField(json, type, 'unitId'),
        ),
    'StartMerchantMoveToCitySelection': (json, type) =>
        StartMerchantMoveToCitySelectionCommand(
          requiredStringField(json, type, 'unitId'),
        ),
    'CancelMerchantMoveToCitySelection': (json, type) =>
        CancelMerchantMoveToCitySelectionCommand(
          requiredStringField(json, type, 'unitId'),
        ),
    'CancelResearchSelection': (json, type) => CancelResearchSelectionCommand(
      requiredStringField(json, type, 'playerId'),
    ),
    'ToggleMoveTargeting': (_, _) => const ToggleMoveTargetingCommand(),
    'StartCityFounding': (_, _) => const StartCityFoundingCommand(),
    'CancelCityFounding': (_, _) => const CancelCityFoundingCommand(),
    'StartCityWorkedHexSelection': (json, type) =>
        StartCityWorkedHexSelectionCommand(
          requiredStringField(json, type, 'cityId'),
        ),
    'CancelCityWorkedHexSelection': (json, type) =>
        CancelCityWorkedHexSelectionCommand(
          requiredStringField(json, type, 'cityId'),
        ),
    'StartCityExpansionSelection': (json, type) =>
        StartCityExpansionSelectionCommand(
          requiredStringField(json, type, 'cityId'),
        ),
    'CancelCityExpansionSelection': (json, type) =>
        CancelCityExpansionSelectionCommand(
          requiredStringField(json, type, 'cityId'),
        ),
    'StartWorkerActionSelection': (json, type) =>
        StartWorkerActionSelectionCommand(
          requiredStringField(json, type, 'unitId'),
        ),
    'CancelWorkerActionSelection': (json, type) =>
        CancelWorkerActionSelectionCommand(
          requiredStringField(json, type, 'unitId'),
        ),
    'StartAttackTargeting': (json, type) => StartAttackTargetingCommand(
      requiredStringField(json, type, 'attackerUnitId'),
    ),
    'CancelAttackTargeting': (json, type) => CancelAttackTargetingCommand(
      requiredStringField(json, type, 'attackerUnitId'),
    ),
    'StartCommanderMergeSelection': (json, type) =>
        StartCommanderMergeSelectionCommand(
          requiredStringField(json, type, 'commanderUnitId'),
        ),
    'CancelCommanderMergeSelection': (json, type) =>
        CancelCommanderMergeSelectionCommand(
          requiredStringField(json, type, 'commanderUnitId'),
        ),
    'SelectTile': (json, type) => SelectTileCommand(
      requiredIntField(json, type, 'col'),
      requiredIntField(json, type, 'row'),
    ),
    'SelectUnit': (json, type) =>
        SelectUnitCommand(requiredStringField(json, type, 'unitId')),
    'SelectCity': (json, type) =>
        SelectCityCommand(requiredStringField(json, type, 'cityId')),
    'FocusNextPendingAction': (json, type) => FocusNextPendingActionCommand(
      requiredStringField(json, type, 'playerId'),
      preferredObjectiveAdvice: optionalEnumField(
        json,
        type,
        'preferredObjectiveAdvice',
        GameObjectiveAdvice.values,
      ),
      actionIndex: optionalIntField(json, type, 'actionIndex'),
      actionStep: optionalIntField(json, type, 'actionStep') ?? 1,
    ),
    'FocusTurnStartAction': (json, type) => FocusTurnStartActionCommand(
      requiredStringField(json, type, 'playerId'),
    ),
  };
}
