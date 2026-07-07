import 'package:aonw_core/game/domain/combat/combat_modifier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'combat_stats.freezed.dart';

@freezed
abstract class CombatStats with _$CombatStats {
  const CombatStats._();

  const factory CombatStats({
    @Default(0) int attack,
    @Default(0) int defense,
    @Default(0) int hp,
    @Default(1) int range,
    @Default(1) int mobility,
  }) = _CombatStats;

  CombatStats add(CombatStats other) {
    return CombatStats(
      attack: attack + other.attack,
      defense: defense + other.defense,
      hp: hp + other.hp,
      range: range > other.range ? range : other.range,
      mobility: mobility + other.mobility,
    );
  }

  CombatStats multiply(int count) {
    return CombatStats(
      attack: attack * count,
      defense: defense * count,
      hp: hp * count,
      range: range,
      mobility: mobility * count,
    );
  }

  CombatStats apply(CombatModifier modifier) {
    return switch (modifier.target) {
      CombatStatTarget.attack => copyWith(attack: attack + modifier.delta),
      CombatStatTarget.defense => copyWith(defense: defense + modifier.delta),
      CombatStatTarget.hp => copyWith(hp: hp + modifier.delta),
      CombatStatTarget.range => copyWith(range: range + modifier.delta),
      CombatStatTarget.mobility => copyWith(
        mobility: mobility + modifier.delta,
      ),
    };
  }

  CombatStats applyAll(Iterable<CombatModifier> modifiers) {
    var stats = this;
    for (final modifier in modifiers) {
      stats = stats.apply(modifier);
    }
    return stats;
  }
}
