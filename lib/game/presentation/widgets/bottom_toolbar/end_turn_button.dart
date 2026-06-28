import 'dart:async';

import 'package:aonw/game/presentation/widgets/hud/turn/turn_action_hint.dart';
import 'package:aonw/game/presentation/widgets/hud/turn/turn_hint_objective_matcher.dart';
import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmark_targets.dart';
import 'package:aonw/game/presentation/widgets/theme/city_sprite_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/technology_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_sprite_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_type_icon.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'end_turn_button_content.dart';
part 'end_turn_button_painter.dart';
part 'end_turn_button_visuals.dart';

/// One-shot fingerprint of the visual state. Drives both the visuals (icon,
/// label, colors) and the haptics decision in [didUpdateWidget].
enum _EndTurnButtonMode { waiting, ready, action }

class EndTurnButton extends StatefulWidget {
  static const double actionSegmentWidthCompact = 42;
  static const double actionSegmentWidthNormal = 50;

  final Color playerColor;
  final int turn;
  final bool waiting;
  final bool readyToEndTurn;
  final int actionCount;
  final int currentActionIndex;
  final List<HudTurnActionOption> actionOptions;
  final bool submitMode;
  final String waitingForLabel;
  final String? actionHintLabel;
  final bool compact;
  final bool showTurnLabel;
  final double? minHeight;
  final bool showActionMenu;
  final bool pulseActionBorder;
  final ValueChanged<int>? onActionSelected;
  final VoidCallback onTap;

  const EndTurnButton({
    required this.playerColor,
    required this.turn,
    required this.waiting,
    required this.readyToEndTurn,
    this.actionCount = 0,
    this.currentActionIndex = -1,
    this.actionOptions = const [],
    this.submitMode = false,
    this.waitingForLabel = '',
    this.actionHintLabel,
    required this.compact,
    this.showTurnLabel = true,
    this.minHeight,
    this.showActionMenu = false,
    this.pulseActionBorder = false,
    this.onActionSelected,
    required this.onTap,
    super.key,
  });

  static double preferredWidth({
    required bool compact,
    bool includeActionSegment = false,
    bool includeAutoSegment = false,
  }) {
    final base = compact
        ? GameHudTheme.endTurnButtonWidthCompact
        : GameHudTheme.endTurnButtonWidthNormal;
    final includeSegment = includeActionSegment || includeAutoSegment;
    if (!includeSegment) return base;
    return base +
        (compact ? actionSegmentWidthCompact : actionSegmentWidthNormal);
  }

  @override
  State<EndTurnButton> createState() => _EndTurnButtonState();
}

class _EndTurnButtonState extends State<EndTurnButton>
    with SingleTickerProviderStateMixin {
  static const Duration _stateTransitionDuration = GameMotion.scene;
  static const Duration _borderPulseDuration = Duration(milliseconds: 1100);

  late final AnimationController _borderPulseController;

  @override
  void initState() {
    super.initState();
    _borderPulseController = AnimationController(
      vsync: this,
      duration: _borderPulseDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBorderPulse();
  }

  @override
  void didUpdateWidget(covariant EndTurnButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newMode = _modeFor(widget);
    final oldMode = _modeFor(oldWidget);
    if (newMode != oldMode) {
      _maybeFireHaptics(from: oldMode, to: newMode);
    }
    _syncBorderPulse();
  }

  @override
  void dispose() {
    _borderPulseController.dispose();
    super.dispose();
  }

  _EndTurnButtonMode _modeFor(EndTurnButton w) {
    if (w.waiting) return _EndTurnButtonMode.waiting;
    if (w.readyToEndTurn) return _EndTurnButtonMode.ready;
    return _EndTurnButtonMode.action;
  }

  void _maybeFireHaptics({
    required _EndTurnButtonMode from,
    required _EndTurnButtonMode to,
  }) {
    // Reduce-motion users typically also opt out of incidental haptics.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
    switch (to) {
      case _EndTurnButtonMode.ready:
        unawaited(HapticFeedback.mediumImpact());
      case _EndTurnButtonMode.action:
        if (from == _EndTurnButtonMode.waiting) {
          unawaited(HapticFeedback.selectionClick());
        }
      case _EndTurnButtonMode.waiting:
        // Entering "waiting" is passive (server processed our submit) and
        // does not deserve a buzz on every multiplayer turn boundary.
        break;
    }
  }

  void _syncBorderPulse() {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldPulse =
        widget.pulseActionBorder &&
        !disableAnimations &&
        _modeFor(widget) == _EndTurnButtonMode.action;
    if (shouldPulse) {
      if (!_borderPulseController.isAnimating) {
        unawaited(_borderPulseController.repeat(reverse: true));
      }
    } else {
      if (_borderPulseController.isAnimating) {
        _borderPulseController.stop();
      }
      if (_borderPulseController.value != 0) {
        _borderPulseController.value = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mode = _modeFor(widget);

    final visual = _EndTurnVisuals.forMode(mode, l10n);
    final minHeight =
        widget.minHeight ??
        (widget.compact
            ? GameHudTheme.buttonHeightCompact
            : GameHudTheme.buttonHeightNormal);
    final actionCount = widget.actionCount < 0 ? 0 : widget.actionCount;
    final actionHintLabel = _normalizedHintLabel(widget.actionHintLabel);
    final actionTotal = widget.actionOptions.isNotEmpty
        ? widget.actionOptions.length
        : actionCount;
    final currentActionIndex =
        widget.currentActionIndex >= 0 &&
            widget.currentActionIndex < actionTotal
        ? widget.currentActionIndex
        : 0;
    final tooltipLabel = widget.waiting
        ? widget.waitingForLabel.isEmpty
              ? l10n.waitingForPlayersTooltip
              : widget.waitingForLabel
        : widget.readyToEndTurn
        ? widget.submitMode
              ? l10n.submitTurnTooltip(widget.turn)
              : l10n.endTurnTooltip(widget.turn)
        : _actionTooltipLabel(l10n, actionCount, actionHintLabel);
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final transitionDuration = disableAnimations
        ? Duration.zero
        : _stateTransitionDuration;
    final isAction = mode == _EndTurnButtonMode.action;
    final objectiveLinked = isAction && _isObjectiveHint(l10n, actionHintLabel);
    final canShowActionMenu =
        widget.showActionMenu &&
        widget.onActionSelected != null &&
        !widget.waiting &&
        isAction &&
        widget.actionOptions.isNotEmpty &&
        actionTotal > 0;
    final actionSegmentWidth = widget.compact
        ? EndTurnButton.actionSegmentWidthCompact
        : EndTurnButton.actionSegmentWidthNormal;
    final totalWidth = EndTurnButton.preferredWidth(
      compact: widget.compact,
      includeActionSegment: canShowActionMenu,
    );
    final mainSegmentWidth = canShowActionMenu
        ? totalWidth - actionSegmentWidth
        : totalWidth;
    final previewActionIndex = _actionPreviewIndex(
      actionTotal: widget.actionOptions.length,
      currentActionIndex: widget.currentActionIndex,
    );
    final previewActionOption = isAction && previewActionIndex != -1
        ? widget.actionOptions[previewActionIndex]
        : null;
    final mainBorderRadius = BorderRadius.horizontal(
      left: const Radius.circular(GameHudTheme.buttonRadius),
      right: Radius.circular(canShowActionMenu ? 0 : GameHudTheme.buttonRadius),
    );
    const joinedBorderRadius = BorderRadius.all(
      Radius.circular(GameHudTheme.buttonRadius),
    );
    final button = AnimatedContainer(
      duration: transitionDuration,
      curve: GameMotion.stateChange,
      width: mainSegmentWidth,
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: visual.gradientColors,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: mainBorderRadius,
          side: canShowActionMenu
              ? BorderSide.none
              : BorderSide(color: visual.borderColor, width: 1.4),
        ),
        shadows: widget.waiting
            ? null
            : SurfaceElevation.modal.shadows(
                glowColor: visual.glowColor,
                glowAlpha: GameHudTheme.actionActiveShadowAlpha,
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: minHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!canShowActionMenu)
              if (previewActionOption?.thumbnail case final thumbnail?)
                _EndTurnActionThumbnailBackdrop(
                  compact: widget.compact,
                  thumbnail: thumbnail,
                  foreground: visual.foreground,
                ),
            _EndTurnContent(
              compact: widget.compact,
              turn: widget.turn,
              label: visual.label,
              actionCount: 0,
              objectiveLinked: objectiveLinked,
              icon: visual.icon,
              foreground: visual.foreground,
              showTurnLabel: widget.showTurnLabel,
              transitionDuration: transitionDuration,
            ),
          ],
        ),
      ),
    );

    return KeyedSubtree(
      key: FirstTurnCoachmarkTargets.endTurn,
      child: AnimatedOpacity(
        duration: transitionDuration,
        curve: GameMotion.stateChange,
        opacity: widget.waiting ? 0.62 : 1,
        child: canShowActionMenu
            ? _borderedButton(
                borderRadius: joinedBorderRadius,
                staticColor: visual.borderColor,
                pulseColor: visual.glowColor,
                pulse: widget.pulseActionBorder,
                child: SizedBox(
                  width: totalWidth,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _EndTurnMainSegment(
                        tooltipLabel: tooltipLabel,
                        waiting: widget.waiting,
                        onTap: widget.onTap,
                        child: button,
                      ),
                      _EndTurnActionMenuButton(
                        compact: widget.compact,
                        currentIndex: currentActionIndex,
                        totalCount: actionTotal,
                        options: widget.actionOptions,
                        foreground: visual.foreground,
                        accent: visual.glowColor,
                        gradientColors: visual.gradientColors,
                        thumbnail: previewActionOption?.thumbnail,
                        width: actionSegmentWidth,
                        minHeight: minHeight,
                        onActionSelected: widget.onActionSelected!,
                      ),
                    ],
                  ),
                ),
              )
            : _EndTurnMainSegment(
                tooltipLabel: tooltipLabel,
                waiting: widget.waiting,
                onTap: widget.onTap,
                child: button,
              ),
      ),
    );
  }

  Widget _borderedButton({
    required Widget child,
    required BorderRadius borderRadius,
    required Color staticColor,
    required Color pulseColor,
    required bool pulse,
  }) {
    if (pulse && _borderPulseController.isAnimating) {
      return AnimatedBuilder(
        key: const Key('endTurnButton.animatedActionBorder'),
        animation: _borderPulseController,
        builder: (context, child) => CustomPaint(
          foregroundPainter: EndTurnPulsingBorderPainter(
            progress: _borderPulseController.value,
            borderRadius: borderRadius,
            color: pulseColor,
          ),
          child: child,
        ),
        child: child,
      );
    }

    return CustomPaint(
      foregroundPainter: _StaticBorderPainter(
        borderRadius: borderRadius,
        color: staticColor,
      ),
      child: child,
    );
  }

  static String? _normalizedHintLabel(String? label) {
    final normalized = label?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  static String _actionTooltipLabel(
    AppLocalizations l10n,
    int actionCount,
    String? actionHintLabel,
  ) {
    final fallback = actionCount > 0
        ? l10n.nextActionWithCountTooltip(actionCount)
        : l10n.nextActionTooltip;
    if (actionHintLabel == null) return fallback;
    return '$actionHintLabel\n$fallback';
  }

  static bool _isObjectiveHint(AppLocalizations l10n, String? label) =>
      hudTurnHintIsObjective(l10n, label);

  static int _actionPreviewIndex({
    required int actionTotal,
    required int currentActionIndex,
  }) {
    if (actionTotal <= 0) return -1;
    if (actionTotal == 1) return currentActionIndex == 0 ? -1 : 0;
    if (currentActionIndex < 0 || currentActionIndex >= actionTotal) return 0;
    return (currentActionIndex + 1) % actionTotal;
  }
}
