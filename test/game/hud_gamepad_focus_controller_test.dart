import 'package:aonw/game/presentation/input/gamepad/gamepad_input_snapshot.dart';
import 'package:aonw/game/presentation/providers/hud/hud_gamepad_focus_controller_provider.dart';
import 'package:aonw/game/presentation/widgets/hud/gamepad/hud_gamepad_focus_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cycles through the full HUD interface sections', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      hudGamepadFocusControllerProvider.notifier,
    );
    final targets = [
      _target(HudGamepadFocusSection.menu, HudGamepadFocusTargetIds.menuReturn),
      _target(HudGamepadFocusSection.globalActions, 'global.options'),
      _target(HudGamepadFocusSection.topResources, 'resource.gold'),
      _target(HudGamepadFocusSection.rightPlayers, 'players.player_1'),
      _target(HudGamepadFocusSection.selectionActions, 'selection.move'),
    ];

    controller.toggle(targets);

    expect(
      container.read(hudGamepadFocusControllerProvider).section,
      HudGamepadFocusSection.menu,
    );

    controller.nextSection(targets);
    expect(
      container.read(hudGamepadFocusControllerProvider).section,
      HudGamepadFocusSection.topResources,
    );

    controller.nextSection(targets);
    expect(
      container.read(hudGamepadFocusControllerProvider).section,
      HudGamepadFocusSection.rightPlayers,
    );

    controller.nextSection(targets);
    expect(
      container.read(hudGamepadFocusControllerProvider).section,
      HudGamepadFocusSection.selectionActions,
    );

    controller.nextSection(targets);
    expect(
      container.read(hudGamepadFocusControllerProvider).section,
      HudGamepadFocusSection.globalActions,
    );

    controller.nextSection(targets);
    expect(
      container.read(hudGamepadFocusControllerProvider).section,
      HudGamepadFocusSection.menu,
    );

    controller.previousSection(targets);
    expect(
      container.read(hudGamepadFocusControllerProvider).section,
      HudGamepadFocusSection.globalActions,
    );
  });

  test('stick section focus enters the HUD at the menu', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      hudGamepadFocusControllerProvider.notifier,
    );
    final targets = [
      _target(HudGamepadFocusSection.globalActions, 'global.options'),
      _target(HudGamepadFocusSection.menu, HudGamepadFocusTargetIds.menuReturn),
      _target(HudGamepadFocusSection.topResources, 'resource.gold'),
    ];

    controller.nextSection(targets);
    expect(
      container.read(hudGamepadFocusControllerProvider).section,
      HudGamepadFocusSection.menu,
    );

    controller
      ..deactivate()
      ..previousSection(targets);
    expect(
      container.read(hudGamepadFocusControllerProvider).section,
      HudGamepadFocusSection.menu,
    );
  });

  test('moves vertically inside the right player rail', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      hudGamepadFocusControllerProvider.notifier,
    );
    final targets = [
      _target(HudGamepadFocusSection.rightPlayers, 'players.player_1'),
      _target(HudGamepadFocusSection.rightPlayers, 'players.player_2'),
      _target(HudGamepadFocusSection.selectionActions, 'selection.move'),
    ];

    controller
      ..toggle(targets)
      ..move(GamepadMapDirection.down, targets);

    expect(
      container.read(hudGamepadFocusControllerProvider).targetId,
      'players.player_2',
    );

    controller.move(GamepadMapDirection.right, targets);
    expect(
      container.read(hudGamepadFocusControllerProvider).section,
      HudGamepadFocusSection.selectionActions,
    );
  });
}

HudGamepadFocusTarget _target(HudGamepadFocusSection section, String id) {
  return HudGamepadFocusTarget(
    section: section,
    id: id,
    label: id,
    onActivate: () {},
  );
}
