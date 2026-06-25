import 'package:aonw/game/presentation/widgets/hud/hud_victory_status_summary.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:flutter/material.dart';

class VictoryStatusPopup extends StatelessWidget {
  const VictoryStatusPopup({
    required this.status,
    required this.onClose,
    this.maxWidth = 330,
    this.maxHeight = 380,
    this.showDragHandle = false,
    super.key,
  });

  final HudVictoryStatusSummary status;
  final VoidCallback onClose;
  final double maxWidth;
  final double maxHeight;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = status.critical ? GameUiTheme.warning : GameUiTheme.info;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      child: GameModalScaffold(
        showCornerDiamonds: false,
        contentPadding: EdgeInsets.zero,
        centerInAvailableSpace: false,
        scrollable: false,
        content: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDragHandle) ...[
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: ShapeDecoration(
                      color: SurfaceElevation.flat.fill(
                        background: GameUiTheme.copper,
                        alpha: 120,
                      ),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              GameUiEpicHeader(
                label: l10n.gameGoalTitle,
                accent: color,
                alignment: Alignment.centerLeft,
                leading: GameIcon(
                  GameIcons.stats,
                  size: GameIconSize.regular,
                  color: color,
                ),
                trailing: _VictoryPopupIconButton(
                  icon: GameIcons.close,
                  tooltip: l10n.closeAction,
                  onTap: onClose,
                ),
              ),
              const SizedBox(height: 8),
              _VictoryStatusSection(status: status, accent: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _VictoryStatusSection extends StatelessWidget {
  const _VictoryStatusSection({required this.status, required this.accent});

  final HudVictoryStatusSummary status;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: SurfaceElevation.flat.decoration(
        accent: accent,
        background: GameUiTheme.bg,
        backgroundAlpha: 132,
        borderAlpha: 70,
        shape: SurfaceShape.card,
        includeShadow: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.technologyDetailsProgress,
            style: GameUiTheme.sectionHeader.copyWith(color: accent),
          ),
          const SizedBox(height: 6),
          _VictoryInfoRow(label: l10n.commonStatus, value: status.fullLabel),
          if (status.details.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final detail in status.details) ...[
              _VictoryInfoRow(
                label: detail.label,
                value: detail.value,
                accent: detail.highlighted ? accent : null,
              ),
              const SizedBox(height: 5),
            ],
          ],
          const SizedBox(height: 8),
          Text(
            status.tooltip,
            style: GameUiTheme.bodySmall.copyWith(
              color: GameUiTheme.textPrimary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _VictoryInfoRow extends StatelessWidget {
  const _VictoryInfoRow({
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final progress = _VictoryProgress.tryParse(value);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodySmall,
              ),
              if (progress != null) ...[
                const SizedBox(height: 4),
                _VictoryProgressBar(progress: progress, accent: accent),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: GameUiTheme.bodyStrong.copyWith(
                color: accent ?? GameUiTheme.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VictoryProgress {
  const _VictoryProgress({required this.current, required this.target});

  final int current;
  final int target;

  double get factor => target <= 0 ? 0 : (current / target).clamp(0.0, 1.0);

  static _VictoryProgress? tryParse(String value) {
    final match = RegExp(r'(\d+)%\s*/\s*(\d+)%').firstMatch(value);
    if (match == null) return null;
    final current = int.tryParse(match.group(1)!);
    final target = int.tryParse(match.group(2)!);
    if (current == null || target == null || target <= 0) return null;
    return _VictoryProgress(current: current, target: target);
  }
}

class _VictoryProgressBar extends StatelessWidget {
  const _VictoryProgressBar({required this.progress, required this.accent});

  final _VictoryProgress progress;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? GameUiTheme.info;
    return SizedBox(
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: ColoredBox(
          color: GameUiTheme.surfaceDeep.withAlpha(160),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.factor,
              child: ColoredBox(color: color.withAlpha(210)),
            ),
          ),
        ),
      ),
    );
  }
}

class _VictoryPopupIconButton extends StatelessWidget {
  const _VictoryPopupIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final GameIconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: SurfaceElevation.flat.fill(
            background: GameUiTheme.chipSurface,
            alpha: 190,
          ),
          borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
          child: InkWell(
            borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
            onTap: onTap,
            child: SizedBox(
              width: 30,
              height: 30,
              child: Center(
                child: GameIcon(
                  icon,
                  size: GameIconSize.small,
                  color: GameUiTheme.goldLight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
