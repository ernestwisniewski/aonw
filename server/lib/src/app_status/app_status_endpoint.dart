import 'package:aonw_core/protocol.dart';
import 'package:serverpod/serverpod.dart';

class AppStatusEndpoint extends Endpoint {
  @unauthenticatedClientCall
  Future<String> versionStatus(
    Session session, {
    required String platform,
    required int buildNumber,
    int? multiplayerVersion,
  }) async {
    final latestBuildNumber = _buildNumberFor(_serverAppVersion);
    return appVersionStatus(
      buildNumber: buildNumber,
      latestBuildNumber: latestBuildNumber,
      multiplayerVersion: multiplayerVersion,
    );
  }
}

String appVersionStatus({
  required int buildNumber,
  required int latestBuildNumber,
  required int? multiplayerVersion,
}) {
  if (!isCompatibleMultiplayerVersion(multiplayerVersion)) return 'soon';
  if (buildNumber < latestBuildNumber) return 'soon';
  return 'current';
}

const _serverAppVersion = String.fromEnvironment(
  'AONW_APP_VERSION',
  defaultValue: '0.0.0+0',
);

int _buildNumberFor(String version) {
  final separator = version.lastIndexOf('+');
  if (separator < 0 || separator == version.length - 1) return 0;
  return int.tryParse(version.substring(separator + 1)) ?? 0;
}
