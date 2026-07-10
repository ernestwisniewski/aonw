import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;

typedef ServerpodAuthKeyProviderFactory = sp.ClientAuthKeyProvider Function();

sp.Client createServerpodClient(
  String host, {
  AuthToken? token,
  sp.ClientAuthKeyProvider? authKeyProvider,
  Duration? connectionTimeout,
}) {
  final client = sp.Client(host, connectionTimeout: connectionTimeout);
  if (authKeyProvider != null) {
    client.authKeyProvider = authKeyProvider;
  } else if (token != null) {
    client.authKeyProvider = ServerpodAuthTokenProvider(token);
  }
  return client;
}

class ServerpodAuthTokenProvider implements sp.ClientAuthKeyProvider {
  final AuthToken token;

  const ServerpodAuthTokenProvider(this.token);

  @override
  Future<String?> get authHeaderValue async {
    return sp.wrapAsBearerAuthHeaderValue(token.value);
  }
}
