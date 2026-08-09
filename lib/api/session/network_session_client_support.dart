part of 'network_session_client.dart';

extension _NetworkSessionClientSupport on NetworkSessionClient {
  Future<NetworkAuthResult> _loginWithExternalBrowser({
    required String signInName,
    required Set<String> pendingStatuses,
    required Future<_ExternalAuthStart> Function(sp.Client client) start,
    required Future<_ExternalAuthPoll> Function(
      sp.Client client,
      String requestId,
    )
    poll,
  }) async {
    final operation = _beginExternalAuthOperation();
    try {
      final client = _activeAnonymousClient;
      final authStart = await _startExternalAuthOperation(
        operation: operation,
        signInName: signInName,
        client: client,
        start: start,
      );
      return await _pollExternalAuthOperation(
        operation: operation,
        signInName: signInName,
        pendingStatuses: pendingStatuses,
        client: client,
        authStart: authStart,
        poll: poll,
      );
    } on _ExternalAuthCancelled {
      if (_closed) {
        throw StateError('Network session client is closed.');
      }
      throw StateError('$signInName sign-in was cancelled.');
    } finally {
      _finishExternalAuthOperation(operation);
    }
  }

  Future<_ExternalAuthStart> _startExternalAuthOperation({
    required _ExternalAuthOperation operation,
    required String signInName,
    required sp.Client client,
    required Future<_ExternalAuthStart> Function(sp.Client client) start,
  }) async {
    final authStart = await operation.waitFor(_mapRequest(() => start(client)));
    _ensureActiveExternalAuth(operation, signInName: signInName);
    final opened = await operation.waitFor(
      operation.browser.navigate(Uri.parse(authStart.authUrl)),
    );
    _ensureActiveExternalAuth(operation, signInName: signInName);
    if (!opened) throw StateError('Could not open $signInName sign-in.');
    return authStart;
  }

  Future<NetworkAuthResult> _pollExternalAuthOperation({
    required _ExternalAuthOperation operation,
    required String signInName,
    required Set<String> pendingStatuses,
    required sp.Client client,
    required _ExternalAuthStart authStart,
    required Future<_ExternalAuthPoll> Function(
      sp.Client client,
      String requestId,
    )
    poll,
  }) async {
    final expiresAt = authStart.expiresAt.toUtc();
    while (true) {
      await _waitForExternalAuthPollSlot(
        operation,
        signInName: signInName,
        expiresAt: expiresAt,
      );
      final authPoll = await operation.waitFor(
        _mapRequest(() => poll(client, authStart.requestId)),
      );
      _ensureActiveExternalAuth(operation, signInName: signInName);
      final auth = authPoll.auth;
      if (auth != null) {
        final result = await operation.waitFor(
          completeNativeSocialAuth(authSuccess: auth),
        );
        _ensureActiveExternalAuth(operation, signInName: signInName);
        return result;
      }
      if (!pendingStatuses.contains(authPoll.status)) {
        throw StateError(
          '$signInName sign-in failed: ${authPoll.error ?? authPoll.status}',
        );
      }
    }
  }

  Future<void> _waitForExternalAuthPollSlot(
    _ExternalAuthOperation operation, {
    required String signInName,
    required DateTime expiresAt,
  }) async {
    _ensureActiveExternalAuth(operation, signInName: signInName);
    final remaining = expiresAt.difference(DateTime.now().toUtc());
    if (remaining <= Duration.zero) {
      throw StateError('$signInName sign-in expired.');
    }
    final pollDelay = remaining < _externalAuthPollInterval
        ? remaining
        : _externalAuthPollInterval;
    await operation.waitFor(Future<void>.delayed(pollDelay));
    _ensureActiveExternalAuth(operation, signInName: signInName);
    if (!DateTime.now().toUtc().isBefore(expiresAt)) {
      throw StateError('$signInName sign-in expired.');
    }
  }

  _ExternalAuthOperation _beginExternalAuthOperation() {
    _ensureOpen();
    _externalAuthGeneration += 1;
    _externalAuthOperation?.cancel();
    final operation = _ExternalAuthOperation(
      generation: _externalAuthGeneration,
      browser: _externalAuthBrowserFactory(),
    );
    _externalAuthOperation = operation;
    return operation;
  }

  void _ensureActiveExternalAuth(
    _ExternalAuthOperation operation, {
    required String signInName,
  }) {
    if (_closed) throw StateError('Network session client is closed.');
    if (!identical(_externalAuthOperation, operation) ||
        operation.generation != _externalAuthGeneration) {
      throw StateError('$signInName sign-in was cancelled.');
    }
  }

  void _finishExternalAuthOperation(_ExternalAuthOperation operation) {
    if (identical(_externalAuthOperation, operation)) {
      _externalAuthOperation = null;
    }
    operation.cancel();
  }

  Future<T> _withExplicitToken<T>(
    AuthToken token,
    Future<T> Function(sp.Client client) run,
  ) {
    return _withOwnedClient(token: token, run: run);
  }

  Future<T> _withAnonymousClient<T>(Future<T> Function(sp.Client client) run) {
    return _mapRequest(() => run(_activeAnonymousClient));
  }

  Future<T> _mapRequest<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (error, stackTrace) {
      throwMappedServerpodMultiplayerFailure(error, stackTrace);
    }
  }

  Future<T> _withOwnedClient<T>({
    AuthToken? token,
    Duration? connectionTimeout,
    required Future<T> Function(sp.Client client) run,
  }) async {
    _ensureOpen();
    final client = _clientFactory(
      serverpodHost,
      token: token,
      connectionTimeout: connectionTimeout,
    );
    try {
      try {
        return await run(client);
      } catch (error, stackTrace) {
        throwMappedServerpodMultiplayerFailure(error, stackTrace);
      }
    } finally {
      client.close();
    }
  }

  sp.Client get _activeAnonymousClient {
    _ensureOpen();
    return _anonymousClient ??= _clientFactory(serverpodHost);
  }

  sp.Client get _activeAuthenticatedClient {
    _ensureOpen();
    final active = _authenticatedClient;
    if (active != null) return active;
    final providerFactory = authKeyProviderFactory;
    if (providerFactory == null) {
      throw StateError('No refresh-aware auth provider is configured.');
    }
    return _authenticatedClient = _clientFactory(
      serverpodHost,
      authKeyProvider: providerFactory(),
    );
  }

  void _ensureOpen() {
    if (_closed) throw StateError('Network session client is closed.');
  }
}

typedef _ExternalAuthStart = ({
  String requestId,
  String authUrl,
  DateTime expiresAt,
});

typedef _ExternalAuthPoll = ({
  String status,
  sp_auth.AuthSuccess? auth,
  String? error,
});

final class _ExternalAuthOperation {
  _ExternalAuthOperation({required this.generation, required this.browser});

  final int generation;
  final ExternalAuthBrowser browser;
  final Completer<void> _cancelled = Completer<void>();
  var _browserClosed = false;

  Future<T> waitFor<T>(Future<T> action) {
    return Future.any<T>([
      action,
      _cancelled.future.then<T>((_) => throw const _ExternalAuthCancelled()),
    ]);
  }

  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
    if (_browserClosed) return;
    _browserClosed = true;
    browser.close();
  }
}

final class _ExternalAuthCancelled implements Exception {
  const _ExternalAuthCancelled();
}
