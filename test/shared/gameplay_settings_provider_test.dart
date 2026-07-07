import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('keeps unit movement camera follow disabled by default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(gameplaySettingsProvider).followUnitMovementCamera,
      isFalse,
    );
  });

  test('keeps cinematic camera disabled by default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(gameplaySettingsProvider).cinematicCameraEnabled,
      isFalse,
    );
  });

  test('keeps enemy unit camera follow disabled by default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(gameplaySettingsProvider).followEnemyUnitCamera,
      isFalse,
    );
  });

  test('keeps gamepad input enabled with default tuning', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final gamepad = container.read(gameplaySettingsProvider).gamepad;

    expect(gamepad.enabled, isTrue);
    expect(gamepad.deadzone, 0.24);
    expect(gamepad.cameraSensitivity, 1);
    expect(gamepad.invertCameraY, isFalse);
  });

  test('persists unit movement camera follow preference', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(gameplaySettingsProvider.notifier)
        .setFollowUnitMovementCamera(true);

    expect(
      container.read(gameplaySettingsProvider).followUnitMovementCamera,
      isTrue,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('gameplay.follow_unit_movement_camera'), isTrue);
  });

  test('persists cinematic camera preference', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(gameplaySettingsProvider.notifier)
        .setCinematicCameraEnabled(true);

    expect(
      container.read(gameplaySettingsProvider).cinematicCameraEnabled,
      isTrue,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('gameplay.cinematic_camera_enabled'), isTrue);
  });

  test('persists enemy unit camera follow preference', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(gameplaySettingsProvider.notifier)
        .setFollowEnemyUnitCamera(true);

    expect(
      container.read(gameplaySettingsProvider).followEnemyUnitCamera,
      isTrue,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('gameplay.follow_enemy_unit_camera'), isTrue);
  });

  test('persists gamepad preferences', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(gameplaySettingsProvider.notifier)
      ..setGamepadEnabled(false)
      ..setGamepadDeadzone(0.31)
      ..setGamepadCameraSensitivity(0.75)
      ..setGamepadInvertCameraY(true)
      ..setGamepadButtonBinding(GamepadButtonAction.confirm, GamepadButton.y)
      ..setGamepadAxisBinding(
        GamepadAxisAction.cameraX,
        GamepadAxis.leftStickX,
      );

    final gamepad = container.read(gameplaySettingsProvider).gamepad;
    expect(gamepad.enabled, isFalse);
    expect(gamepad.deadzone, 0.31);
    expect(gamepad.cameraSensitivity, 0.75);
    expect(gamepad.invertCameraY, isTrue);
    expect(
      gamepad.buttonBindings.primaryButtonFor(GamepadButtonAction.confirm),
      GamepadButton.y,
    );
    expect(
      gamepad.axisBindings.axisFor(GamepadAxisAction.cameraX),
      GamepadAxis.leftStickX,
    );

    await Future<void>.delayed(const Duration(milliseconds: 1));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('gameplay.gamepad.enabled'), isFalse);
    expect(prefs.getDouble('gameplay.gamepad.deadzone'), 0.31);
    expect(prefs.getDouble('gameplay.gamepad.camera_sensitivity'), 0.75);
    expect(prefs.getBool('gameplay.gamepad.invert_camera_y'), isTrue);
    expect(prefs.getString('gameplay.gamepad.button_bindings'), isNotNull);
    expect(prefs.getString('gameplay.gamepad.axis_bindings'), isNotNull);
  });

  test(
    'falls back to default gamepad bindings after invalid storage',
    () async {
      SharedPreferences.setMockInitialValues({
        'gameplay.gamepad.button_bindings': '{',
        'gameplay.gamepad.axis_bindings': '{',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);

      final gamepad = container.read(gameplaySettingsProvider).gamepad;
      expect(
        gamepad.buttonBindings.primaryButtonFor(GamepadButtonAction.confirm),
        GamepadButton.a,
      );
      expect(
        gamepad.axisBindings.axisFor(GamepadAxisAction.cameraY),
        GamepadAxis.rightStickY,
      );
    },
  );
}
