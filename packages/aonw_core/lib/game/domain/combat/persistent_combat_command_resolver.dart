import 'package:aonw_core/domain/map_definition.dart';
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
import 'package:aonw_core/map/domain/map_data.dart';
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
    required MapDefinition mapDefinition,
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

    final attackerTile = _tileDataAt(mapDefinition, attacker.col, attacker.row);
    if (attackerTile == null) {
      return _reject(state, 'attacker_out_of_bounds');
    }
    final targetTile = _tileDataAt(
      mapDefinition,
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
      mapDefinition: mapDefinition,
      ruleset: ruleset,
    );
    if (resolved.events.whereType<CombatResolvedEvent>().isEmpty) {
      return _reject(state, 'attack_not_resolved');
    }

    final mapData = LegacyWorldMapAdapter.mapDataFromDefinition(mapDefinition);
    final updatedFog = fogOfWarService.recompute(
      current: state.fogOfWar,
      mapData: mapData,
      playerIds: state.knownPlayerIds,
      units: resolved.state.units,
      cities: resolved.state.cities,
    );
    final diplomacy = DiplomaticContact.mergeDiscoveredContacts(
      diplomacy: resolved.state.runtimeState.diplomacy,
      fogOfWar: updatedFog,
      units: resolved.state.units,
      cities: resolved.state.cities,
      playerIds: state.knownPlayerIds,
    );
    final next = resolved.state.copyWith(
      fogOfWar: updatedFog,
      runtimeState: resolved.state.runtimeState.copyWith(
        intendedAttacks: previousIntents,
        diplomacy: diplomacy,
      ),
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

  static TileData? _tileDataAt(MapDefinition mapDefinition, int col, int row) {
    final tile = mapDefinition.tileAt(col, row);
    if (tile == null) return null;
    return TileData(
      col: tile.col,
      row: tile.row,
      terrains: tile.terrains,
      resources: tile.resources,
      height: tile.height,
    );
  }
}
