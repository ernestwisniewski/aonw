import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_type_icon_resolver.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_type_icon.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('gameIconForUnitType', () {
    test('uses canonical icons for unit families', () {
      expect(
        gameIconForUnitType(GameUnitType.warrior),
        same(GameIcons.warrior),
      );
      expect(gameIconForUnitType(GameUnitType.archer), same(GameIcons.archer));
      expect(
        gameIconForUnitType(GameUnitType.worker),
        same(GameIcons.production),
      );
      expect(
        gameIconForUnitType(GameUnitType.merchant),
        same(GameIcons.commerce),
      );
      expect(
        gameIconForUnitType(GameUnitType.scout),
        same(GameIcons.visibility),
      );
      expect(gameIconForUnitType(GameUnitType.scoutShip), same(GameIcons.ship));
      expect(gameIconForUnitType(GameUnitType.warship), same(GameIcons.ship));
      expect(
        gameIconForUnitType(GameUnitType.fieldCannon),
        same(GameIcons.attack),
      );
    });

    test('unit markers reuse canonical unit icons', () {
      expect(
        UnitMarkerTypeIconResolver.iconFor(GameUnitType.warship),
        same(gameIconForUnitType(GameUnitType.warship)),
      );
      expect(
        UnitMarkerTypeIconResolver.iconFor(GameUnitType.scoutShip),
        same(gameIconForUnitType(GameUnitType.scoutShip)),
      );
    });
  });
}
