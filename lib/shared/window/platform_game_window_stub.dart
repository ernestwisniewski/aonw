import 'package:aonw/shared/window/game_window.dart';

final class PlatformGameWindow implements GameWindow {
  @override
  bool get supportsWindowModes => false;

  @override
  Future<void> initialize({required bool windowed}) async {}

  @override
  Future<void> setWindowed(bool windowed) async {}
}
