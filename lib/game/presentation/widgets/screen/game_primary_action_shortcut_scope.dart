import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class GamePrimaryActionShortcutScope extends StatelessWidget {
  const GamePrimaryActionShortcutScope({
    required this.enabled,
    required this.onActivate,
    required this.child,
    super.key,
  });

  final bool enabled;
  final VoidCallback onActivate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space, includeRepeats: false):
            onActivate,
      },
      child: child,
    );
  }
}
