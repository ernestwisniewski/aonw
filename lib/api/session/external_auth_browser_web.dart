import 'package:web/web.dart' as web;

final class ExternalAuthBrowserHandoff {
  ExternalAuthBrowserHandoff(this._window);

  web.Window? _window;

  Future<bool> navigate(Uri uri) async {
    final window = _window;
    if (window == null || window.closed) return false;
    try {
      window.location.href = uri.toString();
      window.focus();
      return true;
    } catch (_) {
      return false;
    }
  }

  void close() {
    final window = _window;
    _window = null;
    if (window == null || window.closed) return;
    try {
      window.close();
    } catch (_) {
      // The browser owns the external window after its cross-origin redirect.
    }
  }
}

ExternalAuthBrowserHandoff prepareExternalAuthBrowser() {
  final name = 'aonw_auth_${DateTime.now().microsecondsSinceEpoch}';
  final window = web.window.open('about:blank', name, 'popup');
  if (window != null) {
    window.opener = null;
  }
  return ExternalAuthBrowserHandoff(window);
}
