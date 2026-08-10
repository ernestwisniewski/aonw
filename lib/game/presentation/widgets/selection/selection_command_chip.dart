import 'dart:async';

import 'package:aonw/game/presentation/widgets/hud/selection/hud_long_press_info_sheet.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

part 'selection_command_chip_style.dart';
part 'selection_command_chip_surface.dart';

class SelectionCommandChip extends StatefulWidget {
  static const double extent = 48;
  static const double labeledExtent = 136;
  static const double expandedLabeledExtent = 216;
  static const double wideLabeledExtent = 304;
  static const double iconExtent = GameIconSize.large;
  static const double _labeledHorizontalPadding = 24;
  static const double _labeledIconGap = 8;

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
    if (_pulseController.isAnimating) _pulseController.stop();
    _pulseController.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canTap = widget.enabled && widget.onTap != null;
    final style = _SelectionCommandChipStyle.resolve(widget);
    return Tooltip(
      message: _tooltipMessage(canTap),
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
          onLongPress: () => _showInfo(l10n, style.accent, canTap),
          child: _SelectionCommandChipSurface(
            widget: widget,
            style: style,
            canTap: canTap,
            shouldPulse: _shouldPulse,
            pulseAnimation: _pulseController,
          ),
        ),
      ),
    );
  }

  String _tooltipMessage(bool canTap) {
    if (canTap || widget.disabledReason == null) return widget.label;
    return '${widget.label}: ${widget.disabledReason}';
  }

  void _showInfo(AppLocalizations l10n, Color accent, bool canTap) {
    unawaited(
      showHudLongPressInfoSheet(
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
  if (active) return l10n.selectionCommandActiveDescription(label);
  if (prominent) return l10n.selectionCommandProminentDescription(label);
  return l10n.selectionCommandDefaultDescription(label);
}
