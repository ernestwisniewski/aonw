enum FieldImprovementType {
  farm,
  riverFarm,
  mine,
  lumberMill,
  pasture,
  camp,
  quarry,
  fishingBoats,
  orchard,
  plantation,
  vineyard,
  tradingPost,
  prospectorCamp,
  horseRanch,
  pearlDivers,
  coalShaft,
  oilWell,
  bauxiteMine,
  uraniumMine;

  String get displayName => switch (this) {
    FieldImprovementType.farm => 'Farm',
    FieldImprovementType.riverFarm => 'River farm',
    FieldImprovementType.mine => 'Mine',
    FieldImprovementType.lumberMill => 'Lumber mill',
    FieldImprovementType.pasture => 'Pasture',
    FieldImprovementType.camp => 'Camp',
    FieldImprovementType.quarry => 'Quarry',
    FieldImprovementType.fishingBoats => 'Fishing boats',
    FieldImprovementType.orchard => 'Orchard',
    FieldImprovementType.plantation => 'Plantation',
    FieldImprovementType.vineyard => 'Vineyard',
    FieldImprovementType.tradingPost => 'Trading post',
    FieldImprovementType.prospectorCamp => 'Prospector camp',
    FieldImprovementType.horseRanch => 'Horse ranch',
    FieldImprovementType.pearlDivers => 'Pearl divers',
    FieldImprovementType.coalShaft => 'Coal shaft',
    FieldImprovementType.oilWell => 'Oil well',
    FieldImprovementType.bauxiteMine => 'Bauxite mine',
    FieldImprovementType.uraniumMine => 'Uranium mine',
  };

  static FieldImprovementType fromString(String value) {
    return FieldImprovementType.values.firstWhere(
      (type) => type.name == value,
      orElse: () =>
          throw ArgumentError('Unknown field improvement type: $value'),
    );
  }
}
