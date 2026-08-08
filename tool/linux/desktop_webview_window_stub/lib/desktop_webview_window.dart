import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Configuration retained for source compatibility with
/// `desktop_webview_window` 0.3.0.
class CreateConfiguration {
  const CreateConfiguration({
    this.windowWidth = 1280,
    this.windowHeight = 720,
    this.windowPosX = 0,
    this.windowPosY = 0,
    this.title = '',
    this.titleBarHeight = 40,
    this.titleBarTopPadding = 0,
    this.userDataFolderWindows = 'webview_window_WebView2',
    this.useWindowPositionAndSize = false,
    this.openMaximized = false,
  });

  factory CreateConfiguration.platform() => const CreateConfiguration();

  final int windowWidth;
  final int windowHeight;
  final int windowPosX;
  final int windowPosY;
  final String title;
  final int titleBarHeight;
  final int titleBarTopPadding;
  final String userDataFolderWindows;
  final bool useWindowPositionAndSize;
  final bool openMaximized;
}

typedef JavaScriptMessageHandler = void Function(String name, dynamic body);
typedef PromptHandler = String Function(String prompt, String defaultText);
typedef OnHistoryChangedCallback = void Function(
  bool canGoBack,
  bool canGoForward,
);
typedef OnUrlRequestCallback = bool Function(String url);
typedef OnWebMessageReceivedCallback = void Function(String message);

/// API surface required by flutter_web_auth_2.
///
/// AONW never creates this view on desktop: native desktop authentication is
/// handed to the system browser and completed through server-side polling.
abstract class Webview {
  Future<void> get onClose;
  ValueListenable<bool> get isNavigating;

  void registerJavaScriptMessageHandler(
    String name,
    JavaScriptMessageHandler handler,
  );
  void unregisterJavaScriptMessageHandler(String name);
  void setPromptHandler(PromptHandler? handler);
  void launch(String url, {bool triggerOnUrlRequestEvent = true});
  void setBrightness(Brightness? brightness);
  void addScriptToExecuteOnDocumentCreated(String javaScript);
  Future<void> setApplicationNameForUserAgent(String applicationName);
  Future<void> back();
  Future<void> forward();
  Future<void> setWebviewWindowVisibility(bool visible);
  Future<void> moveWebviewWindow(int left, int top, int width, int height);
  Future<void> bringToForeground({bool maximized = false});
  Future<Map<dynamic, dynamic>?> getPositionalParameters();
  Future<void> reload();
  Future<void> stop();
  Future<void> openDevToolsWindow();
  void setOnHistoryChangedCallback(OnHistoryChangedCallback? callback);
  void setOnUrlRequestCallback(OnUrlRequestCallback? callback);
  void addOnWebMessageReceivedCallback(OnWebMessageReceivedCallback callback);
  void removeOnWebMessageReceivedCallback(
    OnWebMessageReceivedCallback callback,
  );
  void removeAllWebMessageReceivedCallback();
  void close();
  Future<String?> evaluateJavaScript(String javaScript);
  Future<void> postWebMessageAsString(String webMessage);
  Future<void> postWebMessageAsJson(String webMessage);
  Future<List<WebviewCookie>> getAllCookies();
}

class WebviewCookie {
  const WebviewCookie({
    required this.name,
    required this.value,
    required this.domain,
    required this.path,
    required this.expires,
    required this.secure,
    required this.httpOnly,
    required this.sessionOnly,
  });

  final String name;
  final String value;
  final String domain;
  final String path;
  final DateTime? expires;
  final bool secure;
  final bool httpOnly;
  final bool sessionOnly;
}

/// Embedded desktop webviews are deliberately unavailable in AONW builds.
abstract final class WebviewWindow {
  static Future<bool> isWebviewAvailable() async => false;

  static Future<Webview> create({CreateConfiguration? configuration}) {
    throw UnsupportedError(
      'AONW desktop authentication uses the system browser.',
    );
  }

  static Future<void> clearAll({
    String userDataFolderWindows = 'webview_window_WebView2',
  }) async {}
}

bool runWebViewTitleBarWidget(
  List<String> args, {
  WidgetBuilder? builder,
  Color? backgroundColor,
}) =>
    false;
