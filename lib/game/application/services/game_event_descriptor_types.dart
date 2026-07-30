part of 'game_event_descriptor.dart';

enum GameEventMessageGroup {
  city,
  unit,
  combat,
  turn,
  research,
  objective,
  diplomacy,
  system,
}

enum GameEventRendererEffectKind {
  none,
  unitMoved,
  fortifiedUnitThreatened,
  cityFounded,
  cityProducedUnit,
  cityClaimedHex,
  unitKilled,
  unitRetreated,
  combatResolved,
  workerCompletedJob,
  technologyResearched,
}

enum GameEventSoundCueKind { none, city, combat }

enum GameEventActivityCategory { combat, city, diplomacy, technology }

enum GameEventDiplomaticPopupTone { neutral, positive, negative }

sealed class GameEventFocusHint {
  const GameEventFocusHint();
}

final class UnitGameEventFocusHint extends GameEventFocusHint {
  const UnitGameEventFocusHint(this.unitId);

  final String unitId;
}

final class CityGameEventFocusHint extends GameEventFocusHint {
  const CityGameEventFocusHint(this.cityId);

  final String cityId;
}

final class TileGameEventFocusHint extends GameEventFocusHint {
  const TileGameEventFocusHint({
    required this.id,
    required this.col,
    required this.row,
  });

  final String id;
  final int col;
  final int row;
}

final class PlayerAnchorGameEventFocusHint extends GameEventFocusHint {
  const PlayerAnchorGameEventFocusHint(this.playerId);

  final String playerId;
}

typedef _GameEventPlayerIdsResolver =
    List<String> Function(
      GameState state,
      GameState? previousState,
      String? visiblePlayerId,
    );

typedef _CriticalNotificationResolver =
    bool Function(GameState state, String playerId);
