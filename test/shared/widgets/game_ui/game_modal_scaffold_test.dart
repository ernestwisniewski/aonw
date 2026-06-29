import 'dart:async';

import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GameModalScaffold renders header, content and actions', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameModalScaffold(
            header: const GameModalHeader(title: 'Title', subtitle: 'Subtitle'),
            content: const Text('Body'),
            actions: [
              GameModalAction(label: 'Do it', onPressed: () => tapped = true),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Subtitle'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);

    await tester.tap(find.text('Do it'));
    expect(tapped, isTrue);
  });

  testWidgets('bottom sheet scaffold is readable on wide viewports', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameModalScaffold(
            surfaceKey: Key('bottomSheet.surface'),
            shape: GameModalShape.bottomSheet,
            centerInAvailableSpace: false,
            content: Text('Body'),
          ),
        ),
      ),
    );

    final surface = tester.getRect(
      find.byKey(const Key('bottomSheet.surface')),
    );

    expect(surface.width, lessThanOrEqualTo(680));
    expect(surface.center.dx, closeTo(800, 1));
  });

  testWidgets('showGameConfirmation returns true for confirm action', (
    tester,
  ) async {
    bool? confirmed;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                confirmed = await showGameConfirmation(
                  context: context,
                  title: 'Delete?',
                  message: 'This cannot be undone.',
                  confirmLabel: 'Delete',
                  tone: GameConfirmationTone.danger,
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });

  testWidgets('game modals keep the map backdrop undimmed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                unawaited(
                  showGameModal<void>(
                    context: context,
                    builder: (_) =>
                        const GameModalScaffold(content: Text('Modal content')),
                  ),
                );
              },
              child: const Text('Open modal'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open modal'));
    await tester.pumpAndSettle();

    expect(find.text('Modal content'), findsOneWidget);
    expect(_modalBarrierColors(tester), everyElement(_transparentBarrierColor));
  });

  testWidgets('game bottom sheets keep the map backdrop undimmed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                unawaited(
                  showGameBottomSheet<void>(
                    context: context,
                    builder: (_) => const GameModalScaffold(
                      shape: GameModalShape.bottomSheet,
                      content: Text('Sheet content'),
                    ),
                  ),
                );
              },
              child: const Text('Open sheet'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Sheet content'), findsOneWidget);
    expect(_modalBarrierColors(tester), everyElement(_transparentBarrierColor));
  });
}

final Matcher _transparentBarrierColor = anyOf(isNull, Colors.transparent);

List<Color?> _modalBarrierColors(WidgetTester tester) {
  return [
    for (final widget in tester.allWidgets)
      if (widget is ModalBarrier)
        widget.color
      else if (widget is AnimatedModalBarrier)
        widget.color.value,
  ];
}
