part of 'end_turn_button.dart';

class _EndTurnActionThumbnailBackdrop extends StatelessWidget {
  static const _defaultMaskStops = [0.0, 0.05, 0.14, 0.28, 0.48, 1.0];
  static const _defaultMaskColors = [
    Colors.transparent,
    Color(0x30FFFFFF),
    Color(0x90FFFFFF),
    Color(0xC8FFFFFF),
    Color(0xD9FFFFFF),
    Color(0xD9FFFFFF),
  ];
  static const _unitMaskStops = [0.0, 0.18, 0.42, 0.66, 0.86, 1.0];
  static const _unitMaskColors = [
    Colors.transparent,
    Color(0x04FFFFFF),
    Color(0x1CFFFFFF),
    Color(0x68FFFFFF),
    Color(0xB8FFFFFF),
    Color(0xD9FFFFFF),
  ];
  static const _cityMaskStops = [0.0, 0.22, 0.48, 0.72, 0.9, 1.0];
  static const _cityMaskColors = [
    Colors.transparent,
    Color(0x08FFFFFF),
    Color(0x30FFFFFF),
    Color(0x88FFFFFF),
    Color(0xC8FFFFFF),
    Color(0xD9FFFFFF),
  ];

  const _EndTurnActionThumbnailBackdrop({
    required this.compact,
    required this.thumbnail,
    required this.foreground,
    this.imageSize,
    this.width,
    this.height,
    this.offset,
    this.alignment = Alignment.centerRight,
    this.maskStops = _defaultMaskStops,
    this.maskColors = _defaultMaskColors,
    this.coverCity = false,
  });

  final bool compact;
  final HudTurnActionThumbnail thumbnail;
  final Color foreground;
  final double? imageSize;
  final double? width;
  final double? height;
  final Offset? offset;
  final Alignment alignment;
  final List<double> maskStops;
  final List<Color> maskColors;
  final bool coverCity;

  @override
  Widget build(BuildContext context) {
    final imageSize = this.imageSize ?? (compact ? 58.0 : 70.0);
    final frameWidth = width ?? imageSize + 24;
    final frameHeight = height ?? imageSize + 14;
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.centerRight,
          child: Transform.translate(
            offset: offset ?? Offset(compact ? 8 : 10, 0),
            child: SizedBox(
              width: frameWidth,
              height: frameHeight,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: maskStops,
                    colors: maskColors,
                  ).createShader(bounds);
                },
                child: Align(
                  alignment: alignment,
                  child: _thumbnailFor(
                    imageSize,
                    frameSize: Size(frameWidth, frameHeight),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbnailFor(double size, {required Size frameSize}) {
    return switch (thumbnail.kind) {
      HudTurnActionThumbnailKind.unit => _unitThumbnailFor(size),
      HudTurnActionThumbnailKind.city => CitySpriteIcon(
        key: const Key('endTurnButton.actionThumbnail.city'),
        visualLevel: thumbnail.cityVisualLevel ?? 0,
        technologyProfileIndex: thumbnail.cityTechnologyProfileIndex ?? 0,
        size: size * 1.04,
        width: coverCity ? frameSize.width : null,
        height: coverCity ? frameSize.height : null,
        fit: coverCity ? BoxFit.cover : BoxFit.contain,
        alignment: coverCity ? Alignment.centerRight : Alignment.center,
        fallback: GameIcon(
          GameIcons.cityFilled,
          size: size * 0.52,
          color: foreground,
        ),
      ),
      HudTurnActionThumbnailKind.research =>
        thumbnail.technologyId == null
            ? GameIcon(
                GameIcons.science,
                key: const Key('endTurnButton.actionThumbnail.research'),
                size: size * 0.5,
                color: foreground,
              )
            : TechnologySpriteIcon(
                key: const Key('endTurnButton.actionThumbnail.research'),
                id: thumbnail.technologyId!,
                size: size * 0.84,
                fallback: GameIcon(
                  GameIcons.science,
                  size: size * 0.5,
                  color: foreground,
                ),
              ),
    };
  }

  Widget _unitThumbnailFor(double size) {
    final type = thumbnail.unitType!;
    final unitSize = size * _unitThumbnailScale(type);
    return UnitSpriteIcon(
      key: const Key('endTurnButton.actionThumbnail.unit'),
      type: type,
      size: unitSize,
      fallback: GameIcon(
        gameIconForUnitType(type),
        size: unitSize * 0.52,
        color: foreground,
      ),
    );
  }

  double _unitThumbnailScale(GameUnitType type) {
    return switch (type) {
      GameUnitType.worker ||
      GameUnitType.merchant ||
      GameUnitType.scout ||
      GameUnitType.fieldCannon ||
      GameUnitType.tank => 1.0,
      GameUnitType.rifleman || GameUnitType.reconPlane => 1.04,
      GameUnitType.catapult || GameUnitType.heavyInfantry => 1.06,
      GameUnitType.warrior ||
      GameUnitType.archer ||
      GameUnitType.settler ||
      GameUnitType.spearman ||
      GameUnitType.cavalry ||
      GameUnitType.warship => 1.10,
      GameUnitType.commander || GameUnitType.scoutShip => 1.14,
    };
  }
}

class _EndTurnContent extends StatelessWidget {
  final bool compact;
  final int turn;
  final String label;
  final int actionCount;
  final bool objectiveLinked;
  final GameIconData icon;
  final Color foreground;
  final bool showTurnLabel;
  final Duration transitionDuration;

  const _EndTurnContent({
    required this.compact,
    required this.turn,
    required this.label,
    required this.actionCount,
    required this.objectiveLinked,
    required this.icon,
    required this.foreground,
    required this.showTurnLabel,
    required this.transitionDuration,
  });

  @override
  Widget build(BuildContext context) {
    final actionRow = AnimatedSwitcher(
      duration: transitionDuration,
      switchInCurve: GameMotion.enter,
      switchOutCurve: GameMotion.exit,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: [...previousChildren, ?currentChild],
        );
      },
      child: Row(
        key: ValueKey('$label:$actionCount'),
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(
            icon,
            size: compact ? GameIconSize.tiny : GameIconSize.small,
            color: foreground,
          ),
          SizedBox(width: compact ? 4 : 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: GameHudTheme.buttonLabel.copyWith(
                  color: foreground,
                  fontSize: compact ? 10 : 11,
                  height: 1,
                ),
              ),
            ),
          ),
          if (objectiveLinked) ...[
            SizedBox(width: compact ? 3 : 4),
            GameIcon(
              GameIcons.checkCircle,
              key: const Key('endTurnButton.objectiveLink'),
              size: compact ? 9 : 10,
              color: SurfaceElevation.flat.fill(
                background: foreground,
                alpha: 230,
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
      child: showTurnLabel
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  AppLocalizations.of(context).endTurnButtonTurnLabel(turn),
                  maxLines: 1,
                  style: GameHudTheme.buttonTopLabel.copyWith(
                    color: SurfaceElevation.flat.fill(
                      background: foreground,
                      alpha: 210,
                    ),
                    fontSize: 10,
                    height: 1,
                    fontFeatures: GameUiTheme.tabularFigures,
                  ),
                ),
                const SizedBox(height: 2),
                actionRow,
              ],
            )
          : Center(child: actionRow),
    );
  }
}

class _EndTurnMainSegment extends StatelessWidget {
  const _EndTurnMainSegment({
    required this.tooltipLabel,
    required this.waiting,
    required this.onTap,
    required this.child,
  });

  final String tooltipLabel;
  final bool waiting;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltipLabel,
      child: Semantics(
        button: true,
        enabled: !waiting,
        label: tooltipLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: waiting ? null : onTap,
          child: child,
        ),
      ),
    );
  }
}

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
    final l10n = AppLocalizations.of(context);
    final controlForeground = SurfaceElevation.flat.fill(
      background: foreground,
      alpha: 230,
    );
    final progressGlow = SurfaceElevation.flat.fill(
      background: accent,
      alpha: 230,
    );
    final progressShade = SurfaceElevation.flat.fill(
      background: Colors.black,
      alpha: 170,
    );
    final progressLabel = '${currentIndex + 1}/$totalCount';

    return SizedBox(
      key: const Key('endTurnButton.actionMenu'),
      width: width,
      height: minHeight,
      child: PopupMenuButton<int>(
        tooltip: l10n.turnActionListTooltip,
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
        itemBuilder: (context) => [
          for (final option in options)
            CheckedPopupMenuItem<int>(
              key: Key('endTurnButton.actionMenu.item.${option.index}'),
              value: option.index,
              checked: option.index == currentIndex,
              child: _TurnActionMenuItem(option: option),
            ),
        ],
        child: Center(
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
                if (thumbnail case final thumbnail?)
                  _EndTurnActionThumbnailBackdrop(
                    compact: compact,
                    thumbnail: thumbnail,
                    foreground: foreground,
                    imageSize: _thumbnailImageSize(
                      compact: compact,
                      minHeight: minHeight,
                      thumbnail: thumbnail,
                    ),
                    width: _thumbnailFrameWidth(
                      compact: compact,
                      width: width,
                      thumbnail: thumbnail,
                    ),
                    height: _thumbnailFrameHeight(
                      compact: compact,
                      minHeight: minHeight,
                      thumbnail: thumbnail,
                    ),
                    offset: _thumbnailOffset(
                      compact: compact,
                      thumbnail: thumbnail,
                    ),
                    alignment: _thumbnailAlignment(thumbnail),
                    maskStops: _thumbnailMaskStops(thumbnail),
                    maskColors: _thumbnailMaskColors(thumbnail),
                    coverCity:
                        thumbnail.kind == HudTurnActionThumbnailKind.city,
                  ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: compact ? 4 : 5,
                      right: compact ? 3 : 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              progressLabel,
                              key: const Key('endTurnButton.actionProgress'),
                              maxLines: 1,
                              style: GameHudTheme.buttonTopLabel.copyWith(
                                color: controlForeground,
                                fontSize: compact ? 8 : 9,
                                height: 1,
                                fontFeatures: GameUiTheme.tabularFigures,
                                shadows: [
                                  Shadow(
                                    color: progressGlow,
                                    blurRadius: compact ? 5 : 6,
                                  ),
                                  Shadow(
                                    color: progressShade,
                                    blurRadius: 3,
                                    offset: const Offset(0, 0.6),
                                  ),
                                ],
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _thumbnailImageSize({
    required bool compact,
    required double minHeight,
    required HudTurnActionThumbnail thumbnail,
  }) {
    return switch (thumbnail.kind) {
      HudTurnActionThumbnailKind.city => minHeight,
      _ => compact ? 54.6 : 65.8,
    };
  }

  double _thumbnailFrameWidth({
    required bool compact,
    required double width,
    required HudTurnActionThumbnail thumbnail,
  }) {
    return switch (thumbnail.kind) {
      HudTurnActionThumbnailKind.city => width + (compact ? 8 : 10),
      _ => width + (compact ? 16 : 20),
    };
  }

  double _thumbnailFrameHeight({
    required bool compact,
    required double minHeight,
    required HudTurnActionThumbnail thumbnail,
  }) {
    return switch (thumbnail.kind) {
      HudTurnActionThumbnailKind.city => minHeight,
      _ => minHeight + (compact ? 14 : 18),
    };
  }

  Offset _thumbnailOffset({
    required bool compact,
    required HudTurnActionThumbnail thumbnail,
  }) {
    return switch (thumbnail.kind) {
      HudTurnActionThumbnailKind.city => Offset.zero,
      _ => Offset(compact ? 8 : 10, compact ? -5 : -7),
    };
  }

  Alignment _thumbnailAlignment(HudTurnActionThumbnail thumbnail) {
    return switch (thumbnail.kind) {
      HudTurnActionThumbnailKind.city => Alignment.centerRight,
      _ => Alignment.topRight,
    };
  }

  List<double> _thumbnailMaskStops(HudTurnActionThumbnail thumbnail) {
    return switch (thumbnail.kind) {
      HudTurnActionThumbnailKind.unit =>
        _EndTurnActionThumbnailBackdrop._unitMaskStops,
      HudTurnActionThumbnailKind.city =>
        _EndTurnActionThumbnailBackdrop._cityMaskStops,
      _ => _EndTurnActionThumbnailBackdrop._defaultMaskStops,
    };
  }

  List<Color> _thumbnailMaskColors(HudTurnActionThumbnail thumbnail) {
    return switch (thumbnail.kind) {
      HudTurnActionThumbnailKind.unit =>
        _EndTurnActionThumbnailBackdrop._unitMaskColors,
      HudTurnActionThumbnailKind.city =>
        _EndTurnActionThumbnailBackdrop._cityMaskColors,
      _ => _EndTurnActionThumbnailBackdrop._defaultMaskColors,
    };
  }
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
