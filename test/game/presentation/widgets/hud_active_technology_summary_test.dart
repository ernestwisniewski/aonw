import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_active_technology_summary.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudActiveTechnologySummary', () {
    final l10n = AppLocalizationsEn();

    test('is empty without active technology', () {
      final summary = HudActiveTechnologySummary.fromViewModel(
        viewModel: TechnologyPanelViewModel.empty,
        l10n: l10n,
      );

      expect(summary.name, isNull);
      expect(summary.turnsRemaining, isNull);
      expect(summary.completionTurn, isNull);
    });

    test('formats active technology name and ETA', () {
      final summary = HudActiveTechnologySummary.fromViewModel(
        viewModel: const TechnologyPanelViewModel(
          sciencePerTurn: 3,
          activeTechnology: TechnologyCardViewModel(
            id: TechnologyId.agriculture,
            state: TechnologyCardState.active,
            progress: 2,
            totalCost: 6,
            turnsRemaining: 2,
            boostActive: false,
          ),
          technologies: [],
        ),
        l10n: l10n,
        currentTurn: 5,
      );

      expect(summary.name, l10n.technologyAgriculture);
      expect(summary.turnsRemaining, 2);
      expect(summary.completionTurn, 7);
      expect(summary.eta.compactLabel(l10n), '2 turns • T7');
    });
  });
}
