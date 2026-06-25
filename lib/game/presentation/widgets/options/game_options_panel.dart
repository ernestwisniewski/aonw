import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/presentation/widgets/options/map_overlay_toggle.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/widgets/map_view_mode_toggle.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_options_panel.dart';
import 'package:flutter/material.dart';

class GameOptionsPanel extends StatelessWidget {
  const GameOptionsPanel({
    required this.width,
    required this.session,
    required this.allowGraphicMode,
    required this.onViewModeChanged,
    required this.displaySettings,
    required this.onToggleTerrain,
    required this.onToggleResources,
    required this.onToggleHeightBadge,
    required this.onToggleCitySites,
    required this.onToggleCityGrowth,
    required this.onToggleHexBorders,
    required this.onToggleHeightWalls,
    required this.autoActionFlowEnabled,
    required this.onAutoActionFlowChanged,
    required this.autoTurnFlowEnabled,
    required this.onAutoTurnFlowChanged,
    required this.followUnitMovementCameraEnabled,
    required this.onFollowUnitMovementCameraChanged,
    required this.followEnemyUnitCameraEnabled,
    required this.onFollowEnemyUnitCameraChanged,
    required this.cinematicCameraEnabled,
    required this.onCinematicCameraChanged,
    this.onHexBorderColorChanged,
    this.onWallTintColorChanged,
    this.onResetHexBorderColor,
    this.onResetWallTintColor,
    this.showDiceRollTest = false,
    this.onToggleDiceRollTest,
    this.onResignMatch,
    required this.resigning,
    super.key,
  });

  final double width;
  final GameSession session;
  final bool allowGraphicMode;
  final ValueChanged<MapViewMode> onViewModeChanged;
  final HexDisplaySettings displaySettings;
  final VoidCallback onToggleTerrain;
  final VoidCallback onToggleResources;
  final VoidCallback onToggleHeightBadge;
  final VoidCallback onToggleCitySites;
  final VoidCallback onToggleCityGrowth;
  final VoidCallback onToggleHexBorders;
  final VoidCallback onToggleHeightWalls;
  final bool autoActionFlowEnabled;
  final ValueChanged<bool> onAutoActionFlowChanged;
  final bool autoTurnFlowEnabled;
  final ValueChanged<bool> onAutoTurnFlowChanged;
  final bool followUnitMovementCameraEnabled;
  final ValueChanged<bool> onFollowUnitMovementCameraChanged;
  final bool followEnemyUnitCameraEnabled;
  final ValueChanged<bool> onFollowEnemyUnitCameraChanged;
  final bool cinematicCameraEnabled;
  final ValueChanged<bool> onCinematicCameraChanged;
  final ValueChanged<Color>? onHexBorderColorChanged;
  final ValueChanged<Color>? onWallTintColorChanged;
  final VoidCallback? onResetHexBorderColor;
  final VoidCallback? onResetWallTintColor;
  final bool showDiceRollTest;
  final VoidCallback? onToggleDiceRollTest;
  final VoidCallback? onResignMatch;
  final bool resigning;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GameUiOptionsPanel(
      width: width,
      children: [
        GameUiVisibilityRow(
          label: GameText.sectionLabel(l10n.gameOptionTerrain),
          value: displaySettings.showTerrain,
          onToggle: onToggleTerrain,
        ),
        const SizedBox(height: 4),
        GameUiVisibilityRow(
          label: GameText.sectionLabel(l10n.gameOptionResources),
          value: displaySettings.showResources,
          onToggle: onToggleResources,
        ),
        const SizedBox(height: 4),
        GameUiVisibilityRow(
          label: GameText.sectionLabel(l10n.gameOptionHeight),
          value: displaySettings.showHeightBadge,
          onToggle: onToggleHeightBadge,
        ),
        const SizedBox(height: 4),
        GameUiVisibilityRow(
          label: GameText.sectionLabel(l10n.gameOptionCitySites),
          value: displaySettings.showCitySites,
          onToggle: onToggleCitySites,
        ),
        if (onToggleDiceRollTest case final toggle?) ...[
          const SizedBox(height: 4),
          GameUiVisibilityRow(
            label: GameText.sectionLabel(l10n.gameOptionDiceTest),
            value: showDiceRollTest,
            onToggle: toggle,
          ),
        ],
        const SizedBox(height: 8),
        const _OptionsSeparator(),
        const SizedBox(height: 8),
        _MapToggleOptionRow(
          rowKey: const Key('gameOptions.autoActionFlowRow'),
          enabledIconKey: const Key('gameOptions.autoActionFlowIcon.on'),
          disabledIconKey: const Key('gameOptions.autoActionFlowIcon.off'),
          label: GameText.sectionLabel(l10n.gameOptionAutoActionFlow),
          enabled: autoActionFlowEnabled,
          onToggle: () => onAutoActionFlowChanged(!autoActionFlowEnabled),
        ),
        const SizedBox(height: 4),
        _MapToggleOptionRow(
          rowKey: const Key('gameOptions.autoTurnFlowRow'),
          enabledIconKey: const Key('gameOptions.autoTurnFlowIcon.on'),
          disabledIconKey: const Key('gameOptions.autoTurnFlowIcon.off'),
          label: GameText.sectionLabel(l10n.gameOptionAutoTurnFlow),
          enabled: autoTurnFlowEnabled,
          onToggle: () => onAutoTurnFlowChanged(!autoTurnFlowEnabled),
        ),
        const SizedBox(height: 4),
        _MapToggleOptionRow(
          rowKey: const Key('gameOptions.followUnitMovementCameraRow'),
          enabledIconKey: const Key(
            'gameOptions.followUnitMovementCameraIcon.on',
          ),
          disabledIconKey: const Key(
            'gameOptions.followUnitMovementCameraIcon.off',
          ),
          label: GameText.sectionLabel(l10n.followUnitMovementCameraLabel),
          enabled: followUnitMovementCameraEnabled,
          onToggle: () => onFollowUnitMovementCameraChanged(
            !followUnitMovementCameraEnabled,
          ),
        ),
        const SizedBox(height: 4),
        _MapToggleOptionRow(
          rowKey: const Key('gameOptions.followEnemyUnitCameraRow'),
          enabledIconKey: const Key('gameOptions.followEnemyUnitCameraIcon.on'),
          disabledIconKey: const Key(
            'gameOptions.followEnemyUnitCameraIcon.off',
          ),
          label: GameText.sectionLabel(l10n.followEnemyUnitCameraLabel),
          enabled: followEnemyUnitCameraEnabled,
          onToggle: () =>
              onFollowEnemyUnitCameraChanged(!followEnemyUnitCameraEnabled),
        ),
        const SizedBox(height: 4),
        _MapToggleOptionRow(
          rowKey: const Key('gameOptions.cinematicCameraRow'),
          enabledIconKey: const Key('gameOptions.cinematicCameraIcon.on'),
          disabledIconKey: const Key('gameOptions.cinematicCameraIcon.off'),
          label: GameText.sectionLabel(l10n.cinematicCameraLabel),
          enabled: cinematicCameraEnabled,
          onToggle: () => onCinematicCameraChanged(!cinematicCameraEnabled),
        ),
        const SizedBox(height: 8),
        const _OptionsSeparator(key: Key('gameOptions.autoTurnSeparator')),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: double.infinity,
            child: MapViewModeToggle(
              value: session.viewMode,
              allowGraphicMode: allowGraphicMode,
              onChanged: onViewModeChanged,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: MapOverlayToggle(
            hexesVisible: displaySettings.hexBordersVisible,
            heightVisible: displaySettings.heightWallsVisible,
            onToggleHexes: onToggleHexBorders,
            onToggleHeight: onToggleHeightWalls,
          ),
        ),
        if (onResignMatch != null) ...[
          const SizedBox(height: 10),
          Divider(color: SurfaceElevation.flat.strokeColor(alpha: 70)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: resigning ? null : onResignMatch,
            style: OutlinedButton.styleFrom(
              foregroundColor: GameUiTheme.danger,
              disabledForegroundColor: SurfaceElevation.flat.fill(
                background: GameUiTheme.textSecondary,
                alpha: 120,
              ),
              side: BorderEmphasis.strong.side(GameUiTheme.danger),
              textStyle: GameUiTheme.labelSmall,
              visualDensity: VisualDensity.compact,
            ),
            icon: resigning
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const GameIcon(
                    GameIcons.flag,
                    size: GameIconSize.small,
                    color: GameUiTheme.danger,
                  ),
            label: Text(GameText.actionLabel(l10n.resignAction)),
          ),
        ],
      ],
    );
  }
}

class _OptionsSeparator extends StatelessWidget {
  const _OptionsSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: SurfaceElevation.flat.strokeColor(
        color: GameUiTheme.gold,
        alpha: 66,
      ),
    );
  }
}

class _MapToggleOptionRow extends StatelessWidget {
  const _MapToggleOptionRow({
    required this.rowKey,
    required this.enabledIconKey,
    required this.disabledIconKey,
    required this.label,
    required this.enabled,
    required this.onToggle,
  });

  final Key rowKey;
  final Key enabledIconKey;
  final Key disabledIconKey;
  final String label;
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = enabled ? GameUiTheme.success : GameUiTheme.danger;
    final background = enabled
        ? GameUiTheme.successSubtle
        : GameUiTheme.dangerSubtle;
    final message = enabled
        ? l10n.visibilityHideAction(label)
        : l10n.visibilityShowAction(label);
    final iconKey = enabled ? enabledIconKey : disabledIconKey;

    return Tooltip(
      message: message,
      child: Semantics(
        button: true,
        toggled: enabled,
        label: label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            key: rowKey,
            decoration: SurfaceElevation.flat.decoration(
              background: background,
              backgroundAlpha: enabled ? 112 : 82,
              borderColor: accent,
              border: enabled ? BorderEmphasis.strong : BorderEmphasis.regular,
              borderWidth: enabled ? 1.2 : 1,
              radius: 8,
              includeShadow: false,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GameUiTheme.labelSmall.copyWith(
                          color: enabled
                              ? GameUiTheme.goldLight
                              : GameUiTheme.gold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GameIcon(
                      enabled ? GameIcons.checkCircle : GameIcons.error,
                      key: iconKey,
                      size: GameIconSize.small,
                      color: accent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
