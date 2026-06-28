import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';

abstract final class DiplomacyDisplayNames {
  static String relation(
    AppLocalizations l10n,
    DiplomaticRelationStatus status,
  ) {
    return switch (status) {
      DiplomaticRelationStatus.friendly => l10n.diplomacyRelationFriendly,
      DiplomaticRelationStatus.neutral => l10n.diplomacyRelationNeutral,
      DiplomaticRelationStatus.hostile => l10n.diplomacyRelationHostile,
      DiplomaticRelationStatus.truce => l10n.diplomacyRelationTruce,
      DiplomaticRelationStatus.war => l10n.diplomacyRelationWar,
    };
  }

  static String relationShort(
    AppLocalizations l10n,
    DiplomaticRelationStatus status,
  ) {
    return switch (status) {
      DiplomaticRelationStatus.friendly => l10n.diplomacyRelationFriendlyShort,
      DiplomaticRelationStatus.neutral => l10n.diplomacyRelationNeutralShort,
      DiplomaticRelationStatus.hostile => l10n.diplomacyRelationHostileShort,
      DiplomaticRelationStatus.truce => l10n.diplomacyRelationTruceShort,
      DiplomaticRelationStatus.war => l10n.diplomacyRelationWarShort,
    };
  }
}
