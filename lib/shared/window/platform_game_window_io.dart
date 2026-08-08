import 'dart:async';

import 'package:aonw/shared/window/game_window.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

final class PlatformGameWindow implements GameWindow {
  @override
  bool get supportsWindowModes => supportsDesktopWindowModes();

  @override
  Future<void> initialize({required bool windowed}) async {
    if (!supportsWindowModes) return;
    await windowManager.ensureInitialized();
    unawaited(
      windowManager.waitUntilReadyToShow(
        WindowOptions(fullScreen: !windowed, backgroundColor: Colors.black),
        () async {
          await windowManager.show();
          await windowManager.focus();
        },
      ),
    );
  }

  @override
  Future<void> setWindowed(bool windowed) async {
    if (!supportsWindowModes) return;
    await windowManager.setFullScreen(!windowed);
  }
}
