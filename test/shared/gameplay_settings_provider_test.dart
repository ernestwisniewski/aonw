import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
