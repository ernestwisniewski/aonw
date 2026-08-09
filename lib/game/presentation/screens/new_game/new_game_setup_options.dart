import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:flutter/material.dart';

enum SinglePlayerGameLengthPreset { short60, normal90, long120, veryLong }

extension SinglePlayerGameLengthPresetDisplay on SinglePlayerGameLengthPreset {
  GameLengthConfig get config => switch (this) {
    SinglePlayerGameLengthPreset.short60 => GameLengthConfig.standard60,
    SinglePlayerGameLengthPreset.normal90 => GameLengthConfig.normal90,
    SinglePlayerGameLengthPreset.long120 => GameLengthConfig.long120,
    SinglePlayerGameLengthPreset.veryLong => GameLengthConfig.unlimited,
  };

  IconData get icon => switch (this) {
    SinglePlayerGameLengthPreset.short60 => Icons.bolt_outlined,
    SinglePlayerGameLengthPreset.normal90 => Icons.schedule_outlined,
    SinglePlayerGameLengthPreset.long120 => Icons.hourglass_bottom_outlined,
    SinglePlayerGameLengthPreset.veryLong => Icons.all_inclusive,
  };

  String label(AppLocalizations l10n) => switch (this) {
    SinglePlayerGameLengthPreset.short60 => l10n.gameLengthPresetShort60,
    SinglePlayerGameLengthPreset.normal90 => l10n.gameLengthPresetNormal90,
    SinglePlayerGameLengthPreset.long120 => l10n.gameLengthPresetLong120,
    SinglePlayerGameLengthPreset.veryLong => l10n.gameLengthPresetVeryLong,
  };
}

extension AiDifficultyNewGameDisplay on AiDifficulty {
  IconData get icon => switch (this) {
    AiDifficulty.easy => Icons.sentiment_satisfied_alt_outlined,
    AiDifficulty.normal => Icons.psychology_alt_outlined,
    AiDifficulty.hard => Icons.local_fire_department_outlined,
    AiDifficulty.veryHard => Icons.military_tech_outlined,
  };

  String label(AppLocalizations l10n) => switch (this) {
    AiDifficulty.easy => l10n.aiDifficultyEasy,
    AiDifficulty.normal => l10n.aiDifficultyNormal,
    AiDifficulty.hard => l10n.aiDifficultyHard,
    AiDifficulty.veryHard => l10n.aiDifficultyVeryHard,
  };
}
