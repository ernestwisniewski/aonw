import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/material.dart';

enum MultiplayerAvatarStatus { active, submitted, thinking, waiting, timeout }

class MultiplayerAvatarTileData {
  const MultiplayerAvatarTileData({
    required this.player,
    required this.playerName,
    required this.status,
    required this.timerLabel,
    this.relationStatus,
  });

  final Player player;
  final String playerName;
  final MultiplayerAvatarStatus status;
  final String? timerLabel;
  final DiplomaticRelationStatus? relationStatus;
}

abstract final class MultiplayerAvatarStatusStyle {
  static Color color(MultiplayerAvatarStatus status, Color playerColor) {
    return switch (status) {
      MultiplayerAvatarStatus.active => Color.lerp(
        playerColor,
        GameUiTheme.warning,
        0.45,
      )!,
      MultiplayerAvatarStatus.submitted => GameUiTheme.success,
      MultiplayerAvatarStatus.thinking => GameUiTheme.warning,
      MultiplayerAvatarStatus.waiting => GameHudTheme.colorWaiting,
      MultiplayerAvatarStatus.timeout => GameUiTheme.danger,
    };
  }

  static String label(AppLocalizations l10n, MultiplayerAvatarStatus status) {
    return switch (status) {
      MultiplayerAvatarStatus.active => l10n.multiplayerStatusActive,
      MultiplayerAvatarStatus.submitted => l10n.multiplayerStatusSubmitted,
      MultiplayerAvatarStatus.thinking => l10n.multiplayerStatusThinking,
      MultiplayerAvatarStatus.waiting => l10n.multiplayerStatusWaiting,
      MultiplayerAvatarStatus.timeout => l10n.multiplayerStatusTimeout,
    };
  }
}

abstract final class MultiplayerRelationStatusStyle {
  static Color color(DiplomaticRelationStatus status) {
    return switch (status) {
      DiplomaticRelationStatus.friendly => GameUiTheme.success,
      DiplomaticRelationStatus.neutral => GameUiTheme.textTertiary,
      DiplomaticRelationStatus.hostile => GameUiTheme.warning,
      DiplomaticRelationStatus.truce => GameUiTheme.info,
      DiplomaticRelationStatus.war => GameUiTheme.danger,
    };
  }

  static String label(AppLocalizations l10n, DiplomaticRelationStatus status) {
    return GameDisplayNames.diplomaticRelation(l10n, status);
  }

  static String shortLabel(
    AppLocalizations l10n,
    DiplomaticRelationStatus status,
  ) {
    return GameDisplayNames.diplomaticRelationShort(l10n, status);
  }
}
