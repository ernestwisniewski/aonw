import 'package:aonw/api/session/external_auth_browser_contract.dart';
import 'package:url_launcher/url_launcher.dart';

final class ExternalAuthBrowserHandoff implements ExternalAuthBrowser {
  const ExternalAuthBrowserHandoff();

  @override
  Future<bool> navigate(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void close() {}
}

ExternalAuthBrowser prepareExternalAuthBrowser() {
  return const ExternalAuthBrowserHandoff();
}
