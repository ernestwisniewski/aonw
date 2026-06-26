import 'dart:async';

import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as sp_auth
    show AuthSuccess;
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

part 'multiplayer_account_dialog_config.dart';
part 'multiplayer_account_dialog_auth_methods.dart';

class _MultiplayerAccountDialog extends ConsumerStatefulWidget {
  const _MultiplayerAccountDialog({
    required this.login,
    required this.createAccount,
    required this.socialAuthClientFactory,
    required this.completeSocialAuth,
    required this.steamAuth,
    required this.initialDisplayName,
  });

  final MultiplayerAccountAction login;
  final MultiplayerCreateAccountAction createAccount;
  final MultiplayerSocialAuthClientFactory? socialAuthClientFactory;
  final MultiplayerCompleteSocialAuthAction? completeSocialAuth;
  final MultiplayerSteamAuthAction? steamAuth;
  final String initialDisplayName;

  @override
  _MultiplayerAccountDialogState createState() =>
      _MultiplayerAccountDialogState();
}

class _MultiplayerAccountDialogState
    extends ConsumerState<_MultiplayerAccountDialog> {
  late final TextEditingController _nicknameController;
  late final sp.Client? _socialAuthClient;
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
    _socialAuthClient = _supportsGoogleAppleSignIn
        ? widget.socialAuthClientFactory?.call()
        : null;
    final socialAuthClient = _socialAuthClient;
    if (socialAuthClient != null && widget.completeSocialAuth != null) {
      unawaited(_initializeSocialAuth(socialAuthClient));
    }
  }

  @override
  void dispose() {
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
    final showSteamAuth = _supportsSteamSignIn && widget.steamAuth != null;
    return GameModalScaffold(
      size: GameModalSize.regular,
      surfaceKey: const Key('multiplayer.account.surface'),
      header: GameModalHeader(
        title: l10n.multiplayerAccountTitle,
        subtitle: l10n.multiplayerAccountSubtitle,
        icon: Icons.lock_outline,
        onClose: _busy && !_externalAuthBusy
            ? null
            : () => Navigator.of(context).pop(),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IgnorePointer(
            ignoring: _busy,
            child: Opacity(
              opacity: _busy ? 0.62 : 1,
              child: _AuthMethodButtons(
                client: showSocialAuth ? _socialAuthClient : null,
                socialAuthReady: _socialAuthReady,
                emailSelected: _emailFormExpanded,
                onEmailPressed: _showEmailForm,
                onAuthenticated: () => unawaited(_completeSocialAuth()),
                onError: _handleSocialAuthError,
                onSteamPressed: showSteamAuth
                    ? () => unawaited(_signInWithSteam())
                    : null,
              ),
            ),
          ),
          AnimatedSize(
            duration: GameMotion.slide,
            curve: GameMotion.stateChange,
            alignment: Alignment.topCenter,
            child: _emailFormExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: _EmailAccountForm(
                      l10n: l10n,
                      mode: _mode,
                      busy: _busy,
                      nicknameController: _nicknameController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      onModeChanged: (mode) {
                        setState(() {
                          _mode = mode;
                          _error = null;
                        });
                      },
                      onSubmitted: () => unawaited(_submit()),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              key: const Key('multiplayer.account.error'),
              _error!,
              style: GameUiTheme.bodyStrong.copyWith(color: GameUiTheme.danger),
            ),
          ],
        ],
      ),
      actions: [
        GameModalAction(
          label: l10n.selectionActionCancel,
          variant: EpicButtonVariant.text,
          onPressed: _busy && !_externalAuthBusy
              ? null
              : () => Navigator.of(context).pop(),
        ),
        if (_emailFormExpanded)
          GameModalAction(
            key: const Key('multiplayer.account.submit'),
            label: _mode == _AccountMode.signIn
                ? l10n.multiplayerAccountSignInAction
                : l10n.multiplayerAccountCreateAction,
            variant: EpicButtonVariant.primary,
            icon: _mode == _AccountMode.signIn
                ? Icons.login_rounded
                : Icons.person_add_alt_1_rounded,
            onPressed: _busy ? null : () => unawaited(_submit()),
          ),
      ],
    );
  }

  void _showEmailForm() {
    if (_emailFormExpanded) return;
    setState(() {
      _emailFormExpanded = true;
      _error = null;
    });
  }

  Future<void> _initializeSocialAuth(sp.Client client) async {
    try {
      await client.auth.initializeGoogleSignIn(
        clientId: _googleClientId(),
        serverClientId: _googleServerClientId(),
      );
      await client.auth.initializeAppleSignIn(
        serviceIdentifier: _appleServiceIdentifier(),
        redirectUri: _appleRedirectUri(),
      );
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
    final auth = socialAuthClient?.auth.authInfo;
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
      final result = await completeSocialAuth(auth: auth);
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
