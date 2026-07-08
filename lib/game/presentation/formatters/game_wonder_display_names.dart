import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/wonder.dart';

String wonderDisplayName(AppLocalizations l10n, WonderType type) =>
    WonderDisplayNames.wonder(l10n, type);

abstract final class WonderDisplayNames {
  static String wonder(AppLocalizations l10n, WonderType type) {
    return switch (type) {
      WonderType.greatLibrary => l10n.wonderGreatLibrary,
      WonderType.hangingGardens => l10n.wonderHangingGardens,
      WonderType.greatWall => l10n.wonderGreatWall,
      WonderType.petra => l10n.wonderPetra,
      WonderType.centralBank => l10n.wonderCentralBank,
      WonderType.imperialUniversity => l10n.wonderImperialUniversity,
      WonderType.grandCathedral => l10n.wonderGrandCathedral,
      WonderType.motherFactory => l10n.wonderMotherFactory,
      WonderType.nationalObservatory => l10n.wonderNationalObservatory,
      WonderType.svalbardSeedVault => l10n.wonderSvalbardSeedVault,
      WonderType.grandExposition => l10n.wonderGrandExposition,
    };
  }

  static String description(AppLocalizations l10n, WonderType type) {
    return switch (type) {
      WonderType.greatLibrary => l10n.wonderGreatLibraryDescription,
      WonderType.hangingGardens => l10n.wonderHangingGardensDescription,
      WonderType.greatWall => l10n.wonderGreatWallDescription,
      WonderType.petra => l10n.wonderPetraDescription,
      WonderType.centralBank => l10n.wonderCentralBankDescription,
      WonderType.imperialUniversity => l10n.wonderImperialUniversityDescription,
      WonderType.grandCathedral => l10n.wonderGrandCathedralDescription,
      WonderType.motherFactory => l10n.wonderMotherFactoryDescription,
      WonderType.nationalObservatory =>
        l10n.wonderNationalObservatoryDescription,
      WonderType.svalbardSeedVault => l10n.wonderSvalbardSeedVaultDescription,
      WonderType.grandExposition => l10n.wonderGrandExpositionDescription,
    };
  }
}
