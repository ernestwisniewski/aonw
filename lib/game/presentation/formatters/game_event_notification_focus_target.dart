import 'package:aonw/game/application/services/game_event_descriptor.dart';
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
  for (final hint in GameEventDescriptor.forEvent(event).focusHints) {
    final target = _focusTargetForHint(
      hint,
      state,
      viewerPlayerId: viewerPlayerId,
    );
    if (target != null) return target;
  }
  return null;
}

GameEventNotificationFocusTarget? _focusTargetForHint(
  GameEventFocusHint hint,
  GameState state, {
  String? viewerPlayerId,
}) {
  return switch (hint) {
    UnitGameEventFocusHint(:final unitId) => _unitTarget(
      state,
      unitId,
      viewerPlayerId: viewerPlayerId,
    ),
    CityGameEventFocusHint(:final cityId) => _cityTarget(
      state,
      cityId,
      viewerPlayerId: viewerPlayerId,
    ),
    TileGameEventFocusHint(:final id, :final col, :final row) =>
      TileNotificationFocusTarget(id: id, col: col, row: row),
    PlayerAnchorGameEventFocusHint(:final playerId) => _playerAnchorTarget(
      state,
      playerId,
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
