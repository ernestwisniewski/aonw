import 'dart:async';

import 'package:aonw/game/presentation/widgets/hud/selection/hud_long_press_info_sheet.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

class SelectionCommandChip extends StatefulWidget {
  static const double extent = 48;
  static const double labeledExtent = 136;
  static const double expandedLabeledExtent = 216;
  static const double wideLabeledExtent = 304;
  static const double iconExtent = GameIconSize.large;
  static const double _labeledHorizontalPadding = 24;
  static const double _labeledIconGap = 8;

  final GameIconData icon;
  final String actionId;
  final String label;
  final Color color;
  final bool active;
  final bool enabled;
  final bool prominent;
  final bool pulseBorder;
  final bool showLabel;
  final bool dangerOutlined;
  final double disabledOpacity;
  final String? disabledReason;
  final String? badgeLabel;
  final VoidCallback? onTap;

  const SelectionCommandChip({
    required this.icon,
    required this.label,
    required this.onTap,
    String? actionId,
    this.color = GameUiTheme.gold,
    this.active = false,
    this.enabled = true,
    this.prominent = false,
    this.pulseBorder = false,
    this.showLabel = false,
    this.dangerOutlined = false,
    this.disabledOpacity = 0.42,
    this.disabledReason,
    this.badgeLabel,
    super.key,
  }) : actionId = actionId ?? label;

  double get mainExtent => actionExtentFor(label: label, showLabel: showLabel);

  static double actionExtentFor({
    required String label,
    required bool showLabel,
  }) {
    if (!showLabel) return extent;
    if (label.length > 24) return wideLabeledExtent;
    if (label.length > 14) return expandedLabeledExtent;
    return labeledExtent;
  }

  @override
  State<SelectionCommandChip> createState() => _SelectionCommandChipState();
}

class _SelectionCommandChipState extends State<SelectionCommandChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  bool get _shouldPulse =>
      widget.pulseBorder && widget.enabled && widget.onTap != null;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(SelectionCommandChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _syncPulse() {
    if (_shouldPulse) {
      if (!_pulseController.isAnimating) {
        unawaited(_pulseController.repeat(reverse: true));
      }
      return;
    }
    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
    _pulseController.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canTap = widget.enabled && widget.onTap != null;
    final dangerFill = Color.lerp(
      GameUiTheme.danger,
      GameUiTheme.copper,
      0.18,
    )!;
    final dangerBorder = Color.lerp(
      GameUiTheme.dangerSubtle,
      GameUiTheme.copperDeep,
      0.22,
    )!;
    final accent = widget.dangerOutlined
        ? dangerFill
        : widget.active
        ? GameUiTheme.gold
        : widget.color;
    final foreground = widget.dangerOutlined
        ? Colors.black
        : widget.active
        ? GameUiTheme.bg
        : Color.lerp(accent, Colors.white, 0.22)!;
    final highlighted = widget.active || widget.prominent || widget.pulseBorder;
    final surface = widget.dangerOutlined
        ? SurfaceElevation.raised
        : widget.active
        ? SurfaceElevation.modal
        : widget.prominent || widget.pulseBorder
        ? SurfaceElevation.raised
        : SurfaceElevation.flat;
    final background = widget.dangerOutlined
        ? dangerFill
        : (widget.prominent || widget.pulseBorder) && !widget.active
        ? Color.lerp(GameUiTheme.surface, accent, 0.18)!
        : widget.active
        ? accent
        : null;

    final tooltipMessage = canTap || widget.disabledReason == null
        ? widget.label
        : '${widget.label}: ${widget.disabledReason}';
    final chipWidth = widget.mainExtent;

    return Tooltip(
      message: tooltipMessage,
      triggerMode: TooltipTriggerMode.manual,
      child: Semantics(
        button: true,
        enabled: canTap,
        selected: widget.active,
        label: widget.label,
        hint: canTap ? null : widget.disabledReason,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: canTap ? widget.onTap : null,
          onLongPress: () => showHudLongPressInfoSheet(
            context: context,
            icon: widget.icon,
            title: widget.label,
            body: _descriptionFor(
              l10n: l10n,
              label: widget.label,
              enabled: widget.enabled,
              prominent: widget.prominent || widget.pulseBorder,
              active: widget.active,
              disabledReason: widget.disabledReason,
            ),
            accent: accent,
            actionLabel: canTap ? l10n.commonExecuteAction : null,
            onAction: canTap ? widget.onTap : null,
          ),
          child: AnimatedOpacity(
            opacity: canTap ? 1 : widget.disabledOpacity,
            duration: GameMotion.snap,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulse = _shouldPulse
                    ? Curves.easeInOut.transform(_pulseController.value)
                    : 0.0;
                final borderWidth = widget.dangerOutlined
                    ? widget.active
                          ? 1.8 + pulse * 0.3
                          : 1.6 + pulse * 0.3
                    : widget.active
                    ? 2.0 + pulse * 0.5
                    : widget.pulseBorder
                    ? 1.7 + pulse * 1.0
                    : widget.prominent
                    ? 1.7
                    : 1.2;
                final glowAlpha = widget.dangerOutlined
                    ? 48 + (pulse * 28).round()
                    : widget.active
                    ? 90 + (pulse * 44).round()
                    : widget.pulseBorder
                    ? 78 + (pulse * 60).round()
                    : 78;
                final pulseBackground = widget.dangerOutlined
                    ? Color.lerp(dangerFill, dangerBorder, pulse * 0.14)!
                    : widget.pulseBorder && !widget.active
                    ? Color.lerp(
                        GameUiTheme.surface,
                        accent,
                        0.18 + pulse * 0.08,
                      )!
                    : background;

                return AnimatedContainer(
                  key: Key('selectionInfo.action.${widget.actionId}'),
                  duration: GameMotion.snap,
                  curve: GameMotion.enter,
                  width: chipWidth,
                  height: SelectionCommandChip.extent,
                  decoration: surface.decoration(
                    accent: accent,
                    background: pulseBackground,
                    backgroundAlpha: widget.dangerOutlined ? 245 : null,
                    borderColor: widget.dangerOutlined ? dangerBorder : null,
                    border: highlighted
                        ? BorderEmphasis.active
                        : BorderEmphasis.strong,
                    borderAlpha: widget.dangerOutlined ? 255 : null,
                    borderWidth: borderWidth,
                    glowColor: highlighted && canTap && !widget.dangerOutlined
                        ? accent
                        : null,
                    glowAlpha: glowAlpha,
                    includeShadow: true,
                    shape: SurfaceShape.chip,
                  ),
                  child: child,
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: widget.showLabel
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal:
                                  SelectionCommandChip
                                      ._labeledHorizontalPadding /
                                  2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _commandIcon(
                                  size: GameIconSize.regular,
                                  foreground: foreground,
                                ),
                                const SizedBox(
                                  width: SelectionCommandChip._labeledIconGap,
                                ),
                                Flexible(
                                  child: Text(
                                    _labelText,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.visible,
                                    style: _labelStyle(foreground),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: _commandIcon(
                              size: SelectionCommandChip.iconExtent,
                              foreground: foreground,
                            ),
                          ),
                  ),
                  if (widget.badgeLabel case final badge?)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: _SelectionCommandChipBadge(
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

  TextStyle _labelStyle(Color foreground) {
    return GameUiTheme.actionLabel.copyWith(color: foreground);
  }

  String get _labelText => widget.label;

  Widget _commandIcon({required double size, required Color foreground}) {
    return GameIcon(widget.icon, size: size, color: foreground);
  }
}

class _SelectionCommandChipBadge extends StatelessWidget {
  const _SelectionCommandChipBadge({required this.label, required this.color});

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
        includeShadow: true,
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

String _descriptionFor({
  required AppLocalizations l10n,
  required String label,
  required bool enabled,
  required bool prominent,
  required bool active,
  required String? disabledReason,
}) {
  if (!enabled) {
    return disabledReason == null || disabledReason.isEmpty
        ? l10n.selectionCommandUnavailableDescription(label)
        : disabledReason;
  }
  if (active) {
    return l10n.selectionCommandActiveDescription(label);
  }
  if (prominent) {
    return l10n.selectionCommandProminentDescription(label);
  }
  return l10n.selectionCommandDefaultDescription(label);
}
