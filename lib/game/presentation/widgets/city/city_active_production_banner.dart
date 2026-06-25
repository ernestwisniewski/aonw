import 'package:aonw/game/presentation/formatters/turn_eta.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class CityActiveProductionBanner extends StatelessWidget {
  const CityActiveProductionBanner({
    required this.title,
    required this.continuous,
    required this.turnsRemaining,
    required this.totalCost,
    required this.investedProduction,
    required this.progress,
    required this.metaLabels,
    required this.canBeRushed,
    required this.rushGoldCost,
    required this.playerGold,
    required this.onRushProduction,
    this.eta = const TurnEta.blocked(),
    super.key,
  });

  final String title;
  final bool continuous;
  final int? turnsRemaining;
  final TurnEta eta;
  final int totalCost;
  final int investedProduction;
  final double progress;
  final List<String> metaLabels;
  final bool canBeRushed;
  final int rushGoldCost;
  final int playerGold;
  final VoidCallback? onRushProduction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canRushNow =
        canBeRushed && playerGold >= rushGoldCost && onRushProduction != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: SurfaceElevation.flat.fill(background: GameUiTheme.bg, alpha: 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                l10n.productionInProgressLabel,
                style: GameUiTheme.toolbarLabel.copyWith(
                  color: GameUiTheme.gold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.body.copyWith(
                    color: GameUiTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _statusLabel(l10n),
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (continuous) ...[
            const SizedBox(height: 6),
            Text(
              metaLabels.skip(1).join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: SurfaceElevation.flat.fill(
                  background: GameUiTheme.goldDark,
                  alpha: 86,
                ),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  GameUiTheme.gold,
                ),
              ),
            ),
          ],
          if (canBeRushed) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.cityProductionTreasuryGold(playerGold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.bodySmall.copyWith(
                      color: GameUiTheme.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: canRushNow ? onRushProduction : null,
                  icon: GameIcon(
                    GameIcons.lightning,
                    size: GameIconSize.small,
                    color: canRushNow ? GameUiTheme.bg : GameUiTheme.textMuted,
                  ),
                  label: Text(l10n.cityProductionRushAction(rushGoldCost)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    backgroundColor: canRushNow
                        ? SurfaceElevation.flat.fill(
                            background: GameUiTheme.gold,
                            alpha: 220,
                          )
                        : SurfaceElevation.flat.fill(
                            background: Colors.white,
                            alpha: 12,
                          ),
                    foregroundColor: canRushNow
                        ? GameUiTheme.bg
                        : GameUiTheme.textMuted,
                    disabledForegroundColor: GameUiTheme.textMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n) {
    if (continuous) return l10n.cityProductionContinuous;
    if (turnsRemaining == null) {
      return l10n.cityProductionCostShort(totalCost - investedProduction);
    }
    final displayEta = eta.hasTurns
        ? eta
        : TurnEtaFormatter.fromTurns(
            turnsRemaining: turnsRemaining,
            blockedLabel: eta.blockedLabel,
          );
    return displayEta.compactLabel(l10n);
  }
}
