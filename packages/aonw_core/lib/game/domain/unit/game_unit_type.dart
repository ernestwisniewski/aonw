import 'package:aonw_core/game/domain/unit/unit_catalog.dart';

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

  bool get canBeProducedByCities =>
      UnitCatalog.specFor(this).capabilities.producibleByCities;

  bool get isNaval => UnitCatalog.specFor(this).capabilities.naval;

  static GameUnitType fromName(String name) {
    return values.byName(name);
  }
}
