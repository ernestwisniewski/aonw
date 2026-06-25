import 'dart:math' as math;

import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class ScrollableErrorView extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const ScrollableErrorView({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.all(24);
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = math.max(
          0.0,
          constraints.maxHeight - padding.vertical,
        );
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: GameUiTheme.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: onAction,
                    child: Text(
                      actionLabel,
                      style: const TextStyle(color: GameUiTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
