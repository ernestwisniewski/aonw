import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat/combat_distance.dart';
import 'package:aonw_core/game/domain/combat/combat_modifier_collector.dart';
import 'package:aonw_core/game/domain/combat/intended_attack.dart';
import 'package:aonw_core/game/domain/combat/unit_combat_stats.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/turn/persistent_turn_combat_resolver.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/persistence/legacy_world_map_adapter.dart';

class PersistentCombatCommandResult {
  const PersistentCombatCommandResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final List<GameEvent> events;
  final String? reason;
}

/// Validates and resolves an instant combat command against persistent state.
///
/// [PersistentTurnCombatResolver] owns the shared combat outcome application.
/// This resolver adds the command-boundary validation that the turn resolver
/// deliberately omits because turn intents have already been validated.
class PersistentCombatCommandResolver {
  const PersistentCombatCommandResolver({
    this.fogOfWarService = const FogOfWarService(),
  });

  final FogOfWarService fogOfWarService;

  PersistentCombatCommandResult resolve({
    required PersistentGameState state,
    required AttackHexCommand command,
    required String actorPlayerId,
    required int turn,
    required int commandTick,
    required WorldMap worldMap,
    GameRuleset ruleset = GameRuleset.defaults,
  }) {
    final attacker = state.units.byId(command.attackerUnitId);
    if (attacker == null) return _reject(state, 'attacker_not_found');
    if (attacker.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'attacker_not_controlled');
    }
    if (attacker.isWorking) return _reject(state, 'attacker_unavailable');
    if (attacker.movementPoints <= 0) {
      return _reject(state, 'attacker_exhausted');
    }

    final attackerTile = LegacyWorldMapAdapter.tileDataAt(
      worldMap,
      attacker.col,
      attacker.row,
    );
    if (attackerTile == null) {
      return _reject(state, 'attacker_out_of_bounds');
    }
    final targetTile = LegacyWorldMapAdapter.tileDataAt(
      worldMap,
      command.defenderCol,
      command.defenderRow,
    );
    if (targetTile == null) {
      return _reject(state, 'attack_target_out_of_bounds');
    }

    final attackerModifiers = CombatModifierCollector.forAttacker(
      unit: attacker,
      tile: attackerTile,
      research: state.research.forPlayer(attacker.ownerPlayerId),
      ruleset: ruleset.combat,
      technologyRuleset: ruleset.technology,
    );
    final attackerStats = UnitCombatStats.derive(
      attacker,
      ruleset: ruleset.combat,
    ).applyAll(attackerModifiers);
    if (attackerStats.attack <= 0) {
      return _reject(state, 'attacker_cannot_attack');
    }

    final target = _targetAt(state, command);
    if (target == null) return _reject(state, 'attack_target_not_found');
    if (target.ownerPlayerId == attacker.ownerPlayerId) {
      return _reject(state, 'attack_target_not_enemy');
    }
    if (_isProtectedRelation(
      state.runtimeState.diplomacy,
      attacker.ownerPlayerId,
      target.ownerPlayerId,
    )) {
      return _reject(state, 'attack_target_protected_by_treaty');
    }
    if (!FogVisibilityQuery(
      playerId: actorPlayerId,
      state: state.fogOfWar,
    ).canSeeDynamicAt(command.defenderCol, command.defenderRow)) {
      return _reject(state, 'attack_target_not_visible');
    }
    final distance = CombatDistance.fromUnitToCoordinate(
      attacker,
      HexCoordinate(col: command.defenderCol, row: command.defenderRow),
    );
    if (distance > attackerStats.range) {
      return _reject(state, 'attack_target_out_of_range');
    }
    if (target.city != null && ruleset.combat.cityBaseStats.hp <= 0) {
      return _reject(state, 'attack_city_has_no_health');
    }

    final previousIntents = state.runtimeState.intendedAttacks;
    final isolated = state.copyWith(
      runtimeState: state.runtimeState.copyWith(
        intendedAttacks: [
          IntendedAttack(
            attackerUnitId: attacker.id,
            defenderCol: command.defenderCol,
            defenderRow: command.defenderRow,
            declaredAtTick: commandTick,
            declaringPlayerId: actorPlayerId,
            cityConquestAction: command.cityConquestAction,
          ),
        ],
      ),
    );
    final resolved = PersistentTurnCombatResolver.resolve(
      turn: turn,
      state: isolated,
      worldMap: worldMap,
      ruleset: ruleset,
    );
    if (resolved.events.whereType<CombatResolvedEvent>().isEmpty) {
      return _reject(state, 'attack_not_resolved');
    }

    final next = _stateWithUpdatedVisibility(
      originalState: state,
      combatState: resolved.state,
      previousIntents: previousIntents,
      worldMap: worldMap,
    );
    return PersistentCombatCommandResult(
      accepted: true,
      state: next,
      events: resolved.events,
    );
  }

  PersistentCombatCommandResult _reject(
    PersistentGameState state,
    String reason,
  ) {
    return PersistentCombatCommandResult(
      accepted: false,
      state: state,
      reason: reason,
    );
  }

  PersistentGameState _stateWithUpdatedVisibility({
    required PersistentGameState originalState,
    required PersistentGameState combatState,
    required List<IntendedAttack> previousIntents,
    required WorldMap worldMap,
  }) {
    final mapData = LegacyWorldMapAdapter.toMapData(worldMap);
    final updatedFog = fogOfWarService.recompute(
      current: originalState.fogOfWar,
      mapData: mapData,
      playerIds: originalState.knownPlayerIds,
      units: combatState.units,
      cities: combatState.cities,
    );
    final diplomacy = DiplomaticContact.mergeDiscoveredContacts(
      diplomacy: combatState.runtimeState.diplomacy,
      fogOfWar: updatedFog,
      units: combatState.units,
      cities: combatState.cities,
      playerIds: originalState.knownPlayerIds,
    );
    return combatState.copyWith(
      fogOfWar: updatedFog,
      runtimeState: combatState.runtimeState.copyWith(
        intendedAttacks: previousIntents,
        diplomacy: diplomacy,
      ),
    );
  }

  static ({String ownerPlayerId, GameUnit? unit, GameCity? city})? _targetAt(
    PersistentGameState state,
    AttackHexCommand command,
  ) {
    final unit = state.units.unitAt(command.defenderCol, command.defenderRow);
    if (unit != null) {
      return (ownerPlayerId: unit.ownerPlayerId, unit: unit, city: null);
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
