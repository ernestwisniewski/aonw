import 'package:aonw/game/domain/city.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/player.dart';
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
    required this.defenderRange,
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
  final int defenderRange;
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
      return l10n.combatPreviewNoRetaliationLine(distance, defenderRange);
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
