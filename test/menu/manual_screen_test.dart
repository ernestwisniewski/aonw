import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/menu/manual_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('manual screen separates desktop and mobile controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: '/manual',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/manual',
          builder: (context, state) => const ManualScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Controls manual'), findsOneWidget);
    expect(find.text('CORE COMMAND LOOP'), findsOneWidget);
    expect(find.byKey(const Key('manual.desktopSection')), findsOneWidget);
    expect(find.byKey(const Key('manual.mobileSection')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('manual.mobileSection'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('manual.desktopSection'))).dy,
      ),
    );
    expect(find.text('Left click'), findsOneWidget);
    expect(find.text('Tap'), findsOneWidget);
    expect(find.text('?'), findsWidgets);
  });

  testWidgets('manual screen puts mobile controls first on compact screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(480, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: '/manual',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/manual',
          builder: (context, state) => const ManualScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.byKey(const Key('manual.mobileSection'))).dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const Key('manual.commandLoopSection')))
            .dy,
      ),
    );
    expect(find.text('Tap'), findsOneWidget);
    expect(find.text('CORE COMMAND LOOP'), findsOneWidget);
  });
}
