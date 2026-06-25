import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class GameUiEpicHeader extends StatelessWidget {
  const GameUiEpicHeader({
    required this.label,
    this.leading,
    this.trailing,
    this.alignment = Alignment.centerRight,
    this.accent = GameUiTheme.gold,
    this.compact = true,
    this.textKey,
    super.key,
  });

  final String label;
  final Widget? leading;
  final Widget? trailing;
  final AlignmentGeometry alignment;
  final Color accent;
  final bool compact;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final resolvedAlignment = alignment.resolve(textDirection);
    final alignRight = resolvedAlignment.x > 0;

    return Semantics(
      header: true,
      label: label,
      child: SizedBox(
        height: compact ? 22 : 30,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: compact ? 7 : 10),
            ],
            Expanded(
              child: Align(
                alignment: alignment,
                child: _GameUiEpicHeaderLockup(
                  label: label,
                  alignRight: alignRight,
                  accent: accent,
                  compact: compact,
                  textKey: textKey,
                ),
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: compact ? 7 : 10),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _GameUiEpicHeaderLockup extends StatelessWidget {
  const _GameUiEpicHeaderLockup({
    required this.label,
    required this.alignRight,
    required this.accent,
    required this.compact,
    this.textKey,
  });

  final String label;
  final bool alignRight;
  final Color accent;
  final bool compact;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    final text = Flexible(
      flex: 4,
      child: Text(
        label,
        key: textKey,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: _style,
      ),
    );
    final rule = Flexible(
      flex: compact ? 3 : 2,
      child: _GameUiEpicHeaderRule(accent: accent, diamondAtEnd: false),
    );

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [text, const SizedBox(width: 7), rule],
    );
  }

  TextStyle get _style {
    final glowColor = Color.lerp(accent, GameUiTheme.goldLight, 0.35)!;
    return TextStyle(
      color: glowColor,
      fontFamily: GameUiTheme.headingFont,
      fontSize: compact ? 11 : 15.5,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.05,
      fontFeatures: GameUiTheme.tabularFigures,
      shadows: [
        Shadow(
          color: GameUiTheme.bg.withAlpha(235),
          blurRadius: 0,
          offset: const Offset(0, 1),
        ),
        Shadow(
          color: GameUiTheme.bg.withAlpha(210),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        Shadow(color: accent.withAlpha(120), blurRadius: compact ? 12 : 18),
      ],
    );
  }
}

class _GameUiEpicHeaderRule extends StatelessWidget {
  const _GameUiEpicHeaderRule({
    required this.accent,
    required this.diamondAtEnd,
  });

  final Color accent;
  final bool diamondAtEnd;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: diamondAtEnd
                ? [accent.withAlpha(0), accent.withAlpha(150)]
                : [accent.withAlpha(150), accent.withAlpha(0)],
          ),
          boxShadow: [
            BoxShadow(color: GameUiTheme.bg.withAlpha(190), blurRadius: 5),
          ],
        ),
        child: const SizedBox(height: 1.2),
      ),
    );
    final diamond = Transform.rotate(
      angle: 0.7853981634,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GameUiTheme.goldLight.withAlpha(190),
          boxShadow: [BoxShadow(color: accent.withAlpha(85), blurRadius: 8)],
        ),
        child: const SizedBox(width: 4, height: 4),
      ),
    );

    return Row(
      children: diamondAtEnd
          ? [line, const SizedBox(width: 6), diamond]
          : [diamond, const SizedBox(width: 6), line],
    );
  }
}
