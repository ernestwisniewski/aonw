part of '../run_save_ai_benchmark.dart';

Set<String> _targetableOwnerIds(GameView view) {
  return {
    for (final unit in view.visibleTargetableEnemyUnits) unit.ownerPlayerId,
    for (final city in view.rememberedTargetableEnemyCities) city.ownerPlayerId,
  };
}

Set<String> _attackTargetOwnerIds(
  Iterable<GameCommand> commands,
  GameView view,
) {
  final ownerIds = <String>{};
  for (final command in commands) {
    if (command is! AttackHexCommand) continue;
    final ownerId = _ownerAt(view, command.defenderCol, command.defenderRow);
    if (ownerId != null) ownerIds.add(ownerId);
  }
  return ownerIds;
}

GameCommand? _firstCommandForUnit(
  Iterable<GameCommand> commands,
  String unitId,
) {
  for (final command in commands) {
    if (_commandPrimaryUnitId(command) == unitId) return command;
  }
  return null;
}

String? _commandPrimaryUnitId(GameCommand command) {
  return switch (command) {
    MoveUnitCommand(:final unitId) => unitId,
    CancelUnitActionCommand(:final unitId) => unitId,
    AttackHexCommand(:final attackerUnitId) => attackerUnitId,
    SkipUnitTurnCommand(:final unitId) => unitId,
    FortifyUnitCommand(:final unitId) => unitId,
    AutoExploreUnitCommand(:final unitId) => unitId,
    SelectWorkerImprovementCommand(:final unitId) => unitId,
    ConfirmWorkerImprovementCommand(:final unitId) => unitId,
    AssignWorkerToHexCommand(:final unitId) => unitId,
    CancelWorkerAssignmentCommand(:final unitId) => unitId,
    CancelWorkerJobCommand(:final unitId) => unitId,
    FoundCityCommand(:final founderId) => founderId,
    _ => null,
  };
}

GameUnit? _unitByIdOrNull(Iterable<GameUnit> units, String unitId) {
  for (final unit in units) {
    if (unit.id == unitId) return unit;
  }
  return null;
}

GameUnit? _unitAtOrNull(Iterable<GameUnit> units, int col, int row) {
  for (final unit in units) {
    if (unit.col == col && unit.row == row) return unit;
  }
  return null;
}

List<String> _sortedStrings(Iterable<String> values) {
  return values.toSet().toList()..sort();
}

GameSave _resetPlayerTurns(GameSave save) {
  return save.copyWith(
    playerStates: {
      for (final playerId in _activePlayerIds(save))
        playerId: PlayerTurnState.active,
    },
  );
}

GameState _prepareCycleState(
  GameState state, {
  required GameSave save,
  required Set<String> humanPlayerIds,
}) {
  if (save.gameMode != GameMode.multiplayer) return state;
  return state
      .copyWith(
        activePlayerId: '',
        activePlayerCanAct: true,
        submittedPlayerIds: {
          for (final playerId in humanPlayerIds)
            if (playerId.isNotEmpty) playerId,
        },
      )
      .copyWithInteraction(
        moveCommandActive: false,
        movePreview: null,
        cityFoundingDraft: null,
        pendingAction: null,
      );
}

List<String> _activePlayerIds(GameSave save) {
  final ids = save.players
      .map((player) => player.id)
      .where((id) => id.isNotEmpty)
      .toList();
  if (ids.isNotEmpty) return ids..sort();
  return save.playerStates.keys.where((id) => id.isNotEmpty).toList()..sort();
}

DateTime _syntheticSavedAt(GameSave save, {required int cycles}) {
  return save.savedAt.toUtc().add(Duration(seconds: cycles));
}

int _cityCountOwnedBy(Iterable<GameCity> cities, Set<String> playerIds) {
  return cities.where((city) => playerIds.contains(city.ownerPlayerId)).length;
}

List<_HumanCityEndState> _humanCityEndStates(
  GameState state, {
  required Set<String> humanPlayerIds,
}) {
  final cities =
      [
        for (final city in state.cities)
          if (humanPlayerIds.contains(city.ownerPlayerId)) city,
      ]..sort((a, b) {
        final col = a.center.col.compareTo(b.center.col);
        if (col != 0) return col;
        final row = a.center.row.compareTo(b.center.row);
        if (row != 0) return row;
        return a.id.compareTo(b.id);
      });

  return [
    for (final city in cities)
      _HumanCityEndState(
        cityId: city.id,
        ownerPlayerId: city.ownerPlayerId,
        centerCol: city.center.col,
        centerRow: city.center.row,
        hitPoints: city.hitPoints,
        centerOccupant: _unitLabel(
          _unitAtOrNull(state.units, city.center.col, city.center.row),
        ),
        adjacentNonHumanUnits: _nearbyNonHumanUnitLabels(
          state.units,
          city.center.toCoordinate(),
          humanPlayerIds: humanPlayerIds,
        ),
        readyAttackers: _readyCityAttackerLabels(
          state,
          city,
          humanPlayerIds: humanPlayerIds,
        ),
      ),
  ];
}

List<String> _nearbyNonHumanUnitLabels(
  Iterable<GameUnit> units,
  HexCoordinate center, {
  required Set<String> humanPlayerIds,
}) {
  final labels = <String>[];
  for (final unit in units) {
    if (humanPlayerIds.contains(unit.ownerPlayerId)) continue;
    final distance = HexDistance.between(
      HexCoordinate(col: unit.col, row: unit.row),
      center,
    );
    if (distance > 1) continue;
    labels.add(_unitLabel(unit)!);
  }
  labels.sort();
  return labels;
}

List<String> _readyCityAttackerLabels(
  GameState state,
  GameCity city, {
  required Set<String> humanPlayerIds,
}) {
  final labels = <String>[];
  final cityHex = city.center.toCoordinate();
  for (final unit in state.units) {
    if (humanPlayerIds.contains(unit.ownerPlayerId)) continue;
    if (unit.isWorking || unit.movementPoints <= 0) continue;
    if (!_hasHostileRelation(state, unit.ownerPlayerId, city.ownerPlayerId)) {
      continue;
    }
    final stats = UnitCombatStats.derive(
      unit,
      ruleset: GameRuleset.defaults.combat,
    );
    if (stats.attack <= 0) continue;
    final distance = HexDistance.between(
      HexCoordinate(col: unit.col, row: unit.row),
      cityHex,
    );
    if (distance > stats.range) continue;
    labels.add(_unitLabel(unit)!);
  }
  labels.sort();
  return labels;
}

bool _hasHostileRelation(
  GameState state,
  String attackerId,
  String defenderId,
) {
  final status = state.runtimeState.diplomacy.statusBetween(
    attackerId,
    defenderId,
  );
  return status == DiplomaticRelationStatus.hostile ||
      status == DiplomaticRelationStatus.war;
}

String? _unitLabel(GameUnit? unit) {
  if (unit == null) return null;
  return '${unit.id}/${unit.ownerPlayerId}@${unit.col},${unit.row}';
}

MapDefinition _mapDefinition(MapData mapData) {
  return MapDefinition(
    cols: mapData.cols,
    rows: mapData.rows,
    mapName: mapData.mapName,
    defaultZoom: mapData.defaultZoom,
    tiles: [
      for (final tile in mapData.tiles)
        MapTileDefinition(
          col: tile.col,
          row: tile.row,
          terrains: tile.terrains,
          resources: tile.resources,
          height: tile.height,
        ),
    ],
  );
}

Set<String> _pendingHostilePlayerIds({
  required SaveSnapshot snapshot,
  required String playerId,
}) {
  final hostilePlayerIds = <String>{};
  for (final attack in snapshot.runtimeState.intendedAttacks) {
    if (attack.declaringPlayerId == playerId) continue;
    if (_targetsPlayer(snapshot, playerId: playerId, attack: attack)) {
      hostilePlayerIds.add(attack.declaringPlayerId);
    }
  }
  return hostilePlayerIds;
}

bool _targetsPlayer(
  SaveSnapshot snapshot, {
  required String playerId,
  required IntendedAttack attack,
}) {
  for (final unit in snapshot.units) {
    if (unit.ownerPlayerId == playerId &&
        unit.col == attack.defenderCol &&
        unit.row == attack.defenderRow) {
      return true;
    }
  }
  for (final city in snapshot.cities) {
    if (city.ownerPlayerId == playerId &&
        city.center.col == attack.defenderCol &&
        city.center.row == attack.defenderRow) {
      return true;
    }
  }
  return false;
}

List<PendingCityAttackThreat> _pendingCityAttackThreats({
  required SaveSnapshot snapshot,
  required String playerId,
}) {
  final unitsById = {for (final unit in snapshot.units) unit.id: unit};
  final threats = <PendingCityAttackThreat>[];
  for (final attack in snapshot.runtimeState.intendedAttacks) {
    if (attack.declaringPlayerId == playerId) continue;
    final attacker = unitsById[attack.attackerUnitId];
    if (attacker == null || attacker.ownerPlayerId == playerId) continue;
    final city = _cityAt(
      snapshot,
      playerId: playerId,
      col: attack.defenderCol,
      row: attack.defenderRow,
    );
    if (city == null) continue;
    threats.add(
      PendingCityAttackThreat(
        attackerPlayerId: attack.declaringPlayerId,
        attackerUnitId: attack.attackerUnitId,
        attackerHex: HexCoordinate(col: attacker.col, row: attacker.row),
        cityId: city.id,
        cityCenter: city.center,
      ),
    );
  }
  return List.unmodifiable(threats);
}

GameCity? _cityAt(
  SaveSnapshot snapshot, {
  required String playerId,
  required int col,
  required int row,
}) {
  for (final city in snapshot.cities) {
    if (city.ownerPlayerId == playerId &&
        city.center.col == col &&
        city.center.row == row) {
      return city;
    }
  }
  return null;
}

DateTime? _deadlineFor(GameSave save, DateTime? turnStartedAt) {
  if (save.gameMode != GameMode.multiplayer) return null;
  final startedAt = turnStartedAt ?? save.savedAt;
  return startedAt.toUtc().add(const Duration(seconds: 115));
}

bool _isMilitaryUnit(GameUnit unit, CombatRuleset ruleset) {
  final stats = UnitCombatStats.derive(unit, ruleset: ruleset);
  return stats.attack > 0 || stats.defense > 0;
}

GameCommandContext _commandContext({
  required String playerId,
  required AiContext aiContext,
}) {
  return GameCommandContext(
    actorPlayerId: playerId,
    canAct: true,
    combatSeedTurn: aiContext.turn,
    ignoreFogOfWar: true,
  );
}
