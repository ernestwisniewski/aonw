part of 'end_turn_button.dart';

class _EndTurnActionMenuButton extends StatelessWidget {
  const _EndTurnActionMenuButton({
    required this.compact,
    required this.currentIndex,
    required this.totalCount,
    required this.options,
    required this.foreground,
    required this.accent,
    required this.gradientColors,
    required this.thumbnail,
    required this.width,
    required this.minHeight,
    required this.onActionSelected,
  });

  final bool compact;
  final int currentIndex;
  final int totalCount;
  final List<HudTurnActionOption> options;
  final Color foreground;
  final Color accent;
  final List<Color> gradientColors;
  final HudTurnActionThumbnail? thumbnail;
  final double width;
  final double minHeight;
  final ValueChanged<int> onActionSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('endTurnButton.actionMenu'),
      width: width,
      height: minHeight,
      child: PopupMenuButton<int>(
        tooltip: AppLocalizations.of(context).turnActionListTooltip,
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        offset: const Offset(0, 6),
        color: SurfaceElevation.modal.fill(background: GameUiTheme.surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameUiTheme.radiusButton),
          side: BorderSide(
            color: SurfaceElevation.raised.strokeColor(accent: accent),
            width: 1.2,
          ),
        ),
        onSelected: onActionSelected,
        itemBuilder: _buildMenuItems,
        child: _EndTurnActionMenuSurface(
          compact: compact,
          currentIndex: currentIndex,
          totalCount: totalCount,
          foreground: foreground,
          accent: accent,
          gradientColors: gradientColors,
          thumbnail: thumbnail,
          width: width,
          minHeight: minHeight,
        ),
      ),
    );
  }

  List<PopupMenuEntry<int>> _buildMenuItems(BuildContext context) {
    return [
      for (final option in options)
        CheckedPopupMenuItem<int>(
          key: Key('endTurnButton.actionMenu.item.${option.index}'),
          value: option.index,
          checked: option.index == currentIndex,
          child: _TurnActionMenuItem(option: option),
        ),
    ];
  }
}

class _EndTurnActionMenuSurface extends StatelessWidget {
  const _EndTurnActionMenuSurface({
    required this.compact,
    required this.currentIndex,
    required this.totalCount,
    required this.foreground,
    required this.accent,
    required this.gradientColors,
    required this.thumbnail,
    required this.width,
    required this.minHeight,
  });

  final bool compact;
  final int currentIndex;
  final int totalCount;
  final Color foreground;
  final Color accent;
  final List<Color> gradientColors;
  final HudTurnActionThumbnail? thumbnail;
  final double width;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: GameMotion.snap,
        curve: GameMotion.enter,
        width: width,
        constraints: BoxConstraints(minHeight: minHeight),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(GameHudTheme.buttonRadius),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnail case final thumbnail?) _thumbnailBackdrop(thumbnail),
            _EndTurnActionMenuProgress(
              compact: compact,
              currentIndex: currentIndex,
              totalCount: totalCount,
              foreground: foreground,
              accent: accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailBackdrop(HudTurnActionThumbnail thumbnail) {
    return _EndTurnActionThumbnailBackdrop(
      compact: compact,
      thumbnail: thumbnail,
      foreground: foreground,
      imageSize: _thumbnailImageSize(thumbnail),
      width: _thumbnailFrameWidth(thumbnail),
      height: _thumbnailFrameHeight(thumbnail),
      offset: _thumbnailOffset(thumbnail),
      alignment: _thumbnailAlignment(thumbnail),
      maskStops: _thumbnailMaskStops(thumbnail),
      maskColors: _thumbnailMaskColors(thumbnail),
      coverCity: thumbnail.kind == HudTurnActionThumbnailKind.city,
    );
  }

  double _thumbnailImageSize(HudTurnActionThumbnail thumbnail) =>
      switch (thumbnail.kind) {
        HudTurnActionThumbnailKind.city => minHeight,
        _ => compact ? 54.6 : 65.8,
      };

  double _thumbnailFrameWidth(HudTurnActionThumbnail thumbnail) =>
      switch (thumbnail.kind) {
        HudTurnActionThumbnailKind.city => width + (compact ? 8 : 10),
        _ => width + (compact ? 16 : 20),
      };

  double _thumbnailFrameHeight(HudTurnActionThumbnail thumbnail) =>
      switch (thumbnail.kind) {
        HudTurnActionThumbnailKind.city => minHeight,
        _ => minHeight + (compact ? 14 : 18),
      };

  Offset _thumbnailOffset(HudTurnActionThumbnail thumbnail) =>
      switch (thumbnail.kind) {
        HudTurnActionThumbnailKind.city => Offset.zero,
        _ => Offset(compact ? 8 : 10, compact ? -5 : -7),
      };

  Alignment _thumbnailAlignment(HudTurnActionThumbnail thumbnail) =>
      switch (thumbnail.kind) {
        HudTurnActionThumbnailKind.city => Alignment.centerRight,
        _ => Alignment.topRight,
      };

  List<double> _thumbnailMaskStops(HudTurnActionThumbnail thumbnail) =>
      switch (thumbnail.kind) {
        HudTurnActionThumbnailKind.unit =>
          _EndTurnActionThumbnailBackdrop._unitMaskStops,
        HudTurnActionThumbnailKind.city =>
          _EndTurnActionThumbnailBackdrop._cityMaskStops,
        _ => _EndTurnActionThumbnailBackdrop._defaultMaskStops,
      };

  List<Color> _thumbnailMaskColors(HudTurnActionThumbnail thumbnail) =>
      switch (thumbnail.kind) {
        HudTurnActionThumbnailKind.unit =>
          _EndTurnActionThumbnailBackdrop._unitMaskColors,
        HudTurnActionThumbnailKind.city =>
          _EndTurnActionThumbnailBackdrop._cityMaskColors,
        _ => _EndTurnActionThumbnailBackdrop._defaultMaskColors,
      };
}

class _EndTurnActionMenuProgress extends StatelessWidget {
  const _EndTurnActionMenuProgress({
    required this.compact,
    required this.currentIndex,
    required this.totalCount,
    required this.foreground,
    required this.accent,
  });

  final bool compact;
  final int currentIndex;
  final int totalCount;
  final Color foreground;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final controlForeground = SurfaceElevation.flat.fill(
      background: foreground,
      alpha: 230,
    );
    return Center(
      child: Padding(
        padding: EdgeInsets.only(left: compact ? 4 : 5, right: compact ? 3 : 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${currentIndex + 1}/$totalCount',
                  key: const Key('endTurnButton.actionProgress'),
                  maxLines: 1,
                  style: GameHudTheme.buttonTopLabel.copyWith(
                    color: controlForeground,
                    fontSize: compact ? 8 : 9,
                    height: 1,
                    fontFeatures: GameUiTheme.tabularFigures,
                    shadows: _progressShadows(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            GameIcon(
              GameIcons.chevronDown,
              key: const Key('endTurnButton.actionChevron'),
              size: compact ? 7 : 8,
              color: controlForeground,
            ),
          ],
        ),
      ),
    );
  }

  List<Shadow> _progressShadows() => [
    Shadow(
      color: SurfaceElevation.flat.fill(background: accent, alpha: 230),
      blurRadius: compact ? 5 : 6,
    ),
    Shadow(
      color: SurfaceElevation.flat.fill(background: Colors.black, alpha: 170),
      blurRadius: 3,
      offset: const Offset(0, 0.6),
    ),
  ];
}

class _TurnActionMenuItem extends StatelessWidget {
  const _TurnActionMenuItem({required this.option});

  final HudTurnActionOption option;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180),
      child: Row(
        children: [
          Text(
            '${option.index + 1}.',
            style: GameHudTheme.buttonTopLabel.copyWith(
              color: GameUiTheme.gold,
              fontSize: 10,
              height: 1,
              fontFeatures: GameUiTheme.tabularFigures,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameHudTheme.buttonLabel.copyWith(
                    color: GameUiTheme.textBright,
                    fontSize: 12,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  option.kindLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameHudTheme.buttonTopLabel.copyWith(
                    color: GameUiTheme.textSecondary,
                    fontSize: 9,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
