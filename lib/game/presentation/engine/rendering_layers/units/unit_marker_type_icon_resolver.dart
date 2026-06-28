import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_type_icon.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class UnitMarkerTypeIconResolver {
  static GameIconData iconFor(GameUnitType type) => gameIconForUnitType(type);
}
