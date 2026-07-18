import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

/// Persistence-neutral result of an artifact command involving a unit.
final class ArtifactUnitCommandResult {
  const ArtifactUnitCommandResult._accepted({
    required this.units,
    required this.artifacts,
  }) : accepted = true,
       reason = null;

  const ArtifactUnitCommandResult._rejected({
    required this.units,
    required this.artifacts,
    required this.reason,
  }) : accepted = false;

  final bool accepted;
  final String? reason;
  final List<GameUnit> units;
  final List<WorldArtifact> artifacts;
}

/// Persistence-neutral result of an artifact trade.
final class ArtifactTradeCommandResult {
  const ArtifactTradeCommandResult._accepted({
    required this.artifacts,
    required this.playerGold,
  }) : accepted = true,
       reason = null;

  const ArtifactTradeCommandResult._rejected({
    required this.artifacts,
    required this.playerGold,
    required this.reason,
  }) : accepted = false;

  final bool accepted;
  final String? reason;
  final List<WorldArtifact> artifacts;
  final Map<String, int> playerGold;
}

/// Applies artifact rules without depending on a state container.
abstract final class ArtifactCommandResolver {
  static const excavationTurns = 2;

  static ArtifactUnitCommandResult startExcavation({
    required List<GameUnit> units,
    required List<WorldArtifact> artifacts,
    required StartArtifactExcavationCommand command,
    required String actorPlayerId,
  }) {
    final controlled = _controlledUnit(units, command.unitId, actorPlayerId);
    if (controlled.reason case final reason?) {
      return _rejectUnit(units, artifacts, reason);
    }
    final unit = controlled.unit!;
    final availabilityReason = _excavationAvailabilityReason(unit);
    if (availabilityReason != null) {
      return _rejectUnit(units, artifacts, availabilityReason);
    }
    final artifact = _mapArtifactAt(artifacts, unit.col, unit.row);
    if (artifact == null) {
      return _rejectUnit(units, artifacts, 'artifact_not_found');
    }

    final nextUnit = unit
        .copyWith(movementPoints: 0)
        .copyWithQueuedPath(null)
        .copyWithExcavatingArtifact(artifact.id);
    final nextArtifact = artifact.copyWith(
      location: WorldArtifactLocation.excavation(
        unitId: unit.id,
        col: unit.col,
        row: unit.row,
        remainingTurns: excavationTurns,
      ),
    );
    return ArtifactUnitCommandResult._accepted(
      units: _replaceUnit(units, nextUnit),
      artifacts: _replaceArtifact(artifacts, nextArtifact),
    );
  }

  static ArtifactUnitCommandResult storeInCity({
    required List<GameUnit> units,
    required List<GameCity> cities,
    required List<WorldArtifact> artifacts,
    required StoreArtifactInCityCommand command,
    required String actorPlayerId,
  }) {
    final controlled = _controlledUnit(units, command.unitId, actorPlayerId);
    if (controlled.reason case final reason?) {
      return _rejectUnit(units, artifacts, reason);
    }
    final unit = controlled.unit!;
    final carried = _carriedArtifactFor(unit, artifacts);
    if (carried.reason case final reason?) {
      return _rejectUnit(units, artifacts, reason);
    }
    final city = _cityForArtifactStore(
      unit: unit,
      cities: cities,
      artifacts: artifacts,
      requestedCityId: command.cityId,
      actorPlayerId: actorPlayerId,
    );
    if (city.reason case final reason?) {
      return _rejectUnit(units, artifacts, reason);
    }

    return ArtifactUnitCommandResult._accepted(
      units: _replaceUnit(units, unit.copyWithCarriedArtifact(null)),
      artifacts: _replaceArtifact(
        artifacts,
        carried.artifact!.copyWith(
          location: WorldArtifactLocation.stored(cityId: city.city!.id),
        ),
      ),
    );
  }

  static ArtifactTradeCommandResult tradeArtifact({
    required List<GameCity> cities,
    required List<WorldArtifact> artifacts,
    required Map<String, int> playerGold,
    required DiplomacyState diplomacy,
    required TradeArtifactCommand command,
    required String actorPlayerId,
  }) {
    final requestReason = _tradeRequestRejectionReason(command, actorPlayerId);
    if (requestReason != null) {
      return _rejectTrade(artifacts, playerGold, requestReason);
    }
    final permissionReason = _tradePermissionRejectionReason(
      command: command,
      playerGold: playerGold,
      diplomacy: diplomacy,
    );
    if (permissionReason != null) {
      return _rejectTrade(artifacts, playerGold, permissionReason);
    }

    final offered = _artifactById(artifacts, command.offeredArtifactId);
    if (offered == null ||
        !_artifactStoredByPlayer(
          cities: cities,
          artifact: offered,
          playerId: command.playerId,
        )) {
      return _rejectTrade(
        artifacts,
        playerGold,
        'offered_artifact_unavailable',
      );
    }
    final targetCity = _firstEmptyArtifactCity(
      cities: cities,
      artifacts: artifacts,
      playerId: command.targetPlayerId,
    );
    if (targetCity == null) {
      return _rejectTrade(
        artifacts,
        playerGold,
        'target_artifact_slot_unavailable',
      );
    }

    return ArtifactTradeCommandResult._accepted(
      artifacts: _replaceArtifact(
        artifacts,
        offered.copyWith(
          location: WorldArtifactLocation.stored(cityId: targetCity.id),
        ),
      ),
      playerGold: _transferOfferedGold(playerGold, command),
    );
  }

  static _ControlledUnit _controlledUnit(
    List<GameUnit> units,
    String unitId,
    String actorPlayerId,
  ) {
    final unit = units.byId(unitId);
    if (unit == null) return (unit: null, reason: 'unit_not_found');
    if (unit.ownerPlayerId != actorPlayerId) {
      return (unit: null, reason: 'unit_not_controlled');
    }
    return (unit: unit, reason: null);
  }

  static String? _excavationAvailabilityReason(GameUnit unit) {
    if (unit.isWorking || unit.isFortified) return 'unit_unavailable';
    if (unit.carriedArtifactId != null) {
      return 'unit_already_carrying_artifact';
    }
    return null;
  }

  static _CarriedArtifact _carriedArtifactFor(
    GameUnit unit,
    List<WorldArtifact> artifacts,
  ) {
    final carriedArtifactId = unit.carriedArtifactId;
    if (carriedArtifactId == null) {
      return (artifact: null, reason: 'unit_not_carrying_artifact');
    }
    final artifact = _artifactById(artifacts, carriedArtifactId);
    if (artifact == null ||
        artifact.location.unitId != unit.id ||
        !artifact.location.isCarried) {
      return (artifact: null, reason: 'carried_artifact_not_found');
    }
    return (artifact: artifact, reason: null);
  }

  static _ArtifactStoreCity _cityForArtifactStore({
    required GameUnit unit,
    required List<GameCity> cities,
    required List<WorldArtifact> artifacts,
    required String? requestedCityId,
    required String actorPlayerId,
  }) {
    final city = requestedCityId == null
        ? cities.cityAt(unit.col, unit.row)
        : cities.byId(requestedCityId);
    if (city == null) return (city: null, reason: 'city_not_found');
    if (city.ownerPlayerId != actorPlayerId) {
      return (city: null, reason: 'city_not_controlled');
    }
    if (!city.occupiesCenter(unit.col, unit.row)) {
      return (city: null, reason: 'unit_not_in_city');
    }
    if (_storedArtifactInCity(artifacts, city.id) != null) {
      return (city: null, reason: 'city_artifact_slot_full');
    }
    return (city: city, reason: null);
  }

  static String? _tradeRequestRejectionReason(
    TradeArtifactCommand command,
    String actorPlayerId,
  ) {
    if (command.playerId != actorPlayerId || command.playerId.isEmpty) {
      return 'invalid_artifact_trade_actor';
    }
    if (command.targetPlayerId.isEmpty ||
        command.targetPlayerId == command.playerId) {
      return 'invalid_artifact_trade_target';
    }
    if (command.offeredGold < 0 || command.requestedGold < 0) {
      return 'invalid_artifact_trade_gold';
    }
    if (command.requestedArtifactId != null || command.requestedGold > 0) {
      return 'artifact_trade_requires_acceptance';
    }
    return null;
  }

  static String? _tradePermissionRejectionReason({
    required TradeArtifactCommand command,
    required Map<String, int> playerGold,
    required DiplomacyState diplomacy,
  }) {
    if (diplomacy.statusBetween(command.playerId, command.targetPlayerId) ==
        DiplomaticRelationStatus.war) {
      return 'artifact_trade_blocked_by_war';
    }
    if ((playerGold[command.playerId] ?? 0) < command.offeredGold ||
        (playerGold[command.targetPlayerId] ?? 0) < command.requestedGold) {
      return 'artifact_trade_gold_unavailable';
    }
    return null;
  }

  static ArtifactUnitCommandResult _rejectUnit(
    List<GameUnit> units,
    List<WorldArtifact> artifacts,
    String reason,
  ) {
    return ArtifactUnitCommandResult._rejected(
      units: units,
      artifacts: artifacts,
      reason: reason,
    );
  }

  static ArtifactTradeCommandResult _rejectTrade(
    List<WorldArtifact> artifacts,
    Map<String, int> playerGold,
    String reason,
  ) {
    return ArtifactTradeCommandResult._rejected(
      artifacts: artifacts,
      playerGold: playerGold,
      reason: reason,
    );
  }

  static WorldArtifact? _artifactById(
    List<WorldArtifact> artifacts,
    String artifactId,
  ) {
    for (final artifact in artifacts) {
      if (artifact.id == artifactId) return artifact;
    }
    return null;
  }

  static WorldArtifact? _mapArtifactAt(
    List<WorldArtifact> artifacts,
    int col,
    int row,
  ) {
    for (final artifact in artifacts) {
      if (artifact.location.isOnMap &&
          artifact.location.occupiesMapTile(col, row)) {
        return artifact;
      }
    }
    return null;
  }

  static WorldArtifact? _storedArtifactInCity(
    Iterable<WorldArtifact> artifacts,
    String cityId,
  ) {
    for (final artifact in artifacts) {
      if (artifact.location.isStored && artifact.location.cityId == cityId) {
        return artifact;
      }
    }
    return null;
  }

  static bool _artifactStoredByPlayer({
    required List<GameCity> cities,
    required WorldArtifact artifact,
    required String playerId,
  }) {
    final cityId = artifact.location.cityId;
    if (!artifact.location.isStored || cityId == null) return false;
    return cities.byId(cityId)?.ownerPlayerId == playerId;
  }

  static GameCity? _firstEmptyArtifactCity({
    required List<GameCity> cities,
    required List<WorldArtifact> artifacts,
    required String playerId,
  }) {
    final candidates = [
      for (final city in cities)
        if (city.ownerPlayerId == playerId) city,
    ]..sort((a, b) => a.id.compareTo(b.id));
    for (final city in candidates) {
      if (_storedArtifactInCity(artifacts, city.id) == null) return city;
    }
    return null;
  }

  static Map<String, int> _transferOfferedGold(
    Map<String, int> playerGold,
    TradeArtifactCommand command,
  ) {
    final updated = Map<String, int>.from(playerGold);
    updated[command.playerId] =
        (updated[command.playerId] ?? 0) - command.offeredGold;
    updated[command.targetPlayerId] =
        (updated[command.targetPlayerId] ?? 0) + command.offeredGold;
    return Map<String, int>.unmodifiable(updated);
  }

  static List<GameUnit> _replaceUnit(List<GameUnit> units, GameUnit updated) {
    return List<GameUnit>.unmodifiable([
      for (final unit in units)
        if (unit.id == updated.id) updated else unit,
    ]);
  }

  static List<WorldArtifact> _replaceArtifact(
    List<WorldArtifact> artifacts,
    WorldArtifact updated,
  ) {
    return List<WorldArtifact>.unmodifiable([
      for (final artifact in artifacts)
        if (artifact.id == updated.id) updated else artifact,
    ]);
  }
}

typedef _ControlledUnit = ({GameUnit? unit, String? reason});
typedef _CarriedArtifact = ({WorldArtifact? artifact, String? reason});
typedef _ArtifactStoreCity = ({GameCity? city, String? reason});
