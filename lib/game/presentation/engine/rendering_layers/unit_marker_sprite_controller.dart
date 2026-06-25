import 'package:aonw/game/presentation/engine/rendering_layers/unit_sprite.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_sprite_catalog.dart';
import 'package:aonw/map/rendering/tile/hex_icon_cache.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';

class UnitMarkerSpriteController {
  UnitMarkerSpriteController(GameUnitType unitType)
    : _unitType = unitType,
      _sprite = UnitSpriteCatalog.componentFor(unitType);

  GameUnitType _unitType;
  UnitSpriteComponent? _sprite;
  bool _idlePausesEnabled = true;

  GameUnitType get unitType => _unitType;

  UnitSpriteComponent? get sprite => _sprite;

  bool get hasSpriteAsset => _sprite != null;

  int get currentColumn => _sprite?.currentColumn ?? 0;

  UnitSpriteAction? get action => _sprite?.action;

  bool get idlePausesEnabled => _idlePausesEnabled;

  set idlePausesEnabled(bool value) {
    if (_idlePausesEnabled == value) return;
    _idlePausesEnabled = value;
    _sprite?.idlePausesEnabled = value;
  }

  bool setUnitType(GameUnitType value) {
    if (_unitType == value) return false;
    _unitType = value;
    _sprite = UnitSpriteCatalog.componentFor(value);
    _sprite?.idlePausesEnabled = _idlePausesEnabled;
    return true;
  }

  Future<void> loadIfNeeded() async {
    final sprite = _sprite;
    if (sprite == null) return;
    final image = await HexIconCache.load(sprite.definition.assetPath);
    if (!identical(sprite, _sprite)) return;
    await sprite.setImage(image);
  }

  void update(double dt) {
    _sprite?.update(dt);
  }

  void playIdle() {
    _sprite?.playIdle();
  }

  void playWalkToward({required Vector2 from, required Vector2 to}) {
    _sprite?.playWalkToward(from: from, to: to);
  }

  void playAttack() {
    _sprite?.playAttack();
  }

  void playAttackToward({required Vector2 from, required Vector2 to}) {
    _sprite?.playAttackToward(from: from, to: to);
  }

  void playWork() {
    _sprite?.playWork();
  }

  void playDie() {
    _sprite?.playDie();
  }
}
