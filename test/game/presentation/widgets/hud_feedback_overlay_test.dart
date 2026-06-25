import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/providers/hud_feedback_provider.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_feedback_overlay.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders and dismisses local HUD feedback', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: HudFeedbackOverlay()),
        ),
      ),
    );

    expect(find.text('No exploration route'), findsNothing);

    container
        .read(hudFeedbackProvider.notifier)
        .show(HudFeedbackMessages.autoExploreNoTarget);
    await tester.pump();

    expect(find.text('No exploration route'), findsOneWidget);
    expect(find.text('Action did not consume the turn'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('No exploration route'), findsNothing);
    expect(container.read(hudFeedbackProvider), isEmpty);
  });

  testWidgets('renders artifact guidance feedback copy', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: HudFeedbackOverlay()),
        ),
      ),
    );

    container
        .read(hudFeedbackProvider.notifier)
        .show(
          const HudFeedbackContent(
            kind: HudFeedbackKind.artifactGuidance,
            title: 'Artifact discovered',
            body: 'Uzyj akcji Excavatealiska.',
          ),
        );
    await tester.pump();

    expect(find.text('Artifact discovered'), findsOneWidget);
    expect(find.text('Uzyj akcji Excavatealiska.'), findsOneWidget);
  });

  testWidgets('localizes movement blocked feedback reasons', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: HudFeedbackOverlay()),
        ),
      ),
    );

    container
        .read(hudFeedbackProvider.notifier)
        .show(
          const HudFeedbackContent(
            kind: HudFeedbackKind.actionBlocked,
            reason: HudFeedbackReason.movementEnemyOccupied,
            title: '',
            body: '',
          ),
        );
    await tester.pump();

    expect(find.text('Enemy on this tile'), findsOneWidget);
    expect(
      find.text(
        'You cannot enter an enemy tile with a normal move. '
        'Use Attack or choose an adjacent tile.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('localizes treaty protected attack feedback', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: HudFeedbackOverlay()),
        ),
      ),
    );

    container
        .read(hudFeedbackProvider.notifier)
        .show(
          const HudFeedbackContent(
            kind: HudFeedbackKind.actionBlocked,
            reason: HudFeedbackReason.attackProtectedByTreaty,
            title: '',
            body: '',
          ),
        );
    await tester.pump();

    expect(find.text('Treaty blocks attack'), findsOneWidget);
    expect(
      find.text(
        'You cannot attack a unit from a civilization that has an alliance '
        'or a truce with you. Change diplomatic relations first.',
      ),
      findsOneWidget,
    );
  });
}
