import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw/shared/assets/sprite_frame_repository.dart';
import 'package:aonw/shared/assets/texture_packer_sprite_frame_repository.dart';

/// Process-scoped access to immutable generated sprite data.
///
/// The repository cannot be replaced at runtime. Tests that need a custom
/// bundle instantiate [TexturePackerSpriteFrameRepository] directly.
abstract final class SpriteFrames {
  static final SpriteFrameRepository _repository =
      TexturePackerSpriteFrameRepository();

  static SpriteFrame? cached(SpriteFrameId id) => _repository.cached(id);

  static Future<SpriteFrame> load(SpriteFrameId id) => _repository.load(id);

  static Future<void> preload(Iterable<SpriteFrameId> ids) =>
      _repository.preload(ids);
}
