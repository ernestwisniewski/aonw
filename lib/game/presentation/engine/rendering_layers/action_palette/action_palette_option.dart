import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:flutter/foundation.dart';

enum ActionPaletteOptionState { available, recommended, blocked }

enum ActionPaletteYieldKind { food, production, gold, defense }

@immutable
class ActionPaletteYieldChip {
  const ActionPaletteYieldChip({required this.kind, required this.value});

  final ActionPaletteYieldKind kind;
  final int value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionPaletteYieldChip &&
          other.kind == kind &&
          other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);
}

@immutable
class ActionPaletteOption {
  const ActionPaletteOption({
    required this.id,
    required this.iconAtlasRow,
    required this.iconAtlasColumn,
    required this.label,
    required this.yieldChips,
    required this.turns,
    required this.state,
    required this.ctaLabel,
    this.selected = false,
    this.blockedReason,
  }) : vectorIcon = null;

  const ActionPaletteOption.withVectorIcon({
    required this.id,
    required this.vectorIcon,
    required this.label,
    required this.yieldChips,
    required this.turns,
    required this.state,
    required this.ctaLabel,
    this.selected = false,
    this.blockedReason,
  }) : iconAtlasRow = null,
       iconAtlasColumn = null;

  final String id;
  final int? iconAtlasRow;
  final int? iconAtlasColumn;
  final GameIconData? vectorIcon;
  final String label;
  final List<ActionPaletteYieldChip> yieldChips;
  final int? turns;
  final ActionPaletteOptionState state;
  final String ctaLabel;
  final bool selected;
  final String? blockedReason;

  bool get isAvailable => state == ActionPaletteOptionState.available;
  bool get isRecommended => state == ActionPaletteOptionState.recommended;
  bool get isBlocked => state == ActionPaletteOptionState.blocked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionPaletteOption &&
          other.id == id &&
          other.iconAtlasRow == iconAtlasRow &&
          other.iconAtlasColumn == iconAtlasColumn &&
          other.vectorIcon == vectorIcon &&
          other.label == label &&
          listEquals(other.yieldChips, yieldChips) &&
          other.turns == turns &&
          other.state == state &&
          other.ctaLabel == ctaLabel &&
          other.selected == selected &&
          other.blockedReason == blockedReason;

  @override
  int get hashCode => Object.hash(
    id,
    iconAtlasRow,
    iconAtlasColumn,
    vectorIcon,
    label,
    Object.hashAll(yieldChips),
    turns,
    state,
    ctaLabel,
    selected,
    blockedReason,
  );
}
