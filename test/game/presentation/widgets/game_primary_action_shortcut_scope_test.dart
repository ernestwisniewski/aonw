import 'package:aonw/game/presentation/widgets/screen/game_primary_action_shortcut_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('space activates the primary game action once', (tester) async {
    var activations = 0;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: GamePrimaryActionShortcutScope(
          enabled: true,
          onActivate: () => activations++,
          child: Focus(
            focusNode: focusNode,
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);

    expect(activations, 1);
  });

  testWidgets('space is ignored when the scope is disabled', (tester) async {
    var activations = 0;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: GamePrimaryActionShortcutScope(
          enabled: false,
          onActivate: () => activations++,
          child: Focus(
            focusNode: focusNode,
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);

    expect(activations, 0);
  });
}
