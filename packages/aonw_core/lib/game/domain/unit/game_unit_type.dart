enum GameUnitType {
  commander,
  warrior,
  archer,
  settler,
  worker,
  merchant,
  scout,
  spearman,
  cavalry,
  catapult,
  heavyInfantry,
  fieldCannon,
  rifleman,
  tank,
  scoutShip,
  warship,
  reconPlane;

  /// Stable token used as a default persisted unit name.
  ///
  /// User-facing labels must come from localization, not from this domain enum.
  String get defaultNameToken => name;

  bool get canBeProducedByCities => switch (this) {
    GameUnitType.commander ||
    GameUnitType.warrior ||
    GameUnitType.archer ||
    GameUnitType.settler ||
    GameUnitType.worker ||
    GameUnitType.merchant ||
    GameUnitType.scout ||
    GameUnitType.spearman ||
    GameUnitType.cavalry ||
    GameUnitType.catapult ||
    GameUnitType.heavyInfantry ||
    GameUnitType.fieldCannon ||
    GameUnitType.rifleman ||
    GameUnitType.tank ||
    GameUnitType.scoutShip ||
    GameUnitType.warship ||
    GameUnitType.reconPlane => true,
  };

  bool get isNaval => switch (this) {
    GameUnitType.scoutShip || GameUnitType.warship => true,
    GameUnitType.commander ||
    GameUnitType.warrior ||
    GameUnitType.archer ||
    GameUnitType.settler ||
    GameUnitType.worker ||
    GameUnitType.merchant ||
    GameUnitType.scout ||
    GameUnitType.spearman ||
    GameUnitType.cavalry ||
    GameUnitType.catapult ||
    GameUnitType.heavyInfantry ||
    GameUnitType.fieldCannon ||
    GameUnitType.rifleman ||
    GameUnitType.tank ||
    GameUnitType.reconPlane => false,
  };

  static GameUnitType fromName(String name) {
    return values.byName(name);
  }
}
