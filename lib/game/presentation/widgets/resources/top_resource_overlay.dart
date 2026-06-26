import 'package:aonw/game/presentation/widgets/hud/outcome/hud_victory_status_summary.dart';
import 'package:aonw/game/presentation/widgets/resources/resource_breakdown_popup.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_strip.dart';
import 'package:aonw/game/presentation/widgets/resources/victory_status_popup.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';

class TopResourceOverlay extends StatelessWidget {
  const TopResourceOverlay({
    required this.gold,
    required this.goldPerTurn,
    required this.goldIncome,
    required this.unitUpkeep,
    required this.sciencePerTurn,
    required this.resourceInventory,
    required this.openBreakdown,
    required this.goldBreakdown,
    required this.scienceBreakdown,
    required this.cities,
    required this.activeTechnologyName,
    required this.activeTechnologyTurnsRemaining,
    required this.l10n,
    required this.onGoldPressed,
    required this.onSciencePressed,
    required this.onResourcesPressed,
    required this.onVictoryPressed,
    required this.onCloseBreakdown,
    this.victoryStatus,
    this.playerName,
    this.playerColor,
    this.turnNumber,
    this.onTurnPressed,
    this.activeTechnologyCompletionTurn,
    this.resourceNetwork = EmpireResourceNetwork.empty,
    super.key,
  });

  final int gold;
  final int goldPerTurn;
  final int goldIncome;
  final int unitUpkeep;
  final int sciencePerTurn;
  final CityResourceInventory resourceInventory;
  final EmpireResourceNetwork resourceNetwork;
  final TopResourcePopupType? openBreakdown;
  final GoldBreakdown goldBreakdown;
  final ScienceYieldBreakdown scienceBreakdown;
  final List<GameCity> cities;
  final String? activeTechnologyName;
  final int? activeTechnologyTurnsRemaining;
  final int? activeTechnologyCompletionTurn;
  final AppLocalizations l10n;
  final VoidCallback onGoldPressed;
  final VoidCallback onSciencePressed;
  final VoidCallback onResourcesPressed;
  final VoidCallback onVictoryPressed;
  final VoidCallback onCloseBreakdown;
  final HudVictoryStatusSummary? victoryStatus;
  final String? playerName;
  final Color? playerColor;
  final int? turnNumber;
  final VoidCallback? onTurnPressed;

  @override
  Widget build(BuildContext context) {
    final mobileBottomSheet = _usesMobileBottomSheet(context);
    final showOpenPopup =
        openBreakdown != null &&
        (openBreakdown != TopResourcePopupType.victory ||
            victoryStatus != null);
    return Stack(
      children: [
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(64, 10, 12, 0),
              child: SizedBox(
                width: double.infinity,
                child: TopResourceStrip(
                  gold: gold,
                  goldPerTurn: goldPerTurn,
                  goldIncome: goldIncome,
                  unitUpkeep: unitUpkeep,
                  sciencePerTurn: sciencePerTurn,
                  resourceTotal: resourceInventory.totalCount,
                  resourceTypes: resourceInventory.distinctTypeCount,
                  openBreakdown: openBreakdown,
                  victoryStatus: victoryStatus,
                  playerName: playerName,
                  playerColor: playerColor,
                  turnNumber: turnNumber,
                  onTurnPressed: onTurnPressed,
                  onGoldPressed: onGoldPressed,
                  onSciencePressed: onSciencePressed,
                  onResourcesPressed: onResourcesPressed,
                  onVictoryPressed: onVictoryPressed,
                ),
              ),
            ),
          ),
        ),
        if (showOpenPopup)
          mobileBottomSheet
              ? _buildBottomSheetOverlay()
              : _buildPopoverOverlay(),
      ],
    );
  }

  bool _usesMobileBottomSheet(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width < 520 && size.height >= size.width;
  }

  Widget _buildPopoverOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            top: 48,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onCloseBreakdown,
              child: const SizedBox.expand(
                key: Key('gameHud.resourceBreakdown.backdrop'),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 50, 12, 0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: _breakdownPopup(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onCloseBreakdown,
            child: const SizedBox.expand(
              key: Key('gameHud.resourceBreakdown.backdrop'),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final sheetWidth = constraints.maxWidth < 540
                  ? constraints.maxWidth - 20
                  : 520.0;
              final sheetHeight = constraints.maxHeight * 0.72;

              return SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: _SwipeDismissibleResourceBreakdownSheet(
                      onDismiss: onCloseBreakdown,
                      child: SizedBox(
                        key: Key(
                          'gameHud.resourceBreakdownSheet.${_activePopupName()}',
                        ),
                        width: sheetWidth,
                        child: _breakdownPopup(
                          maxWidth: sheetWidth,
                          maxHeight: sheetHeight,
                          showDragHandle: true,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _breakdownPopup({
    double maxWidth = 330,
    double maxHeight = 380,
    bool showDragHandle = false,
  }) {
    final activePopup = openBreakdown!;
    if (activePopup == TopResourcePopupType.victory) {
      return VictoryStatusPopup(
        key: const Key('gameHud.resourceBreakdown.victory'),
        status: victoryStatus!,
        onClose: onCloseBreakdown,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        showDragHandle: showDragHandle,
      );
    }

    final resourceType = activePopup.resourceType!;
    return ResourceBreakdownPopup(
      key: Key('gameHud.resourceBreakdown.${resourceType.name}'),
      type: resourceType,
      gold: goldBreakdown,
      science: scienceBreakdown,
      resources: resourceInventory,
      resourceNetwork: resourceNetwork,
      cities: cities,
      activeTechnologyName: activeTechnologyName,
      activeTechnologyTurnsRemaining: activeTechnologyTurnsRemaining,
      activeTechnologyCompletionTurn: activeTechnologyCompletionTurn,
      l10n: l10n,
      onClose: onCloseBreakdown,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      showDragHandle: showDragHandle,
    );
  }

  String _activePopupName() {
    final popup = openBreakdown!;
    return popup == TopResourcePopupType.victory
        ? popup.name
        : popup.resourceType!.name;
  }
}

class _SwipeDismissibleResourceBreakdownSheet extends StatefulWidget {
  const _SwipeDismissibleResourceBreakdownSheet({
    required this.onDismiss,
    required this.child,
  });

  final VoidCallback onDismiss;
  final Widget child;

  @override
  State<_SwipeDismissibleResourceBreakdownSheet> createState() =>
      _SwipeDismissibleResourceBreakdownSheetState();
}

class _SwipeDismissibleResourceBreakdownSheetState
    extends State<_SwipeDismissibleResourceBreakdownSheet> {
  double _dragOffset = 0;
  double? _dragStartY;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _dragStartY = event.position.dy;
        setState(() => _dragOffset = 0);
      },
      onPointerMove: (event) {
        final startY = _dragStartY;
        if (startY == null) return;
        final offset = event.position.dy - startY;
        if (offset <= 0 && _dragOffset == 0) return;
        setState(() => _dragOffset = offset.clamp(0.0, 72.0).toDouble());
      },
      onPointerUp: (_) => _endDrag(),
      onPointerCancel: (_) => _endDrag(),
      child: AnimatedSlide(
        duration: GameMotion.snap,
        curve: GameMotion.enter,
        offset: Offset(0, _dragOffset / 420),
        child: widget.child,
      ),
    );
  }

  void _endDrag() {
    final shouldDismiss = _dragOffset > 48;
    _dragStartY = null;
    if (mounted) {
      setState(() => _dragOffset = 0);
    }
    if (shouldDismiss) widget.onDismiss();
  }
}
