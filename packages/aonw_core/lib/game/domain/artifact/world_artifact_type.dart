import 'package:aonw_core/game/domain/tile_yield.dart';

enum WorldArtifactType {
  ancientImperialCrown,
  astronomersTablets,
  prophetMask,
  heroSword,
  merchantsSeal,
  firstPeoplesChronicle,
  templeReliquary,
  queensMirror;

  String get displayName => switch (this) {
    WorldArtifactType.ancientImperialCrown => 'Korona Dawnego Imperium',
    WorldArtifactType.astronomersTablets => 'Tablice Astronomow',
    WorldArtifactType.prophetMask => 'Maska Proroka',
    WorldArtifactType.heroSword => 'Miecz Bohatera',
    WorldArtifactType.merchantsSeal => 'Pieczec Kupcow',
    WorldArtifactType.firstPeoplesChronicle => 'Kronika Pierwszych Ludow',
    WorldArtifactType.templeReliquary => 'Relikwiarz Swiatynny',
    WorldArtifactType.queensMirror => 'Zwierciadlo Krolowej',
  };

  TileYield get cityYield => switch (this) {
    WorldArtifactType.ancientImperialCrown => const TileYield(
      food: 0,
      production: 0,
      gold: 0,
      defense: 1,
    ),
    WorldArtifactType.astronomersTablets => TileYield.zero,
    WorldArtifactType.prophetMask => const TileYield(
      food: 0,
      production: 0,
      gold: 1,
      defense: 0,
    ),
    WorldArtifactType.heroSword => TileYield.zero,
    WorldArtifactType.merchantsSeal => const TileYield(
      food: 0,
      production: 0,
      gold: 2,
      defense: 0,
    ),
    WorldArtifactType.firstPeoplesChronicle => const TileYield(
      food: 1,
      production: 0,
      gold: 0,
      defense: 0,
    ),
    WorldArtifactType.templeReliquary => const TileYield(
      food: 1,
      production: 0,
      gold: 0,
      defense: 1,
    ),
    WorldArtifactType.queensMirror => const TileYield(
      food: 0,
      production: 0,
      gold: 1,
      defense: 0,
    ),
  };

  int get sciencePerTurn => switch (this) {
    WorldArtifactType.astronomersTablets => 1,
    _ => 0,
  };

  int get producedUnitExperience => switch (this) {
    WorldArtifactType.heroSword => 2,
    _ => 0,
  };

  int get diplomacyValue => switch (this) {
    WorldArtifactType.prophetMask => 18,
    WorldArtifactType.queensMirror => 18,
    WorldArtifactType.ancientImperialCrown => 14,
    WorldArtifactType.templeReliquary => 12,
    WorldArtifactType.merchantsSeal => 10,
    WorldArtifactType.astronomersTablets => 10,
    WorldArtifactType.firstPeoplesChronicle => 10,
    WorldArtifactType.heroSword => 10,
  };

  String get shortBonusLabel => switch (this) {
    WorldArtifactType.ancientImperialCrown => '+1 defense',
    WorldArtifactType.astronomersTablets => '+1 science',
    WorldArtifactType.prophetMask => '+1 gold, diplomacy',
    WorldArtifactType.heroSword => '+2 XP to produced units',
    WorldArtifactType.merchantsSeal => '+2 gold',
    WorldArtifactType.firstPeoplesChronicle => '+1 food',
    WorldArtifactType.templeReliquary => '+1 food, +1 defense',
    WorldArtifactType.queensMirror => '+1 gold, diplomacy',
  };

  static WorldArtifactType fromName(String name) => values.byName(name);
}
