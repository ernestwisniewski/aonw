enum GamepadMapDirection { up, down, left, right }

final class GamepadInputSnapshot {
  static const empty = GamepadInputSnapshot();

  const GamepadInputSnapshot({
    this.cursorX = 0,
    this.cursorY = 0,
    this.cameraX = 0,
    this.cameraY = 0,
    this.zoomIn = 0,
    this.zoomOut = 0,
    this.dpadUp = false,
    this.dpadDown = false,
    this.dpadLeft = false,
    this.dpadRight = false,
    this.confirm = false,
    this.cancel = false,
    this.inspect = false,
    this.moveMode = false,
    this.hudFocusPrevious = false,
    this.hudFocusNext = false,
    this.focusPrevious = false,
    this.focusNext = false,
    this.primaryAction = false,
  });

  final double cursorX;
  final double cursorY;
  final double cameraX;
  final double cameraY;
  final double zoomIn;
  final double zoomOut;
  final bool dpadUp;
  final bool dpadDown;
  final bool dpadLeft;
  final bool dpadRight;
  final bool confirm;
  final bool cancel;
  final bool inspect;
  final bool moveMode;
  final bool hudFocusPrevious;
  final bool hudFocusNext;
  final bool focusPrevious;
  final bool focusNext;
  final bool primaryAction;

  bool get isIdle => this == empty;

  double get zoom => zoomIn - zoomOut;

  GamepadInputSnapshot copyWith({
    double? cursorX,
    double? cursorY,
    double? cameraX,
    double? cameraY,
    double? zoomIn,
    double? zoomOut,
    bool? dpadUp,
    bool? dpadDown,
    bool? dpadLeft,
    bool? dpadRight,
    bool? confirm,
    bool? cancel,
    bool? inspect,
    bool? moveMode,
    bool? hudFocusPrevious,
    bool? hudFocusNext,
    bool? focusPrevious,
    bool? focusNext,
    bool? primaryAction,
  }) {
    return GamepadInputSnapshot(
      cursorX: cursorX ?? this.cursorX,
      cursorY: cursorY ?? this.cursorY,
      cameraX: cameraX ?? this.cameraX,
      cameraY: cameraY ?? this.cameraY,
      zoomIn: zoomIn ?? this.zoomIn,
      zoomOut: zoomOut ?? this.zoomOut,
      dpadUp: dpadUp ?? this.dpadUp,
      dpadDown: dpadDown ?? this.dpadDown,
      dpadLeft: dpadLeft ?? this.dpadLeft,
      dpadRight: dpadRight ?? this.dpadRight,
      confirm: confirm ?? this.confirm,
      cancel: cancel ?? this.cancel,
      inspect: inspect ?? this.inspect,
      moveMode: moveMode ?? this.moveMode,
      hudFocusPrevious: hudFocusPrevious ?? this.hudFocusPrevious,
      hudFocusNext: hudFocusNext ?? this.hudFocusNext,
      focusPrevious: focusPrevious ?? this.focusPrevious,
      focusNext: focusNext ?? this.focusNext,
      primaryAction: primaryAction ?? this.primaryAction,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GamepadInputSnapshot &&
        other.cursorX == cursorX &&
        other.cursorY == cursorY &&
        other.cameraX == cameraX &&
        other.cameraY == cameraY &&
        other.zoomIn == zoomIn &&
        other.zoomOut == zoomOut &&
        other.dpadUp == dpadUp &&
        other.dpadDown == dpadDown &&
        other.dpadLeft == dpadLeft &&
        other.dpadRight == dpadRight &&
        other.confirm == confirm &&
        other.cancel == cancel &&
        other.inspect == inspect &&
        other.moveMode == moveMode &&
        other.hudFocusPrevious == hudFocusPrevious &&
        other.hudFocusNext == hudFocusNext &&
        other.focusPrevious == focusPrevious &&
        other.focusNext == focusNext &&
        other.primaryAction == primaryAction;
  }

  @override
  int get hashCode => Object.hash(
    cursorX,
    cursorY,
    cameraX,
    cameraY,
    zoomIn,
    zoomOut,
    dpadUp,
    dpadDown,
    dpadLeft,
    dpadRight,
    confirm,
    cancel,
    inspect,
    moveMode,
    hudFocusPrevious,
    hudFocusNext,
    focusPrevious,
    focusNext,
    primaryAction,
  );
}
