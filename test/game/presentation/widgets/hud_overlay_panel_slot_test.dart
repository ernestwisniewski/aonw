import 'package:aonw/game/presentation/widgets/hud/overlay/hud_overlay_panel_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HudOverlayPanelSlot passes padded max height to builder', (
    tester,
  ) async {
    double? maxHeight;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: HudOverlayPanelSlot(
              padding: const EdgeInsets.fromLTRB(12, 20, 30, 50),
              builder: (context, height) {
                maxHeight = height;
                return const SizedBox(
                  key: Key('panel.child'),
                  width: 80,
                  height: 40,
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(maxHeight, 330);
    expect(find.byKey(const Key('panel.child')), findsOneWidget);
  });

  testWidgets('HudOverlayPanelSlot honors alignment', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: HudOverlayPanelSlot(
              padding: EdgeInsets.zero,
              alignment: Alignment.bottomRight,
              builder: (context, height) => const SizedBox(
                key: Key('panel.child'),
                width: 40,
                height: 40,
              ),
            ),
          ),
        ),
      ),
    );

    final childRect = tester.getRect(find.byKey(const Key('panel.child')));
    expect(childRect.right, 300);
    expect(childRect.bottom, 300);
  });

  testWidgets('HudOverlayPanelSlot fills width from the bottom on phones', (
    tester,
  ) async {
    await _pumpSlot(
      tester,
      screenSize: const Size(360, 780),
      padding: const EdgeInsets.fromLTRB(12, 132, 12, 82),
      childSize: const Size(80, 40),
    );

    final childRect = tester.getRect(find.byKey(const Key('panel.child')));
    expect(
      find.byKey(const Key('hudOverlayPanelSlot.mobileSheet')),
      findsOneWidget,
    );
    expect(childRect.left, 12);
    expect(childRect.width, 336);
    expect(childRect.bottom, 698);
  });

  testWidgets('HudOverlayPanelSlot uses sheet width on medium portrait', (
    tester,
  ) async {
    await _pumpSlot(
      tester,
      screenSize: const Size(840, 1180),
      padding: const EdgeInsets.fromLTRB(12, 132, 12, 82),
      childSize: const Size(80, 40),
    );

    final childRect = tester.getRect(find.byKey(const Key('panel.child')));
    expect(
      find.byKey(const Key('hudOverlayPanelSlot.mobileSheet')),
      findsOneWidget,
    );
    expect(childRect.left, 12);
    expect(childRect.width, 816);
    expect(childRect.bottom, 1098);
  });

  testWidgets('HudOverlayPanelSlot keeps top alignment in landscape', (
    tester,
  ) async {
    await _pumpSlot(
      tester,
      screenSize: const Size(678, 360),
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 82),
      childSize: const Size(80, 40),
    );

    final childRect = tester.getRect(find.byKey(const Key('panel.child')));
    expect(
      find.byKey(const Key('hudOverlayPanelSlot.mobileSheet')),
      findsNothing,
    );
    expect(childRect.top, 20);
    expect(childRect.center.dx, 339);
    expect(childRect.width, 80);
  });
}

Future<void> _pumpSlot(
  WidgetTester tester, {
  required Size screenSize,
  required EdgeInsets padding,
  required Size childSize,
}) async {
  tester.view.physicalSize = screenSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HudOverlayPanelSlot(
          padding: padding,
          builder: (context, height) => SizedBox(
            key: const Key('panel.child'),
            width: childSize.width,
            height: childSize.height,
          ),
        ),
      ),
    ),
  );
}
