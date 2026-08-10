part of 'end_turn_button.dart';

class _EndTurnContent extends StatelessWidget {
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

  final bool compact;
  final int turn;
  final String label;
  final int actionCount;
  final bool objectiveLinked;
  final GameIconData icon;
  final Color foreground;
  final bool showTurnLabel;
  final Duration transitionDuration;

  @override
  Widget build(BuildContext context) {
    final actionRow = _EndTurnActionRow(
      compact: compact,
      label: label,
      actionCount: actionCount,
      objectiveLinked: objectiveLinked,
      icon: icon,
      foreground: foreground,
      transitionDuration: transitionDuration,
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
      child: showTurnLabel
          ? _EndTurnContentWithTurn(
              compact: compact,
              turn: turn,
              foreground: foreground,
              actionRow: actionRow,
            )
          : Center(child: actionRow),
    );
  }
}

class _EndTurnActionRow extends StatelessWidget {
  const _EndTurnActionRow({
    required this.compact,
    required this.label,
    required this.actionCount,
    required this.objectiveLinked,
    required this.icon,
    required this.foreground,
    required this.transitionDuration,
  });

  final bool compact;
  final String label;
  final int actionCount;
  final bool objectiveLinked;
  final GameIconData icon;
  final Color foreground;
  final Duration transitionDuration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: transitionDuration,
      switchInCurve: GameMotion.enter,
      switchOutCurve: GameMotion.exit,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.center,
        children: [...previousChildren, ?currentChild],
      ),
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
  }
}

class _EndTurnContentWithTurn extends StatelessWidget {
  const _EndTurnContentWithTurn({
    required this.compact,
    required this.turn,
    required this.foreground,
    required this.actionRow,
  });

  final bool compact;
  final int turn;
  final Color foreground;
  final Widget actionRow;

  @override
  Widget build(BuildContext context) {
    return Column(
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

class _EndTurnActionThumbnailBackdrop extends StatelessWidget {
  static const _unitThumbnailScales = {
    GameUnitType.worker: 1.0,
    GameUnitType.merchant: 1.0,
    GameUnitType.scout: 1.0,
    GameUnitType.fieldCannon: 1.0,
    GameUnitType.tank: 1.0,
    GameUnitType.rifleman: 1.04,
    GameUnitType.reconPlane: 1.04,
    GameUnitType.catapult: 1.06,
    GameUnitType.heavyInfantry: 1.06,
    GameUnitType.warrior: 1.10,
    GameUnitType.archer: 1.10,
    GameUnitType.settler: 1.10,
    GameUnitType.spearman: 1.10,
    GameUnitType.cavalry: 1.10,
    GameUnitType.warship: 1.10,
    GameUnitType.commander: 1.14,
    GameUnitType.scoutShip: 1.14,
  };

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
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: maskStops,
                  colors: maskColors,
                ).createShader(bounds),
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

  double _unitThumbnailScale(GameUnitType type) => _unitThumbnailScales[type]!;
}
