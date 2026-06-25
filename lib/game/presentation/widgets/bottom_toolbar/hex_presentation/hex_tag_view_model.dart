import 'package:aonw/game/domain/hex_assessment.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class HexTagViewModel {
  final String label;
  final GameIconData icon;
  final Color color;

  const HexTagViewModel({
    required this.label,
    required this.icon,
    required this.color,
  });

  factory HexTagViewModel.fromTag(HexAssessmentTag tag, AppLocalizations l10n) {
    return switch (tag) {
      HexAssessmentTag.city => HexTagViewModel(
        label: l10n.hexTagCity,
        icon: GameIcons.city,
        color: const Color(0xFF87c96a),
      ),
      HexAssessmentTag.defense => HexTagViewModel(
        label: l10n.hexTagDefense,
        icon: GameIcons.defense,
        color: const Color(0xFF8da8e8),
      ),
      HexAssessmentTag.trade => HexTagViewModel(
        label: l10n.hexTagTrade,
        icon: GameIcons.route,
        color: const Color(0xFFe0c35c),
      ),
      HexAssessmentTag.fertile => HexTagViewModel(
        label: l10n.hexTagFertile,
        icon: GameIcons.leaf,
        color: const Color(0xFF87c96a),
      ),
      HexAssessmentTag.production => HexTagViewModel(
        label: l10n.hexTagProduction,
        icon: GameIcons.production,
        color: const Color(0xFFc9a95f),
      ),
      HexAssessmentTag.hostile => HexTagViewModel(
        label: l10n.hexTagHostile,
        icon: GameIcons.warning,
        color: const Color(0xFFd48f74),
      ),
      HexAssessmentTag.strategic => HexTagViewModel(
        label: l10n.hexTagStrategic,
        icon: GameIcons.flag,
        color: const Color(0xFFd48f74),
      ),
      HexAssessmentTag.water => HexTagViewModel(
        label: l10n.hexTagWater,
        icon: GameIcons.water,
        color: const Color(0xFF7a9fc4),
      ),
    };
  }
}
