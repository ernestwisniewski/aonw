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
        // A server that does not understand the multiplayer declaration cannot
        // prove compatibility with this client. Keep entry fail-closed instead
        // of retrying the legacy build-only status shape.
        return 'soon';
      }
    },
  );
}
