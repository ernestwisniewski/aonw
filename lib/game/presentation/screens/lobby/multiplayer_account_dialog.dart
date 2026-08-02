import 'dart:async';

import 'package:aonw/game/application/ports/multiplayer_failure.dart';
import 'package:aonw/game/application/ports/multiplayer_session_gateway.dart';
import 'package:aonw/game/application/ports/native_social_auth.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

part 'multiplayer_account_dialog_config.dart';
part 'multiplayer_account_dialog_auth_methods.dart';
part 'multiplayer_account_dialog_view.dart';

class _MultiplayerAccountDialog extends ConsumerStatefulWidget {
  const _MultiplayerAccountDialog({
    required this.login,
    required this.createAccount,
    required this.socialAuthClientFactory,
    required this.completeSocialAuth,
    required this.externalAuth,
    required this.steamAuth,
    required this.initialDisplayName,
  });

  final MultiplayerAccountAction login;
  final MultiplayerCreateAccountAction createAccount;
  final MultiplayerSocialAuthClientFactory? socialAuthClientFactory;
  final MultiplayerCompleteSocialAuthAction? completeSocialAuth;
  final MultiplayerExternalAuthAction? externalAuth;
  final MultiplayerSteamAuthAction? steamAuth;
  final String initialDisplayName;

  @override
  _MultiplayerAccountDialogState createState() =>
      _MultiplayerAccountDialogState();
}

class _MultiplayerAccountDialogState
    extends ConsumerState<_MultiplayerAccountDialog> {
  late final TextEditingController _nicknameController;
  late final NativeSocialAuthSession? _socialAuthClient;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _AccountMode _mode = _AccountMode.signIn;
  bool _emailFormExpanded = false;
  bool _socialAuthReady = false;
  bool _busy = false;
  bool _externalAuthBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: widget.initialDisplayName.trim(),
    );
    _socialAuthClient = _supportsNativeSocialSignIn
        ? widget.socialAuthClientFactory?.call()
        : null;
    final socialAuthClient = _socialAuthClient;
    if (socialAuthClient != null && widget.completeSocialAuth != null) {
      unawaited(_initializeSocialAuth(socialAuthClient));
    }
  }

  @override
  void dispose() {
    _socialAuthClient?.close();
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showSocialAuth =
        _socialAuthClient != null && widget.completeSocialAuth != null;
    return _AccountDialogView(
      l10n: l10n,
      busy: _busy,
      externalAuthBusy: _externalAuthBusy,
      socialAuthClient: showSocialAuth ? _socialAuthClient : null,
      socialAuthReady: _socialAuthReady,
      showNativeGoogle: showSocialAuth && _supportsNativeGoogleSignIn,
      showNativeApple: showSocialAuth && _supportsNativeAppleSignIn,
      showExternalGoogle:
          _usesExternalGoogleSignIn && widget.externalAuth != null,
      showExternalApple:
          _usesExternalAppleSignIn && widget.externalAuth != null,
      showSteam: _supportsSteamSignIn && widget.steamAuth != null,
      emailFormExpanded: _emailFormExpanded,
      mode: _mode,
      error: _error,
      nicknameController: _nicknameController,
      emailController: _emailController,
      passwordController: _passwordController,
      onClose: () => Navigator.of(context).pop(),
      onEmailPressed: _showEmailForm,
      onAuthenticated: () => unawaited(_completeSocialAuth()),
      onSocialError: _handleSocialAuthError,
      onGooglePressed: () =>
          unawaited(_signInWithExternalProvider(_googleExternalAuthProvider)),
      onApplePressed: () =>
          unawaited(_signInWithExternalProvider(_appleExternalAuthProvider)),
      onSteamPressed: () => unawaited(_signInWithSteam()),
      onModeChanged: (mode) {
        setState(() {
          _mode = mode;
          _error = null;
        });
      },
      onSubmitted: () => unawaited(_submit()),
    );
  }

  void _showEmailForm() {
    if (_emailFormExpanded) return;
    setState(() {
      _emailFormExpanded = true;
      _error = null;
    });
  }

  Future<void> _initializeSocialAuth(NativeSocialAuthSession client) async {
    try {
      if (_supportsNativeGoogleSignIn) {
        await client.initializeGoogle(
          clientId: _googleClientId(),
          serverClientId: _googleServerClientId(),
        );
      }
      if (_supportsNativeAppleSignIn) {
        await client.initializeApple(
          serviceIdentifier: _appleServiceIdentifier(),
          redirectUri: _appleRedirectUri(),
        );
      }
      if (!mounted) return;
      setState(() => _socialAuthReady = true);
    } catch (error, stackTrace) {
      _logWarning('Failed to initialize social sign-in.', error, stackTrace);
      if (!mounted) return;
      setState(() {
        _socialAuthReady = false;
        _error = _accountErrorText(AppLocalizations.of(context), error);
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _nicknameController.text.trim();
    final localError = _accountLocalError(
      l10n: l10n,
      mode: _mode,
      email: email,
      password: password,
      displayName: displayName,
    );
    if (localError != null) {
      setState(() => _error = localError);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final result = _mode == _AccountMode.signIn
          ? await widget.login(email: email, password: password)
          : await widget.createAccount(
              email: email,
              password: password,
              displayName: displayName,
            );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _accountErrorText(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeSocialAuth() async {
    final socialAuthClient = _socialAuthClient;
    final completeSocialAuth = widget.completeSocialAuth;
    final auth = socialAuthClient?.authSuccess;
    if (socialAuthClient == null ||
        completeSocialAuth == null ||
        auth == null) {
      _handleSocialAuthError(
        StateError('Missing social authentication state.'),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final result = await completeSocialAuth(authSuccess: auth);
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (error, stackTrace) {
      _logWarning('Social auth completion error.', error, stackTrace);
      if (!mounted) return;
      setState(
        () => _error = _accountErrorText(AppLocalizations.of(context), error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithSteam() async {
    final steamAuth = widget.steamAuth;
    if (steamAuth == null) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _externalAuthBusy = true;
      _error = null;
    });

    try {
      final result = await steamAuth();
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (error, stackTrace) {
      _logWarning('Steam sign-in error.', error, stackTrace);
      if (!mounted) return;
      setState(
        () => _error = _accountErrorText(AppLocalizations.of(context), error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _externalAuthBusy = false;
        });
      }
    }
  }

  Future<void> _signInWithExternalProvider(String provider) async {
    final externalAuth = widget.externalAuth;
    if (externalAuth == null) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _externalAuthBusy = true;
      _error = null;
    });

    try {
      final result = await externalAuth(provider: provider);
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (error, stackTrace) {
      _logWarning('$provider sign-in error.', error, stackTrace);
      if (!mounted) return;
      setState(
        () => _error = _accountErrorText(AppLocalizations.of(context), error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _externalAuthBusy = false;
        });
      }
    }
  }

  void _handleSocialAuthError(Object error) {
    _logWarning('Social auth error.', error);
    if (!mounted) return;
    setState(
      () => _error = _accountErrorText(AppLocalizations.of(context), error),
    );
  }

  void _logWarning(String message, Object error, [StackTrace? stackTrace]) {
    ref
        .read(gameLoggerProvider)
        .warn('MultiplayerAccountDialog', message, error, stackTrace);
  }
}
