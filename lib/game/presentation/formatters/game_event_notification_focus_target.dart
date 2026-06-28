import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/services/map_focus_visibility.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';

sealed class GameEventNotificationFocusTarget {
  const GameEventNotificationFocusTarget({
    required this.id,
    required this.col,
    required this.row,
  });

  final String id;
  final int col;
  final int row;

  GameCommand get selectCommand;
}

final class UnitNotificationFocusTarget
    extends GameEventNotificationFocusTarget {
  const UnitNotificationFocusTarget({
    required super.id,
    required super.col,
    required super.row,
  });

  @override
  GameCommand get selectCommand => SelectUnitCommand(id);
}

final class CityNotificationFocusTarget
    extends GameEventNotificationFocusTarget {
  const CityNotificationFocusTarget({
    required super.id,
    required super.col,
    required super.row,
  });

  @override
  GameCommand get selectCommand => SelectCityCommand(id);
}

final class TileNotificationFocusTarget
    extends GameEventNotificationFocusTarget {
  const TileNotificationFocusTarget({
    required super.id,
    required super.col,
    required super.row,
  });

  @override
  GameCommand get selectCommand => SelectTileCommand(col, row);
}

GameEventNotificationFocusTarget? gameEventNotificationFocusTarget(
  GameEvent event,
  GameState state, {
  String? viewerPlayerId,
}) {
  return switch (event) {
    CombatResolvedEvent(:final attackerUnitId, :final defenderUnitId) ||
    UnitAttackedEvent(:final attackerUnitId, :final defenderUnitId) =>
      _cityTarget(state, defenderUnitId, viewerPlayerId: viewerPlayerId) ??
          _unitTarget(state, attackerUnitId, viewerPlayerId: viewerPlayerId) ??
          _unitTarget(state, defenderUnitId, viewerPlayerId: viewerPlayerId),
    UnitKilledEvent(:final attackerUnitId) =>
      attackerUnitId == null
          ? null
          : _unitTarget(state, attackerUnitId, viewerPlayerId: viewerPlayerId),
    UnitRetreatedEvent(:final unitId) => _unitTarget(
      state,
      unitId,
      viewerPlayerId: viewerPlayerId,
    ),
    CityCapturedEvent(:final cityId) => _cityTarget(
      state,
      cityId,
      viewerPlayerId: viewerPlayerId,
    ),
    CityDestroyedEvent() => null,
    CityFoundedEvent(:final cityId) => _cityTarget(
      state,
      cityId,
      viewerPlayerId: viewerPlayerId,
    ),
    CityBuiltBuildingEvent(:final cityId) => _cityTarget(
      state,
      cityId,
      viewerPlayerId: viewerPlayerId,
    ),
    CityProducedUnitEvent(:final cityId) => _cityTarget(
      state,
      cityId,
      viewerPlayerId: viewerPlayerId,
    ),
    CityClaimedHexEvent(:final cityId) => _cityTarget(
      state,
      cityId,
      viewerPlayerId: viewerPlayerId,
    ),
    UnitMovedEvent(:final unitId) => _unitTarget(
      state,
      unitId,
      viewerPlayerId: viewerPlayerId,
    ),
    UnitGainedExperienceEvent(:final unitId) => _unitTarget(
      state,
      unitId,
      viewerPlayerId: viewerPlayerId,
    ),
    WorkerCompletedJobEvent(:final unitId) => _unitTarget(
      state,
      unitId,
      viewerPlayerId: viewerPlayerId,
    ),
    DominationThresholdReachedEvent(:final playerId) => _playerAnchorTarget(
      state,
      playerId,
      viewerPlayerId: viewerPlayerId,
    ),
    TurnEndedEvent() ||
    ResearchPointsGainedEvent() ||
    StrategicResourceDiscoveredEvent(
      nearestUnclaimedCol: null,
      nearestUnclaimedRow: null,
    ) ||
    DiplomaticProposalSentEvent() ||
    DiplomaticProposalRespondedEvent() ||
    DiplomaticProposalExpiredEvent() ||
    DiplomaticRelationChangedEvent() ||
    DiplomaticMessageSentEvent() ||
    DiplomaticMessageRespondedEvent() ||
    DiplomaticScoreChangedEvent() ||
    DiplomaticPromiseBrokenEvent() ||
    PlayerTimedOutEvent() ||
    TurnAutoResolvedEvent() ||
    PlayerKickedEvent() ||
    CommandRejectedEvent() ||
    AllPlayersSubmittedEvent() => null,
    TechnologyResearchedEvent(:final playerId) => _playerAnchorTarget(
      state,
      playerId,
      viewerPlayerId: viewerPlayerId,
    ),
    StrategicResourceDiscoveredEvent(
      :final nearestUnclaimedCol,
      :final nearestUnclaimedRow,
    ) =>
      nearestUnclaimedCol == null || nearestUnclaimedRow == null
          ? null
          : TileNotificationFocusTarget(
              id: 'resource_${nearestUnclaimedCol}_$nearestUnclaimedRow',
              col: nearestUnclaimedCol,
              row: nearestUnclaimedRow,
            ),
    MapObjectiveSecuredEvent(:final objectiveId, :final col, :final row) =>
      TileNotificationFocusTarget(
        id: 'objective_$objectiveId',
        col: col,
        row: row,
      ),
    CivilizationMetEvent(:final metPlayerId) => _playerAnchorTarget(
      state,
      metPlayerId,
      viewerPlayerId: viewerPlayerId,
    ),
  };
}

UnitNotificationFocusTarget? _unitTarget(
  GameState state,
  String unitId, {
  String? viewerPlayerId,
}) {
  final unit = state.unitById(unitId);
  if (unit == null) return null;
  if (!MapFocusVisibility.canFocusUnit(
    state,
    unit,
    viewerPlayerId: viewerPlayerId,
  )) {
    return null;
  }
  return UnitNotificationFocusTarget(id: unit.id, col: unit.col, row: unit.row);
}

CityNotificationFocusTarget? _cityTarget(
  GameState state,
  String cityId, {
  String? viewerPlayerId,
}) {
  final city = state.cityById(cityId);
  if (city == null) return null;
  if (!MapFocusVisibility.canAutoFocusCity(
    state,
    city,
    viewerPlayerId: viewerPlayerId,
  )) {
    return null;
  }
  return CityNotificationFocusTarget(
    id: city.id,
    col: city.center.col,
    row: city.center.row,
  );
}

GameEventNotificationFocusTarget? _playerAnchorTarget(
  GameState state,
  String playerId, {
  String? viewerPlayerId,
}) {
  for (final city in state.cities) {
    if (city.ownerPlayerId == playerId) {
      if (!MapFocusVisibility.canAutoFocusCity(
        state,
        city,
        viewerPlayerId: viewerPlayerId,
      )) {
        continue;
      }
      return CityNotificationFocusTarget(
        id: city.id,
        col: city.center.col,
        row: city.center.row,
      );
    }
  }
  for (final unit in state.units) {
    if (unit.ownerPlayerId == playerId) {
      if (!MapFocusVisibility.canFocusUnit(
        state,
        unit,
        viewerPlayerId: viewerPlayerId,
      )) {
        continue;
      }
      return UnitNotificationFocusTarget(
        id: unit.id,
        col: unit.col,
        row: unit.row,
      );
    }
  }
  return null;
}
