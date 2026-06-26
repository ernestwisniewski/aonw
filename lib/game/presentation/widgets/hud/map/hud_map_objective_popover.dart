part of 'hud_map_inspection_menu.dart';

class _ObjectiveInspectionPopover extends StatelessWidget {
  const _ObjectiveInspectionPopover({
    required this.progress,
    required this.onClose,
    required this.arrowOnLeft,
    required this.arrowTop,
    required this.maxHeight,
  });

  final MapObjectiveProgress progress;
  final VoidCallback onClose;
  final bool arrowOnLeft;
  final double arrowTop;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('hudMapInspectionMenu.objectivePopover'),
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: arrowOnLeft ? -5 : null,
            right: arrowOnLeft ? null : -5,
            top: arrowTop,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: ShapeDecoration(
                  color: SurfaceElevation.raised.fill(
                    background: GameUiTheme.surfaceDeep,
                    alpha: 244,
                  ),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: SurfaceElevation.raised.strokeColor(
                        color: GameUiTheme.gold,
                        alpha: 145,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    SurfaceElevation.raised.fill(
                      background: GameUiTheme.surfaceDeep,
                      alpha: 246,
                    ),
                    SurfaceElevation.raised.fill(
                      background: GameUiTheme.bg,
                      alpha: 238,
                    ),
                  ],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: SurfaceElevation.raised.strokeColor(
                      color: GameUiTheme.gold,
                      alpha: 168,
                    ),
                  ),
                ),
                shadows: SurfaceElevation.raised.shadows(alpha: 130),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ObjectiveHeader(progress: progress, onClose: onClose),
                      const SizedBox(height: 10),
                      _MapObjectiveInspectionSection(progress: progress),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectiveHeader extends StatelessWidget {
  const _ObjectiveHeader({required this.progress, required this.onClose});

  final MapObjectiveProgress progress;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final definition = progress.definition;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: ShapeDecoration(
            color: SurfaceElevation.flat.fill(
              background: GameUiTheme.gold,
              alpha: 42,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: SurfaceElevation.flat.strokeColor(
                  color: GameUiTheme.gold,
                  alpha: 170,
                ),
              ),
            ),
          ),
          child: const Center(
            child: GameIcon(
              GameIcons.victory,
              size: 20,
              color: GameUiTheme.goldLight,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GameDisplayNames.mapObjective(l10n, definition.type),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GameHudTheme.selectionTitle.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.mapInspectionObjectiveTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameHudTheme.selectionSubtitle.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          key: const Key('hudMapInspectionMenu.objective.close'),
          tooltip: l10n.closeAction,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          onPressed: onClose,
          icon: const GameIcon(
            GameIcons.close,
            size: 15,
            color: GameUiTheme.textMuted,
          ),
        ),
      ],
    );
  }
}
