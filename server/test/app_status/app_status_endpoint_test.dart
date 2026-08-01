import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/app_status/app_status_endpoint.dart';
import 'package:test/test.dart';

void main() {
  test('current and reviewed legacy multiplayer clients remain current', () {
    for (final version in <int?>[
      null,
      kLegacyUndeclaredMultiplayerVersion,
      kCurrentMultiplayerVersion,
    ]) {
      expect(
        appVersionStatus(
          buildNumber: 80,
          latestBuildNumber: 80,
          multiplayerVersion: version,
        ),
        'current',
        reason: 'version $version',
      );
    }
  });

  test('incompatible multiplayer client receives the update notice status', () {
    expect(
      appVersionStatus(
        buildNumber: 80,
        latestBuildNumber: 80,
        multiplayerVersion: kCurrentMultiplayerVersion + 1,
      ),
      'soon',
    );
  });

  test('older app build still receives the update notice status', () {
    expect(
      appVersionStatus(
        buildNumber: 79,
        latestBuildNumber: 80,
        multiplayerVersion: kCurrentMultiplayerVersion,
      ),
      'soon',
    );
  });
}
