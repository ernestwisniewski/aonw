import 'package:aonw/game/presentation/widgets/hud/selection/hud_long_press_info_sheet.dart';
import 'package:aonw/game/presentation/widgets/selection/density.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

class SelectionActionChip extends StatelessWidget {
  const SelectionActionChip({
    required this.model,
    required this.active,
    required this.density,
    required this.onTap,
    super.key,
  });

  final SelectionInfoChipViewModel model;
  final bool active;
  final SelectionDensity density;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spec = SelectionDensitySpec.of(density);
    final accent = _toneColor(model.tone);
    final foreground = active ? GameUiTheme.bg : accent;
    final surface = active ? SurfaceElevation.modal : SurfaceElevation.flat;

    return Tooltip(
      message: model.label,
      triggerMode: TooltipTriggerMode.manual,
      child: Semantics(
        button: true,
        enabled: model.enabled,
        selected: active,
        label: model.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: model.enabled ? onTap : null,
          onLongPress: () => showHudLongPressInfoSheet(
            context: context,
            icon: model.icon,
            title: model.label,
            body: _descriptionFor(l10n, model),
            accent: accent,
            actionLabel: model.enabled ? l10n.commonOpenAction : null,
            onAction: model.enabled ? onTap : null,
          ),
          child: AnimatedOpacity(
            opacity: model.enabled ? 1 : 0.44,
            duration: GameMotion.snap,
            child: AnimatedContainer(
              key: Key('selectionInfo.chip.${model.id}'),
              duration: GameMotion.snap,
              curve: GameMotion.enter,
              width: spec.actionChipSize,
              height: spec.actionChipSize,
              decoration: surface.decoration(
                accent: accent,
                background: active ? accent : null,
                border: active ? BorderEmphasis.active : BorderEmphasis.strong,
                borderWidth: active ? 2 : 1.2,
                glowColor: active ? accent : null,
                shape: SurfaceShape.chip,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: GameIcon(
                      model.icon,
                      color: foreground,
                      size: spec.iconSize,
                    ),
                  ),
                  if (model.badge case final badge?)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: _SelectionActionChipBadge(
                        label: badge,
                        color: accent,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _descriptionFor(
  AppLocalizations l10n,
  SelectionInfoChipViewModel model,
) {
  final badge = model.badge == null
      ? ''
      : l10n.selectionChipBadgeSuffix(model.badge!);
  if (!model.enabled) {
    return '${l10n.selectionInfoChipDisabledDescription}$badge';
  }
  return '${l10n.selectionInfoChipOpenDescription(model.label)}$badge';
}

class _SelectionActionChipBadge extends StatelessWidget {
  const _SelectionActionChipBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.modal.decoration(
        background: color,
        borderColor: GameUiTheme.bg,
        border: BorderEmphasis.active,
        shape: SurfaceShape.pill,
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            color: GameUiTheme.bg,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontFeatures: GameUiTheme.tabularFigures,
          ),
        ),
      ),
    );
  }
}

Color _toneColor(SelectionInfoChipTone tone) {
  return switch (tone) {
    SelectionInfoChipTone.neutral => GameHudTheme.textMuted,
    SelectionInfoChipTone.accent => GameUiTheme.gold,
    SelectionInfoChipTone.warning => GameHudTheme.colorWarning,
  };
}
