import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum AppReleaseChannel {
  alpha('ALPHA');

  const AppReleaseChannel(this.label);

  final String label;
}

@immutable
class AppReleaseInfo {
  const AppReleaseInfo({
    required this.version,
    required this.buildNumber,
    this.channel = AppReleaseChannel.alpha,
  });

  final String version;
  final String buildNumber;
  final AppReleaseChannel channel;

  String get displayVersion {
    if (buildNumber.isEmpty) return 'v$version';
    return 'v$version+$buildNumber';
  }

  String get displayLabel => '${channel.label} $displayVersion';
}

final appReleaseInfoProvider = FutureProvider<AppReleaseInfo>((ref) async {
  final packageInfo = await PackageInfo.fromPlatform();
  return AppReleaseInfo(
    version: packageInfo.version,
    buildNumber: packageInfo.buildNumber,
  );
});
