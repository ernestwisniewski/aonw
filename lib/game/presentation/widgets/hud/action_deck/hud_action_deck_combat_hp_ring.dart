part of 'hud_action_deck.dart';

const _combatHpRoleAlpha = 230;
const _combatHpLossAlpha = 230;
const _combatHpTrackAlpha = 150;
const _combatHpBeforeAlpha = 126;
const _combatHpShadowAlpha = 220;

class _CombatHpRingCard extends StatelessWidget {
  const _CombatHpRingCard({
    required this.roleLabel,
    required this.unitName,
    required this.beforeHp,
    required this.afterHp,
    required this.maxHp,
    required this.killed,
    required this.accent,
    required this.ringSize,
    required this.ringKey,
    required this.hpKey,
  });

  final String roleLabel;
  final String unitName;
  final int beforeHp;
  final int afterHp;
  final int maxHp;
  final bool killed;
  final Color accent;
  final double ringSize;
  final Key ringKey;
  final Key hpKey;

  @override
  Widget build(BuildContext context) {
    final safeMaxHp = math.max(1, maxHp);
    final safeBeforeHp = beforeHp.clamp(0, safeMaxHp).toInt();
    final safeAfterHp = afterHp.clamp(0, safeMaxHp).toInt();
    final lostHp = math.max(0, safeBeforeHp - safeAfterHp);
    final l10n = AppLocalizations.of(context);
    final lossText = lostHp > 0
        ? '-$lostHp ${l10n.unitSelectionHpLabel}'
        : l10n.combatPreviewNoHpLoss;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          roleLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.labelSmall.copyWith(
            color: GameUiTheme.goldLight.withAlpha(_combatHpRoleAlpha),
          ),
        ),
        const SizedBox(height: 5),
        _CombatHpRing(
          key: ringKey,
          beforeHp: safeBeforeHp,
          afterHp: safeAfterHp,
          maxHp: safeMaxHp,
          killed: killed,
          accent: accent,
          size: ringSize,
          hpKey: hpKey,
        ),
        const SizedBox(height: 7),
        Text(
          unitName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GameUiTheme.bodyStrong.copyWith(color: GameUiTheme.textBright),
        ),
        const SizedBox(height: 2),
        Text(
          lossText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.chipLabel.copyWith(
            color: lostHp > 0
                ? GameUiTheme.danger.withAlpha(_combatHpLossAlpha)
                : GameUiTheme.textTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CombatHpRing extends StatelessWidget {
  const _CombatHpRing({
    super.key,
    required this.beforeHp,
    required this.afterHp,
    required this.maxHp,
    required this.killed,
    required this.accent,
    required this.size,
    required this.hpKey,
  });

  final int beforeHp;
  final int afterHp;
  final int maxHp;
  final bool killed;
  final Color accent;
  final double size;
  final Key hpKey;

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = killed ? GameUiTheme.danger : accent;
    final l10n = AppLocalizations.of(context);
    final lostHp = math.max(0, beforeHp - afterHp);
    return Semantics(
      label: l10n.combatPreviewHpAfterSemantics(afterHp, maxHp, lostHp),
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _CombatHpRingPainter(
                beforeHp: beforeHp,
                afterHp: afterHp,
                maxHp: maxHp,
                accent: resolvedAccent,
                trackColor: GameUiTheme.bg.withAlpha(_combatHpTrackAlpha),
                beforeColor: GameUiTheme.goldDark.withAlpha(
                  _combatHpBeforeAlpha,
                ),
                lostColor: GameUiTheme.danger.withAlpha(_combatHpLossAlpha),
                strokeWidth: size < 94 ? 9 : 11,
              ),
            ),
            SizedBox(
              width: size * 0.64,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$afterHp/$maxHp',
                      key: hpKey,
                      style: GameUiTheme.cardTitle.copyWith(
                        color: resolvedAccent,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: GameUiTheme.bg.withAlpha(
                              _combatHpShadowAlpha,
                            ),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      l10n.unitSelectionHpLabel,
                      style: GameUiTheme.labelSmall.copyWith(
                        color: GameUiTheme.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CombatHpRingPainter extends CustomPainter {
  const _CombatHpRingPainter({
    required this.beforeHp,
    required this.afterHp,
    required this.maxHp,
    required this.accent,
    required this.trackColor,
    required this.beforeColor,
    required this.lostColor,
    required this.strokeWidth,
  });

  final int beforeHp;
  final int afterHp;
  final int maxHp;
  final Color accent;
  final Color trackColor;
  final Color beforeColor;
  final Color lostColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final shortestSide = math.min(size.width, size.height);
    final radius = (shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: radius,
    );
    const startAngle = -math.pi / 2;
    const fullSweep = math.pi * 2;
    final beforeFraction = _fraction(beforeHp);
    final afterFraction = _fraction(afterHp);
    final lostFraction = (beforeFraction - afterFraction)
        .clamp(0.0, 1.0)
        .toDouble();

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final beforePaint = Paint()
      ..color = beforeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final afterPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final lostPaint = Paint()
      ..color = lostColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, fullSweep, false, trackPaint);
    if (beforeFraction > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        fullSweep * beforeFraction,
        false,
        beforePaint,
      );
    }
    if (afterFraction > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        fullSweep * afterFraction,
        false,
        afterPaint,
      );
    }
    if (lostFraction > 0) {
      canvas.drawArc(
        rect,
        startAngle + fullSweep * afterFraction,
        fullSweep * lostFraction,
        false,
        lostPaint,
      );
    }
  }

  double _fraction(int hp) {
    if (maxHp <= 0) return 0;
    return (hp.clamp(0, maxHp) / maxHp).clamp(0.0, 1.0).toDouble();
  }

  @override
  bool shouldRepaint(covariant _CombatHpRingPainter oldDelegate) {
    return oldDelegate.beforeHp != beforeHp ||
        oldDelegate.afterHp != afterHp ||
        oldDelegate.maxHp != maxHp ||
        oldDelegate.accent != accent ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.beforeColor != beforeColor ||
        oldDelegate.lostColor != lostColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
