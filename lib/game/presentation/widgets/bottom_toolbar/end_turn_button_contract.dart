part of 'end_turn_button.dart';

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
