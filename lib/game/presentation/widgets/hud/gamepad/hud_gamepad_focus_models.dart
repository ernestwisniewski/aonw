part of 'hud_gamepad_focus_controller.dart';

enum HudGamepadFocusSection {
  menu,
  globalActions,
  topResources,
  rightPlayers,
  selectionActions,
}

abstract final class HudGamepadFocusTargetIds {
  static const menuReturn = 'menu.return';
  static const playerStatusSheet = 'players.statusSheet';
  static const bottomCommand = 'bottom.command';
  static const resourceGold = 'resource.gold';
  static const resourceScience = 'resource.science';
  static const resourceStability = 'resource.stability';
  static const resourceResources = 'resource.resources';
  static const resourceTurn = 'resource.turn';
  static const resourceVictory = 'resource.victory';

  static String globalAction(String actionId) => 'global.$actionId';

  static String playerAvatar(String playerId) => 'players.$playerId';

  static String selectionAction(String actionId) => 'selection.$actionId';
}

final class HudGamepadFocusTarget {
  const HudGamepadFocusTarget({
    required this.section,
    required this.id,
    required this.label,
    required this.onActivate,
    this.enabled = true,
    this.activationKey,
  });

  final HudGamepadFocusSection section;
  final String id;
  final String label;
  final VoidCallback onActivate;
  final bool enabled;
  final Object? activationKey;
}

final class HudGamepadFocusState {
  const HudGamepadFocusState({
    required this.active,
    required this.section,
    required this.targetId,
  });

  static const inactive = HudGamepadFocusState(
    active: false,
    section: HudGamepadFocusSection.menu,
    targetId: null,
  );

  final bool active;
  final HudGamepadFocusSection section;
  final String? targetId;
}
