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
    this.strategicResourceLabel,
    this.spawnBlocked = false,
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
  final String? strategicResourceLabel;
  final bool spawnBlocked;
  final bool canBeRushed;
  final int rushGoldCost;
  final int playerGold;
  final VoidCallback? onRushProduction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: SurfaceElevation.flat.fill(background: GameUiTheme.bg, alpha: 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ProductionHeader(title: title, status: _statusLabel(l10n)),
          if (continuous)
            _ContinuousProductionMeta(metaLabels: metaLabels)
          else
            _FiniteProductionDetails(
              progress: progress,
              metaLabels: metaLabels,
              strategicResourceLabel: strategicResourceLabel,
              spawnBlocked: spawnBlocked,
            ),
          if (canBeRushed)
            _RushProductionSection(
              canRushNow: _canRushNow,
              rushGoldCost: rushGoldCost,
              playerGold: playerGold,
              onRushProduction: onRushProduction,
            ),
        ],
      ),
    );
  }

  bool get _canRushNow =>
      canBeRushed && playerGold >= rushGoldCost && onRushProduction != null;

  String _statusLabel(AppLocalizations l10n) {
    if (continuous) return l10n.cityProductionContinuous;
    if (spawnBlocked) return l10n.cityProductionSpawnBlockedStatus;
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

class _ProductionHeader extends StatelessWidget {
  const _ProductionHeader({required this.title, required this.status});

  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Text(
          l10n.productionInProgressLabel,
          style: GameUiTheme.toolbarLabel.copyWith(color: GameUiTheme.gold),
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
          status,
          style: GameUiTheme.bodySmall.copyWith(
            color: GameUiTheme.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ContinuousProductionMeta extends StatelessWidget {
  const _ContinuousProductionMeta({required this.metaLabels});

  final List<String> metaLabels;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      metaLabels.skip(1).join(' • '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GameUiTheme.bodySmall.copyWith(
        color: GameUiTheme.textMuted,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _FiniteProductionDetails extends StatelessWidget {
  const _FiniteProductionDetails({
    required this.progress,
    required this.metaLabels,
    required this.strategicResourceLabel,
    required this.spawnBlocked,
  });

  final double progress;
  final List<String> metaLabels;
  final String? strategicResourceLabel;
  final bool spawnBlocked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            valueColor: const AlwaysStoppedAnimation<Color>(GameUiTheme.gold),
          ),
        ),
        if (metaLabels.isNotEmpty) _ProductionMetaLabels(labels: metaLabels),
        if (strategicResourceLabel case final label?)
          _StrategicResourceAllocation(label: label),
        if (spawnBlocked)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              l10n.cityProductionSpawnBlockedDescription,
              key: const Key('cityProduction.spawnBlocked'),
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductionMetaLabels extends StatelessWidget {
  const _ProductionMetaLabels({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Text(
      labels.join(' • '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GameUiTheme.bodySmall.copyWith(
        color: GameUiTheme.textMuted,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _StrategicResourceAllocation extends StatelessWidget {
  const _StrategicResourceAllocation({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Text(
      label,
      style: GameUiTheme.bodySmall.copyWith(
        color: GameUiTheme.goldLight,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _RushProductionSection extends StatelessWidget {
  const _RushProductionSection({
    required this.canRushNow,
    required this.rushGoldCost,
    required this.playerGold,
    required this.onRushProduction,
  });

  final bool canRushNow;
  final int rushGoldCost;
  final int playerGold;
  final VoidCallback? onRushProduction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!canRushNow && onRushProduction != null) ...[
            Text(
              l10n.cityProductionRushMissingGold(rushGoldCost - playerGold),
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
          ],
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
              _RushProductionButton(
                canRushNow: canRushNow,
                rushGoldCost: rushGoldCost,
                onPressed: onRushProduction,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RushProductionButton extends StatelessWidget {
  const _RushProductionButton({
    required this.canRushNow,
    required this.rushGoldCost,
    required this.onPressed,
  });

  final bool canRushNow;
  final int rushGoldCost;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextButton.icon(
      onPressed: canRushNow ? onPressed : null,
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
            : SurfaceElevation.flat.fill(background: Colors.white, alpha: 12),
        foregroundColor: canRushNow ? GameUiTheme.bg : GameUiTheme.textMuted,
        disabledForegroundColor: GameUiTheme.textMuted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}
