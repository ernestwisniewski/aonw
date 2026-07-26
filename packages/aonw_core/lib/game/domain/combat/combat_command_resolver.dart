import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/artifact/world_artifact_bonuses.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/combat/combat_command_result.dart';
import 'package:aonw_core/game/domain/combat/combat_command_state.dart';
import 'package:aonw_core/game/domain/combat/combat_distance.dart';
import 'package:aonw_core/game/domain/combat/combat_modifier_collector.dart';
import 'package:aonw_core/game/domain/combat/combat_ruleset.dart';
import 'package:aonw_core/game/domain/combat/combat_stats.dart';
import 'package:aonw_core/game/domain/combat/unit_combat_stats.dart';
import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomatic_contact.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/fog/fog_visibility_query.dart';
import 'package:aonw_core/game/domain/hex/hex_coordinate.dart';
import 'package:aonw_core/game/domain/ruleset/game_ruleset.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_context.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_orchestrator.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_state.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

typedef _CombatTarget = ({
  String ownerPlayerId,
  GameUnit? unit,
  GameCity? city,
});

typedef _CombatCommandRequest = ({
  CombatCommandState state,
  AttackHexCommand command,
  String actorPlayerId,
  MapTileLookup mapTiles,
  GameRuleset ruleset,
  bool ignoreFogOfWar,
});

typedef _AttackTiles = ({MapTileView attacker, MapTileView target});

typedef _TargetAndAttackerStats = ({
  _CombatTarget target,
  CombatStats attackerStats,
});

final class _CombatCheck<T extends Object> {
  const _CombatCheck.accepted(this.value) : rejection = null;

  const _CombatCheck.rejected(this.rejection) : value = null;

  final T? value;
  final CombatCommandResult? rejection;
}

/// Applies authoritative combat-command rules without a state container.
final class CombatCommandResolver {
  const CombatCommandResolver({this.fogOfWarService = const FogOfWarService()});

  final FogOfWarService fogOfWarService;

  CombatCommandResult resolve({
    required CombatCommandState state,
    required AttackHexCommand command,
    required String actorPlayerId,
    required int turn,
    required int commandTick,
    required MapTileLookup mapTiles,
    GameRuleset ruleset = GameRuleset.defaults,
    bool ignoreFogOfWar = false,
  }) {
    final request = (
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      ruleset: ruleset,
      ignoreFogOfWar: ignoreFogOfWar,
    );
    final preparation = _prepare(request);
    if (preparation.rejection case final rejection?) return rejection;
    final attacker = preparation.value!;
    final intent = IntendedAttack(
      attackerUnitId: attacker.id,
      defenderCol: command.defenderCol,
      defenderRow: command.defenderRow,
      declaredAtTick: commandTick,
      declaringPlayerId: actorPlayerId,
      cityConquestAction: command.cityConquestAction,
    );
    if (ruleset.combat.resolutionMode == CombatResolutionMode.simultaneous) {
      return _recordIntent(state, intent);
    }
    return _resolveInstant(
      state: state,
      intent: intent,
      turn: turn,
      mapTiles: mapTiles,
      ruleset: ruleset,
    );
  }

  static _CombatCheck<GameUnit> _prepare(_CombatCommandRequest request) {
    final attackerCheck = _attackerFor(request);
    if (attackerCheck.rejection case final rejection?) {
      return _CombatCheck.rejected(rejection);
    }
    final attacker = attackerCheck.value!;
    final tilesCheck = _tilesFor(request, attacker);
    if (tilesCheck.rejection case final rejection?) {
      return _CombatCheck.rejected(rejection);
    }
    final tiles = tilesCheck.value!;
    final targetCheck = _targetAndStatsFor(request, attacker, tiles);
    if (targetCheck.rejection case final rejection?) {
      return _CombatCheck.rejected(rejection);
    }
    final targetAndStats = targetCheck.value!;
    final targetRejection = _targetRejection(request, attacker, targetAndStats);
    if (targetRejection != null) {
      return _CombatCheck.rejected(_reject(request.state, targetRejection));
    }
    return _CombatCheck.accepted(attacker);
  }

  static _CombatCheck<GameUnit> _attackerFor(_CombatCommandRequest request) {
    final state = request.state;
    final attacker = state.units.byId(request.command.attackerUnitId);
    if (attacker == null) {
      return _CombatCheck.rejected(_reject(state, 'attacker_not_found'));
    }
    if (attacker.ownerPlayerId != request.actorPlayerId) {
      return _CombatCheck.rejected(_reject(state, 'attacker_not_controlled'));
    }
    if (attacker.isWorking) {
      return _CombatCheck.rejected(_reject(state, 'attacker_unavailable'));
    }
    if (attacker.movementPoints <= 0) {
      return _CombatCheck.rejected(_reject(state, 'attacker_exhausted'));
    }
    return _CombatCheck.accepted(attacker);
  }

  static _CombatCheck<_AttackTiles> _tilesFor(
    _CombatCommandRequest request,
    GameUnit attacker,
  ) {
    final state = request.state;
    final attackerTile = request.mapTiles.tileAt(attacker.col, attacker.row);
    if (attackerTile == null) {
      return _CombatCheck.rejected(_reject(state, 'attacker_out_of_bounds'));
    }
    final command = request.command;
    final targetTile = request.mapTiles.tileAt(
      command.defenderCol,
      command.defenderRow,
    );
    if (targetTile == null) {
      return _CombatCheck.rejected(
        _reject(state, 'attack_target_out_of_bounds'),
      );
    }
    return _CombatCheck.accepted((attacker: attackerTile, target: targetTile));
  }

  static _CombatCheck<_TargetAndAttackerStats> _targetAndStatsFor(
    _CombatCommandRequest request,
    GameUnit attacker,
    _AttackTiles tiles,
  ) {
    final state = request.state;
    final targetIndependentStats = _attackerStatsFor(request, attacker, tiles);
    if (targetIndependentStats.attack <= 0) {
      return _CombatCheck.rejected(_reject(state, 'attacker_cannot_attack'));
    }
    if (!_targetIsVisible(request)) {
      return _CombatCheck.rejected(_reject(state, 'attack_target_not_visible'));
    }
    final target = _targetAt(state, request.command, attacker.id);
    if (target == null) {
      return _CombatCheck.rejected(_reject(state, 'attack_target_not_found'));
    }
    final attackerStats = _attackerStatsFor(
      request,
      attacker,
      tiles,
      defender: target.unit,
    );
    if (attackerStats.attack <= 0) {
      return _CombatCheck.rejected(_reject(state, 'attacker_cannot_attack'));
    }
    return _CombatCheck.accepted((
      target: target,
      attackerStats: attackerStats,
    ));
  }

  static CombatStats _attackerStatsFor(
    _CombatCommandRequest request,
    GameUnit attacker,
    _AttackTiles tiles, {
    GameUnit? defender,
  }) {
    final state = request.state;
    return UnitCombatStats.derive(
      attacker,
      ruleset: request.ruleset.combat,
    ).applyAll(
      CombatModifierCollector.forAttacker(
        unit: attacker,
        tile: tiles.attacker,
        research: state.research.forPlayer(attacker.ownerPlayerId),
        defender: defender,
        defenderTile: defender == null ? null : tiles.target,
        ruleset: request.ruleset.combat,
        technologyRuleset: request.ruleset.technology,
      ),
    );
  }

  static bool _targetIsVisible(_CombatCommandRequest request) {
    if (request.ignoreFogOfWar) return true;
    final command = request.command;
    return FogVisibilityQuery(
      playerId: request.actorPlayerId,
      state: request.state.fogOfWar,
    ).canSeeDynamicAt(command.defenderCol, command.defenderRow);
  }

  static String? _targetRejection(
    _CombatCommandRequest request,
    GameUnit attacker,
    _TargetAndAttackerStats targetAndStats,
  ) {
    final state = request.state;
    final command = request.command;
    final target = targetAndStats.target;
    if (target.ownerPlayerId == attacker.ownerPlayerId) {
      return 'attack_target_not_enemy';
    }
    if (_isProtectedRelation(
      state.diplomacy,
      attacker.ownerPlayerId,
      target.ownerPlayerId,
    )) {
      return 'attack_target_protected_by_treaty';
    }
    final distance = CombatDistance.fromUnitToCoordinate(
      attacker,
      HexCoordinate(col: command.defenderCol, row: command.defenderRow),
    );
    if (distance > targetAndStats.attackerStats.range) {
      return 'attack_target_out_of_range';
    }
    if (target.city case final city?) {
      final cityStats = request.ruleset.combat.cityBaseStats.add(
        WorldArtifactBonuses.cityCombatStatsFor(
          cityId: city.id,
          artifacts: state.artifacts,
        ),
      );
      if (cityStats.hp <= 0) return 'attack_city_has_no_health';
    }
    return null;
  }

  CombatCommandResult _resolveInstant({
    required CombatCommandState state,
    required IntendedAttack intent,
    required int turn,
    required MapTileLookup mapTiles,
    required GameRuleset ruleset,
  }) {
    final resolution = TurnCombatOrchestrator.resolve(
      state: TurnCombatState(
        units: state.units,
        cities: state.cities,
        artifacts: state.artifacts,
        intendedAttacks: List.unmodifiable([intent]),
        diplomacy: state.diplomacy,
        resourceTradeAgreements: state.resourceTradeAgreements,
      ),
      context: TurnCombatContext(
        turn: turn,
        researchForPlayer: state.research.forPlayer,
        mapTiles: mapTiles,
        ruleset: ruleset,
      ),
    );
    if (resolution.events.whereType<CombatResolvedEvent>().isEmpty) {
      return _reject(state, 'attack_not_resolved');
    }

    final combat = resolution.state;
    final playerIds = Set<String>.unmodifiable(state.playerIds);
    final fogOfWar = fogOfWarService.recompute(
      current: state.fogOfWar,
      mapData: mapTiles,
      playerIds: playerIds,
      units: combat.units,
      cities: combat.cities,
    );
    final diplomacy = DiplomaticContact.mergeDiscoveredContacts(
      diplomacy: combat.diplomacy,
      fogOfWar: fogOfWar,
      units: combat.units,
      cities: combat.cities,
      playerIds: playerIds,
    );
    return CombatCommandResult.accepted(
      units: combat.units,
      cities: combat.cities,
      artifacts: combat.artifacts,
      fogOfWar: fogOfWar,
      intendedAttacks: state.intendedAttacks,
      diplomacy: diplomacy,
      resourceTradeAgreements: combat.resourceTradeAgreements,
      events: List<GameEvent>.unmodifiable(resolution.events),
    );
  }

  static CombatCommandResult _recordIntent(
    CombatCommandState state,
    IntendedAttack intent,
  ) {
    return CombatCommandResult.accepted(
      units: state.units,
      cities: state.cities,
      artifacts: state.artifacts,
      fogOfWar: state.fogOfWar,
      intendedAttacks: List<IntendedAttack>.unmodifiable([
        for (final existing in state.intendedAttacks)
          if (existing.attackerUnitId != intent.attackerUnitId) existing,
        intent,
      ]),
      diplomacy: state.diplomacy,
      resourceTradeAgreements: state.resourceTradeAgreements,
    );
  }

  static CombatCommandResult _reject(CombatCommandState state, String reason) {
    return CombatCommandResult.rejected(
      units: state.units,
      cities: state.cities,
      artifacts: state.artifacts,
      fogOfWar: state.fogOfWar,
      intendedAttacks: state.intendedAttacks,
      diplomacy: state.diplomacy,
      resourceTradeAgreements: state.resourceTradeAgreements,
      reason: reason,
    );
  }

  static _CombatTarget? _targetAt(
    CombatCommandState state,
    AttackHexCommand command,
    String attackerUnitId,
  ) {
    for (final unit in state.units) {
      if (unit.id != attackerUnitId &&
          unit.occupies(command.defenderCol, command.defenderRow)) {
        return (ownerPlayerId: unit.ownerPlayerId, unit: unit, city: null);
      }
    }
    final city = state.cities.cityAt(command.defenderCol, command.defenderRow);
    if (city == null) return null;
    return (ownerPlayerId: city.ownerPlayerId, unit: null, city: city);
  }

  static bool _isProtectedRelation(
    DiplomacyState diplomacy,
    String attackerPlayerId,
    String defenderPlayerId,
  ) {
    final status = diplomacy.statusBetween(attackerPlayerId, defenderPlayerId);
    return status == DiplomaticRelationStatus.friendly ||
        status == DiplomaticRelationStatus.truce;
  }
}
