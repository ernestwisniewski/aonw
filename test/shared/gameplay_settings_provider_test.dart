import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('uses backward-compatible camera movement defaults', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final settings = container.read(gameplaySettingsProvider);
    expect(settings.focusOwnUnitMovementCamera, isTrue);
    expect(settings.followOwnUnitMovementCamera, isFalse);
    expect(settings.focusEnemyUnitMovementCamera, isFalse);
    expect(settings.followEnemyUnitMovementCamera, isFalse);
  });

  test('keeps cinematic camera disabled by default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(gameplaySettingsProvider).cinematicCameraEnabled,
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

  test('persists the four independent camera movement preferences', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(gameplaySettingsProvider.notifier)
      ..setFocusOwnUnitMovementCamera(false)
      ..setFollowOwnUnitMovementCamera(true)
      ..setFocusEnemyUnitMovementCamera(true)
      ..setFollowEnemyUnitMovementCamera(true);

    final settings = container.read(gameplaySettingsProvider);
    expect(settings.focusOwnUnitMovementCamera, isFalse);
    expect(settings.followOwnUnitMovementCamera, isTrue);
    expect(settings.focusEnemyUnitMovementCamera, isTrue);
    expect(settings.followEnemyUnitMovementCamera, isTrue);

    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('gameplay.focus_own_unit_movement_camera'), isFalse);
    expect(prefs.getBool('gameplay.follow_unit_movement_camera'), isTrue);
    expect(prefs.getBool('gameplay.follow_enemy_unit_camera'), isTrue);
    expect(prefs.getBool('gameplay.follow_enemy_unit_movement_camera'), isTrue);
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

  test(
    'migrates the legacy camera settings without changing behavior',
    () async {
      SharedPreferences.setMockInitialValues({
        'gameplay.follow_unit_movement_camera': true,
        'gameplay.follow_enemy_unit_camera': true,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(gameplaySettingsProvider.notifier).ensureLoaded();

      final settings = container.read(gameplaySettingsProvider);
      expect(settings.focusOwnUnitMovementCamera, isTrue);
      expect(settings.followOwnUnitMovementCamera, isTrue);
      expect(settings.focusEnemyUnitMovementCamera, isTrue);
      expect(settings.followEnemyUnitMovementCamera, isTrue);
    },
  );

  test('persists automation and preferred map view settings', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(gameplaySettingsProvider.notifier)
      ..setAutoActionFlowEnabled(false)
      ..setAutoTurnFlowEnabled(true)
      ..setPreferredMapViewMode(MapViewMode.tile);

    final settings = container.read(gameplaySettingsProvider);
    expect(settings.autoActionFlowEnabled, isFalse);
    expect(settings.autoTurnFlowEnabled, isTrue);
    expect(settings.preferredMapViewMode, MapViewMode.tile);

    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('gameplay.auto_action_flow_enabled'), isFalse);
    expect(prefs.getBool('gameplay.auto_turn_flow_enabled'), isTrue);
    expect(prefs.getString('gameplay.preferred_map_view_mode'), 'tile');
  });

  test(
    'loads automation and preferred map view before session creation',
    () async {
      SharedPreferences.setMockInitialValues({
        'gameplay.auto_action_flow_enabled': false,
        'gameplay.auto_turn_flow_enabled': true,
        'gameplay.preferred_map_view_mode': 'tile',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(gameplaySettingsProvider.notifier).ensureLoaded();

      final settings = container.read(gameplaySettingsProvider);
      expect(settings.autoActionFlowEnabled, isFalse);
      expect(settings.autoTurnFlowEnabled, isTrue);
      expect(settings.preferredMapViewMode, MapViewMode.tile);
    },
  );

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

  test('clamps gamepad tuning to supported upper ranges', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(gameplaySettingsProvider.notifier)
      ..setGamepadDeadzone(0.9)
      ..setGamepadCameraSensitivity(2.4);

    final gamepad = container.read(gameplaySettingsProvider).gamepad;
    expect(gamepad.deadzone, 0.6);
    expect(gamepad.cameraSensitivity, 2);
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
