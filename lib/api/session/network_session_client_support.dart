part of 'network_session_client.dart';

extension _NetworkSessionClientSupport on NetworkSessionClient {
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
