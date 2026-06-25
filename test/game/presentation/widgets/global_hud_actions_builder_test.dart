import 'package:aonw/game/presentation/widgets/hud/global_hud_actions.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('buildMainGlobalHudActions', () {
    test('includes objectives only when available', () {
      final withoutObjectives = buildMainGlobalHudActions(
        l10n: l10n,
        technologyActive: false,
        objectivesAvailable: false,
        objectivesActive: false,
        empireActive: false,
        onToggleTechnology: () {},
        onToggleObjectives: () {},
        onToggleEmpire: () {},
      );

      final withObjectives = buildMainGlobalHudActions(
        l10n: l10n,
        technologyActive: true,
        activeTechnologyName: 'Bronze',
        activeTechnologyTurnsRemaining: 4,
        activeTechnologyCompletionTurn: 12,
        objectivesAvailable: true,
        objectivesActive: true,
        empireActive: false,
        onToggleTechnology: () {},
        onToggleObjectives: () {},
        onToggleEmpire: () {},
      );

      expect(_labels(withoutObjectives), [
        l10n.commonResearch,
        l10n.commonEmpire,
      ]);
      expect(_labels(withObjectives), [
        l10n.commonResearch,
        l10n.objectivesPanelTitle,
        l10n.commonEmpire,
      ]);
      expect((withObjectives.first as GlobalHudActionButton).active, isTrue);
      expect((withObjectives[1] as GlobalHudActionButton).active, isTrue);
      expect(
        (withObjectives.first as GlobalHudActionButton).tooltip,
        l10n.globalHudCloseResearch,
      );
    });

    test('keeps missing research in tooltip without side text', () {
      final actions = buildMainGlobalHudActions(
        l10n: l10n,
        technologyActive: false,
        researchAvailable: true,
        objectivesAvailable: false,
        objectivesActive: false,
        empireActive: false,
        onToggleTechnology: () {},
        onToggleObjectives: () {},
        onToggleEmpire: () {},
      );

      final research = actions.first as GlobalHudActionButton;

      expect(research.tooltip, l10n.globalHudChooseResearch);
    });

    test('includes research completion turn in tooltip', () {
      final actions = buildMainGlobalHudActions(
        l10n: l10n,
        technologyActive: false,
        activeTechnologyName: 'Bronze',
        activeTechnologyTurnsRemaining: 4,
        activeTechnologyCompletionTurn: 12,
        objectivesAvailable: false,
        objectivesActive: false,
        empireActive: false,
        onToggleTechnology: () {},
        onToggleObjectives: () {},
        onToggleEmpire: () {},
      );

      expect(
        (actions.first as GlobalHudActionButton).tooltip,
        l10n.globalHudResearchActiveWithEta(
          'Bronze',
          l10n.turnEtaDetailLabel(l10n.turnCountLabel(4), 12),
        ),
      );
    });
  });
  group('buildDeckGlobalHudActions', () {
    test('returns bottom-deck actions only when enabled', () {
      final disabled = buildDeckGlobalHudActions(
        l10n: l10n,
        useBottomGlobalActions: false,
        canShowGlobalActions: true,
        technologyActive: false,
        activeTechnologyName: null,
        activeTechnologyTurnsRemaining: null,
        researchAvailable: true,
        objectivesAvailable: true,
        objectivesActive: false,
        empireActive: false,
        activityLogAvailable: true,
        activityLogActive: false,
        onToggleTechnology: () {},
        onToggleObjectives: () {},
        onToggleEmpire: () {},
        onToggleActivityLog: () {},
      );

      final enabled = buildDeckGlobalHudActions(
        l10n: l10n,
        useBottomGlobalActions: true,
        canShowGlobalActions: true,
        technologyActive: false,
        activeTechnologyName: null,
        activeTechnologyTurnsRemaining: null,
        researchAvailable: true,
        objectivesAvailable: false,
        objectivesActive: false,
        empireActive: false,
        activityLogAvailable: true,
        activityLogActive: false,
        onToggleTechnology: () {},
        onToggleObjectives: () {},
        onToggleEmpire: () {},
        onToggleActivityLog: () {},
      );

      expect(disabled, isEmpty);
      expect(_labels(enabled), [l10n.commonResearch, l10n.commonEmpire]);
    });
  });
}

List<String> _labels(List<Object> actions) {
  return [
    for (final action in actions)
      if (action is GlobalHudActionButton) action.keyLabel,
  ];
}
