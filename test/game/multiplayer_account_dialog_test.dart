import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/game/presentation/screens/lobby/multiplayer_account_dialog.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders sign-in mode by default', (tester) async {
    await _pumpDialog(tester);

    expect(find.text('Multiplayer account'), findsOneWidget);
    expect(
      find.text('Sign in or create an account to continue.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('multiplayer.account.emailMethod')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('multiplayer.account.email')), findsNothing);
    expect(find.byKey(const Key('multiplayer.account.password')), findsNothing);
    expect(find.byKey(const Key('multiplayer.account.submit')), findsNothing);

    await _openEmailForm(tester);

    expect(find.text('Sign in'), findsNWidgets(2));
    expect(find.text('Create account'), findsOneWidget);
    expect(find.byKey(const Key('multiplayer.account.email')), findsOneWidget);
    expect(
      find.byKey(const Key('multiplayer.account.password')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('multiplayer.account.nickname')), findsNothing);
  });

  testWidgets('does not span the full desktop width', (tester) async {
    await _pumpDialog(tester);

    final dialogSize = tester.getSize(
      find.byKey(const Key('multiplayer.account.surface')),
    );

    expect(dialogSize.width, lessThan(900));
  });

  testWidgets('keeps auth method buttons compact', (tester) async {
    await _pumpDialog(tester);

    final dialogSize = tester.getSize(
      find.byKey(const Key('multiplayer.account.surface')),
    );
    final emailMethodSize = tester.getSize(
      find.byKey(const Key('multiplayer.account.emailMethod')),
    );

    expect(emailMethodSize.width, lessThan(dialogSize.width));
    expect(emailMethodSize.width, closeTo(300, 1));
  });

  testWidgets('shows Steam auth on desktop without social init', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    try {
      var socialFactoryCalls = 0;
      var steamCalls = 0;
      NetworkAuthResult? result;

      await _pumpDialog(
        tester,
        onResult: (value) => result = value,
        socialAuthClientFactory: () {
          socialFactoryCalls++;
          throw StateError('Social auth should not initialize on Windows.');
        },
        steamAuth: () async {
          steamCalls++;
          return _authResult(userId: 'steam_user');
        },
      );

      expect(
        find.byKey(const Key('multiplayer.account.steam')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('multiplayer.account.google.initializing')),
        findsNothing,
      );
      expect(socialFactoryCalls, 0);

      await tester.tap(find.byKey(const Key('multiplayer.account.steam')));
      await tester.pumpAndSettle();

      expect(steamCalls, 1);
      expect(result?.userId, 'steam_user');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('shows local validation before submitting', (tester) async {
    var loginCalls = 0;
    await _pumpDialog(
      tester,
      login: ({required email, required password}) async {
        loginCalls++;
        return _authResult();
      },
    );
    await _openEmailForm(tester);

    await tester.enterText(
      find.byKey(const Key('multiplayer.account.email')),
      'not-an-email',
    );
    await tester.enterText(
      find.byKey(const Key('multiplayer.account.password')),
      'secret',
    );
    await tester.tap(find.byKey(const Key('multiplayer.account.submit')));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(loginCalls, 0);
  });

  testWidgets('signs in with email and password', (tester) async {
    String? submittedEmail;
    String? submittedPassword;
    NetworkAuthResult? result;

    await _pumpDialog(
      tester,
      onResult: (value) => result = value,
      login: ({required email, required password}) async {
        submittedEmail = email;
        submittedPassword = password;
        return _authResult(userId: 'user_sign_in');
      },
    );
    await _openEmailForm(tester);

    await tester.enterText(
      find.byKey(const Key('multiplayer.account.email')),
      ' alice@example.com ',
    );
    await tester.enterText(
      find.byKey(const Key('multiplayer.account.password')),
      'secret',
    );
    await tester.tap(find.byKey(const Key('multiplayer.account.submit')));
    await tester.pumpAndSettle();

    expect(submittedEmail, 'alice@example.com');
    expect(submittedPassword, 'secret');
    expect(result?.userId, 'user_sign_in');
  });

  testWidgets('creates a new account from create mode', (tester) async {
    String? submittedEmail;
    String? submittedPassword;
    String? submittedDisplayName;
    var loginCalls = 0;

    await _pumpDialog(
      tester,
      login: ({required email, required password}) async {
        loginCalls++;
        return _authResult();
      },
      createAccount:
          ({required email, required password, required displayName}) async {
            submittedEmail = email;
            submittedPassword = password;
            submittedDisplayName = displayName;
            return _authResult(userId: 'user_created');
          },
    );
    await _openEmailForm(tester);

    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('multiplayer.account.nickname')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('multiplayer.account.nickname')),
      'New Alice',
    );
    await tester.enterText(
      find.byKey(const Key('multiplayer.account.email')),
      'new@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('multiplayer.account.password')),
      'long-secret',
    );
    await tester.tap(find.byKey(const Key('multiplayer.account.submit')));
    await tester.pumpAndSettle();

    expect(loginCalls, 0);
    expect(submittedEmail, 'new@example.com');
    expect(submittedPassword, 'long-secret');
    expect(submittedDisplayName, 'New Alice');
  });

  testWidgets('maps account-exists errors in create mode', (tester) async {
    await _pumpDialog(
      tester,
      createAccount:
          ({required email, required password, required displayName}) async {
            throw sp.AccountAuthException(code: 'account_exists');
          },
    );
    await _openEmailForm(tester);

    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('multiplayer.account.nickname')),
      'Taken Alice',
    );
    await tester.enterText(
      find.byKey(const Key('multiplayer.account.email')),
      'taken@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('multiplayer.account.password')),
      'long-secret',
    );
    await tester.tap(find.byKey(const Key('multiplayer.account.submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('An account with this email already exists.'),
      findsOneWidget,
    );
  });

  testWidgets('maps duplicate nickname errors in create mode', (tester) async {
    await _pumpDialog(
      tester,
      createAccount:
          ({required email, required password, required displayName}) async {
            throw sp.AccountAuthException(code: 'display_name_taken');
          },
    );
    await _openEmailForm(tester);

    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('multiplayer.account.nickname')),
      'Taken Alice',
    );
    await tester.enterText(
      find.byKey(const Key('multiplayer.account.email')),
      'taken@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('multiplayer.account.password')),
      'long-secret',
    );
    await tester.tap(find.byKey(const Key('multiplayer.account.submit')));
    await tester.pumpAndSettle();

    expect(find.text('This nickname is already taken.'), findsOneWidget);
  });
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  MultiplayerAccountAction? login,
  MultiplayerCreateAccountAction? createAccount,
  MultiplayerSocialAuthClientFactory? socialAuthClientFactory,
  MultiplayerSteamAuthAction? steamAuth,
  ValueChanged<NetworkAuthResult?>? onResult,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                final result = await showMultiplayerAccountDialog(
                  context: context,
                  login: login ?? _defaultAccountAction,
                  createAccount: createAccount ?? _defaultCreateAccountAction,
                  socialAuthClientFactory: socialAuthClientFactory,
                  steamAuth: steamAuth,
                  initialDisplayName: 'Alice',
                );
                onResult?.call(result);
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> _openEmailForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('multiplayer.account.emailMethod')));
  await tester.pumpAndSettle();
}

Future<NetworkAuthResult> _defaultAccountAction({
  required String email,
  required String password,
}) async {
  return _authResult();
}

Future<NetworkAuthResult> _defaultCreateAccountAction({
  required String email,
  required String password,
  required String displayName,
}) async {
  return _authResult(displayName: displayName);
}

NetworkAuthResult _authResult({
  String userId = 'user_1',
  String displayName = 'Alice',
}) {
  return NetworkAuthResult(
    userId: userId,
    token: AuthToken('token'),
    displayName: displayName,
    refreshToken: 'refresh-token',
  );
}
