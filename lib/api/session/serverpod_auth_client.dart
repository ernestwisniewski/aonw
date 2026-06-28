import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;

sp.Client createServerpodClient(
  String host, {
  AuthToken? token,
  Duration? connectionTimeout,
}) {
  final client = sp.Client(host, connectionTimeout: connectionTimeout);
  if (token != null) {
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
