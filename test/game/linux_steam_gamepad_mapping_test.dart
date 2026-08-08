import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

void main() {
  group('Linux Steam controller mappings', () {
    test('normalizes the Steam Deck A button', () {
      final normalizer = GamepadNormalizer.forPlatform(GamepadPlatform.linux);

      final normalized = normalizer.normalize(
        GamepadEvent(
          gamepadId: '/dev/input/js0',
          timestamp: 1,
          type: KeyType.button,
          key: '3',
          value: 1,
          vendorId: 0x28de,
          productId: 0x1205,
        ),
      );

      expect(normalized, hasLength(1));
      expect(normalized.single.button, GamepadButton.a);
      expect(normalized.single.value, 1);
    });

    test('normalizes the Steam Virtual Gamepad A button', () {
      final normalizer = GamepadNormalizer.forPlatform(GamepadPlatform.linux);

      final normalized = normalizer.normalize(
        GamepadEvent(
          gamepadId: '/dev/input/js1',
          timestamp: 1,
          type: KeyType.button,
          key: '0',
          value: 1,
          vendorId: 0x28de,
          productId: 0x11ff,
        ),
      );

      expect(normalized, hasLength(1));
      expect(normalized.single.button, GamepadButton.a);
      expect(normalized.single.value, 1);
    });
  });
}
