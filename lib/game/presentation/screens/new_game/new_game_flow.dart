import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

enum NewGameFlow { singlePlayer, multiplayer, hotSeat }

abstract final class NewGameFeatureFlags {
  static const multiplayerEnabled = bool.fromEnvironment(
    'AONW_ENABLE_MULTIPLAYER',
    defaultValue: true,
  );
}

extension NewGameFlowX on NewGameFlow {
  static const singlePlayerAiOpponentCount = 3;
  static const singlePlayerPlayerCount = 1 + singlePlayerAiOpponentCount;
  static const defaultFlow = NewGameFlow.singlePlayer;
  static const choiceOrder = [
    NewGameFlow.multiplayer,
    NewGameFlow.singlePlayer,
    NewGameFlow.hotSeat,
  ];

  static NewGameFlow fromQuery(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'single-player' || 'singleplayer' || 'single' => NewGameFlow.singlePlayer,
      'multiplayer' || 'multi-player' => NewGameFlow.multiplayer,
      'hot-seat' || 'hotseat' || 'hot_seat' => NewGameFlow.hotSeat,
      _ => defaultFlow,
    };
  }

  String get queryValue => switch (this) {
    NewGameFlow.singlePlayer => 'single-player',
    NewGameFlow.multiplayer => 'multiplayer',
    NewGameFlow.hotSeat => 'hot-seat',
  };

  String menuLabel(AppLocalizations l10n) => switch (this) {
    NewGameFlow.singlePlayer => l10n.gameModeSinglePlayerMenuLabel,
    NewGameFlow.multiplayer => l10n.gameModeMultiplayerMenuLabel,
    NewGameFlow.hotSeat => l10n.gameModeHotSeatMenuLabel,
  };

  String summaryLabel(AppLocalizations l10n) => switch (this) {
    NewGameFlow.singlePlayer => l10n.gameModeSinglePlayerSummaryLabel,
    NewGameFlow.multiplayer => l10n.gameModeMultiplayerSummaryLabel,
    NewGameFlow.hotSeat => l10n.gameModeHotSeatSummaryLabel,
  };

  String mapHeaderTitle(AppLocalizations l10n) => switch (this) {
    NewGameFlow.singlePlayer => l10n.gameModeSinglePlayerMapTitle,
    NewGameFlow.multiplayer => l10n.gameModeMultiplayerMapTitle,
    NewGameFlow.hotSeat => l10n.gameModeHotSeatMapTitle,
  };

  String mapHeaderSubtitle(AppLocalizations l10n) => switch (this) {
    NewGameFlow.singlePlayer => l10n.gameModeSinglePlayerMapSubtitle,
    NewGameFlow.multiplayer => l10n.gameModeMultiplayerMapSubtitle,
    NewGameFlow.hotSeat => l10n.gameModeHotSeatMapSubtitle,
  };

  IconData get icon => switch (this) {
    NewGameFlow.singlePlayer => Icons.smart_toy_outlined,
    NewGameFlow.multiplayer => Icons.public_outlined,
    NewGameFlow.hotSeat => Icons.groups_2_outlined,
  };

  GameMode get gameMode => switch (this) {
    NewGameFlow.singlePlayer => GameMode.multiplayer,
    NewGameFlow.multiplayer => GameMode.multiplayer,
    NewGameFlow.hotSeat => GameMode.hotSeat,
  };

  bool get startsLocally => this != NewGameFlow.multiplayer;
  bool get locksAiOpponent => this == NewGameFlow.singlePlayer;
  bool get enabled =>
      this != NewGameFlow.multiplayer || NewGameFeatureFlags.multiplayerEnabled;

  String? disabledReason(AppLocalizations l10n) {
    if (enabled) return null;
    return switch (this) {
      NewGameFlow.multiplayer => l10n.newGameModeMultiplayerAlphaDisabled,
      _ => null,
    };
  }
}
