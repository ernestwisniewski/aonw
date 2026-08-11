import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/multiplayer_session_gateway.dart';
import 'package:aonw/game/presentation/screens/lobby/multiplayer_account_dialog.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('offers Steam sign-in on web', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showMultiplayerAccountDialog(
              context: context,
              login: _login,
              createAccount: _createAccount,
              steamAuth: _steamLogin,
              initialDisplayName: 'Web player',
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('multiplayer.account.steam')), findsOneWidget);
  }, skip: !kIsWeb);

  testWidgets('uses brokered Google and Apple sign-in on web', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showMultiplayerAccountDialog(
              context: context,
              login: _login,
              createAccount: _createAccount,
              externalAuth: _externalLogin,
              steamAuth: _steamLogin,
              initialDisplayName: 'Web player',
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('multiplayer.account.google')), findsOneWidget);
    expect(find.byKey(const Key('multiplayer.account.apple')), findsOneWidget);
    expect(find.byKey(const Key('multiplayer.account.steam')), findsOneWidget);
  }, skip: !kIsWeb);
}

Future<NetworkAuthResult> _login({
  required String email,
  required String password,
}) async => _result;

Future<NetworkAuthResult> _createAccount({
  required String email,
  required String password,
  required String displayName,
}) async => _result;

Future<NetworkAuthResult> _steamLogin() async => _result;

Future<NetworkAuthResult> _externalLogin({required String provider}) async =>
    _result;

final _result = NetworkAuthResult(
  userId: 'web-user',
  token: AuthToken('token'),
  displayName: 'Web player',
);
