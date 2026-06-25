import 'package:aonw/game/domain/hex_assessment.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/hex_presentation/hex_kind_presentation.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/hex_presentation/hex_recommendation_copy.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/hex_presentation/hex_tag_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

export 'package:aonw/game/presentation/widgets/bottom_toolbar/hex_presentation/hex_tag_view_model.dart';

class HexProfileViewModel {
  final GameIconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final List<HexTagViewModel> tags;
  final List<SelectionInfoItem> detailItems;

  const HexProfileViewModel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.tags,
    required this.detailItems,
  });

  factory HexProfileViewModel.fromAssessment(
    HexAssessment assessment,
    AppLocalizations l10n,
  ) {
    final primary = presentationForHexKind(assessment.kind, l10n);
    final tags = assessment.tags
        .map((tag) => HexTagViewModel.fromTag(tag, l10n))
        .where((tag) => tag.label != primary.label)
        .toList();

    return HexProfileViewModel(
      icon: primary.icon,
      title: primary.label,
      subtitle: hexRecommendationSubtitle(assessment.recommendation, l10n),
      description: hexAssessmentDescription(
        kind: assessment.kind,
        recommendation: assessment.recommendation,
        l10n: l10n,
      ),
      color: primary.color,
      tags: tags,
      detailItems: [
        if (assessment.yield.defense > 0)
          SelectionInfoItem(
            icon: GameIcons.defense,
            label: l10n.tileSelectionBonusLabel,
            value: l10n.tileSelectionDefenseBonusValue,
            color: const Color(0xFF8da8e8),
          ),
        if (assessment.hasRiver)
          SelectionInfoItem(
            icon: GameIcons.water,
            label: l10n.tileSelectionBonusLabel,
            value: l10n.tileSelectionRiverBonusValue,
            color: GameUiTheme.accent,
          ),
      ],
    );
  }
}
