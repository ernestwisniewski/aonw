import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/menu/credits_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Age of New Worlds',
      packageName: 'net.aonw',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('credits screen links to the devlog', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: _LocalizedHarness(child: CreditsScreen())),
    );
    await tester.pump();

    expect(find.text('Devlog: ernest.dev'), findsOneWidget);
    expect(find.byKey(const Key('credits.devlogLink')), findsOneWidget);
  });
}

class _LocalizedHarness extends StatelessWidget {
  const _LocalizedHarness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}
