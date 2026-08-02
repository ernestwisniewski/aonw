part of 'network_session_client.dart';

Future<String> loadNetworkSessionVersionStatus(
  NetworkSessionClient client, {
  required String platform,
  required int buildNumber,
  required int multiplayerVersion,
}) {
  return client._withOwnedClient(
    connectionTimeout: const Duration(seconds: 3),
    run: (serverpodClient) async {
      try {
        return await serverpodClient.appStatus.versionStatus(
          platform: platform,
          buildNumber: buildNumber,
          multiplayerVersion: multiplayerVersion,
        );
      } on sp.ServerpodClientException catch (error) {
        if (error.statusCode != 400) rethrow;
        return serverpodClient.callServerEndpoint<String>(
          'appStatus',
          'versionStatus',
          {'platform': platform, 'buildNumber': buildNumber},
          authenticated: false,
        );
      }
    },
  );
}
