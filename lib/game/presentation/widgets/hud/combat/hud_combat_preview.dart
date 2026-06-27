import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

class HudCombatPreview {
  const HudCombatPreview({
    required this.attackerUnitId,
    required this.defenderUnitId,
    this.attackerOwnerPlayerId = '',
    this.defenderOwnerPlayerId = '',
    this.attackerCountry = PlayerCountry.poland,
    this.defenderCountry = PlayerCountry.poland,
    this.attackerUnitType,
    this.defenderUnitType,
    this.defenderCity,
    required this.attackerName,
    required this.defenderName,
    this.attackerTerrains = const [],
    this.defenderTerrains = const [],
    this.attackerModifiers = const [],
    this.defenderModifiers = const [],
    required this.attackerHpBefore,
    required this.defenderHpBefore,
    required this.attackerMaxHp,
    required this.defenderMaxHp,
    required this.attackerHpAfter,
    required this.defenderHpAfter,
    required this.attackerAttack,
    required this.attackerDefense,
    required this.defenderAttack,
    required this.defenderDefense,
    required this.attackDamage,
    required this.retaliationDamage,
    required this.attackerKilled,
    required this.defenderKilled,
    required this.defenderRetreated,
    required this.targetIsCity,
    required this.distance,
    required this.range,
  });

  final String attackerUnitId;
  final String defenderUnitId;
  final String attackerOwnerPlayerId;
  final String defenderOwnerPlayerId;
  final PlayerCountry attackerCountry;
  final PlayerCountry defenderCountry;
  final GameUnitType? attackerUnitType;
  final GameUnitType? defenderUnitType;
  final GameCity? defenderCity;
  final String attackerName;
  final String defenderName;
  final List<TerrainType> attackerTerrains;
  final List<TerrainType> defenderTerrains;
  final List<CombatModifier> attackerModifiers;
  final List<CombatModifier> defenderModifiers;
  final int attackerHpBefore;
  final int defenderHpBefore;
  final int attackerMaxHp;
  final int defenderMaxHp;
  final int attackerHpAfter;
  final int defenderHpAfter;
  final int attackerAttack;
  final int attackerDefense;
  final int defenderAttack;
  final int defenderDefense;
  final int attackDamage;
  final int retaliationDamage;
  final bool attackerKilled;
  final bool defenderKilled;
  final bool defenderRetreated;
  final bool targetIsCity;
  final int distance;
  final int range;

  bool get hasRetaliation => retaliationDamage > 0;

  String outcome(AppLocalizations l10n) {
    if (defenderKilled && targetIsCity) {
      return l10n.combatPreviewOutcomeCityFalls;
    }
    if (defenderKilled) return l10n.combatPreviewOutcomeDefenderKilled;
    if (attackerKilled) return l10n.combatPreviewOutcomeAttackerKilled;
    if (defenderRetreated) return l10n.combatPreviewOutcomeDefenderRetreated;
    return targetIsCity
        ? l10n.combatPreviewOutcomeCitySurvives
        : l10n.combatPreviewOutcomeDefenderSurvives;
  }

  String outcomeLine(AppLocalizations l10n) {
    return l10n.combatPreviewOutcomeLine(outcome(l10n));
  }

  String targetLine(AppLocalizations l10n) {
    final after = defenderKilled ? 0 : defenderHpAfter;
    return l10n.combatPreviewTargetLine(
      defenderHpBefore,
      after,
      defenderMaxHp,
      attackerAttack,
      defenderDefense,
      attackDamage,
    );
  }

  String attackerLine(AppLocalizations l10n) {
    if (!hasRetaliation) {
      return l10n.combatPreviewNoRetaliationLine(distance, range);
    }
    final after = attackerKilled ? 0 : attackerHpAfter;
    return l10n.combatPreviewRetaliationLine(
      defenderAttack,
      attackerDefense,
      retaliationDamage,
      attackerHpBefore,
      after,
      attackerMaxHp,
    );
  }

  List<String> detailLines(AppLocalizations l10n) => [
    outcomeLine(l10n),
    targetLine(l10n),
    attackerLine(l10n),
  ];
}

abstract final class HudCombatPreviewFactory {
  static HudCombatPreview? from({
    required GameState? gameState,
    required MapData mapData,
    required int turn,
    CombatRuleset combatRuleset = CombatRuleset.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    final state = gameState;
    if (state == null ||
        combatRuleset.resolutionMode != CombatResolutionMode.instant) {
      return null;
    }

    final pendingAction = state.pendingAction;
    if (pendingAction is! PendingAttackTargeting) return null;

    final attacker = state.unitById(pendingAction.attackerUnitId);
    if (attacker == null ||
        !state.canControlUnit(attacker) ||
        attacker.isWorking ||
        attacker.movementPoints <= 0) {
      return null;
    }

    final attackerTile = mapData.tileAt(attacker.col, attacker.row);
    if (attackerTile == null) return null;

    final attackerModifiers = CombatModifierCollector.forAttacker(
      unit: attacker,
      tile: attackerTile,
      research: state.research.forPlayer(attacker.ownerPlayerId),
      ruleset: combatRuleset,
      technologyRuleset: technologyRuleset,
    );
    final attackerBase = UnitCombatStats.derive(
      attacker,
      ruleset: combatRuleset,
    );
    final attackerEffective = attackerBase.applyAll(attackerModifiers);
    if (attackerEffective.attack <= 0) return null;

    final target = pendingAction.hasDefenderTarget
        ? _targetAt(
            state: state,
            mapData: mapData,
            attacker: attacker,
            attackerRange: attackerEffective.range,
            col: pendingAction.defenderCol!,
            row: pendingAction.defenderRow!,
          )
        : _bestVisibleTarget(
            state: state,
            mapData: mapData,
            attacker: attacker,
            attackerRange: attackerEffective.range,
          );
    if (target == null) return null;

    final defender = target.defender;
    final defenderTile = target.tile;
    final defenderModifiers = defender == null
        ? const <CombatModifier>[]
        : CombatModifierCollector.forDefender(
            unit: defender,
            tile: defenderTile,
            defendedCity: _cityAt(state, defender.col, defender.row),
            research: state.research.forPlayer(defender.ownerPlayerId),
            ruleset: combatRuleset,
            technologyRuleset: technologyRuleset,
          );
    final defenderBase = defender == null
        ? combatRuleset.cityBaseStats
        : UnitCombatStats.derive(defender, ruleset: combatRuleset);
    final defenderEffective = defenderBase.applyAll(defenderModifiers);
    final retreatDestination = defender != null && defenderEffective.attack > 0
        ? CombatRetreatResolver.destination(
            attacker: attacker,
            defender: defender,
            units: state.units,
            tileAt: mapData.tileAt,
          )
        : null;

    final attackerCombatant = Combatant(
      unitId: attacker.id,
      ownerPlayerId: attacker.ownerPlayerId,
      baseStats: attackerBase,
      modifiers: attackerModifiers,
      currentHp: UnitCombatHealth.currentHp(
        attacker,
        effectiveStats: attackerEffective,
      ),
    );
    final defenderCombatant = Combatant(
      unitId: target.id,
      ownerPlayerId: target.ownerPlayerId,
      baseStats: defenderBase,
      modifiers: defenderModifiers,
      currentHp: target.currentHp(defenderEffective),
    );
    final outcome = CombatResolver.resolve(
      attacker: attackerCombatant,
      defender: defenderCombatant,
      ruleset: combatRuleset,
      rng: CombatRng.fromTurn(
        turn: turn,
        attackerId: attacker.id,
        defenderId: target.id,
      ),
      defenderCanRetreat: retreatDestination != null,
    );

    return HudCombatPreview(
      attackerUnitId: attacker.id,
      defenderUnitId: target.id,
      attackerOwnerPlayerId: attacker.ownerPlayerId,
      defenderOwnerPlayerId: target.ownerPlayerId,
      attackerCountry: state.countryForPlayer(attacker.ownerPlayerId),
      defenderCountry: state.countryForPlayer(target.ownerPlayerId),
      attackerUnitType: attacker.type,
      defenderUnitType: defender?.type,
      defenderCity: target.city,
      attackerName: attacker.name,
      defenderName: target.name,
      attackerTerrains: List.unmodifiable(attackerTile.terrains),
      defenderTerrains: List.unmodifiable(defenderTile.terrains),
      attackerModifiers: List.unmodifiable(attackerModifiers),
      defenderModifiers: List.unmodifiable(defenderModifiers),
      attackerHpBefore: attackerCombatant.currentHp,
      defenderHpBefore: defenderCombatant.currentHp,
      attackerMaxHp: attackerCombatant.maxHp,
      defenderMaxHp: defenderCombatant.maxHp,
      attackerHpAfter: outcome.attackerHpAfter,
      defenderHpAfter: outcome.defenderHpAfter,
      attackerAttack: attackerEffective.attack,
      attackerDefense: attackerEffective.defense,
      defenderAttack: defenderEffective.attack,
      defenderDefense: defenderEffective.defense,
      attackDamage: _damageFromAttack(outcome),
      retaliationDamage: _damageFromRetaliation(outcome),
      attackerKilled: outcome.attackerKilled,
      defenderKilled: outcome.defenderKilled,
      defenderRetreated: outcome.defenderRetreated,
      targetIsCity: target.isCity,
      distance: target.distance,
      range: attackerEffective.range,
    );
  }

  static _PreviewTarget? _targetAt({
    required GameState state,
    required MapData mapData,
    required GameUnit attacker,
    required int attackerRange,
    required int col,
    required int row,
  }) {
    final defender = state.unitAt(col, row);
    if (defender != null) {
      if (defender.id == attacker.id ||
          defender.ownerPlayerId == attacker.ownerPlayerId ||
          !state.activePlayerVisibility.canSeeDynamicAt(
            defender.col,
            defender.row,
          )) {
        return null;
      }

      final tile = mapData.tileAt(defender.col, defender.row);
      if (tile == null) return null;

      final distance = HexDistance.between(
        HexCoordinate(col: attacker.col, row: attacker.row),
        HexCoordinate(col: defender.col, row: defender.row),
      );
      if (distance > attackerRange) return null;

      return _PreviewTarget.unit(
        defender: defender,
        tile: tile,
        distance: distance,
      );
    }

    final city = _enemyCityAt(state, col, row, attacker.ownerPlayerId);
    if (city == null ||
        !state.activePlayerVisibility.canSeeDynamicAt(
          city.center.col,
          city.center.row,
        )) {
      return null;
    }

    final tile = mapData.tileAt(city.center.col, city.center.row);
    if (tile == null) return null;

    final distance = HexDistance.between(
      HexCoordinate(col: attacker.col, row: attacker.row),
      HexCoordinate(col: city.center.col, row: city.center.row),
    );
    if (distance > attackerRange) return null;

    return _PreviewTarget.city(city: city, tile: tile, distance: distance);
  }

  static _PreviewTarget? _bestVisibleTarget({
    required GameState state,
    required MapData mapData,
    required GameUnit attacker,
    required int attackerRange,
  }) {
    final visibility = state.activePlayerVisibility;
    final candidates = <_PreviewTarget>[];
    final attackerHex = HexCoordinate(col: attacker.col, row: attacker.row);

    for (final unit in state.units) {
      if (unit.id == attacker.id ||
          unit.ownerPlayerId == attacker.ownerPlayerId ||
          !visibility.canSeeDynamicAt(unit.col, unit.row)) {
        continue;
      }
      final tile = mapData.tileAt(unit.col, unit.row);
      if (tile == null) continue;

      final distance = HexDistance.between(
        attackerHex,
        HexCoordinate(col: unit.col, row: unit.row),
      );
      if (distance > attackerRange) continue;

      candidates.add(
        _PreviewTarget.unit(defender: unit, tile: tile, distance: distance),
      );
    }

    for (final city in state.cities) {
      if (city.ownerPlayerId == attacker.ownerPlayerId ||
          !visibility.canSeeDynamicAt(city.center.col, city.center.row)) {
        continue;
      }
      if (state.unitAt(city.center.col, city.center.row) != null) continue;
      final tile = mapData.tileAt(city.center.col, city.center.row);
      if (tile == null) continue;

      final distance = HexDistance.between(
        attackerHex,
        HexCoordinate(col: city.center.col, row: city.center.row),
      );
      if (distance > attackerRange) continue;

      candidates.add(
        _PreviewTarget.city(city: city, tile: tile, distance: distance),
      );
    }

    candidates.sort((left, right) {
      final distance = left.distance.compareTo(right.distance);
      if (distance != 0) return distance;
      final col = left.col.compareTo(right.col);
      if (col != 0) return col;
      final row = left.row.compareTo(right.row);
      if (row != 0) return row;
      return left.id.compareTo(right.id);
    });
    return candidates.isEmpty ? null : candidates.first;
  }

  static GameCity? _cityAt(GameState state, int col, int row) {
    for (final city in state.cities) {
      if (city.center.col == col && city.center.row == row) return city;
    }
    return null;
  }

  static GameCity? _enemyCityAt(
    GameState state,
    int col,
    int row,
    String attackerOwnerPlayerId,
  ) {
    for (final city in state.cities) {
      if (city.ownerPlayerId == attackerOwnerPlayerId) continue;
      if (city.center.col == col && city.center.row == row) return city;
    }
    return null;
  }

  static int _damageFromAttack(CombatOutcome outcome) {
    for (final step in outcome.steps) {
      if (step is AttackStep) return step.damage;
    }
    return 0;
  }

  static int _damageFromRetaliation(CombatOutcome outcome) {
    for (final step in outcome.steps) {
      if (step is RetaliationStep) return step.damage;
    }
    return 0;
  }
}

class _PreviewTarget {
  const _PreviewTarget.unit({
    required GameUnit this.defender,
    required this.tile,
    required this.distance,
  }) : city = null;

  const _PreviewTarget.city({
    required GameCity this.city,
    required this.tile,
    required this.distance,
  }) : defender = null;

  final GameUnit? defender;
  final GameCity? city;
  final TileData tile;
  final int distance;

  bool get isCity => city != null;

  String get id => defender?.id ?? city!.id;

  String get ownerPlayerId => defender?.ownerPlayerId ?? city!.ownerPlayerId;

  String get name => defender?.name ?? city!.name;

  int get col => defender?.col ?? city!.center.col;

  int get row => defender?.row ?? city!.center.row;

  int currentHp(CombatStats effectiveStats) {
    final defender = this.defender;
    if (defender != null) {
      return UnitCombatHealth.currentHp(
        defender,
        effectiveStats: effectiveStats,
      );
    }
    return CityCombatHealth.currentHp(city!, effectiveStats: effectiveStats);
  }
}
