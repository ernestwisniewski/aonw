/// Browser handoff owned by one external authentication attempt.
abstract interface class ExternalAuthBrowser {
  Future<bool> navigate(Uri uri);

  void close();
}

typedef ExternalAuthBrowserFactory = ExternalAuthBrowser Function();
