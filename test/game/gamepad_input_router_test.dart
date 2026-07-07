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

    testWidgets('panel routes arbitrate discrete renderer actions', (
      tester,
    ) async {
      final input = ValueNotifier<GamepadInputSnapshot>(
        GamepadInputSnapshot.empty,
      );
      addTearDown(input.dispose);
      var rendererFrameCount = 0;
      var rendererNavigateCount = 0;
      var rendererConfirmCount = 0;
      var panelNavigateCount = 0;
      var panelConfirmCount = 0;

      await tester.pumpWidget(
        GamepadInputRouterScope(
          input: input,
          child: GamepadInputRouteListener(
            route: GamepadInputRoute(
              priority: GamepadInputRoutePriority.renderer,
              onFrame: (_, _) => rendererFrameCount += 1,
              onNavigate: (_) => rendererNavigateCount += 1,
              onConfirm: () => rendererConfirmCount += 1,
            ),
            child: GamepadPanelInputListener(
              input: input,
              onNavigate: (_) => panelNavigateCount += 1,
              onConfirm: () => panelConfirmCount += 1,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      input.value = const GamepadInputSnapshot(
        cameraX: 0.8,
        dpadRight: true,
        confirm: true,
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(rendererFrameCount, 1);
      expect(rendererNavigateCount, 0);
      expect(rendererConfirmCount, 0);
      expect(panelNavigateCount, 1);
      expect(panelConfirmCount, 1);
    });

    testWidgets('scrollable panels consume unhandled map actions', (
      tester,
    ) async {
      final input = ValueNotifier<GamepadInputSnapshot>(
        GamepadInputSnapshot.empty,
      );
      addTearDown(input.dispose);
      var rendererNavigateCount = 0;
      var rendererConfirmCount = 0;
      var rendererCancelCount = 0;
      var rendererModeCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GamepadInputRouterScope(
            input: input,
            child: GamepadInputRouteListener(
              route: GamepadInputRoute(
                priority: GamepadInputRoutePriority.renderer,
                onNavigate: (_) => rendererNavigateCount += 1,
                onConfirm: () => rendererConfirmCount += 1,
                onCancel: () => rendererCancelCount += 1,
                onMode: () => rendererModeCount += 1,
              ),
              child: SizedBox(
                width: 200,
                height: 200,
                child: GamepadScrollable(
                  input: input,
                  child: const SizedBox(height: 600),
                ),
              ),
            ),
          ),
        ),
      );

      input.value = const GamepadInputSnapshot(
        dpadDown: true,
        confirm: true,
        cancel: true,
        moveMode: true,
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(rendererNavigateCount, 0);
      expect(rendererConfirmCount, 0);
      expect(rendererCancelCount, 0);
      expect(rendererModeCount, 0);
    });
  });
}
