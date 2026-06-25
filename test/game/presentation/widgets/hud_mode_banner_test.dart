import 'package:aonw/game/presentation/widgets/hud/hud_combat_preview.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_mode_banner.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudModeBannerSpec.resolve', () {
    test('returns null when no mode is active', () {
      final spec = _resolve(
        pendingAction: null,
        cityFoundingDraft: null,
        moveTargetingActive: false,
      );

      expect(spec, isNull);
    });

    test('city founding draft outranks other modes and shows progress', () {
      final draft = CityFoundingDraft(
        unitId: 'settler_1',
        ownerPlayerId: 'p1',
        center: const CityHex(col: 3, row: 3),
        controlledHexes: const [CityHex(col: 3, row: 4)],
      );

      final spec = _resolve(
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: 'p1',
          attackerUnitId: 'u1',
        ),
        cityFoundingDraft: draft,
        moveTargetingActive: true,
      );

      expect(spec, isNotNull);
      expect(spec!.id, 'cityFounding');
      expect(spec.progress, '1/2');
      expect(spec.primaryAction, isNull);
      expect(spec.minimizable, isFalse);
    });

    test('city founding draft exposes confirm action when complete', () {
      final spec = _resolve(
        pendingAction: null,
        cityFoundingDraft: CityFoundingDraft(
          unitId: 'settler_1',
          ownerPlayerId: 'p1',
          center: const CityHex(col: 3, row: 3),
          controlledHexes: const [
            CityHex(col: 3, row: 4),
            CityHex(col: 4, row: 3),
          ],
        ),
        moveTargetingActive: false,
      );

      expect(spec, isNotNull);
      expect(spec!.primaryAction, isNotNull);
      expect(spec.primaryAction!.label, 'Found city');
      expect(spec.primaryAction!.icon, GameIcons.flag);
    });

    test(
      'city expansion selection waits for a chosen hex before confirming',
      () {
        final spec = _resolve(
          pendingAction: const PendingCityExpansionSelection(
            ownerPlayerId: 'p1',
            cityId: 'city_1',
          ),
          cityFoundingDraft: null,
          moveTargetingActive: false,
        );

        expect(spec, isNotNull);
        expect(spec!.id, HudModeBannerSpec.cityExpansionSelectionId);
        expect(spec.primaryAction, isNull);
        expect(spec.instruction, contains('Without a choice'));
      },
    );

    test('city expansion selection exposes confirm after choosing a hex', () {
      final spec = _resolve(
        pendingAction: const PendingCityExpansionSelection(
          ownerPlayerId: 'p1',
          cityId: 'city_1',
        ),
        cityFoundingDraft: null,
        moveTargetingActive: false,
        cityExpansionHexSelected: true,
      );

      expect(spec, isNotNull);
      expect(spec!.id, HudModeBannerSpec.cityExpansionSelectionId);
      expect(spec.primaryAction, isNotNull);
      expect(spec.primaryAction!.label, 'Confirm');
      expect(spec.primaryAction!.icon, GameIcons.checkCircle);
      expect(spec.instruction, contains('selected tile'));
    });

    test('attack targeting maps to danger-accent banner description', () {
      final spec = _resolve(
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: 'p1',
          attackerUnitId: 'u1',
          defenderCol: 1,
          defenderRow: 0,
        ),
        cityFoundingDraft: null,
        moveTargetingActive: false,
      );

      expect(spec, isNotNull);
      expect(spec!.id, 'attackTargeting');
      expect(spec.instruction, contains('Select an enemy'));
    });

    test('attack targeting includes combat preview details when available', () {
      const preview = HudCombatPreview(
        attackerUnitId: 'a',
        defenderUnitId: 'd',
        attackerName: 'Warrior',
        defenderName: 'Defender',
        targetIsCity: false,
        attackerHpBefore: 10,
        defenderHpBefore: 10,
        attackerMaxHp: 10,
        defenderMaxHp: 10,
        attackerHpAfter: 8,
        defenderHpAfter: 6,
        attackerAttack: 6,
        attackerDefense: 3,
        defenderAttack: 4,
        defenderDefense: 2,
        attackDamage: 4,
        retaliationDamage: 2,
        attackerKilled: false,
        defenderKilled: false,
        defenderRetreated: false,
        distance: 1,
        range: 1,
      );

      final spec = _resolve(
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: 'p1',
          attackerUnitId: 'u1',
          defenderCol: 1,
          defenderRow: 0,
        ),
        cityFoundingDraft: null,
        moveTargetingActive: false,
        combatPreview: preview,
      );

      expect(spec, isNotNull);
      expect(spec!.id, 'attackTargeting');
      expect(spec.progress, '-4 HP');
      expect(spec.instruction, contains('popup'));
      expect(spec.details, [
        'Outcome: defender survives',
        'Target: HP 10->6/10, Attack 6 vs Defense 2 (-4)',
        'Retaliation: Attack 4 vs Defense 3 (-2), HP 10->8/10',
      ]);
    });

    test('combat preview is ignored outside attack targeting', () {
      const preview = HudCombatPreview(
        attackerUnitId: 'a',
        defenderUnitId: 'd',
        attackerName: 'Warrior',
        defenderName: 'Defender',
        targetIsCity: false,
        attackerHpBefore: 10,
        defenderHpBefore: 10,
        attackerMaxHp: 10,
        defenderMaxHp: 10,
        attackerHpAfter: 8,
        defenderHpAfter: 6,
        attackerAttack: 6,
        attackerDefense: 3,
        defenderAttack: 4,
        defenderDefense: 2,
        attackDamage: 4,
        retaliationDamage: 2,
        attackerKilled: false,
        defenderKilled: false,
        defenderRetreated: false,
        distance: 1,
        range: 1,
      );

      final spec = _resolve(
        pendingAction: const PendingResearchSelection(ownerPlayerId: 'p1'),
        cityFoundingDraft: null,
        moveTargetingActive: false,
        combatPreview: preview,
      );

      expect(spec, isNotNull);
      expect(spec!.id, 'researchSelection');
      expect(spec.progress, isNull);
      expect(spec.details, isEmpty);
    });

    test('research selection explains the required technology choice', () {
      final spec = _resolve(
        pendingAction: const PendingResearchSelection(ownerPlayerId: 'p1'),
        cityFoundingDraft: null,
        moveTargetingActive: false,
      );

      expect(spec, isNotNull);
      expect(spec!.id, 'researchSelection');
      expect(spec.instruction, contains('choose a research target'));
    });

    test('worker selection without improvement asks player to pick one', () {
      final spec = _resolve(
        pendingAction: const PendingWorkerActionSelection(
          ownerPlayerId: 'p1',
          unitId: 'w1',
        ),
        cityFoundingDraft: null,
        moveTargetingActive: false,
      );

      expect(spec, isNotNull);
      expect(spec!.id, 'workerAction');
      expect(spec.instruction, contains('Choose an improvement type'));
    });

    test('worker selection with improvement nudges to confirm', () {
      final spec = _resolve(
        pendingAction: const PendingWorkerActionSelection(
          ownerPlayerId: 'p1',
          unitId: 'w1',
          improvementType: FieldImprovementType.farm,
        ),
        cityFoundingDraft: null,
        moveTargetingActive: false,
      );

      expect(spec, isNotNull);
      expect(spec!.instruction, contains('Confirm'));
    });

    test('selected worker action hint exposes an improvement button', () {
      final spec = _resolve(
        pendingAction: null,
        cityFoundingDraft: null,
        moveTargetingActive: false,
        selectedUnit: _unit(GameUnitType.worker),
        workerActionAvailable: true,
      );

      expect(spec, isNotNull);
      expect(spec!.id, HudModeBannerSpec.selectedWorkerActionId);
      expect(spec.title, 'Worker: improve tile');
      expect(spec.primaryAction?.label, 'Improve');
      expect(spec.primaryAction?.accent, GameUiTheme.success);
      expect(spec.minimizable, isTrue);
    });

    test('blocked worker hint explains that the unit should move', () {
      final spec = _resolve(
        pendingAction: null,
        cityFoundingDraft: null,
        moveTargetingActive: false,
        selectedUnit: _unit(GameUnitType.worker),
        workerActionAvailable: false,
        workerActionBlockedReason: 'The tile must belong to a city.',
        selectedUnitMoveActionEnabled: true,
      );

      expect(spec, isNotNull);
      expect(spec!.id, HudModeBannerSpec.selectedWorkerMoveToWorkId);
      expect(spec.title, 'Worker: find a tile');
      expect(spec.instruction, contains('The tile must belong to a city.'));
      expect(spec.instruction, contains('Move the worker'));
      expect(spec.primaryAction?.label, 'Move');
      expect(spec.primaryAction?.enabled, isTrue);
      expect(spec.accent, GameUiTheme.warning);
    });

    test('blocked worker move action can be disabled with a reason', () {
      final spec = _resolve(
        pendingAction: null,
        cityFoundingDraft: null,
        moveTargetingActive: false,
        selectedUnit: _unit(GameUnitType.worker),
        workerActionBlockedReason: 'No movement points left this turn.',
        selectedUnitMoveActionEnabled: false,
        selectedUnitMoveActionDisabledReason:
            'No movement points left this turn.',
      );

      expect(spec, isNotNull);
      expect(spec!.id, HudModeBannerSpec.selectedWorkerMoveToWorkId);
      expect(spec.primaryAction?.enabled, isFalse);
      expect(
        spec.primaryAction?.disabledReason,
        'No movement points left this turn.',
      );
    });

    test('selected scout action hint exposes auto-explore', () {
      final spec = _resolve(
        pendingAction: null,
        cityFoundingDraft: null,
        moveTargetingActive: false,
        selectedUnit: _unit(GameUnitType.scout),
        scoutAutoExploreAvailable: true,
      );

      expect(spec, isNotNull);
      expect(spec!.id, HudModeBannerSpec.selectedScoutExploreId);
      expect(spec.title, 'Scout: explore');
      expect(spec.primaryAction?.label, 'Explore');
      expect(spec.accent, GameUiTheme.info);
    });

    test('selected settler action hint exposes city founding', () {
      final spec = _resolve(
        pendingAction: null,
        cityFoundingDraft: null,
        moveTargetingActive: false,
        selectedUnit: _unit(GameUnitType.settler),
        canStartCityFounding: true,
      );

      expect(spec, isNotNull);
      expect(spec!.id, HudModeBannerSpec.selectedSettlerCityFoundingId);
      expect(spec.title, 'Settler: found city');
      expect(spec.primaryAction?.label, 'Found city');
    });

    test('blocked settler hint explains that the unit should move', () {
      final spec = _resolve(
        pendingAction: null,
        cityFoundingDraft: null,
        moveTargetingActive: false,
        selectedUnit: _unit(GameUnitType.settler),
        canStartCityFounding: false,
        cityFoundingBlockedReason: 'There is already a city on this tile.',
        selectedUnitMoveActionEnabled: true,
      );

      expect(spec, isNotNull);
      expect(spec!.id, HudModeBannerSpec.selectedSettlerMoveToCitySiteId);
      expect(spec.title, 'Settler: find a site');
      expect(
        spec.instruction,
        contains('There is already a city on this tile.'),
      );
      expect(spec.instruction, contains('Move the settler'));
      expect(spec.primaryAction?.label, 'Move');
    });

    test(
      'selected unit hint only appears when the special action can start',
      () {
        final spec = _resolve(
          pendingAction: null,
          cityFoundingDraft: null,
          moveTargetingActive: false,
          selectedUnit: _unit(GameUnitType.worker),
          workerActionAvailable: false,
        );

        expect(spec, isNull);
      },
    );

    test('pending actions outrank selected unit hints', () {
      final spec = _resolve(
        pendingAction: const PendingResearchSelection(ownerPlayerId: 'p1'),
        cityFoundingDraft: null,
        moveTargetingActive: true,
        selectedUnit: _unit(GameUnitType.scout),
        scoutAutoExploreAvailable: true,
      );

      expect(spec, isNotNull);
      expect(spec!.id, 'researchSelection');
    });

    test('movement hint outranks selected unit hints', () {
      final spec = _resolve(
        pendingAction: null,
        cityFoundingDraft: null,
        moveTargetingActive: true,
        selectedUnit: _unit(GameUnitType.scout),
        scoutAutoExploreAvailable: true,
      );

      expect(spec, isNotNull);
      expect(spec!.id, HudModeBannerSpec.moveTargetingId);
      expect(spec.primaryAction?.label, 'Exit movement');
    });

    test('move targeting flag falls back to its own banner', () {
      final spec = _resolve(
        pendingAction: null,
        cityFoundingDraft: null,
        moveTargetingActive: true,
      );

      expect(spec, isNotNull);
      expect(spec!.id, HudModeBannerSpec.moveTargetingId);
      expect(spec.instruction, contains('first tap'));
      expect(spec.instruction, contains('Tap the same hex again'));
      expect(spec.instruction, contains('move'));
      expect(spec.primaryAction?.icon, GameIcons.close);
      expect(spec.primaryAction?.label, 'Exit movement');
    });

    test('commander merge maps to its own banner', () {
      final spec = _resolve(
        pendingAction: const PendingCommanderMergeSelection(
          ownerPlayerId: 'p1',
          commanderUnitId: 'c1',
        ),
        cityFoundingDraft: null,
        moveTargetingActive: false,
      );

      expect(spec, isNotNull);
      expect(spec!.id, 'commanderMerge');
    });

    test('unit turn skip surfaces waiting context', () {
      final spec = _resolve(
        pendingAction: const PendingUnitTurnSkip(
          ownerPlayerId: 'p1',
          unitId: 'u1',
          restoreMovementPoints: 2,
        ),
        cityFoundingDraft: null,
        moveTargetingActive: false,
      );

      expect(spec, isNotNull);
      expect(spec!.id, 'unitTurnSkip');
      expect(spec.instruction, contains('waits until the next turn'));
    });
  });

  group('HudModeBanner widget', () {
    Widget wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Align(child: child)),
    );

    testWidgets('renders founding progress without minimize control', (
      tester,
    ) async {
      final spec = _resolve(
        pendingAction: null,
        cityFoundingDraft: CityFoundingDraft(
          unitId: 'settler_1',
          ownerPlayerId: 'p1',
          center: const CityHex(col: 0, row: 0),
        ),
        moveTargetingActive: false,
      )!;

      await tester.pumpWidget(
        wrap(HudModeBanner(spec: spec, compact: true, onMinimize: () {})),
      );

      expect(find.text('Founding a city'), findsOneWidget);
      expect(find.textContaining('Choose 2 connected tiles'), findsOneWidget);
      expect(find.text('0/2'), findsOneWidget);
      expect(
        find.byKey(const Key('hudModeBanner.primaryAction')),
        findsNothing,
      );
      expect(find.byKey(const Key('hudModeBanner.cancel')), findsNothing);
      expect(find.byKey(const Key('hudModeBanner.minimize')), findsNothing);
    });

    testWidgets('renders founding toolbar hint instead of action button', (
      tester,
    ) async {
      final spec = _resolve(
        pendingAction: null,
        cityFoundingDraft: CityFoundingDraft(
          unitId: 'settler_1',
          ownerPlayerId: 'p1',
          center: const CityHex(col: 0, row: 0),
          controlledHexes: const [
            CityHex(col: 0, row: 1),
            CityHex(col: 1, row: 0),
          ],
        ),
        moveTargetingActive: false,
      )!;

      await tester.pumpWidget(wrap(HudModeBanner(spec: spec, compact: true)));

      expect(
        find.byKey(const Key('hudModeBanner.primaryAction')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('hudModeBanner.toolbarHint')),
        findsOneWidget,
      );
      expect(
        find.text('Use the bottom toolbar for actions when you need them.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders city expansion toolbar hint instead of action button',
      (tester) async {
        final spec = _resolve(
          pendingAction: const PendingCityExpansionSelection(
            ownerPlayerId: 'p1',
            cityId: 'city_1',
          ),
          cityFoundingDraft: null,
          moveTargetingActive: false,
          cityExpansionHexSelected: true,
        )!;

        await tester.pumpWidget(wrap(HudModeBanner(spec: spec, compact: true)));

        expect(find.text('City growth'), findsOneWidget);
        expect(
          find.byKey(const Key('hudModeBanner.primaryAction')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('hudModeBanner.toolbarHint')),
          findsOneWidget,
        );
        expect(
          find.text('Use the bottom toolbar for actions when you need them.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'uses slide motion and move-hint surface styling for all modes',
      (tester) async {
        final spec = _resolve(
          pendingAction: const PendingAttackTargeting(
            ownerPlayerId: 'p1',
            attackerUnitId: 'u1',
          ),
          cityFoundingDraft: null,
          moveTargetingActive: false,
        )!;

        await tester.pumpWidget(
          wrap(HudModeBanner(spec: spec, compact: false)),
        );

        final tween = tester.widget<TweenAnimationBuilder<Offset>>(
          find.byType(TweenAnimationBuilder<Offset>),
        );
        final surface = tester.widget<DecoratedBox>(
          find.byKey(const Key('hudModeBanner.attackTargeting')),
        );
        final decoration = surface.decoration as BoxDecoration;
        final modeIcon = tester
            .widgetList<GameIcon>(find.byType(GameIcon))
            .firstWhere((icon) => icon.icon == spec.icon);

        expect(tween.duration, GameMotion.slide);
        expect(tween.curve, GameMotion.enter);
        expect(decoration.color, GameUiTheme.surfaceDeep.withAlpha(232));
        expect(modeIcon.size, GameIconSize.large);
        expect(modeIcon.color, spec.accent);
      },
    );

    testWidgets('renders combat preview detail chips', (tester) async {
      const spec = HudModeBannerSpec(
        id: 'attackTargeting',
        icon: GameIcons.attack,
        accent: GameUiTheme.danger,
        title: 'Attack',
        instruction: 'Forecast for the nearest target.',
        progress: '-4 HP',
        details: ['Defender: -4 HP, 6/10 HP', 'Warrior: -2 HP, 8/10 HP'],
      );

      await tester.pumpWidget(
        wrap(const HudModeBanner(spec: spec, compact: true)),
      );

      expect(find.byKey(const Key('hudModeBanner.detail.0')), findsOneWidget);
      expect(find.byKey(const Key('hudModeBanner.detail.1')), findsOneWidget);
      expect(find.text('Defender: -4 HP, 6/10 HP'), findsOneWidget);
      expect(find.text('-4 HP'), findsOneWidget);
    });

    testWidgets('move hint keeps styling and exposes minimize control', (
      tester,
    ) async {
      final spec = _resolve(
        pendingAction: null,
        cityFoundingDraft: null,
        moveTargetingActive: true,
      )!;

      var minimized = false;

      await tester.pumpWidget(
        wrap(
          HudModeBanner(
            spec: spec,
            compact: false,
            onMinimize: () => minimized = true,
          ),
        ),
      );

      final surface = tester.widget<DecoratedBox>(
        find.byKey(const Key('hudModeBanner.moveTargeting')),
      );
      final decoration = surface.decoration as BoxDecoration;
      final modeIcon = tester
          .widgetList<GameIcon>(find.byType(GameIcon))
          .firstWhere((icon) => icon.icon == spec.icon);

      expect(decoration.color, GameUiTheme.surfaceDeep.withAlpha(232));
      expect(modeIcon.color, GameUiTheme.gold);
      expect(find.text('Do not show again'), findsNothing);
      expect(find.byKey(const Key('hudModeBanner.cancel')), findsNothing);
      expect(find.text('Exit movement'), findsNothing);
      expect(
        find.byKey(const Key('hudModeBanner.primaryAction')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('hudModeBanner.toolbarHint')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('hudModeBanner.minimize')));
      await tester.pump();
      expect(minimized, isTrue);
    });

    testWidgets('research banner also stays description-only', (tester) async {
      final spec = _resolve(
        pendingAction: const PendingResearchSelection(ownerPlayerId: 'p1'),
        cityFoundingDraft: null,
        moveTargetingActive: false,
      )!;

      await tester.pumpWidget(
        wrap(HudModeBanner(spec: spec, compact: true, onMinimize: () {})),
      );

      expect(find.byKey(const Key('hudModeBanner.cancel')), findsNothing);
      expect(find.byKey(const Key('hudModeBanner.minimize')), findsOneWidget);
      expect(find.text('Choose research'), findsOneWidget);
    });

    testWidgets('uses unique key per spec id', (tester) async {
      final attack = _resolve(
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: 'p1',
          attackerUnitId: 'u1',
        ),
        cityFoundingDraft: null,
        moveTargetingActive: false,
      )!;

      await tester.pumpWidget(
        wrap(HudModeBanner(spec: attack, compact: false)),
      );

      expect(
        find.byKey(const Key('hudModeBanner.attackTargeting')),
        findsOneWidget,
      );
    });
  });
}

GameUnit _unit(GameUnitType type) {
  return GameUnit(
    id: '${type.name}_1',
    ownerPlayerId: 'p1',
    type: type,
    name: type.defaultNameToken,
    col: 1,
    row: 1,
  );
}

HudModeBannerSpec? _resolve({
  required PendingPlayerAction? pendingAction,
  required CityFoundingDraft? cityFoundingDraft,
  required bool moveTargetingActive,
  HudCombatPreview? combatPreview,
  GameUnit? selectedUnit,
  bool workerActionAvailable = false,
  String? workerActionBlockedReason,
  bool scoutAutoExploreAvailable = false,
  bool canStartCityFounding = false,
  String? cityFoundingBlockedReason,
  bool cityExpansionHexSelected = false,
  bool selectedUnitMoveActionEnabled = false,
  String? selectedUnitMoveActionDisabledReason,
}) {
  return HudModeBannerSpec.resolve(
    l10n: AppLocalizationsEn(),
    pendingAction: pendingAction,
    cityFoundingDraft: cityFoundingDraft,
    moveTargetingActive: moveTargetingActive,
    combatPreview: combatPreview,
    selectedUnit: selectedUnit,
    workerActionAvailable: workerActionAvailable,
    workerActionBlockedReason: workerActionBlockedReason,
    scoutAutoExploreAvailable: scoutAutoExploreAvailable,
    canStartCityFounding: canStartCityFounding,
    cityFoundingBlockedReason: cityFoundingBlockedReason,
    cityExpansionHexSelected: cityExpansionHexSelected,
    selectedUnitMoveActionEnabled: selectedUnitMoveActionEnabled,
    selectedUnitMoveActionDisabledReason: selectedUnitMoveActionDisabledReason,
  );
}
