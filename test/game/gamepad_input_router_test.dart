import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GamepadInputRouterScope', () {
    testWidgets('dispatches button edges to the highest priority route', (
      tester,
    ) async {
      final input = ValueNotifier<GamepadInputSnapshot>(
        GamepadInputSnapshot.empty,
      );
      addTearDown(input.dispose);
      var panelConfirmCount = 0;
      var modalConfirmCount = 0;

      await tester.pumpWidget(
        GamepadInputRouterScope(
          input: input,
          child: Column(
            children: [
              GamepadPanelInputListener(
                input: input,
                onConfirm: () => panelConfirmCount += 1,
                child: const SizedBox.shrink(),
              ),
              GamepadPanelInputListener(
                input: input,
                priority: GamepadInputRoutePriority.modal,
                onConfirm: () => modalConfirmCount += 1,
                child: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );

      input.value = const GamepadInputSnapshot(confirm: true);
      await tester.pump(const Duration(milliseconds: 16));

      expect(panelConfirmCount, 0);
      expect(modalConfirmCount, 1);
    });

    testWidgets('primes held input when the scope mounts', (tester) async {
      final input = ValueNotifier<GamepadInputSnapshot>(
        const GamepadInputSnapshot(confirm: true),
      );
      addTearDown(input.dispose);
      var confirmCount = 0;

      await tester.pumpWidget(
        GamepadInputRouterScope(
          input: input,
          child: GamepadPanelInputListener(
            input: input,
            onConfirm: () => confirmCount += 1,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(confirmCount, 0);

      input.value = GamepadInputSnapshot.empty;
      await tester.pump(const Duration(milliseconds: 16));
      input.value = const GamepadInputSnapshot(confirm: true);
      await tester.pump(const Duration(milliseconds: 16));

      expect(confirmCount, 1);
    });

    testWidgets('primes held input when a route registers later', (
      tester,
    ) async {
      final input = ValueNotifier<GamepadInputSnapshot>(
        GamepadInputSnapshot.empty,
      );
      addTearDown(input.dispose);
      var confirmCount = 0;
      var routeVisible = false;
      StateSetter? setHarnessState;

      await tester.pumpWidget(
        GamepadInputRouterScope(
          input: input,
          child: StatefulBuilder(
            builder: (context, setState) {
              setHarnessState = setState;
              return routeVisible
                  ? GamepadPanelInputListener(
                      input: input,
                      onConfirm: () => confirmCount += 1,
                      child: const SizedBox.shrink(),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ),
      );

      input.value = const GamepadInputSnapshot(confirm: true);
      await tester.pump(const Duration(milliseconds: 16));
      setHarnessState!(() => routeVisible = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(confirmCount, 0);

      input.value = GamepadInputSnapshot.empty;
      await tester.pump(const Duration(milliseconds: 16));
      input.value = const GamepadInputSnapshot(confirm: true);
      await tester.pump(const Duration(milliseconds: 16));

      expect(confirmCount, 1);
    });

    testWidgets('keeps HUD hotkeys active alongside the renderer frame route', (
      tester,
    ) async {
      final input = ValueNotifier<GamepadInputSnapshot>(
        GamepadInputSnapshot.empty,
      );
      addTearDown(input.dispose);
      var frameCount = 0;
      var hudNextCount = 0;

      await tester.pumpWidget(
        GamepadInputRouterScope(
          input: input,
          child: GamepadInputRouteListener(
            route: GamepadInputRoute(
              priority: GamepadInputRoutePriority.renderer,
              onFrame: (_, _) => frameCount += 1,
            ),
            child: GamepadPanelInputListener(
              input: input,
              priority: GamepadInputRoutePriority.hud,
              onHudFocusNext: () => hudNextCount += 1,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      input.value = const GamepadInputSnapshot(hudFocusNext: true);
      await tester.pump(const Duration(milliseconds: 16));

      expect(frameCount, 1);
      expect(hudNextCount, 1);
    });
  });
}
