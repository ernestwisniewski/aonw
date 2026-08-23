import 'package:aonw_flutter/features/map/infrastructure/gamepad_map_input_source.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

void main() {
  test('maps pressed standard gamepad buttons to map input commands', () {
    expect(
      MapGamepadMapper.commandFor(GamepadButton.dpadUp, 1),
      MapInputCommand.cursorUp,
    );
    expect(
      MapGamepadMapper.commandFor(GamepadButton.a, 1),
      MapInputCommand.activate,
    );
    expect(
      MapGamepadMapper.commandFor(GamepadButton.b, 1),
      MapInputCommand.cancel,
    );
    expect(
      MapGamepadMapper.commandFor(GamepadButton.y, 1),
      MapInputCommand.toggleReference,
    );
  });

  test('ignores releases and unrelated buttons', () {
    expect(MapGamepadMapper.commandFor(GamepadButton.a, 0), isNull);
    expect(MapGamepadMapper.commandFor(GamepadButton.leftBumper, 1), isNull);
    expect(MapGamepadMapper.commandFor(null, 1), isNull);
  });
}
