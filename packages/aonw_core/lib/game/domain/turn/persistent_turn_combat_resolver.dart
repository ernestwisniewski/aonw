import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class PersistentTurnCombatResult {
  final PersistentGameState state;
  final List<GameEvent> events;

  const PersistentTurnCombatResult({
    required this.state,
    this.events = const [],
  });
}

abstract final class PersistentTurnCombatResolver {
  static PersistentTurnCombatResult resolve({
    required int turn,
    required PersistentGameState state,
    MapDefinition? mapDefinition,
    GameRuleset ruleset = GameRuleset.defaults,
  }) {
    if (state.runtimeState.intendedAttacks.isEmpty || state.units.isEmpty) {
      return PersistentTurnCombatResult(state: state);
    }

    final units = [...state.units];
    final cities = [...state.cities];
    final artifacts = [...state.artifacts];
    final events = <GameEvent>[];
    var diplomacy = state.runtimeState.diplomacy;
    var resourceTradeAgreements = state.runtimeState.resourceTradeAgreements;
    final ordered = [...state.runtimeState.intendedAttacks]
      ..sort(_compareIntents);

    for (final intent in ordered) {
      final attackerIndex = _unitIndexById(units, intent.attackerUnitId);
      if (attackerIndex == null) continue;
      final attacker = units[attackerIndex];
      final defenderIndex = _unitIndexAt(
        units,
        intent.defenderCol,
        intent.defenderRow,
      );
      if (defenderIndex == null) {
        final resolved = _resolveCityAttack(
          turn: turn,
          intent: intent,
          attacker: attacker,
          attackerIndex: attackerIndex,
          state: state,
          units: units,
          cities: cities,
          artifacts: artifacts,
          events: events,
          diplomacy: diplomacy,
          resourceTradeAgreements: resourceTradeAgreements,
          updateDiplomacy: (next) => diplomacy = next,
          updateResourceTradeAgreements: (next) =>
              resourceTradeAgreements = next,
          mapDefinition: mapDefinition,
          ruleset: ruleset,
        );
        if (resolved) continue;
        continue;
      }
      final defender = units[defenderIndex];
      if (attacker.ownerPlayerId == defender.ownerPlayerId) continue;
      if (_isProtectedRelation(
        diplomacy,
        attacker.ownerPlayerId,
        defender.ownerPlayerId,
      )) {
        continue;
      }

      final attack = _combatantsFor(
        attacker: attacker,
        defender: defender,
        cities: cities,
        state: state,
        mapDefinition: mapDefinition,
        ruleset: ruleset,
      );
      if (attack == null) continue;
      if (attack.attacker.effective.attack <= 0) continue;
      if (_distance(attacker, defender) > attack.attacker.effective.range) {
        continue;
      }
      diplomacy = diplomacy.registerUnitAttack(
        attackerPlayerId: attacker.ownerPlayerId,
        defenderPlayerId: defender.ownerPlayerId,
        turn: turn,
      );
      final retreatDestination =
          attack.defender.effective.attack > 0 && mapDefinition != null
          ? CombatRetreatResolver.destination(
              attacker: attacker,
              defender: defender,
              units: units,
              tileAt: (col, row) => _tileDataAt(mapDefinition, col, row),
            )
          : null;

      final outcome = CombatResolver.resolve(
        attacker: attack.attacker,
        defender: attack.defender,
        rng: CombatRng.fromTurn(
          turn: turn,
          attackerId: attacker.id,
          defenderId: defender.id,
        ),
        ruleset: ruleset.combat,
        defenderCanRetreat: retreatDestination != null,
      );
      events.addAll([
        UnitAttackedEvent(
          attackerUnitId: attacker.id,
          attackerOwnerPlayerId: attacker.ownerPlayerId,
          defenderUnitId: defender.id,
          defenderOwnerPlayerId: defender.ownerPlayerId,
        ),
        CombatResolvedEvent(
          attackerUnitId: attacker.id,
          defenderUnitId: defender.id,
          outcome: outcome,
        ),
      ]);
      if (outcome.defenderRetreated && retreatDestination != null) {
        events.add(
          UnitRetreatedEvent(
            unitId: defender.id,
            ownerPlayerId: defender.ownerPlayerId,
            fromCol: defender.col,
            fromRow: defender.row,
            toCol: retreatDestination.col,
            toRow: retreatDestination.row,
          ),
        );
      }

      final attackerExperience = UnitVeterancyRules.experienceAwardForCombat(
        unit: attacker,
        survived: !outcome.attackerKilled,
        defeatedEnemy: outcome.defenderKilled,
      );
      final defenderExperience = UnitVeterancyRules.experienceAwardForCombat(
        unit: defender,
        survived: !outcome.defenderKilled,
        defeatedEnemy: outcome.attackerKilled,
      );
      final removals = <int>[];
      if (outcome.attackerKilled) {
        _dropUnitArtifacts(artifacts, attacker);
        removals.add(attackerIndex);
        events.add(
          UnitKilledEvent(
            unitId: attacker.id,
            ownerPlayerId: attacker.ownerPlayerId,
            attackerUnitId: defender.id,
          ),
        );
      } else {
        final updatedAttacker = _withCombatState(
          attacker,
          hitPoints: outcome.attackerHpAfter,
          maxHitPoints: attack.attacker.maxHp,
          movementPoints: 0,
          experienceAward: attackerExperience,
        );
        units[attackerIndex] = updatedAttacker;
        final experienceEvent = _experienceEvent(
          before: attacker,
          after: updatedAttacker,
          amount: attackerExperience,
        );
        if (experienceEvent != null) events.add(experienceEvent);
      }

      if (outcome.defenderKilled) {
        _dropUnitArtifacts(artifacts, defender);
        removals.add(defenderIndex);
        events.add(
          UnitKilledEvent(
            unitId: defender.id,
            ownerPlayerId: defender.ownerPlayerId,
            attackerUnitId: attacker.id,
          ),
        );
      } else {
        final updatedDefender = _withCombatState(
          defender,
          hitPoints: outcome.defenderHpAfter,
          maxHitPoints: attack.defender.maxHp,
          retreatDestination: outcome.defenderRetreated
              ? retreatDestination
              : null,
          experienceAward: defenderExperience,
        );
        units[defenderIndex] = updatedDefender;
        final experienceEvent = _experienceEvent(
          before: defender,
          after: updatedDefender,
          amount: defenderExperience,
        );
        if (experienceEvent != null) events.add(experienceEvent);
      }

      removals.sort((a, b) => b.compareTo(a));
      for (final index in removals) {
        units.removeAt(index);
      }
    }

    return PersistentTurnCombatResult(
      state: state.copyWith(
        units: units,
        cities: cities,
        artifacts: artifacts,
        runtimeState: state.runtimeState.copyWith(
          diplomacy: diplomacy,
          resourceTradeAgreements: resourceTradeAgreements,
        ),
      ),
      events: events,
    );
  }

  static int _compareIntents(IntendedAttack a, IntendedAttack b) {
    final tick = a.declaredAtTick.compareTo(b.declaredAtTick);
    if (tick != 0) return tick;
    return a.attackerUnitId.compareTo(b.attackerUnitId);
  }

  static ({Combatant attacker, Combatant defender})? _combatantsFor({
    required GameUnit attacker,
    required GameUnit defender,
    required List<GameCity> cities,
    required PersistentGameState state,
    required MapDefinition? mapDefinition,
    required GameRuleset ruleset,
  }) {
    final attackerTile = _tileDataAt(mapDefinition, attacker.col, attacker.row);
    final defenderTile = _tileDataAt(mapDefinition, defender.col, defender.row);
    final attackerResearch = state.research.forPlayer(attacker.ownerPlayerId);
    final defenderResearch = state.research.forPlayer(defender.ownerPlayerId);
    final defendedCity = cities.cityAt(defender.col, defender.row);

    final attackerModifiers = attackerTile == null
        ? const <CombatModifier>[]
        : CombatModifierCollector.forAttacker(
            unit: attacker,
            tile: attackerTile,
            research: attackerResearch,
            defender: defender,
            defenderTile: defenderTile,
            ruleset: ruleset.combat,
            technologyRuleset: ruleset.technology,
          );
    final defenderModifiers = defenderTile == null
        ? const <CombatModifier>[]
        : CombatModifierCollector.forDefender(
            unit: defender,
            tile: defenderTile,
            defendedCity: defendedCity,
            research: defenderResearch,
            attacker: attacker,
            ruleset: ruleset.combat,
            technologyRuleset: ruleset.technology,
          );
    final attackerBaseStats = UnitCombatStats.derive(
      attacker,
      ruleset: ruleset.combat,
    );
    final defenderBaseStats = UnitCombatStats.derive(
      defender,
      ruleset: ruleset.combat,
    );
    final attackerEffective = attackerBaseStats.applyAll(attackerModifiers);
    final defenderEffective = defenderBaseStats.applyAll(defenderModifiers);

    return (
      attacker: Combatant(
        unitId: attacker.id,
        ownerPlayerId: attacker.ownerPlayerId,
        baseStats: attackerBaseStats,
        modifiers: attackerModifiers,
        currentHp: UnitCombatHealth.currentHp(
          attacker,
          effectiveStats: attackerEffective,
        ),
      ),
      defender: Combatant(
        unitId: defender.id,
        ownerPlayerId: defender.ownerPlayerId,
        baseStats: defenderBaseStats,
        modifiers: defenderModifiers,
        currentHp: UnitCombatHealth.currentHp(
          defender,
          effectiveStats: defenderEffective,
        ),
      ),
    );
  }

  static TileData? _tileDataAt(MapDefinition? mapDefinition, int col, int row) {
    final tile = mapDefinition?.tileAt(col, row);
    if (tile == null) return null;
    return TileData(
      col: tile.col,
      row: tile.row,
      terrains: tile.terrains,
      resources: tile.resources,
      height: tile.height,
    );
  }

  static int? _unitIndexById(List<GameUnit> units, String unitId) {
    for (var i = 0; i < units.length; i++) {
      if (units[i].id == unitId) return i;
    }
    return null;
  }

  static int? _unitIndexAt(List<GameUnit> units, int col, int row) {
    for (var i = 0; i < units.length; i++) {
      if (units[i].occupies(col, row)) return i;
    }
    return null;
  }

  static int? _cityIndexAt(List<GameCity> cities, int col, int row) {
    for (var i = 0; i < cities.length; i++) {
      if (cities[i].occupiesCenter(col, row)) return i;
    }
    return null;
  }

  static bool _resolveCityAttack({
    required int turn,
    required IntendedAttack intent,
    required GameUnit attacker,
    required int attackerIndex,
    required PersistentGameState state,
    required List<GameUnit> units,
    required List<GameCity> cities,
    required List<WorldArtifact> artifacts,
    required List<GameEvent> events,
    required DiplomacyState diplomacy,
    required List<ResourceTradeAgreement> resourceTradeAgreements,
    required void Function(DiplomacyState) updateDiplomacy,
    required void Function(List<ResourceTradeAgreement>)
    updateResourceTradeAgreements,
    required MapDefinition? mapDefinition,
    required GameRuleset ruleset,
  }) {
    final cityIndex = _cityIndexAt(
      cities,
      intent.defenderCol,
      intent.defenderRow,
    );
    if (cityIndex == null) return false;
    final city = cities[cityIndex];
    if (city.ownerPlayerId == attacker.ownerPlayerId) return false;
    if (_isProtectedRelation(
      diplomacy,
      attacker.ownerPlayerId,
      city.ownerPlayerId,
    )) {
      return false;
    }

    final attackerTile = _tileDataAt(mapDefinition, attacker.col, attacker.row);
    if (attackerTile == null ||
        _tileDataAt(mapDefinition, city.center.col, city.center.row) == null) {
      return false;
    }

    final attackerResearch = state.research.forPlayer(attacker.ownerPlayerId);
    final attackerModifiers = CombatModifierCollector.forAttacker(
      unit: attacker,
      tile: attackerTile,
      research: attackerResearch,
      ruleset: ruleset.combat,
      technologyRuleset: ruleset.technology,
    );
    final attackerBaseStats = UnitCombatStats.derive(
      attacker,
      ruleset: ruleset.combat,
    );
    final attackerEffective = attackerBaseStats.applyAll(attackerModifiers);
    if (attackerEffective.attack <= 0) return false;
    if (_distanceToHex(attacker, city.center) > attackerEffective.range) {
      return false;
    }
    final cityBaseStats = ruleset.combat.cityBaseStats.add(
      WorldArtifactBonuses.cityCombatStatsFor(
        cityId: city.id,
        artifacts: state.artifacts,
      ),
    );
    if (cityBaseStats.hp <= 0) return false;
    final cityAttackDiplomacy = diplomacy.registerCityAttack(
      attackerPlayerId: attacker.ownerPlayerId,
      defenderPlayerId: city.ownerPlayerId,
      turn: turn,
    );
    final reputation = DiplomaticWarmongerReputation.apply(
      diplomacy: cityAttackDiplomacy,
      aggressorPlayerId: attacker.ownerPlayerId,
      victimPlayerId: city.ownerPlayerId,
      action: DiplomaticWarmongerAction.cityAttack,
      turn: turn,
      sourceId: 'city_attack.$turn.${attacker.id}',
    );
    updateDiplomacy(reputation.diplomacy);
    updateResourceTradeAgreements(
      _removeResourceTradeAgreementsBetween(
        resourceTradeAgreements,
        attacker.ownerPlayerId,
        city.ownerPlayerId,
      ),
    );
    final attackerCombatant = Combatant(
      unitId: attacker.id,
      ownerPlayerId: attacker.ownerPlayerId,
      baseStats: attackerBaseStats,
      modifiers: attackerModifiers,
      currentHp: UnitCombatHealth.currentHp(
        attacker,
        effectiveStats: attackerEffective,
      ),
    );
    final cityCombatant = Combatant(
      unitId: city.id,
      ownerPlayerId: city.ownerPlayerId,
      baseStats: cityBaseStats,
      currentHp: CityCombatHealth.currentHp(
        city,
        effectiveStats: cityBaseStats,
      ),
    );
    final outcome = CombatResolver.resolve(
      attacker: attackerCombatant,
      defender: cityCombatant,
      rng: CombatRng.fromTurn(
        turn: turn,
        attackerId: attacker.id,
        defenderId: city.id,
      ),
      ruleset: ruleset.combat,
    );
    events
      ..add(
        CombatResolvedEvent(
          attackerUnitId: attacker.id,
          defenderUnitId: city.id,
          outcome: outcome,
        ),
      )
      ..addAll(_warmongerScoreEvents(reputation.entries));

    final attackerExperience = UnitVeterancyRules.experienceAwardForCombat(
      unit: attacker,
      survived: !outcome.attackerKilled,
      defeatedEnemy: outcome.defenderKilled,
    );
    if (outcome.attackerKilled) {
      _dropUnitArtifacts(artifacts, attacker);
      units.removeAt(attackerIndex);
      events.add(
        UnitKilledEvent(
          unitId: attacker.id,
          ownerPlayerId: attacker.ownerPlayerId,
          attackerUnitId: city.id,
        ),
      );
    } else {
      final updatedAttacker = _withCombatState(
        attacker,
        hitPoints: outcome.attackerHpAfter,
        maxHitPoints: attackerCombatant.maxHp,
        movementPoints: 0,
        experienceAward: attackerExperience,
      );
      units[attackerIndex] = updatedAttacker;
      final experienceEvent = _experienceEvent(
        before: attacker,
        after: updatedAttacker,
        amount: attackerExperience,
      );
      if (experienceEvent != null) events.add(experienceEvent);
    }

    if (!outcome.defenderKilled) {
      cities[cityIndex] = city.copyWithHitPoints(
        CityCombatHealth.storedHp(
          outcome.defenderHpAfter,
          effectiveStats: cityBaseStats,
        ),
      );
      return true;
    }

    if (intent.cityConquestAction == CityConquestAction.destroy) {
      _dropStoredArtifactsFromCity(artifacts, city);
      cities.removeAt(cityIndex);
      events.add(
        CityDestroyedEvent(
          cityId: city.id,
          previousOwnerPlayerId: city.ownerPlayerId,
          attackerOwnerPlayerId: attacker.ownerPlayerId,
        ),
      );
      return true;
    }

    cities[cityIndex] = city.copyWith(
      ownerPlayerId: attacker.ownerPlayerId,
      hitPoints: CityCombatHealth.capturedHp(effectiveStats: cityBaseStats),
    );
    events.add(
      CityCapturedEvent(
        cityId: city.id,
        previousOwnerPlayerId: city.ownerPlayerId,
        newOwnerPlayerId: attacker.ownerPlayerId,
      ),
    );
    return true;
  }

  static int _distance(GameUnit a, GameUnit b) {
    return HexDistance.between(
      HexCoordinate(col: a.col, row: a.row),
      HexCoordinate(col: b.col, row: b.row),
    );
  }

  static int _distanceToHex(GameUnit unit, CityHex hex) {
    return HexDistance.between(
      HexCoordinate(col: unit.col, row: unit.row),
      HexCoordinate(col: hex.col, row: hex.row),
    );
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

  static List<DiplomaticScoreChangedEvent> _warmongerScoreEvents(
    Iterable<DiplomaticScoreEntry> entries,
  ) {
    return [
      for (final entry in entries)
        DiplomaticScoreChangedEvent(
          playerAId: entry.playerAId,
          playerBId: entry.playerBId,
          delta: entry.delta,
          scoreAfter: entry.scoreAfter,
          reason: entry.reason,
          sourceId: entry.sourceId,
        ),
    ];
  }

  static List<ResourceTradeAgreement> _removeResourceTradeAgreementsBetween(
    Iterable<ResourceTradeAgreement> agreements,
    String playerAId,
    String playerBId,
  ) {
    final key = DiplomacyState.relationKey(playerAId, playerBId);
    return [
      for (final agreement in agreements)
        if (DiplomacyState.relationKey(
              agreement.exporterPlayerId,
              agreement.importerPlayerId,
            ) !=
            key)
          agreement,
    ];
  }

  static GameUnit _withCombatState(
    GameUnit unit, {
    required int hitPoints,
    required int maxHitPoints,
    int? movementPoints,
    HexCoordinate? retreatDestination,
    int experienceAward = 0,
  }) {
    final updated = unit.copyWith(
      col: retreatDestination?.col,
      row: retreatDestination?.row,
      movementPoints: retreatDestination == null ? movementPoints : 0,
    );
    final withHitPoints = updated.copyWithHitPoints(
      hitPoints >= maxHitPoints ? null : hitPoints,
    );
    return UnitVeterancyRules.addExperience(withHitPoints, experienceAward);
  }

  static void _dropUnitArtifacts(List<WorldArtifact> artifacts, GameUnit unit) {
    final carriedId = unit.carriedArtifactId;
    final excavatingId = unit.excavatingArtifactId;
    if (carriedId == null && excavatingId == null) return;
    for (var i = 0; i < artifacts.length; i++) {
      final artifact = artifacts[i];
      if (artifact.id == carriedId || artifact.id == excavatingId) {
        artifacts[i] = artifact.copyWith(
          location: WorldArtifactLocation.map(col: unit.col, row: unit.row),
        );
      }
    }
  }

  static void _dropStoredArtifactsFromCity(
    List<WorldArtifact> artifacts,
    GameCity city,
  ) {
    for (var i = 0; i < artifacts.length; i++) {
      final artifact = artifacts[i];
      final location = artifact.location;
      if (location.isStored && location.cityId == city.id) {
        artifacts[i] = artifact.copyWith(
          location: WorldArtifactLocation.map(
            col: city.center.col,
            row: city.center.row,
          ),
        );
      }
    }
  }

  static UnitGainedExperienceEvent? _experienceEvent({
    required GameUnit before,
    required GameUnit after,
    required int amount,
  }) {
    if (amount <= 0) return null;
    final beforeRank = UnitVeterancyRules.rankFor(before);
    final afterRank = UnitVeterancyRules.rankFor(after);
    return UnitGainedExperienceEvent(
      unitId: after.id,
      ownerPlayerId: after.ownerPlayerId,
      amount: amount,
      totalExperience: after.experiencePoints,
      rank: afterRank,
      promoted: beforeRank != afterRank,
    );
  }
}
