import 'package:url_launcher/url_launcher.dart';

final class ExternalAuthBrowserHandoff {
  const ExternalAuthBrowserHandoff();

  Future<bool> navigate(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void close() {}
}

ExternalAuthBrowserHandoff prepareExternalAuthBrowser() {
  return const ExternalAuthBrowserHandoff();
}
