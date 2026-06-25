enum CombatStatTarget { attack, defense, hp, range, mobility }

sealed class CombatModifier {
  final String label;
  final CombatStatTarget target;
  final int delta;

  const CombatModifier({
    required this.label,
    required this.target,
    required this.delta,
  });

  @override
  bool operator ==(Object other) {
    return other.runtimeType == runtimeType &&
        other is CombatModifier &&
        other.label == label &&
        other.target == target &&
        other.delta == delta;
  }

  @override
  int get hashCode => Object.hash(runtimeType, label, target, delta);

  @override
  String toString() {
    return '$runtimeType(label: $label, target: $target, delta: $delta)';
  }
}

final class TerrainModifier extends CombatModifier {
  const TerrainModifier({
    required super.label,
    required super.target,
    required super.delta,
  });
}

final class FortificationModifier extends CombatModifier {
  const FortificationModifier({
    required super.label,
    required super.target,
    required super.delta,
  });
}

final class TechnologyModifier extends CombatModifier {
  const TechnologyModifier({
    required super.label,
    required super.target,
    required super.delta,
  });
}

final class CounterModifier extends CombatModifier {
  const CounterModifier({
    required super.label,
    required super.target,
    required super.delta,
  });
}

final class TroopCompositionModifier extends CombatModifier {
  const TroopCompositionModifier({
    required super.label,
    required super.target,
    required super.delta,
  });
}

final class VeterancyModifier extends CombatModifier {
  const VeterancyModifier({
    required super.label,
    required super.target,
    required super.delta,
  });
}
