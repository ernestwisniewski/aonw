import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';

class PersistentArtifactCommandResult {
  const PersistentArtifactCommandResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final String? reason;
}

class PersistentArtifactCommandResolver {
  const PersistentArtifactCommandResolver();

  static const excavationTurns = 2;

  PersistentArtifactCommandResult startExcavation({
    required PersistentGameState state,
    required StartArtifactExcavationCommand command,
    required String actorPlayerId,
  }) {
    final unit = state.units.byId(command.unitId);
    if (unit == null) return _reject(state, 'unit_not_found');
    if (unit.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'unit_not_controlled');
    }
    if (unit.isWorking || unit.isFortified) {
      return _reject(state, 'unit_unavailable');
    }
    if (unit.carriedArtifactId != null) {
      return _reject(state, 'unit_already_carrying_artifact');
    }
    final artifact = _mapArtifactAt(state.artifacts, unit.col, unit.row);
    if (artifact == null) return _reject(state, 'artifact_not_found');

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

    return PersistentArtifactCommandResult(
      accepted: true,
      state: state.copyWith(
        units: _replaceUnit(state.units, nextUnit),
        artifacts: _replaceArtifact(state.artifacts, nextArtifact),
      ),
    );
  }

  PersistentArtifactCommandResult storeInCity({
    required PersistentGameState state,
    required StoreArtifactInCityCommand command,
    required String actorPlayerId,
  }) {
    final unit = state.units.byId(command.unitId);
    if (unit == null) return _reject(state, 'unit_not_found');
    if (unit.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'unit_not_controlled');
    }
    final carriedArtifactId = unit.carriedArtifactId;
    if (carriedArtifactId == null) {
      return _reject(state, 'unit_not_carrying_artifact');
    }
    final artifact = _artifactById(state.artifacts, carriedArtifactId);
    if (artifact == null ||
        artifact.location.unitId != unit.id ||
        !artifact.location.isCarried) {
      return _reject(state, 'carried_artifact_not_found');
    }
    final city = command.cityId == null
        ? _cityAt(state, unit.col, unit.row)
        : state.cities.byId(command.cityId!);
    if (city == null) return _reject(state, 'city_not_found');
    if (city.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'city_not_controlled');
    }
    if (!city.occupiesCenter(unit.col, unit.row)) {
      return _reject(state, 'unit_not_in_city');
    }
    if (_storedArtifactInCity(state.artifacts, city.id) != null) {
      return _reject(state, 'city_artifact_slot_full');
    }

    final nextUnit = unit.copyWithCarriedArtifact(null);
    final nextArtifact = artifact.copyWith(
      location: WorldArtifactLocation.stored(cityId: city.id),
    );
    return PersistentArtifactCommandResult(
      accepted: true,
      state: state.copyWith(
        units: _replaceUnit(state.units, nextUnit),
        artifacts: _replaceArtifact(state.artifacts, nextArtifact),
      ),
    );
  }

  PersistentArtifactCommandResult tradeArtifact({
    required PersistentGameState state,
    required TradeArtifactCommand command,
    required String actorPlayerId,
  }) {
    if (command.playerId != actorPlayerId || command.playerId.isEmpty) {
      return _reject(state, 'invalid_artifact_trade_actor');
    }
    if (command.targetPlayerId.isEmpty ||
        command.targetPlayerId == command.playerId) {
      return _reject(state, 'invalid_artifact_trade_target');
    }
    if (command.offeredGold < 0 || command.requestedGold < 0) {
      return _reject(state, 'invalid_artifact_trade_gold');
    }
    if (command.requestedArtifactId != null || command.requestedGold > 0) {
      return _reject(state, 'artifact_trade_requires_acceptance');
    }
    final relation = state.runtimeState.diplomacy.statusBetween(
      command.playerId,
      command.targetPlayerId,
    );
    if (relation == DiplomaticRelationStatus.war) {
      return _reject(state, 'artifact_trade_blocked_by_war');
    }
    if ((state.playerGold[command.playerId] ?? 0) < command.offeredGold ||
        (state.playerGold[command.targetPlayerId] ?? 0) <
            command.requestedGold) {
      return _reject(state, 'artifact_trade_gold_unavailable');
    }

    final offered = _artifactById(state.artifacts, command.offeredArtifactId);
    if (offered == null ||
        !_artifactStoredByPlayer(state, offered, command.playerId)) {
      return _reject(state, 'offered_artifact_unavailable');
    }
    final targetCity = _firstEmptyArtifactCity(state, command.targetPlayerId);
    if (targetCity == null) {
      return _reject(state, 'target_artifact_slot_unavailable');
    }

    final nextOffered = offered.copyWith(
      location: WorldArtifactLocation.stored(cityId: targetCity.id),
    );
    final artifacts = _replaceArtifact(state.artifacts, nextOffered);

    final playerGold = Map<String, int>.from(state.playerGold);
    playerGold[command.playerId] =
        (playerGold[command.playerId] ?? 0) - command.offeredGold;
    playerGold[command.targetPlayerId] =
        (playerGold[command.targetPlayerId] ?? 0) + command.offeredGold;

    return PersistentArtifactCommandResult(
      accepted: true,
      state: state.copyWith(
        artifacts: artifacts,
        playerGold: Map.unmodifiable(playerGold),
      ),
    );
  }

  PersistentArtifactCommandResult _reject(
    PersistentGameState state,
    String reason,
  ) {
    return PersistentArtifactCommandResult(
      accepted: false,
      state: state,
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

  static GameCity? _cityAt(PersistentGameState state, int col, int row) {
    for (final city in state.cities) {
      if (city.occupiesCenter(col, row)) return city;
    }
    return null;
  }

  static WorldArtifact? _storedArtifactInCity(
    Iterable<WorldArtifact> artifacts,
    String cityId, {
    String? ignoringArtifactId,
  }) {
    for (final artifact in artifacts) {
      if (artifact.id == ignoringArtifactId) continue;
      if (artifact.location.isStored && artifact.location.cityId == cityId) {
        return artifact;
      }
    }
    return null;
  }

  static bool _artifactStoredByPlayer(
    PersistentGameState state,
    WorldArtifact artifact,
    String playerId,
  ) {
    final cityId = artifact.location.cityId;
    if (!artifact.location.isStored || cityId == null) return false;
    final city = state.cities.byId(cityId);
    return city?.ownerPlayerId == playerId;
  }

  static GameCity? _firstEmptyArtifactCity(
    PersistentGameState state,
    String playerId, {
    String? ignoringArtifactId,
  }) {
    final cities = [
      for (final city in state.cities)
        if (city.ownerPlayerId == playerId) city,
    ]..sort((a, b) => a.id.compareTo(b.id));
    for (final city in cities) {
      if (_storedArtifactInCity(
            state.artifacts,
            city.id,
            ignoringArtifactId: ignoringArtifactId,
          ) ==
          null) {
        return city;
      }
    }
    return null;
  }

  static List<GameUnit> _replaceUnit(List<GameUnit> units, GameUnit updated) {
    return [
      for (final unit in units)
        if (unit.id == updated.id) updated else unit,
    ];
  }

  static List<WorldArtifact> _replaceArtifact(
    List<WorldArtifact> artifacts,
    WorldArtifact updated,
  ) {
    return [
      for (final artifact in artifacts)
        if (artifact.id == updated.id) updated else artifact,
    ];
  }
}
