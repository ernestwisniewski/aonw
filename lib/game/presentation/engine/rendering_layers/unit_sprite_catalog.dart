import 'package:aonw/game/presentation/engine/rendering_layers/unit_sprite.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class UnitSpriteCatalog {
  static const UnitSpriteSize _normalSize = UnitSpriteSize(
    width: 64,
    height: 86,
  );
  static const UnitSpriteSize _smallSize = UnitSpriteSize(
    width: 42,
    height: 57,
  );
  static const UnitSpriteSize _wideSize = UnitSpriteSize(width: 76, height: 72);
  static const UnitSpriteSize _wideSmallSize = UnitSpriteSize(
    width: 50,
    height: 47,
  );

  static final UnitSpriteDefinition commander = UnitSpriteDefinition(
    assetPath: 'assets/sprites/units/commander.png',
    normalSize: _normalSize,
    smallSize: _smallSize,
    actions: _unitActions(),
  );

  static final UnitSpriteDefinition warrior = UnitSpriteDefinition(
    assetPath: 'assets/sprites/units/warrior.png',
    normalSize: _normalSize,
    smallSize: _smallSize,
    actions: _unitActions(),
  );

  static final UnitSpriteDefinition archer = UnitSpriteDefinition(
    assetPath: 'assets/sprites/units/archer.png',
    normalSize: _normalSize,
    smallSize: _smallSize,
    actions: _unitActions(),
  );

  static final UnitSpriteDefinition settler = UnitSpriteDefinition(
    assetPath: 'assets/sprites/units/settler.png',
    normalSize: _normalSize,
    smallSize: _smallSize,
    actions: _civilianUnitActions(),
  );

  static final UnitSpriteDefinition worker = UnitSpriteDefinition(
    assetPath: 'assets/sprites/units/worker.png',
    normalSize: _normalSize,
    smallSize: _smallSize,
    actions: _civilianUnitActions(),
  );

  static final UnitSpriteDefinition merchant = UnitSpriteDefinition(
    assetPath: 'assets/sprites/units/merchant.png',
    normalSize: _normalSize,
    smallSize: _smallSize,
    actions: _civilianUnitActions(),
  );

  static UnitSpriteDefinition _definition(
    String assetName, {
    UnitSpriteSize normalSize = _normalSize,
    UnitSpriteSize smallSize = _smallSize,
  }) {
    return UnitSpriteDefinition(
      assetPath: 'assets/sprites/units/$assetName.png',
      normalSize: normalSize,
      smallSize: smallSize,
      actions: _unitActions(),
    );
  }

  static final Map<GameUnitType, UnitSpriteDefinition> _definitions = {
    GameUnitType.commander: commander,
    GameUnitType.warrior: warrior,
    GameUnitType.archer: archer,
    GameUnitType.settler: settler,
    GameUnitType.worker: worker,
    GameUnitType.merchant: merchant,
    GameUnitType.scout: _definition('scout'),
    GameUnitType.spearman: _definition('spearman'),
    GameUnitType.cavalry: _definition('cavalry'),
    GameUnitType.catapult: _definition(
      'catapult',
      normalSize: _wideSize,
      smallSize: _wideSmallSize,
    ),
    GameUnitType.heavyInfantry: _definition('heavyInfantry'),
    GameUnitType.fieldCannon: _definition(
      'fieldCannon',
      normalSize: _wideSize,
      smallSize: _wideSmallSize,
    ),
    GameUnitType.rifleman: _definition('rifleman'),
    GameUnitType.tank: _definition(
      'tank',
      normalSize: _wideSize,
      smallSize: _wideSmallSize,
    ),
    GameUnitType.scoutShip: _definition(
      'scoutShip',
      normalSize: _wideSize,
      smallSize: _wideSmallSize,
    ),
    GameUnitType.warship: _definition(
      'warship',
      normalSize: _wideSize,
      smallSize: _wideSmallSize,
    ),
    GameUnitType.reconPlane: _definition(
      'reconPlane',
      normalSize: _wideSize,
      smallSize: _wideSmallSize,
    ),
  };

  static UnitSpriteDefinition? definitionFor(GameUnitType type) =>
      _definitions[type];

  static Map<GameUnitType, UnitSpriteDefinition> get definitions =>
      Map.unmodifiable(_definitions);

  static UnitSpriteComponent? componentFor(GameUnitType type) {
    final definition = definitionFor(type);
    return definition == null ? null : UnitSpriteComponent(definition);
  }

  static Map<UnitSpriteAction, UnitSpriteActionDefinition>
  _civilianUnitActions() {
    return {
      UnitSpriteAction.idle: const UnitSpriteActionDefinition(
        row: 0,
        frameDuration: 0.9,
      ),
      UnitSpriteAction.walk: const UnitSpriteActionDefinition(
        row: 1,
        frameDuration: 0.14,
      ),
      UnitSpriteAction.work: const UnitSpriteActionDefinition(
        row: 2,
        frameDuration: 0.22,
      ),
      UnitSpriteAction.die: const UnitSpriteActionDefinition(
        row: 3,
        frameDuration: 0.18,
        loops: false,
      ),
    };
  }

  static Map<UnitSpriteAction, UnitSpriteActionDefinition> _unitActions() {
    return {
      UnitSpriteAction.idle: const UnitSpriteActionDefinition(
        row: 0,
        frameDuration: 0.9,
      ),
      UnitSpriteAction.walk: const UnitSpriteActionDefinition(
        row: 1,
        frameDuration: 0.14,
      ),
      UnitSpriteAction.attack: const UnitSpriteActionDefinition(
        row: 2,
        frameDuration: 0.13,
        loops: false,
      ),
      UnitSpriteAction.die: const UnitSpriteActionDefinition(
        row: 3,
        frameDuration: 0.18,
        loops: false,
      ),
    };
  }
}
