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

    controller.nextSection(targets);

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

  test('can jump directly to the bottom action toolbar', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      hudGamepadFocusControllerProvider.notifier,
    );
    final targets = [
      _target(HudGamepadFocusSection.globalActions, 'global.options'),
      _target(HudGamepadFocusSection.menu, HudGamepadFocusTargetIds.menuReturn),
      _target(
        HudGamepadFocusSection.selectionActions,
        HudGamepadFocusTargetIds.bottomCommand,
      ),
    ];

    controller.focusSection(
      targets,
      HudGamepadFocusSection.selectionActions,
      fallbackSection: HudGamepadFocusSection.menu,
    );

    final state = container.read(hudGamepadFocusControllerProvider);
    expect(state.active, isTrue);
    expect(state.section, HudGamepadFocusSection.selectionActions);
    expect(state.targetId, HudGamepadFocusTargetIds.bottomCommand);
  });

  test('bottom action toolbar jump falls back to the menu', () {
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

    controller.focusSection(
      targets,
      HudGamepadFocusSection.selectionActions,
      fallbackSection: HudGamepadFocusSection.menu,
    );

    final state = container.read(hudGamepadFocusControllerProvider);
    expect(state.active, isTrue);
    expect(state.section, HudGamepadFocusSection.menu);
    expect(state.targetId, HudGamepadFocusTargetIds.menuReturn);
  });

  test('optimistic bottom action toolbar jump resolves after target sync', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      hudGamepadFocusControllerProvider.notifier,
    );
    final menuTargets = [
      _target(HudGamepadFocusSection.menu, HudGamepadFocusTargetIds.menuReturn),
    ];

    controller.focusSection(
      menuTargets,
      HudGamepadFocusSection.selectionActions,
      fallbackSection: HudGamepadFocusSection.menu,
      optimistic: true,
    );

    var state = container.read(hudGamepadFocusControllerProvider);
    expect(state.active, isTrue);
    expect(state.section, HudGamepadFocusSection.selectionActions);
    expect(state.targetId, isNull);

    controller.syncTargets([
      ...menuTargets,
      _target(
        HudGamepadFocusSection.selectionActions,
        HudGamepadFocusTargetIds.bottomCommand,
      ),
    ], enabled: true);

    state = container.read(hudGamepadFocusControllerProvider);
    expect(state.active, isTrue);
    expect(state.section, HudGamepadFocusSection.selectionActions);
    expect(state.targetId, HudGamepadFocusTargetIds.bottomCommand);
  });

  test('moves spatially through the HUD layout with map directions', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      hudGamepadFocusControllerProvider.notifier,
    );
    final targets = [
      _target(HudGamepadFocusSection.globalActions, 'global.options'),
      _target(HudGamepadFocusSection.globalActions, 'global.research'),
      _target(HudGamepadFocusSection.menu, HudGamepadFocusTargetIds.menuReturn),
      _target(HudGamepadFocusSection.topResources, 'resource.gold'),
      _target(HudGamepadFocusSection.topResources, 'resource.science'),
      _target(HudGamepadFocusSection.rightPlayers, 'players.player_1'),
      _target(HudGamepadFocusSection.rightPlayers, 'players.player_2'),
      _target(HudGamepadFocusSection.selectionActions, 'selection.move'),
      _target(
        HudGamepadFocusSection.selectionActions,
        HudGamepadFocusTargetIds.bottomCommand,
      ),
    ];

    controller
      ..nextSection(targets)
      ..move(GamepadMapDirection.right, targets);

    expect(
      container.read(hudGamepadFocusControllerProvider).section,
      HudGamepadFocusSection.topResources,
    );

    controller.move(GamepadMapDirection.down, targets);

    expect(
      container.read(hudGamepadFocusControllerProvider).section,
      HudGamepadFocusSection.rightPlayers,
    );

    controller.move(GamepadMapDirection.down, targets);

    expect(
      container.read(hudGamepadFocusControllerProvider).targetId,
      'players.player_2',
    );

    controller.move(GamepadMapDirection.down, targets);
    expect(
      container.read(hudGamepadFocusControllerProvider).section,
      HudGamepadFocusSection.selectionActions,
    );

    expect(
      container.read(hudGamepadFocusControllerProvider).targetId,
      'selection.move',
    );

    controller.move(GamepadMapDirection.down, targets);
    expect(
      container.read(hudGamepadFocusControllerProvider).targetId,
      HudGamepadFocusTargetIds.bottomCommand,
    );
  });

  test('moves up from the left HUD rail to the menu button', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      hudGamepadFocusControllerProvider.notifier,
    );
    final targets = [
      _target(HudGamepadFocusSection.globalActions, 'global.options'),
      _target(HudGamepadFocusSection.globalActions, 'global.research'),
      _target(HudGamepadFocusSection.menu, HudGamepadFocusTargetIds.menuReturn),
    ];

    controller
      ..focusSection(targets, HudGamepadFocusSection.globalActions)
      ..move(GamepadMapDirection.up, targets);

    expect(
      container.read(hudGamepadFocusControllerProvider).targetId,
      HudGamepadFocusTargetIds.menuReturn,
    );
  });

  test('moves back up from the command button to action chips', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      hudGamepadFocusControllerProvider.notifier,
    );
    final targets = [
      _target(HudGamepadFocusSection.selectionActions, 'selection.move'),
      _target(HudGamepadFocusSection.selectionActions, 'selection.attack'),
      _target(
        HudGamepadFocusSection.selectionActions,
        HudGamepadFocusTargetIds.bottomCommand,
      ),
    ];

    controller
      ..focusSection(targets, HudGamepadFocusSection.selectionActions)
      ..move(GamepadMapDirection.down, targets)
      ..move(GamepadMapDirection.up, targets);

    expect(
      container.read(hudGamepadFocusControllerProvider).targetId,
      'selection.move',
    );
  });

  test('registry refreshes callbacks when activation key changes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final registry = container.read(
      hudGamepadFocusTargetRegistryProvider.notifier,
    );
    final activations = <String>[];

    registry
      ..setSource('source', [
        _target(
          HudGamepadFocusSection.rightPlayers,
          'players.player_1',
          activationKey: 'player_1',
          onActivate: () => activations.add('player_1'),
        ),
      ])
      ..setSource('source', [
        _target(
          HudGamepadFocusSection.rightPlayers,
          'players.player_1',
          activationKey: 'player_2',
          onActivate: () => activations.add('player_2'),
        ),
      ]);

    final targets = HudGamepadFocusTargetRegistry.flatten(
      container.read(hudGamepadFocusTargetRegistryProvider),
    );
    targets.single.onActivate();

    expect(activations, ['player_2']);
  });

  test('popup capture remains active until every source releases', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    void setCaptured(String sourceId, bool captured) {
      container
          .read(hudGamepadPopupInputCaptureProvider.notifier)
          .setSourceCaptured(sourceId, captured);
    }

    setCaptured('playersSheet', true);
    setCaptured('diplomacyPopup', true);
    setCaptured('playersSheet', false);

    expect(container.read(hudGamepadPopupInputCaptureProvider), isTrue);

    setCaptured('diplomacyPopup', false);

    expect(container.read(hudGamepadPopupInputCaptureProvider), isFalse);
  });
}

HudGamepadFocusTarget _target(
  HudGamepadFocusSection section,
  String id, {
  Object? activationKey,
  void Function()? onActivate,
}) {
  return HudGamepadFocusTarget(
    section: section,
    id: id,
    label: id,
    onActivate: onActivate ?? () {},
    activationKey: activationKey,
  );
}
