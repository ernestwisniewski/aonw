import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('game toast rises from the bottom in game palette', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => GameToast.show(
                  context,
                  message: 'Match code copied.',
                  tone: GameToastTone.success,
                ),
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.fixed);
    expect(snackBar.backgroundColor, Colors.transparent);
    expect(snackBar.elevation, 0);
    expect(snackBar.width, isNull);
    expect(snackBar.margin, isNull);

    expect(find.text('Match code copied.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);

    final toastRect = tester.getRect(
      find.byKey(const Key('gameToast.surface')),
    );
    expect(toastRect.bottom, greaterThan(520));

    final accent = tester.widget<DecoratedBox>(
      find.byKey(const Key('gameToast.accent')),
    );
    final decoration = accent.decoration as BoxDecoration;
    final gradient = decoration.gradient as LinearGradient;
    expect(gradient.colors.first, GameUiTheme.success.withAlpha(245));
  });
}
