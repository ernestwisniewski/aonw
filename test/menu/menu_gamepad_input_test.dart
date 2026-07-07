import 'dart:async';

import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/menu/menu_gamepad_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navigates and activates focused menu actions', (tester) async {
    final input = ValueNotifier<GamepadInputSnapshot>(
      GamepadInputSnapshot.empty,
    );
    addTearDown(input.dispose);
    var firstActivations = 0;
    var secondActivations = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MenuGamepadInputBinding(
            input: input,
            child: Column(
              children: [
                MenuGamepadAction(
                  onActivate: () => firstActivations++,
                  builder: (context, focused) =>
                      Text(focused ? 'First focused' : 'First'),
                ),
                MenuGamepadAction(
                  onActivate: () => secondActivations++,
                  builder: (context, focused) =>
                      Text(focused ? 'Second focused' : 'Second'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await _pressGamepad(
      tester,
      input,
      const GamepadInputSnapshot(dpadDown: true),
    );
    await _pressGamepad(
      tester,
      input,
      const GamepadInputSnapshot(confirm: true),
    );
    await _pressGamepad(
      tester,
      input,
      const GamepadInputSnapshot(dpadUp: true),
    );
    await _pressGamepad(
      tester,
      input,
      const GamepadInputSnapshot(confirm: true),
    );
    expect(firstActivations, 1);
    expect(secondActivations, 1);
  });

  testWidgets('shows menu focus only while navigating with gamepad', (
    tester,
  ) async {
    final input = ValueNotifier<GamepadInputSnapshot>(
      GamepadInputSnapshot.empty,
    );
    addTearDown(input.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MenuGamepadInputBinding(
            input: input,
            child: Column(
              children: [
                MenuGamepadAction(
                  key: const Key('firstAction'),
                  onActivate: () {},
                  builder: (context, focused) =>
                      Text(focused ? 'First focused' : 'First'),
                ),
                MenuGamepadAction(
                  key: const Key('secondAction'),
                  onActivate: () {},
                  builder: (context, focused) =>
                      Text(focused ? 'Second focused' : 'Second'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('First focused'), findsNothing);
    expect(find.text('Second focused'), findsNothing);

    await tester.tap(find.byKey(const Key('firstAction')));
    await tester.pump();

    expect(find.text('First focused'), findsNothing);
    expect(find.text('Second focused'), findsNothing);

    await _pressGamepad(
      tester,
      input,
      const GamepadInputSnapshot(dpadDown: true),
    );

    expect(_focusedMenuLabels(), findsOneWidget);

    await tester.tap(find.byKey(const Key('firstAction')));
    await tester.pump();

    expect(find.text('First focused'), findsNothing);
    expect(find.text('Second focused'), findsNothing);
  });

  testWidgets('cancel closes popup routes before invoking route cancel', (
    tester,
  ) async {
    final input = ValueNotifier<GamepadInputSnapshot>(
      GamepadInputSnapshot.empty,
    );
    addTearDown(input.dispose);
    var cancelCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MenuGamepadInputBinding(
            input: input,
            onCancel: () => cancelCount++,
            child: Builder(
              builder: (context) {
                void openPopup() {
                  unawaited(
                    showDialog<void>(
                      context: context,
                      builder: (context) =>
                          const AlertDialog(content: Text('Popup content')),
                    ),
                  );
                }

                return MenuGamepadAction(
                  onActivate: openPopup,
                  builder: (context, focused) => GestureDetector(
                    onTap: openPopup,
                    child: const Text('Open popup'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open popup'));
    await tester.pumpAndSettle();
    expect(find.text('Popup content'), findsOneWidget);

    await _pressGamepad(
      tester,
      input,
      const GamepadInputSnapshot(cancel: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('Popup content'), findsNothing);
    expect(cancelCount, 0);

    await _pressGamepad(
      tester,
      input,
      const GamepadInputSnapshot(cancel: true),
    );
    expect(cancelCount, 1);
  });
}

Finder _focusedMenuLabels() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        (widget.data == 'First focused' || widget.data == 'Second focused'),
  );
}

Future<void> _pressGamepad(
  WidgetTester tester,
  ValueNotifier<GamepadInputSnapshot> input,
  GamepadInputSnapshot snapshot,
) async {
  input.value = snapshot;
  await tester.pump(const Duration(milliseconds: 16));
  input.value = GamepadInputSnapshot.empty;
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 180));
}
