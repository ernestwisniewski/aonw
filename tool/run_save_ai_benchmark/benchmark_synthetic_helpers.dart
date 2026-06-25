part of '../run_save_ai_benchmark.dart';

Set<String> _pressureTargetPlayerIds(
  Iterable<Player> players, {
  required String playerId,
  required DiplomacyState diplomacy,
}) {
  return {
    for (final player in players)
      if (_shouldPressureHumanPlayer(
        player: player,
        playerId: playerId,
        diplomacy: diplomacy,
      ))
        player.id,
  };
}

Set<String> _defaultNeutralPlayerIds(
  Iterable<Player> players, {
  required String playerId,
}) {
  return {
    for (final player in players)
      if (player.id != playerId && player.kind != PlayerKind.human) player.id,
  };
}

bool _shouldPressureHumanPlayer({
  required Player player,
  required String playerId,
  required DiplomacyState diplomacy,
}) {
  if (player.id == playerId || player.kind != PlayerKind.human) return false;

  final status = diplomacy.statusBetween(playerId, player.id);
  if (status == DiplomaticRelationStatus.hostile ||
      status == DiplomaticRelationStatus.war) {
    return true;
  }
  if (status == DiplomaticRelationStatus.friendly) return false;

  final relationKey = DiplomacyState.relationKey(playerId, player.id);
  return relationKey.isNotEmpty &&
      !diplomacy.relations.containsKey(relationKey);
}

_PreparedPlayer _prepareSyntheticPlayer({
  required SaveSnapshot snapshot,
  required MapData mapData,
  required String playerId,
  required Set<String> humanPlayerIds,
  required bool includeDeadline,
}) {
  final player = snapshot.save.players.firstWhere(
    (candidate) => candidate.id == playerId,
  );
  return _PreparedPlayer.fromSnapshot(
    snapshot: snapshot,
    player: player,
    humanPlayerIds: humanPlayerIds,
    mapData: mapData,
    includeDeadline: includeDeadline,
  );
}

MapData _syntheticMapData({
  required int cols,
  required int rows,
  required String mapName,
}) {
  return MapData(
    cols: cols,
    rows: rows,
    mapName: mapName,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

SaveSnapshot _syntheticDiplomacySnapshot(MapData mapData) {
  const aiId = 'ai_synthetic';
  const warHumanId = 'human_war';
  const hostileHumanId = 'human_hostile';
  const friendlyHumanId = 'human_friendly';
  const neutralHumanId = 'human_neutral';
  const defaultNeutralAiId = 'ai_default_neutral';
  final players = [
    const Player(
      id: warHumanId,
      name: 'Human War',
      colorValue: 0xFF2563EB,
      country: PlayerCountry.poland,
    ),
    const Player(
      id: hostileHumanId,
      name: 'Human Hostile',
      colorValue: 0xFF9333EA,
      country: PlayerCountry.spain,
    ),
    const Player(
      id: friendlyHumanId,
      name: 'Human Friendly',
      colorValue: 0xFF22C55E,
      country: PlayerCountry.france,
    ),
    const Player(
      id: neutralHumanId,
      name: 'Human Neutral',
      colorValue: 0xFFF59E0B,
      country: PlayerCountry.netherlands,
    ),
    const Player(
      id: aiId,
      name: 'AI Synthetic',
      colorValue: 0xFFDC2626,
      country: PlayerCountry.germany,
      kind: PlayerKind.ai,
      ai: AiPlayer(
        strategyId: AiStrategyId.basic,
        difficulty: AiDifficulty.normal,
        persona: AiPersona.aggressive,
        seed: 7301,
      ),
    ),
    const Player(
      id: defaultNeutralAiId,
      name: 'Default Neutral AI',
      colorValue: 0xFF607D8B,
      country: PlayerCountry.unitedKingdom,
      kind: PlayerKind.ai,
      ai: AiPlayer(
        strategyId: AiStrategyId.basic,
        difficulty: AiDifficulty.normal,
        persona: AiPersona.balanced,
        seed: 7302,
      ),
    ),
  ];
  var diplomacy = DiplomacyState.empty;
  diplomacy = diplomacy.setStatus(
    aiId,
    warHumanId,
    DiplomaticRelationStatus.war,
    turn: 132,
    reason: DiplomaticRelationChangeReason.manual,
  );
  diplomacy = diplomacy.setStatus(
    aiId,
    hostileHumanId,
    DiplomaticRelationStatus.hostile,
    turn: 132,
    reason: DiplomaticRelationChangeReason.unitAttack,
  );
  diplomacy = diplomacy.setStatus(
    aiId,
    friendlyHumanId,
    DiplomaticRelationStatus.friendly,
    turn: 132,
    reason: DiplomaticRelationChangeReason.manual,
  );
  diplomacy = diplomacy.setStatus(
    aiId,
    neutralHumanId,
    DiplomaticRelationStatus.neutral,
    turn: 132,
    reason: DiplomaticRelationChangeReason.manual,
  );
  final savedAt = DateTime.utc(2026, 5, 29, 10);
  return SaveSnapshot(
    save: _syntheticSave(
      id: 'synthetic_diplomacy_guard',
      name: 'Synthetic diplomacy target filter',
      mapName: mapData.mapName ?? 'synthetic_diplomacy_guard',
      turn: 132,
      savedAt: savedAt,
      players: players,
    ),
    playerColors: {for (final player in players) player.id: player.colorValue},
    playerCountries: {for (final player in players) player.id: player.country},
    playerGold: const {aiId: 240},
    units: [
      GameUnit(
        id: 'ai_tank',
        ownerPlayerId: aiId,
        type: GameUnitType.tank,
        name: GameUnitType.tank.defaultNameToken,
        col: 1,
        row: 1,
      ),
      GameUnit(
        id: 'friendly_warrior',
        ownerPlayerId: friendlyHumanId,
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 1,
        row: 0,
      ),
      GameUnit(
        id: 'neutral_warrior',
        ownerPlayerId: neutralHumanId,
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 1,
      ),
      GameUnit(
        id: 'hostile_warrior',
        ownerPlayerId: hostileHumanId,
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 4,
        row: 0,
      ),
      GameUnit(
        id: 'default_neutral_ai_warrior',
        ownerPlayerId: defaultNeutralAiId,
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 2,
        row: 2,
      ),
    ],
    cities: const [
      GameCity(
        id: 'ai_capital',
        ownerPlayerId: aiId,
        name: 'AI Capital',
        center: CityHex(col: 0, row: 2),
      ),
      GameCity(
        id: 'war_target_city',
        ownerPlayerId: warHumanId,
        name: 'War Target',
        center: CityHex(col: 2, row: 1),
        hitPoints: 2,
      ),
      GameCity(
        id: 'hostile_target_city',
        ownerPlayerId: hostileHumanId,
        name: 'Hostile Target',
        center: CityHex(col: 4, row: 1),
        hitPoints: 2,
      ),
      GameCity(
        id: 'default_neutral_ai_city',
        ownerPlayerId: defaultNeutralAiId,
        name: 'Default Neutral AI City',
        center: CityHex(col: 3, row: 2),
      ),
    ],
    fogOfWar: _syntheticVisibleFog(mapData, players),
    runtimeState: GameRuntimeState(
      diplomacy: diplomacy,
      turnStartedAt: savedAt,
    ),
  );
}

SaveSnapshot _syntheticFortifiedWakeUpSnapshot(MapData mapData) {
  const aiId = 'ai_synthetic';
  const humanId = 'human_war';
  final players = [
    const Player(
      id: humanId,
      name: 'Human War',
      colorValue: 0xFF2563EB,
      country: PlayerCountry.poland,
    ),
    const Player(
      id: aiId,
      name: 'AI Synthetic',
      colorValue: 0xFFDC2626,
      country: PlayerCountry.germany,
      kind: PlayerKind.ai,
      ai: AiPlayer(
        strategyId: AiStrategyId.basic,
        difficulty: AiDifficulty.normal,
        persona: AiPersona.aggressive,
        seed: 7302,
      ),
    ),
  ];
  final diplomacy = DiplomacyState.empty.setStatus(
    aiId,
    humanId,
    DiplomaticRelationStatus.war,
    turn: 132,
    reason: DiplomaticRelationChangeReason.manual,
  );
  final savedAt = DateTime.utc(2026, 5, 29, 10, 1);
  return SaveSnapshot(
    save: _syntheticSave(
      id: 'synthetic_fortified_wakeup_guard',
      name: 'Synthetic fortified offensive wake-up',
      mapName: mapData.mapName ?? 'synthetic_fortified_wakeup_guard',
      turn: 132,
      savedAt: savedAt,
      players: players,
    ),
    playerColors: {for (final player in players) player.id: player.colorValue},
    playerCountries: {for (final player in players) player.id: player.country},
    playerGold: const {aiId: 240},
    units: [
      GameUnit(
        id: 'aa_fortified_vanguard',
        ownerPlayerId: aiId,
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 2,
        row: 2,
        movementPoints: 0,
        posture: UnitPosture.fortified,
      ),
      GameUnit(
        id: 'bb_active_guard',
        ownerPlayerId: aiId,
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 1,
      ),
    ],
    cities: const [
      GameCity(
        id: 'ai_capital',
        ownerPlayerId: aiId,
        name: 'AI Capital',
        center: CityHex(col: 0, row: 0),
      ),
      GameCity(
        id: 'human_target_city',
        ownerPlayerId: humanId,
        name: 'Human Target',
        center: CityHex(col: 5, row: 2),
      ),
    ],
    fogOfWar: _syntheticVisibleFog(mapData, players),
    runtimeState: GameRuntimeState(
      diplomacy: diplomacy,
      turnStartedAt: savedAt,
    ),
  );
}

GameSave _syntheticSave({
  required String id,
  required String name,
  required String mapName,
  required int turn,
  required DateTime savedAt,
  required List<Player> players,
}) {
  return GameSave(
    id: id,
    name: name,
    mapName: mapName,
    turn: turn,
    playerStates: {
      for (final player in players) player.id: PlayerTurnState.active,
    },
    savedAt: savedAt,
    camera: CameraState.zero,
    players: players,
    gameMode: GameMode.hotSeat,
  );
}

FogOfWarState _syntheticVisibleFog(MapData mapData, Iterable<Player> players) {
  final visibleHexes = _allHexesIn(mapData);
  return FogOfWarState(
    players: {
      for (final player in players)
        player.id: PlayerFogOfWar(
          playerId: player.id,
          visibleHexes: visibleHexes,
        ),
    },
  );
}

Set<HexCoordinate> _allHexesIn(MapData mapData) {
  return {
    for (final tile in mapData.tiles)
      HexCoordinate(col: tile.col, row: tile.row),
  };
}

void _appendFailingPlannerFindings(
  List<_Finding> target,
  _PlayerBenchmarkResult result,
) {
  for (final finding in result.findings) {
    if (finding.severity != 'fail') continue;
    target.add(
      _Finding(
        severity: finding.severity,
        message: 'Planner guard: ${finding.message}',
      ),
    );
  }
}

GameStateTransition _reduceSyntheticCommand(
  _PreparedPlayer prepared,
  GameCommand command,
) {
  final reducer = GameStateReducer(
    mapData: prepared.mapData,
    ruleset: prepared.context.ruleset,
  );
  return reducer.reduce(
    prepared._executionInitialState(),
    command,
    context: _commandContext(
      playerId: prepared.player.id,
      aiContext: prepared.context,
    ),
  );
}

bool _syntheticCommandChangesState(
  _PreparedPlayer prepared,
  GameCommand command,
) {
  final state = prepared._executionInitialState();
  final reducer = GameStateReducer(
    mapData: prepared.mapData,
    ruleset: prepared.context.ruleset,
  );
  final transition = reducer.reduce(
    state,
    command,
    context: _commandContext(
      playerId: prepared.player.id,
      aiContext: prepared.context,
    ),
  );
  return transition.state != state;
}
