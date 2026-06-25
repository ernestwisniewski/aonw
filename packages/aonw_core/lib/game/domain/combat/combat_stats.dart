import 'package:aonw_core/game/domain/combat/combat_modifier.dart';

class CombatStats {
  final int attack;
  final int defense;
  final int hp;
  final int range;
  final int mobility;

  const CombatStats({
    this.attack = 0,
    this.defense = 0,
    this.hp = 0,
    this.range = 1,
    this.mobility = 1,
  });

  CombatStats copyWith({
    int? attack,
    int? defense,
    int? hp,
    int? range,
    int? mobility,
  }) {
    return CombatStats(
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      hp: hp ?? this.hp,
      range: range ?? this.range,
      mobility: mobility ?? this.mobility,
    );
  }

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

  @override
  bool operator ==(Object other) {
    return other is CombatStats &&
        other.attack == attack &&
        other.defense == defense &&
        other.hp == hp &&
        other.range == range &&
        other.mobility == mobility;
  }

  @override
  int get hashCode => Object.hash(attack, defense, hp, range, mobility);

  @override
  String toString() {
    return 'CombatStats(attack: $attack, defense: $defense, hp: $hp, '
        'range: $range, mobility: $mobility)';
  }
}
