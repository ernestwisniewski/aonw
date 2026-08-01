part of 'network_session_client.dart';

extension NetworkSessionClientVersionStatus on NetworkSessionClient {
  Future<String> versionStatus({
    required String platform,
    required int buildNumber,
    int multiplayerVersion = kCurrentMultiplayerVersion,
  }) {
    return _withOwnedClient(
      connectionTimeout: const Duration(seconds: 3),
      run: (client) async {
        try {
          return await client.appStatus.versionStatus(
            platform: platform,
            buildNumber: buildNumber,
            multiplayerVersion: multiplayerVersion,
          );
        } on sp.ServerpodClientException catch (error) {
          if (error.statusCode != 400) rethrow;
          return client.callServerEndpoint<String>(
            'appStatus',
            'versionStatus',
            {'platform': platform, 'buildNumber': buildNumber},
            authenticated: false,
          );
        }
      },
    );
  }
}
