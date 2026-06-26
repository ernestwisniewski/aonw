import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/combat/hud_combat_preview.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudCombatPreviewFactory', () {
    final l10n = AppLocalizationsEn();

    test('melee preview includes attack and retaliation damage', () {
      final ruleset = CombatRuleset(
        varianceRange: 0,
        unitBaseStats: {
          ...CombatRuleset.standard.unitBaseStats,
          GameUnitType.warrior: const CombatStats(
            attack: 6,
            defense: 1,
            hp: 10,
            range: 1,
            mobility: 1,
          ),
        },
      );
      final attacker = _unit(
        id: 'attacker',
        ownerPlayerId: 'p1',
        name: 'Player warrior',
        col: 0,
        row: 0,
      );
      final defender = _unit(
        id: 'defender',
        ownerPlayerId: 'p2',
        name: 'Enemy warrior',
        col: 1,
        row: 0,
      );
      final state = _state(attacker: attacker, enemies: [defender]);

      final preview = HudCombatPreviewFactory.from(
        gameState: state,
        mapData: _map(3, 3),
        turn: 1,
        combatRuleset: ruleset,
      );

      expect(preview, isNotNull);
      expect(preview!.attackerUnitId, 'attacker');
      expect(preview.defenderUnitId, 'defender');
      expect(preview.attackerUnitType, GameUnitType.warrior);
      expect(preview.defenderUnitType, GameUnitType.warrior);
      expect(preview.attackDamage, 5);
      expect(preview.retaliationDamage, 5);
      expect(preview.attackerAttack, 6);
      expect(preview.attackerDefense, 1);
      expect(preview.defenderAttack, 6);
      expect(preview.defenderDefense, 1);
      expect(preview.attackerHpAfter, 5);
      expect(preview.defenderHpAfter, 5);
      expect(preview.hasRetaliation, isTrue);
      expect(preview.outcomeLine(l10n), 'Outcome: defender survives');
      expect(
        preview.targetLine(l10n),
        'Target: HP 10->5/10, Attack 6 vs Defense 1 (-5)',
      );
      expect(
        preview.attackerLine(l10n),
        'Retaliation: Attack 6 vs Defense 1 (-5), HP 10->5/10',
      );
    });

    test('ranged preview marks no retaliation', () {
      final ruleset = CombatRuleset(
        varianceRange: 0,
        unitBaseStats: {
          ...CombatRuleset.standard.unitBaseStats,
          GameUnitType.archer: const CombatStats(
            attack: 6,
            defense: 1,
            hp: 8,
            range: 2,
            mobility: 1,
          ),
          GameUnitType.warrior: const CombatStats(
            attack: 4,
            defense: 1,
            hp: 10,
            range: 1,
            mobility: 1,
          ),
        },
      );
      final attacker = _unit(
        id: 'archer',
        ownerPlayerId: 'p1',
        type: GameUnitType.archer,
        name: 'Archer',
        col: 0,
        row: 0,
      );
      final defender = _unit(
        id: 'defender',
        ownerPlayerId: 'p2',
        name: 'Enemy warrior',
        col: 2,
        row: 0,
      );
      final state = _state(attacker: attacker, enemies: [defender]);

      final preview = HudCombatPreviewFactory.from(
        gameState: state,
        mapData: _map(4, 3),
        turn: 1,
        combatRuleset: ruleset,
      );

      expect(preview, isNotNull);
      expect(preview!.distance, 2);
      expect(preview.range, 2);
      expect(preview.attackDamage, 5);
      expect(preview.retaliationDamage, 0);
      expect(preview.attackerHpAfter, 8);
      expect(preview.hasRetaliation, isFalse);
      expect(
        preview.attackerLine(l10n),
        'Retaliation: none (ranged attack, distance 2, range 2)',
      );
    });

    test('uses the selected attack target when one is pending', () {
      final attacker = _unit(
        id: 'attacker',
        ownerPlayerId: 'p1',
        name: 'Player warrior',
        col: 0,
        row: 0,
      );
      final nearest = _unit(
        id: 'nearest',
        ownerPlayerId: 'p2',
        name: 'Nearest enemy',
        col: 1,
        row: 0,
      );
      final selected = _unit(
        id: 'selected',
        ownerPlayerId: 'p2',
        name: 'Selected enemy',
        col: 0,
        row: 1,
      );
      final state = _state(
        attacker: attacker,
        enemies: [nearest, selected],
        defenderCol: 0,
        defenderRow: 1,
      );

      final preview = HudCombatPreviewFactory.from(
        gameState: state,
        mapData: _map(3, 3),
        turn: 1,
      );

      expect(preview, isNotNull);
      expect(preview!.defenderUnitId, 'selected');
      expect(preview.defenderName, 'Selected enemy');
    });

    test('returns null when the selected attack target is invalid', () {
      final attacker = _unit(
        id: 'attacker',
        ownerPlayerId: 'p1',
        name: 'Player warrior',
        col: 0,
        row: 0,
      );
      final defender = _unit(
        id: 'defender',
        ownerPlayerId: 'p2',
        name: 'Enemy warrior',
        col: 1,
        row: 0,
      );
      final state = _state(
        attacker: attacker,
        enemies: [defender],
        defenderCol: 2,
        defenderRow: 2,
      );

      final preview = HudCombatPreviewFactory.from(
        gameState: state,
        mapData: _map(3, 3),
        turn: 1,
      );

      expect(preview, isNull);
    });

    test('returns null outside active attack targeting', () {
      final attacker = _unit(
        id: 'attacker',
        ownerPlayerId: 'p1',
        name: 'Player warrior',
        col: 0,
        row: 0,
      );
      final defender = _unit(
        id: 'defender',
        ownerPlayerId: 'p2',
        name: 'Enemy warrior',
        col: 1,
        row: 0,
      );
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker, defender],
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
      );

      final preview = HudCombatPreviewFactory.from(
        gameState: state,
        mapData: _map(3, 3),
        turn: 1,
      );

      expect(preview, isNull);
    });
  });
}

GameState _state({
  required GameUnit attacker,
  required List<GameUnit> enemies,
  int? defenderCol,
  int? defenderRow,
}) {
  return GameState(
    activePlayerId: attacker.ownerPlayerId,
    units: [attacker, ...enemies],
    pendingAction: PendingAttackTargeting(
      ownerPlayerId: attacker.ownerPlayerId,
      attackerUnitId: attacker.id,
      defenderCol: defenderCol,
      defenderRow: defenderRow,
    ),
    fogOfWar: _visible(attacker.ownerPlayerId, [
      HexCoordinate(col: attacker.col, row: attacker.row),
      for (final enemy in enemies)
        HexCoordinate(col: enemy.col, row: enemy.row),
    ]),
  );
}

GameUnit _unit({
  required String id,
  required String ownerPlayerId,
  required String name,
  required int col,
  required int row,
  GameUnitType type = GameUnitType.warrior,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: name,
    col: col,
    row: row,
  );
}

FogOfWarState _visible(String playerId, Iterable<HexCoordinate> hexes) {
  return FogOfWarState(
    players: {
      playerId: PlayerFogOfWar(
        playerId: playerId,
        visibleHexes: Set<HexCoordinate>.of(hexes),
      ),
    },
  );
}

MapData _map(int cols, int rows) => MapData(
  cols: cols,
  rows: rows,
  tiles: [
    for (var col = 0; col < cols; col++)
      for (var row = 0; row < rows; row++)
        TileData(
          col: col,
          row: row,
          height: 0,
          terrains: const [TerrainType.grassland],
          resources: const [],
        ),
  ],
);
