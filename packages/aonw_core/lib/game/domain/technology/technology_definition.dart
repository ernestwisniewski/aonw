import 'package:aonw_core/game/domain/technology/technology_boost.dart';
import 'package:aonw_core/game/domain/technology/technology_effect.dart';
import 'package:aonw_core/game/domain/technology/technology_era.dart';
import 'package:aonw_core/game/domain/technology/technology_id.dart';
import 'package:aonw_core/game/domain/technology/technology_tree_position.dart';
import 'package:aonw_core/game/domain/technology/technology_unlock.dart';
import 'package:aonw_core/util/collection_equality.dart';

class TechnologyDefinition {
  final TechnologyId id;
  final String name;
  final String description;
  final TechnologyEra era;
  final int baseCost;
  final List<TechnologyId> prerequisites;
  final List<TechnologyId> blockedBy;
  final List<TechnologyUnlock> unlocks;
  final List<TechnologyEffect> effects;
  final List<TechnologyBoostDefinition> boosts;
  final TechnologyTreePosition treePosition;

  const TechnologyDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.era,
    required this.baseCost,
    required this.treePosition,
    this.prerequisites = const [],
    this.blockedBy = const [],
    this.unlocks = const [],
    this.effects = const [],
    this.boosts = const [],
  });

  @override
  bool operator ==(Object other) =>
      other is TechnologyDefinition &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.era == era &&
      other.baseCost == baseCost &&
      listEquals(other.prerequisites, prerequisites) &&
      listEquals(other.blockedBy, blockedBy) &&
      listEquals(other.unlocks, unlocks) &&
      listEquals(other.effects, effects) &&
      listEquals(other.boosts, boosts) &&
      other.treePosition == treePosition;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    era,
    baseCost,
    Object.hashAll(prerequisites),
    Object.hashAll(blockedBy),
    Object.hashAll(unlocks),
    Object.hashAll(effects),
    Object.hashAll(boosts),
    treePosition,
  );
}
