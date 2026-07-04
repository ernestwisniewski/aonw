import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_catalog.dart';
import 'package:aonw_core/game/domain/unit/unit_spec.dart';

class UnitSpecResolver {
  static const standard = UnitSpecResolver();

  final Map<GameUnitType, UnitSpec> catalog;

  const UnitSpecResolver({this.catalog = UnitCatalog.standard});

  UnitSpec specFor(GameUnitType type) {
    final spec = catalog[type];
    if (spec == null) {
      throw StateError('No UnitSpec registered for $type');
    }
    return spec;
  }
}
