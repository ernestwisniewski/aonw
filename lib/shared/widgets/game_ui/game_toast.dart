import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

enum GameToastTone { info, success, warning, error }

abstract final class GameToast {
  static void show(
    BuildContext context, {
    required String message,
    GameToastTone tone = GameToastTone.info,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    final media = MediaQuery.maybeOf(context);
    final bottomInset = media?.padding.bottom ?? 0;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          duration: duration,
          dismissDirection: DismissDirection.down,
          content: _GameToastContent(
            message: message,
            tone: tone,
            bottomPadding: 14 + bottomInset,
          ),
        ),
      );
  }
}

class _GameToastContent extends StatelessWidget {
  final String message;
  final GameToastTone tone;
  final double bottomPadding;

  const _GameToastContent({
    required this.message,
    required this.tone,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(tone);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, bottomPadding),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: DecoratedBox(
                key: const Key('gameToast.surface'),
                decoration: SurfaceElevation.floating.decoration(
                  background: GameUiTheme.surfaceDeep,
                  backgroundAlpha: 244,
                  borderColor: accent,
                  border: BorderEmphasis.strong,
                  radius: 8,
                  boxShadow: [
                    const BoxShadow(
                      color: Color(0xAA000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                    BoxShadow(color: accent.withAlpha(32), blurRadius: 22),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DecoratedBox(
                        key: const Key('gameToast.accent'),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accent.withAlpha(245),
                              accent.withAlpha(150),
                            ],
                          ),
                        ),
                        child: const SizedBox(width: 4),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
                        child: Icon(_iconFor(tone), size: 20, color: accent),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 14, 11),
                          child: Text(
                            message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GameUiTheme.bodyStrong.copyWith(
                              color: GameUiTheme.textPrimary,
                              fontSize: 13,
                              height: 1.22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _accentFor(GameToastTone tone) {
  return switch (tone) {
    GameToastTone.info => GameUiTheme.info,
    GameToastTone.success => GameUiTheme.success,
    GameToastTone.warning => GameUiTheme.warning,
    GameToastTone.error => GameUiTheme.danger,
  };
}

IconData _iconFor(GameToastTone tone) {
  return switch (tone) {
    GameToastTone.info => Icons.info_outline_rounded,
    GameToastTone.success => Icons.check_circle_outline_rounded,
    GameToastTone.warning => Icons.warning_amber_rounded,
    GameToastTone.error => Icons.error_outline_rounded,
  };
}
