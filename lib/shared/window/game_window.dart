import 'package:flutter/foundation.dart';

abstract interface class GameWindow {
  bool get supportsWindowModes;

  Future<void> initialize({required bool windowed});

  Future<void> setWindowed(bool windowed);
}

bool supportsDesktopWindowModes({bool? isWeb, TargetPlatform? platform}) {
  if (isWeb ?? kIsWeb) return false;
  return switch (platform ?? defaultTargetPlatform) {
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => true,
    TargetPlatform.android ||
    TargetPlatform.fuchsia ||
    TargetPlatform.iOS => false,
  };
}
